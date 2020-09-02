// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [ConstructorElement]s.
class RenameConstructorRefactoringImpl extends RenameRefactoringImpl {
  final AnalysisSession session;

  RenameConstructorRefactoringImpl(
      RefactoringWorkspace workspace, this.session, ConstructorElement element)
      : super(workspace, element);

  @override
  ConstructorElement get element => super.element as ConstructorElement;

  @override
  String get refactoringName {
    return 'Rename Constructor';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    result.addStatus(validateConstructorName(newName));
    if (newName != null) {
      _analyzePossibleConflicts(result);
    }
    return result;
  }

  @override
  Future<void> fillChange() async {
    // prepare references
    var matches = await searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    // append declaration
    if (element.isSynthetic) {
      await _replaceSynthetic();
    } else {
      references.add(_createDeclarationReference());
    }
    // update references
    var replacement = newName.isEmpty ? '' : '.$newName';
    for (var reference in references) {
      reference.addEdit(change, replacement);
    }
  }

  void _analyzePossibleConflicts(RefactoringStatus result) {
    var parentClass = element.enclosingElement;
    // Check if the "newName" is the name of the enclosing class.
    if (parentClass.name == newName) {
      result.addError('The constructor should not have the same name '
          'as the name of the enclosing class.');
    }
    // check if there are members with "newName" in the same ClassElement
    for (var newNameMember in getChildren(parentClass, newName)) {
      var message = format("Class '{0}' already declares {1} with name '{2}'.",
          parentClass.displayName, getElementKindName(newNameMember), newName);
      result.addError(message, newLocation_fromElement(newNameMember));
    }
  }

  SourceReference _createDeclarationReference() {
    SourceRange sourceRange;
    var offset = element.periodOffset;
    if (offset != null) {
      sourceRange = range.startOffsetEndOffset(offset, element.nameEnd);
    } else {
      sourceRange = SourceRange(element.nameEnd, 0);
    }
    return SourceReference(SearchMatchImpl(
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

  Future<void> _replaceSynthetic() async {
    var classElement = element.enclosingElement;

    var result = await AnalysisSessionHelper(session)
        .getElementDeclaration(classElement);
    ClassDeclaration classNode = result.node;
    var utils = CorrectionUtils(result.resolvedUnit);
    var location = utils.prepareNewConstructorLocation(classNode);
    doSourceChange_addElementEdit(
        change,
        classElement,
        SourceEdit(
            location.offset,
            0,
            location.prefix +
                '${classElement.name}.$newName();' +
                location.suffix));
  }
}
