// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/handlers/handler_states.dart';
import 'package:analysis_server/src/lsp/handlers/handlers.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';

class IntializedMessageHandler extends MessageHandler<InitializedParams, void> {
  final List<String> openWorkspacePaths;
  IntializedMessageHandler(
    LspAnalysisServer server,
    this.openWorkspacePaths,
  ) : super(server);
  @override
  Method get handlesMessage => Method.initialized;

  @override
  LspJsonHandler<InitializedParams> get jsonHandler =>
      InitializedParams.jsonHandler;

  @override
  ErrorOr<void> handle(InitializedParams params, CancellationToken token) {
    server.messageHandler = InitializedStateMessageHandler(
      server,
    );

    _performDynamicRegistration();

    if (!server.initializationOptions.onlyAnalyzeProjectsWithOpenFiles) {
      server.setAnalysisRoots(openWorkspacePaths);
    }

    return success();
  }

  /// If the client supports dynamic registrations we can tell it what methods
  /// we support for which documents. For example, this allows us to ask for
  /// file edits for .dart as well as pubspec.yaml but only get hover/completion
  /// calls for .dart. This functionality may not be supported by the client, in
  /// which case they will use the ServerCapabilities to know which methods we
  /// support and it will be up to them to decide which file types they will
  /// send requests for.
  Future<void> _performDynamicRegistration() async {
    final dartFiles = DocumentFilter('dart', 'file', null);
    final pubspecFile = DocumentFilter('yaml', 'file', '**/pubspec.yaml');
    final analysisOptionsFile =
        DocumentFilter('yaml', 'file', '**/analysis_options.yaml');
    final allTypes = [dartFiles, pubspecFile, analysisOptionsFile];

    // TODO(dantup): When we support plugins, we will need to collect their
    // requirements too. For example, the Angular plugin might wish to add HTML
    // `DocumentFilter('html', 'file', null)` to many of these requests.

    var _lastRegistrationId = 1;
    final registrations = <Registration>[];

    /// Helper for creating registrations with IDs.
    void register(bool condition, Method method, [ToJsonable options]) {
      if (condition == true) {
        registrations.add(Registration(
            (_lastRegistrationId++).toString(), method.toJson(), options));
      }
    }

    final textCapabilities = server.clientCapabilities?.textDocument;

    register(
      textCapabilities?.synchronization?.dynamicRegistration,
      Method.textDocument_didOpen,
      TextDocumentRegistrationOptions(allTypes),
    );
    register(
      textCapabilities?.synchronization?.dynamicRegistration,
      Method.textDocument_didClose,
      TextDocumentRegistrationOptions(allTypes),
    );
    register(
      textCapabilities?.synchronization?.dynamicRegistration,
      Method.textDocument_didChange,
      TextDocumentChangeRegistrationOptions(
          TextDocumentSyncKind.Incremental, allTypes),
    );
    register(
      server.clientCapabilities?.textDocument?.completion?.dynamicRegistration,
      Method.textDocument_completion,
      CompletionRegistrationOptions(
        dartCompletionTriggerCharacters,
        null,
        true,
        [dartFiles],
      ),
    );
    register(
      textCapabilities?.hover?.dynamicRegistration,
      Method.textDocument_hover,
      TextDocumentRegistrationOptions([dartFiles]),
    );
    register(
      textCapabilities?.signatureHelp?.dynamicRegistration,
      Method.textDocument_signatureHelp,
      SignatureHelpRegistrationOptions(
          dartSignatureHelpTriggerCharacters, [dartFiles]),
    );
    register(
      server.clientCapabilities?.textDocument?.references?.dynamicRegistration,
      Method.textDocument_references,
      TextDocumentRegistrationOptions([dartFiles]),
    );
    register(
      textCapabilities?.documentHighlight?.dynamicRegistration,
      Method.textDocument_documentHighlight,
      TextDocumentRegistrationOptions([dartFiles]),
    );
    register(
      textCapabilities?.documentSymbol?.dynamicRegistration,
      Method.textDocument_documentSymbol,
      TextDocumentRegistrationOptions([dartFiles]),
    );
    register(
      server.clientCapabilities?.textDocument?.formatting?.dynamicRegistration,
      Method.textDocument_formatting,
      TextDocumentRegistrationOptions([dartFiles]),
    );
    register(
      textCapabilities?.onTypeFormatting?.dynamicRegistration,
      Method.textDocument_onTypeFormatting,
      DocumentOnTypeFormattingRegistrationOptions(
        dartTypeFormattingCharacters.first,
        dartTypeFormattingCharacters.skip(1).toList(),
        [dartFiles],
      ),
    );
    register(
      server.clientCapabilities?.textDocument?.definition?.dynamicRegistration,
      Method.textDocument_definition,
      TextDocumentRegistrationOptions([dartFiles]),
    );
    register(
      textCapabilities?.implementation?.dynamicRegistration,
      Method.textDocument_implementation,
      TextDocumentRegistrationOptions([dartFiles]),
    );
    register(
      server.clientCapabilities?.textDocument?.codeAction?.dynamicRegistration,
      Method.textDocument_codeAction,
      CodeActionRegistrationOptions(
          [dartFiles], DartCodeActionKind.serverSupportedKinds),
    );
    register(
      textCapabilities?.rename?.dynamicRegistration,
      Method.textDocument_rename,
      RenameRegistrationOptions(true, [dartFiles]),
    );
    register(
      textCapabilities?.foldingRange?.dynamicRegistration,
      Method.textDocument_foldingRange,
      TextDocumentRegistrationOptions([dartFiles]),
    );

    // Only send the registration request if we have at least one (since
    // otherwise we don't know that the client supports registerCapability).
    if (registrations.isNotEmpty) {
      final registrationResponse = await server.sendRequest(
        Method.client_registerCapability,
        RegistrationParams(registrations),
      );

      if (registrationResponse.error != null) {
        server.logErrorToClient(
          'Failed to register capabilities with client: '
          '(${registrationResponse.error.code}) '
          '${registrationResponse.error.message}',
        );
      }
    }
  }
}
