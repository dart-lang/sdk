// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_class_member;

import 'dart:async';

import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/dart/ast/ast.dart' show Identifier;
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/java_core.dart';

/**
 * Checks if creating a method with the given [name] in [classElement] will
 * cause any conflicts.
 */
Future<RefactoringStatus> validateCreateMethod(
    SearchEngine searchEngine, ClassElement classElement, String name) {
  return new _ClassMemberValidator.forCreate(searchEngine, classElement, name)
      .validate();
}

/**
 * A [Refactoring] for renaming class member [Element]s.
 */
class RenameClassMemberRefactoringImpl extends RenameRefactoringImpl {
  _ClassMemberValidator _validator;

  RenameClassMemberRefactoringImpl(SearchEngine searchEngine, Element element)
      : super(searchEngine, element);

  @override
  String get refactoringName {
    if (element is TypeParameterElement) {
      return "Rename Type Parameter";
    }
    if (element is FieldElement) {
      return "Rename Field";
    }
    return "Rename Method";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    _validator =
        new _ClassMemberValidator.forRename(searchEngine, element, newName);
    return _validator.validate();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    RefactoringStatus result = await super.checkInitialConditions();
    if (element is MethodElement && (element as MethodElement).isOperator) {
      result.addFatalError('Cannot rename operator.');
    }
    return new Future<RefactoringStatus>.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    if (element is FieldElement) {
      result.addStatus(validateFieldName(newName));
    }
    if (element is MethodElement) {
      result.addStatus(validateMethodName(newName));
    }
    return result;
  }

  @override
  Future fillChange() async {
    // update declarations
    for (Element renameElement in _validator.elements) {
      if (renameElement.isSynthetic && renameElement is FieldElement) {
        addDeclarationEdit(renameElement.getter);
        addDeclarationEdit(renameElement.setter);
      } else {
        addDeclarationEdit(renameElement);
      }
    }
    // update references
    addReferenceEdits(_validator.references);
    // potential matches
    List<SearchMatch> nameMatches =
        await searchEngine.searchMemberReferences(oldName);
    List<SourceReference> nameRefs = getSourceReferences(nameMatches);
    for (SourceReference reference in nameRefs) {
      // ignore references from SDK and pub cache
      if (isElementInSdkOrPubCache(reference.element)) {
        continue;
      }
      // check the element being renamed is accessible
      {
        LibraryElement whereLibrary = reference.element.library;
        if (!element.isAccessibleIn(whereLibrary)) {
          continue;
        }
      }
      // add edit
      reference.addEdit(change, newName, id: _newPotentialId());
    }
  }

  String _newPotentialId() {
    String id = potentialEditIds.length.toString();
    potentialEditIds.add(id);
    return id;
  }
}

/**
 * Helper to check if the created or renamed [Element] will cause any conflicts.
 */
class _ClassMemberValidator {
  final SearchEngine searchEngine;
  final LibraryElement library;
  final Element element;
  final ClassElement elementClass;
  final ElementKind elementKind;
  final String name;
  final bool isRename;

  final RefactoringStatus result = new RefactoringStatus();
  Set<Element> elements = new Set<Element>();
  List<SearchMatch> references = <SearchMatch>[];

  _ClassMemberValidator.forCreate(
      this.searchEngine, this.elementClass, this.name)
      : isRename = false,
        library = null,
        element = null,
        elementKind = ElementKind.METHOD;

  _ClassMemberValidator.forRename(this.searchEngine, Element element, this.name)
      : isRename = true,
        library = element.library,
        element = element,
        elementClass = element.enclosingElement,
        elementKind = element.kind;

  Future<RefactoringStatus> validate() async {
    // check if there is a member with "newName" in the same ClassElement
    for (Element newNameMember in getChildren(elementClass, name)) {
      result.addError(
          format(
              "Class '{0}' already declares {1} with name '{2}'.",
              elementClass.displayName,
              getElementKindName(newNameMember),
              name),
          newLocation_fromElement(newNameMember));
    }
    // do chained computations
    Set<ClassElement> superClasses = getSuperClasses(elementClass);
    await _prepareReferences();
    Set<ClassElement> subClasses =
        await searchEngine.searchAllSubtypes(elementClass);
    // check shadowing of class names
    if (element != null) {
      for (Element element in elements) {
        ClassElement clazz = element.enclosingElement;
        if (clazz.name == name) {
          result.addError(
              format(
                  "Renamed {0} has the same name as the declaring class '{1}'.",
                  elementKind.displayName,
                  name),
              newLocation_fromElement(element));
        }
      }
    } else {
      if (elementClass.name == name) {
        result.addError(
            format(
                "Created {0} has the same name as the declaring class '{1}'.",
                elementKind.displayName,
                name),
            newLocation_fromElement(elementClass));
      }
    }
    // usage of the renamed Element is shadowed by a local element
    {
      _MatchShadowedByLocal conflict = _getShadowingLocalElement();
      if (conflict != null) {
        LocalElement localElement = conflict.localElement;
        result.addError(
            format(
                "Usage of renamed {0} will be shadowed by {1} '{2}'.",
                elementKind.displayName,
                getElementKindName(localElement),
                localElement.displayName),
            newLocation_fromMatch(conflict.match));
      }
    }
    // check shadowing in the hierarchy
    List<SearchMatch> declarations =
        await searchEngine.searchMemberDeclarations(name);
    for (SearchMatch declaration in declarations) {
      Element nameElement = getSyntheticAccessorVariable(declaration.element);
      Element nameClass = nameElement.enclosingElement;
      // the renamed Element shadows a member of a superclass
      if (superClasses.contains(nameClass)) {
        result.addError(
            format(
                isRename
                    ? "Renamed {0} will shadow {1} '{2}'."
                    : "Created {0} will shadow {1} '{2}'.",
                elementKind.displayName,
                getElementKindName(nameElement),
                getElementQualifiedName(nameElement)),
            newLocation_fromElement(nameElement));
      }
      // the renamed Element is shadowed by a member of a subclass
      if (isRename && subClasses.contains(nameClass)) {
        result.addError(
            format(
                "Renamed {0} will be shadowed by {1} '{2}'.",
                elementKind.displayName,
                getElementKindName(nameElement),
                getElementQualifiedName(nameElement)),
            newLocation_fromElement(nameElement));
      }
    }
    // visibility
    if (isRename) {
      _validateWillBeInvisible();
    }
    // done
    return result;
  }

  _MatchShadowedByLocal _getShadowingLocalElement() {
    for (SearchMatch match in references) {
      // qualified reference cannot be shadowed by a local element
      if (match.isQualified) {
        continue;
      }
      // check local elements of the enclosing executable
      Element containingElement = match.element;
      if (containingElement is ExecutableElement) {
        Iterable<LocalElement> localElements = <Iterable<LocalElement>>[
          containingElement.functions,
          containingElement.localVariables,
          containingElement.parameters
        ].expand((Iterable<LocalElement> x) => x);
        for (LocalElement localElement in localElements) {
          if (localElement.displayName == name &&
              localElement.visibleRange.intersects(match.sourceRange)) {
            return new _MatchShadowedByLocal(match, localElement);
          }
        }
      }
    }
    return null;
  }

  /**
   * Fills [elements] with [Element]s to rename.
   */
  Future _prepareElements() async {
    if (element is ClassMemberElement) {
      elements = await getHierarchyMembers(searchEngine, element);
    } else {
      elements = new Set.from([element]);
    }
  }

  /**
   * Fills [references] with all references to [elements].
   */
  Future _prepareReferences() async {
    if (!isRename) {
      return new Future.value();
    }
    await _prepareElements();
    await Future.forEach(elements, (Element element) async {
      List<SearchMatch> elementReferences =
          await searchEngine.searchReferences(element);
      references.addAll(elementReferences);
    });
  }

  /**
   * Validates if any usage of [element] renamed to [name] will be invisible.
   */
  void _validateWillBeInvisible() {
    if (!Identifier.isPrivateName(name)) {
      return;
    }
    for (SearchMatch reference in references) {
      Element refElement = reference.element;
      LibraryElement refLibrary = refElement.library;
      if (refLibrary != library) {
        String message = format("Renamed {0} will be invisible in '{1}'.",
            getElementKindName(element), getElementQualifiedName(refLibrary));
        result.addError(message, newLocation_fromMatch(reference));
      }
    }
  }
}

class _MatchShadowedByLocal {
  final SearchMatch match;
  final LocalElement localElement;

  _MatchShadowedByLocal(this.match, this.localElement);
}
