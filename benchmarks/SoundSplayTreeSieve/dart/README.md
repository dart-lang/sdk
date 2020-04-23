# SoundSplayTreeSieve
The SoundSplayTreeSieve benchmark reports the runtime of the `sieve9` Golem benchmark
for a `SplayTreeSet` from `dart:collection` and a `SoundSplayTreeSet` that
declares variance modifiers for its type parameters.

## Running the benchmark
These are instructions for running the benchmark, assuming you are in the `sdk`
directory.

These benchmarks print a result similar to this (with varying runtimes):
```
CollectionSieves-SplayTreeSet-removeLoop(RunTime): 4307.52688172043 us.
CollectionSieves-SoundSplayTreeSet-removeLoop(RunTime): 4344.902386117137 us.
```

**Dart2JS**
```
$ sdk/bin/dart2js_developer benchmarks/SoundSplayTreeSieve/dart/SoundSplayTreeSieve.dart --enable-experiment=variance --experiment-new-rti --out=soundsplay_d2js.js
$ third_party/d8/linux/d8 soundsplay_d2js.js
```

**Dart2JS (Omit implicit checks)**
```
$ sdk/bin/dart2js_developer benchmarks/SoundSplayTreeSieve/dart/SoundSplayTreeSieve.dart --enable-experiment=variance --experiment-new-rti --omit-implicit-checks --out=soundsplay_d2js_omit.js --lax-runtime-type-to-string
$ third_party/d8/linux/d8 soundsplay_d2js_omit.js
```

**DDK**
```
$ pkg/dev_compiler/tool/ddb -d -r chrome --enable-experiment=variance -k benchmarks/SoundSplayTreeSieve/dart/SoundSplayTreeSieve.dart
```