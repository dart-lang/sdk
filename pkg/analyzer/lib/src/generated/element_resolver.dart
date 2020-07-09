// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart'
    show PrefixedIdentifierImpl, SimpleIdentifierImpl;
import 'package:analyzer/src/dart/ast/token.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/inheritance_manager3.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/element/type_system.dart';
import 'package:analyzer/src/dart/resolver/extension_member_resolver.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/resolution_result.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/super_context.dart';
import 'package:analyzer/src/task/strong/checker.dart';
import 'package:meta/meta.dart';

/// An object used by instances of [ResolverVisitor] to resolve references
/// within the AST structure to the elements being referenced. The requirements
/// for the element resolver are:
///
/// 1. Every [SimpleIdentifier] should be resolved to the element to which it
///    refers. Specifically:
///    * An identifier within the declaration of that name should resolve to the
///      element being declared.
///    * An identifier denoting a prefix should resolve to the element
///      representing the import that defines the prefix (an [ImportElement]).
///    * An identifier denoting a variable should resolve to the element
///      representing the variable (a [VariableElement]).
///    * An identifier denoting a parameter should resolve to the element
///      representing the parameter (a [ParameterElement]).
///    * An identifier denoting a field should resolve to the element
///      representing the getter or setter being invoked (a
///      [PropertyAccessorElement]).
///    * An identifier denoting the name of a method or function being invoked
///      should resolve to the element representing the method or function (an
///      [ExecutableElement]).
///    * An identifier denoting a label should resolve to the element
///      representing the label (a [LabelElement]).
///    The identifiers within directives are exceptions to this rule and are
///    covered below.
/// 2. Every node containing a token representing an operator that can be
///    overridden ( [BinaryExpression], [PrefixExpression], [PostfixExpression])
///    should resolve to the element representing the method invoked by that
///    operator (a [MethodElement]).
/// 3. Every [FunctionExpressionInvocation] should resolve to the element
///    representing the function being invoked (a [FunctionElement]). This will
///    be the same element as that to which the name is resolved if the function
///    has a name, but is provided for those cases where an unnamed function is
///    being invoked.
/// 4. Every [LibraryDirective] and [PartOfDirective] should resolve to the
///    element representing the library being specified by the directive (a
///    [LibraryElement]) unless, in the case of a part-of directive, the
///    specified library does not exist.
/// 5. Every [ImportDirective] and [ExportDirective] should resolve to the
///    element representing the library being specified by the directive unless
///    the specified library does not exist (an [ImportElement] or
///    [ExportElement]).
/// 6. The identifier representing the prefix in an [ImportDirective] should
///    resolve to the element representing the prefix (a [PrefixElement]).
/// 7. The identifiers in the hide and show combinators in [ImportDirective]s
///    and [ExportDirective]s should resolve to the elements that are being
///    hidden or shown, respectively, unless those names are not defined in the
///    specified library (or the specified library does not exist).
/// 8. Every [PartDirective] should resolve to the element representing the
///    compilation unit being specified by the string unless the specified
///    compilation unit does not exist (a [CompilationUnitElement]).
///
/// Note that AST nodes that would represent elements that are not defined are
/// not resolved to anything. This includes such things as references to
/// undeclared variables (which is an error) and names in hide and show
/// combinators that are not defined in the imported library (which is not an
/// error).
class ElementResolver extends SimpleAstVisitor<void> {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElement _definingLibrary;

  /// The type representing the type 'dynamic'.
  DartType _dynamicType;

  /// The type representing the type 'Type'.
  InterfaceType _typeType;

  /// Whether constant evaluation errors should be reported during resolution.
  @Deprecated('This field is no longer used')
  final bool reportConstEvaluationErrors;

  /// Helper for extension method resolution.
  final ExtensionMemberResolver _extensionResolver;

  /// Helper for resolving properties on types.
  final TypePropertyResolver _typePropertyResolver;

  MethodInvocationResolver _methodInvocationResolver;

  /// Initialize a newly created visitor to work for the given [_resolver] to
  /// resolve the nodes in a compilation unit.
  ElementResolver(this._resolver,
      {this.reportConstEvaluationErrors = true,
      MigratableAstInfoProvider migratableAstInfoProvider =
          const MigratableAstInfoProvider()})
      : _definingLibrary = _resolver.definingLibrary,
        _extensionResolver = _resolver.extensionResolver,
        _typePropertyResolver = _resolver.typePropertyResolver {
    _dynamicType = _typeProvider.dynamicType;
    _typeType = _typeProvider.typeType;
    _methodInvocationResolver = MethodInvocationResolver(
      _resolver,
      migratableAstInfoProvider,
      inferenceHelper: _resolver.inferenceHelper,
    );
  }

  /// Return `true` iff the current enclosing function is a constant constructor
  /// declaration.
  bool get isInConstConstructor {
    ExecutableElement function = _resolver.enclosingFunction;
    if (function is ConstructorElement) {
      return function.isConst;
    }
    return false;
  }

  ErrorReporter get _errorReporter => _resolver.errorReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  TypeSystemImpl get _typeSystem => _resolver.typeSystem;

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
          AnalysisEngine.instance.instrumentationService
              .logError("Found element with null library: ${element.name}");
        } else if (library != _definingLibrary) {
          // TODO(brianwilkerson) Report this error.
        }
        if (node.newKeyword == null) {
          if (element is ClassElement) {
            name.staticElement = element.getMethod(name.name) ??
                element.getGetter(name.name) ??
                element.getSetter(name.name) ??
                element.getNamedConstructor(name.name);
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
        constructor = _resolver.toLegacyElement(constructor);
      } else {
        constructor = type.lookUpConstructor(name.name, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
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
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
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
    DartType targetType = _getStaticType(target);

    if (identical(targetType, NeverTypeImpl.instance)) {
      _resolver.errorReporter.reportErrorForNode(
        HintCode.RECEIVER_OF_TYPE_NEVER,
        target,
      );
      return;
    }

    if (node.isNullAware) {
      if (target is ExtensionOverride) {
        // https://github.com/dart-lang/language/pull/953
      } else {
        targetType = _typeSystem.promoteToNonNull(targetType);
      }
    }

    String getterMethodName = TokenType.INDEX.lexeme;
    String setterMethodName = TokenType.INDEX_EQ.lexeme;

    ResolutionResult result;
    if (target is ExtensionOverride) {
      result = _extensionResolver.getOverrideMember(target, getterMethodName);
    } else {
      result = _typePropertyResolver.resolve(
        receiver: target,
        receiverType: targetType,
        name: getterMethodName,
        receiverErrorNode: target,
        nameErrorNode: target,
      );
    }

    bool isInGetterContext = node.inGetterContext();
    bool isInSetterContext = node.inSetterContext();
    if (isInGetterContext && isInSetterContext) {
      node.staticElement = result.setter;
      node.auxiliaryElements = AuxiliaryElements(result.getter);
    } else if (isInGetterContext) {
      node.staticElement = result.getter;
    } else if (isInSetterContext) {
      node.staticElement = result.setter;
    }

    if (isInGetterContext) {
      _checkForUndefinedIndexOperator(
          node, target, getterMethodName, result, result.getter, targetType);
    }
    if (isInSetterContext) {
      _checkForUndefinedIndexOperator(
          node, target, setterMethodName, result, result.setter, targetType);
    }
  }

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    ConstructorElement invokedConstructor = node.constructorName.staticElement;
    ArgumentList argumentList = node.argumentList;
    List<ParameterElement> parameters =
        _resolveArgumentsToFunction(argumentList, invokedConstructor);
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
  void visitPrefixedIdentifier(PrefixedIdentifier node) {
    SimpleIdentifier prefix = node.prefix;
    SimpleIdentifier identifier = node.identifier;
    //
    // First, check the "lib.loadLibrary" case
    //
    if (identifier.name == FunctionElement.LOAD_LIBRARY_NAME &&
        _isDeferredPrefix(prefix)) {
      LibraryElement importedLibrary = _getImportedLibrary(prefix);
      var element = importedLibrary?.loadLibraryFunction;
      element = _resolver.toLegacyElement(element);
      identifier.staticElement = element;
      return;
    }
    //
    // Check to see whether the prefix is really a prefix.
    //
    Element prefixElement = prefix.staticElement;
    if (prefixElement is PrefixElement) {
      Element element = _resolver.nameScope.lookup(node, _definingLibrary);
      if (element == null && identifier.inSetterContext()) {
        Identifier setterName = PrefixedIdentifierImpl.temp(
            node.prefix,
            SimpleIdentifierImpl(StringToken(TokenType.STRING,
                "${node.identifier.name}=", node.identifier.offset - 1)));
        element = _resolver.nameScope.lookup(setterName, _definingLibrary);
      }
      element = _resolver.toLegacyElement(element);
      if (element == null && _resolver.nameScope.shouldIgnoreUndefined(node)) {
        return;
      }
      if (element == null) {
        AstNode parent = node.parent;
        if (parent is Annotation) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_ANNOTATION,
              parent,
              [identifier.name]);
        } else {
          _errorReporter.reportErrorForNode(
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
      return;
    }
    //
    // Otherwise, the prefix is really an expression that happens to be a simple
    // identifier and this is really equivalent to a property access node.
    //
    _resolvePropertyAccess(
      prefix,
      identifier,
      isCascaded: false,
      isNullAware: false,
    );
  }

  @override
  void visitPropertyAccess(PropertyAccess node) {
    Expression target = node.realTarget;
    if (target is SuperExpression &&
        SuperContext.of(target) != SuperContext.valid) {
      return;
    } else if (target is ExtensionOverride) {
      if (node.isCascaded) {
        // Report this error and recover by treating it like a non-cascade.
        _errorReporter.reportErrorForToken(
            CompileTimeErrorCode.EXTENSION_OVERRIDE_WITH_CASCADE,
            node.operator);
      }
      ExtensionElement element = target.extensionName.staticElement;
      SimpleIdentifier propertyName = node.propertyName;
      String memberName = propertyName.name;
      ExecutableElement member;
      var result = _extensionResolver.getOverrideMember(target, memberName);
      if (propertyName.inSetterContext()) {
        member = result.setter;
        if (member == null) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
              propertyName,
              [memberName, element.name]);
        }
        if (propertyName.inGetterContext()) {
          ExecutableElement getter = result.getter;
          if (getter == null) {
            _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
                propertyName,
                [memberName, element.name]);
          }
          propertyName.auxiliaryElements = AuxiliaryElements(getter);
        }
      } else if (propertyName.inGetterContext()) {
        member = result.getter;
        if (member == null) {
          _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
              propertyName,
              [memberName, element.name]);
        }
      }
      if (member != null && member.isStatic) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.EXTENSION_OVERRIDE_ACCESS_TO_STATIC_MEMBER,
            propertyName);
      }

      propertyName.staticElement = member;
      return;
    }
    SimpleIdentifier propertyName = node.propertyName;
    _resolvePropertyAccess(
      target,
      propertyName,
      isCascaded: node.isCascaded,
      isNullAware: node.isNullAware,
    );
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
        _resolveArgumentsToFunction(argumentList, element);
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
    // Otherwise, the node should be resolved.
    //
    Element element = _resolveSimpleIdentifier(node);
    ClassElement enclosingClass = _resolver.enclosingClass;
    if (_isFactoryConstructorReturnType(node) &&
        !identical(element, enclosingClass)) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_FACTORY_NAME_NOT_A_CLASS, node);
    } else if (_isConstructorReturnType(node) &&
        !identical(element, enclosingClass)) {
      // This error is now reported by the parser.
      element = null;
    } else if (element == null ||
        (element is PrefixElement && !_isValidAsPrefix(node))) {
      // TODO(brianwilkerson) Recover from this error.
      if (_isConstructorReturnType(node)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.INVALID_CONSTRUCTOR_NAME, node);
      } else if (parent is Annotation) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_ANNOTATION, parent, [node.name]);
      } else if (element != null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
            node,
            [element.name]);
      } else if (node.name == "await" && _resolver.enclosingFunction != null) {
        _errorReporter.reportErrorForNode(
          StaticWarningCode.UNDEFINED_IDENTIFIER_AWAIT,
          node,
        );
      } else if (!_resolver.nameScope.shouldIgnoreUndefined(node)) {
        _errorReporter.reportErrorForNode(
          StaticWarningCode.UNDEFINED_IDENTIFIER,
          node,
          [node.name],
        );
      }
    }
    node.staticElement = element;
    if (node.inSetterContext() &&
        node.inGetterContext() &&
        enclosingClass != null) {
      InterfaceType enclosingType = enclosingClass.thisType;
      var result = _typePropertyResolver.resolve(
        receiver: null,
        receiverType: enclosingType,
        name: node.name,
        receiverErrorNode: node,
        nameErrorNode: node,
      );
      node.auxiliaryElements = AuxiliaryElements(
        result.getter,
      );
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
    ClassElementImpl enclosingClass = _resolver.enclosingClass;
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
    element = _resolver.toLegacyElement(element);
    if (element == null || !element.isAccessibleIn(_definingLibrary)) {
      if (name != null) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER,
            node,
            [superType, name]);
      } else {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_CONSTRUCTOR_IN_INITIALIZER_DEFAULT,
            node,
            [superType]);
      }
      return;
    } else {
      if (element.isFactory) {
        _errorReporter.reportErrorForNode(
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
    List<ParameterElement> parameters =
        _resolveArgumentsToFunction(argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  @override
  void visitSuperExpression(SuperExpression node) {
    var context = SuperContext.of(node);
    if (context == SuperContext.static) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node);
    } else if (context == SuperContext.extension) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_EXTENSION, node);
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

  /// If the [element] is not static, report the error on the [identifier].
  void _checkForStaticAccessToInstanceMember(
    SimpleIdentifier identifier,
    ExecutableElement element,
  ) {
    if (element.isStatic) return;

    _errorReporter.reportErrorForNode(
      StaticWarningCode.STATIC_ACCESS_TO_INSTANCE_MEMBER,
      identifier,
      [identifier.name],
    );
  }

  /// Check that the given index [expression] was resolved, otherwise a
  /// [StaticTypeWarningCode.UNDEFINED_OPERATOR] is generated. The [target] is
  /// the target of the expression. The [methodName] is the name of the operator
  /// associated with the context of using of the given index expression.
  void _checkForUndefinedIndexOperator(
      IndexExpression expression,
      Expression target,
      String methodName,
      ResolutionResult result,
      ExecutableElement element,
      DartType staticType) {
    if (result.isAmbiguous) {
      return;
    }
    if (element != null) {
      return;
    }
    if (target is! ExtensionOverride) {
      if (staticType == null || staticType.isDynamic) {
        return;
      }
    }

    var leftBracket = expression.leftBracket;
    var rightBracket = expression.rightBracket;
    var offset = leftBracket.offset;
    var length = rightBracket.end - offset;
    if (target is ExtensionOverride) {
      _errorReporter.reportErrorForOffset(
        CompileTimeErrorCode.UNDEFINED_EXTENSION_OPERATOR,
        offset,
        length,
        [methodName, target.staticElement.name],
      );
    } else if (target is SuperExpression) {
      _errorReporter.reportErrorForOffset(
        StaticTypeWarningCode.UNDEFINED_SUPER_OPERATOR,
        offset,
        length,
        [methodName, staticType],
      );
    } else if (staticType.isVoid) {
      _errorReporter.reportErrorForOffset(
        StaticWarningCode.USE_OF_VOID_RESULT,
        offset,
        length,
      );
    } else if (identical(staticType, NeverTypeImpl.instance)) {
      _resolver.errorReporter.reportErrorForNode(
        HintCode.RECEIVER_OF_TYPE_NEVER,
        target,
      );
    } else {
      _errorReporter.reportErrorForOffset(
        StaticTypeWarningCode.UNDEFINED_OPERATOR,
        offset,
        length,
        [methodName, staticType],
      );
    }
  }

  /// Assuming that the given [identifier] is a prefix for a deferred import,
  /// return the library that is being imported.
  LibraryElement _getImportedLibrary(SimpleIdentifier identifier) {
    PrefixElement prefixElement = identifier.staticElement as PrefixElement;
    List<ImportElement> imports =
        prefixElement.enclosingElement.getImportsWithPrefix(prefixElement);
    return imports[0].importedLibrary;
  }

  /// Return the static type of the given [expression] that is to be used for
  /// type analysis.
  DartType _getStaticType(Expression expression, {bool read = false}) {
    if (expression is NullLiteral) {
      return _typeProvider.nullType;
    }
    DartType type = read ? getReadType(expression) : expression.staticType;
    return _resolveTypeParameter(type);
  }

  InterfaceType _instantiateAnnotationClass(ClassElement element) {
    return element.instantiate(
      typeArguments: List.filled(
        element.typeParameters.length,
        _dynamicType,
      ),
      nullabilitySuffix: _resolver.noneOrStarSuffix,
    );
  }

  /// Return `true` if the given [expression] is a prefix for a deferred import.
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

  /// Return `true` if the given [node] can validly be resolved to a prefix:
  /// * it is the prefix in an import directive, or
  /// * it is the prefix in a prefixed identifier.
  bool _isValidAsPrefix(SimpleIdentifier node) {
    AstNode parent = node.parent;
    if (parent is ImportDirective) {
      return identical(parent.prefix, node);
    } else if (parent is PrefixedIdentifier) {
      return true;
    } else if (parent is MethodInvocation) {
      return identical(parent.target, node) &&
          parent.operator?.type == TokenType.PERIOD;
    }
    return false;
  }

  /// Return the target of a break or continue statement, and update the static
  /// element of its label (if any). The [parentNode] is the AST node of the
  /// break or continue statement. The [labelNode] is the label contained in
  /// that statement (if any). The flag [isContinue] is `true` if the node being
  /// visited is a continue statement.
  AstNode _lookupBreakOrContinueTarget(
      AstNode parentNode, SimpleIdentifier labelNode, bool isContinue) {
    if (labelNode == null) {
      return _resolver.implicitLabelScope.getTarget(isContinue);
    } else {
      LabelScope labelScope = _resolver.labelScope;
      if (labelScope == null) {
        // There are no labels in scope, so by definition the label is
        // undefined.
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      LabelScope definingScope = labelScope.lookup(labelNode.name);
      if (definingScope == null) {
        // No definition of the given label name could be found in any
        // enclosing scope.
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_UNDEFINED, labelNode, [labelNode.name]);
        return null;
      }
      // The target has been found.
      labelNode.staticElement = definingScope.element;
      ExecutableElement labelContainer =
          definingScope.element.thisOrAncestorOfType();
      if (!identical(labelContainer, _resolver.enclosingFunction)) {
        _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.LABEL_IN_OUTER_SCOPE,
            labelNode,
            [labelNode.name]);
      }
      return definingScope.node;
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
        _resolveArgumentsToFunction(argumentList, constructor);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  /// Continues resolution of the given [annotation].
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
        constructor = _instantiateAnnotationClass(element1)
            .lookUpConstructor(null, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
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
        element2 = _resolver.toLegacyElement(element2);
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
        constructor = _resolver.toLegacyElement(constructor);
      }
      // Class.constructor(args)
      if (element1 is ClassElement) {
        constructor = _instantiateAnnotationClass(element1)
            .lookUpConstructor(nameNode2.name, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
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
          getter = _resolver.toLegacyElement(getter);
          nameNode3.staticElement = getter;
          annotation.element = getter;
          _resolveAnnotationElementGetter(annotation, getter);
          return;
        }
        // prefix.Class.constructor(args)
        constructor = _instantiateAnnotationClass(element2)
            .lookUpConstructor(name3, _definingLibrary);
        constructor = _resolver.toLegacyElement(constructor);
        nameNode3.staticElement = constructor;
      } else if (element2 == null) {
        undefined = true;
      }
    }
    // we need constructor
    if (constructor == null) {
      if (!undefined) {
        // If the class was not found then we've already reported the error.
        _errorReporter.reportErrorForNode(
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
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION_GETTER, annotation);
      return;
    }
    // variable should be constant
    VariableElement variableElement = accessorElement.variable;
    if (!variableElement.isConst) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.INVALID_ANNOTATION, annotation);
      return;
    }
    // no arguments
    if (annotation.arguments != null) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.ANNOTATION_WITH_NON_CLASS,
          annotation.name,
          [annotation.name]);
    }
    // OK
    return;
  }

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  List<ParameterElement> _resolveArgumentsToFunction(
      ArgumentList argumentList, ExecutableElement executableElement) {
    if (executableElement == null) {
      return null;
    }
    List<ParameterElement> parameters = executableElement.parameters;
    return _resolveArgumentsToParameters(argumentList, parameters);
  }

  /// Given an [argumentList] and the [parameters] related to the element that
  /// will be invoked using those arguments, compute the list of parameters that
  /// correspond to the list of arguments. An error will be reported if any of
  /// the arguments cannot be matched to a parameter. Return the parameters that
  /// correspond to the arguments.
  List<ParameterElement> _resolveArgumentsToParameters(
      ArgumentList argumentList, List<ParameterElement> parameters) {
    return ResolverVisitor.resolveArgumentsToParameters(
        argumentList, parameters, _errorReporter.reportErrorForNode);
  }

  /// Resolve the names in the given [combinators] in the scope of the given
  /// [library].
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
        NamespaceBuilder().createExportNamespaceForLibrary(library);
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

  /// Given a [node] that can have annotations associated with it, resolve the
  /// annotations in the element model representing annotations to the node.
  void _resolveMetadataForParameter(NormalFormalParameter node) {
    _resolveAnnotations(node.metadata);
  }

  void _resolvePropertyAccess(
    Expression target,
    SimpleIdentifier propertyName, {
    @required bool isCascaded,
    @required bool isNullAware,
  }) {
    DartType staticType = _getStaticType(target);

    //
    // If this property access is of the form 'E.m' where 'E' is an extension,
    // then look for the member in the extension. This does not apply to
    // conditional property accesses (i.e. 'C?.m').
    //
    if (target is Identifier && target.staticElement is ExtensionElement) {
      ExtensionElement extension = target.staticElement;
      String memberName = propertyName.name;

      if (propertyName.inGetterContext()) {
        ExecutableElement element;
        element ??= extension.getGetter(memberName);
        element ??= extension.getMethod(memberName);
        if (element != null) {
          element = _resolver.toLegacyElement(element);
          propertyName.staticElement = element;
          _checkForStaticAccessToInstanceMember(propertyName, element);
        } else {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_EXTENSION_GETTER,
            propertyName,
            [memberName, extension.name],
          );
        }
      }

      if (propertyName.inSetterContext()) {
        var element = extension.getSetter(memberName);
        if (element != null) {
          element = _resolver.toLegacyElement(element);
          propertyName.staticElement = element;
          _checkForStaticAccessToInstanceMember(propertyName, element);
        } else {
          _errorReporter.reportErrorForNode(
            CompileTimeErrorCode.UNDEFINED_EXTENSION_SETTER,
            propertyName,
            [memberName, extension.name],
          );
        }
      }

      return;
    }

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

      if (propertyName.inGetterContext()) {
        ExecutableElement element;

        if (element == null) {
          var getter = typeReference.getGetter(propertyName.name);
          if (getter != null && getter.isAccessibleIn(_definingLibrary)) {
            element = getter;
          }
        }

        if (element == null) {
          var method = typeReference.getMethod(propertyName.name);
          if (method != null && method.isAccessibleIn(_definingLibrary)) {
            element = method;
          }
        }

        if (element != null) {
          element = _resolver.toLegacyElement(element);
          propertyName.staticElement = element;
          _checkForStaticAccessToInstanceMember(propertyName, element);
        } else {
          var code = typeReference.isEnum
              ? StaticTypeWarningCode.UNDEFINED_ENUM_CONSTANT
              : StaticTypeWarningCode.UNDEFINED_GETTER;
          _errorReporter.reportErrorForNode(
            code,
            propertyName,
            [propertyName.name, typeReference.name],
          );
        }
      }

      if (propertyName.inSetterContext()) {
        ExecutableElement element;

        var setter = typeReference.getSetter(propertyName.name);
        if (setter != null) {
          element = setter;
          if (!setter.isAccessibleIn(_definingLibrary)) {
            _errorReporter.reportErrorForNode(
              CompileTimeErrorCode.PRIVATE_SETTER,
              propertyName,
              [propertyName.name, typeReference.name],
            );
          }
        }

        if (element != null) {
          element = _resolver.toLegacyElement(element);
          propertyName.staticElement = element;
          _checkForStaticAccessToInstanceMember(propertyName, element);
        } else {
          var getter = typeReference.getGetter(propertyName.name);
          if (getter != null) {
            propertyName.staticElement = getter;
            // The error will be reported in ErrorVerifier.
          } else {
            _errorReporter.reportErrorForNode(
              StaticTypeWarningCode.UNDEFINED_SETTER,
              propertyName,
              [propertyName.name, typeReference.name],
            );
          }
        }
      }

      return;
    }

    if (target is SuperExpression) {
      if (staticType is InterfaceTypeImpl) {
        if (propertyName.inGetterContext()) {
          var name = Name(_definingLibrary.source.uri, propertyName.name);
          var element = _resolver.inheritance
              .getMember2(staticType.element, name, forSuper: true);

          if (element != null) {
            element = _resolver.toLegacyElement(element);
            propertyName.staticElement = element;
          } else {
            // We were not able to find the concrete dispatch target.
            // But we would like to give the user at least some resolution.
            // So, we retry simply looking for an inherited member.
            var element =
                _resolver.inheritance.getInherited2(staticType.element, name);
            if (element != null) {
              propertyName.staticElement = element;
              _errorReporter.reportErrorForNode(
                CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
                propertyName,
                [element.kind.displayName, propertyName.name],
              );
            } else {
              _errorReporter.reportErrorForNode(
                StaticTypeWarningCode.UNDEFINED_SUPER_GETTER,
                propertyName,
                [propertyName.name, staticType],
              );
            }
          }
        }

        if (propertyName.inSetterContext()) {
          var element = staticType.lookUpSetter2(
            propertyName.name,
            _definingLibrary,
            concrete: true,
            inherited: true,
          );

          if (element != null) {
            element = _resolver.toLegacyElement(element);
            propertyName.staticElement = element;
          } else {
            // We were not able to find the concrete dispatch target.
            // But we would like to give the user at least some resolution.
            // So, we retry without the "concrete" requirement.
            var element = staticType.lookUpSetter2(
              propertyName.name,
              _definingLibrary,
              inherited: true,
            );
            if (element != null) {
              propertyName.staticElement = element;
              ClassElementImpl receiverSuperClass =
                  staticType.element.supertype.element;
              if (!receiverSuperClass.hasNoSuchMethod) {
                _errorReporter.reportErrorForNode(
                  CompileTimeErrorCode.ABSTRACT_SUPER_MEMBER_REFERENCE,
                  propertyName,
                  [element.kind.displayName, propertyName.name],
                );
              }
            } else {
              _errorReporter.reportErrorForNode(
                StaticTypeWarningCode.UNDEFINED_SUPER_SETTER,
                propertyName,
                [propertyName.name, staticType],
              );
            }
          }
        }
      }

      return;
    }

    if (staticType == null || staticType.isDynamic) {
      return;
    }

    if (isNullAware) {
      staticType = _typeSystem.promoteToNonNull(staticType);
    }

    if (staticType.isVoid) {
      _errorReporter.reportErrorForNode(
        StaticWarningCode.USE_OF_VOID_RESULT,
        propertyName,
      );
      return;
    }

    var result = _typePropertyResolver.resolve(
      receiver: target,
      receiverType: staticType,
      name: propertyName.name,
      receiverErrorNode: target,
      nameErrorNode: propertyName,
    );

    if (propertyName.inGetterContext()) {
      var shouldReportUndefinedGetter = false;
      if (result.isSingle) {
        var getter = result.getter;
        if (getter != null) {
          propertyName.staticElement = getter;
        } else {
          shouldReportUndefinedGetter = true;
        }
      } else if (result.isNone) {
        if (staticType is FunctionType &&
            propertyName.name == FunctionElement.CALL_METHOD_NAME) {
          // Referencing `.call` on a `Function` type is OK.
        } else if (staticType is InterfaceType &&
            staticType.isDartCoreFunction &&
            propertyName.name == FunctionElement.CALL_METHOD_NAME) {
          // Referencing `.call` on a `Function` type is OK.
        } else if (staticType is NeverTypeImpl) {
          shouldReportUndefinedGetter = false;
        } else {
          shouldReportUndefinedGetter = true;
        }
      }
      if (shouldReportUndefinedGetter) {
        _errorReporter.reportErrorForNode(
          StaticTypeWarningCode.UNDEFINED_GETTER,
          propertyName,
          [propertyName.name, staticType],
        );
      }
    }

    if (propertyName.inSetterContext()) {
      if (result.isSingle) {
        var setter = result.setter;
        if (setter != null) {
          propertyName.staticElement = setter;
          propertyName.auxiliaryElements = AuxiliaryElements(result.getter);
        } else {
          var getter = result.getter;
          propertyName.staticElement = getter;
          // A more specific error will be reported in ErrorVerifier.
        }
      } else if (result.isNone) {
        if (staticType is NeverTypeImpl) {
          // OK
        } else {
          _errorReporter.reportErrorForNode(
            StaticTypeWarningCode.UNDEFINED_SETTER,
            propertyName,
            [propertyName.name, staticType],
          );
        }
      }
    }
  }

  /// Resolve the given simple [identifier] if possible. Return the element to
  /// which it could be resolved, or `null` if it could not be resolved. This
  /// does not record the results of the resolution.
  Element _resolveSimpleIdentifier(SimpleIdentifier identifier) {
    Element element = _resolver.nameScope.lookup(identifier, _definingLibrary);
    element = _resolver.toLegacyElement(element);
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
            var result = _typePropertyResolver.resolve(
              receiver: null,
              receiverType: enclosingClass.thisType,
              name: identifier.name,
              receiverErrorNode: identifier,
              nameErrorNode: identifier,
            );
            setter = result.setter;
          }
        }
        if (setter != null) {
          element = setter;
        }
      }
    } else if (element == null &&
        (identifier.inSetterContext() ||
            identifier.parent is CommentReference)) {
      Identifier setterId = SyntheticIdentifier('${identifier.name}=');
      element = _resolver.nameScope.lookup(setterId, _definingLibrary);
      element = _resolver.toLegacyElement(element);
    }
    if (element == null) {
      InterfaceType enclosingType;
      ClassElement enclosingClass = _resolver.enclosingClass;
      if (enclosingClass == null) {
        var enclosingExtension = _resolver.enclosingExtension;
        if (enclosingExtension == null) {
          return null;
        }
        DartType extendedType =
            _resolveTypeParameter(enclosingExtension.extendedType);
        if (extendedType is InterfaceType) {
          enclosingType = extendedType;
        } else if (extendedType is FunctionType) {
          enclosingType = _typeProvider.functionType;
        } else {
          return null;
        }
      } else {
        enclosingType = enclosingClass.thisType;
      }
      if (element == null && enclosingType != null) {
        var result = _typePropertyResolver.resolve(
          receiver: null,
          receiverType: enclosingType,
          name: identifier.name,
          receiverErrorNode: identifier,
          nameErrorNode: identifier,
        );
        if (identifier.inSetterContext() ||
            identifier.parent is CommentReference) {
          element = result.setter;
        }
        element ??= result.getter;
      }
    }
    return element;
  }

  /// If the given [type] is a type parameter, resolve it to the type that
  /// should be used when looking up members. Otherwise, return the original
  /// type.
  DartType _resolveTypeParameter(DartType type) =>
      type?.resolveToBound(_typeProvider.objectType);

  /// Checks whether the given [expression] is a reference to a class. If it is
  /// then the element representing the class is returned, otherwise `null` is
  /// returned.
  static ClassElement getTypeReference(Expression expression) {
    if (expression is Identifier) {
      Element staticElement = expression.staticElement;
      if (staticElement is ClassElement) {
        return staticElement;
      }
    }
    return null;
  }

  /// Given a [node] that can have annotations associated with it, resolve the
  /// annotations in the element model representing the annotations on the node.
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

  /// Return `true` if the given [identifier] is the return type of a
  /// constructor declaration.
  static bool _isConstructorReturnType(SimpleIdentifier identifier) {
    AstNode parent = identifier.parent;
    if (parent is ConstructorDeclaration) {
      return identical(parent.returnType, identifier);
    }
    return false;
  }

  /// Return `true` if the given [identifier] is the return type of a factory
  /// constructor.
  static bool _isFactoryConstructorReturnType(SimpleIdentifier identifier) {
    AstNode parent = identifier.parent;
    if (parent is ConstructorDeclaration) {
      return identical(parent.returnType, identifier) &&
          parent.factoryKeyword != null;
    }
    return false;
  }

  /// Resolve each of the annotations in the given list of [annotations].
  static void _resolveAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      ElementAnnotationImpl elementAnnotation = annotation.elementAnnotation;
      elementAnnotation.element = annotation.element;
    }
  }
}

/// An identifier that can be used to look up names in the lexical scope when
/// there is no identifier in the AST structure. There is no identifier in the
/// AST when the parser could not distinguish between a method invocation and an
/// invocation of a top-level function imported with a prefix.
class SyntheticIdentifier implements SimpleIdentifier {
  @override
  final String name;

  SyntheticIdentifier(this.name);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
