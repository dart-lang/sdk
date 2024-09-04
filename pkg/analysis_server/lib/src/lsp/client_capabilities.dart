// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';

/// The key in the client capabilities experimental object that enables the Dart
/// TextDocumentContentProvider.
///
/// The presence of this key indicates that the client supports our
/// (non-standard) way of using TextDocumentContentProvider. This will need to
/// continue to be supported after switching to standard LSP support for some
/// period to support outdated extensions.
const dartExperimentalTextDocumentContentProviderKey =
    'supportsDartTextDocumentContentProvider';

/// The original key used for [dartExperimentalTextDocumentContentProviderKey].
///
/// This is temporarily supported to avoid the macro support vanishing for users
/// for a period if their SDK is updated before Dart-Code passes the standard
/// flag.
///
const dartExperimentalTextDocumentContentProviderLegacyKey =
    // TODO(dantup): Remove this after the next beta branch.
    'supportsDartTextDocumentContentProviderEXP1';

/// A fixed set of ClientCapabilities used for clients that may execute LSP
/// requests without performing standard LSP initialization (such as a DTD
/// client or LSP-over-Legacy).
///
/// These capabilities may affect the behaviour and format of responses so
/// should be as stable as possible to avoid affecting existing callers.
final fixedBasicLspClientCapabilities = LspClientCapabilities(
  ClientCapabilities(
    textDocument: TextDocumentClientCapabilities(
      hover: HoverClientCapabilities(
        contentFormat: [
          MarkupKind.Markdown,
        ],
      ),
    ),
    workspace: WorkspaceClientCapabilities(
      workspaceEdit: WorkspaceEditClientCapabilities(
        documentChanges: true,
      ),
    ),
  ),
);

/// Wraps the client (editor) capabilities to improve performance.
///
/// Sets transferred as arrays in JSON will be converted to Sets for faster
/// lookups and default values and nulls will be handled here.
class LspClientCapabilities {
  /// If the client does not provide capabilities.completion.completionItemKind.valueSet
  /// then we must never send a kind that's not in this list.
  static final Set<CompletionItemKind> defaultSupportedCompletionKinds = {
    CompletionItemKind.Text,
    CompletionItemKind.Method,
    CompletionItemKind.Function,
    CompletionItemKind.Constructor,
    CompletionItemKind.Field,
    CompletionItemKind.Variable,
    CompletionItemKind.Class,
    CompletionItemKind.Interface,
    CompletionItemKind.Module,
    CompletionItemKind.Property,
    CompletionItemKind.Unit,
    CompletionItemKind.Value,
    CompletionItemKind.Enum,
    CompletionItemKind.Keyword,
    CompletionItemKind.Snippet,
    CompletionItemKind.Color,
    CompletionItemKind.File,
    CompletionItemKind.Reference,
  };

  /// If the client does not provide capabilities.documentSymbol.symbolKind.valueSet
  /// then we must never send a kind that's not in this list.
  static final Set<SymbolKind> defaultSupportedSymbolKinds = {
    SymbolKind.File,
    SymbolKind.Module,
    SymbolKind.Namespace,
    SymbolKind.Package,
    SymbolKind.Class,
    SymbolKind.Method,
    SymbolKind.Property,
    SymbolKind.Field,
    SymbolKind.Constructor,
    SymbolKind.Enum,
    SymbolKind.Interface,
    SymbolKind.Function,
    SymbolKind.Variable,
    SymbolKind.Constant,
    SymbolKind.Str,
    SymbolKind.Number,
    SymbolKind.Boolean,
    SymbolKind.Array,
  };

  final ClientCapabilities raw;
  final bool documentChanges;
  final bool changeAnnotations;
  final bool configuration;
  final bool createResourceOperations;
  final bool renameResourceOperations;
  final bool completionDeprecatedFlag;
  final bool applyEdit;
  final bool workDoneProgress;
  final bool completionSnippets;
  final bool renameValidation;
  final bool literalCodeActions;
  final bool insertReplaceCompletionRanges;
  final bool definitionLocationLink;
  final bool typeDefinitionLocationLink;
  final bool hierarchicalSymbols;
  final bool diagnosticCodeDescription;
  final bool lineFoldingOnly;
  final Set<CodeActionKind> codeActionKinds;
  final Set<CompletionItemTag> completionItemTags;
  final Set<DiagnosticTag> diagnosticTags;
  final Set<MarkupKind>? completionDocumentationFormats;
  final Set<MarkupKind>? signatureHelpDocumentationFormats;
  final Set<MarkupKind>? hoverContentFormats;
  final Set<SymbolKind> documentSymbolKinds;
  final Set<SymbolKind> workspaceSymbolKinds;
  final Set<CompletionItemKind> completionItemKinds;
  final Set<InsertTextMode> completionInsertTextModes;
  final bool completionLabelDetails;
  final bool completionDefaultEditRange;
  final bool completionDefaultTextMode;
  final bool experimentalSnippetTextEdit;
  final Set<String> codeActionCommandParameterSupportedKinds;
  final bool supportsShowMessageRequest;

  /// Whether the client supports the custom Dart TextDocumentContentProvider,
  /// meaning it can request file contents from the server for custom URI
  /// schemes.
  final bool supportsDartExperimentalTextDocumentContentProvider;

  /// A set of commands that exist on the client that the server may call.
  final Set<String> supportedCommands;

  /// User-friendly error messages from parsing the experimental capabilities.
  final List<String> experimentalCapabilitiesErrors;

  factory LspClientCapabilities(ClientCapabilities raw) {
    var workspace = raw.workspace;
    var workspaceEdit = workspace?.workspaceEdit;
    var resourceOperations = workspaceEdit?.resourceOperations;
    var textDocument = raw.textDocument;
    var completion = textDocument?.completion;
    var completionItem = completion?.completionItem;
    var completionList = completion?.completionList;
    var completionDefaults = _listToSet(completionList?.itemDefaults);
    var codeAction = textDocument?.codeAction;
    var codeActionLiteral = codeAction?.codeActionLiteralSupport;
    var documentSymbol = textDocument?.documentSymbol;
    var publishDiagnostics = textDocument?.publishDiagnostics;
    var signatureHelp = textDocument?.signatureHelp;
    var signatureInformation = signatureHelp?.signatureInformation;
    var hover = textDocument?.hover;
    var definition = textDocument?.definition;
    var typeDefinition = textDocument?.typeDefinition;
    var workspaceSymbol = workspace?.symbol;

    var applyEdit = workspace?.applyEdit ?? false;
    var codeActionKinds =
        _listToSet(codeActionLiteral?.codeActionKind.valueSet);
    var completionDeprecatedFlag = completionItem?.deprecatedSupport ?? false;
    var completionDocumentationFormats =
        _listToNullableSet(completionItem?.documentationFormat);
    var completionInsertTextModes =
        _listToSet(completionItem?.insertTextModeSupport?.valueSet);
    var completionItemKinds = _listToSet(
        completion?.completionItemKind?.valueSet,
        defaults: defaultSupportedCompletionKinds);
    var completionLabelDetails = completionItem?.labelDetailsSupport ?? false;
    var completionSnippets = completionItem?.snippetSupport ?? false;
    var completionDefaultEditRange = completionDefaults.contains('editRange');
    var completionDefaultTextMode =
        completionDefaults.contains('insertTextMode');
    var configuration = workspace?.configuration ?? false;
    var createResourceOperations =
        resourceOperations?.contains(ResourceOperationKind.Create) ?? false;
    var renameResourceOperations =
        resourceOperations?.contains(ResourceOperationKind.Rename) ?? false;
    var definitionLocationLink = definition?.linkSupport ?? false;
    var typeDefinitionLocationLink = typeDefinition?.linkSupport ?? false;
    var completionItemTags = _listToSet(completionItem?.tagSupport?.valueSet);
    var diagnosticTags = _listToSet(publishDiagnostics?.tagSupport?.valueSet);
    var documentChanges = workspaceEdit?.documentChanges ?? false;
    var changeAnnotations = workspaceEdit?.changeAnnotationSupport != null;
    var documentSymbolKinds = _listToSet(documentSymbol?.symbolKind?.valueSet,
        defaults: defaultSupportedSymbolKinds);
    var hierarchicalSymbols =
        documentSymbol?.hierarchicalDocumentSymbolSupport ?? false;
    var diagnosticCodeDescription =
        publishDiagnostics?.codeDescriptionSupport ?? false;
    var hoverContentFormats = _listToNullableSet(hover?.contentFormat);
    var insertReplaceCompletionRanges =
        completionItem?.insertReplaceSupport ?? false;
    var lineFoldingOnly = textDocument?.foldingRange?.lineFoldingOnly ?? false;
    var literalCodeActions = codeActionLiteral != null;
    var renameValidation = textDocument?.rename?.prepareSupport ?? false;
    var signatureHelpDocumentationFormats =
        _listToNullableSet(signatureInformation?.documentationFormat);
    var workDoneProgress = raw.window?.workDoneProgress ?? false;
    var workspaceSymbolKinds = _listToSet(workspaceSymbol?.symbolKind?.valueSet,
        defaults: defaultSupportedSymbolKinds);

    var experimental = _ExperimentalClientCapabilities.parse(raw.experimental);

    return LspClientCapabilities._(
      raw,
      documentChanges: documentChanges,
      changeAnnotations: changeAnnotations,
      configuration: configuration,
      createResourceOperations: createResourceOperations,
      renameResourceOperations: renameResourceOperations,
      completionDeprecatedFlag: completionDeprecatedFlag,
      applyEdit: applyEdit,
      workDoneProgress: workDoneProgress,
      completionSnippets: completionSnippets,
      renameValidation: renameValidation,
      literalCodeActions: literalCodeActions,
      insertReplaceCompletionRanges: insertReplaceCompletionRanges,
      definitionLocationLink: definitionLocationLink,
      typeDefinitionLocationLink: typeDefinitionLocationLink,
      hierarchicalSymbols: hierarchicalSymbols,
      lineFoldingOnly: lineFoldingOnly,
      diagnosticCodeDescription: diagnosticCodeDescription,
      codeActionKinds: codeActionKinds,
      completionItemTags: completionItemTags,
      diagnosticTags: diagnosticTags,
      completionDocumentationFormats: completionDocumentationFormats,
      signatureHelpDocumentationFormats: signatureHelpDocumentationFormats,
      hoverContentFormats: hoverContentFormats,
      documentSymbolKinds: documentSymbolKinds,
      workspaceSymbolKinds: workspaceSymbolKinds,
      completionItemKinds: completionItemKinds,
      completionInsertTextModes: completionInsertTextModes,
      completionLabelDetails: completionLabelDetails,
      completionDefaultEditRange: completionDefaultEditRange,
      completionDefaultTextMode: completionDefaultTextMode,
      experimentalSnippetTextEdit: experimental.snippetTextEdit,
      codeActionCommandParameterSupportedKinds:
          experimental.commandParameterKinds,
      supportsShowMessageRequest: experimental.showMessageRequest,
      supportsDartExperimentalTextDocumentContentProvider:
          experimental.dartTextDocumentContentProvider,
      supportedCommands: experimental.commands,
      experimentalCapabilitiesErrors: experimental.errors,
    );
  }

  LspClientCapabilities._(
    this.raw, {
    required this.documentChanges,
    required this.changeAnnotations,
    required this.configuration,
    required this.createResourceOperations,
    required this.renameResourceOperations,
    required this.completionDeprecatedFlag,
    required this.applyEdit,
    required this.workDoneProgress,
    required this.completionSnippets,
    required this.renameValidation,
    required this.literalCodeActions,
    required this.insertReplaceCompletionRanges,
    required this.definitionLocationLink,
    required this.typeDefinitionLocationLink,
    required this.hierarchicalSymbols,
    required this.lineFoldingOnly,
    required this.diagnosticCodeDescription,
    required this.codeActionKinds,
    required this.completionItemTags,
    required this.diagnosticTags,
    required this.completionDocumentationFormats,
    required this.signatureHelpDocumentationFormats,
    required this.hoverContentFormats,
    required this.documentSymbolKinds,
    required this.workspaceSymbolKinds,
    required this.completionItemKinds,
    required this.completionInsertTextModes,
    required this.completionLabelDetails,
    required this.completionDefaultEditRange,
    required this.completionDefaultTextMode,
    required this.experimentalSnippetTextEdit,
    required this.codeActionCommandParameterSupportedKinds,
    required this.supportsShowMessageRequest,
    required this.supportsDartExperimentalTextDocumentContentProvider,
    required this.supportedCommands,
    required this.experimentalCapabilitiesErrors,
  });

  /// Converts a list to a `Set`, returning null if the list is null.
  static Set<T>? _listToNullableSet<T>(List<T>? items) {
    return items != null ? {...items} : null;
  }

  /// Converts a list to a `Set`, returning [defaults] if the list is null.
  ///
  /// If [defaults] is not supplied, will return an empty set.
  static Set<T> _listToSet<T>(List<T>? items, {Set<T> defaults = const {}}) {
    return items != null ? {...items} : defaults;
  }
}

/// A helper for parsing experimental capabilities and collecting any errors
/// because their values do not match the types expected by the server.
class _ExperimentalClientCapabilities {
  /// User-friendly error messages from parsing the experimental capabilities.
  final List<String> errors;

  final bool snippetTextEdit;
  final Set<String> commandParameterKinds;
  final bool dartTextDocumentContentProvider;
  final Set<String> commands;
  final bool showMessageRequest;

  _ExperimentalClientCapabilities({
    required this.snippetTextEdit,
    required this.commandParameterKinds,
    required this.dartTextDocumentContentProvider,
    required this.commands,
    required this.showMessageRequest,
    required this.errors,
  });

  /// Parse the experimental capabilities.
  ///
  /// Unlike the capabilities above the spec doesn't define any types for
  /// these, so we may see types we don't expect (whereas the above would have
  /// failed to deserialize if the types are invalid). So, check the types
  /// carefully and report a warning to the client if something looks wrong.
  ///
  /// Example: https://github.com/dart-lang/sdk/issues/55935
  factory _ExperimentalClientCapabilities.parse(Object? raw) {
    var errors = <String>[];

    /// Helper to ensure [object] is type [T] and otherwise records an error in
    /// [errors] and returns `null`.
    T? expectType<T>(String suffix, Object? object, [String? typeDescription]) {
      if (object is! T) {
        errors.add(
            'ClientCapabilities.experimental$suffix must be a ${typeDescription ?? T}');
        return null;
      }
      return object;
    }

    var expectMap = expectType<Map<String, Object?>?>;
    var expectBool = expectType<bool?>;
    var expectString = expectType<String>;

    /// Helper to expect a nullable list of strings and return them as a set.
    Set<String>? expectNullableStringSet(String name, Object? object) {
      return expectType<List<Object?>?>(name, object, 'List<String>?')
          ?.map((item) => expectString('$name[]', item))
          .nonNulls
          .toSet();
    }

    var experimental = expectMap('', raw) ?? const {};

    // Snippets.
    var snippetTextEdit = expectBool(
      '.snippetTextEdit',
      experimental['snippetTextEdit'],
    );

    // Refactor command parameters.
    var experimentalActions = expectMap(
      '.dartCodeAction',
      experimental['dartCodeAction'],
    );
    experimentalActions ??= const {};
    var commandParameters = expectMap(
      '.dartCodeAction.commandParameterSupport',
      experimentalActions['commandParameterSupport'],
    );
    commandParameters ??= {};
    var commandParameterKinds = expectNullableStringSet(
      '.dartCodeAction.commandParameterSupport.supportedKinds',
      commandParameters['supportedKinds'],
    );

    // Macro/Augmentation content.
    var dartContentValue =
        experimental[dartExperimentalTextDocumentContentProviderKey] ??
            experimental[dartExperimentalTextDocumentContentProviderLegacyKey];
    var dartTextDocumentContentProvider = expectBool(
      '.$dartExperimentalTextDocumentContentProviderKey',
      dartContentValue,
    );

    // Executable commands.
    var commands =
        expectNullableStringSet('.commands', experimental['commands']);

    /// At the time of writing (2023-02-01) there is no official capability for
    /// supporting 'showMessageRequest' because LSP assumed all clients
    /// supported it.
    ///
    /// This turned out to not be the case, so to avoid sending prompts that
    /// might not be seen, we will only use this functionality if we _know_ the
    /// client supports it via a custom flag in 'experimental' that is passed by
    /// the Dart-Code VS Code extension since version v3.58.0 (2023-01-25).
    var showMessageRequest = expectBool(
      '.supportsWindowShowMessageRequest',
      experimental['supportsWindowShowMessageRequest'],
    );

    return _ExperimentalClientCapabilities(
      snippetTextEdit: snippetTextEdit ?? false,
      commandParameterKinds: commandParameterKinds ?? {},
      dartTextDocumentContentProvider: dartTextDocumentContentProvider ?? false,
      commands: commands ?? {},
      showMessageRequest: showMessageRequest ?? false,
      errors: errors,
    );
  }
}
