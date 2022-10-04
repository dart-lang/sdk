// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';

/// A factory used to create diagnostics.
class DiagnosticFactory {
  /// Initialize a newly created diagnostic factory.
  DiagnosticFactory();

  /// Return a diagnostic indicating that [duplicateElement] reuses a name
  /// already used by [originalElement].
  AnalysisError duplicateDefinition(ErrorCode code, Element duplicateElement,
      Element originalElement, List<Object> arguments) {
    final duplicate = duplicateElement.nonSynthetic;
    final original = originalElement.nonSynthetic;
    return AnalysisError(
      duplicate.source!,
      duplicate.nameOffset,
      duplicate.nameLength,
      code,
      arguments,
      [
        DiagnosticMessageImpl(
            filePath: original.source!.fullName,
            message: "The first definition of this name.",
            offset: original.nameOffset,
            length: original.nameLength,
            url: null)
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateNode] reuses a name
  /// already used by [originalNode].
  AnalysisError duplicateDefinitionForNodes(Source source, ErrorCode code,
      AstNode duplicateNode, AstNode originalNode, List<Object> arguments) {
    return AnalysisError(
      source,
      duplicateNode.offset,
      duplicateNode.length,
      code,
      arguments,
      [
        DiagnosticMessageImpl(
            filePath: source.fullName,
            message: "The first definition of this name.",
            offset: originalNode.offset,
            length: originalNode.length,
            url: null)
      ],
    );
  }

  /// Return a diagnostic indicating that [duplicateField] reuses a name
  /// already used by [originalField].
  AnalysisError duplicateFieldDefinitionInLiteral(Source source,
      NamedExpression duplicateField, NamedExpression originalField) {
    var duplicateNode = duplicateField.name.label;
    var duplicateName = duplicateNode.name;
    return AnalysisError(
      source,
      duplicateNode.offset,
      duplicateNode.length,
      CompileTimeErrorCode.DUPLICATE_FIELD_NAME,
      [duplicateName],
      [
        DiagnosticMessageImpl(
            filePath: source.fullName,
            length: duplicateName.length,
            message: 'The first ',
            offset: originalField.name.label.offset,
            url: source.uri.toString()),
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
    return AnalysisError(
      source,
      duplicateNode.offset,
      duplicateNode.length,
      CompileTimeErrorCode.DUPLICATE_FIELD_NAME,
      [duplicateName],
      [
        DiagnosticMessageImpl(
            filePath: source.fullName,
            length: duplicateName.length,
            message: 'The first ',
            offset: originalField.name!.offset,
            url: source.uri.toString()),
      ],
    );
  }

  /// Return a diagnostic indicating that the [duplicateElement] (in a constant
  /// set) is a duplicate of the [originalElement].
  AnalysisError equalElementsInConstSet(
      Source source, Expression duplicateElement, Expression originalElement) {
    return AnalysisError(
        source,
        duplicateElement.offset,
        duplicateElement.length,
        CompileTimeErrorCode.EQUAL_ELEMENTS_IN_CONST_SET, [], [
      DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The first element with this value.",
          offset: originalElement.offset,
          length: originalElement.length,
          url: null)
    ]);
  }

  /// Return a diagnostic indicating that the [duplicateKey] (in a constant map)
  /// is a duplicate of the [originalKey].
  AnalysisError equalKeysInConstMap(
      Source source, Expression duplicateKey, Expression originalKey) {
    return AnalysisError(source, duplicateKey.offset, duplicateKey.length,
        CompileTimeErrorCode.EQUAL_KEYS_IN_CONST_MAP, [], [
      DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The first key with this value.",
          offset: originalKey.offset,
          length: originalKey.length,
          url: null)
    ]);
  }

  /// Return a diagnostic indicating that the [duplicateKey] (in a constant map)
  /// is a duplicate of the [originalKey].
  AnalysisError invalidNullAwareAfterShortCircuit(Source source, int offset,
      int length, List<Object> arguments, Token previousToken) {
    var lexeme = previousToken.lexeme;
    return AnalysisError(
        source,
        offset,
        length,
        StaticWarningCode.INVALID_NULL_AWARE_OPERATOR_AFTER_SHORT_CIRCUIT,
        arguments, [
      DiagnosticMessageImpl(
          filePath: source.fullName,
          message: "The operator '$lexeme' is causing the short circuiting.",
          offset: previousToken.offset,
          length: previousToken.length,
          url: null)
    ]);
  }

  /// Return a diagnostic indicating that [member] is not a correct override of
  /// [superMember].
  AnalysisError invalidOverride(
      Source source,
      ErrorCode? errorCode,
      SyntacticEntity errorNode,
      ExecutableElement member,
      ExecutableElement superMember) {
    errorCode ??= CompileTimeErrorCode.INVALID_OVERRIDE;
    // Elements enclosing members that can participate in overrides are always
    // named, so we can safely assume `_thisMember.enclosingElement3.name` and
    // `superMember.enclosingElement3.name` are non-`null`.
    return AnalysisError(
        source, errorNode.offset, errorNode.length, errorCode, [
      member.name,
      member.enclosingElement.name!,
      member.type,
      superMember.enclosingElement.name!,
      superMember.type,
    ], [
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
            url: null)
    ]);
  }

  /// Return a diagnostic indicating that the given [identifier] was referenced
  /// before it was declared.
  AnalysisError referencedBeforeDeclaration(
      Source source, Identifier identifier,
      {Element? element}) {
    String name = identifier.name;
    Element staticElement = element ?? identifier.staticElement!;
    List<DiagnosticMessage>? contextMessages;
    int declarationOffset = staticElement.nameOffset;
    if (declarationOffset >= 0) {
      contextMessages = [
        DiagnosticMessageImpl(
            filePath: source.fullName,
            message: "The declaration of '$name' is here.",
            offset: declarationOffset,
            length: staticElement.nameLength,
            url: null)
      ];
    }
    return AnalysisError(
        source,
        identifier.offset,
        identifier.length,
        CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION,
        [name],
        contextMessages ?? const []);
  }
}
