// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.relation_subtype;

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
  LibraryMirror thisLibrary = mirrors.findLibrary(#test.relation_subtype);

  // Classes.
  TypeMirror Super = thisLibrary.declarations[#Superclass];
  TypeMirror Sub1 = thisLibrary.declarations[#Subclass1];
  TypeMirror Sub2 = thisLibrary.declarations[#Subclass2];
  TypeMirror Obj = coreLibrary.declarations[#Object];

  Expect.isTrue(Obj.isSubtypeOf(Obj));
  Expect.isTrue(Super.isSubtypeOf(Super));
  Expect.isTrue(Sub1.isSubtypeOf(Sub1));
  Expect.isTrue(Sub2.isSubtypeOf(Sub2));

  Expect.isTrue(Sub1.isSubtypeOf(Super));
  Expect.isFalse(Super.isSubtypeOf(Sub1));

  Expect.isTrue(Sub2.isSubtypeOf(Super));
  Expect.isFalse(Super.isSubtypeOf(Sub2));

  Expect.isFalse(Sub2.isSubtypeOf(Sub1));
  Expect.isFalse(Sub1.isSubtypeOf(Sub2));

  Expect.isTrue(Sub1.isSubtypeOf(Obj));
  Expect.isFalse(Obj.isSubtypeOf(Sub1));

  Expect.isTrue(Sub2.isSubtypeOf(Obj));
  Expect.isFalse(Obj.isSubtypeOf(Sub2));

  Expect.isTrue(Super.isSubtypeOf(Obj));
  Expect.isFalse(Obj.isSubtypeOf(Super));

  // Function typedef - argument type.
  TypeMirror Func = coreLibrary.declarations[#Function];
  TypedefMirror NumPred = thisLibrary.declarations[#NumberPredicate];
  TypedefMirror IntPred = thisLibrary.declarations[#IntegerPredicate];
  TypedefMirror DubPred = thisLibrary.declarations[#DoublePredicate];

  Expect.isTrue(Func.isSubtypeOf(Func));
  Expect.isTrue(NumPred.isSubtypeOf(NumPred));
  Expect.isTrue(IntPred.isSubtypeOf(IntPred));
  Expect.isTrue(DubPred.isSubtypeOf(DubPred));

  Expect.isTrue(NumPred.isSubtypeOf(Func));
  Expect.isTrue(NumPred.isSubtypeOf(IntPred));
  Expect.isTrue(NumPred.isSubtypeOf(DubPred));

  Expect.isTrue(IntPred.isSubtypeOf(Func));
  Expect.isTrue(IntPred.isSubtypeOf(NumPred));
  Expect.isFalse(IntPred.isSubtypeOf(DubPred));

  Expect.isTrue(DubPred.isSubtypeOf(Func));
  Expect.isTrue(DubPred.isSubtypeOf(NumPred));
  Expect.isFalse(DubPred.isSubtypeOf(IntPred));

  Expect.isTrue(Func.isSubtypeOf(Obj));
  Expect.isTrue(NumPred.isSubtypeOf(Obj));
  Expect.isTrue(IntPred.isSubtypeOf(Obj));
  Expect.isTrue(DubPred.isSubtypeOf(Obj));

  // Function typedef - return type.
  TypedefMirror NumGen = thisLibrary.declarations[#NumberGenerator];
  TypedefMirror IntGen = thisLibrary.declarations[#IntegerGenerator];
  TypedefMirror DubGen = thisLibrary.declarations[#DoubleGenerator];

  Expect.isTrue(NumGen.isSubtypeOf(NumGen));
  Expect.isTrue(IntGen.isSubtypeOf(IntGen));
  Expect.isTrue(DubGen.isSubtypeOf(DubGen));

  Expect.isTrue(NumGen.isSubtypeOf(Func));
  Expect.isTrue(NumGen.isSubtypeOf(IntGen));
  Expect.isTrue(NumGen.isSubtypeOf(DubGen));

  Expect.isTrue(IntGen.isSubtypeOf(Func));
  Expect.isTrue(IntGen.isSubtypeOf(NumGen));
  Expect.isFalse(IntGen.isSubtypeOf(DubGen));

  Expect.isTrue(DubGen.isSubtypeOf(Func));
  Expect.isTrue(DubGen.isSubtypeOf(NumGen));
  Expect.isFalse(DubGen.isSubtypeOf(IntGen));

  Expect.isTrue(Func.isSubtypeOf(Obj));
  Expect.isTrue(NumGen.isSubtypeOf(Obj));
  Expect.isTrue(IntGen.isSubtypeOf(Obj));
  Expect.isTrue(DubGen.isSubtypeOf(Obj));

  // Function - argument type.
  TypeMirror NumPredRef = NumPred.referent;
  TypeMirror IntPredRef = IntPred.referent;
  TypeMirror DubPredRef = DubPred.referent;

  Expect.isTrue(Func.isSubtypeOf(Func));
  Expect.isTrue(NumPredRef.isSubtypeOf(NumPredRef));
  Expect.isTrue(IntPredRef.isSubtypeOf(IntPredRef));
  Expect.isTrue(DubPredRef.isSubtypeOf(DubPredRef));

  Expect.isTrue(NumPredRef.isSubtypeOf(Func));
  Expect.isTrue(NumPredRef.isSubtypeOf(IntPredRef));
  Expect.isTrue(NumPredRef.isSubtypeOf(DubPredRef));

  Expect.isTrue(IntPredRef.isSubtypeOf(Func));
  Expect.isTrue(IntPredRef.isSubtypeOf(NumPredRef));
  Expect.isFalse(IntPredRef.isSubtypeOf(DubPredRef));

  Expect.isTrue(DubPredRef.isSubtypeOf(Func));
  Expect.isTrue(DubPredRef.isSubtypeOf(NumPredRef));
  Expect.isFalse(DubPredRef.isSubtypeOf(IntPredRef));

  Expect.isTrue(Func.isSubtypeOf(Obj));
  Expect.isTrue(NumPredRef.isSubtypeOf(Obj));
  Expect.isTrue(IntPredRef.isSubtypeOf(Obj));
  Expect.isTrue(DubPredRef.isSubtypeOf(Obj));

  // Function - return type.
  TypeMirror NumGenRef = NumGen.referent;
  TypeMirror IntGenRef = IntGen.referent;
  TypeMirror DubGenRef = DubGen.referent;

  Expect.isTrue(NumGenRef.isSubtypeOf(NumGenRef));
  Expect.isTrue(IntGenRef.isSubtypeOf(IntGenRef));
  Expect.isTrue(DubGenRef.isSubtypeOf(DubGenRef));

  Expect.isTrue(NumGenRef.isSubtypeOf(Func));
  Expect.isTrue(NumGenRef.isSubtypeOf(IntGenRef));
  Expect.isTrue(NumGenRef.isSubtypeOf(DubGenRef));

  Expect.isTrue(IntGenRef.isSubtypeOf(Func));
  Expect.isTrue(IntGenRef.isSubtypeOf(NumGenRef));
  Expect.isFalse(IntGenRef.isSubtypeOf(DubGenRef));

  Expect.isTrue(DubGenRef.isSubtypeOf(Func));
  Expect.isTrue(DubGenRef.isSubtypeOf(NumGenRef));
  Expect.isFalse(DubGenRef.isSubtypeOf(IntGenRef));

  Expect.isTrue(Func.isSubtypeOf(Obj));
  Expect.isTrue(NumGenRef.isSubtypeOf(Obj));
  Expect.isTrue(IntGenRef.isSubtypeOf(Obj));
  Expect.isTrue(DubGenRef.isSubtypeOf(Obj));

  // Function typedef / function.
  Expect.isTrue(NumPred.isSubtypeOf(NumPredRef));
  Expect.isTrue(IntPred.isSubtypeOf(IntPredRef));
  Expect.isTrue(DubPred.isSubtypeOf(DubPredRef));
  Expect.isTrue(NumPredRef.isSubtypeOf(NumPred));
  Expect.isTrue(IntPredRef.isSubtypeOf(IntPred));
  Expect.isTrue(DubPredRef.isSubtypeOf(DubPred));

  // Function typedef / function.
  Expect.isTrue(NumGen.isSubtypeOf(NumGenRef));
  Expect.isTrue(IntGen.isSubtypeOf(IntGenRef));
  Expect.isTrue(DubGen.isSubtypeOf(DubGenRef));
  Expect.isTrue(NumGenRef.isSubtypeOf(NumGen));
  Expect.isTrue(IntGenRef.isSubtypeOf(IntGen));
  Expect.isTrue(DubGenRef.isSubtypeOf(DubGen));

  // Type variable.
  TypeMirror TFromA =
      (thisLibrary.declarations[#A] as ClassMirror).typeVariables.single;
  TypeMirror TFromB =
      (thisLibrary.declarations[#B] as ClassMirror).typeVariables.single;
  TypeMirror TFromC =
      (thisLibrary.declarations[#C] as ClassMirror).typeVariables.single;

  Expect.isTrue(TFromA.isSubtypeOf(TFromA));
  Expect.isTrue(TFromB.isSubtypeOf(TFromB));
  Expect.isTrue(TFromC.isSubtypeOf(TFromC));

  Expect.isFalse(TFromA.isSubtypeOf(TFromB));
  Expect.isFalse(TFromA.isSubtypeOf(TFromC));
  Expect.isFalse(TFromB.isSubtypeOf(TFromA));
  Expect.isFalse(TFromB.isSubtypeOf(TFromC));
  Expect.isFalse(TFromC.isSubtypeOf(TFromA));
  Expect.isFalse(TFromC.isSubtypeOf(TFromB));

  TypeMirror Num = coreLibrary.declarations[#num];
  Expect.isTrue(TFromC.isSubtypeOf(Num));
  Expect.isFalse(Num.isSubtypeOf(TFromC));

  // dynamic & void.
  TypeMirror Dynamic = mirrors.dynamicType;
  Expect.isTrue(Dynamic.isSubtypeOf(Dynamic));
  Expect.isTrue(Obj.isSubtypeOf(Dynamic));
  Expect.isTrue(Super.isSubtypeOf(Dynamic));
  Expect.isTrue(Sub1.isSubtypeOf(Dynamic));
  Expect.isTrue(Sub2.isSubtypeOf(Dynamic));
  Expect.isTrue(NumPred.isSubtypeOf(Dynamic));
  Expect.isTrue(IntPred.isSubtypeOf(Dynamic));
  Expect.isTrue(DubPred.isSubtypeOf(Dynamic));
  Expect.isTrue(NumPredRef.isSubtypeOf(Dynamic));
  Expect.isTrue(IntPredRef.isSubtypeOf(Dynamic));
  Expect.isTrue(DubPredRef.isSubtypeOf(Dynamic));
  Expect.isTrue(NumGen.isSubtypeOf(Dynamic));
  Expect.isTrue(IntGen.isSubtypeOf(Dynamic));
  Expect.isTrue(DubGen.isSubtypeOf(Dynamic));
  Expect.isTrue(NumGenRef.isSubtypeOf(Dynamic));
  Expect.isTrue(IntGenRef.isSubtypeOf(Dynamic));
  Expect.isTrue(DubGenRef.isSubtypeOf(Dynamic));
  Expect.isTrue(TFromA.isSubtypeOf(Dynamic));
  Expect.isTrue(TFromB.isSubtypeOf(Dynamic));
  Expect.isTrue(TFromC.isSubtypeOf(Dynamic));
  Expect.isTrue(Dynamic.isSubtypeOf(Obj));
  Expect.isTrue(Dynamic.isSubtypeOf(Super));
  Expect.isTrue(Dynamic.isSubtypeOf(Sub1));
  Expect.isTrue(Dynamic.isSubtypeOf(Sub2));
  Expect.isTrue(Dynamic.isSubtypeOf(NumPred));
  Expect.isTrue(Dynamic.isSubtypeOf(IntPred));
  Expect.isTrue(Dynamic.isSubtypeOf(DubPred));
  Expect.isTrue(Dynamic.isSubtypeOf(NumPredRef));
  Expect.isTrue(Dynamic.isSubtypeOf(IntPredRef));
  Expect.isTrue(Dynamic.isSubtypeOf(DubPredRef));
  Expect.isTrue(Dynamic.isSubtypeOf(NumGen));
  Expect.isTrue(Dynamic.isSubtypeOf(IntGen));
  Expect.isTrue(Dynamic.isSubtypeOf(DubGen));
  Expect.isTrue(Dynamic.isSubtypeOf(NumGenRef));
  Expect.isTrue(Dynamic.isSubtypeOf(IntGenRef));
  Expect.isTrue(Dynamic.isSubtypeOf(DubGenRef));
  Expect.isTrue(Dynamic.isSubtypeOf(TFromA));
  Expect.isTrue(Dynamic.isSubtypeOf(TFromB));
  Expect.isTrue(Dynamic.isSubtypeOf(TFromC));

  TypeMirror Void = mirrors.voidType;
  Expect.isTrue(Void.isSubtypeOf(Void));
  Expect.isFalse(Obj.isSubtypeOf(Void));
  Expect.isFalse(Super.isSubtypeOf(Void));
  Expect.isFalse(Sub1.isSubtypeOf(Void));
  Expect.isFalse(Sub2.isSubtypeOf(Void));
  Expect.isFalse(NumPred.isSubtypeOf(Void));
  Expect.isFalse(IntPred.isSubtypeOf(Void));
  Expect.isFalse(DubPred.isSubtypeOf(Void));
  Expect.isFalse(NumPredRef.isSubtypeOf(Void));
  Expect.isFalse(IntPredRef.isSubtypeOf(Void));
  Expect.isFalse(DubPredRef.isSubtypeOf(Void));
  Expect.isFalse(NumGen.isSubtypeOf(Void));
  Expect.isFalse(IntGen.isSubtypeOf(Void));
  Expect.isFalse(DubGen.isSubtypeOf(Void));
  Expect.isFalse(NumGenRef.isSubtypeOf(Void));
  Expect.isFalse(IntGenRef.isSubtypeOf(Void));
  Expect.isFalse(DubGenRef.isSubtypeOf(Void));
  Expect.isFalse(TFromA.isSubtypeOf(Void));
  Expect.isFalse(TFromB.isSubtypeOf(Void));
  Expect.isFalse(TFromC.isSubtypeOf(Void));
  Expect.isFalse(Void.isSubtypeOf(Obj));
  Expect.isFalse(Void.isSubtypeOf(Super));
  Expect.isFalse(Void.isSubtypeOf(Sub1));
  Expect.isFalse(Void.isSubtypeOf(Sub2));
  Expect.isFalse(Void.isSubtypeOf(NumPred));
  Expect.isFalse(Void.isSubtypeOf(IntPred));
  Expect.isFalse(Void.isSubtypeOf(DubPred));
  Expect.isFalse(Void.isSubtypeOf(NumPredRef));
  Expect.isFalse(Void.isSubtypeOf(IntPredRef));
  Expect.isFalse(Void.isSubtypeOf(DubPredRef));
  Expect.isFalse(Void.isSubtypeOf(NumGen));
  Expect.isFalse(Void.isSubtypeOf(IntGen));
  Expect.isFalse(Void.isSubtypeOf(DubGen));
  Expect.isFalse(Void.isSubtypeOf(NumGenRef));
  Expect.isFalse(Void.isSubtypeOf(IntGenRef));
  Expect.isFalse(Void.isSubtypeOf(DubGenRef));
  Expect.isFalse(Void.isSubtypeOf(TFromA));
  Expect.isFalse(Void.isSubtypeOf(TFromB));
  Expect.isFalse(Void.isSubtypeOf(TFromC));

  Expect.isTrue(Dynamic.isSubtypeOf(Void));
  Expect.isTrue(Void.isSubtypeOf(Dynamic));
}

main() {
  test(currentMirrorSystem());
}
