// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/completion_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/completion/completion_core.dart';
import 'package:analyzer_plugin/utilities/completion/completion_core.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(CompletionMixinTest);
}

@reflectiveTest
class CompletionMixinTest with ResourceProviderMixin {
  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  MockChannel channel;
  _TestServerPlugin plugin;

  void setUp() {
    packagePath1 = convertPath('/package1');
    filePath1 = join(packagePath1, 'lib', 'test.dart');
    newFile(filePath1, content: 'int foo = bar;');
    contextRoot1 = ContextRoot(packagePath1, <String>[]);

    channel = MockChannel();
    plugin = _TestServerPlugin(resourceProvider);
    plugin.start(channel);
  }

  Future<void> test_handleCompletionGetSuggestions() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result = await plugin.handleCompletionGetSuggestions(
        CompletionGetSuggestionsParams(filePath1, 13));
    expect(result, isNotNull);
    expect(result.results, hasLength(3));
  }
}

class _TestCompletionContributor implements CompletionContributor {
  List<CompletionSuggestion> suggestions;

  _TestCompletionContributor(this.suggestions);

  @override
  Future<void> computeSuggestions(
      CompletionRequest request, CompletionCollector collector) async {
    if ((collector as CompletionCollectorImpl).offset == null) {
      collector.offset = 1;
      collector.length = 2;
    }
    for (var suggestion in suggestions) {
      collector.addSuggestion(suggestion);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with CompletionMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  CompletionSuggestion createSuggestion() {
    return CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER, 1, '', 0, 0, false, false);
  }

  @override
  List<CompletionContributor> getCompletionContributors(String path) {
    return <CompletionContributor>[
      _TestCompletionContributor(
          <CompletionSuggestion>[createSuggestion(), createSuggestion()]),
      _TestCompletionContributor(<CompletionSuggestion>[createSuggestion()]),
    ];
  }

  @override
  Future<CompletionRequest> getCompletionRequest(
      CompletionGetSuggestionsParams parameters) async {
    var result = MockResolvedUnitResult();
    return DartCompletionRequestImpl(
        resourceProvider, parameters.offset, result);
  }
}
