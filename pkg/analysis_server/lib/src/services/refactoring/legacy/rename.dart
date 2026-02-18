// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analysis_server/src/protocol_server.dart' hide Element;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/code_style_options.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/utilities/extensions/element.dart';
import 'package:analyzer_plugin/utilities/range_factory.dart';

/// Helper for renaming one or more elements.
class RenameProcessor {
  final RefactoringWorkspace workspace;
  final AnalysisSessionHelper sessionHelper;
  final SourceChange change;
  final String newName;

  RenameProcessor(
    this.workspace,
    this.sessionHelper,
    this.change,
    this.newName,
  );

  /// Add the edit that updates the [element] declaration.
  void addDeclarationEdit(Element? element) {
    if (element == null) {
      return;
    } else if (element is LibraryElementImpl) {
      // TODO(brianwilkerson): Consider adding public API to get the offset and
      //  length of the library's name.
      var nameRange = range.startOffsetLength(
        element.nameOffset,
        element.nameLength,
      );
      var edit = newSourceEdit_range(nameRange, newName);
      doSourceChange_addFragmentEdit(change, element.firstFragment, edit);
    } else if (workspace.containsElement(element)) {
      Fragment? fragment = element.firstFragment;
      SourceRange? nameRange;
      var replacement = newName;
      var supportsPrivateNamedParameters =
          element.library?.featureSet.isEnabled(
            Feature.private_named_parameters,
          ) ??
          false;
      while (fragment != null) {
        switch (fragment) {
          case FieldFormalParameterFragment(:var privateName?)
              when supportsPrivateNamedParameters:
            // A private named parameter's element has the public name ("foo"),
            // but the identifier we are renaming is the original private name
            // ("_foo"). In that case, use the private name so that we have the
            // correct length including the underscore.
            nameRange = range.startOffsetLength(
              fragment.nameOffset!,
              privateName.length,
            );

          case SuperFormalParameterFragment()
              when supportsPrivateNamedParameters &&
                  fragment.element.isNamed &&
                  newName.startsWith('_'):
            // A super parameter works more like a named *argument* than a
            // named parameter. If the corresponding parameter in the
            // supertype is named and private, then refer to it by its public
            // name in the super parameter.
            nameRange = range.fragmentName(fragment);
            replacement = correspondingPublicName(newName) ?? newName;
          default:
            nameRange = range.fragmentName(fragment);
        }

        if (nameRange != null) {
          var edit = newSourceEdit_range(nameRange, replacement);
          doSourceChange_addFragmentEdit(change, fragment, edit);
        }

        fragment = fragment.nextFragment;
      }
    }
  }

  /// Add edits that update [matches].
  void addReferenceEdits(List<SearchMatch> matches) {
    var references = getSourceReferences(matches);
    for (var reference in references) {
      if (!workspace.containsElement(reference.element)) {
        continue;
      }
      reference.addEdit(change, newName);
    }
  }

  /// Update the [element] declaration and references to it.
  Future<void> renameElement(Element element) async {
    addDeclarationEdit(element);
    var matches = await workspace.searchEngine.searchReferences(element);
    addReferenceEdits(matches);
  }

  /// Add an edit that replaces the specified region with [code].
  /// Uses [referenceElement] to identify the file to update.
  void replace({
    required Element referenceElement,
    required int offset,
    required int length,
    required String code,
  }) {
    var edit = SourceEdit(offset, length, code);
    doSourceChange_addFragmentEdit(
      change,
      referenceElement.firstFragment,
      edit,
    );
  }
}

/// An abstract implementation of [RenameRefactoring].
abstract class RenameRefactoringImpl extends RefactoringImpl
    implements RenameRefactoring {
  final RefactoringWorkspace workspace;
  final AnalysisSessionHelper sessionHelper;
  final SearchEngine searchEngine;
  final Element _element;
  @override
  final String elementKindName;
  @override
  final String oldName;
  late SourceChange change;

  late String newName;

  RenameRefactoringImpl(this.workspace, this.sessionHelper, Element element)
    : searchEngine = workspace.searchEngine,
      _element = element,
      elementKindName = element.kind.displayName,
      oldName = _getOldName(element);

  Element get element => _element;

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    var result = RefactoringStatus();
    if (element.library?.isInSdk == true) {
      var message = formatList(
        "The {0} '{1}' is defined in the SDK, so cannot be renamed.",
        [getElementKindName(element), getElementQualifiedName(element)],
      );
      result.addFatalError(message);
    }
    if (!workspace.containsElement(element)) {
      var message = formatList(
        "The {0} '{1}' is defined outside of the project, so cannot be renamed.",
        [getElementKindName(element), getElementQualifiedName(element)],
      );
      result.addFatalError(message);
    }
    return Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    var result = RefactoringStatus();
    if (newName == oldName) {
      result.addFatalError(
        'The new name must be different than the current name.',
      );
    }
    return result;
  }

  @override
  Future<SourceChange> createChange() async {
    var changeName = "$refactoringName '$oldName' to '$newName'";
    change = SourceChange(changeName);
    await fillChange();
    return change;
  }

  /// Adds individual edits to [change].
  Future<void> fillChange();

  CodeStyleOptions getCodeStyleOptions(File file) => sessionHelper
      .session
      .analysisContext
      .getAnalysisOptionsForFile(file)
      .codeStyleOptions;

  static String _getOldName(Element element) {
    if (element is ConstructorElement) {
      var name = element.name;
      if (name == null || name == 'new') {
        return '';
      }
      return name;
    } else if (element is MockLibraryImportElement) {
      var prefix = element.import.prefix?.element;
      if (prefix != null) {
        return prefix.displayName;
      }
      return '';
    }
    return element.displayName;
  }
}
