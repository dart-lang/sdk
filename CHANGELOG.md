## 1.13.0

* `dart:core`
  * `Uri` added `removeFragment` method.
  * `String.allMatches` (implementing `Pattern.allMatches`) is now lazy,
    as all `allMatches` implementations are intended to be.

* `dart:io`
  * `HttpClient` no longer sends URI fragments in the request. This is not
    allowed by the HTTP protocol.
    The `HttpServer` still gracefully receives fragments, but discards them
    before delivering the request.

* `dart:async`
  * `StreamTransformer`s created with `fromHandlers` with no `handleError`
    callback now forward stack traces along with errors to the resulting
    streams.

## 1.12.0

### Language changes

* Null-aware operators
    * `??`: if null operator. `expr1 ?? expr2` evaluates to `expr1` if not `null`, otherwise `expr2`.
    * `??=`: null-aware assignment. `v ??= expr` causes `v` to be assigned `expr` only if `v` is `null`.
    * `x?.p`: null-aware access. `x?.p` evaluates to `x.p` if `x` is not `null`, otherwise evaluates to `null`.
    * `x?.m()`: null-aware method invocation. `x?.m()` invokes `m` only if `x` is not `null`.

### Core library changes

* `dart:async`
  * `StreamController` added setters for the `onListen`, `onPause`, `onResume`
    and `onCancel` callbacks.

* `dart:convert`
  * `LineSplitter` added a `split` static method returning an `Iterable`.

* `dart:core`
  * `Uri` class now perform path normalization when a URI is created.
    This removes most `..` and `.` sequences from the URI path.
    Purely relative paths (no scheme or authority) are allowed to retain
    some leading "dot" segments.
    Also added `hasAbsolutePath`, `hasEmptyPath`, and `hasScheme` properties.

* `dart:developer`
  * New `log` function to transmit logging events to Observatory.

* `dart:html`
  * `NodeTreeSanitizer` added the `const trusted` field. It can be used
    instead of defining a `NullTreeSanitizer` class when calling
    `setInnerHtml` or other methods that create DOM from text. It is
    also more efficient, skipping the creation of a `DocumentFragment`.

* `dart:io`
  * Added two new file modes, `WRITE_ONLY` and `WRITE_ONLY_APPEND` for
    opening a file write only.
    [eaeecf2](https://github.com/dart-lang/sdk/commit/eaeecf2ed13ba6c7fbfd653c3c592974a7120960)
  * Change stdout/stderr to binary mode on Windows.
    [4205b29](https://github.com/dart-lang/sdk/commit/4205b2997e01f2cea8e2f44c6f46ed6259ab7277)

* `dart:isolate`
  * Added `onError`, `onExit` and `errorsAreFatal` parameters to
    `Isolate.spawnUri`.

* `dart:mirrors`
  * `InstanceMirror.delegate` moved up to `ObjectMirror`.
  * Fix InstanceMirror.getField optimization when the selector is an operator.
  * Fix reflective NoSuchMethodErrors to match their non-reflective
    counterparts when due to argument mismatches. (VM only)

### Tool changes

* Documentation tools

  * `dartdoc` is now the default tool to generate static HTML for API docs.
    [Learn more](https://pub.dartlang.org/packages/dartdoc).

  * `docgen` and `dartdocgen` have been deprecated. Currently plan is to remove
    them in 1.13.

* Formatter (`dartfmt`)

  * Over 50 bugs fixed.

  * Optimized line splitter is much faster and produces better output on
    complex code.

* Observatory
  * Allocation profiling.

  * New feature to display output from logging.

  * Heap snapshot analysis works for 64-bit VMs.

  * Improved ability to inspect typed data, regex and compiled code.

  * Ability to break on all or uncaught exceptions from Observatory's debugger.

  * Ability to set closure-specific breakpoints.

  * 'anext' - step past await/yield.

  * Preserve when a variable has been expanded/unexpanded in the debugger.

  * Keep focus on debugger input box whenever possible.

  * Echo stdout/stderr in the Observatory debugger.  Standalone-only so far.

  * Minor fixes to service protocol documentation.

* Pub

  * **Breaking:** various commands that previously ran `pub get` implicitly no
    longer do so. Instead, they merely check to make sure the ".packages" file
    is newer than the pubspec and the lock file, and fail if it's not.

  * Added support for `--verbosity=error` and `--verbosity=warning`.

  * `pub serve` now collapses multiple GET requests into a single line of
    output. For full output, use `--verbose`.

  * `pub deps` has improved formatting for circular dependencies on the
    entrypoint package.

  * `pub run` and `pub global run`

    * **Breaking:** to match the behavior of the Dart VM, executables no longer
      run in checked mode by default. A `--checked` flag has been added to run
      them in checked mode manually.

    * Faster start time for executables that don't import transformed code.

    * Binstubs for globally-activated executables are now written in the system
      encoding, rather than always in `UTF-8`. To update existing executables,
      run `pub cache repair`.

  * `pub get` and `pub upgrade`

    * Pub will now generate a ".packages" file in addition to the "packages"
      directory when running `pub get` or similar operations, per the
      [package spec proposal][]. Pub now has a `--no-package-symlinks` flag that
      will stop "packages" directories from being generated at all.

    * An issue where HTTP requests were sometimes made even though `--offline`
      was passed has been fixed.

    * A bug with `--offline` that caused an unhelpful error message has been
      fixed.

    * Pub will no longer time out when a package takes a long time to download.

  * `pub publish`

    * Pub will emit a non-zero exit code when it finds a violation while
      publishing.

    * `.gitignore` files will be respected even if the package isn't at the top
      level of the Git repository.

  * Barback integration

    * A crashing bug involving transformers that only apply to non-public code
      has been fixed.

    * A deadlock caused by declaring transformer followed by a lazy transformer
      (such as the built-in `$dart2js` transformer) has been fixed.

    * A stack overflow caused by a transformer being run multiple times on the
      package that defines it has been fixed.

    * A transformer that tries to read a non-existent asset in another package
      will now be re-run if that asset is later created.

[package spec proposal]: https://github.com/lrhn/dep-pkgspec

### VM Service Protocol Changes

* **BREAKING** The service protocol now sends JSON-RPC 2.0-compatible
  server-to-client events. To reflect this, the service protocol version is
  now 2.0.

* The service protocol now includes a `"jsonrpc"` property in its responses, as
  opposed to `"json-rpc"`.

* The service protocol now properly handles requests with non-string ids.
  Numeric ids are no longer converted to strings, and null ids now don't produce
  a response.

* Some RPCs that didn't include a `"jsonrpc"` property in their responses now
  include one.

## 1.11.2

### Core library changes

* Fix a bug where `WebSocket.close()` would crash if called after
  `WebSocket.cancel()`.

## 1.11.1

### Tool changes

* Pub will always load Dart SDK assets from the SDK whose `pub` executable was
  run, even if a `DART_SDK` environment variable is set.

## 1.11.0 - 2015-06-25

### Core library changes

* `dart:core`
  * `Iterable` added an `empty` constructor.
    [dcf0286](https://github.com/dart-lang/sdk/commit/dcf0286f5385187a68ce9e66318d3bf19abf454b)
  * `Iterable` can now be extended directly. An alternative to extending
    `IterableBase` from `dart:collection`.
  * `List` added an `unmodifiable` constructor.
    [r45334](https://code.google.com/p/dart/source/detail?r=45334)
  * `Map` added an `unmodifiable` constructor.
    [r45733](https://code.google.com/p/dart/source/detail?r=45733)
  * `int` added a `gcd` method.
    [a192ef4](https://github.com/dart-lang/sdk/commit/a192ef4acb95fad1aad1887f59eed071eb5e8201)
  * `int` added a `modInverse` method.
    [f6f338c](https://github.com/dart-lang/sdk/commit/f6f338ce67eb8801b350417baacf6d3681b26002)
  * `StackTrace` added a `fromString` constructor.
    [68dd6f6](https://github.com/dart-lang/sdk/commit/68dd6f6338e63d0465041d662e778369c02c2ce6)
  * `Uri` added a `directory` constructor.
    [d8dbb4a](https://github.com/dart-lang/sdk/commit/d8dbb4a60f5e8a7f874c2a4fbf59eaf1a39f4776)
  * List iterators may not throw `ConcurrentModificationError` as eagerly in
    release mode. In checked mode, the modification check is still as eager
    as possible.
    [r45198](https://github.com/dart-lang/sdk/commit/5a79c03)

* `dart:developer` - **NEW**
  * Replaces the deprecated `dart:profiler` library.
  * Adds new functions `debugger` and `inspect`.
    [6e42aec](https://github.com/dart-lang/sdk/blob/6e42aec4f64cf356dde7bad9426e07e0ea5b58d5/sdk/lib/developer/developer.dart)

* `dart:io`
  * `FileSystemEntity` added a `uri` property.
    [8cf32dc](https://github.com/dart-lang/sdk/commit/8cf32dc1a1664b516e57f804524e46e55fae88b2)
  * `Platform` added a `static resolvedExecutable` property.
    [c05c8c6](https://github.com/dart-lang/sdk/commit/c05c8c66069db91cc2fd48691dfc406c818d411d)

* `dart:html`
  * `Element` methods, `appendHtml` and `insertAdjacentHtml` now take `nodeValidator`
    and `treeSanitizer` parameters, and the inputs are consistently
    sanitized.
    [r45818 announcement](https://groups.google.com/a/dartlang.org/forum/#!topic/announce/GVO7EAcPi6A)

* `dart:isolate`
  * **BREAKING** The positional `priority` parameter of `Isolate.ping` and `Isolate.kill` is
    now a named parameter named `priority`.
  * **BREAKING** Removed the `Isolate.AS_EVENT` priority.
  * `Isolate` methods `ping` and `addOnExitListener` now have a named parameter
    `response`.
    [r45092](https://github.com/dart-lang/sdk/commit/1b208bd)
  * `Isolate.spawnUri` added a named argument `checked`.
  * Remove the experimental state of the API.

* `dart:profiler` - **DEPRECATED**
  * This library will be removed in 1.12. Use `dart:developer` instead.

### Tool changes

* This is the first release that does not include the Eclipse-based
  **Dart Editor**.
  See [dartlang.org/tools](https://www.dartlang.org/tools/) for alternatives.
* This is the last release that ships the (unsupported)
  dart2dart (aka `dart2js --output-type=dart`) utility as part
  of dart2js

## 1.10.0 – 2015-04-29

### Core library changes

* `dart:convert`
  * **POTENTIALLY BREAKING** Fix behavior of `HtmlEscape`. It no longer escapes
  no-break space (U+00A0) anywhere or forward slash (`/`, `U+002F`) in element
  context. Slash is still escaped using `HtmlEscapeMode.UNKNOWN`.
  [r45003](https://github.com/dart-lang/sdk/commit/8b8223d),
  [r45153](https://github.com/dart-lang/sdk/commit/8a5d049),
  [r45189](https://github.com/dart-lang/sdk/commit/3c39ad2)

* `dart:core`
  * `Uri.parse` added `start` and `end` positional arguments.

* `dart:html`
  * **POTENTIALLY BREAKING** `CssClassSet` method arguments must now be 'tokens', i.e. non-empty
  strings with no white-space characters. The implementation was incorrect for
  class names containing spaces. The fix is to forbid spaces and provide a
  faster implementation.
  [Announcement](https://groups.google.com/a/dartlang.org/d/msg/announce/jmUI2XJHfC8/UZUCvJH3p2oJ)

* `dart:io`

  * `ProcessResult` now exposes a constructor.
  * `import` and `Isolate.spawnUri` now supports the
    [Data URI scheme](http://en.wikipedia.org/wiki/Data_URI_scheme) on the VM.

## Tool Changes

### pub

  * Running `pub run foo` within a package now runs the `foo` executable defined
    by the `foo` package. The previous behavior ran `bin/foo`. This makes it
    easy to run binaries in dependencies, for instance `pub run test`.

  * On Mac and Linux, signals sent to `pub run` and forwarded to the child
    command.

## 1.9.3 – 2015-04-14

This is a bug fix release which merges a number of commits from `bleeding_edge`.

* dart2js: Addresses as issue with minified Javascript output with CSP enabled -
  [r44453](https://code.google.com/p/dart/source/detail?r=44453)

* Editor: Fixes accidental updating of files in the pub cache during rename
  refactoring - [r44677](https://code.google.com/p/dart/source/detail?r=44677)

* Editor: Fix for
  [issue 23032](https://code.google.com/p/dart/issues/detail?id=23032)
  regarding skipped breakpoints on Windows -
  [r44824](https://code.google.com/p/dart/source/detail?r=44824)

* dart:mirrors: Fix `MethodMirror.source` when the method is on the first line
  in a script -
  [r44957](https://code.google.com/p/dart/source/detail?r=44957),
  [r44976](https://code.google.com/p/dart/source/detail?r=44976)

* pub: Fix for
  [issue 23084](https://code.google.com/p/dart/issues/detail?id=23084):
  Pub can fail to load transformers necessary for local development -
  [r44876](https://code.google.com/p/dart/source/detail?r=44876)

## 1.9.1 – 2015-03-25

### Language changes

* Support for `async`, `await`, `sync*`, `async*`, `yield`, `yield*`, and `await
  for`. See the [the language tour][async] for more details.

* Enum support is fully enabled. See [the language tour][enum] for more details.

[async]: https://www.dartlang.org/docs/dart-up-and-running/ch02.html#asynchrony
[enum]: https://www.dartlang.org/docs/dart-up-and-running/ch02.html#enums

### Tool changes

* The formatter is much more comprehensive and generates much more readable
  code. See [its tool page][dartfmt] for more details.

* The analysis server is integrated into the IntelliJ plugin and the Dart
  editor. This allows analysis to run out-of-process, so that interaction
  remains smooth even for large projects.

* Analysis supports more and better hints, including unused variables and unused
  private members.

[dartfmt]: https://www.dartlang.org/tools/dartfmt/

### Core library changes

#### Highlights

* There's a new model for shared server sockets with no need for a `Socket`
  reference.

* A new, much faster [regular expression engine][regexp].

* The Isolate API now works across the VM and `dart2js`.

[regexp]: http://news.dartlang.org/2015/02/irregexp-dart-vms-new-regexp.html

#### Details

For more information on any of these changes, see the corresponding
documentation on the [Dart API site](http://api.dartlang.org).

* `dart:async`:

  * `Future.wait` added a new named argument, `cleanUp`, which is a callback
    that releases resources allocated by a successful `Future`.

  * The `SynchronousStreamController` class was added as an explicit name for
    the type returned when the `sync` argument is passed to `new
    StreamController`.

* `dart:collection`: The `new SplayTreeSet.from(Iterable)` constructor was
  added.

* `dart:convert`: `Utf8Encoder.convert` and `Utf8Decoder.convert` added optional
  `start` and `end` arguments.

* `dart:core`:

  * `RangeError` added new static helper functions: `checkNotNegative`,
    `checkValidIndex`, `checkValidRange`, and `checkValueInInterval`.

  * `int` added the `modPow` function.

  * `String` added the `replaceFirstMapped` and `replaceRange` functions.

* `dart:io`:

  * Support for locking files to prevent concurrent modification was added. This
    includes the `File.lock`, `File.lockSync`, `File.unlock`, and
    `File.unlockSync` functions as well as the `FileLock` class.

  * Support for starting detached processes by passing the named `mode` argument
    (a `ProcessStartMode`) to `Process.start`. A process can be fully attached,
    fully detached, or detached except for its standard IO streams.

  * `HttpServer.bind` and `HttpServer.bindSecure` added the `v6Only` named
    argument. If this is true, only IPv6 connections will be accepted.

  * `HttpServer.bind`, `HttpServer.bindSecure`, `ServerSocket.bind`,
    `RawServerSocket.bind`, `SecureServerSocket.bind` and
    `RawSecureServerSocket.bind` added the `shared` named argument. If this is
    true, multiple servers or sockets in the same Dart process may bind to the
    same address, and incoming requests will automatically be distributed
    between them.

  * **Deprecation:** the experimental `ServerSocketReference` and
    `RawServerSocketReference` classes, as well as getters that returned them,
    are marked as deprecated. The `shared` named argument should be used
    instead. These will be removed in Dart 1.10.

  * `Socket.connect` and `RawSocket.connect` added the `sourceAddress` named
    argument, which specifies the local address to bind when making a
    connection.

  * The static `Process.killPid` method was added to kill a process with a given
    PID.

  * `Stdout` added the `nonBlocking` instance property, which returns a
    non-blocking `IOSink` that writes to standard output.

* `dart:isolate`:

  * The static getter `Isolate.current` was added.

  * The `Isolate` methods `addOnExitListener`, `removeOnExitListener`,
    `setErrorsFatal`, `addOnErrorListener`, and `removeOnErrorListener` now work
    on the VM.

  * Isolates spawned via `Isolate.spawn` now allow most objects, including
    top-level and static functions, to be sent between them.

## 1.8.5 – 2015-01-21

* Code generation for SIMD on ARM and ARM64 is fixed.

* A possible crash on MIPS with newer GCC toolchains has been prevented.

* A segfault when using `rethrow` was fixed ([issue 21795][]).

[issue 21795]: https://code.google.com/p/dart/issues/detail?id=21795

## 1.8.3 – 2014-12-10

* Breakpoints can be set in the Editor using file suffixes ([issue 21280][]).

* IPv6 addresses are properly handled by `HttpClient` in `dart:io`, fixing a
  crash in pub ([issue 21698][]).

* Issues with the experimental `async`/`await` syntax have been fixed.

* Issues with a set of number operations in the VM have been fixed.

* `ListBase` in `dart:collection` always returns an `Iterable` with the correct
  type argument.

[issue 21280]: https://code.google.com/p/dart/issues/detail?id=21280
[issue 21698]: https://code.google.com/p/dart/issues/detail?id=21698

## 1.8.0 – 2014-11-28

* `dart:collection`: `SplayTree` added the `toSet` function.

* `dart:convert`: The `JsonUtf8Encoder` class was added.

* `dart:core`:

  * The `IndexError` class was added for errors caused by an index being outside
    its expected range.

  * The `new RangeError.index` constructor was added. It forwards to `new
    IndexError`.

  * `RangeError` added three new properties. `invalidProperty` is the value that
    caused the error, and `start` and `end` are the minimum and maximum values
    that the value is allowed to assume.

  * `new RangeError.value` and `new RangeError.range` added an optional
    `message` argument.

  * The `new String.fromCharCodes` constructor added optional `start` and `end`
    arguments.

* `dart:io`:

  * Support was added for the [Application-Layer Protocol Negotiation][alpn]
    extension to the TLS protocol for both the client and server.

  * `SecureSocket.connect`, `SecureServerSocket.bind`,
    `RawSecureSocket.connect`, `RawSecureSocket.secure`,
    `RawSecureSocket.secureServer`, and `RawSecureServerSocket.bind` added a
    `supportedProtocols` named argument for protocol negotiation.

  * `RawSecureServerSocket` added a `supportedProtocols` field.

  * `RawSecureSocket` and `SecureSocket` added a `selectedProtocol` field which
    contains the protocol selected during protocol negotiation.

[alpn]: https://tools.ietf.org/html/rfc7301

## 1.7.0 – 2014-10-15

### Tool changes

* `pub` now generates binstubs for packages that are globally activated so that
  they can be put on the user's `PATH` and used as normal executables. See the
  [`pub global activate` documentation][pub global activate].

* When using `dart2js`, deferred loading now works with multiple Dart apps on
  the same page.

[pub global activate]: https://www.dartlang.org/tools/pub/cmd/pub-global.html#running-a-script-from-your-path

### Core library changes

* `dart:async`: `Zone`, `ZoneDelegate`, and `ZoneSpecification` added the
  `errorCallback` function, which allows errors that have been programmatically
  added to a `Future` or `Stream` to be intercepted.

* `dart:io`:

  * **Breaking change:** `HttpClient.close` must be called for all clients or
    they will keep the Dart process alive until they time out. This fixes the
    handling of persistent connections. Previously, the client would shut down
    immediately after a request.

  * **Breaking change:** `HttpServer` no longer compresses all traffic by
    default. The new `autoCompress` property can be set to `true` to re-enable
    compression.

* `dart:isolate`: `Isolate.spawnUri` added the optional `packageRoot` argument,
  which controls how it resolves `package:` URIs.
