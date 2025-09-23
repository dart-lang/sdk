// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart'
    hide AnalysisOptions;
import 'package:analyzer/src/test_utilities/test_code_format.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:meta/meta.dart';
import 'package:test/test.dart';

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

  void addTestFile(String content) {
    var code = TestCode.parse(content);
    completionOffset = code.position.offset;

    server.newFile(server.testFilePath, code.code);
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
    if (response.error case var error?) {
      fail('${request.method} failed: ${error.code}: ${error.message}');
    }
    var result = CompletionGetSuggestions2Result.fromResponse(
      response,
      clientUriConverter: null,
    );
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
      var decoded = AnalysisErrorsParams.fromNotification(
        notification,
        clientUriConverter: null,
      );
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
