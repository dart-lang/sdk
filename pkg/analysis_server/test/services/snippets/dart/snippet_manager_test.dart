// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart/snippet_manager.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SnippetManagerTest);
  });
}

@reflectiveTest
class SnippetManagerTest extends AbstractSingleUnitTest {
  Future<void> test_notValidProducers() async {
    await resolveTestCode('');
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: 0,
    );

    final manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_NotValidSnippetProducer.newInstance],
    });
    final results = await manager.computeSnippets(request);
    expect(results, isEmpty);
  }

  Future<void> test_onlyCreatesForContext() async {
    await resolveTestCode('');
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: 0,
    );

    final manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_ValidSnippetProducer.newInstance],
      SnippetContext.inClass: [
        (context) => throw 'Tried to create producer for wrong context',
      ]
    });
    final results = await manager.computeSnippets(request);
    expect(results, hasLength(1));
  }

  Future<void> test_validProducers() async {
    await resolveTestCode('');
    final request = DartSnippetRequest(
      unit: testAnalysisResult,
      offset: 0,
    );

    final manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_ValidSnippetProducer.newInstance],
    });
    final results = await manager.computeSnippets(request);
    expect(results, hasLength(1));
    final snippet = results.single;
    expect(snippet.prefix, 'mysnip');
    expect(snippet.label, 'My Test Snippet');
  }
}

/// A snippet producer that always returns `false` from [isValid] and throws
/// if [compute] is called.
class _NotValidSnippetProducer extends SnippetProducer {
  _NotValidSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() {
    throw UnsupportedError(
      'compute should not be called for a producer '
      'that returned false from isValid',
    );
  }

  @override
  Future<bool> isValid() async => false;

  static _NotValidSnippetProducer newInstance(DartSnippetRequest request) =>
      _NotValidSnippetProducer._(request);
}

class _TestDartSnippetManager extends DartSnippetManager {
  @override
  final Map<SnippetContext, List<SnippetProducerGenerator>> producerGenerators;

  _TestDartSnippetManager(this.producerGenerators);
}

/// A snippet producer that always returns `true` from [isValid] and a simple
/// snippet from [compute].
class _ValidSnippetProducer extends SnippetProducer {
  _ValidSnippetProducer._(DartSnippetRequest request) : super(request);

  @override
  Future<Snippet> compute() async {
    return Snippet(
      'mysnip',
      'My Test Snippet',
      'This is a test snippet',
      SourceChange('message'),
    );
  }

  @override
  Future<bool> isValid() async => true;

  static _ValidSnippetProducer newInstance(DartSnippetRequest request) =>
      _ValidSnippetProducer._(request);
}
