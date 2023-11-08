// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/protocol_server.dart';

import '../analysis_server_base.dart';
import '../lsp/request_helpers_mixin.dart';

abstract class LspOverLegacyTest extends PubPackageAnalysisServerTest
    with LspRequestHelpersMixin {
  var _requestId = 0;

  Uri get testFileUri =>
      server.resourceProvider.pathContext.toUri(convertPath(testFilePath));

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

    final legacyRequest = Request(
      '${_requestId++}',
      'lsp.handle',
      LspHandleParams(messageJson).toJson(),
    );
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
}
