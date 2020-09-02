// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// A [Refactoring] for renaming [ImportElement]s.
class RenameImportRefactoringImpl extends RenameRefactoringImpl {
  final AnalysisSession session;

  RenameImportRefactoringImpl(
      RefactoringWorkspace workspace, this.session, ImportElement element)
      : super(workspace, element);

  @override
  ImportElement get element => super.element as ImportElement;

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
      var prefix = element.prefix;
      SourceEdit edit;
      if (newName.isEmpty) {
        var node = _findNode();
        var uriEnd = node.uri.end;
        var prefixEnd = element.prefixOffset + prefix.nameLength;
        edit = newSourceEdit_range(
            range.startOffsetEndOffset(uriEnd, prefixEnd), '');
      } else {
        if (prefix == null) {
          var node = _findNode();
          var uriEnd = node.uri.end;
          edit = newSourceEdit_range(SourceRange(uriEnd, 0), ' as $newName');
        } else {
          var offset = element.prefixOffset;
          var length = prefix.nameLength;
          edit = newSourceEdit_range(SourceRange(offset, length), newName);
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
        var interpolationIdentifier = _getInterpolationIdentifier(reference);
        if (interpolationIdentifier != null) {
          doSourceChange_addElementEdit(
              change,
              reference.element,
              SourceEdit(
                  interpolationIdentifier.offset,
                  interpolationIdentifier.length,
                  '{$newName.${interpolationIdentifier.name}}'));
        } else {
          reference.addEdit(change, '$newName.');
        }
      }
    }
  }

  /// Return the [ImportDirective] node that corresponds to the [element].
  ImportDirective _findNode() {
    var library = element.library;
    var path = library.source.fullName;
    var unit = session.getParsedUnit(path).unit;
    var index = library.imports.indexOf(element);
    return unit.directives.whereType<ImportDirective>().elementAt(index);
  }

  /// If the given [reference] is before an interpolated [SimpleIdentifier] in
  /// an [InterpolationExpression] without surrounding curly brackets, return
  /// it. Otherwise return `null`.
  SimpleIdentifier _getInterpolationIdentifier(SourceReference reference) {
    var source = reference.element.source;
    var unit = session.getParsedUnit(source.fullName).unit;
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
