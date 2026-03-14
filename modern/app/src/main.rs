use chrono::NaiveDate;
use clap::Parser;
use serde::Serialize;
use tracing::{error, info};
use tracing_subscriber::{EnvFilter, fmt};

#[derive(Parser, Debug)]
#[command(
    name = "mainframe-batch-modernizer",
    version,
    about = "Simulates a modernized mainframe batch workload in Rust"
)]
struct Args {
    #[arg(long, default_value = "../../legacy/data/input_fixed.dat")]
    input: String,
}

#[derive(Debug, Serialize)]
struct TransactionRecord {
    account_id: String,
    txn_date: NaiveDate,
    amount_cents: i64,
    txn_type: TransactionType,
    description: String,
}

#[derive(Debug, Serialize, PartialEq, Eq)]
enum TransactionType {
    Credit,
    Debit,
}

#[derive(Debug, Default)]
struct BatchSummary {
    records_read: usize,
    total_credits_cents: i64,
    total_debits_cents: i64,
    net_amount_cents: i64,
}

fn main() {
    init_logging();

    let args = Args::parse();

    info!(input = %args.input, "starting batch job");

    match run(&args.input) {
        Ok(summary) => {
            print_summary(&summary);
            info!("batch job finished successfully");
        }
        Err(err) => {
            error!(error = %err, "batch job failed");
            std::process::exit(1);
        }
    }
}

fn init_logging() {
    let filter = EnvFilter::try_from_default_env().unwrap_or_else(|_| EnvFilter::new("info"));

    fmt()
        .with_env_filter(filter)
        .with_target(false)
        .json()
        .init();
}

fn run(input_path: &str) -> Result<BatchSummary, Box<dyn std::error::Error>> {
    let content = std::fs::read_to_string(input_path)?;
    let mut records = Vec::new();

    for (idx, line) in content.lines().enumerate() {
        let line_number = idx + 1;

        if line.trim().is_empty() {
            continue;
        }

        let record = parse_record(line).map_err(|err| format!("line {}: {}", line_number, err))?;

        info!(
            line_number = line_number,
            account_id = %record.account_id,
            amount_cents = record.amount_cents,
            "record parsed successfully"
        );

        records.push(record);
    }

    info!(record_count = records.len(), "all records parsed");

    Ok(build_summary(&records))
}

fn build_summary(records: &[TransactionRecord]) -> BatchSummary {
    let mut summary = BatchSummary {
        records_read: records.len(),
        ..BatchSummary::default()
    };

    for record in records {
        match record.txn_type {
            TransactionType::Credit => {
                summary.total_credits_cents += record.amount_cents;
                summary.net_amount_cents += record.amount_cents;
            }
            TransactionType::Debit => {
                summary.total_debits_cents += record.amount_cents;
                summary.net_amount_cents -= record.amount_cents;
            }
        }
    }

    summary
}

fn print_summary(summary: &BatchSummary) {
    println!("RECORDS_READ={}", summary.records_read);
    println!(
        "TOTAL_CREDITS={:.2}",
        cents_to_decimal(summary.total_credits_cents)
    );
    println!(
        "TOTAL_DEBITS={:.2}",
        cents_to_decimal(summary.total_debits_cents)
    );
    println!(
        "NET_AMOUNT={:.2}",
        cents_to_decimal(summary.net_amount_cents)
    );
}

fn cents_to_decimal(cents: i64) -> f64 {
    cents as f64 / 100.0
}

fn parse_record(line: &str) -> Result<TransactionRecord, String> {
    if line.len() != 48 {
        return Err(format!(
            "invalid record length: expected 48, got {}",
            line.len()
        ));
    }

    let account_id = slice(line, 0, 10).trim().to_string();
    let txn_date_raw = slice(line, 10, 18).trim();
    let amount_raw = slice(line, 18, 27).trim();
    let txn_type_raw = slice(line, 27, 28).trim();
    let description = slice(line, 28, 48).trim().to_string();

    if account_id.is_empty() {
        return Err("account_id is required".to_string());
    }

    let txn_date = NaiveDate::parse_from_str(txn_date_raw, "%Y%m%d")
        .map_err(|_| format!("invalid txn_date: {}", txn_date_raw))?;

    let amount_cents: i64 = amount_raw
        .parse()
        .map_err(|_| format!("invalid amount: {}", amount_raw))?;

    let txn_type = match txn_type_raw {
        "C" => TransactionType::Credit,
        "D" => TransactionType::Debit,
        _ => return Err(format!("invalid txn_type: {}", txn_type_raw)),
    };

    Ok(TransactionRecord {
        account_id,
        txn_date,
        amount_cents,
        txn_type,
        description,
    })
}

fn slice(value: &str, start: usize, end: usize) -> &str {
    &value[start..end]
}
