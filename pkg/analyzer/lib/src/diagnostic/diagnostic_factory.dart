// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/diagnostic/diagnostic.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';

/// A factory used to create diagnostics.
class DiagnosticFactory {
  /// Initialize a newly created diagnostic factory.
  DiagnosticFactory();

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
          length: originalElement.length)
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
          length: originalKey.length)
    ]);
  }

  /// Return a diagnostic indicating that the given [identifier] was referenced
  /// before it was declared.
  AnalysisError referencedBeforeDeclaration(
      Source source, Identifier identifier,
      {Element element}) {
    String name = identifier.name;
    Element staticElement = element ?? identifier.staticElement;
    List<DiagnosticMessage> contextMessages;
    int declarationOffset = staticElement.nameOffset;
    if (declarationOffset >= 0 && staticElement != null) {
      CompilationUnitElement unit = staticElement.thisOrAncestorOfType();
      CharacterLocation location = unit.lineInfo.getLocation(declarationOffset);
      contextMessages = [
        DiagnosticMessageImpl(
            filePath: source.fullName,
            message:
                "The declaration of '$name' is on line ${location.lineNumber}.",
            offset: declarationOffset,
            length: staticElement.nameLength)
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
