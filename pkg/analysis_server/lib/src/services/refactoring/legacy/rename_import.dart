// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [LibraryImport]s.
class RenameImportRefactoringImpl extends RenameRefactoringImpl {
  final MockLibraryImportElement importElement;

  factory RenameImportRefactoringImpl(
    RefactoringWorkspace workspace,
    AnalysisSessionHelper sessionHelper,
    LibraryImport import,
  ) {
    var element2 = MockLibraryImportElement(import);
    return RenameImportRefactoringImpl._(
      workspace,
      sessionHelper,
      element2,
      element2,
    );
  }

  RenameImportRefactoringImpl._(
    super.workspace,
    super.sessionHelper,
    super.element,
    this.importElement,
  ) : super();

  @override
  MockLibraryImportElement get element => importElement;

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
        doSourceChange_addSourceEdit(
          change,
          element.libraryFragment.source,
          edit,
        );
      }
    }
    // update references
    var references = await searchEngine.searchLibraryImportReferences(
      element.import,
    );
    for (var reference in references) {
      if (newName.isEmpty) {
        doSourceChange_addSourceEdit(
          change,
          reference.libraryFragment.source,
          newSourceEdit_range(reference.range, ''),
        );
      } else {
        var identifier = await _getInterpolationIdentifier(reference);
        if (identifier != null) {
          doSourceChange_addFragmentEdit(
            change,
            reference.libraryFragment,
            SourceEdit(
              identifier.offset,
              identifier.length,
              '{$newName.${identifier.name}}',
            ),
          );
        } else {
          doSourceChange_addSourceEdit(
            change,
            reference.libraryFragment.source,
            newSourceEdit_range(reference.range, '$newName.'),
          );
        }
      }
    }
  }

  /// Return the [ImportDirective] node that corresponds to the element.
  Future<ImportDirective?> _findNode() async {
    var libraryFragment = element.libraryFragment;
    var path = libraryFragment.source.fullName;
    var unitResult = sessionHelper.session.getParsedUnit(path);
    if (unitResult is! ParsedUnitResult) {
      return null;
    }
    var unit = unitResult.unit;
    var index = libraryFragment.libraryImports.indexOf(element.import);
    return unit.directives.whereType<ImportDirective>().elementAt(index);
  }

  /// If the given [reference] is before an interpolated [SimpleIdentifier] in
  /// an [InterpolationExpression] without surrounding curly brackets, return
  /// it. Otherwise return `null`.
  Future<SimpleIdentifier?> _getInterpolationIdentifier(
    LibraryFragmentSearchMatch reference,
  ) async {
    var source = reference.libraryFragment.source;
    var unitResult = sessionHelper.session.getParsedUnit(source.fullName);
    if (unitResult is! ParsedUnitResult) {
      return null;
    }
    var node = unitResult.unit.nodeCovering(offset: reference.range.offset);
    if (node is SimpleIdentifier) {
      var parent = node.parent;
      if (parent is InterpolationExpression && parent.rightBracket == null) {
        return node;
      }
    }
    return null;
  }
}
