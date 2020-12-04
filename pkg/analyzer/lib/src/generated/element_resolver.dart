// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/dart/resolver/type_property_resolver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/migratable_ast_info_provider.dart';
import 'package:analyzer/src/generated/resolver.dart';
import 'package:analyzer/src/generated/super_context.dart';

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

  /// Whether constant evaluation errors should be reported during resolution.
  @Deprecated('This field is no longer used')
  final bool reportConstEvaluationErrors;

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
        _typePropertyResolver = _resolver.typePropertyResolver {
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

  @override
  void visitBreakStatement(BreakStatement node) {
    node.target = _lookupBreakOrContinueTarget(node, node.label, false);
  }

  @override
  void visitClassDeclaration(ClassDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitClassTypeAlias(ClassTypeAlias node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitCommentReference(CommentReference node) {
    Identifier identifier = node.identifier;
    if (identifier is SimpleIdentifier) {
      Element element = _resolveSimpleIdentifier(identifier);
      if (element == null) {
        // TODO(brianwilkerson) Report this error?
        //        resolver.reportError(
        //            CompileTimeErrorCode.UNDEFINED_IDENTIFIER,
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
      Element prefixElement = _resolveSimpleIdentifier(prefix);
      prefix.staticElement = prefixElement;

      SimpleIdentifier name = identifier.identifier;

      if (prefixElement == null) {
//        resolver.reportError(CompileTimeErrorCode.UNDEFINED_IDENTIFIER, prefix, prefix.getName());
        return;
      }

      if (prefixElement is PrefixElement) {
        var prefixScope = prefixElement.scope;
        var lookupResult = prefixScope.lookup(name.name);
        var element = lookupResult.getter ?? lookupResult.setter;
        element = _resolver.toLegacyElement(element);
        name.staticElement = element;
        return;
      }

      LibraryElement library = prefixElement.library;
      if (library != _definingLibrary) {
        // TODO(brianwilkerson) Report this error.
      }

      if (node.newKeyword == null) {
        if (prefixElement is ClassElement) {
          name.staticElement = prefixElement.getMethod(name.name) ??
              prefixElement.getGetter(name.name) ??
              prefixElement.getSetter(name.name) ??
              prefixElement.getNamedConstructor(name.name);
        } else {
          // TODO(brianwilkerson) Report this error.
        }
      } else if (prefixElement is ClassElement) {
        var constructor = prefixElement.getNamedConstructor(name.name);
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
      _resolveAnnotations(node.metadata);
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
//          // CompileTimeErrorCode.NEW_WITH_NON_TYPE
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
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitEnumDeclaration(EnumDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitExportDirective(ExportDirective node) {
    ExportElement exportElement = node.element;
    if (exportElement != null) {
      // The element is null when the URI is invalid
      // TODO(brianwilkerson) Figure out whether the element can ever be
      // something other than an ExportElement
      _resolveCombinators(exportElement.exportedLibrary, node.combinators);
      _resolveAnnotations(node.metadata);
    }
  }

  @override
  void visitExtensionDeclaration(ExtensionDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitFieldDeclaration(FieldDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitFieldFormalParameter(FieldFormalParameter node) {
    _resolveMetadataForParameter(node);
    super.visitFieldFormalParameter(node);
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitFunctionTypeAlias(FunctionTypeAlias node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {
    _resolveMetadataForParameter(node);
  }

  @override
  void visitGenericTypeAlias(GenericTypeAlias node) {
    _resolveAnnotations(node.metadata);
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
      _resolveAnnotations(node.metadata);
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
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitMethodDeclaration(MethodDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitMethodInvocation(MethodInvocation node) {
    _methodInvocationResolver.resolve(node);
  }

  @override
  void visitMixinDeclaration(MixinDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitPartDirective(PartDirective node) {
    _resolveAnnotations(node.metadata);
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
  void visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var enclosingClass = _resolver.enclosingClass;
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
      if (element.isFactory &&
          // Check if we've reported [NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS].
          !element.enclosingElement.constructors
              .every((constructor) => constructor.isFactory)) {
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
    if (context == SuperContext.annotation || context == SuperContext.static) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT, node);
    } else if (context == SuperContext.extension) {
      _errorReporter.reportErrorForNode(
          CompileTimeErrorCode.SUPER_IN_EXTENSION, node);
    }
    super.visitSuperExpression(node);
  }

  @override
  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitTypeParameter(TypeParameter node) {
    _resolveAnnotations(node.metadata);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    _resolveAnnotations(node.metadata);
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

  /// Resolve the given simple [identifier] if possible. Return the element to
  /// which it could be resolved, or `null` if it could not be resolved. This
  /// does not record the results of the resolution.
  Element _resolveSimpleIdentifier(SimpleIdentifier identifier) {
    var lookupResult = _resolver.nameScope.lookup(identifier.name);

    Element element = lookupResult.getter;
    element = _resolver.toLegacyElement(element);

    if (element is PropertyAccessorElement && identifier.inSetterContext()) {
      var setter = lookupResult.setter;
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
            nameErrorEntity: identifier,
          );
          setter = result.setter;
        }
      }
      if (setter != null) {
        setter = _resolver.toLegacyElement(setter);
        element = setter;
      }
    } else if (element == null &&
        (identifier.inSetterContext() ||
            identifier.parent is CommentReference)) {
      element = lookupResult.setter;
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
          nameErrorEntity: identifier,
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

  /// Resolve each of the annotations in the given list of [annotations].
  static void _resolveAnnotations(NodeList<Annotation> annotations) {
    for (Annotation annotation in annotations) {
      var elementAnnotation =
          annotation.elementAnnotation as ElementAnnotationImpl;
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
