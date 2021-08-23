// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/correction/dart/abstract_producer.dart';
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

  void test_registerFixForLint() {
    CorrectionProducer producer() => MockCorrectionProducer();

    var lintName = 'not_a_lint';
    expect(FixProcessor.lintProducerMap[lintName], null);
    FixProcessor.registerFixForLint(lintName, producer);
    expect(FixProcessor.lintProducerMap[lintName], contains(producer));
    // Restore the map to it's original state so as to not impact other tests.
    FixProcessor.lintProducerMap.remove(lintName);
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

class MockCorrectionProducer implements CorrectionProducer {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
