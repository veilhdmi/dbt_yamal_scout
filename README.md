# dbt_yamal_scout

dbt project (BigQuery) that turns Lamine Yamal's raw ESPN match log into tested, model-ready tables for the [Yamal Scout](https://github.com/veilhdmi/yamal_scout) agent.

## Lineage

```
source espn.raw_espn_gamelog          (yamal_scout, loaded by ingest_espn.py)
        │
        ▼
stg_espn__gamelog                     (yamal_staging, view)
        │
        ├──► fct_lamine_matches          (yamal_marts, table) — every match, friendlies flagged; the agent queries this
        └──► fct_lamine_match_features   (yamal_marts, table) — competitive matches, point-in-time features for the model
```

## Design decisions

- **No leakage by construction.** Every rolling feature uses a window ending at `1 preceding`. `tests/assert_no_feature_leakage.sql` recomputes the 5-match average with a self-join on earlier matches and fails if the mart disagrees.
- **Unknown values fail loudly.** `league_slug` has an explicit list of accepted values and `team` has no `else` branch, so a new competition or team stops the build instead of silently being misclassified.
- **Severity matches the impact.** Duplicated or missing keys are errors. Known source gaps (ESPN records 0 shots on target in friendlies) are warnings. `assert_complete_club_seasons` warns at 1 short season and errors at 3.
- **Custom schemas, no prefix.** `macros/generate_schema_name.sql` writes to `yamal_staging` / `yamal_marts` instead of `yamal_dev_yamal_staging`.

## Run

```powershell
python -m venv .venv
.venv\Scripts\activate
python -m pip install -r requirements.txt
dbt deps
dbt build                 # expected: all PASS, 1 WARN (friendlies without shots on target)
dbt source freshness
```

Needs a `yamal_scout` profile in `~/.dbt/profiles.yml` (BigQuery, oauth, location US).
