## 3.2.0

### Language

### Libraries

#### `dart:js_interop`

- **JSNumber.toDart and Object.toJS**:
  `JSNumber.toDart` is removed in favor of `toDartDouble` and `toDartInt` to
  make the type explicit. `Object.toJS` is also removed in favor of
  `Object.toJSBox`. Previously, this function would allow Dart objects to flow
  into JS unwrapped on the JS backends. Now, there's an explicit wrapper that is
  added and unwrapped via `JSBoxedDartObject.toDart`. Similarly,
  `JSExportedDartObject` is renamed to `JSBoxedDartObject` and the extensions
  `ObjectToJSExportedDartObject` and `JSExportedDartObjectToObject` are renamed
  to `ObjectToJSBoxedDartObject` and `JSBoxedDartObjectToObject` in order to
  avoid confusion with `@JSExport`.
- **Type parameters in external APIs**:
  Type parameters must now be bound to a static interop type or one of the
  `dart:js_interop` types like `JSNumber` when used in an external API. This
  only affects `dart:js_interop` classes and not `package:js` or other forms of
  JS interop.

## 3.1.0

### Language

### Libraries

#### `dart:async`

- **Breaking change** [#52334][]:
  - Added `interface` modifier to purely abstract classes:
    `MultiStreamController`, `StreamConsumer`, `StreamIterator` and
    `StreamTransformer`.

[#52334]: https://dartbug.com/52334

#### `dart:convert`

- **Breaking change** [#52801][]:
  - Changed return types of `utf8.encode()` and `Utf8Codec.encode()` from
    `List<int>` to `Uint8List`.

[#52801]: https://dartbug.com/52801

#### `dart:core`

- `Uri.base` on native platforms now respectes `IOOverrides` overriding
   current directory ([#39796][]).

[#39796]: https://darbug.com/39796

#### `dart:io`

- **Breaking change** [#51486][]:
  - Added `sameSite` to the `Cookie` class.
  - Added class `SameSite`.
- **Breaking change** [#52027][]: `FileSystemEvent` is
  [`sealed`](https://dart.dev/language/class-modifiers#sealed). This means
  that `FileSystemEvent` cannot be extended or implemented.
- Added a deprecation warning when `Platform` is instantiated.
- Added `Platform.lineTerminator` which exposes the character or characters
  that the operating system uses to separate lines of text, e.g.,
  `"\r\n"` on Windows.

[#51486]: https://github.com/dart-lang/sdk/issues/51486
[#52027]: https://github.com/dart-lang/sdk/issues/52027

#### `dart:isolate`

- Added `Isolate.packageConfigSync` and `Isolate.resolvePackageUriSync` APIs.

#### `dart:js_interop`

- **Object literal constructors**:
  `ObjectLiteral` is removed from `dart:js_interop`. It's no longer needed in
  order to declare an object literal constructor with inline classes. As long as
  an external constructor has at least one named parameter, it'll be treated as
  an object literal constructor. If you want to create an object literal with no
  named members, use `{}.jsify()`.

### Other libraries

#### `package:js`

- **Breaking change to `@staticInterop` and `external` extension members**:
  `external` `@staticInterop` members and `external` extension members can no
  longer be used as tear-offs. Declare a closure or a non-`external` method that
  calls these members, and use that instead.
- **Breaking change to `@staticInterop` and `external` extension members**:
  `external` `@staticInterop` members and `external` extension members will
  generate slightly different JS code for methods that have optional parameters.
  Whereas before, the JS code passed in the default value for missing optionals,
  it will now pass in only the provided members. This aligns with how JS
  parameters work, where omitted parameters are actually omitted. For example,
  calling `external void foo([int a, int b])` as `foo(0)` will now result in
  `foo(0)`, and not `foo(0, null)`.

## 3.0.4 - 2023-06-07

This is a patch release that:

- Handles formatting nullable record types with no fields (dart_style issue [#1224]).
- Fixes error when using records when targeting the web in development mode
(issue [#52480]).
- Fixes a bad cast in the frontend which can manifest as a crash in the dart2js
`ListFactorySpecializer` during Flutter web builds (issue [#52403]).

[#1224]: https://github.com/dart-lang/dart_style/issues/1224
[#52403]: https://github.com/dart-lang/sdk/issues/52403
[#52480]: https://github.com/dart-lang/sdk/issues/52480

## 3.0.3 - 2023-02-07

This is a patch release that:

- Fixes an AOT compiler crash when generating an implicit getter returning an unboxed record (issue [#52449]).
- Fixes a situation in which variables appearing in multiple branches of an or-pattern might be erroneously reported as being mismatched (issue [#52373]).
- Adds missing `interface` modifiers on the purely abstract classes
  `MultiStreamController`, `StreamConsumer`, `StreamIterator` and
  `StreamTransformer` ([#52334]).
- Fixes an error during debugging when `InternetAddress.tryParse` is
used (issue [#52423]).
- Fixes a VM issue causing crashes on hot reload (issue [#126884]).
- Improves linter support (issue [#4195]).
- Fixes an issue in variable patterns preventing users from expressing
  a pattern match using a variable or wildcard pattern with a nullable
  record type (issue [#52439]).
- Updates warnings and provide instructions for updating the Dart pub
  cache on Windows (issue [#52386]).

[#52373]: https://github.com/dart-lang/sdk/issues/52373
[#52334]: https://github.com/dart-lang/sdk/issues/52334
[#52423]: https://github.com/dart-lang/sdk/issues/52423
[#126884]: https://github.com/flutter/flutter/issues/126884
[#4195]: https://github.com/dart-lang/linter/issues/4195
[#52439]: https://github.com/dart-lang/sdk/issues/52439
[#52449]: https://github.com/dart-lang/sdk/issues/52449
[#52386]: https://github.com/dart-lang/sdk/issues/52386

## 3.0.2 - 2023-05-24

This is a patch release that:

- Fixes a dart2js crash when using a switch case expression on a record where the fields don't match the cases. (issue [#52438]).
- Add chips for class and mixin pages on dartdoc generated pages. (issue [#3392]).
- Fixes a situation causing the parser to fail resulting in an infinite loop
leading to higher memory usage. (issue [#52352]).
- Add clear errors when mixing inheritence in pre and post Dart 3 libraries.
(issue: [#52078]).

[#52438]: https://github.com/dart-lang/sdk/issues/52438
[#3392]: https://github.com/dart-lang/dartdoc/issues/3392
[#52352]: https://github.com/dart-lang/sdk/issues/52352
[#52078]: https://github.com/dart-lang/sdk/issues/52078

## 3.0.1 - 2023-05-17

This is a patch release that:

- Fixes a compiler crash involving redirecting factories and FFI
  (issue [#124369]).
- Fixes a dart2js crash when using a combination of local functions, generics,
  and records (issue [#51899]).
- Fixes incorrect error using a `void` in a switch case expression
  (issue [#52191]).
- Fixes a false error when using in switch case expressions when the switch
  refers to a private getter (issue [#52041]).
- Prevent the use of `when` and `as` as variable names in patterns
  (issue [#52260]).
- Fixes an inconsistency in type promotion between the analuzer and VM
  (issue [#52241]).
- Improve performance on functions with many parameters (issue [#1212]).

[#124369]: https://github.com/flutter/flutter/issues/124369
[#51899]: https://github.com/dart-lang/sdk/issues/51899
[#52191]: https://github.com/dart-lang/sdk/issues/52191
[#52041]: https://github.com/dart-lang/sdk/issues/52041
[#52260]: https://github.com/dart-lang/sdk/issues/52260
[#52241]: https://github.com/dart-lang/sdk/issues/52241
[#1212]: https://github.com/dart-lang/dart_style/issues/1212

## 3.0.0 - 2023-05-10

### Language

Dart 3.0 adds the following features. To use them, set your package's [SDK
constraint][language version] lower bound to 3.0 or greater (`sdk: '^3.0.0'`).

[language version]: https://dart.dev/guides/language/evolution

- **[Records]**: Records are anonymous immutable data structures that let you
  aggregate multiple values together, similar to [tuples][] in other languages.
  With records, you can return multiple values from a function, create composite
  map keys, or use them any other place where you want to bundle a couple of
  objects together.

  For example, using a record to return two values:

  ```dart
  (double x, double y) geoLocation(String name) {
    if (name == 'Nairobi') {
      return (-1.2921, 36.8219);
    } else {
      ...
    }
  }
  ```

- **[Pattern matching]**: Expressions build values out of smaller pieces.
  Conversely, patterns are an expressive tool for decomposing values back into
  their constituent parts. Patterns can call getters on an object, access
  elements from a list, pull fields out of a record, etc. For example, we can
  destructure the record from the previous example like so:

  ```dart
  var (lat, long) = geoLocation('Nairobi');
  print('Nairobi is at $lat, $long.');
  ```

  Patterns can also be used in [switch cases]. There, you can destructure values
  and also test them to see if they have a certain type or value:

  ```dart
  switch (object) {
    case [int a]:
      print('A list with a single integer element $a');
    case ('name', _):
      print('A two-element record whose first field is "name".');
    default: print('Some other object.');
  }
  ```

  Also, as you can see, non-empty switch cases no longer need `break;`
  statements.

  **Breaking change**: Dart 3.0 interprets [switch cases] as patterns instead of
  constant expressions. Most constant expressions found in switch cases are
  valid patterns with the same meaning (named constants, literals, etc.). You
  may need to tweak a few constant expressions to make them valid. This only
  affects libraries that have upgraded to language version 3.0.

- **[Switch expressions]**: Switch expressions allow you to use patterns and
  multi-way branching in contexts where a statement isn't allowed:

  ```dart
  return TextButton(
    onPressed: _goPrevious,
    child: Text(switch (page) {
      0 => 'Exit story',
      1 => 'First page',
      _ when page == _lastPage => 'Start over',
      _ => 'Previous page',
    }),
  );
  ```

- **[If-case statements and elements]**: A new if construct that matches a value
  against a pattern and executes the then or else branch depending on whether
  the pattern matches:

  ```dart
  if (json case ['user', var name]) {
    print('Got user message for user $name.');
  }
  ```

  There is also a corresponding [if-case element] that can be used in collection
  literals.

- **[Sealed classes]**: When you mark a type `sealed`, the compiler ensures that
  switches on values of that type [exhaustively cover] every subtype. This
  enables you to program in an [algebraic datatype][] style with the
  compile-time safety you expect:

  ```dart
  sealed class Amigo {}
  class Lucky extends Amigo {}
  class Dusty extends Amigo {}
  class Ned extends Amigo {}

  String lastName(Amigo amigo) =>
      switch (amigo) {
        Lucky _ => 'Day',
        Ned _   => 'Nederlander',
      };
  ```

  In this last example, the compiler reports an error that the switch doesn't
  cover the subclass `Dusty`.

- **[Class modifiers]**: New modifiers `final`, `interface`, `base`, and `mixin`
  on `class` and `mixin` declarations let you control how the type can be used.
  By default, Dart is flexible in that a single class declaration can be used as
  an interface, a superclass, or even a mixin. This flexibility can make it
  harder to evolve an API over time without breaking users. We mostly keep the
  current flexible defaults, but these new modifiers give you finer-grained
  control over how the type can be used.

  **Breaking change:** Class declarations from libraries that have been upgraded
  to Dart 3.0 can no longer be used as mixins by default. If you want the class
  to be usable as both a class and a mixin, mark it [`mixin class`][mixin
  class]. If you want it to be used only as a mixin, make it a `mixin`
  declaration. If you haven't upgraded a class to Dart 3.0, you can still use it
  as a mixin.

- **Breaking Change** [#50902][]: Dart reports a compile-time error if a
  `continue` statement targets a [label] that is not a loop (`for`, `do` and
  `while` statements) or a `switch` member. Fix this by changing the `continue`
  to target a valid labeled statement.

[records]: https://dart.dev/language/records
[tuples]: https://en.wikipedia.org/wiki/Tuple
[pattern matching]: https://dart.dev/language/patterns
[switch cases]: https://dart.dev/language/branches#switch
[switch expressions]: https://dart.dev/language/branches#switch-expressions
[if-case statements and elements]: https://dart.dev/language/branches#if-case
[if-case element]: https://dart.dev/language/collections#control-flow-operators
[sealed classes]: https://dart.dev/language/class-modifiers#sealed
[exhaustively cover]: https://dart.dev/language/branches#exhaustiveness-checking
[algebraic datatype]: https://en.wikipedia.org/wiki/Algebraic_data_type
[class modifiers]: https://dart.dev/language/class-modifiers
[mixin class]: https://dart.dev/language/mixins#class-mixin-or-mixin-class
[#50902]: https://github.com/dart-lang/sdk/issues/50902
[label]: https://dart.dev/language/branches#switch

### Libraries

#### General changes

- **Breaking Change**: Non-`mixin` classes in the platform libraries
  can no longer be mixed in, unless they are explicitly marked as `mixin class`.
  The following existing classes have been made mixin classes:
  * `Iterable`
  * `IterableMixin` (now alias for `Iterable`)
  * `IterableBase` (now alias for `Iterable`)
  * `ListMixin`
  * `SetMixin`
  * `MapMixin`
  * `LinkedListEntry`
  * `StringConversionSink`

#### `dart:core`
- Added `bool.parse` and `bool.tryParse` static methods.
- Added `DateTime.timestamp()` constructor to get current time as UTC.
- The type of `RegExpMatch.pattern` is now `RegExp`, not just `Pattern`.

- **Breaking change** [#49529][]:
  - Removed the deprecated `List` constructor, as it wasn't null safe.
    Use list literals (e.g. `[]` for an empty list or `<int>[]` for an empty
    typed list) or [`List.filled`][].
  - Removed the deprecated `onError` argument on [`int.parse`][], [`double.parse`][],
    and [`num.parse`][]. Use the [`tryParse`][] method instead.
  - Removed the deprecated [`proxy`][] and [`Provisional`][] annotations.
    The original `proxy` annotation has no effect in Dart 2,
    and the `Provisional` type and [`provisional`][] constant
    were only used internally during the Dart 2.0 development process.
  - Removed the deprecated [`Deprecated.expires`][] getter.
    Use [`Deprecated.message`][] instead.
  - Removed the deprecated [`CastError`][] error.
    Use [`TypeError`][] instead.
  - Removed the deprecated [`FallThroughError`][] error. The kind of
    fall-through previously throwing this error was made a compile-time
    error in Dart 2.0.
  - Removed the deprecated [`NullThrownError`][] error. This error is never
    thrown from null safe code.
  - Removed the deprecated [`AbstractClassInstantiationError`][] error. It was made
    a compile-time error to call the constructor of an abstract class in Dart 2.0.
  - Removed the deprecated [`CyclicInitializationError`]. Cyclic dependencies are
    no longer detected at runtime in null safe code. Such code will fail in other
    ways instead, possibly with a StackOverflowError.
  - Removed the deprecated [`NoSuchMethodError`][] default constructor.
    Use the [`NoSuchMethodError.withInvocation`][] named constructor instead.
  - Removed the deprecated [`BidirectionalIterator`][] class.
    Existing bidirectional iterators can still work, they just don't have
    a shared supertype locking them to a specific name for moving backwards.

- **Breaking change when migrating code to Dart 3.0**:
  Some changes to platform libraries only affect code when that code is migrated
  to language version 3.0.
  - The `Function` type can no longer be implemented, extended or mixed in.
    Since Dart 2.0 writing `implements Function` has been allowed
    for backwards compatibility, but it has not had any effect.
    In Dart 3.0, the `Function` type is `final` and cannot be subtyped,
    preventing code from mistakenly assuming it works.
  - The following declarations can only be implemented, not extended:
    * `Comparable`
    * `Exception`
    * `Iterator`
    * `Pattern`
    * `Match`
    * `RegExp`
    * `RegExpMatch`
    * `StackTrace`
    * `StringSink`

    None of these declarations contained any implementation to inherit,
    and are marked as `interface` to signify that they are only intended
    as interfaces.
  - The following declarations can no longer be implemented or extended:
    * `MapEntry`
    * `OutOfMemoryError`
    * `StackOverflowError`
    * `Expando`
    * `WeakReference`
    * `Finalizer`

    The `MapEntry` value class is restricted to enable later optimizations.
    The remaining classes are tightly coupled to the platform and not
    intended to be subclassed or implemented.

[#49529]: https://github.com/dart-lang/sdk/issues/49529
[`List.filled`]: https://api.dart.dev/stable/2.18.6/dart-core/List/List.filled.html
[`int.parse`]: https://api.dart.dev/stable/2.18.4/dart-core/int/parse.html
[`double.parse`]: https://api.dart.dev/stable/2.18.4/dart-core/double/parse.html
[`num.parse`]: https://api.dart.dev/stable/2.18.4/dart-core/num/parse.html
[`tryParse`]: https://api.dart.dev/stable/2.18.4/dart-core/num/tryParse.html
[`Deprecated.expires`]: https://api.dart.dev/stable/2.18.4/dart-core/Deprecated/expires.html
[`Deprecated.message`]: https://api.dart.dev/stable/2.18.4/dart-core/Deprecated/message.html
[`AbstractClassInstantiationError`]: https://api.dart.dev/stable/2.17.4/dart-core/AbstractClassInstantiationError-class.html
[`CastError`]: https://api.dart.dev/stable/2.17.4/dart-core/CastError-class.html
[`FallThroughError`]: https://api.dart.dev/stable/2.17.4/dart-core/FallThroughError-class.html
[`NoSuchMethodError`]: https://api.dart.dev/stable/2.18.4/dart-core/NoSuchMethodError/NoSuchMethodError.html
[`NoSuchMethodError.withInvocation`]: https://api.dart.dev/stable/2.18.4/dart-core/NoSuchMethodError/NoSuchMethodError.withInvocation.html
[`CyclicInitializationError`]: https://api.dart.dev/dev/2.19.0-430.0.dev/dart-core/CyclicInitializationError-class.html
[`Provisional`]: https://api.dart.dev/stable/2.18.4/dart-core/Provisional-class.html
[`provisional`]: https://api.dart.dev/stable/2.18.4/dart-core/provisional-constant.html
[`proxy`]: https://api.dart.dev/stable/2.18.4/dart-core/proxy-constant.html
[`CastError`]: https://api.dart.dev/stable/2.18.3/dart-core/CastError-class.html
[`TypeError`]: https://api.dart.dev/stable/2.18.3/dart-core/TypeError-class.html
[`FallThroughError`]: https://api.dart.dev/dev/2.19.0-374.0.dev/dart-core/FallThroughError-class.html
[`NullThrownError`]: https://api.dart.dev/dev/2.19.0-430.0.dev/dart-core/NullThrownError-class.html
[`AbstractClassInstantiationError`]: https://api.dart.dev/stable/2.18.3/dart-core/AbstractClassInstantiationError-class.html
[`CyclicInitializationError`]: https://api.dart.dev/dev/2.19.0-430.0.dev/dart-core/CyclicInitializationError-class.html
[`BidirectionalIterator`]: https://api.dart.dev/dev/2.19.0-430.0.dev/dart-core/BidirectionalIterator-class.html

#### `dart:async`

- Added extension member `wait` on iterables and 2-9 tuples of futures.

- **Breaking change** [#49529][]:
  - Removed the deprecated [`DeferredLibrary`][] class.
    Use the [`deferred as`][] import syntax instead.

[#49529]: https://github.com/dart-lang/sdk/issues/49529
[`DeferredLibrary`]: https://api.dart.dev/stable/2.18.4/dart-async/DeferredLibrary-class.html
[`deferred as`]: https://dart.dev/guides/language/language-tour#deferred-loading

#### `dart:collection`

- Added extension members `nonNulls`, `firstOrNull`, `lastOrNull`,
  `singleOrNull`, `elementAtOrNull` and `indexed` on `Iterable`s.
  Also exported from `dart:core`.
- Deprecated the `HasNextIterator` class ([#50883][]).

- **Breaking change when migrating code to Dart 3.0**:
  Some changes to platform libraries only affect code when it is migrated
  to language version 3.0.
  - The following interface can no longer be extended, only implemented:
    * `Queue`
  - The following implementation classes can no longer be implemented:
    * `LinkedList`
    * `LinkedListEntry`
  - The following implementation classes can no longer be implemented
    or extended:
    * `HasNextIterator` (Also deprecated.)
    * `HashMap`
    * `LinkedHashMap`
    * `HashSet`
    * `LinkedHashSet`
    * `DoubleLinkedQueue`
    * `ListQueue`
    * `SplayTreeMap`
    * `SplayTreeSet`

[#50883]: https://github.com/dart-lang/sdk/issues/50883

#### `dart:developer`

- **Breaking change** [#49529][]:
  - Removed the deprecated [`MAX_USER_TAGS`][] constant.
    Use [`maxUserTags`][] instead.
- Callbacks passed to `registerExtension` will be run in the zone from which
  they are registered.

- **Breaking change** [#50231][]:
  - Removed the deprecated [`Metrics`][], [`Metric`][], [`Counter`][],
    and [`Gauge`][] classes as they have been broken since Dart 2.0.

[#49529]: https://github.com/dart-lang/sdk/issues/49529
[#50231]: https://github.com/dart-lang/sdk/issues/50231
[`MAX_USER_TAGS`]: https://api.dart.dev/stable/dart-developer/UserTag/MAX_USER_TAGS-constant.html
[`maxUserTags`]: https://api.dart.dev/beta/2.19.0-255.2.beta/dart-developer/UserTag/maxUserTags-constant.html
[`Metrics`]: https://api.dart.dev/stable/2.18.2/dart-developer/Metrics-class.html
[`Metric`]: https://api.dart.dev/stable/2.18.2/dart-developer/Metric-class.html
[`Counter`]: https://api.dart.dev/stable/2.18.2/dart-developer/Counter-class.html
[`Gauge`]: https://api.dart.dev/stable/2.18.2/dart-developer/Gauge-class.html

#### `dart:html`

- **Breaking change**: As previously announced, the deprecated `registerElement`
  and `registerElement2` methods in `Document` and `HtmlDocument` have been
  removed.  See [#49536](https://github.com/dart-lang/sdk/issues/49536) for
  details.

#### `dart:math`

- **Breaking change when migrating code to Dart 3.0**:
  Some changes to platform libraries only affect code when it is migrated
  to language version 3.0.
  - The `Random` interface can only be implemented, not extended.

#### `dart:io`

- Added `name` and `signalNumber` to the `ProcessSignal` class.
- Deprecate `NetworkInterface.listSupported`. Has always returned true since
  Dart 2.3.
- Finalize `httpEnableTimelineLogging` parameter name transition from `enable`
  to `enabled`. See [#43638][].
- Favor IPv4 connections over IPv6 when connecting sockets. See
  [#50868].
- **Breaking change** [#51035][]:
  - Update `NetworkProfiling` to accommodate new `String` ids
    that are introduced in vm_service:11.0.0

[#43638]: https://github.com/dart-lang/sdk/issues/43638
[#50868]: https://github.com/dart-lang/sdk/issues/50868
[#51035]: https://github.com/dart-lang/sdk/issues/51035

#### `dart:js_util`

- Added several helper functions to access more JavaScript operators, like
  `delete` and the `typeof` functionality.
- `jsify` is now permissive and has inverse semantics to `dartify`.
- `jsify` and `dartify` both handle types they understand natively more
  efficiently.
- Signature of `callMethod` has been aligned with the other methods and
  now takes `Object` instead of `String`.

### Tools

#### Observatory
- Observatory is no longer served by default and users should instead use Dart
  DevTools. Users requiring specific functionality in Observatory should set
  the `--serve-observatory` flag.

#### Web Dev Compiler (DDC)
- Removed deprecated command line flags `-k`, `--kernel`, and `--dart-sdk`.
- The compile time flag `--nativeNonNullAsserts`, which ensures web library APIs
are sound in their nullability, is by default set to true in sound mode. For
more information on the flag, see [NATIVE_NULL_ASSERTIONS.md][].

[NATIVE_NULL_ASSERTIONS.md]: https://github.com/dart-lang/sdk/blob/main/sdk/lib/html/doc/NATIVE_NULL_ASSERTIONS.md

#### dart2js
- The compile time flag `--native-null-assertions`, which ensures web library
APIs are sound in their nullability, is by default set to true in sound mode,
unless `-O3` or higher is passed, in which case they are not checked. For more
information on the flag, see [NATIVE_NULL_ASSERTIONS.md][].

[NATIVE_NULL_ASSERTIONS.md]: https://github.com/dart-lang/sdk/blob/main/sdk/lib/html/doc/NATIVE_NULL_ASSERTIONS.md

#### Dart2js

- Cleanup related to [#46100](https://github.com/dart-lang/sdk/issues/46100):
  the internal dart2js snapshot fails unless it is called from a supported
  interface, such as `dart compile js`, `flutter build`, or
  `build_web_compilers`. This is not expected to be a visible change.

#### Formatter

* Format `sync*` and `async*` functions with `=>` bodies.
* Don't split after `<` in collection literals.
* Better indentation of multiline function types inside type argument lists.
* Fix bug where parameter metadata wouldn't always split when it should.

#### Analyzer

- Most static analysis "hints" are converted to be "warnings," and any
  remaining hints are intended to be converted soon after the Dart 3.0 release.
  This means that any (previously) hints reported by `dart analyze` are now
  considered "fatal" (will result in a non-zero exit code). The previous
  behavior, where such hints (now warnings) are not fatal, can be achieved by
  using the `--no-fatal-warnings` flag. This behavior can also be altered, on a
  code-by-code basis, by [changing the severity of rules] in an analysis
  options file.
- Add static enforcement of the SDK-only `@Since` annotation. When code in a
  package uses a Dart SDK element annotated with `@Since`, analyzer will report
  a warning if the package's [Dart SDK constraint] allows versions of Dart
  which don't include that element.
- Protects the Dart Analysis Server against extreme memory usage by limiting
  the number of plugins per analysis context to 1. (issue [#50981][]).

[changing the severity of rules]: https://dart.dev/guides/language/analysis-options#changing-the-severity-of-rules
[Dart SDK constraint]: https://dart.dev/tools/pub/pubspec#sdk-constraints

#### Linter

Updates the Linter to `1.35.0`, which includes changes that

- add new lints:
  - `implicit_reopen`
  - `unnecessary_breaks`
  - `type_literal_in_constant_pattern`
  - `invalid_case_patterns`
- update existing lints to support patterns and class modifiers
- remove support for:
  - `enable_null_safety`
  - `invariant_booleans`
  - `prefer_bool_in_asserts`
  - `prefer_equal_for_default_values`
  - `super_goes_last`
- fix `unnecessary_parenthesis` false-positives with null-aware expressions.
- fix `void_checks` to allow assignments of `Future<dynamic>?` to parameters
  typed `FutureOr<void>?`.
- fix `use_build_context_synchronously` in if conditions.
- fix a false positive for `avoid_private_typedef_functions` with generalized
  type aliases.
- update `unnecessary_parenthesis` to detect some doubled parens.
- update `void_checks` to allow returning `Never` as void.
- update `no_adjacent_strings_in_list` to support set literals and for- and
  if-elements.
- update `avoid_types_as_parameter_names` to handle type variables.
- update `avoid_positional_boolean_parameters` to handle typedefs.
- update `avoid_redundant_argument_values` to check parameters of redirecting
  constructors.
- improve performance for `prefer_const_literals_to_create_immutables`.
- update `use_build_context_synchronously` to check context properties.
- improve `unnecessary_parenthesis` support for property accesses and method
  invocations.
- update `unnecessary_parenthesis` to allow parentheses in more null-aware
  cascade contexts.
- update `unreachable_from_main` to track static elements.
- update `unnecessary_null_checks` to not report on arguments passed to
  `Future.value` or `Completer.complete`.
- mark `always_use_package_imports` and `prefer_relative_imports` as
  incompatible rules.
- update `only_throw_errors` to not report on `Never`-typed expressions.
- update `unnecessary_lambdas` to not report with `late final` variables.
- update `avoid_function_literals_in_foreach_calls` to not report with nullable-
  typed targets.
- add new lint: `deprecated_member_use_from_same_package` which replaces the
  soft-deprecated analyzer hint of the same name.
- update `public_member_api_docs` to not require docs on enum constructors.
- update `prefer_void_to_null` to not report on as-expressions.

#### Migration tool removal

The null safety migration tool (`dart migrate`) has been removed.  If you still
have code which needs to be migrated to null safety, please run `dart migrate`
using Dart version 2.19, before upgrading to Dart version 3.0.

#### Pub

- To preserve compatibility with null-safe code pre Dart 3, Pub will interpret a
  language constraint indicating a language version of `2.12` or higher and an
  upper bound of `<3.0.0` as `<4.0.0`.

  For example `>=2.19.2 <3.0.0` will be interpreted as `>=2.19.2 <4.0.0`.
- `dart pub publish` will no longer warn about `dependency_overrides`. Dependency
  overrides only take effect in the root package of a resolution.
- `dart pub token add` now verifies that the given token is valid for including
  in a header according to [RFC 6750 section
  2.1](https://www.rfc-editor.org/rfc/rfc6750#section-2.1). This means they must
  contain only the characters: `^[a-zA-Z0-9._~+/=-]+$`. Before a failure would
  happen when attempting to send the authorization header.
- `dart pub get` and related commands will now by default also update the
  dependencies in the `example` folder (if it exists). Use `--no-example` to
  avoid this.
- On Windows the `PUB_CACHE` has moved to `%LOCALAPPDATA%`, since Dart 2.8 the
  `PUB_CACHE` has been created in `%LOCALAPPDATA%` when one wasn't present.
  Hence, this only affects users with a `PUB_CACHE` created by Dart 2.7 or
  earlier. If you have `path/to/.pub-cache/bin` in `PATH` you may need to
  update your `PATH`.

## 2.19.6 - 2023-03-29

This is a patch release that:

- Fixes an `Out of Memory` exception due to a VM bug. (issue [#50537]).

[#50537]: https://github.com/dart-lang/sdk/issues/50537

## 2.19.5 - 2023-03-22

This is a patch release that:

- Fixes fixes broken usage of `Dart_CObject_Type`. (issue [#51459]).

[#51459]: https://github.com/dart-lang/sdk/issues/51459

## 2.19.4 - 2023-03-08

This is a patch release that:

- Fixes mobile devices vm crashes caused by particular use of RegExp. (issue
  [#121270][]).

[#121270]: https://github.com/flutter/flutter/issues/121270

## 2.19.3 - 2023-03-01

This is a patch release that:

- Updates DDC test and builder configuration. (issue [#51481][]).

- Protects the Dart Analysis Server against extreme memory usage by limiting
  the number of plugins per analysis context to 1. (issue [#50981][]).

[#50981]: https://github.com/dart-lang/sdk/issues/50981
[#51481]: https://github.com/dart-lang/sdk/issues/51481

## 2.19.2 - 2023-02-08

This is a patch release that:

- Fixes a VM crash when mixing the use of double and float calculations in
  debug/jit configuration. (issue [#50622][]).

- Fixes the compiler crashing when attempting to inline a method with lots of
  optional parameters with distinct default values. (issue [#119220][]).

- Fixes the `part_of_different_library` error encountered when using `PackageBuildWorkspace`. (issue [#51087][]).

[#50622]: https://github.com/dart-lang/sdk/issues/50622
[#119220]: https://github.com/flutter/flutter/issues/119220
[#51087]: https://github.com/dart-lang/sdk/issues/51087

## 2.19.1 - 2023-02-01

This is a patch release that:

- Fixes `pub get` behaviour: In Dart 2.19.0 a `dart pub get` with a
  `pubspec.lock` created by a 2.18 SDK will unlock all constraints, effectively
  like a `pub upgrade` (issue [#51166][]).

- Stops rewriting SDK constraints: In Dart 3, a SDK constraint like
  `>=2.12.0 <3.0.0` gets interpreted by the pub client as `>=2.12.0 <4.0.0` to
  allow for backwards compatibility (issue [#51101][]).

  This change was intended for Dart 3.0.0 and later, but was landed already in
  2.19.0. It is now being removed in 2.19.1, as it can give confusing messages
  such as:

  > Because library requires SDK version >=2.19.2 <4.0.0, version solving failed.

  This reinterpretation no longer happens in Dart 2.19.1.

- Fixes a VM crash caused by incorrect sharing of RegExp between isolates
  (issue [#51130][]).

[#51166]: https://github.com/dart-lang/sdk/issues/51166
[#51101]: https://github.com/dart-lang/sdk/issues/51101
[#51130]: https://github.com/dart-lang/sdk/issues/51130

## 2.19.0 - 2023-01-24

### Language

- **Breaking change** [#49635][]: Flag additional code as unreachable due to
  types `Null` and `Never`. Several unusual constructs that lead to unreachable
  code are now recognized by flow analysis:

  - Control flow after an expression of the form `e ?? other` or `e ??= other`,
    where `e` has static type `Null` and `other` has static type `Never`, is
    considered unreachable.

  - Control flow predicated on an expression of the form `e is Never` evaluating
    to `true` is considered unreachable.

  - Control flow predicated on an expression of the form `e is! Never`
    evaluating to `false` is considered unreachable.

  - Control flow on the RHS of a null-aware access such as `e?.property...`,
    `e?.property = ...` or `e?.method(...)`, where `e` has static type `Null`,
    is considered unreachable (Note: this can arise in the presence of extension
    methods).

  Previously, these behaviors only took effect if `e` was a reference to a local
  variable.

  Additionally, a type test of the form `v is Never` (where `v` is a local
  variable) no longer promotes `v` to type `Never`.

[#49635]: https://github.com/dart-lang/sdk/issues/49635

- **Breaking Change** [#49687][]: Don't delegate inaccessible private names to
  `noSuchMethod`. If a concrete class implements an interface containing a
  member with a name that's private to different library, and does not inherit
  an implementation of that interface member, a invocation of that member will
  result in an exception getting thrown. Previously, such attempts would result
  in the call being diverted to the `noSuchMethod` method.

  This change closes a loophole in Dart's privacy system, where another library
  can provide a different implementation of a supposedly private member using
  `noSuchMethod`, and paves the way for a future implementation of promotion for
  private final fields (see [#2020][]).

[#49687]: https://github.com/dart-lang/sdk/issues/49687
[#2020]: https://github.com/dart-lang/language/issues/2020

- **Breaking Change** [#50383][]: Report a compile-time error for all cyclic
  dependencies during top-level type inference.

  Previously, some of these dependencies were ignored, based on an analysis
  determining that they could not influence the inferred type. However, this
  analysis was complex, differed slightly among tools, and had become much more
  complex due to other changes (especially, enhanced flow analysis).

  With this change, all tools treat these cyclic dependencies in the same way,
  the analysis is well-understood, and, arguably, the code is more readable.

  Breakage is mitigated by adding a declared type to one top-level declaration
  per cycle which is now an error.

[#50383]: https://github.com/dart-lang/sdk/issues/50383

- Add support for **unnamed libraries**. Dart language 2.19 allows a library
  directive to be written without a name (`library;`). A library directive can
  be used for library-level annotations (such as `@deprecated`) and for
  library-level documentation comments, and with this new feature, you don't
  have to provide a unique name for each library directive. Instead, a name can
  simply be omitted (see [#1073][]).

[#1073]: https://github.com/dart-lang/language/issues/1073

### Libraries

#### `dart:convert`

- **Breaking change** [#34233]: The previously deprecated API
  [`DEFAULT_BUFFER_SIZE`] in `JsonUtf8Encoder` has been removed.

[#34233]: https://github.com/dart-lang/sdk/issues/34233
[`DEFAULT_BUFFER_SIZE`]: https://api.dart.dev/stable/2.17.6/dart-convert/JsonUtf8Encoder/DEFAULT_BUFFER_SIZE-constant.html

#### `dart:core`

- Deprecated `FallThroughError`. Has not been thrown since Dart 2.0
  (see [#49529]).
- Added `copyWith` extension method on `DateTime` (see [#24644]).
- Deprecated `RangeError.checkValidIndex` in favor of `IndexError.check`.
- Deprecated `IndexError` constructor in favor of `IndexError.withLength`
  constructor.
- Deprecated `NullThrownError` and `CyclicInitializationError`.
  Neither error is thrown by null safe code.
[#49529]: https://github.com/dart-lang/sdk/issues/49529
[#24644]: https://github.com/dart-lang/sdk/issues/24644

#### `dart:developer`

- **Breaking change** [#34233]: The previously deprecated APIs `kInvalidParams`,
  `kExtensionError`, `kExtensionErrorMax`, and `kExtensionErrorMin` in
  [`ServiceExtensionResponse`] have been removed. They have been replaced by
  `invalidParams`, `extensionError`, `extensionErrorMax`, and
  `extensionErrorMin`.
- Deprecated `UserTag.MAX_USER_TAGS` in favor of `UserTag.maxUserTags`.

[#34233]: https://github.com/dart-lang/sdk/issues/34233
[`ServiceExtensionResponse`]: https://api.dart.dev/stable/2.17.6/dart-developer/ServiceExtensionResponse-class.html#constants

#### `dart:ffi`

- **Breaking change** [#49935]: The runtime type argument of `Pointer` has
  changed to `Never` in preparation of completely removing the runtime type
  argument. `Pointer.toString` has changed to not report any type argument.

[#49935]: https://github.com/dart-lang/sdk/issues/49935

#### `dart:html`

- Add constructor and `slice` to `SharedArrayBuffer`.
- Deprecated `registerElement` and `registerElement2` in `Document` and
  `HtmlDocument`. These APIs were based on the deprecated Web Components v0.5
  specification and are not supported by browsers today. These APIs are expected
  to be deleted in a future release. See the related breaking change request
  [#49536](https://github.com/dart-lang/sdk/issues/49536).

#### `dart:io`

- **Breaking change** [#49305](https://github.com/dart-lang/sdk/issues/49305):
  Disallow negative or hexadecimal content-length headers.
- **Breaking change** [#49647](https://github.com/dart-lang/sdk/issues/49647):
  `File.create` now takes new optional `exclusive` `bool` parameter, and when it
  is `true` the operation will fail if target file already exists.
- **Breaking change** [#49878]: Calling `ResourceHandle.toFile()`,
  `ResourceHandle.toSocket()`, `ResourceHandle.toRawSocket()` or
  `ResourceHandle.toRawDatagramSocket()`, more than once now throws a
  `StateError`.

  The previous behavior would allow multiple Dart objects to refer to the same
  file descriptor, which would produce errors when one object was closed or
  garbage collected.

[#49878]: https://github.com/dart-lang/sdk/issues/49878

- Adds three new `FileSystemException` subclasses to handle common error cases:

  - `PathAccessException`: The necessary access rights are not available.
  - `PathExistsException`: The path being created already exists.
  - `PathNotFoundException`: The path being accessed does not exist.

[#12461]: https://github.com/dart-lang/sdk/issues/12461
[#50436]: https://github.com/dart-lang/sdk/issues/50436

#### `dart:isolate`

- Add `Isolate.run` to run a function in a new isolate.
- **Breaking change**: `SendPort.send` is again applying strict checks to the
  contents of the message when sending messages between isolates that are not
  known to share the same code (e.g. an isolate spawned via `Isolate.spawnUri`).
  These checks were accidentally relaxed in an earlier Dart version allowing
  all classes from `dart:core` and `dart:collection` through. This for
  example means that you can't send an instance of a `HashMap` to an isolate
  spawned via `Isolate.spawnUri`. See [`SendPort.send`] documentation for
  the full list of restrictions.

[`SendPort.send`]: https://api.dart.dev/stable/dart-isolate/SendPort/send.html

#### `dart:mirrors`

- **Breaking change** [#34233]: The APIs [`MirrorsUsed`] and [`Comment`] have
  been removed. `MirrorsUsed` was experimental and deprecated; `Comment` was
  previously used internally in dart2js. Both are no longer functional.

[#34233]: https://github.com/dart-lang/sdk/issues/34233
[`MirrorsUsed`]: https://api.dart.dev/stable/dart-mirrors/MirrorsUsed-class.html
[`Comment`]: https://api.dart.dev/stable/dart-mirrors/Comment-class.html

### Other libraries

#### `package:js`

- **Breaking changes to the preview feature `@staticInterop`**:
  - Classes with this annotation are now disallowed from using `external`
    generative constructors. Use `external factory`s for these classes instead,
    and the behavior should be identical. This includes use of synthetic
    constructors. See [#48730] and [#49941] for more details.
  - Classes with this annotation's external extension members are now disallowed
    from using type parameters e.g. `external void method<T>(T t)`. Use a
    non-`external` extension method for type parameters instead. See [#49350]
    for more details.
  - Classes with this annotation should also have the `@JS` annotation. You can
    also have the `@anonymous` annotation with these two annotations for an
    object literal constructor, but it isn't required.
  - Classes with this annotation can not be implemented by classes without this
    annotation. This is to avoid confusing type behavior.

[#48730]: https://github.com/dart-lang/sdk/issues/48730
[#49941]: https://github.com/dart-lang/sdk/issues/49941
[#49350]: https://github.com/dart-lang/sdk/issues/49350

### Tools

#### Analyzer

- add static enforcement of new `mustBeOverridden` annotation, and quick fixes
- add quick fixes for many diagnostics including compile-time errors, hints, and
  lints. There are now quick fixes for over 300 diagnostic codes. These lint
  rules have new fixes: `combinators_ordering`, `dangling_library_doc_comments`,
  `implicit_call_tearoffs`, `library_annotations`, and
  `unnecessary_library_directive`.
- add new hints: `body_might_complete_normally_catch_error`,
  `cast_from_null_always_fails`, `cast_from_nullable_always_fails`,
  `deprecated_colon_for_default_value`, and `duplicate_export`
- remove hint: `invalid_override_different_default_values`

#### Linter

Updated the Linter to `1.31.0`, which includes changes that

- add new lint: `collection_methods_unrelated_type`.
- add new lint: `combinators_ordering`.
- add new lint: `dangling_library_doc_comments`.
- add new lint: `enable_null_safety`.
- add new lint: `implicit_call_tearoffs`.
- add new lint: `library_annotations`.
- add new lint: `unnecessary_library_directive`.
- add new lint: `unreachable_from_main`.
- add new lint: `use_string_in_part_of_directives`.
- fix `no_leading_underscores_for_local_identifiers` to not report super formals
  as local variables.
- fix `unnecessary_overrides` false negatives.
- fix `cancel_subscriptions` for nullable fields.
- update `library_names` to support unnamed libraries.
- fix `unnecessary_parenthesis` support for as-expressions.
- fix `use_build_context_synchronously` to check for context property accesses.
- fix false positive in `comment_references`.
- improved unrelated type checks to handle enums and cascades.
- fix `unnecessary_brace_in_string_interps` for `this` expressions .
- update `use_build_context_synchronously` for `BuildContext.mounted`.
- improve `flutter_style_todos` to handle more cases.
- fix `use_build_context_synchronously` to check for `BuildContext`s in named
  expressions.
- fix `exhaustive_cases` to check parenthesized expressions
- update `avoid_redundant_argument_values` to work with enum declarations.
- fix `avoid_redundant_argument_values` when referencing required
  parameters in legacy libraries.
- fix `use_super_parameters` false positives with repeated super
  parameter references.
- update `use_late_for_private_fields_and_variables` to handle enums.
- fix `prefer_contains` false positives when a start index is non-zero.
- improve `noop_primitive_operations` to catch `.toString()`
  in string interpolations.
- update `public_member_api_docs` to report diagnostics on extension
  names (instead of bodies).
- fix `use_colored_box` and `use_decorated_box` to not over-report on containers without
  a child.
- fix `unnecessary_parenthesis` false positives on a map-or-set literal at the start of
  an expression statement.
- fix `prefer_final_locals` false positives reporting on fields.
- fix `unnecessary_overrides` to allow overrides on `@Protected`members.
- fix `avoid_multiple_declarations_per_line` false positives in `for` statements.
- fix `prefer_final_locals` false positives on declaration lists with at least one
  non-final variable.
- fix`use_build_context_synchronously` to handle `await`s in `if` conditions.
- improves performance for:
  - `avoid_escaping_inner_quotes`.
  - `avoid_null_checks_in_equality_operators`.
  - `avoid_positional_boolean_parameters`.
  - `avoid_returning_null`.
  - `avoid_returning_null`.
  - `avoid_returning_this`.
  - `cascade_invocations`.
  - `diagnostic_describe_all_properties`.
  - `flutter_style_todos`.
  - `join_return_with_statement`.
  - `parameter_assignments`.
  - `prefer_const_constructors`.
  - `prefer_constructors_over_static_methods`.
  - `prefer_constructors_over_static_methods`.
  - `prefer_contains`.
  - `prefer_foreach`.
  - `prefer_interpolation_to_compose_strings`.
  - `prefer_interpolation_to_compose_strings`.
  - `recursive_getters`.
  - `tighten_type_of_initializing_formals`.
  - `unnecessary_lambdas`.
  - `use_late_for_private_fields_and_variables`.

#### Pub

- Treats packages with sdk constraint lower bound `>=2.12.0` or more and upper
  bound `<3.0.0` as compatible with `<4.0.0`.
- Introduces content-hashes in pubspec.lock, to protect against corrupted
  package repositories.

  These will show up in the lock file on the first run of `dart pub get`.

  See https://dart.dev/go/content-hashes for more details.
- New flag `dart pub get --enforce-lockfile` will fetch dependencies, but fail
  if anything deviates from `pubspec.lock`. Useful for ensuring reproducible runs
  in CI and production.
- Remove remaining support for `.packages` files. The flag
  `--legacy-packages-file` is no longer supported.
- The client will now default to the `pub.dev` repository instead of `pub.dartlang.org`.
  This will cause a change in `pubspec.lock`.
- Support a new field [`funding`](https://dart.dev/tools/pub/pubspec#funding) in `pubspec.yaml`.
- Validate the CRC32c checksum of downloaded archives and retry on failure.
- `dart pub add foo:<constraint>` with an existing dependency will now update
  the constraint rather than fail.
- Update `dart pub publish` to allow `dependency_overrides` in `pubspec.yaml`.
  They will still cause a publication warning.
  Note that only `dependency_overrides` from the root package effect resolution.
- Update `dart pub publish` to require a working resolution.
  If publishing a breaking release of mutually dependent packages use `dependency_overrides`
  to obtain a resolution.
- `dart pub add` will now allow adding multiple packages from any source using
  the same YAML syntax as in `pubspec.yaml`.

  For example:
  ```console
  $ dart pub add retry:^1.0.0 'dev:foo{"git":"https://github.com/foo/foo"}'
  ```
- `dart pub publish` will now give a warning if `dart analyze` reports any diagnostics.
- `dart pub get` now fails gracefully when run from inside the pub-cache.
- `dart pub publish` now shows the file sizes of large files in your package to
  prevent accidental publication of large unrelated files.
- Fix a bug in `dart pub upgrade --major-versions` where packages not requiring
  major updates would be held back unless needed.

#### dart2js

- **Breaking change** [49473](https://github.com/dart-lang/sdk/issues/49473):
  dart2js no longer supports HTTP URIs as inputs.

## 2.18.5 - 2022-11-23

- fixes an error on private variable setters in mixins on dart web
  (issue [#50119][]).
- fixes the handling of type parameter nullability in factory constructors
  (issue [#50392][]).

[#50119]: https://github.com/dart-lang/sdk/issues/50119
[#50392]: https://github.com/dart-lang/sdk/issues/50392

## 2.18.4 - 2022-11-02

This is a patch release that fixes crashes during hot reload
(issue [flutter/flutter#113540][]).

[flutter/flutter#113540]: https://github.com/flutter/flutter/issues/113540

## 2.18.3 - 2022-10-19

This is a patch release that fixes a regression in code coverage computation
(issue [#49887][]).

[#49887]: https://github.com/dart-lang/sdk/issues/49887

## 2.18.2 - 2022-09-28

This is a patch release that:

- fixes incorrect behavior in `Uri.parse`.
- fixes a compiler crash (issue [#50052][]).

### Libraries

#### `dart:core`

- **Security advisory** [CVE-2022-3095](https://github.com/dart-lang/sdk/security/advisories/GHSA-m9pm-2598-57rj):
  There is a auth bypass vulnerability in Dart SDK, specifically `dart:uri` core
  library, used to parse and validate URLs. This library is vulnerable to the
  backslash-trick wherein backslash is not recognized as equivalent to forward
  slash in URLs.

  The `Uri` class has been changed to parse a backslash in the path or the
  authority separator of a URI as a forward slash. This affects the `Uri`
  constructor's `path` parameter, and the `Uri.parse` method.
  This change was made to not diverge as much from the browser `URL` behavior.
  The Dart `Uri` class is still not an implementation of the same standard
  as the browser's `URL` implementation.

[#50052]: https://github.com/dart-lang/sdk/issues/50052

## 2.18.1 - 2022-09-14

This is a patch release that fixes a crash caused by incorrect type inference
(issues [flutter/flutter#110715][] and [flutter/flutter#111088][]).

[flutter/flutter#110715]: https://github.com/flutter/flutter/issues/110715
[flutter/flutter#111088]: https://github.com/flutter/flutter/issues/111088

## 2.18.0 - 2022-08-30

### Language

The following features are new in the Dart 2.18 [language version][]. To use
them, you must set the lower bound on the SDK constraint for your package to
2.18 or greater (`sdk: '>=2.18.0 <3.0.0'`).

[language version]: https://dart.dev/guides/language/evolution

-  **[Enhanced type inference for generic invocations with function literals][]**:
   Invocations of generic methods/constructors that supply function literal
   arguments now have improved type inference. This primarily affects the
   `Iterable.fold` method. For example, in previous versions of Dart, the
   compiler would fail to infer an appropriate type for the parameter `a`:

   ```dart
   void main() {
     List<int> ints = [1, 2, 3];
     var maximum = ints.fold(0, (a, b) => a < b ? b : a);
   }
   ```

   With this improvement, `a` receives its type from the initial value, `0`.

   On rare occasions, the wrong type will be inferred, leading to a compile-time
   error, for example in this code, type inference will infer that `a` has a
   type of `Null`:

   ```dart
   void main() {
     List<int> ints = [1, 2, 3];
     var maximumOrNull = ints.fold(null,
         (a, b) => a == null || a < b ? b : a);
   }
   ```

   This can be worked around by supplying the appropriate type as an explicit
   type argument to `fold`:

   ```dart
   void main() {
     List<int> ints = [1, 2, 3];
     var maximumOrNull = ints.fold<int?>(null,
         (a, b) => a == null || a < b ? b : a);
   }
   ```
[Enhanced type inference for generic invocations with function literals]: https://github.com/dart-lang/language/issues/731

- **Breaking Change** [#48167](https://github.com/dart-lang/sdk/issues/48167):
  Mixin of classes that don't extend `Object` is no longer supported:
  ```dart
  class Base {}
  class Mixin extends Base {}
  class C extends Base with Mixin {}
  ```
  This should instead be written using a mixin declaration of `Mixin`:
  ```dart
  class Base {}
  mixin Mixin on Base {}
  class C extends Base with Mixin {}
  ```
  This feature has not been supported in most compilation targets for some
  time but is now completely removed.

### Core libraries

#### `dart:async`

- The `Stream.fromIterable` stream can now be listened to more than once.

#### `dart:collection`

- Deprecates `BidirectionalIterator`.

#### `dart:core`

- Allow omitting the `unencodedPath` positional argument to `Uri.http` and
  `Uri.https` to default to an empty path.

#### `dart:html`

- Add `connectionState` attribute and `connectionstatechange` listener to
  `RtcPeerConnection`.

#### `dart:io`

- **Breaking Change** [#49045](https://github.com/dart-lang/sdk/issues/49045):
  The `uri` property of `RedirectException` in `dart:io` has been changed to
  be nullable. Programs must be updated to handle the `null` case.
- **Breaking Change** [#34218](https://github.com/dart-lang/sdk/issues/34218):
  Constants in `dart:io`'s networking APIs following the `SCREAMING_CAPS`
  convention have been removed (they were previously deprecated). Please use
  the corresponding `lowerCamelCase` constants instead.

- **Breaking Change** [#45630][]: The Dart VM no longer automatically restores
    the initial terminal settings upon exit. Programs that change the `Stdin`
    settings `lineMode` and `echoMode` are now responsible for restoring the
    settings upon program exit. E.g. a program disabling `echoMode` will now
    need to restore the setting itself and handle exiting by the appropriate
    signals if desired:

    ```dart
    import 'dart:io';
    import 'dart:async';

    main() {
      bool echoWasEnabled = stdin.echoMode;
      try {
        late StreamSubscription subscription;
        subscription = ProcessSignal.sigint.watch().listen((ProcessSignal signal) {
          stdin.echoMode = echoWasEnabled;
          subscription.cancel();
          Process.killPid(pid, signal); /* Die by the signal. */
        });
        stdin.echoMode = false;
      } finally {
        stdin.echoMode = echoWasEnabled;
      }
    }
    ```

    This change is needed to fix [#36453][] where the dart programs not caring
    about the terminal settings can inadvertently corrupt the terminal settings
    when e.g. piping into less.

    Furthermore the `echoMode` setting now only controls the `echo` local mode
    and no longer sets the `echonl` local mode on POSIX systems (which controls
    whether newline are echoed even if the regular echo mode is disabled). The
    `echonl` local mode is usually turned off in common shell environments.
    Programs that wish to control the `echonl` local mode can use the new
    `echoNewlineMode` setting.

    The Windows console code pages (if not UTF-8) and ANSI escape code support
    (if disabled) remain restored when the VM exits.

[#45630]: https://github.com/dart-lang/sdk/issues/45630
[#36453]: https://github.com/dart-lang/sdk/issues/36453

#### `dart:js_util`

- Added `dartify` and a number of minor helper functions.

### Dart VM

Implementation of `async`/`async*`/`sync*` is revamped in Dart VM,
both in JIT and AOT modes. This also affects Flutter except Flutter Web.

Besides smaller code size and better performance of async methods,
the new implementation carries a few subtle changes in behavior:

- If `async` method returns before reaching the first `await`, it now
  returns a completed Future.
  Previously `async` methods completed resulting Future in separate microtasks.

- Stack traces no longer have duplicate entries for `async` methods.

- New implementation now correctly throws an error if `null` occurs as
  an argument of a logical expression (`&&` and `||`) which also contains
  an `await`.

- New implementation avoids unnecessary extending the liveness of local
  variables in `async`/`async*`/`sync*` methods, which means that unused
  objects stored in local variables in such methods might be garbage
  collected earlier than they were before
  (see issue [#36983](https://github.com/dart-lang/sdk/issues/36983)
  for details).

### Tools

#### General

- **Breaking Change** [#48272](https://github.com/dart-lang/sdk/issues/48272):
  The `.packages` file has been fully discontinued. Historically when the
  commands `dart pub get` or `flutter pub get` are executed, pub resolved all
  dependencies, and installs those dependencies to the local pub cache. It
  furthermore created a mapping from each used package to their location on the
  local file system, and wrote that into two files:

    * `.dart_tool/package_config.json`
    * `.packages` (deprecated in Dart 2.8.0)

  As of Dart 2.18.0, the `.packages` is now fully desupported, and all tools
  distributed in, and based on, the Dart SDK no longer support it, and thus
  solely use the `.dart_tool/package_config.json` file. If you've run `dart pub
  get` or `flutter pub get` with any Dart SDK from the past few years you
  already have a `.dart_tool/package_config.json` and thus should not be
  impacted. You can delete any old `.packages` files.

  If you have any third-party tools that for historical reasons depend on a
  `.packages` we will support the ability to generate a `.packages` by passing
  the flag `--legacy-packages-file` to `dart pub get`. This support will be
  removed in a following stable release.

#### Dart command line

- **Breaking change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The standalone `dart2js` and `dartdevc` tools have been removed as previously
  announced. `dart2js` is replaced by the `dart compile js` command, `dartdevc`
  is no longer exposed as a command-line tool.

- **Breaking change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The standalone `dartanalyzer` tool has been removed as previously
  announced. `dartanalyzer` is replaced by the `dart analyze` command.

#### Analyzer

- added quick fixes for diagnostics: `abstract_field_constructor_initializer`,
  `abstract_class_member`,
  [`always_put_control_body_on_new_line`](https://dart.dev/lints/always_put_control_body_on_new_line),
  [`avoid_print`](https://dart.dev/lints/avoid_print),
  [`avoid_renaming_method_parameters`](https://dart.dev/lints/avoid_renaming_method_parameters),
  [`discarded_futures`](https://dart.dev/lints/discarded_futures),
  `enum_with_abstract_member`, `non_bool_condition`,
  `super_formal_parameter_without_associated_named`,
  [`unawaited_futures`](https://dart.dev/lints/unawaited_futures),
  `unnecessary_final` `unused_element_parameter`,
- added new Hint: `deprecated_export_use`

#### Linter

Updated the Linter to `1.25.0`, which includes changes that

- add new lint: `discarded_futures`.
- add new lint: `unnecessary_null_aware_operator_on_extension_on_nullable`.
- add new lint: `unnecessary_to_list_in_spreads`.
- improve message and highlight range for `no_duplicate_case_values`
- improve performance for `lines_longer_than_80_chars`,
  `prefer_const_constructors_in_immutables`, and
  `prefer_initializing_formals`.
- fix `prefer_final_parameters` to support super parameters.
- fix `unawaited_futures` to handle string interpolated
  futures.
- update `use_colored_box` to not flag nullable colors,
- fix `no_leading_underscores_for_local_identifiers`
  to lint local function declarations.
- fix `avoid_init_to_null` to correctly handle super
  initializing defaults that are non-null.
- update `no_leading_underscores_for_local_identifiers`
  to allow identifiers with just underscores.
- fix `flutter_style_todos` to support usernames that
  start with a digit.
- update `require_trailing_commas` to handle functions
  in asserts and multi-line strings.
- update `unsafe_html` to allow assignments to
  `img.src`.
- fix `unnecessary_null_checks` to properly handle map
  literal entries.

#### Pub

* `dart pub get` and `dart pub upgrade` no longer create the
  `.packages` file. For details, see breaking change #48272 above.
* `dart pub outdated` now shows which of your dependencies are discontinued.
* `dart pub publish` will now list all the files it is about to publish.

## 2.17.7 - 2022-08-24

This is a patch release that:

- fixes a crash in the debugger (issue [#49209][]).

[#49209]: https://github.com/dart-lang/sdk/issues/49209

## 2.17.6 - 2022-07-13

This is a patch release that:

- improves code completion for Flutter (issue [#49054][]).
- fixes a crash on ARM (issue [#106510][]).
- fixes a compiler crash with Finalizable parameters (issue [#49402][]).

[#49054]: https://github.com/dart-lang/sdk/issues/49054
[#106510]: https://github.com/flutter/flutter/issues/106510
[#49402]: https://github.com/dart-lang/sdk/issues/49402

## 2.17.5 - 2022-06-22

This is a patch release that:

- improves analysis of enums and switch (issue [#49188][]).
- fixes a compiler crash when initializing Finalizable objects
  (issue [#49075][]).

[#49188]: https://github.com/dart-lang/sdk/issues/49188
[#49075]: https://github.com/dart-lang/sdk/issues/49075

## 2.17.3 - 2022-06-01

This is a patch release that fixes:

- a Dart VM compiler crash (issue [#100375][]).
- code completion when writing method overrides (issue [#49027][]).
- the `dart pub login` command (issue [#3424][]).
- analysis of enhanced enums (issue [#49097][]).

[#100375]: https://github.com/flutter/flutter/issues/100375
[#49027]: https://github.com/dart-lang/sdk/issues/49027
[#3424]: https://github.com/dart-lang/pub/issues/3424
[#49097]: https://github.com/dart-lang/sdk/issues/49097

## 2.17.1 - 2022-05-18

This is a patch release that fixes:

- an analyzer plugin crash (issue [#48682][]).
- Dart FFI support for `late` `Finalizable` variables (issue [#49024]).
- `dart compile` on macOS 10.15 (issue [#49010][]).

[#48682]: https://github.com/dart-lang/sdk/issues/48682
[#49024]: https://github.com/dart-lang/sdk/issues/49024
[#49010]: https://github.com/dart-lang/sdk/issues/49010

## 2.17.0 - 2022-05-11

### Language

The following features are new in the Dart 2.17 [language version][]. To use
them, you must set the lower bound on the SDK constraint for your package to
2.17 or greater (`sdk: '>=2.17.0 <3.0.0'`).

[language version]: https://dart.dev/guides/language/evolution

-   **[Enhanced enums with members][]**: Enum declarations can now define
    members including fields, constructors, methods, getters, etc. For example:

    ```dart
    enum Water {
      frozen(32),
      lukewarm(100),
      boiling(212);

      final int tempInFahrenheit;
      const Water(this.tempInFahrenheit);

      @override
      String toString() => "The $name water is $tempInFahrenheit F.";
    }
    ```

    Constructors must be `const` since enum values are always constants. If the
    constructor takes arguments, they are passed when the enum value is
    declared.

    The above enum can be used like so:

    ```dart
    void main() {
      print(Water.frozen); // prints "The frozen water is 32 F."
    }
    ```

[enhanced enums with members]: https://github.com/dart-lang/language/blob/master/accepted/future-releases/enhanced-enums/feature-specification.md

-   **[Super parameters][]**: When extending a class whose constructor takes
    parameters, the subclass constructor needs to provide arguments for them.
    Often, these are passed as parameters to the subclass constructor, which
    then forwards them to the superclass constructor. This is verbose because
    the subclass constructor must list the name and type of each parameter in
    its parameter list, and then explicitly forward each one as an argument to
    the superclass constructor.

    [@roy-sianez][] suggested [allowing `super.`][super dot] before a subclass
    constructor parameter to implicitly forward it to the corresponding
    superclass constructor parameter. Applying this feature to Flutter
    eliminated [nearly 2,000 lines of code][flutter super]. For example, before:

    ```dart
    class CupertinoPage<T> extends Page<T> {
      const CupertinoPage({
        required this.child,
        this.maintainState = true,
        this.title,
        this.fullscreenDialog = false,
        LocalKey? key,
        String? name,
        Object? arguments,
        String? restorationId,
      }) : super(
            key: key,
            name: name,
            arguments: arguments,
            restorationId: restorationId,
          );

      // ...
    }
    ```

    And using super parameters:

    ```dart
    class CupertinoPage<T> extends Page<T> {
      const CupertinoPage({
        required this.child,
        this.maintainState = true,
        this.title,
        this.fullscreenDialog = false,
        super.key,
        super.name,
        super.arguments,
        super.restorationId,
      });

      // ...
    }
    ```

    From our analysis, over 90% of explicit superclass constructor calls can be
    completely eliminated, using `super.` parameters instead.

[super parameters]: https://github.com/dart-lang/language/blob/master/working/1855%20-%20super%20parameters/proposal.md
[@roy-sianez]: https://github.com/roy-sianez
[super dot]: https://github.com/dart-lang/language/issues/1855
[flutter super]: https://github.com/flutter/flutter/pull/100905/files

-   **[Named args everywhere][]**: In a function call, Dart requires positional
    arguments to appear before named arguments. This can be frustrating for
    arguments like collection literals and function expressions that look best
    as the last argument in the argument list but are positional, like the
    `test()` function in the [test package][]:

    ```dart
    main() {
      test('A test description', () {
        // Very long function body here...
      }, skip: true);
    }
    ```

    It would be better if the `skip` argument appeared at the top of the call
    to `test()` so that it wasn't easily overlooked, but since it's named and
    the test body argument is positional, `skip` must be placed at the end.

    Dart 2.17 removes this restriction. Named arguments can be freely
    interleaved with positional arguments, allowing code like:

    ```dart
    main() {
      test(skip: true, 'A test description', () {
        // Very long function body here...
      });
    }
    ```

[named args everywhere]: https://github.com/dart-lang/language/blob/master/accepted/future-releases/named-arguments-anywhere/feature-specification.md
[test package]: https://pub.dev/packages/test

### Core libraries

#### `dart:core`

- Add `Finalizer` and `WeakReference` which can potentially detect when
  objects are "garbage collected".
- Add `isMimeType` method to `UriData` class, to allow case-insensitive
  checking of the MIME type.
- Add `isCharset` and `isEncoding` methods to `UriData` class,
  to allow case-insensitive and alternative-encoding-name aware checking
  of the MIME type "charset" parameter.
- Make `UriData.fromString` and `UriData.fromBytes` recognize and omit
  a "text/plain" `mimeType` even if it is not all lower-case.

#### `dart:ffi`

- Add `ref=` and `[]=` methods to the `StructPointer` and `UnionPointer`
  extensions. They copy a compound instance into a native memory region.
- Add `AbiSpecificInteger`s for common C types:
  - `char`
  - `unsigned char`
  - `signed char`
  - `short`
  - `unsigned short`
  - `int`
  - `unsigned int`
  - `long`
  - `unsigned long`
  - `long long`
  - `unsigned long long`
  - `uintptr_t`
  - `size_t`
  - `wchar_t`
- Add `NativeFinalizer` which can potentially detect when objects are
  "garbage collected". `NativeFinalizer`s run native code where `dart:core`'s
  `Finalizer`s run Dart code on finalization.

#### `dart:html`

- Add `scrollIntoViewIfNeeded` to `Element`. Previously, this method was nested
  within `scrollIntoView` based on the `ScrollAlignment` value. `scrollIntoView`
  is unchanged for now, but users who intend to use the native
  `Element.scrollIntoViewIfNeeded` should use the new `scrollIntoViewIfNeeded`
  definition instead.
- Change `Performance.mark` and `Performance.measure` to accept their different
  overloads. `mark` can now accept a `markOptions` map, and `measure` can now
  accept a `startMark` and `endMark`, or a `measureOptions` map. Both methods
  return their correct return types now as well - `PerformanceEntry?` and
  `PerformanceMeasure?`, respectively.

#### `dart:indexed_db`

- `IdbFactory.supportsDatabaseNames` has been deprecated. It will always return
  `false`.

#### `dart:io`

- **Breaking Change** [#47887](https://github.com/dart-lang/sdk/issues/47887):
  `HttpClient` has a new `connectionFactory` property, which allows socket
  creation to be customized. Classes that `implement HttpClient` may be broken
  by this change. Add the following method to your classes to fix them:

  ```dart
  void set connectionFactory(
      Future<ConnectionTask<Socket>> Function(
              Uri url, String? proxyHost, int? proxyPort)?
          f) =>
      throw UnsupportedError("connectionFactory not implemented");
  ```

- **Breaking Change** [#48093](https://github.com/dart-lang/sdk/issues/48093):
  `HttpClient` has a new `keyLog` property, which allows TLS keys to be logged
  for debugging purposes. Classes that `implement HttpClient` may be broken by
  this change. Add the following method to your classes to fix them:

  ```dart
  void set keyLog(Function(String line)? callback) =>
      throw UnsupportedError("keyLog not implemented");
  ```

- **Breaking Change** [#34218](https://github.com/dart-lang/sdk/issues/34218):
  Constants in `dart:io` following the `SCREAMING_CAPS` convention have been
  removed (they were previously deprecated).  Please use the corresponding
  `lowerCamelCase` constants instead.
- **Breaking Change** [#48513](https://github.com/dart-lang/sdk/issues/48513):
  Add a new `allowLegacyUnsafeRenegotiation` property to `SecurityContext`,
  which allows TLS renegotiation for client secure sockets.
- Add a optional `keyLog` parameter to `SecureSocket.connect` and
  `SecureSocket.startConnect`.
- Deprecate `SecureSocket.renegotiate` and `RawSecureSocket.renegotiate`,
  which were no-ops.

### Tools

#### Dart command line

- **Breaking change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The standalone `dart2js` tool has been
  marked deprecated as previously announced.
  Its replacement is the `dart compile js` command.
  Should you find any issues, or missing features, in the replacement
  command, kindly file [an issue](https://github.com/dart-lang/sdk/issues/new).

- **Breaking change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The standalone `dartdevc` tool has been marked deprecated as previously
  announced and will be deleted in a future Dart stable release.  This tool
  was intended for use only by build systems like bazel, `build_web_compilers`
  and `flutter_tools`. The functionality remains available for those systems,
  but it is no longer exposed as a command-line tool in the SDK.
  Please share any concerns in the
  [breaking change tracking issue](https://github.com/dart-lang/sdk/issues/46100).

- **Breaking change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The standalone `dartdoc` tool has been removed as
  previously announced. Its replacement is the `dart doc` command.

- The template names used in the `dart create` command have been simplified,
  and the current template names are now the set shown below. (Note: for
  backwards compatibility the former template names can still be used.)
```
          [console] (default)    A command-line application.
          [package]              A package containing shared Dart libraries.
          [server-shelf]         A server app using package:shelf.
          [web]                  A web app that uses only core Dart libraries.
```

#### Analyzer

- added quick fixes for diagnostics:
  [`always_use_package_imports`](https://dart.dev/lints/always_use_package_imports),
  [`avoid_void_async`](https://dart.dev/lints/avoid_void_async),
  [`cascade_invocations`](https://dart.dev/lints/cascade_invocations),
  `default_list_constructor`,
  [`must_call_super`](https://dart.dev/tools/diagnostic-messages#must_call_super),
  [`no_leading_underscores_for_local_identifiers`](https://dart.dev/lints/no_leading_underscores_for_local_identifiers),
  [`null_check_on_nullable_type_parameter`](https://dart.dev/lints/null_check_on_nullable_type_parameter),
  [`prefer_function_declarations_over_variables`](https://dart.dev/lints/prefer_function_declarations_over_variables),
  [`sort_constructors_first`](https://dart.dev/lints/sort_constructors_first),
  [`sort_unnamed_constructors_first`](https://dart.dev/lints/sort_unnamed_constructors_first),
  `undefined_enum_constant`,
  [`unnecessary_late`](https://dart.dev/lints/unnecessary_late),
  `unnecessary_null_aware_assignments`,
  [`use_enums`](https://dart.dev/lints/use_enums),
  [`use_raw_strings`](https://dart.dev/lints/use_raw_strings),
  [`use_super_parameters`](https://dart.dev/lints/use_super_parameters),
  `var_return_type`
- added many errors for invalid enhanced enums
- added new Hint: [`unnecessary_final`](https://dart.dev/tools/diagnostic-messages#unnecessary_final)
- added new FFI error: `compound_implements_finalizable`
- improved errors for invalid Unicode escapes in source code

#### Linter

Updated the Linter to `1.22.0`, which includes changes that

- fixes null-safe variance exceptions in `invariant_booleans`.
- updates `depend_on_referenced_packages` to treat `flutter_gen` as a virtual
  package, not needing an explicit dependency.
- updates `unnecessary_null_checks` and
  `null_check_on_nullable_type_parameter` to handle
  list/set/map literals, and `yield` and `await` expressions.
- fixes `unnecessary_null_aware_assignments` property-access
  false positives.
- adds new lint: `use_super_parameters`.
- adds new lint: `use_enums`.
- adds new lint: `use_colored_box`.
- improves performance for `sort_constructors`.
- improves docs for `always_use_package_imports`,
  `avoid_print`, and `avoid_relative_lib_imports` .
- updates `avoid_void_async` to skip `main` functions.
- updates `prefer_final_parameters` to not super on super params.
- updates lints for enhanced-enums and super-initializer language
  features.
- updates `unnecessary_late` to report on variable names.
- marks `null_check_on_nullable_type_parameter` stable.

#### Dartdoc

Updated dartdoc to 5.1.0, which includes changes that

- support the enhanced enums feature
- remove superfluous `[...]` links
- fix `categoryOrder` option
- display categorized extensions
- add annotations to extensions
- make minor improvements to performance

## 2.16.2 - 2022-03-24

This is a patch release that fixes a dart2js crash when building some Flutter
web apps (issue [#47916][]).

[#47916]: https://github.com/dart-lang/sdk/issues/47916

## 2.16.1 - 2022-02-09

This is a patch release that fixes an AOT precompiler crash when building some
Flutter apps (issue [flutter/flutter#97301][]).

[flutter/flutter#97301]: https://github.com/flutter/flutter/issues/97301

## 2.16.0 - 2022-02-03

### Core libraries

#### `dart:core`

- Add `Error.throwWithStackTrace` which can `throw` an
  error with an existing stack trace, instead of creating
  a new stack trace.

#### `dart:ffi`

- Add `Abi` and `AbiSpecificInteger`. These enable specifying integers which
  have different sizes/signs per ABI (hardware and OS combination).

#### `dart:io`

- **Security advisory**
  [CVE-2022-0451](https://github.com/dart-lang/sdk/security/advisories/GHSA-c8mh-jj22-xg5h),
  **breaking change** [#45410](https://github.com/dart-lang/sdk/issues/45410):
  `HttpClient` no longer transmits some headers (i.e. `authorization`,
  `www-authenticate`, `cookie`, `cookie2`) when processing redirects to a
  different domain.
- **Breaking change** [#47653](https://github.com/dart-lang/sdk/issues/47653):
  On Windows, `Directory.rename` will no longer delete a directory if
  `newPath` specifies one. Instead, a `FileSystemException` will be thrown.
- **Breaking change** [#47769](https://github.com/dart-lang/sdk/issues/47769):
  The `Platform.packageRoot` API has been removed. It had been marked deprecated
  in 2018, as it doesn't work with any Dart 2.x release.
- Add optional `sourcePort` parameter to `Socket.connect`, `Socket.startConnect`, `RawSocket.connect` and `RawSocket.startConnect`

#### `dart:isolate`

- **Breaking change** [#47769](https://github.com/dart-lang/sdk/issues/47769):
The `Isolate.packageRoot` API has been removed. It had been marked deprecated
in 2018, as it doesn't work with any Dart 2.x release.

### Tools

#### Dart command line

- **Breaking change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The standalone `dartanalyzer` tool has been
  marked deprecated as previously announced.
  Its replacement is the `dart analyze` command.
  Should you find any issues, or missing features, in the replacement
  command, kindly file [an issue][].

[an issue]: https://github.com/dart-lang/sdk/issues/new

- **Breaking change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The standalone `dartdoc` tool has been
  marked deprecated as previously announced.
  Its replacement is the `dart doc` command.
  Should you find any issues, or missing features, in the replacement
  command, kindly file [an issue][].

[an issue]: https://github.com/dart-lang/sdk/issues/new

- **Breaking Change** [#46100](https://github.com/dart-lang/sdk/issues/46100):
  The deprecated standalone `pub` tool has been removed.
  Its replacement is the `dart pub` command.
  Should you find any issues, or missing features, in the replacement
  command, kindly file [an issue][].

[an issue]: https://github.com/dart-lang/pub/issues/new

#### Pub

- Fixed race conditions in `dart pub get`, `dart run` and `dart pub global run`.
  It should now be safe to run these concurrently.
- If (when) Pub crashes it will save a verbose log in
  `$PUB_CACHE/log/pub_log.txt` This can be used for filing issues to the issue
  tracker.

  `dart --verbose pub [command]` will also cause the log file to be written.
- `dart pub global activate --source=git` now takes arguments `--git-path` to
  specify the path of the activated package in the pubspec and `--git-ref` to
  specify the branch or revision to check out.
- `dart pub add` can now add multiple packages in one command.
- `dart pub token add` can now add a token for [pub.dev](https://pub.dev).
- `dart pub uploader` has been removed. To manage uploaders for a package use
  the `https://pub.dev/<packagename>/admin` web-interface.
- Pub now supports a separate `pubspec_overrides.yaml` file that can contain
  `dependency_overrides`. This makes it easier to avoid checking the local
  overrides into version control.

#### Linter

Updated the Linter to `1.18.0`, which includes changes that

- extends `camel_case_types` to cover enums.
- fixes `no_leading_underscores_for_local_identifiers` to not
  mis-flag field formal parameters with default values.
- fixes `prefer_function_declarations_over_variables` to not
  mis-flag non-final fields.
- improves performance for `prefer_contains`.
- updates `exhaustive_cases` to skip deprecated values that
  redirect to other values.
- adds new lint: `unnecessary_late`.
- improves docs for `prefer_initializing_formals`.
- updates `secure_pubspec_urls` to check `issue_tracker` and
  `repository` entries.
- adds new lint: `conditional_uri_does_not_exist`.
- improves performance for
  `missing_whitespace_between_adjacent_strings`.
- adds new lint: `avoid_final_parameters`.
- adds new lint: `no_leading_underscores_for_library_prefixes`.
- adds new lint: `no_leading_underscores_for_local_identifiers`.
- adds new lint: `secure_pubspec_urls`.
- adds new lint: `sized_box_shrink_expand`.
- adds new lint: `use_decorated_box`.
- improves docs for `omit_local_variable_types`.

## 2.15.1 - 2021-12-14

This is a patch release that fixes:

- an AOT compilation failure in some Flutter apps (issue [#47878][]).
- `dart pub publish` for servers with a path in the URL (pr
  [dart-lang/pub#3244][]).

[#47878]: https://github.com/dart-lang/sdk/issues/47878
[dart-lang/pub#3244]: https://github.com/dart-lang/pub/pull/3244

## 2.15.0 - 2021-12-08

- **Security advisory**
  [CVE-2021-22567](https://github.com/dart-lang/sdk/security/advisories/GHSA-8pcp-6qc9-rqmv):
  Bidirectional Unicode text can be interpreted and compiled differently than
  how it appears in editors and code-review tools. Exploiting this an attacker
  could embed source that is invisible to a code reviewer but that modifies the
  behavior of a program in unexpected ways. Dart 2.15.0 introduces new analysis
  warnings that flags the use of these.

- **Security advisory**
  [CVE-2021-22568](https://github.com/dart-lang/sdk/security/advisories/GHSA-r32f-vhjp-qhj7):
  A malicious third-party package repository may impersonate a user on pub.dev
  for up to one hour after the user has published a package to that third-party
  package repository using `dart pub publish`. As of Dart SDK version 2.15.0
  requests to third-party package repositories will no longer include an OAuth2
  `access_token` intended for pub.dev.

### Language

The following features are new in the Dart 2.15 [language version][]. To use
them, you must set the lower bound on the SDK constraint for your package to
2.15 or greater (`sdk: '>=2.15.0 <3.0.0'`).

[language version]: https://dart.dev/guides/language/evolution

- **[Constructor tear-offs][]**: Previous Dart versions allowed a method on an
  instance to be passed as a closure, and similarly for static methods. This is
  commonly referred to as "closurizing" or "tearing off" a method. Constructors
  were not previously eligible for closurization, forcing users to explicitly
  write wrapper functions when using constructors as first class functions.
  See the calls to `map()` in this example:

  ```dart
  class A {
    int x;
    A(this.x);
    A.fromString(String s) : x = int.parse(s);
  }

  void main() {
    var listOfInts = [1, 2, 3];
    var listOfStrings = ["1", "2", "3"];
    for(var a in listOfInts.map((x) => A(x))) {
      print(a.x);
    }
    for(var a in listOfStrings.map((x) => A.fromString(x))) {
      print(a.x);
    }
  }
  ```

  New in Dart 2.15, constructors are now allowed to be torn off. Named
  constructors are closurized using their declared name (here `A.fromString`).
  To closurize unnamed constructors, use the keyword `new` (here `A.new`).
  The above example may now be written as:

  ```dart
  class A {
    int x;
    A(this.x);
    A.fromString(String s) : x = int.parse(s);
  }

  void main() {
    var listOfInts = [1, 2, 3];
    var listOfStrings = ["1", "2", "3"];
    for(A a in listOfInts.map(A.new)) {
      print(a.x);
    }
    for(A a in listOfStrings.map(A.fromString)) {
      print(a.x);
    }
  }
  ```

  Constructors for generic classes may be torn off as generic functions, or
  instantiated at the tear-off site. In the following example, the tear-off
  `G.new` is used to initialize the variable `f` produces a generic function
  which may be used to produce an instance of `G<T>` for any type `T` provided
  when `f` is called. The tear-off `G<String>.new` is used to initialize the
  variable `g` to produce a non-generic function which may only be used
  to produce instances of type `G<String>`.

  ```dart
  class G<T> {
    T x;
    G(this.x);
  }

  void main() {
    G<T> Function<T>(T x) f = G.new;
    var x = f<int>(3);
    G<String> Function(String y) g = G<String>.new;
    var y = g("hello");
  }
  ```

[constructor tear-offs]: https://github.com/dart-lang/language/blob/master/accepted/2.15/constructor-tearoffs/feature-specification.md

- **[Generic type literals][explicit instantiation]**: Previous Dart versions
  allowed class names to be used as type literals. So for example,`int` may be
  used as an expression, producing a value of type `Type`. Generic classes (e.g.
  `List`) could be referred to by name as an expression, but no type arguments
  could be provided and so only the `dynamic` instantiation could be produced
  directly as an expression without using indirect methods:

  ```dart
  // Workaround to capture generic type literals.
  Type typeOf<T>() => T;

  void main() {
    var x = int; // The Type literal corresponding to `int`.
    var y = List; // The Type literal corresponding to `List<dynamic>`.
    // Use workaround to capture generic type literal.
    var z = typeOf<List<int>>(); // The Type literal for `List<int>`.
  }
  ```

  New in Dart 2.15, instantiations of generic classes may now be used as Type
  literals:

  ```dart
  void main() {
    var x = int; // The Type literal corresponding to `int`.
    var y = List; // The Type literal corresponding to `List<dynamic>`.
    var z = List<int>; // The Type literal corresponding to `List<int>`.
  }
  ```

- **[Explicit generic method instantiations][explicit instantiation]**: Previous
  Dart versions allowed generic methods to be implicitly specialized (or
  "instantiated") to non-generic versions when assigned to a location with a
  compatible monomorphic type. Example:

  ```dart
  // The generic identity function.
  T id<T>(T x) => x;

  void main() {
    // Initialize `intId` with a version of `id` implicitly specialized to
    // `int`.
    int Function(int) intId = id;
    print(intId(3));
    // Initialize `stringId` with a version of `id` implicitly specialized to
    // `String`.
    String Function(String) stringId = id;
    print(stringId("hello"));
  }
  ```

  New in Dart 2.15, generic methods may be explicitly instantiated using the
  syntax `f<T>` where `f` is the generic method to specialize and `T` is the
  type argument (in general, type arguments) to be used to specialize the
  method. Example:

  ```dart
  // The generic identity function.
  T id<T>(T x) => x;

  void main() {
    // Initialize `intId` with a version of `id` explicitly specialized to
    // `int`.
    var intId = id<int>;
    print(intId(3));
    // Initialize `stringId` with a version of `id` explicitly specialized to
    // `String`.
    var stringId = id<String>;
    print(stringId("hello"));
  }
  ```

[explicit instantiation]: https://github.com/dart-lang/language/blob/master/accepted/2.15/constructor-tearoffs/feature-specification.md#explicitly-instantiated-classes-and-functions

- **[Generic instantiation of function objects][object instantiation]**: Generic
  function instantiation was previously restricted to function declarations. For
  example, as soon as a function had been torn off, it could not be
  instantiated:

  ```dart
  // Before Dart 2.15:
  X id<X>(X x) => x;

  void main() {
    var fo = id; // Tear off `id`, creating a function object.
    var c1 = fo<int>; // Compile-time error: can't instantiate `fo`.
    int Function(int) c2 = fo; // Same compile-time error.
    // Constants are treated the same.
  }
  ```

  New in Dart 2.15, this restriction has been lifted. It is now possible
  to obtain a generic instantiation of an existing function object, both
  explicitly and implicitly (again, this works the same for non-constants):

  ```dart
  X id<X>(X x) => x;
  X other<X>(X x) => throw x;

  void main() {
    const fo = id; // Tear off `id`, creating a function object.

    // Generic function instantiation on `fo` is no longer an error.
    const c1 = fo<int>; // OK.
    const int Function(int) c2 = fo; // OK.

    // This also generalizes function instantiation because we can,
    // e.g., use non-trivial expressions and go via a constructor.
    const c3 = A(true); // OK.
  }

  class A {
    final int Function(int) x;
    // `(...)<T>` is now allowed, also in a `const` constructor.
    const A(bool b): x = (b ? id : other)<int>;
  }
  ```

[Object instantiation]: https://github.com/dart-lang/language/pull/1812

- Annotations on type parameters of classes can no longer refer to class members
  without a prefix.  For example, this used to be permitted:

  ```dart
  class C<@Annotation(foo) T> {
    static void foo() {}
  }
  ```

  Now, the reference must be qualified with the class name, i.e.:

  ```dart
  class C<@Annotation(C.foo) T> {
    static void foo() {}
  }
  ```

  This brings the implementation behavior in line with the spec.

- Initializer expressions on implicitly typed condition variables can now
  contribute to type promotion.  For example, this program no longer produces a
  compile-time error:

  ```dart
  f(int? i) {
    var iIsNull = i == null;
    if (!iIsNull) {
      print(i + 1); // OK, because `i` is known to be non-null.
    }
  }
  ```

  Previously, the above program had a compile-time error due to a bug
  ([#1785][]) in type promotion which prevented the initializer expression
  (`i == null`) from being accounted for when the variable in question
  (`iIsNull`) lacked an explicit type.

  To avoid causing problems for packages that are intended to work with older
  versions of Dart, the fix only takes effect when the minimum SDK of the source
  packages is 2.15 or greater.

[#1785]: https://github.com/dart-lang/language/issues/1785

- Restrictions on members of a class with a constant constructor are relaxed
  such that they only apply when the class has a _generative_ constant
  constructor. For example, this used to be an error, but is now permitted:

  ```dart
  abstract class A {
    const factory A() = B;
    var v1;
    late final v2 = Random().nextInt(10);
    late final v3;
  }

  class B implements A {
    const B([this.v3 = 1]);
    get v1 => null;
    set v1(_) => throw 'Cannot mutate B.v1';
    final v2 = 0;
    final v3;
    set v3(_) => throw 'Cannot initialize B.v3';
  }
  ```

  This implements a relaxation of the specified rule for a `late final`
  instance variable, and it brings the implementation behavior in line with
  the specification in all other cases.

- **Function object canonicalization and equality**: Several corner cases in the
  area of function object canonicalization and function object equality have
  been updated, such that all tools behave in the same way, and the behavior
  matches the specification.

  In particular, function objects are now equal when they are obtained by
  generic instantiation from the same function with the same actual type
  arguments, even when that type argument is not known at compile time.
  When the expressions are constant then the function objects are identical.
  Constant expressions are treated as such even when they do not occur in a
  constant context (e.g., `var f = top;`).

### Core libraries

#### `dart:async`

- Make the `unawaited` function's argument nullable, to allow calls like
  `unawaited(foo?.bar())`.

#### `dart:cli`

- The experimental `waitFor` functionality, and the library containing only that
  function, are now deprecated.

#### `dart:core`

- Add extension `name` getter on enum values.
- Add `Enum.compareByIndex` helper function for comparing enum values by index.
- Add `Enum.compareByName` helper function for comparing enum values by name.
- Add extension methods on `Iterable<T extends Enum>`, intended for
  `SomeEnumType.values` lists, to look up values by name.
- Deprecate `IntegerDivisionByZeroException`.
  Makes the class also implement `Error`. Code throwing the exception will be
  migrated to throwing an `Error` instead until the class is unused and
  ready to be removed.
  Code catching the class should move to catching `Error` instead
  (or, for integers, check first for whether it's dividing by zero).

#### `dart:ffi`

- Add `Bool` native type.

#### `dart:io`

- **Breaking change** [#46875](https://github.com/dart-lang/sdk/issues/46875):
  The `SecurityContext` class in `dart:io` has been updated to set the minimum
  TLS protocol version to TLS1_2_VERSION (1.2) instead of TLS1_VERSION.
- Add `RawSocket.sendMessage`, `RawSocket.receiveMessage` that allow passing of
  file handle references via Unix domain sockets.

#### `dart:js_util`

- The `js_util` methods `setProperty`, `callMethod`, and `callConstructor` have
  been optimized to remove checks on arguments when the checks can be elided.
  Also, those methods, along with `getProperty` and `newObject`, now support a
  generic type argument to specify a return type. These two changes make simple
  `js_util` usage, like reading and writing primitive properties or calling
  methods with simple arguments, have zero overhead.

#### `dart:web_sql`

- **Breaking change** [#46316](https://github.com/dart-lang/sdk/issues/46316):
  The WebSQL standard was abandoned more than 10
  years ago and is not supported by many browsers. This release completely
  deletes the `dart:web_sql` library.

#### `dart:html`

- **Breaking change** [#46316](https://github.com/dart-lang/sdk/issues/46316):
  Related to the removal of `dart:web_sql` (see above), `window.openDatabase`
  has been removed.

### Tools

#### Dart command line

- **Breaking change** [#46100][]: The standalone `dart2native` tool has been
  removed as previously announced. Its replacements are the
  `dart compile exe` and `dart compile aot-snapshot` commands, which offer the
  same functionality.

- **Breaking change**: The standalone `dartfmt` tool has been removed as
  previously announced. Its replacement is the `dart format` command.

  Note that `dart format` has [a different set of options and
  defaults][dartfmt cli] than `dartfmt`.

- When a script is `dart run` it will always be precompiled, but with
  incremental precompilation for following runs.

#### Dart VM

- **Breaking change** [#45451](https://github.com/dart-lang/sdk/issues/45451):
  Support for `dart-ext:`-style native extensions has been removed as previously
  announced. Use `dart:ffi` to bind to native libraries instead.

- **Breaking change** [#46754](https://github.com/dart-lang/sdk/issues/46754):
  Isolates spawned via the `Isolate.spawn()` API are now grouped, operate on the
  same managed heap and can therefore share various VM-internal data structures.

  This leads to ~100x faster isolate startup latency, ~10-100x lower
  per-isolate base memory overhead and ~8x faster inter-isolate communication.

  Making isolates operate on the same heap will also make them collaborate on
  garbage collections, which changes performance characteristics for GC-heavy
  applications that may - in rare cases - negatively affect pause times or
  throughput.

- Allow closures both in inter-isolate messages as well as as entrypoints in
  `Isolate.spawn(<entrypoint>, ...)` calls. Closures and their enclosing context
  may need to be copied in this process. The enclosing context is - as with
  normal messages - verified to only contain objects that are sendable.

  Note of caution: The Dart VM's current representation of enclosing variables
  in closures can make closures hang on to more variables than strictly needed.
  Using such closures in inter-isolate communication can therefore lead to
  copying of larger transitive object graphs. If the extended transitive
  closure includes objects that are illegal to send, the sending will fail.
  See [#36983](https://github.com/dart-lang/sdk/issues/36983), which tracks this
  existing memory leak issue.

#### Linter

Updated the Linter to `1.14.0`, which includes changes that
- improves performance for `annotate_overrides`, `prefer_contains`, and
  `prefer_void_to_null`.
- marks `avoid_dynamic_calls` stable.
- fixed `avoid_null_checks_in_equality_operators` false positive with
  non-nullable params.
- update `avoid_print` to allow `kDebugMode`-wrapped print calls.
- adds support for constructor tear-offs to `avoid_redundant_argument_values`,
  `unnecessary_lambdas`, and `unnecessary_parenthesis`.
- improves messages for `avoid_renaming_method_parameters`.
- improves regular expression parsing performance for common checks
  (`camel_case_types`, `file_names`, etc.).
- fixed `file_names` to report at the start of the file
  (not the entire compilation unit).
- allow `while (true) { ... }` in `literal_only_boolean_expressions`.
- fixed `omit_local_variable_types` false positives.
- fixed `omit_local_variable_types` to not flag a local type that is required
  for inference.
- fixed `overridden_fields` false positive with static fields.
- fixed `prefer_collection_literals` named typed parameter false positives.
- fixed `prefer_const_constructors` false positive for deferred imports.
- fixed `prefer_final_parameters` handling of initializing formals.
- fixed `prefer_generic_function_type_aliases` false positives with incomplete
  statements.
- fixed `prefer_initializing_formals` false positives with factory constructors.
- fixed `prefer_void_to_null` false positive with overridden properties.
- fixed `prefer_void_to_null` false positives on overriding returns.
- fixed `prefer_void_to_null` false positives.
- adds a new lint: `unnecessary_constructor_name` to flag unnecessary uses of
  `.new`.
- updates `unnecessary_getters_setters` to only flag the getter.
- fixed `unnecessary_parenthesis` false positive with function expressions.
- fixed `use_build_context_synchronously` false positive in awaits inside
  anonymous functions.
- improve control flow analysis for `use_build_context_synchronously`.
- fixed `use_rethrow_when_possible` false positives.
- fixed `void_checks` false positives with incomplete source.

### Pub

- If you have analytics enabled `dart pub get` will send
  [usage metrics](https://github.com/dart-lang/pub/blob/0035a40f25d027130c0314571da53ffafc6d973b/lib/src/solver/result.dart#L131-L175)
  for packages from pub.dev, intended for popularity analysis.
- Adds support for token-based authorization to third-party package-repositories
  with the new command `dart pub token`.
- Credentials are no longer stored in the pub-cache, but in a platform dependent
  config directory:
  * On Linux `$XDG_CONFIG_HOME/dart/pub-credentials.json` if `$XDG_CONFIG_HOME`
    is defined, otherwise `$HOME/.config/dart/pub-credentials.json`
  * On Mac OS: `$HOME/Library/Application Support/dart/pub-credentials.json`
  * On Windows: `%APPDATA%/dart/pub-credentials.json`
- The syntax for dependencies hosted at a third-party package repository has
  been simplified. Before you would need to write:

```yaml
dependencies:
  colorizer:
    hosted:
      name: colorizer
      url: 'https://custom-pub-server.com'
    version: ^1.2.3
environment:
  sdk: '>=2.14.0 < 3.0.0'
```

Now you can write:

```yaml
dependencies:
  colorizer:
    hosted: 'https://custom-pub-server.com'
    version: ^1.2.3
environment:
  sdk: '>=2.15.0 < 3.0.0'
```

This feature requires
[language-version](https://dart.dev/guides/language/evolution#language-versioning)
2.15 or later, e.g. the `pubspec.yaml` should have an SDK constraint of
`>=2.15 <3.0.0`.

- Detect potential leaks in `dart pub publish`.
  When publishing, pub will examine your files for potential secret keys, and
  warn you.

  To ignore a file that has a false positive, add it to a
  [`false_secrets`](https://dart.dev/go/false-secrets) section of your
  `pubspec.yaml`.
- Fixes unicode terminal detection windows.
- New flag `--example` to the commands
  `dart pub get/upgrade/downgrade/add/remove` that will result in the `example/`
  folder dependencies to be updated after operating in the current directory.

### Other libraries

#### `package:js`

- Extensions on JS interop or native `dart:html` classes can now declare
  members as `external`. These members are equivalent to regular extension
  members that use `js_util` to expose the underlying JavaScript.

## 2.14.4 - 2021-10-14

This is a patch release that fixes:

- a memory leak of analyzer plugins (issue [flutter/flutter#90868][]).
- the Dart VM sometimes loading expired certificates on Windows (issues
  [#46370][] and [#47420][]).

[flutter/flutter#90868]: https://github.com/flutter/flutter/issues/90868
[#46370]: https://github.com/dart-lang/sdk/issues/46370
[#47420]: https://github.com/dart-lang/sdk/issues/47420

## 2.14.3 - 2021-09-30

This is a patch release that fixes:

- a code completion performance regression (issue
  [flutter/flutter-intellij#5761][]).
- debug information emitted by the Dart VM (issue [#47289][]).

[flutter/flutter-intellij#5761]:
  https://github.com/flutter/flutter-intellij/issues/5761
[#47289]: https://github.com/dart-lang/sdk/issues/47289

## 2.14.2 - 2021-09-16

This is a patch release that fixes:

- two dartdoc crashes (issues [dart-lang/dartdoc#2740][] and
  [dart-lang/dartdoc#2755][]).
- error messages when using the `>>>` operator on older language versions
  (issue [#46886][]).
- invalid `pubspec.lock` paths on Windows (issue [dart-lang/pub#3012][]).

[dart-lang/dartdoc#2740]: https://github.com/dart-lang/dartdoc/issues/2740
[dart-lang/dartdoc#2755]: https://github.com/dart-lang/dartdoc/issues/2755
[#46886]: https://github.com/dart-lang/sdk/issues/46886
[#45767]: https://github.com/dart-lang/sdk/issues/45767
[dart-lang/pub#3012]: https://github.com/dart-lang/pub/issues/3012

## 2.14.1 - 2021-09-09

- Fixed an issue specific to the macOS ARM64 (Apple Silicon) SDK, where the Dart
  commandline tools did not have the expected startup performance.

## 2.14.0 - 2021-09-09

### Language

- Add an unsigned shift right operator `>>>`. Pad with zeroes, ignoring the sign
  bit. On the web platform `int.>>>` shifts the low 32 bits interpreted as an
  unsigned integer, so `a >>> b` gives the same result as
  `a.toUnsigned(32) >>> b` on the VM.

- Prior to Dart 2.14, metadata (annotations) were not permitted to be specified
  with generic type arguments. This restriction is lifted in Dart 2.14.

  ```dart
  class C<T> {
    const C();
  }
  @C();      // Previously permitted.
  @C<int>(); // Previously an error, now permitted.
  ```

- Prior to Dart 2.14, generic function types were not permitted as arguments to
  generic classes or functions, nor to be used as generic bounds. This
  restriction is lifted in Dart 2.14.

  ```dart
  T wrapWithLogging<T>(T f) {
    if (f is void Function<T>(T x)) {
      return <S>(S x) {
        print("Call: f<$S>($x)");
        var r = f<S>(x);
        print("Return: $x");
        return r;
      } as T;
    } // More cases here
    return f;
  }
  void foo<T>(T x) {
    print("Foo!");
  }
  void main() {
    // Previously an error, now permitted.
    var f = wrapWithLogging<void Function<T>(T)>(foo);
    f<int>(3);
  }
  ```

### Core libraries

#### `dart:async`

- The uncaught error handlers of `Zone`s are now run in the parent zone of the
  zone where they were declared. This prevents a throwing handler from causing
  an infinite loop by repeatedly triggering itself.

- Added `ignore()` as extension member on futures.

- Added `void unawaited(Future)` top-level function to deal with the
  `unawaited_futures` lint.

#### `dart:core`

- Introduce `Enum` interface implemented by all `enum` declarations.

- The native `DateTime` class now better handles local time around daylight
  saving changes that are not precisely one hour. (No change on the Web which
  uses the JavaScript `Date` object.)

- Adds static methods `hash`, `hashAll` and `hashAllUnordered` to the `Object`
  class. These can be used to combine the hash codes of multiple objects in a
  consistent way.

- The `Symbol` constructor now accepts any string as argument. Symbols are equal
  if they were created from the same string.


#### `dart:ffi`

- Add the `DynamicLibrary.providesSymbol` function to check whether a symbol is
  available in a dynamic library.
- Add `Union` native type for interacting with unions in native memory.

#### `dart:html`

- `convertNativeToDart_Dictionary()` now converts objects recursively, this
  fixes APIs like MediaStreamTrack.getCapabilities that convert between Maps and
  browser Dictionaries. [#44319]
- Added some access-control HTTP header names to `HttpHeaders`.

[#44319]: https://github.com/dart-lang/sdk/issues/44319

#### `dart:io`

- BREAKING CHANGE (for pre-migrated null safe code): `HttpClient`'s
  `.authenticate` and `.authenticateProxy` setter callbacks must now accept a
  nullable `realm` argument.
- Added some access-control HTTP header names to `HttpHeaders`.

#### `dart:typed_data`

- **BREAKING CHANGE** (https://github.com/dart-lang/sdk/issues/45115) Most types
  exposed by this library can no longer be extended, implemented or mixed-in.
  The affected types are `ByteBuffer`, `TypedData` and _all_ its subclasses,
  `Int32x4`, `Float32x4`, `Float64x2` and `Endian`.

#### `dart:web_sql`

- `dart:web_sql` is marked deprecated and will be removed in an upcoming
  release. Also the API `window.openDatabase` in `dart:html` is deprecated as
  well.

  This API and library was exposing the WebSQL proposed standard. The standard
  was abandoned more than 5 years ago and is not supported by most browsers. The
  `dart:web_sql` library has been documented as unsupported and deprecated for
  many years as well and but wasn't annotated properly until now.

### Dart VM

- **Breaking change** [#45071][]: `Dart_NewWeakPersistentHandle`'s and
  `Dart_NewFinalizableHandle`'s `object` parameter no longer accepts `Pointer`s
  and subtypes of `Struct`. Expandos no longer accept `Pointer`s and subtypes of
  `Struct`s.

[#45071]: https://github.com/dart-lang/sdk/issues/45071

### Tools

#### Dart command line

- **Breaking change** [#46100][]: The standalone `dart2native` tool has been
  marked deprecated, and now prints a warning message. Its replacements are the
  `dart compile exe` and `dart compile aot-snapshot` commands, which offer the
  same functionality. The `dart2native` tool will be removed from the Dart SDK
  in Dart 2.15.

- **Breaking change**: The standalone `dartfmt` tool has been marked deprecated,
  and now prints a warning message. Instead, use `dart format`. The `dartfmt`
  tool will be removed from the Dart SDK in Dart 2.15.

  Note that `dart format` has [a different set of options and
  defaults][dartfmt cli] than `dartfmt`.

- The `dart create` command has been updated to create projects that use the new
  'recommended' set of lints from `package:lints`. See
  https://dart.dev/go/core-lints for more information about these lints.

[#46100]: https://github.com/dart-lang/sdk/issues/46100
[dartfmt cli]: https://github.com/dart-lang/dart_style/wiki/CLI-Changes

- The `dart analyze` command has been extended to support specifying multiple
  files or directories to analyze; see also
  https://github.com/dart-lang/sdk/issues/45352.

- The `dartanalyzer` command's JSON output mode has been changed to emit the
  JSON output on stdout instead of stderr.

#### dart format

- Simplify and optimize cascade formatting. See:
  https://github.com/dart-lang/dart_style/pull/1033
- Don't unnecessarily split argument lists with `/* */` comments.
- Return correct exit code from `FormatCommand` when formatting stdin.
- Split empty catch blocks with finally clauses or catches after them.

#### Linter

Updated the Linter to `1.8.0`, which includes changes that
- improve performance for `prefer_is_not_empty`.
- fix false positives in `no_logic_in_create_state`.
- improve `package_names` to allow dart identifiers as package names.
- fix a false-positive in `package_names` (causing keywords to wrongly get flagged).
- fix `avoid_classes_with_only_static_member` to check for inherited members and also
  flag classes with only methods.
- fix `curly_braces_in_flow_control_structures` to properly flag terminating `else-if`
  blocks.
- improve `always_specify_types` to support type aliases.
- fix a false positive in `unnecessary_string_interpolations` w/ nullable interpolated
  strings
- fix a false positive in `avoid_function_literals_in_foreach_calls` for nullable
  iterables.
- fix false positives in `avoid_returning_null` w/ NNBD
- fix false positives in `use_late_for_private_fields_and_variables` in the presence
  of const constructors.
- adds a new lint: `eol_at_end_of_file`.
- fix case-sensitive false positive in `use_full_hex_values_for_flutter_colors`.
- improve try-block and switch statement flow analysis for
  `use_build_context_synchronously`.
- update `use_setters_to_change_properties` to only highlight a method name, not
  the entire body and doc comment.
- update `unnecessary_getters_setters` to allow otherwise "unnecessary" getters
  and setters with annotations.
- update `missing_whitespace_between_adjacent_strings` to allow String
  interpolations at the beginning and end of String literals.
- update `unnecessary_getters_setters` to allow for setters with non-basic
  assignments (for example, `??=` or `+=`).
- relax `non_constant_identifier_names` to allow for a trailing underscore.
- fix false negative in `prefer_final_parameters` where first parameter is
  final.
- improve `directives_ordering` sorting of directives with dot paths and
  dot-separated package names.
- (internal) migrate to `SecurityLintCode` instead of deprecated
  `SecurityLintCodeWithUniqueName`.
- (internal) fix `avoid_types_as_parameter_names` to skip field formal
  parameters.
- fix false positives in `prefer_interpolation_to_compose_strings` where the
  left operand is not a String.
- fix false positives in `only_throw_errors` for misidentified type variables.
- add new lint: `depend_on_referenced_packages`.
- update `avoid_returning_null_for_future` to skip checks for null-safe
  libraries.
- add new lint: `use_test_throws_matchers`.
- relax `sort_child_properties_last` to accept closures after child.
- improve performance for `prefer_contains` and `prefer_is_empty`.
- add new lint: `noop_primitive_operations`.
- mark `avoid_web_libraries_in_flutter` as stable.
- add new lint: `prefer_final_parameters`.
- update `prefer_initializing_formals` to allow assignments where identifier
  names don't match.
- update `directives_ordering` to checks ordering of `package:` imports in code
  outside pub packages.
- add simple reachability analysis to `use_build_context_synchronously` to
  short-circuit await-discovery in terminating blocks.
- update `use_build_context_synchronously` to recognize nullable types when
  accessed from legacy libraries.

#### Pub

- `dart pub publish` now respects `.pubignore` files with gitignore-style rules.
  `.gitignore` files in the repo are still respected if they are not overridden
  by a `.pubignore` in the same directory.

  pub no longer queries git for listing the files. This implies:

  - Checked in files will now be ignored if they are included by a `.gitignore`
    rule.
  - Global ignores are no longer taken into account.
  - Even packages that are not in git source control will have their
    `.gitignore` files respected.
  - `.gitignore` and `.pubignore` is always case-insensitive on MacOs and
    Windows (as is default for `git` repositories).

- New flag `dart pub deps --json` gives a machine parsable overview of the
  current dependencies.
- New command: `dart pub cache clean`. Will delete everything in your current
  pub cache.
- Commands related to a single package now takes a `--directory` option to
  operate on a package in the given directory instead of the working directory.
- git dependencies with a relative repo url would previously be interpreted
  relative to the current package, even for transitive dependencies. This now
  fails instead.

- Pub now uses a Dart library to read and write tar files. This should fix
  several issues we had with incompatibilities between different system `tar`s.
- `PUB_HOSTED_URL` can now include a trailing slash.
- Incremental compilation is now used for compilation of executables from
  dependencies when using `dart run <package>:<command>`.

#### Dart2JS

*   **Breaking change** [#46545][]: Dart2JS emits ES6+ JavaScript by default,
    thereby no longer supporting legacy browsers. Passing the
    `--legacy-javascript` flag will let you opt out of this update, but this
    flag will be removed in a future release. Modern browsers will not be
    affected, as Dart2JS continues to support [last two major releases][1] of
    Edge, Safari, Firefox, and Chrome.

[#46545]: https://github.com/dart-lang/sdk/issues/46545
[1]: https://dart.dev/faq#q-what-browsers-do-you-support-as-javascript-compilation-targets

#### Dart Dev Compiler (DDC)

- **Breaking change** [#44154][]: Subtyping relations of `package:js` classes
  have been changed to be more correct and consistent with Dart2JS.
  Like `anonymous` classes, non-`anonymous` classes will no longer check the
  underlying type in DDC. The internal type representation of these objects have
  changed as well, which will affect the `toString` value of these types.

[#44154]: https://github.com/dart-lang/sdk/issues/44154

## 2.13.4 - 2021-06-28

This is a patch release that fixes:

- a Dart VM compiler crash (issue [flutter/flutter#84212][]).
- a DDC compiler crash (issue [flutter/flutter#82838][]).

[flutter/flutter#84212]: https://github.com/flutter/flutter/issues/84212
[flutter/flutter#82838]: https://github.com/flutter/flutter/issues/82838

## 2.13.3 - 2021-06-10

This is a patch release that fixes:

- a Dart compiler crash (issue [flutter/flutter#83094][]).
- an analysis server deadlock causing it to stop responding to IDE requests
  (issue [#45996][]).
- an analyzer crash when analyzing against `package:meta` `v1.4.0` (issue
  [#46183][]).

[flutter/flutter#83094]: https://github.com/flutter/flutter/issues/83094
[#45996]: https://github.com/dart-lang/sdk/issues/45996
[#46183]: https://github.com/dart-lang/sdk/issues/46183

## 2.13.1 - 2021-05-25

This is a patch release that fixes:

- incorrect behavior in CastMap (issue [#45473][]).
- missing nullability from recursive type hierarchies in DDC (issue [#45767][]).

[#45473]: https://github.com/dart-lang/sdk/issues/45473
[#45767]: https://github.com/dart-lang/sdk/issues/45767

## 2.13.0 - 2021-05-18

### Language

- **Type aliases** [Non-function type aliases][]: Type aliases (names for types
  introduced via the `typedef` keyword) were previously restricted to only
  introduce names for function types. In this release, we remove this
  restriction and allow type aliases to name any kind of type.

  ```dart
  import 'dart:convert';

  typedef JsonMap = Map<String, dynamic>;

  JsonMap parseJsonMap(String input) => json.decode(input) as JsonMap;
  ```

  In addition to being usable as type annotations, type aliases that name class
  types can now also be used anywhere that the underlying class could be used,
  allowing type aliases to be used to safely rename existing classes.

  ```dart
  class NewClassName<T> {
     NewClassName.create(T x);
     static NewClassName<T> mkOne<T>(T x) => NewClassName<T>.create(x);
   }
  @Deprecated("Use NewClassName instead")
  typedef OldClassName<T> = NewClassName<T>;

  class LegacyClass extends OldClassName<int> {
    LegacyClass() : super.create(3);
  }
  OldClassName<int> legacyCode() {
    var one = OldClassName.create(1);
    var two = OldClassName.mkOne(2);
    return LegacyClass();
  }
  ```

  The new type alias feature is only available as part of the 2.13
  [language version](https://dart.dev/guides/language/evolution). To use this
  feature, you must set the lower bound on the sdk constraint for your package
  to 2.13 or greater.

  [non-function type aliases]:
    https://github.com/dart-lang/language/blob/master/accepted/2.13/nonfunction-type-aliases/feature-specification.md

### Core libraries

#### `dart:collection`

- The `SplayTreeMap` was changed to allow `null` as key if the `compare`
  function allows it. It now checks that a new key can be used as an argument to
  the `compare` function when the member is added, _even if the map is empty_
  (in which case it just compares the key to itself).

- The `SplayTreeSet` was changed to checks that a new element can be used as an
  argument to the `compare` function when the member is added, _even if the set
  is empty_ (in which case it just compares the element to itself).

#### `dart:developer`

- Added `serverWebSocketUri` property to `ServiceProtocolInfo`.

#### `dart:ffi`

- Add `Packed` for interacting with packed structs in native memory.
- Add `Array` for interacting with structs with inline arrays.

### Dart VM

### Tools

#### Analyzer

- Static analyses with "error" severity can once again be ignored with comments
  like `// ignore: code` and `// ignore_for_file: code`. To declare that certain
  analysis codes, or codes with certain severities ("error", "warning", and
  "info") cannot be ignored with such comments, list them in
  `analysis_options.yaml`, under the `analyzer` heading, with a new YAML key,
  `cannot-ignore`. For example, to declare that "error" codes and
  `unused_import` cannot be ignored, write the following into
  `analysis_options.yaml`:

  ```yaml
  analyzer:
    cannot-ignore:
      - error
      - unused_import
  ```

#### dart format

- Correct constructor initializer indentation after `required` named parameters.

#### Linter

Updated the Linter to `1.2.1`, which includes:

- Improved `iterable_contains_unrelated_type` to better support `List` content
  checks.
- Fixed `camel_case_types` and `prefer_mixin` to support non-function type
  aliases.
- Fixed `prefer_mixin` to properly make exceptions for `dart.collection` legacy
  mixins.
- Added new lints `avoid_multiple_declarations_per_line`,
  `use_if_null_to_convert_nulls_to_bools`, `deprecated_consistency`,
  `use_named_constants`, `use_build_context_synchronously` (experimental).
- Deprecated `avoid_as`.
- Migrated library to null-safety.

### Other libraries

#### `package:js`

- **Breaking change:** It is no longer valid to use `String`s that match an
  `@Native` annotation in an `@JS()` annotation for a non-anonymous JS interop
  class. This led to erroneous behavior due to the way interceptors work. If you
  need to work with a native class, prefer `dart:html`, an `@anonymous` class,
  or `js_util`. See issue [#44211][] for more details.

[#44211]: https://github.com/dart-lang/sdk/issues/44211

## 2.12.4 - 2021-04-15

This is a patch release that fixes a Dart VM compiler crashes when compiling
initializers containing async closures (issue [#45306][]).

[#45306]: https://github.com/dart-lang/sdk/issues/45306

## 2.12.3 - 2021-04-14

**Security advisory**: This is a patch release that fixes a vulnerability in
`dart:html` related to DOM clobbering. See the security advisory
[CVE-2021-22540][cve-2021-22540] for more details. Thanks again to **Vincenzo di
Cicco** for finding and reporting this vulnerability.

[cve-2021-22540]:
  https://github.com/dart-lang/sdk/security/advisories/GHSA-3rfv-4jvg-9522

## 2.12.2 - 2021-03-17

This is a patch release that fixes crashes reported by Flutter 2 users (issue
[flutter/flutter#78167][]).

[flutter/flutter#78167]: https://github.com/flutter/flutter/issues/78167

## 2.12.1 - 2021-03-10

This is a patch release that fixes:

- an unhandled exception in HTTPS connections (issue [#45047][]).
- a typing issue in the typed_data `+` operator (issue [#45140][]).

[#45047]: https://github.com/dart-lang/sdk/issues/45047
[#45140]: https://github.com/dart-lang/sdk/issues/45140

## 2.12.0 - 2021-03-03

### Language

- **Breaking change** [Null safety][] is now enabled by default in all code that
  has not opted out. With null safety, types in your code are non-nullable by
  default. Null can only flow into parts of your program where you want it. With
  null safety, your runtime null-dereference bugs turn into edit-time analysis
  errors.

  You can opt out of null safety and preserve your code's previous behavior by
  setting the lower bound of the SDK constraint in your pubspec to 2.11.0 or
  earlier to request an earlier [language version][]. You can opt out individual
  Dart files by adding `// @dart=2.11` to the beginning of the file.

  Files that are opted in to null safety may report new compile-time errors.
  Opting in to null safety also gives you access to other new language features:

  - Smarter flow analysis and type promotion
  - `required` named parameters
  - `late` variables
  - The postfix `!` null assertion operator
  - The `?..` and `?[]` null-aware operators

- **Breaking change** [#44660][]: Fixed an implementation bug where `this` would
  sometimes undergo type promotion in extensions.

[null safety]: https://dart.dev/null-safety/understanding-null-safety
[language version]:
  https://dart.dev/guides/language/evolution#language-versioning
[#44660]: https://github.com/dart-lang/sdk/issues/44660

### Core libraries

#### `dart:async`

- Add extension method `onError()` on `Future` to allow better typing of error
  callbacks.

#### `dart:collection`

- Add `UnmodifiableSetView` class, which allows users to guarantee that methods
  that could change underlying `Set` instance can not be invoked.

- Make it explicit that `LinkedList` compares elements by identity, and update
  `contains()` to take advantage of this.

#### `dart:core`

- Add `Set.unmodifiable()` constructor, which allows users to create
  unmodifiable `Set` instances.

#### `dart:ffi`

- **Breaking change** [#44621][]: Invocations with a generic `T` of `sizeOf<T>`,
  `Pointer<T>.elementAt()`, `Pointer<T extends Struct>.ref`, and
  `Pointer<T extends Struct>[]` are being deprecated in the current stable
  release (2.12), and are planned to be fully removed in the following stable
  release (2.13). Consequently, `allocate` in `package:ffi` will no longer be
  able to invoke `sizeOf<T>` generically, and will be deprecated as well.
  Instead, the `Allocator` it is introduced to `dart:ffi`, and also requires a
  constant `T` on invocations. For migration notes see the breaking change
  request.

- **Breaking change** [#44622][]: Subtypes of `Struct` without any native member
  are being deprecated in the current stable release (2.12), and are planned to
  be fully removed in the following stable release (2.13). Migrate opaque types
  to extend `Opaque` rather than `Struct`.

[#44621]: https://github.com/dart-lang/sdk/issues/44621
[#44622]: https://github.com/dart-lang/sdk/issues/44622

#### `dart:io`

- `HttpRequest` now correctly follows HTTP 308 redirects
  (`HttpStatus.permanentRedirect`).

#### `dart:isolate`

- Add `debugName` positional parameter to `ReceivePort` and `RawReceivePort`
  constructors, a name which can be associated with the port and displayed in
  tooling.
- Introduce `Isolate.exit([port, message])` which terminates current isolate
  and, if `port` is specified, as a last action sends out the `message` out to
  that `port`.

#### `dart:html`

- `EventStreamSubscription.cancel` has been updated to retain its synchronous
  timing when running in both sound and unsound null safety modes. See issue
  [#44157][] for more details.

[#44157]: https://github.com/dart-lang/sdk/issues/44157

### Dart VM

- **Breaking change** [#42312][]: `Dart_WeakPersistentHandle`s no longer
  auto-delete themselves when the referenced object is garbage collected to
  avoid race conditions, but they are still automatically deleted when the
  isolate group shuts down.

- **Breaking change** [#42312][]: `Dart_WeakPersistentHandleFinalizer` is
  renamed to `Dart_HandleFinalizer` and had its `handle` argument removed. All
  API functions using that type have been updated.

[#42312]: https://github.com/dart-lang/sdk/issues/42312

### Dart2JS

- Remove `--no-defer-class-types` and `--no-new-deferred-split`.

### Tools

#### Analyzer

- Remove the `--use-fasta-parser`, `--preview-dart-2`, and
  `--enable-assert-initializers` command line options. These options haven't
  been supported in a while and were no-ops.

- Report diagnostics regarding the
  [`@internal`](https://pub.dev/documentation/meta/latest/meta/internal-constant.html)
  annotation.

- Improve diagnostic-reporting regarding the
  [`@doNotStore`](https://pub.dev/documentation/meta/latest/meta/doNotStore-constant.html)
  annotation.

- Introduce a diagnostic which is reported when a library member named `main` is
  not a function.

- Introduce a diagnostic which is reported when a `main` function's first
  parameter is not a supertype of `List<String>`.

- Introduce diagnostics for when an `// ignore` comment contains an error code
  which is not being reported, cannot be ignored, or is already being ignored.

- Report diagnostics when using
  [`@visibleForTesting`](https://pub.dev/documentation/meta/latest/meta/
  visibleForTesting-constant.html) on top-level variables.

- Fix false positive reports of "unused element" for top-level setters and
  getters.

- Fix false positive reports regarding `@deprecated` field formal parameters at
  their declaration.

- For null safety, introduce a diagnostic which reports when a null-check will
  always fail.

- Fix false positive reports regarding optional parameters on private
  constructors being unused.

- Introduce a diagnostic which is reported when a constructor includes duplicate
  field formal parameters.

- Improve the "unused import" diagnostic when multiple import directives share a
  common prefix.

- Fix false positive "unused import" diagnostic regarding an import which
  provides an extension method which is used.

- For null safety, improve the messaging of "use of nullable value" diagnostics
  for eight different contexts.

- Fix false positive reports regarding `@visibleForTesting` members in a "hide"
  combinator of an import or export directive.

- Improve the messaging of "invalid override" diagnostics.

- Introduce a diagnostic which is reported when `Future<T>.catchError` is called
  with an `onError` callback which does not return `FutureOr<T>`.

#### dartfmt

- Don't duplicate comments on chained if elements.

- Preserve `?` in initializing formal function-typed parameters.

- Fix performance issue with constructors that have no initializer list.

#### Linter

Updated the Linter to `0.1.129`, which includes:

- New lints: `avoid_dynamic_calls`, `cast_nullable_to_non_nullable`,
  `null_check_on_nullable_type_parameter`,
  `tighten_type_of_initializing_formals`, `unnecessary_null_checks`, and
  `avoid_type_to_string`.

- Fix crash in `prefer_collection_literals` when there is no static parameter
  element.

- Fix false negatives for `prefer_collection_literals` when a LinkedHashSet or
  LinkedHashMap instantiation is passed as the argument to a function in any
  position other than the first.

- Fix false negatives for `prefer_collection_literals` when a LinkedHashSet or
  LinkedHashMap instantiation is used in a place with a static type other than
  Set or Map.

- Update to `package_names` to allow leading underscores.

- Fix crashes in `unnecessary_null_checks` and
  `missing_whitespace_between_adjacent_strings`.

- Update to `void_checks` for null safety.

- Fix range error in `unnecessary_string_escapes`.

- Fix false positives in `unnecessary_null_types`.

- Fix to `prefer_constructors_over_static_methods` to respect type parameters.

- Update to `always_require_non_null_named_parameters` to be null safety-aware.

- Update to `unnecessary_nullable_for_final_variable_declarations` to allow
  dynamic.

- Update `overridden_fields` to not report on abstract parent fields.

- Fix to `unrelated_type_equality_checks` for null safety.

- Improvements to `type_init_formals`to allow types not equal to the field type.

- Updates to `public_member_apis` to check generic type aliases.

- Fix `close_sinks` to handle `this`-prefixed property accesses.

- Fix `unawaited_futures` to handle `Future` subtypes.

- Performance improvements to `always_use_package_imports`,
  `avoid_renaming_method_parameters`, `prefer_relative_imports` and
  `public_member_api_docs`.

#### Pub

- **Breaking**: The Dart SDK constraint is now **required** in `pubspec.yaml`.
  You must include a section like:

  ```yaml
  environment:
    sdk: ">=2.10.0 <3.0.0"
  ```

  See [#44072][].

  For legacy dependencies without an SDK constraint, pub will now assume a
  default language version of 2.7.

- The top level `pub` executable has been deprecated. Use `dart pub` instead.
  See [dart tool][].

- New command `dart pub add` that adds new dependencies to your `pubspec.yaml`,
  and a corresponding `dart pub remove` that removes dependencies.

- New option `dart pub upgrade --major-versions` will update constraints in your
  `pubspec.yaml` to match the _resolvable_ column reported in
  `dart pub outdated`. This allows users to easily upgrade to latest version for
  all dependencies where this is possible, even if such upgrade requires an
  update to the version constraint in `pubspec.yaml`.

  It is also possible to only upgrade the major version for a subset of your
  dependencies using `dart pub upgrade --major-versions <dependencies...>`.

- New option `dart pub upgrade --null-safety` will attempt to update constraints
  in your `pubspec.yaml`, such that only null-safety migrated versions of
  dependencies are allowed.

- New option `dart pub outdated --mode=null-safety` that will analyze your
  dependencies for null-safety.

- `dart pub get` and `dart pub upgrade` will highlight dependencies that have
  been [discontinued](https://dart.dev/tools/pub/publishing#discontinue) on
  pub.dev.

- `dart pub publish` will now check your pubspec keys for likely typos.

- `dart pub upgrade package_foo` fetchs dependencies but ignores the
  `pubspec.lock` for `package_foo`, allowing users to only upgrade a subset of
  dependencies.

- New command `dart pub login` that logs into pub.dev.

- The `--server` option to `dart pub publish` and `dart pub uploader` are
  deprecated. Use `publish_to` in your `pubspec.yaml` or set the
  `$PUB_HOSTED_URL` environment variable.

- `pub global activate` no longer re-precompiles if the current global
  installation was same version.

- The Flutter SDK constraint upper bound is now ignored in pubspecs and
  deprecated when publishing. See: [flutter-upper-bound-deprecation][].

[flutter-upper-bound-deprecation]:
  https://dart.dev/go/flutter-upper-bound-deprecation
[#44072]: https://github.com/dart-lang/sdk/issues/44072
[dart tool]: https://dart.dev/tools/dart-tool

## 2.10.5 - 2021-01-21

This is a patch release that fixes a crash in the Dart VM. (issue [#44563][]).

[#44563]: https://github.com/dart-lang/sdk/issues/44563

## 2.10.4 - 2020-11-12

This is a patch release that fixes a crash in the Dart VM (issues [#43941][],
[flutter/flutter#43620][], and [Dart-Code/Dart-Code#2814][]).

[#43941]: https://github.com/dart-lang/sdk/issues/43941
[flutter/flutter#43620]: https://github.com/flutter/flutter/issues/43620
[dart-code/dart-code#2814]: https://github.com/Dart-Code/Dart-Code/issues/2814

## 2.10.3 - 2020-10-29

This is a patch release that fixes the following issues:

- breaking changes in Chrome 86 that affect DDC (issues [#43750][] and
  [#43193][]).
- compiler error causing incorrect use of positional parameters when named
  parameters should be used instead (issues [flutter/flutter#65324][] and
  [flutter/flutter#68092][]).
- crashes and/or undefined behavior in AOT compiled code (issues [#43770][] and
  [#43786][]).
- AOT compilation of classes with more than 64 unboxed fields (issue
  [flutter/flutter#67803][]).

[#43750]: https://github.com/dart-lang/sdk/issues/43750
[#43193]: https://github.com/dart-lang/sdk/issues/43193
[flutter/flutter#65324]: https://github.com/flutter/flutter/issues/65324
[flutter/flutter#68092]: https://github.com/flutter/flutter/issues/68092
[#43770]: https://github.com/dart-lang/sdk/issues/43770
[#43786]: https://github.com/dart-lang/sdk/issues/43786
[flutter/flutter#67803]: https://github.com/flutter/flutter/issues/67803

## 2.10.2 - 2020-10-15

This is a patch release that fixes a DDC compiler crash (issue [#43589]).

[#43589]: https://github.com/dart-lang/sdk/issues/43589

## 2.10.1 - 2020-10-06

This is a patch release that fixes the following issues:

- crashes when developing Flutter applications (issue [#43464][]).
- non-deterministic incorrect program behaviour and/or crashes (issue
  [flutter/flutter#66672][]).
- uncaught TypeErrors in DDC (issue [#43661][]).

[#43464]: https://github.com/dart-lang/sdk/issues/43464
[flutter/flutter#66672]: https://github.com/flutter/flutter/issues/66672
[#43661]: https://github.com/dart-lang/sdk/issues/43661

## 2.10.0 - 2020-09-28

### Core libraries

#### `dart:io`

- Adds `Abort` method to class `HttpClientRequest`, which allows users to cancel
  outgoing HTTP requests and stop following IO operations.
- A validation check is added to `path` of class `Cookie`. Having characters
  ranging from 0x00 to 0x1f and 0x3b (";") will lead to a `FormatException`.
- The `HttpClient` and `HttpServer` classes now have a 1 MiB limit for the total
  size of the HTTP headers when parsing a request or response, instead of the
  former 8 KiB limit for each header name and value. This limit cannot be
  configured at this time.

#### `dart:typed_data`

- Class `BytesBuilder` is moved from `dart:io` to `dart:typed_data`. It's
  temporarily being exported from `dart:io` as well.

### `dart:uri`

- [#42564]: Solved inconsistency in `Uri.https` and `Uri.http` constructors'
  `queryParams` type.

### Dart VM

- **Breaking change** [#42982][]: `dart_api_dl.cc` is renamed to `dart_api_dl.c`
  and changed to a pure C file.
- Introduces `Dart_FinalizableHandle`s. They do auto-delete, and the weakly
  referred object cannot be accessed through them.

### Dart2JS

- Adds support for deferred loading of types separately from classes. This
  enables dart2js to make better optimization choices when deferred loading.
  This work is necessary to address unsoundness in the deferred loading
  algorithm. Currently, fixing this unsoundness would result in code bloat, but
  loading types separately from classes will allow us to fix the unsoundness
  with only a minimal regression. To explicitly disable deferred loading of
  types, pass `--no-defer-class-types`. See the original post on the
  [unsoundness in the deferred loading algorithm][].
- Enables a new sound deferred splitting algorithm. To explicitly disable the
  new deferred splitting algorithm, pass `--no-new-deferred-split`. See the
  original post on the [unsoundness in the deferred loading algorithm][].

[#42982]: https://github.com/dart-lang/sdk/issues/42982
[unsoundness in the deferred loading algorithm]:
  https://github.com/dart-lang/sdk/blob/302ad7ab2cd2de936254850550aad128ae76bbb7/CHANGELOG.md#dart2js-3

### Tools

#### dartfmt

- Don't crash when non-ASCII whitespace is trimmed.
- Split all conditional expressions (`?:`) when they are nested.
- Handle `external` and `abstract` fields and variables.

#### Linter

Updated the Linter to `0.1.118`, which includes:

- New lint: `unnecessary_nullable_for_final_variable_declarations`.
- Fixed NPE in `prefer_asserts_in_initializer_lists`.
- Fixed range error in `unnecessary_string_escapes`.
- `unsafe_html` updated to support unique error codes.
- Updates to `diagnostic_describe_all_properties` to check for `Diagnosticable`s
  (not `DiagnosticableMixin`s).
- New lint: `use_late`.
- Fixed `unnecessary_lambdas` to respect deferred imports.
- Updated `public_member_api_docs` to check mixins.
- Updated `unnecessary_statements` to skip `as` expressions.
- Fixed `prefer_relative_imports` to work with path dependencies.

#### Pub

- `pub run` and `pub global run` accepts a `--(no-)-sound-null-safety` flag,
  that is passed to the VM.
- Fix: Avoid multiple recompilation of binaries in global packages.
- Fix: Avoid exponential behaviour of error reporting from the solver.
- Fix: Refresh binstubs after recompile in global run.

## 2.9.3 - 2020-09-08

This is a patch release that fixes DDC to handle a breaking change in Chrome
(issue [#43193][]).

[#43193]: https://github.com/dart-lang/sdk/issues/43193

## 2.9.2 - 2020-08-26

This is a patch release that fixes transient StackOverflow exceptions when
building Flutter applications (issue [flutter/flutter#63560][]).

[flutter/flutter#63560]: https://github.com/flutter/flutter/issues/63560

## 2.9.1 - 2020-08-12

This is a patch release that fixes unhandled exceptions in some Flutter
applications (issue [flutter/flutter#63038][]).

[flutter/flutter#63038]: https://github.com/flutter/flutter/issues/63038

## 2.9.0 - 2020-08-05

### Language

### Core libraries

#### `dart:async`

- Adds `Stream.multi` constructor creating streams which can be listened to more
  than once, and where each individual listener can be controlled independently.

#### `dart:convert`

- **Breaking change** [#41100][]: When encoding a string containing unpaired
  surrogates as UTF-8, the unpaired surrogates will be encoded as replacement
  characters (`U+FFFD`). When decoding UTF-8, encoded surrogates will be treated
  as malformed input. When decoding UTF-8 with `allowMalformed: true`, the
  number of replacement characters emitted for malformed input sequences has
  been changed to match the [WHATWG encoding standard][].

[#41100]: https://github.com/dart-lang/sdk/issues/41100
[whatwg encoding standard]: https://encoding.spec.whatwg.org/#utf-8-decoder

#### `dart:io`

- [#42006][]: The signature of `exit` has been changed to return the `Never`type
  instead of `void`. since no code will run after it,
- Class `OSError` now implements `Exception`. This change means `OSError` will
  now be caught in catch clauses catching `Exception`s.
- Added `InternetAddress.tryParse`.
- [Abstract Unix Domain Socket][] is supported on Linux/Android now. Using an
  `InternetAddress` with `address` starting with '@' and type being
  `InternetAddressType.Unix` will create an abstract Unix Domain Socket.
- On Windows, file APIs can now handle files and directories identified by long
  paths (greater than 260 characters). It complies with all restrictions from
  [Long Path on Windows][]. Note that `Directory.current` does not work with
  long path.

[#42006]: https://github.com/dart-lang/sdk/issues/42006
[abstract unix domain socket]: http://man7.org/linux/man-pages/man7/unix.7.html
[long path on windows]:
  https://docs.microsoft.com/en-us/windows/win32/fileio/naming-a-file#maximum-path-length-limitation

#### `dart:html`

- **Breaking change**: `CssClassSet.add()` previously returned `null` if the
  `CssClassSet` corresponded to multiple elements. In order to align with the
  null-safe changes in the `Set` interface, it will now return `false` instead.
  The same applies for `CssClassSet.toggle`.

- `EventStreamSubscription.cancel` method used to return `null`, but since
  `StreamSubscription.cancel` has changed to be non-nullable, this method
  returns an empty `Future` instead. Due to an optimization on `null` `Future`s,
  this method used to complete synchronously, but now that the `Future` is empty
  instead, it completes asynchronously, therefore potentially invalidating code
  that relied on the synchronous side-effect. This change will only affect code
  using sound null-safety. See issue [#41653][] for more details.

- Methods in `Console` have been updated to better reflect the modern Console
  specification. Particularly of interest are `dir` and `table` which take in
  extra optional arguments.

[#41653]: https://github.com/dart-lang/sdk/issues/41653

#### `dart:mirrors`

- **Breaking change** [#42714][]: web compilers (dart2js and DDC) now produce a
  compile-time error if `dart:mirrors` is imported.

  Most projects should not be affected. Since 2.0.0 this library was unsupported
  and produced runtime errors on all its APIs. Since then several tools already
  reject code that use `dart:mirrors` including webdev and flutter tools, we
  expect few projects to run into this problem.

[#42714]: https://github.com/dart-lang/sdk/issues/42714

### Tools

#### dartfmt

- Add `--fix-single-cascade-statements`.
- Correctly handle `var` in `--fix-function-typedefs`.
- Preserve leading indentation in fixed doc comments.
- Split outer nested control flow elements.
- Always place a blank line after script tags.
- Don't add unneeded splits on if elements near comments.
- Indent blocks in initializers of multiple-variable declarations.
- Update the null-aware subscript syntax from `?.[]` to `?[]`.

#### Analyzer

- Static analyses with a severity of "error" can no longer be ignored with
  comments (`// ignore: code` and `// ignore_for_file: code`).

#### Linter

Updated the Linter to `0.1.117`, which includes:

- New lint: `do_not_use_environment`.
- New lint: `exhaustive_cases`.
- New lint: `no_default_cases` (experimental).
- New lint: `sized_box_for_whitespace`.
- New lint: `use_is_even_rather_than_modulo`.
- Updated `directives_ordering` to remove third party package special-casing.
- Updated `prefer_is_empty` to special-case assert initializers and const
  contexts.
- Updated `prefer_mixin` to allow "legacy" SDK abstract class mixins.
- Updated `sized_box_for_whitespace` to address false-positives.
- Updated `type_annotate_public_apis` to allow inferred types in final field
  assignments.
- Updated `unnecessary_lambdas` to check for tear-off assignability.
- Updated `unsafe_html` to use a `SecurityLintCode` (making it un-ignorable) and
  to include `Window.open`, `Element.html` and `DocumentFragment.html` in unsafe
  API checks. Also added checks for attributes and methods on extensions.

### Dart VM

- **Breaking change** [#41100][]: When printing a string using the `print`
  function, the default implementation (used when not overridden by the embedder
  or the current zone) will print any unpaired surrogates in the string as
  replacement characters (`U+FFFD`). Similarly, the `Dart_StringToUTF8` function
  in the Dart API will convert unpaired surrogates into replacement characters.

### Pub

- `pub run` and `pub global run` accepts a `--enable-experiment` flag enabling
  experiments in the Dart VM (and language).
- Warn when publishing the first null-safe version of a package.
- `pub outdated`:
  - If the current version of a dependency is a prerelease version, use
    prereleases for latest if there is no newer stable.
  - Don't require a `pubspec.lock` file. When the lockfile is missing, the
    **Current** column is empty.
- `pub upgrade`: Show summary count of outdated packages after running. It will
  also only show newer packages if they are not prereleases or the package is
  already a prerelease.
- Publishing Flutter plugins using the old plugin format is no longer allowed.
  Plugins using the old plugin format can still be consumed.
- `pub run`: Fix precompilation with relative `PUB_CACHE` paths
  ([#2486](https://github.com/dart-lang/pub/pull/2486)).
- Preserve Windows line endings in `pubspec.lock` if they are already there
  ([#2489](https://github.com/dart-lang/pub/pull/2489)).
- Better terminal color-detection. Use colors in terminals on Windows.
- Fix git folder names in cache, allowing for ssh-style git dependencies.
- Fix: Avoid precompilation of dependencies of global packages.

## 2.8.4 - 2020-06-04

This is a patch release that fixes potential memory leaks in the Dart front-end
(issues [#42111][] and [#42112][]).

[#42111]: https://github.com/dart-lang/sdk/issues/42111
[#42112]: https://github.com/dart-lang/sdk/issues/42112

## 2.8.3 - 2020-05-28

This is a patch release that fixes the following issues:

- crashes in Flutter apps (issue [flutter/flutter#57318][]).
- a regression in stack traces (issue [#41907][]).
- re-canonicalization of constants with unboxed fields (issue
  [flutter/flutter#57190][]).

[flutter/flutter#57318]: https://github.com/flutter/flutter/issues/57318
[#41907]: https://github.com/dart-lang/sdk/issues/41907
[flutter/flutter#57190]: https://github.com/flutter/flutter/issues/57190

## 2.8.2 - 2020-05-13

This is a patch release that fixes an AOT compilation bug in global
transformations which manifests as a NoSuchMethod exception (issue
[flutter/flutter#56479][]).

[flutter/flutter#56479]: https://github.com/flutter/flutter/issues/56479

## 2.8.1 - 2020-05-06

Much of the changes in this release are in preparation for non-nullable types,
which will arrive in a future version. In anticipation of that, we have made a
number of small but technically breaking changes to several core library APIs in
order to make them easier to use in a world with non-nullable types. Almost all
existing Dart code will be unaffected by these changes, but if you see
unexpected failures, note the breaking changes listed below.

### Language

There are no new language features in this release. There are only two minor
breaking changes:

- **Breaking change** [#40675][]: Fixed an implementation bug where local
  variable inference would incorrectly use the promoted type of a type variable.

- **Breaking change** [#41362][]: Dart 2.0.0 made the clauses
  `implements Function`, `extends Function`, or `with Function` have no effect
  (spec section 19.6). We fixed an implementation bug that may be visible on
  some rare scenarios.

[#40675]: https://github.com/dart-lang/sdk/issues/40675
[#41362]: https://github.com/dart-lang/sdk/issues/41362

### Core libraries

#### `dart:async`

- **Breaking change** [#40676][]: Changed the return type of
  `StreamSubscription.cancel()` to `Future<void>`. Previously, it was declared
  to return `Future` and was allowed to return `null` at runtime.

- **Breaking change** [#40681][]: The `runZoned()` function is split into two
  functions: `runZoned()` and `runZonedGuarded()`, where the latter has a
  required `onError` parameter, and the former has none. This prepares the
  functions for null safety where the two functions will differ in the
  nullability of their return types.

- **Breaking change** [#40683][]: Errors passed to `Completer.completeError()`,
  `Stream.addError()`, `Future.error()`, etc. can no longer be `null`. These
  operations now _synchronously_ throw an exception if passed a `null` error.

- Make stack traces non-null [#40130][]. Where methods like
  `completer.completeError()` allow omitting a stack trace, the platform will
  now insert a default stack trace rather than propagate a `null` value.

  Error handling functions need no longer be prepared for `null` stack traces.

[#40676]: https://github.com/dart-lang/sdk/issues/40676
[#40681]: https://github.com/dart-lang/sdk/issues/40681
[#40683]: https://github.com/dart-lang/sdk/issues/40683
[#40130]: https://github.com/dart-lang/sdk/issues/40130

#### `dart:core`

- **Breaking change** [#40674][]: Three members on `RuneIterator` no longer
  return `null` when accessed before the first call to `moveNext()`. Instead,
  `current` and `rawIndex` return `-1` and `currentAsString` returns an empty
  string.

- **Breaking change** [#40678][]: The `String.fromEnvironment()` default value
  for `defaultValue` is now an empty string instead of `null`. Likewise, the
  default value for `int.fromEnvironment()`'s `defaultValue` parameter is zero.
  Under null safety, a constructor cannot return `null`, so this prepares these
  APIs for that.

- The class `CastError` is deprecated, and all implementation specific classes
  implementing `TypeError` or `CastError` now implement both. In a future
  release, `CastError` will be removed. See issue [40763][] for details.

- Adds `StackTrace.empty` constant which is the stack trace used as default
  stack trace when no better alternative is available.

- The class `TypeError` no longer extends `AssertionError`. This also means that
  it no longer inherits the spurious `message` getter which was added to
  `AssertionError` when the second operand to `assert` was allowed. The value of
  that getter on a `TypeError` was the same string as returned by `toString()`,
  so it is still available.

- `ArgumentError.checkNotNull()` and the `RangeError` static methods
  `checkValueInInterval()`, `checkValidIndex()` and `checkNotNegative()` all
  return their first argument on success. This makes these functions more
  convenient to use in-line in, for example, `=>` function bodies or constructor
  initialization lists.

[#40674]: https://github.com/dart-lang/sdk/issues/40674
[#40678]: https://github.com/dart-lang/sdk/issues/40678
[40763]: https://github.com/dart-lang/sdk/issues/40763

#### `dart:developer`

- The constructors for `TimelineTask` now accept an optional `filterKey`
  parameter. If provided, the arguments for all events associated with the task
  will contain an entry named `filterKey`, set to the value of the `filterKey`
  parameter provided in the constructor. This will be used by tooling to allow
  for better filtering of timeline events.

#### `dart:ffi`

- **Breaking change**: Changed `Pointer.asFunction()` and
  `DynamicLibrary.lookupFunction()` to extension methods. Invoking them
  dynamically previously already threw an exception, so the runtime behavior
  stays the same. However, the extension methods are only visible if `dart:ffi`
  is imported directly. This breaks code where `dart:ffi` is not directly
  imported. To fix, add:

  ```dart
  import 'dart:ffi';
  ```

#### `dart:html`

- **Breaking change** [#39627][]: Changed the return type of several HTML native
  methods involving futures. In return types that matched `Future<List<T>>`,
  `T was` changed to `dynamic`. These methods would have resulted in a runtime
  error if they were used.

- **Breaking change**: `Node.insertAllBefore()` erroneously had a return type of
  `Node`, even though it was not returning anything. This has been corrected to
  `void`.

[#39627]: https://github.com/dart-lang/sdk/issues/39627

#### `dart:io`

- Class `HttpParser` will no longer throw an exception when a HTTP response
  status code is within [0, 999]. Customized status codes in this range are now
  valid.

- **Breaking change** [#33501][]: The signature of `HttpHeaders` methods `add()`
  and `set` have been changed to:

  ```dart
  void add(String name, Object value, {bool preserveHeaderCase: false})
  void set(String name, Object value, {bool preserveHeaderCase: false})
  ```

  Setting `preserveHeaderCase` to `true` preserves the case of the `name`
  parameter instead of converting it to lowercase. The `HttpHeader.forEach()`
  method provides the current case of each header.

  This is breaking only for classes extending or implementing `HttpHeaders` and
  having their own `add` or `set` methods without the `bool preserveHeaderCase`
  named parameter.

- **Breaking change** [#40702][]: The `Socket` class now throws a
  `SocketException` if the socket has been explicitly destroyed or upgraded to a
  secure socket upon setting or getting socket options. Previously, setting a
  socket option would be ignored and getting a socket option would return
  `null`.

- **Breaking change** [#40483][]: The `Process` class now throws a `StateError`
  if the process is detached (`ProcessStartMode.detached` and
  `ProcessStartMode.detachedWithStdio`) upon accessing the `exitCode` getter. It
  now also throws when not connected to the child process's stdio
  (`ProcessStartMode.detached` and `ProcessStartMode.inheritStdio`) upon
  accessing the `stdin`, `stdout`, and `stderr` getters. Previously, these
  getters would all return `null`.

- **Breaking change** [#40706][]: The dummy object returned if `FileStat.stat()`
  or `FileStat.statSync()` fail now contains Unix epoch timestamps instead of
  `null` for the `accessed`, `changed`, and `modified` getters.

- **Breaking change** [#40709][]: The `HeaderValue` class now parses more
  strictly in two invalid edge cases. This is the class used to parse the
  semicolon delimited parameters used in the `Accept`, `Authorization`,
  `Content-Type`, and other such HTTP headers.

  The empty parameter value without double quotes (which is not allowed by the
  standards) is now parsed as the empty string rather than `null`. E.g.
  `HeaderValue.parse("v;a=").parameters` now gives `{"a": ""}` rather than
  `{"a": null}`.

  Invalid inputs with unbalanced double quotes are now rejected. E.g.
  `HeaderValue.parse('v;a="b').parameters` will now throw a `HttpException`
  instead of giving `{"a": "b"}`.

- The `HeaderValue.toString()` method now supports parameters with `null` values
  by omitting the value. `HeaderValue("v", {"a": null, "b": "c"}).toString()`
  now gives `v; a; b=c`. This behavior can be used to implement some features in
  the `Accept` and `Sec-WebSocket-Extensions` headers.

  Likewise the empty value and values using characters outside of [RFC 7230
  tokens][] are now correctly implemented by double quoting such values with
  escape sequences. For example:

  ```dart
  HeaderValue("v",
      {"a": "A", "b": "(B)", "c": "", "d": "ø", "e": "\\\""}).toString()
  ```

  Gives: `v;a=A;b="(B)";c="";d="ø";e="\\\""`.

- [Unix domain sockets][] are now supported on Linux, Android and MacOS, which
  can be used by passing a `InternetAddress` of `InternetAddressType.Unix` into
  the `connect()`, `startConnect()` and `bind()` methods. The `port` argument in
  those methods will be ignored. The `port` getter always returns 0 for Unix
  domain sockets.

- Class `InternetAddressType` gains one more option `Unix`, which represents a
  Unix domain address.

- Class `InternetAddress`:

  - `InternetAddress` constructor gains an optional `type` parameter. To create
    a Unix domain address, `type` is set to `InternetAddressType.Unix` and
    `address` is a file path.

  - `InternetAddress` gains a new constructor `fromRawAddress()` that takes an
    address in byte format for Internet addresses or raw file path for Unix
    domain addresses.

- **Breaking change** [#40681][]: The static methods `runZoned()` and
  `runWithHttpOverrides()` on `HttpOverrides` no longer accept
  `zoneSpecification` and `onError` parameters. Use the `runZoned()` or
  `runZonedGuarded()` functions from `dart:async` directly if needing to specify
  those.

- Class `HttpClient` and `HttpServer`, when receiving `HttpRequest` or
  `HttpClientResponse`, will now put a 8K size limit on its header fields and
  values.

[#33501]: https://github.com/dart-lang/sdk/issues/33501
[#40702]: https://github.com/dart-lang/sdk/issues/40702
[#40483]: https://github.com/dart-lang/sdk/issues/40483
[#40706]: https://github.com/dart-lang/sdk/issues/40706
[#40709]: https://github.com/dart-lang/sdk/issues/40709
[rfc 7230 tokens]: https://tools.ietf.org/html/rfc7230#section-3.2.6
[unix domain sockets]: https://en.wikipedia.org/wiki/Unix_domain_socket

#### `dart:mirrors`

- Added `MirrorSystem.neverType`.

### Dart VM

- Added `Dart_TypeDynamic`, `Dart_TypeVoid` and `Dart_TypeNever`. Type `dynamic`
  can no longer by reached using `Dart_GetType(dart:core, dynamic)`.

- Added the following methods to the VM embedding API:

  - `Dart_GetNonNullableType()`
  - `Dart_GetNullableType()`
  - `Dart_TypeToNonNullable()`
  - `Dart_TypeToNullable()`
  - `Dart_IsLegacyType()`
  - `Dart_IsNonNullableType()`
  - `Dart_IsNullableType()`

### Tools

#### Dart Dev Compiler (DDC)

We fixed several inconsistencies between DDC and Dart2JS so that users less
frequently encounter code that is accepted by one compiler but then fails in the
other.

- **Breaking change**: Deleted the legacy (analyzer based) version of DDC. For
  additional details see the [announcement][ddc].

  - The `--kernel` option is now ignored and defaults to true. There is no
    longer any way to invoke the legacy (analyzer based) version of DDC.

  - Command line arguments that were only used for the legacy DDC have been
    removed.

  - The pre-compiled `dart_sdk.js` artifacts generated by legacy DDC have been
    deleted from `dart-sdk/lib/dev_compiler` in favor of the versions located at
    `dart-sdk/lib/dev_compiler/kernel`.

- **Breaking change**: Functions passed to JavaScript using the recommended
  `package:js` interop specification must now be wrapped with a call to
  `allowInterop`. This behavior was always enforced by Dart2JS, but was not
  enforced consistently by DDC. It is now enforced by both.

- **Breaking change**: Constructors in `@JS()` classes must be marked with
  `external`. Previously the `external` could be omitted in some cases with DDC
  but doing so would cause incorrect behavior with Dart2JS.

- JS interop classes with an index operator are now static errors.

- All remaining support from the `dart:mirrors` library has been removed. Use of
  this library on the web has been unsupported and prevented by the Dart build
  systems since Dart v2.0.0. All known exception cases have been cleaned up.
  This change makes DDC and Dart2JS now behave consistently.

  The library can still be imported on web apps, but all APIs throw. In a future
  breaking change release, imports to this library will likely become a
  compile-time error.

[ddc]: https://github.com/dart-lang/sdk/issues/38994

#### Dart2JS

A new representation of runtime types is enabled by default.

This change is part of a long term goal of making runtime checks cheaper and
more flexible for upcoming changes in the language. The new representation
disentangles how types and classes are represented and makes types first-class
to the compiler. This makes it possible to do certain kind of optimizations on
type checks that were not possible before and will enable us to model
non-nullable types in the near future.

This change should not affect the semantics of your application, but it has some
relatively small visible effects that we want to highlight:

- Types are now canonicalized, this fixes a long standing bug that Types could
  not be used in switch cases (issue [17207][]).

- Code-size changes may be visible, but the difference is small overall. It is
  more visible on smaller apps because the new implementation includes more
  helper methods. On large apps we have even seen an overall code-size
  reduction.

- Certain checks are a lot faster. This is less noticeable if you are compiling
  apps with `-O3` where checks are omitted altogether. Even with `-O3`, the
  performance of some `is` checks used by your app may improve.

- When using `-O3` and `-O4` incorrect type annotations could surface as errors.
  The old type representation was accidentally lenient on some invalid type
  annotations. We have only encountered this issue on programs that were not
  tested properly at the js-interop program boundary.

- `Type.toString()` has a small change that is rarely visible. For a long time,
  Dart2JS has had support to erase unused type variables. Today, when Dart2JS is
  given `--lax-runtime-type-to-string` (currently included in `-O2`, `-O3`, and
  `-O4`) and it decides to erase the type variable of a class `Foo<T>`, then it
  compiles expressions like `foo.runtimeType.toString()` to print `Foo`. With
  the new representation, this will show `Foo<erased>` instead. This change may
  be visible in error messages produced by type checks involving erased types.

Because types and classes are represented separately, we will likely reevaluate
restrictions of deferred libraries in the near future. For example, we could
support referring to deferred types because types can be downloaded while
classes are not.

In the unlikely case you run into any issues, please file a bug so we can
investigate. You can temporarily force the old type representation by passing
`--use-old-rti` to Dart2JS if necessary, but our goal is to delete the old type
representation soon.

In addition, we fixed some inconsistencies between Dart2JS and DDC:

- JS interop classes with an index operator are now static errors instead of
  causing invalid code in Dart2JS.

- **Breaking change**: The subtyping rule for generic functions is now more
  forgiving. Corresponding type parameter bounds now only need to be mutual
  subtypes rather than structurally equal up to renaming of bound type variables
  and equating all top types.

- **Breaking change**: Types are now normalized. See [normalization][] for the
  full specification. Types will now be printed in their normal form, and mutual
  subtypes with the same normal form will now be considered equal.

- **Breaking change**: Constructors in `@JS()` classes must be marked with
  `external`. Previously, the external could be omitted for unused constructors.
  Omitting `external` for a constructor which is used would cause incorrect
  behavior at runtime, now omitting it on any constructor is a static error.

[17207]: https://github.com/dart-lang/sdk/issues/17207
[normalization]:
  https://github.com/dart-lang/language/blob/master/resources/type-system/normalization.md

Other dart2js changes:

- **Breaking change**: The `--package-root` flag, which was hidden and disabled
  in Dart 2.0.0, has been completely removed. Passing this flag will now cause
  `dart2js` to fail.

#### Linter

Updated the Linter to `0.1.114`, which includes:

- Fixed `avoid_shadowing_type_parameters` to support extensions and mixins.
- Updated `non_constant_identifier_names` to allow named constructors made up of
  only underscores (`_`).
- Updated `avoid_unused_constructor_parameters` to ignore unused params named in
  all underscores (`_`).

#### Analyzer

- Removed support for the deprecated analysis options file name
  `.analysis_options`.

#### Pub

- Added `pub outdated` command which lists outdated package dependencies, and
  gives advice on how to upgrade.

- `pub get` and `pub upgrade` now fetch version information about hosted
  dependencies in parallel, improving the time package resolution performance.

- `pub get` and `pub upgrade` no longer precompile executables from dependencies
  by default. Instead they are precompiled on first `pub run`. Use
  `pub get --precompile` to get the previous behavior.

- Fixed missing retries of DNS failures during `pub get`.

- If code contains imports for packages not listed in the package's
  `pubspec.yaml` then `pub publish` will reject the package.

- `pub publish` no longer requires the presence of a `homepage` field, if the
  `repository` field is provided.

- `pub publish` warns if non-pre-release packages depends on pre-release
  packages or pre-release Dart SDKs.

- Relative paths in `pubspec.lock` now use `/` also on Windows to make the file
  sharable between machines.

- Fixed language version in [`.dart_tool/package_config.json`][package config]
  for packages without an explicit SDK constraint. Pub now writes an empty
  language version where before the language version of the current SDK would be
  used.

- `%LOCALAPPDATA%` is now preferred over `%APPDATA%` when creating a pub cache
  directory on Windows. `%LOCALAPPDATA%` is not copied when users roam between
  devices.

- `pub publish` warns if LICENSE and README.md files are not called those exact
  names.

- `pub repair cache` downloads hosted packages in parallel.

[package config]:
  https://github.com/dart-lang/language/blob/master/accepted/future-releases/language-versioning/package-config-file-v2.md

## 2.7.2 - 2020-03-23

**Security advisory**: This is a patch release that addresses a vulnerability in
`dart:html` [NodeValidator][] related to DOM clobbering of `previousSibling`.
See the security advisory [CVE-2020-8923][cve-2020-8923] for more details.
Thanks to **Vincenzo di Cicco** for finding and reporting this issue.

This release also improves compatibility with ARMv8 processors (issue [40001][])
and dart:io stability (issue [40589][]).

[nodevalidator]: https://api.dart.dev/stable/dart-html/NodeValidator-class.html
[cve-2020-8923]:
  https://github.com/dart-lang/sdk/security/advisories/GHSA-hfq3-v9pv-p627
[40001]: https://github.com/dart-lang/sdk/issues/40001
[40589]: https://github.com/dart-lang/sdk/issues/40589

## 2.7.1 - 2020-01-23

This is a patch release that improves dart2js compile-time (issue [40217][]).

[40217]: https://github.com/dart-lang/sdk/issues/40217

**Breaking change**: The Dart SDK for macOS is now only available for x64 (issue
[39810][]).

[39810]: https://github.com/dart-lang/sdk/issues/39810

## 2.7.0 - 2019-12-11

**Extension methods** -- which we shipped in preview in 2.6.0 -- are no longer
in preview, and are now officially supported as of 2.7.0. Learn more about them
here:

https://medium.com/dartlang/extension-methods-2d466cd8b308

### Language

- **Breaking change**: [Static extension members][] are accessible when imported
  with a prefix (issue [671][]). In the extension method **preview** launch,
  importing a library with a prefix hid all extension members in addition to
  hiding the extension name, thereby making them inaccessible in the importing
  library except via the explicit override syntax. Based on user feedback, we
  have changed this to make extensions methods accessible even when imported
  with a prefix.

      ```dart
        // "thing.dart"
        class Thing {
        }
        extension Show on Thing {
          void show() {
            print("This is a thing");
          }
       }
       // "client.dart"
       import "thing.dart" as p;
       void test() {
         p.Thing().show(); // Previously an error, now resolves to Show.show
       }
      ```

[static extension members]:
  https://github.com/dart-lang/language/blob/master/accepted/2.6/static-extension-members/feature-specification.md
[671]: https://github.com/dart-lang/language/issues/671

### Core libraries

#### `dart:io`

- **Breaking change**: Added `IOOverrides.serverSocketBind` to aid in writing
  tests that wish to mock `ServerSocket.bind`.

#### `dart:typed_data`

- Added new constructors, `.sublistView(TypedData, [start, end])` to all
  `TypedData` classes. The constructor makes it easier, and less error-prone, to
  create a view of (a slice of) another `TypedData` object.

### Dart VM

- New fields added to existing instances by a reload will now be initialized
  lazily, as if the field was a late field. This makes the initialization order
  program-defined, whereas previously it was undefined.

### Tools

#### Linter

The Linter was updated to `0.1.104`, which includes:

- updated `unnecessary_overrides` to allow overrides when annotations (besides
  `@override` are specified)
- updated `file_names` to allow names w/ leading `_`'s (and improved
  performance)
- new lint: `unnecessary_final`

#### Pub

- `pub get` generates
  [`.dart_tool/package_config.json`](https://github.com/dart-lang/language/blob/62c036cc41b10fb543102d2f73ee132d1e2b2a0e/accepted/future-releases/language-versioning/package-config-file-v2.md)
  in addition to `.packages` to support language versioning.

- `pub publish` now warns about the old flutter plugin registration format.

- `pub publish` now warns about the `author` field in pubspec.yaml being.
  obsolete.

- Show a proper error message when `git` is not installed.

## 2.6.1 - 2019-11-11

This is a patch release that reduces dart2js memory usage (issue [27883][]),
improves stability on arm64 (issue [39090][]) and updates the Dart FFI
documentation.

[27883]: https://github.com/dart-lang/sdk/issues/27883
[39090]: https://github.com/dart-lang/sdk/issues/39090

## 2.6.0 - 2019-11-05

### Language

- **[IN PREVIEW]** [Static extension members][]: A new language feature allowing
  specially declared static functions to be invoked like instance members on
  expressions of appropriate static types is available in preview.

  Static extension members are declared using a new `extension` declaration.
  Example:

  ```dart
  extension MyFancyList<T> on List<T> {
    /// Whether this list has an even length.
    bool get isLengthEven => this.length.isEven;

    /// Whether this list has an odd length.
    bool get isLengthOdd => !isLengthEven;

    /// List of values computed for each pairs of adjacent elements.
    ///
    /// The result always has one element less than this list,
    /// if this list has any elements.
    List<R> combinePairs<R>(R Function(T, T) combine) =>
        [for (int i = 1; i < this.length; i++)
            combine(this[i - 1], this[i])];
  }
  ```

  Extension declarations cannot declare instance fields or constructors.
  Extension members can be invoked explicitly,
  `MyFancyList(intList).isLengthEven)`, or implicitly, `intList.isLengthEven`,
  where the latter is recognized by `intList` matching the `List<T>` "on" type
  of the declaration. An extension member cannot be called implicitly on an
  expression whose static type has a member with the same base-name. In that
  case, the interface member takes precedence. If multiple extension members
  apply to the same implicit invocation, the most specific one is used, if there
  is one such.

  Extensions can be declared on any type, not just interface types.

  ```dart
  extension IntCounter on int {
    /// The numbers from this number to, but not including, [end].
    Iterable<int> to(int end) sync* {
      int step = end < this ? -1 : 1;
      for (int i = this; i != end; i += step) yield i;
    }
  }

  extension CurryFunction<R, S, T> on R Function(S, T) {
    /// Curry a binary function with its first argument.
    R Function(T) curry(S first) => (T second) => this(first, second);
  }
  ```

  [static extension members]:
    https://github.com/dart-lang/language/blob/master/accepted/2.6/static-extension-members/feature-specification.md

- **Breaking change** [#37985](https://github.com/dart-lang/sdk/issues/37985):
  Inference is changed when using `Null` values in a `FutureOr` context. Namely,
  constraints of the forms similar to `Null` <: `FutureOr<T>` now yield `Null`
  as the solution for `T`. For example, the following code will now print
  "Null", and it was printing "dynamic" before (note that the anonymous closure
  `() {}` in the example has `Null` as its return type):

  ```dart
  import 'dart:async';

  void foo<T>(FutureOr<T> Function() f) { print(T); }

  main() { foo(() {}); }
  ```

### Core libraries

- Default values of parameters of abstract methods are no longer available via
  `dart:mirrors`.

#### `dart:developer`

- Added optional `parent` parameter to `TimelineTask` constructor to allow for
  linking of asynchronous timeline events in the DevTools timeline view.

#### `dart:ffi`

- **Breaking change**: The API now makes use of static extension members. Static
  extension members enable the `dart:ffi` API to be more precise with types, and
  provide convenient access to memory through extension getters and setters. The
  extension members on `Pointer` provide `.value` and `.value =` for accessing
  the value in native memory and `[]` and `[]=` for indexed access. The method
  `asExternalTypedData` has been replaced with `asTypedList` extension methods.
  And finally, `Structs` do no longer have a type argument and are accessed
  using the extension member `.ref` on `Pointer`. These changes makes the code
  using `dart:ffi` much more concise.
- **Breaking change**: The memory management has been removed
  (`Pointer.allocate` and `Pointer.free`). Instead, memory management is
  available in [package:ffi](https://pub.dev/packages/ffi).
- **Breaking change**: `Pointer.offsetBy` was removed, use `cast` and
  `elementAt` instead.
- Faster memory load and stores.
- The dartanalyzer (commandline and IDEs) now reports `dart:ffi` static errors.
- Callbacks are now supported in AOT (ahead-of-time) compiled code.

#### `dart:io`

- Added `enableTimelineLogging` property to `HttpClient` which, when enabled,
  will post HTTP connection and request information to the developer timeline
  for all `HttpClient` instances.

### Dart VM

- Added a new tool for AOT compiling Dart programs to native, self-contained
  executables. See https://dart.dev/tools/dart2native for additional details.

### Dart for the Web

#### Dart Dev Compiler (DDC)

- Kernel DDC will no longer accept non-dill files as summary inputs.
- Removed support for the deprecated web extension.

### Tools

#### Linter

The Linter was updated to `0.1.101`, which includes:

- fixed `diagnostic_describe_all_properties` to flag properties in
  `Diagnosticable`s with no debug methods defined
- fixed `noSuchMethod` exception in `camel_case_extensions` when analyzing
  unnamed extensions
- fixed `avoid_print` to catch tear-off usage
- new lint: `avoid_web_libraries_in_flutter` (experimental)
- (internal) prepare `unnecessary_lambdas` for coming `MethodInvocation` vs.
  `FunctionExpressionInvocation` changes

## 2.5.2 - 2019-10-08

This is a patch release with properly signed binaries required for macOS
Catalina (Issue [38765][]).

[38765]: https://github.com/dart-lang/sdk/issues/38765

## 2.5.1 - 2019-09-27

This is a patch release that prevents type inference failures in the analyzer
(Issue [38365][]).

[38365]: https://github.com/dart-lang/sdk/issues/38365

## 2.5.0 - 2019-09-10

### Language

The set of operations allowed in constant expressions has been expanded as
described in the
[constant update proposal](https://github.com/dart-lang/language/issues/61). The
control flow and spread collection features shipped in Dart 2.3 are now also
supported in constants as
[described in the specification here](https://github.com/dart-lang/language/blob/master/accepted/2.3/unified-collections/feature-specification.md#constant-semantics).

Specifically, it is now valid to use the following operations in constant
expressions under the appropriate conditions:

- Casts (`e as T`) and type tests (`e is T`).
- Comparisons to `null`, even for types which override the `==` operator.
- The `&`, `|`, and `^` binary operators on booleans.
- The spread operators (`...` and `...?`).
- An `if` element in a collection literal.

```dart
// Example: these are now valid constants.
const Object i = 3;
const list = [i as int];
const set = {if (list is List<int>) ...list};
const map = {if (i is int) i : "int"};
```

In addition, the semantics of constant evaluation has been changed as follows:

- The `&&` operator only evaluates its second operand if the first evaluates to
  true.
- The `||` operator only evaluates its second operand if the first evaluates to
  false.
- The `??` operator only evaluates its second operand if the first evaluates to
  null.
- The conditional operator (`e ? e1 : e2`) only evaluates one of the two
  branches, depending on the value of the first operand.

```dart
// Example: x is now a valid constant definition.
const String s = null;
const int x = (s == null) ? 0 : s.length;
```

### Core libraries

- **Breaking change** [#36900](https://github.com/dart-lang/sdk/issues/36900):
  The following methods and properties across various core libraries, which used
  to declare a return type of `List<int>`, were updated to declare a return type
  of `Uint8List`:

  - `BytesBuilder.takeBytes()`
  - `BytesBuilder.toBytes()`
  - `Datagram.data`
  - `File.readAsBytes()` (`Future<Uint8List>`)
  - `File.readAsBytesSync()`
  - `InternetAddress.rawAddress`
  - `RandomAccessFile.read()` (`Future<Uint8List>`)
  - `RandomAccessFile.readSync()`
  - `RawSocket.read()`
  - `Utf8Codec.encode()` (and `Utf8Encoder.convert()`)

  In addition, the following classes were updated to implement
  `Stream<Uint8List>` rather than `Stream<List<int>>`:

  - `HttpRequest`
  - `Socket`

  **Possible errors and how to fix them**

  - > The argument type 'Utf8Decoder' can't be assigned to the parameter type
    > 'StreamTransformer<Uint8List, dynamic>'

    > type 'Utf8Decoder' is not a subtype of type 'StreamTransformer' of
    > 'streamTransformer'"

    You can fix these call sites by updating your code to use
    `StreamTransformer.bind()` instead of `Stream.transform()`, like so:

    _Before:_ `stream.transform(utf8.decoder)` _After:_
    `utf8.decoder.bind(stream)`

  - > The argument type 'IOSink' can't be assigned to the parameter type
    > 'StreamConsumer<Uint8List>'

    > type '\_IOSinkImpl' is not a subtype of type 'StreamConsumer<Uint8List>'
    > of 'streamConsumer'

    You can fix these call sites by casting your stream instance to a
    `Stream<List<int>>` before calling `.pipe()` on the stream, like so:

    _Before:_ `stream.pipe(consumer)` _After:_
    `stream.cast<List<int>>().pipe(consumer)`

  Finally, the following typed lists were updated to have their `sublist()`
  methods declare a return type that is the same as the source list:

  - `Int8List.sublist()` → `Int8List`
  - `Int16List.sublist()` → `Int16List`
  - `Int32List.sublist()` → `Int32List`
  - `Int64List.sublist()` → `Int64List`
  - `Int32x4List.sublist()` → `Int32x4List`
  - `Float32List.sublist()` → `Float32List`
  - `Float64List.sublist()` → `Float64List`
  - `Float32x4List.sublist()` → `Float32x4List`
  - `Float64x2List.sublist()` → `Float64x2List`
  - `Uint8List.sublist()` → `Uint8List`
  - `Uint8ClampedList.sublist()` → `Uint8ClampedList`
  - `Uint16List.sublist()` → `Uint16List`
  - `Uint32List.sublist()` → `Uint32List`
  - `Uint64List.sublist()` → `Uint64List`

#### `dart:async`

- Add `value` and `error` constructors on `Stream` to allow easily creating
  single-value or single-error streams.

#### `dart:core`

- Update `Uri` class to support [RFC6874](https://tools.ietf.org/html/rfc6874):
  "%25" or "%" can be appended to the end of a valid IPv6 representing a Zone
  Identifier. A valid zone ID consists of unreversed character or Percent
  encoded octet, which was defined in RFC3986. IPv6addrz = IPv6address "%25"
  ZoneID

  [29456]: https://github.com/dart-lang/sdk/issues/29456

#### `dart:io`

- **Breaking change** [#37192](https://github.com/dart-lang/sdk/issues/37192):
  The `Cookie` class's constructor's `name` and `value` optional positional
  parameters are now mandatory. The signature changes from:

      Cookie([String name, String value])

  to

      Cookie(String name, String value)

  However, it has not been possible to set `name` and `value` to null since Dart
  1.3.0 (2014) where a bug made it impossible. Any code not using both
  parameters or setting any to null would necessarily get a noSuchMethod
  exception at runtime. This change catches such erroneous uses at compile time.
  Since code could not previously correctly omit the parameters, this is not
  really a breaking change.

- **Breaking change** [#37192](https://github.com/dart-lang/sdk/issues/37192):
  The `Cookie` class's `name` and `value` setters now validates that the strings
  are made from the allowed character set and are not null. The constructor
  already made these checks and this fixes the loophole where the setters didn't
  also validate.

### Dart VM

### Tools

#### Pub

- Clean-up invalid git repositories in cache when fetching from git.
- **Breaking change** [#36765](https://github.com/dart-lang/sdk/issues/36765):
  Packages published to [pub.dev](https://pub.dev) can no longer contain git
  dependencies. These packages will be rejected by the server.

#### Linter

The Linter was updated to `0.1.96`, which includes:

- fixed false positives in `unnecessary_parens`
- various changes to migrate to preferred analyzer APIs
- rule test fixes

#### Dartdoc

Dartdoc was updated to `0.28.4`; this version includes several fixes and is
based on a newer version of the analyzer package.

## 2.4.1 - 2019-08-07

This is a patch release that fixes a performance regression in JIT mode, as well
as a potential crash of our AOT compiler.

### Dart VM

- Fixed a performance regression where usage of `Int32List` could trigger
  repeated deoptimizations in JIT mode (Issue [37551][]).

- Fixed a bug where usage of a static getter with name `length` could cause a
  crash in our AOT compiler (Issue [35121][]).

[37551]: https://github.com/dart-lang/sdk/issues/37551
[35121]: https://github.com/dart-lang/sdk/issues/35121

### Dart Dev Compiler (DDC)

Callbacks passed to JS and wrapped with `allowInterop` or
`allowInteropCaptureThis` are now strict about argument counts and argument
types. This may mean that tests which were previously passing and relying on
loose argument checking (too many or too few arguments, or arguments with too
specific types like `List<Something>` instead of `List<dynamic>`) may start
failing. This changes makes DDC behave more like dart2js with the default flags.

## 2.4.0 - 2019-06-27

### Core libraries

#### `dart:isolate`

- `TransferableTypedData` class was added to facilitate faster cross-isolate
  communication of `Uint8List` data.

- **Breaking change**: `Isolate.resolvePackageUri` will always throw an
  `UnsupportedError` when compiled with dart2js or DDC. This was the only
  remaining API in `dart:isolate` that didn't automatically throw since we
  dropped support for this library in [Dart 2.0.0][1]. Note that the API already
  throws in dart2js if the API is used directly without manually setting up a
  `defaultPackagesBase` hook.

[1]: https://github.com/dart-lang/sdk/blob/main/CHANGELOG.md#200---2018-08-07

#### `dart:developer`

- Exposed `result`, `errorCode` and `errorDetail` getters in
  `ServiceExtensionResponse` to allow for better debugging of VM service
  extension RPC results.

#### `dart:io`

- Fixed `Cookie` class interoperability with certain websites by allowing the
  cookie values to be the empty string (Issue [35804][]) and not stripping
  double quotes from the value (Issue [33327][]) in accordance with RFC 6265.

  [33327]: https://github.com/dart-lang/sdk/issues/33327
  [35804]: https://github.com/dart-lang/sdk/issues/35804

- [#36971](https://github.com/dart-lang/sdk/issues/36971): The
  `HttpClientResponse` interface has been extended with the addition of a new
  `compressionState` getter, which specifies whether the body of a response was
  compressed when it was received and whether it has been automatically
  uncompressed via `HttpClient.autoUncompress`.

  As part of this change, a corresponding new enum was added to `dart:io`:
  `HttpClientResponseCompressionState`.

  This is a **breaking change** for those implementing the `HttpClientResponse`
  interface as subclasses will need to implement the new getter.

#### `dart:async`

- **Breaking change** [#36382](https://github.com/dart-lang/sdk/issues/36382):
  The `await for` allowed `null` as a stream due to a bug in `StreamIterator`
  class. This bug has now been fixed.

#### `dart:core`

- [#36171](https://github.com/dart-lang/sdk/issues/36171): The `RegExp`
  interface has been extended with two new constructor named parameters:

  - `unicode:` (`bool`, default: `false`), for Unicode patterns
  - `dotAll:` (`bool`, default: `false`), to change the matching behavior of '.'
    to also match line terminating characters.

  Appropriate properties for these named parameters have also been added so
  their use can be detected after construction.

  In addition, `RegExp` methods that originally returned `Match` objects now
  return a more specific subtype, `RegExpMatch`, which adds two features:

  - `Iterable<String> groupNames`, a property that contains the names of all
    named capture groups
  - `String namedGroup(String name)`, a method that retrieves the match for the
    given named capture group

  This is a **breaking change** for implementers of the `RegExp` interface.
  Subclasses will need to add the new properties and may have to update the
  return types on overridden methods.

### Language

- **Breaking change** [#35097](https://github.com/dart-lang/sdk/issues/35097):
  Covariance of type variables used in super-interfaces is now enforced. For
  example, the following code was previously accepted and will now be rejected:

```dart
class A<X> {};
class B<X> extends A<void Function(X)> {};
```

- The identifier `async` can now be used in asynchronous and generator
  functions.

### Dart for the Web

#### Dart Dev Compiler (DDC)

- Improve `NoSuchMethod` errors for failing dynamic calls. Now they include
  specific information about the nature of the error such as:
  - Attempting to call a null value.
  - Calling an object instance with a null `call()` method.
  - Passing too few or too many arguments.
  - Passing incorrect named arguments.
  - Passing too few or too many type arguments.
  - Passing type arguments to a non-generic method.

### Tools

#### Linter

The Linter was updated to `0.1.91`, which includes the following changes:

- Fixed missed cases in `prefer_const_constructors`
- Fixed `prefer_initializing_formals` to no longer suggest API breaking changes
- Updated `omit_local_variable_types` to allow explicit `dynamic`s
- Fixed null-reference in `unrelated_type_equality_checks`
- New lint: `unsafe_html`
- Broadened `prefer_null_aware_operators` to work beyond local variables.
- Added `prefer_if_null_operators`.
- Fixed `prefer_contains` false positives.
- Fixed `unnecessary_parenthesis` false positives.
- Fixed `prefer_asserts_in_initializer_lists` false positives
- Fixed `curly_braces_in_flow_control_structures` to handle more cases
- New lint: `prefer_double_quotes`
- New lint: `sort_child_properties_last`
- Fixed `type_annotate_public_apis` false positive for `static const`
  initializers

#### Pub

- `pub publish` will no longer warn about missing dependencies for import
  statements in `example/`.
- OAuth2 authentication will explicitly ask for the `openid` scope.

## 2.3.2 - 2019-06-11

This is a patch version release with a security improvement.

### Security vulnerability

- **Security improvement:** On Linux and Android, starting a process with
  `Process.run`, `Process.runSync`, or `Process.start` would first search the
  current directory before searching `PATH` (Issue [37101][]). This behavior
  effectively put the current working directory in the front of `PATH`, even if
  it wasn't in the `PATH`. This release changes that behavior to only searching
  the directories in the `PATH` environment variable. Operating systems other
  than Linux and Android didn't have this behavior and aren't affected by this
  vulnerability.

  This vulnerability could result in execution of untrusted code if a command
  without a slash in its name was run inside an untrusted directory containing
  an executable file with that name:

  ```dart
  Process.run("ls", workingDirectory: "/untrusted/directory")
  ```

  This would attempt to run `/untrusted/directory/ls` if it existed, even though
  it is not in the `PATH`. It was always safe to instead use an absolute path or
  a path containing a slash.

  This vulnerability was introduced in Dart 2.0.0.

[37101]: https://github.com/dart-lang/sdk/issues/37101

## 2.3.1 - 2019-05-21

This is a patch version release with bug fixes.

### Tools

#### dart2js

- Fixed a bug that caused the compiler to crash when it compiled UI-as-code
  features within fields (Issue [36864][]).

[36864]: https://github.com/dart-lang/sdk/issues/36864

## 2.3.0 - 2019-05-08

The focus in this release is on the new "UI-as-code" language features which
make collections more expressive and declarative.

### Language

Flutter is growing rapidly, which means many Dart users are building UI in code
out of big deeply-nested expressions. Our goal with 2.3.0 was to [make that kind
of code easier to write and maintain][ui-as-code]. Collection literals are a
large component, so we focused on three features to make collections more
powerful. We'll use list literals in the examples below, but these features also
work in map and set literals.

[ui-as-code]:
  https://medium.com/dartlang/making-dart-a-better-language-for-ui-f1ccaf9f546c

#### Spread

Placing `...` before an expression inside a collection literal unpacks the
result of the expression and inserts its elements directly inside the new
collection. Where before you had to write something like this:

```dart
CupertinoPageScaffold(
  child: ListView(children: [
    Tab2Header()
  ]..addAll(buildTab2Conversation())
    ..add(buildFooter())),
);
```

Now you can write this:

```dart
CupertinoPageScaffold(
  child: ListView(children: [
    Tab2Header(),
    ...buildTab2Conversation(),
    buildFooter()
  ]),
);
```

If you know the expression might evaluate to null and you want to treat that as
equivalent to zero elements, you can use the null-aware spread `...?`.

#### Collection if

Sometimes you might want to include one or more elements in a collection only
under certain conditions. If you're lucky, you can use a `?:` operator to
selectively swap out a single element, but if you want to exchange more than one
or omit elements, you are forced to write imperative code like this:

```dart
Widget build(BuildContext context) {
  var children = [
    IconButton(icon: Icon(Icons.menu)),
    Expanded(child: title)
  ];

  if (isAndroid) {
    children.add(IconButton(icon: Icon(Icons.search)));
  }

  return Row(children: children);
}
```

We now allow `if` inside collection literals to conditionally omit or (with
`else`) swap out an element:

```dart
Widget build(BuildContext context) {
  return Row(
    children: [
      IconButton(icon: Icon(Icons.menu)),
      Expanded(child: title),
      if (isAndroid)
        IconButton(icon: Icon(Icons.search)),
    ],
  );
}
```

Unlike the existing `?:` operator, a collection `if` can be composed with
spreads to conditionally include or omit multiple items:

```dart
Widget build(BuildContext context) {
  return Row(
    children: [
      IconButton(icon: Icon(Icons.menu)),
      if (isAndroid) ...[
        Expanded(child: title),
        IconButton(icon: Icon(Icons.search)),
      ]
    ],
  );
}
```

#### Collection for

In many cases, the higher-order methods on Iterable give you a declarative way
to modify a collection in the context of a single expression. But some
operations, especially involving both transforming and filtering, can be
cumbersome to express in a functional style.

To solve this problem, you can use `for` inside a collection literal. Each
iteration of the loop produces an element which is then inserted in the
resulting collection. Consider the following code:

```dart
var command = [
  engineDartPath,
  frontendServer,
  ...fileSystemRoots.map((root) => "--filesystem-root=$root"),
  ...entryPoints
      .where((entryPoint) => fileExists("lib/$entryPoint.json"))
      .map((entryPoint) => "lib/$entryPoint"),
  mainPath
];
```

With a collection `for`, the code becomes simpler:

```dart
var command = [
  engineDartPath,
  frontendServer,
  for (var root in fileSystemRoots) "--filesystem-root=$root",
  for (var entryPoint in entryPoints)
    if (fileExists("lib/$entryPoint.json")) "lib/$entryPoint",
  mainPath
];
```

As you can see, all three of these features can be freely composed. For full
details of the changes, see [the official proposal][ui-as-code proposal].

[ui-as-code proposal]:
  https://github.com/dart-lang/language/blob/master/accepted/future-releases/unified-collections/feature-specification.md

**Note: These features are not currently supported in _const_ collection
literals. In a future release, we intend to relax this restriction and allow
spread and collection `if` inside const collections.**

### Core library changes

#### `dart:isolate`

- Added `debugName` property to `Isolate`.
- Added `debugName` optional parameter to `Isolate.spawn` and
  `Isolate.spawnUri`.

#### `dart:core`

- RegExp patterns can now use lookbehind assertions.
- RegExp patterns can now use named capture groups and named backreferences.
  Currently, named group matches can only be retrieved in Dart either by the
  implicit index of the named group or by downcasting the returned Match object
  to the type RegExpMatch. The RegExpMatch interface contains methods for
  retrieving the available group names and retrieving a match by group name.

### Dart VM

- The VM service now requires an authentication code by default. This behavior
  can be disabled by providing the `--disable-service-auth-codes` flag.

- Support for deprecated flags '-c' and '--checked' has been removed.

### Dart for the Web

#### dart2js

A binary format was added to dump-info. The old JSON format is still available
and provided by default, but we are starting to deprecate it. The new binary
format is more compact and cheaper to generate. On some large apps we tested, it
was 4x faster to serialize and used 6x less memory.

To use the binary format today, use `--dump-info=binary`, instead of
`--dump-info`.

What to expect next?

- The [visualizer tool][visualizer] will not be updated to support the new
  binary format, but you can find several command-line tools at
  `package:dart2js_info` that provide similar features to those in the
  visualizer.

- The command-line tools in `package:dart2js_info` also work with the old JSON
  format, so you can start using them even before you enable the new format.

- In a future release `--dump-info` will default to `--dump-info=binary`. At
  that point, there will be an option to fallback to the JSON format, but the
  visualizer tool will be deprecated.

- A release after that, the JSON format will no longer be available from
  dart2js, but may be available from a command-line tool in
  `package:dart2js_info`.

[visualizer]: https://dart-lang.github.io/dump-info-visualizer/

### Tools

#### dartfmt

- Tweak set literal formatting to follow other collection literals.
- Add support for "UI as code" features.
- Properly format trailing commas in assertions.
- Improve indentation of adjacent strings in argument lists.

#### Linter

The Linter was updated to `0.1.86`, which includes the following changes:

- Added the following lints: `prefer_inlined_adds`,
  `prefer_for_elements_to_map_fromIterable`,
  `prefer_if_elements_to_conditional_expressions`,
  `diagnostic_describe_all_properties`.
- Updated `file_names` to skip prefixed-extension Dart files (`.css.dart`,
  `.g.dart`, etc.).
- Fixed false positives in `unnecessary_parenthesis`.

#### Pub

- Added a CHANGELOG validator that complains if you `pub publish` without
  mentioning the current version.
- Removed validation of library names when doing `pub publish`.
- Added support for `pub global activate`ing package from a custom pub URL.
- Added subcommand: `pub logout`. Logs you out of the current session.

#### Dart native

Initial support for compiling Dart apps to native machine code has been added.
Two new tools have been added to the `bin` folder of the Dart SDK:

- `dart2aot`: AOT (ahead-of-time) compiles a Dart program to native machine
  code. The tool is supported on Windows, macOS, and Linux.

- `dartaotruntime`: A small runtime used for executing an AOT compiled program.

## 2.2.0 - 2019-02-26

### Language

Sets now have a literal syntax like lists and maps do:

```dart
var set = {1, 2, 3};
```

Using curly braces makes empty sets ambiguous with maps:

```dart
var collection = {}; // Empty set or map?
```

To avoid breaking existing code, an ambiguous literal is treated as a map. To
create an empty set, you can rely on either a surrounding context type or an
explicit type argument:

```dart
// Variable type forces this to be a set:
Set<int> set = {};

// A single type argument means this must be a set:
var set2 = <int>{};
```

Set literals are released on all platforms. The `set-literals` experiment flag
has been disabled.

### Tools

#### Analyzer

- The `DEPRECATED_MEMBER_USE` hint was split into two hints:

  - `DEPRECATED_MEMBER_USE` reports on usage of `@deprecated` members declared
    in a different package.
  - `DEPRECATED_MEMBER_USE_FROM_SAME_PACKAGE` reports on usage of `@deprecated`
    members declared in the same package.

#### Linter

Upgraded the linter to `0.1.82` which adds the following improvements:

- Added `provide_deprecation_message`, and
  `use_full_hex_values_for_flutter_colors`, `prefer_null_aware_operators`.
- Fixed `prefer_const_declarations` set literal false-positives.
- Updated `prefer_collection_literals` to support set literals.
- Updated `unnecessary_parenthesis` play nicer with cascades.
- Removed deprecated lints from the "all options" sample.
- Stopped registering "default lints".
- Fixed `hash_and_equals` to respect `hashCode` fields.

### Other libraries

#### `package:kernel`

- **Breaking change:** The `klass` getter on the `InstanceConstant` class in the
  Kernel AST API has been renamed to `classNode` for consistency.

- **Breaking change:** Updated `Link` implementation to utilize true symbolic
  links instead of junctions on Windows. Existing junctions will continue to
  work with the new `Link` implementation, but all new links will create
  symbolic links.

  To create a symbolic link, Dart must be run with administrative privileges or
  Developer Mode must be enabled, otherwise a `FileSystemException` will be
  raised with errno set to `ERROR_PRIVILEGE_NOT_HELD` (Issue [33966]).

[33966]: https://github.com/dart-lang/sdk/issues/33966

## 2.1.1 - 2019-02-18

This is a patch version release. Again, the team's focus was mostly on improving
performance and stability after the large changes in Dart 2.0.0. In particular,
dart2js now always uses the "fast startup" emitter and the old emitter has been
removed.

There are a couple of very minor **breaking changes:**

- In `dart:io`, adding to a closed `IOSink` now throws a `StateError`.

- On the Dart VM, a soundness hole when using `dart:mirrors` to reflectively
  invoke a method in an incorrect way that violates its static types has been
  fixed (Issue [35611][]).

### Language

This release has no language changes.

### Core library

#### `dart:core`

- Made `DateTime.parse()` also recognize `,` as a valid decimal separator when
  parsing from a string (Issue [35576][]).

[35576]: https://github.com/dart-lang/sdk/issues/35576

#### `dart:html`

- Added methods `Element.removeAttribute`, `Element.removeAttributeNS`,
  `Element.hasAttribute` and `Element.hasAttributeNS`. (Issue [35655][]).
- Improved dart2js compilation of `element.attributes.remove(name)` to generate
  `element.removeAttribute(name)`, so that there is no performance reason to
  migrate to the above methods.
- Fixed a number of `dart:html` bugs:

  - Fixed HTML API's with callback typedef to correctly convert Dart functions
    to JS functions (Issue [35484]).
  - HttpStatus constants exposed in `dart:html` (Issue [34318]).
  - Expose DomName `ondblclick` and `dblclickEvent` for Angular analyzer.
  - Fixed `removeAll` on `classes`; `elements` parameter should be
    `Iterable<Object>` to match Set's `removeAll` not `Iterable<E>` (Issue
    [30278]).
  - Fixed a number of methods on DataTransferItem, Entry, FileEntry and
    DirectoryEntry which previously returned NativeJavaScriptObject. This fixes
    handling drag/drop of files/directories (Issue [35510]).
  - Added ability to allow local file access from Chrome browser in ddb.

[35655]: https://github.com/dart-lang/sdk/issues/35655
[30278]: https://github.com/dart-lang/sdk/issues/30278
[34318]: https://github.com/dart-lang/sdk/issues/34318
[35484]: https://github.com/dart-lang/sdk/issues/35484
[35510]: https://github.com/dart-lang/sdk/issues/35510

#### `dart:io`

- **Breaking change:** Adding to a closed `IOSink` now throws a `StateError`.
- Added ability to get and set low level socket options.

[29554]: https://github.com/dart-lang/sdk/issues/29554

### Dart VM

In previous releases it was possible to violate static types using
`dart:mirrors`. This code would run without any TypeErrors and print
"impossible" output:

```dart
import 'dart:mirrors';

class A {
  void method(int v) {
    if (v != null && v is! int) {
      print("This should be impossible: expected null or int got ${v}");
    }
  }
}

void main() {
  final obj = A();
  reflect(obj).invoke(#method, ['not-an-number']);
}
```

This bug is fixed now. Only code that already violates static typing will break.
See Issue [35611][] for more details.

[35611]: https://github.com/dart-lang/sdk/issues/35611

### Dart for the Web

#### dart2js

- The old "full emitter" back-end is removed and dart2js always uses the "fast
  startup" back-end. The generated fast startup code is optimized to load
  faster, even though it can be slightly larger. The `--fast-startup` and
  `--no-fast-startup` are allowed but ignored. They will be removed in a future
  version.

- We fixed a bug in how deferred constructor calls were incorrectly not marked
  as deferred. The old behavior didn't cause breakages, but was imprecise and
  pushed more code to the main output unit.

- A new deferred split algorithm implementation was added.

  This implementation fixes a soundness bug and addresses performance issues of
  the previous implementation, because of that it can have a visible impact on
  apps. In particular:

  - We fixed a performance issue which was introduced when we migrated to the
    common front-end. On large apps, the fix can cut 2/3 of the time spent on
    this task.

  - We fixed a bug in how inferred types were categorized (Issue [35311][]). The
    old behavior was unsound and could produce broken programs. The fix may
    cause more code to be pulled into the main output unit.

    This shows up frequently when returning deferred values from closures since
    the closure's inferred return type is the deferred type. For example, if you
    have:

    ```dart
    () async {
      await deferred_prefix.loadLibrary();
      return new deferred_prefix.Foo();
    }
    ```

    The closure's return type is `Future<Foo>`. The old implementation defers
    `Foo`, and incorrectly makes the return type `Future<dynamic>`. This may
    break in places where the correct type is expected.

    The new implementation will not defer `Foo`, and will place it in the main
    output unit. If your intent is to defer it, then you need to ensure the
    return type is not inferred to be `Foo`. For example, you can do so by
    changing the code to a named closure with a declared type, or by ensuring
    that the return expression has the type you want, like:

    ```dart
    () async {
      await deferred_prefix.loadLibrary();
      return new deferred_prefix.Foo() as dynamic;
    }
    ```

    Because the new implementation might require you to inspect and fix your
    app, we exposed two temporary flags:

  - The `--report-invalid-deferred-types` causes dart2js to run both the old and
    new algorithms and report any cases where an invalid type was detected.

  - The `--new-deferred-split` flag enables this new algorithm.

- The `--categories=*` flag is being replaced. `--categories=all` was only used
  for testing and it is no longer supported. `--categories=Server` continues to
  work at this time but it is deprecated, please use `--server-mode` instead.

- The `--library-root` flag was replaced by `--libraries-spec`. This flag is
  rarely used by developers invoking dart2js directly. It's important for
  integrating dart2js with build systems. See `--help` for more details on the
  new flag.

[35311]: https://github.com/dart-lang/sdk/issues/35311

### Tools

#### Analyzer

- Support for `declarations-casts` has been removed and the `implicit-casts`
  option now has the combined semantics of both options. This means that users
  that disable `implicit-casts` might now see errors that were not previously
  being reported.

- New hints added:

  - `NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR` and
    `NON_CONST_CALL_TO_LITERAL_CONSTRUCTOR_USING_NEW` inform you when a
    `@literal` const constructor is called in a non-const context (or with
    `new`).
  - `INVALID_LITERAL_ANNOTATION` reports when something other than a const
    constructor is annotated with `@literal`.
  - `SUBTYPE_OF_SEALED_CLASS` reports when any class or mixin subclasses
    (extends, implements, mixes in, or constrains to) a `@sealed` class, and the
    two are declared in different packages.
  - `MIXIN_ON_SEALED_CLASS` reports when a `@sealed` class is used as a
    superclass constraint of a mixin.

#### dartdoc

Default styles now work much better on mobile. Simple browsing and searching of
API docs now work in many cases.

Upgraded the linter to `0.1.78` which adds the following improvements:

- Added `prefer_final_in_for_each`, `unnecessary_await_in_return`,
  `use_function_type_syntax_for_parameters`, `avoid_returning_null_for_future`,
  and `avoid_shadowing_type_parameters`.
- Updated `invariant_booleans` status to experimental.
- Fixed `type_annotate_public_apis` false positives on local functions.
- Fixed `avoid_shadowing_type_parameters` to report shadowed type parameters in
  generic typedefs.
- Fixed `use_setters_to_change_properties` to not wrongly lint overriding
  methods.
- Fixed `cascade_invocations` to not lint awaited targets.
- Fixed `prefer_conditional_assignment` false positives.
- Fixed `join_return_with_assignment` false positives.
- Fixed `cascade_invocations` false positives.
- Deprecated `prefer_bool_in_asserts` as it is redundant in Dart 2.

## 2.1.0 - 2018-11-15

This is a minor version release. The team's focus was mostly on improving
performance and stability after the large changes in Dart 2.0.0. Notable
changes:

- We've introduced a dedicated syntax for declaring a mixin. Instead of the
  `class` keyword, it uses `mixin`:

  ```dart
  mixin SetMixin<E> implements Set<E> {
    ...
  }
  ```

  The new syntax also enables `super` calls inside mixins.

- Integer literals now work in double contexts. When passing a literal number to
  a function that expects a `double`, you no longer need an explicit `.0` at the
  end of the number. In releases before 2.1, you need code like this when
  setting a double like `fontSize`:

  ```dart
  TextStyle(fontSize: 18.0)
  ```

  Now you can remove the `.0`:

  ```dart
  TextStyle(fontSize: 18)
  ```

  In releases before 2.1, `fontSize : 18` causes a static error. This was a
  common mistake and source of friction.

- **Breaking change:** A number of static errors that should have been detected
  and reported were not supported in 2.0.0. These are reported now, which means
  existing incorrect code may show new errors.

- `dart:core` now exports `Future` and `Stream`. You no longer need to import
  `dart:async` to use those very common types.

### Language

- Introduced a new syntax for mixin declarations.

  ```dart
  mixin SetMixin<E> implements Set<E> {
    ...
  }
  ```

  Most classes that are intended to be used as mixins are intended to _only_ be
  used as mixins. The library author doesn't want users to be able to construct
  or subclass the class. The new syntax makes that intent clear and enforces it
  in the type system. It is an error to extend or construct a type declared
  using `mixin`. (You can implement it since mixins expose an implicit
  interface.)

  Over time, we expect most mixin declarations to use the new syntax. However,
  if you have a "mixin" class where users _are_ extending or constructing it,
  note that moving it to the new syntax is a breaking API change since it
  prevents users from doing that. If you have a type like this that is a mixin
  as well as being a concrete class and/or superclass, then the existing syntax
  is what you want.

  If you need to use a `super` inside a mixin, the new syntax is required. This
  was previously only allowed with the experimental `--supermixins` flag because
  it has some complex interactions with the type system. The new syntax
  addresses those issues and lets you use `super` calls by declaring the
  superclass constraint your mixin requires:

  ```dart
  class Superclass {
    superclassMethod() {
      print("in superclass");
    }
  }

  mixin SomeMixin on Superclass {
    mixinMethod() {
      // This is OK:
      super.superclassMethod();
    }
  }

  class GoodSub extends Superclass with SomeMixin {}

  class BadSub extends Object with SomeMixin {}
  // Error: Since the super() call in mixinMethod() can't find a
  // superclassMethod() to call, this is prohibited.
  ```

  Even if you don't need to use `super` calls, the new mixin syntax is good
  because it clearly expresses that you intend the type to be mixed in.

- Allow integer literals to be used in double contexts. An integer literal used
  in a place where a double is required is now interpreted as a double value.
  The numerical value of the literal needs to be precisely representable as a
  double value.

- Integer literals compiled to JavaScript are now allowed to have any value that
  can be exactly represented as a JavaScript `Number`. They were previously
  limited to such numbers that were also representable as signed 64-bit
  integers.

**(Breaking)** A number of static errors that should have been detected and
reported were not supported in 2.0.0. These are reported now, which means
existing incorrect code may show new errors:

- **Setters with the same name as the enclosing class aren't allowed.** (Issue
  [34225][].) It is not allowed to have a class member with the same name as the
  enclosing class:

  ```dart
  class A {
    set A(int x) {}
  }
  ```

  Dart 2.0.0 incorrectly allows this for setters (only). Dart 2.1.0 rejects it.

  _To fix:_ This is unlikely to break anything, since it violates all style
  guides anyway.

- **Constant constructors cannot redirect to non-constant constructors.** (Issue
  [34161][].) It is not allowed to have a constant constructor that redirects to
  a non-constant constructor:

  ```dart
  class A {
    const A.foo() : this(); // Redirecting to A()
    A() {}
  }
  ```

  Dart 2.0.0 incorrectly allows this. Dart 2.1.0 rejects it.

  _To fix:_ Make the target of the redirection a properly const constructor.

- **Abstract methods may not unsoundly override a concrete method.** (Issue
  [32014][].) Concrete methods must be valid implementations of their
  interfaces:

  ```dart
  class A {
    num get thing => 2.0;
  }

  abstract class B implements A {
    int get thing;
  }

  class C extends A with B {}
  // 'thing' from 'A' is not a valid override of 'thing' from 'B'.

  main() {
    print(new C().thing.isEven); // Expects an int but gets a double.
  }
  ```

  Dart 2.0.0 allows unsound overrides like the above in some cases. Dart 2.1.0
  rejects them.

  _To fix:_ Relax the type of the invalid override, or tighten the type of the
  overridden method.

- **Classes can't implement FutureOr.** (Issue [33744][].) Dart doesn't allow
  classes to implement the FutureOr type:

  ```dart
  class A implements FutureOr<Object> {}
  ```

  Dart 2.0.0 allows classes to implement FutureOr. Dart 2.1.0 does not.

  _To fix:_ Don't do this.

- **Type arguments to generic typedefs must satisfy their bounds.** (Issue
  [33308][].) If a parameterized typedef specifies a bound, actual arguments
  must be checked against it:

  ```dart
  class A<X extends int> {}

  typedef F<Y extends int> = A<Y> Function();

  F<num> f = null;
  ```

  Dart 2.0.0 allows bounds violations like `F<num>` above. Dart 2.1.0 rejects
  them.

  _To fix:_ Either remove the bound on the typedef parameter, or pass a valid
  argument to the typedef.

- **Constructor invocations must use valid syntax, even with optional `new`.**
  (Issue [34403][].) Type arguments to generic named constructors go after the
  class name, not the constructor name, even when used without an explicit
  `new`:

  ```dart
  class A<T> {
    A.foo() {}
  }

  main() {
    A.foo<String>(); // Incorrect syntax, was accepted in 2.0.0.
    A<String>.foo(); // Correct syntax.
  }
  ```

  Dart 2.0.0 accepts the incorrect syntax when the `new` keyword is left out.
  Dart 2.1.0 correctly rejects this code.

  _To fix:_ Move the type argument to the correct position after the class name.

- **Instance members should shadow prefixes.** (Issue [34498][].) If the same
  name is used as an import prefix and as a class member name, then the class
  member name takes precedence in the class scope.

  ```dart
  import 'dart:core';
  import 'dart:core' as core;

  class A {
    core.List get core => null; // "core" refers to field, not prefix.
  }
  ```

  Dart 2.0.0 incorrectly resolves the use of `core` in `core.List` to the prefix
  name. Dart 2.1.0 correctly resolves this to the field name.

  _To fix:_ Change the prefix name to something which does not clash with the
  instance member.

- **Implicit type arguments in extends clauses must satisfy the class bounds.**
  (Issue [34532][].) Implicit type arguments for generic classes are computed if
  not passed explicitly, but when used in an `extends` clause they must be
  checked for validity:

  ```dart
  class Foo<T> {}

  class Bar<T extends Foo<T>> {}

  class Baz extends Bar {} // Should error because Bar completes to Bar<Foo>
  ```

  Dart 2.0.0 accepts the broken code above. Dart 2.1.0 rejects it.

  _To fix:_ Provide explicit type arguments to the superclass that satisfy the
  bound for the superclass.

- **Mixins must correctly override their superclasses.** (Issue [34235][].) In
  some rare cases, combinations of uses of mixins could result in invalid
  overrides not being caught:

  ```dart
  class A {
    num get thing => 2.0;
  }

  class M1 {
    int get thing => 2;
  }

  class B = A with M1;

  class M2 {
    num get thing => 2.0;
  }

  class C extends B with M2 {} // 'thing' from 'M2' not a valid override.

  main() {
    M1 a = new C();
    print(a.thing.isEven); // Expects an int but gets a double.
  }
  ```

  Dart 2.0.0 accepts the above example. Dart 2.1.0 rejects it.

  _To fix:_ Ensure that overriding methods are correct overrides of their
  superclasses, either by relaxing the superclass type, or tightening the
  subclass/mixin type.

[32014]: https://github.com/dart-lang/sdk/issues/32014
[33308]: https://github.com/dart-lang/sdk/issues/33308
[33744]: https://github.com/dart-lang/sdk/issues/33744
[34161]: https://github.com/dart-lang/sdk/issues/34161
[34225]: https://github.com/dart-lang/sdk/issues/34225
[34235]: https://github.com/dart-lang/sdk/issues/34235
[34403]: https://github.com/dart-lang/sdk/issues/34403
[34498]: https://github.com/dart-lang/sdk/issues/34498
[34532]: https://github.com/dart-lang/sdk/issues/34532

### Core libraries

#### `dart:async`

- Fixed a bug where calling `stream.take(0).drain(value)` would not correctly
  forward the `value` through the returned `Future`.
- Added a `StreamTransformer.fromBind` constructor.
- Updated `Stream.fromIterable` to send a done event after the error when the
  iterator's `moveNext` throws, and handle if the `current` getter throws (issue
  [33431][]).

[33431]: http://dartbug.com/33431

#### `dart:core`

- Added `HashMap.fromEntries` and `LinkedHashmap.fromEntries` constructors.
- Added `ArgumentError.checkNotNull` utility method.
- Made `Uri` parsing more permissive about `[` and `]` occurring in the path,
  query or fragment, and `#` occurring in fragment.
- Exported `Future` and `Stream` from `dart:core`.
- Added operators `&`, `|` and `^` to `bool`.
- Added missing methods to `UnmodifiableMapMixin`. Some maps intended to be
  unmodifiable incorrectly allowed new methods added in Dart 2 to succeed.
- Deprecated the `provisional` annotation and the `Provisional` annotation
  class. These should have been removed before releasing Dart 2.0, and they have
  no effect.

#### `dart:html`

Fixed Service Workers and any Promise/Future API with a Dictionary parameter.

APIs in dart:html (that take a Dictionary) will receive a Dart Map parameter.
The Map parameter must be converted to a Dictionary before passing to the
browser's API. Before this change, any Promise/Future API with a Map/Dictionary
parameter never called the Promise and didn't return a Dart Future - now it
does.

This caused a number of breaks especially in Service Workers (register, etc.).
Here is a complete list of the fixed APIs:

- BackgroundFetchManager
  - `Future<BackgroundFetchRegistration> fetch(String id, Object requests, [Map options])`
- CacheStorage
  - `Future match(/*RequestInfo*/ request, [Map options])`
- CanMakePayment
  - `Future<List<Client>> matchAll([Map options])`
- CookieStore
  - `Future getAll([Map options])`
  - `Future set(String name, String value, [Map options])`
- CredentialsContainer
  - `Future get([Map options])`
  - `Future create([Map options])`
- ImageCapture
  - `Future setOptions(Map photoSettings)`
- MediaCapabilities
  - `Future<MediaCapabilitiesInfo> decodingInfo(Map configuration)`
  - `Future<MediaCapabilitiesInfo> encodingInfo(Map configuration)`
- MediaStreamTrack
  - `Future applyConstraints([Map constraints])`
- Navigator
  - `Future requestKeyboardLock([List<String> keyCodes])`
  - `Future requestMidiAccess([Map options])`
  - `Future share([Map data])`
- OffscreenCanvas
  - `Future<Blob> convertToBlob([Map options])`
- PaymentInstruments
  - `Future set(String instrumentKey, Map details)`
- Permissions
  - `Future<PermissionStatus> query(Map permission)`
  - `Future<PermissionStatus> request(Map permissions)`
  - `Future<PermissionStatus> revoke(Map permission)`
- PushManager
  - `Future permissionState([Map options])`
  - `Future<PushSubscription> subscribe([Map options])`
- RtcPeerConnection

  - Changed:

    ```dart
    Future createAnswer([options_OR_successCallback,
        RtcPeerConnectionErrorCallback failureCallback,
        Map mediaConstraints])
    ```

    to:

    ```dart
    Future<RtcSessionDescription> createAnswer([Map options])
    ```

  - Changed:

    ```dart
    Future createOffer([options_OR_successCallback,
        RtcPeerConnectionErrorCallback failureCallback,
        Map rtcOfferOptions])
    ```

    to:

    ```dart
    Future<RtcSessionDescription> createOffer([Map options])
    ```

  - Changed:

    ```dart
    Future setLocalDescription(Map description,
        VoidCallback successCallback,
        [RtcPeerConnectionErrorCallback failureCallback])
    ```

    to:

    ```dart
    Future setLocalDescription(Map description)
    ```

  - Changed:

    ```dart
    Future setLocalDescription(Map description,
        VoidCallback successCallback,
        [RtcPeerConnectionErrorCallback failureCallback])
    ```

    to:

    ```dart
    Future setRemoteDescription(Map description)
    ```

- ServiceWorkerContainer
  - `Future<ServiceWorkerRegistration> register(String url, [Map options])`
- ServiceWorkerRegistration
  - `Future<List<Notification>> getNotifications([Map filter])`
  - `Future showNotification(String title, [Map options])`
- VRDevice
  - `Future requestSession([Map options])`
  - `Future supportsSession([Map options])`
- VRSession
  - `Future requestFrameOfReference(String type, [Map options])`
- Window
  - `Future fetch(/*RequestInfo*/ input, [Map init])`
- WorkerGlobalScope
  - `Future fetch(/*RequestInfo*/ input, [Map init])`

In addition, exposed Service Worker "self" as a static getter named "instance".
The instance is exposed on four different Service Worker classes and can throw a
InstanceTypeError if the instance isn't of the class expected
(WorkerGlobalScope.instance will always work and not throw):

- `SharedWorkerGlobalScope.instance`
- `DedicatedWorkerGlobalScope.instance`
- `ServiceWorkerGlobalScope.instance`
- `WorkerGlobalScope.instance`

#### `dart:io`

- Added new HTTP status codes.

### Dart for the Web

#### dart2js

- **(Breaking)** Duplicate keys in a const map are not allowed and produce a
  compile-time error. Dart2js used to report this as a warning before. This was
  already an error in dartanalyzer and DDC and will be an error in other tools
  in the future as well.

- Added `-O` flag to tune optimization levels. For more details run
  `dart2js -h -v`.

  We recommend to enable optimizations using the `-O` flag instead of individual
  flags for each optimization. This is because the `-O` flag is intended to be
  stable and continue to work in future versions of dart2js, while individual
  flags may come and go.

  At this time we recommend to test and debug with `-O1` and to deploy with
  `-O3`.

### Tool Changes

#### dartfmt

- Addressed several dartfmt issues when used with the new CFE parser.

#### Linter

Bumped the linter to `0.1.70` which includes the following new lints:

- `avoid_returning_null_for_void`
- `sort_pub_dependencies`
- `prefer_mixin`
- `avoid_implementing_value_types`
- `flutter_style_todos`
- `avoid_void_async`
- `prefer_void_to_null`

and improvements:

- Fixed NPE in `prefer_iterable_whereType`.
- Improved message display for `await_only_futures`
- Performance improvements for `null_closures`
- Mixin support
- Updated `sort_constructors_first` to apply to all members.
- Updated `unnecessary_this` to work on field initializers.
- Updated `unawaited_futures` to ignore assignments within cascades.
- Improved handling of constant expressions with generic type params.
- NPE fix for `invariant_booleans`.
- Improved docs for `unawaited_futures`.
- Updated `unawaited_futures` to check cascades.
- Relaxed `void_checks` (allowing `T Function()` to be assigned to
  `void Function()`).
- Fixed false positives in `lines_longer_than_80_chars`.

#### Pub

- Renamed the `--checked` flag to `pub run` to `--enable-asserts`.
- Pub will no longer delete directories named "packages".
- The `--packages-dir` flag is now ignored.

## 2.0.0 - 2018-08-07

This is the first major version release of Dart since 1.0.0, so it contains many
significant changes across all areas of the platform. Large changes include:

- **(Breaking)** The unsound optional static type system has been replaced with
  a sound static type system using type inference and runtime checks. This was
  formerly called "[strong mode][]" and only used by the Dart for web products.
  Now it is the one official static type system for the entire platform and
  replaces the previous "checked" and "production" modes.

- **(Breaking)** Functions marked `async` now run synchronously until the first
  `await` statement. Previously, they would return to the event loop once at the
  top of the function body before any code runs ([issue 30345][]).

- **(Breaking)** Constants in the core libraries have been renamed from
  `SCREAMING_CAPS` to `lowerCamelCase`.

- **(Breaking)** Many new methods have been added to core library classes. If
  you implement the interfaces of these classes, you will need to implement the
  new methods.

- **(Breaking)** "dart:isolate" and "dart:mirrors" are no longer supported when
  using Dart for the web. They are still supported in the command-line VM.

- **(Breaking)** Pub's transformer-based build system has been replaced by a
  [new build system][build system].

- The `new` keyword is optional and can be omitted. Likewise, `const` can be
  omitted inside a const context ([issue 30921][]).

- Dartium is no longer maintained or supported.

[issue 30345]: https://github.com/dart-lang/sdk/issues/30345
[issue 30921]: https://github.com/dart-lang/sdk/issues/30921
[strong mode]: https://dart.dev/guides/language/type-system
[build system]: https://github.com/dart-lang/build

### Language

- "[Strong mode][]" is now the official type system of the language.

- The `new` keyword is optional and can be omitted. Likewise, `const` can be
  omitted inside a const context.

- A string in a `part of` declaration may now be used to refer to the library
  this file is part of. A library part can now declare its library as either:

  ```dart
  part of name.of.library;
  ```

  Or:

  ```dart
  part of "uriReferenceOfLibrary.dart";
  ```

  This allows libraries with no library declarations (and therefore no name) to
  have parts, and it allows tools to easily find the library of a part file. The
  Dart 1.0 syntax is supported but deprecated.

- Functions marked `async` now run synchronously until the first `await`
  statement. Previously, they would return to the event loop once at the top of
  the function body before any code runs ([issue 30345][]).

- The type `void` is now a Top type like `dynamic`, and `Object`. It also now
  has new errors for being used where not allowed (such as being assigned to any
  non-`void`-typed parameter). Some libraries (importantly, mockito) may need to
  be updated to accept void values to keep their APIs working.

- Future flattening is now done only as specified in the Dart 2.0 spec, rather
  than more broadly. This means that the following code has an error on the
  assignment to `y`.

  ```dart
  test() {
    Future<int> f;
    var x = f.then<Future<List<int>>>((x) => []);
    Future<List<int>> y = x;
  }
  ```

- Invocations of `noSuchMethod()` receive default values for optional args. The
  following program used to print "No arguments passed", and now prints "First
  argument is 3".

  ```dart
  abstract class B {
    void m([int x = 3]);
  }

  class A implements B {
    noSuchMethod(Invocation i) {
      if (i.positionalArguments.length == 0) {
        print("No arguments passed");
      } else {
        print("First argument is ${i.positionalArguments[0]}");
      }
    }
  }

  void main() {
    A().m();
  }
  ```

- Bounds on generic functions are invariant. The following program now issues an
  invalid override error ([issue 29014][sdk#29014]):

  ```dart
  class A {
    void f<T extends int>() {}
  }

  class B extends A {
    @override
    void f<T extends num>() {}
  }
  ```

- Numerous corner case bugs around return statements in synchronous and
  asynchronous functions fixed. Specifically:

  - Issues [31887][issue 31887], [32881][issue 32881]. Future flattening should
    not be recursive.
  - Issues [30638][issue 30638], [32233][issue 32233]. Incorrect downcast errors
    with `FutureOr`.
  - Issue [32233][issue 32233]. Errors when returning `FutureOr`.
  - Issue [33218][issue 33218]. Returns in functions with void related types.
  - Issue [31278][issue 31278]. Incorrect hint on empty returns in async.
    functions.

- An empty `return;` in an async function with return type `Future<Object>` does
  not report an error.

- `return exp;` where `exp` has type `void` in an async function is now an error
  unless the return type of the function is `void` or `dynamic`.

- Mixed return statements of the form `return;` and `return exp;` are now
  allowed when `exp` has type `void`.

- A compile time error is emitted for any literal which cannot be exactly
  represented on the target platform. As a result, dart2js and DDC report errors
  if an integer literal cannot be represented exactly in JavaScript ([issue
  33282][]).

- New member conflict rules have been implemented. Most cases of conflicting
  members with the same name are now static errors ([issue 33235][]).

[sdk#29014]: https://github.com/dart-lang/sdk/issues/29014
[issue 30638]: https://github.com/dart-lang/sdk/issues/30638
[issue 31278]: https://github.com/dart-lang/sdk/issues/31278
[issue 31887]: https://github.com/dart-lang/sdk/issues/31887
[issue 32233]: https://github.com/dart-lang/sdk/issues/32233
[issue 32881]: https://github.com/dart-lang/sdk/issues/32881
[issue 33218]: https://github.com/dart-lang/sdk/issues/33218
[issue 33235]: https://github.com/dart-lang/sdk/issues/33235
[issue 33282]: https://github.com/dart-lang/sdk/issues/33282
[issue 33341]: https://github.com/dart-lang/sdk/issues/33341

### Core libraries

- Replaced `UPPER_CASE` constant names with `lowerCamelCase`. For example,
  `HTML_ESCAPE` is now `htmlEscape`.

- The Web libraries were re-generated using Chrome 63 WebIDLs ([details][idl]).

[idl]: https://github.com/dart-lang/sdk/wiki/Chrome-63-Dart-Web-Libraries

#### `dart:async`

- `Stream`:
  - Added `cast` and `castFrom`.
  - Changed `firstWhere`, `lastWhere`, and `singleWhere` to return `Future<T>`
    and added an optional `T orElse()` callback.
- `StreamTransformer`: added `cast` and `castFrom`.
- `StreamTransformerBase`: new class.
- `Timer`: added `tick` property.
- `Zone`
  - changed to be strong-mode clean. This required some breaking API changes.
    See https://goo.gl/y9mW2x for more information.
  - Added `bindBinaryCallbackGuarded`, `bindCallbackGuarded`, and
    `bindUnaryCallbackGuarded`.
  - Renamed `Zone.ROOT` to `Zone.root`.
- Removed the deprecated `defaultValue` parameter on `Stream.firstWhere` and
  `Stream.lastWhere`.
- Changed an internal lazily-allocated reusable "null future" to always belong
  to the root zone. This avoids race conditions where the first access to the
  future determined which zone it would belong to. The zone is only used for
  _scheduling_ the callback of listeners, the listeners themselves will run in
  the correct zone in any case. Issue [#32556](http://dartbug.com/32556).

#### `dart:cli`

- _New_ "provisional" library for CLI-specific features.
- `waitFor`: function that suspends a stack to wait for a `Future` to complete.

#### `dart:collection`

- `MapBase`: added `mapToString`.
- `LinkedHashMap` no longer implements `HashMap`
- `LinkedHashSet` no longer implements `HashSet`.
- Added `of` constructor to `Queue`, `ListQueue`, `DoubleLinkedQueue`,
  `HashSet`, `LinkedHashSet`, `SplayTreeSet`, `Map`, `HashMap`, `LinkedHashMap`,
  `SplayTreeMap`.
- Removed `Maps` class. Extend `MapBase` or mix in `MapMixin` instead to provide
  map method implementations for a class.
- Removed experimental `Document` method `getCSSCanvasContext` and property
  `supportsCssCanvasContext`.
- Removed obsolete `Element` property `xtag` no longer supported in browsers.
- Exposed `ServiceWorker` class.
- Added constructor to `MessageChannel` and `MessagePort` `addEventListener`
  automatically calls `start` method to receive queued messages.

#### `dart:convert`

- `Base64Codec.decode` return type is now `Uint8List`.
- `JsonUnsupportedObjectError`: added `partialResult` property
- `LineSplitter` now implements `StreamTransformer<String, String>` instead of
  `Converter`. It retains `Converter` methods `convert` and
  `startChunkedConversion`.
- `Utf8Decoder` when compiled with dart2js uses the browser's `TextDecoder` in
  some common cases for faster decoding.
- Renamed `ASCII`, `BASE64`, `BASE64URI`, `JSON`, `LATIN1` and `UTF8` to
  `ascii`, `base64`, `base64Uri`, `json`, `latin1` and `utf8`.
- Renamed the `HtmlEscapeMode` constants `UNKNOWN`, `ATTRIBUTE`, `SQ_ATTRIBUTE`
  and `ELEMENT` to `unknown`, `attribute`, `sqAttribute` and `elements`.
- Added `jsonEncode`, `jsonDecode`, `base64Encode`, `base64UrlEncode` and
  `base64Decode` top-level functions.
- Changed return type of `encode` on `AsciiCodec` and `Latin1Codec`, and
  `convert` on `AsciiEncoder`, `Latin1Encoder`, to `Uint8List`.
- Allow `utf8.decoder.fuse(json.decoder)` to ignore leading Unicode BOM.

#### `dart:core`

- `BigInt` class added to support integers greater than 64-bits.
- Deprecated the `proxy` annotation.
- Added `Provisional` class and `provisional` field.
- Added `pragma` annotation.
- `RegExp` added static `escape` function.
- The `Uri` class now correctly handles paths while running on Node.js on
  Windows.
- Core collection changes:
  - `Iterable` added members `cast`, `castFrom`, `followedBy` and `whereType`.
  - `Iterable.singleWhere` added `orElse` parameter.
  - `List` added `+` operator, `first` and `last` setters, and `indexWhere` and
    `lastIndexWhere` methods, and static `copyRange` and `writeIterable`
    methods.
  - `Map` added `fromEntries` constructor.
  - `Map` added `addEntries`, `cast`, `entries`, `map`, `removeWhere`, `update`
    and `updateAll` members.
  - `MapEntry`: new class used by `Map.entries`.
  - _Note_: if a class extends `IterableBase`, `ListBase`, `SetBase` or
    `MapBase` (or uses the corresponding mixins) from `dart:collection`, the new
    members are implemented automatically.
  - Added `of` constructor to `List`, `Set`, `Map`.
- Renamed `double.INFINITY`, `double.NEGATIVE_INFINITY`, `double.NAN`,
  `double.MAX_FINITE` and `double.MIN_POSITIVE` to `double.infinity`,
  `double.negativeInfinity`, `double.nan`, `double.maxFinite` and
  `double.minPositive`.
- Renamed the following constants in `DateTime` to lower case: `MONDAY` through
  `SUNDAY`, `DAYS_PER_WEEK` (as `daysPerWeek`), `JANUARY` through `DECEMBER` and
  `MONTHS_PER_YEAR` (as `monthsPerYear`).
- Renamed the following constants in `Duration` to lower case:
  `MICROSECONDS_PER_MILLISECOND` to `microsecondsPerMillisecond`,
  `MILLISECONDS_PER_SECOND` to `millisecondsPerSecond`, `SECONDS_PER_MINUTE` to
  `secondsPerMinute`, `MINUTES_PER_HOUR` to `minutesPerHour`, `HOURS_PER_DAY` to
  `hoursPerDay`, `MICROSECONDS_PER_SECOND` to `microsecondsPerSecond`,
  `MICROSECONDS_PER_MINUTE` to `microsecondsPerMinute`, `MICROSECONDS_PER_HOUR`
  to `microsecondsPerHour`, `MICROSECONDS_PER_DAY` to `microsecondsPerDay`,
  `MILLISECONDS_PER_MINUTE` to `millisecondsPerMinute`, `MILLISECONDS_PER_HOUR`
  to `millisecondsPerHour`, `MILLISECONDS_PER_DAY` to `millisecondsPerDay`,
  `SECONDS_PER_HOUR` to `secondsPerHour`, `SECONDS_PER_DAY` to `secondsPerDay`,
  `MINUTES_PER_DAY` to `minutesPerDay`, and `ZERO` to `zero`.
- Added `typeArguments` to `Invocation` class.
- Added constructors to invocation class that allows creation of `Invocation`
  objects directly, without going through `noSuchMethod`.
- Added `unaryMinus` and `empty` constant symbols on the `Symbol` class.
- Changed return type of `UriData.dataAsBytes` to `Uint8List`.
- Added `tryParse` static method to `int`, `double`, `num`, `BigInt`, `Uri` and
  `DateTime`.
- Deprecated `onError` parameter on `int.parse`, `double.parse` and `num.parse`.
- Deprecated the `NoSuchMethodError` constructor.
- `int.parse` on the VM no longer accepts unsigned hexadecimal numbers greater
  than or equal to `2**63` when not prefixed by `0x`. (SDK issue
  [32858](https://github.com/dart-lang/sdk/issues/32858))

#### `dart:developer`

- `Flow` class added.
- `Timeline.startSync` and `Timeline.timeSync` now accepts an optional parameter
  `flow` of type `Flow`. The `flow` parameter is used to generate flow timeline
  events that are enclosed by the slice described by
  `Timeline.{start,finish}Sync` and `Timeline.timeSync`.

<!--
Still need entries for all changes to dart:html since 1.x
-->

#### `dart:html`

- Removed deprecated `query` and `queryAll`. Use `querySelector` and
  `querySelectorAll`.

#### `dart:io`

- `HttpStatus` added `UPGRADE_REQUIRED`.
- `IOOverrides` and `HttpOverrides` added to aid in writing tests that wish to
  mock varios `dart:io` objects.
- `Platform.operatingSystemVersion` added that gives a platform-specific String
  describing the version of the operating system.
- `ProcessStartMode.INHERIT_STDIO` added, which allows a child process to
  inherit the parent's stdio handles.
- `RawZLibFilter` added for low-level access to compression and decompression
  routines.
- Unified backends for `SecureSocket`, `SecurityContext`, and `X509Certificate`
  to be consistent across all platforms. All `SecureSocket`, `SecurityContext`,
  and `X509Certificate` properties and methods are now supported on iOS and OSX.
- `SecurityContext.alpnSupported` deprecated as ALPN is now supported on all
  platforms.
- `SecurityContext`: added `withTrustedRoots` named optional parameter
  constructor, which defaults to false.
- Added a `timeout` parameter to `Socket.connect`, `RawSocket.connect`,
  `SecureSocket.connect` and `RawSecureSocket.connect`. If a connection attempt
  takes longer than the duration specified in `timeout`, a `SocketException`
  will be thrown. Note: if the duration specified in `timeout` is greater than
  the OS level timeout, a timeout may occur sooner than specified in `timeout`.
- `Stdin.hasTerminal` added, which is true if stdin is attached to a terminal.
- `WebSocket` added static `userAgent` property.
- `RandomAccessFile.close` returns `Future<void>`
- Added `IOOverrides.socketConnect`.
- Added Dart-styled constants to `ZLibOptions`, `FileMode`, `FileLock`,
  `FileSystemEntityType`, `FileSystemEvent`, `ProcessStartMode`,
  `ProcessSignal`, `InternetAddressType`, `InternetAddress`, `SocketDirection`,
  `SocketOption`, `RawSocketEvent`, and `StdioType`, and deprecated the old
  `SCREAMING_CAPS` constants.
- Added the Dart-styled top-level constants `zlib`, `gzip`, and
  `systemEncoding`, and deprecated the old `SCREAMING_CAPS` top-level constants.
- Removed the top-level `FileMode` constants `READ`, `WRITE`, `APPEND`,
  `WRITE_ONLY`, and `WRITE_ONLY_APPEND`. Please use e.g. `FileMode.read`
  instead.
- Added `X509Certificate.der`, `X509Certificate.pem`, and
  `X509Certificate.sha1`.
- Added `FileSystemEntity.fromRawPath` constructor to allow for the creation of
  `FileSystemEntity` using `Uint8List` buffers.
- Dart-styled constants have been added for `HttpStatus`, `HttpHeaders`,
  `ContentType`, `HttpClient`, `WebSocketStatus`, `CompressionOptions`, and
  `WebSocket`. The `SCREAMING_CAPS` constants are marked deprecated. Note that
  `HttpStatus.CONTINUE` is now `HttpStatus.continue_`, and that e.g.
  `HttpHeaders.FIELD_NAME` is now `HttpHeaders.fieldNameHeader`.
- Deprecated `Platform.packageRoot`, which is only used for `packages/`
  directory resolution which is no longer supported. It will now always return
  null, which is a value that was always possible for it to return previously.
- Adds `HttpClient.connectionTimeout`.
- Adds `{Socket,RawSocket,SecureSocket}.startConnect`. These return a
  `ConnectionTask`, which can be used to cancel an in-flight connection attempt.

#### `dart:isolate`

- Make `Isolate.spawn` take a type parameter representing the argument type of
  the provided function. This allows functions with arguments types other than
  `Object` in strong mode.
- Rename `IMMEDIATE` and `BEFORE_NEXT_EVENT` on `Isolate` to `immediate` and
  `beforeNextEvent`.
- Deprecated `Isolate.packageRoot`, which is only used for `packages/` directory
  resolution which is no longer supported. It will now always return null, which
  is a value that was always possible for it to return previously.
- Deprecated `packageRoot` parameter in `Isolate.spawnUri`, which is was
  previously used only for `packages/` directory resolution. That style of
  resolution is no longer supported in Dart 2.

<!--
Still need entries for all changes to dart:js since 1.x
-->

#### `dart.math`

- Renamed `E`, `LN10`, `LN`, `LOG2E`, `LOG10E`, `PI`, `SQRT1_2` and `SQRT2` to
  `e`, `ln10`, `ln`, `log2e`, `log10e`, `pi`, `sqrt1_2` and `sqrt2`.

#### `dart.mirrors`

- Added `IsolateMirror.loadUri`, which allows dynamically loading additional
  code.
- Marked `MirrorsUsed` as deprecated. The `MirrorsUsed` annotation was only used
  to inform the dart2js compiler about how mirrors were used, but dart2js no
  longer supports the mirrors library altogether.

<!--
Still need entries for all changes to dart:svg since 1.x
-->

#### `dart:typed_data`

- Added `Unmodifiable` view classes over all `List` types.
- Renamed `BYTES_PER_ELEMENT` to `bytesPerElement` on all typed data lists.
- Renamed constants `XXXX` through `WWWW` on `Float32x4` and `Int32x4` to
  lower-case `xxxx` through `wwww`.
- Renamed `Endinanness` to `Endian` and its constants from `BIG_ENDIAN`,
  `LITTLE_ENDIAN` and `HOST_ENDIAN` to `little`, `big` and `host`.

<!--
Still need entries for all changes to dart:web_audio,web_gl,web_sql since 1.x
-->

### Dart VM

- Support for MIPS has been removed.

- Dart `int` is now restricted to 64 bits. On overflow, arithmetic operations
  wrap around, and integer literals larger than 64 bits are not allowed. See
  https://github.com/dart-lang/sdk/blob/main/docs/language/informal/int64.md
  for details.

- The Dart VM no longer attempts to perform `packages/` directory resolution
  (for loading scripts, and in `Isolate.resolveUri`). Users relying on
  `packages/` directories should switch to `.packages` files.

### Dart for the Web

- Expose JavaScript Promise APIs using Dart futures. For example,
  `BackgroundFetchManager.get` is defined as:

  ```dart
    Future<BackgroundFetchRegistration> get(String id)
  ```

  It can be used like:

  ```dart
  BackgroundFetchRegistration result = await fetchMgr.get('abc');
  ```

  The underlying JS Promise-to-Future mechanism will be exposed as a public API
  in the future.

#### Dart Dev Compiler (DDC)

- dartdevc will no longer throw an error from `is` checks that return a
  different result in weak mode (SDK [issue 28988][sdk#28988]). For example:

  ```dart
  main() {
    List l = [];
    // Prints "false", does not throw.
    print(l is List<String>);
  }
  ```

- Failed `as` casts on `Iterable<T>`, `Map<T>`, `Future<T>`, and `Stream<T>` are
  no longer ignored. These failures were ignored to make it easier to migrate
  Dart 1 code to strong mode, but ignoring them is a hole in the type system.
  This closes part of that hole. (We still need to stop ignoring "as" cast
  failures on function types, and implicit cast failures on the above types and
  function types.)

[sdk#28988]: https://github.com/dart-lang/sdk/issues/28988

#### dart2js

- dart2js now compiles programs with Dart 2.0 semantics. Apps are expected to be
  bigger than before, because Dart 2.0 has many more implicit checks (similar to
  the `--checked` flag in Dart 1.0).

  We exposed a `--omit-implicit-checks` flag which removes most of the extra
  implicit checks. Only use this if you have enough test coverage to know that
  the app will work well without the checks. If a check would have failed and it
  is omitted, your app may crash or behave in unexpected ways. This flag is
  similar to `--trust-type-annotations` in Dart 1.0.

- dart2js replaced its front-end with the common front-end (CFE). Thanks to the
  CFE, dart2js errors are more consistent with all other Dart tools.

- dart2js replaced its source-map implementation. There aren't any big
  differences, but more data is emitted for synthetic code generated by the
  compiler.

- `dart:mirrors` support was removed. Frameworks are encouraged to use
  code-generation instead. Conditional imports indicate that mirrors are not
  supported, and any API in the mirrors library will throw at runtime.

- The generated output of dart2js can now be run as a webworker.

- `dart:isolate` support was removed. To launch background tasks, please use
  webworkers instead. APIs for webworkers can be accessed from `dart:html` or
  JS-interop.

- dart2js no longer supports the `--package-root` flag. This flag was deprecated
  in favor of `--packages` long ago.

### Tool Changes

#### Analyzer

- The analyzer will no longer issue a warning when a generic type parameter is
  used as the type in an instance check. For example:

  ```dart
  test<T>() {
    print(3 is T); // No warning
  }
  ```

- New static checking of `@visibleForTesting` elements. Accessing a method,
  function, class, etc. annotated with `@visibleForTesting` from a file _not_ in
  a `test/` directory will result in a new hint ([issue 28273][]).

- Static analysis now respects functions annotated with `@alwaysThrows` ([issue
  31384][]).

- New hints added:

  - `NULL_AWARE_BEFORE_OPERATOR` when an operator is used after a null-aware
    access. For example:

    ```dart
    x?.a - ''; // HINT
    ```

  - `NULL_AWARE_IN_LOGICAL_OPERATOR` when an expression with null-aware access
    is used as a condition in logical operators. For example:

    ```dart
    x.a || x?.b; // HINT
    ```

- The command line analyzer (dartanalyzer) and the analysis server no longer
  treat directories named `packages` specially. Previously they had ignored
  these directories - and their contents - from the point of view of analysis.
  Now they'll be treated just as regular directories. This special-casing of
  `packages` directories was to support using symlinks for package: resolution;
  that functionality is now handled by `.packages` files.

- New static checking of duplicate shown or hidden names in an export directive
  ([issue 33182][]).

- The analysis server will now only analyze code in Dart 2 mode ('strong mode').
  It will emit warnings for analysis options files that have
  `strong-mode: false` set (and will emit a hint for `strong-mode: true`, which
  is no longer necessary).

- The dartanalyzer `--strong` flag is now deprecated and ignored. The
  command-line analyzer now only analyzes code in strong mode.

[issue 28273]: https://github.com/dart-lang/sdk/issues/28273
[issue 31384]: https://github.com/dart-lang/sdk/issues/31384
[issue 33182]: https://github.com/dart-lang/sdk/issues/33182

#### dartfmt

- Support `assert()` in const constructor initializer lists.

- Better formatting for multi-line strings in argument lists.

- Force splitting an empty block as the then body of an if with an else.

- Support metadata annotations on enum cases.

- Add `--fix` to remove unneeded `new` and `const` keywords, and change `:` to
  `=` before named parameter default values.

- Change formatting rules around static methods to uniformly format code with
  and without `new` and `const`.

- Format expressions inside string interpolation.

#### Pub

- Pub has a brand new version solver! It supports all the same features as the
  old version solver, but it's much less likely to stall out on difficult
  package graphs, and it's much clearer about why a solution can't be found when
  version solving fails.

- Remove support for transformers, `pub build`, and `pub serve`. Use the [new
  build system][transformers] instead.

- There is now a default SDK constraint of `<2.0.0` for any package with no
  existing upper bound. This allows us to move more safely to 2.0.0. All new
  packages published on pub will now require an upper bound SDK constraint so
  future major releases of Dart don't destabilize the package ecosystem.

  All SDK constraint exclusive upper bounds are now treated as though they allow
  pre-release versions of that upper bound. For example, the SDK constraint
  `>=1.8.0 <2.0.0` now allows pre-release SDK versions such as `2.0.0-beta.3.0`.
  This allows early adopters to try out packages that don't explicitly declare
  support for the new version yet. You can disable this functionality by setting
  the `PUB_ALLOW_PRERELEASE_SDK` environment variable to `false`.

- Allow depending on a package in a subdirectory of a Git repository. Git
  dependencies may now include a `path` parameter, indicating that the package
  exists in a subdirectory of the Git repository. For example:

  ```yaml
  dependencies:
    foobar:
      git:
        url: git://github.com/dart-lang/multi_package_repo
        path: pkg/foobar
  ```

- Added an `--executables` option to `pub deps` command. This will list all
  available executables that can be run with `pub run`.

- The Flutter `sdk` source will now look for packages in
  `flutter/bin/cache/pkg/` as well as `flutter/packages/`. In particular, this
  means that packages can depend on the `sky_engine` package from the `sdk`
  source ([issue 1775][pub#1775]).

- Pub now caches compiled packages and snapshots in the `.dart_tool/pub`
  directory, rather than the `.pub` directory ([issue 1795][pub#1795]).

- Other bug fixes and improvements.

[issue 30246]: https://github.com/dart-lang/sdk/issues/30246
[pub#1679]: https://github.com/dart-lang/pub/issues/1679
[pub#1684]: https://github.com/dart-lang/pub/issues/1684
[pub#1775]: https://github.com/dart-lang/pub/issues/1775
[pub#1795]: https://github.com/dart-lang/pub/issues/1795
[pub#1823]: https://github.com/dart-lang/pub/issues/1823

## 1.24.3 - 2017-12-14

- Fix for constructing a new SecurityContext that contains the built-in
  certificate authority roots
  ([issue 24693](https://github.com/dart-lang/sdk/issues/24693)).

### Core library changes

- `dart:io`
  - Unified backends for `SecureSocket`, `SecurityContext`, and
    `X509Certificate` to be consistent across all platforms. All `SecureSocket`,
    `SecurityContext`, and `X509Certificate` properties and methods are now
    supported on iOS and OSX.

## 1.24.2 - 2017-06-22

- Fixes for debugging in Dartium.
  - Fix DevConsole crash with JS
    ([issue 29873](https://github.com/dart-lang/sdk/issues/29873)).
  - Fix debugging in WebStorm, NULL returned for JS objects
    ([issue 29854](https://github.com/dart-lang/sdk/issues/29854)).

## 1.24.1 - 2017-06-14

- Bug fixes for dartdevc support in `pub serve`.
  - Fixed module config invalidation logic so modules are properly recalculated
    when package layout changes.
  - Fixed exception when handling require.js errors that aren't script load
    errors.
  - Fixed an issue where requesting the bootstrap.js file before the dart.js
    file would result in a 404.
  - Fixed a Safari issue during bootstrapping (note that Safari is still not
    officially supported but does work for trivial examples).
- Fix for a Dartium issue where there was no sound in checked mode
  ([issue 29810](https://github.com/dart-lang/sdk/issues/29810)).

## 1.24.0 - 2017-06-12

### Language

- During a dynamic type check, `void` is not required to be `null` anymore. In
  practice, this makes overriding `void` functions with non-`void` functions
  safer.

- During static analysis, a function or setter declared using `=>` with return
  type `void` now allows the returned expression to have any type. For example,
  assuming the declaration `int x;`, it is now type correct to have
  `void f() => ++x;`.

- A new function-type syntax has been added to the language. **Warning**: _In
  Dart 1.24, this feature is incomplete, and not stable in the Analyzer._

  Intuitively, the type of a function can be constructed by textually replacing
  the function's name with `Function` in its declaration. For instance, the type
  of `void foo() {}` would be `void Function()`. The new syntax may be used
  wherever a type can be written. It is thus now possible to declare fields
  containing functions without needing to write typedefs: `void Function() x;`.
  The new function type has one restriction: it may not contain the old-style
  function-type syntax for its parameters. The following is thus illegal:
  `void Function(int f())`. `typedefs` have been updated to support this new
  syntax.

  Examples:

  ```dart
  typedef F = void Function();  // F is the name for a `void` callback.
  int Function(int) f;  // A field `f` that contains an int->int function.

  class A<T> {
    // The parameter `callback` is a function that takes a `T` and returns
    // `void`.
    void forEach(void Function(T) callback);
  }

  // The new function type supports generic arguments.
  typedef Invoker = T Function<T>(T Function() callback);
  ```

### Core library changes

- `dart:async`, `dart:core`, `dart:io`

  - Adding to a closed sink, including `IOSink`, is no longer not allowed. In
    1.24, violations are only reported (on stdout or stderr), but a future
    version of the Dart SDK will change this to throwing a `StateError`.

- `dart:convert`

  - **BREAKING** Removed the deprecated `ChunkedConverter` class.
  - JSON maps are now typed as `Map<String, dynamic>` instead of
    `Map<dynamic, dynamic>`. A JSON-map is not a `HashMap` or `LinkedHashMap`
    anymore (but just a `Map`).

- `dart:io`

  - Added `Platform.localeName`, needed for accessing the locale on platforms
    that don't store it in an environment variable.
  - Added `ProcessInfo.currentRss` and `ProcessInfo.maxRss` for inspecting the
    Dart VM process current and peak resident set size.
  - Added `RawSynchronousSocket`, a basic synchronous socket implementation.

- `dart:` web APIs have been updated to align with Chrome v50. This change
  includes **a large number of changes**, many of which are breaking. In some
  cases, new class names may conflict with names that exist in existing code.

- `dart:html`

  - **REMOVED** classes: `Bluetooth`, `BluetoothDevice`,
    `BluetoothGattCharacteristic`, `BluetoothGattRemoteServer`,
    `BluetoothGattService`, `BluetoothUuid`, `CrossOriginConnectEvent`,
    `DefaultSessionStartEvent`, `DomSettableTokenList`, `MediaKeyError`,
    `PeriodicSyncEvent`, `PluginPlaceholderElement`, `ReadableStream`,
    `StashedMessagePort`, `SyncRegistration`

  - **REMOVED** members:

    - `texImage2DCanvas` was removed from `RenderingContext`.
    - `endClip` and `startClip` were removed from `Animation`.
    - `after` and `before` were removed from `CharacterData`, `ChildNode` and
      `Element`.
    - `keyLocation` was removed from `KeyboardEvent`. Use `location` instead.
    - `generateKeyRequest`, `keyAddedEvent`, `keyErrorEvent`, `keyMessageEvent`,
      `mediaGroup`, `needKeyEvent`, `onKeyAdded`, `onKeyError`, `onKeyMessage`,
      and `onNeedKey` were removed from `MediaElement`.
    - `getStorageUpdates` was removed from `Navigator`
    - `status` was removed from `PermissionStatus`
    - `getAvailability` was removed from `PreElement`

  - Other behavior changes:
    - URLs returned in CSS or html are formatted with quoted string. Like
      `url("http://google.com")` instead of `url(http://google.com)`.
    - Event timestamp property type changed from `int` to `num`.
    - Chrome introduced slight layout changes of UI objects. In addition many
      height/width dimensions are returned in subpixel values (`num` instead of
      whole numbers).
    - `setRangeText` with a `selectionMode` value of 'invalid' is no longer
      valid. Only "select", "start", "end", "preserve" are allowed.

- `dart:svg`

  - A large number of additions and removals. Review your use of `dart:svg`
    carefully.

- `dart:web_audio`

  - new method on `AudioContext` - `createIirFilter` returns a new class
    `IirFilterNode`.

- `dart:web_gl`

  - new classes: `CompressedTextureAstc`, `ExtColorBufferFloat`,
    `ExtDisjointTimerQuery`, and `TimerQueryExt`.

  - `ExtFragDepth` added: `readPixels2` and `texImage2D2`.

#### Strong Mode

- Removed ad hoc `Future.then` inference in favor of using `FutureOr`. Prior to
  adding `FutureOr` to the language, the analyzer implemented an ad hoc type
  inference for `Future.then` (and overrides) treating it as if the onValue
  callback was typed to return `FutureOr` for the purposes of inference. This ad
  hoc inference has been removed now that `FutureOr` has been added.

  Packages that implement `Future` must either type the `onValue` parameter to
  `.then` as returning `FutureOr<T>`, or else must leave the type of the
  parameter entirely to allow inference to fill in the type.

- During static analysis, a function or setter declared using `=>` with return
  type `void` now allows the returned expression to have any type.

### Tool Changes

- Dartium

  Dartium is now based on Chrome v50. See _Core library changes_ above for
  details on the changed APIs.

- Pub

  - `pub build` and `pub serve`

    - Added support for the Dart Development Compiler.

      Unlike dart2js, this new compiler is modular, which allows pub to do
      incremental re-builds for `pub serve`, and potentially `pub build` in the
      future.

      In practice what that means is you can edit your Dart files, refresh in
      Chrome (or other supported browsers), and see your edits almost
      immediately. This is because pub is only recompiling your package, not all
      packages that you depend on.

      There is one caveat with the new compiler, which is that your package and
      your dependencies must all be strong mode clean. If you are getting an
      error compiling one of your dependencies, you will need to file bugs or
      send pull requests to get them strong mode clean.

      There are two ways of opting into the new compiler:

      - Use the new `--web-compiler` flag, which supports `dartdevc`, `dart2js`
        or `none` as options. This is the easiest way to try things out without
        changing the default.

      - Add config to your pubspec. There is a new `web` key which supports a
        single key called `compiler`. This is a map from mode names to compiler
        to use. For example, to default to dartdevc in debug mode you can add
        the following to your pubspec:

        ```yaml
        web:
          compiler:
            debug: dartdevc
        ```

      You can also use the new compiler to run your tests in Chrome much more
      quickly than you can with dart2js. In order to do that, run
      `pub serve test --web-compiler=dartdevc`, and then run
      `pub run test -p chrome --pub-serve=8080`.

    - The `--no-dart2js` flag has been deprecated in favor of
      `--web-compiler=none`.

    - `pub build` will use a failing exit code if there are errors in any
      transformer.

  - `pub publish`

    - Added support for the UNLICENSE file.

    - Packages that depend on the Flutter SDK may be published.

  - `pub get` and `pub upgrade`

    - Don't dump a stack trace when a network error occurs while fetching
      packages.

- dartfmt
  - Preserve type parameters in new generic function typedef syntax.
  - Add self-test validation to ensure formatter bugs do not cause user code to
    be lost.

### Infrastructure changes

- As of this release, we'll show a warning when using the MIPS architecture.
  Unless we learn about any critical use of Dart on MIPS in the meantime, we're
  planning to deprecate support for MIPS starting with the next stable release.

## 1.23.0 - 2017-04-21

#### Strong Mode

- Breaking change - it is now a strong mode error if a mixin causes a name
  conflict between two private members (field/getter/setter/method) from a
  different library. (SDK issue
  [28809](https://github.com/dart-lang/sdk/issues/28809)).

lib1.dart:

```dart
class A {
  int _x;
}

class B {
  int _x;
}
```

lib2.dart:

```dart
import 'lib1.dart';

class C extends A with B {}
```

```
    error • The private name _x, defined by B, conflicts with the same name defined by A at tmp/lib2.dart:3:24 • private_collision_in_mixin_application
```

- Breaking change - strong mode will prefer the expected type to infer generic
  types, functions, and methods (SDK issue
  [27586](https://github.com/dart-lang/sdk/issues/27586)).

  ```dart
  main() {
    List<Object> foo = /*infers: <Object>*/['hello', 'world'];
    var bar = /*infers: <String>*/['hello', 'world'];
  }
  ```

- Strong mode inference error messages are improved (SDK issue
  [29108](https://github.com/dart-lang/sdk/issues/29108)).

  ```dart
  import 'dart:math';
  test(Iterable/* fix is to add <num> here */ values) {
    num n = values.fold(values.first as num, max);
  }
  ```

  Now produces the error on the generic function "max":

  ```
  Couldn't infer type parameter 'T'.

  Tried to infer 'dynamic' for 'T' which doesn't work:
    Function type declared as '<T extends num>(T, T) → T'
                  used where  '(num, dynamic) → num' is required.

  Consider passing explicit type argument(s) to the generic.
  ```

- Strong mode supports overriding fields, `@virtual` is no longer required (SDK
  issue [28120](https://github.com/dart-lang/sdk/issues/28120)).

  ```dart
  class C {
    int x = 42;
  }
  class D extends C {
    get x {
      print("x got called");
      return super.x;
    }
  }
  main() {
    print(new D().x);
  }
  ```

- Strong mode down cast composite warnings are no longer issued by default. (SDK
  issue [28588](https://github.com/dart-lang/sdk/issues/28588)).

```dart
void test() {
  List untyped = [];
  List<int> typed = untyped; // No down cast composite warning
}
```

To opt back into the warnings, add the following to the
[.analysis_options](https://dart.dev/guides/language/analysis-options)
file for your project.

```
analyzer:
  errors:
    strong_mode_down_cast_composite: warning
```

### Core library changes

- `dart:core`
  - Added `Uri.isScheme` function to check the scheme of a URI. Example:
    `uri.isScheme("http")`. Ignores case when comparing.
  - Make `UriData.parse` validate its input better. If the data is base-64
    encoded, the data is normalized wrt. alphabet and padding, and it contains
    invalid base-64 data, parsing fails. Also normalizes non-base-64 data.
- `dart:io`
  - Added functions `File.lastAccessed`, `File.lastAccessedSync`,
    `File.setLastModified`, `File.setLastModifiedSync`, `File.setLastAccessed`,
    and `File.setLastAccessedSync`.
  - Added `{Stdin,Stdout}.supportsAnsiEscapes`.

### Dart VM

- Calls to `print()` and `Stdout.write*()` now correctly print unicode
  characters to the console on Windows. Calls to `Stdout.add*()` behave as
  before.

### Tool changes

- Analysis

  - `dartanalyzer` now follows the same rules as the analysis server to find an
    analysis options file, stopping when an analysis options file is found:
    - Search up the directory hierarchy looking for an analysis options file.
    - If analyzing a project referencing the [Flutter](https://flutter.io/)
      package, then use the
      [default Flutter analysis options](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/analysis_options_user.yaml)
      found in `package:flutter`.
    - If in a Bazel workspace, then use the analysis options in
      `package:dart.analysis_options/default.yaml` if it exists.
    - Use the default analysis options rules.
  - In addition, specific to `dartanalyzer`:
    - an analysis options file can be specified on the command line via
      `--options` and that file will be used instead of searching for an
      analysis options file.
    - any analysis option specified on the command line (e.g. `--strong` or
      `--no-strong`) takes precedence over any corresponding value specified in
      the analysis options file.

- Dartium, dart2js, and DDC

  - Imports to `dart:io` are allowed, but the imported library is not supported
    and will likely fail on most APIs at runtime. This change was made as a
    stopgap measure to make it easier to write libraries that share code between
    platforms (like package `http`). This might change again when configuration
    specific imports are supported.

- Pub

  - Now sends telemetry data to `pub.dartlang.org` to allow better understanding
    of why a particular package is being accessed.
  - `pub publish`
    - Warns if a package imports a package that's not a dependency from within
      `lib/` or `bin/`, or a package that's not a dev dependency from within
      `benchmark/`, `example/`, `test/` or `tool/`.
    - No longer produces "UID too large" errors on OS X. All packages are now
      uploaded with the user and group names set to "pub".
    - No longer fails with a stack overflow when uploading a package that uses
      Git submodules.
  - `pub get` and `pub upgrade`
    - Produce more informative error messages if they're run directly in a
      package that uses Flutter.
    - Properly unlock SDK and path dependencies if they have a new version
      that's also valid according to the user's pubspec.

- dartfmt
  - Support new generic function typedef syntax.
  - Make the precedence of cascades more visible.
  - Fix a couple of places where spurious newlines were inserted.
  - Correctly report unchanged formatting when reading from stdin.
  - Ensure space between `-` and `--`. Code that does this is pathological, but
    it technically meant dartfmt could change the semantics of the code.
  - Preserve a blank line between enum cases.
  - Other small formatting tweaks.

## 1.22.1 - 2017-02-22

Patch release, resolves two issues:

- Dart VM crash: [Issue 28072](https://github.com/dart-lang/sdk/issues/28757)

- Dart VM bug combining types, await, and deferred loading:
  [Issue 28678](https://github.com/dart-lang/sdk/issues/28678)

## 1.22.0 - 2017-02-14

### Language

- Breaking change:
  ['Generalized tear-offs'](https://github.com/gbracha/generalizedTearOffs/blob/master/proposal.md)
  are no longer supported, and will cause errors. We updated the language spec
  and added warnings in 1.21, and are now taking the last step to fully
  de-support them. They were previously only supported in the VM, and there are
  almost no known uses of them in the wild.

- The `assert()` statement has been expanded to support an optional second
  `message` argument (SDK issue
  [27342](https://github.com/dart-lang/sdk/issues/27342)).

  The message is displayed if the assert fails. It can be any object, and it is
  accessible as `AssertionError.message`. It can be used to provide more user
  friendly exception outputs. As an example, the following assert:

  ```dart
  assert(configFile != null, "Tool config missing. Please see https://goo.gl/k8iAi for details.");
  ```

  would produce the following exception output:

  ```
  Unhandled exception:
  'file:///Users/mit/tmp/tool/bin/main.dart': Failed assertion: line 9 pos 10:
  'configFile != null': Tool config missing. Please see https://goo.gl/k8iAi for details.
  #0      _AssertionError._doThrowNew (dart:core-patch/errors_patch.dart:33)
  #1      _AssertionError._throwNew (dart:core-patch/errors_patch.dart:29)
  #2      main (file:///Users/mit/tmp/tool/bin/main.dart:9:10)
  ```

- The `Null` type has been moved to the bottom of the type hierarchy. As such,
  it is considered a subtype of every other type. The `null` _literal_ was
  always treated as a bottom type. Now the named class `Null` is too:

  ```dart
  const empty = <Null>[];

  String concatenate(List<String> parts) => parts.join();
  int sum(List<int> numbers) => numbers.fold(0, (sum, n) => sum + n);

  concatenate(empty); // OK.
  sum(empty); // OK.
  ```

- Introduce `covariant` modifier on parameters. It indicates that the parameter
  (and the corresponding parameter in any method that overrides it) has looser
  override rules. In strong mode, these require a runtime type check to maintain
  soundness, but enable an architectural pattern that is useful in some code.

  It lets you specialize a family of classes together, like so:

  ```dart
  abstract class Predator {
    void chaseAndEat(covariant Prey p);
  }

  abstract class Prey {}

  class Mouse extends Prey {}

  class Seal extends Prey {}

  class Cat extends Predator {
    void chaseAndEat(Mouse m) => ...
  }

  class Orca extends Predator {
    void chaseAndEat(Seal s) => ...
  }
  ```

  This isn't statically safe, because you could do:

  ```dart
  Predator predator = new Cat(); // Upcast.
  predator.chaseAndEat(new Seal()); // Cats can't eat seals!
  ```

  To preserve soundness in strong mode, in the body of a method that uses a
  covariant override (here, `Cat.chaseAndEat()`), the compiler automatically
  inserts a check that the parameter is of the expected type. So the compiler
  gives you something like:

  ```dart
  class Cat extends Predator {
    void chaseAndEat(o) {
      var m = o as Mouse;
      ...
    }
  }
  ```

  Spec mode allows this unsound behavior on all parameters, even though users
  rarely rely on it. Strong mode disallowed it initially. Now, strong mode lets
  you opt into this behavior in the places where you do want it by using this
  modifier. Outside of strong mode, the modifier is ignored.

- Change instantiate-to-bounds rules for generic type parameters when running in
  strong mode. If you leave off the type parameters from a generic type, we need
  to decide what to fill them in with. Dart 1.0 says just use `dynamic`, but
  that isn't sound:

  ```dart
  class Abser<T extends num> {
     void absThis(T n) { n.abs(); }
  }

  var a = new Abser(); // Abser<dynamic>.
  a.absThis("not a num");
  ```

  We want the body of `absThis()` to be able to safely assume `n` is at least a
  `num` -- that's why there's a constraint on T, after all. Implicitly using
  `dynamic` as the type parameter in this example breaks that.

  Instead, strong mode uses the bound. In the above example, it fills it in with
  `num`, and then the second line where a string is passed becomes a static
  error.

  However, there are some cases where it is hard to figure out what that default
  bound should be:

  ```dart
  class RuhRoh<T extends Comparable<T>> {}
  ```

  Strong mode's initial behavior sometimes produced surprising, unintended
  results. For 1.22, we take a simpler approach and then report an error if a
  good default type argument can't be found.

### Core libraries

- Define `FutureOr<T>` for code that works with either a future or an immediate
  value of some type. For example, say you do a lot of text manipulation, and
  you want a handy function to chain a bunch of them:

  ```dart
  typedef String StringSwizzler(String input);

  String swizzle(String input, List<StringSwizzler> swizzlers) {
    var result = input;
    for (var swizzler in swizzlers) {
      result = swizzler(result);
    }

    return result;
  }
  ```

  This works fine:

  ```dart
  main() {
    var result = swizzle("input", [
      (s) => s.toUpperCase(),
      (s) => () => s * 2)
    ]);
    print(result); // "INPUTINPUT".
  }
  ```

  Later, you realize you'd also like to support swizzlers that are asynchronous
  (maybe they look up synonyms for words online). You could make your API
  strictly asynchronous, but then users of simple synchronous swizzlers have to
  manually wrap the return value in a `Future.value()`. Ideally, your
  `swizzle()` function would be "polymorphic over asynchrony". It would allow
  both synchronous and asynchronous swizzlers. Because `await` accepts immediate
  values, it is easy to implement this dynamically:

  ```dart
  Future<String> swizzle(String input, List<StringSwizzler> swizzlers) async {
    var result = input;
    for (var swizzler in swizzlers) {
      result = await swizzler(result);
    }

    return result;
  }

  main() async {
    var result = swizzle("input", [
      (s) => s.toUpperCase(),
      (s) => new Future.delayed(new Duration(milliseconds: 40), () => s * 2)
    ]);
    print(await result);
  }
  ```

  What should the declared return type on StringSwizzler be? In the past, you
  had to use `dynamic` or `Object`, but that doesn't tell the user much. Now,
  you can do:

  ```dart
  typedef FutureOr<String> StringSwizzler(String input);
  ```

  Like the name implies, `FutureOr<String>` is a union type. It can be a
  `String` or a `Future<String>`, but not anything else. In this case, that's
  not super useful beyond just stating a more precise type for readers of the
  code. It does give you a little better error checking in code that uses the
  result of that.

  `FutureOr<T>` becomes really important in _generic_ methods like
  `Future.then()`. In those cases, having the type system understand this
  magical union type helps type inference figure out the type argument of
  `then()` based on the closure you pass it.

  Previously, strong mode had hard-coded rules for handling `Future.then()`
  specifically. `FutureOr<T>` exposes that functionality so third-party APIs can
  take advantage of it too.

### Tool changes

- Dart2Js

  - Remove support for (long-time deprecated) mixin typedefs.

- Pub

  - Avoid using a barback asset server for executables unless they actually use
    transformers. This makes precompilation substantially faster, produces
    better error messages when precompilation fails, and allows
    globally-activated executables to consistently use the
    `Isolate.resolvePackageUri()` API.

  - On Linux systems, always ignore packages' original file owners and
    permissions when extracting those packages. This was already the default
    under most circumstances.

  - Properly close the standard input stream of child processes started using
    `pub run`.

  - Handle parse errors from the package cache more gracefully. A package whose
    pubspec can't be parsed will now be ignored by `pub get --offline` and
    deleted by `pub cache repair`.

  - Make `pub run` run executables in spawned isolates. This lets them handle
    signals and use standard IO reliably.

  - Fix source-maps produced by dart2js when running in `pub serve`: URL
    references to assets from packages match the location where `pub serve`
    serves them (`packages/package_name/` instead of
    `../packages/package_name/`).

### Infrastructure changes

- The SDK now uses GN rather than gyp to generate its build files, which will
  now be exclusively ninja flavored. Documentation can be found on our
  [wiki](https://github.com/dart-lang/sdk/wiki/Building-with-GN). Also see the
  help message of `tools/gn.py`. This change is in response to the deprecation
  of gyp. Build file generation with gyp will continue to be available in this
  release by setting the environment variable `DART_USE_GYP` before running
  `gclient sync` or `gclient runhooks`, but this will be removed in a future
  release.

## 1.21.1 - 2017-01-13

Patch release, resolves one issue:

- Dart VM: Snapshots of generic functions fail.
  [Issue 28072](https://github.com/dart-lang/sdk/issues/28072)

## 1.21.0 - 2016-12-07

### Language

- Support generic method syntax. Type arguments are not available at runtime.
  For details, check the
  [informal specification](https://gist.github.com/eernstg/4353d7b4f669745bed3a5423e04a453c).
- Support access to initializing formals, e.g., the use of `x` to initialize `y`
  in `class C { var x, y; C(this.x): y = x; }`. Please check the
  [informal specification](https://gist.github.com/eernstg/cff159be9e34d5ea295d8c24b1a3e594)
  for details.
- Don't warn about switch case fallthrough if the case ends in a `rethrow`
  statement. (SDK issue [27650](https://github.com/dart-lang/sdk/issues/27650))
- Also don't warn if the entire switch case is wrapped in braces - as long as
  the block ends with a `break`, `continue`, `rethrow`, `return` or `throw`.
- Allow `=` as well as `:` as separator for named parameter default values.

  ```dart
  enableFlags({bool hidden: false}) { … }
  ```

  can now be replaced by

  ```dart
  enableFlags({bool hidden = false}) { … }
  ```

  (SDK issue [27559](https://github.com/dart-lang/sdk/issues/27559))

### Core library changes

- `dart:core`: `Set.difference` now takes a `Set<Object>` as argument. (SDK
  issue [27573](https://github.com/dart-lang/sdk/issues/27573))

- `dart:developer`

  - Added `Service` class.
    - Allows inspecting and controlling the VM service protocol HTTP server.
    - Provides an API to access the ID of an `Isolate`.

### Tool changes

- Dart Dev Compiler

  - Support calls to `loadLibrary()` on deferred libraries. Deferred libraries
    are still loaded eagerly. (SDK issue
    [27343](https://github.com/dart-lang/sdk/issues/27343))

## 1.20.1 - 2016-10-13

Patch release, resolves one issue:

- Dartium: Fixes a bug that caused crashes. No issue filed.

### Strong Mode

- It is no longer a warning when casting from dynamic to a composite type (SDK
  issue [27766](https://github.com/dart-lang/sdk/issues/27766)).

  ```dart
  main() {
    dynamic obj = <int>[1, 2, 3];
    // This is now allowed without a warning.
    List<int> list = obj;
  }
  ```

## 1.20.0 - 2016-10-11

### Dart VM

- We have improved the way that the VM locates the native code library for a
  native extension (e.g. `dart-ext:` import). We have updated this
  [article on native extensions](https://dart.dev/server/c-interop-native-extensions)
  to reflect the VM's improved behavior.

- Linux builds of the VM will now use the `tcmalloc` library for memory
  allocation. This has the advantages of better debugging and profiling support
  and faster small allocations, with the cost of slightly larger initial memory
  footprint, and slightly slower large allocations.

- We have improved the way the VM searches for trusted root certificates for
  secure socket connections on Linux. First, the VM will look for trusted root
  certificates in standard locations on the file system
  (`/etc/pki/tls/certs/ca-bundle.crt` followed by `/etc/ssl/certs`), and only if
  these do not exist will it fall back on the builtin trusted root certificates.
  This behavior can be overridden on Linux with the new flags
  `--root-certs-file` and `--root-certs-cache`. The former is the path to a file
  containing the trusted root certificates, and the latter is the path to a
  directory containing root certificate files hashed using `c_rehash`.

- The VM now throws a catchable `Error` when method compilation fails. This
  allows easier debugging of syntax errors, especially when testing. (SDK issue
  [23684](https://github.com/dart-lang/sdk/issues/23684))

### Core library changes

- `dart:core`: Remove deprecated `Resource` class. Use the class in
  `package:resource` instead.
- `dart:async`
  - `Future.wait` now catches synchronous errors and returns them in the
    returned Future. (SDK issue
    [27249](https://github.com/dart-lang/sdk/issues/27249))
  - More aggressively returns a `Future` on `Stream.cancel` operations.
    Discourages to return `null` from `cancel`. (SDK issue
    [26777](https://github.com/dart-lang/sdk/issues/26777))
  - Fixes a few bugs where the cancel future wasn't passed through
    transformations.
- `dart:io`
  - Added `WebSocket.addUtf8Text` to allow sending a pre-encoded text message
    without a round-trip UTF-8 conversion. (SDK issue
    [27129](https://github.com/dart-lang/sdk/issues/27129))

### Strong Mode

- Breaking change - it is an error if a generic type parameter cannot be
  inferred (SDK issue [26992](https://github.com/dart-lang/sdk/issues/26992)).

  ```dart
  class Cup<T> {
    Cup(T t);
  }
  main() {
    // Error because:
    // - if we choose Cup<num> it is not assignable to `cOfInt`,
    // - if we choose Cup<int> then `n` is not assignable to int.
    num n;
    C<int> cOfInt = new C(n);
  }
  ```

- New feature - use `@checked` to override a method and tighten a parameter type
  (SDK issue [25578](https://github.com/dart-lang/sdk/issues/25578)).

  ```dart
  import 'package:meta/meta.dart' show checked;
  class View {
    addChild(View v) {}
  }
  class MyView extends View {
    // this override is legal, it will check at runtime if we actually
    // got a MyView.
    addChild(@checked MyView v) {}
  }
  main() {
    dynamic mv = new MyView();
    mv.addChild(new View()); // runtime error
  }
  ```

- New feature - use `@virtual` to allow field overrides in strong mode (SDK
  issue [27384](https://github.com/dart-lang/sdk/issues/27384)).

  ```dart
  import 'package:meta/meta.dart' show virtual;
  class Base {
    @virtual int x;
  }
  class Derived extends Base {
    int x;

    // Expose the hidden storage slot:
    int get superX => super.x;
    set superX(int v) { super.x = v; }
  }
  ```

- Breaking change - infer list and map literals from the context type as well as
  their values, consistent with generic methods and instance creation (SDK issue
  [27151](https://github.com/dart-lang/sdk/issues/27151)).

  ```dart
  import 'dart:async';
  main() async {
    var b = new Future<B>.value(new B());
    var c = new Future<C>.value(new C());
    var/*infer List<Future<A>>*/ list = [b, c];
    var/*infer List<A>*/ result = await Future.wait(list);
  }
  class A {}
  class B extends A {}
  class C extends A {}
  ```

### Tool changes

- `dartfmt` - upgraded to v0.2.10

  - Don't crash on annotations before parameters with trailing commas.
  - Always split enum declarations if they end in a trailing comma.
  - Add `--set-exit-if-changed` to set the exit code on a change.

- Pub
  - Pub no longer generates a `packages/` directory by default. Instead, it
    generates a `.packages` file, called a package spec. To generate a
    `packages/` directory in addition to the package spec, use the
    `--packages-dir` flag with `pub get`, `pub upgrade`, and `pub downgrade`.
    See the
    [Good-bye symlinks](http://news.dartlang.org/2016/10/good-bye-symlinks.html)
    article for details.

## 1.19.1 - 2016-09-08

Patch release, resolves one issue:

- Dartdoc: Fixes a bug that prevented generation of docs. (Dartdoc issue
  [1233](https://github.com/dart-lang/dartdoc/issues/1233))

## 1.19.0 - 2016-08-26

### Language changes

- The language now allows a trailing comma after the last argument of a call and
  the last parameter of a function declaration. This can make long argument or
  parameter lists easier to maintain, as commas can be left as-is when
  reordering lines. For details, see SDK issue
  [26644](https://github.com/dart-lang/sdk/issues/26644).

### Tool Changes

- `dartfmt` - upgraded to v0.2.9+1

  - Support trailing commas in argument and parameter lists.
  - Gracefully handle read-only files.
  - About a dozen other bug fixes.

- Pub

  - Added a `--no-packages-dir` flag to `pub get`, `pub upgrade`, and
    `pub downgrade`. When this flag is passed, pub will not generate a
    `packages/` directory, and will remove that directory and any symlinks to it
    if they exist. Note that this replaces the unsupported
    `--no-package-symlinks` flag.

  - Added the ability for packages to declare a constraint on the [Flutter][]
    SDK:

    ```yaml
    environment:
      flutter: ^0.1.2
      sdk: >=1.19.0 <2.0.0
    ```

    A Flutter constraint will only be satisfiable when pub is running in the
    context of the `flutter` executable, and when the Flutter SDK version
    matches the constraint.

  - Added `sdk` as a new package source that fetches packages from a hard-coded
    SDK. Currently only the `flutter` SDK is supported:

    ```yaml
    dependencies:
      flutter_driver:
        sdk: flutter
        version: ^0.0.1
    ```

    A Flutter `sdk` dependency will only be satisfiable when pub is running in
    the context of the `flutter` executable, and when the Flutter SDK contains a
    package with the given name whose version matches the constraint.

  - `tar` files on Linux are now created with `0` as the user and group IDs.
    This fixes a crash when publishing packages while using Active Directory.

  - Fixed a bug where packages from a hosted HTTP URL were considered the same
    as packages from an otherwise-identical HTTPS URL.

  - Fixed timer formatting for timers that lasted longer than a minute.

  - Eliminate some false negatives when determining whether global executables
    are on the user's executable path.

- `dart2js`
  - `dart2dart` (aka `dart2js --output-type=dart`) has been removed (this was
    deprecated in Dart 1.11).

[flutter]: https://flutter.io/

### Dart VM

- The dependency on BoringSSL has been rolled forward. Going forward, builds of
  the Dart VM including secure sockets will require a compiler with C++11
  support. For details, see the
  [Building wiki page](https://github.com/dart-lang/sdk/wiki/Building).

### Strong Mode

- New feature - an option to disable implicit casts (SDK issue
  [26583](https://github.com/dart-lang/sdk/issues/26583)), see the
  [documentation](https://github.com/dart-lang/dev_compiler/blob/master/doc/STATIC_SAFETY.md#disable-implicit-casts)
  for usage instructions and examples.

- New feature - an option to disable implicit dynamic (SDK issue
  [25573](https://github.com/dart-lang/sdk/issues/25573)), see the
  [documentation](https://github.com/dart-lang/dev_compiler/blob/master/doc/STATIC_SAFETY.md#disable-implicit-dynamic)
  for usage instructions and examples.

- Breaking change - infer generic type arguments from the constructor invocation
  arguments (SDK issue [25220](https://github.com/dart-lang/sdk/issues/25220)).

  ```dart
  var map = new Map<String, String>();

  // infer: Map<String, String>
  var otherMap = new Map.from(map);
  ```

- Breaking change - infer local function return type (SDK issue
  [26414](https://github.com/dart-lang/sdk/issues/26414)).

  ```dart
  void main() {
    // infer: return type is int
    f() { return 40; }
    int y = f() + 2; // type checks
    print(y);
  }
  ```

- Breaking change - allow type promotion from a generic type parameter (SDK
  issue [26414](https://github.com/dart-lang/sdk/issues/26965)).

  ```dart
  void fn/*<T>*/(/*=T*/ object) {
    if (object is String) {
      // Treat `object` as `String` inside this block.
      // But it will require a cast to pass it to something that expects `T`.
      print(object.substring(1));
    }
  }
  ```

- Breaking change - smarter inference for Future.then (SDK issue
  [25944](https://github.com/dart-lang/sdk/issues/25944)). Previous workarounds
  that use async/await or `.then/*<Future<SomeType>>*/` should no longer be
  necessary.

  ```dart
  // This will now infer correctly.
  Future<List<int>> t2 = f.then((_) => [3]);
  // This infers too.
  Future<int> t2 = f.then((_) => new Future.value(42));
  ```

- Breaking change - smarter inference for async functions (SDK issue
  [25322](https://github.com/dart-lang/sdk/issues/25322)).

  ```dart
  void test() async {
    List<int> x = await [4]; // was previously inferred
    List<int> y = await new Future.value([4]); // now inferred too
  }
  ```

- Breaking change - sideways casts are no longer allowed (SDK issue
  [26120](https://github.com/dart-lang/sdk/issues/26120)).

## 1.18.1 - 2016-08-02

Patch release, resolves two issues and improves performance:

- Debugger: Fixes a bug that crashes the VM (SDK issue
  [26941](https://github.com/dart-lang/sdk/issues/26941))

- VM: Fixes an optimizer bug involving closures, try, and await (SDK issue
  [26948](https://github.com/dart-lang/sdk/issues/26948))

- Dart2js: Speeds up generated code on Firefox
  (https://codereview.chromium.org/2180533002)

## 1.18.0 - 2016-07-27

### Core library changes

- `dart:core`
  - Improved performance when parsing some common URIs.
  - Fixed bug in `Uri.resolve` (SDK issue
    [26804](https://github.com/dart-lang/sdk/issues/26804)).
- `dart:io`
  - Adds file locking modes `FileLock.BLOCKING_SHARED` and
    `FileLock.BLOCKING_EXCLUSIVE`.

## 1.17.1 - 2016-06-10

Patch release, resolves two issues:

- VM: Fixes a bug that caused crashes in async functions. (SDK issue
  [26668](https://github.com/dart-lang/sdk/issues/26668))

- VM: Fixes a bug that caused garbage collection of reachable weak properties.
  (https://codereview.chromium.org/2041413005)

## 1.17.0 - 2016-06-08

### Core library changes

- `dart:convert`

  - Deprecate `ChunkedConverter` which was erroneously added in 1.16.

- `dart:core`

  - `Uri.replace` supports iterables as values for the query parameters.
  - `Uri.parseIPv6Address` returns a `Uint8List`.

- `dart:io`
  - Added `NetworkInterface.listSupported`, which is `true` when
    `NetworkInterface.list` is supported, and `false` otherwise. Currently,
    `NetworkInterface.list` is not supported on Android.

### Tool Changes

- Pub

  - TAR files created while publishing a package on Mac OS and Linux now use a
    more portable format.

  - Errors caused by invalid arguments now print the full usage information for
    the command.

  - SDK constraints for dependency overrides are no longer considered when
    determining the total SDK constraint for a lockfile.

  - A bug has been fixed in which a lockfile was considered up-to-date when it
    actually wasn't.

  - A bug has been fixed in which `pub get --offline` would crash when a
    prerelease version was selected.

- Dartium and content shell
  - Debugging Dart code inside iframes improved, was broken.

## 1.16.1 - 2016-05-24

Patch release, resolves one issue:

- VM: Fixes a bug that caused intermittent hangs on Windows. (SDK issue
  [26400](https://github.com/dart-lang/sdk/issues/26400))

## 1.16.0 - 2016-04-26

### Core library changes

- `dart:convert`

  - Added `BASE64URL` codec and corresponding `Base64Codec.urlSafe` constructor.

  - Introduce `ChunkedConverter` and deprecate chunked methods on `Converter`.

- `dart:html`

  There have been a number of **BREAKING** changes to align APIs with recent
  changes in Chrome. These include:

  - Chrome's `ShadowRoot` interface no longer has the methods `getElementById`,
    `getElementsByClassName`, and `getElementsByTagName`, e.g.,

    ```dart
    elem.shadowRoot.getElementsByClassName('clazz')
    ```

    should become:

    ```dart
    elem.shadowRoot.querySelectorAll('.clazz')
    ```

  - The `clipboardData` property has been removed from `KeyEvent` and `Event`.
    It has been moved to the new `ClipboardEvent` class, which is now used by
    `copy`, `cut`, and `paste` events.

  - The `layer` property has been removed from `KeyEvent` and `UIEvent`. It has
    been moved to `MouseEvent`.

  - The `Point get page` property has been removed from `UIEvent`. It still
    exists on `MouseEvent` and `Touch`.

  There have also been a number of other additions and removals to `dart:html`,
  `dart:indexed_db`, `dart:svg`, `dart:web_audio`, and `dart:web_gl` that
  correspond to changes to Chrome APIs between v39 and v45. Many of the breaking
  changes represent APIs that would have caused runtime exceptions when compiled
  to JavaScript and run on recent Chrome releases.

- `dart:io`
  - Added `SecurityContext.alpnSupported`, which is true if a platform supports
    ALPN, and false otherwise.

### JavaScript interop

For performance reasons, a potentially **BREAKING** change was added for
libraries that use JS interop. Any Dart file that uses `@JS` annotations on
declarations (top-level functions, classes or class members) to interop with
JavaScript code will require that the file have the annotation `@JS()` on a
library directive.

```dart
@JS()
library my_library;
```

The analyzer will enforce this by generating the error:

The `@JS()` annotation can only be used if it is also declared on the library
directive.

If part file uses the `@JS()` annotation, the library that uses the part should
have the `@JS()` annotation e.g.,

```dart
// library_1.dart
@JS()
library library_1;

import 'package:js/js.dart';

part 'part_1.dart';
```

```dart
// part_1.dart
part of library_1;

@JS("frameworkStabilizers")
external List<FrameworkStabilizer> get frameworkStabilizers;
```

If your library already has a JS module e.g.,

```dart
@JS('array.utils')
library my_library;
```

Then your library will work without any additional changes.

### Analyzer

- Static checking of `for in` statements. These will now produce static
  warnings:

  ```dart
  // Not Iterable.
  for (var i in 1234) { ... }

  // String cannot be assigned to int.
  for (int n in <String>["a", "b"]) { ... }
  ```

### Tool Changes

- Pub

  - `pub serve` now provides caching headers that should improve the performance
    of requesting large files multiple times.

  - Both `pub get` and `pub upgrade` now have a `--no-precompile` flag that
    disables precompilation of executables and transformed dependencies.

  - `pub publish` now resolves symlinks when publishing from a Git repository.
    This matches the behavior it always had when publishing a package that
    wasn't in a Git repository.

- Dart Dev Compiler

  - The **experimental** `dartdevc` executable has been added to the SDK.

  - It will help early adopters validate the implementation and provide
    feedback. `dartdevc` **is not** yet ready for production usage.

  - Read more about the Dart Dev Compiler [here][dartdevc].

[dartdevc]: https://github.com/dart-lang/dev_compiler

## 1.15.0 - 2016-03-09

### Core library changes

- `dart:async`

  - Made `StreamView` class a `const` class.

- `dart:core`

  - Added `Uri.queryParametersAll` to handle multiple query parameters with the
    same name.

- `dart:io`
  - Added `SecurityContext.usePrivateKeyBytes`,
    `SecurityContext.useCertificateChainBytes`,
    `SecurityContext.setTrustedCertificatesBytes`, and
    `SecurityContext.setClientAuthoritiesBytes`.
  - **Breaking** The named `directory` argument of
    `SecurityContext.setTrustedCertificates` has been removed.
  - Added support to `SecurityContext` for PKCS12 certificate and key
    containers.
  - All calls in `SecurityContext` that accept certificate data now accept an
    optional named parameter `password`, similar to
    `SecurityContext.usePrivateKeyBytes`, for use as the password for PKCS12
    data.

### Tool changes

- Dartium and content shell

  - The Chrome-based tools that ship as part of the Dart SDK - Dartium and
    content shell - are now based on Chrome version 45 (instead of Chrome 39).
  - Dart browser libraries (`dart:html`, `dart:svg`, etc) _have not_ been
    updated.
    - These are still based on Chrome 39.
    - These APIs will be updated in a future release.
  - Note that there are experimental APIs which have changed in the underlying
    browser, and will not work with the older libraries. For example,
    `Element.animate`.

- `dartfmt` - upgraded to v0.2.4
  - Better handling for long collections with comments.
  - Always put member metadata annotations on their own line.
  - Indent functions in named argument lists with non-functions.
  - Force the parameter list to split if a split occurs inside a function-typed
    parameter.
  - Don't force a split for before a single named argument if the argument
    itself splits.

### Service protocol changes

- Fixed a documentation bug where the field `extensionRPCs` in `Isolate` was not
  marked optional.

### Experimental language features

- Added support for
  [configuration-specific imports](https://github.com/munificent/dep-interface-libraries/blob/master/Proposal.md).
  On the VM and `dart2js`, they can be enabled with `--conditional-directives`.

  The analyzer requires additional configuration:

  ```yaml
  analyzer:
    language:
      enableConditionalDirectives: true
  ```

  Read about [configuring the analyzer] for more details.

[configuring the analyzer]:
  https://github.com/dart-lang/sdk/tree/master/pkg/analyzer#configuring-the-analyzer

## 1.14.2 - 2016-02-10

Patch release, resolves three issues:

- VM: Fixed a code generation bug on x64. (SDK commit
  [834b3f02](https://github.com/dart-lang/sdk/commit/834b3f02b6ab740a213fd808e6c6f3269bed80e5))

- `dart:io`: Fixed EOF detection when reading some special device files. (SDK
  issue [25596](https://github.com/dart-lang/sdk/issues/25596))

- Pub: Fixed an error using hosted dependencies in SDK version 1.14. (Pub issue
  [1386](https://github.com/dart-lang/pub/issues/1386))

## 1.14.1 - 2016-02-04

Patch release, resolves one issue:

- Debugger: Fixes a VM crash when a debugger attempts to set a break point
  during isolate initialization. (SDK issue
  [25618](https://github.com/dart-lang/sdk/issues/25618))

## 1.14.0 - 2016-01-28

### Core library changes

- `dart:async`

  - Added `Future.any` static method.
  - Added `Stream.fromFutures` constructor.

- `dart:convert`

  - `Base64Decoder.convert` now takes optional `start` and `end` parameters.

- `dart:core`

  - Added `current` getter to `StackTrace` class.
  - `Uri` class added support for data URIs
    - Added two new constructors: `dataFromBytes` and `dataFromString`.
    - Added a `data` getter for `data:` URIs with a new `UriData` class for the
      return type.
  - Added `growable` parameter to `List.filled` constructor.
  - Added microsecond support to `DateTime`: `DateTime.microsecond`,
    `DateTime.microsecondsSinceEpoch`, and
    `new DateTime.fromMicrosecondsSinceEpoch`.

- `dart:math`

  - `Random` added a `secure` constructor returning a cryptographically secure
    random generator which reads from the entropy source provided by the
    embedder for every generated random value.

- `dart:io`

  - `Platform` added a static `isIOS` getter and `Platform.operatingSystem` may
    now return `ios`.
  - `Platform` added a static `packageConfig` getter.
  - Added support for WebSocket compression as standardized in RFC 7692.
  - Compression is enabled by default for all WebSocket connections.
    - The optionally named parameter `compression` on the methods
      `WebSocket.connect`, `WebSocket.fromUpgradedSocket`, and
      `WebSocketTransformer.upgrade` and the `WebSocketTransformer` constructor
      can be used to modify or disable compression using the new
      `CompressionOptions` class.

- `dart:isolate`
  - Added **_experimental_** support for [Package Resolution Configuration].
    - Added `packageConfig` and `packageRoot` instance getters to `Isolate`.
    - Added a `resolvePackageUri` method to `Isolate`.
    - Added named arguments `packageConfig` and `automaticPackageResolution` to
      the `Isolate.spawnUri` constructor.

[package resolution configuration]:
  https://github.com/dart-lang/dart_enhancement_proposals/blob/master/Accepted/0005%20-%20Package%20Specification/DEP-pkgspec.md

### Tool changes

- `dartfmt`

  - Better line splitting in a variety of cases.

  - Other optimizations and bug fixes.

- Pub

  - **Breaking:** Pub now eagerly emits an error when a pubspec's "name" field
    is not a valid Dart identifier. Since packages with non-identifier names
    were never allowed to be published, and some of them already caused crashes
    when being written to a `.packages` file, this is unlikely to break many
    people in practice.

  - **Breaking:** Support for `barback` versions prior to 0.15.0 (released July

    1.  has been dropped. Pub will no longer install these older barback
        versions.

  - `pub serve` now GZIPs the assets it serves to make load times more similar
    to real-world use-cases.

  - `pub deps` now supports a `--no-dev` flag, which causes it to emit the
    dependency tree as it would be if no `dev_dependencies` were in use. This
    makes it easier to see your package's dependency footprint as your users
    will experience it.

  - `pub global run` now detects when a global executable's SDK constraint is no
    longer met and errors out, rather than trying to run the executable anyway.

  - Pub commands that check whether the lockfile is up-to-date (`pub run`,
    `pub deps`, `pub serve`, and `pub build`) now do additional verification.
    They ensure that any path dependencies' pubspecs haven't been changed, and
    they ensure that the current SDK version is compatible with all
    dependencies.

  - Fixed a crashing bug when using `pub global run` on a global script that
    didn't exist.

  - Fixed a crashing bug when a pubspec contains a dependency without a source
    declared.

## 1.13.2 - 2016-01-06

Patch release, resolves one issue:

- dart2js: Stack traces are not captured correctly (SDK issue [25235]
  (https://github.com/dart-lang/sdk/issues/25235))

## 1.13.1 - 2015-12-17

Patch release, resolves three issues:

- VM type propagation fix: Resolves a potential crash in the Dart VM (SDK commit
  [dff13be]
  (https://github.com/dart-lang/sdk/commit/dff13bef8de104d33b04820136da2d80f3c835d7))

- dart2js crash fix: Resolves a crash in pkg/js and dart2js (SDK issue [24974]
  (https://github.com/dart-lang/sdk/issues/24974))

- Pub get crash on ARM: Fixes a crash triggered when running 'pub get' on ARM
  processors such as those on a Raspberry Pi (SDK issue [24855]
  (https://github.com/dart-lang/sdk/issues/24855))

## 1.13.0 - 2015-11-18

### Core library changes

- `dart:async`

  - `StreamController` added getters for `onListen`, `onPause`, and `onResume`
    with the corresponding new `typedef void ControllerCallback()`.
  - `StreamController` added a getter for `onCancel` with the corresponding new
    `typedef ControllerCancelCallback()`;
  - `StreamTransformer` instances created with `fromHandlers` with no
    `handleError` callback now forward stack traces along with errors to the
    resulting streams.

- `dart:convert`

  - Added support for Base-64 encoding and decoding.
    - Added new classes `Base64Codec`, `Base64Encoder`, and `Base64Decoder`.
    - Added new top-level `const Base64Codec BASE64`.

- `dart:core`

  - `Uri` added `removeFragment` method.
  - `String.allMatches` (implementing `Pattern.allMatches`) is now lazy, as all
    `allMatches` implementations are intended to be.
  - `Resource` is deprecated, and will be removed in a future release.

- `dart:developer`

  - Added `Timeline` class for interacting with Observatory's timeline feature.
  - Added `ServiceExtensionHandler`, `ServiceExtensionResponse`, and
    `registerExtension` which enable developers to provide their own VM service
    protocol extensions.

- `dart:html`, `dart:indexed_db`, `dart:svg`, `dart:web_audio`, `dart:web_gl`,
  `dart:web_sql`

  - The return type of some APIs changed from `double` to `num`. Dartium is now
    using JS interop for most operations. JS does not distinguish between
    numeric types, and will return a number as an int if it fits in an int. This
    will mostly cause an error if you assign to something typed `double` in
    checked mode. You may need to insert a `toDouble()` call or accept `num`.
    Examples of APIs that are affected include `Element.getBoundingClientRect`
    and `TextMetrics.width`.

- `dart:io`

  - **Breaking:** Secure networking has changed, replacing the NSS library with
    the BoringSSL library. `SecureSocket`, `SecureServerSocket`,
    `RawSecureSocket`,`RawSecureServerSocket`, `HttpClient`, and `HttpServer`
    now all use a `SecurityContext` object which contains the certificates and
    keys used for secure TLS (SSL) networking.

    This is a breaking change for server applications and for some client
    applications. Certificates and keys are loaded into the `SecurityContext`
    from PEM files, instead of from an NSS certificate database. Information
    about how to change applications that use secure networking is at
    https://www.dartlang.org/server/tls-ssl.html

  - `HttpClient` no longer sends URI fragments in the request. This is not
    allowed by the HTTP protocol. The `HttpServer` still gracefully receives
    fragments, but discards them before delivering the request.
  - To allow connections to be accepted on the same port across different
    isolates, set the `shared` argument to `true` when creating server socket
    and `HttpServer` instances.
    - The deprecated `ServerSocketReference` and `RawServerSocketReference`
      classes have been removed.
    - The corresponding `reference` properties on `ServerSocket` and
      `RawServerSocket` have been removed.

- `dart:isolate`
  - `spawnUri` added an `environment` named argument.

### Tool changes

- `dart2js` and Dartium now support improved JavaScript Interoperability via the
  [js package](https://pub.dev/packages/js).

- `docgen` and `dartdocgen` no longer ship in the SDK. The `docgen` sources have
  been removed from the repository.

- This is the last release to ship the VM's "legacy debug protocol". We intend
  to remove the legacy debug protocol in Dart VM 1.14.

- The VM's Service Protocol has been updated to version 3.0 to take care of a
  number of issues uncovered by the first few non-observatory clients. This is a
  potentially breaking change for clients.

- Dartium has been substantially changed. Rather than using C++ calls into
  Chromium internals for DOM operations it now uses JS interop. The DOM objects
  in `dart:html` and related libraries now wrap a JavaScript object and delegate
  operations to it. This should be mostly transparent to users. However,
  performance and memory characteristics may be different from previous
  versions. There may be some changes in which DOM objects are wrapped as Dart
  objects. For example, if you get a reference to a Window object, even through
  JS interop, you will always see it as a Dart Window, even when used
  cross-frame. We expect the change to using JS interop will make it much
  simpler to update to new Chrome versions.

## 1.12.2 - 2015-10-21

### Core library changes

- `dart:io`

  - A memory leak in creation of Process objects is fixed.

## 1.12.1 - 2015-09-08

### Tool changes

- Pub

  - Pub will now respect `.gitignore` when validating a package before it's
    published. For example, if a `LICENSE` file exists but is ignored, that is
    now an error.

  - If the package is in a subdirectory of a Git repository and the entire
    subdirectory is ignored with `.gitignore`, pub will act as though nothing
    was ignored instead of uploading an empty package.

  - The heuristics for determining when `pub get` needs to be run before various
    commands have been improved. There should no longer be false positives when
    non-dependency sections of the pubspec have been modified.

## 1.12.0 - 2015-08-31

### Language changes

- Null-aware operators
  - `??`: if null operator. `expr1 ?? expr2` evaluates to `expr1` if not `null`,
    otherwise `expr2`.
  - `??=`: null-aware assignment. `v ??= expr` causes `v` to be assigned `expr`
    only if `v` is `null`.
  - `x?.p`: null-aware access. `x?.p` evaluates to `x.p` if `x` is not `null`,
    otherwise evaluates to `null`.
  - `x?.m()`: null-aware method invocation. `x?.m()` invokes `m` only if `x` is
    not `null`.

### Core library changes

- `dart:async`

  - `StreamController` added setters for the `onListen`, `onPause`, `onResume`
    and `onCancel` callbacks.

- `dart:convert`

  - `LineSplitter` added a `split` static method returning an `Iterable`.

- `dart:core`

  - `Uri` class now perform path normalization when a URI is created. This
    removes most `..` and `.` sequences from the URI path. Purely relative paths
    (no scheme or authority) are allowed to retain some leading "dot" segments.
    Also added `hasAbsolutePath`, `hasEmptyPath`, and `hasScheme` properties.

- `dart:developer`

  - New `log` function to transmit logging events to Observatory.

- `dart:html`

  - `NodeTreeSanitizer` added the `const trusted` field. It can be used instead
    of defining a `NullTreeSanitizer` class when calling `setInnerHtml` or other
    methods that create DOM from text. It is also more efficient, skipping the
    creation of a `DocumentFragment`.

- `dart:io`

  - Added two new file modes, `WRITE_ONLY` and `WRITE_ONLY_APPEND` for opening a
    file write only.
    [eaeecf2](https://github.com/dart-lang/sdk/commit/eaeecf2ed13ba6c7fbfd653c3c592974a7120960)
  - Change stdout/stderr to binary mode on Windows.
    [4205b29](https://github.com/dart-lang/sdk/commit/4205b2997e01f2cea8e2f44c6f46ed6259ab7277)

- `dart:isolate`

  - Added `onError`, `onExit` and `errorsAreFatal` parameters to
    `Isolate.spawnUri`.

- `dart:mirrors`
  - `InstanceMirror.delegate` moved up to `ObjectMirror`.
  - Fix InstanceMirror.getField optimization when the selector is an operator.
  - Fix reflective NoSuchMethodErrors to match their non-reflective counterparts
    when due to argument mismatches. (VM only)

### Tool changes

- Documentation tools

  - `dartdoc` is now the default tool to generate static HTML for API docs.
    [Learn more](https://pub.dev/packages/dartdoc).

  - `docgen` and `dartdocgen` have been deprecated. Currently plan is to remove
    them in 1.13.

- Formatter (`dartfmt`)

  - Over 50 bugs fixed.

  - Optimized line splitter is much faster and produces better output on complex
    code.

- Observatory

  - Allocation profiling.

  - New feature to display output from logging.

  - Heap snapshot analysis works for 64-bit VMs.

  - Improved ability to inspect typed data, regex and compiled code.

  - Ability to break on all or uncaught exceptions from Observatory's debugger.

  - Ability to set closure-specific breakpoints.

  - 'anext' - step past await/yield.

  - Preserve when a variable has been expanded/unexpanded in the debugger.

  - Keep focus on debugger input box whenever possible.

  - Echo stdout/stderr in the Observatory debugger. Standalone-only so far.

  - Minor fixes to service protocol documentation.

- Pub

  - **Breaking:** various commands that previously ran `pub get` implicitly no
    longer do so. Instead, they merely check to make sure the ".packages" file
    is newer than the pubspec and the lock file, and fail if it's not.

  - Added support for `--verbosity=error` and `--verbosity=warning`.

  - `pub serve` now collapses multiple GET requests into a single line of
    output. For full output, use `--verbose`.

  - `pub deps` has improved formatting for circular dependencies on the
    entrypoint package.

  - `pub run` and `pub global run`

    - **Breaking:** to match the behavior of the Dart VM, executables no longer
      run in checked mode by default. A `--checked` flag has been added to run
      them in checked mode manually.

    - Faster start time for executables that don't import transformed code.

    - Binstubs for globally-activated executables are now written in the system
      encoding, rather than always in `UTF-8`. To update existing executables,
      run `pub cache repair`.

  - `pub get` and `pub upgrade`

    - Pub will now generate a ".packages" file in addition to the "packages"
      directory when running `pub get` or similar operations, per the [package
      spec proposal][]. Pub now has a `--no-package-symlinks` flag that will
      stop "packages" directories from being generated at all.

    - An issue where HTTP requests were sometimes made even though `--offline`
      was passed has been fixed.

    - A bug with `--offline` that caused an unhelpful error message has been
      fixed.

    - Pub will no longer time out when a package takes a long time to download.

  - `pub publish`

    - Pub will emit a non-zero exit code when it finds a violation while
      publishing.

    - `.gitignore` files will be respected even if the package isn't at the top
      level of the Git repository.

  - Barback integration

    - A crashing bug involving transformers that only apply to non-public code
      has been fixed.

    - A deadlock caused by declaring transformer followed by a lazy transformer
      (such as the built-in `$dart2js` transformer) has been fixed.

    - A stack overflow caused by a transformer being run multiple times on the
      package that defines it has been fixed.

    - A transformer that tries to read a nonexistent asset in another package
      will now be re-run if that asset is later created.

[package spec proposal]: https://github.com/lrhn/dep-pkgspec

### VM Service Protocol Changes

- **BREAKING** The service protocol now sends JSON-RPC 2.0-compatible
  server-to-client events. To reflect this, the service protocol version is now
  2.0.

- The service protocol now includes a `"jsonrpc"` property in its responses, as
  opposed to `"json-rpc"`.

- The service protocol now properly handles requests with non-string ids.
  Numeric ids are no longer converted to strings, and null ids now don't produce
  a response.

- Some RPCs that didn't include a `"jsonrpc"` property in their responses now
  include one.

## 1.11.2 - 2015-08-03

### Core library changes

- Fix a bug where `WebSocket.close()` would crash if called after
  `WebSocket.cancel()`.

## 1.11.1 - 2015-07-02

### Tool changes

- Pub will always load Dart SDK assets from the SDK whose `pub` executable was
  run, even if a `DART_SDK` environment variable is set.

## 1.11.0 - 2015-06-25

### Core library changes

- `dart:core`

  - `Iterable` added an `empty` constructor.
    [dcf0286](https://github.com/dart-lang/sdk/commit/dcf0286f5385187a68ce9e66318d3bf19abf454b)
  - `Iterable` can now be extended directly. An alternative to extending
    `IterableBase` from `dart:collection`.
  - `List` added an `unmodifiable` constructor.
    [r45334](https://code.google.com/p/dart/source/detail?r=45334)
  - `Map` added an `unmodifiable` constructor.
    [r45733](https://code.google.com/p/dart/source/detail?r=45733)
  - `int` added a `gcd` method.
    [a192ef4](https://github.com/dart-lang/sdk/commit/a192ef4acb95fad1aad1887f59eed071eb5e8201)
  - `int` added a `modInverse` method.
    [f6f338c](https://github.com/dart-lang/sdk/commit/f6f338ce67eb8801b350417baacf6d3681b26002)
  - `StackTrace` added a `fromString` constructor.
    [68dd6f6](https://github.com/dart-lang/sdk/commit/68dd6f6338e63d0465041d662e778369c02c2ce6)
  - `Uri` added a `directory` constructor.
    [d8dbb4a](https://github.com/dart-lang/sdk/commit/d8dbb4a60f5e8a7f874c2a4fbf59eaf1a39f4776)
  - List iterators may not throw `ConcurrentModificationError` as eagerly in
    release mode. In checked mode, the modification check is still as eager as
    possible. [r45198](https://github.com/dart-lang/sdk/commit/5a79c03)

- `dart:developer` - **NEW**

  - Replaces the deprecated `dart:profiler` library.
  - Adds new functions `debugger` and `inspect`.
    [6e42aec](https://github.com/dart-lang/sdk/blob/6e42aec4f64cf356dde7bad9426e07e0ea5b58d5/sdk/lib/developer/developer.dart)

- `dart:io`

  - `FileSystemEntity` added a `uri` property.
    [8cf32dc](https://github.com/dart-lang/sdk/commit/8cf32dc1a1664b516e57f804524e46e55fae88b2)
  - `Platform` added a `static resolvedExecutable` property.
    [c05c8c6](https://github.com/dart-lang/sdk/commit/c05c8c66069db91cc2fd48691dfc406c818d411d)

- `dart:html`

  - `Element` methods, `appendHtml` and `insertAdjacentHtml` now take
    `nodeValidator` and `treeSanitizer` parameters, and the inputs are
    consistently sanitized.
    [r45818 announcement](https://groups.google.com/a/dartlang.org/forum/#!topic/announce/GVO7EAcPi6A)

- `dart:isolate`

  - **BREAKING** The positional `priority` parameter of `Isolate.ping` and
    `Isolate.kill` is now a named parameter named `priority`.
  - **BREAKING** Removed the `Isolate.AS_EVENT` priority.
  - `Isolate` methods `ping` and `addOnExitListener` now have a named parameter
    `response`. [r45092](https://github.com/dart-lang/sdk/commit/1b208bd)
  - `Isolate.spawnUri` added a named argument `checked`.
  - Remove the experimental state of the API.

- `dart:profiler` - **DEPRECATED**
  - This library will be removed in 1.12. Use `dart:developer` instead.

### Tool changes

- This is the first release that does not include the Eclipse-based **Dart
  Editor**. See [dart.dev/tools](https://dart.dev/tools#ides-and-editors) for
  alternatives.
- This is the last release that ships the (unsupported) dart2dart (aka
  `dart2js --output-type=dart`) utility as part of dart2js

## 1.10.0 - 2015-04-29

### Core library changes

- `dart:convert`

  - **POTENTIALLY BREAKING** Fix behavior of `HtmlEscape`. It no longer escapes
    no-break space (U+00A0) anywhere or forward slash (`/`, `U+002F`) in element
    context. Slash is still escaped using `HtmlEscapeMode.UNKNOWN`.
    [r45003](https://github.com/dart-lang/sdk/commit/8b8223d),
    [r45153](https://github.com/dart-lang/sdk/commit/8a5d049),
    [r45189](https://github.com/dart-lang/sdk/commit/3c39ad2)

- `dart:core`

  - `Uri.parse` added `start` and `end` positional arguments.

- `dart:html`

  - **POTENTIALLY BREAKING** `CssClassSet` method arguments must now be
    'tokens', i.e. non-empty strings with no white-space characters. The
    implementation was incorrect for class names containing spaces. The fix is
    to forbid spaces and provide a faster implementation.
    [Announcement](https://groups.google.com/a/dartlang.org/d/msg/announce/jmUI2XJHfC8/UZUCvJH3p2oJ)

- `dart:io`

  - `ProcessResult` now exposes a constructor.
  - `import` and `Isolate.spawnUri` now supports the
    [Data URI scheme](http://en.wikipedia.org/wiki/Data_URI_scheme) on the VM.

### Tool Changes

#### pub

- Running `pub run foo` within a package now runs the `foo` executable defined
  by the `foo` package. The previous behavior ran `bin/foo`. This makes it easy
  to run binaries in dependencies, for instance `pub run test`.

- On Mac and Linux, signals sent to `pub run` and forwarded to the child
  command.

## 1.9.3 - 2015-04-14

This is a bug fix release which merges a number of commits from `bleeding_edge`.

- dart2js: Addresses as issue with minified JavaScript output with CSP enabled -
  [r44453](https://code.google.com/p/dart/source/detail?r=44453)

- Editor: Fixes accidental updating of files in the pub cache during rename
  refactoring - [r44677](https://code.google.com/p/dart/source/detail?r=44677)

- Editor: Fix for
  [issue 23032](https://code.google.com/p/dart/issues/detail?id=23032) regarding
  skipped breakpoints on Windows -
  [r44824](https://code.google.com/p/dart/source/detail?r=44824)

- dart:mirrors: Fix `MethodMirror.source` when the method is on the first line
  in a script - [r44957](https://code.google.com/p/dart/source/detail?r=44957),
  [r44976](https://code.google.com/p/dart/source/detail?r=44976)

- pub: Fix for
  [issue 23084](https://code.google.com/p/dart/issues/detail?id=23084): Pub can
  fail to load transformers necessary for local development -
  [r44876](https://code.google.com/p/dart/source/detail?r=44876)

## 1.9.1 - 2015-03-25

### Language changes

- Support for `async`, `await`, `sync*`, `async*`, `yield`, `yield*`, and
  `await for`. See the [the language tour][async] for more details.

- Enum support is fully enabled. See [the language tour][enum] for more details.

[async]: https://dart.dev/guides/language/language-tour#asynchrony
[enum]: https://dart.dev/guides/language/language-tour#enums

### Tool changes

- The formatter is much more comprehensive and generates much more readable
  code. See [its tool page][dartfmt] for more details.

- The analysis server is integrated into the IntelliJ plugin and the Dart
  editor. This allows analysis to run out-of-process, so that interaction
  remains smooth even for large projects.

- Analysis supports more and better hints, including unused variables and unused
  private members.

[dartfmt]: https://dart.dev/tools/dart-format

### Core library changes

#### Highlights

- There's a new model for shared server sockets with no need for a `Socket`
  reference.

- A new, much faster [regular expression engine][regexp].

- The Isolate API now works across the VM and `dart2js`.

[regexp]: http://news.dartlang.org/2015/02/irregexp-dart-vms-new-regexp.html

#### Details

For more information on any of these changes, see the corresponding
documentation on the [Dart API site](http://api.dart.dev).

- `dart:async`:

  - `Future.wait` added a new named argument, `cleanUp`, which is a callback
    that releases resources allocated by a successful `Future`.

  - The `SynchronousStreamController` class was added as an explicit name for
    the type returned when the `sync` argument is passed to
    `new StreamController`.

- `dart:collection`: The `new SplayTreeSet.from(Iterable)` constructor was
  added.

- `dart:convert`: `Utf8Encoder.convert` and `Utf8Decoder.convert` added optional
  `start` and `end` arguments.

- `dart:core`:

  - `RangeError` added new static helper functions: `checkNotNegative`,
    `checkValidIndex`, `checkValidRange`, and `checkValueInInterval`.

  - `int` added the `modPow` function.

  - `String` added the `replaceFirstMapped` and `replaceRange` functions.

- `dart:io`:

  - Support for locking files to prevent concurrent modification was added. This
    includes the `File.lock`, `File.lockSync`, `File.unlock`, and
    `File.unlockSync` functions as well as the `FileLock` class.

  - Support for starting detached processes by passing the named `mode` argument
    (a `ProcessStartMode`) to `Process.start`. A process can be fully attached,
    fully detached, or detached except for its standard IO streams.

  - `HttpServer.bind` and `HttpServer.bindSecure` added the `v6Only` named
    argument. If this is true, only IPv6 connections will be accepted.

  - `HttpServer.bind`, `HttpServer.bindSecure`, `ServerSocket.bind`,
    `RawServerSocket.bind`, `SecureServerSocket.bind` and
    `RawSecureServerSocket.bind` added the `shared` named argument. If this is
    true, multiple servers or sockets in the same Dart process may bind to the
    same address, and incoming requests will automatically be distributed
    between them.

  - **Deprecation:** the experimental `ServerSocketReference` and
    `RawServerSocketReference` classes, as well as getters that returned them,
    are marked as deprecated. The `shared` named argument should be used
    instead. These will be removed in Dart 1.10.

  - `Socket.connect` and `RawSocket.connect` added the `sourceAddress` named
    argument, which specifies the local address to bind when making a
    connection.

  - The static `Process.killPid` method was added to kill a process with a given
    PID.

  - `Stdout` added the `nonBlocking` instance property, which returns a
    non-blocking `IOSink` that writes to standard output.

- `dart:isolate`:

  - The static getter `Isolate.current` was added.

  - The `Isolate` methods `addOnExitListener`, `removeOnExitListener`,
    `setErrorsFatal`, `addOnErrorListener`, and `removeOnErrorListener` now work
    on the VM.

  - Isolates spawned via `Isolate.spawn` now allow most objects, including
    top-level and static functions, to be sent between them.

## 1.8.5 - 2015-01-21

- Code generation for SIMD on ARM and ARM64 is fixed.

- A possible crash on MIPS with newer GCC toolchains has been prevented.

- A segfault when using `rethrow` was fixed ([issue 21795][]).

[issue 21795]: https://code.google.com/p/dart/issues/detail?id=21795

## 1.8.3 - 2014-12-10

- Breakpoints can be set in the Editor using file suffixes ([issue 21280][]).

- IPv6 addresses are properly handled by `HttpClient` in `dart:io`, fixing a
  crash in pub ([issue 21698][]).

- Issues with the experimental `async`/`await` syntax have been fixed.

- Issues with a set of number operations in the VM have been fixed.

- `ListBase` in `dart:collection` always returns an `Iterable` with the correct
  type argument.

[issue 21280]: https://code.google.com/p/dart/issues/detail?id=21280
[issue 21698]: https://code.google.com/p/dart/issues/detail?id=21698

## 1.8.0 - 2014-11-28

- `dart:collection`: `SplayTree` added the `toSet` function.

- `dart:convert`: The `JsonUtf8Encoder` class was added.

- `dart:core`:

  - The `IndexError` class was added for errors caused by an index being outside
    its expected range.

  - The `new RangeError.index` constructor was added. It forwards to
    `new IndexError`.

  - `RangeError` added three new properties. `invalidProperty` is the value that
    caused the error, and `start` and `end` are the minimum and maximum values
    that the value is allowed to assume.

  - `new RangeError.value` and `new RangeError.range` added an optional
    `message` argument.

  - The `new String.fromCharCodes` constructor added optional `start` and `end`
    arguments.

- `dart:io`:

  - Support was added for the [Application-Layer Protocol Negotiation][alpn]
    extension to the TLS protocol for both the client and server.

  - `SecureSocket.connect`, `SecureServerSocket.bind`,
    `RawSecureSocket.connect`, `RawSecureSocket.secure`,
    `RawSecureSocket.secureServer`, and `RawSecureServerSocket.bind` added a
    `supportedProtocols` named argument for protocol negotiation.

  - `RawSecureServerSocket` added a `supportedProtocols` field.

  - `RawSecureSocket` and `SecureSocket` added a `selectedProtocol` field which
    contains the protocol selected during protocol negotiation.

[alpn]: https://tools.ietf.org/html/rfc7301

## 1.7.0 - 2014-10-15

### Tool changes

- `pub` now generates binstubs for packages that are globally activated so that
  they can be put on the user's `PATH` and used as normal executables. See the
  [`pub global activate` documentation][pub global activate].

- When using `dart2js`, deferred loading now works with multiple Dart apps on
  the same page.

[pub global activate]:
  https://dart.dev/tools/pub/cmd/pub-global#running-a-script-from-your-path

### Core library changes

- `dart:async`: `Zone`, `ZoneDelegate`, and `ZoneSpecification` added the
  `errorCallback` function, which allows errors that have been programmatically
  added to a `Future` or `Stream` to be intercepted.

- `dart:io`:

  - **Breaking change:** `HttpClient.close` must be called for all clients or
    they will keep the Dart process alive until they time out. This fixes the
    handling of persistent connections. Previously, the client would shut down
    immediately after a request.

  - **Breaking change:** `HttpServer` no longer compresses all traffic by
    default. The new `autoCompress` property can be set to `true` to re-enable
    compression.

- `dart:isolate`: `Isolate.spawnUri` added the optional `packageRoot` argument,
  which controls how it resolves `package:` URIs.
