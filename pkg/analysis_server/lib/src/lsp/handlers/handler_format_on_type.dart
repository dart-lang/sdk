// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';
import 'package:analysis_server/src/lsp/source_edits.dart';

typedef StaticOptions = DocumentOnTypeFormattingOptions?;

class FormatOnTypeHandler extends SharedMessageHandler<
    DocumentOnTypeFormattingParams, List<TextEdit>?> {
  FormatOnTypeHandler(super.server);
  @override
  Method get handlesMessage => Method.textDocument_onTypeFormatting;

  @override
  LspJsonHandler<DocumentOnTypeFormattingParams> get jsonHandler =>
      DocumentOnTypeFormattingParams.jsonHandler;

  Future<ErrorOr<List<TextEdit>?>> formatFile(String path) async {
    final file = server.resourceProvider.getFile(path);
    if (!file.exists) {
      return error(
          ServerErrorCodes.InvalidFilePath, 'File does not exist', path);
    }

    final result = await server.getParsedUnit(path);
    if (result == null || result.errors.isNotEmpty) {
      return success(null);
    }

    final lineLength =
        server.lspClientConfiguration.forResource(path).lineLength;
    return generateEditsForFormatting(result, lineLength);
  }

  @override
  Future<ErrorOr<List<TextEdit>?>> handle(DocumentOnTypeFormattingParams params,
      MessageInfo message, CancellationToken token) async {
    if (!isDartDocument(params.textDocument)) {
      return success(null);
    }

    final path = pathOfDoc(params.textDocument);
    return path.mapResult((path) {
      if (!server.lspClientConfiguration.forResource(path).enableSdkFormatter) {
        // Because we now support formatting for just some WorkspaceFolders
        // we should silently do nothing for those that are disabled.
        return success(null);
      }

      return formatFile(path);
    });
  }
}

class FormatOnTypeRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  FormatOnTypeRegistrations(super.info);

  bool get enableFormatter => clientConfiguration.global.enableSdkFormatter;

  @override
  ToJsonable? get options {
    return DocumentOnTypeFormattingRegistrationOptions(
      documentSelector: [dartFiles], // This is currently Dart-specific
      firstTriggerCharacter: dartTypeFormattingCharacters.first,
      moreTriggerCharacter: dartTypeFormattingCharacters.skip(1).toList(),
    );
  }

  @override
  Method get registrationMethod => Method.textDocument_onTypeFormatting;

  @override
  StaticOptions get staticOptions => enableFormatter
      ? DocumentOnTypeFormattingOptions(
          firstTriggerCharacter: dartTypeFormattingCharacters.first,
          moreTriggerCharacter: dartTypeFormattingCharacters.skip(1).toList())
      : null;

  @override
  bool get supportsDynamic => enableFormatter && clientDynamic.typeFormatting;

  @override
  bool get supportsStatic => enableFormatter;
}
