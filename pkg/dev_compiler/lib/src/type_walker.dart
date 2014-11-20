/*
 * This code is adapted from the Dart analyzer's StaticTypeAnalyzer class.
 */

library typewalker;

import 'package:analyzer/analyzer.dart';
import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/scanner.dart' as sc;

/// Instances of the class `StaticTypeAnalyzer` perform two type-related tasks.
/// First, they compute the static type of every expression. Second, they look
/// for any static type errors or warnings that might need to be generated. The
/// requirements for the type analyzer are:
///
///   * Every element that refers to types should be fully populated.
///   * Every node representing an expression should be resolved to the Type of
///     the expression.
class RestrictedTypeWalker extends SimpleAstVisitor {

  /// Object providing access to the types defined by the language.
  final TypeProvider _typeProvider;

  /// The enclosing library element.
  final LibraryElement _libraryElement;

  /// The type representing the type 'dynamic'.
  DartType _dynamicType;

  /// The type representing the class containing the nodes being analyzed, or
  /// `null` if the nodes are not within a class.
  InterfaceType thisType;

  ///  A map of expressions to static start types.
  Map<Expression, DartType> _startTypes = new Map<Expression, DartType>();

  RestrictedTypeWalker(this._typeProvider, this._libraryElement) {
    _dynamicType = _typeProvider.dynamicType;
  }

  @override
  Object visitAdjacentStrings(AdjacentStrings node) {
    _recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  @override
  Object visitAsExpression(AsExpression node) {
    _recordStaticType(node, _getType(node.type));
    return null;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.TokenType operator = node.operator.type;
    if (operator == sc.TokenType.EQ) {
      Expression rightHandSide = node.rightHandSide;
      DartType staticType = getStaticType(rightHandSide);
      _recordStaticType(node, staticType);
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      _recordStaticType(node, staticType);
    }
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    ExecutableElement staticMethodElement = node.staticElement;
    // TODO(vsm): check...
    DartType staticType = _computeStaticReturnType(staticMethodElement);
    staticType = _refineBinaryExpressionType(node, staticType);
    _recordStaticType(node, staticType);
    return null;
  }

  @override
  Object visitBooleanLiteral(BooleanLiteral node) {
    _recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  @override
  Object visitCascadeExpression(CascadeExpression node) {
    _recordStaticType(node, getStaticType(node.target));
    return null;
  }

  @override
  Object visitConditionalExpression(ConditionalExpression node) {
    DartType staticThenType = getStaticType(node.thenExpression);
    DartType staticElseType = getStaticType(node.elseExpression);
    if (staticThenType == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticThenType = _dynamicType;
    }
    if (staticElseType == null) {
      // TODO(brianwilkerson) Determine whether this can still happen.
      staticElseType = _dynamicType;
    }
    // TODO(vsm): check... lub in rules?
    DartType staticType = staticThenType.getLeastUpperBound(staticElseType);
    if (staticType == null) {
      staticType = _dynamicType;
    }
    _recordStaticType(node, staticType);
    return null;
  }

  @override
  Object visitDoubleLiteral(DoubleLiteral node) {
    _recordStaticType(node, _typeProvider.doubleType);
    return null;
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    FunctionExpression function = node.functionExpression;
    ExecutableElementImpl functionElement =
        node.element as ExecutableElementImpl;
    // TODO(vsm): Should we ever use the expression type in a (...) => expr or
    // just the written type?
    functionElement.returnType =
        _computeStaticReturnTypeOfFunctionDeclaration(node);
    _recordStaticType(function, functionElement.type);
    return null;
  }

  @override
  Object visitFunctionExpression(FunctionExpression node) {
    if (node.parent is FunctionDeclaration) {
      // The function type will be resolved and set when we visit the parent
      // node.
      return null;
    }
    ExecutableElementImpl functionElement =
        node.element as ExecutableElementImpl;
    functionElement.returnType =
        _computeStaticReturnTypeOfFunctionExpression(node);
    _recordStaticType(node, baseElementType(node.element));
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    ExecutableElement staticMethodElement = node.staticElement;
    // Record static return type of the static element.
    DartType staticStaticType = _computeStaticReturnType(staticMethodElement);
    _recordStaticType(node, staticStaticType);
    return null;
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    if (node.inSetterContext()) {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeArgumentType(staticMethodElement);
      _recordStaticType(node, staticType);
    } else {
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      _recordStaticType(node, staticType);
    }
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    FunctionType staticType = baseElementType(node.staticElement);
    _recordStaticType(
        node, staticType.returnType /*node.constructorName.type.type*/);
    ConstructorElement element = node.staticElement;
    if (element != null && "Element" == element.enclosingElement.name) {
      LibraryElement library = element.library;
    }
    return null;
  }

  @override
  Object visitIntegerLiteral(IntegerLiteral node) {
    _recordStaticType(node, _typeProvider.intType);
    return null;
  }

  @override
  Object visitIsExpression(IsExpression node) {
    _recordStaticType(node, _typeProvider.boolType);
    return null;
  }

  @override
  Object visitListLiteral(ListLiteral node) {
    // TODO(vsm): Erasure!
    _recordStaticType(node, _typeProvider.listType
        .substitute4(<DartType>[_dynamicType]));
    return null;
  }

  @override
  Object visitMapLiteral(MapLiteral node) {
    // TODO(vsm): Erasure!
    DartType staticKeyType = _dynamicType;
    DartType staticValueType = _dynamicType;
    _recordStaticType(node, _typeProvider.mapType
        .substitute4(<DartType>[staticKeyType, staticValueType]));
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier methodNameNode = node.methodName;
    Element staticMethodElement = methodNameNode.staticElement;
    // Record types of the local variable invoked as a function.
    if (staticMethodElement is LocalVariableElement) {
      LocalVariableElement variable = staticMethodElement;
      DartType staticType = variableType(variable);
      _recordStaticType(methodNameNode, staticType);
    }
    // Record static return type of the static element.
    DartType staticStaticType = _computeStaticReturnType(staticMethodElement);
    _recordStaticType(node, staticStaticType);
    return null;
  }

  @override
  Object visitNamedExpression(NamedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, getStaticType(expression));
    return null;
  }

  @override
  Object visitNullLiteral(NullLiteral node) {
    _recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  @override
  Object visitParenthesizedExpression(ParenthesizedExpression node) {
    Expression expression = node.expression;
    _recordStaticType(node, getStaticType(expression));
    return null;
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    Expression operand = node.operand;
    DartType staticType = getStaticType(operand);
    sc.TokenType operator = node.operator.type;
    if (operator ==
        sc.TokenType.MINUS_MINUS || operator == sc.TokenType.PLUS_PLUS) {
      DartType intType = _typeProvider.intType;
      if (identical(getStaticType(node.operand), intType)) {
        staticType = intType;
      }
    }
    _recordStaticType(node, staticType);
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefixedIdentifier = node.identifier;
    Element staticElement = prefixedIdentifier.staticElement;
    DartType staticType = _dynamicType;
    if (staticElement is ClassElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = baseElementType(staticElement);
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (staticElement is FunctionTypeAliasElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = baseElementType(staticElement);
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (staticElement is MethodElement) {
      staticType = baseElementType(staticElement);
    } else if (staticElement is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(staticElement, node.prefix.staticType);
    } else if (staticElement is ExecutableElement) {
      staticType = baseElementType(staticElement);
    } else if (staticElement is TypeParameterElement) {
      staticType = _dynamicType;
      // staticType = baseElementType(staticElement);
    } else if (staticElement is VariableElement) {
      staticType = baseElementType(staticElement);
    }
    _recordStaticType(prefixedIdentifier, staticType);
    _recordStaticType(node, staticType);
    return null;
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    sc.TokenType operator = node.operator.type;
    if (operator == sc.TokenType.BANG) {
      _recordStaticType(node, _typeProvider.boolType);
    } else {
      // The other cases are equivalent to invoking a method.
      ExecutableElement staticMethodElement = node.staticElement;
      DartType staticType = _computeStaticReturnType(staticMethodElement);
      if (operator ==
          sc.TokenType.MINUS_MINUS || operator == sc.TokenType.PLUS_PLUS) {
        DartType intType = _typeProvider.intType;
        if (identical(getStaticType(node.operand), intType)) {
          staticType = intType;
        }
      }
      _recordStaticType(node, staticType);
    }
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    SimpleIdentifier propertyName = node.propertyName;
    Element staticElement = propertyName.staticElement;
    DartType staticType = _dynamicType;
    if (staticElement is MethodElement) {
      staticType = baseElementType(staticElement);
    } else if (staticElement is PropertyAccessorElement) {
      Expression realTarget = node.realTarget;
      staticType = _getTypeOfProperty(
          staticElement, realTarget != null ? getStaticType(realTarget) : null);
    }
    _recordStaticType(propertyName, staticType);
    _recordStaticType(node, staticType);
    return null;
  }

  @override
  Object visitRethrowExpression(RethrowExpression node) {
    _recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    DartType staticType = _dynamicType;
    if (element is ClassElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = baseElementType(element);
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is FunctionTypeAliasElement) {
      if (_isNotTypeLiteral(node)) {
        staticType = baseElementType(element);
      } else {
        staticType = _typeProvider.typeType;
      }
    } else if (element is MethodElement) {
      staticType = baseElementType(element);
    } else if (element is PropertyAccessorElement) {
      staticType = _getTypeOfProperty(element, null);
    } else if (element is ExecutableElement) {
      staticType = baseElementType(element);
    } else if (element is TypeParameterElement) {
      // staticType = _typeProvider.typeType;
      staticType = _dynamicType;
    } else if (element is VariableElement) {
      VariableElement variable = element;
      // FIXME(vsm): Do we allow this?
      // staticType = _promoteManager.getStaticType(variable);
      staticType = variableType(variable);
    } else if (element is PrefixElement) {
      return null;
    } else {
      staticType = _dynamicType;
    }
    _recordStaticType(node, staticType);
    return null;
  }

  @override
  Object visitSimpleStringLiteral(SimpleStringLiteral node) {
    _recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  @override
  Object visitStringInterpolation(StringInterpolation node) {
    _recordStaticType(node, _typeProvider.stringType);
    return null;
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    if (_thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported
      _recordStaticType(node, _dynamicType);
    } else {
      _recordStaticType(node, _thisType);
    }
    return null;
  }

  @override
  Object visitSymbolLiteral(SymbolLiteral node) {
    _recordStaticType(node, _typeProvider.symbolType);
    return null;
  }

  @override
  Object visitThisExpression(ThisExpression node) {
    if (_thisType == null) {
      // TODO(brianwilkerson) Report this error if it hasn't already been
      // reported
      _recordStaticType(node, _dynamicType);
    } else {
      _recordStaticType(node, _thisType);
    }
    return null;
  }

  @override
  Object visitThrowExpression(ThrowExpression node) {
    _recordStaticType(node, _typeProvider.bottomType);
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    Expression initializer = node.initializer;
    // FIXME(vsm): Need this?
    if (initializer != null) {
      DartType type = getStaticType(initializer);
      VariableElement element = node.element;
      if (element.type == _dynamicType) _setVariableType(element, type);
    }
    return null;
  }

  /// Extract the type of the second argument to [method].
  DartType _computeArgumentType(ExecutableElement method) {
    if (method != null) {
      List<ParameterElement> parameters = method.parameters;
      if (parameters != null && parameters.length == 2) {
        return parameters[1].type;
      }
    }
    return _dynamicType;
  }

  /// Return the static return type of the method or function represented by
  /// [element].
  DartType _computeStaticReturnType(Element element) {
    if (element is PropertyAccessorElement) {
      // This is a function invocation expression disguised as something else.
      // We are invoking a getter and then invoking the returned function.
      FunctionType propertyType = baseElementType(element);
      if (propertyType != null) {
        DartType returnType = propertyType.returnType;
        if (returnType.isDartCoreFunction) {
          return _dynamicType;
        } else if (returnType is InterfaceType) {
          MethodElement callMethod = returnType
              .lookUpMethod(FunctionElement.CALL_METHOD_NAME, _libraryElement);
          if (callMethod != null) {
            return callMethod.type.returnType;
          }
        } else if (returnType is FunctionType) {
          DartType innerReturnType = returnType.returnType;
          if (innerReturnType != null) {
            return innerReturnType;
          }
        }
        if (returnType != null) {
          return returnType;
        }
      }
    } else if (element is ExecutableElement) {
      // TODO(vsm): Better place for this logic?
      FunctionType type = baseElementType(element);
      if (type != null) {
        // TODO(brianwilkerson) Figure out the conditions under which the type
        // is null.
        return type.returnType;
      }
    } else if (element is VariableElement) {
      VariableElement variable = element;
      // TODO(vsm): Remove?
      DartType varType =
          variableType(variable); //_promoteManager.getStaticType(variable);
      if (varType is FunctionType) {
        return varType.returnType;
      }
    }
    return _dynamicType;
  }

  /// Compute the return static type of [function].
  DartType _computeStaticReturnTypeOfFunctionDeclaration(
      FunctionDeclaration function) {
    TypeName returnType = function.returnType;
    if (returnType == null) {
      return _dynamicType;
    }
    return returnType.type;
  }

  /// Compute the return static type of [function]. The return type of functions
  /// with a block body is `dynamicType`, with an expression body it is the type
  /// of the expression.
  DartType _computeStaticReturnTypeOfFunctionExpression(
      FunctionExpression function) {
    FunctionBody body = function.body;
    if (body is ExpressionFunctionBody) {
      return getStaticType(body.expression);
    }
    return _dynamicType;
  }

  /// Return the static type of the given [expression].
  DartType getStaticType(Expression expression) {
    if (!_startTypes.containsKey(expression)) {
      expression.accept(this);
      assert(_startTypes.containsKey(expression));
    }
    DartType type = _startTypes[expression]; //expression.staticType;
    if (type == null) {
      // TODO(brianwilkerson) Determine the conditions for which the static type
      // is null.
      return _dynamicType;
    }
    return type;
  }

  /// Return the type represented by the given type [name].
  DartType _getType(TypeName name) {
    DartType type = name.type;
    if (type == null) {
      //TODO(brianwilkerson) Determine the conditions for which the type is
      //null.
      return _dynamicType;
    }
    return type;
  }

  /// Return the type that should be recorded for a node that resolved to the
  /// given [accessor].
  DartType _getTypeOfProperty(
      PropertyAccessorElement accessor, DartType context) {
    FunctionType functionType = accessor.type;
    if (functionType == null) {
      // TODO(brianwilkerson) Report this internal error. This happens when we
      // are analyzing a reference to a property before we have analyzed the
      // declaration of the property or when the property does not have a
      // defined type.
      return _dynamicType;
    }
    if (accessor.isSetter) {
      List<DartType> parameterTypes = functionType.normalParameterTypes;
      if (parameterTypes != null && parameterTypes.length > 0) {
        return parameterTypes[0];
      }
      PropertyAccessorElement getter = accessor.variable.getter;
      if (getter != null) {
        functionType = getter.type;
        if (functionType != null) {
          return functionType.returnType;
        }
      }
      return _dynamicType;
    }
    DartType returnType = functionType.returnType;
    // TODO(vsm): Is this what we want?
    if (returnType is TypeParameterType) return _dynamicType;
    // TODO(vsm): Delete?
    if (returnType is TypeParameterType && context is InterfaceType) {
      // if the return type is a TypeParameter, we try to use the context [that
      // the function is being called on] to get a more accurate returnType type
      InterfaceType interfaceTypeContext = context;
      //      Type[] argumentTypes = interfaceTypeContext.getTypeArguments();
      List<TypeParameterElement> typeParameterElements =
          interfaceTypeContext.element != null ?
          interfaceTypeContext.element.typeParameters : null;
      if (typeParameterElements != null) {
        for (int i = 0; i < typeParameterElements.length; i++) {
          TypeParameterElement typeParameterElement = typeParameterElements[i];
          if (returnType.name == typeParameterElement.name) {
            return interfaceTypeContext.typeArguments[i];
          }
        }
      }
    }
    return returnType;
  }

  bool _isNotTypeLiteral(Identifier node) {
    AstNode parent = node.parent;
    return parent is TypeName ||
        (parent is PrefixedIdentifier &&
        (parent.parent is TypeName || identical(parent.prefix, node))) ||
        (parent is PropertyAccess && identical(parent.target, node)) ||
        (parent is MethodInvocation && identical(node, parent.target));
  }

  /// Record that the static type of [expression] is [type].
  void _recordStaticType(Expression expression, DartType type) {
    // TODO(vsm): Erase generics?
    if (type == null) {
      _startTypes[expression] = _dynamicType;
    } else {
      _startTypes[expression] = type;
    }
  }

  /// Attempts to make a better guess for the static type of the given binary
  /// [expression]. [staticType] is the static type of the expression as
  /// resolved.
  DartType _refineBinaryExpressionType(
      BinaryExpression expression, DartType staticType) {
    sc.TokenType operator = expression.operator.type;
    // bool
    if (operator == sc.TokenType.AMPERSAND_AMPERSAND ||
        operator == sc.TokenType.BAR_BAR ||
        operator == sc.TokenType.EQ_EQ ||
        operator == sc.TokenType.BANG_EQ) {
      return _typeProvider.boolType;
    }
    DartType intType = _typeProvider.intType;
    if (getStaticType(expression.leftOperand) == intType) {
      // int op double
      if (operator == sc.TokenType.MINUS ||
          operator == sc.TokenType.PERCENT ||
          operator == sc.TokenType.PLUS ||
          operator == sc.TokenType.STAR) {
        DartType doubleType = _typeProvider.doubleType;
        if (getStaticType(expression.rightOperand) == doubleType) {
          return doubleType;
        }
      }
      // int op int
      if (operator == sc.TokenType.MINUS ||
          operator == sc.TokenType.PERCENT ||
          operator == sc.TokenType.PLUS ||
          operator == sc.TokenType.STAR ||
          operator == sc.TokenType.TILDE_SLASH) {
        if (getStaticType(expression.rightOperand) == intType) {
          staticType = intType;
        }
      }
    }
    // default
    return staticType;
  }

  DartType dynamize(DartType type) {
    if (type is ParameterizedType) {
      int len = type.typeParameters.length;
      if (len > 0) {
        var params = new List.filled(len, _dynamicType);
        return type.substitute2(params, type.typeArguments);
      }
    }
    // Erasure
    if (type is TypeParameterElement) type = _dynamicType;
    return type;
  }

  DartType baseElementType(Element element) {
    DartType type = null;
    if (element is Member) element = (element as Member).baseElement;
    if (element is ExecutableElement) type = element.type;
    if (element is VariableElement) type = variableType(element);
    if (element is ClassElement) type = element.type;
    if (element is FunctionTypeAliasElement) type = element.type;
    if (element is TypeParameterElement) type = element.type;
    assert(type != null);
    return dynamize(type);
  }

  Map<VariableElement, DartType> _variableTypeMap =
      new Map<VariableElement, DartType>();

  void _setVariableType(VariableElement element, DartType type) {
    _variableTypeMap[element] = type;
  }

  DartType variableType(VariableElement element) {
    if (_variableTypeMap.containsKey(element)) return _variableTypeMap[element];
    return element.type;
  }
}
