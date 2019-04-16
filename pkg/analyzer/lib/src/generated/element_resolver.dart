// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/precedence.dart';
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
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager2.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
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
class ElementResolver extends SimpleAstVisitor<void> {
  /**
   * The manager for the inheritance mappings.
   */
  final InheritanceManager2 _inheritance;

  /**
   * The resolver driving this participant.
   */
  final ResolverVisitor _resolver;

  /**
   * The element for the library containing the compilation unit being visited.
   */
  final LibraryElement _definingLibrary;

  /**
   * The type representing the type 'dynamic'.
   */
  DartType _dynamicType;

  /**
   * The type representing the type 'Type'.
   */
  InterfaceType _typeType;

  /// Whether constant evaluation errors should be reported during resolution.
  final bool reportConstEvaluationErrors;

  final MethodInvocationResolver _methodInvocationResolver;

  /**
   * Initialize a newly created visitor to work for the given [_resolver] to
   * resolve the nodes in a compilation unit.
   */
  ElementResolver(this._resolver, {this.reportConstEvaluationErrors: true})
      : _inheritance = _resolver.inheritance,
        _definingLibrary = _resolver.definingLibrary,
        _methodInvocationResolver = new MethodInvocationResolver(_resolver) {
    _dynamicType = _resolver.typeProvider.dynamicType;
    _typeType = _resolver.typeProvider.typeType;
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
  void visitAssignmentExpression(AssignmentExpression node) {
    Token operator = node.operator;
    TokenType operatorType = operator.type;
    Expression leftHandSide = node.leftHandSide;
    DartType staticType = _getStaticType(leftHandSide, read: true);

    // For any compound assignments to a void or nullable variable, report it.
    // Example: `y += voidFn()`, not allowed.
    if (operatorType != TokenType.EQ) {
      if (staticType != null && staticType.isVoid) {
        _recordUndefinedToken(
            null, StaticWarningCode.USE_OF_VOID_RESULT, operator, []);
        return;
      }
    }

    if (operatorType != TokenType.AMPERSAND_AMPERSAND_EQ &&
        operatorType != TokenType.BAR_BAR_EQ &&
        operatorType != TokenType.EQ &&
        operatorType != TokenType.QUESTION_QUESTION_EQ) {
      operatorType = operatorFromCompoundAssignment(operatorType);
      if (leftHandSide != null) {
        String methodName = operatorType.lexeme;
        MethodElement staticMethod =
            _lookUpMethod(leftHandSide, staticType, methodName);
        node.staticElement = staticMethod;
        if (_shouldReportInvalidMember(staticType, staticMethod)) {
          _recordUndefinedToken(
              staticType.element,
              StaticTypeWarningCode.UNDEFINED_METHOD,
              operator,
              [methodName, staticType.displayName]);
        }
      }
    }
  }

  @override
  void visitBinaryExpression(BinaryExpression node) {
    Token operator = node.operator;
    if (operator.isUserDefinableOperator) {
      _resolveBinaryExpression(node, operator.lexeme);
    } else if (operator.type == TokenType.BANG_EQ) {
      _resolveBinaryExpression(node, TokenType.EQ_EQ.lexeme);
    }
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, false);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    resolveMetadata(node);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    resolveMetadata(node);
  }

  @override
  void visitCommentReference(CommentReference node) {
    Identifier identifier = node.identifier;
    if (identifier is SimpleIdentifier) {
      Element element = _resolveSimpleIdentifier(identifier);
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
          return;
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
  }

  @override
  void visitConstructorDeclaration(ConstructorDeclaration node) {
    super.visitConstructorDeclaration(node);
    ConstructorElement element = node.declaredElement;
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
  }

  @override
  void visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    SimpleIdentifier fieldName = node.fieldName;
    ClassElement enclosingClass = _resolver.enclosingClass;
    FieldElement fieldElement = enclosingClass.getField(fieldName.name);
    fieldName.staticElement = fieldElement;
  }

  @override
  void visitConstructorName(ConstructorName node) {
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
  }

  @override
  void visitContinueStatement(ContinueStatement node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, true);
  }

  @override
  void visitDeclaredIdentifier(DeclaredIdentifier node) {
    resolveMetadata(node);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    resolveMetadata(node);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid
      // TODO(brianwilkerson) Figure out whether the element can ever be
      // something other than an ExportElement
      _resolveCombinators(exportElement.exportedLibrary, node.combinators);
      resolveMetadata(node);
    }
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _resolveMetadataForParameter(node);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    resolveMetadata(node);
  }

  @override
  void visitFunctionExpressionInvocation(FunctionExpressionInvocation node) {
    Expression function = node.function;
    DartType staticInvokeType = _instantiateGenericMethod(
        function.staticType, node.typeArguments, node);

    node.staticInvokeType = staticInvokeType;

    List<ParameterElement> parameters =
        _computeCorrespondingParameters(node.argumentList, staticInvokeType);
    if (parameters != null) {
      node.argumentList.correspondingStaticParameters = parameters;
    }
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    resolveMetadata(node);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _resolveMetadataForParameter(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    resolveMetadata(node);
    return null;
  }

  @override
  void visitImportDirective(ImportDirective node) {
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
  }

  @override
  void visitIndexExpression(IndexExpression node) {
    Expression target = node.realTarget;
    DartType staticType = _getStaticType(target);
    String getterMethodName = TokenType.INDEX.lexeme;
    String setterMethodName = TokenType.INDEX_EQ.lexeme;
    bool isInGetterContext = node.inGetterContext();
    bool isInSetterContext = node.inSetterContext();
    if (isInGetterContext && isInSetterContext) {
      // lookup setter
      MethodElement setterStaticMethod =
          _lookUpMethod(target, staticType, setterMethodName);
      // set setter element
      node.staticElement = setterStaticMethod;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(
          node, target, setterMethodName, setterStaticMethod, staticType);
      // lookup getter method
      MethodElement getterStaticMethod =
          _lookUpMethod(target, staticType, getterMethodName);
      // set getter element
      AuxiliaryElements auxiliaryElements =
          new AuxiliaryElements(getterStaticMethod, null);
      node.auxiliaryElements = auxiliaryElements;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(
          node, target, getterMethodName, getterStaticMethod, staticType);
    } else if (isInGetterContext) {
      // lookup getter method
      MethodElement staticMethod =
          _lookUpMethod(target, staticType, getterMethodName);
      // set getter element
      node.staticElement = staticMethod;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(
          node, target, getterMethodName, staticMethod, staticType);
    } else if (isInSetterContext) {
      // lookup setter method
      MethodElement staticMethod =
          _lookUpMethod(target, staticType, setterMethodName);
      // set setter element
      node.staticElement = staticMethod;
      // generate undefined method warning
      _checkForUndefinedIndexOperator(
          node, target, setterMethodName, staticMethod, staticType);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement invokedConstructor = node.constructorName.staticElement;
    node.staticElement = invokedConstructor;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = _resolveArgumentsToFunction(
        reportConstEvaluationErrors && node.isConst,
        argumentList,
        invokedConstructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  @override
  void visitLibraryDirective(LibraryDirective node) {
    resolveMetadata(node);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    resolveMetadata(node);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _methodInvocationResolver.resolve(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    resolveMetadata(node);
  }

  @override
  void visitPartDirective(PartDirective node) {
    resolveMetadata(node);
  }

  @override
  void visitPostfixExpression(PostfixExpression node) {
    Expression operand = node.operand;
    if (node.operator.type == TokenType.BANG) {
      // Null-assertion operator (`!`).  There's nothing to do, since this is a
      // built-in operation (there's no associated operator declaration).
      return;
    }
    String methodName = _getPostfixOperator(node);
    DartType staticType = _getStaticType(operand);
    MethodElement staticMethod = _lookUpMethod(operand, staticType, methodName);
    node.staticElement = staticMethod;
    if (_shouldReportInvalidMember(staticType, staticMethod)) {
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
    }
  }

  @override
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    SimpleIdentifier identifier = node.identifier;
    //
    // First, check the "lib.loadLibrary" case
    //
    if (identifier.name == FunctionElement.LOAD_LIBRARY_NAME &&
        _isDeferredPrefix(prefix)) {
      LibraryElement importedLibrary = _getImportedLibrary(prefix);
      identifier.staticElement = importedLibrary?.loadLibraryFunction;
      return;
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
        return;
      }
      if (element == null) {
        AstNode parent = node.parent;
        if (parent is Annotation) {
          _resolver.errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_ANNOTATION,
              parent,
              [identifier.name]);
        } else {
          _resolver.errorReporter.reportErrorForNode(
              StaticTypeWarningCode.UNDEFINED_PREFIXED_NAME,
              identifier,
              [identifier.name, prefixElement.name]);
        }
        return;
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
      return;
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
  }

  @override
  void visitPrefixExpression(PrefixExpression node) {
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
      if (_shouldReportInvalidMember(staticType, staticMethod)) {
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
      }
    }
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    if (target is SuperExpression && !_isSuperInValidContext(target)) {
      return;
    }
    SimpleIdentifier propertyName = node.propertyName;
    _resolvePropertyAccess(target, propertyName, node.isCascaded);
  }

  @override
  void visitRedirectingConstructorInvocation(
      RedirectingConstructorInvocation node) {
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (enclosingClass == null) {
      // TODO(brianwilkerson) Report this error.
      return;
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
      return;
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
  }

  @override
  void visitSimpleFormalParameter(SimpleFormalParameter node) {
    _resolveMetadataForParameter(node);
  }

  @override
  void visitSimpleIdentifier(SimpleIdentifier node) {
    //
    // Synthetic identifiers have been already reported during parsing.
    //
    if (node.isSynthetic) {
      return;
    }
    //
    // Ignore nodes that should have been resolved before getting here.
    //
    if (node.inDeclarationContext()) {
      return;
    }
    if (node.staticElement is LocalVariableElement ||
        node.staticElement is ParameterElement) {
      return;
    }
    AstNode parent = node.parent;
    if (parent is FieldFormalParameter) {
      return;
    } else if (parent is ConstructorFieldInitializer &&
        parent.fieldName == node) {
      return;
    } else if (parent is Annotation && parent.constructorName == node) {
      return;
    }
    //
    // The name dynamic denotes a Type object even though dynamic is not a
    // class.
    //
    if (node.name == _dynamicType.name) {
      node.staticElement = _dynamicType.element;
      node.staticType = _typeType;
      return;
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
            CompileTimeErrorCode.UNDEFINED_ANNOTATION, parent, [node.name]);
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
  }

  @override
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    ClassElementImpl enclosingClass =
        AbstractClassElementImpl.getImpl(_resolver.enclosingClass);
    if (enclosingClass == null) {
      // TODO(brianwilkerson) Report this error.
      return;
    }
    InterfaceType superType = enclosingClass.supertype;
    if (superType == null) {
      // TODO(brianwilkerson) Report this error.
      return;
    }
    SimpleIdentifier name = node.constructorName;
    String superName = name?.name;
    ConstructorElement element =
        superType.lookUpConstructor(superName, _definingLibrary);
    if (element == null || !element.isAccessibleIn(_definingLibrary)) {
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
      return;
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
        node.thisOrAncestorOfType<ClassDeclaration>();
    Identifier superclassName = declaration?.extendsClause?.superclass?.name;
    if (superclassName != null &&
        _resolver.nameScope.shouldIgnoreUndefined(superclassName)) {
      return;
    }
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters = _resolveArgumentsToFunction(
        isInConstConstructor, argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    if (!_isSuperInValidContext(node)) {
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node);
    }
    super.visitSuperExpression(node);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    resolveMetadata(node);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    resolveMetadata(node);
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
      DartType staticType) {
    if (_shouldReportInvalidMember(staticType, staticMethod)) {
      Token leftBracket = expression.leftBracket;
      Token rightBracket = expression.rightBracket;
      ErrorCode errorCode;
      var errorArguments = [methodName, staticType.displayName];
      if (target is SuperExpression) {
        errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR;
      } else if (staticType != null && staticType.isVoid) {
        errorCode = StaticWarningCode.USE_OF_VOID_RESULT;
        errorArguments = [];
      } else {
        errorCode = StaticTypeWarningCode.UNDEFINED_OPERATOR;
      }
      if (leftBracket == null || rightBracket == null) {
        _recordUndefinedNode(
            staticType.element, errorCode, expression, errorArguments);
      } else {
        int offset = leftBracket.offset;
        int length = rightBracket.offset - offset + 1;
        _recordUndefinedOffset(
            staticType.element, errorCode, offset, length, errorArguments);
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
   * Return the name of the method invoked by the given postfix [expression].
   */
  String _getPostfixOperator(PostfixExpression expression) {
    if (expression.operator.type == TokenType.PLUS_PLUS) {
      return TokenType.PLUS.lexeme;
    } else if (expression.operator.type == TokenType.MINUS_MINUS) {
      return TokenType.MINUS.lexeme;
    } else {
      throw new UnsupportedError(
          'Unsupported postfix operator ${expression.operator.lexeme}');
    }
  }

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
   * Check for a generic method & apply type arguments if any were passed.
   */
  DartType _instantiateGenericMethod(
      DartType invokeType, TypeArgumentList typeArguments, AstNode node) {
    DartType parameterizableType;
    List<TypeParameterElement> parameters;
    if (invokeType is FunctionType) {
      parameterizableType = invokeType;
      parameters = invokeType.typeFormals;
    } else if (invokeType is InterfaceType) {
      MethodElement callMethod = invokeType.lookUpMethod(
          FunctionElement.CALL_METHOD_NAME, _resolver.definingLibrary);
      parameterizableType = callMethod?.type;
      parameters = (parameterizableType as FunctionType)?.typeFormals;
    }

    if (parameterizableType is ParameterizedType) {
      NodeList<TypeAnnotation> arguments = typeArguments?.arguments;
      if (arguments != null && arguments.length != parameters.length) {
        _resolver.errorReporter.reportErrorForNode(
            StaticTypeWarningCode.WRONG_NUMBER_OF_TYPE_ARGUMENTS_METHOD,
            node,
            [parameterizableType, parameters.length, arguments?.length ?? 0]);
        // Wrong number of type arguments. Ignore them.
        arguments = null;
      }
      if (parameters.isNotEmpty) {
        if (arguments == null) {
          return _resolver.typeSystem.instantiateToBounds(parameterizableType);
        } else {
          return parameterizableType
              .instantiate(arguments.map((n) => n.type).toList());
        }
      }

      return parameterizableType;
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
   * Look up the [FunctionType] of a getter or a method with the given [name]
   * in the given [targetType].
   */
  FunctionType _lookUpGetterType(DartType targetType, String name,
      {bool concrete: false, bool forSuper: false}) {
    targetType = _resolveTypeParameter(targetType);
    if (targetType is InterfaceType) {
      var nameObject = new Name(_definingLibrary.source.uri, name);
      return _inheritance.getMember(
        targetType,
        nameObject,
        concrete: concrete,
        forSuper: forSuper,
      );
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
   * Record that the given [node] is undefined, causing an error to be reported
   * if appropriate. The [declaringElement] is the element inside which no
   * declaration was found. If this element is a proxy, no error will be
   * reported. If null, then an error will always be reported. The [errorCode]
   * is the error code to report. The [arguments] are the arguments to the error
   * message.
   */
  void _recordUndefinedNode(Element declaringElement, ErrorCode errorCode,
      AstNode node, List<Object> arguments) {
    _resolver.errorReporter.reportErrorForNode(errorCode, node, arguments);
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
    _resolver.errorReporter
        .reportErrorForOffset(errorCode, offset, length, arguments);
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
    _resolver.errorReporter.reportErrorForToken(errorCode, token, arguments);
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
    ConstructorElement constructor;
    bool undefined = false;
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
        constructor = element1.type.lookUpConstructor(null, _definingLibrary);
      } else if (element1 == null) {
        undefined = true;
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
        constructor =
            element1.type.lookUpConstructor(nameNode2.name, _definingLibrary);
        nameNode2.staticElement = constructor;
      }
      if (element1 == null && element2 == null) {
        undefined = true;
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
        constructor = element2.type.lookUpConstructor(name3, _definingLibrary);
        nameNode3.staticElement = constructor;
      } else if (element2 == null) {
        undefined = true;
      }
    }
    // we need constructor
    if (constructor == null) {
      if (!undefined) {
        // If the class was not found then we've already reported the error.
        _resolver.errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      }
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
          CompileTimeErrorCode.INVALID_ANNOTATION_GETTER, annotation);
      return;
    }
    // variable should be constant
    VariableElement variableElement = accessorElement.variable;
    if (!variableElement.isConst) {
      _resolver.errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      return;
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
      DartType leftType = _getStaticType(leftOperand);
      var isSuper = leftOperand is SuperExpression;
      var invokeType = _lookUpGetterType(leftType, methodName,
          concrete: isSuper, forSuper: isSuper);
      var invokeElement = invokeType?.element;
      node.staticElement = invokeElement;
      node.staticInvokeType = invokeType;
      if (_shouldReportInvalidMember(leftType, invokeElement)) {
        if (isSuper) {
          _recordUndefinedToken(
              leftType.element,
              StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
              node.operator,
              [methodName, leftType.displayName]);
        } else {
          _recordUndefinedToken(
              leftType.element,
              StaticTypeWarningCode.UNDEFINED_OPERATOR,
              node.operator,
              [methodName, leftType.displayName]);
        }
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
    Element staticElement = null;
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
      staticElement = _resolveElement(typeReference, propertyName);
    } else {
      if (target is SuperExpression) {
        if (staticType is InterfaceTypeImpl) {
          staticElement = staticType.lookUpInheritedMember(
              propertyName.name, _definingLibrary,
              setter: propertyName.inSetterContext(),
              concrete: true,
              forSuperInvocation: true);
          // We were not able to find the concrete dispatch target.
          // But we would like to give the user at least some resolution.
          // So, we retry without the "concrete" requirement.
          if (staticElement == null) {
            staticElement = staticType.lookUpInheritedMember(
                propertyName.name, _definingLibrary,
                setter: propertyName.inSetterContext(), concrete: false);
            if (staticElement != null) {
              ClassElementImpl receiverSuperClass =
                  AbstractClassElementImpl.getImpl(
                staticType.element.supertype.element,
              );
              if (!receiverSuperClass.hasNoSuchMethod) {
                _resolver.errorReporter.reportErrorForNode(
                    CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
                    propertyName,
                    [staticElement.kind.displayName, propertyName.name]);
              }
            }
          }
        }
      } else {
        staticElement = _resolveProperty(target, staticType, propertyName);
      }
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
    if (_shouldReportInvalidMember(staticType, staticElement)) {
      Element staticOrPropagatedEnclosingElt = staticType.element;
      bool isStaticProperty = _isStatic(staticOrPropagatedEnclosingElt);
      // Special getter cases.
      if (propertyName.inGetterContext()) {
        if (!isStaticProperty &&
            staticOrPropagatedEnclosingElt is ClassElement) {
          InterfaceType targetType = staticOrPropagatedEnclosingElt.type;
          if (targetType != null &&
              targetType.isDartCoreFunction &&
              propertyName.name == FunctionElement.CALL_METHOD_NAME) {
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
        var arguments = [propertyName.name, staticType.displayName];
        if (target is SuperExpression) {
          errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_SETTER;
        } else {
          if (staticType.isVoid) {
            errorCode = StaticWarningCode.USE_OF_VOID_RESULT;
            arguments = [];
          } else {
            errorCode = StaticTypeWarningCode.UNDEFINED_SETTER;
          }
        }
        _recordUndefinedNode(
            declaringElement, errorCode, propertyName, arguments);
      } else if (propertyName.inGetterContext()) {
        ErrorCode errorCode;
        var arguments = [propertyName.name, staticType.displayName];
        if (target is SuperExpression) {
          errorCode = StaticTypeWarningCode.UNDEFINED_SUPER_GETTER;
        } else {
          if (staticType.isVoid) {
            errorCode = StaticWarningCode.USE_OF_VOID_RESULT;
            arguments = [];
          } else {
            errorCode = StaticTypeWarningCode.UNDEFINED_GETTER;
          }
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
   * Return `true` if we should report an error for a [member] lookup that found
   * no match on the given [type], or accessing a [member] on a nullable type.
   */
  bool _shouldReportInvalidMember(DartType type, Element member) {
    return type != null &&
        member == null &&
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
  Precedence get precedence => Precedence.primary;

  @deprecated
  @override
  Element get propagatedElement => null;

  @override
  Element get staticElement => null;

  @override
  E accept<E>(AstVisitor<E> visitor) => null;

  @override
  void visitChildren(AstVisitor visitor) {}
}
