# Calculator example

This simple command-line calculator example illustrates how to use Dart Dynamic
Modules. Please refer to the package [readme](../README.md) for details about
what Dynamic Modules are, their limitations, typical steps to use them, and how
this example maps to those steps.

The code in this folder is a simple calculator command line interface that lets
users extend it with new operations beyond those built-in.

We recommend exploring the example in this order:
* Check out `dynamic_interface.yaml` and `common/common.dart`. These define the
  API surface area. That is, the interface exposed to dynamic modules to define
  new operations, as well as the API to register them.
* Then, see `host/main.dart`. This defines the main REPL and provides one
  built-in operation (the addition operation).
* Then, check the files under the `modules/` subfolder. Each file defines a
  dynamic module that provides new operations for the calculator following the
  API surface area defined earlier.
* Finally look at the `run.sh` script to see how the pieces come together.


The `run.sh` script contains a lot of steps and details:
* First, it shows how to build Dart SDK artifacts with support for Dart Dynamic
  Modules once you have a proper Dart SDK checkout. A change with how we
  normally build Dart is the use of the `--dart-dynamic-modules` build flag.

* Second, it shows how to use the dynamic interface to build various artifacts:
  * The unoptimized kernel of the app: an input needed later when compiling
    bytecode.
  * The optimized AOT kernel of the app: an input to the next step.
  * The optimized AOT snapshot of the app: the app that we will be running.
  * The bytecode for each dynamic module.

Traditionally compilation of an AOT app is done in a single command (e.g. `dart
compile exe`), but we had to split the underlying logic into multiple steps
(building kernel and snapshots separately). In part, this is because we haven't
added the plumbing to provide the dynamic interface through the regular
commands. But another reason is that we need additional artifacts to anchor the
compilation of dynamic modules later (like the unoptimized kernel), which are
not usually materialized when using the regular commands.

Bytecode files are copied over to a data directory, this is an over simplistic
way to represent the delivery of a dynamic module to an app (rather than using
the network or some other mechanism).

We haven't implemented provenance validation in the package yet, so the
validation step described in the documentation is not represented in the example
yet. We will update it in the future once the corresponding API is added.
