# Usage

**This document is out-of-date.  We'll be updating it shortly.**

The [Dart Dev Compiler](README.md) (DDC) is an **experimental**
development tool and transpiler.  In particular, the ES6 backend is
still incomplete, under heavy development, and not yet ready for
production use.

With those caveats, we welcome feedback.  

## Installation

You can install DDC via pub:

    $ pub global activate dev_compiler
    
The above will install a `dartdevc` executable.  To update to the
latest DDC, you can just re-run this step.

## Running the static checker

By default, DDC runs in static checking mode.  The DDC checker is strictly stronger than the standard Dart
analyzer: it reports extra errors and warnings.  For example, given the following `main.dart`:

```dart
void main() {
  List<String> list = ["hello", "world"];

  for (var item in list) {
    print(item + 42);
  }
}
```

the Dart analyzer will not report a static error or warning even
though the program will clearly fail (in checked mode).  Running with --strong
mode:

    $ dartanalyzer --strong main.dart

will display a severe error.  Modifying `42` to `'42'` will
correct the error.

## Generating ES6

For code that statically type checks, DDC can be used to generate EcmaScript 6 (ES6) code:

    $ dartdevc -o out/main.js lib1.dart main.dart

The generated output will be in 'out/main.js'.  DDC generates one ES6
file per module.  It is a modular compiler: the whole program is not
necessary, but you may need to pass in summaries from other modules using `-s`.

## Feedback

Please file issues in our [GitHub issue tracker](https://github.com/dart-lang/dev_compiler/issues).

You can also view or join our [mailing list](https://groups.google.com/a/dartlang.org/forum/#!forum/dev-compiler).



