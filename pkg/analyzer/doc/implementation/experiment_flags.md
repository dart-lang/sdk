# Experiment flags

If you're implementing a language feature, then it needs to have an accompanying
experiment flag. (Or multiple experiments if it's going to be enabled over the
course of multiple releases.)

## Adding an experiment flag

Experiment flags are shared across all of the tools, so they are defined in a
single location. To add a new flag, edit
[`experimental_features.yaml`](https://github.com/dart-lang/sdk/blob/main/tools/experimental_features.yaml).
The initial commit is only required to define the name and to include a `help:`
key.

To generate the declarations used by the analyzer, run
`dart pkg/analyzer/tool/experiments/generate.dart`.

To generate the declarations used by the front-end, run
`dart pkg/front_end/tool/fasta.dart generate-experimental-flags`.

## Summary representation

The set of (the indexes of) enabled experiments is used to build the hash for
[summary files](summaries.md). If defining the new experiment flag changes the
indexes of existing experiment flags, then the value of the static field
`AnalysisDriver.DATA_VERSION` needs to be incremented.