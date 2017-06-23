// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/ast_provider.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/**
 * A [Refactoring] for renaming [ConstructorElement]s.
 */
class RenameConstructorRefactoringImpl extends RenameRefactoringImpl {
  final AstProvider astProvider;

  RenameConstructorRefactoringImpl(
      SearchEngine searchEngine, this.astProvider, ConstructorElement element)
      : super(searchEngine, element);

  @override
  ConstructorElement get element => super.element as ConstructorElement;

  @override
  String get refactoringName {
    return "Rename Constructor";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    RefactoringStatus result = new RefactoringStatus();
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    result.addStatus(validateConstructorName(newName));
    if (newName != null) {
      _analyzePossibleConflicts(result);
    }
    return result;
  }

  @override
  Future fillChange() async {
    // prepare references
    List<SearchMatch> matches = await searchEngine.searchReferences(element);
    List<SourceReference> references = getSourceReferences(matches);
    // append declaration
    if (element.isSynthetic) {
      await _replaceSynthetic();
    } else {
      references.add(_createDeclarationReference());
    }
    // update references
    String replacement = newName.isEmpty ? '' : '.$newName';
    for (SourceReference reference in references) {
      reference.addEdit(change, replacement);
    }
  }

  void _analyzePossibleConflicts(RefactoringStatus result) {
    ClassElement parentClass = element.enclosingElement;
    // Check if the "newName" is the name of the enclosing class.
    if (parentClass.name == newName) {
      result.addError('The constructor should not have the same name '
          'as the name of the enclosing class.');
    }
    // check if there are members with "newName" in the same ClassElement
    for (Element newNameMember in getChildren(parentClass, newName)) {
      String message = format(
          "Class '{0}' already declares {1} with name '{2}'.",
          parentClass.displayName,
          getElementKindName(newNameMember),
          newName);
      result.addError(message, newLocation_fromElement(newNameMember));
    }
  }

  SourceReference _createDeclarationReference() {
    SourceRange sourceRange;
    int offset = element.periodOffset;
    if (offset != null) {
      sourceRange = range.startOffsetEndOffset(offset, element.nameEnd);
    } else {
      sourceRange = new SourceRange(element.nameEnd, 0);
    }
    return new SourceReference(new SearchMatchImpl(
        element.source.fullName,
        element.library.source,
        element.source,
        element.library,
        element,
        true,
        true,
        MatchKind.DECLARATION,
        sourceRange));
  }

  Future<Null> _replaceSynthetic() async {
    ClassElement classElement = element.enclosingElement;
    AstNode name = await astProvider.getResolvedNameForElement(classElement);
    ClassDeclaration classNode = name.parent as ClassDeclaration;
    CorrectionUtils utils = new CorrectionUtils(classNode.parent);
    ClassMemberLocation location =
        utils.prepareNewConstructorLocation(classNode);
    doSourceChange_addElementEdit(
        change,
        classElement,
        new SourceEdit(
            location.offset,
            0,
            location.prefix +
                '${classElement.name}.$newName();' +
                location.suffix));
  }
}
