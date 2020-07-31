// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Annotation {
  const Annotation();
}

@Annotation()
late int topLevelField;

@Annotation()
late final int finalTopLevelField;

@Annotation()
late final int finalTopLevelFieldWithInitializer = 0;

class A {
  @Annotation()
  late int instanceField;

  @Annotation()
  late final int finalInstanceField;

  @Annotation()
  late final int finalInstanceFieldWithInitializer = 0;

  @Annotation()
  covariant late num covariantInstanceField;

  @Annotation()
  static late int staticField;

  @Annotation()
  static late final int finalStaticField;

  @Annotation()
  static late final int finalStaticFieldWithInitializer = 0;
}

mixin B {
  @Annotation()
  late int instanceField;

  @Annotation()
  late final int finalInstanceField;

  @Annotation()
  late final int finalInstanceFieldWithInitializer = 0;

  @Annotation()
  covariant late num covariantInstanceField;

  @Annotation()
  static late int staticField;

  @Annotation()
  static late final int finalStaticField;

  @Annotation()
  static late final int finalStaticFieldWithInitializer = 0;
}

extension Extension on A {
  @Annotation()
  static late int extensionStaticField;

  @Annotation()
  static late final int finalExtensionStaticField;

  @Annotation()
  static late final int finalExtensionStaticFieldWithInitializer = 0;
}

main() {}
