// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/utilities/selection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [ConstructorElement]s.
class RenameConstructorRefactoringImpl extends RenameRefactoringImpl {
  RenameConstructorRefactoringImpl(
      super.workspace, super.sessionHelper, ConstructorElement super.element);

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
    _analyzePossibleConflicts(result);
    return result;
  }

  @override
  Future<void> fillChange() async {
    // prepare references
    var matches = await searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    // update references
    for (var reference in references) {
      // Handle implicit references.
      var coveringNode = await _nodeCoveringReference(reference);
      var coveringParent = coveringNode?.parent;
      if (coveringNode is ClassDeclaration) {
        _addDefaultConstructorToClass(
          reference: reference,
          classDeclaration: coveringNode,
        );
        continue;
      } else if (coveringParent is ConstructorDeclaration &&
          coveringParent.returnType.offset == reference.range.offset) {
        _addSuperInvocationToConstructor(
          reference: reference,
          constructor: coveringParent,
        );
        continue;
      }

      String replacement;
      if (newName.isNotEmpty) {
        replacement = '.$newName';
      } else {
        replacement = reference.isConstructorTearOff ? '.new' : '';
      }
      if (reference.isInvocationByEnumConstantWithoutArguments) {
        replacement += '()';
      }
      reference.addEdit(change, replacement);
    }
    // Update the declaration.
    if (element.isSynthetic) {
      await _replaceSynthetic();
    } else {
      doSourceChange_addSourceEdit(
        change,
        element.source,
        newSourceEdit_range(
          _declarationNameRange(),
          newName.isNotEmpty ? '.$newName' : '',
        ),
      );
    }
  }

  void _addDefaultConstructorToClass({
    required SourceReference reference,
    required ClassDeclaration classDeclaration,
  }) {
    final className = classDeclaration.name.lexeme;
    _replaceInReferenceFile(
      reference: reference,
      range: range.endLength(classDeclaration.leftBracket, 0),
      replacement: '\n  $className() : super.$newName();',
    );
  }

  void _addSuperInvocationToConstructor({
    required SourceReference reference,
    required ConstructorDeclaration constructor,
  }) {
    final initializers = constructor.initializers;
    if (initializers.lastOrNull case final last?) {
      _replaceInReferenceFile(
        reference: reference,
        range: range.endLength(last, 0),
        replacement: ', super.$newName()',
      );
    } else {
      _replaceInReferenceFile(
        reference: reference,
        range: range.endLength(constructor.parameters, 0),
        replacement: ' : super.$newName()',
      );
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

  SourceRange _declarationNameRange() {
    var offset = element.periodOffset;
    var nameEnd = element.nameEnd!;
    if (offset != null) {
      return range.startOffsetEndOffset(offset, nameEnd);
    } else {
      return SourceRange(nameEnd, 0);
    }
  }

  Future<AstNode?> _nodeCoveringReference(SourceReference reference) async {
    var element = reference.element;
    var unitResult = await sessionHelper.getResolvedUnitByElement(element);
    return unitResult?.unit
        .select(offset: reference.range.offset, length: 0)
        ?.coveringNode;
  }

  void _replaceInReferenceFile({
    required SourceReference reference,
    required SourceRange range,
    required String replacement,
  }) {
    doSourceChange_addElementEdit(
      change,
      reference.element,
      newSourceEdit_range(range, replacement),
    );
  }

  Future<void> _replaceSynthetic() async {
    var classElement = element.enclosingElement;

    var result = await sessionHelper.getElementDeclaration(classElement);
    if (result == null) {
      return;
    }

    var resolvedUnit = result.resolvedUnit;
    if (resolvedUnit == null) {
      return;
    }

    var node = result.node;
    if (node is ClassDeclaration) {
      var utils = CorrectionUtils(resolvedUnit);
      var location =
          utils.prepareNewConstructorLocation(sessionHelper.session, node);
      if (location == null) {
        return;
      }

      var header = '${classElement.name}.$newName();';
      doSourceChange_addElementEdit(
        change,
        classElement,
        SourceEdit(
          location.offset,
          0,
          location.prefix + header + location.suffix,
        ),
      );
    } else if (node is EnumDeclaration) {
      var utils = CorrectionUtils(resolvedUnit);
      var location = utils.prepareEnumNewConstructorLocation(node);
      var header = 'const ${classElement.name}.$newName();';
      doSourceChange_addElementEdit(
        change,
        classElement,
        SourceEdit(
          location.offset,
          0,
          location.prefix + header + location.suffix,
        ),
      );
    }
  }
}
