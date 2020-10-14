// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Tests static errors for JS interop members without an external keyword.

@JS()
library external_member_static_test;

import 'package:js/js.dart';

@JS()
class JSClass {
  int? field;

  @JS()
  int? fieldWithJS;

  static int? staticField;

  @JS()
  static int? staticFieldWithJS;

  JSClass.constructor();
//^
// [web] JS interop classes do not support non-external constructors.
  @JS()
  JSClass.constructorWithJS();
//^
// [web] JS interop classes do not support non-external constructors.

  // Dart factories of a JS interop class are allowed.
  factory JSClass.fact() => JSClass.constructor();

  factory JSClass.redirectingFactory() = JSClass.constructor;

  external factory JSClass.externalFactory();

  @JS()
  factory JSClass.factoryWithJS() => JSClass.fact();

  int get getSet => 0;
  //      ^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  @JS()
  int get getSetWithJS => 0;
  //      ^^^^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  set getSet(int val) {}
  //  ^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  @JS()
  set getSetWithJS(int val) {}
  //  ^^^^^^^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  int method() => 0;
  //  ^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  @JS()
  int methodWithJS() => 0;
  //  ^^^^^^^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.

  // Static methods on JS interop classes are allowed.
  static int staticMethod() => 0;

  @JS()
  static int staticMethodWithJS() => 0;
}

@JS()
@anonymous
class JSAnonymousClass {
  int? field;

  @JS()
  int? fieldWithJS;

  static int? staticField;

  @JS()
  static int? staticFieldWithJS;

  JSAnonymousClass.constructor();
//^
// [web] JS interop classes do not support non-external constructors.
  @JS()
  JSAnonymousClass.constructorWithJS();
//^
// [web] JS interop classes do not support non-external constructors.

  factory JSAnonymousClass.fact() => JSAnonymousClass.constructor();

  factory JSAnonymousClass.redirectingFactory() = JSAnonymousClass.fact;

  external factory JSAnonymousClass.externalFactory();

  @JS()
  factory JSAnonymousClass.factoryWithJS() => JSAnonymousClass.fact();

  int get getSet => 0;
  //      ^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  @JS()
  int get getSetWithJS => 0;
  //      ^^^^^^^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  set getSet(int val) {}
  //  ^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  @JS()
  set getSetWithJS(int val) {}
  //  ^^^^^^^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  int method() => 0;
  //  ^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.
  @JS()
  int methodWithJS() => 0;
  //  ^^^^^^^^^^^^
  // [web] This JS interop member must be annotated with `external`. Only factories and static methods can be non-external.

  static int staticMethod() => 0;

  @JS()
  static int staticMethodWithJS() => 0;
}

@JS()
abstract class JSAbstractClass {
  int? field;

  @JS()
  int? fieldWithJS;

  static int? staticField;

  @JS()
  static int? staticFieldWithJS;

  JSAbstractClass.constructor();
//^
// [web] JS interop classes do not support non-external constructors.
  @JS()
  JSAbstractClass.constructorWithJS();
//^
// [web] JS interop classes do not support non-external constructors.

  factory JSAbstractClass.fact() => JSAbstractClass.factoryWithJS();

  factory JSAbstractClass.redirectingFactory() = JSAbstractClass.fact;

  external factory JSAbstractClass.externalFactory();

  @JS()
  factory JSAbstractClass.factoryWithJS() => JSAbstractClass.fact();

  // Members in an abstract class are allowed.
  int get getSet;

  @JS()
  int get getSetWithJS;

  set getSet(int val);

  @JS()
  set getSetWithJS(int val);

  int method();

  @JS()
  int methodWithJS();

  static int staticMethod() => 0;

  @JS()
  static int staticMethodWithJS() => 0;
}

@JS()
class JSClassWithSyntheticConstructor {}

@JS()
int? globalWithJS;
@JS()
int get getSetWithJS => 0;
@JS()
set getSetWithJS(int val) {}
@JS()
int methodWithJS() => 0;

external int get getSet;
external set getSet(int val);
external int method();

main() {}
