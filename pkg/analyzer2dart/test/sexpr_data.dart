// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Test data for sexpr_test.
library test.sexpr.data;

import 'test_helper.dart';

const List<Group> TEST_DATA = const [
  const Group('Empty main', const [
    const TestSpec('''
main() {}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant NullConstant))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
foo() {}
main() {
  foo();
}
''', '''
(FunctionDefinition main ( return)
  (LetCont (k0 v0)
    (LetPrim v1 (Constant NullConstant))
    (InvokeContinuation return v1))
  (InvokeStatic foo  k0))
''')
  ]),

  const Group('Literals', const [
    const TestSpec('''
main() {
  return 0;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main() {
  return 1.5;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant DoubleConstant(1.5)))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main() {
  return true;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant BoolConstant(true)))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main() {
  return false;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant BoolConstant(false)))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main() {
  return "a";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant StringConstant("a")))
  (InvokeContinuation return v0))
'''),
  ]),

  const Group('Parameters', const [
    const TestSpec('''
main(args) {}
''', '''
(FunctionDefinition main (args return)
  (LetPrim v0 (Constant NullConstant))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main(a, b) {}
''', '''
(FunctionDefinition main (a b return)
  (LetPrim v0 (Constant NullConstant))
  (InvokeContinuation return v0))
'''),
  ]),

  const Group('Pass arguments', const [
    const TestSpec('''
foo(a) {}
main() {
  foo(null);
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant NullConstant))
  (LetCont (k0 v1)
    (LetPrim v2 (Constant NullConstant))
    (InvokeContinuation return v2))
  (InvokeStatic foo v0 k0))
'''),

    const TestSpec('''
bar(b, c) {}
foo(a) {}
main() {
  foo(null);
  bar(0, "");
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant NullConstant))
  (LetCont (k0 v1)
    (LetPrim v2 (Constant IntConstant(0)))
    (LetPrim v3 (Constant StringConstant("")))
    (LetCont (k1 v4)
      (LetPrim v5 (Constant NullConstant))
      (InvokeContinuation return v5))
    (InvokeStatic bar v2 v3 k1))
  (InvokeStatic foo v0 k0))
'''),

    const TestSpec('''
foo(a) {}
main() {
  return foo(null);
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant NullConstant))
  (LetCont (k0 v1)
    (InvokeContinuation return v1))
  (InvokeStatic foo v0 k0))
'''),
  ]),

  const Group('Local variables', const [
    const TestSpec('''
main() {
  var a;
  return a;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant NullConstant))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main() {
  var a = 0;
  return a;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main(a) {
  return a;
}
''', '''
(FunctionDefinition main (a return)
  (InvokeContinuation return a))
'''),
    ]),

  const Group('Local variable writes', const <TestSpec>[
    const TestSpec('''
main() {
  var a;
  a = 10;
  return a;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant NullConstant))
  (LetPrim v1 (Constant IntConstant(10)))
  (InvokeContinuation return v1))
'''),

    const TestSpec('''
main() {
  var a = 0;
  a = 10;
  return a;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant IntConstant(10)))
  (InvokeContinuation return v1))
'''),

    const TestSpec('''
main() {
  var a = 0;
  print(a);
  a = "";
  print(a);
  return a;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1)
    (LetPrim v2 (Constant StringConstant("")))
    (LetCont (k1 v3)
      (InvokeContinuation return v2))
    (InvokeStatic print v2 k1))
  (InvokeStatic print v0 k0))
'''),

    const TestSpec('''
main(a) {
  print(a);
  a = "";
  print(a);
  return a;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (LetPrim v1 (Constant StringConstant("")))
    (LetCont (k1 v2)
      (InvokeContinuation return v1))
    (InvokeStatic print v1 k1))
  (InvokeStatic print a k0))
'''),

    const TestSpec('''
main(a) {
  if (a) {
    a = "";
  }
  print(a);
  return a;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (LetCont (k1 v1)
      (InvokeContinuation return v0))
    (InvokeStatic print v0 k1))
  (LetCont (k2)
    (LetPrim v2 (Constant StringConstant("")))
    (InvokeContinuation k0 v2))
  (LetCont (k3)
    (InvokeContinuation k0 a))
  (Branch (IsTrue a) k2 k3))
'''),
  ]),

  const Group('Dynamic access', const [
    const TestSpec('''
main(a) {
  return a.foo;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (InvokeContinuation return v0))
  (InvokeMethod a foo  k0))
'''),

    const TestSpec('''
main() {
  var a = "";
  return a.foo;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant StringConstant("")))
  (LetCont (k0 v1)
    (InvokeContinuation return v1))
  (InvokeMethod v0 foo  k0))
'''),
    ]),

  const Group('Dynamic invocation', const [
    const TestSpec('''
main(a) {
  return a.foo(0);
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1)
    (InvokeContinuation return v1))
  (InvokeMethod a foo v0 k0))
'''),

    const TestSpec('''
main() {
  var a = "";
  return a.foo(0, 1);
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant StringConstant("")))
  (LetPrim v1 (Constant IntConstant(0)))
  (LetPrim v2 (Constant IntConstant(1)))
  (LetCont (k0 v3)
    (InvokeContinuation return v3))
  (InvokeMethod v0 foo v1 v2 k0))
'''),
    ]),

  const Group('Binary expressions', const [
    const TestSpec('''
main() {
  return 0 + "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 + v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 - "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 - v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 * "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 * v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 / "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 / v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 ~/ "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 ~/ v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 < "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 < v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 <= "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 <= v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 > "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 > v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 >= "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 >= v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 << "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 << v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 >> "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 >> v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 & "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 & v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 | "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 | v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 ^ "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 ^ v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 == "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (InvokeContinuation return v2))
  (InvokeMethod v0 == v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 != "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (LetCont (k1 v3)
      (InvokeContinuation return v3))
    (LetCont (k2)
      (LetPrim v4 (Constant BoolConstant(false)))
      (InvokeContinuation k1 v4))
    (LetCont (k3)
      (LetPrim v5 (Constant BoolConstant(true)))
      (InvokeContinuation k1 v5))
    (Branch (IsTrue v2) k2 k3))
  (InvokeMethod v0 == v1 k0))
'''),

    const TestSpec('''
main() {
  return 0 && "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1)
    (InvokeContinuation return v1))
  (LetCont (k1)
    (LetPrim v2 (Constant StringConstant("")))
    (LetCont (k2)
      (LetPrim v3 (Constant BoolConstant(true)))
      (InvokeContinuation k0 v3))
    (LetCont (k3)
      (LetPrim v4 (Constant BoolConstant(false)))
      (InvokeContinuation k0 v4))
    (Branch (IsTrue v2) k2 k3))
  (LetCont (k4)
    (LetPrim v5 (Constant BoolConstant(false)))
    (InvokeContinuation k0 v5))
  (Branch (IsTrue v0) k1 k4))
'''),

    const TestSpec('''
main() {
  return 0 || "";
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont (k0 v1)
    (InvokeContinuation return v1))
  (LetCont (k1)
    (LetPrim v2 (Constant BoolConstant(true)))
    (InvokeContinuation k0 v2))
  (LetCont (k2)
    (LetPrim v3 (Constant StringConstant("")))
    (LetCont (k3)
      (LetPrim v4 (Constant BoolConstant(true)))
      (InvokeContinuation k0 v4))
    (LetCont (k4)
      (LetPrim v5 (Constant BoolConstant(false)))
      (InvokeContinuation k0 v5))
    (Branch (IsTrue v3) k3 k4))
  (Branch (IsTrue v0) k1 k2))
'''),

    const TestSpec('''
main() {
  return 0 + "" * 2;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetPrim v2 (Constant IntConstant(2)))
  (LetCont (k0 v3)
    (LetCont (k1 v4)
      (InvokeContinuation return v4))
    (InvokeMethod v0 + v3 k1))
  (InvokeMethod v1 * v2 k0))
'''),

    const TestSpec('''
main() {
  return 0 * "" + 2;
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("")))
  (LetCont (k0 v2)
    (LetPrim v3 (Constant IntConstant(2)))
    (LetCont (k1 v4)
      (InvokeContinuation return v4))
    (InvokeMethod v2 + v3 k1))
  (InvokeMethod v0 * v1 k0))
'''),
    ]),

  const Group('If statement', const [
    const TestSpec('''
main(a) {
  if (a) {
    print(0);
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0)
    (LetPrim v0 (Constant NullConstant))
    (InvokeContinuation return v0))
  (LetCont (k1)
    (LetPrim v1 (Constant IntConstant(0)))
    (LetCont (k2 v2)
      (InvokeContinuation k0 ))
    (InvokeStatic print v1 k2))
  (LetCont (k3)
    (InvokeContinuation k0 ))
  (Branch (IsTrue a) k1 k3))
'''),

    const TestSpec('''
main(a) {
  if (a) {
    print(0);
  } else {
    print(1);
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0)
    (LetPrim v0 (Constant NullConstant))
    (InvokeContinuation return v0))
  (LetCont (k1)
    (LetPrim v1 (Constant IntConstant(0)))
    (LetCont (k2 v2)
      (InvokeContinuation k0 ))
    (InvokeStatic print v1 k2))
  (LetCont (k3)
    (LetPrim v3 (Constant IntConstant(1)))
    (LetCont (k4 v4)
      (InvokeContinuation k0 ))
    (InvokeStatic print v3 k4))
  (Branch (IsTrue a) k1 k3))
'''),

    const TestSpec('''
main(a) {
  if (a) {
    print(0);
  } else {
    print(1);
    print(2);
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0)
    (LetPrim v0 (Constant NullConstant))
    (InvokeContinuation return v0))
  (LetCont (k1)
    (LetPrim v1 (Constant IntConstant(0)))
    (LetCont (k2 v2)
      (InvokeContinuation k0 ))
    (InvokeStatic print v1 k2))
  (LetCont (k3)
    (LetPrim v3 (Constant IntConstant(1)))
    (LetCont (k4 v4)
      (LetPrim v5 (Constant IntConstant(2)))
      (LetCont (k5 v6)
        (InvokeContinuation k0 ))
      (InvokeStatic print v5 k5))
    (InvokeStatic print v3 k4))
  (Branch (IsTrue a) k1 k3))
'''),
    ]),

  const Group('Conditional expression', const [
    const TestSpec('''
main(a) {
  return a ? print(0) : print(1);
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (InvokeContinuation return v0))
  (LetCont (k1)
    (LetPrim v1 (Constant IntConstant(0)))
    (LetCont (k2 v2)
      (InvokeContinuation k0 v2))
    (InvokeStatic print v1 k2))
  (LetCont (k3)
    (LetPrim v3 (Constant IntConstant(1)))
    (LetCont (k4 v4)
      (InvokeContinuation k0 v4))
    (InvokeStatic print v3 k4))
  (Branch (IsTrue a) k1 k3))
'''),
    ]),


  // These test that unreachable statements are skipped within a block.
  const Group('Block statements', const <TestSpec>[
    const TestSpec('''
main(a) {
  return 0;
  return 1;
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant IntConstant(0)))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main(a) {
  if (a) {
    return 0;
    return 1;
  } else {
    return 2;
    return 3;
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0)
    (LetPrim v0 (Constant IntConstant(0)))
    (InvokeContinuation return v0))
  (LetCont (k1)
    (LetPrim v1 (Constant IntConstant(2)))
    (InvokeContinuation return v1))
  (Branch (IsTrue a) k0 k1))
'''),

    const TestSpec('''
main(a) {
  if (a) {
    print(0);
    return 0;
    return 1;
  } else {
    print(2);
    return 2;
    return 3;
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0)
    (LetPrim v0 (Constant IntConstant(0)))
    (LetCont (k1 v1)
      (LetPrim v2 (Constant IntConstant(0)))
      (InvokeContinuation return v2))
    (InvokeStatic print v0 k1))
  (LetCont (k2)
    (LetPrim v3 (Constant IntConstant(2)))
    (LetCont (k3 v4)
      (LetPrim v5 (Constant IntConstant(2)))
      (InvokeContinuation return v5))
    (InvokeStatic print v3 k3))
  (Branch (IsTrue a) k0 k2))
'''),
  ]),

  const Group('Constructor invocation', const <TestSpec>[
    const TestSpec('''
main(a) {
  new Object();
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (LetPrim v1 (Constant NullConstant))
    (InvokeContinuation return v1))
  (InvokeConstructor Object  k0))
'''),

    const TestSpec('''
main(a) {
  new Deprecated("");
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant StringConstant("")))
  (LetCont (k0 v1)
    (LetPrim v2 (Constant NullConstant))
    (InvokeContinuation return v2))
  (InvokeConstructor Deprecated v0 k0))
'''),
  ]),

  const Group('List literal', const <TestSpec>[
    const TestSpec('''
main() {
  return [];
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (LiteralList ()))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main() {
  return [0];
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (LiteralList (v0)))
  (InvokeContinuation return v1))
'''),

    const TestSpec('''
main(a) {
  return [0, 1, a];
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant IntConstant(1)))
  (LetPrim v2 (LiteralList (v0 v1 a)))
  (InvokeContinuation return v2))
'''),

    const TestSpec('''
main(a) {
  return [0, [1], [a, [3]]];
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant IntConstant(1)))
  (LetPrim v2 (LiteralList (v1)))
  (LetPrim v3 (Constant IntConstant(3)))
  (LetPrim v4 (LiteralList (v3)))
  (LetPrim v5 (LiteralList (a v4)))
  (LetPrim v6 (LiteralList (v0 v2 v5)))
  (InvokeContinuation return v6))
'''),
  ]),

  const Group('Map literal', const <TestSpec>[
    const TestSpec('''
main() {
  return {};
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (LiteralMap () ()))
  (InvokeContinuation return v0))
'''),

    const TestSpec('''
main() {
  return {"a": 0};
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant StringConstant("a")))
  (LetPrim v1 (Constant IntConstant(0)))
  (LetPrim v2 (LiteralMap (v0) (v1)))
  (InvokeContinuation return v2))
'''),

    const TestSpec('''
main(a) {
  return {"a": 0, "b": 1, "c": a};
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant StringConstant("a")))
  (LetPrim v1 (Constant IntConstant(0)))
  (LetPrim v2 (Constant StringConstant("b")))
  (LetPrim v3 (Constant IntConstant(1)))
  (LetPrim v4 (Constant StringConstant("c")))
  (LetPrim v5 (LiteralMap (v0 v2 v4) (v1 v3 a)))
  (InvokeContinuation return v5))
'''),

    const TestSpec('''
main(a) {
  return {0: "a", 1: {2: "b"}, a: {3: "c"}};
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetPrim v1 (Constant StringConstant("a")))
  (LetPrim v2 (Constant IntConstant(1)))
  (LetPrim v3 (Constant IntConstant(2)))
  (LetPrim v4 (Constant StringConstant("b")))
  (LetPrim v5 (LiteralMap (v3) (v4)))
  (LetPrim v6 (Constant IntConstant(3)))
  (LetPrim v7 (Constant StringConstant("c")))
  (LetPrim v8 (LiteralMap (v6) (v7)))
  (LetPrim v9 (LiteralMap (v0 v2 a) (v1 v5 v8)))
  (InvokeContinuation return v9))
'''),
  ]),

  const Group('For loop', const <TestSpec>[
    const TestSpec('''
main() {
  for (;;) {}
}
''', '''
(FunctionDefinition main ( return)
  (LetCont* (k0)
    (LetPrim v0 (Constant BoolConstant(true)))
    (LetCont (k1)
      (LetPrim v1 (Constant NullConstant))
      (InvokeContinuation return v1))
    (LetCont (k2)
      (InvokeContinuation* k0 ))
    (Branch (IsTrue v0) k2 k1))
  (InvokeContinuation k0 ))
'''),

const TestSpec('''
main() {
  for (var i = 0; i < 10; i = i + 1) {
    print(i);
  }
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont* (k0 v1)
    (LetPrim v2 (Constant IntConstant(10)))
    (LetCont (k1 v3)
      (LetCont (k2)
        (LetPrim v4 (Constant NullConstant))
        (InvokeContinuation return v4))
      (LetCont (k3)
        (LetCont (k4 v5)
          (LetPrim v6 (Constant IntConstant(1)))
          (LetCont (k5 v7)
            (InvokeContinuation* k0 v7))
          (InvokeMethod v1 + v6 k5))
        (InvokeStatic print v1 k4))
      (Branch (IsTrue v3) k3 k2))
    (InvokeMethod v1 < v2 k1))
  (InvokeContinuation k0 v0))
'''),

const TestSpec('''
main(i) {
  for (i = 0; i < 10; i = i + 1) {
    print(i);
  }
}
''', '''
(FunctionDefinition main (i return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont* (k0 v1)
    (LetPrim v2 (Constant IntConstant(10)))
    (LetCont (k1 v3)
      (LetCont (k2)
        (LetPrim v4 (Constant NullConstant))
        (InvokeContinuation return v4))
      (LetCont (k3)
        (LetCont (k4 v5)
          (LetPrim v6 (Constant IntConstant(1)))
          (LetCont (k5 v7)
            (InvokeContinuation* k0 v7))
          (InvokeMethod v1 + v6 k5))
        (InvokeStatic print v1 k4))
      (Branch (IsTrue v3) k3 k2))
    (InvokeMethod v1 < v2 k1))
  (InvokeContinuation k0 v0))
'''),
  ]),

  const Group('While loop', const <TestSpec>[
    const TestSpec('''
main() {
  while (true) {}
}
''', '''
(FunctionDefinition main ( return)
  (LetCont* (k0)
    (LetPrim v0 (Constant BoolConstant(true)))
    (LetCont (k1)
      (LetPrim v1 (Constant NullConstant))
      (InvokeContinuation return v1))
    (LetCont (k2)
      (InvokeContinuation* k0 ))
    (Branch (IsTrue v0) k2 k1))
  (InvokeContinuation k0 ))
'''),

const TestSpec('''
main() {
  var i = 0;
  while (i < 10) {
    print(i);
    i = i + 1;
  }
}
''', '''
(FunctionDefinition main ( return)
  (LetPrim v0 (Constant IntConstant(0)))
  (LetCont* (k0 v1)
    (LetPrim v2 (Constant IntConstant(10)))
    (LetCont (k1 v3)
      (LetCont (k2)
        (LetPrim v4 (Constant NullConstant))
        (InvokeContinuation return v4))
      (LetCont (k3)
        (LetCont (k4 v5)
          (LetPrim v6 (Constant IntConstant(1)))
          (LetCont (k5 v7)
            (InvokeContinuation* k0 v7))
          (InvokeMethod v1 + v6 k5))
        (InvokeStatic print v1 k4))
      (Branch (IsTrue v3) k3 k2))
    (InvokeMethod v1 < v2 k1))
  (InvokeContinuation k0 v0))
'''),
  ]),

  const Group('Type operators', const <TestSpec>[
    const TestSpec('''
main(a) {
  return a is String;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (InvokeContinuation return v0))
  (TypeOperator is a String k0))
'''),

    const TestSpec('''
main(a) {
  return a is List<String>;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (InvokeContinuation return v0))
  (TypeOperator is a List<String> k0))
'''),

    const TestSpec('''
main(a) {
  return a is Comparator<String>;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (InvokeContinuation return v0))
  (TypeOperator is a Comparator<String> k0))
'''),

  const TestSpec('''
main(a) {
  return a is! String;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (LetCont (k1 v1)
      (InvokeContinuation return v1))
    (LetCont (k2)
      (LetPrim v2 (Constant BoolConstant(false)))
      (InvokeContinuation k1 v2))
    (LetCont (k3)
      (LetPrim v3 (Constant BoolConstant(true)))
      (InvokeContinuation k1 v3))
    (Branch (IsTrue v0) k2 k3))
  (TypeOperator is a String k0))
'''),

const TestSpec('''
main(a) {
  return a as String;
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (InvokeContinuation return v0))
  (TypeOperator as a String k0))
'''),
  ]),

  const Group('For in loop', const <TestSpec>[
// TODO(johnniwinther): Add tests for `i` as top-level, static and instance
// fields.
    const TestSpec('''
main(a) {
  for (var i in a) {
    print(i);
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (LetCont* (k1 v1)
      (LetCont (k2 v2)
        (LetCont (k3)
          (LetPrim v3 (Constant NullConstant))
          (InvokeContinuation return v3))
        (LetCont (k4)
          (LetPrim v4 (Constant NullConstant))
          (LetCont (k5 v5)
            (LetCont (k6 v6)
              (InvokeContinuation* k1 v1))
            (InvokeStatic print v5 k6))
          (InvokeMethod v0 current  k5))
        (Branch (IsTrue v2) k4 k3))
      (InvokeMethod v0 moveNext  k2))
    (InvokeContinuation k1 a))
  (InvokeMethod a iterator  k0))
'''),

    const TestSpec('''
main(a) {
  for (var i in a) {
    print(i);
    i = 0;
    print(i);
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetCont (k0 v0)
    (LetCont* (k1 v1)
      (LetCont (k2 v2)
        (LetCont (k3)
          (LetPrim v3 (Constant NullConstant))
          (InvokeContinuation return v3))
        (LetCont (k4)
          (LetPrim v4 (Constant NullConstant))
          (LetCont (k5 v5)
            (LetCont (k6 v6)
              (LetPrim v7 (Constant IntConstant(0)))
              (LetCont (k7 v8)
                (InvokeContinuation* k1 v1))
              (InvokeStatic print v7 k7))
            (InvokeStatic print v5 k6))
          (InvokeMethod v0 current  k5))
        (Branch (IsTrue v2) k4 k3))
      (InvokeMethod v0 moveNext  k2))
    (InvokeContinuation k1 a))
  (InvokeMethod a iterator  k0))
'''),

    const TestSpec('''
main(a) {
  var i;
  for (i in a) {
    print(i);
  }
}
''', '''
(FunctionDefinition main (a return)
  (LetPrim v0 (Constant NullConstant))
  (LetCont (k0 v1)
    (LetCont* (k1 v2 v3)
      (LetCont (k2 v4)
        (LetCont (k3)
          (LetPrim v5 (Constant NullConstant))
          (InvokeContinuation return v5))
        (LetCont (k4)
          (LetCont (k5 v6)
            (LetCont (k6 v7)
              (InvokeContinuation* k1 v2 v6))
            (InvokeStatic print v6 k6))
          (InvokeMethod v1 current  k5))
        (Branch (IsTrue v4) k4 k3))
      (InvokeMethod v1 moveNext  k2))
    (InvokeContinuation k1 a v0))
  (InvokeMethod a iterator  k0))
'''),
  ]),
];
