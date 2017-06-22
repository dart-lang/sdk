// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_test_helper;

import 'test_data.dart';

/// Returns the test arguments for testing the [index]th skipped test. The
/// [skip] count is used to check that [index] is a valid index.
List<String> testSkipped(int index, int skip) {
  if (index < 0 || index >= skip) {
    throw new ArgumentError('Invalid skip index $index');
  }
  return ['${index}', '${index + 1}'];
}

/// Return the test arguments for testing the [index]th segment (1-based) of
/// the [TESTS] split into [count] groups. The first [skip] tests are excluded
/// from the automatic grouping.
List<String> testSegment(int index, int count, int skip) {
  if (index < 0 || index > count) {
    throw new ArgumentError('Invalid segment index $index');
  }

  String segmentNumber(int i) {
    return '${skip + i * (TESTS.length - skip) ~/ count}';
  }

  if (index == 1 && skip != 0) {
    return ['${skip}', segmentNumber(index)];
  } else if (index == count) {
    return [segmentNumber(index - 1)];
  } else {
    return [segmentNumber(index - 1), segmentNumber(index)];
  }
}
