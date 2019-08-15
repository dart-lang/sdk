// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const dynamic nullLiteralField = null;

const dynamic boolLiteralField = true;

const dynamic intLiteralField = 42;

const dynamic doubleLiteralField = 0.5;

const dynamic stringLiteralField = "foo";

const dynamic symbolLiteralField = #foo;

const dynamic listLiteralField = [true, false];

const dynamic mapLiteralField = {true: false};

const dynamic stringMapLiteralField = {'foo': false};

const dynamic setLiteralField = {true, false};

class SuperClass {
  /*member: SuperClass.field1:type=[inst:JSNull]*/
  final field1;

  const SuperClass(this.field1);
}

class Class extends SuperClass {
  /*member: Class.field2:type=[inst:JSNull]*/
  final field2;

  const Class(field1, this.field2) : super(field1);

  static staticMethodField() {}
}

const instanceConstantField = const Class(true, false);

const typeLiteralField = String;

/*member: id:static=[checkSubtype(4),checkSubtypeOfRuntimeType(2),getRuntimeTypeArgument(3),getRuntimeTypeArgumentIntercepted(4),getRuntimeTypeInfo(1),getTypeArgumentByIndex(2),setRuntimeTypeInfo(2)],type=[inst:JSArray<dynamic>,inst:JSBool,inst:JSExtendableArray<dynamic>,inst:JSFixedArray<dynamic>,inst:JSMutableArray<dynamic>,inst:JSUnmodifiableArray<dynamic>,param:Object,param:id.T]*/
T id<T>(T t) => t;

const int Function(int) _instantiation = id;

const dynamic instantiationField = _instantiation;

topLevelMethod() {}

const dynamic topLevelTearOffField = topLevelMethod;

const dynamic staticTearOffField = Class.staticMethodField;
