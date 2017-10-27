## 1.1.4

* Add `@dart2js.noInline` and `@dart2js.tryInline` annotations.

## 1.1.2

* Rollback SDK constraint update for 2.0.0. No longer needed.

## 1.1.1
* Update SDK constraint to be 2.0.0 dev friendly.

## 1.1.0
* Introduce `@alwaysThrows` to declare that a function always throws
    (SDK issue [17999](https://github.com/dart-lang/sdk/issues/17999)). This
    is first available in Dart SDK 1.25.0-dev.1.0.

    ```dart
    import 'package:meta/meta.dart';

    // Without knowing that [failBigTime] always throws, it looks like this
    // function might return without returning a bool.
    bool fn(expected, actual) {
      if (expected != actual)
        failBigTime(expected, actual);
      else
        return True;
    }

    @alwaysThrows
    void failBigTime(expected, actual) {
      throw new StateError('Expected $expected, but was $actual.');
    }
    ```

## 1.0.4
* Introduce `@virtual` to allow field overrides in strong mode
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

## 1.0.3
* Introduce `@checked` to override a method and tighten a parameter
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

## 1.0.2
* Introduce `@visibleForTesting` annotation for declarations that may be referenced only in the library or in a test.

## 1.0.1
* Updated `@factory` to allow statics and methods returning `null`.

## 1.0.0
* First stable API release.

## 0.12.2
* Updated `@protected` to include implemented interfaces (linter#252).

## 0.12.1
* Fixed markdown in dartdocs.

## 0.12.0
* Introduce `@optionalTypeArgs` annotation for classes whose type arguments are to be treated as optional.

## 0.11.0
* Added new `Required` constructor with a means to specify a reason to explain why a parameter is required.

## 0.10.0
* Introduce `@factory` annotation for methods that must either be abstract or
must return a newly allocated object.
* Introduce `@literal` annotation that indicates that any invocation of a
constructor must use the keyword `const` unless one or more of the
arguments to the constructor is not a compile-time constant.

## 0.9.0
* Introduce `@protected` annotation for members that must only be called from
instance members of subclasses.
* Introduce `@required` annotation for optional parameters that should be treated
as required.
* Introduce `@mustCallSuper` annotation for methods that must be invoked by all
overriding methods.
