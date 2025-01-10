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
import 'package:analysis_server/src/utilities/change_builder.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [ConstructorElement2]s.
class RenameConstructorRefactoringImpl extends RenameRefactoringImpl {
  RenameConstructorRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    ConstructorElement2 super.element,
  ) : super.c2();

  @override
  ConstructorElement2 get element2 => super.element2 as ConstructorElement2;

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
    var matches = await searchEngine.searchReferences(element2);
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
    if (element2.isSynthetic) {
      await _replaceSynthetic();
    } else {
      doSourceChange_addSourceEdit(
        change,
        element2.firstFragment.libraryFragment.source,
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
    var className = classDeclaration.name.lexeme;
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
    var initializers = constructor.initializers;
    if (initializers.lastOrNull case var last?) {
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
    var parentClass = element2.enclosingElement2;
    // Check if the "newName" is the name of the enclosing class.
    if (parentClass.name3 == newName) {
      result.addError(
        'The constructor should not have the same name '
        'as the name of the enclosing class.',
      );
    }
    // check if there are members with "newName" in the same ClassElement
    for (var newNameMember in getChildren(parentClass, newName)) {
      var message = format(
        "{0} '{1}' already declares {2} with name '{3}'.",
        capitalize(parentClass.kind.displayName),
        parentClass.displayName,
        getElementKindName(newNameMember),
        newName,
      );
      result.addError(message, newLocation_fromElement2(newNameMember));
    }
  }

  SourceRange _declarationNameRange() {
    var fragment = element2.firstFragment;
    var offset = fragment.periodOffset;
    if (offset != null) {
      var name = fragment.name2;
      var nameEnd = fragment.nameOffset2! + name.length;
      return range.startOffsetEndOffset(offset, nameEnd);
    } else {
      return SourceRange(
        fragment.typeNameOffset! + fragment.typeName!.length,
        0,
      );
    }
  }

  Future<AstNode?> _nodeCoveringReference(SourceReference reference) async {
    var element = reference.element2;
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
    doSourceChange_addFragmentEdit(
      change,
      reference.element2.firstFragment,
      newSourceEdit_range(range, replacement),
    );
  }

  Future<void> _replaceSynthetic() async {
    var classElement = element2.enclosingElement2;

    var fragment = classElement.firstFragment;
    var result = await sessionHelper.getElementDeclaration(fragment);
    if (result == null) {
      return;
    }

    var resolvedUnit = result.resolvedUnit;
    if (resolvedUnit == null) {
      return;
    }

    var node = result.node;
    if (node is! NamedCompilationUnitMember) {
      return;
    }
    if (node is! ClassDeclaration && node is! EnumDeclaration) {
      return;
    }

    var edit = await buildEditForInsertedConstructor(
      node,
      resolvedUnit: resolvedUnit,
      session: sessionHelper.session,
      (builder) => builder.writeConstructorDeclaration(
        classElement.name3!,
        constructorName: newName,
        isConst: node is EnumDeclaration,
      ),
    );
    if (edit == null) {
      return;
    }
    doSourceChange_addFragmentEdit(change, fragment, edit);
  }
}
