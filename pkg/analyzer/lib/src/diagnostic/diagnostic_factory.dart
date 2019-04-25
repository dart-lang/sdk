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
      CompilationUnitElement unit = staticElement
          .getAncestor((element) => element is CompilationUnitElement);
      CharacterLocation location = unit.lineInfo.getLocation(declarationOffset);
      contextMessages = [
        new DiagnosticMessageImpl(
            filePath: source.fullName,
            message:
                "The declaration of '$name' is on line ${location.lineNumber}.",
            offset: declarationOffset,
            length: staticElement.nameLength)
      ];
    }
    return new AnalysisError(
        source,
        identifier.offset,
        identifier.length,
        CompileTimeErrorCode.REFERENCED_BEFORE_DECLARATION,
        [name],
        contextMessages);
  }
}
