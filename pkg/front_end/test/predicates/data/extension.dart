// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

extension Extension on int {
  /*member: Extension|instanceMethod:extensionName=Extension.instanceMethod*/
  /*member: Extension|get#instanceMethod:extensionName=Extension.instanceMethod*/
  int /*
   extensionThis,
   name=this
  */
  instanceMethod() => this;

  /*member: Extension|get#instanceGetter:extensionName=Extension.instanceGetter*/
  int get /*
   extensionThis,
   name=this
  */ instanceGetter => this;

  /*member: Extension|set#instanceSetter:extensionName=Extension.instanceSetter*/
  void set /*
   extensionThis,
   name=this
  */ instanceSetter(int value) {}

  /*member: Extension|staticMethod:extensionName=Extension.staticMethod*/
  static int staticMethod() => 42;

  /*member: Extension|staticGetter:extensionName=Extension.staticGetter*/
  static int get staticGetter => 42;

  /*member: Extension|staticSetter=:extensionName=Extension.staticSetter*/
  static void set staticSetter(int value) {}
}

extension on int {
  /*member: _extension#1|instanceMethod:extensionName=<unnamed extension>.instanceMethod*/
  /*member: _extension#1|get#instanceMethod:extensionName=<unnamed extension>.instanceMethod*/
  int /*
   extensionThis,
   name=this
  */
  instanceMethod() => this;

  /*member: _extension#1|get#instanceGetter:extensionName=<unnamed extension>.instanceGetter*/
  int get /*
   extensionThis,
   name=this
  */ instanceGetter => this;

  /*member: _extension#1|set#instanceSetter:extensionName=<unnamed extension>.instanceSetter*/
  void set /*
   extensionThis,
   name=this
  */ instanceSetter(int value) {}

  /*member: _extension#1|staticMethod:extensionName=<unnamed extension>.staticMethod*/
  static int staticMethod() => 42;

  /*member: _extension#1|staticGetter:extensionName=<unnamed extension>.staticGetter*/
  static int get staticGetter => 42;

  /*member: _extension#1|staticSetter=:extensionName=<unnamed extension>.staticSetter*/
  static void set staticSetter(int value) {}
}
