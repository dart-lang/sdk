// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/protocol/protocol_internal.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import '../analysis_server_base.dart';
import '../lsp/change_verifier.dart';
import '../lsp/request_helpers_mixin.dart';

abstract class LspOverLegacyTest extends PubPackageAnalysisServerTest
    with
        LspRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin {
  /// The next ID to use for the LSP request that is wrapped inside
  /// a legacy `lsp.handle` request.
  var _nextLspRequestId = 0;

  /// The last ID that was used for a legacy request.
  late String lastSentLegacyRequestId;

  @override
  path.Context get pathContext => resourceProvider.pathContext;

  @override
  String get projectFolderPath => convertPath(testPackageRootPath);

  Uri get testFileUri => toUri(convertPath(testFilePath));

  Future<void> addOverlay(String filePath, String content) {
    return handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        convertPath(filePath): AddContentOverlay(content),
      }).toRequest('${_nextLspRequestId++}'),
    );
  }

  /// Creates a legacy request with an auto-assigned ID.
  Request createLegacyRequest(RequestParams params) {
    return params.toRequest('${_nextLspRequestId++}');
  }

  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
    RequestMessage message,
    T Function(R) fromJson,
  ) async {
    // Round-trip request via JSON because this doesn't happen automatically
    // when we're bypassing the streams (running in-process) and we want to
    // validate everything.
    final messageJson =
        jsonDecode(jsonEncode(message.toJson())) as Map<String, Object?>;

    final legacyRequest = createLegacyRequest(LspHandleParams(messageJson));
    final legacyResponse = await handleSuccessfulRequest(legacyRequest);
    final legacyResult = LspHandleResult.fromResponse(legacyResponse);

    // Round-trip response via JSON because this doesn't happen automatically
    // when we're bypassing the streams (running in-process) and we want to
    // validate everything.
    final lspResponseJson = jsonDecode(jsonEncode(legacyResult.lspResponse))
        as Map<String, Object?>;

    // Unwrap the LSP response.
    final lspResponse = ResponseMessage.fromJson(lspResponseJson);
    final error = lspResponse.error;
    if (error != null) {
      throw error;
    } else if (T == Null) {
      return lspResponse.result == null
          ? null as T
          : throw 'Expected Null response but got ${lspResponse.result}';
    } else {
      return fromJson(lspResponse.result as R);
    }
  }

  @override
  String? getCurrentFileContent(Uri uri) {
    try {
      return resourceProvider.getFile(fromUri(uri)).readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<Response> handleRequest(Request request) {
    lastSentLegacyRequestId = request.id;
    return super.handleRequest(request);
  }

  /// Gets the number of recorded responses for [method].
  int numberOfRecordedResponses(String method) {
    return server.analyticsManager
        .getRequestData(method)
        .responseTimes
        .valueCount;
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> updateOverlay(String filePath, SourceEdit edit) {
    return handleSuccessfulRequest(
      AnalysisUpdateContentParams({
        convertPath(filePath): ChangeContentOverlay([edit]),
      }).toRequest('${_nextLspRequestId++}'),
    );
  }

  void verifyEdit(WorkspaceEdit edit, String expected) {
    final verifier = LspChangeVerifier(this, edit);
    // For LSP-over-Legacy we set documentChanges in the standard client
    // capabilities and assume all new users of this will support it.
    expect(edit.documentChanges, isNotNull);
    expect(edit.changes, isNull);
    verifier.verifyFiles(expected);
  }
}
