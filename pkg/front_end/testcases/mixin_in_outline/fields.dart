// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String topLevelField = 'topLevelField';

class Class {
  String instanceField = 'instanceField';

  static String staticField = 'staticField';
}

mixin class MixinClass {
  String instanceField = 'instanceField';

  static String staticField = 'staticField';
}

mixin Mixin {
  String instanceField = 'instanceField';

  static String staticField = 'staticField';
}

enum Enum {
  a;

  final String instanceField = 'instanceField';

  static String staticField = 'staticField';
}

extension Extension on int {
  static String staticField = 'staticField';
}

extension type ExtensionType(int it) {
  static String staticField = 'staticField';
}
