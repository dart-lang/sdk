// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import 'package:expect/minitest.dart';

/// This test is currently written as a white box test to ensure we don't
/// regress on any of the existing code paths that lead to NoSuchMethod errors
/// from dynamic calls. The test cases written with the knowledge of what the
/// generated code will look like.

// TODO(52190): Improve the NSM errors to make them more helpful.

expectThrowsNSMWithExactError(
        void Function() computation, String expectedErrorMessage) =>
    Expect.throws<NoSuchMethodError>(
        computation, (error) => error.toString() == expectedErrorMessage);

class A {
  String arity1(int val) {
    val += 10;
    return val.toString();
  }

  void genericArity2<T, S>() => print('$T, $S');

  static String staticArity1(int val) {
    val += 10;
    return val.toString();
  }

  static void staticGenericArity2<T, S>() => print('$T, $S');

  Function? nullField;

  Function fieldArity1 = (int val) {
    val += 10;
    return val.toString();
  };
}

String arity1(int val) {
  val += 10;
  return val.toString();
}

void genericArity2<T, S>() => print('$T, $S');

Function fieldArity1 = (int val) {
  val += 10;
  return val.toString();
};

String requiredNamedArity1({required bool fosse}) {
  return fosse.toString();
}

int? x;

void main() {
  group('Dynamic call of', () {
    dynamic instanceOfA = A();
    test('instance of a class with no `call()` method', () {
      // Compiled as `dcall()`.
      expectThrowsNSMWithExactError(
          () => instanceOfA(),
          "NoSuchMethodError: 'call'\n"
          "Dynamic call of object has no instance method 'call'.\n"
          "Receiver: ${Error.safeToString(instanceOfA)}\n"
          "Arguments: []");
    });
    group('null', () {
      // TODO(49628): These should actually throw NoSuchMethodError with a
      // helpful error message.
      group('value', () {
        dynamic nullVal = null;
        test('without type arguments', () {
          // Compiled as `dcall()`.
          Expect.throws(() => nullVal());
        });
        test('passing type arguments', () {
          // Compiled as `dgcall()`.
          Expect.throws(() => nullVal<String, bool>());
        });
      });
      group('instance field', () {
        test('without type arguments', () {
          // Compiled as `dsend()`.
          Expect.throws(() => instanceOfA.nullField());
        });
        test('passing type arguments', () {
          // Compiled as `dgsend()`.
          Expect.throws(() => instanceOfA.nullField<String, bool>());
        });
      });
    });
    group('class instance members that do not exist', () {
      group('method', () {
        test('without passing type arguments', () {
          // Compiled as `dsend()`.
          expectThrowsNSMWithExactError(
              () => instanceOfA.doesNotExist(),
              "NoSuchMethodError: 'doesNotExist'\n"
              "Dynamic call of null.\n"
              "Receiver: ${Error.safeToString(instanceOfA)}\n"
              "Arguments: []");
        });
        test('passing type arguments', () {
          // Compiled as `dgsend()`.
          expectThrowsNSMWithExactError(
              () => instanceOfA.doesNotExist<String, bool>(),
              "NoSuchMethodError: 'doesNotExist'\n"
              "Dynamic call of null.\n"
              "Receiver: ${Error.safeToString(instanceOfA)}\n"
              "Arguments: []");
        });
      });
      test('setter', () {
        // Compiled as `dput()`.
        expectThrowsNSMWithExactError(
            () => instanceOfA.doesNotExist = 10,
            "NoSuchMethodError: 'doesNotExist='\n"
            "method not found\n"
            "Receiver: ${Error.safeToString(instanceOfA)}\n"
            "Arguments: [10]");
      });
      test('getter', () {
        // Compiled as `dload()`.
        expectThrowsNSMWithExactError(
            () => x = instanceOfA.doesNotExist,
            "NoSuchMethodError: 'doesNotExist'\n"
            "method not found\n"
            "Receiver: ${Error.safeToString(instanceOfA)}\n"
            "Arguments: []");
      });
    });
    group('tearoff', () {
      // The code path for throwing NoSuchMethodErrors because of the incorrect
      // type arguments is shared by all forms of dynamic invocations. Simply
      // using tearoffs to trigger each form of the error.
      dynamic arity1Tearoff = arity1;
      dynamic genericArity2Tearoff = genericArity2;
      dynamic instantiatedTearoff = genericArity2<int, String>;
      test('passing unexpected type arguments', () {
        // Compiled as `dgcall()` and throws from `checkAndCall()`.
        expectThrowsNSMWithExactError(
            () => arity1Tearoff<bool>(42),
            "NoSuchMethodError: 'arity1'\n"
            "Dynamic call with unexpected type arguments. "
            "Expected: 0 Actual: 1\n"
            "Receiver: ${Error.safeToString(arity1Tearoff)}\n"
            "Arguments: [42]");
      });
      test('passing too many type arguments', () {
        // Compiled as `dgcall()` and throws from `checkAndCall()`.
        expectThrowsNSMWithExactError(
            () => genericArity2Tearoff<int, double, String>(),
            "NoSuchMethodError: 'genericArity2'\n"
            "Dynamic call with incorrect number of type arguments. "
            "Expected: 2 Actual: 3\n"
            "Receiver: ${Error.safeToString(genericArity2Tearoff)}\n"
            "Arguments: []");
      });
      test('passing too few type arguments', () {
        // Compiled as `dgcall()` and throws from `checkAndCall()`.
        expectThrowsNSMWithExactError(
            () => genericArity2Tearoff<int>(),
            "NoSuchMethodError: 'genericArity2'\n"
            "Dynamic call with incorrect number of type arguments. "
            "Expected: 2 Actual: 1\n"
            "Receiver: ${Error.safeToString(genericArity2Tearoff)}\n"
            "Arguments: []");
      });
      test('already instantiated and passing type arguments ', () {
        // Compiled as `dgcall()` and throws from `checkAndCall()`.
        expectThrowsNSMWithExactError(
            () => instantiatedTearoff<int, double>(),
            "NoSuchMethodError: 'result'\n"
            "Dynamic call with unexpected type arguments. "
            "Expected: 0 Actual: 2\n"
            "Receiver: ${Error.safeToString(instantiatedTearoff)}\n"
            "Arguments: []");
      });
    });
    group('`Function.apply()`', () {
      Function arity1Tearoff = arity1;
      Function requiredNamedArity1Tearoff = requiredNamedArity1;
      // The code path for throwing NoSuchMethodErrors because of the wrong
      // number of arguments or incorrect named arguments is shared by all
      // forms of dynamic invocations. Function.apply used here for simplicity.
      // Argument errors generated from `_argumentErrors()`.
      test('passing too many arguments', () {
        expectThrowsNSMWithExactError(
            () => Function.apply(arity1Tearoff, [42, false]),
            "NoSuchMethodError: 'arity1'\n"
            "Dynamic call with too many arguments. Expected: 1 Actual: 2\n"
            "Receiver: ${Error.safeToString(arity1Tearoff)}\n"
            "Arguments: [42, false]");
      });
      test('passing too few arguments', () {
        expectThrowsNSMWithExactError(
            () => Function.apply(arity1Tearoff, []),
            "NoSuchMethodError: 'arity1'\n"
            "Dynamic call with too few arguments. Expected: 1 Actual: 0\n"
            "Receiver: ${Error.safeToString(arity1Tearoff)}\n"
            "Arguments: []");
      });
      test('passing unexpected named argument', () {
        expectThrowsNSMWithExactError(
            () => Function.apply(
                requiredNamedArity1Tearoff, null, {#fosse: true, #cello: true}),
            "NoSuchMethodError: 'requiredNamedArity1'\n"
            "Dynamic call with unexpected named argument 'cello'.\n"
            "Receiver: ${Error.safeToString(requiredNamedArity1Tearoff)}\n"
            "Arguments: [fosse: true, cello: true]");
      });
      test('missing required named argument', () {
        // Missing required named arguments are not an error when running
        // without sound null safety.
        if (hasUnsoundNullSafety) return;
        expectThrowsNSMWithExactError(
            () => Function.apply(requiredNamedArity1Tearoff, null),
            "NoSuchMethodError: 'requiredNamedArity1'\n"
            "Dynamic call with missing required named arguments: fosse.\n"
            "Receiver: ${Error.safeToString(requiredNamedArity1Tearoff)}\n"
            "Arguments: []");
      });
    });
  });
  group('Descriptors appearing in `NoSuchMethodError` message for ', () {
    // Some extra tests for the names that appear in all the forms of dynamic
    // calls. All of these tests pass wrong number of arguments just to trigger
    // the error message.
    test('class instance method', () {
      dynamic instanceOfA = A();
      Expect.throws<NoSuchMethodError>(() => instanceOfA.arity1(),
          (error) => error.toString().contains("NoSuchMethodError: 'arity1'"));
    });
    test('class instance method tearoff', () {
      dynamic tearoff = A().arity1;
      Expect.throws<NoSuchMethodError>(
          () => tearoff(),
          (error) =>
              error.toString().contains("NoSuchMethodError: 'bound arity1'"));
    });
    test('class instance generic method', () {
      dynamic instanceOfA = A();
      Expect.throws<NoSuchMethodError>(
          () => instanceOfA.genericArity2(10),
          (error) =>
              error.toString().contains("NoSuchMethodError: 'genericArity2'"));
    });
    test('class instance generic method tearoff', () {
      dynamic tearoff = A().genericArity2;
      Expect.throws<NoSuchMethodError>(
          () => tearoff(10),
          (error) => error
              .toString()
              .contains("NoSuchMethodError: 'bound genericArity2'"));
    });
    test('class instance generic method tearoff instantiated', () {
      dynamic tearoff = A().genericArity2<int, String>;
      Expect.throws<NoSuchMethodError>(() => tearoff(10),
          (error) => error.toString().contains("NoSuchMethodError: 'result'"));
    });
    test('class instance field', () {
      dynamic instanceOfA = A();
      Expect.throws<NoSuchMethodError>(
          () => instanceOfA.fieldArity1(),
          (error) =>
              error.toString().contains("NoSuchMethodError: 'fieldArity1'"));
    });
    test('class static method tearoff', () {
      dynamic tearoff = A.staticArity1;
      Expect.throws<NoSuchMethodError>(
          () => tearoff(),
          (error) =>
              error.toString().contains("NoSuchMethodError: 'staticArity1'"));
    });
    test('class static generic method tearoff', () {
      dynamic tearoff = A.staticGenericArity2;
      Expect.throws<NoSuchMethodError>(
          () => tearoff(10),
          (error) => error
              .toString()
              .contains("NoSuchMethodError: 'staticGenericArity2'"));
    });
    test('class static generic method tearoff instantiated', () {
      dynamic tearoff = A.staticGenericArity2<int, double>;
      Expect.throws<NoSuchMethodError>(() => tearoff(10),
          (error) => error.toString().contains("NoSuchMethodError: 'result'"));
    });
    test('top level method tearoff', () {
      dynamic tearoff = A.staticArity1;
      Expect.throws<NoSuchMethodError>(
          () => tearoff(),
          (error) =>
              error.toString().contains("NoSuchMethodError: 'staticArity1'"));
    });
    test('top level generic method tearoff', () {
      dynamic tearoff = genericArity2;
      Expect.throws<NoSuchMethodError>(
          () => tearoff(10),
          (error) =>
              error.toString().contains("NoSuchMethodError: 'genericArity2'"));
    });
    test('top level generic method tearoff instantiated', () {
      dynamic tearoff = genericArity2<int, String>;
      Expect.throws<NoSuchMethodError>(() => tearoff(10),
          (error) => error.toString().contains("NoSuchMethodError: 'result'"));
    });
    test('top level field', () {
      Expect.throws<NoSuchMethodError>(() => fieldArity1(),
          (error) => error.toString().contains("NoSuchMethodError: ''"));
    });
  });
}
