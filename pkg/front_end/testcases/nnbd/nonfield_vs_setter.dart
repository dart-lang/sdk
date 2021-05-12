// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

topLevelMethodAndSetter() {}
void set topLevelMethodAndSetter(value) {}

typedef typedefAndSetter = Function();
void set topLevelMethodAndSetter(value) {}

class classAndSetter {}

void set classAndSetter(value) {}

class Class {
  instanceMethodAndSetter() {}
  void set instanceMethodAndSetter(value) {}

  static staticMethodAndSetter() {}
  static void set staticMethodAndSetter(value) {}

  instanceMethodAndStaticSetter() {}
  static void set instanceMethodAndStaticSetter(value) {}

  static staticMethodAndInstanceSetter() {}
  void set staticMethodAndInstanceSetter(value) {}

  Class() {}
  void set Class(value) {}
}

extension Extension on int? {
  extensionInstanceMethodAndSetter() {}
  void set extensionInstanceMethodAndSetter(value) {}

  static extensionStaticMethodAndSetter() {}
  static void set extensionStaticMethodAndSetter(value) {}

  extensionInstanceMethodAndStaticSetter() {}
  static void set extensionInstanceMethodAndStaticSetter(value) {}

  static extensionStaticMethodAndInstanceSetter() {}
  void set extensionStaticMethodAndInstanceSetter(value) {}
}

test() {
  topLevelMethodAndSetter = topLevelMethodAndSetter();
  typedefAndSetter = typedefAndSetter();
  classAndSetter = classAndSetter();

  var c = new Class();

  c.instanceMethodAndSetter = c.instanceMethodAndSetter();

  Class.staticMethodAndSetter = Class.staticMethodAndSetter();

  c.staticMethodAndInstanceSetter = Class.staticMethodAndInstanceSetter();

  Class.instanceMethodAndStaticSetter = c.instanceMethodAndStaticSetter();

  c.Class = c.Class;

  0.extensionInstanceFieldAndSetter = 0.extensionInstanceMethodAndSetter();

  Extension.extensionStaticMethodAndSetter =
      Extension.extensionStaticMethodAndSetter();

  0.extensionStaticMethodAndInstanceSetter =
      Extension.extensionStaticMethodAndInstanceSetter();

  Extension.extensionInstanceMethodAndStaticSetter =
      0.extensionInstanceMethodAndStaticSetter();
}

main() {}
