// Copyright (c) 2021, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol_generated.dart';

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
  final bool hierarchicalSymbols;
  final bool diagnosticCodeDescription;
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
  final bool experimentalSnippetTextEdit;

  LspClientCapabilities(this.raw)
      : applyEdit = raw.workspace?.applyEdit ?? false,
        codeActionKinds = _listToSet(raw.textDocument?.codeAction
            ?.codeActionLiteralSupport?.codeActionKind.valueSet),
        completionDeprecatedFlag =
            raw.textDocument?.completion?.completionItem?.deprecatedSupport ??
                false,
        completionDocumentationFormats = _completionDocumentationFormats(raw),
        completionInsertTextModes = _listToSet(raw.textDocument?.completion
            ?.completionItem?.insertTextModeSupport?.valueSet),
        completionItemKinds = _listToSet(
            raw.textDocument?.completion?.completionItemKind?.valueSet,
            defaults: defaultSupportedCompletionKinds),
        completionSnippets =
            raw.textDocument?.completion?.completionItem?.snippetSupport ??
                false,
        configuration = raw.workspace?.configuration ?? false,
        createResourceOperations = raw
                .workspace?.workspaceEdit?.resourceOperations
                ?.contains(ResourceOperationKind.Create) ??
            false,
        renameResourceOperations = raw
                .workspace?.workspaceEdit?.resourceOperations
                ?.contains(ResourceOperationKind.Rename) ??
            false,
        definitionLocationLink =
            raw.textDocument?.definition?.linkSupport ?? false,
        completionItemTags = _listToSet(
            raw.textDocument?.completion?.completionItem?.tagSupport?.valueSet),
        diagnosticTags = _listToSet(
            raw.textDocument?.publishDiagnostics?.tagSupport?.valueSet),
        documentChanges =
            raw.workspace?.workspaceEdit?.documentChanges ?? false,
        documentSymbolKinds = _listToSet(
            raw.textDocument?.documentSymbol?.symbolKind?.valueSet,
            defaults: defaultSupportedSymbolKinds),
        hierarchicalSymbols = raw.textDocument?.documentSymbol
                ?.hierarchicalDocumentSymbolSupport ??
            false,
        diagnosticCodeDescription =
            raw.textDocument?.publishDiagnostics?.codeDescriptionSupport ??
                false,
        hoverContentFormats = _hoverContentFormats(raw),
        insertReplaceCompletionRanges = raw.textDocument?.completion
                ?.completionItem?.insertReplaceSupport ??
            false,
        literalCodeActions =
            raw.textDocument?.codeAction?.codeActionLiteralSupport != null,
        renameValidation = raw.textDocument?.rename?.prepareSupport ?? false,
        signatureHelpDocumentationFormats = _sigHelpDocumentationFormats(raw),
        workDoneProgress = raw.window?.workDoneProgress ?? false,
        workspaceSymbolKinds = _listToSet(
            raw.workspace?.symbol?.symbolKind?.valueSet,
            defaults: defaultSupportedSymbolKinds),
        experimentalSnippetTextEdit =
            raw.experimental is Map<String, Object?> &&
                (raw.experimental as Map<String, Object?>)['snippetTextEdit'] ==
                    true;

  static Set<MarkupKind>? _completionDocumentationFormats(
      ClientCapabilities raw) {
    // For formats, null is valid (which means only raw strings are supported,
    // not [MarkupContent]).
    return _listToNullableSet(
        raw.textDocument?.completion?.completionItem?.documentationFormat);
  }

  static Set<MarkupKind>? _hoverContentFormats(ClientCapabilities raw) {
    // For formats, null is valid (which means only raw strings are supported,
    // not [MarkupContent]), so use null as default.
    return _listToNullableSet(raw.textDocument?.hover?.contentFormat);
  }

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

  static Set<MarkupKind>? _sigHelpDocumentationFormats(ClientCapabilities raw) {
    // For formats, null is valid (which means only raw strings are supported,
    // not [MarkupContent]), so use null as default.
    return _listToNullableSet(raw.textDocument?.signatureHelp
        ?.signatureInformation?.documentationFormat);
  }
}
