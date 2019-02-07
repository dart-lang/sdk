// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/domain_completion.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../../analysis_abstract.dart';

@reflectiveTest
class AvailableSuggestionsBase extends AbstractAnalysisTest {
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

  /// Remove the set with the given [uri].
  /// The set must be already received.
  void removeSet(String uri) {
    var set = uriToSetMap.remove(uri);
    expect(set, isNotNull);

    idToSetMap.remove(set.id);
  }

  @override
  void setUp() {
    super.setUp();
    // TODO(scheglov) restore after fixing the issue in analyzer
//    projectPath = convertPath('/home');
    projectPath = convertPath('/home/test');
    testFile = convertPath('/home/test/lib/test.dart');

    newFile('/home/test/pubspec.yaml', content: '');
    newFile('/home/test/.packages', content: '''
test:${toUri('/home/test/lib')}
''');

    createProject();
    handler = new CompletionDomainHandler(server);
    _setCompletionSubscriptions([CompletionService.AVAILABLE_SUGGESTION_SETS]);
  }

  Future<AvailableSuggestionSet> waitForSetWithUri(String uri) async {
    while (true) {
      var result = uriToSetMap[uri];
      if (result != null) {
        return result;
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  Future<void> waitForSetWithUriRemoved(String uri) async {
    while (true) {
      var result = uriToSetMap[uri];
      if (result == null) {
        return;
      }
      await Future.delayed(const Duration(milliseconds: 1));
    }
  }

  void _setCompletionSubscriptions(List<CompletionService> subscriptions) {
    handleSuccessfulRequest(
      CompletionSetSubscriptionsParams(subscriptions).toRequest('0'),
    );
  }
}
