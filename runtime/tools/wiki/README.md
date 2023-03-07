This directory contains helper scripts for rendering runtime wiki pages as HTML.

```shell
# Run webserver for development.
$ runtime/tools/wiki/build/build.py

# Build wiki for deployment
$ runtime/tools/wiki/build/build.py --deploy
```

# Markdown extensions

## Admonitions and Asides

Blockquotes starting with `> **Marker**` are converted either:

- into sidenotes (if `Marker` is `Note`), which will be rendered on margins
of the page;
- admonitions (if `Marker` is `Source to read`, `Trying it` or `Warning`).

## Referencing C++ symbols and files

Script extends Markdown references with special support for references that
use ``[`ref`][]`` and ``[text][`ref`]``. The following values for `ref` are
recognized and resolved as links to GitHub at the current commit.

* `file-path` is resolved as a link to the given file;
* `package:name/path.dart` is resolved as a link to file `path.dart` within
package `name` - actual path is resolved via `.dart_tool/package_config.json`
file in the SDK root;
* `c++ symbol` is resolved as a link to the line in the file which defines
the given C++ symbol.

If markdown file contains any references in this form then running
`runtime/tools/wiki/build/build.py --deploy` will generate a reference
section at the end of the file. Appending this section allows other Markdown
tools (e.g. GitHub viewer) to render such special links correctly.

# Prerequisites

1. Install all Python dependencies.
    ```console
    $ pip3 install coloredlogs jinja2 markdown aiohttp watchdog pymdown-extensions pygments
    ```
2. Install `libclang` (`brew install llvm` on Mac OS X).
3. Install SASS compiler (make sure that SASS binary is in your path).
