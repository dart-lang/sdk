This directory contains helper scripts for rendering runtime wiki pages as HTML.

```shell
# Run webserver for development.
$ runtime/tools/wiki/build/build.py

# Build wiki for deployment
$ runtime/tools/wiki/build/build.py --deploy
```

# Markdown extensions

## Asides

Paragraphs wrapped into `<aside>...</aside>` will be rendered as a sidenote on
margins of the page.

## Cross-references `@{ref|text}`

Cross-references are rendered as links to GitHub at the current commit.

* `@{file-path}` is just rendered a link to the given file;
* `@{package:name/path.dart}` is rendered as a link to file `path.dart` within
package `name` - actual path is resolved via root `.packages` file in the SDK
root;
* `@{c++-symbol}` is rendered as a link to the line in the file which defines
the given C++ symbol.

# Prerequisites

1. Install all Python dependencies.
    ```console
    $ pip3 install coloredlogs jinja2 markdown aiohttp watchdog pymdown-extensions pygments
    ```
2. Install the custom pygments lexer we use for shell session examples:
    ```
    $ cd runtime/tools/wiki/CustomShellSessionPygmentsLexer
    $ python3 setup.py develop
    ```
3. Install SASS compiler (make sure that SASS binary is in your path).
4. Generate `xref.json` file following instructions in
`xref_extractor/README.md`.