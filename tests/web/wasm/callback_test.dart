// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:_wasm';
import 'dart:js_util';

import 'package:expect/expect.dart';
import 'package:js/js.dart';

@JS()
external void eval(String code);

typedef SumTwoPositionalFun = String Function(String a, String b);
typedef SumOnePositionalAndOneOptionalFun = String Function(String a,
    [String? b]);
typedef SumTwoOptionalFun = String Function([String? a, String? b]);
typedef SumOnePositionalAndOneOptionalNonNullFun = String Function(String a,
    [String b]);
typedef SumTwoOptionalNonNullFun = String Function([String a, String b]);

@JS()
@staticInterop
class DartFromJSCallbackHelper {
  external factory DartFromJSCallbackHelper.factory(
      SumTwoPositionalFun sumTwoPositional,
      SumOnePositionalAndOneOptionalFun sumOnePositionalOneOptional,
      SumTwoOptionalFun sumTwoOptional,
      SumOnePositionalAndOneOptionalNonNullFun
          sumOnePositionalAndOneOptionalNonNull,
      SumTwoOptionalNonNullFun sumTwoOptionalNonNull);
}

extension DartFromJSCallbackHelperMethods on DartFromJSCallbackHelper {
  external String doSum1();
  external String doSum2(String a, String b);
  external String doSum3(Object summer);

  external String doSumOnePositionalAndOneOptionalA(String a);
  external String doSumOnePositionalAndOneOptionalB(String a, String b);
  external String doSumTwoOptionalA();
  external String doSumTwoOptionalB(String a);
  external String doSumTwoOptionalC(String a, String b);

  external String doSumOnePositionalAndOneOptionalANonNull(String a);
  external String doSumOnePositionalAndOneOptionalBNonNull(String a, String b);
  external String doSumTwoOptionalANonNull();
  external String doSumTwoOptionalBNonNull(String a);
  external String doSumTwoOptionalCNonNull(String a, String b);
}

String sumTwoPositional(String a, String b) {
  return a + b;
}

String sumOnePositionalAndOneOptional(String a, [String? b]) {
  return a + (b ?? 'bar');
}

String sumTwoOptional([String? a, String? b]) {
  return (a ?? 'foo') + (b ?? 'bar');
}

String sumOnePositionalAndOneOptionalNonNull(String a, [String b = 'bar']) {
  return a + b;
}

String sumTwoOptionalNonNull([String a = 'foo', String b = 'bar']) {
  return a + b;
}

void staticInteropCallbackTest() {
  eval(r'''
    globalThis.DartFromJSCallbackHelper = function(
        sumTwoPositional, sumOnePositionalOneOptional, sumTwoOptional,
        sumOnePositionalAndOneOptionalNonNull, sumTwoOptionalNonNull) {
      this.a = 'hello ';
      this.b = 'world!';
      this.sum = null;
      this.sumTwoPositional = sumTwoPositional;
      this.sumOnePositionalOneOptional = sumOnePositionalOneOptional;
      this.sumTwoOptional = sumTwoOptional;
      this.sumOnePositionalAndOneOptionalNonNull = sumOnePositionalAndOneOptionalNonNull;
      this.sumTwoOptionalNonNull = sumTwoOptionalNonNull;
      this.doSum1 = () => {
        return this.sumTwoPositional(this.a, this.b);
      }
      this.doSum2 = (a, b) => {
        return this.sumTwoPositional(a, b);
      }
      this.doSum3 = (summer) => {
        return summer(this.a, this.b);
      }
      this.doSumOnePositionalAndOneOptionalA = (a) => {
        return sumOnePositionalOneOptional(a);
      }
      this.doSumOnePositionalAndOneOptionalB = (a, b) => {
        return sumOnePositionalOneOptional(a, b);
      }
      this.doSumTwoOptionalA = () => {
        return sumTwoOptional();
      }
      this.doSumTwoOptionalB = (a) => {
        return sumTwoOptional(a);
      }
      this.doSumTwoOptionalC = (a, b) => {
        return sumTwoOptional(a, b);
      }
      this.doSumOnePositionalAndOneOptionalANonNull = (a) => {
        return sumOnePositionalAndOneOptionalNonNull(a);
      }
      this.doSumOnePositionalAndOneOptionalBNonNull = (a, b) => {
        return sumOnePositionalAndOneOptionalNonNull(a, b);
      }
      this.doSumTwoOptionalANonNull = () => {
        return sumTwoOptionalNonNull();
      }
      this.doSumTwoOptionalBNonNull = (a) => {
        return sumTwoOptionalNonNull(a);
      }
      this.doSumTwoOptionalCNonNull = (a, b) => {
        return sumTwoOptionalNonNull(a, b);
      }

    }
  ''');

  final helper = DartFromJSCallbackHelper.factory(
      allowInterop<SumTwoPositionalFun>(sumTwoPositional),
      allowInterop<SumOnePositionalAndOneOptionalFun>(
          sumOnePositionalAndOneOptional),
      allowInterop<SumTwoOptionalFun>(sumTwoOptional),
      allowInterop<SumOnePositionalAndOneOptionalNonNullFun>(
          sumOnePositionalAndOneOptionalNonNull),
      allowInterop<SumTwoOptionalNonNullFun>(sumTwoOptionalNonNull));

  Expect.equals('hello world!', helper.doSum1());
  Expect.equals('foobar', helper.doSum2('foo', 'bar'));
  Expect.equals('hello world!',
      helper.doSum3(allowInterop<SumTwoPositionalFun>((a, b) => a + b)));

  Expect.equals('foobar', helper.doSumOnePositionalAndOneOptionalA('foo'));
  Expect.equals(
      'foobar', helper.doSumOnePositionalAndOneOptionalB('foo', 'bar'));
  Expect.equals('foobar', helper.doSumTwoOptionalA());
  Expect.equals('foobar', helper.doSumTwoOptionalB('foo'));
  Expect.equals('foobar', helper.doSumTwoOptionalC('foo', 'bar'));

  Expect.equals(
      'foobar', helper.doSumOnePositionalAndOneOptionalANonNull('foo'));
  Expect.equals(
      'foobar', helper.doSumOnePositionalAndOneOptionalBNonNull('foo', 'bar'));
  Expect.equals('foobar', helper.doSumTwoOptionalANonNull());
  Expect.equals('foobar', helper.doSumTwoOptionalBNonNull('foo'));
  Expect.equals('foobar', helper.doSumTwoOptionalCNonNull('foo', 'bar'));
}

typedef NoArgsFun = String Function();
typedef OneArgFun = String Function(String arg);
typedef OnePositionalAndOneOptionalArgsFun = String Function(String arg,
    [String arg2]);
typedef TwoOptionalArgsFun = String Function([String arg, String arg2]);

class TornOffClass {
  String noArgs() {
    return 'foo';
  }

  String oneArg(String arg) {
    return arg;
  }

  String onePositionalAndOneOptionalArgs(String arg, [String arg2 = 'bar']) {
    return arg + arg2;
  }

  String twoOptionalArgs([String arg = 'foo', String? arg2]) {
    return arg + (arg2 ?? '');
  }
}

typedef OneArgFunB = String Function(double arg);
typedef OnePositionalAndOneOptionalArgsFunB = String Function(double arg,
    [String arg2]);
typedef TwoOptionalArgsFunB = String Function([double arg, String arg2]);

class GenericTornOffClass<T, V> {
  String noArgs() {
    return 'foo';
  }

  String oneArg(T arg) {
    return '$arg';
  }

  String onePositionalAndOneOptionalArgs(T arg, [V? arg2]) {
    return '$arg $arg2';
  }

  String twoOptionalArgs([T? arg, V? arg2]) {
    return '$arg $arg2';
  }
}

void allowInteropCallbackTest() {
  eval(r'''
    globalThis.doSum1 = function(summer) {
      return summer('foo', 'bar');
    }
    globalThis.doSum2 = function(a, b) {
      return globalThis.summer(a, b);
    }
    globalThis.doSumOnePositionalAndOneOptionalA = function(a) {
      return summer(a);
    }
    globalThis.doSumOnePositionalAndOneOptionalB = function(a, b) {
      return summer(a, b);
    }
    globalThis.doSumTwoOptionalA = function() {
      return summer();
    }
    globalThis.doSumTwoOptionalB = function(a) {
      return summer(a);
    }
    globalThis.doSumTwoOptionalC = function(a, b) {
      return summer(a, b);
    }
    globalThis.doSumOnePositionalAndOneOptionalANonNull = function(a) {
      return summer(a);
    }
    globalThis.doSumOnePositionalAndOneOptionalBNonNull = function(a, b) {
      return summer(a, b);
    }
    globalThis.doSumTwoOptionalANonNull = function() {
      return summer();
    }
    globalThis.doSumTwoOptionalBNonNull = function(a) {
      return summer(a);
    }
    globalThis.doSumTwoOptionalCNonNull = function(a, b) {
      return summer(a, b);
    }

    // tear off cases
    globalThis.tearOffNoArgs = function (f) {
      return f();
    }
    globalThis.tearOffOneArg = function (f) {
      return f('foo');
    }
    globalThis.tearOffOnePositionalAndOneOptionalArgsA = function (f) {
      return f('foo');
    }
    globalThis.tearOffOnePositionalAndOneOptionalArgsB = function (f) {
      return f('foo', 'baz');
    }
    globalThis.tearOffTwoOptionalArgsA = function (f) {
      return f('foo');
    }
    globalThis.tearOffTwoOptionalArgsB = function (f) {
      return f('foo', 'baz');
    }

    // tear off generic class cases
    globalThis.tearOffGenericNoArgs = function (f) {
      return f();
    }
    globalThis.tearOffGenericOneArg = function (f) {
      return f(1.0);
    }
    globalThis.tearOffGenericOnePositionalAndOneOptionalArgsA = function (f) {
      return f(1.0);
    }
    globalThis.tearOffGenericOnePositionalAndOneOptionalArgsB = function (f) {
      return f(1.0, 'baz');
    }
    globalThis.tearOffGenericTwoOptionalArgsA = function (f) {
      return f(1.0);
    }
    globalThis.tearOffGenericTwoOptionalArgsB = function (f) {
      return f(1.0, 'baz');
    }
  ''');

  // General
  {
    final interopCallback = allowInterop<SumTwoPositionalFun>((a, b) => a + b);
    Expect.equals('foobar',
        callMethod(globalThis, 'doSum1', [interopCallback]).toString());
    setProperty(globalThis, 'summer', interopCallback);
    Expect.equals(
        'foobar', callMethod(globalThis, 'doSum2', ['foo', 'bar']).toString());
    final roundTripCallback = getProperty(globalThis, 'summer');
    Expect.equals('foobar',
        (dartify(roundTripCallback) as SumTwoPositionalFun)('foo', 'bar'));
  }

  // 1 nullable optional argument
  {
    final interopCallback = allowInterop<SumOnePositionalAndOneOptionalFun>(
        (a, [b]) => a + (b ?? 'bar'));
    setProperty(globalThis, 'summer', interopCallback);
    Expect.equals(
        'foobar',
        callMethod(globalThis, 'doSumOnePositionalAndOneOptionalA', ['foo'])
            .toString());
    Expect.equals(
        'foobar',
        callMethod(
                globalThis, 'doSumOnePositionalAndOneOptionalB', ['foo', 'bar'])
            .toString());
  }

  // All nullable optional arguments
  {
    final interopCallback = allowInterop<SumTwoOptionalFun>(
        ([a, b]) => (a ?? 'foo') + (b ?? 'bar'));
    setProperty(globalThis, 'summer', interopCallback);
    Expect.equals(
        'foobar', callMethod(globalThis, 'doSumTwoOptionalA', []).toString());
    Expect.equals('foobar',
        callMethod(globalThis, 'doSumTwoOptionalB', ['foo']).toString());
    Expect.equals('foobar',
        callMethod(globalThis, 'doSumTwoOptionalC', ['foo', 'bar']).toString());
  }

  // 1 non-nullable optional argument
  {
    final interopCallback =
        allowInterop<SumOnePositionalAndOneOptionalNonNullFun>(
            (a, [b = 'bar']) => a + b);
    setProperty(globalThis, 'summer', interopCallback);
    Expect.equals(
        'foobar',
        callMethod(globalThis, 'doSumOnePositionalAndOneOptionalA', ['foo'])
            .toString());
    Expect.equals(
        'foobar',
        callMethod(
                globalThis, 'doSumOnePositionalAndOneOptionalB', ['foo', 'bar'])
            .toString());
  }

  // All non-nullable optional arguments
  {
    final interopCallback = allowInterop<SumTwoOptionalNonNullFun>(
        ([a = 'foo', b = 'bar']) => a + b);
    setProperty(globalThis, 'summer', interopCallback);
    Expect.equals(
        'foobar', callMethod(globalThis, 'doSumTwoOptionalA', []).toString());
    Expect.equals('foobar',
        callMethod(globalThis, 'doSumTwoOptionalB', ['foo']).toString());
    Expect.equals('foobar',
        callMethod(globalThis, 'doSumTwoOptionalC', ['foo', 'bar']).toString());
  }

  // Tear off cases
  // No args.
  {
    final t = TornOffClass();
    final interopCallback = allowInterop<NoArgsFun>(t.noArgs);
    Expect.equals(
        'foo', callMethod(globalThis, 'tearOffNoArgs', [interopCallback]));
  }

  // One arg.
  {
    final t = TornOffClass();
    final interopCallback = allowInterop<OneArgFun>(t.oneArg);
    Expect.equals(
        'foo', callMethod(globalThis, 'tearOffOneArg', [interopCallback]));
  }

  // One positional and one optional case A.
  {
    final t = TornOffClass();
    final interopCallback = allowInterop<OnePositionalAndOneOptionalArgsFun>(
        t.onePositionalAndOneOptionalArgs);
    Expect.equals(
        'foobar',
        callMethod(globalThis, 'tearOffOnePositionalAndOneOptionalArgsA',
            [interopCallback]));
  }

  // One positional and one optional case B.
  {
    final t = TornOffClass();
    final interopCallback = allowInterop<OnePositionalAndOneOptionalArgsFun>(
        t.onePositionalAndOneOptionalArgs);
    Expect.equals(
        'foobaz',
        callMethod(globalThis, 'tearOffOnePositionalAndOneOptionalArgsB',
            [interopCallback]));
  }

  // Two optional case A.
  {
    final t = TornOffClass();
    final interopCallback = allowInterop<TwoOptionalArgsFun>(t.twoOptionalArgs);
    Expect.equals('foo',
        callMethod(globalThis, 'tearOffTwoOptionalArgsA', [interopCallback]));
  }

  // Two optional case B.
  {
    final t = TornOffClass();
    final interopCallback = allowInterop<TwoOptionalArgsFun>(t.twoOptionalArgs);
    Expect.equals('foobaz',
        callMethod(globalThis, 'tearOffTwoOptionalArgsB', [interopCallback]));
  }

  // Tearoffs of generic classes.
  // No args.
  {
    final t = GenericTornOffClass<double, String>();
    final interopCallback = allowInterop<NoArgsFun>(t.noArgs);
    Expect.equals('foo',
        callMethod(globalThis, 'tearOffGenericNoArgs', [interopCallback]));
  }

  // One arg.
  {
    final t = GenericTornOffClass<double, String>();
    final interopCallback = allowInterop<OneArgFunB>(t.oneArg);
    Expect.equals('1.0',
        callMethod(globalThis, 'tearOffGenericOneArg', [interopCallback]));
  }

  // One positional and one optional case A.
  {
    final t = GenericTornOffClass<double, String>();
    final interopCallback = allowInterop<OnePositionalAndOneOptionalArgsFunB>(
        t.onePositionalAndOneOptionalArgs);
    Expect.equals(
        '1.0 null',
        callMethod(globalThis, 'tearOffGenericOnePositionalAndOneOptionalArgsA',
            [interopCallback]));
  }

  // One positional and one optional case B.
  {
    final t = GenericTornOffClass<double, String>();
    final interopCallback = allowInterop<OnePositionalAndOneOptionalArgsFunB>(
        t.onePositionalAndOneOptionalArgs);
    Expect.equals(
        '1.0 baz',
        callMethod(globalThis, 'tearOffGenericOnePositionalAndOneOptionalArgsB',
            [interopCallback]));
  }

  // Two optional case A.
  {
    final t = GenericTornOffClass<double, String>();
    final interopCallback =
        allowInterop<TwoOptionalArgsFunB>(t.twoOptionalArgs);
    Expect.equals(
        '1.0 null',
        callMethod(
            globalThis, 'tearOffGenericTwoOptionalArgsA', [interopCallback]));
  }

  // Two optional case B.
  {
    final t = GenericTornOffClass<double, String>();
    final interopCallback =
        allowInterop<TwoOptionalArgsFunB>(t.twoOptionalArgs);
    Expect.equals(
        '1.0 baz',
        callMethod(
            globalThis, 'tearOffGenericTwoOptionalArgsB', [interopCallback]));
  }
}

void main() {
  staticInteropCallbackTest();
  allowInteropCallbackTest();
}
