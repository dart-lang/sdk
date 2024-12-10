// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/protocol_server.dart'
    show newLocation_fromElement2, newLocation_fromMatch;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server/src/services/search/element_visitors.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart' show Identifier;
import 'package:analyzer/dart/element/element2.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/utilities/extensions/flutter.dart';

/// Checks if creating a top-level function with the given [name] in [library]
/// will cause any conflicts.
Future<RefactoringStatus> validateCreateFunction(
  SearchEngine searchEngine,
  LibraryElement2 library,
  String name,
) {
  return _CreateUnitMemberValidator(
    searchEngine,
    library,
    ElementKind.FUNCTION,
    name,
  ).validate();
}

/// Checks if creating a top-level function with the given [name] in [element]
/// will cause any conflicts.
Future<RefactoringStatus> validateRenameTopLevel(
  SearchEngine searchEngine,
  Element2 element,
  String name,
) {
  return _RenameUnitMemberValidator(searchEngine, element, name).validate();
}

/// A [Refactoring] for renaming compilation unit member [Element]s.
class RenameUnitMemberRefactoringImpl extends RenameRefactoringImpl {
  final ResolvedUnitResult resolvedUnit;

  /// If the [element] is a Flutter `StatefulWidget` declaration, this is the
  /// corresponding `State` declaration.
  ClassElement2? _flutterWidgetState;

  /// If [_flutterWidgetState] is set, this is the new name of it.
  String? _flutterWidgetStateNewName;

  RenameUnitMemberRefactoringImpl(
    super.workspace,
    super.sessionHelper,
    this.resolvedUnit,
    super.element,
  ) : super.c2();

  @override
  String get refactoringName {
    if (element2 is ExtensionElement2) {
      return 'Rename Extension';
    }
    if (element2 is ExtensionTypeElement2) {
      return 'Rename Extension Type';
    }
    if (element2 is TopLevelFunctionElement) {
      return 'Rename Top-Level Function';
    }
    if (element2 is TopLevelVariableElement2) {
      return 'Rename Top-Level Variable';
    }
    if (element2 is TypeAliasElement2) {
      return 'Rename Type Alias';
    }
    return 'Rename Class';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() async {
    var status = await validateRenameTopLevel(searchEngine, element2, newName);
    var flutterWidgetState = _flutterWidgetState;
    var flutterWidgetStateNewName = _flutterWidgetStateNewName;
    if (flutterWidgetState != null && flutterWidgetStateNewName != null) {
      _updateFlutterWidgetStateName();
      status.addStatus(
        await validateRenameTopLevel(
          searchEngine,
          flutterWidgetState,
          flutterWidgetStateNewName,
        ),
      );
    }
    return status;
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    _findFlutterStateClass();
    return super.checkInitialConditions();
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    if (element2 is ExtensionTypeElement2) {
      result.addStatus(validateExtensionTypeName(newName));
    }
    if (element2 is TopLevelFunctionElement) {
      result.addStatus(validateFunctionName(newName));
    }
    if (element2 is InterfaceElement2) {
      result.addStatus(validateClassName(newName));
    }
    if (element2 is TopLevelVariableElement2) {
      result.addStatus(validateVariableName(newName));
    }
    if (element2 is TypeAliasElement2) {
      result.addStatus(validateTypeAliasName(newName));
    }
    return result;
  }

  @override
  Future<void> fillChange() async {
    // prepare elements
    var elements = <Element2>[];
    if (element2 is PropertyInducingElement2 && element2.isSynthetic) {
      var property = element2 as PropertyInducingElement2;
      var getter = property.getter2;
      var setter = property.setter2;
      if (getter != null) {
        elements.add(getter);
      }
      if (setter != null) {
        elements.add(setter);
      }
    } else {
      elements.add(element2);
    }

    // Rename each element and references to it.
    var processor = RenameProcessor(workspace, sessionHelper, change, newName);
    for (var element in elements) {
      await processor.renameElement2(element);
    }

    // If a StatefulWidget is being renamed, rename also its State.
    var flutterWidgetState = _flutterWidgetState;
    if (flutterWidgetState != null) {
      _updateFlutterWidgetStateName();
      await RenameProcessor(
        workspace,
        sessionHelper,
        change,
        _flutterWidgetStateNewName!,
      ).renameElement2(flutterWidgetState);
    }
  }

  void _findFlutterStateClass() {
    var element = element2;
    if (element is ClassElement2 && element.isStatefulWidgetDeclaration) {
      var oldStateName = '${oldName}State';
      var library = element.library2;
      _flutterWidgetState =
          library.getClass2(oldStateName) ??
          library.getClass2('_$oldStateName');
    }
  }

  void _updateFlutterWidgetStateName() {
    var flutterWidgetState = _flutterWidgetState;
    if (flutterWidgetState != null) {
      var flutterWidgetStateNewName = '${newName}State';
      // If the State was private, ensure that it stays private.
      if (flutterWidgetState.name3!.startsWith('_') &&
          !flutterWidgetStateNewName.startsWith('_')) {
        flutterWidgetStateNewName = '_$flutterWidgetStateNewName';
      }
      _flutterWidgetStateNewName = flutterWidgetStateNewName;
    }
  }
}

/// The base class for the create and rename validators.
class _BaseUnitMemberValidator {
  final SearchEngine searchEngine;
  final LibraryElement2 library;
  final ElementKind elementKind;
  final String name;

  final RefactoringStatus result = RefactoringStatus();

  _BaseUnitMemberValidator(
    this.searchEngine,
    this.library,
    this.elementKind,
    this.name,
  );

  /// Returns `true` if [element] is visible at the given [SearchMatch].
  bool _isVisibleAt(Element2 element, SearchMatch at) {
    var atLibrary = at.element2.library2!;
    // may be the same library
    if (library == atLibrary) {
      return true;
    }
    // check imports
    // TODO(enhanced-parts): This needs to look at the set of imports for the
    //  library fragment in which the reference occurs.
    for (var libraryImport in atLibrary.firstFragment.libraryImports2) {
      // ignore if imported with prefix
      if (libraryImport.prefix2 != null) {
        continue;
      }
      // check imported elements
      if (libraryImport.namespace.definedNames2.containsValue(element)) {
        return true;
      }
    }
    // no, it is not visible
    return false;
  }

  /// Validates if an element with the [name] will conflict with another
  /// top-level [Element] in the same library.
  void _validateWillConflict() {
    for (var element in library.children2) {
      if (hasDisplayName(element, name)) {
        var message = format(
          "Library already declares {0} with name '{1}'.",
          getElementKindName(element),
          name,
        );
        result.addError(message, newLocation_fromElement2(element));
      }
    }
  }

  /// Validates if renamed [element] will shadow any [Element] named [name].
  Future<void> _validateWillShadow(Element2? element) async {
    var declarations = await searchEngine.searchMemberDeclarations(name);
    for (var declaration in declarations) {
      var member = declaration.element2;
      var declaringClass = member.enclosingElement2 as InterfaceElement2;
      var memberReferences = await searchEngine.searchReferences2(member);
      for (var memberReference in memberReferences) {
        var refElement = memberReference.element2;
        // cannot be shadowed if qualified
        if (memberReference.isQualified) {
          continue;
        }
        // cannot be shadowed if declared in the same class as reference
        var refClass = refElement.thisOrAncestorOfType2<InterfaceElement2>();
        if (refClass == declaringClass) {
          continue;
        }
        // ignore if not visible
        if (element != null && !_isVisibleAt(element, memberReference)) {
          continue;
        }
        // OK, reference will be shadowed be the element being renamed
        var message = format(
          element != null
              ? "Renamed {0} will shadow {1} '{2}'."
              : "Created {0} will shadow {1} '{2}'.",
          elementKind.displayName,
          getElementKindName(member),
          getElementQualifiedName(member),
        );
        result.addError(message, newLocation_fromMatch(memberReference));
      }
    }
  }
}

/// Helper to check if the created element will cause any conflicts.
class _CreateUnitMemberValidator extends _BaseUnitMemberValidator {
  _CreateUnitMemberValidator(
    super.searchEngine,
    super.library,
    super.elementKind,
    super.name,
  );

  Future<RefactoringStatus> validate() async {
    _validateWillConflict();
    await _validateWillShadow(null);
    return result;
  }
}

/// Helper to check if the renamed element will cause any conflicts.
class _RenameUnitMemberValidator extends _BaseUnitMemberValidator {
  final Element2 element;
  List<SearchMatch> references = <SearchMatch>[];

  _RenameUnitMemberValidator(
    SearchEngine searchEngine,
    this.element,
    String name,
  ) : super(searchEngine, element.library2!, element.kind, name);

  Future<RefactoringStatus> validate() async {
    _validateWillConflict();
    references = await searchEngine.searchReferences2(element);
    _validateWillBeInvisible();
    _validateWillBeShadowed();
    await _validateWillShadow(element);
    return result;
  }

  /// Validates if any usage of [element] renamed to [name] will be invisible.
  void _validateWillBeInvisible() {
    if (!Identifier.isPrivateName(name)) {
      return;
    }
    for (var reference in references) {
      var refElement = reference.element2;
      var refLibrary = refElement.library2!;
      if (refLibrary != library) {
        var message = format(
          "Renamed {0} will be invisible in '{1}'.",
          getElementKindName(element),
          getElementQualifiedName(refLibrary),
        );
        result.addError(message, newLocation_fromMatch(reference));
      }
    }
  }

  /// Validates if any usage of [element] renamed to [name] will be shadowed.
  void _validateWillBeShadowed() {
    for (var reference in references) {
      var refElement = reference.element2;
      var refClass = refElement.thisOrAncestorOfType2<InterfaceElement2>();
      if (refClass != null) {
        visitChildren2(refClass, (shadow) {
          if (hasDisplayName(shadow, name)) {
            var message = format(
              "Reference to renamed {0} will be shadowed by {1} '{2}'.",
              getElementKindName(element),
              getElementKindName(shadow),
              getElementQualifiedName(shadow),
            );
            result.addError(message, newLocation_fromElement2(shadow));
          }
          return false;
        });
      }
    }
  }
}
