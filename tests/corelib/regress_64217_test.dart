// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64217.
// Verify that LinkedHashMap.removeWhere does not leave stale index.

import 'dart:collection';

import "package:expect/expect.dart";

void main() {
  final map = LinkedHashMap<String, String>(
    equals: (a, b) => a.toLowerCase() == b.toLowerCase(),
    hashCode: (key) => key.toLowerCase().hashCode,
  )..['X-Auth-Token'] = 'old';

  map.removeWhere((key, value) => true);
  map['X-Auth-Token'] = 'new';

  Expect.equals(1, map.length);
  Expect.equals('new', map['X-Auth-Token']);
}
