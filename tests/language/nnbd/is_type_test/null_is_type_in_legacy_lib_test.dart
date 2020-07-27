// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Opt out of Null Safety:
// @dart = 2.6

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';
import 'null_safe_library.dart';

// Type tests (is checks) located in a legacy library.
main() {
  // `null is Never*`
  Expect.isTrue(null is Never);
  // `null is Never?`
  Expect.isTrue(legacyIsNullable<Never>(null));
  Expect.isTrue(null is Null);
  // `null is Object*`
  Expect.isTrue(null is Object);
  // `null is Object?`
  Expect.isTrue(legacyIsNullable<Object>(null));
  Expect.isTrue(null is dynamic);

  // Testing all built in types because of a regression that caused them to be
  // handled differently https://github.com/dart-lang/sdk/issues/42851.
  // `null is bool*`
  Expect.isFalse(null is bool);
  // `null is bool?`
  Expect.isTrue(legacyIsNullable<bool>(null));
  // `null is num*`
  Expect.isFalse(null is num);
  // `null is num?`
  Expect.isTrue(legacyIsNullable<num>(null));
  // `null is int*`
  Expect.isFalse(null is int);
  // `null is int?`
  Expect.isTrue(legacyIsNullable<int>(null));
  // `null is double*`
  Expect.isFalse(null is double);
  // `null is double?`
  Expect.isTrue(legacyIsNullable<double>(null));
  // `null is String*`
  Expect.isFalse(null is String);
  // `null is String?`
  Expect.isTrue(legacyIsNullable<String>(null));
  // `null is List*`
  Expect.isFalse(null is List);
  // `null is List?
  Expect.isTrue(legacyIsNullable<List>(null));
  // `null is Set*`
  Expect.isFalse(null is Set);
  // `null is Set?
  Expect.isTrue(legacyIsNullable<Set>(null));
  // `null is Map*`
  Expect.isFalse(null is Map);
  // `null is Map?
  Expect.isTrue(legacyIsNullable<Map>(null));
  // `null is Symbol*`
  Expect.isFalse(null is Symbol);
  // `null is Symbol?
  Expect.isTrue(legacyIsNullable<Symbol>(null));
}
