# Dart VM Embedding examples

Examples of using Dart VM and executing Dart code from C++ binaries.

## run_kernel.cc

To run the example:

```sh
./tools/build.py --no-rbe --mode=release samples/embedder:run_kernel && out/ReleaseX64/run_kernel
```

The example initializes Dart VM, creates an isolate from a kernel file (by
default it uses kernel-compiled `hello.dart`), launches its `main` function with
args and exits.

You can also compile your own Dart kernel like this:

```sh
dart compile kernel --no-link-platform my.dart
out/ReleaseX64/run_kernel my.dill
```

Since the kernel file format is unstable, the `dart` binary needs to be of a
matching version. The simplest way to ensure this is to build Dart SDK from the
same checkout, see
[Building Dart SDK](https://github.com/dart-lang/sdk/blob/main/docs/Building.md#building).
