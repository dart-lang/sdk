# Web commands of `dart`

The implementation of two `dart` commands for web apps:

- `dart serve`: serves a Dart web app over HTTP.
- `dart build web` (planned): compiles a Dart web app with any of the web
  compilers (DDC, dart2js, dart2wasm).

Serving and compiling are kept in separate classes. `dart serve` will call the
same compile step as `dart build web`, then serve the result, so it can serve
development and release builds alike.

It is part of dartdev, so it is compiled into the dartdev snapshot. Code
that both commands use is at the root of `lib/src/web/`; `serve/` (and
later `build/`) hold what each command needs. Tests mirror this in
`test/web/`.

## How `dart serve` works today

1. **Project** (`WebProject`): finds the package root, its
   `package_config.json`, the `web/` directory and the app's entrypoint
   (`web/main.dart` by default).
2. **Compiler**: compiles the app with the frontend server (through
   `package:frontend_server_client`) to JavaScript in DDC's library bundle
   format, and keeps the output in memory. This step moves behind
   `dart build web` once that command exists.
3. **Server**: serves the files in `web/`, the compiled JavaScript, and the
   scripts that start the app.

There is no debugging, hot reload or hot restart yet.

## Try it

`test/web/fixtures/hello_web` is a minimal web app (the one the tests use). With an SDK
built from this checkout:

```
cd pkg/dartdev/test/web/fixtures/hello_web
dart pub get
dart experimental-serve
```

The command is called `experimental-serve` until the feature is ready; it
will then become `dart serve`.

Open the printed URL: the page title changes from "loading" to "hello" once
`main()` runs.
