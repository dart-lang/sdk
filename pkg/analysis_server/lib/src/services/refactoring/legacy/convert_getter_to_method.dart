// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// [ConvertMethodToGetterRefactoring] implementation.
class ConvertGetterToMethodRefactoringImpl extends RefactoringImpl
    implements ConvertGetterToMethodRefactoring {
  final RefactoringWorkspace workspace;
  final SearchEngine searchEngine;
  final AnalysisSession session;
  final GetterElement element;

  late SourceChange change;

  ConvertGetterToMethodRefactoringImpl(
    this.workspace,
    this.session,
    this.element,
  ) : searchEngine = workspace.searchEngine;

  @override
  String get refactoringName => 'Convert Getter To Method';

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var result = RefactoringStatus();
    var elements = await _getElements();
    for (var element in elements) {
      var matches = await searchEngine.searchReferences(element);
      var references = getSourceReferences(matches);
      for (var reference in references) {
        if (reference.isReferenceInPatternField) {
          result.addWarning(
            'Will match the method tear-off instead of the result.',
            _getLocation(reference),
          );
        }
      }
    }
    return result;
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = _checkInitialConditions();
    return Future.value(result);
  }

  @override
  Future<SourceChange> createChange() async {
    change = SourceChange(refactoringName);
    var elements = await _getElements();
    for (var element in elements) {
      await _updateElementDeclaration(element);
      await _updateElementReferences(element);
    }
    return change;
  }

  @override
  bool isAvailable() {
    return !_checkElement().hasFatalError;
  }

  /// Checks if [element] is valid to perform this refactor.
  RefactoringStatus _checkElement() {
    if (!workspace.containsElement(element)) {
      return RefactoringStatus.fatal(
        'Only getters in your workspace can be converted.',
      );
    }

    if (!element.isOriginDeclaration) {
      return RefactoringStatus.fatal(
        'Only explicit getters can be converted to methods.',
      );
    }
    return RefactoringStatus();
  }

  RefactoringStatus _checkInitialConditions() {
    return _checkElement();
  }

  Future<List<GetterElement>> _getElements() async {
    var elements = <GetterElement>[];
    // function
    if (element.enclosingElement is LibraryElement) {
      elements.add(element);
    }
    // method
    var field = element.variable;
    if (field is FieldElement) {
      var hierarchyMembers = await getHierarchyMembers(searchEngine, field);
      for (var member in hierarchyMembers) {
        if (member is FieldElement) {
          var getter = member.getter;
          if (getter != null && getter.isOriginDeclaration) {
            elements.add(getter);
          }
        }
      }
    }
    return elements;
  }

  Location? _getLocation(SourceReference reference) {
    var file = reference.file;
    var drivers = workspace.driversContaining(file);
    if (drivers.isEmpty) {
      return null;
    }
    var result = drivers.first.currentSession.getFile(file);
    if (result is FileResult) {
      var lineInfo = result.lineInfo;
      var start = lineInfo.getLocation(reference.range.offset);
      var end = lineInfo.getLocation(reference.range.end);
      return Location(
        file,
        reference.range.offset,
        reference.range.length,
        start.lineNumber,
        start.columnNumber,
        endLine: end.lineNumber,
        endColumn: end.columnNumber,
      );
    }
    return null;
  }

  Future<void> _updateElementDeclaration(GetterElement element) async {
    // prepare "get" keyword
    Token? getKeyword;
    for (
      GetterFragment? fragment = element.firstFragment;
      fragment != null;
      fragment = fragment.nextFragment
    ) {
      var nameRange = range.fragmentName(fragment);
      if (nameRange == null) {
        return;
      }
      var sessionHelper = AnalysisSessionHelper(session);
      var result = await sessionHelper.getFragmentDeclaration(fragment);
      var declaration = result?.node;
      if (declaration is MethodDeclaration) {
        getKeyword = declaration.propertyKeyword;
      } else if (declaration is FunctionDeclaration) {
        getKeyword = declaration.propertyKeyword;
      } else {
        return;
      }
      // remove "get "
      if (getKeyword != null) {
        var getRange = range.startOffsetEndOffset(
          getKeyword.offset,
          fragment.nameOffset!,
        );
        var edit = newSourceEdit_range(getRange, '');
        doSourceChange_addFragmentEdit(change, fragment, edit);
      }
      // add parameters "()"
      var edit = SourceEdit(nameRange.end, 0, '()');
      doSourceChange_addFragmentEdit(change, fragment, edit);
    }
  }

  Future<void> _updateElementReferences(GetterElement element) async {
    var matches = await searchEngine.searchReferences(element);
    var references = getSourceReferences(matches);
    for (var reference in references) {
      if (reference.isReferenceInPatternField) {
        continue;
      }
      var refRange = reference.range;
      // insert "()"
      var edit = SourceEdit(refRange.end, 0, '()');
      doSourceChange_addSourceEdit(change, reference.unitSource, edit);
    }
  }
}
