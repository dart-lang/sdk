// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/semantic_tokens/legend.dart';

/// Helper for reading client dynamic registrations which may be omitted by the
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
    Method.textDocument_inlayHint,
    Method.textDocument_signatureHelp,
    Method.textDocument_references,
    Method.textDocument_documentHighlight,
    Method.textDocument_documentColor,
    Method.textDocument_formatting,
    Method.textDocument_onTypeFormatting,
    Method.textDocument_rangeFormatting,
    Method.textDocument_definition,
    Method.textDocument_codeAction,
    Method.textDocument_rename,
    Method.textDocument_foldingRange,
    Method.textDocument_selectionRange,
    Method.textDocument_typeDefinition,
    Method.textDocument_prepareCallHierarchy,
    Method.textDocument_prepareTypeHierarchy,
    // workspace.fileOperations covers all file operation methods but we only
    // support this one.
    Method.workspace_willRenameFiles,
    // Semantic tokens are all registered under a single "method" as the
    // actual methods are controlled by the server capabilities.
    CustomMethods.semanticTokenDynamicRegistration,
  ];
  final ClientCapabilities _capabilities;

  ClientDynamicRegistrations(this._capabilities);

  bool get callHierarchy =>
      _capabilities.textDocument?.callHierarchy?.dynamicRegistration ?? false;

  bool get codeActions =>
      _capabilities.textDocument?.codeAction?.dynamicRegistration ?? false;

  bool get colorProvider =>
      _capabilities.textDocument?.colorProvider?.dynamicRegistration ?? false;

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

  bool get inlayHints =>
      _capabilities.textDocument?.inlayHint?.dynamicRegistration ?? false;

  bool get rangeFormatting =>
      _capabilities.textDocument?.rangeFormatting?.dynamicRegistration ?? false;

  bool get references =>
      _capabilities.textDocument?.references?.dynamicRegistration ?? false;

  bool get rename =>
      _capabilities.textDocument?.rename?.dynamicRegistration ?? false;

  bool get selectionRange =>
      _capabilities.textDocument?.selectionRange?.dynamicRegistration ?? false;

  bool get semanticTokens =>
      _capabilities.textDocument?.semanticTokens?.dynamicRegistration ?? false;

  bool get signatureHelp =>
      _capabilities.textDocument?.signatureHelp?.dynamicRegistration ?? false;

  bool get textSync =>
      _capabilities.textDocument?.synchronization?.dynamicRegistration ?? false;

  bool get typeDefinition =>
      _capabilities.textDocument?.typeDefinition?.dynamicRegistration ?? false;

  bool get typeFormatting =>
      _capabilities.textDocument?.onTypeFormatting?.dynamicRegistration ??
      false;

  bool get typeHierarchy =>
      _capabilities.textDocument?.typeHierarchy?.dynamicRegistration ?? false;
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
      ),
      FileOperationFilter(
        scheme: 'file',
        pattern: FileOperationPattern(
          glob: '**/',
          matches: FileOperationPatternKind.folder,
        ),
      )
    ],
  );

  final LspAnalysisServer _server;

  /// List of current registrations.
  Set<Registration> currentRegistrations = {};
  var _lastRegistrationId = 0;

  final dartFiles =
      TextDocumentFilterWithScheme(language: 'dart', scheme: 'file');
  final pubspecFile = TextDocumentFilterWithScheme(
      language: 'yaml', scheme: 'file', pattern: '**/pubspec.yaml');
  final analysisOptionsFile = TextDocumentFilterWithScheme(
      language: 'yaml', scheme: 'file', pattern: '**/analysis_options.yaml');
  final fixDataFile = TextDocumentFilterWithScheme(
      language: 'yaml',
      scheme: 'file',
      pattern: '**/lib/{fix_data.yaml,fix_data/**.yaml}');

  ServerCapabilitiesComputer(this._server);
  ServerCapabilities computeServerCapabilities(
      LspClientCapabilities clientCapabilities) {
    final codeActionLiteralSupport = clientCapabilities.literalCodeActions;
    final renameOptionsSupport = clientCapabilities.renameValidation;
    final enableFormatter =
        _server.lspClientConfiguration.global.enableSdkFormatter;
    final previewCommitCharacters =
        _server.lspClientConfiguration.global.previewCommitCharacters;

    final dynamicRegistrations =
        ClientDynamicRegistrations(clientCapabilities.raw);

    // When adding new capabilities to the server that may apply to specific file
    // types, it's important to update
    // [InitializedMessageHandler._performDynamicRegistration()] to notify
    // supporting clients of this. This avoids clients needing to hard-code the
    // list of what files types we support (and allows them to avoid sending
    // requests where we have only partial support for some types).
    return ServerCapabilities(
      textDocumentSync: dynamicRegistrations.textSync
          ? null
          : Either2<TextDocumentSyncKind, TextDocumentSyncOptions>.t2(
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
      callHierarchyProvider: dynamicRegistrations.callHierarchy
          ? null
          : Either3<bool, CallHierarchyOptions,
              CallHierarchyRegistrationOptions>.t1(true),
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
          : codeActionLiteralSupport
              ? Either2<bool, CodeActionOptions>.t2(CodeActionOptions(
                  codeActionKinds: DartCodeActionKind.serverSupportedKinds,
                ))
              : Either2<bool, CodeActionOptions>.t1(true),
      colorProvider: dynamicRegistrations.colorProvider
          ? null
          : Either3<bool, DocumentColorOptions,
                  DocumentColorRegistrationOptions>.t3(
              DocumentColorRegistrationOptions(documentSelector: [dartFiles])),
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
      inlayHintProvider: dynamicRegistrations.inlayHints
          ? null
          : Either3<bool, InlayHintOptions, InlayHintRegistrationOptions>.t2(
              InlayHintOptions(resolveProvider: false),
            ),
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
      selectionRangeProvider: dynamicRegistrations.selectionRange
          ? null
          : Either3<bool, SelectionRangeOptions,
              SelectionRangeRegistrationOptions>.t1(true),
      semanticTokensProvider: dynamicRegistrations.semanticTokens
          ? null
          : Either2<SemanticTokensOptions,
              SemanticTokensRegistrationOptions>.t1(
              SemanticTokensOptions(
                legend: semanticTokenLegend.lspLegend,
                full: Either2<bool, SemanticTokensOptionsFull>.t2(
                  SemanticTokensOptionsFull(delta: false),
                ),
                range: Either2<bool, SemanticTokensOptionsRange>.t1(true),
              ),
            ),
      typeHierarchyProvider: dynamicRegistrations.typeHierarchy
          ? null
          : Either3<bool, TypeHierarchyOptions,
              TypeHierarchyRegistrationOptions>.t1(true),
      executeCommandProvider: ExecuteCommandOptions(
        commands: Commands.serverSupportedCommands,
        workDoneProgress: true,
      ),
      workspaceSymbolProvider: Either2<bool, WorkspaceSymbolOptions>.t1(true),
      workspace: ServerCapabilitiesWorkspace(
        workspaceFolders: WorkspaceFoldersServerCapabilities(
          supported: true,
          changeNotifications: Either2<bool, String>.t1(true),
        ),
        fileOperations: dynamicRegistrations.fileOperations
            ? null
            : FileOperationOptions(
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
    final pluginTypes = AnalysisServer.supportsPlugins
        ? _server.pluginManager.plugins
            .expand(
                (plugin) => plugin.currentSession?.interestingFiles ?? const [])
            // All published plugins use something like `*.extension` as
            // interestingFiles. Prefix a `**/` so that the glob matches nested
            // folders as well.
            .map((glob) => TextDocumentFilterWithScheme(
                scheme: 'file', pattern: '**/$glob'))
        : <TextDocumentFilterWithScheme>[];
    final pluginTypesExcludingDart =
        pluginTypes.where((filter) => filter.pattern != '**/*.dart');

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
    // wish to move them to fullySupportedTypes but add an exclusion for formatting.
    final completionSupportedTypesExcludingDart = {
      // Dart is excluded here at it's registered separately with trigger/commit
      // characters.
      ...pluginTypesExcludingDart,
      pubspecFile,
      analysisOptionsFile,
      fixDataFile,
    }.toList();

    final registrations = <Registration>[];

    final enableFormatter =
        _server.lspClientConfiguration.global.enableSdkFormatter;
    final previewCommitCharacters =
        _server.lspClientConfiguration.global.previewCommitCharacters;
    final updateImportsOnRename =
        _server.lspClientConfiguration.global.updateImportsOnRename;

    /// Helper for creating registrations with IDs.
    void register(bool condition, Method method, [ToJsonable? options]) {
      if (condition == true) {
        registrations.add(Registration(
            id: (_lastRegistrationId++).toString(),
            method: method.toString(),
            registerOptions: options));
      }
    }

    final dynamicRegistrations =
        ClientDynamicRegistrations(_server.lspClientCapabilities!.raw);

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
    // Trigger and commit characters are specific to Dart, so register them
    // separately to the others.
    register(
      dynamicRegistrations.completion,
      Method.textDocument_completion,
      CompletionRegistrationOptions(
        documentSelector: [dartFiles],
        triggerCharacters: dartCompletionTriggerCharacters,
        allCommitCharacters:
            previewCommitCharacters ? dartCompletionCommitCharacters : null,
        resolveProvider: true,
      ),
    );
    register(
      dynamicRegistrations.completion,
      Method.textDocument_completion,
      CompletionRegistrationOptions(
        documentSelector: completionSupportedTypesExcludingDart,
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
      dynamicRegistrations.colorProvider,
      // This registration covers both documentColor and colorPresentation.
      Method.textDocument_documentColor,
      DocumentColorRegistrationOptions(documentSelector: [dartFiles]),
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
      dynamicRegistrations.typeDefinition,
      Method.textDocument_typeDefinition,
      TextDocumentRegistrationOptions(
        documentSelector: [dartFiles], // This one is currently Dart-specific
      ),
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
      updateImportsOnRename && dynamicRegistrations.fileOperations,
      Method.workspace_willRenameFiles,
      fileOperationRegistrationOptions,
    );
    register(
      dynamicRegistrations.didChangeConfiguration,
      Method.workspace_didChangeConfiguration,
    );
    register(
      dynamicRegistrations.selectionRange,
      Method.textDocument_selectionRange,
      SelectionRangeRegistrationOptions(
        documentSelector: [dartFiles],
      ),
    );
    register(
      dynamicRegistrations.callHierarchy,
      Method.textDocument_prepareCallHierarchy,
      CallHierarchyRegistrationOptions(
        documentSelector: [dartFiles],
      ),
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
        range: Either2<bool, SemanticTokensOptionsRange>.t1(true),
      ),
    );
    register(
      dynamicRegistrations.typeHierarchy,
      Method.textDocument_prepareTypeHierarchy,
      TypeHierarchyRegistrationOptions(
        documentSelector: [dartFiles],
      ),
    );
    register(
      dynamicRegistrations.inlayHints,
      Method.textDocument_inlayHint,
      InlayHintRegistrationOptions(
        documentSelector: [dartFiles],
        resolveProvider: false,
      ),
    );

    await _applyRegistrations(registrations);
  }

  Future<void> _applyRegistrations(List<Registration> newRegistrations) async {
    // Compute a diff of old and new registrations to send the unregister or
    // another register request. We compare registrations by their methods and
    // the hashcode of their registration options to allow for multiple
    // registrations of a single method.

    String registrationHash(Registration registration) =>
        '${registration.method}${registration.registerOptions.hashCode}';

    final newRegistrationsMap = Map.fromEntries(
        newRegistrations.map((r) => MapEntry(r, registrationHash(r))));
    final newRegistrationsJsons = newRegistrationsMap.values.toSet();
    final currentRegistrationsMap = Map.fromEntries(
        currentRegistrations.map((r) => MapEntry(r, registrationHash(r))));
    final currentRegistrationJsons = currentRegistrationsMap.values.toSet();

    final registrationsToAdd = newRegistrationsMap.entries
        .where((entry) => !currentRegistrationJsons.contains(entry.value))
        .map((entry) => entry.key)
        .toList();

    final registrationsToRemove = currentRegistrationsMap.entries
        .where((entry) => !newRegistrationsJsons.contains(entry.value))
        .map((entry) => entry.key)
        .toList();

    // Update the current list before we start sending requests since we
    // go async.
    currentRegistrations
      ..removeAll(registrationsToRemove)
      ..addAll(registrationsToAdd);

    Future<void>? unregistrationRequest;
    if (registrationsToRemove.isNotEmpty) {
      final unregistrations = registrationsToRemove
          .map((r) => Unregistration(id: r.id, method: r.method))
          .toList();
      // It's important not to await this request here, as we must ensure
      // we cannot re-enter this method until we have sent both the unregister
      // and register requests to the client atomically.
      // https://github.com/dart-lang/sdk/issues/47851#issuecomment-988093109
      unregistrationRequest = _server.sendRequest(
          Method.client_unregisterCapability,
          UnregistrationParams(unregisterations: unregistrations));
    }

    Future<void>? registrationRequest;
    // Only send the registration request if we have at least one (since
    // otherwise we don't know that the client supports registerCapability).
    if (registrationsToAdd.isNotEmpty) {
      registrationRequest = _server
          .sendRequest(Method.client_registerCapability,
              RegistrationParams(registrations: registrationsToAdd))
          .then((registrationResponse) {
        final error = registrationResponse.error;
        if (error != null) {
          _server.logErrorToClient(
            'Failed to register capabilities with client: '
            '(${error.code}) '
            '${error.message}',
          );
        }
      });
    }

    // Only after we have sent both unregistration + registration events may
    // we await them, knowing another "thread" could not have executed this
    // method between them.
    await unregistrationRequest;
    await registrationRequest;
  }
}
