// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [LibraryImportElement]s.
class RenameImportRefactoringImpl extends RenameRefactoringImpl {
  RenameImportRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    LibraryImportElement super.element,
  );

  @override
  LibraryImportElement get element => super.element as LibraryImportElement;

  @override
  String get refactoringName {
    return 'Rename Import Prefix';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    result.addStatus(validateImportPrefixName(newName));
    return result;
  }

  @override
  Future<void> fillChange() async {
    // update declaration
    {
      var node = await _findNode();
      if (node == null) {
        return;
      }

      var prefixNode = node.prefix;
      SourceEdit? edit;
      if (newName.isEmpty) {
        // We should not get `prefix == null` because we check in
        // `checkNewName` that the new name is different.
        if (prefixNode != null) {
          var uriEnd = node.uri.end;
          var prefixEnd = prefixNode.end;
          edit = newSourceEdit_range(
            range.startOffsetEndOffset(uriEnd, prefixEnd),
            '',
          );
        }
      } else {
        if (prefixNode == null) {
          var uriEnd = node.uri.end;
          edit = newSourceEdit_range(SourceRange(uriEnd, 0), ' as $newName');
        } else {
          edit = newSourceEdit_range(range.node(prefixNode), newName);
        }
      }
      if (edit != null) {
        doSourceChange_addElementEdit(change, element, edit);
      }
    }
    // update references
    var matches = await searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    for (var reference in references) {
      if (newName.isEmpty) {
        reference.addEdit(change, '');
      } else {
        var identifier = await _getInterpolationIdentifier(reference);
        if (identifier != null) {
          doSourceChange_addElementEdit(
            change,
            reference.element,
            SourceEdit(
              identifier.offset,
              identifier.length,
              '{$newName.${identifier.name}}',
            ),
          );
        } else {
          reference.addEdit(change, '$newName.');
        }
      }
    }
  }

  /// Return the [ImportDirective] node that corresponds to the [element].
  Future<ImportDirective?> _findNode() async {
    var library = element.library;
    var path = library.source.fullName;
    var unitResult = sessionHelper.session.getParsedUnit(path);
    if (unitResult is! ParsedUnitResult) {
      return null;
    }
    var unit = unitResult.unit;
    var index = library.definingCompilationUnit.libraryImports.indexOf(element);
    return unit.directives.whereType<ImportDirective>().elementAt(index);
  }

  /// If the given [reference] is before an interpolated [SimpleIdentifier] in
  /// an [InterpolationExpression] without surrounding curly brackets, return
  /// it. Otherwise return `null`.
  Future<SimpleIdentifier?> _getInterpolationIdentifier(
    SourceReference reference,
  ) async {
    var source = reference.element.source!;
    var unitResult = sessionHelper.session.getParsedUnit(source.fullName);
    if (unitResult is! ParsedUnitResult) {
      return null;
    }
    var unit = unitResult.unit;
    var nodeLocator = NodeLocator(reference.range.offset);
    var node = nodeLocator.searchWithin(unit);
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is InterpolationExpression && parent.rightBracket == null) {
        return node;
      }
    }
    return null;
  }
}
