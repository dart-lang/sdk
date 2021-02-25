// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.9

// ignore: import_internal_library
import 'dart:_internal';

@patch
extension Extension on String {
  /*member: Extension|instanceMethod:
   builder-name=instanceMethod,
   builder-params=[#this],
   member-name=Extension|instanceMethod,
   member-params=[#this]
  */
  @patch
  int instanceMethod() => 42;

  /*member: Extension|genericInstanceMethod:
   builder-name=genericInstanceMethod,
   builder-params=[#this,t],
   builder-type-params=[T],
   member-name=Extension|genericInstanceMethod,
   member-params=[#this,t],
   member-type-params=[T]
  */
  @patch
  T genericInstanceMethod<T>(T t) => t;

  /*member: Extension|staticMethod:
   builder-name=staticMethod,
   member-name=Extension|staticMethod
  */
  @patch
  static int staticMethod() => 87;

  /*member: Extension|genericStaticMethod:
   builder-name=genericStaticMethod,
   builder-params=[t],
   builder-type-params=[T],
   member-name=Extension|genericStaticMethod,
   member-params=[t],
   member-type-params=[T]
  */
  @patch
  static T genericStaticMethod<T>(T t) => t;

  /*member: Extension|get#instanceProperty:
   builder-name=instanceProperty,
   builder-params=[#this],
   member-name=Extension|get#instanceProperty,
   member-params=[#this]
  */
  @patch
  int get instanceProperty => 123;

  /*member: Extension|set#instanceProperty:
   builder-name=instanceProperty,
   builder-params=[#this,value],
   member-name=Extension|set#instanceProperty,
   member-params=[#this,value]
  */
  @patch
  void set instanceProperty(int value) {}

  /*member: Extension|staticProperty:
   builder-name=staticProperty,
   member-name=Extension|staticProperty
  */
  @patch
  static int get staticProperty => 237;

  /*member: Extension|staticProperty=:
   builder-name=staticProperty,
   builder-params=[value],
   member-name=Extension|staticProperty=,
   member-params=[value]
  */
  @patch
  static void set staticProperty(int value) {}
}


@patch
extension GenericExtension<T> on T {
  /*member: GenericExtension|instanceMethod:
   builder-name=instanceMethod,
   builder-params=[#this],
   builder-type-params=[T],
   member-name=GenericExtension|instanceMethod,
   member-params=[#this],
   member-type-params=[T]
  */
  @patch
  int instanceMethod() => 42;

  /*member: GenericExtension|genericInstanceMethod:
   builder-name=genericInstanceMethod,
   builder-params=[#this,t],
   builder-type-params=[T,T],
   member-name=GenericExtension|genericInstanceMethod,
   member-params=[#this,t],
   member-type-params=[#T,T]
  */
  @patch
  T genericInstanceMethod<T>(T t) => t;

  /*member: GenericExtension|staticMethod:
   builder-name=staticMethod,
   member-name=GenericExtension|staticMethod
  */
  @patch
  static int staticMethod() => 87;

  /*member: GenericExtension|genericStaticMethod:
   builder-name=genericStaticMethod,
   builder-params=[t],
   builder-type-params=[T],
   member-name=GenericExtension|genericStaticMethod,
   member-params=[t],
   member-type-params=[T]
  */
  @patch
  static T genericStaticMethod<T>(T t) => t;

  /*member: GenericExtension|get#instanceProperty:
   builder-name=instanceProperty,
   builder-params=[#this],
   builder-type-params=[T],
   member-name=GenericExtension|get#instanceProperty,
   member-params=[#this],
   member-type-params=[T]
  */
  @patch
  int get instanceProperty => 123;

  /*member: GenericExtension|set#instanceProperty:
   builder-name=instanceProperty,
   builder-params=[#this,value],
   builder-type-params=[T],
   member-name=GenericExtension|set#instanceProperty,
   member-params=[#this,value],
   member-type-params=[T]
  */
  @patch
  void set instanceProperty(int value) {}

  /*member: GenericExtension|staticProperty:
   builder-name=staticProperty,
   member-name=GenericExtension|staticProperty
  */
  @patch
  static int get staticProperty => 237;

  /*member: GenericExtension|staticProperty=:
   builder-name=staticProperty,
   builder-params=[value],
   member-name=GenericExtension|staticProperty=,
   member-params=[value]
  */
  @patch
  static void set staticProperty(int value) {}
}
