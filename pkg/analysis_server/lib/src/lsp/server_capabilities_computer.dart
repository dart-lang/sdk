// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';
import 'package:analysis_server/lsp_protocol/protocol_special.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';

/// Helper for reading client dynamic registrations which may be ommitted by the
/// client.
class ClientDynamicRegistrations {
  /// All dynamic registrations supported by the Dart LSP server.
  ///
  /// Anything listed here and supported by the client will not send a static
  /// registration but instead dynamically register (usually only for a subset of
  /// files such as for .dart/pubspec.yaml/etc).
  ///
  /// When adding new capabilities that will be registered dynamically, the
  /// test_dynamicRegistration_XXX tests in `lsp/initialization_test.dart` should
  /// also be updated to ensure no double-registrations.
  static const supported = [
    Method.textDocument_didOpen,
    Method.textDocument_didChange,
    Method.textDocument_didClose,
    Method.textDocument_completion,
    Method.textDocument_hover,
    Method.textDocument_signatureHelp,
    Method.textDocument_references,
    Method.textDocument_documentHighlight,
    Method.textDocument_formatting,
    Method.textDocument_onTypeFormatting,
    Method.textDocument_rangeFormatting,
    Method.textDocument_definition,
    Method.textDocument_codeAction,
    Method.textDocument_rename,
    Method.textDocument_foldingRange,
    // workspace.fileOperations covers all file operation methods but we only
    // support this one.
    Method.workspace_willRenameFiles,
    // Sematic tokens are all registered under a single "method" as the
    // actual methods are controlled by the server capabilities.
    CustomMethods.semanticTokenDynamicRegistration,
  ];
  final ClientCapabilities _capabilities;

  ClientDynamicRegistrations(this._capabilities);

  bool get codeActions =>
      _capabilities.textDocument?.foldingRange?.dynamicRegistration ?? false;

  bool get completion =>
      _capabilities.textDocument?.completion?.dynamicRegistration ?? false;

  bool get definition =>
      _capabilities.textDocument?.definition?.dynamicRegistration ?? false;

  bool get didChangeConfiguration =>
      _capabilities.workspace?.didChangeConfiguration?.dynamicRegistration ??
      false;

  bool get documentHighlights =>
      _capabilities.textDocument?.documentHighlight?.dynamicRegistration ??
      false;

  bool get documentSymbol =>
      _capabilities.textDocument?.documentSymbol?.dynamicRegistration ?? false;

  bool get fileOperations =>
      _capabilities.workspace?.fileOperations?.dynamicRegistration ?? false;

  bool get folding =>
      _capabilities.textDocument?.foldingRange?.dynamicRegistration ?? false;

  bool get formatting =>
      _capabilities.textDocument?.formatting?.dynamicRegistration ?? false;

  bool get hover =>
      _capabilities.textDocument?.hover?.dynamicRegistration ?? false;

  bool get implementation =>
      _capabilities.textDocument?.implementation?.dynamicRegistration ?? false;

  bool get rangeFormatting =>
      _capabilities.textDocument?.rangeFormatting?.dynamicRegistration ?? false;

  bool get references =>
      _capabilities.textDocument?.references?.dynamicRegistration ?? false;

  bool get rename =>
      _capabilities.textDocument?.rename?.dynamicRegistration ?? false;

  bool get semanticTokens =>
      _capabilities.textDocument?.semanticTokens?.dynamicRegistration ?? false;

  bool get signatureHelp =>
      _capabilities.textDocument?.signatureHelp?.dynamicRegistration ?? false;

  bool get textSync =>
      _capabilities.textDocument?.synchronization?.dynamicRegistration ?? false;

  bool get typeFormatting =>
      _capabilities.textDocument?.onTypeFormatting?.dynamicRegistration ??
      false;
}

class ServerCapabilitiesComputer {
  static final fileOperationRegistrationOptions =
      FileOperationRegistrationOptions(
    filters: [
      FileOperationFilter(
        scheme: 'file',
        pattern: FileOperationPattern(
          glob: '**/*.dart',
          matches: FileOperationPatternKind.file,
        ),
      )
    ],
  );

  final LspAnalysisServer _server;

  /// Map from method name to current registration data.
  Map<String, Registration> currentRegistrations = {};
  var _lastRegistrationId = 0;

  ServerCapabilitiesComputer(this._server);

  ServerCapabilities computeServerCapabilities(
      ClientCapabilities clientCapabilities) {
    final codeActionLiteralSupport =
        clientCapabilities.textDocument?.codeAction?.codeActionLiteralSupport;

    final renameOptionsSupport =
        clientCapabilities.textDocument?.rename?.prepareSupport ?? false;

    final enableFormatter = _server.clientConfiguration.enableSdkFormatter;
    final previewCommitCharacters =
        _server.clientConfiguration.previewCommitCharacters;

    final dynamicRegistrations = ClientDynamicRegistrations(clientCapabilities);

    // When adding new capabilities to the server that may apply to specific file
    // types, it's important to update
    // [IntializedMessageHandler._performDynamicRegistration()] to notify
    // supporting clients of this. This avoids clients needing to hard-code the
    // list of what files types we support (and allows them to avoid sending
    // requests where we have only partial support for some types).
    return ServerCapabilities(
      textDocumentSync: dynamicRegistrations.textSync
          ? null
          : Either2<TextDocumentSyncOptions, TextDocumentSyncKind>.t1(
              TextDocumentSyncOptions(
              // The open/close and sync kind flags are registered dynamically if the
              // client supports them, so these static registrations are based on whether
              // the client supports dynamic registration.
              openClose: true,
              change: TextDocumentSyncKind.Incremental,
              willSave: false,
              willSaveWaitUntil: false,
              save: null,
            )),
      completionProvider: dynamicRegistrations.completion
          ? null
          : CompletionOptions(
              triggerCharacters: dartCompletionTriggerCharacters,
              allCommitCharacters: previewCommitCharacters
                  ? dartCompletionCommitCharacters
                  : null,
              resolveProvider: true,
            ),
      hoverProvider: dynamicRegistrations.hover
          ? null
          : Either2<bool, HoverOptions>.t1(true),
      signatureHelpProvider: dynamicRegistrations.signatureHelp
          ? null
          : SignatureHelpOptions(
              triggerCharacters: dartSignatureHelpTriggerCharacters,
              retriggerCharacters: dartSignatureHelpRetriggerCharacters,
            ),
      definitionProvider: dynamicRegistrations.definition
          ? null
          : Either2<bool, DefinitionOptions>.t1(true),
      implementationProvider: dynamicRegistrations.implementation
          ? null
          : Either3<bool, ImplementationOptions,
              ImplementationRegistrationOptions>.t1(
              true,
            ),
      referencesProvider: dynamicRegistrations.references
          ? null
          : Either2<bool, ReferenceOptions>.t1(true),
      documentHighlightProvider: dynamicRegistrations.documentHighlights
          ? null
          : Either2<bool, DocumentHighlightOptions>.t1(true),
      documentSymbolProvider: dynamicRegistrations.documentSymbol
          ? null
          : Either2<bool, DocumentSymbolOptions>.t1(true),
      // "The `CodeActionOptions` return type is only valid if the client
      // signals code action literal support via the property
      // `textDocument.codeAction.codeActionLiteralSupport`."
      codeActionProvider: dynamicRegistrations.codeActions
          ? null
          : codeActionLiteralSupport != null
              ? Either2<bool, CodeActionOptions>.t2(CodeActionOptions(
                  codeActionKinds: DartCodeActionKind.serverSupportedKinds,
                ))
              : Either2<bool, CodeActionOptions>.t1(true),
      documentFormattingProvider: dynamicRegistrations.formatting
          ? null
          : Either2<bool, DocumentFormattingOptions>.t1(enableFormatter),
      documentOnTypeFormattingProvider: dynamicRegistrations.typeFormatting
          ? null
          : enableFormatter
              ? DocumentOnTypeFormattingOptions(
                  firstTriggerCharacter: dartTypeFormattingCharacters.first,
                  moreTriggerCharacter:
                      dartTypeFormattingCharacters.skip(1).toList())
              : null,
      documentRangeFormattingProvider: dynamicRegistrations.typeFormatting
          ? null
          : Either2<bool, DocumentRangeFormattingOptions>.t1(enableFormatter),
      renameProvider: dynamicRegistrations.rename
          ? null
          : renameOptionsSupport
              ? Either2<bool, RenameOptions>.t2(
                  RenameOptions(prepareProvider: true))
              : Either2<bool, RenameOptions>.t1(true),
      foldingRangeProvider: dynamicRegistrations.folding
          ? null
          : Either3<bool, FoldingRangeOptions,
              FoldingRangeRegistrationOptions>.t1(
              true,
            ),
      semanticTokensProvider: dynamicRegistrations.semanticTokens
          ? null
          : Either2<SemanticTokensOptions,
              SemanticTokensRegistrationOptions>.t1(
              SemanticTokensOptions(
                legend: semanticTokenLegend.lspLegend,
                full: Either2<bool, SemanticTokensOptionsFull>.t2(
                  SemanticTokensOptionsFull(delta: false),
                ),
              ),
            ),
      executeCommandProvider: ExecuteCommandOptions(
        commands: Commands.serverSupportedCommands,
        workDoneProgress: true,
      ),
      workspaceSymbolProvider: Either2<bool, WorkspaceSymbolOptions>.t1(true),
      workspace: ServerCapabilitiesWorkspace(
        workspaceFolders: WorkspaceFoldersServerCapabilities(
          supported: true,
          changeNotifications: Either2<String, bool>.t2(true),
        ),
        fileOperations: dynamicRegistrations.fileOperations
            ? null
            : ServerCapabilitiesFileOperations(
                willRename: fileOperationRegistrationOptions,
              ),
      ),
    );
  }

  /// If the client supports dynamic registrations we can tell it what methods
  /// we support for which documents. For example, this allows us to ask for
  /// file edits for .dart as well as pubspec.yaml but only get hover/completion
  /// calls for .dart. This functionality may not be supported by the client, in
  /// which case they will use the ServerCapabilities to know which methods we
  /// support and it will be up to them to decide which file types they will
  /// send requests for.
  Future<void> performDynamicRegistration() async {
    final dartFiles = DocumentFilter(language: 'dart', scheme: 'file');
    final pubspecFile = DocumentFilter(
        language: 'yaml', scheme: 'file', pattern: '**/pubspec.yaml');
    final analysisOptionsFile = DocumentFilter(
        language: 'yaml', scheme: 'file', pattern: '**/analysis_options.yaml');
    final fixDataFile = DocumentFilter(
        language: 'yaml', scheme: 'file', pattern: '**/lib/fix_data.yaml');

    final pluginTypes = _server.pluginManager.plugins
        .expand((plugin) => plugin.currentSession?.interestingFiles ?? const [])
        // All published plugins use something like `*.extension` as
        // interestingFiles. Prefix a `**/` so that the glob matches nested
        // folders as well.
        .map((glob) => DocumentFilter(scheme: 'file', pattern: '**/$glob'));

    final fullySupportedTypes = {dartFiles, ...pluginTypes}.toList();

    // Add pubspec + analysis options only for synchronisation. We do not support
    // things like hovers/formatting/etc. for these files so there's no point
    // in having the client send those requests (plus, for things like formatting
    // this could result in the editor reporting "multiple formatters installed"
    // and prevent a built-in YAML formatter from being selected).
    final synchronisedTypes = {
      ...fullySupportedTypes,
      pubspecFile,
      analysisOptionsFile,
      fixDataFile,
    }.toList();

    // Completion is supported for some synchronised files that we don't _fully_
    // support (eg. YAML). If these gain support for things like hover, we may
    // wish to move them to fullySupprtedTypes but add an exclusion for formatting.
    final completionSupportedTypes = {
      ...fullySupportedTypes,
      pubspecFile,
      analysisOptionsFile,
      fixDataFile,
    }.toList();

    final registrations = <Registration>[];

    final enableFormatter = _server.clientConfiguration.enableSdkFormatter;
    final previewCommitCharacters =
        _server.clientConfiguration.previewCommitCharacters;

    /// Helper for creating registrations with IDs.
    void register(bool condition, Method method, [ToJsonable options]) {
      if (condition == true) {
        registrations.add(Registration(
            id: (_lastRegistrationId++).toString(),
            method: method.toJson(),
            registerOptions: options));
      }
    }

    final dynamicRegistrations =
        ClientDynamicRegistrations(_server.clientCapabilities);

    register(
      dynamicRegistrations.textSync,
      Method.textDocument_didOpen,
      TextDocumentRegistrationOptions(documentSelector: synchronisedTypes),
    );
    register(
      dynamicRegistrations.textSync,
      Method.textDocument_didClose,
      TextDocumentRegistrationOptions(documentSelector: synchronisedTypes),
    );
    register(
      dynamicRegistrations.textSync,
      Method.textDocument_didChange,
      TextDocumentChangeRegistrationOptions(
          syncKind: TextDocumentSyncKind.Incremental,
          documentSelector: synchronisedTypes),
    );
    register(
      dynamicRegistrations.completion,
      Method.textDocument_completion,
      CompletionRegistrationOptions(
        documentSelector: completionSupportedTypes,
        triggerCharacters: dartCompletionTriggerCharacters,
        allCommitCharacters:
            previewCommitCharacters ? dartCompletionCommitCharacters : null,
        resolveProvider: true,
      ),
    );
    register(
      dynamicRegistrations.hover,
      Method.textDocument_hover,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      dynamicRegistrations.signatureHelp,
      Method.textDocument_signatureHelp,
      SignatureHelpRegistrationOptions(
        documentSelector: fullySupportedTypes,
        triggerCharacters: dartSignatureHelpTriggerCharacters,
        retriggerCharacters: dartSignatureHelpRetriggerCharacters,
      ),
    );
    register(
      dynamicRegistrations.references,
      Method.textDocument_references,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      dynamicRegistrations.documentHighlights,
      Method.textDocument_documentHighlight,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      dynamicRegistrations.documentSymbol,
      Method.textDocument_documentSymbol,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      enableFormatter && dynamicRegistrations.formatting,
      Method.textDocument_formatting,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      enableFormatter && dynamicRegistrations.typeFormatting,
      Method.textDocument_onTypeFormatting,
      DocumentOnTypeFormattingRegistrationOptions(
        documentSelector: [dartFiles], // This one is currently Dart-specific
        firstTriggerCharacter: dartTypeFormattingCharacters.first,
        moreTriggerCharacter: dartTypeFormattingCharacters.skip(1).toList(),
      ),
    );
    register(
      enableFormatter && dynamicRegistrations.rangeFormatting,
      Method.textDocument_rangeFormatting,
      DocumentRangeFormattingRegistrationOptions(
        documentSelector: [dartFiles], // This one is currently Dart-specific
      ),
    );
    register(
      dynamicRegistrations.definition,
      Method.textDocument_definition,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      dynamicRegistrations.implementation,
      Method.textDocument_implementation,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      dynamicRegistrations.codeActions,
      Method.textDocument_codeAction,
      CodeActionRegistrationOptions(
        documentSelector: fullySupportedTypes,
        codeActionKinds: DartCodeActionKind.serverSupportedKinds,
      ),
    );
    register(
      dynamicRegistrations.rename,
      Method.textDocument_rename,
      RenameRegistrationOptions(
          documentSelector: fullySupportedTypes, prepareProvider: true),
    );
    register(
      dynamicRegistrations.folding,
      Method.textDocument_foldingRange,
      TextDocumentRegistrationOptions(documentSelector: fullySupportedTypes),
    );
    register(
      dynamicRegistrations.fileOperations,
      Method.workspace_willRenameFiles,
      fileOperationRegistrationOptions,
    );
    register(
      dynamicRegistrations.didChangeConfiguration,
      Method.workspace_didChangeConfiguration,
    );
    register(
      dynamicRegistrations.semanticTokens,
      CustomMethods.semanticTokenDynamicRegistration,
      SemanticTokensRegistrationOptions(
        documentSelector: fullySupportedTypes,
        legend: semanticTokenLegend.lspLegend,
        full: Either2<bool, SemanticTokensOptionsFull>.t2(
          SemanticTokensOptionsFull(delta: false),
        ),
      ),
    );

    await _applyRegistrations(registrations);
  }

  Future<void> _applyRegistrations(List<Registration> registrations) async {
    final newRegistrationsByMethod = {
      for (final registration in registrations)
        registration.method: registration
    };

    final additionalRegistrations = List.of(registrations);
    final removedRegistrations = <Unregistration>[];

    // compute a diff of old and new registrations to send the unregister or
    // another register request. We assume that we'll only ever have one
    // registration per LSP method name.
    for (final entry in currentRegistrations.entries) {
      final method = entry.key;
      final registration = entry.value;

      final newRegistrationForMethod = newRegistrationsByMethod[method];
      final entryRemovedOrChanged = newRegistrationForMethod?.registerOptions !=
          registration.registerOptions;

      if (entryRemovedOrChanged) {
        removedRegistrations.add(
            Unregistration(id: registration.id, method: registration.method));
      } else {
        // Replace the registration in our new set with the original registration
        // so that we retain the original ID sent to the client (otherwise we
        // will try to unregister using an ID the client was never sent).
        newRegistrationsByMethod[method] = registration;
        additionalRegistrations.remove(newRegistrationForMethod);
      }
    }

    currentRegistrations = newRegistrationsByMethod;

    if (removedRegistrations.isNotEmpty) {
      await _server.sendRequest(Method.client_unregisterCapability,
          UnregistrationParams(unregisterations: removedRegistrations));
    }

    // Only send the registration request if we have at least one (since
    // otherwise we don't know that the client supports registerCapability).
    if (additionalRegistrations.isNotEmpty) {
      final registrationResponse = await _server.sendRequest(
        Method.client_registerCapability,
        RegistrationParams(registrations: additionalRegistrations),
      );

      if (registrationResponse.error != null) {
        _server.logErrorToClient(
          'Failed to register capabilities with client: '
          '(${registrationResponse.error.code}) '
          '${registrationResponse.error.message}',
        );
      }
    }
  }
}
