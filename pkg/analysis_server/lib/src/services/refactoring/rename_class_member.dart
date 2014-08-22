// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_class_member;

import 'dart:async';

import 'package:analysis_server/src/protocol2.dart' show Location, SourceEdit;
import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';


/**
 * A [Refactoring] for renaming class member [Element]s.
 */
class RenameClassMemberRefactoringImpl extends RenameRefactoringImpl {
  _RenameClassMemberValidator _validator;

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
        new _RenameClassMemberValidator(searchEngine, element, newName);
    return _validator.validate();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() {
    RefactoringStatus result = new RefactoringStatus();
    if (element is MethodElement && (element as MethodElement).isOperator) {
      result.addFatalError('Cannot rename operator.');
    }
    return new Future.value(result);
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    if (element is FieldElement) {
      FieldElement fieldElement = element as FieldElement;
      if (fieldElement.isStatic && fieldElement.isConst) {
        result.addStatus(validateConstantName(newName));
      } else {
        result.addStatus(validateFieldName(newName));
      }
    }
    if (element is MethodElement) {
      result.addStatus(validateMethodName(newName));
    }
    return result;
  }

  @override
  Future<Change> createChange() {
    Change change = new Change(refactoringName);
    // update declarations
    for (Element renameElement in _validator.elements) {
      if (renameElement.isSynthetic && renameElement is FieldElement) {
        addDeclarationEdit(change, renameElement.getter);
        addDeclarationEdit(change, renameElement.setter);
      } else {
        addDeclarationEdit(change, renameElement);
      }
    }
    // update references
    List<SourceReference> references =
        getSourceReferences(_validator.references);
    for (SourceReference reference in references) {
      addReferenceEdit(change, reference);
    }
    // potential matches
    return searchEngine.searchMemberReferences(oldName).then((nameMatches) {
      List<SourceReference> nameRefs = getSourceReferences(nameMatches);
      for (SourceReference reference in nameRefs) {
        // ignore resolved reference, we have already updated it
        if (reference.isResolved) {
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
        SourceEdit edit =
            createReferenceEdit(reference, newName, id: _newPotentialId());
        change.addEdit(reference.file, edit);
      }
    }).then((_) => change);
  }

  String _newPotentialId() {
    String id = potentialEditIds.length.toString();
    potentialEditIds.add(id);
    return id;
  }
}


/**
 * Helper to check if renaming of an [Element] to the given name will cause any
 * problems.
 */
class _RenameClassMemberValidator {
  final SearchEngine searchEngine;
  final Element element;
  final String oldName;
  final String newName;

  Set<Element> elements = new Set();
  List<SearchMatch> references = [];

  _RenameClassMemberValidator(this.searchEngine, Element element, this.newName)
      : element = element,
        oldName = element.displayName;

  Future<RefactoringStatus> validate() {
    RefactoringStatus result = new RefactoringStatus();
    ClassElement elementClass = element.enclosingElement;
    // check if there is a member with "newName" in the same ClassElement
    for (Element newNameMember in getChildren(elementClass, newName)) {
      result.addError(
          format(
              "Class '{0}' already declares {1} with name '{2}'.",
              elementClass.displayName,
              getElementKindName(newNameMember),
              newName),
          new Location.fromElement(newNameMember));
    }
    // do chained computations
    Set<ClassElement> superClasses = getSuperClasses(elementClass);
    Set<ClassElement> subClasses;
    return _prepareReferences().then((_) {
      return getSubClasses(searchEngine, elementClass).then((_subs) {
        subClasses = _subs;
      });
    }).then((_) {
      // check shadowing in hierarchy
      return searchEngine.searchElementDeclarations(newName).then((decls) {
        for (SearchMatch decl in decls) {
          Element nameElement = getSyntheticAccessorVariable(decl.element);
          Element nameClass = nameElement.enclosingElement;
          // renamed Element shadows member of superclass
          if (superClasses.contains(nameClass)) {
            result.addError(
                format(
                    "Renamed {0} will shadow {1} '{2}'.",
                    getElementKindName(element),
                    getElementKindName(nameElement),
                    getElementQualifiedName(nameElement)),
                new Location.fromElement(nameElement));
          }
          // renamed Element is shadowed by member of subclass
          if (subClasses.contains(nameClass)) {
            result.addError(
                format(
                    "Renamed {0} will be shadowed by {1} '{2}'.",
                    getElementKindName(element),
                    getElementKindName(nameElement),
                    getElementQualifiedName(nameElement)),
                new Location.fromElement(nameElement));
          }
          // renamed Element is shadowed by local
          if (nameElement is LocalElement) {
            LocalElement localElement = nameElement;
            ClassElement enclosingClass =
                nameElement.getAncestor((element) => element is ClassElement);
            if (enclosingClass == elementClass ||
                subClasses.contains(enclosingClass)) {
              for (SearchMatch reference in references) {
                if (isReferenceInLocalRange(localElement, reference)) {
                  result.addError(
                      format(
                          "Usage of renamed {0} will be shadowed by {1} '{2}'.",
                          getElementKindName(element),
                          getElementKindName(localElement),
                          localElement.displayName),
                      new Location.fromMatch(reference));
                }
              }
            }
          }
        }
      });
    }).then((_) => result);
  }

  /**
   * Fills [elements] with [Element]s to rename.
   */
  Future _prepareElements() {
    if (element is ClassMemberElement) {
      return getHierarchyMembers(
          searchEngine,
          element).then((Set<Element> elements) {
        this.elements = elements;
      });
    } else {
      elements = new Set.from([element]);
      return new Future.value();
    }
  }

  /**
   * Fills [references] with all references to [elements].
   */
  Future _prepareReferences() {
    return _prepareElements().then((_) {
      return Future.forEach(elements, (Element element) {
        return searchEngine.searchReferences(element).then((references) {
          this.references.addAll(references);
        });
      });
    });
  }
}
