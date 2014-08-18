// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.src.refactoring.rename_unit_member;

import 'dart:async';

import 'package:analysis_server/src/services/correction/change.dart';
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/refactoring/refactoring.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/rename.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analysis_server/src/services/search/element_visitors.dart';


/**
 * A [Refactoring] for renaming compilation unit member [Element]s.
 */
class RenameUnitMemberRefactoringImpl extends RenameRefactoringImpl {
  RenameUnitMemberRefactoringImpl(SearchEngine searchEngine, Element element)
      : super(searchEngine, element);

  @override
  String get refactoringName {
    if (element is FunctionElement) {
      return "Rename Top-Level Function";
    }
    if (element is FunctionTypeAliasElement) {
      return "Rename Function Type Alias";
    }
    if (element is TopLevelVariableElement) {
      return "Rename Top-Level Variable";
    }
    return "Rename Class";
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    return new RenameUnitMemberValidator(
        searchEngine,
        element,
        element.kind,
        newName,
        true).validate();
  }

  @override
  RefactoringStatus checkNewName() {
    RefactoringStatus result = super.checkNewName();
    if (element is TopLevelVariableElement) {
      TopLevelVariableElement variable = element as TopLevelVariableElement;
      if (variable.isConst) {
        result.addStatus(validateConstantName(newName));
      } else {
        result.addStatus(validateVariableName(newName));
      }
    }
    if (element is FunctionElement) {
      result.addStatus(validateFunctionName(newName));
    }
    if (element is FunctionTypeAliasElement) {
      result.addStatus(validateFunctionTypeAliasName(newName));
    }
    if (element is ClassElement) {
      result.addStatus(validateClassName(newName));
    }
    return result;
  }

  @override
  Future<Change> createChange() {
    Change change = new Change(refactoringName);
    // prepare elements
    List<Element> elements = [];
    if (element is PropertyInducingElement && element.isSynthetic) {
      PropertyInducingElement property = element as PropertyInducingElement;
      PropertyAccessorElement getter = property.getter;
      PropertyAccessorElement setter = property.setter;
      if (getter != null) {
        elements.add(getter);
      }
      if (setter != null) {
        elements.add(setter);
      }
    } else {
      elements.add(element);
    }
    // update each element
    return Future.forEach(elements, (Element element) {
      // update declaration
      addDeclarationEdit(change, element);
      // schedule updating references
      return searchEngine.searchReferences(element).then((refMatches) {
        List<SourceReference> references = getSourceReferences(refMatches);
        for (SourceReference reference in references) {
          addReferenceEdit(change, reference);
        }
      });
    }).then((_) {
      return change;
    });
  }
}


/**
 * Helper to check if renaming or creating [Element] with given name will cause any problems.
 */
class RenameUnitMemberValidator {
  final SearchEngine searchEngine;
  final Element element;
  final ElementKind elementKind;
  final String newName;
  final bool forRename;

  final RefactoringStatus result = new RefactoringStatus();

  RenameUnitMemberValidator(this.searchEngine, this.element, this.elementKind,
      this.newName, this.forRename);

  Future<RefactoringStatus> validate() {
    _validateWillConflict();
    List<Future> futures = <Future>[];
    if (forRename) {
      futures.add(_validateWillBeShadowed());
    }
    futures.add(_validateWillShadow());
    return Future.wait(futures).then((_) {
      return result;
    });
  }

  /**
   * Returns `true` if [element] is visible at the given [SearchMatch].
   */
  bool _isVisibleAt(Element element, SearchMatch at) {
    LibraryElement library = at.element.library;
    // may be the same library
    if (element.library == library) {
      return true;
    }
    // check imports
    for (ImportElement importElement in library.imports) {
      // ignore if imported with prefix
      if (importElement.prefix != null) {
        continue;
      }
      // check imported elements
      if (getImportNamespace(importElement).containsValue(element)) {
        return true;
      }
    }
    // no, it is not visible
    return false;
  }

  /**
   * Validates if any usage of [element] renamed to [newName] will be shadowed.
   */
  Future _validateWillBeShadowed() {
    return searchEngine.searchReferences(element).then((references) {
      for (SearchMatch reference in references) {
        Element refElement = reference.element;
        ClassElement refClass =
            refElement.getAncestor((e) => e is ClassElement);
        if (refClass != null) {
          visitChildren(refClass, (shadow) {
            if (hasDisplayName(shadow, newName)) {
              String message =
                  format(
                      "Reference to renamed {0} will be shadowed by {1} '{2}'.",
                      getElementKindName(element),
                      getElementKindName(shadow),
                      getElementQualifiedName(shadow));
              result.addError(
                  message,
                  new RefactoringStatusContext.forElement(shadow));
            }
          });
        }
      }
    });
  }

  /**
   * Validates if [element] renamed to [newName] will conflict with another
   * top-level [Element] in the same library.
   */
  void _validateWillConflict() {
    LibraryElement library = element.getAncestor((e) => e is LibraryElement);
    visitLibraryTopLevelElements(library, (element) {
      if (hasDisplayName(element, newName)) {
        String message =
            format(
                "Library already declares {0} with name '{1}'.",
                getElementKindName(element),
                newName);
        result.addError(
            message,
            new RefactoringStatusContext.forElement(element));
      }
    });
  }

  /**
   * Validates if renamed [element] will shadow any [Element] named [newName].
   */
  Future _validateWillShadow() {
    return searchEngine.searchMemberDeclarations(newName).then((declarations) {
      return Future.forEach(declarations, (SearchMatch declaration) {
        Element member = declaration.element;
        ClassElement declaringClass = member.enclosingElement;
        return searchEngine.searchReferences(member).then((memberReferences) {
          for (SearchMatch memberReference in memberReferences) {
            Element refElement = memberReference.element;
            // cannot be shadowed if qualified
            if (memberReference.isQualified) {
              continue;
            }
            // cannot be shadowed if declared in the same class as reference
            ClassElement refClass =
                refElement.getAncestor((e) => e is ClassElement);
            if (refClass == declaringClass) {
              continue;
            }
            // ignore if not visitble
            if (!_isVisibleAt(element, memberReference)) {
              continue;
            }
            // OK, reference will be shadowed be the element being renamed
            String message =
                format(
                    forRename ?
                        "Renamed {0} will shadow {1} '{2}'." :
                        "Created {0} will shadow {1} '{2}'.",
                    getElementKindName(element),
                    getElementKindName(member),
                    getElementQualifiedName(member));
            result.addError(
                message,
                new RefactoringStatusContext.forMatch(memberReference));
          }
        });
      });
    });
  }
}
