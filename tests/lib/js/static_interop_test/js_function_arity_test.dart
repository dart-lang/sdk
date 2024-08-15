// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Requirements=checked-implicit-downcasts

import 'dart:js_interop';

import 'package:expect/expect.dart';
import 'package:expect/variations.dart';

const isDDC = const bool.fromEnvironment('dart.library._ddc_only');
const isDart2JS = const bool.fromEnvironment('dart.tool.dart2js');
const soundNullSafety = !unsoundNullSafety;

@JS('call')
external String _call(JSFunction f, JSArray<JSAny?> args);

String call(JSFunction f, List<Object?> args) =>
    _call(f, args.map((e) => e?.jsify()).toList().toJS);

@JS()
external void eval(String code);

// Zero.
String zeroArgs() => '0';
String zeroArgsThis([JSObject? this_]) => '0';

// One.
String oneRequired(String arg1) => arg1;
String oneOptional([String arg1 = 'default']) => '$arg1';
String oneOptionalThis(JSObject? this_, [String arg1 = 'default']) => '$arg1';

// Two.
String twoRequired(String arg1, String? arg2) => '$arg1$arg2';
String oneRequiredOneOptional(String arg1, [String? arg2 = 'default']) =>
    '$arg1$arg2';
String twoOptional([String arg1 = 'default', String? arg2 = 'default']) =>
    '$arg1$arg2';
String oneRequiredOneOptionalThis(JSObject? this_, String arg1,
        [String? arg2 = 'default']) =>
    '$arg1$arg2';

// Three.
String threeRequired(String arg1, String? arg2, String arg3) =>
    '$arg1$arg2$arg3';
String twoRequiredOneOptional(String arg1, String? arg2,
        [String arg3 = 'default']) =>
    '$arg1$arg2$arg3';
String oneRequiredTwoOptional(String arg1,
        [String? arg2 = 'default', String arg3 = 'default']) =>
    '$arg1$arg2$arg3';
String threeOptional(
        [String arg1 = 'default',
        String? arg2 = 'default',
        String arg3 = 'default']) =>
    '$arg1$arg2$arg3';
String threeOptionalThis(
        [JSObject? this_,
        String arg1 = 'default',
        String? arg2 = 'default',
        String arg3 = 'default']) =>
    '$arg1$arg2$arg3';

// Four.
String fourRequired(String arg1, String? arg2, String arg3, String arg4) =>
    '$arg1$arg2$arg3$arg4';
String threeRequiredOneOptional(String arg1, String? arg2, String arg3,
        [String arg4 = 'default']) =>
    '$arg1$arg2$arg3$arg4';
String twoRequiredTwoOptional(String arg1, String? arg2,
        [String arg3 = 'default', String arg4 = 'default']) =>
    '$arg1$arg2$arg3$arg4';
String oneRequiredThreeOptional(String arg1,
        [String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default']) =>
    '$arg1$arg2$arg3$arg4';
String fourOptional(
        [String arg1 = 'default',
        String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default']) =>
    '$arg1$arg2$arg3$arg4';
String oneRequiredThreeOptionalThis(JSObject? this_, String arg1,
        [String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default']) =>
    '$arg1$arg2$arg3$arg4';

// Five.
String fiveRequired(
        String arg1, String? arg2, String arg3, String arg4, String arg5) =>
    '$arg1$arg2$arg3$arg4$arg5';
String fourRequiredOneOptional(
        String arg1, String? arg2, String arg3, String arg4,
        [String arg5 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5';
String threeRequiredTwoOptional(String arg1, String? arg2, String arg3,
        [String arg4 = 'default', String arg5 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5';
String twoRequiredThreeOptional(String arg1, String? arg2,
        [String arg3 = 'default',
        String arg4 = 'default',
        String arg5 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5';
String oneRequiredFourOptional(String arg1,
        [String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default',
        String arg5 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5';
String fiveOptional(
        [String arg1 = 'default',
        String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default',
        String arg5 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5';
String threeRequiredTwoOptionalThis(
        JSObject? this_, String arg1, String? arg2, String arg3,
        [String arg4 = 'default', String arg5 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5';

// Six.
String sixRequired(String arg1, String? arg2, String arg3, String arg4,
        String arg5, String arg6) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';
String fiveRequiredOneOptional(
        String arg1, String? arg2, String arg3, String arg4, String arg5,
        [String arg6 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';
String fourRequiredTwoOptional(
        String arg1, String? arg2, String arg3, String arg4,
        [String arg5 = 'default', String arg6 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';
String threeRequiredThreeOptional(String arg1, String? arg2, String arg3,
        [String arg4 = 'default',
        String arg5 = 'default',
        String arg6 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';
String twoRequiredFourOptional(String arg1, String? arg2,
        [String arg3 = 'default',
        String arg4 = 'default',
        String arg5 = 'default',
        String arg6 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';
String oneRequiredFiveOptional(String arg1,
        [String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default',
        String arg5 = 'default',
        String arg6 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';
String sixOptional(
        [String arg1 = 'default',
        String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default',
        String arg5 = 'default',
        String arg6 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';
String sixOptionalThis(
        [JSObject? this_,
        String arg1 = 'default',
        String? arg2 = 'default',
        String arg3 = 'default',
        String arg4 = 'default',
        String arg5 = 'default',
        String arg6 = 'default']) =>
    '$arg1$arg2$arg3$arg4$arg5$arg6';

void testZero() {
  // Arity tests.
  Expect.equals(call(zeroArgs.toJS, []), '0');
  Expect.equals(call(zeroArgs.toJS, ['extra']), '0');
  Expect.equals(call(zeroArgs.toJS, [1.0]), '0');
  Expect.equals(call(zeroArgsThis.toJSCaptureThis, []), '0');
  Expect.equals(call(zeroArgs.toJSCaptureThis, []), '0');

  // Conversion round-trip test.
  final tearOff = zeroArgs;
  Expect.identical(tearOff, tearOff.toJS.toDart);
  final tearOffThis = zeroArgsThis;
  Expect.identical(tearOffThis, tearOffThis.toJSCaptureThis.toDart);

  // Avoid rewrapping test.
  if (isDDC || isDart2JS) {
    Expect.throwsArgumentError(() => (zeroArgs.toJS as String Function()).toJS);
    Expect.throwsArgumentError(() =>
        (zeroArgsThis.toJSCaptureThis as String Function()).toJSCaptureThis);
  }
}

void testOne() {
  // Type tests.
  Expect.throws(() => call(oneRequired.toJS, [0]));
  Expect.throwsWhen(soundNullSafety, () => call(oneOptional.toJS, [null]));
  Expect.throwsWhen(
      soundNullSafety, () => call(oneOptional.toJS, ['undefined']));
  Expect.throws(() => call(oneOptionalThis.toJSCaptureThis, [true]));

  // Arity tests.
  Expect.throws(() => call(oneRequired.toJS, []));
  Expect.equals(call(oneRequired.toJS, ['a']), 'a');
  Expect.equals(call(oneRequired.toJS, ['a', 'extra']), 'a');
  Expect.equals(call(oneOptional.toJS, []), 'default');
  Expect.equals(call(oneOptional.toJS, ['a']), 'a');
  Expect.equals(call(oneOptional.toJS, ['a', 'extra']), 'a');
  Expect.equals(call(oneOptionalThis.toJSCaptureThis, ['a']), 'a');
  if (soundNullSafety) {
    // `this` can be null or a JSObject depending on strict mode, which in turn
    // depends on the compiler. To make this consistent, only run when sound
    // null safety is enabled.
    Expect.throws(() => call(oneRequired.toJSCaptureThis, []));
  }

  // Function subtyping tests.
  Expect.equals(call((oneOptional as String Function()).toJS, []), 'default');
  // Throws away the additional args due to the static typing.
  Expect.equals(
      call((oneOptional as String Function()).toJS, ['a']), 'default');
  Expect.equals(
      call((oneOptionalThis as String Function(JSObject?)).toJSCaptureThis,
          ['a']),
      'default');

  // Conversion round-trip test.
  final tearOff = oneRequired;
  Expect.identical(tearOff, tearOff.toJS.toDart);
  final tearOffThis = oneOptionalThis;
  Expect.identical(tearOffThis, tearOffThis.toJSCaptureThis.toDart);

  // Avoid rewrapping test.
  if (isDDC || isDart2JS) {
    Expect.throwsArgumentError(
        () => (oneOptional.toJS as String Function()).toJS);
    Expect.throwsArgumentError(() =>
        (oneOptionalThis.toJSCaptureThis as String Function(JSObject?))
            .toJSCaptureThis);
  }
}

void testTwo() {
  // Type tests.
  Expect.throws(() => call(twoOptional.toJS, [false, 'b']));
  Expect.throws(() => call(twoOptional.toJS, ['a', 1.0]));
  Expect.throwsWhen(soundNullSafety,
      () => call(oneRequiredOneOptional.toJS, ['undefined', 'b']));
  Expect.throws(() => call(oneRequiredOneOptional.toJS, ['a', true]));
  Expect.throws(() => call(twoRequired.toJS, [0, 'b']));
  Expect.throws(() => call(twoRequired.toJS, ['a', 0]));
  Expect.throws(() => call(oneRequiredOneOptional.toJSCaptureThis, [0]));

  // Arity tests.
  Expect.throws(() => call(twoRequired.toJS, []));
  Expect.throws(() => call(twoRequired.toJS, ['a']));
  Expect.equals(call(twoRequired.toJS, ['a', 'b']), 'ab');
  Expect.equals(call(twoRequired.toJS, ['a', 'b', 'extra']), 'ab');
  Expect.throws(() => call(oneRequiredOneOptional.toJS, []));
  Expect.equals(call(oneRequiredOneOptional.toJS, ['a']), 'adefault');
  Expect.equals(call(oneRequiredOneOptional.toJS, ['a', 'b']), 'ab');
  Expect.equals(call(oneRequiredOneOptional.toJS, ['a', 'b', 'extra']), 'ab');
  Expect.equals(call(twoOptional.toJS, []), 'defaultdefault');
  Expect.equals(call(twoOptional.toJS, ['a']), 'adefault');
  Expect.equals(call(twoOptional.toJS, ['a', 'b']), 'ab');
  Expect.equals(call(twoOptional.toJS, ['a', 'b', 'extra']), 'ab');
  Expect.equals(
      call(oneRequiredOneOptionalThis.toJSCaptureThis, ['a', 'b', 'extra']),
      'ab');
  Expect.equals(
      call(oneRequiredOneOptionalThis.toJSCaptureThis, ['a']), 'adefault');

  // Function subtyping tests.
  // TODO(55881): dart2wasm's type conversions are based on the static type,
  // whereas DDC and dart2js only do type checks based on the runtime type. We
  // can't replicate dart2Wasm's behavior in DDC and dart2js as it would require
  // a new Dart trampoline for every function, so there's a discrepancy when we
  // use a static type with different parameter types.
  var closure = () =>
      call((twoRequired as String Function(String, String)).toJS, ['a', null]);
  if (isDDC || isDart2JS) {
    Expect.equals(closure(), 'anull');
  } else {
    Expect.throws(closure);
  }
  Expect.throws(
      () => call((oneRequiredOneOptional as String Function(String)).toJS, []));
  Expect.equals(
      call((oneRequiredOneOptional as String Function(String)).toJS, ['a']),
      'adefault');
  Expect.equals(
      call((oneRequiredOneOptional as String Function(String)).toJS, ['a', 0]),
      'adefault');
  Expect.equals(
      call((twoOptional as String Function()).toJS, []), 'defaultdefault');
  Expect.equals(
      call((twoOptional as String Function()).toJS, ['a']), 'defaultdefault');
  Expect.equals(call((twoOptional as String Function([String])).toJS, []),
      'defaultdefault');
  Expect.equals(
      call((twoOptional as String Function([String])).toJS, ['a']), 'adefault');
  Expect.equals(
      call((twoOptional as String Function([String])).toJS, ['a', false]),
      'adefault');
  Expect.equals(
      call(
          (oneRequiredOneOptionalThis as String Function(JSObject?, String))
              .toJSCaptureThis,
          ['a', 'b']),
      'adefault');

  // `undefined` tests.
  Expect.equals(call(twoRequired.toJS, ['a', 'undefined']), 'anull');
  // TODO(55884): DDC lowers function with defaults to use the JS default
  // argument syntax, which means passing `undefined` results in DDC replacing
  // it with the default, instead of keeping it as `undefined`.
  Expect.equals(call(oneRequiredOneOptional.toJS, ['a', 'undefined']),
      isDDC ? 'adefault' : 'anull');
  Expect.equals(
      call(twoOptional.toJS, ['a', 'undefined']), isDDC ? 'adefault' : 'anull');

  // Conversion round-trip test.
  final tearOff = twoRequired;
  Expect.identical(tearOff, tearOff.toJS.toDart);
  final tearOffThis = oneRequiredOneOptionalThis;
  Expect.identical(tearOffThis, tearOffThis.toJSCaptureThis.toDart);

  // Avoid rewrapping test.
  if (isDDC || isDart2JS) {
    Expect.throwsArgumentError(
        () => (oneRequiredOneOptional.toJS as String Function(String)).toJS);
    Expect.throwsArgumentError(() => (oneRequiredOneOptionalThis.toJSCaptureThis
            as String Function(JSObject?, String))
        .toJSCaptureThis);
  }
}

// To avoid making this test unreadably long, the remaining tests choose a small
// subset of all possible tests for general validation.
void testThree() {
  // Type tests.
  Expect.throws(() => call(threeRequired.toJS, [0, 'b', 'c']));
  Expect.throws(() => call(oneRequiredTwoOptional.toJS, ['a', false]));
  Expect.throws(() => call(threeOptionalThis.toJSCaptureThis, [true]));

  // Arity tests.
  Expect.equals(call(twoRequiredOneOptional.toJS, ['a', 'b']), 'abdefault');
  Expect.throws(() => call(oneRequiredTwoOptional.toJS, []));
  Expect.equals(
      call(threeOptionalThis.toJSCaptureThis, ['a', 'b']), 'abdefault');

  // Function subtyping tests.
  var closure = () => call(
      (twoRequiredOneOptional as String Function(String, String)).toJS,
      ['a', null, 'c']);
  if (isDDC || isDart2JS) {
    Expect.equals(closure(), 'anulldefault');
  } else {
    Expect.throws(closure);
  }
  Expect.equals(
      call((threeOptional as String Function([String])).toJS, ['a', 0, true]),
      'adefaultdefault');
  Expect.equals(
      call(
          (threeOptionalThis as String Function([JSObject?, String, String?]))
              .toJSCaptureThis,
          ['a', 'b', false]),
      'abdefault');

  // `undefined` tests.
  Expect.equals(call(threeOptional.toJS, ['a', 'undefined']),
      isDDC ? 'adefaultdefault' : 'anulldefault');

  // Conversion round-trip test.
  final tearOff = threeRequired;
  Expect.identical(tearOff, tearOff.toJS.toDart);
  final tearOffThis = threeOptionalThis;
  Expect.identical(tearOffThis, tearOffThis.toJSCaptureThis.toDart);

  // Avoid rewrapping test.
  if (isDDC || isDart2JS) {
    Expect.throwsArgumentError(() =>
        (twoRequiredOneOptional.toJS as String Function(String, String?)).toJS);
    Expect.throwsArgumentError(() =>
        (threeOptionalThis.toJSCaptureThis as String Function(JSObject?))
            .toJSCaptureThis);
  }
}

void testFour() {
  // Type tests.
  Expect.throws(
      () => call(threeRequiredOneOptional.toJS, ['a', 'b', 'c', true]));
  Expect.throws(() => call(oneRequiredThreeOptional.toJS, [false]));
  if (soundNullSafety) {
    // `this` can be null or a JSObject depending on strict mode, which in turn
    // depends on the compiler. To make this consistent, only run when sound
    // null safety is enabled.
    Expect.throws(() => call(oneRequiredThreeOptional.toJSCaptureThis, ['a']));
  }

  // Arity tests.
  Expect.equals(call(fourRequired.toJS, ['a', 'b', 'c', 'd', false]), 'abcd');
  Expect.equals(call(fourOptional.toJS, ['a']), 'adefaultdefaultdefault');
  Expect.equals(call(oneRequiredThreeOptionalThis.toJSCaptureThis, ['a', 'b']),
      'abdefaultdefault');

  // Function subtyping tests.
  final closure = () => call(
      (threeRequiredOneOptional as String Function(String, String, String))
          .toJS,
      ['a', null, 'c']);
  if (isDDC || isDart2JS) {
    Expect.equals(closure(), 'anullcdefault');
  } else {
    Expect.throws(closure);
  }
  Expect.equals(
      call(
          (twoRequiredTwoOptional as String Function(String, String?, [String]))
              .toJS,
          ['a', null]),
      'anulldefaultdefault');
  Expect.equals(
      call(
          (oneRequiredThreeOptionalThis as String Function(JSObject?, String))
              .toJSCaptureThis,
          ['a', 'b']),
      'adefaultdefaultdefault');

  // `undefined` tests.
  Expect.equals(call(oneRequiredThreeOptional.toJS, ['a', 'undefined', 'c']),
      isDDC ? 'adefaultcdefault' : 'anullcdefault');

  // Conversion round-trip test.
  final tearOff = fourRequired;
  Expect.identical(tearOff, tearOff.toJS.toDart);
  final tearOffThis = oneRequiredThreeOptionalThis;
  Expect.identical(tearOffThis, tearOffThis.toJSCaptureThis.toDart);

  // Avoid rewrapping test.
  if (isDDC || isDart2JS) {
    Expect.throwsArgumentError(
        () => (oneRequiredThreeOptional.toJS as String Function(String)).toJS);
    Expect.throwsArgumentError(() => (oneRequiredThreeOptionalThis
            .toJSCaptureThis as String Function(JSObject?, String))
        .toJSCaptureThis);
  }
}

void testFive() {
  // Type tests.
  Expect.throws(() => call(twoRequiredThreeOptional.toJS, ['a', 0]));
  Expect.throws(() => call(fiveOptional.toJS, [false]));
  Expect.throws(() =>
      call(threeRequiredTwoOptionalThis.toJSCaptureThis, ['a', 'b', 1.0]));

  // Arity tests.
  Expect.equals(call(fiveRequired.toJS, ['a', 'b', 'c', 'd', 'e', 0]), 'abcde');
  Expect.equals(call(fourRequiredOneOptional.toJS, ['a', null, 'c', 'd']),
      'anullcddefault');
  Expect.equals(
      call(threeRequiredTwoOptionalThis.toJSCaptureThis, ['a', 'b', 'c', 'd']),
      'abcddefault');

  // Function subtyping tests.
  final closure = () => call(
      (threeRequiredTwoOptional as String Function(String, String, String,
              [String]))
          .toJS,
      ['a', null, 'c']);
  if (isDDC || isDart2JS) {
    Expect.equals(closure(), 'anullcdefaultdefault');
  } else {
    Expect.throws(closure);
  }
  Expect.equals(
      call(
          (twoRequiredThreeOptional as String Function(String, String?,
                  [String]))
              .toJS,
          ['a', null, 'c']),
      'anullcdefaultdefault');
  Expect.equals(
      call(
          (threeRequiredTwoOptionalThis as String Function(
                  JSObject?, String, String?, String))
              .toJSCaptureThis,
          ['a', 'b', 'c', 'd']),
      'abcdefaultdefault');

  // `undefined` tests.
  Expect.equals(
      call(oneRequiredFourOptional.toJS, ['a', 'undefined', 'c', 'd', 'e']),
      isDDC ? 'adefaultcde' : 'anullcde');

  // Conversion round-trip test.
  final tearOff = fiveRequired;
  Expect.identical(tearOff, tearOff.toJS.toDart);
  final tearOffThis = threeRequiredTwoOptionalThis;
  Expect.identical(tearOffThis, tearOffThis.toJSCaptureThis.toDart);

  // Avoid rewrapping test.
  if (isDDC || isDart2JS) {
    Expect.throwsArgumentError(() =>
        (twoRequiredThreeOptional.toJS as String Function(String, String?))
            .toJS);
    Expect.throwsArgumentError(() =>
        (threeRequiredTwoOptionalThis.toJSCaptureThis as String Function(
                JSObject?, String, String?, String))
            .toJSCaptureThis);
  }
}

// DDC and dart2js should use either a `dcall` or `Function.apply` for this.
void testSix() {
  // Type tests.
  Expect.throws(() => call(sixRequired.toJS, ['a', 'b', 0.0, 'd', 'e', 'f']));
  Expect.throws(() => call(threeRequiredThreeOptional.toJS, ['undefined']));
  Expect.throwsWhen(
      soundNullSafety, () => call(sixOptionalThis.toJSCaptureThis, [null]));

  // Arity tests.
  // Verify that we appropriately truncate arguments even though we don't have
  // a special lowering for six arguments in DDC and dart2js.
  Expect.equals(
      call(fourRequiredTwoOptional.toJS, ['a', 'b', 'c', 'd', 'e', 'f', 0]),
      'abcdef');
  Expect.throws(() => call(twoRequiredFourOptional.toJS, []));
  Expect.equals(
      call(sixOptionalThis.toJSCaptureThis, ['a', 'b', 'c', 'd', 'e', 'f', 0]),
      'abcdef');

  // Function subtyping tests.
  var closure = () => call(
      (fiveRequiredOneOptional as String Function(
              String, String, String, String, String))
          .toJS,
      ['a', null, 'c', 'd', 'e', 'f']);
  if (isDDC || isDart2JS) {
    Expect.equals(closure(), 'anullcdedefault');
  } else {
    Expect.throws(closure);
  }
  Expect.equals(
      call((oneRequiredFiveOptional as String Function(String, [String?])).toJS,
          ['a', 'b', 0, 0.0, false]),
      'abdefaultdefaultdefaultdefault');
  Expect.equals(
      call((sixOptionalThis as String Function()).toJSCaptureThis,
          [true, 0, 0.0]),
      'defaultdefaultdefaultdefaultdefaultdefault');

  // `undefined` tests.
  Expect.equals(call(sixOptional.toJS, ['a', 'undefined', 'c', 'd', 'e']),
      isDDC ? 'adefaultcdedefault' : 'anullcdedefault');

  // Conversion round-trip test.
  final tearOff = sixRequired;
  Expect.identical(tearOff, tearOff.toJS.toDart);
  final tearOffThis = sixOptionalThis;
  Expect.identical(tearOffThis, tearOffThis.toJSCaptureThis.toDart);

  // Avoid rewrapping test.
  if (isDDC || isDart2JS) {
    Expect.throwsArgumentError(
        () => (sixOptional.toJS as String Function()).toJS);
    Expect.throwsArgumentError(() =>
        (sixOptionalThis.toJSCaptureThis as String Function(JSObject?))
            .toJSCaptureThis);
  }
}

void main() {
  eval('''
    self.call = function(f, args) {
      var convert = function(arg) {
        return arg == 'undefined' ? undefined : arg;
      };
      return f.apply(null, args.map((e) => convert(e)));
    };
  ''');
  testZero();
  testOne();
  testTwo();
  testThree();
  testFour();
  testFive();
  testSix();
}
