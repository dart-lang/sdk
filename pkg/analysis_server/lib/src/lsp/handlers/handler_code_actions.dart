// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/error_or.dart';
import 'package:analysis_server/src/lsp/handlers/code_actions/code_action_computer.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';

typedef StaticOptions = Either2<bool, CodeActionOptions>;

class CodeActionHandler
    extends
        SharedMessageHandler<CodeActionParams, TextDocumentCodeActionResult> {
  CodeActionHandler(super.server);

  @override
  Method get handlesMessage => Method.textDocument_codeAction;

  @override
  LspJsonHandler<CodeActionParams> get jsonHandler =>
      CodeActionParams.jsonHandler;

  @override
  bool get requiresTrustedCaller => false;

  @override
  Future<ErrorOr<TextDocumentCodeActionResult>> handle(
    CodeActionParams params,
    MessageInfo message,
    CancellationToken token,
  ) async {
    var performance = message.performance;
    var editorCapabilities = server.editorClientCapabilities;
    var callerCapabilities = message.clientCapabilities;
    if (editorCapabilities == null || callerCapabilities == null) {
      // This should not happen unless a client misbehaves.
      return serverNotInitializedError;
    }

    var supportsLiterals = callerCapabilities.literalCodeActions;
    var supportedKinds = supportsLiterals
        ? callerCapabilities.codeActionKinds
        : null;

    var computer = CodeActionComputer(
      server,
      params.textDocument,
      params.range,
      editorCapabilities: editorCapabilities,
      callerCapabilities: callerCapabilities,
      only: params.context.only,
      supportedKinds: supportedKinds,
      triggerKind: params.context.triggerKind,
      allowCommands: true,
      allowCodeActionLiterals: supportsLiterals,
      allowSnippets: true, // We allow snippets from code actions requests.
      performance: performance,
    );

    return await computer.compute();
  }
}

class CodeActionRegistrations extends FeatureRegistration
    with SingleDynamicRegistration, StaticRegistration<StaticOptions> {
  CodeActionRegistrations(super.info);

  bool get codeActionLiteralSupport => clientCapabilities.literalCodeActions;

  @override
  ToJsonable? get options => CodeActionRegistrationOptions(
    documentSelector: supportedTypes,
    codeActionKinds: DartCodeActionKind.serverSupportedKinds,
  );

  @override
  Method get registrationMethod => Method.textDocument_codeAction;

  @override
  StaticOptions get staticOptions =>
      // "The `CodeActionOptions` return type is only valid if the client
      // signals code action literal support via the property
      // `textDocument.codeAction.codeActionLiteralSupport`."
      codeActionLiteralSupport
      ? Either2.t2(
          CodeActionOptions(
            codeActionKinds: DartCodeActionKind.serverSupportedKinds,
          ),
        )
      : Either2.t1(true);

  /// Types of documents for which code actions are provided.
  ///
  /// Includes Dart files, plugin types, pubspec.yaml, and analysis_options.yaml.
  List<TextDocumentFilterScheme> get supportedTypes {
    return
    // Join in a Set because fullSupportedTypes includes plugin registrations
    // and might overlap.
    {
      ...fullySupportedTypes,
      // We support code actions in pubspec+analysis_options even though they're
      // not "fully supported" (most handlers do not support them).
      pubspecFile,
      analysisOptionsFile,
    }.toList();
  }

  @override
  bool get supportsDynamic => clientDynamic.codeActions;
}
