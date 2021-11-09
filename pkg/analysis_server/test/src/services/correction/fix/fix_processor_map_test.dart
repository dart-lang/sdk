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
  static const List<String> lintsAllowedToHaveMultipleBulkFixes = [
    'avoid_types_on_closure_parameters',
    'empty_statements',
    'prefer_collection_literals',
    'prefer_const_constructors',
    'prefer_inlined_adds',
  ];

  void test_lintProducerMap() {
    _assertMap(FixProcessor.lintProducerMap.entries,
        lintsAllowedToHaveMultipleBulkFixes);
  }

  void test_nonLintProducerMap() {
    _assertMap(FixProcessor.nonLintProducerMap.entries);
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

  void _assertMap<K>(Iterable<MapEntry<K, List<ProducerGenerator>>> entries,
      [List<String> keysAllowedToHaveMultipleBulkFixes = const []]) {
    var list = <String>[];
    for (var entry in entries) {
      var bulkCount = 0;
      for (var generator in entry.value) {
        var producer = generator();
        _assertValidProducer(producer);
        if (producer.canBeAppliedInBulk) {
          bulkCount++;
        }
      }
      if (bulkCount > 1) {
        var key = entry.key.toString();
        if (!keysAllowedToHaveMultipleBulkFixes.contains(key)) {
          list.add(key);
        }
      }
    }
    if (list.isNotEmpty) {
      var buffer = StringBuffer();
      buffer.writeln('Multiple bulk fixes for');
      for (var code in list) {
        buffer.writeln('- $code');
      }
      fail(buffer.toString());
    }
  }

  void _assertValidProducer(CorrectionProducer producer) {
    var className = producer.runtimeType.toString();
    expect(producer.fixKind, isNotNull, reason: '$className.fixKind');
    if (producer.canBeAppliedToFile) {
      expect(producer.multiFixKind, isNotNull,
          reason: '$className.multiFixKind');
    }
  }
}

class MockCorrectionProducer implements CorrectionProducer {
  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
