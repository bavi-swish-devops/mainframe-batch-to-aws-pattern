use assert_cmd::Command;
use std::path::{Path, PathBuf};
use std::process::Command as ProcessCommand;

fn repo_root() -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("../..")
        .canonicalize()
        .expect("failed to resolve repo root")
}

fn fixture_path(file_name: &str) -> PathBuf {
    PathBuf::from(env!("CARGO_MANIFEST_DIR"))
        .join("tests")
        .join("fixtures")
        .join(file_name)
}

fn compile_cobol_binary(repo_root: &Path) -> PathBuf {
    let source = repo_root.join("legacy/cobol/ACCTPOST.cbl");
    let output = repo_root.join("modern/app/target/acctpost_compat_test");

    let result = ProcessCommand::new("cobc")
        .args([
            "-x",
            "-o",
            output.to_str().expect("invalid output path"),
            source.to_str().expect("invalid source path"),
        ])
        .current_dir(repo_root)
        .output()
        .expect("failed to execute cobc. is GnuCOBOL installed?");

    assert!(
        result.status.success(),
        "failed to compile COBOL.\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&result.stdout),
        String::from_utf8_lossy(&result.stderr)
    );

    output
}

fn run_cobol_binary(repo_root: &Path, cobol_binary: &Path) -> String {
    let result = ProcessCommand::new(cobol_binary)
        .current_dir(repo_root)
        .output()
        .expect("failed to execute compiled COBOL binary");

    assert!(
        result.status.success(),
        "COBOL process failed.\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&result.stdout),
        String::from_utf8_lossy(&result.stderr)
    );

    String::from_utf8_lossy(&result.stdout).to_string()
}

fn run_rust_binary(input_file: &Path) -> String {
    let output = Command::cargo_bin("app")
        .expect("failed to locate cargo binary")
        .args(["--input", input_file.to_str().expect("invalid input path")])
        .output()
        .expect("failed to execute Rust batch");

    assert!(
        output.status.success(),
        "Rust process failed.\nstdout:\n{}\nstderr:\n{}",
        String::from_utf8_lossy(&output.stdout),
        String::from_utf8_lossy(&output.stderr)
    );

    String::from_utf8_lossy(&output.stdout).to_string()
}

fn normalize_cobol_output(output: &str) -> String {
    let mut records_read = None;
    let mut total_credits = None;
    let mut total_debits = None;
    let mut net_amount = None;

    for line in output.lines() {
        let trimmed = line.trim();

        if trimmed.starts_with("RECORDS READ") {
            records_read = trimmed.split(':').nth(1).map(|v| v.trim().to_string());
        } else if trimmed.starts_with("TOTAL CREDITS") {
            total_credits = trimmed.split(':').nth(1).map(|v| v.trim().to_string());
        } else if trimmed.starts_with("TOTAL DEBITS") {
            total_debits = trimmed.split(':').nth(1).map(|v| v.trim().to_string());
        } else if trimmed.starts_with("NET AMOUNT") {
            net_amount = trimmed.split(':').nth(1).map(|v| v.trim().to_string());
        }
    }

    format!(
        "RECORDS_READ={}\nTOTAL_CREDITS={}\nTOTAL_DEBITS={}\nNET_AMOUNT={}",
        records_read.expect("missing RECORDS READ in COBOL output"),
        total_credits.expect("missing TOTAL CREDITS in COBOL output"),
        total_debits.expect("missing TOTAL DEBITS in COBOL output"),
        net_amount.expect("missing NET AMOUNT in COBOL output")
    )
}

fn normalize_rust_output(output: &str) -> String {
    let lines: Vec<String> = output
        .lines()
        .map(str::trim)
        .filter(|line| {
            line.starts_with("RECORDS_READ=")
                || line.starts_with("TOTAL_CREDITS=")
                || line.starts_with("TOTAL_DEBITS=")
                || line.starts_with("NET_AMOUNT=")
        })
        .map(String::from)
        .collect();

    assert!(
        lines.len() == 4,
        "unexpected Rust summary output.\noutput:\n{}",
        output
    );

    lines.join("\n")
}

#[test]
fn legacy_and_modern_outputs_match_for_basic_fixture() {
    let repo = repo_root();
    let input_file = fixture_path("transactions_basic.dat");

    let cobol_binary = compile_cobol_binary(&repo);

    let cobol_output = run_cobol_binary(&repo, &cobol_binary);
    let rust_output = run_rust_binary(&input_file);

    let normalized_cobol = normalize_cobol_output(&cobol_output);
    let normalized_rust = normalize_rust_output(&rust_output);

    assert_eq!(
        normalized_cobol, normalized_rust,
        "legacy and modern outputs differ.\n\nCOBOL:\n{}\n\nRust:\n{}",
        normalized_cobol, normalized_rust
    );
}
