// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: */

/*class: Extension:
 builder-name=Extension,
 builder-onType=String,
 extension-members=[
  genericInstanceMethod=Extension|genericInstanceMethod,
  getter instanceProperty=Extension|get#instanceProperty,
  instanceMethod=Extension|instanceMethod,
  setter instanceProperty=Extension|set#instanceProperty,
  static genericStaticMethod=Extension|genericStaticMethod,
  static getter staticProperty=Extension|staticProperty,
  static setter staticProperty=Extension|staticProperty=,
  static staticMethod=Extension|staticMethod,
  tearoff genericInstanceMethod=Extension|get#genericInstanceMethod,
  tearoff instanceMethod=Extension|get#instanceMethod],
 extension-name=Extension,
 extension-onType=String!
*/
extension Extension on String {
  external int instanceMethod();

  external T genericInstanceMethod<T>(T t);

  external static int staticMethod();

  external static T genericStaticMethod<T>(T t);

  external int get instanceProperty;

  external void set instanceProperty(int value);

  external static int get staticProperty;

  external static void set staticProperty(int value);
}

/*class: GenericExtension:
 builder-name=GenericExtension,
 builder-onType=T,
 builder-type-params=[T],
 extension-members=[
  genericInstanceMethod=GenericExtension|genericInstanceMethod,
  getter instanceProperty=GenericExtension|get#instanceProperty,
  instanceMethod=GenericExtension|instanceMethod,
  setter instanceProperty=GenericExtension|set#instanceProperty,
  static genericStaticMethod=GenericExtension|genericStaticMethod,
  static getter staticProperty=GenericExtension|staticProperty,
  static setter staticProperty=GenericExtension|staticProperty=,
  static staticMethod=GenericExtension|staticMethod,
  tearoff genericInstanceMethod=GenericExtension|get#genericInstanceMethod,
  tearoff instanceMethod=GenericExtension|get#instanceMethod],
 extension-name=GenericExtension,
 extension-onType=T%,
 extension-type-params=[T]
*/
extension GenericExtension<T> on T {
  external int instanceMethod();

  external T genericInstanceMethod<T>(T t);

  external static int staticMethod();

  external static T genericStaticMethod<T>(T t);

  external int get instanceProperty;

  external void set instanceProperty(int value);

  external static int get staticProperty;

  external static void set staticProperty(int value);
}
