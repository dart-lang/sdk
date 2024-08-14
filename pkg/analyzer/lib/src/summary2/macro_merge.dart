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
import 'package:analyzer/src/utilities/extensions/element.dart';

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

  MacroElementsMerger({
    required this.partialUnits,
    required this.unitReference,
    required this.unitNode,
    required this.unitElement,
  });

  void perform({
    required void Function() updateConstants,
  }) {
    // TODO(scheglov): https://github.com/dart-lang/sdk/issues/55931
    // This is a fix for this specific issue, not a complete implementation.
    _mergeClasses(isAugmentation: false);
    _mergeClasses(isAugmentation: true);
    _mergeExtensions();
    _mergeFunctions();
    _mergeUnitPropertyAccessors();
    _mergeUnitVariables();
    updateConstants();
    _rewriteImportPrefixes();
  }

  void _mergeClasses({
    required bool isAugmentation,
  }) {
    for (var partialUnit in partialUnits) {
      var elementsToAdd = <ClassElementImpl>[];
      for (var element in partialUnit.element.classes) {
        if (element.isAugmentation == isAugmentation) {
          var reference = element.reference!;
          var containerRef = element.isAugmentation
              ? unitReference.getChild('@classAugmentation')
              : unitReference.getChild('@class');
          var existingRef = containerRef[element.name];
          if (existingRef == null) {
            elementsToAdd.add(element);
            containerRef.addChildReference(element.name, reference);
          } else {
            var existingElement = existingRef.element as ClassElementImpl;
            if (existingElement.augmentation == element) {
              existingElement.augmentation = null;
            }
            _mergeInstanceChildren(existingRef, existingElement, element);
          }
        }
      }
      unitElement.classes = [
        ...unitElement.classes,
        ...elementsToAdd,
      ].toFixedList();
    }
  }

  void _mergeExtensions() {
    for (var partialUnit in partialUnits) {
      var elementsToAdd = <ExtensionElementImpl>[];
      for (var element in partialUnit.element.extensions) {
        var reference = element.reference!;
        var containerRef = element.isAugmentation
            ? unitReference.getChild('@extensionAugmentation')
            : unitReference.getChild('@extension');
        var name = element.name;
        if (name != null) {
          var existingRef = containerRef[name];
          if (existingRef == null) {
            elementsToAdd.add(element);
            containerRef.addChildReference(name, reference);
          } else {
            var existingElement = existingRef.element as ExtensionElementImpl;
            if (existingElement.augmentation == element) {
              existingElement.augmentation = null;
            }
            _mergeInstanceChildren(existingRef, existingElement, element);
          }
        }
      }
      unitElement.extensions = [
        ...unitElement.extensions,
        ...elementsToAdd,
      ].toFixedList();
    }
  }

  void _mergeFunctions() {
    for (var partialUnit in partialUnits) {
      var elementsToAdd = <FunctionElementImpl>[];
      for (var element in partialUnit.element.functions) {
        var reference = element.reference!;
        var containerRef = element.isAugmentation
            ? unitReference.getChild('@functionAugmentation')
            : unitReference.getChild('@function');
        var existingRef = containerRef[element.name];
        if (existingRef == null) {
          elementsToAdd.add(element);
          containerRef.addChildReference(element.name, reference);
        } else {
          var existingElement = existingRef.element as FunctionElementImpl;
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
    for (var element in newElement.fields) {
      var reference = element.reference!;
      var containerRef = element.isAugmentation
          ? existingRef.getChild('@fieldAugmentation')
          : existingRef.getChild('@field');
      containerRef.addChildReference(element.name, reference);
    }
    existingElement.fields = [
      ...existingElement.fields,
      ...newElement.fields,
    ].toFixedList();

    for (var element in newElement.accessors) {
      var reference = element.reference!;
      var containerRef = element.isGetter
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

    for (var element in newElement.methods) {
      var reference = element.reference!;
      var containerRef = element.isAugmentation
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

      for (var element in newElement.constructors) {
        var reference = element.reference!;
        var containerRef = element.isAugmentation
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
    var containerRef = unitReference.getChild('@accessor');
    for (var partialUnit in partialUnits) {
      for (var element in partialUnit.element.accessors) {
        var reference = element.reference!;
        containerRef.addChildReference(element.name, reference);
      }
      unitElement.accessors = [
        ...unitElement.accessors,
        ...partialUnit.element.accessors,
      ].toFixedList();
    }
  }

  void _mergeUnitVariables() {
    var containerRef = unitReference.getChild('@topLevelVariable');
    for (var partialUnit in partialUnits) {
      for (var element in partialUnit.element.topLevelVariables) {
        var reference = element.reference!;
        containerRef.addChildReference(element.name, reference);
      }
      unitElement.topLevelVariables = [
        ...unitElement.topLevelVariables,
        ...partialUnit.element.topLevelVariables,
      ].toFixedList();
    }
  }

  void _rewriteImportPrefixes() {
    var uriToPartialPrefixes = <Uri, List<PrefixElementImpl>>{};
    for (var partialUnit in partialUnits) {
      for (var import in partialUnit.element.libraryImports) {
        var prefix = import.prefix?.element;
        var importedLibrary = import.importedLibrary;
        if (prefix != null && importedLibrary != null) {
          var uri = importedLibrary.source.uri;
          (uriToPartialPrefixes[uri] ??= []).add(prefix);
        }
      }
    }

    // The merged augmentation imports the same libraries, but with
    // different prefixes. Prepare the mapping.
    var partialPrefixToMerged =
        Map<PrefixElementImpl, PrefixElementImpl>.identity();
    for (var import in unitElement.libraryImports) {
      var prefix = import.prefix?.element;
      var importedLibrary = import.importedLibrary;
      if (prefix != null && importedLibrary != null) {
        var uri = importedLibrary.source.uri;
        var partialPrefixes = uriToPartialPrefixes[uri];
        if (partialPrefixes != null) {
          for (var partialPrefix in partialPrefixes) {
            partialPrefixToMerged[partialPrefix] = prefix;
          }
        }
      }
    }

    // Rewrite import prefixes in constants.
    var visitor = _RewriteImportPrefixes(partialPrefixToMerged);
    for (var partialUnit in partialUnits) {
      partialUnit.node.accept(visitor);
    }
  }
}

class MacroUpdateConstantsForOptimizedCode {
  /// The container of [unitElement].
  final LibraryElementImpl libraryElement;

  /// The parsed merged code.
  final ast.CompilationUnit unitNode;

  /// The edits applied to the code that was parsed into [unitNode].
  /// This class does not have the optimized code itself.
  final List<macro.Edit> codeEdits;

  /// The merged element, with elements in the same order as in [unitNode].
  final CompilationUnitElementImpl unitElement;

  /// The names of classes that have a `const` constructor.
  final Set<String> _namesOfConstClasses = {};

  MacroUpdateConstantsForOptimizedCode({
    required this.libraryElement,
    required this.unitNode,
    required this.codeEdits,
    required this.unitElement,
  });

  /// Iterate over two lists of annotations and constants:
  ///
  /// 1. From the merged, but not optimized, parsed AST.
  ///
  /// 2. From the merged element models, also not optimized.
  /// Because we never optimize partial macro units.
  ///
  /// These elements are *not* produced from the parsed AST above.
  /// But they must be fully consistent with each other.
  /// The same elements, in the same order.
  /// If not, we have a bug in [MacroElementsMerger].
  void perform() {
    _findConstClasses();
    var nodeRecords = _orderedForNodes();
    var elementRecords = _orderedForElement();
    assert(nodeRecords.length == elementRecords.length);

    for (var i = 0; i < nodeRecords.length; i++) {
      var nodeRecord = nodeRecords[i];
      var nodeTokens = nodeRecord.$2.allTokens;

      var elementRecord = elementRecords[i];
      var elementAnnotation = elementRecord.$2;
      var elementTokens = elementAnnotation.allTokens;
      assert(nodeTokens.length == elementTokens.length);

      elementAnnotation.accept(
        _RemoveImportPrefixesVisitor(
          codeEdits: codeEdits,
          nodeTokens: nodeTokens,
          elementTokens: elementTokens.asElementToIndexMap,
          onReplace: ({required toReplace, required replacement}) {
            // Maybe replace the whole constant initializer.
            if (elementRecord.$1 case ConstVariableElement element) {
              if (element.constantInitializer == toReplace) {
                replacement as ast.ExpressionImpl;
                element.constantInitializer = replacement;
              }
            }
          },
        ),
      );
    }
  }

  void _findConstClasses() {
    for (var element in libraryElement.topLevelElements) {
      if (element is! ClassElementImpl) continue;
      if (element.isAugmentation) continue;

      var augmented = element.augmented;
      var hasConst = augmented.constructors.any((e) => e.isConst);
      if (hasConst) {
        _namesOfConstClasses.add(element.name);
      }
    }
  }

  List<(ElementImpl, ast.AstNodeImpl)> _orderedForElement() {
    var result = <(ElementImpl, ast.AstNodeImpl)>[];

    void addElement(ElementImpl element) {
      for (var annotation in element.metadata) {
        result.add((element, annotation.annotationAst));
      }

      switch (element) {
        case ConstVariableElement():
          if (element.constantInitializer case var initializer?) {
            result.add((element, initializer));
          }
        case ExecutableElementImpl():
          for (var formalParameter in element.parameters) {
            addElement(formalParameter.declarationImpl);
          }
      }
    }

    void addInstanceElement(InstanceElementImpl element) {
      addElement(element);

      for (var field in element.fields) {
        if (!field.isSynthetic) {
          addElement(field);
        }
      }

      for (var getter in element.accessors) {
        if (getter.isGetter && !getter.isSynthetic) {
          addElement(getter);
        }
      }

      for (var setter in element.accessors) {
        if (setter.isSetter && !setter.isSynthetic) {
          addElement(setter);
        }
      }

      for (var method in element.methods) {
        addElement(method);
      }
    }

    void addInterfaceElement(InterfaceElementImpl element) {
      addInstanceElement(element);
      for (var constructor in element.constructors) {
        addElement(constructor);
      }
    }

    for (var class_ in unitElement.classes) {
      addInterfaceElement(class_);
    }

    for (var variable in unitElement.topLevelVariables) {
      if (!variable.isSynthetic) {
        addElement(variable);
      }
    }

    for (var getter in unitElement.accessors) {
      if (getter.isGetter && !getter.isSynthetic) {
        addElement(getter);
      }
    }

    for (var setter in unitElement.accessors) {
      if (setter.isSetter && !setter.isSynthetic) {
        addElement(setter);
      }
    }

    for (var function in unitElement.functions) {
      addElement(function);
    }

    return result;
  }

  List<(ast.AstNodeImpl, ast.AstNodeImpl)> _orderedForNodes() {
    var result = <(ast.AstNodeImpl, ast.AstNodeImpl)>[];

    void addMetadata(
      ast.AstNodeImpl node,
      List<ast.AnnotationImpl> metadata,
    ) {
      for (var annotation in metadata) {
        result.add((node, annotation));
      }
    }

    void addAnnotatedNode(ast.AnnotatedNodeImpl node) {
      addMetadata(node, node.metadata);
    }

    void addVariableList(
      ast.VariableDeclarationListImpl variableList,
      List<ast.AnnotationImpl> metadata, {
      required bool withFinals,
    }) {
      for (var variable in variableList.variables) {
        addMetadata(variable, metadata);

        if (variableList.isConst || variableList.isFinal && withFinals) {
          if (variable.initializer case var initializer?) {
            result.add((variable, initializer));
          }
        }
      }
    }

    void addFormalParameters(ast.FormalParameterListImpl? parameterList) {
      if (parameterList != null) {
        for (var formalParameter in parameterList.parameters) {
          addMetadata(formalParameter, formalParameter.metadata);
          if (formalParameter is ast.DefaultFormalParameterImpl) {
            if (formalParameter.defaultValue case var defaultValue?) {
              result.add((formalParameter, defaultValue));
            }
          }
        }
      }
    }

    void addInterfaceMembers(
      List<ast.ClassMemberImpl> members, {
      required bool hasConstConstructor,
    }) {
      for (var field in members) {
        if (field is ast.FieldDeclarationImpl) {
          addVariableList(
            field.fields,
            field.metadata,
            withFinals: hasConstConstructor && !field.isStatic,
          );
        }
      }

      for (var getter in members) {
        if (getter is ast.MethodDeclarationImpl && getter.isGetter) {
          addAnnotatedNode(getter);
          addFormalParameters(getter.parameters);
        }
      }

      for (var setter in members) {
        if (setter is ast.MethodDeclarationImpl && setter.isSetter) {
          addAnnotatedNode(setter);
          addFormalParameters(setter.parameters);
        }
      }

      for (var method in members) {
        if (method is ast.MethodDeclarationImpl &&
            method.propertyKeyword == null) {
          addAnnotatedNode(method);
          addFormalParameters(method.parameters);
        }
      }

      for (var constructor in members) {
        if (constructor is ast.ConstructorDeclarationImpl) {
          addAnnotatedNode(constructor);
          addFormalParameters(constructor.parameters);
        }
      }
    }

    for (var class_ in unitNode.declarations) {
      if (class_ is ast.ClassDeclarationImpl) {
        addAnnotatedNode(class_);
        addInterfaceMembers(
          class_.members,
          hasConstConstructor: _namesOfConstClasses.contains(
            class_.name.lexeme,
          ),
        );
      }
    }

    for (var topVariable in unitNode.declarations) {
      if (topVariable is ast.TopLevelVariableDeclarationImpl) {
        addVariableList(
          topVariable.variables,
          topVariable.metadata,
          withFinals: false,
        );
      }
    }

    for (var getter in unitNode.declarations) {
      if (getter is ast.FunctionDeclarationImpl && getter.isGetter) {
        addAnnotatedNode(getter);
        addFormalParameters(getter.functionExpression.parameters);
      }
    }

    for (var setter in unitNode.declarations) {
      if (setter is ast.FunctionDeclarationImpl && setter.isSetter) {
        addAnnotatedNode(setter);
        addFormalParameters(setter.functionExpression.parameters);
      }
    }

    for (var function in unitNode.declarations) {
      if (function is ast.FunctionDeclarationImpl &&
          function.propertyKeyword == null) {
        addAnnotatedNode(function);
        addFormalParameters(function.functionExpression.parameters);
      }
    }

    return result;
  }
}

class _RemoveImportPrefixesVisitor extends ast.RecursiveAstVisitor<void> {
  final List<macro.Edit> codeEdits;
  final List<Token> nodeTokens;
  final Map<Token, int> elementTokens;
  final void Function({
    required ast.AstNodeImpl toReplace,
    required ast.AstNodeImpl replacement,
  }) onReplace;

  _RemoveImportPrefixesVisitor({
    required this.codeEdits,
    required this.nodeTokens,
    required this.elementTokens,
    required this.onReplace,
  });

  @override
  void visitNamedType(covariant ast.NamedTypeImpl node) {
    if (node.importPrefix case var importPrefix?) {
      var prefix = _correspondingNodeToken(importPrefix.name);
      var edit = _editForRemovePrefix(prefix);
      if (edit != null) {
        node.importPrefix = null;
      }
    }

    super.visitNamedType(node);
  }

  @override
  void visitPrefixedIdentifier(covariant ast.PrefixedIdentifierImpl node) {
    var prefix = _correspondingNodeToken(node.prefix.token);
    var edit = _editForRemovePrefix(prefix);
    if (edit != null) {
      NodeReplacer.replace(node, node.identifier);
      onReplace(
        toReplace: node,
        replacement: node.identifier,
      );
    }

    super.visitPrefixedIdentifier(node);
  }

  Token _correspondingNodeToken(Token elementToken) {
    var index = elementTokens[elementToken]!;
    return nodeTokens[index];
  }

  macro.RemoveImportPrefixReferenceEdit? _editForRemovePrefix(Token prefix) {
    for (var edit in codeEdits) {
      if (edit is macro.RemoveImportPrefixReferenceEdit) {
        if (edit.offset == prefix.offset) {
          return edit;
        }
      }
    }
    return null;
  }
}

class _RewriteImportPrefixes extends ast.RecursiveAstVisitor<void> {
  final Map<PrefixElementImpl, PrefixElementImpl> partialPrefixToMerged;

  _RewriteImportPrefixes(this.partialPrefixToMerged);

  @override
  void visitNamedType(covariant ast.NamedTypeImpl node) {
    if (node.importPrefix case var importPrefix?) {
      var mergedPrefix = partialPrefixToMerged[importPrefix.element];
      if (mergedPrefix != null) {
        node.importPrefix = ast.ImportPrefixReferenceImpl(
          name: StringToken(
            TokenType.IDENTIFIER,
            mergedPrefix.name,
            -1,
          ),
          period: importPrefix.period,
        )..element = mergedPrefix;
      }
    }

    super.visitNamedType(node);
  }

  @override
  void visitSimpleIdentifier(covariant ast.SimpleIdentifierImpl node) {
    var mergedPrefix = partialPrefixToMerged[node.staticElement];
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
