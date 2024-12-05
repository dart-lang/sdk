# Tests for Dart dynamic modules

This folder contains tests for an experiment of implementing dynamic modules in
Dart. All tests are written in the style of the language end-to-end tests.

## Folder structure
Each folder consists of a single test scenario. You'll find 4 kinds of files:
   * `main.dart`: the host application that will later load dynamic modules.
     This will be the core driver of the test.

   * `shared/`: folder containing multiple libraries with code that can be used
     by both the host application and dynamic modules.

   * `modules/`: folder containing code private to dynamic modules. It includes
     libraries with common code as well as an entrypoint file per dynamic
     module. Entrypoint files are named `entryN.dart` and must define an
     exported dynamic module entrypoint. Note: semantics limit that two
     dynamic modules can't share code unless they are compiled in a chained
     fashion, currently the test harness focuses on compiling modules in
     isolation and ensuring conflicts don't arise.

   * `dynamic_interface.yaml`: a contract specifying what parts of the host
     application and libraries in `shared/` are visible to dynamic modules.

## Execution

We've build a test framework that frontloads compilation, so that execution of
the test can be streamlined. This means that:
* The host app will be compiled first, using `dynamic_interface.yaml` as a
  specification for AOT compilers.

* Each and every dynamic module entrypoint in `modules/` will be compiled to
  create a dynamic module artifact.

* Finally an execution environment will be launched that will in turn load each
  dynamic module as prompted by the test logic.

Commands to drive the loading and execution of each dynamic module are
controlled by a helper library in `../common/testing.dart`, which
uses the Dart SDK API and abstracts away differences between platforms.

## Example

Refer to `update_top_level`. This is one of the simplest tests that illustrates
the utilities and concepts in this framework.
