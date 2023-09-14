// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart';

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

  factory LspClientCapabilities(ClientCapabilities raw) {
    final workspace = raw.workspace;
    final workspaceEdit = workspace?.workspaceEdit;
    final resourceOperations = workspaceEdit?.resourceOperations;
    final textDocument = raw.textDocument;
    final completion = textDocument?.completion;
    final completionItem = completion?.completionItem;
    final completionList = completion?.completionList;
    final completionDefaults = _listToSet(completionList?.itemDefaults);
    final codeAction = textDocument?.codeAction;
    final codeActionLiteral = codeAction?.codeActionLiteralSupport;
    final documentSymbol = textDocument?.documentSymbol;
    final publishDiagnostics = textDocument?.publishDiagnostics;
    final signatureHelp = textDocument?.signatureHelp;
    final signatureInformation = signatureHelp?.signatureInformation;
    final hover = textDocument?.hover;
    final definition = textDocument?.definition;
    final typeDefinition = textDocument?.typeDefinition;
    final workspaceSymbol = workspace?.symbol;
    final experimental = _mapOrEmpty(raw.experimental);
    final experimentalActions = _mapOrEmpty(experimental['dartCodeAction']);

    final applyEdit = workspace?.applyEdit ?? false;
    final codeActionKinds =
        _listToSet(codeActionLiteral?.codeActionKind.valueSet);
    final completionDeprecatedFlag = completionItem?.deprecatedSupport ?? false;
    final completionDocumentationFormats =
        _listToNullableSet(completionItem?.documentationFormat);
    final completionInsertTextModes =
        _listToSet(completionItem?.insertTextModeSupport?.valueSet);
    final completionItemKinds = _listToSet(
        completion?.completionItemKind?.valueSet,
        defaults: defaultSupportedCompletionKinds);
    final completionLabelDetails = completionItem?.labelDetailsSupport ?? false;
    final completionSnippets = completionItem?.snippetSupport ?? false;
    final completionDefaultEditRange = completionDefaults.contains('editRange');
    final completionDefaultTextMode =
        completionDefaults.contains('insertTextMode');
    final configuration = workspace?.configuration ?? false;
    final createResourceOperations =
        resourceOperations?.contains(ResourceOperationKind.Create) ?? false;
    final renameResourceOperations =
        resourceOperations?.contains(ResourceOperationKind.Rename) ?? false;
    final definitionLocationLink = definition?.linkSupport ?? false;
    final typeDefinitionLocationLink = typeDefinition?.linkSupport ?? false;
    final completionItemTags = _listToSet(completionItem?.tagSupport?.valueSet);
    final diagnosticTags = _listToSet(publishDiagnostics?.tagSupport?.valueSet);
    final documentChanges = workspaceEdit?.documentChanges ?? false;
    final documentSymbolKinds = _listToSet(documentSymbol?.symbolKind?.valueSet,
        defaults: defaultSupportedSymbolKinds);
    final hierarchicalSymbols =
        documentSymbol?.hierarchicalDocumentSymbolSupport ?? false;
    final diagnosticCodeDescription =
        publishDiagnostics?.codeDescriptionSupport ?? false;
    final hoverContentFormats = _listToNullableSet(hover?.contentFormat);
    final insertReplaceCompletionRanges =
        completionItem?.insertReplaceSupport ?? false;
    final lineFoldingOnly =
        textDocument?.foldingRange?.lineFoldingOnly ?? false;
    final literalCodeActions = codeActionLiteral != null;
    final renameValidation = textDocument?.rename?.prepareSupport ?? false;
    final signatureHelpDocumentationFormats =
        _listToNullableSet(signatureInformation?.documentationFormat);
    final workDoneProgress = raw.window?.workDoneProgress ?? false;
    final workspaceSymbolKinds = _listToSet(
        workspaceSymbol?.symbolKind?.valueSet,
        defaults: defaultSupportedSymbolKinds);
    final experimentalSnippetTextEdit = experimental['snippetTextEdit'] == true;
    final commandParameterSupport =
        _mapOrEmpty(experimentalActions['commandParameterSupport']);
    final commandParameterSupportedKinds =
        _listToSet(commandParameterSupport['supportedKinds'] as List?)
            .cast<String>();

    /// At the time of writing (2023-02-01) there is no official capability for
    /// supporting 'showMessageRequest' because LSP assumed all clients
    /// supported it.
    ///
    /// This turned out to not be the case, so to avoid sending prompts that
    /// might not be seen, we will only use this functionality if we _know_ the
    /// client supports it via a custom flag in 'experimental' that is passed by
    /// the Dart-Code VS Code extension since version v3.58.0 (2023-01-25).
    final supportsShowMessageRequest =
        experimental['supportsWindowShowMessageRequest'] == true;

    return LspClientCapabilities._(
      raw,
      documentChanges: documentChanges,
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
      experimentalSnippetTextEdit: experimentalSnippetTextEdit,
      codeActionCommandParameterSupportedKinds: commandParameterSupportedKinds,
      supportsShowMessageRequest: supportsShowMessageRequest,
    );
  }

  LspClientCapabilities._(
    this.raw, {
    required this.documentChanges,
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

  static Map<String, Object?> _mapOrEmpty(Object? item) {
    return item is Map<String, Object?> ? item : const {};
  }
}
