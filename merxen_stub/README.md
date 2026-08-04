# merxen_stub

A structural stub of [bourdenxlab/MerXen](https://github.com/bourdenxlab/MerXen)
for validating Flow compatibility (FLOW-700).

The aim is to reproduce MerXen's **shape** — the same processes, the same
directory-typed inputs and outputs, the same `${outdir}/<pair_id>/<platform>/<stage>/`
tree — while doing no real computation, so we can iterate quickly on Flow
(especially directory inputs/outputs) without GPUs, conda, or reference data.

## What is faithful vs. stubbed

- **Copied verbatim from MerXen:** `workflows/main.nf`, `workflows/nextflow.config`,
  `workflows/conf/dwight.config`, `workflows/samplesheet.example.csv`. All the
  Groovy orchestration, parameter parsing, channel wiring, the `SEGMENT`
  sub-workflow, `publishDir` targets, and process `input:`/`output:` tuple
  shapes are unchanged.
- **Stubbed:** only each process's `script:` body. The real `merxen …` /
  `pip` / `cargo` / `python -m …` / GPU-monitor calls are replaced with
  `mkdir`/`echo` that create exactly the process's declared outputs with
  placeholder content. `.zarr` outputs are directories containing a dummy
  `.zattrs`; `*_out/` outputs are directories with a placeholder file.
- **Not reproduced:** MerXen's side-channel writes to hardcoded absolute paths
  under `outdir` (e.g. `<pair>/<platform>/latest/latest_spatialdata.zarr`,
  the durable `segmentation/*.npy`). These are written outside Nextflow's
  `publishDir`, so Flow discovers outputs from process executions cannot target
  them anyway. Every `publishDir` directory output *is* reproduced.

Per FLOW-700, the pipeline code is not modified to accommodate Flow — only the
schema (`flow/schema/merxen.json`) and the execution config a deployment
supplies (see `test/local.config`).

## Layout

```
merxen_stub/
├── flow/schema/merxen.json     # Flow schema (inputs + directory outputs)
├── workflows/                  # mirrors the MerXen repo's workflows/ dir
│   ├── main.nf                 # verbatim
│   ├── nextflow.config         # verbatim
│   ├── conf/dwight.config      # verbatim
│   └── modules/*.nf            # verbatim except stubbed script bodies
└── test/                       # local smoke test (not part of the pipeline)
    ├── run_smoke.sh
    ├── local.config            # disables conda/containers/GPU-lock for local runs
    ├── inputs/                 # fake raw MERSCOPE/Xenium directories
    └── refs/                   # dummy reference files + annotation GeoJSONs
```

## Flow registration

- **Path:** `merxen_stub/workflows/main.nf`
- **Schema Path:** `merxen_stub/flow/schema/merxen.json`

The raw MERSCOPE/Xenium inputs are **directories**, exposed in the schema as
`data` columns on the samplesheet. MerXen's hardcoded reference paths (MECR,
clustering annotation, MapMyCells) are exposed as `data` parameters. Every
curated output is a directory (`"filetype": ""`).

## Running the smoke test

```bash
merxen_stub/test/run_smoke.sh
```

Requires Nextflow (auto-pinned to `NXF_VER=26.04.6`; see caveat below) and
Java 17+. It runs two configurations and asserts the expected directory tree:

- **Test A** — paired defaults, `build_spatialdata → clustering_squidpy`.
- **Test B** — paired with all opt-in stages on (`enable_alignment`,
  `cortical_depth_enabled`, `distance_from_object_enabled`) through `mapmycells`.

## Known behaviours surfaced while stubbing

- **Nextflow version:** MerXen's `main.nf` is ~114 KB; its `workflow` body
  compiles a >64 KB constant that the legacy Groovy parser rejects
  (`String too long`) on Nextflow 24.x/25.x. It compiles and runs on 26.x. Flow
  must run this pipeline on Nextflow ≥ 26.x.
- **Only the first segmentation branch runs.** With `analysis_segmentation=both`
  (default), `main.nf` joins the enriched-zarr channel (one item per
  `pair_id|platform`) against a per-segmentation gate (two items per key) using
  `.join()`, which is 1:1 — so only `reseg` proceeds through the downstream
  analysis stages and `original_seg` is silently dropped, despite
  `docs/outputs.md` documenting both. This is upstream behaviour reproduced
  faithfully; worth confirming against however MerXen is run in production.
