// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:path/path.dart';
import 'package:test/test.dart';

import '../../test/lsp/request_helpers_mixin.dart';
import '../../test/lsp/server_abstract.dart';
import '../support/integration_tests.dart';

abstract class AbstractLspOverLegacyTest
    extends AbstractAnalysisServerIntegrationTest
    with
        ClientCapabilitiesHelperMixin,
        LspRequestHelpersMixin,
        LspReverseRequestHelpersMixin,
        LspEditHelpersMixin,
        LspVerifyEditHelpersMixin {
  late final testFile = sourcePath('lib/main.dart');

  // TODO(dantup): Support this for LSP-over-Legacy shared tests, possibly by
  // providing an implementaion of SharedTestInterface for (both kinds of)
  // integration tests.
  var failTestOnErrorDiagnostic = false;

  /// Tracks the current overlay content so that when we apply edits they can
  /// be applied in the same way a real client would apply them.
  final _overlayContent = <String, String>{};

  /// A stream of LSP [NotificationMessage]s from the server.
  Stream<NotificationMessage> get notificationsFromServer =>
      onLspNotification.map(
        (params) => NotificationMessage.fromJson(
          params.lspNotification as Map<String, Object?>,
        ),
      );

  @override
  String get projectFolderPath => sourceDirectory.path;

  @override
  Stream<RequestMessage> get requestsFromServer => serverToClientRequests
      .where((request) => request.method == LSP_REQUEST_HANDLE)
      .map((request) {
        var params = LspHandleParams.fromRequest(
          request,
          clientUriConverter: uriConverter,
        );
        return RequestMessage.fromJson(
          params.lspMessage as Map<String, Object?>,
        );
      });

  /// The URI for the macro-generated content for [testFileUri].
  Uri get testFileMacroUri =>
      Uri.file(testFile).replace(scheme: macroClientUriScheme);

  Uri get testFileUri => Uri.file(testFile);

  void expectMarkdown(
    Either2<MarkupContent, String> contents,
    String expected,
  ) {
    var markup = contents.map(
      (t1) => t1,
      (t2) => throw 'Hover contents were String, not MarkupContent',
    );

    expect(markup.kind, MarkupKind.Markdown);
    expect(markup.value.trimRight(), expected.trimRight());
  }

  @override
  Future<T> expectSuccessfulResponseTo<T, R>(
    RequestMessage message,
    T Function(R) fromJson,
  ) async {
    var lspResponse = await sendRequestToServer(message);
    var error = lspResponse.error;
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
    var filePath = fromUri(uri);
    // First try and overlay the test has set.
    if (_overlayContent.containsKey(filePath)) {
      return _overlayContent[filePath];
    }

    // Otherwise fall back to the disk.
    try {
      return File(filePath).readAsStringSync();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<AnalysisUpdateContentResult> sendAnalysisUpdateContent(
    Map<String, Object> files,
  ) {
    for (var MapEntry(key: filePath, value: content) in files.entries) {
      switch (content) {
        case AddContentOverlay(:var content):
          _overlayContent[filePath] = content;
        case ChangeContentOverlay(:var edits):
          _overlayContent[filePath] = SourceEdit.applySequence(
            _overlayContent[filePath]!,
            edits,
          );
        case RemoveContentOverlay():
          _overlayContent.remove(filePath);
      }
    }

    return super.sendAnalysisUpdateContent(files);
  }

  @override
  Future<ResponseMessage> sendRequestToServer(RequestMessage message) async {
    var legacyResult = await sendLspHandle(message.toJson());
    var lspResponseJson = legacyResult.lspResponse as Map<String, Object?>;

    // Unwrap the LSP response.
    return ResponseMessage.fromJson(lspResponseJson);
  }

  @override
  void sendResponseToServer(ResponseMessage response) {
    server.sendRaw(
      Response(
        // Convert the LSP int-or-string ID to always a string for legacy.
        response.id!.map((i) => i.toString(), (s) => s),
        // A client-provided response to an LSP reverse-request is always
        // a full LSP result payload as the "result". The legacy request should
        // always succeed and any errors handled as LSP error responses within.
        result: LspHandleResult(
          response,
        ).toJson(clientUriConverter: uriConverter),
      ).toJson(),
    );
  }
}
