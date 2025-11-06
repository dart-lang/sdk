// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/error/listener.dart';
import 'package:analyzer/src/dart/ast/ast.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/element/type_provider.dart';
import 'package:analyzer/src/dart/resolver/comment_reference_resolver.dart';
import 'package:analyzer/src/dart/resolver/method_invocation_resolver.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/error/codes.dart';
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
///      representing the import that defines the prefix (an [LibraryImport]).
///    * An identifier denoting a variable should resolve to the element
///      representing the variable (a [VariableElement]).
///    * An identifier denoting a parameter should resolve to the element
///      representing the parameter (a [FormalParameterElement]).
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
///    representing the function being invoked (a [ExecutableElement]). This
///    will be the same element as that to which the name is resolved if the
///    function has a name, but is provided for those cases where an unnamed
///    function is being invoked.
/// 4. Every [LibraryDirective] and [PartOfDirective] should resolve to the
///    element representing the library being specified by the directive (a
///    [LibraryElement]) unless, in the case of a part-of directive, the
///    specified library does not exist.
/// 5. Every [ImportDirective] and [ExportDirective] should resolve to the
///    element representing the library being specified by the directive unless
///    the specified library does not exist (an [LibraryImport] or
///    [LibraryExport]).
/// 6. The identifier representing the prefix in an [ImportDirective] should
///    resolve to the element representing the prefix (a [PrefixElement]).
/// 7. The identifiers in the hide and show combinators in [ImportDirective]s
///    and [ExportDirective]s should resolve to the elements that are being
///    hidden or shown, respectively, unless those names are not defined in the
///    specified library (or the specified library does not exist).
/// 8. Every [PartDirective] should resolve to the element representing the
///    compilation unit being specified by the string unless the specified
///    compilation unit does not exist (a [LibraryFragment]).
///
/// Note that AST nodes that would represent elements that are not defined are
/// not resolved to anything. This includes such things as references to
/// undeclared variables (which is an error) and names in hide and show
/// combinators that are not defined in the imported library (which is not an
/// error).
class ElementResolver {
  /// The resolver driving this participant.
  final ResolverVisitor _resolver;

  /// The element for the library containing the compilation unit being visited.
  final LibraryElementImpl _definingLibrary;

  final MethodInvocationResolver _methodInvocationResolver;

  late final _commentReferenceResolver = CommentReferenceResolver(
    _typeProvider,
    _resolver,
  );

  /// Initialize a newly created visitor to work for the given [_resolver] to
  /// resolve the nodes in a compilation unit.
  ElementResolver(this._resolver)
    : _definingLibrary = _resolver.definingLibrary,
      _methodInvocationResolver = MethodInvocationResolver(
        _resolver,
        inferenceHelper: _resolver.inferenceHelper,
      );

  /// Return `true` iff the current enclosing function is a constant constructor
  /// declaration.
  bool get isInConstConstructor {
    var function = _resolver.enclosingFunction;
    if (function is ConstructorElementImpl) {
      return function.isConst;
    }
    return false;
  }

  DiagnosticReporter get _diagnosticReporter => _resolver.diagnosticReporter;

  TypeProviderImpl get _typeProvider => _resolver.typeProvider;

  void visitClassDeclaration(ClassDeclaration node) {}

  void visitClassTypeAlias(ClassTypeAlias node) {}

  void visitCommentReference(CommentReference node) {
    _commentReferenceResolver.resolve(node);
  }

  void visitConstructorDeclaration(ConstructorDeclarationImpl node) {
    var element = node.declaredFragment!.element;
    var redirectedNode = node.redirectedConstructor;
    if (redirectedNode != null) {
      // set redirected factory constructor
      var redirectedElement = redirectedNode.element;
      element.redirectedConstructor = redirectedElement;
    } else {
      // set redirected generative constructor
      for (ConstructorInitializer initializer in node.initializers) {
        if (initializer is RedirectingConstructorInvocationImpl) {
          var redirectedElement = initializer.element;
          element.redirectedConstructor = redirectedElement;
        }
      }
    }
  }

  void visitConstructorName(covariant ConstructorNameImpl node) {
    var type = node.type.type;
    if (type == null) {
      return;
    }
    if (type is DynamicType) {
      // Nothing to do.
    } else if (type is InterfaceTypeImpl) {
      // look up ConstructorElement
      InternalConstructorElement? constructor;
      var name = node.name;
      if (name == null) {
        constructor = type.lookUpConstructor(null, _definingLibrary);
      } else {
        constructor = type.lookUpConstructor(name.name, _definingLibrary);
        name.element = constructor;
      }
      node.element = constructor;
    }
  }

  void visitDeclaredIdentifier(DeclaredIdentifier node) {}

  void visitDotShorthandConstructorInvocation(
    covariant DotShorthandConstructorInvocationImpl node,
  ) {
    var invokedConstructor = node.element;
    var argumentList = node.argumentList;
    var parameters = _resolveArgumentsToFunction(
      argumentList,
      invokedConstructor,
    );
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  /// Resolves the dot shorthand invocation, [node].
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] or a
  /// [DotShorthandConstructorInvocation] in the process, then returns that new
  /// node. Otherwise, returns `null`.
  RewrittenMethodInvocationImpl? visitDotShorthandInvocation(
    covariant DotShorthandInvocationImpl node, {
    List<WhyNotPromotedGetter>? whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    whyNotPromotedArguments ??= [];
    return _methodInvocationResolver.resolveDotShorthand(
      node,
      whyNotPromotedArguments,
      contextType: contextType,
    );
  }

  void visitEnumConstantDeclaration(EnumConstantDeclaration node) {}

  void visitEnumDeclaration(EnumDeclaration node) {}

  void visitExportDirective(ExportDirectiveImpl node) {
    var exportElement = node.libraryExport;
    if (exportElement != null) {
      // The element is null when the URI is invalid
      // TODO(brianwilkerson): Figure out whether the element can ever be
      // something other than an ExportElement
      _resolveCombinators(exportElement.exportedLibrary, node.combinators);
    }
  }

  void visitExtensionDeclaration(ExtensionDeclaration node) {}

  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {}

  void visitFieldDeclaration(FieldDeclaration node) {}

  void visitFieldFormalParameter(FieldFormalParameter node) {}

  void visitFunctionDeclaration(FunctionDeclaration node) {}

  void visitFunctionTypeAlias(FunctionTypeAlias node) {}

  void visitFunctionTypedFormalParameter(FunctionTypedFormalParameter node) {}

  void visitGenericTypeAlias(GenericTypeAlias node) {}

  void visitImportDirective(covariant ImportDirectiveImpl node) {
    var prefixNode = node.prefix;
    if (prefixNode != null) {
      String prefixName = prefixNode.name;
      var prefixes = _resolver.libraryFragment.prefixes;
      int count = prefixes.length;
      for (int i = 0; i < count; i++) {
        var prefixElement = prefixes[i];
        if (prefixElement.displayName == prefixName) {
          prefixNode.element = prefixElement;
          break;
        }
      }
    }
    var importElement = node.libraryImport;
    if (importElement != null) {
      // The element is null when the URI is invalid
      var library = importElement.importedLibrary;
      if (library != null) {
        _resolveCombinators(library, node.combinators);
      }
    }
  }

  void visitInstanceCreationExpression(
    covariant InstanceCreationExpressionImpl node,
  ) {
    var invokedConstructor = node.constructorName.element;
    var argumentList = node.argumentList;
    var parameters = _resolveArgumentsToFunction(
      argumentList,
      invokedConstructor,
    );
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  void visitLibraryDirective(LibraryDirective node) {}

  void visitMethodDeclaration(MethodDeclaration node) {}

  /// Resolves the method invocation, [node].
  ///
  /// If [node] is rewritten to be a [FunctionExpressionInvocation] in the
  /// process, then returns that new node. Otherwise, returns `null`.
  FunctionExpressionInvocationImpl? visitMethodInvocation(
    MethodInvocation node, {
    List<WhyNotPromotedGetter>? whyNotPromotedArguments,
    required TypeImpl contextType,
  }) {
    whyNotPromotedArguments ??= [];
    return _methodInvocationResolver.resolve(
      node as MethodInvocationImpl,
      whyNotPromotedArguments,
      contextType: contextType,
    );
  }

  void visitMixinDeclaration(MixinDeclaration node) {}

  void visitPartDirective(PartDirective node) {}

  void visitPartOfDirective(PartOfDirective node) {}

  void visitRecordTypeAnnotationNamedField(
    RecordTypeAnnotationNamedField node,
  ) {}

  void visitRecordTypeAnnotationPositionalField(
    RecordTypeAnnotationPositionalField node,
  ) {}

  void visitRedirectingConstructorInvocation(
    covariant RedirectingConstructorInvocationImpl node,
  ) {
    var enclosingClass = _resolver.enclosingClass;
    if (enclosingClass is! InterfaceElementImpl) {
      // TODO(brianwilkerson): Report this error.
      return;
    }
    ConstructorElementImpl? element;
    var name = node.constructorName;
    if (name == null) {
      element = enclosingClass.unnamedConstructor;
    } else {
      element = enclosingClass.getNamedConstructor(name.name);
    }
    if (element == null) {
      // TODO(brianwilkerson): Report this error and decide what element to
      // associate with the node.
      return;
    }
    if (name != null) {
      name.element = element;
    }
    node.element = element;
    var argumentList = node.argumentList;
    var parameters = _resolveArgumentsToFunction(argumentList, element);
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  void visitRepresentationDeclaration(RepresentationDeclaration node) {}

  void visitSimpleFormalParameter(SimpleFormalParameter node) {}

  void visitSuperConstructorInvocation(
    covariant SuperConstructorInvocationImpl node,
  ) {
    var enclosingClass = _resolver.enclosingClass;
    if (enclosingClass is! InterfaceElementImpl) {
      // TODO(brianwilkerson): Report this error.
      return;
    }
    var superType = enclosingClass.supertype;
    if (superType == null) {
      // TODO(brianwilkerson): Report this error.
      return;
    }
    var name = node.constructorName;
    var superName = name?.name;
    var element = superType.lookUpConstructor(superName, _definingLibrary);
    if (element == null || !element.isAccessibleIn(_definingLibrary)) {
      if (name != null) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.undefinedConstructorInInitializer,
          arguments: [superType, name.name],
        );
      } else {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.undefinedConstructorInInitializerDefault,
          arguments: [superType],
        );
      }
      return;
    } else {
      if (element.isFactory &&
          // Check if we've reported [NO_GENERATIVE_CONSTRUCTORS_IN_SUPERCLASS].
          !element.enclosingElement.constructors.every(
            (constructor) => constructor.isFactory,
          )) {
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.nonGenerativeConstructor,
          arguments: [element],
        );
      }
    }
    if (name != null) {
      name.element = element;
    }
    node.element = element;
    // TODO(brianwilkerson): Defer this check until we know there's an error (by
    // in-lining _resolveArgumentsToFunction below).
    var declaration = node.thisOrAncestorOfType<ClassDeclaration>();
    var extendedNamedType = declaration?.extendsClause?.superclass;
    if (extendedNamedType != null &&
        _resolver.libraryFragment.shouldIgnoreUndefinedNamedType(
          extendedNamedType,
        )) {
      return;
    }
    var argumentList = node.argumentList;
    var parameters = _resolveArgumentsToFunction(
      argumentList,
      element,
      enclosingConstructor: node.thisOrAncestorOfType<ConstructorDeclaration>(),
    );
    if (parameters != null) {
      argumentList.correspondingStaticParameters = parameters;
    }
  }

  void visitSuperExpression(SuperExpression node) {
    var context = SuperContext.of(node);
    switch (context) {
      case SuperContext.annotation:
      case SuperContext.static:
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.superInInvalidContext,
        );
      case SuperContext.extension:
        _diagnosticReporter.atNode(node, CompileTimeErrorCode.superInExtension);
      case SuperContext.extensionType:
        _diagnosticReporter.atNode(
          node,
          CompileTimeErrorCode.superInExtensionType,
        );
    }
  }

  void visitTopLevelVariableDeclaration(TopLevelVariableDeclaration node) {}

  void visitTypeParameter(TypeParameter node) {}

  void visitVariableDeclarationList(VariableDeclarationList node) {}

  /// Given an [argumentList] and the [executableElement] that will be invoked
  /// using those argument, compute the list of parameters that correspond to
  /// the list of arguments. An error will be reported if any of the arguments
  /// cannot be matched to a parameter. Return the parameters that correspond to
  /// the arguments, or `null` if no correspondence could be computed.
  List<InternalFormalParameterElement?>? _resolveArgumentsToFunction(
    ArgumentList argumentList,
    ExecutableElement? executableElement, {
    ConstructorDeclaration? enclosingConstructor,
  }) {
    if (executableElement == null) {
      return null;
    }
    return ResolverVisitor.resolveArgumentsToParameters(
      argumentList: argumentList,
      formalParameters: executableElement.formalParameters,
      diagnosticReporter: _diagnosticReporter,
      enclosingConstructor: enclosingConstructor,
    );
  }

  /// Resolve the names in the given [combinators] in the scope of the given
  /// [library].
  void _resolveCombinators(
    LibraryElementImpl? library,
    NodeList<Combinator> combinators,
  ) {
    if (library == null) {
      //
      // The library will be null if the directive containing the combinators
      // has a URI that is not valid.
      //
      return;
    }
    Namespace namespace = library.exportNamespace;
    for (Combinator combinator in combinators) {
      NodeList<SimpleIdentifier> names;
      if (combinator is HideCombinator) {
        names = combinator.hiddenNames;
      } else {
        names = (combinator as ShowCombinator).shownNames;
      }
      for (var name in names) {
        name as SimpleIdentifierImpl;
        String nameStr = name.name;
        var element = namespace.get2(nameStr) ?? namespace.get2("$nameStr=");
        if (element != null) {
          // Ensure that the name always resolves to a top-level variable
          // rather than a getter or setter
          if (element is PropertyAccessorElement) {
            name.element = element.variable;
          } else {
            name.element = element;
          }
        }
      }
    }
  }
}
