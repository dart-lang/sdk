// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/builder.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/resolver.dart';

/// This class takes a [CompilationUnitElement] lazily resynthesized from a
/// fully resolved, but partial AST (contains only APIs), and full unresolved
/// AST - and splices them into a single AST with all declaration nodes
/// fully resolved, and function bodies and variable initializers unresolved.
///
class DeclarationSplicer {
  final CompilationUnitElementImpl _unitElement;

  _ElementWalker _walker;

  DeclarationSplicer(this._unitElement);

  void splice(CompilationUnit full) {
    var partialNode = _unitElement.linkedContext.readUnitEagerly();
    _directives(full, partialNode);
    _declarations(full, partialNode);
  }

  FunctionBody _body(FunctionBody full) {
    _buildLocalElements(full);
    return full;
  }

  void _buildLocalElements(AstNode node) {
    if (node == null) return;

    var holder = ElementHolder();
    var elementBuilder = LocalElementBuilder(holder, _unitElement);
    node.accept(elementBuilder);

    ElementImpl element = _walker.element;
    element.encloseElements(holder.functions);
    element.encloseElements(holder.labels);
    element.encloseElements(holder.localVariables);
  }

  void _classDeclaration(ClassDeclaration full, ClassDeclaration partial) {
    var element = _walker.getClass();
    _match(partial.name, element);
    _walk(_ElementWalker.forClass(element), () {
      _node(full.typeParameters, partial.typeParameters);
      var fullList = full.members;
      var partialList = partial.members;
      for (var i = 0; i < fullList.length; ++i) {
        _node(fullList[i], partialList[i]);
      }
    });
    _metadata(partial.metadata, element);
  }

  void _classTypeAlias(ClassTypeAlias full, ClassTypeAlias partial) {
    var element = _walker.getClass();
    _match(partial.name, element);
    _walk(_ElementWalker.forClass(element), () {
      _node(full.typeParameters, partial.typeParameters);
    });
    _metadata(partial.metadata, element);
  }

  void _constructorDeclaration(
    ConstructorDeclaration full,
    ConstructorDeclaration partial,
  ) {
    var element = _walker.getConstructor();
    _match(partial.name, element);
    (partial as ConstructorDeclarationImpl).declaredElement = element;
    _walk(_ElementWalker.forExecutable(element), () {
      _formalParameterList(full.parameters, partial.parameters);
      _constructorInitializers(full.initializers, partial.initializers);
      partial.body = _body(full.body);
    });
    _metadata(partial.metadata, element);
  }

  void _constructorInitializers(
    List<ConstructorInitializer> full,
    List<ConstructorInitializer> partial,
  ) {
    if (full.isNotEmpty && partial.isEmpty) {
      partial.addAll(full);
    }
    partial.forEach(_buildLocalElements);
  }

  void _declarations(CompilationUnit full, CompilationUnit partial) {
    _walk(_ElementWalker.forCompilationUnit(_unitElement), () {
      var fullList = full.declarations;
      var partialList = partial.declarations;
      for (var i = 0; i < fullList.length; ++i) {
        var partialNode = _node(fullList[i], partialList[i]);
        fullList[i] = partialNode;
      }
    });
  }

  void _directives(CompilationUnit full, CompilationUnit partial) {
    var libraryElement = _unitElement.library;
    var exportIndex = 0;
    var importIndex = 0;
    var partIndex = 0;
    for (var directive in full.directives) {
      if (directive is ExportDirective) {
        var element = libraryElement.exports[exportIndex++];
        _metadata(directive.metadata, element);
      } else if (directive is ImportDirective) {
        var element = libraryElement.imports[importIndex++];
        _metadata(directive.metadata, element);
      } else if (directive is LibraryDirective) {
        var element = libraryElement;
        _metadata(directive.metadata, element);
      } else if (directive is PartDirective) {
        var element = libraryElement.parts[partIndex++];
        _metadata(directive.metadata, element);
      }
    }
  }

  void _enumConstantDeclaration(
      EnumConstantDeclaration full, EnumConstantDeclaration partial) {
    var element = _walker.getVariable();
    _match(partial.name, element);
    _metadata(partial.metadata, element);
  }

  void _enumDeclaration(EnumDeclaration full, EnumDeclaration partial) {
    var element = _walker.getEnum();
    _match(partial.name, element);
    _walk(_ElementWalker.forClass(element), () {
      var fullList = full.constants;
      var partialList = partial.constants;
      for (var i = 0; i < fullList.length; ++i) {
        _node(fullList[i], partialList[i]);
      }
    });
    _metadata(partial.metadata, element);
  }

  void _fieldDeclaration(FieldDeclaration full, FieldDeclaration partial) {
    _node(full.fields, partial.fields);

    var first = partial.fields.variables[0];
    _metadata(partial.metadata, first.declaredElement);
  }

  void _fieldFormalParameter(
    FieldFormalParameter full,
    FieldFormalParameter partial,
  ) {
    var element = _walker.getParameter();
    _match(partial.identifier, element);
    _walk(_ElementWalker.forParameter(element), () {
      _node(full.typeParameters, partial.typeParameters);
      _node(full.parameters, partial.parameters);
    });
    _metadata(partial.metadata, element);
  }

  void _formalParameterList(
    FormalParameterList full,
    FormalParameterList partial,
  ) {
    var fullList = full.parameters;
    var partialList = partial.parameters;
    for (var i = 0; i < fullList.length; ++i) {
      _node(fullList[i], partialList[i]);
    }
  }

  void _functionDeclaration(
    FunctionDeclaration full,
    FunctionDeclaration partial,
  ) {
    var element = partial.propertyKeyword == null
        ? _walker.getFunction()
        : _walker.getAccessor();
    _match(partial.name, element);
    _walk(_ElementWalker.forExecutable(element), () {
      _node(full.functionExpression, partial.functionExpression);
    });
    (partial.functionExpression as FunctionExpressionImpl).declaredElement =
        element;
    _metadata(partial.metadata, element);
    _node(full.returnType, partial.returnType);
  }

  void _functionExpression(
    FunctionExpression full,
    FunctionExpression partial,
  ) {
    _node(full.typeParameters, partial.typeParameters);
    _node(full.parameters, partial.parameters);
    partial.body = _body(full.body);
  }

  void _functionTypeAlias(FunctionTypeAlias full, FunctionTypeAlias partial) {
    var element = _walker.getTypedef();
    _match(partial.name, element);
    _walk(_ElementWalker.forGenericTypeAlias(element), () {
      _node(full.typeParameters, partial.typeParameters);
      _node(full.parameters, partial.parameters);
    });
    _metadata(partial.metadata, element);
  }

  void _functionTypedFormalParameter(
    FunctionTypedFormalParameter full,
    FunctionTypedFormalParameter partial,
  ) {
    var element = _walker.getParameter();
    _match(partial.identifier, element);
    _walk(_ElementWalker.forParameter(element), () {
      _node(full.typeParameters, partial.typeParameters);
      _node(full.parameters, partial.parameters);
    });
    _metadata(partial.metadata, element);
  }

  void _genericFunctionType(
    GenericFunctionType full,
    GenericFunctionType partial,
  ) {
    var element = (partial as GenericFunctionTypeImpl).declaredElement;
    _walk(_ElementWalker.forGenericFunctionType(element), () {
      _node(full.returnType, partial.returnType);
      _node(full.typeParameters, partial.typeParameters);
      _node(full.parameters, partial.parameters);
    });
  }

  void _genericTypeAlias(GenericTypeAlias full, GenericTypeAlias partial) {
    var element = _walker.getTypedef();
    _match(partial.name, element);
    _walk(_ElementWalker.forGenericTypeAlias(element), () {
      _node(full.typeParameters, partial.typeParameters);
      _node(full.functionType, partial.functionType);
    });
    _metadata(partial.metadata, element);
  }

  /// Updates [node] to point to [element], after ensuring that the
  /// element has the expected name.
  E _match<E extends Element>(SimpleIdentifier node, E element) {
    // TODO(scheglov) has troubles with getter/setter.
//    if (element.name != node.name) {
//      throw new StateError(
//        'Expected an element matching `${node.name}`, got `${element.name}`',
//      );
//    }
    if (node != null) {
      node.staticElement = element;
    }
    return element;
  }

  void _methodDeclaration(MethodDeclaration full, MethodDeclaration partial) {
    var element = partial.propertyKeyword == null
        ? _walker.getFunction()
        : _walker.getAccessor();
    _match(partial.name, element);
    _walk(_ElementWalker.forExecutable(element), () {
      _node(full.typeParameters, partial.typeParameters);
      _node(full.parameters, partial.parameters);
      partial.body = _body(full.body);
    });
    _metadata(partial.metadata, element);
    _node(full.returnType, partial.returnType);
  }

  void _mixinDeclaration(MixinDeclaration full, MixinDeclaration partial) {
    var element = _walker.getMixin();
    _match(partial.name, element);
    _walk(_ElementWalker.forClass(element), () {
      _node(full.typeParameters, partial.typeParameters);
      var fullList = full.members;
      var partialList = partial.members;
      for (var i = 0; i < fullList.length; ++i) {
        _node(fullList[i], partialList[i]);
      }
    });
    _metadata(partial.metadata, element);
  }

  AstNode _node(AstNode full, AstNode partial) {
    if (full == null && partial == null) {
      return partial;
    } else if (full is ClassDeclaration && partial is ClassDeclaration) {
      _classDeclaration(full, partial);
      return partial;
    } else if (full is ClassTypeAlias && partial is ClassTypeAlias) {
      _classTypeAlias(full, partial);
      return partial;
    } else if (full is ConstructorDeclaration &&
        partial is ConstructorDeclaration) {
      _constructorDeclaration(full, partial);
      return partial;
    } else if (full is DefaultFormalParameter &&
        partial is DefaultFormalParameter) {
      _node(full.parameter, partial.parameter);
      return partial;
    } else if (full is EnumConstantDeclaration &&
        partial is EnumConstantDeclaration) {
      _enumConstantDeclaration(full, partial);
      return partial;
    } else if (full is EnumDeclaration && partial is EnumDeclaration) {
      _enumDeclaration(full, partial);
      return partial;
    } else if (full is FieldDeclaration && partial is FieldDeclaration) {
      _fieldDeclaration(full, partial);
      return partial;
    } else if (full is FieldFormalParameter &&
        partial is FieldFormalParameter) {
      _fieldFormalParameter(full, partial);
      return partial;
    } else if (full is FormalParameterList && partial is FormalParameterList) {
      _formalParameterList(full, partial);
      return partial;
    } else if (full is FunctionDeclaration && partial is FunctionDeclaration) {
      _functionDeclaration(full, partial);
      return partial;
    } else if (full is FunctionExpression && partial is FunctionExpression) {
      _functionExpression(full, partial);
      return partial;
    } else if (full is FunctionTypedFormalParameter &&
        partial is FunctionTypedFormalParameter) {
      _functionTypedFormalParameter(full, partial);
      return partial;
    } else if (full is FunctionTypeAlias && partial is FunctionTypeAlias) {
      _functionTypeAlias(full, partial);
      return partial;
    } else if (full is GenericFunctionType && partial is GenericFunctionType) {
      _genericFunctionType(full, partial);
      return partial;
    } else if (full is GenericTypeAlias && partial is GenericTypeAlias) {
      _genericTypeAlias(full, partial);
      return partial;
    } else if (full is MethodDeclaration && partial is MethodDeclaration) {
      _methodDeclaration(full, partial);
      return partial;
    } else if (full is MixinDeclaration && partial is MixinDeclaration) {
      _mixinDeclaration(full, partial);
      return partial;
    } else if (full is SimpleFormalParameter &&
        partial is SimpleFormalParameter) {
      _simpleFormalParameter(full, partial);
      return partial;
    } else if (full is TopLevelVariableDeclaration &&
        partial is TopLevelVariableDeclaration) {
      _topLevelVariableDeclaration(full, partial);
      return partial;
    } else if (full is TypeName && partial is TypeName) {
      _typeName(full, partial);
      return partial;
    } else if (full is TypeParameter && partial is TypeParameter) {
      _typeParameter(full, partial);
      return partial;
    } else if (full is TypeParameterList && partial is TypeParameterList) {
      _typeParameterList(full, partial);
      return partial;
    } else if (full is VariableDeclaration && partial is VariableDeclaration) {
      _variableDeclaration(full, partial);
      return partial;
    } else if (full is VariableDeclarationList &&
        partial is VariableDeclarationList) {
      _variableDeclarationList(full, partial);
      return partial;
    } else {
      throw UnimplementedError(
        '${full.runtimeType} and ${partial.runtimeType}',
      );
    }
  }

  void _simpleFormalParameter(
    SimpleFormalParameter full,
    SimpleFormalParameter partial,
  ) {
    var element = _walker.getParameter();
    _match(partial.identifier, element);
    (partial as SimpleFormalParameterImpl).declaredElement = element;
    _metadata(partial.metadata, element);
    _node(full.type, partial.type);
  }

  void _topLevelVariableDeclaration(
    TopLevelVariableDeclaration full,
    TopLevelVariableDeclaration partial,
  ) {
    _node(full.variables, partial.variables);

    var first = partial.variables.variables[0];
    _metadata(partial.metadata, first.declaredElement);
  }

  void _typeName(TypeName full, TypeName partial) {
    var fullList = full.typeArguments?.arguments;
    var partialList = partial.typeArguments?.arguments;
    if (fullList != null && partialList != null) {
      for (var i = 0; i < fullList.length; ++i) {
        _node(fullList[i], partialList[i]);
      }
    }
  }

  void _typeParameter(TypeParameter full, TypeParameter partial) {
    var element = _walker.getTypeParameter();
    _match(partial.name, element);
    _node(full.bound, partial.bound);
    _metadata(partial.metadata, element);
  }

  void _typeParameterList(TypeParameterList full, TypeParameterList partial) {
    var fullList = full.typeParameters;
    var partialList = partial.typeParameters;
    for (var i = 0; i < fullList.length; ++i) {
      _node(fullList[i], partialList[i]);
    }
  }

  void _variableDeclaration(
    VariableDeclaration full,
    VariableDeclaration partial,
  ) {
    var element = _walker.getVariable();
    _match(partial.name, element);

    partial.initializer = full.initializer;
    _buildLocalElements(partial.initializer);
  }

  void _variableDeclarationList(
    VariableDeclarationList full,
    VariableDeclarationList partial,
  ) {
    _node(full.type, partial.type);

    var fullList = full.variables;
    var partialList = partial.variables;
    for (var i = 0; i < fullList.length; ++i) {
      _node(fullList[i], partialList[i]);
    }
  }

  void _walk(_ElementWalker walker, void f()) {
    var outer = _walker;
    _walker = walker;
    f();
    _walker = outer;
  }

  /// Associate [nodes] with the corresponding [ElementAnnotation]s.
  static void _metadata(List<Annotation> nodes, Element element) {
    var elements = element.metadata;
    if (nodes.length != elements.length) {
      throw StateError('Found ${nodes.length} annotation nodes and '
          '${elements.length} element annotations');
    }
    for (var i = 0; i < nodes.length; i++) {
      nodes[i].elementAnnotation = elements[i];
    }
  }
}

class _ElementWalker {
  final Element element;

  List<PropertyAccessorElement> _accessors;
  int _accessorIndex = 0;

  List<ClassElement> _classes;
  int _classIndex = 0;

  List<ConstructorElement> _constructors;
  int _constructorIndex = 0;

  List<ClassElement> _enums;
  int _enumIndex = 0;

  List<ExecutableElement> _functions;
  int _functionIndex = 0;

  List<ClassElement> _mixins;
  int _mixinIndex = 0;

  List<ParameterElement> _parameters;
  int _parameterIndex = 0;

  List<FunctionTypeAliasElement> _typedefs;
  int _typedefIndex = 0;

  List<TypeParameterElement> _typeParameters;
  int _typeParameterIndex = 0;

  List<VariableElement> _variables;
  int _variableIndex = 0;

  _ElementWalker.forClass(ClassElement element)
      : element = element,
        _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _constructors = element.isMixinApplication
            ? null
            : element.constructors.where(_isNotSynthetic).toList(),
        _functions = element.methods,
        _typeParameters = element.typeParameters,
        _variables = element.fields.where(_isNotSynthetic).toList();

  _ElementWalker.forCompilationUnit(CompilationUnitElement element)
      : element = element,
        _accessors = element.accessors.where(_isNotSynthetic).toList(),
        _classes = element.types,
        _enums = element.enums,
        _functions = element.functions,
        _mixins = element.mixins,
        _typedefs = element.functionTypeAliases,
        _variables = element.topLevelVariables.where(_isNotSynthetic).toList();

  _ElementWalker.forExecutable(ExecutableElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  _ElementWalker.forGenericFunctionType(GenericFunctionTypeElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  _ElementWalker.forGenericTypeAlias(FunctionTypeAliasElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  _ElementWalker.forParameter(ParameterElement element)
      : element = element,
        _parameters = element.parameters,
        _typeParameters = element.typeParameters;

  PropertyAccessorElement getAccessor() {
    return _accessors[_accessorIndex++];
  }

  ClassElement getClass() {
    return _classes[_classIndex++];
  }

  ConstructorElement getConstructor() {
    return _constructors[_constructorIndex++];
  }

  ClassElement getEnum() {
    return _enums[_enumIndex++];
  }

  ExecutableElement getFunction() {
    return _functions[_functionIndex++];
  }

  ClassElement getMixin() {
    return _mixins[_mixinIndex++];
  }

  ParameterElement getParameter() {
    return _parameters[_parameterIndex++];
  }

  FunctionTypeAliasElement getTypedef() {
    return _typedefs[_typedefIndex++];
  }

  TypeParameterElement getTypeParameter() {
    return _typeParameters[_typeParameterIndex++];
  }

  VariableElement getVariable() {
    return _variables[_variableIndex++];
  }

  static bool _isNotSynthetic(Element e) => !e.isSynthetic;
}
