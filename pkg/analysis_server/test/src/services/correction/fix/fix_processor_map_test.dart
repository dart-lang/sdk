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

  void _testGenerator(ProducerGenerator generator) {
    var producer = generator();
    var className = producer.runtimeType.toString();
    expect(producer.fixKind, isNotNull, reason: '$className.fixKind');
    if (producer.canBeAppliedToFile) {
      expect(producer.multiFixKind, isNotNull,
          reason: '$className.multiFixKind');
    }
  }

  void _testMap(Iterable<List<ProducerGenerator>> values) {
    for (var generators in values) {
      for (var generator in generators) {
        _testGenerator(generator);
      }
    }
  }
}
