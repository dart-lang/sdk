// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/macros/code_optimizer.dart' as macro;
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart' as ast;
import 'package:analyzer/src/dart/ast/ast.dart' as ast;
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/summary2/library_builder.dart';
import 'package:analyzer/src/summary2/reference.dart';
import 'package:analyzer/src/utilities/extensions/ast.dart';
import 'package:analyzer/src/utilities/extensions/collection.dart';

/// Merges elements from [partialUnits] into [unitElement].
///
/// The [unitElement] is empty initially, but [unitNode] is not, and it is
/// built from the combined macro application results, closely but not exactly
/// corresponding to units from [partialUnits]. We use [unitNode] to update
/// offsets of the elements.
class MacroElementsMerger {
  final List<LinkingUnit> partialUnits;
  final Reference unitReference;
  final ast.CompilationUnit unitNode;
  final CompilationUnitElementImpl unitElement;
  final LibraryAugmentationElementImpl augmentation;

  MacroElementsMerger({
    required this.partialUnits,
    required this.unitReference,
    required this.unitNode,
    required this.unitElement,
    required this.augmentation,
  });

  void perform({
    required Function() updateConstants,
  }) {
    _mergeClasses();
    _mergeFunctions();
    _mergeUnitPropertyAccessors();
    _mergeUnitVariables();
    updateConstants();
    _rewriteImportPrefixes();
  }

  void _mergeClasses() {
    for (final partialUnit in partialUnits) {
      final elementsToAdd = <ClassElementImpl>[];
      for (final element in partialUnit.element.classes) {
        final reference = element.reference!;
        final containerRef = element.isAugmentation
            ? unitReference.getChild('@classAugmentation')
            : unitReference.getChild('@class');
        final existingRef = containerRef[element.name];
        if (existingRef == null) {
          elementsToAdd.add(element);
          containerRef.addChildReference(element.name, reference);
        } else {
          final existingElement = existingRef.element as ClassElementImpl;
          if (existingElement.augmentation == element) {
            existingElement.augmentation = null;
          }
          _mergeInstanceChildren(existingRef, existingElement, element);
        }
      }
      unitElement.classes = [
        ...unitElement.classes,
        ...elementsToAdd,
      ].toFixedList();
    }
  }

  void _mergeFunctions() {
    for (final partialUnit in partialUnits) {
      final elementsToAdd = <FunctionElementImpl>[];
      for (final element in partialUnit.element.functions) {
        final reference = element.reference!;
        final containerRef = element.isAugmentation
            ? unitReference.getChild('@functionAugmentation')
            : unitReference.getChild('@function');
        final existingRef = containerRef[element.name];
        if (existingRef == null) {
          elementsToAdd.add(element);
          containerRef.addChildReference(element.name, reference);
        } else {
          final existingElement = existingRef.element as FunctionElementImpl;
          if (existingElement.augmentation == element) {
            existingElement.augmentation = null;
          }
        }
      }
      unitElement.functions = [
        ...unitElement.functions,
        ...elementsToAdd,
      ].toFixedList();
    }
  }

  void _mergeInstanceChildren(
    Reference existingRef,
    InstanceElementImpl existingElement,
    InstanceElementImpl newElement,
  ) {
    for (final element in newElement.fields) {
      final reference = element.reference!;
      final containerRef = element.isAugmentation
          ? existingRef.getChild('@fieldAugmentation')
          : existingRef.getChild('@field');
      containerRef.addChildReference(element.name, reference);
    }
    existingElement.fields = [
      ...existingElement.fields,
      ...newElement.fields,
    ].toFixedList();

    for (final element in newElement.accessors) {
      final reference = element.reference!;
      final containerRef = element.isGetter
          ? element.isAugmentation
              ? existingRef.getChild('@getterAugmentation')
              : existingRef.getChild('@getter')
          : element.isAugmentation
              ? existingRef.getChild('@setterAugmentation')
              : existingRef.getChild('@setter');
      containerRef.addChildReference(element.name, reference);
    }
    existingElement.accessors = [
      ...existingElement.accessors,
      ...newElement.accessors,
    ].toFixedList();

    for (final element in newElement.methods) {
      final reference = element.reference!;
      final containerRef = element.isAugmentation
          ? existingRef.getChild('@methodAugmentation')
          : existingRef.getChild('@method');
      containerRef.addChildReference(element.name, reference);
    }
    existingElement.methods = [
      ...existingElement.methods,
      ...newElement.methods,
    ].toFixedList();

    if (existingElement is InterfaceElementImpl &&
        newElement is InterfaceElementImpl) {
      if (newElement.interfaces.isNotEmpty) {
        existingElement.interfaces = [
          ...existingElement.interfaces,
          ...newElement.interfaces,
        ].toFixedList();
      }

      for (final element in newElement.constructors) {
        final reference = element.reference!;
        final containerRef = element.isAugmentation
            ? existingRef.getChild('@constructorAugmentation')
            : existingRef.getChild('@constructor');
        containerRef.addChildReference(element.name, reference);
      }
      existingElement.constructors = [
        ...existingElement.constructors,
        ...newElement.constructors,
      ].toFixedList();
    }
  }

  void _mergeUnitPropertyAccessors() {
    final containerRef = unitReference.getChild('@accessor');
    for (final partialUnit in partialUnits) {
      for (final element in partialUnit.element.accessors) {
        final reference = element.reference!;
        containerRef.addChildReference(element.name, reference);
      }
      unitElement.accessors = [
        ...unitElement.accessors,
        ...partialUnit.element.accessors,
      ].toFixedList();
    }
  }

  void _mergeUnitVariables() {
    final containerRef = unitReference.getChild('@topLevelVariable');
    for (final partialUnit in partialUnits) {
      for (final element in partialUnit.element.topLevelVariables) {
        final reference = element.reference!;
        containerRef.addChildReference(element.name, reference);
      }
      unitElement.topLevelVariables = [
        ...unitElement.topLevelVariables,
        ...partialUnit.element.topLevelVariables,
      ].toFixedList();
    }
  }

  void _rewriteImportPrefixes() {
    final uriToPartialPrefixes = <Uri, List<PrefixElementImpl>>{};
    for (final partialUnit in partialUnits) {
      for (final import in partialUnit.container.libraryImports) {
        final prefix = import.prefix?.element;
        final importedLibrary = import.importedLibrary;
        if (prefix != null && importedLibrary != null) {
          final uri = importedLibrary.source.uri;
          (uriToPartialPrefixes[uri] ??= []).add(prefix);
        }
      }
    }

    // The merged augmentation imports the same libraries, but with
    // different prefixes. Prepare the mapping.
    final partialPrefixToMerged =
        Map<PrefixElementImpl, PrefixElementImpl>.identity();
    for (final import in augmentation.libraryImports) {
      final prefix = import.prefix?.element;
      final importedLibrary = import.importedLibrary;
      if (prefix != null && importedLibrary != null) {
        final uri = importedLibrary.source.uri;
        final partialPrefixes = uriToPartialPrefixes[uri];
        if (partialPrefixes != null) {
          for (final partialPrefix in partialPrefixes) {
            partialPrefixToMerged[partialPrefix] = prefix;
          }
        }
      }
    }

    // Rewrite import prefixes in constants.
    final visitor = _RewriteImportPrefixes(partialPrefixToMerged);
    for (final partialUnit in partialUnits) {
      partialUnit.node.accept(visitor);
    }
  }
}

class MacroUpdateConstantsForOptimizedCode {
  /// The parsed merged code.
  final ast.CompilationUnit unitNode;

  /// The edits applied to the code that was parsed into [unitNode].
  /// This class does not have the optimized code itself.
  final List<macro.Edit> codeEdits;

  /// The merged element, with elements in the same order as in [unitNode].
  final CompilationUnitElementImpl unitElement;

  MacroUpdateConstantsForOptimizedCode({
    required this.unitNode,
    required this.codeEdits,
    required this.unitElement,
  });

  void perform() {
    var nodeAnnotations = _annotatedNodesInOrder().expand((node) sync* {
      for (var annotation in node.metadata) {
        yield (
          declaration: node,
          annotation: annotation,
        );
      }
    }).toList();

    var elementAnnotations =
        _annotatedElementsInOrder().expand((element) sync* {
      for (var annotation in element.metadata) {
        annotation as ElementAnnotationImpl;
        yield (
          element: element,
          annotation: annotation.annotationAst,
        );
      }
    }).toList();

    if (nodeAnnotations.length != elementAnnotations.length) {
      throw StateError('''
Different number of element / node annotations.
nodeAnnotations: ${nodeAnnotations.length}
elementAnnotations: ${elementAnnotations.length}
''');
    }

    for (var i = 0; i < nodeAnnotations.length; i++) {
      var nodeRecord = nodeAnnotations[i];
      var elementRecord = elementAnnotations[i];

      var nodeTokens = nodeRecord.annotation.allTokens;
      var elementTokens = elementRecord.annotation.allTokens;
      if (nodeTokens.length != elementTokens.length) {
        throw StateError('''
Different number of element / node annotations.
nodeTokens: ${nodeTokens.length}
elementTokens: ${elementTokens.length}
''');
      }

      elementRecord.annotation.accept(
        _RemoveImportPrefixesVisitor(
          codeEdits: codeEdits,
          nodeTokens: nodeTokens,
          elementTokens: elementTokens.asElementToIndexMap,
        ),
      );
    }
  }

  List<ElementImpl> _annotatedElementsInOrder() {
    var result = <ElementImpl>[];

    void addInstanceElement(InstanceElementImpl element) {
      result.add(element);
      for (var field in element.fields) {
        if (!field.isSynthetic) {
          result.add(field);
        }
      }
      for (var getter in element.accessors) {
        if (getter.isGetter && !getter.isSynthetic) {
          result.add(getter);
        }
      }
      for (var setter in element.accessors) {
        if (setter.isSetter && !setter.isSynthetic) {
          result.add(setter);
        }
      }
      for (var method in element.methods) {
        result.add(method);
      }
    }

    void addInterfaceElement(InterfaceElementImpl element) {
      addInstanceElement(element);
      for (var constructor in element.constructors) {
        result.add(constructor);
      }
    }

    for (var class_ in unitElement.classes) {
      addInterfaceElement(class_);
    }

    for (var variable in unitElement.topLevelVariables) {
      if (!variable.isSynthetic) {
        result.add(variable);
      }
    }

    for (var getter in unitElement.accessors) {
      if (getter.isGetter && !getter.isSynthetic) {
        result.add(getter);
      }
    }

    for (var setter in unitElement.accessors) {
      if (setter.isSetter && !setter.isSynthetic) {
        result.add(setter);
      }
    }

    for (var function in unitElement.functions) {
      result.add(function);
    }

    return result;
  }

  List<ast.AnnotatedNodeImpl> _annotatedNodesInOrder() {
    var result = <ast.AnnotatedNodeImpl>[];

    void addInterfaceMembers(List<ast.ClassMemberImpl> members) {
      for (var field in members) {
        if (field is ast.FieldDeclarationImpl) {
          result.add(field);
        }
      }

      for (var getter in members) {
        if (getter is ast.MethodDeclarationImpl && getter.isGetter) {
          result.add(getter);
        }
      }

      for (var setter in members) {
        if (setter is ast.MethodDeclarationImpl && setter.isSetter) {
          result.add(setter);
        }
      }

      for (var method in members) {
        if (method is ast.MethodDeclarationImpl &&
            method.propertyKeyword == null) {
          result.add(method);
        }
      }

      for (var constructor in members) {
        if (constructor is ast.ConstructorDeclarationImpl) {
          result.add(constructor);
        }
      }
    }

    for (var class_ in unitNode.declarations) {
      if (class_ is ast.ClassDeclarationImpl) {
        result.add(class_);
        addInterfaceMembers(class_.members);
      }
    }

    for (var variable in unitNode.declarations) {
      if (variable is ast.TopLevelVariableDeclarationImpl) {
        result.add(variable);
      }
    }

    for (var getter in unitNode.declarations) {
      if (getter is ast.FunctionDeclarationImpl && getter.isGetter) {
        result.add(getter);
      }
    }

    for (var setter in unitNode.declarations) {
      if (setter is ast.FunctionDeclarationImpl && setter.isSetter) {
        result.add(setter);
      }
    }

    for (var function in unitNode.declarations) {
      if (function is ast.FunctionDeclarationImpl &&
          function.propertyKeyword == null) {
        result.add(function);
      }
    }

    return result;
  }
}

class _RemoveImportPrefixesVisitor extends ast.RecursiveAstVisitor<void> {
  final List<macro.Edit> codeEdits;
  final List<Token> nodeTokens;
  final Map<Token, int> elementTokens;
  int nodePrefixIndex = 0;

  _RemoveImportPrefixesVisitor({
    required this.codeEdits,
    required this.nodeTokens,
    required this.elementTokens,
  });

  @override
  void visitPrefixedIdentifier(ast.PrefixedIdentifier node) {
    var prefix = node.prefix;
    if (prefix.name.startsWith('prefix')) {
      var index = elementTokens[node.prefix.token]!;
      var nodePrefix = nodeTokens[index];
      for (var edit in codeEdits) {
        if (edit is macro.RemoveImportPrefixReferenceEdit) {
          if (edit.offset == nodePrefix.offset) {
            NodeReplacer.replace(node, node.identifier);
            break;
          }
        }
      }
    }

    super.visitPrefixedIdentifier(node);
  }
}

class _RewriteImportPrefixes extends ast.RecursiveAstVisitor<void> {
  final Map<PrefixElementImpl, PrefixElementImpl> partialPrefixToMerged;

  _RewriteImportPrefixes(this.partialPrefixToMerged);

  @override
  void visitSimpleIdentifier(covariant ast.SimpleIdentifierImpl node) {
    final mergedPrefix = partialPrefixToMerged[node.staticElement];
    if (mergedPrefix != null) {
      // The name may be different in the merged augmentation.
      node.token = StringToken(
        TokenType.IDENTIFIER,
        mergedPrefix.name,
        -1,
      );
      // The element is definitely different.
      node.staticElement = mergedPrefix;
    }
  }
}
