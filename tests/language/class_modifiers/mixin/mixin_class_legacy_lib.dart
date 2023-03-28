// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.19

// Provide classes from a pre 3.0 library for use in tests of behaviors around
// mixin classes crossing language versions.

export 'mixin_class_lib.dart' show NotAMixinClass, Class;

class LegacyNotAMixinClass {}

class LegacyNotAMixinClassWithConstructor {
  LegacyNotAMixinClassWithConstructor();
}
