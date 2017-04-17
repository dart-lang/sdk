// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.relation_assignable;

import "dart:mirrors";

import "package:expect/expect.dart";

class Superclass {}

class Subclass1 extends Superclass {}

class Subclass2 extends Superclass {}

typedef bool NumberPredicate(num x);
typedef bool IntegerPredicate(int x);
typedef bool DoublePredicate(double x);

typedef num NumberGenerator();
typedef int IntegerGenerator();
typedef double DoubleGenerator();

class A<T> {}

class B<T> extends A<T> {}

class C<T extends num> {}

test(MirrorSystem mirrors) {
  LibraryMirror coreLibrary = mirrors.findLibrary(#dart.core);
  LibraryMirror thisLibrary = mirrors.findLibrary(#test.relation_assignable);

  // Classes.
  TypeMirror Super = thisLibrary.declarations[#Superclass];
  TypeMirror Sub1 = thisLibrary.declarations[#Subclass1];
  TypeMirror Sub2 = thisLibrary.declarations[#Subclass2];
  TypeMirror Obj = coreLibrary.declarations[#Object];

  Expect.isTrue(Obj.isAssignableTo(Obj));
  Expect.isTrue(Super.isAssignableTo(Super));
  Expect.isTrue(Sub1.isAssignableTo(Sub1));
  Expect.isTrue(Sub2.isAssignableTo(Sub2));

  Expect.isTrue(Sub1.isAssignableTo(Super));
  Expect.isTrue(Super.isAssignableTo(Sub1));

  Expect.isTrue(Sub2.isAssignableTo(Super));
  Expect.isTrue(Super.isAssignableTo(Sub2));

  Expect.isFalse(Sub2.isAssignableTo(Sub1));
  Expect.isFalse(Sub1.isAssignableTo(Sub2));

  Expect.isTrue(Sub1.isAssignableTo(Obj));
  Expect.isTrue(Obj.isAssignableTo(Sub1));

  Expect.isTrue(Sub2.isAssignableTo(Obj));
  Expect.isTrue(Obj.isAssignableTo(Sub2));

  Expect.isTrue(Super.isAssignableTo(Obj));
  Expect.isTrue(Obj.isAssignableTo(Super));

  // Function typedef - argument type.
  TypeMirror Func = coreLibrary.declarations[#Function];
  TypedefMirror NumPred = thisLibrary.declarations[#NumberPredicate];
  TypedefMirror IntPred = thisLibrary.declarations[#IntegerPredicate];
  TypedefMirror DubPred = thisLibrary.declarations[#DoublePredicate];

  Expect.isTrue(Func.isAssignableTo(Func));
  Expect.isTrue(NumPred.isAssignableTo(NumPred));
  Expect.isTrue(IntPred.isAssignableTo(IntPred));
  Expect.isTrue(DubPred.isAssignableTo(DubPred));

  Expect.isTrue(NumPred.isAssignableTo(Func));
  Expect.isTrue(NumPred.isAssignableTo(IntPred));
  Expect.isTrue(NumPred.isAssignableTo(DubPred));

  Expect.isTrue(IntPred.isAssignableTo(Func));
  Expect.isTrue(IntPred.isAssignableTo(NumPred));
  Expect.isFalse(IntPred.isAssignableTo(DubPred));

  Expect.isTrue(DubPred.isAssignableTo(Func));
  Expect.isTrue(DubPred.isAssignableTo(NumPred));
  Expect.isFalse(DubPred.isAssignableTo(IntPred));

  Expect.isTrue(Func.isAssignableTo(Obj));
  Expect.isTrue(NumPred.isAssignableTo(Obj));
  Expect.isTrue(IntPred.isAssignableTo(Obj));
  Expect.isTrue(DubPred.isAssignableTo(Obj));
  Expect.isTrue(Obj.isAssignableTo(Func));
  Expect.isTrue(Obj.isAssignableTo(NumPred));
  Expect.isTrue(Obj.isAssignableTo(IntPred));
  Expect.isTrue(Obj.isAssignableTo(DubPred));

  // Function typedef - return type.
  TypedefMirror NumGen = thisLibrary.declarations[#NumberGenerator];
  TypedefMirror IntGen = thisLibrary.declarations[#IntegerGenerator];
  TypedefMirror DubGen = thisLibrary.declarations[#DoubleGenerator];

  Expect.isTrue(NumGen.isAssignableTo(NumGen));
  Expect.isTrue(IntGen.isAssignableTo(IntGen));
  Expect.isTrue(DubGen.isAssignableTo(DubGen));

  Expect.isTrue(NumGen.isAssignableTo(Func));
  Expect.isTrue(NumGen.isAssignableTo(IntGen));
  Expect.isTrue(NumGen.isAssignableTo(DubGen));

  Expect.isTrue(IntGen.isAssignableTo(Func));
  Expect.isTrue(IntGen.isAssignableTo(NumGen));
  Expect.isFalse(IntGen.isAssignableTo(DubGen));

  Expect.isTrue(DubGen.isAssignableTo(Func));
  Expect.isTrue(DubGen.isAssignableTo(NumGen));
  Expect.isFalse(DubGen.isAssignableTo(IntGen));

  Expect.isTrue(Func.isAssignableTo(Obj));
  Expect.isTrue(NumGen.isAssignableTo(Obj));
  Expect.isTrue(IntGen.isAssignableTo(Obj));
  Expect.isTrue(DubGen.isAssignableTo(Obj));
  Expect.isTrue(Obj.isAssignableTo(Func));
  Expect.isTrue(Obj.isAssignableTo(NumGen));
  Expect.isTrue(Obj.isAssignableTo(IntGen));
  Expect.isTrue(Obj.isAssignableTo(DubGen));

  // Function - argument type.
  TypeMirror NumPredRef = NumPred.referent;
  TypeMirror IntPredRef = IntPred.referent;
  TypeMirror DubPredRef = DubPred.referent;

  Expect.isTrue(Func.isAssignableTo(Func));
  Expect.isTrue(NumPredRef.isAssignableTo(NumPredRef));
  Expect.isTrue(IntPredRef.isAssignableTo(IntPredRef));
  Expect.isTrue(DubPredRef.isAssignableTo(DubPredRef));

  Expect.isTrue(NumPredRef.isAssignableTo(Func));
  Expect.isTrue(NumPredRef.isAssignableTo(IntPredRef));
  Expect.isTrue(NumPredRef.isAssignableTo(DubPredRef));

  Expect.isTrue(IntPredRef.isAssignableTo(Func));
  Expect.isTrue(IntPredRef.isAssignableTo(NumPredRef));
  Expect.isFalse(IntPredRef.isAssignableTo(DubPredRef));

  Expect.isTrue(DubPredRef.isAssignableTo(Func));
  Expect.isTrue(DubPredRef.isAssignableTo(NumPredRef));
  Expect.isFalse(DubPredRef.isAssignableTo(IntPredRef));

  Expect.isTrue(Func.isAssignableTo(Obj));
  Expect.isTrue(NumPredRef.isAssignableTo(Obj));
  Expect.isTrue(IntPredRef.isAssignableTo(Obj));
  Expect.isTrue(DubPredRef.isAssignableTo(Obj));
  Expect.isTrue(Obj.isAssignableTo(Func));
  Expect.isTrue(Obj.isAssignableTo(NumPredRef));
  Expect.isTrue(Obj.isAssignableTo(IntPredRef));
  Expect.isTrue(Obj.isAssignableTo(DubPredRef));

  // Function - return type.
  TypeMirror NumGenRef = NumGen.referent;
  TypeMirror IntGenRef = IntGen.referent;
  TypeMirror DubGenRef = DubGen.referent;

  Expect.isTrue(NumGenRef.isAssignableTo(NumGenRef));
  Expect.isTrue(IntGenRef.isAssignableTo(IntGenRef));
  Expect.isTrue(DubGenRef.isAssignableTo(DubGenRef));

  Expect.isTrue(NumGenRef.isAssignableTo(Func));
  Expect.isTrue(NumGenRef.isAssignableTo(IntGenRef));
  Expect.isTrue(NumGenRef.isAssignableTo(DubGenRef));

  Expect.isTrue(IntGenRef.isAssignableTo(Func));
  Expect.isTrue(IntGenRef.isAssignableTo(NumGenRef));
  Expect.isFalse(IntGenRef.isAssignableTo(DubGenRef));

  Expect.isTrue(DubGenRef.isAssignableTo(Func));
  Expect.isTrue(DubGenRef.isAssignableTo(NumGenRef));
  Expect.isFalse(DubGenRef.isAssignableTo(IntGenRef));

  Expect.isTrue(Func.isAssignableTo(Obj));
  Expect.isTrue(NumGenRef.isAssignableTo(Obj));
  Expect.isTrue(IntGenRef.isAssignableTo(Obj));
  Expect.isTrue(DubGenRef.isAssignableTo(Obj));
  Expect.isTrue(Obj.isAssignableTo(Func));
  Expect.isTrue(Obj.isAssignableTo(NumGenRef));
  Expect.isTrue(Obj.isAssignableTo(IntGenRef));
  Expect.isTrue(Obj.isAssignableTo(DubGenRef));

  // Function typedef / function.
  Expect.isTrue(NumPred.isAssignableTo(NumPredRef));
  Expect.isTrue(IntPred.isAssignableTo(IntPredRef));
  Expect.isTrue(DubPred.isAssignableTo(DubPredRef));
  Expect.isTrue(NumPredRef.isAssignableTo(NumPred));
  Expect.isTrue(IntPredRef.isAssignableTo(IntPred));
  Expect.isTrue(DubPredRef.isAssignableTo(DubPred));

  // Function typedef / function.
  Expect.isTrue(NumGen.isAssignableTo(NumGenRef));
  Expect.isTrue(IntGen.isAssignableTo(IntGenRef));
  Expect.isTrue(DubGen.isAssignableTo(DubGenRef));
  Expect.isTrue(NumGenRef.isAssignableTo(NumGen));
  Expect.isTrue(IntGenRef.isAssignableTo(IntGen));
  Expect.isTrue(DubGenRef.isAssignableTo(DubGen));

  // Type variable.
  TypeMirror TFromA =
      (thisLibrary.declarations[#A] as ClassMirror).typeVariables.single;
  TypeMirror TFromB =
      (thisLibrary.declarations[#B] as ClassMirror).typeVariables.single;
  TypeMirror TFromC =
      (thisLibrary.declarations[#C] as ClassMirror).typeVariables.single;

  Expect.isTrue(TFromA.isAssignableTo(TFromA));
  Expect.isTrue(TFromB.isAssignableTo(TFromB));
  Expect.isTrue(TFromC.isAssignableTo(TFromC));

  Expect.isFalse(TFromA.isAssignableTo(TFromB));
  Expect.isFalse(TFromA.isAssignableTo(TFromC));
  Expect.isFalse(TFromB.isAssignableTo(TFromA));
  Expect.isFalse(TFromB.isAssignableTo(TFromC));
  Expect.isFalse(TFromC.isAssignableTo(TFromA));
  Expect.isFalse(TFromC.isAssignableTo(TFromB));

  TypeMirror Num = coreLibrary.declarations[#num];
  Expect.isTrue(TFromC.isAssignableTo(Num));
  Expect.isTrue(Num.isAssignableTo(TFromC));

  // dynamic & void.
  TypeMirror Dynamic = mirrors.dynamicType;
  Expect.isTrue(Dynamic.isAssignableTo(Dynamic));
  Expect.isTrue(Obj.isAssignableTo(Dynamic));
  Expect.isTrue(Super.isAssignableTo(Dynamic));
  Expect.isTrue(Sub1.isAssignableTo(Dynamic));
  Expect.isTrue(Sub2.isAssignableTo(Dynamic));
  Expect.isTrue(NumPred.isAssignableTo(Dynamic));
  Expect.isTrue(IntPred.isAssignableTo(Dynamic));
  Expect.isTrue(DubPred.isAssignableTo(Dynamic));
  Expect.isTrue(NumPredRef.isAssignableTo(Dynamic));
  Expect.isTrue(IntPredRef.isAssignableTo(Dynamic));
  Expect.isTrue(DubPredRef.isAssignableTo(Dynamic));
  Expect.isTrue(NumGen.isAssignableTo(Dynamic));
  Expect.isTrue(IntGen.isAssignableTo(Dynamic));
  Expect.isTrue(DubGen.isAssignableTo(Dynamic));
  Expect.isTrue(NumGenRef.isAssignableTo(Dynamic));
  Expect.isTrue(IntGenRef.isAssignableTo(Dynamic));
  Expect.isTrue(DubGenRef.isAssignableTo(Dynamic));
  Expect.isTrue(TFromA.isAssignableTo(Dynamic));
  Expect.isTrue(TFromB.isAssignableTo(Dynamic));
  Expect.isTrue(TFromC.isAssignableTo(Dynamic));
  Expect.isTrue(Dynamic.isAssignableTo(Obj));
  Expect.isTrue(Dynamic.isAssignableTo(Super));
  Expect.isTrue(Dynamic.isAssignableTo(Sub1));
  Expect.isTrue(Dynamic.isAssignableTo(Sub2));
  Expect.isTrue(Dynamic.isAssignableTo(NumPred));
  Expect.isTrue(Dynamic.isAssignableTo(IntPred));
  Expect.isTrue(Dynamic.isAssignableTo(DubPred));
  Expect.isTrue(Dynamic.isAssignableTo(NumPredRef));
  Expect.isTrue(Dynamic.isAssignableTo(IntPredRef));
  Expect.isTrue(Dynamic.isAssignableTo(DubPredRef));
  Expect.isTrue(Dynamic.isAssignableTo(NumGen));
  Expect.isTrue(Dynamic.isAssignableTo(IntGen));
  Expect.isTrue(Dynamic.isAssignableTo(DubGen));
  Expect.isTrue(Dynamic.isAssignableTo(NumGenRef));
  Expect.isTrue(Dynamic.isAssignableTo(IntGenRef));
  Expect.isTrue(Dynamic.isAssignableTo(DubGenRef));
  Expect.isTrue(Dynamic.isAssignableTo(TFromA));
  Expect.isTrue(Dynamic.isAssignableTo(TFromB));
  Expect.isTrue(Dynamic.isAssignableTo(TFromC));

  TypeMirror Void = mirrors.voidType;
  Expect.isTrue(Void.isAssignableTo(Void));
  Expect.isFalse(Obj.isAssignableTo(Void));
  Expect.isFalse(Super.isAssignableTo(Void));
  Expect.isFalse(Sub1.isAssignableTo(Void));
  Expect.isFalse(Sub2.isAssignableTo(Void));
  Expect.isFalse(NumPred.isAssignableTo(Void));
  Expect.isFalse(IntPred.isAssignableTo(Void));
  Expect.isFalse(DubPred.isAssignableTo(Void));
  Expect.isFalse(NumPredRef.isAssignableTo(Void));
  Expect.isFalse(IntPredRef.isAssignableTo(Void));
  Expect.isFalse(DubPredRef.isAssignableTo(Void));
  Expect.isFalse(NumGen.isAssignableTo(Void));
  Expect.isFalse(IntGen.isAssignableTo(Void));
  Expect.isFalse(DubGen.isAssignableTo(Void));
  Expect.isFalse(NumGenRef.isAssignableTo(Void));
  Expect.isFalse(IntGenRef.isAssignableTo(Void));
  Expect.isFalse(DubGenRef.isAssignableTo(Void));
  Expect.isFalse(TFromA.isAssignableTo(Void));
  Expect.isFalse(TFromB.isAssignableTo(Void));
  Expect.isFalse(TFromC.isAssignableTo(Void));
  Expect.isFalse(Void.isAssignableTo(Obj));
  Expect.isFalse(Void.isAssignableTo(Super));
  Expect.isFalse(Void.isAssignableTo(Sub1));
  Expect.isFalse(Void.isAssignableTo(Sub2));
  Expect.isFalse(Void.isAssignableTo(NumPred));
  Expect.isFalse(Void.isAssignableTo(IntPred));
  Expect.isFalse(Void.isAssignableTo(DubPred));
  Expect.isFalse(Void.isAssignableTo(NumPredRef));
  Expect.isFalse(Void.isAssignableTo(IntPredRef));
  Expect.isFalse(Void.isAssignableTo(DubPredRef));
  Expect.isFalse(Void.isAssignableTo(NumGen));
  Expect.isFalse(Void.isAssignableTo(IntGen));
  Expect.isFalse(Void.isAssignableTo(DubGen));
  Expect.isFalse(Void.isAssignableTo(NumGenRef));
  Expect.isFalse(Void.isAssignableTo(IntGenRef));
  Expect.isFalse(Void.isAssignableTo(DubGenRef));
  Expect.isFalse(Void.isAssignableTo(TFromA));
  Expect.isFalse(Void.isAssignableTo(TFromB));
  Expect.isFalse(Void.isAssignableTo(TFromC));

  Expect.isTrue(Dynamic.isAssignableTo(Void));
  Expect.isTrue(Void.isAssignableTo(Dynamic));
}

main() {
  test(currentMirrorSystem());
}
