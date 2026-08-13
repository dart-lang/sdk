# Setting VM flags in standalone executables

Dart VM flags and options can be provided to any executable generated using `dart compile exe` via the `DART_VM_OPTIONS` environment variable.

`DART_VM_OPTIONS` should be set to a list of comma-separated flags and options with no whitespace. Options that allow for multiple values to be provided as comma-separated values are not supported (e.g., `--timeline-streams=Dart,GC,Compiler`).

Example of a valid `DART_VM_OPTIONS` environment variable:

    DART_VM_OPTIONS=--random_seed=42,--verbose_gc
