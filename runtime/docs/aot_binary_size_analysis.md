# AOT code size analysis

The Dart VM's AOT compiler has support for emitting binary size information
for all the code that gets generated. This information can then be visualized.

## Telling the AOT compiler to generate binary size information

Our AOT compiler accepts an extra `--print-instructions-sizes-to=sizes.json`
flag. If supplied the AOT compiler will emit binary size information for all
generated functions to `sizes.json`.

This flag can be passed to `gen_snapshot` directly, or to the various wrapper
scripts (e.g. `pkg/vm/tool/precompiler2`):

```
% tools/build.py -mrelease -ax64 runtime_kernel dart_precompiled_runtime
% pkg/vm/tool/precompiler2 --print-instructions-sizes-to=hello_sizes.json hello.dart hello.dart.aot
```

In Flutter, pass this argument to `flutter build`:

```
% flutter build aot --release --extra-gen-snapshot-options=--print-instructions-sizes-to=hello_sizes.json
```

## Visualizing the information from the binary size json file

To visualize the information emitted by the AOT compiler one can use our binary
size analysis tool:

```
% dart pkg/vm/bin/snapshot_analysis.dart treemap hello_sizes.json hello_sizes
Generated file:///.../sdk/hello_sizes/index.html
% chrome hello_sizes/index.html
```


## Comparing the sizes of two AOT builds

To visualize the differences between two AOT builds one can use our binary size
comparison tool:

```
% dart pkg/vm/bin/snapshot_analysis.dart compare app-sizes--before.json app-sizes--after.json

+---------+--------+--------------+
| Library | Method | Diff (Bytes) |
+---------+--------+--------------+
...
```

## Object-level data

gen_snapshot also accepts an extra `--write-v8-snapshot-profile-to=hello.heapsnapshot`
flag. If supplied the AOT compiler will emit snapshot size information for all objects in the snapshot
to `hello.heapsnapshot` in V8 snapshot format.

This flag can be passed to `gen_snapshot` directly, or to the various wrapper
scripts (e.g. `pkg/vm/tool/precompiler2`):

```
% tools/build.py -mrelease -ax64 runtime_kernel dart_precompiled_runtime
% pkg/vm/tool/precompiler2 --write-v8-snapshot-profile-to=hello.heapsnapshot hello.dart hello.dart.aot
```

In Flutter, pass this argument to `flutter build`:

```
% flutter build aot --release --extra-gen-snapshot-options=--write-v8-snapshot-profile-to=hello.heapsnapshot
```

This output can be visualized by loading it in the "Memory" tab in Chrome's developer tools, or by loading it into [Graph Explorer](../tools/graphexplorer/graphexplorer.html).
