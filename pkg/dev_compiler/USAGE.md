# Usage

The [Dart Dev Compiler](README.md) (DDC) is an **experimental** development
compiler from Dart to EcmaScript 6. It is still incomplete, under heavy
development, and not yet ready for production use.

With those caveats, we welcome feedback for those experimenting.

The easiest way to compile and run DDC generated code for now is via NodeJS.
The following instructions are in a state of flux -- please expect them to
change. If you find issues, please let us know.

1.  Follow the [Getting the Source](https://github.com/dart-lang/sdk/wiki/Building#getting-the-source) steps, and
    set the environment variable `DDC_PATH` to the `pkg/dev_compiler`
    subdirectory within wherever you check that out.

2.  Install nodejs v6.0 or later and add it to your path. It can be installed
    from:

    https://nodejs.org/

    Note, v6 or later is required for harmony / ES6 support.

3.  Define a node path (you can add other directories if you want to separate
    things out):

    ```sh
    export NODE_PATH=$DDC_PATH/lib/js/common:.
    ```

4.  Compile a test file with a `main` entry point:

    ```sh
    dart $DDC_PATH/bin/dartdevc.dart --modules node -o hello.js hello.dart
    ```

    Note, the `hello.js` built here is not fully linked. It loads the SDK via a `require` call.

5.  Run it via your node built in step 1:

    ```sh
    node -e 'require("hello").hello.main()'
    ```

6.  Compile multiple libraries using summaries. E.g., write a `world.dart` that
    imports `hello.dart` with it's own `main`. Step 5 above generated a summary
    (`hello.sum`) for `hello.dart`. Build world:

    ```sh
    dart $DDC_PATH/bin/dartdevc.dart --modules node -s hello.sum -o world.js world.dart
    ```

    Run world just like hello above:

    ```sh
    node -e 'require("world").world.main()'
    ```

7.  Node modules do not run directly on the browser or v8. You can use a tool
    like `browserify` to build a linked javascript file that can:

    Install:

    ```sh
    sudo npm install -g browserify
    ```

    and run, e.g.,:

    ```sh
    echo 'require("world").world.main()' | browserify -d - > world.dart.js
    ```

    The produced `world.dart.js` fully links all dependencies (`dart_sdk`,
    `hello`, and `world`) and executes `world.main`.  It can be loaded via
    script tag and run in Chrome (stable or later).

## Feedback

Please file issues in our [GitHub issue
tracker](https://github.com/dart-lang/sdk/issues).
