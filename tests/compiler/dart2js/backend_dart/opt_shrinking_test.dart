// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'sexpr_unstringifier.dart';
import "package:expect/expect.dart";
import 'package:compiler/src/cps_ir/cps_ir_nodes.dart';
import 'package:compiler/src/cps_ir/cps_ir_nodes_sexpr.dart';
import 'package:compiler/src/cps_ir/optimizers.dart';

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
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 42)))
    (LetPrim (v1 (Constant (Int 0)))
      (InvokeContinuation return (v1)))))
""";
String DEAD_VAL_OUT = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (InvokeContinuation return (v0))))
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
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 42)))
    (LetPrim (v1 (Constant (Int 1)))
      (LetCont ((k0 (v2)
                  (LetPrim (v3 (Constant (Int 0)))
                    (InvokeContinuation return (v3)))))
        (InvokeMethod v0 + (v1) k0)))))
""";
String ITERATIVE_DEAD_VAL1_OUT = ITERATIVE_DEAD_VAL1_IN;

// Iterative dead-val. IR written by hand.

String ITERATIVE_DEAD_VAL2_IN = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 42)))
    (LetPrim (v1
        (CreateFunction
          (FunctionDefinition f () (i) return
            (InvokeContinuation return (v0)))))
      (LetPrim (v2 (Constant (Int 0)))
        (InvokeContinuation return (v2))))))
""";
String ITERATIVE_DEAD_VAL2_OUT = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (InvokeContinuation return (v0))))
""";

// Basic dead-cont: letcont k x = L in K -> K (k not free in K).
// IR written by hand.

String DEAD_CONT_IN = """
(FunctionDefinition main () () return
  (LetPrim (v4 (Constant (Int 0)))
    (LetCont ((k0 (v0)
                (InvokeConstructor List () return)))
      (LetCont ((k1 (v1)
                  (LetCont ((k2 (v2)
                              (LetPrim (v3 (Constant (Int 0)))
                                (InvokeContinuation return (v3)))))
                    (InvokeStatic print (v4) k2))))
        (InvokeStatic print (v4) k1)))))
""";
String DEAD_CONT_OUT = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (LetCont ((k0 (v1)
                (LetCont ((k1 (v2)
                            (LetPrim (v3 (Constant (Int 0)))
                              (InvokeContinuation return (v3)))))
                  (InvokeStatic print (v0) k1))))
      (InvokeStatic print (v0) k0))))
""";

// Iterative dead-cont. IR written by hand.

String ITERATIVE_DEAD_CONT_IN = """
(FunctionDefinition main () () return
  (LetPrim (v4 (Constant (Int 0)))
    (LetCont ((k0 (v0)
                (InvokeConstructor List () return)))
      (LetCont ((k3 (v5)
                  (InvokeContinuation k0 (v5))))
        (LetCont ((k1 (v1)
                    (LetCont ((k2 (v2)
                                (LetPrim (v3 (Constant (Int 0)))
                                  (InvokeContinuation return (v3)))))
                      (InvokeStatic print (v4) k2))))
          (InvokeStatic print (v4) k1))))))
""";
String ITERATIVE_DEAD_CONT_OUT = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (LetCont ((k0 (v1)
                (LetCont ((k1 (v2)
                            (LetPrim (v3 (Constant (Int 0)))
                              (InvokeContinuation return (v3)))))
                  (InvokeStatic print (v0) k1))))
      (InvokeStatic print (v0) k0))))
""";

// Beta-cont-lin: letcont k x = K in C[k y] -> C[K[y/x]] (k not free in C).
// IR written by hand.

String BETA_CONT_LIN_IN = """
(FunctionDefinition main () () return
  (LetCont ((k0 (v0)
              (LetCont ((k1 (v1)
                          (LetCont ((k2 (v2)
                                      (LetPrim (v3 (Constant (Int 0)))
                                        (InvokeContinuation return (v3)))))
                            (InvokeStatic print (v0) k2))))
                (InvokeStatic print (v0) k1))))
    (LetPrim (v4 (Constant (Int 0)))
      (InvokeContinuation k0 (v4)))))
""";
String BETA_CONT_LIN_OUT = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (LetCont ((k0 (v1)
                (LetCont ((k1 (v2)
                            (LetPrim (v3 (Constant (Int 0)))
                              (InvokeContinuation return (v3)))))
                  (InvokeStatic print (v0) k1))))
      (InvokeStatic print (v0) k0))))
""";

// Beta-cont-lin with recursive continuation. IR written by hand.

String RECURSIVE_BETA_CONT_LIN_IN = """
(FunctionDefinition main () () return
  (LetCont ((rec k0 (v0)
              (InvokeContinuation rec k0 (v0))))
    (LetPrim (v1 (Constant (Int 0)))
      (InvokeContinuation k0 (v1)))))
""";
String RECURSIVE_BETA_CONT_LIN_OUT = RECURSIVE_BETA_CONT_LIN_IN;

// Beta-cont-lin used inside body. IR written by hand.

String USED_BETA_CONT_LIN_IN = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (LetCont ((k0 (v1)
                (LetCont ((k1 (v2)
                            (LetCont ((k2 (v3)
                                        (LetPrim (v4 (Constant (Int 0)))
                                          (InvokeContinuation return (v4)))))
                              (InvokeStatic print (v1) k2))))
                  (InvokeStatic print (v1) k1))))
      (LetPrim (v5
                 (CreateFunction
                   (FunctionDefinition f () () return
                     (InvokeContinuation return (v1)))))
        (InvokeContinuation k0 (v0))))))
""";
String USED_BETA_CONT_LIN_OUT = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (LetCont ((k0 (v1)
                (LetCont ((k1 (v2)
                            (LetPrim (v3 (Constant (Int 0)))
                              (InvokeContinuation return (v3)))))
                  (InvokeStatic print (v0) k1))))
      (InvokeStatic print (v0) k0))))
""";

// Eta-cont: letcont k x = j x in K -> K[j/k].
// IR written by hand.
//
// This test is incorrectly named: with the current implementation, there is no
// eta reduction.  Instead, dead-parameter, beta-cont-lin, and dead-val
// reductions are performed, which in turn creates a second beta-cont-lin
// reduction.
//
// TODO(kmillikin): To test continuation eta reduction, use eta redexes that are
// not overlapping beta redexes.
String ETA_CONT_IN = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (LetCont ((rec k0 (v1)
                (InvokeContinuation return (v0))))
      (LetCont ((k1 (v2)
                  (InvokeContinuation k0 (v2))))
        (LetPrim (v3
                   (CreateFunction
                     (FunctionDefinition f () () return
                       (InvokeContinuation k0 (v0)))))
          (InvokeContinuation k1 (v0)))))))
""";
String ETA_CONT_OUT = """
(FunctionDefinition main () () return
  (LetPrim (v0 (Constant (Int 0)))
    (InvokeContinuation return (v0))))
""";

// Dead-parameter:
// letcont k x = E0 in E1 -> letcont k () = E0 in E1,
//    if x does not occur free in E0.

// Parameter v1 is unused in k0.
String DEAD_PARAMETER_IN = """
(FunctionDefinition main () (x) return
  (LetCont ((k0 (v0 v1 v2)
              (InvokeStatic foo (v0 v2) return)))
    (LetCont ((k1 ()
                (LetPrim (v3 (Constant (Int 0)))
                  (LetPrim (v4 (Constant (Int 1)))
                    (LetPrim (v5 (Constant (Int 2)))
                      (InvokeContinuation k0 (v3 v4 v5))))))
              (k2 ()
                (LetPrim (v6 (Constant (Int 3)))
                  (LetPrim (v7 (Constant (Int 4)))
                    (LetPrim (v8 (Constant (Int 5)))
                      (InvokeContinuation k0 (v6 v7 v8)))))))
      (Branch (IsTrue x) k1 k2))))
""";
String DEAD_PARAMETER_OUT = """
(FunctionDefinition main () (x) return
  (LetCont ((k0 (v0 v1)
              (InvokeStatic foo (v0 v1) return)))
    (LetCont ((k1 ()
                (LetPrim (v2 (Constant (Int 0)))
                  (LetPrim (v3 (Constant (Int 2)))
                    (InvokeContinuation k0 (v2 v3)))))
              (k2 ()
                (LetPrim (v4 (Constant (Int 3)))
                  (LetPrim (v5 (Constant (Int 5)))
                    (InvokeContinuation k0 (v4 v5))))))
      (Branch (IsTrue x) k1 k2))))
""";

// Create an eta-cont redex:
// Dead parameter reductions can create an eta-cont redex by removing unused
// continuation parameters and thus creating the eta redex.
String CREATE_ETA_CONT_IN = """
(FunctionDefinition main () (x) return
  (LetCont ((rec loop (v0)
              (InvokeContinuation rec loop (v0))))
    (LetCont ((created (v1 v2 v3)
                (InvokeContinuation loop (v2))))
      (LetCont ((then ()
                  (LetPrim (v4 (Constant (Int 0)))
                    (LetPrim (v5 (Constant (Int 1)))
                      (LetPrim (v6 (Constant (Int 2)))
                        (InvokeContinuation created (v4 v5 v6))))))
                (else ()
                  (LetPrim (v6 (Constant (Int 3)))
                    (LetPrim (v7 (Constant (Int 4)))
                      (LetPrim (v8 (Constant (Int 5)))
                        (InvokeContinuation created (v6 v7 v8)))))))
        (Branch (IsTrue x) then else)))))
""";
String CREATE_ETA_CONT_OUT = """
(FunctionDefinition main () (x) return
  (LetCont ((rec k0 (v0)
              (InvokeContinuation rec k0 (v0))))
    (LetCont ((k1 ()
                (LetPrim (v1 (Constant (Int 1)))
                  (InvokeContinuation k0 (v1))))
              (k2 ()
                (LetPrim (v2 (Constant (Int 4)))
                  (InvokeContinuation k0 (v2)))))
      (Branch (IsTrue x) k1 k2))))
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
  String actual = normalizeSExpr(stringifier.visit(f));

  Expect.equals(expected, actual);
}

void main() {
  testShrinkingReducer(DEAD_VAL_IN, DEAD_VAL_OUT);
  testShrinkingReducer(ITERATIVE_DEAD_VAL1_IN, ITERATIVE_DEAD_VAL1_OUT);
  testShrinkingReducer(ITERATIVE_DEAD_VAL2_IN, ITERATIVE_DEAD_VAL2_OUT);
  testShrinkingReducer(DEAD_CONT_IN, DEAD_CONT_OUT);
  testShrinkingReducer(ITERATIVE_DEAD_CONT_IN, ITERATIVE_DEAD_CONT_OUT);
  testShrinkingReducer(BETA_CONT_LIN_IN, BETA_CONT_LIN_OUT);
  testShrinkingReducer(RECURSIVE_BETA_CONT_LIN_IN, RECURSIVE_BETA_CONT_LIN_OUT);
  testShrinkingReducer(USED_BETA_CONT_LIN_IN, USED_BETA_CONT_LIN_OUT);
  testShrinkingReducer(ETA_CONT_IN, ETA_CONT_OUT);
  testShrinkingReducer(DEAD_PARAMETER_IN, DEAD_PARAMETER_OUT);
  testShrinkingReducer(CREATE_ETA_CONT_IN, CREATE_ETA_CONT_OUT);
}
