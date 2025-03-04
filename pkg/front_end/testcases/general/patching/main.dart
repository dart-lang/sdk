// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:test';

main() {
  topLevelSetter = topLevelGetter;
  topLevelMethod(42);
  topLevelMethod;
  var c = Class(42);
  Class.new;
  Class.redirecting(42);
  Class.redirecting;
  Class.factory(42);
  Class.factory;
  Class.redirectingFactory(42);
  Class.redirectingFactory;
  c.instanceSetter = c.instanceGetter;
  c.instanceMethod(42);
  c.instanceMethod;
  c + c;
  Class.staticSetter = Class.staticGetter;
  Class.staticMethod(42);
  Class.staticMethod;
  c.extensionInstanceSetter = c.extensionInstanceGetter;
  c.extensionInstanceMethod(42);
  c.extensionInstanceMethod;
  c - c;
  Extension.extensionStaticSetter = Extension.extensionStaticGetter;
  Extension.extensionStaticMethod(42);
  Extension.extensionStaticMethod;
}
