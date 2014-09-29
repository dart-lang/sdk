// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'sexpr_unstringifier.dart';
import "package:expect/expect.dart";
import 'package:compiler/implementation/cps_ir/cps_ir_nodes.dart';
import 'package:compiler/implementation/cps_ir/cps_ir_nodes_sexpr.dart';
import 'package:compiler/implementation/cps_ir/optimizers.dart';

// The tests in this file that ensure shrinking reductions work as expected.
// Reductions and their corresponding names are taken from
// 'Compiling with Continuations, Continued' by Andrew Kennedy.

// Basic dead-val: letprim x = V in K -> K (x not free in K).
//
//  int main() {
//    int i = 42;
//    return 0;
//  }

String DEAD_VAL_IN = """
(FunctionDefinition main ( return) (LetPrim v0 (Constant IntConstant(42)))
  (LetPrim v1 (Constant IntConstant(0))) (InvokeContinuation return v1))
""";
String DEAD_VAL_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0))) (InvokeContinuation return v0))
""";

// Iterative dead-val. No optimizations possible since the continuation to
// InvokeMethod must have one argument, even if it is unused.
//
//  int main() {
//    int i = 42;
//    int j = i + 1;
//    return 0;
//  }

String ITERATIVE_DEAD_VAL1_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(42)))
  (LetPrim v1 (Constant IntConstant(1)))
  (LetCont (k0 v2) (LetPrim v3 (Constant IntConstant(0)))
    (InvokeContinuation return v3))
  (InvokeMethod v0 + v1 k0))
""";
String ITERATIVE_DEAD_VAL1_OUT = ITERATIVE_DEAD_VAL1_IN;

// Iterative dead-val. IR written by hand.

String ITERATIVE_DEAD_VAL2_IN = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(42)))
  (LetPrim v1
    (CreateFunction
      (FunctionDefinition f (i return)
        (InvokeContinuation return v0))))
  (LetPrim v2 (Constant IntConstant(0)))
  (InvokeContinuation return v2))
""";
String ITERATIVE_DEAD_VAL2_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (InvokeContinuation return v0))
""";

// Basic dead-cont: letcont k x = L in K -> K (k not free in K).
// IR written by hand.

String DEAD_CONT_IN = """
(FunctionDefinition main ( return)
  (LetPrim v4 (Constant IntConstant(0)))
  (LetCont (k0 v0) (InvokeConstructor List return))
  (LetCont (k1 v1)
    (LetCont (k2 v2) (LetPrim v3 (Constant IntConstant(0)))
      (InvokeContinuation return v3))
    (InvokeStatic print v4 k2))
  (InvokeStatic print v4 k1))
""";
String DEAD_CONT_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1)
    (LetCont (k1 v2) (LetPrim v3 (Constant IntConstant(0)))
      (InvokeContinuation return v3))
    (InvokeStatic print v0 k1))
  (InvokeStatic print v0 k0))
""";

// Iterative dead-cont. IR written by hand.

String ITERATIVE_DEAD_CONT_IN = """
(FunctionDefinition main ( return)
  (LetPrim v4 (Constant IntConstant(0)))
  (LetCont (k0 v0) (InvokeConstructor List return))
  (LetCont (k3 v5) (InvokeContinuation k0 v5))
  (LetCont (k1 v1)
    (LetCont (k2 v2) (LetPrim v3 (Constant IntConstant(0)))
      (InvokeContinuation return v3))
    (InvokeStatic print v4 k2))
  (InvokeStatic print v4 k1))
""";
String ITERATIVE_DEAD_CONT_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1)
    (LetCont (k1 v2) (LetPrim v3 (Constant IntConstant(0)))
      (InvokeContinuation return v3))
    (InvokeStatic print v0 k1))
  (InvokeStatic print v0 k0))
""";

// Beta-cont-lin: letcont k x = K in C[k y] -> C[K[y/x]] (k not free in C).
// IR written by hand.

String BETA_CONT_LIN_IN = """
(FunctionDefinition main ( return)
  (LetCont (k0 v0)
    (LetCont (k1 v1)
      (LetCont (k2 v2) (LetPrim v3 (Constant IntConstant(0)))
        (InvokeContinuation return v3))
      (InvokeStatic print v0 k2))
    (InvokeStatic print v0 k1))
  (LetPrim v4 (Constant IntConstant(0)))
  (InvokeContinuation k0 v4))
""";
String BETA_CONT_LIN_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1)
    (LetCont (k1 v2) (LetPrim v3 (Constant IntConstant(0)))
      (InvokeContinuation return v3))
    (InvokeStatic print v0 k1))
  (InvokeStatic print v0 k0))
""";

// Beta-cont-lin with continuation passed as arg in invoke. IR written by hand.

String ARG_BETA_CONT_LIN_IN = """
(FunctionDefinition main ( return)
  (LetCont (k0 v0)
    (LetPrim v1 (Constant IntConstant(0)))
    (InvokeStatic print v1 return))
  (InvokeContinuation return k0))
""";
String ARG_BETA_CONT_LIN_OUT = ARG_BETA_CONT_LIN_IN;

// Beta-cont-lin with recursive continuation. IR written by hand.

String RECURSIVE_BETA_CONT_LIN_IN = """
(FunctionDefinition main ( return)
  (LetCont* (k0 v0)
    (InvokeContinuation* k0 v0))
  (LetPrim v1 (Constant IntConstant(0)))
  (InvokeContinuation k0 v1))
""";
String RECURSIVE_BETA_CONT_LIN_OUT = RECURSIVE_BETA_CONT_LIN_IN;

// Beta-cont-lin used inside body. IR written by hand.

String USED_BETA_CONT_LIN_IN = """
(FunctionDefinition main ( return)
  (LetCont (k0 v0)
    (LetCont (k1 v1)
      (LetCont (k2 v2) (LetPrim v3 (Constant IntConstant(0)))
        (InvokeContinuation return v3))
      (InvokeStatic print v0 k2))
    (InvokeStatic print v0 k1))
    (LetPrim v4
      (CreateFunction
        (FunctionDefinition f ( return)
          (InvokeContinuation return k0))))
  (InvokeContinuation k0 v4))
""";
String USED_BETA_CONT_LIN_OUT = USED_BETA_CONT_LIN_IN;

// Eta-cont: letcont k x = j x in K -> K[j/k].
// IR written by hand.

String ETA_CONT_IN = """
(FunctionDefinition main ( return)
  (LetPrim v3 (Constant IntConstant(0)))
  (LetCont* (k1 v1) (InvokeContinuation return v3))
  (LetCont (k0 v0) (InvokeContinuation k1 v0))
  (LetPrim v4
    (CreateFunction
      (FunctionDefinition f ( return)
        (InvokeContinuation k1 k0))))
  (InvokeContinuation k0 v3))
""";
String ETA_CONT_OUT = """
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1) (InvokeContinuation return v0))
  (InvokeContinuation k0 v0))
""";

// Beta-fun-lin and eta-fun might not apply to us, since
// a. in (InvokeMethod v0 call k0), v0 might carry state, and
// b. there is no way to generate static nested functions that we could
//    use InvokeStatic on.

/// Normalizes whitespace by replacing all whitespace sequences by a single
/// space and trimming leading and trailing whitespace.
String normalizeSExpr(String input) {
  return input.replaceAll(new RegExp(r'[ \n\t]+'), ' ').trim();
}

/// Parses the given input IR, runs an optimization pass over it, and compares
/// the stringification of the result against the expected output.
void testShrinkingReducer(String input, String expectedOutput) {
  final unstringifier = new SExpressionUnstringifier();
  final stringifier   = new SExpressionStringifier();
  final optimizer     = new ShrinkingReducer();

  FunctionDefinition f = unstringifier.unstringify(input);
  optimizer.rewrite(f);

  String expected = normalizeSExpr(expectedOutput);
  String actual   = normalizeSExpr(stringifier.visit(f));

   Expect.equals(expected, actual);
}

void main() {
  testShrinkingReducer(DEAD_VAL_IN, DEAD_VAL_OUT);
  testShrinkingReducer(ITERATIVE_DEAD_VAL1_IN, ITERATIVE_DEAD_VAL1_OUT);
  testShrinkingReducer(ITERATIVE_DEAD_VAL2_IN, ITERATIVE_DEAD_VAL2_OUT);
  testShrinkingReducer(DEAD_CONT_IN, DEAD_CONT_OUT);
  testShrinkingReducer(ITERATIVE_DEAD_CONT_IN, ITERATIVE_DEAD_CONT_OUT);
  testShrinkingReducer(BETA_CONT_LIN_IN, BETA_CONT_LIN_OUT);
  testShrinkingReducer(ARG_BETA_CONT_LIN_IN, ARG_BETA_CONT_LIN_OUT);
  testShrinkingReducer(RECURSIVE_BETA_CONT_LIN_IN, RECURSIVE_BETA_CONT_LIN_OUT);
  testShrinkingReducer(USED_BETA_CONT_LIN_IN, USED_BETA_CONT_LIN_OUT);
  testShrinkingReducer(ETA_CONT_IN, ETA_CONT_OUT);
}
