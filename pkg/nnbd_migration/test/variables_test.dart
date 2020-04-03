// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:nnbd_migration/src/variables.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_UniqueIdentifierForSpanTest);
  });
}

@reflectiveTest
class _UniqueIdentifierForSpanTest {
  void test_inverse() {
    const maxEnd = 1000;
    for (int offset = 0; offset <= maxEnd; offset++) {
      for (int end = offset; end <= maxEnd; end++) {
        var uniqueId = Variables.uniqueIdentifierForSpan(offset, end);
        var decoded = Variables.spanForUniqueIdentifier(uniqueId);
        expect(decoded.offset, offset);
        expect(decoded.end, end);
      }
    }
  }

  void test_uniqueness() {
    const maxEnd = 1000;
    const maxExpectedId = maxEnd * maxEnd;
    var idsSeen = <int, String>{};
    for (int offset = 0; offset <= maxEnd; offset++) {
      for (int end = offset; end <= maxEnd; end++) {
        var pairDescription = '($offset, $end)';
        var uniqueId = Variables.uniqueIdentifierForSpan(offset, end);
        expect(uniqueId, lessThanOrEqualTo(maxExpectedId));
        var previousUseOfThisId = idsSeen[uniqueId];
        expect(previousUseOfThisId, isNull,
            reason:
                '$pairDescription maps to $uniqueId, which was previously used '
                'by $previousUseOfThisId');
        idsSeen[uniqueId] = pairDescription;
      }
    }
  }
}
