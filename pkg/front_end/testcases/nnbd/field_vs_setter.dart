// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? topLevelFieldAndSetter;
void set topLevelFieldAndSetter(int? value) {}

int? topLevelFieldAndDuplicateSetter;
void set topLevelFieldAndDuplicateSetter(int? value) {}
void set topLevelFieldAndDuplicateSetter(int? value) {}

late final int? topLevelLateFinalFieldAndSetter;
void set topLevelLateFinalFieldAndSetter(int? value) {}

late final int? topLevelLateFinalFieldAndDuplicateSetter;
void set topLevelLateFinalFieldAndDuplicateSetter(int? value) {}
void set topLevelLateFinalFieldAndDuplicateSetter(int? value) {}

class Class {
  int? instanceFieldAndSetter;
  void set instanceFieldAndSetter(int? value) {}

  int? instanceFieldAndDuplicateSetter;
  void set instanceFieldAndDuplicateSetter(int? value) {}
  void set instanceFieldAndDuplicateSetter(int? value) {}

  late final int? instanceLateFinalFieldAndSetter;
  void set instanceLateFinalFieldAndSetter(int? value) {}

  late final int? instanceLateFinalFieldAndDuplicateSetter;
  void set instanceLateFinalFieldAndDuplicateSetter(int? value) {}
  void set instanceLateFinalFieldAndDuplicateSetter(int? value) {}

  static int? staticFieldAndSetter;
  static void set staticFieldAndSetter(int? value) {}

  static int? staticFieldAndDuplicateSetter;
  static void set staticFieldAndDuplicateSetter(int? value) {}
  static void set staticFieldAndDuplicateSetter(int? value) {}

  static late final int? staticLateFinalFieldAndSetter;
  static void set staticLateFinalFieldAndSetter(int? value) {}

  static late final int? staticLateFinalFieldAndDuplicateSetter;
  static void set staticLateFinalFieldAndDuplicateSetter(int? value) {}
  static void set staticLateFinalFieldAndDuplicateSetter(int? value) {}

  static int? staticFieldAndInstanceSetter;
  void set staticFieldAndInstanceSetter(int? value) {}

  static int? staticFieldAndInstanceDuplicateSetter;
  void set staticFieldAndInstanceDuplicateSetter(int? value) {}
  void set staticFieldAndInstanceDuplicateSetter(int? value) {}

  int? instanceFieldAndStaticSetter;
  static void set instanceFieldAndStaticSetter(int? value) {}

  int? instanceFieldAndStaticDuplicateSetter;
  static void set instanceFieldAndStaticDuplicateSetter(int? value) {}
  static void set instanceFieldAndStaticDuplicateSetter(int? value) {}
}

extension Extension on int? {
  int? extensionInstanceFieldAndSetter;
  void set extensionInstanceFieldAndSetter(int? value) {}

  int? extensionInstanceFieldAndDuplicateSetter;
  void set extensionInstanceFieldAndDuplicateSetter(int? value) {}
  void set extensionInstanceFieldAndDuplicateSetter(int? value) {}

  static int? extensionStaticFieldAndSetter;
  static void set extensionStaticFieldAndSetter(int? value) {}

  static int? extensionStaticFieldAndDuplicateSetter;
  static void set extensionStaticFieldAndDuplicateSetter(int? value) {}
  static void set extensionStaticFieldAndDuplicateSetter(int? value) {}

  static late final int? extensionStaticLateFinalFieldAndSetter;
  static void set extensionStaticLateFinalFieldAndSetter(int? value) {}

  static late final int? extensionStaticLateFinalFieldAndDuplicateSetter;
  static void set extensionStaticLateFinalFieldAndDuplicateSetter(int? value) {}
  static void set extensionStaticLateFinalFieldAndDuplicateSetter(int? value) {}

  static int? extensionStaticFieldAndInstanceSetter;
  void set extensionStaticFieldAndInstanceSetter(int? value) {}

  static int? extensionStaticFieldAndInstanceDuplicateSetter;
  void set extensionStaticFieldAndInstanceDuplicateSetter(int? value) {}
  void set extensionStaticFieldAndInstanceDuplicateSetter(int? value) {}

  int? extensionInstanceFieldAndStaticSetter;
  static void set extensionInstanceFieldAndStaticSetter(int? value) {}

  int? extensionInstanceFieldAndStaticDuplicateSetter;
  static void set extensionInstanceFieldAndStaticDuplicateSetter(int? value) {}
  static void set extensionInstanceFieldAndStaticDuplicateSetter(int? value) {}
}

test() {
  topLevelFieldAndSetter = topLevelFieldAndSetter;
  topLevelFieldAndDuplicateSetter = topLevelFieldAndDuplicateSetter;
  topLevelLateFinalFieldAndSetter = topLevelLateFinalFieldAndSetter;
  topLevelLateFinalFieldAndDuplicateSetter =
      topLevelLateFinalFieldAndDuplicateSetter;

  var c = new Class();

  c.instanceFieldAndSetter = c.instanceFieldAndSetter;
  c.instanceFieldAndDuplicateSetter = c.instanceFieldAndDuplicateSetter;
  c.instanceLateFinalFieldAndSetter = c.instanceLateFinalFieldAndSetter;
  c.instanceLateFinalFieldAndDuplicateSetter =
      c.instanceLateFinalFieldAndDuplicateSetter;

  Class.staticFieldAndSetter = Class.staticFieldAndSetter;
  Class.staticFieldAndDuplicateSetter = Class.staticFieldAndDuplicateSetter;
  Class.staticLateFinalFieldAndSetter = Class.staticLateFinalFieldAndSetter;
  Class.staticLateFinalFieldAndDuplicateSetter =
      Class.staticLateFinalFieldAndDuplicateSetter;

  c.staticFieldAndInstanceSetter = Class.staticFieldAndInstanceSetter;
  Class.staticFieldAndInstanceSetter = Class.staticFieldAndInstanceSetter;

  c.staticFieldAndInstanceDuplicateSetter =
      Class.staticFieldAndInstanceDuplicateSetter;
  Class.staticFieldAndInstanceDuplicateSetter =
      Class.staticFieldAndInstanceDuplicateSetter;

  Class.instanceFieldAndStaticSetter = c.instanceFieldAndStaticSetter;
  c.instanceFieldAndStaticSetter = c.instanceFieldAndStaticSetter;

  Class.instanceFieldAndStaticDuplicateSetter =
      c.instanceFieldAndStaticDuplicateSetter;
  c.instanceFieldAndStaticDuplicateSetter =
      c.instanceFieldAndStaticDuplicateSetter;

  0.extensionInstanceFieldAndSetter = 0.extensionInstanceFieldAndSetter;
  0.extensionInstanceFieldAndDuplicateSetter =
      0.extensionInstanceFieldAndDuplicateSetter;

  Extension.extensionStaticFieldAndSetter =
      Extension.extensionStaticFieldAndSetter;

  Extension.extensionStaticFieldAndDuplicateSetter =
      Extension.extensionStaticFieldAndDuplicateSetter;

  Extension.extensionStaticLateFinalFieldAndSetter =
      Extension.extensionStaticLateFinalFieldAndSetter;

  Extension.extensionStaticLateFinalFieldAndDuplicateSetter =
      Extension.extensionStaticLateFinalFieldAndDuplicateSetter;

  0.extensionStaticFieldAndInstanceSetter =
      Extension.extensionStaticFieldAndInstanceSetter;
  Extension.extensionStaticFieldAndInstanceSetter =
      Extension.extensionStaticFieldAndInstanceSetter;

  0.extensionStaticFieldAndInstanceDuplicateSetter =
      Extension.extensionStaticFieldAndInstanceDuplicateSetter;
  Extension.extensionStaticFieldAndInstanceDuplicateSetter =
      Extension.extensionStaticFieldAndInstanceDuplicateSetter;

  Extension.extensionInstanceFieldAndStaticSetter =
      0.extensionInstanceFieldAndStaticSetter;
  0.extensionInstanceFieldAndStaticSetter =
      0.extensionInstanceFieldAndStaticSetter;

  Extension.extensionInstanceFieldAndStaticDuplicateSetter =
      0.extensionInstanceFieldAndStaticDuplicateSetter;
  0.extensionInstanceFieldAndStaticDuplicateSetter =
      0.extensionInstanceFieldAndStaticDuplicateSetter;
}

main() {}
