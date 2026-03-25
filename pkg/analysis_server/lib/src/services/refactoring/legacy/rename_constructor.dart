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
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analysis_server_plugin/src/utilities/selection.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_dart.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [ConstructorElement]s.
class RenameConstructorRefactoringImpl extends RenameRefactoringImpl {
  final ResolvedUnitResult resolvedUnit;
  final CorrectionUtils utils;

  RenameConstructorRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    this.resolvedUnit,
    ConstructorElement super.element,
  ) : utils = CorrectionUtils(resolvedUnit),
      super();

  @override
  ConstructorElement get element => super.element as ConstructorElement;

  @override
  String get refactoringName {
    return 'Rename Constructor';
  }

  Future<void> buildChange({required ChangeBuilder builder}) async {
    // prepare references
    var matches = await searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    // update references
    for (var reference in references) {
      // Handle implicit references.
      var coveringNode = await _nodeCoveringReference(reference);
      var coveringParent = coveringNode?.parent;
      if (coveringParent is ClassDeclaration) {
        await builder.addDartFileEdit(reference.file, (builder) {
          _addDefaultConstructorToClass(
            builder: builder,
            classDeclaration: coveringParent,
          );
        });
        continue;
      } else if (coveringParent is ConstructorDeclaration &&
          coveringParent.typeName!.offset == reference.range.offset) {
        await builder.addDartFileEdit(reference.file, (builder) {
          _addSuperInvocationToConstructor(
            builder: builder,
            constructor: coveringParent,
          );
        });
        continue;
      }

      String replacement;
      if (newName.isNotEmpty) {
        if (reference.isDotShortHandsConstructor) {
          replacement = newName;
        } else {
          replacement = '.$newName';
        }
      } else {
        if (reference.isDotShortHandsConstructor) {
          replacement = 'new';
        } else if (reference.isConstructorTearOff) {
          replacement = '.new';
        } else {
          replacement = '';
        }
      }
      if (reference.isInvocationByEnumConstantWithoutArguments) {
        replacement += '()';
      }
      await builder.addDartFileEdit(reference.file, (builder) {
        builder.addSimpleReplacement(reference.range, replacement);
      });
    }
    // Update the declaration.
    if (element.isOriginImplicitDefault) {
      await _replaceSynthetic(builder: builder);
    } else if (element.firstFragment.typeNameOffset != null) {
      await _replaceWhenTypeName(builder: builder);
    } else {
      await _replaceWhenKeyword(builder: builder);
    }
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
  Future<SourceChange> createChange({ChangeBuilder? builder}) async {
    builder ??= ChangeBuilder(
      session: resolvedUnit.session,
      defaultEol: utils.endOfLine,
    );
    await buildChange(builder: builder);
    var sourceChange = builder.sourceChange;
    sourceChange.message = "$refactoringName '$oldName' to '$newName'";
    return sourceChange;
  }

  @override
  Future<void> fillChange() {
    throw UnsupportedError('This method should never be called.');
  }

  void _addDefaultConstructorToClass({
    required DartFileEditBuilder builder,
    required ClassDeclaration classDeclaration,
  }) {
    var body = classDeclaration.body;
    var className = classDeclaration.namePart.typeName.lexeme;
    if (body is BlockClassBody) {
      builder.addSimpleInsertion(
        body.leftBracket.end,
        '${utils.endOfLine}  $className() : super.$newName();',
      );
    } else if (body is EmptyClassBody) {
      var endOfLine = utils.endOfLine;
      builder.addSimpleReplacement(
        range.token(body.semicolon),
        ' {$endOfLine  $className() : super.$newName();$endOfLine}',
      );
    }
  }

  void _addSuperInvocationToConstructor({
    required DartFileEditBuilder builder,
    required ConstructorDeclaration constructor,
  }) {
    var initializers = constructor.initializers;
    if (initializers.lastOrNull case var last?) {
      builder.addSimpleInsertion(last.end, ', super.$newName()');
    } else {
      builder.addSimpleInsertion(
        constructor.parameters.end,
        ' : super.$newName()',
      );
    }
  }

  void _analyzePossibleConflicts(RefactoringStatus result) {
    var parentClass = element.enclosingElement;
    // Check if the "newName" is the name of the enclosing class.
    if (parentClass.name == newName) {
      result.addError(
        'The constructor should not have the same name '
        'as the name of the enclosing class.',
      );
    }
    // check if there are members with "newName" in the same ClassElement
    for (var newNameMember in getChildren(parentClass, newName)) {
      var message =
          formatList("{0} '{1}' already declares {2} with name '{3}'.", [
            capitalize(parentClass.kind.displayName),
            parentClass.displayName,
            getElementKindName(newNameMember),
            newName,
          ]);
      result.addError(message, newLocation_fromElement(newNameMember));
    }
  }

  Future<AstNode?> _nodeCoveringReference(SourceReference reference) async {
    var element = reference.element;
    var unitResult = await sessionHelper.getResolvedUnitByElement(element);
    return unitResult?.unit
        .select(offset: reference.range.offset, length: 0)
        ?.coveringNode;
  }

  Future<void> _replaceSynthetic({required ChangeBuilder builder}) async {
    var classElement = element.enclosingElement;

    var fragment = classElement.firstFragment;
    var result = await sessionHelper.getFragmentDeclaration(fragment);
    if (result == null) {
      return;
    }

    var resolvedUnit = result.resolvedUnit;
    if (resolvedUnit == null) {
      return;
    }

    var node = result.node;
    if (node is! CompilationUnitMember) {
      return;
    }
    if (node is! ClassDeclaration && node is! EnumDeclaration) {
      return;
    }

    await builder.addDartFileEdit(fragment.libraryFragment.source.fullName, (
      builder,
    ) {
      builder.insertConstructor(
        node,
        (builder) => builder.writeConstructorDeclaration(
          classElement.name!,
          constructorName: newName,
          isConst: node is EnumDeclaration,
        ),
      );
    });
  }

  /// Adds a source edit for when the constructor is declared using the `new`
  /// or `factory` keywords instead of a type name.
  Future<void> _replaceWhenKeyword({required ChangeBuilder builder}) async {
    // Compute the source range always including any space because we may
    // need to remove it.
    var fragment = element.firstFragment;
    var offset = fragment.newKeywordOffset != null
        ? fragment.newKeywordOffset! + 'new'.length
        : fragment.factoryKeywordOffset! + 'factory'.length;
    var end = fragment.nameOffset != null
        ? fragment.nameOffset! + fragment.name.length
        : offset;
    var replacementRange = SourceRange(offset, end - offset);
    await builder.addDartFileEdit(
      element.firstFragment.libraryFragment.source.fullName,
      (builder) {
        builder.addSimpleReplacement(
          replacementRange,
          // Replace assuming any existing period is in the range.
          newName.isNotEmpty ? ' $newName' : '',
        );
      },
    );
  }

  /// Adds a source edit for when the constructor is declared using the type
  /// name.
  Future<void> _replaceWhenTypeName({required ChangeBuilder builder}) async {
    SourceRange replacementRange;

    // Compute the source range always including the period because we may
    // need to remove it.
    var fragment = element.firstFragment;
    var offset = fragment.periodOffset;
    if (offset != null) {
      var nameEnd = fragment.nameOffset! + fragment.name.length;
      replacementRange = range.startOffsetEndOffset(offset, nameEnd);
    } else {
      replacementRange = SourceRange(
        fragment.typeNameOffset! + fragment.typeName!.length,
        0,
      );
    }

    await builder.addDartFileEdit(
      element.firstFragment.libraryFragment.source.fullName,
      (builder) {
        builder.addSimpleReplacement(
          replacementRange,
          // Replace assuming any existing period is in the range.
          newName.isNotEmpty ? '.$newName' : '',
        );
      },
    );
  }
}
