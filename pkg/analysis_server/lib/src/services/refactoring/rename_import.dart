// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_import;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/source_range.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A [Refactoring] for renaming [ImportElement]s.
 */
class RenameImportRefactoringImpl extends RenameRefactoringImpl {
  RenameImportRefactoringImpl(SearchEngine searchEngine, ImportElement element)
      : super(searchEngine, element);

  @override
  ImportElement get element => super.element as ImportElement;

  @override
  String get refactoringName {
    return "Rename Import Prefix";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    result.addStatus(validateImportPrefixName(newName));
    return result;
  }

  @override
  Future fillChange() async {
    // update declaration
    {
      PrefixElement prefix = element.prefix;
      SourceEdit edit = null;
      if (newName.isEmpty) {
        int uriEnd = element.uriEnd;
        int prefixEnd = element.prefixOffset + prefix.nameLength;
        SourceRange range = rangeStartEnd(uriEnd, prefixEnd);
        edit = newSourceEdit_range(range, "");
      } else {
        if (prefix == null) {
          SourceRange range = rangeStartLength(element.uriEnd, 0);
          edit = newSourceEdit_range(range, " as $newName");
        } else {
          int offset = element.prefixOffset;
          int length = prefix.nameLength;
          SourceRange range = rangeStartLength(offset, length);
          edit = newSourceEdit_range(range, newName);
        }
      }
      if (edit != null) {
        doSourceChange_addElementEdit(change, element, edit);
      }
    }
    // update references
    List<SearchMatch> matches = await searchEngine.searchReferences(element);
    List<SourceReference> references = getSourceReferences(matches);
    for (SourceReference reference in references) {
      if (newName.isEmpty) {
        reference.addEdit(change, '');
      } else {
        SimpleIdentifier interpolationIdentifier =
            _getInterpolationIdentifier(reference);
        if (interpolationIdentifier != null) {
          doSourceChange_addElementEdit(
              change,
              reference.element,
              new SourceEdit(
                  interpolationIdentifier.offset,
                  interpolationIdentifier.length,
                  '{$newName.${interpolationIdentifier.name}}'));
        } else {
          reference.addEdit(change, '$newName.');
        }
      }
    }
  }

  /**
   * If the given [reference] is before an interpolated [SimpleIdentifier] in
   * an [InterpolationExpression] without surrounding curly brackets, return it.
   * Otherwise return `null`.
   */
  SimpleIdentifier _getInterpolationIdentifier(SourceReference reference) {
    Source source = reference.element.source;
    CompilationUnit unit = context.parseCompilationUnit(source);
    NodeLocator nodeLocator = new NodeLocator(reference.range.offset);
    AstNode node = nodeLocator.searchWithin(unit);
    if (node is SimpleIdentifier) {
      AstNode parent = node.parent;
      if (parent is InterpolationExpression && parent.rightBracket == null) {
        return node;
      }
    }
    return null;
  }
}
