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

- **Input access is verified, not faked.** MerXen receives the raw
  `merscope_dir`/`xenium_dir` as a *value* path (embedded in a config JSON, not
  a Nextflow-staged `path()`) and its Python opens that absolute path directly.
  So `BUILD_SPATIALDATA` reproduces the real input resolution
  (`io/builders/pipeline.py`): it reads `input_path` from the config and **fails
  the task** if that path is not an accessible directory, or — for a raw export
  folder — if it lacks the files the builder reads (MERSCOPE: `images/`,
  `micron_to_mosaic_pixel_transform.csv`, `cell_boundaries.parquet`,
  `detected_transcripts.parquet|csv`; XENIUM: `experiment.xenium`/`specs.json`
  and `transcripts.parquet`). A reusable `.zarr` cache path only needs to be a
  directory. This is what makes the stub a real probe of Flow directory inputs:
  if Flow doesn't mount the selected data path into the process container, or
  the uploaded directory has the wrong structure, the stub fails exactly where a
  real run would — it does not report a false success.

Per FLOW-700, the pipeline code is not modified to accommodate Flow — only the
schema (`flow/schema/merxen.json`) and the execution config a deployment
supplies (see `test/local.config`).

The equivalent access check is *not* yet applied to the file inputs consumed by
later stages (MECR/clustering/MapMyCells reference paths, cortical-depth /
distance GeoJSONs). Those are value paths too, so they carry the same
container-mount risk; `main.nf`'s preflight checks their existence only on the
launch node, not inside the process container.

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

## Running on Flow

Register (admin panel → Pipelines):

- **Repo:** `goodwright/nf-test`
- **Path:** `merxen_stub/workflows/main.nf`
- **Schema Path:** `merxen_stub/flow/schema/merxen.json`
- **Config Paths:** `merxen_stub/flow/flow.config`

`flow/flow.config` adapts MerXen's workstation defaults (GPU queues, GPU `flock`
locks, apptainer/conda directives, 200–300 GB memory requests from
`conf/dwight.config`) to a Flow docker + slurm environment: it runs the stub's
pure-shell bodies in `ubuntu:22.04`, drops the GPU queues/locks, and requests
trivial resources. It changes execution only, never pipeline logic.

Two Flow-backend behaviours (from `flow-api`) must be handled first — these are
the actual FLOW-700 outcomes:

### Nextflow version (blocker)

Flow's default is `DEFAULT_NEXTFLOW_VERSION = 23.04.3`, which **cannot compile**
`main.nf` (`String too long`; see below). Set the pipeline version's
`allowed_nextflow_versions` (or the global `NextflowVersion` table) to a **26.x**
release, or the run fails before any process starts.

### Output flattening / collisions (the core finding)

Flow appends a generated `publish.config` **last** (highest precedence) that
forces `publishDir` for every process to a flat
`flow-results/<process_name>/`, and a `withName` publishDir in a later config
**replaces** a module's body `publishDir` (verified). So on a normal run:

- MerXen's nested `${outdir}/<pair_id>/<platform>/<stage>/` tree is **not**
  produced — everything is captured flat, keyed only by process name.
- The `pair_id` / `platform` / `segmentation` context is lost from the paths,
  so parallel tasks of the same process **collide**: both platforms'
  `BUILD_SPATIALDATA` publish `spatialdata_out/source_spatialdata.zarr`, every
  `QC` task publishes `qc_out/`, etc., all into the same `flow-results/<proc>/`.

MerXen relies on its nested `publishDir` paths to disambiguate outputs; Flow's
forced flat publishing collapses them. This is the compatibility gap FLOW-700
set out to find. The backend does have an escape hatch: pipelines registered
with **"imports samples" = true** get an *empty* `publish.config` (native
publishing), which lets MerXen's own nested `publishDir` directives take effect.
That is the most promising next thing to try — register the pipeline with
"imports samples" checked and confirm the nested tree and per-pair/platform
disambiguation survive.

Directory outputs themselves are supported: the backend records
`is_directory` from the filesystem snapshot and derives `filetype` from the
file extension (so a `.zarr` directory registers as a directory with filetype
`zarr`). `flow/flow.config` has the lowest precedence (config_paths are applied
before deployment configs and `publish.config`), so it only sets keys the
deployment leaves unset (container, GPU params, queue, resources) and cannot
influence `publishDir`.

### Minimal first run

Isolate directory handling from reference data with `stop_stage=enrich` and
`mecr_enabled=false`: build → segment → enrich needs only the raw
MERSCOPE/Xenium directory inputs and emits `.zarr`/`*_out` directories. Then add
the reference `data` inputs, push `stop_stage` to `clustering_squidpy`, and
finally enable the opt-in stages.

The uploaded directory must have the structure `BUILD_SPATIALDATA` checks (see
"Input access is verified" above), or the run fails there **by design** — that
failure is the signal that Flow either didn't mount the path or delivered the
wrong structure. Use `test/inputs/merscope/EX01` and `test/inputs/xenium/EX01`
as correctly-structured dummy directories to upload. A single-platform
(`analysis_mode=xenium`) run needs just the one Xenium directory.

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
