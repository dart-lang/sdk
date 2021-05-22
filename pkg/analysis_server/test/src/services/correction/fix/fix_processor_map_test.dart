// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/fix_internal.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FixProcessorMapTest);
  });
}

@reflectiveTest
class FixProcessorMapTest {
  void test_lintProducerMap() {
    _testMap(FixProcessor.lintProducerMap.values);
  }

  void test_nonLintProducerMap() {
    _testMap(FixProcessor.nonLintProducerMap.values);
  }

  void _testInfo(FixInfo info) {
    for (var generator in info.generators) {
      var producer = generator();
      var className = producer.runtimeType.toString();
      expect(producer.fixKind, isNotNull, reason: '$className.fixKind');
      if (info.canBeAppliedToFile) {
        expect(producer.multiFixKind, isNotNull,
            reason: '$className.multiFixKind');
      }
    }
  }

  void _testMap(Iterable<List<FixInfo>> values) {
    for (var list in values) {
      for (var info in list) {
        _testInfo(info);
      }
    }
  }
}
