// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:matcher/matcher.dart';
import 'package:meta/meta.dart';

import '../../analysis_server_base.dart';
import 'expect_mixin.dart';

class CompletionDriver with ExpectMixin {
  final PubPackageAnalysisServerTest server;

  Map<String, Completer<void>> receivedSuggestionsCompleters = {};
  List<CompletionSuggestion> suggestions = [];
  Map<String, List<CompletionSuggestion>> allSuggestions = {};

  final Map<String, ExistingImports> fileToExistingImports = {};

  final Map<String, List<AnalysisError>> filesErrors = {};

  late String completionId;
  late int completionOffset;
  late int replacementOffset;
  late int replacementLength;

  CompletionDriver({required this.server}) {
    server.serverChannel.notifications.listen(processNotification);
  }

  void addTestFile(String content, {int? offset}) {
    completionOffset = content.indexOf('^');
    if (offset != null) {
      expect(completionOffset, -1, reason: 'cannot supply offset and ^');
      completionOffset = offset;
      server.newFile(server.testFilePath, content);
    } else {
      expect(completionOffset, isNot(equals(-1)), reason: 'missing ^');
      var nextOffset = content.indexOf('^', completionOffset + 1);
      expect(nextOffset, equals(-1), reason: 'too many ^');
      server.newFile(
        server.testFilePath,
        content.substring(0, completionOffset) +
            content.substring(completionOffset + 1),
      );
    }
  }

  void assertValidId(String id) {
    expect(id, isNotNull);
    expect(id.isNotEmpty, isTrue);
  }

  Future<void> createProject() async {
    await server.setRoots(included: [server.workspaceRootPath], excluded: []);
  }

  Future<List<CompletionSuggestion>> getSuggestions() async {
    var request = CompletionGetSuggestions2Params(
      server.convertPath(server.testFilePath),
      completionOffset,
      1 << 16,
      timeout: 60 * 1000,
    ).toRequest('0', clientUriConverter: null);
    var response = await server.handleRequest(request);
    var result = CompletionGetSuggestions2Result.fromResponse(response,
        clientUriConverter: null);
    replacementOffset = result.replacementOffset;
    replacementLength = result.replacementLength;
    return result.suggestions;
  }

  @mustCallSuper
  Future<void> processNotification(Notification notification) async {
    if (notification.event == COMPLETION_NOTIFICATION_EXISTING_IMPORTS) {
      var params = CompletionExistingImportsParams.fromNotification(
        notification,
        clientUriConverter: null,
      );
      fileToExistingImports[params.file] = params.imports;
    } else if (notification.event == ANALYSIS_NOTIFICATION_ERRORS) {
      var decoded = AnalysisErrorsParams.fromNotification(notification,
          clientUriConverter: null);
      filesErrors[decoded.file] = decoded.errors;
    } else if (notification.event == ANALYSIS_NOTIFICATION_FLUSH_RESULTS) {
      // Ignored.
    } else if (notification.event == SERVER_NOTIFICATION_ERROR) {
      throw Exception('server error: ${notification.toJson()}');
    } else if (notification.event == SERVER_NOTIFICATION_CONNECTED) {
      // Ignored.
    } else {
      print('Unhandled notification: ${notification.event}');
    }
  }
}
