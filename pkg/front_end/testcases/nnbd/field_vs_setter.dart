// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? topLevelFieldAndSetter;
void set topLevelFieldAndSetter(int? value) {}

late final int? topLevelLateFinalFieldAndSetter;
void set topLevelLateFinalFieldAndSetter(int? value) {}

class Class {
  int? instanceFieldAndSetter;
  void set instanceFieldAndSetter(int? value) {}

  late final int? instanceLateFinalFieldAndSetter;
  void set instanceLateFinalFieldAndSetter(int? value) {}

  static int? staticFieldAndSetter;
  static void set staticFieldAndSetter(int? value) {}

  static late final int? staticLateFinalFieldAndSetter;
  static void set staticLateFinalFieldAndSetter(int? value) {}

  static int? staticFieldAndInstanceSetter;
  void set staticFieldAndInstanceSetter(int? value) {}

  int? instanceFieldAndStaticSetter;
  static void set instanceFieldAndStaticSetter(int? value) {}
}

extension Extension on int? {
  int? extensionInstanceFieldAndSetter;
  void set extensionInstanceFieldAndSetter(int? value) {}

  static int? extensionStaticFieldAndSetter;
  static void set extensionStaticFieldAndSetter(int? value) {}

  static late final int? extensionStaticLateFinalFieldAndSetter;
  static void set extensionStaticFieldAndSetter(int? value) {}

  static int? extensionStaticFieldAndInstanceSetter;
  void set extensionStaticFieldAndInstanceSetter(int? value) {}

  int? extensionInstanceFieldAndStaticSetter;
  static void set extensionInstanceFieldAndStaticSetter(int? value) {}
}

test() {
  topLevelFieldAndSetter = topLevelFieldAndSetter;
  topLevelLateFinalFieldAndSetter = topLevelLateFinalFieldAndSetter;

  var c = new Class();

  c.instanceFieldAndSetter = c.instanceFieldAndSetter;
  c.instanceLateFinalFieldAndSetter = c.instanceLateFinalFieldAndSetter;

  Class.staticFieldAndSetter = Class.staticFieldAndSetter;
  Class.staticLateFinalFieldAndSetter = Class.staticLateFinalFieldAndSetter;

  c.staticFieldAndInstanceSetter = Class.staticFieldAndInstanceSetter;
  Class.staticFieldAndInstanceSetter = Class.staticFieldAndInstanceSetter;

  Class.instanceFieldAndStaticSetter = c.instanceFieldAndStaticSetter;
  c.instanceFieldAndStaticSetter = c.instanceFieldAndStaticSetter;

  0.extensionInstanceFieldAndSetter = 0.extensionInstanceFieldAndSetter;

  Extension.extensionStaticFieldAndSetter =
      Extension.extensionStaticFieldAndSetter;
  Extension.extensionStaticLateFinalFieldAndSetter =
      Extension.extensionStaticLateFinalFieldAndSetter;

  0.extensionStaticFieldAndInstanceSetter =
      Extension.extensionStaticFieldAndInstanceSetter;
  Extension.extensionStaticFieldAndInstanceSetter =
      Extension.extensionStaticFieldAndInstanceSetter;

  Extension.extensionInstanceFieldAndStaticSetter =
      0.extensionInstanceFieldAndStaticSetter;
  0.extensionInstanceFieldAndStaticSetter =
      0.extensionInstanceFieldAndStaticSetter;
}

main() {}
