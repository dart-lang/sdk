// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:js_interop';

import 'package:benchmark_harness/benchmark_harness.dart';

// Static js-interop benchmarks.
//
// Type checks:
//
//     JSInterop.as.Foo     - x as Foo
//     JSInterop.as.T.Foo   - x as T, where T is Foo
//
// Type tests:
//
//     JSInterop.isA.Foo    - x.isA<Foo>()
//
// Calls.
//
//     JSInterop.call.moveFoo -
//       Repeatedly copy the same Foo (some kind of JSObject) to JavaScript and
//       back.
//
//     JSInterop.call.{inline,hoisted,implicit}3ArgsSSS
//       Passes three String arguments, using different positioning of `.toJS`
//       conversions.
//
//     JSInterop.call.{inline,hoisted,implicit}3ArgsIII
//       Similar to JSInterop.call.*ArgsSSS but passing integer Numbers instead.
//
//     JSInterop.call.inline7Args
//       Compare with JSInterop.call.inline3ArgsSSS to assess the cost of more
//       arguments.

/// Aliases for `Object.assign` with different types.
///
/// `Object.assign` with one argument returns the argument. It is a fast
/// JavaScript method that returns a JSObject.
@JS('Object')
extension type ObjectMethods(JSObject _) implements JSObject {
  @JS('assign')
  external static JSObject moveJSObject(JSObject o);

  @JS('assign')
  external static JSArray moveJSArray(JSArray o);

  @JS('assign')
  external static JSUint8Array moveJSUint8Array(JSUint8Array o);
}

// Alias for `.toString()` with different types.
//
// `x.toString()`, when called on a JSString receiver, calls
// `String.prototype.toString`, which is fast, since it returns the
// receiver. Additional arguments are ignored.
extension ToStringMethod on JSAny {
  @JS('toString')
  external JSString toString1(JSAny? a);

  @JS('toString')
  external JSString toString3SSS(JSString a, JSString b, JSString c);

  @JS('toString')
  external JSString toString3NNN(JSNumber a, JSNumber b, JSNumber c);

  // This version uses Dart primitive types which implies an implicit
  // conversion.
  @JS('toString')
  external String toString3ConvertedSSS(String a, String b, String c);

  // This version uses Dart primitive types which implies an implicit
  // conversion.
  @JS('toString')
  external String toString3ConvertedIII(int a, int b, int c);

  @JS('toString')
  external JSString toString7(
    JSAny? a1,
    JSAny? a2,
    JSAny? a3,
    JSAny? a4,
    JSAny? a5,
    JSAny? a6,
    JSAny? a7,
  );
}

extension type Date._(JSObject _) implements JSObject {
  external Date.forTimestamp(int _);
  external static int now();
}

const int N = 1000;

class Base extends BenchmarkBase {
  Base(super.name);
}

List<Object?> allJSObjects() {
  return List<Object?>.generate(N, (i) => createObject(), growable: false);
}

List<Object?> allJSAnys() {
  return allJSObjects()
    ..[1] = 123.toJS
    ..[2] = 'x'.toJS;
}

List<Object?> allJSAnyQs() {
  return allJSObjects()
    ..[0] = null
    ..[1] = 123.toJS
    ..[2] = 'x'.toJS;
}

final List<Object?> allJSNumbers = List<Object?>.generate(
  N,
  (i) => i.toJS,
  growable: false,
);

final List<Object?> allJSStrings = List<Object?>.generate(
  N,
  (i) => '$i'.toJS,
  growable: false,
);

final List<Object?> allJSUint8Array = List<Object?>.generate(
  N,
  (_) => JSUint8Array.withLength(2),
  growable: false,
);

abstract class CastsBase extends Base {
  final List<Object?> data;
  CastsBase(String name, {required this.data}) : super('JSInterop.as.$name');
}

class Casts1 extends CastsBase {
  Casts1() : super('JSObject', data: allJSObjects());

  @override
  void run() {
    for (final o in data) {
      sink = o as JSObject;
    }
  }
}

class Casts2 extends CastsBase {
  Casts2() : super('JSAny', data: allJSAnys());

  @override
  void run() {
    for (final o in data) {
      sink = o as JSAny;
    }
  }
}

class Casts3 extends CastsBase {
  Casts3() : super('JSAnyQ', data: allJSAnyQs());

  @override
  void run() {
    for (final o in data) {
      sink = o as JSAny?;
    }
  }
}

class Casts4 extends CastsBase {
  Casts4() : super('JSNumber', data: allJSNumbers);

  @override
  void run() {
    for (final o in data) {
      sink = o as JSNumber;
    }
  }
}

class Casts5 extends CastsBase {
  Casts5() : super('JSString', data: allJSStrings);

  @override
  void run() {
    for (final o in data) {
      sink = o as JSString;
    }
  }
}

class Casts6 extends CastsBase {
  Casts6() : super('JSUint8Array', data: allJSUint8Array);

  @override
  void run() {
    for (final o in data) {
      sink = o as JSUint8Array;
    }
  }
}

class CastsT<T> extends CastsBase {
  CastsT(String name, {required super.data}) : super('T.$name');

  @override
  void run() {
    for (final o in data) {
      sink = o as T;
    }
  }
}

class Calls1SSS extends Base {
  Calls1SSS() : super('JSInterop.calls.inline3ArgsSSS');

  @override
  void run() {
    String s = 'hello';
    for (int i = 0; i < N; i++) {
      // Pass in arguments with '.toJS' conversion.
      // There is potential for a compiler to hoist the conversions.
      // Implicit conversion of result of `toString3` to JSString.
      // Explicit `.toDart` conversion of result JSString to Dart String.
      sink = s = s.toJS.toString3SSS('a'.toJS, 'b'.toJS, 'c'.toJS).toDart;
    }
  }
}

class Calls1NNN extends Base {
  Calls1NNN() : super('JSInterop.calls.inline3ArgsIII');

  @override
  void run() {
    String s = 'hello';
    for (int i = 0; i < N; i++) {
      // Pass in arguments with '.toJS' conversion.
      // There is potential for a compiler to hoist the conversions.
      // Implicit conversion of result of `toString3` to JSString.
      // Explicit `.toDart` conversion of result JSString to Dart String.
      sink = s = s.toJS.toString3NNN(1.toJS, 2.toJS, 3.toJS).toDart;
    }
  }
}

class Calls2SSS extends Base {
  Calls2SSS() : super('JSInterop.calls.hoisted3ArgsSSS');

  static final _a = 'a'.toJS;
  static final _b = 'b'.toJS;
  static final _c = 'c'.toJS;

  @override
  void run() {
    String s = 'hello';
    for (int i = 0; i < N; i++) {
      // Manually hoisted argument conversions.
      // Implicit conversion of result of `toString3` to JSString.
      // Explicit `.toDart` conversion of result JSString to Dart String.
      sink = s = s.toJS.toString3SSS(_a, _b, _c).toDart;
    }
  }
}

class Calls2NNN extends Base {
  Calls2NNN() : super('JSInterop.calls.hoisted3ArgsIII');

  static final _a = 1.toJS;
  static final _b = 2.toJS;
  static final _c = 3.toJS;

  @override
  void run() {
    String s = 'hello';
    for (int i = 0; i < N; i++) {
      // Manually hoisted argument conversions.
      // Implicit conversion of result of `toString3` to JSString.
      // Explicit `.toDart` conversion of result JSString to Dart String.
      sink = s = s.toJS.toString3NNN(_a, _b, _c).toDart;
    }
  }
}

class Calls3SSS extends Base {
  Calls3SSS() : super('JSInterop.calls.implicit3ArgsSSS');

  @override
  void run() {
    String s = 'hello';
    for (int i = 0; i < N; i++) {
      // Implicit conversion of arguments and result as they have a primitive
      // type.
      sink = s = s.toJS.toString3ConvertedSSS('a', 'b', 'c');
    }
  }
}

class Calls3NNN extends Base {
  Calls3NNN() : super('JSInterop.calls.implicit3ArgsIII');

  @override
  void run() {
    String s = 'hello';
    for (int i = 0; i < N; i++) {
      // Implicit conversion of arguments and result as they have a primitive
      // type.
      sink = s = s.toJS.toString3ConvertedIII(1, 2, 3);
    }
  }
}

class Calls4 extends Base {
  Calls4() : super('JSInterop.calls.inline7Args');

  @override
  void run() {
    String s = 'hello';
    for (int i = 0; i < N; i++) {
      sink = s = s.toJS
          .toString7(
            '1'.toJS,
            '2'.toJS,
            '3'.toJS,
            '4'.toJS,
            '5'.toJS,
            '6'.toJS,
            '7'.toJS,
          )
          .toDart;
    }
  }
}

class Calls5 extends Base {
  Calls5() : super('JSInterop.calls.moveJSObject');

  static final _o = JSObject();

  @override
  void run() {
    JSObject o = _o;
    for (int i = 0; i < N; i++) {
      // Implicit conversion of result to JSObject.
      sink = o = ObjectMethods.moveJSObject(o);
    }
  }
}

class Calls6 extends Base {
  Calls6() : super('JSInterop.calls.moveJSArray');

  static final _o = JSArray.withLength(2);

  @override
  void run() {
    JSArray o = _o;
    for (int i = 0; i < N; i++) {
      // Implicit conversion of result to JSArray.
      sink = o = ObjectMethods.moveJSArray(o);
    }
  }
}

class Calls7 extends Base {
  Calls7() : super('JSInterop.calls.moveJSUint8Array');

  static final _o = JSUint8Array.withLength(2);

  @override
  void run() {
    JSUint8Array o = _o;
    for (int i = 0; i < N; i++) {
      // Implicit conversion of result to JSUint8Array.
      sink = o = ObjectMethods.moveJSUint8Array(o);
    }
  }
}

List<JSAny?> _objects() => List<JSAny?>.generate(
  N,
  (i) => switch (i % 7) {
    0 => JSObject(),
    1 => i.toJS,
    2 => JSArray(),
    3 => '$i'.toJS,
    4 => Date.forTimestamp(Date.now()),
    5 => null,
    6 => JSUint8Array.withLength(2),
    int() => throw StateError('unexpected: $i'),
  },
  growable: false,
);

abstract class IsABase extends Base {
  IsABase(String name) : super('JSInterop.isA.$name');

  final List<JSAny?> objects = _objects();
}

class IsA1 extends IsABase {
  IsA1() : super('JSObject');

  @override
  void run() {
    for (final o in objects) {
      sink = o.isA<JSObject>();
    }
  }
}

class IsA2 extends IsABase {
  IsA2() : super('JSAny');

  @override
  void run() {
    for (final o in objects) {
      sink = o.isA<JSAny>();
    }
  }
}

class IsA3 extends IsABase {
  IsA3() : super('JSString');

  @override
  void run() {
    for (final o in objects) {
      sink = o.isA<JSString>();
    }
  }
}

class IsA4 extends IsABase {
  IsA4() : super('JSArray');

  @override
  void run() {
    for (final o in objects) {
      sink = o.isA<JSArray>();
    }
  }
}

class IsA5 extends IsABase {
  IsA5() : super('Date');

  @override
  void run() {
    for (final o in objects) {
      sink = o.isA<Date>();
    }
  }
}

class IsA6 extends IsABase {
  IsA6() : super('DateQ');

  @override
  void run() {
    for (final o in objects) {
      sink = o.isA<Date?>();
    }
  }
}

class IsA7 extends IsABase {
  IsA7() : super('JSUint8Array');

  @override
  void run() {
    for (final o in objects) {
      sink = o.isA<JSUint8Array>();
    }
  }
}

/// Returns a new JSObject, but with a type that is hard for an optimizing
/// compiler to know exactly.
Object? createObject() {
  if (inscrutableTrue) return JSObject();
  if (inscrutableTrue) return 123.toJS;
  if (inscrutableTrue) return 'x'.toJS;
  if (inscrutableTrue) return true.toJS;
  if (inscrutableTrue) return StringBuffer();
  return null;
}

bool get inscrutableTrue => DateTime.now().millisecondsSinceEpoch > 42;

Object? sink;

void main() {
  print(Date.forTimestamp(Date.now()));

  final benchmarks = [
    IsA1(),
    IsA2(),
    IsA3(),
    IsA4(),
    IsA5(),
    IsA6(),
    IsA7(),

    Calls1SSS(),
    Calls1NNN(),
    Calls2SSS(),
    Calls2NNN(),
    Calls3SSS(),
    Calls3NNN(),
    Calls4(),
    Calls5(),
    Calls6(),
    Calls7(),

    Casts1(),
    Casts2(),
    Casts3(),
    Casts4(),
    Casts5(),
    Casts6(),

    CastsT<JSObject>('JSObject', data: allJSObjects()),
    CastsT<JSAny>('JSAny', data: allJSAnys()),
    CastsT<JSAny?>('JSAnyQ', data: allJSAnyQs()),
    CastsT<JSNumber>('JSNumber', data: allJSNumbers),
    CastsT<JSString>('JSString', data: allJSStrings),
    CastsT<JSUint8Array>('JSUint8Array', data: allJSUint8Array),
  ];

  // Warmup all benchmarks to ensure JIT compilers see full polymorphism.
  for (var benchmark in benchmarks) {
    benchmark.setup();
    benchmark.run();
    benchmark.run();
    if (sink == null) throw StateError('unexpected');
  }

  for (var benchmark in benchmarks) {
    benchmark.run();
  }

  for (var benchmark in benchmarks) {
    benchmark.report();
  }
}
