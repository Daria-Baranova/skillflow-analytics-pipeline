# Data Quality Report — SkillFlow

Profiling of `bronze` tables and how each issue is handled in `silver` (dbt staging models).

## payments (GCS)
| Issue | Rows | Fix in `stg_payments` |
|---|---|---|
| Exact duplicate rows | 40 | `row_number()` by `payment_id` |
| `amount_raw` in mixed formats: `$9.99`, `9.99 USD`, `3 332,92 UAH` | all | regexp → numeric, comma → dot |
| Refunds stored as negative amounts | 84 | kept, flagged by `is_refund` |

## users (S3)
| Issue | Rows | Fix in `stg_users` |
|---|---|---|
| Exact duplicate rows | 150 | `row_number()` by `user_id` |
| `signup_at` in `DD/MM/YYYY HH24:MI` format (dlt variant column `signup_at__v_text`), values are UTC | 1 615 | `to_timestamp(... ' +00', ... TZH)` |
| `country` spelling: `UA`, `ukraine`, `Ukraine ` | ~4 000 | ISO codes mapped, `initcap(trim())` |
| Leading/trailing spaces in `device`, `traffic_source` | ~3 000 | `trim()` |
| Test accounts | 59 | kept, flagged by `is_test_account` |

## subscriptions (S3)
| Issue | Rows | Fix in `stg_subscriptions` |
|---|---|---|
| Exact duplicate rows | 50 | `row_number()` |
| `trial_status` has 11 spellings (`conv`, `canceled`, `CONVERTED`) | ~900 | normalized to `active / converted / cancelled` |
| `converted` status without `converted_at` | 17 | not fixed — to be caught by dbt test |

## lessons (GCS)
| Issue | Rows | Fix in `stg_lessons` |
|---|---|---|
| `duration_min` as text, `20` or `20 min` | 28 | strip ` min`, cast to INT |
| `is_active` as `yes / true / TRUE / 1 / false` | all | converted to boolean |

## lesson_progress (GCS)
| Issue | Rows | Fix in `stg_lesson_progress` |
|---|---|---|
| `completion_pct` as text, some with `%` | 1 423 | strip `%`, cast to INT |
| `completion_pct` > 100 (max 120) | — | capped at 100 with `least()` |
| `completed_at` earlier than `started_at` | 109 | set to NULL |
| `lesson_id` not present in `lessons` | 100 | not fixed — to be caught by relationships test |

## events (S3)
| Issue | Rows | Fix in `stg_events` |
|---|---|---|
| Duplicate `event_id` | 3 119 | `row_number()`, prefer non-null `user_id`, then later `event_ts` |
| Duplicate copies with `event_ts` shifted −3h (timezone bug) | 121 | later copy kept (verified against signup time) |
| NULL `user_id` | 1 575 | recovered from `session_id` (`S<user_id>-<date>`) |
| `event_name`, `platform` in mixed case | ~45 000 | `lower(trim())` |

## experiments (S3)
| Issue | Rows | Fix in `stg_experiments` |
|---|---|---|
| Groups named `A / B / a / B ` and `control / treatment` | ~4 500 | `control → A`, `treatment → B`, `upper(trim())` |
| Duplicate user assignments, 60 with conflicting groups | 140 | prefer `assignment_source = 'sdk'` over `manual_backfill` |

## marketing_spend (S3)
| Issue | Rows | Fix in `stg_marketing_spend` |
|---|---|---|
| `spend_usd` as text in mixed formats | all | parsed like payments |
| Negative spend | 2 | set to NULL |
| `channel` spellings: `paid_social`, `PaidSocial`, `GoogleAds` | ~400 | mapped to `users.traffic_source` names |

## app_errors (GCS)
| Issue | Rows | Fix in `stg_app_errors` |
|---|---|---|
| `error_code` case and leading spaces | ~800 | `upper(trim())` |
| Errors from deleted users (`user_id` not in users) | 150 | not fixed — to be caught by relationships test |

## support_tickets (GCS)
| Issue | Rows | Fix in `stg_support_tickets` |
|---|---|---|
| `category` in mixed case | ~540 | `lower(trim())` |

## Known limitations
| Limitation | Impact |
|---|---|
| Activity data covers max 22 days after signup | D30 retention cannot be measured — D14 used instead |
| Events end on 2026-07-22 | July metrics (DAU/MAU) cover a partial month |