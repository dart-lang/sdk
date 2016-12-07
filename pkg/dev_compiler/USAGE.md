# Usage

The [Dart Dev Compiler](README.md) (DDC) is an **experimental**
development compiler from Dart to EcmaScript 6.  It is
still incomplete, under heavy development, and not yet ready for
production use.

With those caveats, we welcome feedback for those experimenting.

The easiest way to compile and run DDC generated code for now is via NodeJS.  The following instructions are in a state of flux - please expect them to change.  If you find issues, please let us know.

(1) Clone the [DDC repository](https://github.com/dart-lang/dev_compiler) and set the environment variable DDC_PATH to your checkout.

(2) Install nodejs v6.0 or later and add it to your path.  It can be installed from:

https://nodejs.org/

Note, v6 or later is required for harmony / ES6 support.

(3) Create a node compatible version of the dart_sdk:

```
dart $DDC_PATH/tool/build_sdk.dart --dart-sdk $DDC_PATH/gen/patched_sdk/ --modules node -o dart_sdk.js
```

You can ignore any errors or warnings for now.

(4) Define a node path (you can add other directories if you want to separate things out):

```
export NODE_PATH=.
```

(5) Compile a test file with a `main` entry point:

```
dart  $DDC_PATH/bin/dartdevc.dart --modules node -o hello.js hello.dart
```

Note, the `hello.js` built here is not fully linked.  It loads the SDK via a `require` call.

(6) Run it via your node built in step 1:

```
node -e 'require("hello").hello.main()'
```

(7) Compile multiple libraries using summaries.  E.g., write a `world.dart` that imports `hello.dart` with it's own `main`.  Step 5 above generated a summary (`hello.sum`) for `hello.dart`.  Build world:

```
dart $DDC_PATH/bin/dartdevc.dart --modules node -s hello.sum -o world.js world.dart
```

Run world just like hello above:

```
node -e 'require("world").world.main()'
```

(8) Node modules do not run directly on the browser or v8.  You can use a tool like `browserify` to build a linked javascript file that can:

Install:
```
sudo npm install -g browserify
```

and run, e.g.,:
```
echo 'require("world").world.main()' | browserify -d - > world.dart.js
```

The produced `world.dart.js` fully links all dependencies (`dart_sdk`, `hello`, and `world`) and executes `world.main`.  It can be loaded via script tag and run in Chrome (stable or later).

## Feedback

Please file issues in our [GitHub issue tracker](https://github.com/dart-lang/sdk/issues).

You can also view or join our [mailing list](https://groups.google.com/a/dartlang.org/forum/#!forum/dev-compiler).



