// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';

/// A factory used to create diagnostics.
class DiagnosticFactory {
  /// Initialize a newly created diagnostic factory.
  DiagnosticFactory();

  /// Return a diagnostic indicating that [duplicate] uses the same [variable]
  /// as a previous [original] node in a pattern assignment.
  AnalysisError duplicateAssignmentPatternVariable({
    required Source source,
    required PromotableElement variable,
    required AssignedVariablePatternImpl original,
    required AssignedVariablePatternImpl duplicate,
  }) {
    return AnalysisError.tmp(
      source: source,
      offset: duplicate.offset,
      length: duplicate.length,
      errorCode: CompileTimeErrorCode.DUPLICATE_PATTERN_ASSIGNMENT_VARIABLE,
      arguments: [variable.name],
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

  /// Return a diagnostic indicating that [duplicateElement] reuses a name
  /// already used by [originalElement].
  AnalysisError duplicateDefinition(ErrorCode code, Element duplicateElement,
      Element originalElement, List<Object> arguments) {
    final duplicate = duplicateElement.nonSynthetic;
    final original = originalElement.nonSynthetic;
    return AnalysisError.tmp(
      source: duplicate.source!,
      offset: duplicate.nameOffset,
      length: duplicate.nameLength,
      errorCode: code,
      arguments: arguments,
      contextMessages: [
        DiagnosticMessageImpl(
          filePath: original.source!.fullName,
          message: "The first definition of this name.",
          offset: original.nameOffset,
          length: original.nameLength,
          url: null,
        ),
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateNode] reuses a name
  /// already used by [originalNode].
  AnalysisError duplicateDefinitionForNodes(
      Source source,
      ErrorCode code,
      SyntacticEntity duplicateNode,
      SyntacticEntity originalNode,
      List<Object> arguments) {
    return AnalysisError.tmp(
      source: source,
      offset: duplicateNode.offset,
      length: duplicateNode.length,
      errorCode: code,
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
  AnalysisError duplicateFieldDefinitionInLiteral(Source source,
      NamedExpression duplicateField, NamedExpression originalField) {
    var duplicateNode = duplicateField.name.label;
    var duplicateName = duplicateNode.name;
    return AnalysisError.tmp(
      source: source,
      offset: duplicateNode.offset,
      length: duplicateNode.length,
      errorCode: CompileTimeErrorCode.DUPLICATE_FIELD_NAME,
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
  AnalysisError duplicateFieldDefinitionInType(
      Source source,
      RecordTypeAnnotationField duplicateField,
      RecordTypeAnnotationField originalField) {
    var duplicateNode = duplicateField.name!;
    var duplicateName = duplicateNode.lexeme;
    return AnalysisError.tmp(
      source: source,
      offset: duplicateNode.offset,
      length: duplicateNode.length,
      errorCode: CompileTimeErrorCode.DUPLICATE_FIELD_NAME,
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
  AnalysisError duplicatePatternField({
    required Source source,
    required String name,
    required PatternField duplicateField,
    required PatternField originalField,
  }) {
    var originalNode = originalField.name!;
    var originalTarget = originalNode.name ?? originalNode.colon;
    var duplicateNode = duplicateField.name!;
    var duplicateTarget = duplicateNode.name ?? duplicateNode.colon;
    return AnalysisError.tmp(
      source: source,
      offset: duplicateTarget.offset,
      length: duplicateTarget.length,
      errorCode: CompileTimeErrorCode.DUPLICATE_PATTERN_FIELD,
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
  AnalysisError duplicateRestElementInPattern({
    required Source source,
    required RestPatternElement originalElement,
    required RestPatternElement duplicateElement,
  }) {
    return AnalysisError.tmp(
      source: source,
      offset: duplicateElement.offset,
      length: duplicateElement.length,
      errorCode: CompileTimeErrorCode.DUPLICATE_REST_ELEMENT_IN_PATTERN,
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
  AnalysisError equalElementsInConstSet(
      Source source, Expression duplicateElement, Expression originalElement) {
    return AnalysisError.tmp(
      source: source,
      offset: duplicateElement.offset,
      length: duplicateElement.length,
      errorCode: CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET,
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
  AnalysisError equalKeysInConstMap(
      Source source, Expression duplicateKey, Expression originalKey) {
    return AnalysisError.tmp(
      source: source,
      offset: duplicateKey.offset,
      length: duplicateKey.length,
      errorCode: CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP,
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
  AnalysisError equalKeysInMapPattern(
      Source source, Expression duplicateKey, Expression originalKey) {
    return AnalysisError.tmp(
      source: source,
      offset: duplicateKey.offset,
      length: duplicateKey.length,
      errorCode: CompileTimeErrorCode.EQUAL_KEYS_IN_MAP_PATTERN,
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

  /// Return a diagnostic indicating that the [duplicateKey] (in a constant map)
  /// is a duplicate of the [originalKey].
  AnalysisError invalidNullAwareAfterShortCircuit(Source source, int offset,
      int length, List<Object> arguments, Token previousToken) {
    var lexeme = previousToken.lexeme;
    return AnalysisError.tmp(
      source: source,
      offset: offset,
      length: length,
      errorCode:
          StaticWarningCode.INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT,
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
  AnalysisError invalidOverride(
      Source source,
      ErrorCode errorCode,
      SyntacticEntity errorNode,
      ExecutableElement member,
      ExecutableElement superMember,
      String memberName) {
    // Elements enclosing members that can participate in overrides are always
    // named, so we can safely assume `_thisMember.enclosingElement3.name` and
    // `superMember.enclosingElement3.name` are non-`null`.
    return AnalysisError.tmp(
      source: source,
      offset: errorNode.offset,
      length: errorNode.length,
      errorCode: errorCode,
      arguments: [
        memberName,
        member.enclosingElement.name!,
        member.type,
        superMember.enclosingElement.name!,
        superMember.type,
      ],
      contextMessages: [
        // Only include the context location for INVALID_OVERRIDE because for
        // some other types this location is not ideal (for example
        // INVALID_IMPLEMENTATION_OVERRIDE may provide the subclass as superMember
        // if the subclass has an abstract member and the superclass has the
        // concrete).
        if (errorCode == CompileTimeErrorCode.INVALID_OVERRIDE)
          DiagnosticMessageImpl(
            filePath: superMember.source.fullName,
            message: "The member being overridden.",
            offset: superMember.nonSynthetic.nameOffset,
            length: superMember.nonSynthetic.nameLength,
            url: null,
          ),
        if (errorCode == CompileTimeErrorCode.INVALID_OVERRIDE_SETTER)
          DiagnosticMessageImpl(
            filePath: superMember.source.fullName,
            message: "The setter being overridden.",
            offset: superMember.nonSynthetic.nameOffset,
            length: superMember.nonSynthetic.nameLength,
            url: null,
          )
      ],
    );
  }

  /// Return a diagnostic indicating that the given [identifier] was referenced
  /// before it was declared.
  AnalysisError referencedBeforeDeclaration(
    Source source, {
    required Token nameToken,
    required Element element,
  }) {
    String name = nameToken.lexeme;
    List<DiagnosticMessage>? contextMessages;
    int declarationOffset = element.nameOffset;
    if (declarationOffset >= 0) {
      contextMessages = [
        DiagnosticMessageImpl(
            filePath: source.fullName,
            message: "The declaration of '$name' is here.",
            offset: declarationOffset,
            length: element.nameLength,
            url: null)
      ];
    }
    return AnalysisError.tmp(
      source: source,
      offset: nameToken.offset,
      length: nameToken.length,
      errorCode: CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION,
      arguments: [name],
      contextMessages: contextMessages ?? const [],
    );
  }
}
