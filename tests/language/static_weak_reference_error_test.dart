// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test errors for incorrect usage of 'weak-tearoff-reference' pragma.

@pragma('weak-tearoff-reference')
Function? validWeakRef(Function? x) => x;

@pragma('weak-tearoff-reference')
Function? weakRef1({Function? x}) => x;
//        ^
// [cfe] Weak reference should take one required positional argument.

@pragma('weak-tearoff-reference')
Function? weakRef2({required Function? x}) => x;
//        ^
// [cfe] Weak reference should take one required positional argument.

@pragma('weak-tearoff-reference')
Function? weakRef3([Function? x]) => x;
//        ^
// [cfe] Weak reference should take one required positional argument.

@pragma('weak-tearoff-reference')
Function? weakRef4(Function? x, int y) => x;
//        ^
// [cfe] Weak reference should take one required positional argument.

@pragma('weak-tearoff-reference')
Function? weakRef5(Function? x, {int? y}) => x;
//        ^
// [cfe] Weak reference should take one required positional argument.

@pragma('weak-tearoff-reference')
Function weakRef6(Function x) => x;
//       ^
// [cfe] Return type of a weak reference should be nullable.

@pragma('weak-tearoff-reference')
Function weakRef7(Function x) => x;
//       ^
// [cfe] Return type of a weak reference should be nullable.

@pragma('weak-tearoff-reference')
dynamic validWeakRef8(dynamic x) => x;

@pragma('weak-tearoff-reference')
Function? weakRef9(void Function() x) => x;
//        ^
// [cfe] Return and argument types of a weak reference should match.

@pragma('weak-tearoff-reference')
Function? weakRef10(Function x) => x;
//        ^
// [cfe] Return and argument types of a weak reference should match.

class A {
  @pragma('weak-tearoff-reference')
  external static T Function()? validWeakReference11<T>(T Function()? x);

  @pragma('weak-tearoff-reference')
  external T Function()? weakReference12<T>(T Function()? x);
//                       ^
// [cfe] Weak reference pragma can be used on a static method only.
}

class B {
  static int validTarget() => 42;

  B();
  B.bar();
  factory B.baz() => B();
  int instanceMethod() => 42;

  static int arg1(int x) => 42;
  static int arg2([int? x]) => 42;
  static int arg3({int? x}) => 42;
  static int arg4<T>() => 42;
}

void main() {
  validWeakRef(B.validTarget); // OK

  validWeakRef(B.new);
//^
// [cfe] The target of weak reference should be a tearoff of a static method.

  validWeakRef(B.bar);
//^
// [cfe] The target of weak reference should be a tearoff of a static method.

  validWeakRef(B.baz);
//^
// [cfe] The target of weak reference should be a tearoff of a static method.

  validWeakRef(B().instanceMethod);
//^
// [cfe] The target of weak reference should be a tearoff of a static method.

  final x = B.validTarget;
  validWeakRef(x);
//^
// [cfe] The target of weak reference should be a tearoff of a static method.

  const y = B.validTarget;
  validWeakRef(y); // OK

  validWeakRef(B.arg1);
//^
// [cfe] The target of weak reference should not take parameters.

  validWeakRef(B.arg2);
//^
// [cfe] The target of weak reference should not take parameters.

  validWeakRef(B.arg3);
//^
// [cfe] The target of weak reference should not take parameters.

  validWeakRef(B.arg4);
//^
// [cfe] The target of weak reference should not take parameters.
}
