// Copyright (c) 2025, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/src/test_utilities/platform.dart';
import 'package:test/test.dart';

/// Returns a matcher that checks that the input matches [expected] after
/// newlines have been normalized to the current platforms (only in
/// [expected]).
Matcher equalsNormalized(Object? expected) {
  return switch (expected) {
    String() => equals(normalizeNewlinesForPlatform(expected)),
    List<String>() => equals(expected.map(normalizeNewlinesForPlatform)),
    _ => throw UnimplementedError("Can't normalize a ${expected.runtimeType}"),
  };
}
