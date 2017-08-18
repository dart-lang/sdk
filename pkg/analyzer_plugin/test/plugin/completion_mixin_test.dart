// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/completion_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:path/src/context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(CompletionMixinTest);
}

@reflectiveTest
class CompletionMixinTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  MockChannel channel;
  _TestServerPlugin plugin;

  void setUp() {
    Context pathContext = resourceProvider.pathContext;

    packagePath1 = resourceProvider.convertPath('/package1');
    filePath1 = pathContext.join(packagePath1, 'lib', 'test.dart');
    resourceProvider.newFile(filePath1, 'int foo = bar;');
    contextRoot1 = new ContextRoot(packagePath1, <String>[]);

    channel = new MockChannel();
    plugin = new _TestServerPlugin(resourceProvider);
    plugin.start(channel);
  }

  test_handleCompletionGetSuggestions() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    CompletionGetSuggestionsResult result =
        await plugin.handleCompletionGetSuggestions(
            new CompletionGetSuggestionsParams(filePath1, 13));
    expect(result, isNotNull);
    expect(result.results, hasLength(3));
  }
}

class _TestCompletionContributor implements CompletionContributor {
  List<CompletionSuggestion> suggestions;

  _TestCompletionContributor(this.suggestions);

  @override
  Future<Null> computeSuggestions(
      CompletionRequest request, CompletionCollector collector) async {
    if ((collector as CompletionCollectorImpl).offset == null) {
      collector.offset = 1;
      collector.length = 2;
    }
    for (CompletionSuggestion suggestion in suggestions) {
      collector.addSuggestion(suggestion);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with CompletionMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  CompletionSuggestion createSuggestion() {
    return new CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER, 1, '', 0, 0, false, false);
  }

  @override
  List<CompletionContributor> getCompletionContributors(String path) {
    return <CompletionContributor>[
      new _TestCompletionContributor(
          <CompletionSuggestion>[createSuggestion(), createSuggestion()]),
      new _TestCompletionContributor(
          <CompletionSuggestion>[createSuggestion()]),
    ];
  }

  @override
  Future<CompletionRequest> getCompletionRequest(
      CompletionGetSuggestionsParams parameters) async {
    AnalysisResult result = new AnalysisResult(
        null, null, null, null, null, null, null, null, null, null, null);
    return new DartCompletionRequestImpl(
        resourceProvider, parameters.offset, result);
  }
}
