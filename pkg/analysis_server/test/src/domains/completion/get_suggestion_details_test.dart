// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(GetSuggestionDetailsTest);
  });
}

@reflectiveTest
class GetSuggestionDetailsTest extends AbstractAnalysisTest {
  final Map<int, AvailableSuggestionSet> idToSetMap = {};
  final Map<String, AvailableSuggestionSet> uriToSetMap = {};

  @override
  void processNotification(Notification notification) {
    if (notification.event == COMPLETION_NOTIFICATION_AVAILABLE_SUGGESTIONS) {
      var params = CompletionAvailableSuggestionsParams.fromNotification(
        notification,
      );
      for (var set in params.changedLibraries) {
        idToSetMap[set.id] = set;
        uriToSetMap[set.uri] = set;
      }
      for (var id in params.removedLibraries) {
        var set = idToSetMap.remove(id);
        uriToSetMap.remove(set?.uri);
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    handler = new CompletionDomainHandler(server);
    _setCompletionSubscriptions([CompletionService.AVAILABLE_SUGGESTION_SETS]);
  }

  test_dart_existingImport() async {
    addTestFile(r'''
import 'dart:math';

main() {}
''');

    var mathSet = await _waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(id: mathSet.id, label: 'sin');

    expect(result.completion, 'sin');
    _assertEmptyChange(result.change);
  }

  test_dart_existingImport_prefixed() async {
    addTestFile(r'''
import 'dart:math' as math;

main() {}
''');

    var mathSet = await _waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(id: mathSet.id, label: 'sin');

    expect(result.completion, 'math.sin');
    _assertEmptyChange(result.change);
  }

  test_dart_newImport() async {
    addTestFile(r'''
main() {}
''');

    var mathSet = await _waitForSetWithUri('dart:math');
    var result = await _getSuggestionDetails(id: mathSet.id, label: 'sin');

    expect(result.completion, 'sin');
    _assertTestFileChange(result.change, r'''
import 'dart:math';

main() {}
''');
  }

  void _assertEmptyChange(SourceChange change) {
    expect(change.edits, isEmpty);
  }

  void _assertTestFileChange(SourceChange change, String expected) {
    var fileEdits = change.edits;
    expect(fileEdits, hasLength(1));

    var fileEdit = fileEdits[0];
    expect(fileEdit.file, testFile);

    var edits = fileEdit.edits;
    expect(SourceEdit.applySequence(testCode, edits), expected);
  }

  Future<CompletionGetSuggestionDetailsResult> _getSuggestionDetails({
    String file,
    @required int id,
    @required String label,
  }) async {
    file ??= testFile;
    var response = await waitResponse(
      CompletionGetSuggestionDetailsParams(label, testFile, id).toRequest('0'),
    );
    return CompletionGetSuggestionDetailsResult.fromResponse(response);
  }

  void _setCompletionSubscriptions(List<CompletionService> subscriptions) {
    handleSuccessfulRequest(
      CompletionSetSubscriptionsParams(subscriptions).toRequest('0'),
    );
  }

  Future<AvailableSuggestionSet> _waitForSetWithUri(String uri) async {
    AvailableSuggestionSet result;
    await Future.doWhile(() async {
      result = uriToSetMap[uri];
      return result == null;
    });
    return result;
  }
}
