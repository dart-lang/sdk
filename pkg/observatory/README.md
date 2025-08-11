# Observatory Developer Tooling

_**WARNING: This tooling is deprecated and maintained on a best-effort basis by members of the Dart VM team.**_

## Activating Observatory

To easily serve Observatory without having to manually run `webdev serve` in this project, Observatory can be activated as a
global `pub` package and run via the `observatory` tool.

To do this, run `dart bin/activate.dart`, which will create the `observatory` script at `$PUB_CACHE/bin`.

**Note:** If any changes are made to `bin/observatory.dart`, `dart bin/activate.dart` must be re-run to pick up the changes.

## Serving Observatory

To serve Observatory, simply run the `observatory` command. To automatically launch Observatory in Chrome, provide the `--launch`
flag.

## Developing Observatory

When making changes to Observatory, run `observatory --debug` to run Observatory with DDC. This will allow for a more typical
web development workflow as changes to the Observatory sources will be picked up automatically on a page refresh.

## Code Reviews

The development workflow of Dart (and Observatory) is based on code reviews.

Follow the code review [instructions][code_review] to be able to successfully
submit your code.

The main reviewers for Observatory related CLs are:

- aam
- rmacnak

[code_review]: https://github.com/dart-lang/sdk/blob/main/docs/Code-review-workflow-with-GitHub-and-Gerrit.md "Code Review"
