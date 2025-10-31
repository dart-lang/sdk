// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';

typedef StaticOptions = Either2<bool, DocumentFormattingOptions>;

class FormattingHandler
    extends SharedMessageHandler<DocumentFormattingParams, List<TextEdit>?> {
  FormattingHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_formatting;

  @override
  LspJsonHandler<DocumentFormattingParams> get jsonHandler =>
      DocumentFormattingParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  Future<ErrorOr<List<TextEdit>?>> formatFile(String path) async {
    var file = server.resourceProvider.getFile(path);
    if (!file.exists) {
      return error(
        ServerErrorCodes.invalidFilePath,
        'File does not exist',
        path,
      );
    }

    var result = await server.getParsedUnit(path);
    if (result == null || result.diagnostics.isNotEmpty) {
      return success(null);
    }

    var lineLength = server.lspClientConfiguration.forResource(path).lineLength;
    return generateEditsForFormatting(result, defaultPageWidth: lineLength);
  }

  @override
  Future<ErrorOr<List<TextEdit>?>> handle(
    DocumentFormattingParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    var path = pathOfDoc(params.textDocument);
    return path.mapResult((path) async {
      if (!server.lspClientConfiguration.forResource(path).enableSdkFormatter) {
        // Because we now support formatting for just some WorkspaceFolders
        // we should silently do nothing for those that are disabled.
        return success(null);
      }
      return await formatFile(path);
    });
  }
}

class FormattingRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  FormattingRegistrations(super.info);

  bool get enableFormatter => clientConfiguration.global.enableSdkFormatter;

  @override
  ToJsonable? get options =>
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes);

  @override
  Method get registrationMethod => Method.textDocument_formatting;

  @override
  StaticOptions get staticOptions => Either2.t1(true);

  @override
  bool get supportsDynamic => enableFormatter && clientDynamic.formatting;

  @override
  bool get supportsStatic => enableFormatter;
}
