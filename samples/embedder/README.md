# Dart VM Embedding examples

Examples of using Dart VM and executing Dart code from C++ binaries.

All examples can run either AOT or Kernel snapshots, depending on
which shared library variant they depend on.

Since snapshot file formats are unstable, the `dart` binary needs to
be of a matching version. The simplest way to ensure this is to build
Dart SDK from the same checkout, see [Building Dart
SDK](https://github.com/dart-lang/sdk/blob/main/docs/Building.md#building).

## `run_main.cc`

This is the simplest example, which just calls a `main` function from a given AOT/Kernel
snapshot. It does not handle isolate messages, so it cannot run Dart
programs with async functions.

To run the example with a Kernel snapshot:

```sh
./tools/build.py --mode=release samples/embedder:run_main_kernel && \
  out/ReleaseX64/run_main_kernel out/ReleaseX64/gen/hello_kernel.dart.snapshot.
```

To run the example with an AOT snapshot:

```sh
./tools/build.py --mode=release samples/embedder:run_main_aot && \
  out/ReleaseX64/run_main_aot out/ReleaseX64/hello_aot.snapshot.
```

## `run_two_programs.cc`

This example calls a function from one Dart snapshot and then passes
the returned string to another Dart snapshot.

## `run_timer.cc`

Demonstrates running an isolate event loop in a separate thread.

## `run_timer_async.cc`

Demonstrates a custom message scheduler using `std::async`.
