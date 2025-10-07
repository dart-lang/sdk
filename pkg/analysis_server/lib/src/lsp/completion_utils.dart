// Copyright (c) 2024, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/plugin/protocol/protocol_dart.dart';
import 'package:analysis_server/src/collections.dart';
import 'package:analysis_server/src/computer/computer_documentation.dart';
import 'package:analysis_server/src/lsp/client_capabilities.dart';
import 'package:analysis_server/src/lsp/dartdoc.dart';
import 'package:analysis_server/src/lsp/mapping.dart';
import 'package:analysis_server/src/protocol_server.dart' as server;
import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analysis_server/src/utilities/extensions/string.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/line_info.dart' as server;
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer_plugin/src/utilities/client_uri_converter.dart';
import 'package:analyzer_plugin/src/utilities/documentation.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:collection/collection.dart';
import 'package:path/path.dart' as path;

/// Computes completion string, text to display and imports, if any for
/// an [OverrideSuggestion].
Future<TypeImportData?> createOverrideSuggestionData(
  OverrideSuggestion suggestion,
  DartCompletionRequest request,
) async {
  var displayTextBuffer = StringBuffer();
  var overrideImports = <Uri>{};
  var builder = ChangeBuilder(session: request.analysisSession);
  await builder.addDartFileEdit(request.path, createEditsForImports: false, (
    builder,
  ) {
    builder.addReplacement(suggestion.replacementRange, (builder) {
      builder.writeOverride(
        suggestion.element,
        displayTextBuffer: displayTextBuffer,
        invokeSuper: suggestion.shouldInvokeSuper,
      );
    });
    overrideImports.addAll(builder.requiredImports);
  });

  var fileEdits = builder.sourceChange.edits;
  if (fileEdits.length != 1) {
    return null;
  }

  var sourceEdits = fileEdits[0].edits;
  if (sourceEdits.length != 1) {
    return null;
  }

  var replacement = sourceEdits[0].replacement;
  var completion = replacement.trim();
  var overrideAnnotation = '@override';
  if (request.target.containingNode.hasOverride &&
      completion.startsWith(overrideAnnotation)) {
    completion = completion.substring(overrideAnnotation.length).trim();
  }
  if (suggestion.skipAt && completion.startsWith(overrideAnnotation)) {
    completion = completion.substring('@'.length);
  }
  if (completion.isEmpty) {
    return null;
  }

  var selectionRange = builder.selectionRange;
  if (selectionRange == null) {
    return null;
  }
  var offsetDelta =
      suggestion.replacementRange.offset + replacement.indexOf(completion);

  var displayText = displayTextBuffer.toString();
  if (displayText.isEmpty) {
    return null;
  }

  if (suggestion.skipAt) {
    displayText = 'override $displayText';
  }
  return TypeImportData(
    completion,
    displayText,
    overrideImports,
    selectionRange.offset - offsetDelta,
    selectionRange.length,
  );
}

/// Computes completion string, text to display and imports, if any for
/// an [TypedSuggestion].
Future<TypeImportData?> createTypedSuggestionData(
  TypedSuggestion suggestion,
  DartCompletionRequest request,
) async {
  // No keyword or type annotation means that we don't need to do anything.
  if (!suggestion.addTypeAnnotation && suggestion.keyword == null) {
    return null;
  }
  var typeImports = <Uri>{};
  var builder = ChangeBuilder(session: request.analysisSession);
  await builder.addDartFileEdit(request.path, createEditsForImports: false, (
    builder,
  ) {
    builder.addReplacement(suggestion.replacementRange, (builder) {
      if (suggestion.keyword case var keyword?) {
        builder.write(keyword.lexeme);
        builder.write(' ');
      }
      if (suggestion.addTypeAnnotation) {
        builder.writeType(suggestion.type, shouldWriteDynamic: true);
        builder.write(' ');
      }
      if (suggestion is SetStateMethodSuggestion &&
          (suggestion.addTypeAnnotation || suggestion.keyword != null)) {
        builder.write('setState');
      } else {
        builder.write(suggestion.completion);
      }
    });
    typeImports.addAll(builder.requiredImports);
  });

  var fileEdits = builder.sourceChange.edits;
  if (fileEdits.length != 1) {
    return null;
  }

  var sourceEdits = fileEdits.first.edits;
  if (sourceEdits.length != 1) {
    return null;
  }

  var replacement = sourceEdits.first.replacement;
  var completion = replacement.trim();
  if (completion.isEmpty) {
    return null;
  }

  var selectionRange = builder.selectionRange;

  int? selectionOffset;
  if (selectionRange != null) {
    var offsetDelta =
        suggestion.replacementRange.offset + replacement.indexOf(completion);
    selectionOffset = selectionRange.offset - offsetDelta;
  }

  return TypeImportData(
    completion,
    suggestion.completion,
    typeImports,
    selectionOffset,
    selectionRange?.length,
  );
}

// TODO(keertip): Move over completions for plugins and snippets to use
// this function.
lsp.CompletionItem? toLspCompletionItem(
  LspClientCapabilities capabilities,
  server.LineInfo lineInfo,
  CandidateSuggestion suggestion, {
  required ClientUriConverter uriConverter,
  required path.Context pathContext,
  required String completionFilePath,
  bool hasDefaultEditRange = false,
  bool hasDefaultTextMode = false,
  required lsp.Range replacementRange,
  required lsp.Range insertionRange,
  required DocumentationPreference includeDocumentation,
  required bool commitCharactersEnabled,
  required bool completeFunctionCalls,
  lsp.CompletionItemResolutionInfo? resolutionData,
  required DartCompletionRequest request,
}) {
  // isCallable is used to suffix the label with parens so it's clear the item
  // is callable.
  //
  // isInvocation means the location at which it's used is an invocation (and
  // therefore it is appropriate to include the parens/parameters in the
  // inserted text).
  //
  // In the case of show combinators, the parens will still be shown to indicate
  // functions but they should not be included in the completions.
  var element = suggestion is ElementBasedSuggestion
      ? (suggestion as ElementBasedSuggestion).element
      : null;
  var isCallable =
      element != null &&
      (element is ConstructorElement ||
          element is LocalFunctionElement ||
          element is TopLevelFunctionElement ||
          element is MethodElement);
  var isInvocation =
      (suggestion is ExecutableSuggestion &&
          suggestion.kind == server.CompletionSuggestionKind.INVOCATION) ||
      suggestion is ClosureSuggestion ||
      suggestion is FunctionCall;
  if (!isCallable || !isInvocation) {
    completeFunctionCalls = false;
  }

  var supportsCompletionDeprecatedFlag = capabilities.completionDeprecatedFlag;
  var supportsDeprecatedTag = capabilities.completionItemTags.contains(
    lsp.CompletionItemTag.Deprecated,
  );
  var formats = capabilities.completionDocumentationFormats;
  var supportsSnippets = capabilities.completionSnippets;
  var supportsInsertReplace = capabilities.insertReplaceCompletionRanges;
  var supportsAsIsInsertMode = capabilities.completionInsertTextModes.contains(
    lsp.InsertTextMode.asIs,
  );
  var useLabelDetails = capabilities.completionLabelDetails;

  var label = _getDisplayText(suggestion, request);

  if (label.isEmpty) {
    return null;
  }

  // Displayed labels may have additional info appended (for example '(...)' on
  // callables and ` => ` on getters) that should not be included in filterText,
  // so strip anything from the first paren/space.
  //
  // Only do this if label doesn't start with the pattern, because if it does
  // (for example for a closure `(a, b) {}`) we'll end up with an empty string
  // but we should instead use the whole label.

  // TODO(dantup): Consider including more of these raw fields in the original
  //  suggestion to avoid needing to manipulate them in this way here.
  var filterText = !label.startsWith(completionFilterTextSplitPattern)
      ? label.split(completionFilterTextSplitPattern).first.trim()
      : label;

  // If we're using label details, we also don't want the label to include any
  // additional symbols as noted above, because they will appear in the extra
  // details fields.
  if (useLabelDetails) {
    label = filterText;
  }

  // If this suggestion is an override, we always want to include "override" at
  // the start of the label even if it's not there (which may be because the
  // user has already typed it). We set this _after_ setting filterText because
  // in that case, we do not want the client to rank this item badly because
  // it starts "override" and the user is typing something different.
  if (suggestion is OverrideSuggestion && !label.startsWith('override ')) {
    label = 'override $label';
  }

  // Trim any trailing comma from the (displayed) label.
  if (label.endsWith(',')) {
    label = label.substring(0, label.length - 1);
  }

  var colorPreviewHex =
      capabilities.completionItemKinds.contains(lsp.CompletionItemKind.Color) &&
          suggestion is ElementBasedSuggestion
      ? server.getColorHexString(element)
      : null;

  var completionKind = colorPreviewHex != null
      ? lsp.CompletionItemKind.Color
      : _candidateToCompletionItemKind(
          capabilities.completionItemKinds,
          suggestion,
          label,
        );

  var labelDetails = _getCompletionDetail(
    suggestion,
    isCallable: isCallable,
    isInvocation: isInvocation,
    supportsDeprecated:
        supportsCompletionDeprecatedFlag || supportsDeprecatedTag,
  );

  // For legacy display, include short params on the end of labels as long as
  // the item doesn't have custom display text (which may already include
  // params).
  if (!useLabelDetails &&
      (suggestion is! ClosureSuggestion &&
          suggestion is! OverrideSuggestion &&
          suggestion is! SetStateMethodSuggestion)) {
    label += labelDetails.truncatedParams;
  }

  List<String>? parameterNames;

  CompletionDefaultArgumentList? defaultArgumentList;
  String? cleanedDoc;
  if (suggestion is ElementBasedSuggestion) {
    var element = (suggestion as ElementBasedSuggestion).element;

    if (element is ExecutableElement && element is! PropertyAccessorElement) {
      parameterNames = element.formalParameters.map((parameter) {
        return parameter.displayName;
      }).toList();

      var requiredParameters = element.formalParameters.where(
        (FormalParameterElement param) => param.isRequiredPositional,
      );

      var namedParameters = element.formalParameters.where(
        (FormalParameterElement param) => param.isNamed,
      );

      defaultArgumentList = computeCompletionDefaultArgumentList(
        element,
        requiredParameters,
        namedParameters,
      );
    }
    cleanedDoc = _getDocumentation(element, request, includeDocumentation);
  }

  var completion = suggestion.completion;

  var (selectionOffset, selectionLength) = switch (suggestion) {
    KeywordSuggestion(:var selectionOffset) => (selectionOffset, 0),
    SuggestionData(:var selectionOffset) => (selectionOffset, 0),
    TypedSuggestion(
      data: TypeImportData(:var selectionOffset?, :var selectionLength?),
    ) =>
      (selectionOffset, selectionLength),
    OverrideSuggestion(
      data: TypeImportData(:var selectionOffset?, :var selectionLength?),
    ) =>
      (selectionOffset, selectionLength),
    _ => (completion.length, 0),
  };

  var insertTextInfo = buildInsertText(
    supportsSnippets: supportsSnippets,
    commitCharactersEnabled: commitCharactersEnabled,
    completeFunctionCalls: completeFunctionCalls,
    requiredArgumentListString: defaultArgumentList?.text,
    requiredArgumentListTextRanges: defaultArgumentList?.ranges,
    hasOptionalParameters: parameterNames?.isNotEmpty ?? false,
    completion: completion,
    selectionOffset: selectionOffset,
    selectionLength: selectionLength,
  );
  var insertText = insertTextInfo.text;
  var insertTextFormat = insertTextInfo.format;
  var isMultilineCompletion = insertText.contains('\n');

  // To improve the display of some items (like pubspec version numbers),
  // short labels in the format `_foo_` in docComplete are "upgraded" to the
  // detail field.
  var labelMatch = cleanedDoc != null
      ? upgradableDocCompletePattern.firstMatch(cleanedDoc)
      : null;
  if (labelMatch != null) {
    cleanedDoc = null;
    labelDetails = (
      detail: labelMatch.group(1)!,
      truncatedParams: labelDetails.truncatedParams,
      truncatedSignature: labelDetails.truncatedSignature,
      autoImportUri: labelDetails.autoImportUri,
    );
  }

  // Append hex colours to the end of the docs, this will allow editors that
  // use a regex to find a color at the start/end like VS Code to show a color
  // preview.
  if (colorPreviewHex != null) {
    cleanedDoc = '${cleanedDoc ?? ''}\n\n$colorPreviewHex'.trim();
  }

  var isDeprecated =
      suggestion is ElementBasedSuggestion &&
      (suggestion as ElementBasedSuggestion).element.hasOrInheritsDeprecated;

  // Because we potentially send thousands of these items, we should minimise
  // the generated JSON as much as possible - for example using nulls in place
  // of empty lists/false where possible.
  return lsp.CompletionItem(
    label: label,
    kind: completionKind,
    tags: nullIfEmpty([
      if (supportsDeprecatedTag && isDeprecated)
        lsp.CompletionItemTag.Deprecated,
    ]),
    data: resolutionData,
    detail: labelDetails.detail.nullIfEmpty,
    labelDetails: useLabelDetails
        ? lsp.CompletionItemLabelDetails(
            detail: labelDetails.truncatedSignature.nullIfEmpty,
            description: getCompletionDisplayUriString(
              uriConverter: uriConverter,
              pathContext: pathContext,
              elementLibraryUri: labelDetails.autoImportUri,
              completionFilePath: completionFilePath,
            ),
          ).nullIfEmpty
        : null,
    documentation: cleanedDoc != null
        ? asMarkupContentOrString(formats, cleanedDoc)
        : null,
    deprecated: supportsCompletionDeprecatedFlag && isDeprecated ? true : null,
    sortText: relevanceToSortText(suggestion.relevanceScore),
    filterText: filterText.orNullIfSameAs(
      label,
    ), // filterText uses label if not set
    insertTextFormat: insertTextFormat != lsp.InsertTextFormat.PlainText
        ? insertTextFormat
        : null, // Defaults to PlainText if not supplied
    insertTextMode:
        !hasDefaultTextMode && supportsAsIsInsertMode && isMultilineCompletion
        ? lsp.InsertTextMode.asIs
        : null,
    // When using defaults for edit range, don't use textEdit.
    textEdit: hasDefaultEditRange
        ? null
        : supportsInsertReplace && insertionRange != replacementRange
        ? lsp.Either2<lsp.InsertReplaceEdit, lsp.TextEdit>.t1(
            lsp.InsertReplaceEdit(
              insert: insertionRange,
              replace: replacementRange,
              newText: insertText,
            ),
          )
        : lsp.Either2<lsp.InsertReplaceEdit, lsp.TextEdit>.t2(
            lsp.TextEdit(range: replacementRange, newText: insertText),
          ),
    // When using defaults for edit range, use textEditText.
    textEditText: hasDefaultEditRange ? insertText.orNullIfSameAs(label) : null,
  );
}

/// Returns the [lsp.CompletionItemKind] or `null` for the given
/// [CandidateSuggestion] and the set of supported [lsp.CompletionItemKind]s.
lsp.CompletionItemKind? _candidateToCompletionItemKind(
  Set<lsp.CompletionItemKind> supportedCompletionKinds,
  CandidateSuggestion suggestion,
  String label,
) {
  bool isSupported(lsp.CompletionItemKind kind) =>
      supportedCompletionKinds.contains(kind);

  if (suggestion is ElementBasedSuggestion) {
    return _elementToCompletionItemKind(
      (suggestion as ElementBasedSuggestion).element,
      supportedCompletionKinds,
    ).firstWhereOrNull(isSupported);
  }

  List<lsp.CompletionItemKind> getCompletionKind() {
    switch (suggestion) {
      case ClosureSuggestion():
        return const [lsp.CompletionItemKind.Method];
      case FunctionCall():
        return const [lsp.CompletionItemKind.Method];
      case IdentifierSuggestion():
        return const [lsp.CompletionItemKind.Variable];
      case KeywordSuggestion():
        return const [lsp.CompletionItemKind.Keyword];
      case LabelSuggestion():
        // There isn't really a good CompletionItemKind for labels so we'll
        // just use the Text option.
        return const [lsp.CompletionItemKind.Text];
      case NamedArgumentSuggestion():
        return const [lsp.CompletionItemKind.Variable];
      case NameSuggestion():
        return const [lsp.CompletionItemKind.Variable];
      case RecordFieldSuggestion():
        return const [lsp.CompletionItemKind.Variable];
      case RecordLiteralNamedFieldSuggestion():
        return const [lsp.CompletionItemKind.Variable];
      case UriSuggestion():
        if (!label.startsWith('dart:')) {
          return label.endsWith('.dart')
              ? const [
                  lsp.CompletionItemKind.File,
                  lsp.CompletionItemKind.Module,
                ]
              : const [
                  lsp.CompletionItemKind.Folder,
                  lsp.CompletionItemKind.Module,
                ];
        }
        return const [lsp.CompletionItemKind.Module];
      default:
        return const [];
    }
  }

  return getCompletionKind().firstWhereOrNull(isSupported);
}

/// Get the [lsp.CompletionItemKind] based on the [Element] for
/// an [ElementBasedSuggestion].
List<lsp.CompletionItemKind> _elementToCompletionItemKind(
  Element element,
  Set<lsp.CompletionItemKind> supportedCompletionKinds,
) {
  if (element is ClassElement) {
    return const [lsp.CompletionItemKind.Class];
  }
  if (element is ConstructorElement) {
    return const [lsp.CompletionItemKind.Constructor];
  }
  if (element is EnumElement) {
    return const [lsp.CompletionItemKind.Enum];
  }
  if (element is ExtensionElement) {
    return const [lsp.CompletionItemKind.Method];
  }
  if (element is ExtensionTypeElement) {
    return const [lsp.CompletionItemKind.Class];
  }
  if (element is FieldElement) {
    if (element.isEnumConstant) {
      return const [
        lsp.CompletionItemKind.EnumMember,
        lsp.CompletionItemKind.Enum,
      ];
    }
    return const [lsp.CompletionItemKind.Field];
  }
  if (element is LocalFunctionElement) {
    return const [lsp.CompletionItemKind.Function];
  }
  if (element is TopLevelFunctionElement) {
    return const [lsp.CompletionItemKind.Function];
  }
  if (element is LabelElement) {
    return const [lsp.CompletionItemKind.Text];
  }
  if (element is LibraryElement) {
    return const [lsp.CompletionItemKind.Module];
  }
  if (element is LocalVariableElement) {
    return const [lsp.CompletionItemKind.Variable];
  }
  if (element is MethodElement) {
    return const [lsp.CompletionItemKind.Method];
  }
  if (element is MixinElement) {
    return const [lsp.CompletionItemKind.Class];
  }
  if (element is FormalParameterElement) {
    return const [lsp.CompletionItemKind.Variable];
  }
  if (element is PrefixElement) {
    return const [lsp.CompletionItemKind.Variable];
  }
  if (element is PropertyAccessorElement) {
    return const [lsp.CompletionItemKind.Property];
  }
  if (element is TopLevelVariableElement) {
    return const [lsp.CompletionItemKind.Variable];
  }
  if (element is TypeAliasElement) {
    return const [lsp.CompletionItemKind.Class];
  }
  if (element is TypeParameterElement) {
    return const [
      lsp.CompletionItemKind.TypeParameter,
      lsp.CompletionItemKind.Variable,
    ];
  }
  var kind = element.kind;
  if (kind == ElementKind.PART) {
    return const [lsp.CompletionItemKind.File, lsp.CompletionItemKind.Module];
  }
  if (kind == ElementKind.GENERIC_FUNCTION_TYPE) {
    return const [lsp.CompletionItemKind.Class];
  }

  return const [];
}

/// Returns additional details to be shown against a completion.
CompletionDetail _getCompletionDetail(
  CandidateSuggestion suggestion, {
  required bool supportsDeprecated,
  required bool isCallable,
  required bool isInvocation,
}) {
  String? returnType;
  if (suggestion is FunctionCall) {
    returnType = 'void';
  } else if (suggestion is RecordFieldSuggestion) {
    returnType = suggestion.field.type.getDisplayString();
  }
  var element = suggestion is ElementBasedSuggestion
      ? (suggestion as ElementBasedSuggestion).element
      : null;

  // Usually getter/setters look the same in completion because they insert the
  // same text. This is not the case for overrides because they will insert
  // getter or setter stub code. To make this clear, we'll include get/set in
  // the signature.
  var isOverride = suggestion is OverrideSuggestion;
  var isGetterOverride = false, isSetterOverride = false;
  if (suggestion is OverrideSuggestion) {
    isGetterOverride = element is GetterElement;
    isSetterOverride = element is SetterElement;
  }

  if (suggestion is NamedArgumentSuggestion) {
    element = suggestion.parameter;
  }
  String? parameters;
  if (element != null) {
    parameters = getParametersString(element);
    // Prefer the element return type (because it may be more specific
    // for overrides) and fall back to the parameter type or return type from
    // the suggestion (handles records).
    String? parameterType;
    if (element is FormalParameterElement) {
      parameterType = element.type.getDisplayString();
    }
    returnType = server.getReturnTypeString(element) ?? parameterType;

    // Extract the type from setters to be shown in the place a return type
    // would usually be shown.
    if (returnType == null &&
        element.kind == ElementKind.SETTER &&
        parameters != null) {
      returnType = completionSetterTypePattern.firstMatch(parameters)?.group(1);
      parameters = null;
    }
  }

  var truncatedParameters = switch (parameters) {
    null || '' => '',
    '()' => '()',
    _ => '(…)',
  };
  var fullSignature = switch ((
    parameters,
    returnType,
    isGetterOverride,
    isSetterOverride,
  )) {
    (_, var returnType?, true, _) => '$returnType get',
    (_, var returnType?, _, true) => 'set ($returnType)',
    (null, _, _, _) => returnType ?? '',
    (var parameters?, null || '', _, _) => parameters,
    (var parameters?, var returnType?, _, _) => '$parameters → $returnType',
  };
  var truncatedSignature = switch ((
    parameters,
    returnType,
    isGetterOverride,
    isSetterOverride,
    // When not callable/invocation/override, signatures will have a leading
    // space, so that they are not formatted like calls, but the signature is
    // instead just informational.
    (isCallable && isInvocation) || isOverride,
  )) {
    // Include a leading space when no parameters so return type isn't right
    // against the completion label.
    (_, var returnType?, true, _, _) => ' $returnType get',
    (_, var returnType?, _, true, _) => ' set ($returnType)',
    (null, var returnType?, _, _, _) => ' $returnType',
    (null || '', _, _, _, _) => '',
    (_, null || '', _, _, true) => truncatedParameters,
    (_, null || '', _, _, false) => ' $truncatedParameters',
    (_, var returnType?, _, _, true) => '$truncatedParameters → $returnType',
    (_, var returnType?, _, _, false) => ' $truncatedParameters → $returnType',
  };

  // Use the full signature in the details popup.
  var detail = fullSignature;
  if (element != null &&
      element.metadata.hasDeprecated &&
      !supportsDeprecated) {
    // If the item is deprecated and we don't support the native deprecated flag
    // then include it in the details.
    detail = '$detail\n\n(Deprecated)'.trim();
  }

  var isNotImported = false;
  String libraryUri = '';
  if (suggestion is ImportableSuggestion) {
    var importData = suggestion.importData;
    if (importData != null) {
      libraryUri = importData.libraryUri.toString();
      isNotImported = importData.isNotImported;
    }
  }
  var autoImportUri = isNotImported && libraryUri.isNotEmpty
      ? Uri.parse(libraryUri)
      : null;

  return (
    detail: detail,
    truncatedParams: truncatedParameters,
    truncatedSignature: truncatedSignature,
    autoImportUri: autoImportUri,
  );
}

// Compute text to display for [suggestion].
String _getDisplayText(
  CandidateSuggestion suggestion,
  DartCompletionRequest request,
) {
  return switch (suggestion) {
    SuggestionData(:var displayText) => displayText,
    FunctionCall() => 'call()',
    OverrideSuggestion(:var data, :var completion) =>
      data?.displayText ?? completion,
    TypedSuggestion(:var data, :var completion) =>
      data?.displayText ?? completion,
    _ => suggestion.completion,
  };
}

/// If the [element] has a documentation comment, return it.
_ElementDocumentation? _getDocsFromComputer(
  Element element,
  DartCompletionRequest request,
) {
  var doc = request.documentationComputer.compute(
    element,
    includeSummary: true,
  );
  if (doc is DocumentationWithSummary) {
    return _ElementDocumentation(full: doc.full, summary: doc.summary);
  }
  if (doc is Documentation) {
    return _ElementDocumentation(full: doc.full, summary: null);
  }
  return null;
}

/// If the [element] has a documentation comment, return it.
String? _getDocumentation(
  Element element,
  DartCompletionRequest request,
  DocumentationPreference includeDocumentation,
) {
  if (includeDocumentation == DocumentationPreference.none) return null;
  var docs = _getDocsFromComputer(element, request);

  var doc = removeDartDocDelimiters(docs?.full);
  var rawDoc = includeDocumentation == DocumentationPreference.full
      ? doc
      : includeDocumentation == DocumentationPreference.summary
      ? getDartDocSummary(docs?.summary)
      : null;
  return cleanDartdoc(rawDoc);
}

/// Additional details about a completion that may be formatted differently
/// depending on the client capabilities.
typedef CompletionDetail = ({
  /// Additional details to go in the details popup.
  ///
  /// This is usually a full signature (with full parameters) and may also
  /// include whether the item is deprecated if the client did not support the
  /// native deprecated tag.
  String detail,

  /// Truncated parameters. Similar to [truncatedSignature] but does not
  /// include return types. Used in clients that cannot format signatures
  /// differently and is appended immediately after the completion label. The
  /// return type is omitted to reduce noise because this text is not subtle.
  String truncatedParams,

  /// A signature with truncated params. Used for showing immediately after
  /// the completion label when it can be formatted differently.
  ///
  /// () → String
  String truncatedSignature,

  /// The URI that will be auto-imported if this item is selected in a
  /// user-friendly string format (for example a relative path if for a `file:/`
  /// URI).
  Uri? autoImportUri,
});

class _ElementDocumentation {
  final String full;
  final String? summary;

  _ElementDocumentation({required this.full, required this.summary});
}
