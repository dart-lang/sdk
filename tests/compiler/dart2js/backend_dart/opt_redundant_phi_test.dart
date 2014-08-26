// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'sexpr_unstringifier.dart';
import "package:expect/expect.dart";
import 'package:compiler/implementation/cps_ir/cps_ir_nodes.dart';
import 'package:compiler/implementation/cps_ir/cps_ir_nodes_sexpr.dart';
import 'package:compiler/implementation/cps_ir/optimizers.dart';

// The 'read in loop' IR tests the most basic case of redundant phi removal
// and represents the following source code:
//
// void main() {
//   int j = 42;
//   for (int i = 0; i < 2; i++) {
//     print(j.toString());
//   }
// }

String READ_IN_LOOP_IN = """
(FunctionDefinition main (return) (LetPrim v0 (Constant 42))
  (LetPrim v1 (Constant 0))
  (LetCont* (k0 v2 v3)
    (LetCont (k1) (LetPrim v4 (Constant null))
      (InvokeContinuation return v4))
    (LetCont (k2)
      (LetCont (k3 v5)
        (LetCont (k4 v6) (LetPrim v7 (Constant 1))
          (LetCont (k5 v8) (InvokeContinuation* k0 v2 v8))
          (InvokeMethod v3 + v7 k5))
        (InvokeStatic print v5 k4))
      (InvokeMethod v2 toString k3))
    (LetPrim v9 (Constant 2))
    (LetCont (k6 v10) (Branch (IsTrue v10) k2 k1))
    (InvokeMethod v3 < v9 k6))
  (InvokeContinuation k0 v0 v1))
""";

String READ_IN_LOOP_OUT = """
(FunctionDefinition main ( return) (LetPrim v0 (Constant 42))
  (LetPrim v1 (Constant 0))
  (LetCont* (k0 v2)
    (LetCont (k1) (LetPrim v3 (Constant null))
      (InvokeContinuation return v3))
    (LetCont (k2)
      (LetCont (k3 v4)
        (LetCont (k4 v5) (LetPrim v6 (Constant 1))
          (LetCont (k5 v7) (InvokeContinuation* k0 v7))
          (InvokeMethod v2 + v6 k5))
        (InvokeStatic print v4 k4))
      (InvokeMethod v0 toString k3))
    (LetPrim v8 (Constant 2))
    (LetCont (k6 v9) (Branch (IsTrue v9) k2 k1))
    (InvokeMethod v2 < v8 k6))
  (InvokeContinuation k0 v1))
""";

// The 'inner loop' IR represents the following source code:
//
// void main() {
//   int j = 42;
//   for (int i = 0; i < 2; i++) {
//     for (int k = 0; k < 2; k++) {
//       print(i.toString());
//     }
//   }
//   print(j.toString());
// }
//
// This test case ensures that iterative optimization works: first, v8 and v9
// are removed from k5, and only then can k0 be optimized as well.

const String INNER_LOOP_IN = """
(FunctionDefinition main (return) (LetPrim v0 (Constant 42))
  (LetPrim v1 (Constant 0))
  (LetCont* (k0 v2 v3)
    (LetCont (k1)
      (LetCont (k2 v4)
        (LetCont (k3 v5) (LetPrim v6 (Constant null))
          (InvokeContinuation return v6))
        (InvokeStatic print v4 k3))
      (InvokeMethod v2 toString k2))
    (LetCont (k4) (LetPrim v7 (Constant 0))
      (LetCont* (k5 v8 v9 v10)
        (LetCont (k6) (LetPrim v11 (Constant 1))
          (LetCont (k7 v12) (InvokeContinuation* k0 v8 v12))
          (InvokeMethod v9 + v11 k7))
        (LetCont (k8)
          (LetCont (k9 v13)
            (LetCont (k10 v14) (LetPrim v15 (Constant 1))
              (LetCont (k11 v16)
                (InvokeContinuation* k5 v8 v9 v16))
              (InvokeMethod v10 + v15 k11))
            (InvokeStatic print v13 k10))
          (InvokeMethod v9 toString k9))
        (LetPrim v17 (Constant 2))
        (LetCont (k12 v18) (Branch (IsTrue v18) k8 k6))
        (InvokeMethod v10 < v17 k12))
      (InvokeContinuation k5 v2 v3 v7))
    (LetPrim v19 (Constant 2))
    (LetCont (k13 v20) (Branch (IsTrue v20) k4 k1))
    (InvokeMethod v3 < v19 k13))
  (InvokeContinuation k0 v0 v1))
""";

const String INNER_LOOP_OUT = """
(FunctionDefinition main ( return) (LetPrim v0 (Constant 42))
  (LetPrim v1 (Constant 0))
  (LetCont* (k0 v2)
    (LetCont (k1)
      (LetCont (k2 v3)
        (LetCont (k3 v4) (LetPrim v5 (Constant null))
          (InvokeContinuation return v5))
        (InvokeStatic print v3 k3))
      (InvokeMethod v0 toString k2))
    (LetCont (k4) (LetPrim v6 (Constant 0))
      (LetCont* (k5 v7)
        (LetCont (k6) (LetPrim v8 (Constant 1))
          (LetCont (k7 v9) (InvokeContinuation* k0 v9))
          (InvokeMethod v2 + v8 k7))
        (LetCont (k8)
          (LetCont (k9 v10)
            (LetCont (k10 v11) (LetPrim v12 (Constant 1))
              (LetCont (k11 v13)
                (InvokeContinuation* k5 v13))
              (InvokeMethod v7 + v12 k11))
            (InvokeStatic print v10 k10))
          (InvokeMethod v2 toString k9))
        (LetPrim v14 (Constant 2))
        (LetCont (k12 v15) (Branch (IsTrue v15) k8 k6))
        (InvokeMethod v7 < v14 k12))
      (InvokeContinuation k5 v6))
    (LetPrim v16 (Constant 2))
    (LetCont (k13 v17) (Branch (IsTrue v17) k4 k1))
    (InvokeMethod v2 < v16 k13))
  (InvokeContinuation k0 v1))
""";

// There are no redundant phis in the 'basic loop' IR, and this test ensures
// simply that the optimization does not alter the IR. It represents the
// following program:
//
// void main() {
//   for (int i = 0; i < 2; i++) {
//     print(i.toString());
//   }
// }

String BASIC_LOOP_IN = """
(FunctionDefinition main ( return) (LetPrim v0 (Constant 0))
  (LetCont* (k0 v1)
    (LetCont (k1) (LetPrim v2 (Constant null))
      (InvokeContinuation return v2))
    (LetCont (k2)
      (LetCont (k3 v3)
        (LetCont (k4 v4) (LetPrim v5 (Constant 1))
          (LetCont (k5 v6) (InvokeContinuation* k0 v6))
          (InvokeMethod v1 + v5 k5))
        (InvokeStatic print v3 k4))
      (InvokeMethod v1 toString k3))
    (LetPrim v7 (Constant 2))
    (LetCont (k6 v8) (Branch (IsTrue v8) k2 k1))
    (InvokeMethod v1 < v7 k6))
  (InvokeContinuation k0 v0))
""";

String BASIC_LOOP_OUT = BASIC_LOOP_IN;

// Ensures that continuations which are never invoked are not optimized.
// IR written by hand.

String NEVER_INVOKED1_IN = """
(FunctionDefinition main ( return) 
  (LetPrim v0 (Constant 0))
  (LetCont (k0 v1)
    (InvokeStatic print v1 return))
  (InvokeContinuation return v0))
""";

String NEVER_INVOKED1_OUT = NEVER_INVOKED1_IN;

// As in the previous test, except with the added wrinkle of higher order
// continuations.

String NEVER_INVOKED2_IN = """
(FunctionDefinition main ( return)
  (LetCont (k0 v0)
    (InvokeStatic print v0 return))
  (InvokeContinuation return k0))
""";

String NEVER_INVOKED2_OUT = NEVER_INVOKED2_IN;

// As in the previous test, but the continuation is invoked as well as passed
// as an argument.

String AS_ARG_IN = """
(FunctionDefinition main ( return)
  (LetCont (k0 v0)
    (InvokeStatic print v0 return))
  (InvokeContinuation k0 k0))
""";

String AS_ARG_OUT = AS_ARG_IN;

/// Normalizes whitespace by replacing all whitespace sequences by a single
/// space and trimming leading and trailing whitespace.
String normalizeSExpr(String input) {
  return input.replaceAll(new RegExp(r'[ \n\t]+'), ' ').trim();
}

/// Parses the given input IR, runs a redundant phi pass over it, and compares
/// the stringification of the result against the expected output.
void testRedundantPhi(String input, String expectedOutput) {
  final unstringifier = new SExpressionUnstringifier();
  final stringifier   = new SExpressionStringifier();
  final optimizer     = new RedundantPhiEliminator();

  FunctionDefinition f = unstringifier.unstringify(input);
  optimizer.rewrite(f);

  String expected = normalizeSExpr(expectedOutput);
  String actual   = normalizeSExpr(stringifier.visit(f));

  Expect.equals(expected, actual);
}

void main() {
  testRedundantPhi(READ_IN_LOOP_IN, READ_IN_LOOP_OUT);
  testRedundantPhi(INNER_LOOP_IN, INNER_LOOP_OUT);
  testRedundantPhi(BASIC_LOOP_IN, BASIC_LOOP_OUT);
  testRedundantPhi(NEVER_INVOKED1_IN, NEVER_INVOKED1_OUT);
  testRedundantPhi(NEVER_INVOKED2_IN, NEVER_INVOKED2_OUT);
  testRedundantPhi(AS_ARG_IN, AS_ARG_OUT);
}
