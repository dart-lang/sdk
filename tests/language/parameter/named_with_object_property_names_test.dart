// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";

// Test for named parameter with the name of a JavaScript property found on
// 'Object'.  For such a NAME, foo.NAME may exist in an empty map, i.e.
//    'toString' in {} --> true.

main() {
  // Test properties found on instances of Object in Chrome 15 and Firefox 6.
  test_constructor();
  test_hasOwnProperty();
  test_isPrototypeOf();
  test_propertyIsEnumerable();
  test_toSource();
  test_toLocaleString();
  test_toString();
  test_unwatch();
  test_valueOf();
  test_watch();
}

// 'constructor' property.

class TestClass_constructor {
  method({constructor}) => constructor;
  static staticMethod({constructor}) => constructor;
}

globalMethod_constructor({constructor}) => constructor;

test_constructor() {
  var obj = new TestClass_constructor();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(constructor: 0));

  Expect.equals(null, TestClass_constructor.staticMethod());
  Expect.equals(0, TestClass_constructor.staticMethod(constructor: 0));

  Expect.equals(null, globalMethod_constructor());
  Expect.equals(0, globalMethod_constructor(constructor: 0));
}

// 'hasOwnProperty' property.

class TestClass_hasOwnProperty {
  method({hasOwnProperty}) => hasOwnProperty;
  static staticMethod({hasOwnProperty}) => hasOwnProperty;
}

globalMethod_hasOwnProperty({hasOwnProperty}) => hasOwnProperty;

test_hasOwnProperty() {
  var obj = new TestClass_hasOwnProperty();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(hasOwnProperty: 0));

  Expect.equals(null, TestClass_hasOwnProperty.staticMethod());
  Expect.equals(0, TestClass_hasOwnProperty.staticMethod(hasOwnProperty: 0));

  Expect.equals(null, globalMethod_hasOwnProperty());
  Expect.equals(0, globalMethod_hasOwnProperty(hasOwnProperty: 0));
}

// 'isPrototypeOf' property.

class TestClass_isPrototypeOf {
  method({isPrototypeOf}) => isPrototypeOf;
  static staticMethod({isPrototypeOf}) => isPrototypeOf;
}

globalMethod_isPrototypeOf({isPrototypeOf}) => isPrototypeOf;

test_isPrototypeOf() {
  var obj = new TestClass_isPrototypeOf();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(isPrototypeOf: 0));

  Expect.equals(null, TestClass_isPrototypeOf.staticMethod());
  Expect.equals(0, TestClass_isPrototypeOf.staticMethod(isPrototypeOf: 0));

  Expect.equals(null, globalMethod_isPrototypeOf());
  Expect.equals(0, globalMethod_isPrototypeOf(isPrototypeOf: 0));
}

// 'propertyIsEnumerable' property.

class TestClass_propertyIsEnumerable {
  method({propertyIsEnumerable}) => propertyIsEnumerable;
  static staticMethod({propertyIsEnumerable}) => propertyIsEnumerable;
}

globalMethod_propertyIsEnumerable({propertyIsEnumerable}) =>
    propertyIsEnumerable;

test_propertyIsEnumerable() {
  var obj = new TestClass_propertyIsEnumerable();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(propertyIsEnumerable: 0));

  Expect.equals(null, TestClass_propertyIsEnumerable.staticMethod());
  Expect.equals(
      0, TestClass_propertyIsEnumerable.staticMethod(propertyIsEnumerable: 0));

  Expect.equals(null, globalMethod_propertyIsEnumerable());
  Expect.equals(0, globalMethod_propertyIsEnumerable(propertyIsEnumerable: 0));
}

// 'toSource' property.

class TestClass_toSource {
  method({toSource}) => toSource;
  static staticMethod({toSource}) => toSource;
}

globalMethod_toSource({toSource}) => toSource;

test_toSource() {
  var obj = new TestClass_toSource();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(toSource: 0));

  Expect.equals(null, TestClass_toSource.staticMethod());
  Expect.equals(0, TestClass_toSource.staticMethod(toSource: 0));

  Expect.equals(null, globalMethod_toSource());
  Expect.equals(0, globalMethod_toSource(toSource: 0));
}

// 'toLocaleString' property.

class TestClass_toLocaleString {
  method({toLocaleString}) => toLocaleString;
  static staticMethod({toLocaleString}) => toLocaleString;
}

globalMethod_toLocaleString({toLocaleString}) => toLocaleString;

test_toLocaleString() {
  var obj = new TestClass_toLocaleString();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(toLocaleString: 0));

  Expect.equals(null, TestClass_toLocaleString.staticMethod());
  Expect.equals(0, TestClass_toLocaleString.staticMethod(toLocaleString: 0));

  Expect.equals(null, globalMethod_toLocaleString());
  Expect.equals(0, globalMethod_toLocaleString(toLocaleString: 0));
}

// 'toString' property.

class TestClass_toString {
  method({toString}) => toString;
  static staticMethod({toString}) => toString;
}

globalMethod_toString({toString}) => toString;

test_toString() {
  var obj = new TestClass_toString();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(toString: 0));

  Expect.equals(null, TestClass_toString.staticMethod());
  Expect.equals(0, TestClass_toString.staticMethod(toString: 0));

  Expect.equals(null, globalMethod_toString());
  Expect.equals(0, globalMethod_toString(toString: 0));
}

// 'unwatch' property.

class TestClass_unwatch {
  method({unwatch}) => unwatch;
  static staticMethod({unwatch}) => unwatch;
}

globalMethod_unwatch({unwatch}) => unwatch;

test_unwatch() {
  var obj = new TestClass_unwatch();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(unwatch: 0));

  Expect.equals(null, TestClass_unwatch.staticMethod());
  Expect.equals(0, TestClass_unwatch.staticMethod(unwatch: 0));

  Expect.equals(null, globalMethod_unwatch());
  Expect.equals(0, globalMethod_unwatch(unwatch: 0));
}

// 'valueOf' property.

class TestClass_valueOf {
  method({valueOf}) => valueOf;
  static staticMethod({valueOf}) => valueOf;
}

globalMethod_valueOf({valueOf}) => valueOf;

test_valueOf() {
  var obj = new TestClass_valueOf();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(valueOf: 0));

  Expect.equals(null, TestClass_valueOf.staticMethod());
  Expect.equals(0, TestClass_valueOf.staticMethod(valueOf: 0));

  Expect.equals(null, globalMethod_valueOf());
  Expect.equals(0, globalMethod_valueOf(valueOf: 0));
}

// 'watch' property.

class TestClass_watch {
  method({watch}) => watch;
  static staticMethod({watch}) => watch;
}

globalMethod_watch({watch}) => watch;

test_watch() {
  var obj = new TestClass_watch();

  Expect.equals(null, obj.method());
  Expect.equals(0, obj.method(watch: 0));

  Expect.equals(null, TestClass_watch.staticMethod());
  Expect.equals(0, TestClass_watch.staticMethod(watch: 0));

  Expect.equals(null, globalMethod_watch());
  Expect.equals(0, globalMethod_watch(watch: 0));
}
