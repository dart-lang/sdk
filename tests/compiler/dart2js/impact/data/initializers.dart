// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: main:
 static=[
  testDefaultValuesNamed(0),
  testDefaultValuesPositional(0),
  testFieldInitializer1(0),
  testFieldInitializer2(0),
  testFieldInitializer3(0),
  testGenericClass(0),
  testInstanceFieldTyped(0),
  testInstanceFieldWithInitializer(0),
  testSuperInitializer(0),
  testThisInitializer(0)]
*/
main() {
  testDefaultValuesPositional();
  testDefaultValuesNamed();
  testFieldInitializer1();
  testFieldInitializer2();
  testFieldInitializer3();
  testInstanceFieldWithInitializer();
  testInstanceFieldTyped();
  testThisInitializer();
  testSuperInitializer();
  testGenericClass();
}

/*kernel.element: testDefaultValuesPositional:type=[check:bool,inst:JSBool]*/
/*strong.element: testDefaultValuesPositional:type=[inst:JSBool,param:bool]*/
testDefaultValuesPositional([bool value = false]) {}

/*kernel.element: testDefaultValuesNamed:type=[check:bool,inst:JSBool]*/
/*strong.element: testDefaultValuesNamed:type=[inst:JSBool,param:bool]*/
testDefaultValuesNamed({bool value: false}) {}

class ClassFieldInitializer1 {
  /*element: ClassFieldInitializer1.field:type=[inst:JSNull]*/
  var field;

  /*element: ClassFieldInitializer1.:static=[Object.(0),init:ClassFieldInitializer1.field]*/
  ClassFieldInitializer1(this.field);
}

/*element: testFieldInitializer1:
 static=[ClassFieldInitializer1.(1)],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testFieldInitializer1() => new ClassFieldInitializer1(42);

class ClassFieldInitializer2 {
  /*element: ClassFieldInitializer2.field:type=[inst:JSNull]*/
  var field;

  /*element: ClassFieldInitializer2.:static=[Object.(0),init:ClassFieldInitializer2.field]*/
  ClassFieldInitializer2(value) : field = value;
}

/*element: testFieldInitializer2:
 static=[ClassFieldInitializer2.(1)],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testFieldInitializer2() => new ClassFieldInitializer2(42);

class ClassFieldInitializer3 {
  /*element: ClassFieldInitializer3.field:type=[inst:JSNull]*/
  var field;

  /*element: ClassFieldInitializer3.a:static=[Object.(0),init:ClassFieldInitializer3.field],type=[inst:JSNull]*/
  ClassFieldInitializer3.a();

  /*element: ClassFieldInitializer3.b:static=[Object.(0),init:ClassFieldInitializer3.field]*/
  ClassFieldInitializer3.b(value) : field = value;
}

/*element: testFieldInitializer3:
 static=[ClassFieldInitializer3.a(0),ClassFieldInitializer3.b(1)],
 type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]
*/
testFieldInitializer3() {
  new ClassFieldInitializer3.a();
  new ClassFieldInitializer3.b(42);
}

/*element: ClassInstanceFieldWithInitializer.:static=[Object.(0)]*/
class ClassInstanceFieldWithInitializer {
  /*kernel.element: ClassInstanceFieldWithInitializer.field:type=[inst:JSBool]*/
  /*strong.element: ClassInstanceFieldWithInitializer.field:type=[inst:JSBool,param:bool]*/
  var field = false;
}

/*element: testInstanceFieldWithInitializer:static=[ClassInstanceFieldWithInitializer.(0)]*/
testInstanceFieldWithInitializer() => new ClassInstanceFieldWithInitializer();

/*element: ClassInstanceFieldTyped.:static=[Object.(0)]*/
class ClassInstanceFieldTyped {
  /*kernel.element: ClassInstanceFieldTyped.field:type=[check:int,inst:JSNull]*/
  /*strong.element: ClassInstanceFieldTyped.field:type=[inst:JSBool,inst:JSNull,param:int]*/
  int field;
}

/*element: testInstanceFieldTyped:static=[ClassInstanceFieldTyped.(0)]*/
testInstanceFieldTyped() => new ClassInstanceFieldTyped();

class ClassThisInitializer {
  /*element: ClassThisInitializer.:static=[ClassThisInitializer.internal(0)]*/
  ClassThisInitializer() : this.internal();

  /*element: ClassThisInitializer.internal:static=[Object.(0)]*/
  ClassThisInitializer.internal();
}

/*element: testThisInitializer:static=[ClassThisInitializer.(0)]*/
testThisInitializer() => new ClassThisInitializer();

class ClassSuperInitializer extends ClassThisInitializer {
  /*element: ClassSuperInitializer.:static=[ClassThisInitializer.internal(0)]*/
  ClassSuperInitializer() : super.internal();
}

/*element: testSuperInitializer:static=[ClassSuperInitializer.(0)]*/
testSuperInitializer() => new ClassSuperInitializer();

class ClassGeneric<T> {
  /*kernel.element: ClassGeneric.:static=[Object.(0)],type=[check:ClassGeneric.T]*/
  /*strong.element: ClassGeneric.:
   static=[
    Object.(0),
    checkSubtype,
    checkSubtypeOfRuntimeType,
    getRuntimeTypeArgument,
    getRuntimeTypeArgumentIntercepted,
    getRuntimeTypeInfo,
    getTypeArgumentByIndex,
    setRuntimeTypeInfo],
   type=[
    inst:JSArray<dynamic>,
    inst:JSBool,
    inst:JSExtendableArray<dynamic>,
    inst:JSFixedArray<dynamic>,
    inst:JSMutableArray<dynamic>,
    inst:JSUnmodifiableArray<dynamic>,
    param:ClassGeneric.T]
  */
  ClassGeneric(T arg);
}

/*element: testGenericClass:static=[ClassGeneric.(1),assertIsSubtype,throwTypeError],type=[inst:JSDouble,inst:JSInt,inst:JSNumber,inst:JSPositiveInt,inst:JSUInt31,inst:JSUInt32]*/
testGenericClass() => new ClassGeneric<int>(0);
