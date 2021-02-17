// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

int? topLevelFieldAndSetter;
void set topLevelFieldAndSetter(int? value) {}

int? topLevelFieldAndDuplicateSetter;
void set topLevelFieldAndDuplicateSetter(int? value) {}
void set topLevelFieldAndDuplicateSetter(int? value) {}

int? duplicateTopLevelFieldAndSetter1;
final int? duplicateTopLevelFieldAndSetter1 = null;
void set duplicateTopLevelFieldAndSetter1(int? value) {}

final int? duplicateTopLevelFieldAndSetter2 = null;
int? duplicateTopLevelFieldAndSetter2;
void set duplicateTopLevelFieldAndSetter2(int? value) {}

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

  int? duplicateInstanceFieldAndSetter1;
  final int? duplicateInstanceFieldAndSetter1 = null;
  void set duplicateInstanceFieldAndSetter1(int? value) {}

  final int? duplicateInstanceFieldAndSetter2 = null;
  int? duplicateInstanceFieldAndSetter2;
  void set duplicateInstanceFieldAndSetter2(int? value) {}

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

  static int? duplicateStaticFieldAndSetter1;
  static final int? duplicateStaticFieldAndSetter1 = null;
  static void set duplicateStaticFieldAndSetter1(int? value) {}

  static final int? duplicateStaticFieldAndSetter2 = null;
  static int? duplicateStaticFieldAndSetter2;
  static void set duplicateStaticFieldAndSetter2(int? value) {}

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

  int? duplicateInstanceFieldAndStaticSetter1;
  final int? duplicateInstanceFieldAndStaticSetter1 = null;
  static void set duplicateInstanceFieldAndStaticSetter1(int? value) {}

  final int? duplicateInstanceFieldAndStaticSetter2 = null;
  int? duplicateInstanceFieldAndStaticSetter2;
  static void set duplicateInstanceFieldAndStaticSetter2(int? value) {}

  static int? duplicateStaticFieldAndInstanceSetter1;
  static final int? duplicateStaticFieldAndInstanceSetter1 = null;
  void set duplicateStaticFieldAndInstanceSetter1(int? value) {}

  static final int? duplicateStaticFieldAndInstanceSetter2 = null;
  static int? duplicateStaticFieldAndInstanceSetter2;
  void set duplicateStaticFieldAndInstanceSetter2(int? value) {}
}

extension Extension on int? {
  int? extensionInstanceFieldAndSetter;
  void set extensionInstanceFieldAndSetter(int? value) {}

  int? extensionInstanceFieldAndDuplicateSetter;
  void set extensionInstanceFieldAndDuplicateSetter(int? value) {}
  void set extensionInstanceFieldAndDuplicateSetter(int? value) {}

  int? duplicateExtensionInstanceFieldAndSetter1;
  final int? duplicateExtensionInstanceFieldAndSetter1 = null;
  void set duplicateExtensionInstanceFieldAndSetter1(int? value) {}

  final int? duplicateExtensionInstanceFieldAndSetter2 = null;
  int? duplicateExtensionInstanceFieldAndSetter2;
  void set duplicateExtensionInstanceFieldAndSetter2(int? value) {}

  static int? extensionStaticFieldAndSetter;
  static void set extensionStaticFieldAndSetter(int? value) {}

  static int? extensionStaticFieldAndDuplicateSetter;
  static void set extensionStaticFieldAndDuplicateSetter(int? value) {}
  static void set extensionStaticFieldAndDuplicateSetter(int? value) {}

  static int? duplicateExtensionStaticFieldAndSetter1;
  static final int? duplicateExtensionStaticFieldAndSetter1 = null;
  static void set duplicateExtensionStaticFieldAndSetter1(int? value) {}

  static final int? duplicateExtensionStaticFieldAndSetter2 = null;
  static int? duplicateExtensionStaticFieldAndSetter2;
  static void set duplicateExtensionStaticFieldAndSetter2(int? value) {}

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

  int? duplicateExtensionInstanceFieldAndStaticSetter1;
  final int? duplicateExtensionInstanceFieldAndStaticSetter1 = null;
  static void set duplicateExtensionInstanceFieldAndStaticSetter1(int? value) {}

  final int? duplicateExtensionInstanceFieldAndStaticSetter2 = null;
  int? duplicateExtensionInstanceFieldAndStaticSetter2;
  static void set duplicateExtensionInstanceFieldAndStaticSetter2(int? value) {}

  static int? duplicateExtensionStaticFieldAndInstanceSetter1;
  static final int? duplicateExtensionStaticFieldAndInstanceSetter1 = null;
  void set duplicateExtensionStaticFieldAndInstanceSetter1(int? value) {}

  static final int? duplicateExtensionStaticFieldAndInstanceSetter2 = null;
  static int? duplicateExtensionStaticFieldAndInstanceSetter2;
  void set duplicateExtensionStaticFieldAndInstanceSetter2(int? value) {}
}

test() {
  topLevelFieldAndSetter = topLevelFieldAndSetter;
  topLevelFieldAndDuplicateSetter = topLevelFieldAndDuplicateSetter;
  topLevelLateFinalFieldAndSetter = topLevelLateFinalFieldAndSetter;
  topLevelLateFinalFieldAndDuplicateSetter =
      topLevelLateFinalFieldAndDuplicateSetter;
  duplicateTopLevelFieldAndSetter1 = duplicateTopLevelFieldAndSetter1;
  duplicateTopLevelFieldAndSetter2 = duplicateTopLevelFieldAndSetter2;

  var c = new Class();

  c.instanceFieldAndSetter = c.instanceFieldAndSetter;
  c.instanceFieldAndDuplicateSetter = c.instanceFieldAndDuplicateSetter;
  c.instanceLateFinalFieldAndSetter = c.instanceLateFinalFieldAndSetter;
  c.instanceLateFinalFieldAndDuplicateSetter =
      c.instanceLateFinalFieldAndDuplicateSetter;
  c.duplicateInstanceFieldAndStaticSetter1 =
      c.duplicateInstanceFieldAndStaticSetter1;
  c.duplicateInstanceFieldAndStaticSetter2 =
      c.duplicateInstanceFieldAndStaticSetter2;

  Class.staticFieldAndSetter = Class.staticFieldAndSetter;
  Class.staticFieldAndDuplicateSetter = Class.staticFieldAndDuplicateSetter;
  Class.staticLateFinalFieldAndSetter = Class.staticLateFinalFieldAndSetter;
  Class.staticLateFinalFieldAndDuplicateSetter =
      Class.staticLateFinalFieldAndDuplicateSetter;
  Class.duplicateStaticFieldAndSetter1 = Class.duplicateStaticFieldAndSetter1;
  Class.duplicateStaticFieldAndSetter2 = Class.duplicateStaticFieldAndSetter2;

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

  c.duplicateStaticFieldAndInstanceSetter1 =
      Class.duplicateStaticFieldAndInstanceSetter1;
  Class.duplicateStaticFieldAndInstanceSetter1 =
      Class.duplicateStaticFieldAndInstanceSetter1;

  c.duplicateStaticFieldAndInstanceSetter2 =
      Class.duplicateStaticFieldAndInstanceSetter2;
  Class.duplicateStaticFieldAndInstanceSetter2 =
      Class.duplicateStaticFieldAndInstanceSetter2;

  Class.duplicateInstanceFieldAndStaticSetter1 =
      0.duplicateInstanceFieldAndStaticSetter1;
  Class.duplicateInstanceFieldAndStaticSetter2 =
      0.duplicateInstanceFieldAndStaticSetter2;

  0.extensionInstanceFieldAndSetter = 0.extensionInstanceFieldAndSetter;
  0.extensionInstanceFieldAndDuplicateSetter =
      0.extensionInstanceFieldAndDuplicateSetter;

  0.duplicateExtensionInstanceFieldAndSetter1 =
      0.duplicateExtensionInstanceFieldAndSetter1;
  0.duplicateExtensionInstanceFieldAndSetter2 =
      0.duplicateExtensionInstanceFieldAndSetter2;

  Extension.extensionStaticFieldAndSetter =
      Extension.extensionStaticFieldAndSetter;

  Extension.extensionStaticFieldAndDuplicateSetter =
      Extension.extensionStaticFieldAndDuplicateSetter;

  Extension.extensionStaticLateFinalFieldAndSetter =
      Extension.extensionStaticLateFinalFieldAndSetter;

  Extension.extensionStaticLateFinalFieldAndDuplicateSetter =
      Extension.extensionStaticLateFinalFieldAndDuplicateSetter;
  Extension.duplicateExtensionStaticFieldAndSetter1 =
      Extension.duplicateExtensionStaticFieldAndSetter1;
  Extension.duplicateExtensionStaticFieldAndSetter2 =
      Extension.duplicateExtensionStaticFieldAndSetter2;

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

  Extension.duplicateExtensionInstanceFieldAndStaticSetter1 =
      0.duplicateExtensionInstanceFieldAndStaticSetter1;
  0.duplicateExtensionInstanceFieldAndStaticSetter1 =
      0.duplicateExtensionInstanceFieldAndStaticSetter1;

  Extension.duplicateExtensionInstanceFieldAndStaticSetter2 =
      0.duplicateExtensionInstanceFieldAndStaticSetter2;
  0.duplicateExtensionInstanceFieldAndStaticSetter2 =
      0.duplicateExtensionInstanceFieldAndStaticSetter2;

  Extension.duplicateExtensionStaticFieldAndInstanceSetter1 =
      Extension.duplicateExtensionStaticFieldAndInstanceSetter1;
  0.duplicateExtensionStaticFieldAndInstanceSetter1 =
      Extension.duplicateExtensionStaticFieldAndInstanceSetter1;

  Extension.duplicateExtensionStaticFieldAndInstanceSetter2 =
      Extension.duplicateExtensionStaticFieldAndInstanceSetter2;
  0.duplicateExtensionStaticFieldAndInstanceSetter2 =
      Extension.duplicateExtensionStaticFieldAndInstanceSetter2;
}

main() {}
