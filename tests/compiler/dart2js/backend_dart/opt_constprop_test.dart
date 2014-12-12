// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import '../mock_compiler.dart';
import 'sexpr_unstringifier.dart';
import 'package:async_helper/async_helper.dart';
import "package:expect/expect.dart";
import 'package:compiler/src/cps_ir/cps_ir_nodes_sexpr.dart';
import 'package:compiler/src/cps_ir/optimizers.dart';
import 'package:compiler/src/dart2jslib.dart' as dart2js;

// The tests in this file that ensure that sparse constant propagation on the
// CPS IR works as expected.

// CP1 represents the following incoming dart code:
//
//  int main() {
//    int i = 1;
//    int j;
//    if (i == 1) {
//      j = 2;
//    } else {
//      j = 3;
//    }
//    return j;
//  }

String CP1_IN = """
(FunctionDefinition main (return) (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(1)))
  (LetCont (k0 v2)
    (LetCont (k1) (LetPrim v3 (Constant IntConstant(2)))
      (InvokeContinuation return v3))
    (LetCont (k2) (LetPrim v4 (Constant IntConstant(3)))
      (InvokeContinuation return v4))
    (Branch (IsTrue v2) k1 k2))
  (InvokeMethod v0 == v1 k0))
""";
String CP1_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(1)))
  (LetCont (k0 v2)
    (LetCont (k1)
      (LetPrim v3 (Constant IntConstant(2)))
      (InvokeContinuation return v3))
    (LetCont (k2)
      (LetPrim v4 (Constant IntConstant(3)))
      (InvokeContinuation return v4))
    (InvokeContinuation k1 ))
  (LetPrim v5 (Constant BoolConstant(true)))
  (InvokeContinuation k0 v5))
""";

// CP2 represents the following incoming dart code:
//
//  int main() {
//    int i = 1;
//    while (true) {
//      if (false || false) {
//        return i;
//      }
//      if (true && i == 1) {
//        return i;
//      }
//    }
//    return 42;
//  }

String CP2_IN = """
(FunctionDefinition main (return) (LetPrim v0 (Constant IntConstant(1)))
  (LetCont* (k0)
    (LetCont (k1) (LetPrim v1 (Constant IntConstant(42)))
      (InvokeContinuation return v1))
    (LetCont (k2) (LetPrim v2 (Constant BoolConstant(false)))
      (LetCont (k3 v3)
        (LetCont (k4) (InvokeContinuation return v0))
        (LetCont (k5) (LetPrim v4 (Constant BoolConstant(true)))
          (LetCont (k6 v5)
            (LetCont (k7) (InvokeContinuation return v0))
            (LetCont (k8) (InvokeContinuation* k0))
            (Branch (IsTrue v5) k7 k8))
          (LetCont (k9) (LetPrim v6 (Constant IntConstant(1)))
            (LetCont (k10 v7)
              (LetCont (k11) (LetPrim v8 (Constant BoolConstant(true)))
                (InvokeContinuation k6 v8))
              (LetCont (k12) (LetPrim v9 (Constant BoolConstant(false)))
                (InvokeContinuation k6 v9))
              (Branch (IsTrue v7) k11 k12))
            (InvokeMethod v0 == v6 k10))
          (LetCont (k13) (LetPrim v10 (Constant BoolConstant(false)))
            (InvokeContinuation k6 v10))
          (Branch (IsTrue v4) k9 k13))
        (Branch (IsTrue v3) k4 k5))
      (LetCont (k14) (LetPrim v11 (Constant BoolConstant(true)))
        (InvokeContinuation k3 v11))
      (LetCont (k15) (LetPrim v12 (Constant BoolConstant(false)))
        (LetCont (k16) (LetPrim v13 (Constant BoolConstant(true)))
          (InvokeContinuation k3 v13))
        (LetCont (k17) (LetPrim v14 (Constant BoolConstant(false)))
          (InvokeContinuation k3 v14))
        (Branch (IsTrue v12) k16 k17))
      (Branch (IsTrue v2) k14 k15))
    (LetPrim v15 (Constant BoolConstant(true)))
    (Branch (IsTrue v15) k2 k1))
  (InvokeContinuation k0))
""";
String CP2_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetCont* (k0)
    (LetCont (k1) (LetPrim v1 (Constant IntConstant(42)))
      (InvokeContinuation return v1))
    (LetCont (k2)
      (LetPrim v2 (Constant BoolConstant(false)))
      (LetCont (k3 v3)
        (LetCont (k4) (InvokeContinuation return v0))
        (LetCont (k5)
          (LetPrim v4 (Constant BoolConstant(true)))
          (LetCont (k6 v5)
            (LetCont (k7) (InvokeContinuation return v0))
            (LetCont (k8) (InvokeContinuation* k0 ))
            (InvokeContinuation k7 ))
          (LetCont (k9)
            (LetPrim v6 (Constant IntConstant(1)))
            (LetCont (k10 v7)
              (LetCont (k11)
                (LetPrim v8 (Constant BoolConstant(true)))
                (InvokeContinuation k6 v8))
              (LetCont (k12) (LetPrim v9 (Constant BoolConstant(false)))
                (InvokeContinuation k6 v9))
              (InvokeContinuation k11 ))
            (LetPrim v10 (Constant BoolConstant(true)))
            (InvokeContinuation k10 v10))
          (LetCont (k13) (LetPrim v11 (Constant BoolConstant(false)))
            (InvokeContinuation k6 v11))
          (InvokeContinuation k9 ))
        (InvokeContinuation k5 ))
      (LetCont (k14) (LetPrim v12 (Constant BoolConstant(true)))
        (InvokeContinuation k3 v12))
      (LetCont (k15)
        (LetPrim v13 (Constant BoolConstant(false)))
        (LetCont (k16) (LetPrim v14 (Constant BoolConstant(true)))
          (InvokeContinuation k3 v14))
        (LetCont (k17)
          (LetPrim v15 (Constant BoolConstant(false)))
          (InvokeContinuation k3 v15))
        (InvokeContinuation k17 ))
      (InvokeContinuation k15 ))
    (LetPrim v16 (Constant BoolConstant(true)))
    (InvokeContinuation k2 ))
  (InvokeContinuation k0 ))
""";

// CP3 represents the following incoming dart code:
//
//  int main() {
//    int i = 1;
//    i = f();
//    if (i == 1) {
//      return 42;
//    }
//    return i;
//  }

String CP3_IN = """
(FunctionDefinition main ( return) (LetPrim v0 (Constant IntConstant(1)))
  (LetCont (k0 v1) (LetPrim v2 (Constant IntConstant(1)))
    (LetCont (k1 v3)
      (LetCont (k2) (LetPrim v4 (Constant IntConstant(42)))
        (InvokeContinuation return v4))
      (LetCont (k3) (InvokeContinuation return v1))
      (Branch (IsTrue v3) k2 k3))
    (InvokeMethod v1 == v2 k1))
  (InvokeStatic f k0))
""";
String CP3_OUT = CP3_IN;

// Addition.

String CP4_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(2)))
  (LetCont (k0 v2)
     (InvokeContinuation return v2))
  (InvokeMethod v0 + v1 k0))
""";
String CP4_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(2)))
  (LetCont (k0 v2)
     (InvokeContinuation return v2))
  (LetPrim v3 (Constant IntConstant(3)))
  (InvokeContinuation k0 v3))
""";

// Array access operator (no optimization).

String CP5_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(2)))
  (LetCont (k0 v2)
     (InvokeContinuation return v2))
  (InvokeMethod v0 [] v1 k0))
""";
String CP5_OUT = CP5_IN;

// Division by 0.

String CP6_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(0)))
  (LetCont (k0 v2)
     (InvokeContinuation return v2))
  (InvokeMethod v0 / v1 k0))
""";
String CP6_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(0)))
  (LetCont (k0 v2)
     (InvokeContinuation return v2))
  (LetPrim v3 (Constant DoubleConstant(Infinity)))
  (InvokeContinuation k0 v3))
""";

// Concatenate strings.

String CP7_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant StringConstant("b")))
  (LetPrim v1 (Constant StringConstant("d")))
  (LetPrim v2 (Constant StringConstant("a")))
  (LetPrim v3 (Constant StringConstant("c")))
  (LetPrim v4 (Constant StringConstant("")))
  (LetCont (k0 v5)
    (LetCont (k1 v6)
      (InvokeContinuation return v6))
    (InvokeMethod v5 length k1))
  (ConcatenateStrings v2 v0 v3 v1 v4 k0))
""";
String CP7_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant StringConstant("b")))
  (LetPrim v1 (Constant StringConstant("d")))
  (LetPrim v2 (Constant StringConstant("a")))
  (LetPrim v3 (Constant StringConstant("c")))
  (LetPrim v4 (Constant StringConstant("")))
  (LetCont (k0 v5)
    (LetCont (k1 v6)
      (InvokeContinuation return v6))
    (InvokeMethod v5 length k1))
  (LetPrim v7 (Constant StringConstant("abcd")))
  (InvokeContinuation k0 v7))
""";

// TODO(jgruber): We can't test is-check optimization because the unstringifier
// does not recreate accurate types for the TypeOperator node.

// Simple branch removal.

String CP8_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(1)))
  (LetCont (k0 v2)
    (LetCont (k1)
      (LetPrim v3 (Constant IntConstant(42)))
      (InvokeContinuation return v3))
    (LetCont (k2)
      (InvokeContinuation return v0))
    (Branch (IsTrue v2) k1 k2))
  (InvokeMethod v0 == v1 k0))
""";
String CP8_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetPrim v1 (Constant IntConstant(1)))
  (LetCont (k0 v2)
    (LetCont (k1) (LetPrim v3 (Constant IntConstant(42)))
      (InvokeContinuation return v3))
    (LetCont (k2) (InvokeContinuation return v0))
    (InvokeContinuation k1 ))
  (LetPrim v4 (Constant BoolConstant(true)))
  (InvokeContinuation k0 v4))
""";

// While loop.

String CP9_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetCont* (k0 v1)
    (LetCont (k1)
      (InvokeContinuation return v1))
    (LetCont (k2)
      (LetPrim v2 (Constant IntConstant(1)))
      (LetCont (k3 v3)
        (LetCont (k4 v4)
          (LetCont (k5)
            (LetPrim v5 (Constant IntConstant(42)))
            (InvokeContinuation return v5))
          (LetCont (k6)
            (LetPrim v6 (Constant IntConstant(1)))
            (LetCont (k7 v7)
              (InvokeContinuation* k0 v7))
            (InvokeMethod v1 + v6 k7))
          (Branch (IsTrue v4) k5 k6))
        (LetCont (k8)
          (LetPrim v8 (Constant BoolConstant(false)))
          (InvokeContinuation k4 v8))
        (LetCont (k9)
          (LetPrim v9 (Constant BoolConstant(true)))
          (InvokeContinuation k4 v9))
        (Branch (IsTrue v3) k8 k9))
      (InvokeMethod v1 == v2 k3))
    (LetPrim v10 (Constant BoolConstant(true)))
    (Branch (IsTrue v10) k2 k1))
  (InvokeContinuation k0 v0))
""";
String CP9_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(1)))
  (LetCont* (k0 v1)
    (LetCont (k1)
      (InvokeContinuation return v1))
    (LetCont (k2)
      (LetPrim v2 (Constant IntConstant(1)))
      (LetCont (k3 v3)
        (LetCont (k4 v4)
          (LetCont (k5)
            (LetPrim v5 (Constant IntConstant(42)))
            (InvokeContinuation return v5))
          (LetCont (k6)
            (LetPrim v6 (Constant IntConstant(1)))
            (LetCont (k7 v7)
              (InvokeContinuation* k0 v7))
            (InvokeMethod v1 + v6 k7))
          (Branch (IsTrue v4) k5 k6))
        (LetCont (k8)
          (LetPrim v8 (Constant BoolConstant(false)))
          (InvokeContinuation k4 v8))
        (LetCont (k9)
          (LetPrim v9 (Constant BoolConstant(true)))
          (InvokeContinuation k4 v9))
        (Branch (IsTrue v3) k8 k9))
      (InvokeMethod v1 == v2 k3))
    (LetPrim v10 (Constant BoolConstant(true)))
    (InvokeContinuation k2 ))
  (InvokeContinuation k0 v0))
""";

// While loop, from:
//
//  int main() {
//    for (int i = 0; i < 2; i++) {
//      print(42 + i);
//    }
//  }

String CP10_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont* (k0 v1)
    (LetCont (k1)
      (LetPrim v2 (Constant NullConstant))
      (InvokeContinuation return v2))
    (LetCont (k2)
      (LetPrim v3 (Constant IntConstant(42)))
      (LetCont (k3 v4)
        (LetCont (k4 v5)
          (LetPrim v6 (Constant IntConstant(1)))
          (LetCont (k5 v7)
            (InvokeContinuation* k0 v7))
          (InvokeMethod v1 + v6 k5))
        (InvokeStatic print v4 k4))
      (InvokeMethod v3 + v1 k3))
    (LetPrim v8 (Constant IntConstant(2)))
    (LetCont (k6 v9)
      (Branch (IsTrue v9) k2 k1))
    (InvokeMethod v1 < v8 k6))
  (InvokeContinuation k0 v0))
""";
String CP10_OUT = CP10_IN;

/// Normalizes whitespace by replacing all whitespace sequences by a single
/// space and trimming leading and trailing whitespace.
String normalizeSExpr(String input) {
  return input.replaceAll(new RegExp(r'[ \n\t]+'), ' ').trim();
}

class UnitTypeSystem implements TypeSystem<String> {
  static const String UNIT = 'unit';

  get boolType => UNIT;
  get dynamicType => UNIT;
  get functionType => UNIT;
  get intType => UNIT;
  get listType => UNIT;
  get mapType => UNIT;
  get stringType => UNIT;
  get typeType => UNIT;

  bool areAssignable(a, b) => true;
  getParameterType(_) => UNIT;
  getReturnType(_) => UNIT;
  join(a, b) => UNIT;
  typeOf(_) => UNIT;
}

/// Parses the given input IR, runs an optimization pass over it, and compares
/// the stringification of the result against the expected output.
Future testConstantPropagator(String input, String expectedOutput) {
  final compiler = new MockCompiler.internal(
      emitJavaScript: false,
      enableMinification: false);
  return compiler.init().then((_) {
    final unstringifier = new SExpressionUnstringifier();
    final stringifier   = new SExpressionStringifier();
    final optimizer     = new TypePropagator(
        compiler,
        dart2js.DART_CONSTANT_SYSTEM,
        new UnitTypeSystem(),
        compiler.internalError);

    final f = unstringifier.unstringify(input);
    optimizer.rewrite(f);

    String expected = normalizeSExpr(expectedOutput);
    String actual   = normalizeSExpr(stringifier.visit(f));

    Expect.equals(expected, actual);
  });
}

void main() {
  asyncTest(() => testConstantPropagator(CP1_IN, CP1_OUT));
  asyncTest(() => testConstantPropagator(CP2_IN, CP2_OUT));
  asyncTest(() => testConstantPropagator(CP3_IN, CP3_OUT));
  asyncTest(() => testConstantPropagator(CP4_IN, CP4_OUT));
  asyncTest(() => testConstantPropagator(CP5_IN, CP5_OUT));
  asyncTest(() => testConstantPropagator(CP6_IN, CP6_OUT));
  asyncTest(() => testConstantPropagator(CP7_IN, CP7_OUT));
  asyncTest(() => testConstantPropagator(CP8_IN, CP8_OUT));
  asyncTest(() => testConstantPropagator(CP9_IN, CP9_OUT));
  asyncTest(() => testConstantPropagator(CP10_IN, CP10_OUT));
}
