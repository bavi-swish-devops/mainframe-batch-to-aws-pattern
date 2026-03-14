# Decision Matrix

This document compares two modernization strategies for the batch workload represented in this repository:

- **Re-host**: preserve the COBOL application and operating model with minimal application change
- **Re-platform / Re-engineer**: rebuild the batch workload using modern AWS-aligned components

The goal is not to declare one option universally better. The goal is to make the trade-offs explicit for this specific project.

---

## Context

Current repository state:

- the legacy path is implemented as a COBOL batch program plus representative JCL
- the modern path is implemented as a Rust batch application with Docker packaging
- Terraform scaffolding exists, but the AWS execution model is still partial
- compatibility between legacy and modern output is validated by automated tests

Because this repository is intended to demonstrate modernization thinking and cloud architecture mapping, long-term maintainability and cloud alignment matter more here than lowest-effort migration.

---

## Scoring model

- Score scale: `1` = weak fit, `5` = strong fit
- Weight scale: higher weight means greater importance for this project
- Weighted score = `score x weight`

---

## Decision Matrix

| Criterion                                    | Weight | Re-host Score | Re-host Weighted | Re-platform / Re-engineer Score | Re-platform / Re-engineer Weighted | Notes                                                                                                               |
| -------------------------------------------- | -----: | ------------: | ---------------: | ------------------------------: | ---------------------------------: | ------------------------------------------------------------------------------------------------------------------- |
| Migration speed                              |      5 |             5 |               25 |                               2 |                                 10 | Re-host is faster because it preserves COBOL and the batch operating model.                                         |
| Upfront engineering effort                   |      4 |             5 |               20 |                               2 |                                  8 | Re-host minimizes code and process change. Re-engineering requires redesign, implementation, and validation.        |
| Legacy code preservation                     |      3 |             5 |               15 |                               1 |                                  3 | Re-host keeps the original application structure largely intact.                                                    |
| Cloud-native flexibility                     |      5 |             2 |               10 |                               5 |                                 25 | Re-engineering fits S3, containers, ECS, CloudWatch, and IaC more naturally.                                        |
| Long-term maintainability                    |      5 |             2 |               10 |                               5 |                                 25 | The Rust path is easier to evolve with modern tooling, testing, and delivery practices.                             |
| Observability and operations                 |      4 |             2 |                8 |                               5 |                                 20 | Modern structured logging and AWS-native monitoring are better aligned with the re-engineered path.                 |
| Platform lock-in risk                        |      3 |             2 |                6 |                               4 |                                 12 | Re-host often depends on a compatible runtime or specialized modernization platform.                                |
| Cost efficiency over time                    |      4 |             2 |                8 |                               4 |                                 16 | Re-host may reduce migration cost but can carry higher recurring platform cost.                                     |
| Skills and hiring alignment                  |      3 |             2 |                6 |                               4 |                                 12 | Modern engineering skills are more broadly available than specialized legacy runtime expertise.                     |
| Functional equivalence confidence            |      4 |             4 |               16 |                               4 |                                 16 | Both paths can preserve behavior, but the modern path needs disciplined testing, which already exists in this repo. |
| Security and compliance evolution            |      3 |             2 |                6 |                               4 |                                 12 | Modern tooling and infra automation generally improve the ability to evolve controls over time.                     |
| Portfolio / strategic value for this project |      5 |             2 |               10 |                               5 |                                 25 | This repository is explicitly positioned as a modernization showcase, not only a migration exercise.                |
| **Total**                                    | **48** |               |          **140** |                                 |                            **184** |                                                                                                                     |

---

## Recommendation

For this repository, the recommended strategy is **Re-platform / Re-engineer**.

Reason:

- it aligns with the stated project goal of demonstrating modernization decision-making and AWS-aligned design
- the repository already contains a working modern implementation path in Rust
- automated compatibility tests reduce the risk of behavior drift between legacy and modern flows
- the long-term benefits in maintainability, observability, and cloud fit outweigh the extra implementation effort for this use case

If the primary business objective were instead "move quickly with minimal application change," then **Re-host** would likely be the better near-term choice.

---

## When Re-host Is The Better Choice

Choose re-host when:

- migration timeline is the dominant constraint
- the COBOL workload is stable and not expected to change much
- the organization wants minimal disruption to current job control and batch operations
- short-term delivery matters more than long-term cloud-native optimization

---

## When Re-platform / Re-engineer Is The Better Choice

Choose re-platform / re-engineer when:

- the workload will continue to evolve
- observability, automation, and CI/CD matter
- the target state is AWS-native operations rather than runtime compatibility
- long-term maintainability and talent availability are strategic concerns

---

## Conclusion

The matrix does not suggest that re-host is wrong. It shows that for **this project's stated purpose**, re-engineering creates more value. Re-host remains a valid option for organizations optimizing primarily for migration speed and low application change.
