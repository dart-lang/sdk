// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:front_end/src/base/source.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/type_environment.dart' as kernel;

/**
 * Object that can resynthesize analyzer [LibraryElement] from Kernel.
 */
class KernelResynthesizer {
  final AnalysisContext _analysisContext;
  final kernel.TypeEnvironment _types;
  final Map<String, kernel.Library> _kernelMap;
  final Map<String, LibraryElementImpl> _libraryMap = {};

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  KernelResynthesizer(this._analysisContext, this._types, this._kernelMap);

  /**
   * Return the [LibraryElementImpl] for the given [uriStr], or `null` if
   * the library is not part of the Kernel libraries bundle.
   */
  LibraryElementImpl getLibrary(String uriStr) {
    return _libraryMap.putIfAbsent(uriStr, () {
      var kernel = _kernelMap[uriStr];
      if (kernel == null) return null;

      var libraryContext =
          new _KernelLibraryResynthesizerContextImpl(this, kernel);
      Source librarySource = _getSource(uriStr);
      LibraryElementImpl libraryElement =
          new LibraryElementImpl.forKernel(_analysisContext, libraryContext);
      CompilationUnitElementImpl definingUnit =
          libraryElement.definingCompilationUnit;
      definingUnit.source = librarySource;
      definingUnit.librarySource = librarySource;
      return libraryElement;
    });
  }

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(
        uri, () => _analysisContext.sourceFactory.forUri(uri));
  }
}

/**
 * Builder of [Expression]s from [kernel.Expression]s.
 */
class _ExprBuilder {
  final _KernelLibraryResynthesizerContextImpl _context;

  _ExprBuilder(this._context);

  Expression build(kernel.Expression expr) {
    if (expr is kernel.NullLiteral) {
      return AstTestFactory.nullLiteral();
    }
    if (expr is kernel.BoolLiteral) {
      return AstTestFactory.booleanLiteral(expr.value);
    }
    if (expr is kernel.IntLiteral) {
      return AstTestFactory.integer(expr.value);
    }
    if (expr is kernel.DoubleLiteral) {
      return AstTestFactory.doubleLiteral(expr.value);
    }
    if (expr is kernel.StringLiteral) {
      return AstTestFactory.string2(expr.value);
    }
    if (expr is kernel.StringConcatenation) {
      List<InterpolationElement> elements = expr.expressions
          .map(build)
          .map(_newInterpolationElement)
          .toList(growable: false);
      return AstTestFactory.string(elements);
    }
    if (expr is kernel.SymbolLiteral) {
      List<String> components = expr.value.split('.').toList();
      return AstTestFactory.symbolLiteral(components);
    }

    if (expr is kernel.ListLiteral) {
      Keyword keyword = expr.isConst ? Keyword.CONST : null;
      var typeArguments = _buildTypeArgumentList([expr.typeArgument]);
      var elements = expr.expressions.map(build).toList();
      return AstTestFactory.listLiteral2(keyword, typeArguments, elements);
    }

    if (expr is kernel.MapLiteral) {
      Keyword keyword = expr.isConst ? Keyword.CONST : null;
      var typeArguments =
          _buildTypeArgumentList([expr.keyType, expr.valueType]);

      int numberOfEntries = expr.entries.length;
      var entries = new List<MapLiteralEntry>(numberOfEntries);
      for (int i = 0; i < numberOfEntries; i++) {
        var entry = expr.entries[i];
        Expression key = build(entry.key);
        Expression value = build(entry.value);
        entries[i] = AstTestFactory.mapLiteralEntry2(key, value);
      }

      return AstTestFactory.mapLiteral(keyword, typeArguments, entries);
    }

    if (expr is kernel.StaticGet) {
      return _buildIdentifier(expr.targetReference, isGet: true);
    }

    if (expr is kernel.PropertyGet) {
      Expression target = build(expr.receiver);
      kernel.Reference reference = expr.interfaceTargetReference;
      SimpleIdentifier identifier = _buildSimpleIdentifier(reference);
      return AstTestFactory.propertyAccess(target, identifier);
    }

    if (expr is kernel.ConditionalExpression) {
      var condition = build(expr.condition);
      var then = build(expr.then);
      var otherwise = build(expr.otherwise);
      return AstTestFactory.conditionalExpression(condition, then, otherwise);
    }

    if (expr is kernel.Not) {
      kernel.Expression kernelOperand = expr.operand;
      var operand = build(kernelOperand);
      return AstTestFactory.prefixExpression(TokenType.BANG, operand);
    }

    if (expr is kernel.LogicalExpression) {
      var operator = _toBinaryOperatorTokenType(expr.operator);
      var left = build(expr.left);
      var right = build(expr.right);
      return AstTestFactory.binaryExpression(left, operator, right);
    }

    if (expr is kernel.MethodInvocation) {
      kernel.Member member = expr.interfaceTarget;
      if (member is kernel.Procedure) {
        if (member.kind == kernel.ProcedureKind.Operator) {
          var left = build(expr.receiver);
          String operatorName = expr.name.name;
          List<kernel.Expression> args = expr.arguments.positional;
          if (args.isEmpty) {
            if (operatorName == 'unary-') {
              return AstTestFactory.prefixExpression(TokenType.MINUS, left);
            }
            if (operatorName == '~') {
              return AstTestFactory.prefixExpression(TokenType.TILDE, left);
            }
          } else if (args.length == 1) {
            var operator = _toBinaryOperatorTokenType(operatorName);
            var right = build(args.single);
            return AstTestFactory.binaryExpression(left, operator, right);
          }
        }
      }
    }

    if (expr is kernel.StaticInvocation) {
      kernel.Procedure target = expr.target;
      String name = target.name.name;
      List<Expression> arguments = _toArguments(expr.arguments);
      MethodInvocation invocation =
          AstTestFactory.methodInvocation3(null, name, null, arguments);
      invocation.methodName.staticElement = _getElement(target.reference);
      return invocation;
    }

    if (expr is kernel.ConstructorInvocation) {
      var element = _getElement(expr.targetReference);

      var kernelType = expr.getStaticType(_context._resynthesizer._types);
      var type = _context.getType(null, kernelType);
      TypeName typeName = _buildType(type);

      var constructorName = AstTestFactory.constructorName(
          typeName, element.name.isNotEmpty ? element.name : null);
      constructorName?.name?.staticElement = element;

      var keyword = expr.isConst ? Keyword.CONST : Keyword.NEW;
      var arguments = _toArguments(expr.arguments);
      return AstTestFactory.instanceCreationExpression(
          keyword, constructorName, arguments);
    }

    // TODO(scheglov): complete getExpression
    throw new UnimplementedError('kernel: (${expr.runtimeType}) $expr');
  }

  ConstructorInitializer buildInitializer(kernel.Initializer k) {
    if (k is kernel.FieldInitializer) {
      Expression value = build(k.value);
      ConstructorFieldInitializer initializer = AstTestFactory
          .constructorFieldInitializer(false, k.field.name.name, value);
      initializer.fieldName.staticElement = _getElement(k.fieldReference);
      return initializer;
    }

    if (k is kernel.RedirectingInitializer) {
      ConstructorElementImpl redirect = _getElement(k.targetReference);
      var arguments = _toArguments(k.arguments);

      RedirectingConstructorInvocation invocation =
          AstTestFactory.redirectingConstructorInvocation(arguments);
      invocation.staticElement = redirect;

      String name = k.target.name.name;
      if (name.isNotEmpty) {
        invocation.constructorName = AstTestFactory.identifier3(name)
          ..staticElement = redirect;
      }

      return invocation;
    }

    if (k is kernel.SuperInitializer) {
      ConstructorElementImpl redirect = _getElement(k.targetReference);
      var arguments = _toArguments(k.arguments);

      SuperConstructorInvocation invocation =
          AstTestFactory.superConstructorInvocation(arguments);
      invocation.staticElement = redirect;

      String name = k.target.name.name;
      if (name.isNotEmpty) {
        invocation.constructorName = AstTestFactory.identifier3(name)
          ..staticElement = redirect;
      }

      return invocation;
    }

    // TODO(scheglov) Support other kernel initializer types.
    throw new UnimplementedError('For ${k.runtimeType}');
  }

  Expression _buildIdentifier(kernel.Reference reference, {bool isGet: false}) {
    Element element = _getElement(reference);
    if (isGet && element is PropertyInducingElement) {
      element = (element as PropertyInducingElement).getter;
    }
    SimpleIdentifier property = AstTestFactory.identifier3(element.displayName)
      ..staticElement = element;
    Element enclosingElement = element.enclosingElement;
    if (enclosingElement is ClassElement) {
      SimpleIdentifier classRef = AstTestFactory
          .identifier3(enclosingElement.name)
            ..staticElement = enclosingElement;
      return AstTestFactory.propertyAccess(classRef, property);
    } else {
      return property;
    }
  }

  SimpleIdentifier _buildSimpleIdentifier(kernel.Reference reference) {
    String name = reference.canonicalName.name;
    SimpleIdentifier identifier = AstTestFactory.identifier3(name);
    Element element = _getElement(reference);
    identifier.staticElement = element;
    return identifier;
  }

  TypeAnnotation _buildType(DartType type) {
    if (type is InterfaceType) {
      var name = AstTestFactory.identifier3(type.element.name)
        ..staticElement = type.element
        ..staticType = type;
      List<TypeAnnotation> arguments = _buildTypeArguments(type.typeArguments);
      return AstTestFactory.typeName3(name, arguments)..type = type;
    }
    if (type is DynamicTypeImpl) {
      var name = AstTestFactory.identifier3('dynamic')
        ..staticElement = type.element
        ..staticType = type;
      return AstTestFactory.typeName3(name)..type = type;
    }
    // TODO(scheglov) Implement for other types.
    throw new UnimplementedError('type: $type');
  }

  TypeArgumentList _buildTypeArgumentList(List<kernel.DartType> kernels) {
    int length = kernels.length;
    var types = new List<TypeAnnotation>(length);
    for (int i = 0; i < length; i++) {
      DartType type = _context.getType(null, kernels[i]);
      TypeAnnotation typeAnnotation = _buildType(type);
      types[i] = typeAnnotation;
    }
    return AstTestFactory.typeArgumentList(types);
  }

  List<TypeAnnotation> _buildTypeArguments(List<DartType> types) {
    if (types.every((t) => t.isDynamic)) return null;
    return types.map(_buildType).toList();
  }

  ElementImpl _getElement(kernel.Reference reference) {
    return _context._getElement(reference?.canonicalName);
  }

  InterpolationElement _newInterpolationElement(Expression expr) {
    if (expr is SimpleStringLiteral) {
      return astFactory.interpolationString(expr.literal, expr.value);
    } else {
      return AstTestFactory.interpolationExpression(expr);
    }
  }

  /// Return [Expression]s for the given [kernelArguments].
  List<Expression> _toArguments(kernel.Arguments kernelArguments) {
    int numPositional = kernelArguments.positional.length;
    int numNamed = kernelArguments.named.length;
    var arguments = new List<Expression>(numPositional + numNamed);

    int i = 0;
    for (kernel.Expression k in kernelArguments.positional) {
      arguments[i++] = build(k);
    }

    for (kernel.NamedExpression k in kernelArguments.named) {
      var value = build(k.value);
      arguments[i++] = AstTestFactory.namedExpression2(k.name, value);
    }

    return arguments;
  }

  /// Return the [TokenType] for the given operator [name].
  TokenType _toBinaryOperatorTokenType(String name) {
    if (name == '==') return TokenType.EQ_EQ;
    if (name == '&&') return TokenType.AMPERSAND_AMPERSAND;
    if (name == '||') return TokenType.BAR_BAR;
    if (name == '^') return TokenType.CARET;
    if (name == '&') return TokenType.AMPERSAND;
    if (name == '|') return TokenType.BAR;
    if (name == '>>') return TokenType.GT_GT;
    if (name == '<<') return TokenType.LT_LT;
    if (name == '+') return TokenType.PLUS;
    if (name == '-') return TokenType.MINUS;
    if (name == '*') return TokenType.STAR;
    if (name == '/') return TokenType.SLASH;
    if (name == '~/') return TokenType.TILDE_SLASH;
    if (name == '%') return TokenType.PERCENT;
    if (name == '>') return TokenType.GT;
    if (name == '<') return TokenType.LT;
    if (name == '>=') return TokenType.GT_EQ;
    if (name == '<=') return TokenType.LT_EQ;
    if (name == 'unary-') return TokenType.MINUS;
    throw new ArgumentError(name);
  }
}

/**
 * Implementation of [KernelLibraryResynthesizerContext].
 */
class _KernelLibraryResynthesizerContextImpl
    implements KernelLibraryResynthesizerContext {
  final KernelResynthesizer _resynthesizer;

  @override
  final kernel.Library library;

  _KernelLibraryResynthesizerContextImpl(this._resynthesizer, this.library);

  @override
  ConstructorInitializer getConstructorInitializer(
      ConstructorElementImpl constructor, kernel.Initializer k) {
    if (k is kernel.LocalInitializer ||
        k is kernel.FieldInitializer && k.isSynthetic ||
        k is kernel.SuperInitializer && k.isSynthetic) {
      return null;
    }
    return new _ExprBuilder(this).buildInitializer(k);
  }

  @override
  ElementImpl getElement(kernel.Reference reference) {
    return _getElement(reference.canonicalName);
  }

  @override
  Expression getExpression(kernel.Expression expression) {
    return new _ExprBuilder(this).build(expression);
  }

  @override
  InterfaceType getInterfaceType(
      ElementImpl context, kernel.Supertype kernelType) {
    return _getInterfaceType(
        context, kernelType.className.canonicalName, kernelType.typeArguments);
  }

  @override
  LibraryElement getLibrary(String uriStr) {
    return _resynthesizer.getLibrary(uriStr);
  }

  DartType getType(ElementImpl context, kernel.DartType kernelType) {
    if (kernelType is kernel.DynamicType) return DynamicTypeImpl.instance;
    if (kernelType is kernel.VoidType) return VoidTypeImpl.instance;

    if (kernelType is kernel.InterfaceType) {
      return _getInterfaceType(context, kernelType.className.canonicalName,
          kernelType.typeArguments);
    }

    if (kernelType is kernel.TypeParameterType) {
      kernel.TypeParameter kTypeParameter = kernelType.parameter;
      return _getTypeParameter(context, kTypeParameter).type;
    }

    if (kernelType is kernel.FunctionType) {
      var functionElement = new FunctionElementImpl.synthetic([], null);
      functionElement.enclosingElement = context;

      functionElement.typeParameters = kernelType.typeParameters.map((k) {
        return new TypeParameterElementImpl.forKernel(functionElement, k);
      }).toList(growable: false);

      functionElement.parameters = ParameterElementImpl.forKernelParameters(
          functionElement,
          kernelType.requiredParameterCount,
          kernelType.positionalParameters
              .map((t) => new kernel.VariableDeclaration(null, type: t))
              .toList(),
          kernelType.namedParameters
              .map((t) => new kernel.VariableDeclaration(t.name, type: t.type))
              .toList());

      functionElement.returnType =
          getType(functionElement, kernelType.returnType);
      return functionElement.type;
    }

    // TODO(scheglov) Support other kernel types.
    throw new UnimplementedError('For ${kernelType.runtimeType}');
  }

  /**
   * Return the [ElementImpl] that corresponds to the given [name], or `null`
   * if the corresponding element cannot be found.
   */
  ElementImpl _getElement(kernel.CanonicalName name) {
    if (name == null) return null;
    kernel.CanonicalName parentName = name.parent;

    // If the parent is the root, then this name is a library.
    if (parentName.isRoot) {
      return _resynthesizer.getLibrary(name.name);
    }

    // If the name is private, it is prefixed with a library URI.
    if (name.name.startsWith('_')) {
      parentName = parentName.parent;
    }

    // Skip qualifiers.
    bool isGetter = false;
    bool isSetter = false;
    bool isField = false;
    bool isConstructor = false;
    bool isMethod = false;
    if (parentName.name == '@getters') {
      isGetter = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@setters') {
      isSetter = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@fields') {
      isField = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@constructors') {
      isConstructor = true;
      parentName = parentName.parent;
    } else if (parentName.name == '@methods') {
      isMethod = true;
      parentName = parentName.parent;
    }

    ElementImpl parentElement = _getElement(parentName);
    if (parentElement == null) return null;

    // Search in units of the library.
    if (parentElement is LibraryElementImpl) {
      for (CompilationUnitElement unit in parentElement.units) {
        CompilationUnitElementImpl unitImpl = unit;
        ElementImpl child = unitImpl.getChild(name.name);
        if (child != null) {
          return child;
        }
      }
      return null;
    }

    // Search in the class.
    if (parentElement is ClassElementImpl) {
      if (isGetter) {
        return parentElement.getGetter(name.name) as ElementImpl;
      } else if (isSetter) {
        return parentElement.getSetter(name.name) as ElementImpl;
      } else if (isField) {
        return parentElement.getField(name.name) as ElementImpl;
      } else if (isConstructor) {
        if (name.name.isEmpty) {
          return parentElement.unnamedConstructor as ConstructorElementImpl;
        }
        return parentElement.getNamedConstructor(name.name) as ElementImpl;
      } else if (isMethod) {
        return parentElement.getMethod(name.name) as ElementImpl;
      }
      return null;
    }

    throw new UnimplementedError('Should not be reached.');
  }

  InterfaceType _getInterfaceType(ElementImpl context,
      kernel.CanonicalName className, List<kernel.DartType> kernelArguments) {
    var libraryName = className.parent;
    var libraryElement = _resynthesizer.getLibrary(libraryName.name);
    ClassElementImpl classElement = libraryElement.getType(className.name);

    if (kernelArguments.isEmpty) {
      return classElement.type;
    }

    return new InterfaceTypeImpl.elementWithNameAndArgs(
        classElement, classElement.name, () {
      List<DartType> arguments = kernelArguments
          .map((kernel.DartType k) => getType(context, k))
          .toList(growable: false);
      return arguments;
    });
  }

  /// Return the [TypeParameterElement] for the given [kernelTypeParameter].
  TypeParameterElement _getTypeParameter(
      ElementImpl context, kernel.TypeParameter kernelTypeParameter) {
    String name = kernelTypeParameter.name;
    for (var ctx = context; ctx != null; ctx = ctx.enclosingElement) {
      if (ctx is TypeParameterizedElementMixin) {
        for (var typeParameter in ctx.typeParameters) {
          if (typeParameter.name == name) {
            return typeParameter;
          }
        }
      }
    }
    throw new StateError('Not found $kernelTypeParameter in $context');
  }
}
