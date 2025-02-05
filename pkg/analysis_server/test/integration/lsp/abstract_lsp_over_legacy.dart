// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:test/test.dart';

import '../../lsp/request_helpers_mixin.dart';
import '../support/integration_tests.dart';

abstract class AbstractLspOverLegacyTest
    extends AbstractAnalysisServerIntegrationTest
    with LspRequestHelpersMixin, LspEditHelpersMixin {
  late final testFile = sourcePath('lib/test.dart');

  /// A stream of LSP [NotificationMessage]s from the server.
  @override
  Stream<NotificationMessage> get notificationsFromServer =>
      onLspNotification.map(
        (params) => NotificationMessage.fromJson(
          params.lspNotification as Map<String, Object?>,
        ),
      );

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
    var legacyResult = await sendLspHandle(message.toJson());
    var lspResponseJson = legacyResult.lspResponse as Map<String, Object?>;

    // Unwrap the LSP response.
    var lspResponse = ResponseMessage.fromJson(lspResponseJson);
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
}
