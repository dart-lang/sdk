// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'opt_redundant_phi_test.dart';

// The 'cyclic deps' IR tests removal of redundant phis with cyclic
// dependencies.
//
//  void main() {
//    var x = 0;
//    var y = x;
//    for (int i = 0; i < 10; i++) {
//      if (i == -1) x = y;
//      if (i == -1) y = x;
//    }
//    print(x);
//    print(y);
//  }

String CYCLIC_DEPS_IN = """
(FunctionDefinition main (return) (LetPrim v0 (Constant 0))
  (LetPrim v1 (Constant 0))
  (LetCont* (k0 v2 v3 v4)
    (LetCont (k1)
      (LetCont (k2 v5)
        (LetCont (k3 v6) (LetPrim v7 (Constant null))
          (InvokeContinuation return v7))
        (InvokeStatic print v3 k3))
      (InvokeStatic print v2 k2))
    (LetCont (k4) (LetPrim v8 (Constant 1))
      (LetCont (k5 v9)
        (LetCont (k6 v10)
          (LetCont (k7 v11) (LetPrim v12 (Constant 1))
            (LetCont (k8 v13)
              (LetCont (k9 v14)
                (LetCont (k10 v15)
                  (LetPrim v16 (Constant 1))
                  (LetCont (k11 v17)
                    (InvokeContinuation* k0 v11 v15 v17))
                  (InvokeMethod v4 + v16 k11))
                (LetCont (k12) (InvokeContinuation k10 v11))
                (LetCont (k13) (InvokeContinuation k10 v3))
                (Branch (IsTrue v14) k12 k13))
              (InvokeMethod v4 == v13 k9))
            (InvokeMethod v12 unary- k8))
          (LetCont (k14) (InvokeContinuation k7 v3))
          (LetCont (k15) (InvokeContinuation k7 v2))
          (Branch (IsTrue v10) k14 k15))
        (InvokeMethod v4 == v9 k6))
      (InvokeMethod v8 unary- k5))
    (LetPrim v18 (Constant 10))
    (LetCont (k16 v19) (Branch (IsTrue v19) k4 k1))
    (InvokeMethod v4 < v18 k16))
  (InvokeContinuation k0 v0 v0 v1))
""";

String CYCLIC_DEPS_OUT = """
(FunctionDefinition main (return) (LetPrim v0 (Constant 0))
  (LetPrim v1 (Constant 0))
  (LetCont* (k0 v2)
    (LetCont (k1)
      (LetCont (k2 v3)
        (LetCont (k3 v4) (LetPrim v5 (Constant null))
          (InvokeContinuation return v5))
        (InvokeStatic print v0 k3))
      (InvokeStatic print v0 k2))
    (LetCont (k4) (LetPrim v6 (Constant 1))
      (LetCont (k5 v7)
        (LetCont (k6 v8)
          (LetCont (k7) (LetPrim v9 (Constant 1))
            (LetCont (k8 v10)
              (LetCont (k9 v11)
                (LetCont (k10)
                  (LetPrim v12 (Constant 1))
                  (LetCont (k11 v13)
                    (InvokeContinuation* k0 v13))
                  (InvokeMethod v2 + v12 k11))
                (LetCont (k12) (InvokeContinuation k10))
                (LetCont (k13) (InvokeContinuation k10))
                (Branch (IsTrue v11) k12 k13))
              (InvokeMethod v2 == v10 k9))
            (InvokeMethod v9 unary- k8))
          (LetCont (k14) (InvokeContinuation k7))
          (LetCont (k15) (InvokeContinuation k7))
          (Branch (IsTrue v8) k14 k15))
        (InvokeMethod v2 == v7 k6))
      (InvokeMethod v6 unary- k5))
    (LetPrim v14 (Constant 10))
    (LetCont (k16 v15) (Branch (IsTrue v15) k4 k1))
    (InvokeMethod v2 < v14 k16))
  (InvokeContinuation k0 v1))
""";

void main() {
  testRedundantPhi(CYCLIC_DEPS_IN, CYCLIC_DEPS_OUT);
}
