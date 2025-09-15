// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/utilities/extensions/string.dart';
import 'package:yaml/yaml.dart';

/// A factory used to create diagnostics.
class DiagnosticFactory {
  /// Initialize a newly created diagnostic factory.
  DiagnosticFactory();

  /// Return a diagnostic indicating that [duplicate] uses the same [variable]
  /// as a previous [original] node in a pattern assignment.
  Diagnostic duplicateAssignmentPatternVariable({
    required Source source,
    required PromotableElementImpl variable,
    required AssignedVariablePatternImpl original,
    required AssignedVariablePatternImpl duplicate,
  }) {
    return Diagnostic.tmp(
      source: source,
      offset: duplicate.offset,
      length: duplicate.length,
      diagnosticCode: CompileTimeErrorCode.duplicatePatternAssignmentVariable,
      arguments: [variable.name!],
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          length: original.length,
          message: 'The first assigned variable pattern.',
          offset: original.offset,
          url: source.uri.toString(),
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateFragment] reuses a name
  /// already used by [originalElement].
  Diagnostic duplicateDefinition(
    DiagnosticCode code,
    FragmentImpl duplicateFragment,
    ElementImpl originalElement,
    List<Object> arguments,
  ) {
    var originalFragment = originalElement.nonSynthetic.firstFragment;
    return Diagnostic.tmp(
      source: duplicateFragment.libraryFragment!.source,
      offset: duplicateFragment.nameOffset ?? -1,
      length: duplicateFragment.name!.length,
      diagnosticCode: code,
      arguments: arguments,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: originalFragment.libraryFragment!.source.fullName,
          message: "The first definition of this name.",
          offset: originalFragment.nameOffset ?? -1,
          length: originalElement.nonSynthetic.name!.length,
          url: null,
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateNode] reuses a name
  /// already used by [originalNode].
  Diagnostic duplicateDefinitionForNodes(
    Source source,
    DiagnosticCode code,
    SyntacticEntity duplicateNode,
    SyntacticEntity originalNode,
    List<Object> arguments,
  ) {
    return Diagnostic.tmp(
      source: source,
      offset: duplicateNode.offset,
      length: duplicateNode.length,
      diagnosticCode: code,
      arguments: arguments,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The first definition of this name.",
          offset: originalNode.offset,
          length: originalNode.length,
          url: null,
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateField] reuses a name
  /// already used by [originalField].
  Diagnostic duplicateFieldDefinitionInLiteral(
    Source source,
    NamedExpression duplicateField,
    NamedExpression originalField,
  ) {
    var duplicateNode = duplicateField.name.label;
    var duplicateName = duplicateNode.name;
    return Diagnostic.tmp(
      source: source,
      offset: duplicateNode.offset,
      length: duplicateNode.length,
      diagnosticCode: CompileTimeErrorCode.duplicateFieldName,
      arguments: [duplicateName],
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          length: duplicateName.length,
          message: 'The first ',
          offset: originalField.name.label.offset,
          url: source.uri.toString(),
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateField] reuses a name
  /// already used by [originalField].
  ///
  /// This method requires that both the [duplicateField] and [originalField]
  /// have a non-null `name`.
  Diagnostic duplicateFieldDefinitionInType(
    Source source,
    RecordTypeAnnotationField duplicateField,
    RecordTypeAnnotationField originalField,
  ) {
    var duplicateNode = duplicateField.name!;
    var duplicateName = duplicateNode.lexeme;
    return Diagnostic.tmp(
      source: source,
      offset: duplicateNode.offset,
      length: duplicateNode.length,
      diagnosticCode: CompileTimeErrorCode.duplicateFieldName,
      arguments: [duplicateName],
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          length: duplicateName.length,
          message: 'The first ',
          offset: originalField.name!.offset,
          url: source.uri.toString(),
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateField] reuses a name
  /// already used by [originalField].
  Diagnostic duplicatePatternField({
    required Source source,
    required String name,
    required PatternField duplicateField,
    required PatternField originalField,
  }) {
    var originalNode = originalField.name!;
    var originalTarget = originalNode.name ?? originalNode.colon;
    var duplicateNode = duplicateField.name!;
    var duplicateTarget = duplicateNode.name ?? duplicateNode.colon;
    return Diagnostic.tmp(
      source: source,
      offset: duplicateTarget.offset,
      length: duplicateTarget.length,
      diagnosticCode: CompileTimeErrorCode.duplicatePatternField,
      arguments: [name],
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          length: originalTarget.length,
          message: 'The first field.',
          offset: originalTarget.offset,
          url: source.uri.toString(),
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateElement] reuses a name
  /// already used by [originalElement].
  Diagnostic duplicateRestElementInPattern({
    required Source source,
    required RestPatternElement originalElement,
    required RestPatternElement duplicateElement,
  }) {
    return Diagnostic.tmp(
      source: source,
      offset: duplicateElement.offset,
      length: duplicateElement.length,
      diagnosticCode: CompileTimeErrorCode.duplicateRestElementInPattern,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          length: originalElement.length,
          message: 'The first rest element.',
          offset: originalElement.offset,
          url: source.uri.toString(),
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that the [duplicateElement] (in a constant
  /// set) is a duplicate of the [originalElement].
  Diagnostic equalElementsInConstSet(
    Source source,
    Expression duplicateElement,
    Expression originalElement,
  ) {
    return Diagnostic.tmp(
      source: source,
      offset: duplicateElement.offset,
      length: duplicateElement.length,
      diagnosticCode: CompileTimeErrorCode.equalElementsInConstSet,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The first element with this value.",
          offset: originalElement.offset,
          length: originalElement.length,
          url: null,
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that the [duplicateKey] (in a constant map)
  /// is a duplicate of the [originalKey].
  Diagnostic equalKeysInConstMap(
    Source source,
    Expression duplicateKey,
    Expression originalKey,
  ) {
    return Diagnostic.tmp(
      source: source,
      offset: duplicateKey.offset,
      length: duplicateKey.length,
      diagnosticCode: CompileTimeErrorCode.equalKeysInConstMap,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The first key with this value.",
          offset: originalKey.offset,
          length: originalKey.length,
          url: null,
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that the [duplicateKey] (in a map pattern)
  /// is a duplicate of the [originalKey].
  Diagnostic equalKeysInMapPattern(
    Source source,
    Expression duplicateKey,
    Expression originalKey,
  ) {
    return Diagnostic.tmp(
      source: source,
      offset: duplicateKey.offset,
      length: duplicateKey.length,
      diagnosticCode: CompileTimeErrorCode.equalKeysInMapPattern,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The first key with this value.",
          offset: originalKey.offset,
          length: originalKey.length,
          url: null,
        ),
      ],
    );
  }

  Diagnostic incompatibleLint({
    required Source source,
    required YamlScalar reference,
    required Map<String, YamlScalar> incompatibleRules,
  }) {
    assert(reference.value is String);
    assert(incompatibleRules.values.every((node) => node.value is String));
    return Diagnostic.tmp(
      source: source,
      offset: reference.span.start.offset,
      length: reference.span.length,
      diagnosticCode: AnalysisOptionsWarningCode.incompatibleLint,
      arguments: [
        reference.value as String,
        incompatibleRules.values
            .map((node) => node.value as String)
            .quotedAndCommaSeparatedWithAnd,
      ],
      contextMessages: [
        for (var MapEntry(key: file, value: incompatible)
            in incompatibleRules.entries)
          DiagnosticMessageImpl(
            filePath: file,
            message:
                "The rule '${incompatible.value.toString()}' is enabled here.",
            offset: incompatible.span.start.offset,
            length: incompatible.span.length,
            url: file,
          ),
      ],
    );
  }

  /// Returns a diagnostic indicating that incompatible rules were found between
  /// the current list and one or more of the included files.
  Diagnostic incompatibleLintFiles({
    required Source source,
    required YamlScalar reference,
    required Map<String, YamlScalar> incompatibleRules,
  }) {
    assert(reference.value is String);
    assert(incompatibleRules.values.every((node) => node.value is String));
    return Diagnostic.tmp(
      source: source,
      offset: reference.span.start.offset,
      length: reference.span.length,
      diagnosticCode: AnalysisOptionsWarningCode.incompatibleLintFiles,
      arguments: [
        reference.value as String,
        incompatibleRules.values
            .map((node) => node.value as String)
            .quotedAndCommaSeparatedWithAnd,
      ],
      contextMessages: [
        for (var MapEntry(key: file, value: incompatible)
            in incompatibleRules.entries)
          DiagnosticMessageImpl(
            filePath: file,
            message:
                "The rule '${incompatible.value.toString()}' is enabled here "
                "in the file '$file'.",
            offset: incompatible.span.start.offset,
            length: incompatible.span.length,
            url: file,
          ),
      ],
    );
  }

  /// Returns a diagnostic indicating that incompatible rules were found between
  /// the included files.
  Diagnostic incompatibleLintIncluded({
    required Source source,
    required YamlScalar reference,
    required Map<String, YamlScalar> incompatibleRules,
    required int fileCount,
  }) {
    assert(fileCount > 0);
    assert(reference.value is String);
    assert(incompatibleRules.values.every((node) => node.value is String));
    return Diagnostic.tmp(
      source: source,
      offset: reference.span.start.offset,
      length: reference.span.length,
      diagnosticCode: AnalysisOptionsWarningCode.incompatibleLintIncluded,
      arguments: [
        reference.value as String,
        incompatibleRules.values
            .map((node) => node.value as String)
            .quotedAndCommaSeparatedWithAnd,
        fileCount,
        fileCount == 1 ? '' : 's',
      ],
      contextMessages: [
        for (var MapEntry(key: file, value: incompatible)
            in incompatibleRules.entries)
          DiagnosticMessageImpl(
            filePath: file,
            message:
                "The rule '${incompatible.value.toString()}' is enabled here.",
            offset: incompatible.span.start.offset,
            length: incompatible.span.length,
            url: file,
          ),
      ],
    );
  }

  Diagnostic invalidNullAwareAfterShortCircuit(
    Source source,
    int offset,
    int length,
    List<Object> arguments,
    Token previousToken,
  ) {
    var lexeme = previousToken.lexeme;
    return Diagnostic.tmp(
      source: source,
      offset: offset,
      length: length,
      diagnosticCode:
          StaticWarningCode.invalidNullAwareOperatorAfterShortCircuit,
      arguments: arguments,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The operator '$lexeme' is causing the short circuiting.",
          offset: previousToken.offset,
          length: previousToken.length,
          url: null,
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [member] is not a correct override of
  /// [superMember].
  Diagnostic invalidOverride(
    Source source,
    DiagnosticCode code,
    SyntacticEntity errorNode,
    ExecutableElement member,
    ExecutableElement superMember,
    String memberName,
  ) {
    // Elements enclosing members that can participate in overrides are always
    // named, so we can safely assume `_thisMember.enclosingElement3.name` and
    // `superMember.enclosingElement3.name` are non-`null`.
    var superElement = superMember.nonSynthetic.baseElement as ElementImpl;
    var superLocation = superElement.firstFragmentLocation;
    return Diagnostic.tmp(
      source: source,
      offset: errorNode.offset,
      length: errorNode.length,
      diagnosticCode: code,
      arguments: [
        memberName,
        member.enclosingElement!.name,
        member.type,
        superMember.enclosingElement!.name,
        superMember.type,
      ],
      contextMessages: [
        // Only include the context location for INVALID_OVERRIDE because for
        // some other types this location is not ideal (for example
        // INVALID_IMPLEMENTATION_OVERRIDE may provide the subclass as superMember
        // if the subclass has an abstract member and the superclass has the
        // concrete).
        if (code == CompileTimeErrorCode.invalidOverride)
          DiagnosticMessageImpl(
            filePath: superLocation.libraryFragment!.source.fullName,
            message: "The member being overridden.",
            offset: superLocation.nameOffset ?? -1,
            length: superLocation.name!.length,
            url: null,
          ),
        if (code == CompileTimeErrorCode.invalidOverrideSetter)
          DiagnosticMessageImpl(
            filePath: superLocation.libraryFragment!.source.fullName,
            message: "The setter being overridden.",
            offset: superLocation.nameOffset ?? -1,
            length: superLocation.name!.length,
            url: null,
          ),
      ],
    );
  }

  /// Return a diagnostic indicating that the given [nameToken] was referenced
  /// before it was declared.
  Diagnostic referencedBeforeDeclaration(
    Source source, {
    required Token nameToken,
    required Element element2,
  }) {
    String name = nameToken.lexeme;
    List<DiagnosticMessage>? contextMessages;
    int declarationOffset = element2.firstFragment.nameOffset ?? -1;
    if (declarationOffset >= 0) {
      contextMessages = [
        DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The declaration of '$name' is here.",
          offset: declarationOffset,
          length: name.length,
          url: null,
        ),
      ];
    }
    return Diagnostic.tmp(
      source: source,
      offset: nameToken.offset,
      length: nameToken.length,
      diagnosticCode: CompileTimeErrorCode.referencedBeforeDeclaration,
      arguments: [name],
      contextMessages: contextMessages ?? const [],
    );
  }
}
