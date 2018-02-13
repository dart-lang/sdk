// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/ast_factory.dart';
import 'package:analyzer/dart/ast/syntactic_entity.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/dart/ast/ast.dart'
    show
        ChildEntities,
        IdentifierImpl,
        PrefixedIdentifierImpl,
        SimpleIdentifierImpl;
import 'package:analyzer/src/dart/ast/ast_factory.dart';
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/ast/utilities.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/task/strong/checker.dart';

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
  InterfaceType _typeType;

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
   * Gets an instance of [AstFactory] based on the standard AST implementation.
   */
  AstFactory _astFactory;

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
    _astFactory = new AstFactoryImpl();
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
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    Expression leftHandSide = node.leftHandSide;
    DartType staticType = _getStaticType(leftHandSide, read: true);

    // For any compound assignments to a void variable, report bad void usage.
    // Example: `y += voidFn()`, not allowed.
    if (operatorType != TokenType.EQ &&
        staticType != null &&
        staticType.isVoid) {
      _recordUndefinedToken(
          null, StaticWarningCode.USE_OF_VOID_RESULT, operator, []);
      return null;
    }

    if (operatorType != TokenType.AMPERSAND_AMPERSAND_EQ &&
        operatorType != TokenType.BAR_BAR_EQ &&
        operatorType != TokenType.EQ &&
        operatorType != TokenType.QUESTION_QUESTION_EQ) {
      operatorType = _operatorFromCompoundAssignment(operatorType);
      if (leftHandSide != null) {
        String methodName = operatorType.lexeme;
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
    Token operator = node.operator;
    if (operator.isUserDefinableOperator) {
      _resolveBinaryExpression(node, operator.lexeme);
    } else if (operator.type == TokenType.BANG_EQ) {
      _resolveBinaryExpression(node, TokenType.EQ_EQ.lexeme);
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
    resolveMetadata(node);
    return null;
  }

  @override
  Object visitClassTypeAlias(ClassTypeAlias node) {
    resolveMetadata(node);
    return null;
  }

  @override
  Object visitCommentReference(CommentReference node) {
    Identifier identifier = node.identifier;
    if (identifier is SimpleIdentifier) {
      Element element = _resolveSimpleIdentifier(identifier);
      if (element == null) {
        //
        // This might be a reference to an imported name that is missing the
        // prefix.
        //
        element = _findImportWithoutPrefix(identifier);
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
        identifier.staticElement = element;
        if (node.newKeyword != null) {
          if (element is ClassElement) {
            ConstructorElement constructor = element.unnamedConstructor;
            if (constructor == null) {
              // TODO(brianwilkerson) Report this error.
            } else {
              identifier.staticElement = constructor;
            }
          } else {
            // TODO(brianwilkerson) Report this error.
          }
        }
      }
    } else if (identifier is PrefixedIdentifier) {
      SimpleIdentifier prefix = identifier.prefix;
      SimpleIdentifier name = identifier.identifier;
      Element element = _resolveSimpleIdentifier(prefix);
      if (element == null) {
//        resolver.reportError(StaticWarningCode.UNDEFINED_IDENTIFIER, prefix, prefix.getName());
      } else {
        prefix.staticElement = element;
        if (element is PrefixElement) {
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
//              reportGetterOrSetterNotFound(identifier, name, element.getDisplayName());
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
      ConstructorName redirectedNode = node.redirectedConstructor;
      if (redirectedNode != null) {
        // set redirected factory constructor
        ConstructorElement redirectedElement = redirectedNode.staticElement;
        element.redirectedConstructor = redirectedElement;
      } else {
        // set redirected generative constructor
        for (ConstructorInitializer initializer in node.initializers) {
          if (initializer is RedirectingConstructorInvocation) {
            ConstructorElement redirectedElement = initializer.staticElement;
            element.redirectedConstructor = redirectedElement;
          }
        }
      }
      resolveMetadata(node);
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
      // Nothing to do.
    } else if (type is InterfaceType) {
      // look up ConstructorElement
      ConstructorElement constructor;
      SimpleIdentifier name = node.name;
      if (name == null) {
        constructor = type.lookUpConstructor(null, _definingLibrary);
      } else {
        constructor = type.lookUpConstructor(name.name, _definingLibrary);
        name.staticElement = constructor;
      }
      node.staticElement = constructor;
    } else {
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
    }
    return null;
  }

  @override
  Object visitContinueStatement(ContinueStatement node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, true);
    return null;
  }

  @override
  Object visitDeclaredIdentifier(DeclaredIdentifier node) {
    resolveMetadata(node);
    return null;
  }

  @override
  Object visitEnumDeclaration(EnumDeclaration node) {
    resolveMetadata(node);
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
      resolveMetadata(node);
    }
    return null;
  }

  @override
  Object visitFieldFormalParameter(FieldFormalParameter node) {
    _resolveMetadataForParameter(node);
    return super.visitFieldFormalParameter(node);
  }

  @override
  Object visitFunctionDeclaration(FunctionDeclaration node) {
    resolveMetadata(node);
    return null;
  }

  @override
  Object visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    Expression function = node.function;
    DartType staticInvokeType = _instantiateGenericMethod(
        function.staticType, node.typeArguments, node);
    DartType propagatedInvokeType = _instantiateGenericMethod(
        function.propagatedType, node.typeArguments, node);

    node.staticInvokeType = staticInvokeType;
    node.propagatedInvokeType =
        _propagatedInvokeTypeIfBetter(propagatedInvokeType, staticInvokeType);

    List<ParameterElement> parameters =
        _computeCorrespondingParameters(node.argumentList, staticInvokeType);
    if (parameters != null) {
      node.argumentList.correspondingStaticParameters = parameters;
    }

    parameters = _computeCorrespondingParameters(
        node.argumentList, propagatedInvokeType);
    if (parameters != null) {
      node.argumentList.correspondingPropagatedParameters = parameters;
    }
    return null;
  }

  @override
  Object visitFunctionTypeAlias(FunctionTypeAlias node) {
    resolveMetadata(node);
    return null;
  }

  @override
  Object visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _resolveMetadataForParameter(node);
    return null;
  }

  @override
  Object visitImportDirective(ImportDirective node) {
    SimpleIdentifier prefixNode = node.prefix;
    if (prefixNode != null) {
      String prefixName = prefixNode.name;
      List<PrefixElement> prefixes = _definingLibrary.prefixes;
      int count = prefixes.length;
      for (int i = 0; i < count; i++) {
        PrefixElement prefixElement = prefixes[i];
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
      resolveMetadata(node);
    }
    return null;
  }

  @override
  Object visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    DartType staticType = _getStaticType(target);
    DartType propagatedType = _getPropagatedType(target);
    String getterMethodName = TokenType.INDEX.lexeme;
    String setterMethodName = TokenType.INDEX_EQ.lexeme;
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
    resolveMetadata(node);
    return null;
  }

  @override
  Object visitMethodDeclaration(MethodDeclaration node) {
    resolveMetadata(node);
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
    bool previewDart2 = _definingLibrary.context.analysisOptions.previewDart2;
    if (target == null) {
      staticElement = _resolveInvokedElement(methodName);
      propagatedElement = null;

      if (previewDart2 &&
          staticElement != null &&
          staticElement is ClassElement) {
        // cases: C() or C<>()
        InstanceCreationExpression instanceCreationExpression =
            _handleImplicitConstructorCase(node, staticElement);
        if (instanceCreationExpression != null) {
          // If a non-null is returned, the node was created, replaced, so we
          // can return here.
          return null;
        }
      }
    } else if (methodName.name == FunctionElement.LOAD_LIBRARY_NAME &&
        _isDeferredPrefix(target)) {
      if (node.operator.type == TokenType.QUESTION_PERIOD) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
            target,
            [(target as SimpleIdentifier).name]);
      }
      LibraryElement importedLibrary = _getImportedLibrary(target);
      FunctionElement loadLibraryFunction =
          importedLibrary?.loadLibraryFunction;
      methodName.staticElement = loadLibraryFunction;
      node.staticInvokeType = loadLibraryFunction?.type;
      return null;
    } else {
      //
      // If this method invocation is of the form 'C.m' where 'C' is a class,
      // then we don't call resolveInvokedElement(...) which walks up the class
      // hierarchy, instead we just look for the member in the type only.  This
      // does not apply to conditional method invocation (i.e. 'C?.m(...)').
      //
      bool isConditional = node.operator.type == TokenType.QUESTION_PERIOD;
      ClassElement typeReference = getTypeReference(target);

      if (previewDart2) {
        InstanceCreationExpression instanceCreationExpression;
        if ((target is SimpleIdentifier &&
                target.staticElement is PrefixElement) ||
            (target is PrefixedIdentifier &&
                target.prefix.staticElement is PrefixElement)) {
          // case: p.C(), p.C<>() or p.C.n()
          instanceCreationExpression =
              _handlePrefixedImplicitConstructorCase(node, target);
        } else if (typeReference is ClassElement) {
          // case: C.n()
          instanceCreationExpression =
              _handleImplicitConstructorCase(node, typeReference);
        }

        if (instanceCreationExpression != null) {
          // If a non-null is returned, the node was created, replaced, so we
          // can return here.
          return null;
        }
      }

      if (typeReference != null) {
        if (node.isCascaded) {
          typeReference = _typeType.element;
        }
        staticElement = _resolveElement(typeReference, methodName);
      } else {
        DartType staticType = _resolver.strongMode
            ? _getStaticTypeOrFunctionType(target)
            : _getStaticType(target);
        DartType propagatedType = _getPropagatedType(target);
        staticElement = _resolveInvokedElementWithTarget(
            target, staticType, methodName, isConditional);
        // If we have propagated type information use it (since it should
        // not be redundant with the staticType).  Otherwise, don't produce
        // a propagatedElement which duplicates the staticElement.
        if (propagatedType is InterfaceType) {
          propagatedElement = _resolveInvokedElementWithTarget(
              target, propagatedType, methodName, isConditional);
        }
      }
    }

    staticElement = _convertSetterToGetter(staticElement);
    propagatedElement = _convertSetterToGetter(propagatedElement);

    //
    // Given the elements, determine the type of the function we are invoking
    //
    DartType staticInvokeType = _getInvokeType(staticElement);
    methodName.staticType = staticInvokeType;

    DartType propagatedInvokeType = _getInvokeType(propagatedElement);
    methodName.propagatedType =
        _propagatedInvokeTypeIfBetter(propagatedInvokeType, staticInvokeType);

    //
    // Instantiate generic function or method if needed.
    //
    staticInvokeType = _instantiateGenericMethod(
        staticInvokeType, node.typeArguments, node.methodName);
    propagatedInvokeType = _instantiateGenericMethod(
        propagatedInvokeType, node.typeArguments, node.methodName);

    //
    // Record the results.
    //
    methodName.staticElement = staticElement;
    methodName.propagatedElement = propagatedElement;

    node.staticInvokeType = staticInvokeType;
    //
    // Store the propagated invoke type if it's more specific than the static
    // type.
    //
    // We still need to record the propagated parameter elements however,
    // as they are used in propagatedType downwards inference of lambda
    // parameters. So we don't want to clear the propagatedInvokeType variable.
    //
    node.propagatedInvokeType =
        _propagatedInvokeTypeIfBetter(propagatedInvokeType, staticInvokeType);

    ArgumentList argumentList = node.argumentList;
    if (staticInvokeType != null) {
      List<ParameterElement> parameters =
          _computeCorrespondingParameters(argumentList, staticInvokeType);
      argumentList.correspondingStaticParameters = parameters;
    }
    if (propagatedInvokeType != null) {
      List<ParameterElement> parameters =
          _computeCorrespondingParameters(argumentList, propagatedInvokeType);
      argumentList.correspondingPropagatedParameters = parameters;
    }
    //
    // Then check for error conditions.
    //
    ErrorCode errorCode = _checkForInvocationError(target, true, staticElement);
    if (errorCode != null &&
        target is SimpleIdentifier &&
        target.staticElement is PrefixElement) {
      Identifier functionName =
          new PrefixedIdentifierImpl.temp(target, methodName);
      if (_resolver.nameScope.shouldIgnoreUndefined(functionName)) {
        return null;
      }
    }
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
            Element element = type.element;
            if (element is ClassElement) {
              classElementContext = element;
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
      if (!_resolver.nameScope.shouldIgnoreUndefined(methodName)) {
        _resolver.errorReporter
            .reportErrorForNode(errorCode, methodName, [methodName.name]);
      }
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
        if (!node.isCascaded) {
          ClassElement typeReference = getTypeReference(target);
          if (typeReference != null) {
            ConstructorElement constructor =
                typeReference.getNamedConstructor(methodName.name);
            if (constructor != null) {
              _recordUndefinedNode(
                  typeReference,
                  StaticTypeWarningCode.UNDEFINED_METHOD_WITH_CONSTRUCTOR,
                  methodName,
                  [methodName.name, typeReference.name]);
              return null;
            }
          }
        }

        targetTypeName = targetType?.displayName;
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
      DartType getSuperType(DartType type) {
        if (type is InterfaceType && !type.isObject) {
          return type.superclass;
        }
        return type;
      }

      DartType targetType = getSuperType(_getStaticType(target));
      String targetTypeName = targetType?.name;
      _resolver.errorReporter.reportErrorForNode(
          StaticTypeWarningCode.UNDEFINED_SUPER_METHOD,
          methodName,
          [methodName.name, targetTypeName]);
    } else if (identical(errorCode, StaticWarningCode.USE_OF_VOID_RESULT)) {
      _resolver.errorReporter.reportErrorForNode(
          StaticWarningCode.USE_OF_VOID_RESULT, target ?? methodName, []);
    }
    return null;
  }

  @override
  Object visitPartDirective(PartDirective node) {
    resolveMetadata(node);
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
      identifier.staticElement = importedLibrary?.loadLibraryFunction;
      return null;
    }
    //
    // Check to see whether the prefix is really a prefix.
    //
    Element prefixElement = prefix.staticElement;
    if (prefixElement is PrefixElement) {
      Element element = _resolver.nameScope.lookup(node, _definingLibrary);
      if (element == null && identifier.inSetterContext()) {
        Identifier setterName = new PrefixedIdentifierImpl.temp(
            node.prefix,
            new SimpleIdentifierImpl(new StringToken(TokenType.STRING,
                "${node.identifier.name}=", node.identifier.offset - 1)));
        element = _resolver.nameScope.lookup(setterName, _definingLibrary);
      }
      if (element == null && _resolver.nameScope.shouldIgnoreUndefined(node)) {
        return null;
      }
      if (element == null) {
        if (identifier.inSetterContext()) {
          _resolver.errorReporter.reportErrorForNode(
              StaticWarningCode.UNDEFINED_SETTER,
              identifier,
              [identifier.name, prefixElement.name]);
          return null;
        }
        AstNode parent = node.parent;
        if (parent is Annotation) {
          _resolver.errorReporter.reportErrorForNode(
              CompileTimeErrorCode.INVALID_ANNOTATION, parent);
        } else {
          _resolver.errorReporter.reportErrorForNode(
              StaticWarningCode.UNDEFINED_GETTER,
              identifier,
              [identifier.name, prefixElement.name]);
        }
        return null;
      }
      Element accessor = element;
      if (accessor is PropertyAccessorElement && identifier.inSetterContext()) {
        PropertyInducingElement variable = accessor.variable;
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
      AstNode parent = node.parent;
      if (parent is Annotation) {
        _resolveAnnotationElement(parent);
      }
      return null;
    }
    // May be annotation, resolve invocation of "const" constructor.
    AstNode parent = node.parent;
    if (parent is Annotation) {
      _resolveAnnotationElement(parent);
    }
    //
    // Otherwise, the prefix is really an expression that happens to be a simple
    // identifier and this is really equivalent to a property access node.
    //
    _resolvePropertyAccess(prefix, identifier, false);
    return null;
  }

  @override
  Object visitPrefixExpression(PrefixExpression node) {
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    if (operatorType.isUserDefinableOperator ||
        operatorType == TokenType.PLUS_PLUS ||
        operatorType == TokenType.MINUS_MINUS) {
      Expression operand = node.operand;
      String methodName = _getPrefixOperator(node);
      DartType staticType = _getStaticType(operand, read: true);
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
    _resolvePropertyAccess(target, propertyName, node.isCascaded);
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
    _resolveMetadataForParameter(node);
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
    // Ignore nodes that should have been resolved before getting here.
    //
    if (node.inDeclarationContext()) {
      return null;
    }
    if (node.staticElement is LocalVariableElement ||
        node.staticElement is ParameterElement) {
      return null;
    }
    AstNode parent = node.parent;
    if (parent is FieldFormalParameter) {
      return null;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return null;
    } else if (parent is Annotation && parent.constructorName == node) {
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
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, node);
    } else if (_isConstructorReturnType(node) &&
        !identical(element, enclosingClass)) {
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node);
      element = null;
    } else if (element == null ||
        (element is PrefixElement && !_isValidAsPrefix(node))) {
      // TODO(brianwilkerson) Recover from this error.
      if (_isConstructorReturnType(node)) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node);
      } else if (parent is Annotation) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_ANNOTATION, parent);
      } else if (element != null) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
            node,
            [element.name]);
      } else if (node.name == "await" && _resolver.enclosingFunction != null) {
        _recordUndefinedNode(
            _resolver.enclosingClass,
            StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT,
            node,
            [_resolver.enclosingFunction.displayName]);
      } else if (!_resolver.nameScope.shouldIgnoreUndefined(node)) {
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
    if (parent is Annotation) {
      _resolveAnnotationElement(parent);
    }
    return null;
  }

  @override
  Object visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassElementImpl enclosingClass =
        AbstractClassElementImpl.getImpl(_resolver.enclosingClass);
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
    String superName = name?.name;
    ConstructorElement element =
        superType.lookUpConstructor(superName, _definingLibrary);
    if (element == null ||
        (!enclosingClass.doesMixinLackConstructors &&
            !enclosingClass.isSuperConstructorAccessible(element))) {
      if (name != null) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER,
            node,
            [superType.displayName, name]);
      } else {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
            node,
            [superType.displayName]);
      }
      return null;
    } else {
      if (element.isFactory) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.NON_GENERATIVE_CONSTRUCTOR, node, [element]);
      }
    }
    if (name != null) {
      name.staticElement = element;
    }
    node.staticElement = element;
    // TODO(brianwilkerson) Defer this check until we know there's an error (by
    // in-lining _resolveArgumentsToFunction below).
    ClassDeclaration declaration =
        node.getAncestor((AstNode node) => node is ClassDeclaration);
    Identifier superclassName = declaration.extendsClause?.superclass?.name;
    if (superclassName != null &&
        _resolver.nameScope.shouldIgnoreUndefined(superclassName)) {
      return null;
    }
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
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node);
    }
    return super.visitSuperExpression(node);
  }

  @override
  Object visitTypeParameter(TypeParameter node) {
    resolveMetadata(node);
    return null;
  }

  @override
  Object visitVariableDeclaration(VariableDeclaration node) {
    resolveMetadata(node);
    return null;
  }

  /**
   * Given that we have found code to invoke the given [element], return the
   * error code that should be reported, or `null` if no error should be
   * reported. The [target] is the target of the invocation, or `null` if there
   * was no target. The flag [useStaticContext] should be `true` if the
   * invocation is in a static constant (does not have access to instance state).
   */
  ErrorCode _checkForInvocationError(
      Expression target, bool useStaticContext, Element element) {
    // Prefix is not declared, instead "prefix.id" are declared.
    if (element is PrefixElement) {
      return CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT;
    } else if (element is PropertyAccessorElement) {
      //
      // This is really a function expression invocation.
      //
      // TODO(brianwilkerson) Consider the possibility of re-writing the AST.
      FunctionType getterType = element.type;
      if (getterType != null) {
        DartType returnType = getterType.returnType;
        return _getErrorCodeForExecuting(returnType);
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
          return _getErrorCodeForExecuting(returnType);
        }
      } else if (element is VariableElement) {
        DartType variableType = element.type;
        return _getErrorCodeForExecuting(variableType);
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
            if (target is Identifier &&
                _resolver.nameScope.shouldIgnoreUndefined(target)) {
              return null;
            }
            return StaticTypeWarningCode.UNDEFINED_FUNCTION;
          } else if (targetType.isVoid) {
            return StaticWarningCode.USE_OF_VOID_RESULT;
          } else if (!targetType.isDynamic && target is! NullLiteral) {
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
      Token leftBracket = expression.leftBracket;
      Token rightBracket = expression.rightBracket;
      ErrorCode errorCode;
      DartType type =
          shouldReportMissingMember_static ? staticType : propagatedType;
      var errorArguments = [methodName, type.displayName];
      if (shouldReportMissingMember_static) {
        if (target is SuperExpression) {
          errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR;
        } else if (staticType != null && staticType.isVoid) {
          errorCode = StaticWarningCode.USE_OF_VOID_RESULT;
          errorArguments = [];
        } else {
          errorCode = StaticTypeWarningCode.UNDEFINED_OPERATOR;
        }
      } else {
        errorCode = HintCode.UNDEFINED_OPERATOR;
      }
      if (leftBracket == null || rightBracket == null) {
        _recordUndefinedNode(
            type.element, errorCode, expression, errorArguments);
      } else {
        int offset = leftBracket.offset;
        int length = rightBracket.offset - offset + 1;
        _recordUndefinedOffset(
            type.element, errorCode, offset, length, errorArguments);
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
      ArgumentList argumentList, DartType type) {
    if (type is InterfaceType) {
      MethodElement callMethod =
          type.lookUpMethod(FunctionElement.CALL_METHOD_NAME, _definingLibrary);
      if (callMethod != null) {
        return _resolveArgumentsToFunction(false, argumentList, callMethod);
      }
    } else if (type is FunctionType) {
      return _resolveArgumentsToParameters(
          false, argumentList, type.parameters);
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
   * Look for any declarations of the given [identifier] that are imported using
   * a prefix. Return the element that was found, or `null` if the name is not
   * imported using a prefix.
   */
  Element _findImportWithoutPrefix(SimpleIdentifier identifier) {
    Element element = null;
    Scope nameScope = _resolver.nameScope;
    List<ImportElement> imports = _definingLibrary.imports;
    int length = imports.length;
    for (int i = 0; i < length; i++) {
      ImportElement importElement = imports[i];
      PrefixElement prefixElement = importElement.prefix;
      if (prefixElement != null) {
        Identifier prefixedIdentifier = new PrefixedIdentifierImpl.temp(
            new SimpleIdentifierImpl(new StringToken(TokenType.STRING,
                prefixElement.name, prefixElement.nameOffset)),
            identifier);
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
   * Assuming that the given [identifier] is a prefix for a deferred import,
   * return the library that is being imported.
   */
  LibraryElement _getImportedLibrary(SimpleIdentifier identifier) {
    PrefixElement prefixElement = identifier.staticElement as PrefixElement;
    List<ImportElement> imports =
        prefixElement.enclosingElement.getImportsWithPrefix(prefixElement);
    return imports[0].importedLibrary;
  }

  /**
   * Given an element, computes the type of the invocation.
   *
   * For executable elements (like methods, functions) this is just their type.
   *
   * For variables it is their type taking into account any type promotion.
   *
   * For calls to getters in Dart, we invoke the function that is returned by
   * the getter, so the invoke type is the getter's returnType.
   */
  DartType _getInvokeType(Element element) {
    DartType invokeType;
    if (element is PropertyAccessorElement) {
      invokeType = element.returnType;
    } else if (element is ExecutableElement) {
      invokeType = element.type;
    } else if (element is VariableElement) {
      invokeType = _promoteManager.getStaticType(element);
    }
    return invokeType ?? DynamicTypeImpl.instance;
  }

  /**
   * Return the name of the method invoked by the given postfix [expression].
   */
  String _getPostfixOperator(PostfixExpression expression) =>
      (expression.operator.type == TokenType.PLUS_PLUS)
          ? TokenType.PLUS.lexeme
          : TokenType.MINUS.lexeme;

  /**
   * Return the name of the method invoked by the given postfix [expression].
   */
  String _getPrefixOperator(PrefixExpression expression) {
    Token operator = expression.operator;
    TokenType operatorType = operator.type;
    if (operatorType == TokenType.PLUS_PLUS) {
      return TokenType.PLUS.lexeme;
    } else if (operatorType == TokenType.MINUS_MINUS) {
      return TokenType.MINUS.lexeme;
    } else if (operatorType == TokenType.MINUS) {
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
  DartType _getStaticType(Expression expression, {bool read: false}) {
    DartType staticType = _getStaticTypeOrFunctionType(expression, read: read);
    if (staticType is FunctionType) {
      //
      // All function types are subtypes of 'Function', which is itself a
      // subclass of 'Object'.
      //
      staticType = _resolver.typeProvider.functionType;
    }
    return staticType;
  }

  DartType _getStaticTypeOrFunctionType(Expression expression,
      {bool read: false}) {
    if (expression is NullLiteral) {
      return _resolver.typeProvider.nullType;
    }
    DartType type = read ? getReadType(expression) : expression.staticType;
    return _resolveTypeParameter(type);
  }

  /**
   * Return the newly created and replaced [InstanceCreationExpression], or
   * `null` if this is not an implicit constructor case.
   *
   * This method covers the "ClassName()" and "ClassName.namedConstructor()"
   * cases for the prefixed cases, i.e. "libraryPrefix.ClassName()" and
   * "libraryPrefix.ClassName.namedConstructor()" see
   * [_handlePrefixedImplicitConstructorCase].
   */
  InstanceCreationExpression _handleImplicitConstructorCase(
      MethodInvocation node, ClassElement classElement) {
    // If target == null, then this is the unnamed constructor, A(), case,
    // otherwise it is the named constructor A.name() case.
    Expression target = node.realTarget;
    bool isNamedConstructorCase = target != null;

    // If we are in the named constructor case, verify that the target is a
    // SimpleIdentifier and that the operator is '.'
    SimpleIdentifier targetSimpleId;
    if (isNamedConstructorCase) {
      if (target is SimpleIdentifier &&
          node.operator.type == TokenType.PERIOD) {
        targetSimpleId = target;
      } else {
        // Return null as this is not an implicit constructor case.
        return null;
      }
    }

    // Before any ASTs are created, look up ConstructorElement to see if we
    // should construct an [InstanceCreationExpression] to replace this
    // [MethodInvocation].
    InterfaceType classType = classElement.type;
    if (node.typeArguments != null) {
      int parameterCount = classType.typeParameters.length;
      int argumentCount = node.typeArguments.arguments.length;
      if (parameterCount == argumentCount) {
        // TODO(brianwilkerson) More gracefully handle the case where the counts
        // are different.
        List<DartType> typeArguments = node.typeArguments.arguments
            .map((TypeAnnotation type) => type.type)
            .toList();
        classType = classType.instantiate(typeArguments);
      }
    } else {
      int parameterCount = classType.typeParameters.length;
      if (parameterCount > 0) {
        List<DartType> typeArguments =
            new List<DartType>.filled(parameterCount, _dynamicType);
        classType = classType.instantiate(typeArguments);
      }
    }
    ConstructorElement constructorElt;
    if (isNamedConstructorCase) {
      constructorElt =
          classType.lookUpConstructor(node.methodName.name, _definingLibrary);
    } else {
      constructorElt = classType.lookUpConstructor(null, _definingLibrary);
    }
    // If the constructor was not looked up, return `null` so resulting
    // resolution, such as error messages, will proceed as a [MethodInvocation].
    if (constructorElt == null) {
      return null;
    }

    // Create the Constructor name, in each case: A[.named]()
    TypeName typeName;
    ConstructorName constructorName;
    if (isNamedConstructorCase) {
      // A.named()
      typeName = _astFactory.typeName(targetSimpleId, node.typeArguments);
      typeName.type = classType;
      constructorName =
          _astFactory.constructorName(typeName, node.operator, node.methodName);
    } else {
      // A()
      typeName = _astFactory.typeName(node.methodName, node.typeArguments);
      typeName.type = classType;
      constructorName = _astFactory.constructorName(typeName, null, null);
    }
    InstanceCreationExpression instanceCreationExpression = _astFactory
        .instanceCreationExpression(null, constructorName, node.argumentList);

    if (isNamedConstructorCase) {
      constructorName.name.staticElement = constructorElt;
    }
    constructorName.staticElement = constructorElt;
    instanceCreationExpression.staticElement = constructorElt;
    instanceCreationExpression.staticType = classType;

    // Finally, do the node replacement, true is returned iff the replacement
    // was successful, only return the new node if it was successful.
    if (NodeReplacer.replace(node, instanceCreationExpression)) {
      return instanceCreationExpression;
    }
    return null;
  }

  /**
   * Return the newly created and replaced [InstanceCreationExpression], or
   * `null` if this is not an implicit constructor case.
   *
   * This method covers the "libraryPrefix.ClassName()" and
   * "libraryPrefix.ClassName.namedConstructor()" cases for the non-prefixed
   * cases, i.e. "ClassName()" and "ClassName.namedConstructor()" see
   * [_handleImplicitConstructorCase].
   */
  InstanceCreationExpression _handlePrefixedImplicitConstructorCase(
      MethodInvocation node, Identifier libraryPrefixId) {
    bool isNamedConstructorCase = libraryPrefixId is PrefixedIdentifier;
    ClassElement classElement;
    if (isNamedConstructorCase) {
      var elt = (libraryPrefixId as PrefixedIdentifier).staticElement;
      if (elt is ClassElement) {
        classElement = elt;
      }
    } else {
      LibraryElementImpl libraryElementImpl = _getImportedLibrary(node.target);
      classElement = libraryElementImpl.getType(node.methodName.name);
    }

    // Before any ASTs are created, look up ConstructorElement to see if we
    // should construct an [InstanceCreationExpression] to replace this
    // [MethodInvocation].
    if (classElement == null) {
      return null;
    }
    InterfaceType classType = classElement.type;
    if (node.typeArguments != null) {
      int parameterCount = classType.typeParameters.length;
      int argumentCount = node.typeArguments.arguments.length;
      if (parameterCount == argumentCount) {
        // TODO(brianwilkerson) More gracefully handle the case where the counts
        // are different.
        List<DartType> typeArguments = node.typeArguments.arguments
            .map((TypeAnnotation type) => type.type)
            .toList();
        classType = classType.instantiate(typeArguments);
      }
    } else {
      int parameterCount = classType.typeParameters.length;
      if (parameterCount > 0) {
        List<DartType> typeArguments =
            new List<DartType>.filled(parameterCount, _dynamicType);
        classType = classType.instantiate(typeArguments);
      }
    }
    ConstructorElement constructorElt;
    if (isNamedConstructorCase) {
      constructorElt =
          classType.lookUpConstructor(node.methodName.name, _definingLibrary);
    } else {
      constructorElt = classType.lookUpConstructor(null, _definingLibrary);
    }
    // If the constructor was not looked up, return `null` so resulting
    // resolution, such as error messages, will proceed as a [MethodInvocation].
    if (constructorElt == null) {
      return null;
    }

    // Create the Constructor name, in each case: A[.named]()
    TypeName typeName;
    ConstructorName constructorName;
    if (isNamedConstructorCase) {
      // p.A.n()
      // libraryPrefixId is a PrefixedIdentifier in this case
      typeName = _astFactory.typeName(libraryPrefixId, node.typeArguments);
      typeName.type = classType;
      constructorName =
          _astFactory.constructorName(typeName, node.operator, node.methodName);
    } else {
      // p.A()
      // libraryPrefixId is a SimpleIdentifier in this case
      PrefixedIdentifier prefixedIdentifier = _astFactory.prefixedIdentifier(
          libraryPrefixId, node.operator, node.methodName);
      typeName = _astFactory.typeName(prefixedIdentifier, node.typeArguments);
      typeName.type = classType;
      constructorName = _astFactory.constructorName(typeName, null, null);
    }
    InstanceCreationExpression instanceCreationExpression = _astFactory
        .instanceCreationExpression(null, constructorName, node.argumentList);

    if (isNamedConstructorCase) {
      constructorName.name.staticElement = constructorElt;
    }
    constructorName.staticElement = constructorElt;
    instanceCreationExpression.staticElement = constructorElt;
    instanceCreationExpression.staticType = classType;

    // Finally, do the node replacement, true is returned iff the replacement
    // was successful, only return the new node if it was successful.
    if (NodeReplacer.replace(node, instanceCreationExpression)) {
      return instanceCreationExpression;
    }
    return null;
  }

  /**
   * Return `true` if the given [element] is or inherits from a class marked
   * with `@proxy`.
   *
   * See [ClassElement.isOrInheritsProxy].
   */
  bool _hasProxy(Element element) =>
      !_resolver.strongMode &&
      element is ClassElement &&
      element.isOrInheritsProxy;

  /**
   * Check for a generic method & apply type arguments if any were passed.
   */
  DartType _instantiateGenericMethod(
      DartType invokeType, TypeArgumentList typeArguments, AstNode node) {
    // TODO(jmesserly): support generic "call" methods on InterfaceType.
    if (invokeType is FunctionType) {
      List<TypeParameterElement> parameters = invokeType.typeFormals;

      NodeList<TypeAnnotation> arguments = typeArguments?.arguments;
      if (arguments != null && arguments.length != parameters.length) {
        if (_resolver.strongMode) {
          _resolver.errorReporter.reportErrorForNode(
              StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
              node,
              [invokeType, parameters.length, arguments?.length ?? 0]);
        } else {
          _resolver.errorReporter.reportErrorForNode(
              HintCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
              node,
              [invokeType, parameters.length, arguments?.length ?? 0]);
        }
        // Wrong number of type arguments. Ignore them.
        arguments = null;
      }
      if (parameters.isNotEmpty) {
        if (arguments == null) {
          return _resolver.typeSystem.instantiateToBounds(invokeType);
        } else {
          return invokeType.instantiate(arguments.map((n) => n.type).toList());
        }
      }
    }
    return invokeType;
  }

  /**
   * Return `true` if the given [expression] is a prefix for a deferred import.
   */
  bool _isDeferredPrefix(Expression expression) {
    if (expression is SimpleIdentifier) {
      Element element = expression.staticElement;
      if (element is PrefixElement) {
        List<ImportElement> imports =
            element.enclosingElement.getImportsWithPrefix(element);
        if (imports.length != 1) {
          return false;
        }
        return imports[0].isDeferred;
      }
    }
    return false;
  }

  /**
   * Return an error if the [type], which is presumably being invoked, is not a
   * function. The errors for non functions may be broken up by type; currently,
   * it returns a special value for when the type is `void`.
   */
  ErrorCode _getErrorCodeForExecuting(DartType type) {
    if (_isExecutableType(type)) {
      return null;
    }

    return type.isVoid
        ? StaticWarningCode.USE_OF_VOID_RESULT
        : StaticTypeWarningCode.INVOCATION_OF_NON_FUNCTION;
  }

  /**
   * Return `true` if the given [type] represents an object that could be
   * invoked using the call operator '()'.
   */
  bool _isExecutableType(DartType type) {
    type = type?.resolveToBound(_resolver.typeProvider.objectType);
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
      if (!_resolver.strongMode &&
          classElement.isProxy &&
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
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      LabelScope definingScope = labelScope.lookup(labelNode.name);
      if (definingScope == null) {
        // No definition of the given label name could be found in any
        // enclosing scope.
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      // The target has been found.
      labelNode.staticElement = definingScope.element;
      ExecutableElement labelContainer = definingScope.element
          .getAncestor((element) => element is ExecutableElement);
      if (!identical(labelContainer, _resolver.enclosingFunction)) {
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE,
            labelNode,
            [labelNode.name]);
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
      return type.lookUpInheritedGetter(getterName,
          library: _definingLibrary, thisType: target is! SuperExpression);
    }
    return null;
  }

  /**
   * Look up the method or getter with the given [memberName] in the given
   * [type]. Return the element representing the method or getter that was
   * found, or `null` if there is no method or getter with the given name.
   */
  ExecutableElement _lookupGetterOrMethod(DartType type, String memberName) {
    type = _resolveTypeParameter(type);
    if (type is InterfaceType) {
      return type.lookUpInheritedGetterOrMethod(memberName,
          library: _definingLibrary);
    }
    return null;
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
      return type.lookUpInheritedMethod(methodName,
          library: _definingLibrary, thisType: target is! SuperExpression);
    }
    return null;
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
      return type.lookUpInheritedSetter(setterName,
          library: _definingLibrary, thisType: target is! SuperExpression);
    }
    return null;
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
  TokenType _operatorFromCompoundAssignment(TokenType operator) {
    if (operator == TokenType.AMPERSAND_EQ) {
      return TokenType.AMPERSAND;
    } else if (operator == TokenType.BAR_EQ) {
      return TokenType.BAR;
    } else if (operator == TokenType.CARET_EQ) {
      return TokenType.CARET;
    } else if (operator == TokenType.GT_GT_EQ) {
      return TokenType.GT_GT;
    } else if (operator == TokenType.LT_LT_EQ) {
      return TokenType.LT_LT;
    } else if (operator == TokenType.MINUS_EQ) {
      return TokenType.MINUS;
    } else if (operator == TokenType.PERCENT_EQ) {
      return TokenType.PERCENT;
    } else if (operator == TokenType.PLUS_EQ) {
      return TokenType.PLUS;
    } else if (operator == TokenType.SLASH_EQ) {
      return TokenType.SLASH;
    } else if (operator == TokenType.STAR_EQ) {
      return TokenType.STAR;
    } else if (operator == TokenType.TILDE_SLASH_EQ) {
      return TokenType.TILDE_SLASH;
    } else {
      // Internal error: Unmapped assignment operator.
      AnalysisEngine.instance.logger.logError(
          "Failed to map ${operator.lexeme} to it's corresponding operator");
      return operator;
    }
  }

  /**
   * Determines if the [propagatedType] of the invoke is better (more specific)
   * than the [staticType]. If so it will be returned, otherwise returns null.
   */
  // TODO(jmesserly): can we refactor Resolver.recordPropagatedTypeIfBetter to
  // get some code sharing? Right now, this method is to support
  // `staticInvokeType` and `propagatedInvokeType`, and the one in Resolver is
  // for `staticType` and `propagatedType` on Expression.
  DartType _propagatedInvokeTypeIfBetter(
      DartType propagatedType, DartType staticType) {
    if (_resolver.strongMode || propagatedType == null) {
      return null;
    }
    if (staticType == null || propagatedType.isMoreSpecificThan(staticType)) {
      return propagatedType;
    }
    return null;
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
    if (!_hasProxy(declaringElement)) {
      _resolver.errorReporter.reportErrorForNode(errorCode, node, arguments);
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
    if (!_hasProxy(declaringElement)) {
      _resolver.errorReporter
          .reportErrorForOffset(errorCode, offset, length, arguments);
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
      Token token, List<Object> arguments) {
    if (!_hasProxy(declaringElement)) {
      _resolver.errorReporter.reportErrorForToken(errorCode, token, arguments);
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
        nameNode1 = annName.prefix;
        nameNode2 = annName.identifier;
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
        constructor = new InterfaceTypeImpl(element1)
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
        element2 = element1.lookUpGetter(nameNode2.name, _definingLibrary);
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
        constructor = new InterfaceTypeImpl(element1)
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
        String name3 = nameNode3.name;
        // prefix.Class.CONST
        PropertyAccessorElement getter =
            element2.lookUpGetter(name3, _definingLibrary);
        if (getter != null) {
          nameNode3.staticElement = getter;
          annotation.element = getter;
          _resolveAnnotationElementGetter(annotation, getter);
          return;
        }
        // prefix.Class.constructor(args)
        constructor = new InterfaceTypeImpl(element2)
            .lookUpConstructor(name3, _definingLibrary);
        nameNode3.staticElement = constructor;
      }
    }
    // we need constructor
    if (constructor == null) {
      _resolver.errorReporter.reportErrorForNode(
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
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      return;
    }
    // variable should be constant
    VariableElement variableElement = accessorElement.variable;
    if (!variableElement.isConst) {
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
    }
    // no arguments
    if (annotation.arguments != null) {
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS,
          annotation.name,
          [annotation.name]);
    }
    // OK
    return;
  }

  /**
   * Given an [argumentList] and the [executableElement] that will be invoked
   * using those argument, compute the list of parameters that correspond to the
   * list of arguments. An error will be reported if any of the arguments cannot
   * be matched to a parameter. The flag [reportAsError] should be `true` if a
   * compile-time error should be reported; or `false` if a compile-time warning
   * should be reported. Return the parameters that correspond to the arguments,
   * or `null` if no correspondence could be computed.
   */
  List<ParameterElement> _resolveArgumentsToFunction(bool reportAsError,
      ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return _resolveArgumentsToParameters(
        reportAsError, argumentList, parameters);
  }

  /**
   * Given an [argumentList] and the [parameters] related to the element that
   * will be invoked using those arguments, compute the list of parameters that
   * correspond to the list of arguments. An error will be reported if any of
   * the arguments cannot be matched to a parameter. The flag [reportAsError]
   * should be `true` if a compile-time error should be reported; or `false` if
   * a compile-time warning should be reported. Return the parameters that
   * correspond to the arguments.
   */
  List<ParameterElement> _resolveArgumentsToParameters(bool reportAsError,
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _resolver.errorReporter.reportErrorForNode,
        reportAsError: reportAsError);
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
        Element element = namespace.get(nameStr) ?? namespace.get("$nameStr=");
        if (element != null) {
          // Ensure that the name always resolves to a top-level variable
          // rather than a getter or setter
          if (element is PropertyAccessorElement) {
            name.staticElement = element.variable;
          } else {
            name.staticElement = element;
          }
        }
      }
    }
  }

  /**
   * Given that we are accessing a property of the given [classElement] with the
   * given [propertyName], return the element that represents the property.
   */
  Element _resolveElement(
      ClassElement classElement, SimpleIdentifier propertyName) {
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
   * whether the invocation uses a '?.' operator.
   */
  Element _resolveInvokedElementWithTarget(Expression target,
      DartType targetType, SimpleIdentifier methodName, bool isConditional) {
    String name = methodName.name;
    if (targetType is InterfaceType) {
      Element element = _lookUpMethod(target, targetType, name);
      if (element == null) {
        //
        // If there's no method, then it's possible that 'm' is a getter that
        // returns a function.
        //
        // TODO (collinsn): need to add union type support here too, in the
        // style of [lookUpMethod].
        element = _lookUpGetter(target, targetType, name);
      }
      return element;
    } else if (targetType is FunctionType &&
        _resolver.typeProvider.isObjectMethod(name)) {
      return _resolver.typeProvider.objectType.element.getMethod(name);
    } else if (target is SimpleIdentifier) {
      Element targetElement = target.staticElement;
      if (targetType is FunctionType &&
          name == FunctionElement.CALL_METHOD_NAME) {
        return targetElement;
      }
      if (targetElement is PrefixElement) {
        if (isConditional) {
          _resolver.errorReporter.reportErrorForNode(
              CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
              target,
              [target.name]);
        }
        //
        // Look to see whether the name of the method is really part of a
        // prefixed identifier for an imported top-level function or top-level
        // getter that returns a function.
        //
        Identifier functionName =
            new PrefixedIdentifierImpl.temp(target, methodName);
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
   * Given a [node] that can have annotations associated with it, resolve the
   * annotations in the element model representing annotations to the node.
   */
  void _resolveMetadataForParameter(NormalFormalParameter node) {
    _resolveAnnotations(node.metadata);
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
      Expression target, SimpleIdentifier propertyName, bool isCascaded) {
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
    ClassElement typeReference = getTypeReference(target);
    if (typeReference != null) {
      if (isCascaded) {
        typeReference = _typeType.element;
      }
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
      DartType displayType =
          staticOrPropagatedType ?? propagatedType ?? staticType;
      // Special getter cases.
      if (propertyName.inGetterContext()) {
        if (!isStaticProperty &&
            staticOrPropagatedEnclosingElt is ClassElement) {
          InterfaceType targetType = staticOrPropagatedEnclosingElt.type;
          if (!_enableStrictCallChecks &&
              targetType != null &&
              targetType.isDartCoreFunction &&
              propertyName.name == FunctionElement.CALL_METHOD_NAME) {
            // TODO(brianwilkerson) Can we ever resolve the function being
            // invoked?
//            resolveArgumentsToParameters(node.getArgumentList(), invokedFunction);
            return;
          } else if (staticOrPropagatedEnclosingElt.isEnum &&
              propertyName.name == "_name") {
            _resolver.errorReporter.reportErrorForNode(
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
        var arguments = [propertyName.name, displayType.displayName];
        if (shouldReportMissingMember_static) {
          if (target is SuperExpression) {
            if (isStaticProperty && !staticType.isVoid) {
              errorCode = StaticWarningCode.UNDEFINED_SUPER_SETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_SETTER;
            }
          } else {
            if (staticType.isVoid) {
              errorCode = StaticWarningCode.USE_OF_VOID_RESULT;
              arguments = [];
            } else if (isStaticProperty) {
              errorCode = StaticWarningCode.UNDEFINED_SETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_SETTER;
            }
          }
        } else {
          errorCode = HintCode.UNDEFINED_SETTER;
        }
        _recordUndefinedNode(
            declaringElement, errorCode, propertyName, arguments);
      } else if (propertyName.inGetterContext()) {
        ErrorCode errorCode;
        var arguments = [propertyName.name, displayType.displayName];
        if (shouldReportMissingMember_static) {
          if (target is SuperExpression) {
            if (isStaticProperty && !staticType.isVoid) {
              errorCode = StaticWarningCode.UNDEFINED_SUPER_GETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_GETTER;
            }
          } else {
            if (staticType.isVoid) {
              errorCode = StaticWarningCode.USE_OF_VOID_RESULT;
              arguments = [];
            } else if (isStaticProperty) {
              errorCode = StaticWarningCode.UNDEFINED_GETTER;
            } else {
              errorCode = StaticTypeWarningCode.UNDEFINED_GETTER;
            }
          }
        } else {
          errorCode = HintCode.UNDEFINED_GETTER;
        }
        _recordUndefinedNode(
            declaringElement, errorCode, propertyName, arguments);
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
      Identifier setterId =
          new SyntheticIdentifier('${identifier.name}=', identifier);
      element = _resolver.nameScope.lookup(setterId, _definingLibrary);
      identifier.setProperty(LibraryImportScope.conflictingSdkElements,
          setterId.getProperty(LibraryImportScope.conflictingSdkElements));
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
  DartType _resolveTypeParameter(DartType type) =>
      type?.resolveToBound(_resolver.typeProvider.objectType);

  /**
   * Return `true` if we should report an error as a result of looking up a
   * [member] in the given [type] and not finding any member.
   */
  bool _shouldReportMissingMember(DartType type, Element member) {
    return member == null &&
        type != null &&
        !type.isDynamic &&
        !type.isDartCoreNull;
  }

  /**
   * Checks whether the given [expression] is a reference to a class. If it is
   * then the element representing the class is returned, otherwise `null` is
   * returned.
   */
  static ClassElement getTypeReference(Expression expression) {
    if (expression is Identifier) {
      Element staticElement = expression.staticElement;
      if (staticElement is ClassElement) {
        return staticElement;
      }
    }
    return null;
  }

  /**
   * Given a [node] that can have annotations associated with it, resolve the
   * annotations in the element model representing the annotations on the node.
   */
  static void resolveMetadata(AnnotatedNode node) {
    _resolveAnnotations(node.metadata);
    if (node is VariableDeclaration) {
      AstNode parent = node.parent;
      if (parent is VariableDeclarationList) {
        _resolveAnnotations(parent.metadata);
        AstNode grandParent = parent.parent;
        if (grandParent is FieldDeclaration) {
          _resolveAnnotations(grandParent.metadata);
        } else if (grandParent is TopLevelVariableDeclaration) {
          _resolveAnnotations(grandParent.metadata);
        }
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
      return identical(parent.returnType, identifier) &&
          parent.factoryKeyword != null;
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
      } else if (node is ConstructorDeclaration) {
        return node.factoryKeyword == null;
      } else if (node is ConstructorFieldInitializer) {
        return false;
      } else if (node is MethodDeclaration) {
        return !node.isStatic;
      }
    }
    return false;
  }

  /**
   * Resolve each of the annotations in the given list of [annotations].
   */
  static void _resolveAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      ElementAnnotationImpl elementAnnotation = annotation.elementAnnotation;
      elementAnnotation.element = annotation.element;
    }
  }
}

/**
 * An identifier that can be used to look up names in the lexical scope when
 * there is no identifier in the AST structure. There is no identifier in the
 * AST when the parser could not distinguish between a method invocation and an
 * invocation of a top-level function imported with a prefix.
 */
class SyntheticIdentifier extends IdentifierImpl {
  /**
   * The name of the synthetic identifier.
   */
  @override
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
  Token get beginToken => null;

  @override
  Element get bestElement => null;

  @override
  Iterable<SyntacticEntity> get childEntities {
    // Should never be called, since a SyntheticIdentifier never appears in the
    // AST--it is just used for lookup.
    assert(false);
    return new ChildEntities();
  }

  @override
  Token get endToken => null;

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
  E accept<E>(AstVisitor<E> visitor) => null;

  @override
  void visitChildren(AstVisitor visitor) {}
}
