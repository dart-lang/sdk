// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library test.relation_subclass;

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

test(MirrorSystem mirrors) {
  LibraryMirror coreLibrary = mirrors.findLibrary(#dart.core);
  LibraryMirror thisLibrary = mirrors.findLibrary(#test.relation_subclass);

  ClassMirror Super = thisLibrary.declarations[#Superclass];
  ClassMirror Sub1 = thisLibrary.declarations[#Subclass1];
  ClassMirror Sub2 = thisLibrary.declarations[#Subclass2];
  ClassMirror Obj = coreLibrary.declarations[#Object];
  ClassMirror Nul = coreLibrary.declarations[#Null];

  Expect.isTrue(Obj.isSubclassOf(Obj));
  Expect.isTrue(Super.isSubclassOf(Super));
  Expect.isTrue(Sub1.isSubclassOf(Sub1));
  Expect.isTrue(Sub2.isSubclassOf(Sub2));
  Expect.isTrue(Nul.isSubclassOf(Nul));

  Expect.isTrue(Sub1.isSubclassOf(Super));
  Expect.isFalse(Super.isSubclassOf(Sub1));

  Expect.isTrue(Sub2.isSubclassOf(Super));
  Expect.isFalse(Super.isSubclassOf(Sub2));

  Expect.isFalse(Sub2.isSubclassOf(Sub1));
  Expect.isFalse(Sub1.isSubclassOf(Sub2));

  Expect.isTrue(Sub1.isSubclassOf(Obj));
  Expect.isFalse(Obj.isSubclassOf(Sub1));

  Expect.isTrue(Sub2.isSubclassOf(Obj));
  Expect.isFalse(Obj.isSubclassOf(Sub2));

  Expect.isTrue(Super.isSubclassOf(Obj));
  Expect.isFalse(Obj.isSubclassOf(Super));

  Expect.isTrue(Nul.isSubclassOf(Obj));
  Expect.isFalse(Obj.isSubclassOf(Nul));
  Expect.isFalse(Nul.isSubclassOf(Super));
  Expect.isFalse(Super.isSubclassOf(Nul));

  ClassMirror Func = coreLibrary.declarations[#Function];
  Expect.isTrue(Func.isSubclassOf(Obj));
  Expect.isFalse(Obj.isSubclassOf(Func));

  // Function typedef.
  var NumPred = thisLibrary.declarations[#NumberPredicate];
  var IntPred = thisLibrary.declarations[#IntegerPredicate];
  var DubPred = thisLibrary.declarations[#DoublePredicate];
  var NumGen = thisLibrary.declarations[#NumberGenerator];
  var IntGen = thisLibrary.declarations[#IntegerGenerator];
  var DubGen = thisLibrary.declarations[#DoubleGenerator];

  isArgumentOrTypeError(e) => e is ArgumentError || e is TypeError;
  Expect.throws(() => Func.isSubclassOf(NumPred), isArgumentOrTypeError);
  Expect.throws(() => Func.isSubclassOf(IntPred), isArgumentOrTypeError);
  Expect.throws(() => Func.isSubclassOf(DubPred), isArgumentOrTypeError);
  Expect.throws(() => Func.isSubclassOf(NumGen), isArgumentOrTypeError);
  Expect.throws(() => Func.isSubclassOf(IntGen), isArgumentOrTypeError);
  Expect.throws(() => Func.isSubclassOf(DubGen), isArgumentOrTypeError);

  Expect.throwsNoSuchMethodError(() => NumPred.isSubclassOf(Func));
  Expect.throwsNoSuchMethodError(() => IntPred.isSubclassOf(Func));
  Expect.throwsNoSuchMethodError(() => DubPred.isSubclassOf(Func));
  Expect.throwsNoSuchMethodError(() => NumGen.isSubclassOf(Func));
  Expect.throwsNoSuchMethodError(() => IntGen.isSubclassOf(Func));
  Expect.throwsNoSuchMethodError(() => DubGen.isSubclassOf(Func));

  // Function type.
  TypeMirror NumPredRef = (NumPred as TypedefMirror).referent;
  TypeMirror IntPredRef = (IntPred as TypedefMirror).referent;
  TypeMirror DubPredRef = (DubPred as TypedefMirror).referent;
  TypeMirror NumGenRef = (NumGen as TypedefMirror).referent;
  TypeMirror IntGenRef = (IntGen as TypedefMirror).referent;
  TypeMirror DubGenRef = (DubGen as TypedefMirror).referent;

  Expect.isFalse(Func.isSubclassOf(NumPredRef));
  Expect.isFalse(Func.isSubclassOf(IntPredRef));
  Expect.isFalse(Func.isSubclassOf(DubPredRef));
  Expect.isFalse(Func.isSubclassOf(NumGenRef));
  Expect.isFalse(Func.isSubclassOf(IntGenRef));
  Expect.isFalse(Func.isSubclassOf(DubGenRef));

  // The spec doesn't require these to be either value, only that they implement
  // Function.
  // NumPredRef.isSubclassOf(Func);
  // IntPredRef.isSubclassOf(Func);
  // DubPredRef.isSubclassOf(Func);
  // NumGenRef.isSubclassOf(Func);
  // IntGenRef.isSubclassOf(Func);
  // DubGenRef.isSubclassOf(Func);
}

main() {
  test(currentMirrorSystem());
}
