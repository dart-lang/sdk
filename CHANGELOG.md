## 1.15.0

### Core library changes

* `dart:async`
  * Made `StreamView` class a `const` class.

* `dart:core`
  * Added `Uri.queryParametersAll` to handle multiple query parameters with
    the same name.

* `dart:io`
  * Added `SecurityContext.usePrivateKeyBytes`,
    `SecurityContext.useCertificateChainBytes`,
    `SecurityContext.setTrustedCertificatesBytes`, and
    `SecurityContext.setClientAuthoritiesBytes`.
  * **Breaking** The named `directory` argument of
    `SecurityContext.setTrustedCertificates` has been removed.
  * Added support to `SecurityContext` for PKCS12 certificate and key
    containers.
  * All calls in `SecurityContext` that accept certificate data now accept an
    optional named parameter `password`, similar to
    `SecurityContext.usePrivateKeyBytes`, for use as the password for PKCS12
    data.

### Service protocol changes

* Fixed a documentation bug where the field `extensionRPCs` in `Isolate`
  was not marked optional.

### Experimental language features
  * Added support for [configuration-specific imports](https://github.com/munificent/dep-interface-libraries/blob/master/Proposal.md).
    On the VM and `dart2js`, they can be enabled with `--conditional-directives`.

    The analyzer requires additional configuration:
    ```yaml
    analyzer:
      language:
        enableConditionalDirectives: true
    ```

    Read about [configuring the analyzer] for more details.

[configuring the analyzer]: https://github.com/dart-lang/sdk/tree/master/pkg/analyzer#configuring-the-analyzer

## 1.14.2 - 2016-02-09

* Fixes a bug where pub would download packages from pub.dartlang.org even when
  a different hosted URL was specified.

## 1.14.1 - 2016-02-04

Patch release, resolves one issue:

* Debugger: Fixes a VM crash when a debugger attempts to set a break point
during isolate initialization.
(SDK issue [25618](https://github.com/dart-lang/sdk/issues/25618))

## 1.14.0 - 2016-01-28

### Core library changes
* `dart:async`
  * Added `Future.any` static method.
  * Added `Stream.fromFutures` constructor.

* `dart:convert`
  * `Base64Decoder.convert` now takes optional `start` and `end` parameters.

* `dart:core`
  * Added `current` getter to `StackTrace` class.
  * `Uri` class added support for data URIs
      * Added two new constructors: `dataFromBytes` and `dataFromString`.
      * Added a `data` getter for `data:` URIs with a new `UriData` class for
      the return type.
  * Added `growable` parameter to `List.filled` constructor.
  * Added microsecond support to `DateTime`: `DateTime.microsecond`,
    `DateTime.microsecondsSinceEpoch`, and
    `new DateTime.fromMicrosecondsSinceEpoch`.

* `dart:math`
  * `Random` added a `secure` constructor returning a cryptographically secure
    random generator which reads from the entropy source provided by the
    embedder for every generated random value.

* `dart:io`
  * `Platform` added a static `isIOS` getter and `Platform.operatingSystem` may
    now return `ios`.
  * `Platform` added a static `packageConfig` getter.
  * Added support for WebSocket compression as standardized in RFC 7692.
  * Compression is enabled by default for all WebSocket connections.
      * The optionally named parameter `compression` on the methods
      `WebSocket.connect`, `WebSocket.fromUpgradedSocket`, and
      `WebSocketTransformer.upgrade` and  the `WebSocketTransformer`
      constructor can be used to modify or disable compression using the new
      `CompressionOptions` class.

* `dart:isolate`
  * Added **_experimental_** support for [Package Resolution Configuration].
    * Added `packageConfig` and `packageRoot` instance getters to `Isolate`.
    * Added a `resolvePackageUri` method to `Isolate`.
    * Added named arguments `packageConfig` and `automaticPackageResolution` to
    the `Isolate.spawnUri` constructor.

[Package Resolution Configuration]: https://github.com/dart-lang/dart_enhancement_proposals/blob/master/Accepted/0005%20-%20Package%20Specification/DEP-pkgspec.md

### Tool changes

* `dartfmt`

  * Better line splitting in a variety of cases.

  * Other optimizations and bug fixes.

* Pub

  * **Breaking:** Pub now eagerly emits an error when a pubspec's "name" field
    is not a valid Dart identifier. Since packages with non-identifier names
    were never allowed to be published, and some of them already caused crashes
    when being written to a `.packages` file, this is unlikely to break many
    people in practice.

  * **Breaking:** Support for `barback` versions prior to 0.15.0 (released July
    2014) has been dropped. Pub will no longer install these older barback
    versions.

  * `pub serve` now GZIPs the assets it serves to make load times more similar
    to real-world use-cases.

  * `pub deps` now supports a `--no-dev` flag, which causes it to emit the
    dependency tree as it would be if no `dev_dependencies` were in use. This
    makes it easier to see your package's dependency footprint as your users
    will experience it.

  * `pub global run` now detects when a global executable's SDK constraint is no
    longer met and errors out, rather than trying to run the executable anyway.

  * Pub commands that check whether the lockfile is up-to-date (`pub run`, `pub
    deps`, `pub serve`, and `pub build`) now do additional verification. They
    ensure that any path dependencies' pubspecs haven't been changed, and they
    ensure that the current SDK version is compatible with all dependencies.

  * Fixed a crashing bug when using `pub global run` on a global script that
    didn't exist.

  * Fixed a crashing bug when a pubspec contains a dependency without a source
    declared.

## 1.13.2 - 2016-01-06

Patch release, resolves one issue:

* dart2js: Stack traces are not captured correctly (SDK issue [25235]
(https://github.com/dart-lang/sdk/issues/25235))

## 1.13.1 - 2015-12-17

Patch release, resolves three issues:

* VM type propagation fix: Resolves a potential crash in the Dart VM (SDK commit
 [dff13be]
(https://github.com/dart-lang/sdk/commit/dff13bef8de104d33b04820136da2d80f3c835d7))

* dart2js crash fix: Resolves a crash in pkg/js and dart2js (SDK issue [24974]
(https://github.com/dart-lang/sdk/issues/24974))

* Pub get crash on ARM: Fixes a crash triggered when running 'pub get' on ARM
 processors such as those on a Raspberry Pi (SDK issue [24855]
(https://github.com/dart-lang/sdk/issues/24855))

## 1.13.0 - 2015-11-18

### Core library changes
* `dart:async`
  * `StreamController` added getters for `onListen`, `onPause`, and `onResume`
    with the corresponding new `typedef void ControllerCallback()`.
  * `StreamController` added a getter for `onCancel` with the corresponding
    new `typedef ControllerCancelCallback()`;
  * `StreamTransformer` instances created with `fromHandlers` with no
    `handleError` callback now forward stack traces along with errors to the
    resulting streams.

* `dart:convert`
  * Added support for Base-64 encoding and decoding.
    * Added new classes `Base64Codec`, `Base64Encoder`, and `Base64Decoder`.
    * Added new top-level `const Base64Codec BASE64`.

* `dart:core`
  * `Uri` added `removeFragment` method.
  * `String.allMatches` (implementing `Pattern.allMatches`) is now lazy,
    as all `allMatches` implementations are intended to be.
  * `Resource` is deprecated, and will be removed in a future release.

* `dart:developer`
  * Added `Timeline` class for interacting with Observatory's timeline feature.
  * Added `ServiceExtensionHandler`, `ServiceExtensionResponse`, and `registerExtension` which enable developers to provide their own VM service protocol extensions.

* `dart:html`, `dart:indexed_db`, `dart:svg`, `dart:web_audio`, `dart:web_gl`, `dart:web_sql`
  * The return type of some APIs changed from `double` to `num`. Dartium is now
    using
    JS interop for most operations. JS does not distinguish between numeric
    types, and will return a number as an int if it fits in an int. This will
    mostly cause an error if you assign to something typed `double` in
    checked mode. You may
    need to insert a `toDouble()` call or accept `num`. Examples of APIs that
    are affected include `Element.getBoundingClientRect` and
    `TextMetrics.width`.

* `dart:io`
  * **Breaking:** Secure networking has changed, replacing the NSS library
    with the BoringSSL library. `SecureSocket`, `SecureServerSocket`,
    `RawSecureSocket`,`RawSecureServerSocket`, `HttpClient`, and `HttpServer`
    now all use a `SecurityContext` object which contains the certificates
    and keys used for secure TLS (SSL) networking.

    This is a breaking change for server applications and for some client
    applications. Certificates and keys are loaded into the `SecurityContext`
    from PEM files, instead of from an NSS certificate database. Information
    about how to change applications that use secure networking is at
    https://www.dartlang.org/server/tls-ssl.html

  * `HttpClient` no longer sends URI fragments in the request. This is not
    allowed by the HTTP protocol.
    The `HttpServer` still gracefully receives fragments, but discards them
    before delivering the request.
  * To allow connections to be accepted on the same port across different
    isolates, set the `shared` argument to `true` when creating server socket
    and `HttpServer` instances.
    * The deprecated `ServerSocketReference` and `RawServerSocketReference`
      classes have been removed.
    * The corresponding `reference` properties on `ServerSocket` and
      `RawServerSocket` have been removed.

* `dart:isolate`
  * `spawnUri` added an `environment` named argument.

### Tool changes

* `dart2js` and Dartium now support improved Javascript Interoperability via the
  [js package](https://pub.dartlang.org/packages/js).

* `docgen` and `dartdocgen` no longer ship in the SDK. The `docgen` sources have
   been removed from the repository.

* This is the last release to ship the VM's "legacy debug protocol".
  We intend to remove the legacy debug protocol in Dart VM 1.14.

* The VM's Service Protocol has been updated to version 3.0 to take care
  of a number of issues uncovered by the first few non-observatory
  clients.  This is a potentially breaking change for clients.

* Dartium has been substantially changed. Rather than using C++ calls into
  Chromium internals for DOM operations it now uses JS interop.
  The DOM objects in `dart:html` and related libraries now wrap
  a JavaScript object and delegate operations to it. This should be
  mostly transparent to users. However, performance and memory characteristics
  may be different from previous versions. There may be some changes in which
  DOM objects are wrapped as Dart objects. For example, if you get a reference
  to a Window object, even through JS interop, you will always see it as a
  Dart Window, even when used cross-frame. We expect the change to using
  JS interop will make it much simpler to update to new Chrome versions.

## 1.12.2 - 2015-10-21

### Core library changes

* `dart:io`

  * A memory leak in creation of Process objects is fixed.

## 1.12.1 - 2015-09-08

### Tool changes

* Pub

  * Pub will now respect `.gitignore` when validating a package before it's
    published. For example, if a `LICENSE` file exists but is ignored, that is
    now an error.

  * If the package is in a subdirectory of a Git repository and the entire
    subdirectory is ignored with `.gitignore`, pub will act as though nothing
    was ignored instead of uploading an empty package.

  * The heuristics for determining when `pub get` needs to be run before various
    commands have been improved. There should no longer be false positives when
    non-dependency sections of the pubspec have been modified.

## 1.12.0 - 2015-08-31

### Language changes

* Null-aware operators
    * `??`: if null operator. `expr1 ?? expr2` evaluates to `expr1` if
      not `null`, otherwise `expr2`.
    * `??=`: null-aware assignment. `v ??= expr` causes `v` to be assigned
      `expr` only if `v` is `null`.
    * `x?.p`: null-aware access. `x?.p` evaluates to `x.p` if `x` is not
      `null`, otherwise evaluates to `null`.
    * `x?.m()`: null-aware method invocation. `x?.m()` invokes `m` only
      if `x` is not `null`.

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

## 1.11.2 - 2015-08-03

### Core library changes

* Fix a bug where `WebSocket.close()` would crash if called after
  `WebSocket.cancel()`.

## 1.11.1 - 2015-07-02

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
