// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Contexts with a prefix import should still work with dot shorthands.

import '../dot_shorthand_helper.dart' as prefix;

void main() {
  prefix.Integer integer = .one;
  const prefix.Integer constInteger = .constOne;

  // Nested
  prefix.ConstructorClass ctorMemberCtor = .staticMember(.ctor(.named(x: 1)));

  // Selector chain
  prefix.StaticMember memberMixed2 = .member().field.method();
}
