// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library engine.resolver.element_resolver;

import 'dart:collection';

import 'ast.dart';
import 'element.dart';
import 'engine.dart';
import 'error.dart';
import 'resolver.dart';
import 'scanner.dart' as sc;
import 'utilities_dart.dart';

/**
 * An object used by instances of [ResolverVisitor] to resolve references within
 * the AST structure to the elements being referenced. The requirements for the
 * element resolver are:
 *
 * 1. Every [SimpleIdentifier] should be resolved to the element to which it
 *    refers. Specifically:
 *    * An identifier within the declaration of that name should resolve to the
 *      element being declared.
 *    * An identifier denoting a prefix should resolve to the element
 *      representing the import that defines the prefix (an [ImportElement]).
 *    * An identifier denoting a variable should resolve to the element
 *      representing the variable (a [VariableElement]).
 *    * An identifier denoting a parameter should resolve to the element
 *      representing the parameter (a [ParameterElement]).
 *    * An identifier denoting a field should resolve to the element
 *      representing the getter or setter being invoked (a
 *      [PropertyAccessorElement]).
 *    * An identifier denoting the name of a method or function being invoked
 *      should resolve to the element representing the method or function (an
 *      [ExecutableElement]).
 *    * An identifier denoting a label should resolve to the element
 *      representing the label (a [LabelElement]).
 *    The identifiers within directives are exceptions to this rule and are
 *    covered below.
 * 2. Every node containing a token representing an operator that can be
 *    overridden ( [BinaryExpression], [PrefixExpression], [PostfixExpression])
 *    should resolve to the element representing the method invoked by that
 *    operator (a [MethodElement]).
 * 3. Every [FunctionExpressionInvocation] should resolve to the element
 *    representing the function being invoked (a [FunctionElement]). This will
 *    be the same element as that to which the name is resolved if the function
 *    has a name, but is provided for those cases where an unnamed function is
 *    being invoked.
 * 4. Every [LibraryDirective] and [PartOfDirective] should resolve to the
 *    element representing the library being specified by the directive (a
 *    [LibraryElement]) unless, in the case of a part-of directive, the
 *    specified library does not exist.
 * 5. Every [ImportDirective] and [ExportDirective] should resolve to the
 *    element representing the library being specified by the directive unless
 *    the specified library does not exist (an [ImportElement] or
 *    [ExportElement]).
 * 6. The identifier representing the prefix in an [ImportDirective] should
 *    resolve to the element representing the prefix (a [PrefixElement]).
 * 7. The identifiers in the hide and show combinators in [ImportDirective]s
 *    and [ExportDirective]s should resolve to the elements that are being
 *    hidden or shown, respectively, unless those names are not defined in the
 *    specified library (or the specified library does not exist).
 * 8. Every [PartDirective] should resolve to the element representing the
 *    compilation unit being specified by the string unless the specified
 *    compilation unit does not exist (a [CompilationUnitElement]).
 *
 * Note that AST nodes that would represent elements that are not defined are
 * not resolved to anything. This includes such things as references to
 * undeclared variables (which is an error) and names in hide and show
 * combinators that are not defined in the imported library (which is not an
 * error).
 */
class ElementResolver extends SimpleAstVisitor<Object> {
  /**
   * The resolver driving this participant.
   */
  final ResolverVisitor _resolver;

  /**
   * The element for the library containing the compilation unit being visited.
   */
  LibraryElement _definingLibrary;

  /**
   * A flag indicating whether we should generate hints.
   */
  bool _enableHints = false;

  /**
   * A flag indicating whether we should strictly follow the specification when
   * generating warnings on "call" methods (fixes dartbug.com/21938).
   */
  bool _enableStrictCallChecks = false;

  /**
   * The type representing the type 'dynamic'.
   */
  DartType _dynamicType;

  /**
   * The type representing the type 'type'.
   */
  DartType _typeType;

  /**
   * A utility class for the resolver to answer the question of "what are my
   * subtypes?".
   */
  SubtypeManager _subtypeManager;

  /**
   * The object keeping track of which elements have had their types promoted.
   */
  TypePromotionManager _promoteManager;

  /**
   * Initialize a newly created visitor to work for the given [_resolver] to
   * resolve the nodes in a compilation unit.
   */
  ElementResolver(this._resolver) {
    this._definingLibrary = _resolver.definingLibrary;
    AnalysisOptions options = _definingLibrary.context.analysisOptions;
    _enableHints = options.hint;
    _enableStrictCallChecks = options.enableStrictCallChecks;
    _dynamicType = _resolver.typeProvider.dynamicType;
    _typeType = _resolver.typeProvider.typeType;
    _subtypeManager = new SubtypeManager();
    _promoteManager = _resolver.promoteManager;
  }

  /**
   * Return `true` iff the current enclosing function is a constant constructor
   * declaration.
   */
  bool get isInConstConstructor {
    ExecutableElement function = _resolver.enclosingFunction;
    if (function is ConstructorElement) {
      return function.isConst;
    }
    return false;
  }

  @override
  Object visitAssignmentExpression(AssignmentExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType operatorType = operator.type;
    if (operatorType != sc.TokenType.EQ &&
        operatorType != sc.TokenType.QUESTION_QUESTION_EQ) {
      operatorType = _operatorFromCompoundAssignment(operatorType);
      Expression leftHandSide = node.leftHandSide;
      if (leftHandSide != null) {
        String methodName = operatorType.lexeme;
        DartType staticType = _getStaticType(leftHandSide);
        MethodElement staticMethod =
            _lookUpMethod(leftHandSide, staticType, methodName);
        node.staticElement = staticMethod;
        DartType propagatedType = _getPropagatedType(leftHandSide);
        MethodElement propagatedMethod =
            _lookUpMethod(leftHandSide, propagatedType, methodName);
        node.propagatedElement = propagatedMethod;
        if (_shouldReportMissingMember(staticType, staticMethod)) {
          _recordUndefinedToken(
              staticType.element,
              StaticTypeWarningCode.UNDEFINED_METHOD,
              operator,
              [methodName, staticType.displayName]);
        } else if (_enableHints &&
            _shouldReportMissingMember(propagatedType, propagatedMethod) &&
            !_memberFoundInSubclass(
                propagatedType.element, methodName, true, false)) {
          _recordUndefinedToken(
              propagatedType.element,
              HintCode.UNDEFINED_METHOD,
              operator,
              [methodName, propagatedType.displayName]);
        }
      }
    }
    return null;
  }

  @override
  Object visitBinaryExpression(BinaryExpression node) {
    sc.Token operator = node.operator;
    if (operator.isUserDefinableOperator) {
      _resolveBinaryExpression(node, operator.lexeme);
    } else if (operator.type == sc.TokenType.BANG_EQ) {
      _resolveBinaryExpression(node, sc.TokenType.EQ_EQ.lexeme);
    }
    return null;
  }

  @override
  Object visitBreakStatement(BreakStatement node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, false);
    return null;
  }

  @override
  Object visitClassDeclaration(ClassDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitCommentReference(CommentReference node) {
    Identifier identifier = node.identifier;
    if (identifier is SimpleIdentifier) {
      SimpleIdentifier simpleIdentifier = identifier;
      Element element = _resolveSimpleIdentifier(simpleIdentifier);
      if (element == null) {
        //
        // This might be a reference to an imported name that is missing the
        // prefix.
        //
        element = _findImportWithoutPrefix(simpleIdentifier);
        if (element is MultiplyDefinedElement) {
          // TODO(brianwilkerson) Report this error?
          element = null;
        }
      }
      if (element == null) {
        // TODO(brianwilkerson) Report this error?
        //        resolver.reportError(
        //            StaticWarningCode.UNDEFINED_IDENTIFIER,
        //            simpleIdentifier,
        //            simpleIdentifier.getName());
      } else {
        if (element.library == null || element.library != _definingLibrary) {
          // TODO(brianwilkerson) Report this error?
        }
        simpleIdentifier.staticElement = element;
        if (node.newKeyword != null) {
          if (element is ClassElement) {
            ConstructorElement constructor = element.unnamedConstructor;
            if (constructor == null) {
              // TODO(brianwilkerson) Report this error.
            } else {
              simpleIdentifier.staticElement = constructor;
            }
          } else {
            // TODO(brianwilkerson) Report this error.
          }
        }
      }
    } else if (identifier is PrefixedIdentifier) {
      PrefixedIdentifier prefixedIdentifier = identifier;
      SimpleIdentifier prefix = prefixedIdentifier.prefix;
      SimpleIdentifier name = prefixedIdentifier.identifier;
      Element element = _resolveSimpleIdentifier(prefix);
      if (element == null) {
//        resolver.reportError(StaticWarningCode.UNDEFINED_IDENTIFIER, prefix, prefix.getName());
      } else {
        if (element is PrefixElement) {
          prefix.staticElement = element;
          // TODO(brianwilkerson) Report this error?
          element = _resolver.nameScope.lookup(identifier, _definingLibrary);
          name.staticElement = element;
          return null;
        }
        LibraryElement library = element.library;
        if (library == null) {
          // TODO(brianwilkerson) We need to understand how the library could
          // ever be null.
          AnalysisEngine.instance.logger
              .logError("Found element with null library: ${element.name}");
        } else if (library != _definingLibrary) {
          // TODO(brianwilkerson) Report this error.
        }
        name.staticElement = element;
        if (node.newKeyword == null) {
          if (element is ClassElement) {
            Element memberElement =
                _lookupGetterOrMethod(element.type, name.name);
            if (memberElement == null) {
              memberElement = element.getNamedConstructor(name.name);
              if (memberElement == null) {
                memberElement = _lookUpSetter(prefix, element.type, name.name);
              }
            }
            if (memberElement == null) {
//              reportGetterOrSetterNotFound(prefixedIdentifier, name, element.getDisplayName());
            } else {
              name.staticElement = memberElement;
            }
          } else {
            // TODO(brianwilkerson) Report this error.
          }
        } else {
          if (element is ClassElement) {
            ConstructorElement constructor =
                element.getNamedConstructor(name.name);
            if (constructor == null) {
              // TODO(brianwilkerson) Report this error.
            } else {
              name.staticElement = constructor;
            }
          } else {
            // TODO(brianwilkerson) Report this error.
          }
        }
      }
    }
    return null;
  }

  @override
  Object visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    ConstructorElement element = node.element;
    if (element is ConstructorElementImpl) {
      ConstructorElementImpl constructorElement = element;
      ConstructorName redirectedNode = node.redirectedConstructor;
      if (redirectedNode != null) {
        // set redirected factory constructor
        ConstructorElement redirectedElement = redirectedNode.staticElement;
        constructorElement.redirectedConstructor = redirectedElement;
      } else {
        // set redirected generative constructor
        for (ConstructorInitializer initializer in node.initializers) {
          if (initializer is RedirectingConstructorInvocation) {
            ConstructorElement redirectedElement = initializer.staticElement;
            constructorElement.redirectedConstructor = redirectedElement;
          }
        }
      }
      setMetadata(constructorElement, node);
    }
    return null;
  }

  @override
  Object visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    ClassElement enclosingClass = _resolver.enclosingClass;
    FieldElement fieldElement = enclosingClass.getField(fieldName.name);
    fieldName.staticElement = fieldElement;
    return null;
  }

  @override
  Object visitConstructorName(ConstructorName node) {
    DartType type = node.type.type;
    if (type != null && type.isDynamic) {
      return null;
    } else if (type is! InterfaceType) {
// TODO(brianwilkerson) Report these errors.
//      ASTNode parent = node.getParent();
//      if (parent instanceof InstanceCreationExpression) {
//        if (((InstanceCreationExpression) parent).isConst()) {
//          // CompileTimeErrorCode.CONST_WITH_NON_TYPE
//        } else {
//          // StaticWarningCode.NEW_WITH_NON_TYPE
//        }
//      } else {
//        // This is part of a redirecting factory constructor; not sure which error code to use
//      }
      return null;
    }
    // look up ConstructorElement
    ConstructorElement constructor;
    SimpleIdentifier name = node.name;
    InterfaceType interfaceType = type as InterfaceType;
    if (name == null) {
      constructor = interfaceType.lookUpConstructor(null, _definingLibrary);
    } else {
      constructor =
          interfaceType.lookUpConstructor(name.name, _definingLibrary);
      name.staticElement = constructor;
    }
    node.staticElement = constructor;
    return null;
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, true);
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid
      // TODO(brianwilkerson) Figure out whether the element can ever be
      // something other than an ExportElement
      _resolveCombinators(exportElement.exportedLibrary, node.combinators);
      setMetadata(exportElement, node);
    }
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    _setMetadataForParameter(node.element, node);
    return super.visitFieldFormalParameter(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    // TODO(brianwilkerson) Can we ever resolve the function being invoked?
    Expression expression = node.function;
    if (expression is FunctionExpression) {
      FunctionExpression functionExpression = expression;
      ExecutableElement functionElement = functionExpression.element;
      ArgumentList argumentList = node.argumentList;
      List<ParameterElement> parameters =
          _resolveArgumentsToFunction(false, argumentList, functionElement);
      if (parameters != null) {
        argumentList.correspondingStaticParameters = parameters;
      }
    }
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _setMetadataForParameter(node.element, node);
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    SimpleIdentifier prefixNode = node.prefix;
    if (prefixNode != null) {
      String prefixName = prefixNode.name;
      for (PrefixElement prefixElement in _definingLibrary.prefixes) {
        if (prefixElement.displayName == prefixName) {
          prefixNode.staticElement = prefixElement;
          break;
        }
      }
    }
    ImportElement importElement = node.element;
    if (importElement != null) {
      // The element is null when the URI is invalid
      LibraryElement library = importElement.importedLibrary;
      if (library != null) {
        _resolveCombinators(library, node.combinators);
      }
      setMetadata(importElement, node);
    }
    return null;
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    DartType staticType = _getStaticType(target);
    DartType propagatedType = _getPropagatedType(target);
    String getterMethodName = sc.TokenType.INDEX.lexeme;
    String setterMethodName = sc.TokenType.INDEX_EQ.lexeme;
    bool isInGetterContext = node.inGetterContext();
    bool isInSetterContext = node.inSetterContext();
    if (isInGetterContext && isInSetterContext) {
      // lookup setter
      MethodElement setterStaticMethod =
          _lookUpMethod(target, staticType, setterMethodName);
      MethodElement setterPropagatedMethod =
          _lookUpMethod(target, propagatedType, setterMethodName);
      // set setter element
      node.staticElement = setterStaticMethod;
      node.propagatedElement = setterPropagatedMethod;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(
          node,
          target,
          getterMethodName,
          setterStaticMethod,
          setterPropagatedMethod,
          staticType,
          propagatedType);
      // lookup getter method
      MethodElement getterStaticMethod =
          _lookUpMethod(target, staticType, getterMethodName);
      MethodElement getterPropagatedMethod =
          _lookUpMethod(target, propagatedType, getterMethodName);
      // set getter element
      AuxiliaryElements auxiliaryElements =
          new AuxiliaryElements(getterStaticMethod, getterPropagatedMethod);
      node.auxiliaryElements = auxiliaryElements;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(
          node,
          target,
          getterMethodName,
          getterStaticMethod,
          getterPropagatedMethod,
          staticType,
          propagatedType);
    } else if (isInGetterContext) {
      // lookup getter method
      MethodElement staticMethod =
          _lookUpMethod(target, staticType, getterMethodName);
      MethodElement propagatedMethod =
          _lookUpMethod(target, propagatedType, getterMethodName);
      // set getter element
      node.staticElement = staticMethod;
      node.propagatedElement = propagatedMethod;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(node, target, getterMethodName,
          staticMethod, propagatedMethod, staticType, propagatedType);
    } else if (isInSetterContext) {
      // lookup setter method
      MethodElement staticMethod =
          _lookUpMethod(target, staticType, setterMethodName);
      MethodElement propagatedMethod =
          _lookUpMethod(target, propagatedType, setterMethodName);
      // set setter element
      node.staticElement = staticMethod;
      node.propagatedElement = propagatedMethod;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(node, target, setterMethodName,
          staticMethod, propagatedMethod, staticType, propagatedType);
    }
    return null;
  }

  @override
  Object visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement invokedConstructor = node.constructorName.staticElement;
    node.staticElement = invokedConstructor;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = _resolveArgumentsToFunction(
        node.isConst, argumentList, invokedConstructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }

  @override
  Object visitLibraryDirective(LibraryDirective node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitMethodInvocation(MethodInvocation node) {
    SimpleIdentifier methodName = node.methodName;
    //
    // Synthetic identifiers have been already reported during parsing.
    //
    if (methodName.isSynthetic) {
      return null;
    }
    //
    // We have a method invocation of one of two forms: 'e.m(a1, ..., an)' or
    // 'm(a1, ..., an)'. The first step is to figure out which executable is
    // being invoked, using both the static and the propagated type information.
    //
    Expression target = node.realTarget;
    if (target is SuperExpression && !_isSuperInValidContext(target)) {
      return null;
    }
    Element staticElement;
    Element propagatedElement;
    DartType staticType = null;
    DartType propagatedType = null;
    if (target == null) {
      staticElement = _resolveInvokedElement(methodName);
      propagatedElement = null;
    } else if (methodName.name == FunctionElement.LOAD_LIBRARY_NAME &&
        _isDeferredPrefix(target)) {
      if (node.operator.type == sc.TokenType.QUESTION_PERIOD) {
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
            target,
            [(target as SimpleIdentifier).name]);
      }
      LibraryElement importedLibrary = _getImportedLibrary(target);
      methodName.staticElement = importedLibrary.loadLibraryFunction;
      return null;
    } else {
      staticType = _getStaticType(target);
      propagatedType = _getPropagatedType(target);
      //
      // If this method invocation is of the form 'C.m' where 'C' is a class,
      // then we don't call resolveInvokedElement(...) which walks up the class
      // hierarchy, instead we just look for the member in the type only.  This
      // does not apply to conditional method invocation (i.e. 'C?.m(...)').
      //
      bool isConditional = node.operator.type == sc.TokenType.QUESTION_PERIOD;
      ClassElementImpl typeReference = getTypeReference(target);
      if (typeReference != null) {
        staticElement =
            propagatedElement = _resolveElement(typeReference, methodName);
      } else {
        staticElement = _resolveInvokedElementWithTarget(
            target, staticType, methodName, isConditional);
        propagatedElement = _resolveInvokedElementWithTarget(
            target, propagatedType, methodName, isConditional);
      }
    }
    staticElement = _convertSetterToGetter(staticElement);
    propagatedElement = _convertSetterToGetter(propagatedElement);
    //
    // Record the results.
    //
    methodName.staticElement = staticElement;
    methodName.propagatedElement = propagatedElement;
    ArgumentList argumentList = node.argumentList;
    if (staticElement != null) {
      List<ParameterElement> parameters =
          _computeCorrespondingParameters(argumentList, staticElement);
      if (parameters != null) {
        argumentList.correspondingStaticParameters = parameters;
      }
    }
    if (propagatedElement != null) {
      List<ParameterElement> parameters =
          _computeCorrespondingParameters(argumentList, propagatedElement);
      if (parameters != null) {
        argumentList.correspondingPropagatedParameters = parameters;
      }
    }
    //
    // Then check for error conditions.
    //
    ErrorCode errorCode = _checkForInvocationError(target, true, staticElement);
    bool generatedWithTypePropagation = false;
    if (_enableHints && errorCode == null && staticElement == null) {
      // The method lookup may have failed because there were multiple
      // incompatible choices. In this case we don't want to generate a hint.
      errorCode = _checkForInvocationError(target, false, propagatedElement);
      if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_METHOD)) {
        ClassElement classElementContext = null;
        if (target == null) {
          classElementContext = _resolver.enclosingClass;
        } else {
          DartType type = _getBestType(target);
          if (type != null) {
            if (type.element is ClassElement) {
              classElementContext = type.element as ClassElement;
            }
          }
        }
        if (classElementContext != null) {
          _subtypeManager.ensureLibraryVisited(_definingLibrary);
          HashSet<ClassElement> subtypeElements =
              _subtypeManager.computeAllSubtypes(classElementContext);
          for (ClassElement subtypeElement in subtypeElements) {
            if (subtypeElement.getMethod(methodName.name) != null) {
              errorCode = null;
            }
          }
        }
      }
      generatedWithTypePropagation = true;
    }
    if (errorCode == null) {
      return null;
    }
    if (identical(
            errorCode, StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION) ||
        identical(errorCode,
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT) ||
        identical(errorCode, StaticTypeWarningCode.UNDEFINED_FUNCTION)) {
      _resolver.reportErrorForNode(errorCode, methodName, [methodName.name]);
    } else if (identical(errorCode, StaticTypeWarningCode.UNDEFINED_METHOD)) {
      String targetTypeName;
      if (target == null) {
        ClassElement enclosingClass = _resolver.enclosingClass;
        targetTypeName = enclosingClass.displayName;
        ErrorCode proxyErrorCode = (generatedWithTypePropagation
            ? HintCode.UNDEFINED_METHOD
            : StaticTypeWarningCode.UNDEFINED_METHOD);
        _recordUndefinedNode(_resolver.enclosingClass, proxyErrorCode,
            methodName, [methodName.name, targetTypeName]);
      } else {
        // ignore Function "call"
        // (if we are about to create a hint using type propagation,
        // then we can use type propagation here as well)
        DartType targetType = null;
        if (!generatedWithTypePropagation) {
          targetType = _getStaticType(target);
        } else {
          // choose the best type
          targetType = _getPropagatedType(target);
          if (targetType == null) {
            targetType = _getStaticType(target);
          }
        }
        if (!_enableStrictCallChecks &&
            targetType != null &&
            targetType.isDartCoreFunction &&
            methodName.name == FunctionElement.CALL_METHOD_NAME) {
          // TODO(brianwilkerson) Can we ever resolve the function being
          // invoked?
//          resolveArgumentsToParameters(node.getArgumentList(), invokedFunction);
          return null;
        }
        targetTypeName = targetType == null ? null : targetType.displayName;
        ErrorCode proxyErrorCode = (generatedWithTypePropagation
            ? HintCode.UNDEFINED_METHOD
            : StaticTypeWarningCode.UNDEFINED_METHOD);
        _recordUndefinedNode(targetType.element, proxyErrorCode, methodName,
            [methodName.name, targetTypeName]);
      }
    } else if (identical(
        errorCode, StaticTypeWarningCode.UNDEFINED_SUPER_METHOD)) {
      // Generate the type name.
      // The error code will never be generated via type propagation
      DartType targetType = _getStaticType(target);
      if (targetType is InterfaceType && !targetType.isObject) {
        targetType = (targetType as InterfaceType).superclass;
      }
      String targetTypeName = targetType == null ? null : targetType.name;
      _resolver.reportErrorForNode(StaticTypeWarningCode.UNDEFINED_SUPER_METHOD,
          methodName, [methodName.name, targetTypeName]);
    }
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitPartOfDirective(PartOfDirective node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitPostfixExpression(PostfixExpression node) {
    Expression operand = node.operand;
    String methodName = _getPostfixOperator(node);
    DartType staticType = _getStaticType(operand);
    MethodElement staticMethod = _lookUpMethod(operand, staticType, methodName);
    node.staticElement = staticMethod;
    DartType propagatedType = _getPropagatedType(operand);
    MethodElement propagatedMethod =
        _lookUpMethod(operand, propagatedType, methodName);
    node.propagatedElement = propagatedMethod;
    if (_shouldReportMissingMember(staticType, staticMethod)) {
      if (operand is SuperExpression) {
        _recordUndefinedToken(
            staticType.element,
            StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
            node.operator,
            [methodName, staticType.displayName]);
      } else {
        _recordUndefinedToken(
            staticType.element,
            StaticTypeWarningCode.UNDEFINED_OPERATOR,
            node.operator,
            [methodName, staticType.displayName]);
      }
    } else if (_enableHints &&
        _shouldReportMissingMember(propagatedType, propagatedMethod) &&
        !_memberFoundInSubclass(
            propagatedType.element, methodName, true, false)) {
      _recordUndefinedToken(propagatedType.element, HintCode.UNDEFINED_OPERATOR,
          node.operator, [methodName, propagatedType.displayName]);
    }
    return null;
  }

  @override
  Object visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    SimpleIdentifier identifier = node.identifier;
    //
    // First, check the "lib.loadLibrary" case
    //
    if (identifier.name == FunctionElement.LOAD_LIBRARY_NAME &&
        _isDeferredPrefix(prefix)) {
      LibraryElement importedLibrary = _getImportedLibrary(prefix);
      identifier.staticElement = importedLibrary.loadLibraryFunction;
      return null;
    }
    //
    // Check to see whether the prefix is really a prefix.
    //
    Element prefixElement = prefix.staticElement;
    if (prefixElement is PrefixElement) {
      Element element = _resolver.nameScope.lookup(node, _definingLibrary);
      if (element == null && identifier.inSetterContext()) {
        element = _resolver.nameScope.lookup(
            new SyntheticIdentifier("${node.name}=", node), _definingLibrary);
      }
      if (element == null) {
        if (identifier.inSetterContext()) {
          _resolver.reportErrorForNode(StaticWarningCode.UNDEFINED_SETTER,
              identifier, [identifier.name, prefixElement.name]);
        } else if (node.parent is Annotation) {
          Annotation annotation = node.parent as Annotation;
          _resolver.reportErrorForNode(
              CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
          return null;
        } else {
          _resolver.reportErrorForNode(StaticWarningCode.UNDEFINED_GETTER,
              identifier, [identifier.name, prefixElement.name]);
        }
        return null;
      }
      if (element is PropertyAccessorElement && identifier.inSetterContext()) {
        PropertyInducingElement variable =
            (element as PropertyAccessorElement).variable;
        if (variable != null) {
          PropertyAccessorElement setter = variable.setter;
          if (setter != null) {
            element = setter;
          }
        }
      }
      // TODO(brianwilkerson) The prefix needs to be resolved to the element for
      // the import that defines the prefix, not the prefix's element.
      identifier.staticElement = element;
      // Validate annotation element.
      if (node.parent is Annotation) {
        Annotation annotation = node.parent as Annotation;
        _resolveAnnotationElement(annotation);
        return null;
      }
      return null;
    }
    // May be annotation, resolve invocation of "const" constructor.
    if (node.parent is Annotation) {
      Annotation annotation = node.parent as Annotation;
      _resolveAnnotationElement(annotation);
    }
    //
    // Otherwise, the prefix is really an expression that happens to be a simple
    // identifier and this is really equivalent to a property access node.
    //
    _resolvePropertyAccess(prefix, identifier);
    return null;
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    sc.Token operator = node.operator;
    sc.TokenType operatorType = operator.type;
    if (operatorType.isUserDefinableOperator ||
        operatorType == sc.TokenType.PLUS_PLUS ||
        operatorType == sc.TokenType.MINUS_MINUS) {
      Expression operand = node.operand;
      String methodName = _getPrefixOperator(node);
      DartType staticType = _getStaticType(operand);
      MethodElement staticMethod =
          _lookUpMethod(operand, staticType, methodName);
      node.staticElement = staticMethod;
      DartType propagatedType = _getPropagatedType(operand);
      MethodElement propagatedMethod =
          _lookUpMethod(operand, propagatedType, methodName);
      node.propagatedElement = propagatedMethod;
      if (_shouldReportMissingMember(staticType, staticMethod)) {
        if (operand is SuperExpression) {
          _recordUndefinedToken(
              staticType.element,
              StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
              operator,
              [methodName, staticType.displayName]);
        } else {
          _recordUndefinedToken(
              staticType.element,
              StaticTypeWarningCode.UNDEFINED_OPERATOR,
              operator,
              [methodName, staticType.displayName]);
        }
      } else if (_enableHints &&
          _shouldReportMissingMember(propagatedType, propagatedMethod) &&
          !_memberFoundInSubclass(
              propagatedType.element, methodName, true, false)) {
        _recordUndefinedToken(
            propagatedType.element,
            HintCode.UNDEFINED_OPERATOR,
            operator,
            [methodName, propagatedType.displayName]);
      }
    }
    return null;
  }

  @override
  Object visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    if (target is SuperExpression && !_isSuperInValidContext(target)) {
      return null;
    }
    SimpleIdentifier propertyName = node.propertyName;
    _resolvePropertyAccess(target, propertyName);
    return null;
  }

  @override
  Object visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      // TODO(brianwilkerson) Report this error.
      return null;
    }
    SimpleIdentifier name = node.constructorName;
    ConstructorElement element;
    if (name == null) {
      element = enclosingClass.unnamedConstructor;
    } else {
      element = enclosingClass.getNamedConstructor(name.name);
    }
    if (element == null) {
      // TODO(brianwilkerson) Report this error and decide what element to
      // associate with the node.
      return null;
    }
    if (name != null) {
      name.staticElement = element;
    }
    node.staticElement = element;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters =
        _resolveArgumentsToFunction(false, argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }

  @override
  Object visitSimpleFormalParameter(SimpleFormalParameter node) {
    _setMetadataForParameter(node.element, node);
    return null;
  }

  @override
  Object visitSimpleIdentifier(SimpleIdentifier node) {
    //
    // Synthetic identifiers have been already reported during parsing.
    //
    if (node.isSynthetic) {
      return null;
    }
    //
    // We ignore identifiers that have already been resolved, such as
    // identifiers representing the name in a declaration.
    //
    if (node.staticElement != null) {
      return null;
    }
    //
    // The name dynamic denotes a Type object even though dynamic is not a
    // class.
    //
    if (node.name == _dynamicType.name) {
      node.staticElement = _dynamicType.element;
      node.staticType = _typeType;
      return null;
    }
    //
    // Otherwise, the node should be resolved.
    //
    Element element = _resolveSimpleIdentifier(node);
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (_isFactoryConstructorReturnType(node) &&
        !identical(element, enclosingClass)) {
      _resolver.reportErrorForNode(
          CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, node);
    } else if (_isConstructorReturnType(node) &&
        !identical(element, enclosingClass)) {
      _resolver.reportErrorForNode(
          CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node);
      element = null;
    } else if (element == null ||
        (element is PrefixElement && !_isValidAsPrefix(node))) {
      // TODO(brianwilkerson) Recover from this error.
      if (_isConstructorReturnType(node)) {
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node);
      } else if (node.parent is Annotation) {
        Annotation annotation = node.parent as Annotation;
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      } else if (element is PrefixElement) {
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
            node,
            [element.name]);
      } else {
        _recordUndefinedNode(_resolver.enclosingClass,
            StaticWarningCode.UNDEFINED_IDENTIFIER, node, [node.name]);
      }
    }
    node.staticElement = element;
    if (node.inSetterContext() &&
        node.inGetterContext() &&
        enclosingClass != null) {
      InterfaceType enclosingType = enclosingClass.type;
      AuxiliaryElements auxiliaryElements = new AuxiliaryElements(
          _lookUpGetter(null, enclosingType, node.name), null);
      node.auxiliaryElements = auxiliaryElements;
    }
    //
    // Validate annotation element.
    //
    if (node.parent is Annotation) {
      Annotation annotation = node.parent as Annotation;
      _resolveAnnotationElement(annotation);
    }
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassElementImpl enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      // TODO(brianwilkerson) Report this error.
      return null;
    }
    InterfaceType superType = enclosingClass.supertype;
    if (superType == null) {
      // TODO(brianwilkerson) Report this error.
      return null;
    }
    SimpleIdentifier name = node.constructorName;
    String superName = name != null ? name.name : null;
    ConstructorElement element =
        superType.lookUpConstructor(superName, _definingLibrary);
    if (element == null ||
        (!enclosingClass.doesMixinLackConstructors &&
            !enclosingClass.isSuperConstructorAccessible(element))) {
      if (name != null) {
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER,
            node,
            [superType.displayName, name]);
      } else {
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
            node,
            [superType.displayName]);
      }
      return null;
    } else {
      if (element.isFactory) {
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node, [element]);
      }
    }
    if (name != null) {
      name.staticElement = element;
    }
    node.staticElement = element;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = _resolveArgumentsToFunction(
        isInConstConstructor, argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
    return null;
  }

  @override
  Object visitSuperExpression(SuperExpression node) {
    if (!_isSuperInValidContext(node)) {
      _resolver.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node);
    }
    return super.visitSuperExpression(node);
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    setMetadata(node.element, node);
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    setMetadata(node.element, node);
    return null;
  }

  /**
   * Given that we have found code to invoke the given [element], return the
   * error code that should be reported, or `null` if no error should be
   * reported. The [target] is the target of the invocation, or `null` if there
   * was no target. The flag [useStaticContext] should be `true` if the
   * invocation is in a static constant (does not have access to instance state.
   */
  ErrorCode _checkForInvocationError(
      Expression target, bool useStaticContext, Element element) {
    // Prefix is not declared, instead "prefix.id" are declared.
    if (element is PrefixElement) {
      return CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT;
    }
    if (element is PropertyAccessorElement) {
      //
      // This is really a function expression invocation.
      //
      // TODO(brianwilkerson) Consider the possibility of re-writing the AST.
      FunctionType getterType = element.type;
      if (getterType != null) {
        DartType returnType = getterType.returnType;
        if (!_isExecutableType(returnType)) {
          return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
        }
      }
    } else if (element is ExecutableElement) {
      return null;
    } else if (element is MultiplyDefinedElement) {
      // The error has already been reported
      return null;
    } else if (element == null && target is SuperExpression) {
      // TODO(jwren) We should split the UNDEFINED_METHOD into two error codes,
      // this one, and a code that describes the situation where the method was
      // found, but it was not accessible from the current library.
      return StaticTypeWarningCode.UNDEFINED_SUPER_METHOD;
    } else {
      //
      // This is really a function expression invocation.
      //
      // TODO(brianwilkerson) Consider the possibility of re-writing the AST.
      if (element is PropertyInducingElement) {
        PropertyAccessorElement getter = element.getter;
        FunctionType getterType = getter.type;
        if (getterType != null) {
          DartType returnType = getterType.returnType;
          if (!_isExecutableType(returnType)) {
            return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
          }
        }
      } else if (element is VariableElement) {
        DartType variableType = element.type;
        if (!_isExecutableType(variableType)) {
          return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
        }
      } else {
        if (target == null) {
          ClassElement enclosingClass = _resolver.enclosingClass;
          if (enclosingClass == null) {
            return StaticTypeWarningCode.UNDEFINED_FUNCTION;
          } else if (element == null) {
            // Proxy-conditional warning, based on state of
            // resolver.getEnclosingClass()
            return StaticTypeWarningCode.UNDEFINED_METHOD;
          } else {
            return StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
          }
        } else {
          DartType targetType;
          if (useStaticContext) {
            targetType = _getStaticType(target);
          } else {
            // Compute and use the propagated type, if it is null, then it may
            // be the case that static type is some type, in which the static
            // type should be used.
            targetType = _getBestType(target);
          }
          if (targetType == null) {
            return StaticTypeWarningCode.UNDEFINED_FUNCTION;
          } else if (!targetType.isDynamic && !targetType.isBottom) {
            // Proxy-conditional warning, based on state of
            // targetType.getElement()
            return StaticTypeWarningCode.UNDEFINED_METHOD;
          }
        }
      }
    }
    return null;
  }

  /**
   * Check that the given index [expression] was resolved, otherwise a
   * [StaticTypeWarningCode.UNDEFINED_OPERATOR] is generated. The [target] is
   * the target of the expression. The [methodName] is the name of the operator
   * associated with the context of using of the given index expression.
   */
  bool _checkForUndefinedIndexOperator(
      IndexExpression expression,
      Expression target,
      String methodName,
      MethodElement staticMethod,
      MethodElement propagatedMethod,
      DartType staticType,
      DartType propagatedType) {
    bool shouldReportMissingMember_static =
        _shouldReportMissingMember(staticType, staticMethod);
    bool shouldReportMissingMember_propagated =
        !shouldReportMissingMember_static &&
            _enableHints &&
            _shouldReportMissingMember(propagatedType, propagatedMethod) &&
            !_memberFoundInSubclass(
                propagatedType.element, methodName, true, false);
    if (shouldReportMissingMember_static ||
        shouldReportMissingMember_propagated) {
      sc.Token leftBracket = expression.leftBracket;
      sc.Token rightBracket = expression.rightBracket;
      ErrorCode errorCode;
      if (shouldReportMissingMember_static) {
        if (target is SuperExpression) {
          errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR;
        } else {
          errorCode = StaticTypeWarningCode.UNDEFINED_OPERATOR;
        }
      } else {
        errorCode = HintCode.UNDEFINED_OPERATOR;
      }
      DartType type =
          shouldReportMissingMember_static ? staticType : propagatedType;
      if (leftBracket == null || rightBracket == null) {
        _recordUndefinedNode(type.element, errorCode, expression,
            [methodName, type.displayName]);
      } else {
        int offset = leftBracket.offset;
        int length = rightBracket.offset - offset + 1;
        _recordUndefinedOffset(type.element, errorCode, offset, length,
            [methodName, type.displayName]);
      }
      return true;
    }
    return false;
  }

  /**
   * Given an [argumentList] and the executable [element] that  will be invoked
   * using those arguments, compute the list of parameters that correspond to
   * the list of arguments. Return the parameters that correspond to the
   * arguments, or `null` if no correspondence could be computed.
   */
  List<ParameterElement> _computeCorrespondingParameters(
      ArgumentList argumentList, Element element) {
    if (element is PropertyAccessorElement) {
      //
      // This is an invocation of the call method defined on the value returned
      // by the getter.
      //
      FunctionType getterType = element.type;
      if (getterType != null) {
        DartType getterReturnType = getterType.returnType;
        if (getterReturnType is InterfaceType) {
          MethodElement callMethod = getterReturnType.lookUpMethod(
              FunctionElement.CALL_METHOD_NAME, _definingLibrary);
          if (callMethod != null) {
            return _resolveArgumentsToFunction(false, argumentList, callMethod);
          }
        } else if (getterReturnType is FunctionType) {
          List<ParameterElement> parameters = getterReturnType.parameters;
          return _resolveArgumentsToParameters(false, argumentList, parameters);
        }
      }
    } else if (element is ExecutableElement) {
      return _resolveArgumentsToFunction(false, argumentList, element);
    } else if (element is VariableElement) {
      VariableElement variable = element;
      DartType type = _promoteManager.getStaticType(variable);
      if (type is FunctionType) {
        FunctionType functionType = type;
        List<ParameterElement> parameters = functionType.parameters;
        return _resolveArgumentsToParameters(false, argumentList, parameters);
      } else if (type is InterfaceType) {
        // "call" invocation
        MethodElement callMethod = type.lookUpMethod(
            FunctionElement.CALL_METHOD_NAME, _definingLibrary);
        if (callMethod != null) {
          List<ParameterElement> parameters = callMethod.parameters;
          return _resolveArgumentsToParameters(false, argumentList, parameters);
        }
      }
    }
    return null;
  }

  /**
   * If the given [element] is a setter, return the getter associated with it.
   * Otherwise, return the element unchanged.
   */
  Element _convertSetterToGetter(Element element) {
    // TODO(brianwilkerson) Determine whether and why the element could ever be
    // a setter.
    if (element is PropertyAccessorElement) {
      return element.variable.getter;
    }
    return element;
  }

  /**
   * Return `true` if the given [element] is not a proxy. See
   * [ClassElement.isOrInheritsProxy].
   */
  bool _doesntHaveProxy(Element element) =>
      !(element is ClassElement && element.isOrInheritsProxy);

  /**
   * Look for any declarations of the given [identifier] that are imported using
   * a prefix. Return the element that was found, or `null` if the name is not
   * imported using a prefix.
   */
  Element _findImportWithoutPrefix(SimpleIdentifier identifier) {
    Element element = null;
    Scope nameScope = _resolver.nameScope;
    for (ImportElement importElement in _definingLibrary.imports) {
      PrefixElement prefixElement = importElement.prefix;
      if (prefixElement != null) {
        Identifier prefixedIdentifier = new SyntheticIdentifier(
            "${prefixElement.name}.${identifier.name}", identifier);
        Element importedElement =
            nameScope.lookup(prefixedIdentifier, _definingLibrary);
        if (importedElement != null) {
          if (element == null) {
            element = importedElement;
          } else {
            element = MultiplyDefinedElementImpl.fromElements(
                _definingLibrary.context, element, importedElement);
          }
        }
      }
    }
    return element;
  }

  /**
   * Return the best type of the given [expression] that is to be used for
   * type analysis.
   */
  DartType _getBestType(Expression expression) {
    DartType bestType = _resolveTypeParameter(expression.bestType);
    if (bestType is FunctionType) {
      //
      // All function types are subtypes of 'Function', which is itself a
      // subclass of 'Object'.
      //
      bestType = _resolver.typeProvider.functionType;
    }
    return bestType;
  }

  /**
   * Assuming that the given [expression] is a prefix for a deferred import,
   * return the library that is being imported.
   */
  LibraryElement _getImportedLibrary(Expression expression) {
    PrefixElement prefixElement =
        (expression as SimpleIdentifier).staticElement as PrefixElement;
    List<ImportElement> imports =
        prefixElement.enclosingElement.getImportsWithPrefix(prefixElement);
    return imports[0].importedLibrary;
  }

  /**
   * Return the name of the method invoked by the given postfix [expression].
   */
  String _getPostfixOperator(PostfixExpression expression) =>
      (expression.operator.type == sc.TokenType.PLUS_PLUS)
          ? sc.TokenType.PLUS.lexeme
          : sc.TokenType.MINUS.lexeme;

  /**
   * Return the name of the method invoked by the given postfix [expression].
   */
  String _getPrefixOperator(PrefixExpression expression) {
    sc.Token operator = expression.operator;
    sc.TokenType operatorType = operator.type;
    if (operatorType == sc.TokenType.PLUS_PLUS) {
      return sc.TokenType.PLUS.lexeme;
    } else if (operatorType == sc.TokenType.MINUS_MINUS) {
      return sc.TokenType.MINUS.lexeme;
    } else if (operatorType == sc.TokenType.MINUS) {
      return "unary-";
    } else {
      return operator.lexeme;
    }
  }

  /**
   * Return the propagated type of the given [expression] that is to be used for
   * type analysis.
   */
  DartType _getPropagatedType(Expression expression) {
    DartType propagatedType = _resolveTypeParameter(expression.propagatedType);
    if (propagatedType is FunctionType) {
      //
      // All function types are subtypes of 'Function', which is itself a
      // subclass of 'Object'.
      //
      propagatedType = _resolver.typeProvider.functionType;
    }
    return propagatedType;
  }

  /**
   * Return the static type of the given [expression] that is to be used for
   * type analysis.
   */
  DartType _getStaticType(Expression expression) {
    if (expression is NullLiteral) {
      return _resolver.typeProvider.bottomType;
    }
    DartType staticType = _resolveTypeParameter(expression.staticType);
    if (staticType is FunctionType) {
      //
      // All function types are subtypes of 'Function', which is itself a
      // subclass of 'Object'.
      //
      staticType = _resolver.typeProvider.functionType;
    }
    return staticType;
  }

  /**
   * Return `true` if the given [expression] is a prefix for a deferred import.
   */
  bool _isDeferredPrefix(Expression expression) {
    if (expression is! SimpleIdentifier) {
      return false;
    }
    Element element = (expression as SimpleIdentifier).staticElement;
    if (element is! PrefixElement) {
      return false;
    }
    PrefixElement prefixElement = element as PrefixElement;
    List<ImportElement> imports =
        prefixElement.enclosingElement.getImportsWithPrefix(prefixElement);
    if (imports.length != 1) {
      return false;
    }
    return imports[0].isDeferred;
  }

  /**
   * Return `true` if the given [type] represents an object that could be
   * invoked using the call operator '()'.
   */
  bool _isExecutableType(DartType type) {
    if (type.isDynamic || type is FunctionType) {
      return true;
    } else if (!_enableStrictCallChecks &&
        (type.isDartCoreFunction || type.isObject)) {
      return true;
    } else if (type is InterfaceType) {
      ClassElement classElement = type.element;
      // 16078 from Gilad: If the type is a Functor with the @proxy annotation,
      // treat it as an executable type.
      // example code: NonErrorResolverTest.
      // test_invocationOfNonFunction_proxyOnFunctionClass()
      if (classElement.isProxy &&
          type.isSubtypeOf(_resolver.typeProvider.functionType)) {
        return true;
      }
      MethodElement methodElement = classElement.lookUpMethod(
          FunctionElement.CALL_METHOD_NAME, _definingLibrary);
      return methodElement != null;
    }
    return false;
  }

  /**
   * Return `true` if the given [element] is a static element.
   */
  bool _isStatic(Element element) {
    if (element is ExecutableElement) {
      return element.isStatic;
    } else if (element is PropertyInducingElement) {
      return element.isStatic;
    }
    return false;
  }

  /**
   * Return `true` if the given [node] can validly be resolved to a prefix:
   * * it is the prefix in an import directive, or
   * * it is the prefix in a prefixed identifier.
   */
  bool _isValidAsPrefix(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (parent is ImportDirective) {
      return identical(parent.prefix, node);
    } else if (parent is PrefixedIdentifier) {
      return true;
    } else if (parent is MethodInvocation) {
      return identical(parent.target, node);
    }
    return false;
  }

  /**
   * Return the target of a break or continue statement, and update the static
   * element of its label (if any). The [parentNode] is the AST node of the
   * break or continue statement. The [labelNode] is the label contained in that
   * statement (if any). The flag [isContinue] is `true` if the node being
   * visited is a continue statement.
   */
  AstNode _lookupBreakOrContinueTarget(
      AstNode parentNode, SimpleIdentifier labelNode, bool isContinue) {
    if (labelNode == null) {
      return _resolver.implicitLabelScope.getTarget(isContinue);
    } else {
      LabelScope labelScope = _resolver.labelScope;
      if (labelScope == null) {
        // There are no labels in scope, so by definition the label is
        // undefined.
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      LabelScope definingScope = labelScope.lookup(labelNode.name);
      if (definingScope == null) {
        // No definition of the given label name could be found in any
        // enclosing scope.
        _resolver.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      // The target has been found.
      labelNode.staticElement = definingScope.element;
      ExecutableElement labelContainer = definingScope.element
          .getAncestor((element) => element is ExecutableElement);
      if (!identical(labelContainer, _resolver.enclosingFunction)) {
        _resolver.reportErrorForNode(CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE,
            labelNode, [labelNode.name]);
      }
      return definingScope.node;
    }
  }

  /**
   * Look up the getter with the given [getterName] in the given [type]. Return
   * the element representing the getter that was found, or `null` if there is
   * no getter with the given name. The [target] is the target of the
   * invocation, or `null` if there is no target.
   */
  PropertyAccessorElement _lookUpGetter(
      Expression target, DartType type, String getterName) {
    type = _resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      PropertyAccessorElement accessor;
      if (target is SuperExpression) {
        accessor = interfaceType.lookUpGetterInSuperclass(
            getterName, _definingLibrary);
      } else {
        accessor = interfaceType.lookUpGetter(getterName, _definingLibrary);
      }
      if (accessor != null) {
        return accessor;
      }
      return _lookUpGetterInInterfaces(
          interfaceType, false, getterName, new HashSet<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the getter with the given [getterName] in the interfaces
   * implemented by the given [targetType], either directly or indirectly.
   * Return the element representing the getter that was found, or `null` if
   * there is no getter with the given name. The flag [includeTargetType] should
   * be `true` if the search should include the target type. The
   * [visitedInterfaces] is a set containing all of the interfaces that have
   * been examined, used to prevent infinite recursion and to optimize the
   * search.
   */
  PropertyAccessorElement _lookUpGetterInInterfaces(
      InterfaceType targetType,
      bool includeTargetType,
      String getterName,
      HashSet<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the
    // specification (titled "Inheritance and Overriding" under "Interfaces")
    // describes a much more complex scheme for finding the inherited member.
    // We need to follow that scheme. The code below should cover the 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      PropertyAccessorElement getter = targetType.getGetter(getterName);
      if (getter != null && getter.isAccessibleIn(_definingLibrary)) {
        return getter;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      PropertyAccessorElement getter = _lookUpGetterInInterfaces(
          interfaceType, true, getterName, visitedInterfaces);
      if (getter != null) {
        return getter;
      }
    }
    for (InterfaceType mixinType in targetType.mixins.reversed) {
      PropertyAccessorElement getter = _lookUpGetterInInterfaces(
          mixinType, true, getterName, visitedInterfaces);
      if (getter != null) {
        return getter;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return _lookUpGetterInInterfaces(
        superclass, true, getterName, visitedInterfaces);
  }

  /**
   * Look up the method or getter with the given [memberName] in the given
   * [type]. Return the element representing the method or getter that was
   * found, or `null` if there is no method or getter with the given name.
   */
  ExecutableElement _lookupGetterOrMethod(DartType type, String memberName) {
    type = _resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      ExecutableElement member =
          interfaceType.lookUpMethod(memberName, _definingLibrary);
      if (member != null) {
        return member;
      }
      member = interfaceType.lookUpGetter(memberName, _definingLibrary);
      if (member != null) {
        return member;
      }
      return _lookUpGetterOrMethodInInterfaces(
          interfaceType, false, memberName, new HashSet<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the method or getter with the given [memberName] in the interfaces
   * implemented by the given [targetType], either directly or indirectly.
   * Return the element representing the method or getter that was found, or
   * `null` if there is no method or getter with the given name. The flag
   * [includeTargetType] should be `true` if the search should include the
   * target type. The [visitedInterfaces] is a set containing all of the
   * interfaces that have been examined, used to prevent infinite recursion and
   * to optimize the search.
   */
  ExecutableElement _lookUpGetterOrMethodInInterfaces(
      InterfaceType targetType,
      bool includeTargetType,
      String memberName,
      HashSet<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the
    // specification (titled "Inheritance and Overriding" under "Interfaces")
    // describes a much more complex scheme for finding the inherited member.
    // We need to follow that scheme. The code below should cover the 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      ExecutableElement member = targetType.getMethod(memberName);
      if (member != null) {
        return member;
      }
      member = targetType.getGetter(memberName);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      ExecutableElement member = _lookUpGetterOrMethodInInterfaces(
          interfaceType, true, memberName, visitedInterfaces);
      if (member != null) {
        return member;
      }
    }
    for (InterfaceType mixinType in targetType.mixins.reversed) {
      ExecutableElement member = _lookUpGetterOrMethodInInterfaces(
          mixinType, true, memberName, visitedInterfaces);
      if (member != null) {
        return member;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return _lookUpGetterOrMethodInInterfaces(
        superclass, true, memberName, visitedInterfaces);
  }

  /**
   * Look up the method with the given [methodName] in the given [type]. Return
   * the element representing the method that was found, or `null` if there is
   * no method with the given name. The [target] is the target of the
   * invocation, or `null` if there is no target.
   */
  MethodElement _lookUpMethod(
      Expression target, DartType type, String methodName) {
    type = _resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      MethodElement method;
      if (target is SuperExpression) {
        method = interfaceType.lookUpMethodInSuperclass(
            methodName, _definingLibrary);
      } else {
        method = interfaceType.lookUpMethod(methodName, _definingLibrary);
      }
      if (method != null) {
        return method;
      }
      return _lookUpMethodInInterfaces(
          interfaceType, false, methodName, new HashSet<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the method with the given [methodName] in the interfaces
   * implemented by the given [targetType], either directly or indirectly.
   * Return the element representing the method that was found, or `null` if
   * there is no method with the given name. The flag [includeTargetType] should
   * be `true` if the search should include the target type. The
   * [visitedInterfaces] is a set containing all of the interfaces that have
   * been examined, used to prevent infinite recursion and to optimize the
   * search.
   */
  MethodElement _lookUpMethodInInterfaces(
      InterfaceType targetType,
      bool includeTargetType,
      String methodName,
      HashSet<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the
    // specification (titled "Inheritance and Overriding" under "Interfaces")
    // describes a much more complex scheme for finding the inherited member.
    // We need to follow that scheme. The code below should cover the 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      MethodElement method = targetType.getMethod(methodName);
      if (method != null && method.isAccessibleIn(_definingLibrary)) {
        return method;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      MethodElement method = _lookUpMethodInInterfaces(
          interfaceType, true, methodName, visitedInterfaces);
      if (method != null) {
        return method;
      }
    }
    for (InterfaceType mixinType in targetType.mixins.reversed) {
      MethodElement method = _lookUpMethodInInterfaces(
          mixinType, true, methodName, visitedInterfaces);
      if (method != null) {
        return method;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return _lookUpMethodInInterfaces(
        superclass, true, methodName, visitedInterfaces);
  }

  /**
   * Look up the setter with the given [setterName] in the given [type]. Return
   * the element representing the setter that was found, or `null` if there is
   * no setter with the given name. The [target] is the target of the
   * invocation, or `null` if there is no target.
   */
  PropertyAccessorElement _lookUpSetter(
      Expression target, DartType type, String setterName) {
    type = _resolveTypeParameter(type);
    if (type is InterfaceType) {
      InterfaceType interfaceType = type;
      PropertyAccessorElement accessor;
      if (target is SuperExpression) {
        accessor = interfaceType.lookUpSetterInSuperclass(
            setterName, _definingLibrary);
      } else {
        accessor = interfaceType.lookUpSetter(setterName, _definingLibrary);
      }
      if (accessor != null) {
        return accessor;
      }
      return _lookUpSetterInInterfaces(
          interfaceType, false, setterName, new HashSet<ClassElement>());
    }
    return null;
  }

  /**
   * Look up the setter with the given [setterName] in the interfaces
   * implemented by the given [targetType], either directly or indirectly.
   * Return the element representing the setter that was found, or `null` if
   * there is no setter with the given name. The [targetType] is the type in
   * which the setter might be defined. The flag [includeTargetType] should be
   * `true` if the search should include the target type. The
   * [visitedInterfaces] is a set containing all of the interfaces that have
   * been examined, used to prevent infinite recursion and to optimize the
   * search.
   */
  PropertyAccessorElement _lookUpSetterInInterfaces(
      InterfaceType targetType,
      bool includeTargetType,
      String setterName,
      HashSet<ClassElement> visitedInterfaces) {
    // TODO(brianwilkerson) This isn't correct. Section 8.1.1 of the
    // specification (titled "Inheritance and Overriding" under "Interfaces")
    // describes a much more complex scheme for finding the inherited member.
    // We need to follow that scheme. The code below should cover the 80% case.
    ClassElement targetClass = targetType.element;
    if (visitedInterfaces.contains(targetClass)) {
      return null;
    }
    visitedInterfaces.add(targetClass);
    if (includeTargetType) {
      PropertyAccessorElement setter = targetType.getSetter(setterName);
      if (setter != null && setter.isAccessibleIn(_definingLibrary)) {
        return setter;
      }
    }
    for (InterfaceType interfaceType in targetType.interfaces) {
      PropertyAccessorElement setter = _lookUpSetterInInterfaces(
          interfaceType, true, setterName, visitedInterfaces);
      if (setter != null) {
        return setter;
      }
    }
    for (InterfaceType mixinType in targetType.mixins.reversed) {
      PropertyAccessorElement setter = _lookUpSetterInInterfaces(
          mixinType, true, setterName, visitedInterfaces);
      if (setter != null) {
        return setter;
      }
    }
    InterfaceType superclass = targetType.superclass;
    if (superclass == null) {
      return null;
    }
    return _lookUpSetterInInterfaces(
        superclass, true, setterName, visitedInterfaces);
  }

  /**
   * Given some class [element], this method uses [_subtypeManager] to find the
   * set of all subtypes; the subtypes are then searched for a member (method,
   * getter, or setter), that has the given [memberName]. The flag [asMethod]
   * should be `true` if the methods should be searched for in the subtypes. The
   * flag [asAccessor] should be `true` if the accessors (getters and setters)
   * should be searched for in the subtypes.
   */
  bool _memberFoundInSubclass(
      Element element, String memberName, bool asMethod, bool asAccessor) {
    if (element is ClassElement) {
      _subtypeManager.ensureLibraryVisited(_definingLibrary);
      HashSet<ClassElement> subtypeElements =
          _subtypeManager.computeAllSubtypes(element);
      for (ClassElement subtypeElement in subtypeElements) {
        if (asMethod && subtypeElement.getMethod(memberName) != null) {
          return true;
        } else if (asAccessor &&
            (subtypeElement.getGetter(memberName) != null ||
                subtypeElement.getSetter(memberName) != null)) {
          return true;
        }
      }
    }
    return false;
  }

  /**
   * Return the binary operator that is invoked by the given compound assignment
   * [operator].
   */
  sc.TokenType _operatorFromCompoundAssignment(sc.TokenType operator) {
    while (true) {
      if (operator == sc.TokenType.AMPERSAND_EQ) {
        return sc.TokenType.AMPERSAND;
      } else if (operator == sc.TokenType.BAR_EQ) {
        return sc.TokenType.BAR;
      } else if (operator == sc.TokenType.CARET_EQ) {
        return sc.TokenType.CARET;
      } else if (operator == sc.TokenType.GT_GT_EQ) {
        return sc.TokenType.GT_GT;
      } else if (operator == sc.TokenType.LT_LT_EQ) {
        return sc.TokenType.LT_LT;
      } else if (operator == sc.TokenType.MINUS_EQ) {
        return sc.TokenType.MINUS;
      } else if (operator == sc.TokenType.PERCENT_EQ) {
        return sc.TokenType.PERCENT;
      } else if (operator == sc.TokenType.PLUS_EQ) {
        return sc.TokenType.PLUS;
      } else if (operator == sc.TokenType.SLASH_EQ) {
        return sc.TokenType.SLASH;
      } else if (operator == sc.TokenType.STAR_EQ) {
        return sc.TokenType.STAR;
      } else if (operator == sc.TokenType.TILDE_SLASH_EQ) {
        return sc.TokenType.TILDE_SLASH;
      } else {
        // Internal error: Unmapped assignment operator.
        AnalysisEngine.instance.logger.logError(
            "Failed to map ${operator.lexeme} to it's corresponding operator");
        return operator;
      }
      break;
    }
  }

  /**
   * Record that the given [node] is undefined, causing an error to be reported
   * if appropriate. The [declaringElement] is the element inside which no
   * declaration was found. If this element is a proxy, no error will be
   * reported. If null, then an error will always be reported. The [errorCode]
   * is the error code to report. The [arguments] are the arguments to the error
   * message.
   */
  void _recordUndefinedNode(Element declaringElement, ErrorCode errorCode,
      AstNode node, List<Object> arguments) {
    if (_doesntHaveProxy(declaringElement)) {
      _resolver.reportErrorForNode(errorCode, node, arguments);
    }
  }

  /**
   * Record that the given [offset]/[length] is undefined, causing an error to
   * be reported if appropriate. The [declaringElement] is the element inside
   * which no declaration was found. If this element is a proxy, no error will
   * be reported. If null, then an error will always be reported. The
   * [errorCode] is the error code to report. The [arguments] are arguments to
   * the error message.
   */
  void _recordUndefinedOffset(Element declaringElement, ErrorCode errorCode,
      int offset, int length, List<Object> arguments) {
    if (_doesntHaveProxy(declaringElement)) {
      _resolver.reportErrorForOffset(errorCode, offset, length, arguments);
    }
  }

  /**
   * Record that the given [token] is undefined, causing an error to be reported
   * if appropriate. The [declaringElement] is the element inside which no
   * declaration was found. If this element is a proxy, no error will be
   * reported. If null, then an error will always be reported. The [errorCode]
   * is the error code to report. The [arguments] are arguments to the error
   * message.
   */
  void _recordUndefinedToken(Element declaringElement, ErrorCode errorCode,
      sc.Token token, List<Object> arguments) {
    if (_doesntHaveProxy(declaringElement)) {
      _resolver.reportErrorForToken(errorCode, token, arguments);
    }
  }

  void _resolveAnnotationConstructorInvocationArguments(
      Annotation annotation, ConstructorElement constructor) {
    ArgumentList argumentList = annotation.arguments;
    // error will be reported in ConstantVerifier
    if (argumentList == null) {
      return;
    }
    // resolve arguments to parameters
    List<ParameterElement> parameters =
        _resolveArgumentsToFunction(true, argumentList, constructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  /**
   * Continues resolution of the given [annotation].
   */
  void _resolveAnnotationElement(Annotation annotation) {
    SimpleIdentifier nameNode1;
    SimpleIdentifier nameNode2;
    {
      Identifier annName = annotation.name;
      if (annName is PrefixedIdentifier) {
        PrefixedIdentifier prefixed = annName;
        nameNode1 = prefixed.prefix;
        nameNode2 = prefixed.identifier;
      } else {
        nameNode1 = annName as SimpleIdentifier;
        nameNode2 = null;
      }
    }
    SimpleIdentifier nameNode3 = annotation.constructorName;
    ConstructorElement constructor = null;
    //
    // CONST or Class(args)
    //
    if (nameNode1 != null && nameNode2 == null && nameNode3 == null) {
      Element element1 = nameNode1.staticElement;
      // CONST
      if (element1 is PropertyAccessorElement) {
        _resolveAnnotationElementGetter(annotation, element1);
        return;
      }
      // Class(args)
      if (element1 is ClassElement) {
        ClassElement classElement = element1;
        constructor = new InterfaceTypeImpl(classElement)
            .lookUpConstructor(null, _definingLibrary);
      }
    }
    //
    // prefix.CONST or prefix.Class() or Class.CONST or Class.constructor(args)
    //
    if (nameNode1 != null && nameNode2 != null && nameNode3 == null) {
      Element element1 = nameNode1.staticElement;
      Element element2 = nameNode2.staticElement;
      // Class.CONST - not resolved yet
      if (element1 is ClassElement) {
        ClassElement classElement = element1;
        element2 = classElement.lookUpGetter(nameNode2.name, _definingLibrary);
      }
      // prefix.CONST or Class.CONST
      if (element2 is PropertyAccessorElement) {
        nameNode2.staticElement = element2;
        annotation.element = element2;
        _resolveAnnotationElementGetter(annotation, element2);
        return;
      }
      // prefix.Class()
      if (element2 is ClassElement) {
        constructor = element2.unnamedConstructor;
      }
      // Class.constructor(args)
      if (element1 is ClassElement) {
        ClassElement classElement = element1;
        constructor = new InterfaceTypeImpl(classElement)
            .lookUpConstructor(nameNode2.name, _definingLibrary);
        nameNode2.staticElement = constructor;
      }
    }
    //
    // prefix.Class.CONST or prefix.Class.constructor(args)
    //
    if (nameNode1 != null && nameNode2 != null && nameNode3 != null) {
      Element element2 = nameNode2.staticElement;
      // element2 should be ClassElement
      if (element2 is ClassElement) {
        ClassElement classElement = element2;
        String name3 = nameNode3.name;
        // prefix.Class.CONST
        PropertyAccessorElement getter =
            classElement.lookUpGetter(name3, _definingLibrary);
        if (getter != null) {
          nameNode3.staticElement = getter;
          annotation.element = element2;
          _resolveAnnotationElementGetter(annotation, getter);
          return;
        }
        // prefix.Class.constructor(args)
        constructor = new InterfaceTypeImpl(classElement)
            .lookUpConstructor(name3, _definingLibrary);
        nameNode3.staticElement = constructor;
      }
    }
    // we need constructor
    if (constructor == null) {
      _resolver.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      return;
    }
    // record element
    annotation.element = constructor;
    // resolve arguments
    _resolveAnnotationConstructorInvocationArguments(annotation, constructor);
  }

  void _resolveAnnotationElementGetter(
      Annotation annotation, PropertyAccessorElement accessorElement) {
    // accessor should be synthetic
    if (!accessorElement.isSynthetic) {
      _resolver.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      return;
    }
    // variable should be constant
    VariableElement variableElement = accessorElement.variable;
    if (!variableElement.isConst) {
      _resolver.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
    }
    // OK
    return;
  }

  /**
   * Given an [argumentList] and the [executableElement] that will be invoked
   * using those argument, compute the list of parameters that correspond to the
   * list of arguments. An error will be reported if any of the arguments cannot
   * be matched to a parameter. The flag [reportError] should be `true` if a
   * compile-time error should be reported; or `false` if a compile-time warning
   * should be reported. Return the parameters that correspond to the arguments,
   * or `null` if no correspondence could be computed.
   */
  List<ParameterElement> _resolveArgumentsToFunction(bool reportError,
      ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return _resolveArgumentsToParameters(reportError, argumentList, parameters);
  }

  /**
   * Given an [argumentList] and the [parameters] related to the element that
   * will be invoked using those arguments, compute the list of parameters that
   * correspond to the list of arguments. An error will be reported if any of
   * the arguments cannot be matched to a parameter. The flag [reportError]
   * should be `true` if a compile-time error should be reported; or `false` if
   * a compile-time warning should be reported. Return the parameters that
   * correspond to the arguments.
   */
  List<ParameterElement> _resolveArgumentsToParameters(bool reportError,
      ArgumentList argumentList, List<ParameterElement> parameters) {
    List<ParameterElement> requiredParameters = new List<ParameterElement>();
    List<ParameterElement> positionalParameters = new List<ParameterElement>();
    HashMap<String, ParameterElement> namedParameters =
        new HashMap<String, ParameterElement>();
    for (ParameterElement parameter in parameters) {
      ParameterKind kind = parameter.parameterKind;
      if (kind == ParameterKind.REQUIRED) {
        requiredParameters.add(parameter);
      } else if (kind == ParameterKind.POSITIONAL) {
        positionalParameters.add(parameter);
      } else {
        namedParameters[parameter.name] = parameter;
      }
    }
    List<ParameterElement> unnamedParameters =
        new List<ParameterElement>.from(requiredParameters);
    unnamedParameters.addAll(positionalParameters);
    int unnamedParameterCount = unnamedParameters.length;
    int unnamedIndex = 0;
    NodeList<Expression> arguments = argumentList.arguments;
    int argumentCount = arguments.length;
    List<ParameterElement> resolvedParameters =
        new List<ParameterElement>(argumentCount);
    int positionalArgumentCount = 0;
    HashSet<String> usedNames = new HashSet<String>();
    bool noBlankArguments = true;
    for (int i = 0; i < argumentCount; i++) {
      Expression argument = arguments[i];
      if (argument is NamedExpression) {
        SimpleIdentifier nameNode = argument.name.label;
        String name = nameNode.name;
        ParameterElement element = namedParameters[name];
        if (element == null) {
          ErrorCode errorCode = (reportError
              ? CompileTimeErrorCode.UNDEFINED_NAMED_PARAMETER
              : StaticWarningCode.UNDEFINED_NAMED_PARAMETER);
          _resolver.reportErrorForNode(errorCode, nameNode, [name]);
        } else {
          resolvedParameters[i] = element;
          nameNode.staticElement = element;
        }
        if (!usedNames.add(name)) {
          _resolver.reportErrorForNode(
              CompileTimeErrorCode.DUPLICATE_NAMED_ARGUMENT, nameNode, [name]);
        }
      } else {
        if (argument is SimpleIdentifier && argument.name.isEmpty) {
          noBlankArguments = false;
        }
        positionalArgumentCount++;
        if (unnamedIndex < unnamedParameterCount) {
          resolvedParameters[i] = unnamedParameters[unnamedIndex++];
        }
      }
    }
    if (positionalArgumentCount < requiredParameters.length &&
        noBlankArguments) {
      ErrorCode errorCode = (reportError
          ? CompileTimeErrorCode.NOT_ENOUGH_REQUIRED_ARGUMENTS
          : StaticWarningCode.NOT_ENOUGH_REQUIRED_ARGUMENTS);
      _resolver.reportErrorForNode(errorCode, argumentList,
          [requiredParameters.length, positionalArgumentCount]);
    } else if (positionalArgumentCount > unnamedParameterCount &&
        noBlankArguments) {
      ErrorCode errorCode = (reportError
          ? CompileTimeErrorCode.EXTRA_POSITIONAL_ARGUMENTS
          : StaticWarningCode.EXTRA_POSITIONAL_ARGUMENTS);
      _resolver.reportErrorForNode(errorCode, argumentList,
          [unnamedParameterCount, positionalArgumentCount]);
    }
    return resolvedParameters;
  }

  void _resolveBinaryExpression(BinaryExpression node, String methodName) {
    Expression leftOperand = node.leftOperand;
    if (leftOperand != null) {
      DartType staticType = _getStaticType(leftOperand);
      MethodElement staticMethod =
          _lookUpMethod(leftOperand, staticType, methodName);
      node.staticElement = staticMethod;
      DartType propagatedType = _getPropagatedType(leftOperand);
      MethodElement propagatedMethod =
          _lookUpMethod(leftOperand, propagatedType, methodName);
      node.propagatedElement = propagatedMethod;
      if (_shouldReportMissingMember(staticType, staticMethod)) {
        if (leftOperand is SuperExpression) {
          _recordUndefinedToken(
              staticType.element,
              StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
              node.operator,
              [methodName, staticType.displayName]);
        } else {
          _recordUndefinedToken(
              staticType.element,
              StaticTypeWarningCode.UNDEFINED_OPERATOR,
              node.operator,
              [methodName, staticType.displayName]);
        }
      } else if (_enableHints &&
          _shouldReportMissingMember(propagatedType, propagatedMethod) &&
          !_memberFoundInSubclass(
              propagatedType.element, methodName, true, false)) {
        _recordUndefinedToken(
            propagatedType.element,
            HintCode.UNDEFINED_OPERATOR,
            node.operator,
            [methodName, propagatedType.displayName]);
      }
    }
  }

  /**
   * Resolve the names in the given [combinators] in the scope of the given
   * [library].
   */
  void _resolveCombinators(
      LibraryElement library, NodeList<Combinator> combinators) {
    if (library == null) {
      //
      // The library will be null if the directive containing the combinators
      // has a URI that is not valid.
      //
      return;
    }
    Namespace namespace =
        new NamespaceBuilder().createExportNamespaceForLibrary(library);
    for (Combinator combinator in combinators) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = combinator.hiddenNames;
      } else {
        names = (combinator as ShowCombinator).shownNames;
      }
      for (SimpleIdentifier name in names) {
        String nameStr = name.name;
        Element element = namespace.get(nameStr);
        if (element == null) {
          element = namespace.get("$nameStr=");
        }
        if (element != null) {
          // Ensure that the name always resolves to a top-level variable
          // rather than a getter or setter
          if (element is PropertyAccessorElement) {
            element = (element as PropertyAccessorElement).variable;
          }
          name.staticElement = element;
        }
      }
    }
  }

  /**
   * Given that we are accessing a property of the given [classElement] with the
   * given [propertyName], return the element that represents the property.
   */
  Element _resolveElement(
      ClassElementImpl classElement, SimpleIdentifier propertyName) {
    String name = propertyName.name;
    Element element = null;
    if (propertyName.inSetterContext()) {
      element = classElement.getSetter(name);
    }
    if (element == null) {
      element = classElement.getGetter(name);
    }
    if (element == null) {
      element = classElement.getMethod(name);
    }
    if (element != null && element.isAccessibleIn(_definingLibrary)) {
      return element;
    }
    return null;
  }

  /**
   * Given an invocation of the form 'm(a1, ..., an)', resolve 'm' to the
   * element being invoked. If the returned element is a method, then the method
   * will be invoked. If the returned element is a getter, the getter will be
   * invoked without arguments and the result of that invocation will then be
   * invoked with the arguments. The [methodName] is the name of the method
   * being invoked ('m').
   */
  Element _resolveInvokedElement(SimpleIdentifier methodName) {
    //
    // Look first in the lexical scope.
    //
    Element element = _resolver.nameScope.lookup(methodName, _definingLibrary);
    if (element == null) {
      //
      // If it isn't defined in the lexical scope, and the invocation is within
      // a class, then look in the inheritance scope.
      //
      ClassElement enclosingClass = _resolver.enclosingClass;
      if (enclosingClass != null) {
        InterfaceType enclosingType = enclosingClass.type;
        element = _lookUpMethod(null, enclosingType, methodName.name);
        if (element == null) {
          //
          // If there's no method, then it's possible that 'm' is a getter that
          // returns a function.
          //
          element = _lookUpGetter(null, enclosingType, methodName.name);
        }
      }
    }
    // TODO(brianwilkerson) Report this error.
    return element;
  }

  /**
   * Given an invocation of the form 'e.m(a1, ..., an)', resolve 'e.m' to the
   * element being invoked. If the returned element is a method, then the method
   * will be invoked. If the returned element is a getter, the getter will be
   * invoked without arguments and the result of that invocation will then be
   * invoked with the arguments. The [target] is the target of the invocation
   * ('e'). The [targetType] is the type of the target. The [methodName] is th
   * name of the method being invoked ('m').  [isConditional] indicates
   * whether the invocatoin uses a '?.' operator.
   */
  Element _resolveInvokedElementWithTarget(Expression target,
      DartType targetType, SimpleIdentifier methodName, bool isConditional) {
    if (targetType is InterfaceType) {
      Element element = _lookUpMethod(target, targetType, methodName.name);
      if (element == null) {
        //
        // If there's no method, then it's possible that 'm' is a getter that
        // returns a function.
        //
        // TODO (collinsn): need to add union type support here too, in the
        // style of [lookUpMethod].
        element = _lookUpGetter(target, targetType, methodName.name);
      }
      return element;
    } else if (target is SimpleIdentifier) {
      Element targetElement = target.staticElement;
      if (targetElement is PrefixElement) {
        if (isConditional) {
          _resolver.reportErrorForNode(
              CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
              target,
              [target.name]);
        }
        //
        // Look to see whether the name of the method is really part of a
        // prefixed identifier for an imported top-level function or top-level
        // getter that returns a function.
        //
        String name = "${target.name}.$methodName";
        Identifier functionName = new SyntheticIdentifier(name, methodName);
        Element element =
            _resolver.nameScope.lookup(functionName, _definingLibrary);
        if (element != null) {
          // TODO(brianwilkerson) This isn't a method invocation, it's a
          // function invocation where the function name is a prefixed
          // identifier. Consider re-writing the AST.
          return element;
        }
      }
    }
    // TODO(brianwilkerson) Report this error.
    return null;
  }

  /**
   * Given that we are accessing a property of the given [targetType] with the
   * given [propertyName], return the element that represents the property. The
   * [target] is the target of the invocation ('e').
   */
  ExecutableElement _resolveProperty(
      Expression target, DartType targetType, SimpleIdentifier propertyName) {
    ExecutableElement memberElement = null;
    if (propertyName.inSetterContext()) {
      memberElement = _lookUpSetter(target, targetType, propertyName.name);
    }
    if (memberElement == null) {
      memberElement = _lookUpGetter(target, targetType, propertyName.name);
    }
    if (memberElement == null) {
      memberElement = _lookUpMethod(target, targetType, propertyName.name);
    }
    return memberElement;
  }

  void _resolvePropertyAccess(
      Expression target, SimpleIdentifier propertyName) {
    DartType staticType = _getStaticType(target);
    DartType propagatedType = _getPropagatedType(target);
    Element staticElement = null;
    Element propagatedElement = null;
    //
    // If this property access is of the form 'C.m' where 'C' is a class,
    // then we don't call resolveProperty(...) which walks up the class
    // hierarchy, instead we just look for the member in the type only.  This
    // does not apply to conditional property accesses (i.e. 'C?.m').
    //
    ClassElementImpl typeReference = getTypeReference(target);
    if (typeReference != null) {
      // TODO(brianwilkerson) Why are we setting the propagated element here?
      // It looks wrong.
      staticElement =
          propagatedElement = _resolveElement(typeReference, propertyName);
    } else {
      staticElement = _resolveProperty(target, staticType, propertyName);
      propagatedElement =
          _resolveProperty(target, propagatedType, propertyName);
    }
    // May be part of annotation, record property element only if exists.
    // Error was already reported in validateAnnotationElement().
    if (target.parent.parent is Annotation) {
      if (staticElement != null) {
        propertyName.staticElement = staticElement;
      }
      return;
    }
    propertyName.staticElement = staticElement;
    propertyName.propagatedElement = propagatedElement;
    bool shouldReportMissingMember_static =
        _shouldReportMissingMember(staticType, staticElement);
    bool shouldReportMissingMember_propagated =
        !shouldReportMissingMember_static &&
            _enableHints &&
            _shouldReportMissingMember(propagatedType, propagatedElement) &&
            !_memberFoundInSubclass(
                propagatedType.element, propertyName.name, false, true);
    if (shouldReportMissingMember_static ||
        shouldReportMissingMember_propagated) {
      DartType staticOrPropagatedType =
          shouldReportMissingMember_static ? staticType : propagatedType;
      Element staticOrPropagatedEnclosingElt = staticOrPropagatedType.element;
      bool isStaticProperty = _isStatic(staticOrPropagatedEnclosingElt);
      DartType displayType = staticOrPropagatedType != null
          ? staticOrPropagatedType
          : propagatedType != null ? propagatedType : staticType;
      // Special getter cases.
      if (propertyName.inGetterContext()) {
        if (!isStaticProperty &&
            staticOrPropagatedEnclosingElt is ClassElement) {
          ClassElement classElement = staticOrPropagatedEnclosingElt;
          InterfaceType targetType = classElement.type;
          if (!_enableStrictCallChecks &&
              targetType != null &&
              targetType.isDartCoreFunction &&
              propertyName.name == FunctionElement.CALL_METHOD_NAME) {
            // TODO(brianwilkerson) Can we ever resolve the function being
            // invoked?
//            resolveArgumentsToParameters(node.getArgumentList(), invokedFunction);
            return;
          } else if (classElement.isEnum && propertyName.name == "_name") {
            _resolver.reportErrorForNode(
                CompileTimeErrorCode.ACCESS_PRIVATE_ENUM_FIELD,
                propertyName,
                [propertyName.name]);
            return;
          }
        }
      }
      Element declaringElement =
          staticType.isVoid ? null : staticOrPropagatedEnclosingElt;
      if (propertyName.inSetterContext()) {
        ErrorCode errorCode;
        if (shouldReportMissingMember_static) {
          if (target is SuperExpression) {
            if (isStaticProperty && !staticType.isVoid) {
              errorCode = StaticWarningCode.UNDEFINED_SUPER_SETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_SETTER;
            }
          } else {
            if (isStaticProperty && !staticType.isVoid) {
              errorCode = StaticWarningCode.UNDEFINED_SETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_SETTER;
            }
          }
        } else {
          errorCode = HintCode.UNDEFINED_SETTER;
        }
        _recordUndefinedNode(declaringElement, errorCode, propertyName,
            [propertyName.name, displayType.displayName]);
      } else if (propertyName.inGetterContext()) {
        ErrorCode errorCode;
        if (shouldReportMissingMember_static) {
          if (target is SuperExpression) {
            if (isStaticProperty && !staticType.isVoid) {
              errorCode = StaticWarningCode.UNDEFINED_SUPER_GETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_GETTER;
            }
          } else {
            if (isStaticProperty && !staticType.isVoid) {
              errorCode = StaticWarningCode.UNDEFINED_GETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_GETTER;
            }
          }
        } else {
          errorCode = HintCode.UNDEFINED_GETTER;
        }
        _recordUndefinedNode(declaringElement, errorCode, propertyName,
            [propertyName.name, displayType.displayName]);
      } else {
        _recordUndefinedNode(
            declaringElement,
            StaticWarningCode.UNDEFINED_IDENTIFIER,
            propertyName,
            [propertyName.name]);
      }
    }
  }

  /**
   * Resolve the given simple [identifier] if possible. Return the element to
   * which it could be resolved, or `null` if it could not be resolved. This
   * does not record the results of the resolution.
   */
  Element _resolveSimpleIdentifier(SimpleIdentifier identifier) {
    Element element = _resolver.nameScope.lookup(identifier, _definingLibrary);
    if (element is PropertyAccessorElement && identifier.inSetterContext()) {
      PropertyInducingElement variable =
          (element as PropertyAccessorElement).variable;
      if (variable != null) {
        PropertyAccessorElement setter = variable.setter;
        if (setter == null) {
          //
          // Check to see whether there might be a locally defined getter and
          // an inherited setter.
          //
          ClassElement enclosingClass = _resolver.enclosingClass;
          if (enclosingClass != null) {
            setter = _lookUpSetter(null, enclosingClass.type, identifier.name);
          }
        }
        if (setter != null) {
          element = setter;
        }
      }
    } else if (element == null &&
        (identifier.inSetterContext() ||
            identifier.parent is CommentReference)) {
      element = _resolver.nameScope.lookup(
          new SyntheticIdentifier("${identifier.name}=", identifier),
          _definingLibrary);
    }
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (element == null && enclosingClass != null) {
      InterfaceType enclosingType = enclosingClass.type;
      if (element == null &&
          (identifier.inSetterContext() ||
              identifier.parent is CommentReference)) {
        element = _lookUpSetter(null, enclosingType, identifier.name);
      }
      if (element == null && identifier.inGetterContext()) {
        element = _lookUpGetter(null, enclosingType, identifier.name);
      }
      if (element == null) {
        element = _lookUpMethod(null, enclosingType, identifier.name);
      }
    }
    return element;
  }

  /**
   * If the given [type] is a type parameter, resolve it to the type that should
   * be used when looking up members. Otherwise, return the original type.
   */
  DartType _resolveTypeParameter(DartType type) {
    if (type is TypeParameterType) {
      DartType bound = type.element.bound;
      if (bound == null) {
        return _resolver.typeProvider.objectType;
      }
      return bound;
    }
    return type;
  }

  /**
   * Given a [node] that can have annotations associated with it and the
   * [element] to which that node has been resolved, create the annotations in
   * the element model representing the annotations on the node.
   */
  void _setMetadataForParameter(Element element, NormalFormalParameter node) {
    if (element is! ElementImpl) {
      return;
    }
    List<ElementAnnotationImpl> annotationList =
        new List<ElementAnnotationImpl>();
    _addAnnotations(annotationList, node.metadata);
    if (!annotationList.isEmpty) {
      (element as ElementImpl).metadata = annotationList;
    }
  }

  /**
   * Return `true` if we should report an error as a result of looking up a
   * [member] in the given [type] and not finding any member.
   */
  bool _shouldReportMissingMember(DartType type, Element member) {
    if (member != null || type == null || type.isDynamic || type.isBottom) {
      return false;
    }
    return true;
  }

  /**
   * Checks whether the given [expression] is a reference to a class. If it is
   * then the element representing the class is returned, otherwise `null` is
   * returned.
   */
  static ClassElementImpl getTypeReference(Expression expression) {
    if (expression is Identifier) {
      Element staticElement = expression.staticElement;
      if (staticElement is ClassElementImpl) {
        return staticElement;
      }
    }
    return null;
  }

  /**
   * Given a [node] that can have annotations associated with it and the
   * [element] to which that node has been resolved, create the annotations in
   * the element model representing the annotations on the node.
   */
  static void setMetadata(Element element, AnnotatedNode node) {
    if (element is! ElementImpl) {
      return;
    }
    List<ElementAnnotationImpl> annotationList = <ElementAnnotationImpl>[];
    _addAnnotations(annotationList, node.metadata);
    if (node is VariableDeclaration && node.parent is VariableDeclarationList) {
      VariableDeclarationList list = node.parent as VariableDeclarationList;
      _addAnnotations(annotationList, list.metadata);
      if (list.parent is FieldDeclaration) {
        FieldDeclaration fieldDeclaration = list.parent as FieldDeclaration;
        _addAnnotations(annotationList, fieldDeclaration.metadata);
      } else if (list.parent is TopLevelVariableDeclaration) {
        TopLevelVariableDeclaration variableDeclaration =
            list.parent as TopLevelVariableDeclaration;
        _addAnnotations(annotationList, variableDeclaration.metadata);
      }
    }
    if (!annotationList.isEmpty) {
      (element as ElementImpl).metadata = annotationList;
    }
  }

  /**
   * Generate annotation elements for each of the annotations in the
   * [annotationList] and add them to the given list of [annotations].
   */
  static void _addAnnotations(List<ElementAnnotationImpl> annotationList,
      NodeList<Annotation> annotations) {
    int annotationCount = annotations.length;
    for (int i = 0; i < annotationCount; i++) {
      Annotation annotation = annotations[i];
      Element resolvedElement = annotation.element;
      if (resolvedElement != null) {
        ElementAnnotationImpl elementAnnotation =
            new ElementAnnotationImpl(resolvedElement);
        annotation.elementAnnotation = elementAnnotation;
        annotationList.add(elementAnnotation);
      }
    }
  }

  /**
   * Return `true` if the given [identifier] is the return type of a constructor
   * declaration.
   */
  static bool _isConstructorReturnType(SimpleIdentifier identifier) {
    AstNode parent = identifier.parent;
    if (parent is ConstructorDeclaration) {
      return identical(parent.returnType, identifier);
    }
    return false;
  }

  /**
   * Return `true` if the given [identifier] is the return type of a factory
   * constructor.
   */
  static bool _isFactoryConstructorReturnType(SimpleIdentifier identifier) {
    AstNode parent = identifier.parent;
    if (parent is ConstructorDeclaration) {
      ConstructorDeclaration constructor = parent;
      return identical(constructor.returnType, identifier) &&
          constructor.factoryKeyword != null;
    }
    return false;
  }

  /**
   * Return `true` if the given 'super' [expression] is used in a valid context.
   */
  static bool _isSuperInValidContext(SuperExpression expression) {
    for (AstNode node = expression; node != null; node = node.parent) {
      if (node is CompilationUnit) {
        return false;
      }
      if (node is ConstructorDeclaration) {
        return node.factoryKeyword == null;
      }
      if (node is ConstructorFieldInitializer) {
        return false;
      }
      if (node is MethodDeclaration) {
        return !node.isStatic;
      }
    }
    return false;
  }
}

/**
 * An identifier that can be used to look up names in the lexical scope when
 * there is no identifier in the AST structure. There is no identifier in the
 * AST when the parser could not distinguish between a method invocation and an
 * invocation of a top-level function imported with a prefix.
 */
class SyntheticIdentifier extends Identifier {
  /**
   * The name of the synthetic identifier.
   */
  final String name;

  /**
   * The identifier to be highlighted in case of an error
   */
  final Identifier targetIdentifier;

  /**
   * Initialize a newly created synthetic identifier to have the given [name]
   * and [targetIdentifier].
   */
  SyntheticIdentifier(this.name, this.targetIdentifier);

  @override
  sc.Token get beginToken => null;

  @override
  Element get bestElement => null;

  @override
  Iterable get childEntities {
    // Should never be called, since a SyntheticIdentifier never appears in the
    // AST--it is just used for lookup.
    assert(false);
    return new ChildEntities();
  }

  @override
  sc.Token get endToken => null;

  @override
  int get length => targetIdentifier.length;

  @override
  int get offset => targetIdentifier.offset;

  @override
  int get precedence => 16;

  @override
  Element get propagatedElement => null;

  @override
  Element get staticElement => null;

  @override
  accept(AstVisitor visitor) => null;

  @override
  void visitChildren(AstVisitor visitor) {}
}
