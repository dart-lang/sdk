// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Can't run in strong mode since it contains a legacy library.
// Requirements=nnbd-weak

import 'package:expect/expect.dart';
import 'legacy_library.dart';

// Type tests (is checks) located in a null safe library.
main() {
  Expect.isFalse(null is Never);
  // `null is Never*`
  Expect.isTrue(nullSafeIsLegacy<Never>(null));
  Expect.isTrue(null is Never?);
  Expect.isTrue(null is Null);
  Expect.isFalse(null is Object);
  // `null is Object*`
  Expect.isTrue(nullSafeIsLegacy<Object>(null));
  Expect.isTrue(null is Object?);
  Expect.isTrue(null is dynamic);

  // Testing all built in types because of a regression that caused them to be
  // handled differently https://github.com/dart-lang/sdk/issues/42851.
  Expect.isFalse(null is bool);
  // `null is bool*`
  Expect.isFalse(nullSafeIsLegacy<bool>(null));
  Expect.isTrue(null is bool?);
  Expect.isFalse(null is num);
  // `null is num*`
  Expect.isFalse(nullSafeIsLegacy<num>(null));
  Expect.isTrue(null is num?);
  Expect.isFalse(null is int);
  // `null is int*`
  Expect.isFalse(nullSafeIsLegacy<int>(null));
  Expect.isTrue(null is int?);
  Expect.isFalse(null is double);
  // `null is double*`
  Expect.isFalse(nullSafeIsLegacy<double>(null));
  Expect.isTrue(null is double?);
  Expect.isFalse(null is String);
  // `null is String*`
  Expect.isFalse(nullSafeIsLegacy<String>(null));
  Expect.isTrue(null is String?);
  Expect.isFalse(null is List);
  // `null is List*`
  Expect.isFalse(nullSafeIsLegacy<List>(null));
  Expect.isTrue(null is List?);
  Expect.isFalse(null is Set);
  // `null is Set*`
  Expect.isFalse(nullSafeIsLegacy<Set>(null));
  Expect.isTrue(null is Set?);
  Expect.isFalse(null is Map);
  // `null is Map*`
  Expect.isFalse(nullSafeIsLegacy<Map>(null));
  Expect.isTrue(null is Map?);
  Expect.isFalse(null is Symbol);
  // `null is Symbol*`
  Expect.isFalse(nullSafeIsLegacy<Symbol>(null));
  Expect.isTrue(null is Symbol?);
}
