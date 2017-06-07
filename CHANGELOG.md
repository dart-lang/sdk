## 1.25.0

### Language

#### Strong Mode

### Core library changes

* `dart:io`
  * Unified backends for `SecureSocket`, `SecurityContext`, and 
    `X509Certificate` to be consistent across all platforms. All
    `SecureSocket`, `SecurityContext`, and `X509Certificate` properties and
    methods are now supported on iOS and OSX.

### Dart VM

### Tool Changes

## 1.24.0

### Language
* During a dynamic type check, `void` is not required to be `null` anymore.
  In practice, this makes overriding `void` functions with non-`void` functions
  safer.
* During static analysis, a function or setter declared using `=>` with return
  type `void` now allows the returned expression to have any type. For example,
  assuming the declaration `int x;`, it is now type correct to have
  `void f() => ++x;`.
* A new function-type syntax has been added to the language.
  Intuitively, the type of a function can be constructed by textually replacing
  the function's name with `Function` in its declaration. For instance, the
  type of `void foo() {}` would be `void Function()`. The new syntax may be used
  wherever a type can be written. It is thus now possible to declare fields
  containing functions without needing to write typedefs: `void Function() x;`.
  The new function type has one restriction: it may not contain the old-style
  function-type syntax for its parameters. The following is thus
  illegal: `void Function(int f())`.
  `typedefs` have been updated to support this new syntax.
  Examples:
  ```
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

#### Strong Mode

* Removed ad hoc Future.then inference in favor of using FutureOr.  Prior to
adding FutureOr to the language, the analyzer implented an ad hoc type inference
for Future.then (and overrides) treating it as if the onValue callback was typed
to return FutureOr for the purposes of inference.  This ad hoc inference has
been removed now that FutureOr has been added.

Packages that implement `Future` must either type the `onValue` parameter to
`.then` as returning `FutureOr<T>`, or else must leave the type of the parameter
entirely to allow inference to fill in the type.

* The following is also a change in strong mode: During static analysis, a
  function or setter declared using `=>` with return type `void` now allows the
  returned expression to have any type.
* The new function-type syntax is also supported by strong mode.

### Core library changes

* `dart:io`
  * Added `Platform.localeName`, needed for accessing the locale on platforms
    that don't store it in an environment variable.
  * Added `ProcessInfo.currentRss` and `ProcessInfo.maxRss` for inspecting
    the Dart VM process current and peak resident set size.
  * Added 'RawSynchronousSocket', a basic synchronous socket implementation.
* `dart:convert`
  * Removed deprecated `ChunkedConverter` class.
  * JSON maps are now typed as `Map<String, dynamic>` instead of
    `Map<dynamic, dynamic>`. A JSON-map is not a `HashMap` or `LinkedHashMap`
    anymore (but just a `Map`).
* `dart:async`, `dart:io`, `dart:core`
    * Adding to a closed sink, including `IOSink`, is not allowed anymore. In
      1.24, violations are only reported (on stdout or stderr), but a future
      version of the Dart SDK will change this to throwing a `StateError`.

### Dart VM

### Tool Changes

* Pub
    * Added support for the Dart Development Compiler in `build` and `serve`.

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

        * Use the new `--web-compiler` flag, which supports `dartdevc`,
          `dart2js` or `none` as options. This is the easiest way to try things
          out without changing the default.

        * Add config to your pubspec. There is a new `web` key which supports a
          single key called `compiler`. This is a map from mode names to
          compiler to use. For example, to default to dartdevc in debug mode you
          can add the following to your pubspec:

          ```yaml
          web:
            compiler:
              debug: dartdevc
          ```

      You can also use the new compiler to run your tests in Chrome much more
      quickly than you can with dart2js. In order to do that, run
      `pub serve test --web-compiler=dartdevc`, and then run
      `pub run test -p chrome --pub-serve=8080`.

    * The `--no-dart2js` flag has been deprecated in favor of
      `--web-compiler=none`.
    * Added support for the UNLICENSE file when validating licenses on
      `pub lish`.
    * Better handling for network errors when fetching packages. These are no
      longer unhandled errors and won't print a stack trace unless you are
      running in verbose mode.
    * `pub build` will use a failing exit code if there are errors in any
      transformer.
    * Allow publishing packages that depend on the Flutter SDK.

* dartfmt
    * Preserve type parameters in new generic function typedef syntax.
    * Add self-test validation to ensure formatter bugs do not cause user code
      to be lost.

### Infrastructure changes

* As of this release, we'll show a warning when using the MIPS architecture.
  Unless we learn about any critical use of Dart on MIPS in the meantime, we're
  planning to deprecate support for MIPS starting with the next stable release.

## 1.23.0

#### Strong Mode

* Breaking change - it is now a strong mode error if a mixin causes a name
  conflict between two private members (field/getter/setter/method) from a
  different library. (SDK
  issue [28809](https://github.com/dart-lang/sdk/issues/28809)).

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


* Breaking change - strong mode will prefer the expected type to infer generic
  types, functions, and methods (SDK
  issue [27586](https://github.com/dart-lang/sdk/issues/27586)).

  ```dart
  main() {
    List<Object> foo = /*infers: <Object>*/['hello', 'world'];
    var bar = /*infers: <String>*/['hello', 'world'];
  }
  ```

* Strong mode inference error messages are improved
  (SDK issue [29108](https://github.com/dart-lang/sdk/issues/29108)).

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

* Strong mode supports overriding fields, `@virtual` is no longer required
    (SDK issue [28120](https://github.com/dart-lang/sdk/issues/28120)).

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

* Strong mode down cast composite warnings are no longer issued by default.
  (SDK issue [28588](https://github.com/dart-lang/sdk/issues/28588)).

```dart
void test() {
  List untyped = [];
  List<int> typed = untyped; // No down cast composite warning
}
```

To opt back into the warnings, add the following to
the
[.analysis_options](https://www.dartlang.org/guides/language/analysis-options)
file for your project.

```
analyzer:
  errors:
    strong_mode_down_cast_composite: warning
```


### Core library changes

* `dart:core`
  * Added `Uri.isScheme` function to check the scheme of a URI.
    Example: `uri.isScheme("http")`. Ignores case when comparing.
  * Make `UriData.parse` validate its input better.
    If the data is base-64 encoded, the data is normalized wrt.
    alphabet and padding, and it contains invalid base-64 data,
    parsing fails. Also normalizes non-base-64 data.
* `dart:io`
  * Added functions `File.lastAccessed`, `File.lastAccessedSync`,
    `File.setLastModified`, `File.setLastModifiedSync`, `File.setLastAccessed`,
    and `File.setLastAccessedSync`.
  * Added `{Stdin,Stdout}.supportsAnsiEscapes`.

### Dart VM

* Calls to `print()` and `Stdout.write*()` now correctly print unicode
  characters to the console on Windows. Calls to `Stdout.add*()` behave as
  before.

### Tool changes

* Analysis
  * `dartanalyzer` now follows the same rules as the analysis server to find
    an analysis options file, stopping when an analysis options file is found:
    * Search up the directory hierarchy looking for an analysis options file.
    * If analyzing a project referencing the [Flutter](https://flutter.io/)
      package, then use the
      [default Flutter analysis options](https://github.com/flutter/flutter/blob/master/packages/flutter/lib/analysis_options_user.yaml)
      found in `package:flutter`.
    * If in a Bazel workspace, then use the analysis options in
      `package:dart.analysis_options/default.yaml` if it exists.
    * Use the default analysis options rules.
  * In addition, specific to `dartanalyzer`:
    * an analysis options file can be specified on the command line via
      `--options` and that file will be used instead of searching for an
      analysis options file.
    * any analysis option specified on the command line
      (e.g. `--strong` or `--no-strong`) takes precedence over any corresponding
      value specified in the analysis options file.

* Dartium, dart2js, and DDC

  * Imports to `dart:io` are allowed, but the imported library is not supported
    and will likely fail on most APIs at runtime. This change was made as a
    stopgap measure to make it easier to write libraries that share code between
    platforms (like package `http`). This might change again when configuration
    specific imports are supported.

* Pub
  * Now sends telemetry data to `pub.dartlang.org` to allow better understanding
    of why a particular package is being accessed.
  * `pub publish`
    * Warns if a package imports a package that's not a dependency from within
      `lib/` or `bin/`, or a package that's not a dev dependency from within
      `benchmark/`, `example/`, `test/` or `tool/`.
    * No longer produces "UID too large" errors on OS X. All packages are now
      uploaded with the user and group names set to "pub".
    * No longer fails with a stack overflow when uploading a package that uses
      Git submodules.
  * `pub get` and `pub upgrade`
    * Produce more informative error messages if they're run directly in a
      package that uses Flutter.
    * Properly unlock SDK and path dependencies if they have a new version
      that's also valid according to the user's pubspec.

* dartfmt
  * Support new generic function typedef syntax.
  * Make the precedence of cascades more visible.
  * Fix a couple of places where spurious newlines were inserted.
  * Correctly report unchanged formatting when reading from stdin.
  * Ensure space between `-` and `--`. Code that does this is pathological, but
    it technically meant dartfmt could change the semantics of the code.
  * Preserve a blank line between enum cases.
  * Other small formatting tweaks.

## 1.22.0 - 2017-02-14

### Language

  * Breaking change:
    ['Generalized tear-offs'](https://github.com/gbracha/generalizedTearOffs/blob/master/proposal.md)
    are no longer supported, and will cause errors. We updated the language spec
    and added warnings in 1.21, and are now taking the last step to fully
    de-support them. They were previously only supported in the VM, and there
    are almost no known uses of them in the wild.

  * The `assert()` statement has been expanded to support an optional second
    `message` argument
    (SDK issue [27342](https://github.com/dart-lang/sdk/issues/27342)).

    The message is displayed if the assert fails. It can be any object, and it
    is accessible as `AssertionError.message`. It can be used to provide more
    user friendly exception outputs. As an example, the following assert:

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

  * The `Null` type has been moved to the bottom of the type hierarchy. As such,
    it is considered a subtype of every other type. The `null` *literal* was
    always treated as a bottom type. Now the named class `Null` is too:

    ```dart
    const empty = <Null>[];

    String concatenate(List<String> parts) => parts.join();
    int sum(List<int> numbers) => numbers.fold(0, (sum, n) => sum + n);

    concatenate(empty); // OK.
    sum(empty); // OK.
    ```

  * Introduce `covariant` modifier on parameters. It indicates that the
    parameter (and the corresponding parameter in any method that overrides it)
    has looser override rules. In strong mode, these require a runtime type
    check to maintain soundness, but enable an architectural pattern that is
    useful in some code.

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
    rarely rely on it. Strong mode disallowed it initially. Now, strong mode
    lets you opt into this behavior in the places where you do want it by using
    this modifier. Outside of strong mode, the modifier is ignored.

  * Change instantiate-to-bounds rules for generic type parameters when running
    in strong mode. If you leave off the type parameters from a generic type, we
    need to decide what to fill them in with.  Dart 1.0 says just use `dynamic`,
    but that isn't sound:

    ```dart
    class Abser<T extends num> {
       void absThis(T n) { n.abs(); }
    }

    var a = new Abser(); // Abser<dynamic>.
    a.absThis("not a num");
    ```

    We want the body of `absThis()` to be able to safely assume `n` is at
    least a `num` -- that's why there's a constraint on T, after all. Implicitly
    using `dynamic` as the type parameter in this example breaks that.

    Instead, strong mode uses the bound. In the above example, it fills it in
    with `num`, and then the second line where a string is passed becomes a
    static error.

    However, there are some cases where it is hard to figure out what that
    default bound should be:

    ```dart
    class RuhRoh<T extends Comparable<T>> {}
    ```

    Strong mode's initial behavior sometimes produced surprising, unintended
    results. For 1.22, we take a simpler approach and then report an error if
    a good default type argument can't be found.

### Core libraries

  * Define `FutureOr<T>` for code that works with either a future or an
    immediate value of some type. For example, say you do a lot of text
    manipulation, and you want a handy function to chain a bunch of them:

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

    Later, you realize you'd also like to support swizzlers that are
    asynchronous (maybe they look up synonyms for words online). You could make
    your API strictly asynchronous, but then users of simple synchronous
    swizzlers have to manually wrap the return value in a `Future.value()`.
    Ideally, your `swizzle()` function would be "polymorphic over asynchrony".
    It would allow both synchronous and asynchronous swizzlers. Because `await`
    accepts immediate values, it is easy to implement this dynamically:

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

    `FutureOr<T>` becomes really important in *generic* methods like
    `Future.then()`. In those cases, having the type system understand this
    magical union type helps type inference figure out the type argument of
    `then()` based on the closure you pass it.

    Previously, strong mode had hard-coded rules for handling `Future.then()`
    specifically. `FutureOr<T>` exposes that functionality so third-party APIs
    can take advantage of it too.

### Tool changes

* Dart2Js

  * Remove support for (long-time deprecated) mixin typedefs.

* Pub

  * Avoid using a barback asset server for executables unless they actually use
    transformers. This makes precompilation substantially faster, produces
    better error messages when precompilation fails, and allows
    globally-activated executables to consistently use the
    `Isolate.resolvePackageUri()` API.

  * On Linux systems, always ignore packages' original file owners and
    permissions when extracting those packages. This was already the default
    under most circumstances.

  * Properly close the standard input stream of child processes started using
    `pub run`.

  * Handle parse errors from the package cache more gracefully. A package whose
    pubspec can't be parsed will now be ignored by `pub get --offline` and
    deleted by `pub cache repair`.

  * Make `pub run` run executables in spawned isolates. This lets them handle
    signals and use standard IO reliably.

  * Fix source-maps produced by dart2js when running in `pub serve`: URL
    references to assets from packages match the location where `pub serve`
    serves them (`packages/package_name/` instead of
    `../packages/package_name/`).

### Infrastructure changes

  * The SDK now uses GN rather than gyp to generate its build files, which will
    now be exclusively ninja flavored. Documentation can be found on our
    [wiki](https://github.com/dart-lang/sdk/wiki/Building-with-GN). Also see the
    help message of `tools/gn.py`. This change is in response to the deprecation
    of gyp. Build file generation with gyp will continue to be available in this
    release by setting the environment variable `DART_USE_GYP` before running
    `gclient sync` or `gclient runhooks`, but this will be removed in a future
    release.

## 1.21.0 - 2016-12-07

### Language

* Support generic method syntax. Type arguments are not available at
  runtime. For details, check the
  [informal specification](https://gist.github.com/eernstg/4353d7b4f669745bed3a5423e04a453c).
* Support access to initializing formals, e.g., the use of `x` to initialize
 `y` in `class C { var x, y; C(this.x): y = x; }`.
  Please check the
  [informal specification](https://gist.github.com/eernstg/cff159be9e34d5ea295d8c24b1a3e594)
  for details.
* Don't warn about switch case fallthrough if the case ends in a `rethrow`
  statement.  (SDK issue
  [27650](https://github.com/dart-lang/sdk/issues/27650))
* Also don't warn if the entire switch case is wrapped in braces - as long as
  the block ends with a `break`, `continue`, `rethrow`, `return` or `throw`.
* Allow `=` as well as `:` as separator for named parameter default values.

  ```dart
  enableFlags({bool hidden: false}) { … }
  ```

  can now be replaced by

  ```dart
  enableFlags({bool hidden = false}) { … }
  ```

  (SDK issue [27559](https://github.com/dart-lang/sdk/issues/27559))

### Core library changes

* `dart:core`: `Set.difference` now takes a `Set<Object>` as argument.  (SDK
  issue [27573](https://github.com/dart-lang/sdk/issues/27573))

* `dart:developer`

  * Added `Service` class.
    * Allows inspecting and controlling the VM service protocol HTTP server.
    * Provides an API to access the ID of an `Isolate`.

### Tool changes

* Dart Dev Compiler

  * Support calls to `loadLibrary()` on deferred libraries. Deferred libraries
    are still loaded eagerly. (SDK issue
    [27343](https://github.com/dart-lang/sdk/issues/27343))

## 1.20.1 - 2016-10-13

Patch release, resolves one issue:

* Dartium: Fixes a bug that caused crashes.  No issue filed.

### Strong Mode

* It is no longer a warning when casting from dynamic to a composite type
    (SDK issue [27766](https://github.com/dart-lang/sdk/issues/27766)).

    ```dart
    main() {
      dynamic obj = <int>[1, 2, 3];
      // This is now allowed without a warning.
      List<int> list = obj;
    }
    ```

## 1.20.0 - 2016-10-11

### Dart VM

* We have improved the way that the VM locates the native code library for a
  native extension (e.g. `dart-ext:` import). We have updated this
  [article on native extensions](https://www.dartlang.org/articles/dart-vm/native-extensions)
  to reflect the VM's improved behavior.

* Linux builds of the VM will now use the `tcmalloc` library for memory
  allocation. This has the advantages of better debugging and profiling support
  and faster small allocations, with the cost of slightly larger initial memory
  footprint, and slightly slower large allocations.

* We have improved the way the VM searches for trusted root certificates for
  secure socket connections on Linux. First, the VM will look for trusted root
  certificates in standard locations on the file system
  (`/etc/pki/tls/certs/ca-bundle.crt` followed by `/etc/ssl/certs`), and only if
  these do not exist will it fall back on the builtin trusted root certificates.
  This behavior can be overridden on Linux with the new flags
  `--root-certs-file` and `--root-certs-cache`. The former is the path to a file
  containing the trusted root certificates, and the latter is the path to a
  directory containing root certificate files hashed using `c_rehash`.

* The VM now throws a catchable `Error` when method compilation fails. This
  allows easier debugging of syntax errors, especially when testing.  (SDK issue
  [23684](https://github.com/dart-lang/sdk/issues/23684))

### Core library changes

* `dart:core`: Remove deprecated `Resource` class.
  Use the class in `package:resource` instead.
* `dart:async`
  * `Future.wait` now catches synchronous errors and returns them in the
    returned Future.  (SDK issue
    [27249](https://github.com/dart-lang/sdk/issues/27249))
  * More aggressively returns a `Future` on `Stream.cancel` operations.
    Discourages to return `null` from `cancel`.  (SDK issue
    [26777](https://github.com/dart-lang/sdk/issues/26777))
  * Fixes a few bugs where the cancel future wasn't passed through
    transformations.
* `dart:io`
  * Added `WebSocket.addUtf8Text` to allow sending a pre-encoded text message
    without a round-trip UTF-8 conversion.  (SDK issue
    [27129](https://github.com/dart-lang/sdk/issues/27129))

### Strong Mode

* Breaking change - it is an error if a generic type parameter cannot be
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

* New feature - use `@checked` to override a method and tighten a parameter
    type (SDK issue [25578](https://github.com/dart-lang/sdk/issues/25578)).

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

* New feature - use `@virtual` to allow field overrides in strong mode
    (SDK issue [27384](https://github.com/dart-lang/sdk/issues/27384)).

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

* Breaking change - infer list and map literals from the context type as well as
    their values, consistent with generic methods and instance creation
    (SDK issue [27151](https://github.com/dart-lang/sdk/issues/27151)).

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

* `dartfmt` - upgraded to v0.2.10
    * Don't crash on annotations before parameters with trailing commas.
    * Always split enum declarations if they end in a trailing comma.
    * Add `--set-exit-if-changed` to set the exit code on a change.

* Pub
  * Pub no longer generates a `packages/` directory by default.  Instead, it
    generates a `.packages` file, called a package spec. To generate
    a `packages/` directory in addition to the package spec, use the
    `--packages-dir` flag with `pub get`, `pub upgrade`, and `pub downgrade`.
    See the [Good-bye
    symlinks](http://news.dartlang.org/2016/10/good-bye-symlinks.html) article
    for details.

## 1.19.1 - 2016-09-08

Patch release, resolves one issue:

* Dartdoc:  Fixes a bug that prevented generation of docs.
  (Dartdoc issue [1233](https://github.com/dart-lang/dartdoc/issues/1233))

## 1.19.0 - 2016-08-26

### Language changes

* The language now allows a trailing comma after the last argument of a call and
 the last parameter of a function declaration. This can make long argument or
 parameter lists easier to maintain, as commas can be left as-is when
 reordering lines. For details, see SDK issue
 [26644](https://github.com/dart-lang/sdk/issues/26644).

### Tool Changes

* `dartfmt` - upgraded to v0.2.9+1
  * Support trailing commas in argument and parameter lists.
  * Gracefully handle read-only files.
  * About a dozen other bug fixes.

* Pub
  * Added a `--no-packages-dir` flag to `pub get`, `pub upgrade`, and `pub
    downgrade`. When this flag is passed, pub will not generate a `packages/`
    directory, and will remove that directory and any symlinks to it if they
    exist. Note that this replaces the unsupported `--no-package-symlinks` flag.

  * Added the ability for packages to declare a constraint on the [Flutter][]
    SDK:

    ```yaml
    environment:
      flutter: ^0.1.2
      sdk: >=1.19.0 <2.0.0
    ```

    A Flutter constraint will only be satisfiable when pub is running in the
    context of the `flutter` executable, and when the Flutter SDK version
    matches the constraint.

  * Added `sdk` as a new package source that fetches packages from a hard-coded
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

  * `tar` files on Linux are now created with `0` as the user and group IDs.
    This fixes a crash when publishing packages while using Active Directory.

  * Fixed a bug where packages from a hosted HTTP URL were considered the same
    as packages from an otherwise-identical HTTPS URL.

  * Fixed timer formatting for timers that lasted longer than a minute.

  * Eliminate some false negatives when determining whether global executables
    are on the user's executable path.

* `dart2js`
  * `dart2dart` (aka `dart2js --output-type=dart`) has been removed (this was deprecated in Dart 1.11).

[Flutter]: https://flutter.io/

### Dart VM

*   The dependency on BoringSSL has been rolled forward. Going forward, builds
    of the Dart VM including secure sockets will require a compiler with C++11
    support. For details, see the
    [Building wiki page](https://github.com/dart-lang/sdk/wiki/Building).

### Strong Mode

*   New feature - an option to disable implicit casts
    (SDK issue [26583](https://github.com/dart-lang/sdk/issues/26583)),
    see the [documentation](https://github.com/dart-lang/dev_compiler/blob/master/doc/STATIC_SAFETY.md#disable-implicit-casts)
    for usage instructions and examples.

*   New feature - an option to disable implicit dynamic
    (SDK issue [25573](https://github.com/dart-lang/sdk/issues/25573)),
    see the [documentation](https://github.com/dart-lang/dev_compiler/blob/master/doc/STATIC_SAFETY.md#disable-implicit-dynamic)
    for usage instructions and examples.

*   Breaking change - infer generic type arguments from the
    constructor invocation arguments
    (SDK issue [25220](https://github.com/dart-lang/sdk/issues/25220)).

    ```dart
    var map = new Map<String, String>();

    // infer: Map<String, String>
    var otherMap = new Map.from(map);
    ```

*   Breaking change - infer local function return type
    (SDK issue [26414](https://github.com/dart-lang/sdk/issues/26414)).

    ```dart
    void main() {
      // infer: return type is int
      f() { return 40; }
      int y = f() + 2; // type checks
      print(y);
    }
    ```

*   Breaking change - allow type promotion from a generic type parameter
    (SDK issue [26414](https://github.com/dart-lang/sdk/issues/26965)).

    ```dart
    void fn/*<T>*/(/*=T*/ object) {
      if (object is String) {
        // Treat `object` as `String` inside this block.
        // But it will require a cast to pass it to something that expects `T`.
        print(object.substring(1));
      }
    }
    ```

* Breaking change - smarter inference for Future.then
    (SDK issue [25944](https://github.com/dart-lang/sdk/issues/25944)).
    Previous workarounds that use async/await or `.then/*<Future<SomeType>>*/`
    should no longer be necessary.

    ```dart
    // This will now infer correctly.
    Future<List<int>> t2 = f.then((_) => [3]);
    // This infers too.
    Future<int> t2 = f.then((_) => new Future.value(42));
    ```

* Breaking change - smarter inference for async functions
    (SDK issue [25322](https://github.com/dart-lang/sdk/issues/25322)).

    ```dart
    void test() async {
      List<int> x = await [4]; // was previously inferred
      List<int> y = await new Future.value([4]); // now inferred too
    }
    ```

* Breaking change - sideways casts are no longer allowed
    (SDK issue [26120](https://github.com/dart-lang/sdk/issues/26120)).

## 1.18.1 - 2016-08-02

Patch release, resolves two issues and improves performance:

* Debugger: Fixes a bug that crashes the VM
(SDK issue [26941](https://github.com/dart-lang/sdk/issues/26941))

* VM: Fixes an optimizer bug involving closures, try, and await
(SDK issue [26948](https://github.com/dart-lang/sdk/issues/26948))

* Dart2js: Speeds up generated code on Firefox
(https://codereview.chromium.org/2180533002)

## 1.18.0 - 2016-07-27

### Core library changes

* `dart:core`
  * Improved performance when parsing some common URIs.
  * Fixed bug in `Uri.resolve` (SDK issue [26804](https://github.com/dart-lang/sdk/issues/26804)).
* `dart:io`
  * Adds file locking modes `FileLock.BLOCKING_SHARED` and
    `FileLock.BLOCKING_EXCLUSIVE`.

## 1.17.1 - 2016-06-10

Patch release, resolves two issues:

* VM: Fixes a bug that caused crashes in async functions.
(SDK issue [26668](https://github.com/dart-lang/sdk/issues/26668))

* VM: Fixes a bug that caused garbage collection of reachable weak properties.
(https://codereview.chromium.org/2041413005)

## 1.17.0 - 2016-06-08

### Core library changes
* `dart:convert`
  * Deprecate `ChunkedConverter` which was erroneously added in 1.16.

* `dart:core`
  * `Uri.replace` supports iterables as values for the query parameters.
  * `Uri.parseIPv6Address` returns a `Uint8List`.

* `dart:io`
  * Added `NetworkInterface.listSupported`, which is `true` when
    `NetworkInterface.list` is supported, and `false` otherwise. Currently,
    `NetworkInterface.list` is not supported on Android.

### Tool Changes

* Pub
  * TAR files created while publishing a package on Mac OS and Linux now use a
    more portable format.

  * Errors caused by invalid arguments now print the full usage information for
    the command.

  * SDK constraints for dependency overrides are no longer considered when
    determining the total SDK constraint for a lockfile.

  * A bug has been fixed in which a lockfile was considered up-to-date when it
    actually wasn't.

  * A bug has been fixed in which `pub get --offline` would crash when a
    prerelease version was selected.

* Dartium and content shell
  * Debugging Dart code inside iframes improved, was broken.

## 1.16.1 - 2016-05-24

Patch release, resolves one issue:

* VM: Fixes a bug that caused intermittent hangs on Windows.
(SDK issue [26400](https://github.com/dart-lang/sdk/issues/26400))

## 1.16.0 - 2016-04-26

### Core library changes

* `dart:convert`
  * Added `BASE64URL` codec and corresponding `Base64Codec.urlSafe` constructor.

  * Introduce `ChunkedConverter` and deprecate chunked methods on `Converter`.

* `dart:html`

  There have been a number of **BREAKING** changes to align APIs with recent
  changes in Chrome. These include:

  * Chrome's `ShadowRoot` interface no longer has the methods `getElementById`,
    `getElementsByClassName`, and `getElementsByTagName`, e.g.,

    ```dart
    elem.shadowRoot.getElementsByClassName('clazz')
    ```

    should become:

    ```dart
    elem.shadowRoot.querySelectorAll('.clazz')
    ```

  * The `clipboardData` property has been removed from `KeyEvent`
    and `Event`. It has been moved to the new `ClipboardEvent` class, which is
    now used by `copy`, `cut`, and `paste` events.

  * The `layer` property has been removed from `KeyEvent` and
    `UIEvent`. It has been moved to `MouseEvent`.

  * The `Point get page` property has been removed from `UIEvent`.
    It still exists on `MouseEvent` and `Touch`.

  There have also been a number of other additions and removals to `dart:html`,
  `dart:indexed_db`, `dart:svg`, `dart:web_audio`, and `dart:web_gl` that
  correspond to changes to Chrome APIs between v39 and v45. Many of the breaking
  changes represent APIs that would have caused runtime exceptions when compiled
  to Javascript and run on recent Chrome releases.

* `dart:io`
  * Added `SecurityContext.alpnSupported`, which is true if a platform
    supports ALPN, and false otherwise.

### JavaScript interop

For performance reasons, a potentially **BREAKING** change was added for
libraries that use JS interop.
Any Dart file that uses `@JS` annotations on declarations (top-level functions,
classes or class members) to interop with JavaScript code will require that the
file have the annotation `@JS()` on a library directive.

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

*   Static checking of `for in` statements. These will now produce static
    warnings:

    ```dart
    // Not Iterable.
    for (var i in 1234) { ... }

    // String cannot be assigned to int.
    for (int n in <String>["a", "b"]) { ... }
    ```

### Tool Changes

* Pub
  * `pub serve` now provides caching headers that should improve the performance
    of requesting large files multiple times.

  * Both `pub get` and `pub upgrade` now have a `--no-precompile` flag that
    disables precompilation of executables and transformed dependencies.

  * `pub publish` now resolves symlinks when publishing from a Git repository.
    This matches the behavior it always had when publishing a package that
    wasn't in a Git repository.

* Dart Dev Compiler
  * The **experimental** `dartdevc` executable has been added to the SDK.

  * It will help early adopters validate the implementation and provide
    feedback. `dartdevc` **is not** yet ready for production usage.

  * Read more about the Dart Dev Compiler [here][dartdevc].

[dartdevc]: https://github.com/dart-lang/dev_compiler

## 1.15.0 - 2016-03-09

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

### Tool changes

* Dartium and content shell
  * The Chrome-based tools that ship as part of the Dart SDK – Dartium and
    content shell – are now based on Chrome version 45 (instead of Chrome 39).
  * Dart browser libraries (`dart:html`, `dart:svg`, etc) *have not* been
    updated.
    * These are still based on Chrome 39.
    * These APIs will be updated in a future release.
  * Note that there are experimental APIs which have changed in the underlying
    browser, and will not work with the older libraries.
    For example, `Element.animate`.

* `dartfmt` - upgraded to v0.2.4
  * Better handling for long collections with comments.
  * Always put member metadata annotations on their own line.
  * Indent functions in named argument lists with non-functions.
  * Force the parameter list to split if a split occurs inside a function-typed
    parameter.
  * Don't force a split for before a single named argument if the argument
    itself splits.

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

## 1.14.2 - 2016-02-10

Patch release, resolves three issues:

* VM: Fixed a code generation bug on x64.
  (SDK commit [834b3f02](https://github.com/dart-lang/sdk/commit/834b3f02b6ab740a213fd808e6c6f3269bed80e5))

* `dart:io`: Fixed EOF detection when reading some special device files.
  (SDK issue [25596](https://github.com/dart-lang/sdk/issues/25596))

* Pub: Fixed an error using hosted dependencies in SDK version 1.14.
  (Pub issue [1386](https://github.com/dart-lang/pub/issues/1386))

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
