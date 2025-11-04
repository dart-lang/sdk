// Copyright (c) 2025, the Dart  project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/completion_utils.dart'
    show createTypedSuggestionData;
import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/completion/dart/candidate_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/completion_manager.dart';
import 'package:analysis_server/src/services/completion/dart/dart_completion_suggestion.dart';
import 'package:analysis_server/src/services/completion/dart/utilities.dart';
import 'package:analysis_server/src/utilities/extensions/ast.dart';
import 'package:analysis_server/src/utilities/extensions/element.dart';
import 'package:analyzer/dart/element/element.dart' as e;
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dartdoc/dartdoc_directive_info.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/completion/relevance.dart';

/// Converts a [CandidateSuggestion] into a [CompletionSuggestion] object.
Future<CompletionSuggestion?> candidateToCompletionSuggestion(
  CandidateSuggestion candidate,
  DartCompletionRequest request,
) async {
  bool? isNotImportedLibrary;
  var requiredImports = <Uri>[];
  String? libraryUriStr;

  if (candidate is ImportableSuggestion) {
    var importData = candidate.importData;
    if (importData != null) {
      var uri = importData.libraryUri;
      if (importData.isNotImported) {
        isNotImportedLibrary = true;
        requiredImports = [uri];
      }
      libraryUriStr = uri.toString();
    }
  }

  switch (candidate) {
    case TypedSuggestion():
      var data = await createTypedSuggestionData(candidate, request);
      requiredImports = data?.imports.toList() ?? requiredImports;
      var kind = request.target.isFunctionalArgument()
          ? CompletionSuggestionKind.IDENTIFIER
          : null;
      candidate.data = data;

      return switch (candidate) {
        FieldSuggestion() => _getDartCompletionSuggestion(
          candidate.element,
          candidate.completion,
          candidate.relevanceScore,
          CompletionSuggestionKind.IDENTIFIER,
          request,
          isNotImportedLibrary,
          libraryUriStr,
          requiredImports,
          displayString: data?.displayText,
        ),

        GetterSuggestion() => _getDartCompletionSuggestion(
          candidate.element,
          candidate.completion,
          candidate.relevanceScore,
          CompletionSuggestionKind.IDENTIFIER,
          request,
          isNotImportedLibrary,
          libraryUriStr,
          requiredImports,
          displayString: data?.displayText,
        ),

        SetStateMethodSuggestion() => DartCompletionSuggestion(
          candidate.kind,
          candidate.relevanceScore,
          candidate.completion,
          candidate.selectionOffset,
          0,
          false,
          false,
          displayText: data?.displayText ?? candidate.displayText,
        ),
        FunctionCall functionCall => _getFunctionCallSuggestion(functionCall),
        MethodSuggestion(kind: var suggestionKind) =>
          // TODO(brianwilkerson): Correctly set the kind of suggestion in cases
          //  where `isFunctionalArgument` would return `true` so we can stop
          //  using the `request.target`.
          _getDartCompletionSuggestion(
            candidate.element,
            candidate.completion,
            candidate.relevanceScore,
            kind ?? suggestionKind,
            request,
            isNotImportedLibrary,
            libraryUriStr,
            requiredImports,
            displayString: data?.displayText,
          ),
        RecordFieldSuggestion() => DartCompletionSuggestion(
          CompletionSuggestionKind.IDENTIFIER,
          candidate.relevanceScore,
          candidate.completion,
          candidate.completion.length,
          0,
          false,
          false,
          returnType: candidate.field.type.getDisplayString(),
          displayText: data?.displayText ?? candidate.name,
        ),

        // This is a workaround because mixins can't be `sealed`.
        TypedSuggestionCompletionMixin() => null,
      };

    case ClassSuggestion():
      return _getInterfaceSuggestion(
        candidate,
        candidate.element,
        request,
        libraryUriStr,
        isNotImportedLibrary,
        requiredImports,
      );
    case ClosureSuggestion():
      return DartCompletionSuggestion(
        CompletionSuggestionKind.INVOCATION,
        candidate.relevanceScore,
        candidate.completion,
        candidate.selectionOffset,
        0,
        false,
        false,
        displayText: candidate.displayText,
      );
    case ConstructorSuggestion():
      var completion = candidate.completion;
      if (completion.isEmpty) {
        return null;
      }
      return _getConstructorSuggestion(
        candidate,
        request,
        libraryUriStr,
        isNotImportedLibrary,
        requiredImports,
      );
    case EnumConstantSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case EnumSuggestion():
      return _getInterfaceSuggestion(
        candidate,
        candidate.element,
        request,
        libraryUriStr,
        isNotImportedLibrary,
        requiredImports,
      );
    case ExtensionSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        candidate.kind,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case ExtensionTypeSuggestion():
      return _getInterfaceSuggestion(
        candidate,
        candidate.element,
        request,
        libraryUriStr,
        isNotImportedLibrary,
        requiredImports,
      );
    case FormalParameterSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case IdentifierSuggestion():
      return CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER,
        candidate.relevanceScore,
        candidate.completion,
        candidate.selectionOffset,
        0,
        false,
        false,
      );
    case ImportPrefixSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );

    case KeywordSuggestion():
      return CompletionSuggestion(
        CompletionSuggestionKind.KEYWORD,
        candidate.relevanceScore,
        candidate.completion,
        candidate.selectionOffset,
        0,
        false,
        false,
      );
    case LabelSuggestion():
      var completion = candidate.label.label.name;
      var suggestion = CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER,
        candidate.relevanceScore,
        completion,
        completion.length,
        0,
        false,
        false,
      );
      suggestion.element = createLocalElement(
        request.source,
        ElementKind.LABEL,
        candidate.label.label,
      );
      return suggestion;
    case LoadLibraryFunctionSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        candidate.kind,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );

    case LocalFunctionSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        candidate.kind,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );

    case LocalVariableSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case MixinSuggestion():
      return _getInterfaceSuggestion(
        candidate,
        candidate.element,
        request,
        libraryUriStr,
        isNotImportedLibrary,
        requiredImports,
      );
    case NamedArgumentSuggestion():
      return _getNamedArgumentSuggestion(candidate, request);
    case NameSuggestion():
      var name = candidate.completion;
      return CompletionSuggestion(
        CompletionSuggestionKind.IDENTIFIER,
        candidate.relevanceScore,
        name,
        name.length,
        0,
        false,
        false,
      );
    case OverrideSuggestion():
      return await _getOverrideSuggestion(candidate, request);
    case RecordLiteralNamedFieldSuggestion():
      var field = candidate.field;
      return CompletionSuggestion(
        CompletionSuggestionKind.NAMED_ARGUMENT,
        Relevance.requiredNamedArgument,
        candidate.completion,
        candidate.selectionOffset,
        0,
        false,
        false,
        parameterName: field.name,
        parameterType: field.type.getDisplayString(),
      );
    case SetterSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case StaticFieldSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case SuperParameterSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case TopLevelFunctionSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        candidate.kind,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case TopLevelGetterSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case TopLevelSetterSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case TopLevelVariableSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case TypeAliasSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case TypeParameterSuggestion():
      return _getDartCompletionSuggestion(
        candidate.element,
        candidate.completion,
        candidate.relevanceScore,
        CompletionSuggestionKind.IDENTIFIER,
        request,
        isNotImportedLibrary,
        libraryUriStr,
        requiredImports,
      );
    case UriSuggestion():
      var uri = candidate.uriStr;
      return CompletionSuggestion(
        CompletionSuggestionKind.IMPORT,
        candidate.relevanceScore,
        uri,
        uri.length,
        0,
        false,
        false,
      );
  }
}

({
  List<String> parameterNames,
  List<String> parameterTypes,
  int requiredParameterCount,
  bool hasNamedParameters,
  CompletionDefaultArgumentList defaultArgumentList,
})
createParametersCompletionData(
  List<e.FormalParameterElement> formalParameters,
) {
  var parameterNames = formalParameters.map((parameter) {
    return parameter.displayName;
  }).toList();
  var parameterTypes = formalParameters.map((
    e.FormalParameterElement parameter,
  ) {
    return parameter.type.getDisplayString();
  }).toList();

  var requiredParameters = formalParameters.where(
    (e.FormalParameterElement param) => param.isRequiredPositional,
  );
  var requiredParameterCount = requiredParameters.length;

  var namedParameters = formalParameters.where(
    (e.FormalParameterElement param) => param.isNamed,
  );
  var hasNamedParameters = namedParameters.isNotEmpty;

  var defaultArgumentList = computeCompletionDefaultArgumentList(
    requiredParameters,
    namedParameters,
  );
  return (
    parameterNames: parameterNames,
    parameterTypes: parameterTypes,
    requiredParameterCount: requiredParameterCount,
    hasNamedParameters: hasNamedParameters,
    defaultArgumentList: defaultArgumentList,
  );
}

_ParameterData _createParameterData(e.Element element) {
  List<String>? parameterNames;
  List<String>? parameterTypes;
  int? requiredParameterCount;
  bool? hasNamedParameters;
  CompletionDefaultArgumentList? defaultArgumentList;
  if (element is e.ExecutableElement && element is! e.PropertyAccessorElement) {
    (
      :parameterNames,
      :parameterTypes,
      :requiredParameterCount,
      :hasNamedParameters,
      :defaultArgumentList,
    ) = createParametersCompletionData(
      element.formalParameters,
    );
  }
  return _ParameterData(
    parameterNames,
    parameterTypes,
    requiredParameterCount,
    hasNamedParameters,
    defaultArgumentList,
  );
}

CompletionSuggestion? _getConstructorSuggestion(
  ConstructorSuggestion candidate,
  DartCompletionRequest request,
  String? libraryUriStr,
  bool? isNotImported,
  List<Uri> requiredImports,
) {
  var hasClassName = candidate.hasClassName;
  var prefix = candidate.prefix;
  var completion = candidate.completion;
  // If the class name is already in the text, then we don't support
  // prepending a prefix.
  assert(!hasClassName || prefix == null);
  if (prefix != null) {
    completion = '$prefix.$completion';
  }

  var constructor = candidate.element;

  var suggestedElement = convertElement(constructor);
  var parameterData = _createParameterData(constructor);

  var suggestion = DartCompletionSuggestion(
    candidate.kind,
    candidate.relevanceScore,
    completion,
    completion.length /*selectionOffset*/,
    0 /*selectionLength*/,
    constructor.hasOrInheritsDeprecated,
    false /*isPotential*/,
    element: suggestedElement,
    declaringType: _getDeclaringType(constructor),
    returnType: getReturnTypeString(constructor),
    requiredParameterCount: parameterData.requiredParameterCount,
    hasNamedParameters: parameterData.hasNamedParameters,
    parameterNames: parameterData.parameterNames,
    parameterTypes: parameterData.parameterTypes,
    defaultArgumentListString: parameterData.defaultArgumentList?.text,
    defaultArgumentListTextRanges: parameterData.defaultArgumentList?.ranges,
    libraryUri: libraryUriStr,
    isNotImported: isNotImported,
    requiredImports: requiredImports,
    colorHex: getColorHexString(constructor),
  );
  _setDocumentation(suggestion, constructor, request);
  return suggestion;
}

DartCompletionSuggestion _getDartCompletionSuggestion(
  e.Element element,
  String completion,
  int relevance,
  CompletionSuggestionKind kind,
  DartCompletionRequest request,
  bool? isNotImported,
  String? libraryUriStr,
  List<Uri> requiredImports, {
  String? displayString,
}) {
  var suggestedElement = convertElement(element);
  _ParameterData? parameterData;
  if (element is e.ExecutableElement && element is! e.PropertyAccessorElement) {
    parameterData = _createParameterData(element);
  }

  var suggestion = DartCompletionSuggestion(
    kind,
    relevance,
    completion,
    completion.length /*selectionOffset*/,
    0 /*selectionLength*/,
    element.hasOrInheritsDeprecated,
    false /*isPotential*/,
    element: suggestedElement,
    declaringType: _getDeclaringType(element),
    returnType: getReturnTypeString(element),
    requiredParameterCount: parameterData?.requiredParameterCount,
    hasNamedParameters: parameterData?.hasNamedParameters,
    parameterNames: parameterData?.parameterNames,
    parameterTypes: parameterData?.parameterTypes,
    defaultArgumentListString: parameterData?.defaultArgumentList?.text,
    defaultArgumentListTextRanges: parameterData?.defaultArgumentList?.ranges,
    libraryUri: libraryUriStr,
    isNotImported: isNotImported,
    requiredImports: requiredImports,
    colorHex: getColorHexString(element),
    displayText: displayString,
  );
  _setDocumentation(suggestion, element, request);
  return suggestion;
}

String? _getDeclaringType(e.Element element) {
  String? declaringType;
  if (element is! e.FormalParameterElement) {
    var enclosingElement = element.enclosingElement;

    if (enclosingElement is e.InterfaceElement) {
      declaringType = enclosingElement.displayName;
    }
  }
  return declaringType;
}

Element _getElementForFunctionCall(
  FunctionType type,
  String parameters,
  String? typeParameters,
) {
  return Element(
    ElementKind.METHOD,
    e.MethodElement.CALL_METHOD_NAME,
    Element.makeFlags(),
    parameters: parameters,
    typeParameters: typeParameters,
    returnType: type.returnType.getDisplayString(),
  );
}

DartCompletionSuggestion _getFunctionCallSuggestion(FunctionCall functionCall) {
  var FunctionCall(:kind, :relevanceScore, :completion, :type) = functionCall;
  var record = createParametersCompletionData(type.formalParameters);
  return DartCompletionSuggestion(
    kind,
    relevanceScore,
    completion,
    completion.length,
    0,
    false,
    false,
    displayText: completion,
    element: _getElementForFunctionCall(
      type,
      '(${record.parameterNames.join(',')})',
      record.parameterTypes.joinWithCommaAndSurroundWithAngle(),
    ),
    returnType: type.returnType.getDisplayString(),
    parameterNames: record.parameterNames,
    parameterTypes: record.parameterTypes,
    requiredParameterCount: record.requiredParameterCount,
    hasNamedParameters: record.hasNamedParameters,
    defaultArgumentListString: record.defaultArgumentList.text,
  );
}

CompletionSuggestion _getInterfaceSuggestion(
  CandidateSuggestion candidate,
  e.Element interfaceElement,
  DartCompletionRequest request,
  String? libraryUriStr,
  bool? isNotImported,
  List<Uri> requiredImports,
) {
  var suggestedElement = convertElement(interfaceElement);
  var completion = candidate.completion;
  var suggestion = DartCompletionSuggestion(
    CompletionSuggestionKind.IDENTIFIER,
    candidate.relevanceScore,
    completion,
    completion.length /*selectionOffset*/,
    0 /*selectionLength*/,
    interfaceElement.hasOrInheritsDeprecated,
    false /*isPotential*/,
    element: suggestedElement,
    declaringType: _getDeclaringType(interfaceElement),
    returnType: getReturnTypeString(interfaceElement),
    libraryUri: libraryUriStr,
    isNotImported: isNotImported,
    requiredImports: requiredImports,
    colorHex: getColorHexString(interfaceElement),
  );

  _setDocumentation(suggestion, interfaceElement, request);
  return suggestion;
}

CompletionSuggestion _getNamedArgumentSuggestion(
  NamedArgumentSuggestion candidate,
  DartCompletionRequest request,
) {
  var parameter = candidate.parameter;
  var name = parameter.name;
  var type = parameter.type.getDisplayString();

  var suggestion = DartCompletionSuggestion(
    CompletionSuggestionKind.NAMED_ARGUMENT,
    candidate.relevanceScore,
    candidate.completion,
    candidate.selectionOffset,
    0,
    false,
    false,
    parameterName: name,
    parameterType: type,
    replacementLength: candidate.replacementLength,
    element: convertElement(parameter),
  );

  _setDocumentation(suggestion, parameter, request);
  return suggestion;
}

/// Add a suggestion to replace the `targetId` with an override of the given
/// [element]. If [invokeSuper] is `true`, then the override will contain an
/// invocation of an overridden member.
Future<CompletionSuggestion?> _getOverrideSuggestion(
  OverrideSuggestion candidate,
  DartCompletionRequest request,
) async {
  var displayTextBuffer = StringBuffer();
  var overrideImports = <Uri>{};
  var builder = ChangeBuilder(session: request.analysisSession);
  var replacementRange = candidate.replacementRange;
  var element = candidate.element;

  await builder.addDartFileEdit(request.path, createEditsForImports: false, (
    builder,
  ) {
    builder.addReplacement(replacementRange, (builder) {
      builder.writeOverride(
        element,
        displayTextBuffer: displayTextBuffer,
        invokeSuper: candidate.shouldInvokeSuper,
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
  if (candidate.skipAt && completion.startsWith(overrideAnnotation)) {
    completion = completion.substring('@'.length);
  }
  if (completion.isEmpty) {
    return null;
  }

  var selectionRange = builder.selectionRange;
  if (selectionRange == null) {
    return null;
  }
  var offsetDelta = replacementRange.offset + replacement.indexOf(completion);

  var displayText = displayTextBuffer.toString();
  if (displayText.isEmpty) {
    return null;
  }

  if (candidate.skipAt) {
    displayText = 'override $displayText';
  }

  var suggestion = DartCompletionSuggestion(
    CompletionSuggestionKind.OVERRIDE,
    candidate.relevanceScore,
    completion,
    selectionRange.offset - offsetDelta,
    selectionRange.length,
    element.metadata.hasDeprecated,
    false,
    displayText: displayText,
    requiredImports: overrideImports.toList(),
  );
  suggestion.element = convertElement(element);
  return suggestion;
}

/// If the [element] has a documentation comment, fill the [suggestion]'s
/// documentation fields.
void _setDocumentation(
  CompletionSuggestion suggestion,
  e.Element element,
  DartCompletionRequest request,
) {
  var doc = request.documentationComputer.compute(
    element,
    includeSummary: true,
  );
  if (doc is DocumentationWithSummary) {
    suggestion.docComplete = doc.full;
    suggestion.docSummary = doc.summary;
  }
}

class _ParameterData {
  List<String>? parameterNames;
  List<String>? parameterTypes;
  int? requiredParameterCount;
  bool? hasNamedParameters;
  CompletionDefaultArgumentList? defaultArgumentList;

  _ParameterData(
    this.parameterNames,
    this.parameterTypes,
    this.requiredParameterCount,
    this.hasNamedParameters,
    this.defaultArgumentList,
  );
}

extension on List<String> {
  String? joinWithCommaAndSurroundWithAngle() {
    if (isEmpty) {
      return null;
    }
    return '<${join(', ')}>';
  }
}
