// Copyright (c) 2022, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/snippets/dart_snippet_request.dart';
import 'package:analysis_server/src/services/snippets/snippet.dart';
import 'package:analysis_server/src/services/snippets/snippet_context.dart';
import 'package:analysis_server/src/services/snippets/snippet_manager.dart';
import 'package:analysis_server/src/services/snippets/snippet_producer.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart' hide Element;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../abstract_single_unit.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(SnippetManagerTest);
  });
}

@reflectiveTest
class SnippetManagerTest extends AbstractSingleUnitTest {
  Future<void> test_filter_match() async {
    await resolveTestCode('');
    var request = DartSnippetRequest(unit: testAnalysisResult, offset: 0);

    var manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_ValidSnippetProducer.newInstance],
    });
    var results = await manager.computeSnippets(
      request,
      filter: (String s) => true,
    );
    expect(results, isNotEmpty);
  }

  Future<void> test_filter_noMatch() async {
    await resolveTestCode('');
    var request = DartSnippetRequest(unit: testAnalysisResult, offset: 0);

    var manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_ValidSnippetProducer.newInstance],
    });
    var results = await manager.computeSnippets(
      request,
      filter: (String s) => false,
    );
    expect(results, isEmpty);
  }

  Future<void> test_notValidProducers() async {
    await resolveTestCode('');
    var request = DartSnippetRequest(unit: testAnalysisResult, offset: 0);

    var manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_NotValidSnippetProducer.newInstance],
    });
    var results = await manager.computeSnippets(request);
    expect(results, isEmpty);
  }

  Future<void> test_onlyCreatesForContext() async {
    await resolveTestCode('');
    var request = DartSnippetRequest(unit: testAnalysisResult, offset: 0);

    var manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_ValidSnippetProducer.newInstance],
      SnippetContext.inClass: [
        (
          context, {
          required Map<Element2, LibraryElement2?> elementImportCache,
        }) => throw 'Tried to create producer for wrong context',
      ],
    });
    var results = await manager.computeSnippets(request);
    expect(results, hasLength(1));
  }

  Future<void> test_validProducers() async {
    await resolveTestCode('');
    var request = DartSnippetRequest(unit: testAnalysisResult, offset: 0);

    var manager = _TestDartSnippetManager({
      SnippetContext.atTopLevel: [_ValidSnippetProducer.newInstance],
    });
    var results = await manager.computeSnippets(request);
    expect(results, hasLength(1));
    var snippet = results.single;
    expect(snippet.prefix, 'mysnip');
    expect(snippet.label, 'My Test Snippet');
  }
}

/// A snippet producer that always returns `false` from [isValid] and throws
/// if [compute] is called.
class _NotValidSnippetProducer extends SnippetProducer {
  _NotValidSnippetProducer._(super.request);

  @override
  String get snippetPrefix => 'invalid';

  @override
  Future<Snippet> compute() {
    throw UnsupportedError(
      'compute should not be called for a producer '
      'that returned false from isValid',
    );
  }

  @override
  Future<bool> isValid() async => false;

  static _NotValidSnippetProducer newInstance(
    DartSnippetRequest request, {
    required Map<Element2, LibraryElement2?> elementImportCache,
  }) => _NotValidSnippetProducer._(request);
}

class _TestDartSnippetManager extends DartSnippetManager {
  @override
  final Map<SnippetContext, List<SnippetProducerGenerator>> producerGenerators;

  _TestDartSnippetManager(this.producerGenerators);
}

/// A snippet producer that always returns `true` from [isValid] and a simple
/// snippet from [compute].
class _ValidSnippetProducer extends SnippetProducer {
  _ValidSnippetProducer._(super.request);

  @override
  String get snippetPrefix => 'mysnip';

  @override
  Future<Snippet> compute() async {
    return Snippet(
      snippetPrefix,
      'My Test Snippet',
      'This is a test snippet',
      SourceChange('message'),
    );
  }

  @override
  Future<bool> isValid() async => true;

  static _ValidSnippetProducer newInstance(
    DartSnippetRequest request, {
    required Map<Element2, LibraryElement2?> elementImportCache,
  }) => _ValidSnippetProducer._(request);
}
