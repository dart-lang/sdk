// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/scanner/token_impl.dart';
import 'package:analysis_server/src/protocol_server.dart'
    hide Element, ElementKind;
import 'package:analysis_server/src/services/correction/status.dart';
import 'package:analysis_server/src/services/correction/util.dart';
import 'package:analysis_server/src/services/refactoring/legacy/naming_conventions.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring.dart';
import 'package:analysis_server/src/services/refactoring/legacy/refactoring_internal.dart';
import 'package:analysis_server/src/services/refactoring/legacy/rename.dart';
import 'package:analysis_server/src/services/refactoring/legacy/visible_ranges_computer.dart';
import 'package:analysis_server/src/services/search/hierarchy.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analysis_server/src/utilities/strings.dart';
import 'package:analyzer/dart/analysis/features.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/session_helper.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Checks if creating a method with the given [name] in [interfaceElement] will
/// cause any conflicts.
Future<RefactoringStatus> validateCreateMethod(
  SearchEngine searchEngine,
  AnalysisSessionHelper sessionHelper,
  InterfaceElement interfaceElement,
  String name,
) {
  return _CreateClassMemberValidator(
    searchEngine,
    sessionHelper,
    interfaceElement,
    name,
  ).validate();
}

/// A [Refactoring] for renaming class members.
class RenameClassMemberRefactoringImpl extends RenameRefactoringImpl {
  final InterfaceElement interfaceElement;

  late _RenameClassMemberValidator _validator;

  RenameClassMemberRefactoringImpl(
    RefactoringWorkspace workspace,
    AnalysisSessionHelper sessionHelper,
    this.interfaceElement,
    Element element,
  ) : super(workspace, sessionHelper, element);

  @override
  String get refactoringName {
    if (element is TypeParameterElement) {
      return 'Rename Type Parameter';
    } else if (element is FieldElement) {
      return 'Rename Field';
    }
    return 'Rename Method';
  }

  @override
  Future<RefactoringStatus> checkFinalConditions() {
    _validator = _RenameClassMemberValidator(
      searchEngine,
      sessionHelper,
      interfaceElement,
      element,
      newName,
    );
    return _validator.validate();
  }

  @override
  Future<RefactoringStatus> checkInitialConditions() async {
    var result = await super.checkInitialConditions();
    if (element is MethodElement && (element as MethodElement).isOperator) {
      result.addFatalError('Cannot rename operator.');
    }
    return result;
  }

  @override
  RefactoringStatus checkNewName() {
    var result = super.checkNewName();
    if (element is FieldElement) {
      result.addStatus(validateFieldName(newName));
    } else if (element is MethodElement) {
      result.addStatus(validateMethodName(newName));
    }
    return result;
  }

  @override
  Future<void> fillChange() async {
    var processor = RenameProcessor(workspace, sessionHelper, change, newName);
    // update declarations
    for (var renameElement in _validator.elements) {
      if (renameElement is FieldElement && renameElement.isOriginGetterSetter) {
        processor.addDeclarationEdit(renameElement.getter);
        processor.addDeclarationEdit(renameElement.setter);
      } else {
        processor.addDeclarationEdit(renameElement);
      }
    }
    await _updateReferences();
    // potential matches
    if (includePotential) {
      var nameMatches = await searchEngine.searchMemberReferences(oldName);
      var nameRefs = getSourceReferences(nameMatches);
      for (var reference in nameRefs) {
        // ignore references from SDK and pub cache
        if (!workspace.containsElement(reference.element)) {
          continue;
        }
        // check the element being renamed is accessible
        if (!element.isAccessibleIn(reference.libraryElement)) {
          continue;
        }
        // add edit
        reference.addEdit(change, newName, id: _newPotentialId());
      }
    }
  }

  Future<void> _addPrivateNamedFormalParameterEdit(
    SourceReference reference,
    FieldFormalParameterElement element,
  ) async {
    FieldFormalParameterFragment? fragment = element.firstFragment;
    while (fragment != null) {
      var result = await sessionHelper.getFragmentDeclaration(fragment);
      var node = result?.node;
      if (node is! DefaultFormalParameter) return;
      var parameter = node.parameter as FieldFormalParameter;

      var start = parameter.thisKeyword.offset;
      var type = element.type.getDisplayString();
      var edit = SourceEdit(start, parameter.period.end - start, '$type ');
      doSourceChange_addSourceEdit(change, reference.unitSource, edit);

      var constructor = node.thisOrAncestorOfType<ConstructorDeclaration>();
      if (constructor != null) {
        var previous = constructor.separator ?? constructor.parameters;
        var replacement = '$newName = ${parameter.name.lexeme}';
        replacement = constructor.initializers.isEmpty
            ? ' : $replacement'
            : ' $replacement,';
        var edit = SourceEdit(previous.end, 0, replacement);
        doSourceChange_addSourceEdit(change, reference.unitSource, edit);
      }
      fragment = fragment.nextFragment;
    }
  }

  Future<void> _addThisEdit(SourceReference reference, String newName) async {
    reference.addEdit(change, 'this.$newName');
  }

  String _newPotentialId() {
    assert(includePotential);
    var id = potentialEditIds.length.toString();
    potentialEditIds.add(id);
    return id;
  }

  Future<void> _updateReferences() async {
    var references = getSourceReferences(_validator.references);
    var unshadowed = getSourceReferences(
      _validator.unshadowed,
    ).map((r) => r.element);

    for (var reference in references) {
      var element = reference.element;
      if (!workspace.containsElement(element)) {
        continue;
      }

      if (newName.startsWith('_') &&
          element is FieldFormalParameterElement &&
          element.isNamed &&
          !element.supportsPrivateNamedParameters) {
        await _addPrivateNamedFormalParameterEdit(reference, element);
        continue;
      }

      if (element is FormalParameterElement) {
        continue;
      }

      if (!reference.isQualified &&
          unshadowed.contains(reference.element) &&
          reference.element is ExecutableElement) {
        await _addThisEdit(reference, newName);
        continue;
      }

      if (reference.isNamedArgumentReference && newName.startsWith('_')) {
        // The named argument refers to a field whose new name is private.
        // At the callsite, the named argument should use its corresponding
        // public name if there is one. (If they are renaming the field to a
        // private name with no corresponding name, then use the private name
        // at the named argument site so they can see the resulting error and
        // fix it.)
        reference.addEdit(change, correspondingPublicName(newName) ?? newName);
      } else {
        reference.addEdit(change, newName);
      }
    }
  }
}

/// The base class for the create and rename validators.
class _BaseClassMemberValidator {
  final SearchEngine searchEngine;
  final AnalysisSessionHelper sessionHelper;
  final InterfaceElement interfaceElement;
  final ElementKind elementKind;
  final String name;

  final RefactoringStatus result = RefactoringStatus();

  _BaseClassMemberValidator(
    this.searchEngine,
    this.sessionHelper,
    this.interfaceElement,
    this.elementKind,
    this.name,
  );

  LibraryElement get library => interfaceElement.library;

  void _checkClassAlreadyDeclares() {
    // check if there is a member with "newName" in the same ClassElement
    for (var newNameMember in getChildren(interfaceElement, name)) {
      result.addError(
        formatList("{0} '{1}' already declares {2} with name '{3}'.", [
          capitalize(interfaceElement.kind.displayName),
          interfaceElement.displayName,
          getElementKindName(newNameMember),
          name,
        ]),
        newLocation_fromElement(newNameMember),
      );
    }
  }

  Future<void> _checkHierarchy({
    required bool isRename,
    required Set<InterfaceElement> subClasses,
  }) async {
    var superClasses = interfaceElement.allSupertypes
        .map((e) => e.element)
        .toSet();
    // check shadowing in the hierarchy
    var declarations = await searchEngine.searchMemberDeclarations(name);
    for (var declaration in declarations) {
      var nameElement = getSyntheticAccessorVariable(declaration.element);
      var nameClass = nameElement.enclosingElement;
      // the renamed Element shadows a member of a superclass
      if (superClasses.contains(nameClass)) {
        result.addError(
          formatList(
            isRename
                ? "Renamed {0} will shadow {1} '{2}'."
                : "Created {0} will shadow {1} '{2}'.",
            [
              elementKind.displayName,
              getElementKindName(nameElement),
              getElementQualifiedName(nameElement),
            ],
          ),
          newLocation_fromElement(nameElement),
        );
      }
      // the renamed Element is shadowed by a member of a subclass
      if (isRename && subClasses.contains(nameClass)) {
        result.addError(
          formatList("Renamed {0} will be shadowed by {1} '{2}'.", [
            elementKind.displayName,
            getElementKindName(nameElement),
            getElementQualifiedName(nameElement),
          ]),
          newLocation_fromElement(nameElement),
        );
      }
    }
  }
}

/// Helper to check if the created element will cause any conflicts.
class _CreateClassMemberValidator extends _BaseClassMemberValidator {
  _CreateClassMemberValidator(
    SearchEngine searchEngine,
    AnalysisSessionHelper sessionHelper,
    InterfaceElement interfaceElement,
    String name,
  ) : super(
        searchEngine,
        sessionHelper,
        interfaceElement,
        ElementKind.METHOD,
        name,
      );

  Future<RefactoringStatus> validate() async {
    _checkClassAlreadyDeclares();
    // do chained computations
    var subClasses = <InterfaceElement>{};
    await searchEngine.appendAllSubtypes(
      interfaceElement,
      subClasses,
      OperationPerformanceImpl('<root>'),
    );
    // check shadowing of class names
    if (interfaceElement.name == name) {
      result.addError(
        'Created ${elementKind.displayName} has the same name as the '
        "declaring ${interfaceElement.kind.displayName} '$name'.",
        newLocation_fromElement(interfaceElement),
      );
    }
    // check shadowing in the hierarchy
    await _checkHierarchy(isRename: false, subClasses: subClasses);
    // done
    return result;
  }
}

class _LocalElementsCollector extends GeneralizingAstVisitor<void> {
  final String name;
  final List<Element> elements = [];

  _LocalElementsCollector(this.name);

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    if (node.name.lexeme == name) {
      var element = node.declaredFragment?.element;
      if (element is LocalFunctionElement) {
        elements.add(element);
      }
    }

    super.visitFunctionDeclaration(node);
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    if (node.name?.lexeme == name) {
      var element = node.declaredFragment?.element;
      if (element != null) {
        elements.add(element);
      }
    }

    super.visitSimpleFormalParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    var element = node.element;
    if (node.parent case AssignmentExpression(
      :var writeElement,
      :var leftHandSide,
    ) when node == leftHandSide) {
      element = writeElement;
    }
    if (element is! PropertyAccessorElement) {
      return;
    }
    if (element.name != name) {
      return;
    }
    if (element is! GetterElement && element is! SetterElement) {
      return;
    }
    if (element.variable case TopLevelVariableElement variable) {
      elements.add(variable);
    }
    super.visitSimpleIdentifier(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.name.lexeme == name) {
      var element = node.declaredFragment?.element;
      if (element is LocalVariableElement) {
        elements.add(element);
      }
    }

    super.visitVariableDeclaration(node);
  }
}

class _MatchShadowedBy {
  final SearchMatch match;
  final Element element;

  _MatchShadowedBy(this.match, this.element);
}

/// Helper to check if the renamed [element] will cause any conflicts.
class _RenameClassMemberValidator extends _BaseClassMemberValidator {
  final Element element;

  Set<Element> elements = {};
  List<SearchMatch> references = [];
  List<SearchMatch> unshadowed = [];

  _RenameClassMemberValidator(
    SearchEngine searchEngine,
    AnalysisSessionHelper sessionHelper,
    InterfaceElement elementInterface,
    this.element,
    String name,
  ) : super(searchEngine, sessionHelper, elementInterface, element.kind, name);

  Future<RefactoringStatus> validate() async {
    _checkClassAlreadyDeclares();
    // do chained computations
    await _prepareReferences();
    var subClasses = <InterfaceElement>{};
    await searchEngine.appendAllSubtypes(
      interfaceElement,
      subClasses,
      OperationPerformanceImpl('<root>'),
    );
    // check shadowing of class names
    for (var element in elements) {
      var enclosingElement = element.enclosingElement;
      if (enclosingElement is InterfaceElement &&
          enclosingElement.name == name) {
        result.addError(
          'Renamed ${elementKind.displayName} has the same name as the '
          "declaring ${enclosingElement.kind.displayName} '$name'.",
          newLocation_fromElement(element),
        );
      }
    }
    // usage of the renamed Element is shadowed by a local element
    {
      var conflict = await _getLocalShadowingElement();
      if (conflict != null) {
        var element = conflict.element;
        result.addError(
          formatList("Usage of renamed {0} will be shadowed by {1} '{2}'.", [
            elementKind.displayName,
            getElementKindName(element),
            element.displayName,
          ]),
          newLocation_fromMatch(conflict.match),
        );
      }
    }
    // check shadowing in the hierarchy
    await _checkHierarchy(isRename: true, subClasses: subClasses);
    // visibility
    _validateWillBeInvisible();
    // done
    return result;
  }

  Future<_MatchShadowedBy?> _getLocalShadowingElement() async {
    var localElementMap = <LibraryFragment, List<Element>>{};
    var visibleRangeMap = <Element, SourceRange>{};

    Future<List<Element>> getLocalElements(Element element) async {
      var unitFragment = element.firstFragment.libraryFragment;
      if (unitFragment == null) {
        return const [];
      }

      var localElements = localElementMap[unitFragment];

      if (localElements == null) {
        var result = await sessionHelper.getResolvedUnitByElement(element);
        if (result == null) {
          return const [];
        }

        var unit = result.unit;

        var collector = _LocalElementsCollector(name);
        unit.accept(collector);
        localElements = collector.elements;
        localElementMap[unitFragment] = localElements;

        visibleRangeMap.addAll(VisibleRangesComputer.forNode(unit));
      }

      return localElements;
    }

    for (var match in references) {
      // Qualified reference cannot be shadowed by local elements.
      if (match.isQualified) {
        continue;
      }
      // Check local elements that might shadow the reference.
      var localElements = await getLocalElements(match.element);
      if (element.kind == ElementKind.FIELD) {
        for (var element in localElements.avoidableShadowsForField) {
          unshadowed.addAll(await searchEngine.searchReferences(element));
          localElements.remove(element);
        }
      }
      for (var localElement in localElements) {
        var elementRange = visibleRangeMap[localElement];
        if (elementRange != null &&
            elementRange.intersects(match.sourceRange)) {
          return _MatchShadowedBy(match, localElement);
        }
      }
    }
    return null;
  }

  /// Fills [elements] with [Element]s to rename.
  Future<void> _prepareElements() async {
    var element = this.element;
    if (element is FieldElement || element is MethodElement) {
      elements = await getHierarchyMembers(searchEngine, element);
    } else {
      elements = {element};
    }

    for (var i = 0; i < elements.length; i++) {
      element = elements.elementAt(i);
      if (element is FieldElement) {
        var interfaceElement = element.enclosingElement;
        if (interfaceElement is InterfaceElement) {
          var formalParameters = interfaceElement.constructors
              .expand((constructor) => constructor.formalParameters)
              .whereType<FieldFormalParameterElement>()
              .where((formalParameter) => formalParameter.field == element)
              .cast<FormalParameterElement>()
              .toList();

          // Skip private named parameters if we are in a library that doesn't
          // support them.
          if (name.startsWith('_') && !element.supportsPrivateNamedParameters) {
            formalParameters.removeWhere((formalParameter) {
              return formalParameter.isNamed;
            });
          }

          await addNamedSuperFormalParameters(searchEngine, formalParameters);
          elements.addAll(formalParameters);
        }
      }
    }
  }

  /// Fills [references] with all references to [elements].
  Future<void> _prepareReferences() async {
    await _prepareElements();
    await Future.forEach(elements, (Element element) async {
      var elementReferences = await searchEngine.searchReferences(element);
      references.addAll(elementReferences);
    });
  }

  /// Validates if any usage of [element] renamed to [name] will be invisible.
  void _validateWillBeInvisible() {
    if (!Identifier.isPrivateName(name)) {
      return;
    }
    for (var reference in references) {
      var refElement = reference.element;
      var refLibrary = refElement.library!;
      if (refLibrary != library) {
        var message = formatList("Renamed {0} will be invisible in '{1}'.", [
          getElementKindName(element),
          getElementQualifiedName(refLibrary),
        ]);
        result.addError(message, newLocation_fromMatch(reference));
      }
    }
  }
}

extension on Element {
  bool get canAvoidShadowForField {
    return switch (kind) {
      ElementKind.LOCAL_VARIABLE ||
      ElementKind.TOP_LEVEL_VARIABLE ||
      ElementKind.PARAMETER => true,
      _ => false,
    };
  }

  bool get supportsPrivateNamedParameters {
    return library?.featureSet.isEnabled(Feature.private_named_parameters) ??
        true;
  }
}

extension on List<Element> {
  List<Element> get avoidableShadowsForField {
    return where((e) => e.canAvoidShadowForField).toList();
  }
}
