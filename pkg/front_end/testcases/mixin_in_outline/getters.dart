// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

String get topLevelGetter {
  return 'topLevelGetter';
}

class Class {
  String get instanceGetter {
    return 'instanceGetter';
  }

  static String get staticGetter {
    return 'staticGetter';
  }
}

mixin class MixinClass {
  String get instanceGetter {
    return 'instanceGetter';
  }

  static String get staticGetter {
    return 'staticGetter';
  }
}

mixin Mixin {
  String get instanceGetter {
    return 'instanceGetter';
  }

  static String get staticGetter {
    return 'staticGetter';
  }
}

enum Enum {
  a;

  String get instanceGetter {
    return 'instanceGetter';
  }

  static String get staticGetter {
    return 'staticGetter';
  }
}

extension Extension on int {
  String get instanceGetter {
    return 'instanceGetter';
  }

  static String get staticGetter {
    return 'staticGetter';
  }
}

extension type ExtensionType(int it) {
  String get instanceGetter {
    return 'instanceGetter';
  }

  static String get staticGetter {
    return 'staticGetter';
  }
}
