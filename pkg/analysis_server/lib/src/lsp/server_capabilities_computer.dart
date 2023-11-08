// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';
import 'package:analysis_server/src/analysis_server.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/constants.dart';
import 'package:analysis_server/src/lsp/lsp_analysis_server.dart';
import 'package:analysis_server/src/lsp/registration/feature_registration.dart';

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
  final LspAnalysisServer _server;

  /// List of current registrations.
  Set<Registration> currentRegistrations = {};
  var _lastRegistrationId = 0;

  ServerCapabilitiesComputer(this._server);

  List<TextDocumentFilterWithScheme> get pluginTypes => AnalysisServer
          .supportsPlugins
      ? _server.pluginManager.plugins
          .expand(
            (plugin) => plugin.currentSession?.interestingFiles ?? const [],
          )
          // All published plugins use something like `*.extension` as
          // interestingFiles. Prefix a `**/` so that the glob matches nested
          // folders as well.
          .map((glob) =>
              TextDocumentFilterWithScheme(scheme: 'file', pattern: '**/$glob'))
          .toList()
      : <TextDocumentFilterWithScheme>[];

  ServerCapabilities computeServerCapabilities(
    LspClientCapabilities clientCapabilities,
  ) {
    final context = RegistrationContext(
      clientCapabilities: clientCapabilities,
      clientConfiguration: _server.lspClientConfiguration,
      pluginTypes: pluginTypes,
    );
    final features = LspFeatures(context);

    return ServerCapabilities(
      textDocumentSync: features.textDocumentSync.staticRegistration,
      callHierarchyProvider: features.callHierarchy.staticRegistration,
      completionProvider: features.completion.staticRegistration,
      hoverProvider: features.hover.staticRegistration,
      signatureHelpProvider: features.signatureHelp.staticRegistration,
      definitionProvider: features.definition.staticRegistration,
      implementationProvider: features.implementation.staticRegistration,
      referencesProvider: features.references.staticRegistration,
      documentHighlightProvider: features.documentHighlight.staticRegistration,
      documentSymbolProvider: features.documentSymbol.staticRegistration,
      codeActionProvider: features.codeActions.staticRegistration,
      colorProvider: features.colors.staticRegistration,
      documentFormattingProvider: features.format.staticRegistration,
      documentOnTypeFormattingProvider:
          features.formatOnType.staticRegistration,
      documentRangeFormattingProvider: features.formatRange.staticRegistration,
      inlayHintProvider: features.inlayHint.staticRegistration,
      renameProvider: features.rename.staticRegistration,
      foldingRangeProvider: features.foldingRange.staticRegistration,
      selectionRangeProvider: features.selectionRange.staticRegistration,
      semanticTokensProvider: features.semanticTokens.staticRegistration,
      typeDefinitionProvider: features.typeDefinition.staticRegistration,
      typeHierarchyProvider: features.typeHierarchy.staticRegistration,
      executeCommandProvider: features.executeCommand.staticRegistration,
      workspaceSymbolProvider: features.workspaceSymbol.staticRegistration,
      workspace: ServerCapabilitiesWorkspace(
        workspaceFolders: WorkspaceFoldersServerCapabilities(
          supported: true,
          changeNotifications: features.changeNotifications.staticRegistration,
        ),
        fileOperations: !context.clientDynamic.fileOperations
            ? FileOperationOptions(
                willRename: features.willRename.staticRegistration,
              )
            : null,
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
    final context = RegistrationContext(
      clientCapabilities: _server.lspClientCapabilities!,
      clientConfiguration: _server.lspClientConfiguration,
      pluginTypes: pluginTypes,
    );
    final features = LspFeatures(context);
    final registrations = <Registration>[];

    // Collect dynamic registrations for all features.
    final dynamicRegistrations = features.allFeatures
        .where((feature) => feature.supportsDynamic)
        .expand((feature) => feature.dynamicRegistrations);
    for (final (method, options) in dynamicRegistrations) {
      registrations.add(
        Registration(
          id: (_lastRegistrationId++).toString(),
          method: method.toString(),
          registerOptions: options,
        ),
      );
    }

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
