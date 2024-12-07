// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/session.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/util/file_paths.dart';
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
  Future<RefactoringStatus> checkFinalConditions() {
    var result = RefactoringStatus();
    return Future.value(result);
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = _checkInitialConditions();
    return Future.value(result);
  }

  @override
  Future<SourceChange> createChange() async {
    change = SourceChange(refactoringName);
    // function
    if (element.enclosingElement2 is LibraryElement2) {
      await _updateElementDeclaration(element);
      await _updateElementReferences(element);
    }
    // method
    var field = element.variable3;
    if (field is FieldElement2 &&
        (field.enclosingElement2 is InterfaceElement2 ||
            field.enclosingElement2 is ExtensionElement2)) {
      var elements = await getHierarchyMembers(searchEngine, field);
      await Future.forEach(elements, (Element2 member) async {
        if (member is FieldElement2) {
          var getter = member.getter2;
          if (getter != null && !getter.isSynthetic) {
            await _updateElementDeclaration(getter);
            return _updateElementReferences(getter);
          }
        }
      });
    }
    // done
    return change;
  }

  @override
  bool isAvailable() {
    return !_checkElement().hasFatalError;
  }

  /// Checks if [element] is valid to perform this refactor.
  RefactoringStatus _checkElement() {
    if (!workspace.containsElement2(element)) {
      return RefactoringStatus.fatal(
        'Only getters in your workspace can be converted.',
      );
    }

    if (element.isSynthetic) {
      return RefactoringStatus.fatal(
        'Only explicit getters can be converted to methods.',
      );
    }
    return RefactoringStatus();
  }

  RefactoringStatus _checkInitialConditions() {
    return _checkElement();
  }

  Future<void> _updateElementDeclaration(GetterElement element) async {
    // prepare "get" keyword
    Token? getKeyword;
    for (
      GetterFragment? fragment = element.firstFragment;
      fragment != null;
      fragment = fragment.nextFragment as GetterFragment?
    ) {
      var nameRange = range.fragmentName(fragment);
      if (nameRange == null) {
        return;
      }
      var sessionHelper = AnalysisSessionHelper(session);
      var result = await sessionHelper.getElementDeclaration2(fragment);
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
          fragment.nameOffset2!,
        );
        var edit = newSourceEdit_range(getRange, '');
        doSourceChange_addFragmentEdit(change, fragment, edit);
      }
      // add parameters "()"
      var edit = SourceEdit(nameRange.end, 0, '()');
      doSourceChange_addFragmentEdit(change, fragment, edit);
    }
  }

  Future<void> _updateElementReferences(Element2 element) async {
    var matches = await searchEngine.searchReferences2(element);
    var references = getSourceReferences(matches);
    for (var reference in references) {
      // Don't update references in macro-generated files.
      if (isMacroGenerated(reference.file)) continue;
      var refRange = reference.range;
      // insert "()"
      var edit = SourceEdit(refRange.end, 0, '()');
      doSourceChange_addSourceEdit(change, reference.unitSource, edit);
    }
  }
}
