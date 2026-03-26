// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server_plugin/edit/correction_utils.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/utilities/change_builder/change_builder_core.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [LibraryImport]s.
class RenameImportRefactoringImpl extends RenameRefactoringImpl {
  final ResolvedUnitResult resolvedUnit;

  final CorrectionUtils utils;

  final MockLibraryImportElement importElement;

  factory RenameImportRefactoringImpl(
    RefactoringWorkspace workspace,
    AnalysisSessionHelper sessionHelper,
    ResolvedUnitResult resolvedUnit,
    LibraryImport import,
  ) {
    var element2 = MockLibraryImportElement(import);
    return RenameImportRefactoringImpl._(
      workspace,
      sessionHelper,
      element2,
      element2,
      resolvedUnit,
      CorrectionUtils(resolvedUnit),
    );
  }

  RenameImportRefactoringImpl._(
    super.workspace,
    super.sessionHelper,
    super.element,
    this.importElement,
    this.resolvedUnit,
    this.utils,
  ) : super();

  @override
  MockLibraryImportElement get element => importElement;

  @override
  String get refactoringName {
    return 'Rename Import Prefix';
  }

  Future<void> buildChange({required ChangeBuilder builder}) async {
    // Update the declaration.
    var node = await _findNode();
    if (node == null) {
      return;
    }

    var prefixNode = node.prefix;
    var libraryPath = element.libraryFragment.source.fullName;
    if (newName.isEmpty) {
      // We shouldn't get `prefix == null` because we check in `checkNewName`
      // that the new name is different.
      if (prefixNode != null) {
        var uriEnd = node.uri.end;
        var prefixEnd = prefixNode.end;
        await builder.addDartFileEdit(libraryPath, (builder) {
          builder.addDeletion(range.startOffsetEndOffset(uriEnd, prefixEnd));
        });
      }
    } else {
      await builder.addDartFileEdit(libraryPath, (builder) {
        if (prefixNode == null) {
          builder.addSimpleInsertion(node.uri.end, ' as $newName');
        } else {
          builder.addSimpleReplacement(range.node(prefixNode), newName);
        }
      });
    }

    // Update the references.
    var references = await searchEngine.searchLibraryImportReferences(
      element.import,
    );
    for (var reference in references) {
      var fragmentPath = reference.libraryFragment.source.fullName;
      if (newName.isEmpty) {
        await builder.addDartFileEdit(fragmentPath, (builder) {
          builder.addDeletion(reference.range);
        });
      } else {
        var identifier = await _getInterpolationIdentifier(reference);
        if (identifier != null) {
          await builder.addDartFileEdit(fragmentPath, (builder) {
            builder.addSimpleReplacement(
              range.node(identifier),
              '{$newName.${identifier.name}}',
            );
          });
        } else {
          await builder.addDartFileEdit(fragmentPath, (builder) {
            builder.addSimpleReplacement(reference.range, '$newName.');
          });
        }
      }
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
    result.addStatus(validateImportPrefixName(newName));
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
