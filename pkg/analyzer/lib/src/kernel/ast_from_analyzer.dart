// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.analyzer.ast_from_analyzer;

import 'package:kernel/ast.dart' as ast;
import 'package:kernel/frontend/super_initializers.dart';
import 'package:kernel/log.dart';
import 'package:kernel/type_algebra.dart';
import 'package:kernel/transformations/flags.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/kernel/loader.dart';
import 'package:analyzer/analyzer.dart';
import 'package:analyzer/dart/ast/standard_resolution_map.dart';
import 'package:analyzer/src/generated/parser.dart';
import 'package:analyzer/src/dart/element/member.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:kernel/frontend/accessors.dart';

/// Provides reference-level access to libraries, classes, and members.
///
/// "Reference level" objects are incomplete nodes that have no children but
/// can be used for linking until the loader promotes the node to a higher
/// loading level.
///
/// The [ReferenceScope] is the most restrictive scope in a hierarchy of scopes
/// that provide increasing amounts of contextual information.  [TypeScope] is
/// used when type parameters might be in scope, and [MemberScope] is used when
/// building the body of a [ast.Member].
class ReferenceScope {
  final ReferenceLevelLoader loader;

  ReferenceScope(this.loader);

  bool get strongMode => loader.strongMode;

  ast.Library getLibraryReference(LibraryElement element) {
    if (element == null) return null;
    return loader.getLibraryReference(getBaseElement(element));
  }

  ast.Class getRootClassReference() {
    return loader.getRootClassReference();
  }

  ast.Class getClassReference(ClassElement element) {
    return loader.getClassReference(getBaseElement(element));
  }

  ast.Member getMemberReference(Element element) {
    return loader.getMemberReference(getBaseElement(element));
  }

  static Element getBaseElement(Element element) {
    while (element is Member) {
      element = (element as Member).baseElement;
    }
    return element;
  }

  static bool supportsConcreteGet(Element element) {
    return (element is PropertyAccessorElement &&
            element.isGetter &&
            !element.isAbstract) ||
        element is FieldElement ||
        element is TopLevelVariableElement ||
        element is MethodElement && !element.isAbstract ||
        isTopLevelFunction(element);
  }

  static bool supportsInterfaceGet(Element element) {
    return (element is PropertyAccessorElement && element.isGetter) ||
        element is FieldElement ||
        element is MethodElement;
  }

  static bool supportsConcreteSet(Element element) {
    return (element is PropertyAccessorElement &&
            element.isSetter &&
            !element.isAbstract) ||
        element is FieldElement && !element.isFinal && !element.isConst ||
        element is TopLevelVariableElement &&
            !element.isFinal &&
            !element.isConst;
  }

  static bool supportsInterfaceSet(Element element) {
    return (element is PropertyAccessorElement && element.isSetter) ||
        element is FieldElement && !element.isFinal && !element.isConst;
  }

  static bool supportsConcreteIndexGet(Element element) {
    return element is MethodElement &&
        element.name == '[]' &&
        !element.isAbstract;
  }

  static bool supportsInterfaceIndexGet(Element element) {
    return element is MethodElement && element.name == '[]';
  }

  static bool supportsConcreteIndexSet(Element element) {
    return element is MethodElement &&
        element.name == '[]=' &&
        !element.isAbstract;
  }

  static bool supportsInterfaceIndexSet(Element element) {
    return element is MethodElement && element.name == '[]=';
  }

  static bool supportsConcreteMethodCall(Element element) {
    // Note that local functions are not valid targets for method calls because
    // they are not "methods" or even "procedures" in our AST.
    return element is MethodElement && !element.isAbstract ||
        isTopLevelFunction(element) ||
        element is ConstructorElement && element.isFactory;
  }

  static bool supportsInterfaceMethodCall(Element element) {
    return element is MethodElement;
  }

  static bool supportsConstructorCall(Element element) {
    return element is ConstructorElement && !element.isFactory;
  }

  ast.Member _resolveGet(
      Element element, Element auxiliary, bool predicate(Element element)) {
    element = desynthesizeGetter(element);
    if (predicate(element)) return getMemberReference(element);
    if (element is PropertyAccessorElement && element.isSetter) {
      // The getter is sometimes stored as the 'corresponding getter' instead
      // of the 'auxiliary' element.
      auxiliary ??= element.correspondingGetter;
    }
    auxiliary = desynthesizeGetter(auxiliary);
    if (predicate(auxiliary)) return getMemberReference(auxiliary);
    return null;
  }

  ast.Member resolveConcreteGet(Element element, Element auxiliary) {
    return _resolveGet(element, auxiliary, supportsConcreteGet);
  }

  ast.Member resolveInterfaceGet(Element element, Element auxiliary) {
    if (!strongMode) return null;
    return _resolveGet(element, auxiliary, supportsInterfaceGet);
  }

  DartType getterTypeOfElement(Element element) {
    if (element is VariableElement) {
      return element.type;
    } else if (element is PropertyAccessorElement && element.isGetter) {
      return element.returnType;
    } else {
      return null;
    }
  }

  /// Returns the interface target of a `call` dispatch to the given member.
  ///
  /// For example, if the member is a field of type C, the target will be the
  /// `call` method of class C, if it has such a method.
  ///
  /// If the class C has a getter or field named `call`, this method returns
  /// `null` - the static type system does support typed calls with indirection.
  ast.Member resolveInterfaceFunctionCall(Element element) {
    if (!strongMode || element == null) return null;
    return resolveInterfaceFunctionCallOnType(getterTypeOfElement(element));
  }

  /// Returns the `call` method of [callee], if it has one, otherwise `null`.
  ast.Member resolveInterfaceFunctionCallOnType(DartType callee) {
    return callee is InterfaceType
        ? resolveInterfaceMethod(callee.getMethod('call'))
        : null;
  }

  ast.Member _resolveSet(
      Element element, Element auxiliary, bool predicate(Element element)) {
    element = desynthesizeSetter(element);
    if (predicate(element)) {
      return getMemberReference(element);
    }
    if (element is PropertyAccessorElement && element.isSetter) {
      // The setter is sometimes stored as the 'corresponding setter' instead
      // of the 'auxiliary' element.
      auxiliary ??= element.correspondingGetter;
    }
    auxiliary = desynthesizeSetter(auxiliary);
    if (predicate(auxiliary)) {
      return getMemberReference(auxiliary);
    }
    return null;
  }

  ast.Member resolveConcreteSet(Element element, Element auxiliary) {
    return _resolveSet(element, auxiliary, supportsConcreteSet);
  }

  ast.Member resolveInterfaceSet(Element element, Element auxiliary) {
    if (!strongMode) return null;
    return _resolveSet(element, auxiliary, supportsInterfaceSet);
  }

  ast.Member resolveConcreteIndexGet(Element element, Element auxiliary) {
    if (supportsConcreteIndexGet(element)) {
      return getMemberReference(element);
    }
    if (supportsConcreteIndexGet(auxiliary)) {
      return getMemberReference(auxiliary);
    }
    return null;
  }

  ast.Member resolveInterfaceIndexGet(Element element, Element auxiliary) {
    if (!strongMode) return null;
    if (supportsInterfaceIndexGet(element)) {
      return getMemberReference(element);
    }
    if (supportsInterfaceIndexGet(auxiliary)) {
      return getMemberReference(auxiliary);
    }
    return null;
  }

  ast.Member resolveConcreteIndexSet(Element element, Element auxiliary) {
    if (supportsConcreteIndexSet(element)) {
      return getMemberReference(element);
    }
    if (supportsConcreteIndexSet(auxiliary)) {
      return getMemberReference(auxiliary);
    }
    return null;
  }

  ast.Member resolveInterfaceIndexSet(Element element, Element auxiliary) {
    if (!strongMode) return null;
    if (supportsInterfaceIndexSet(element)) {
      return getMemberReference(element);
    }
    if (supportsInterfaceIndexSet(auxiliary)) {
      return getMemberReference(auxiliary);
    }
    return null;
  }

  ast.Member resolveConcreteMethod(Element element) {
    if (supportsConcreteMethodCall(element)) {
      return getMemberReference(element);
    }
    return null;
  }

  ast.Member resolveInterfaceMethod(Element element) {
    if (!strongMode) return null;
    if (supportsInterfaceMethodCall(element)) {
      return getMemberReference(element);
    }
    return null;
  }

  ast.Constructor resolveConstructor(Element element) {
    if (supportsConstructorCall(element)) {
      return getMemberReference(element);
    }
    return null;
  }

  ast.Field resolveField(Element element) {
    if (element is FieldElement && !element.isSynthetic) {
      return getMemberReference(element);
    }
    return null;
  }

  /// A static accessor that generates a 'throw NoSuchMethodError' when a
  /// read or write access could not be resolved.
  Accessor staticAccess(String name, Element element, [Element auxiliary]) {
    return new _StaticAccessor(
        this,
        name,
        resolveConcreteGet(element, auxiliary),
        resolveConcreteSet(element, auxiliary));
  }

  /// An accessor that generates a 'throw NoSuchMethodError' on both read
  /// and write access.
  Accessor unresolvedAccess(String name) {
    return new _StaticAccessor(this, name, null, null);
  }
}

class TypeScope extends ReferenceScope {
  final Map<TypeParameterElement, ast.TypeParameter> localTypeParameters =
      <TypeParameterElement, ast.TypeParameter>{};
  TypeAnnotationBuilder _typeBuilder;

  TypeScope(ReferenceLevelLoader loader) : super(loader) {
    _typeBuilder = new TypeAnnotationBuilder(this);
  }

  String get location => '?';

  bool get allowClassTypeParameters => false;

  ast.DartType get defaultTypeParameterBound => getRootClassReference().rawType;

  ast.TypeParameter tryGetTypeParameterReference(TypeParameterElement element) {
    return localTypeParameters[element] ??
        loader.tryGetClassTypeParameter(element);
  }

  ast.TypeParameter getTypeParameterReference(TypeParameterElement element) {
    return localTypeParameters[element] ??
        loader.tryGetClassTypeParameter(element) ??
        (localTypeParameters[element] = new ast.TypeParameter(element.name));
  }

  ast.TypeParameter makeTypeParameter(TypeParameterElement element,
      {ast.DartType bound}) {
    var typeParameter = getTypeParameterReference(element);
    assert(bound != null);
    typeParameter.bound = bound;
    return typeParameter;
  }

  ast.DartType buildType(DartType type) {
    return _typeBuilder.buildFromDartType(type);
  }

  ast.Supertype buildSupertype(DartType type) {
    if (type is InterfaceType) {
      var classElement = type.element;
      if (classElement == null) return getRootClassReference().asRawSupertype;
      var classNode = getClassReference(classElement);
      if (classNode.typeParameters.isEmpty ||
          classNode.typeParameters.length != type.typeArguments.length) {
        return classNode.asRawSupertype;
      } else {
        return new ast.Supertype(classNode,
            type.typeArguments.map(buildType).toList(growable: false));
      }
    }
    return getRootClassReference().asRawSupertype;
  }

  ast.DartType buildTypeAnnotation(AstNode node) {
    return _typeBuilder.build(node);
  }

  ast.DartType buildOptionalTypeAnnotation(AstNode node) {
    return node == null ? null : _typeBuilder.build(node);
  }

  ast.DartType getInferredType(Expression node) {
    if (!strongMode) return const ast.DynamicType();
    // TODO: Is this official way to get the strong-mode inferred type?
    return buildType(node.staticType);
  }

  ast.DartType getInferredTypeArgument(Expression node, int index) {
    var type = getInferredType(node);
    return type is ast.InterfaceType && index < type.typeArguments.length
        ? type.typeArguments[index]
        : const ast.DynamicType();
  }

  ast.DartType getInferredReturnType(Expression node) {
    var type = getInferredType(node);
    return type is ast.FunctionType ? type.returnType : const ast.DynamicType();
  }

  List<ast.DartType> getInferredInvocationTypeArguments(
      InvocationExpression node) {
    if (!strongMode) return <ast.DartType>[];
    ast.DartType inferredFunctionType = buildType(node.staticInvokeType);
    ast.DartType genericFunctionType = buildType(node.function.staticType);
    if (genericFunctionType is ast.FunctionType) {
      if (genericFunctionType.typeParameters.isEmpty) return <ast.DartType>[];
      // Attempt to unify the two types to obtain a substitution of the type
      // variables.  If successful, use the substituted types in the order
      // they occur in the type parameter list.
      var substitution = unifyTypes(genericFunctionType.withoutTypeParameters,
          inferredFunctionType, genericFunctionType.typeParameters.toSet());
      if (substitution != null) {
        return genericFunctionType.typeParameters
            .map((p) => substitution[p] ?? const ast.DynamicType())
            .toList();
      }
      return new List<ast.DartType>.filled(
          genericFunctionType.typeParameters.length, const ast.DynamicType(),
          growable: true);
    } else {
      return <ast.DartType>[];
    }
  }

  List<ast.DartType> buildOptionalTypeArgumentList(TypeArgumentList node) {
    if (node == null) return null;
    return _typeBuilder.buildList(node.arguments);
  }

  List<ast.DartType> buildTypeArgumentList(TypeArgumentList node) {
    return _typeBuilder.buildList(node.arguments);
  }

  List<ast.TypeParameter> buildOptionalTypeParameterList(TypeParameterList node,
      {bool strongModeOnly: false}) {
    if (node == null) return <ast.TypeParameter>[];
    if (strongModeOnly && !strongMode) return <ast.TypeParameter>[];
    return node.typeParameters.map(buildTypeParameter).toList();
  }

  ast.TypeParameter buildTypeParameter(TypeParameter node) {
    return makeTypeParameter(node.element,
        bound: buildOptionalTypeAnnotation(node.bound) ??
            defaultTypeParameterBound);
  }

  ConstructorElement findDefaultConstructor(ClassElement class_) {
    for (var constructor in class_.constructors) {
      // Note: isDefaultConstructor checks if the constructor is suitable for
      // being invoked without arguments.  It does not imply that it is
      // synthetic.
      if (constructor.isDefaultConstructor && !constructor.isFactory) {
        return constructor;
      }
    }
    return null;
  }

  ast.FunctionNode buildFunctionInterface(FunctionTypedElement element) {
    var positional = <ast.VariableDeclaration>[];
    var named = <ast.VariableDeclaration>[];
    int requiredParameterCount = 0;
    // Initialize type parameters in two passes: put them into scope,
    // and compute the bounds afterwards while they are all in scope.
    var typeParameters = <ast.TypeParameter>[];
    var typeParameterElements =
        element is ConstructorElement && element.isFactory
            ? element.enclosingElement.typeParameters
            : element.typeParameters;
    if (strongMode || element is ConstructorElement) {
      for (var parameter in typeParameterElements) {
        var parameterNode = new ast.TypeParameter(parameter.name);
        typeParameters.add(parameterNode);
        localTypeParameters[parameter] = parameterNode;
      }
    }
    for (int i = 0; i < typeParameters.length; ++i) {
      var parameter = typeParameterElements[i];
      var parameterNode = typeParameters[i];
      parameterNode.bound = parameter.bound == null
          ? defaultTypeParameterBound
          : buildType(parameter.bound);
    }
    for (var parameter in element.parameters) {
      var parameterNode = new ast.VariableDeclaration(parameter.name,
          type: buildType(parameter.type));
      switch (parameter.parameterKind) {
        case ParameterKind.REQUIRED:
          positional.add(parameterNode);
          ++requiredParameterCount;
          break;

        case ParameterKind.POSITIONAL:
          positional.add(parameterNode);
          break;

        case ParameterKind.NAMED:
          named.add(parameterNode);
          break;
      }
    }
    var returnType = element is ConstructorElement
        ? const ast.VoidType()
        : buildType(element.returnType);
    return new ast.FunctionNode(null,
        typeParameters: typeParameters,
        positionalParameters: positional,
        namedParameters: named,
        requiredParameterCount: requiredParameterCount,
        returnType: returnType)
      ..fileOffset = element.nameOffset;
  }
}

class ExpressionScope extends TypeScope {
  ast.Library currentLibrary;
  final Map<LocalElement, ast.VariableDeclaration> localVariables =
      <LocalElement, ast.VariableDeclaration>{};

  ExpressionBuilder _expressionBuilder;
  StatementBuilder _statementBuilder;

  ExpressionScope(ReferenceLevelLoader loader, this.currentLibrary)
      : super(loader) {
    assert(currentLibrary != null);
    _expressionBuilder = new ExpressionBuilder(this);
    _statementBuilder = new StatementBuilder(this);
  }

  bool get allowThis => false; // Overridden by MemberScope.

  ast.Name buildName(SimpleIdentifier node) {
    return new ast.Name(node.name, currentLibrary);
  }

  ast.Statement buildStatement(Statement node) {
    return _statementBuilder.build(node);
  }

  ast.Statement buildOptionalFunctionBody(FunctionBody body) {
    if (body == null ||
        body is EmptyFunctionBody ||
        body is NativeFunctionBody) {
      return null;
    }
    return buildMandatoryFunctionBody(body);
  }

  ast.Statement buildMandatoryFunctionBody(FunctionBody body) {
    try {
      if (body is BlockFunctionBody) {
        return buildStatement(body.block);
      } else if (body is ExpressionFunctionBody) {
        if (bodyHasVoidReturn(body)) {
          return new ast.ExpressionStatement(buildExpression(body.expression));
        } else {
          return new ast.ReturnStatement(buildExpression(body.expression))
            ..fileOffset = body.expression.offset;
        }
      } else {
        return internalError('Missing function body');
      }
    } on _CompilationError catch (e) {
      return new ast.ExpressionStatement(buildThrowCompileTimeError(e.message));
    }
  }

  ast.AsyncMarker getAsyncMarker({bool isAsync: false, bool isStar: false}) {
    return ast.AsyncMarker.values[(isAsync ? 2 : 0) + (isStar ? 1 : 0)];
  }

  ast.FunctionNode buildFunctionNode(
      FormalParameterList formalParameters, FunctionBody body,
      {TypeName returnType,
      List<ast.TypeParameter> typeParameters,
      ast.DartType inferredReturnType}) {
    // TODO(asgerf): This will in many cases rebuild the interface built by
    //   TypeScope.buildFunctionInterface.
    var positional = <ast.VariableDeclaration>[];
    var named = <ast.VariableDeclaration>[];
    int requiredParameterCount = 0;
    var formals = formalParameters?.parameters ?? const <FormalParameter>[];
    for (var parameter in formals) {
      var declaration = makeVariableDeclaration(parameter.element,
          initializer: parameter is DefaultFormalParameter
              ? buildOptionalTopLevelExpression(parameter.defaultValue)
              : null,
          type: buildType(
              resolutionMap.elementDeclaredByFormalParameter(parameter).type));
      switch (parameter.kind) {
        case ParameterKind.REQUIRED:
          positional.add(declaration);
          ++requiredParameterCount;
          declaration.initializer = null;
          break;

        case ParameterKind.POSITIONAL:
          positional.add(declaration);
          break;

        case ParameterKind.NAMED:
          named.add(declaration);
          break;
      }
    }
    int offset = formalParameters?.offset ?? body.offset;
    int endOffset = body.endToken.offset;
    ast.AsyncMarker asyncMarker =
        getAsyncMarker(isAsync: body.isAsynchronous, isStar: body.isGenerator);
    return new ast.FunctionNode(buildOptionalFunctionBody(body),
        typeParameters: typeParameters,
        positionalParameters: positional,
        namedParameters: named,
        requiredParameterCount: requiredParameterCount,
        returnType: buildOptionalTypeAnnotation(returnType) ??
            inferredReturnType ??
            const ast.DynamicType(),
        asyncMarker: asyncMarker,
        dartAsyncMarker: asyncMarker)
      ..fileOffset = offset
      ..fileEndOffset = endOffset;
  }

  ast.Expression buildOptionalTopLevelExpression(Expression node) {
    return node == null ? null : buildTopLevelExpression(node);
  }

  ast.Expression buildTopLevelExpression(Expression node) {
    try {
      return _expressionBuilder.build(node);
    } on _CompilationError catch (e) {
      return buildThrowCompileTimeError(e.message);
    }
  }

  ast.Expression buildExpression(Expression node) {
    return _expressionBuilder.build(node);
  }

  ast.Expression buildOptionalExpression(Expression node) {
    return node == null ? null : _expressionBuilder.build(node);
  }

  Accessor buildLeftHandValue(Expression node) {
    return _expressionBuilder.buildLeftHandValue(node);
  }

  ast.Expression buildStringLiteral(Expression node) {
    List<ast.Expression> parts = <ast.Expression>[];
    new StringLiteralPartBuilder(this, parts).build(node);
    return parts.length == 1 && parts[0] is ast.StringLiteral
        ? parts[0]
        : new ast.StringConcatenation(parts);
  }

  ast.Expression buildThis() {
    return allowThis
        ? new ast.ThisExpression()
        : emitCompileTimeError(CompileTimeErrorCode.INVALID_REFERENCE_TO_THIS);
  }

  ast.Initializer buildInitializer(ConstructorInitializer node) {
    try {
      return new InitializerBuilder(this).build(node);
    } on _CompilationError catch (_) {
      return new ast.InvalidInitializer();
    }
  }

  bool isFinal(Element element) {
    return element is VariableElement && element.isFinal ||
        element is FunctionElement;
  }

  bool isConst(Element element) {
    return element is VariableElement && element.isConst;
  }

  ast.VariableDeclaration getVariableReference(LocalElement element) {
    return localVariables.putIfAbsent(element, () {
      return new ast.VariableDeclaration(element.name,
          isFinal: isFinal(element), isConst: isConst(element))
        ..fileOffset = element.nameOffset;
    });
  }

  ast.DartType getInferredVariableType(Element element) {
    if (!strongMode) return const ast.DynamicType();
    if (element is FunctionTypedElement) {
      return buildType(element.type);
    } else if (element is VariableElement) {
      return buildType(element.type);
    } else {
      log.severe('Unexpected variable element: $element');
      return const ast.DynamicType();
    }
  }

  ast.VariableDeclaration makeVariableDeclaration(LocalElement element,
      {ast.DartType type, ast.Expression initializer, int equalsOffset}) {
    var declaration = getVariableReference(element);
    if (equalsOffset != null) declaration.fileEqualsOffset = equalsOffset;
    declaration.type = type ?? getInferredVariableType(element);
    if (initializer != null) {
      declaration.initializer = initializer..parent = declaration;
    }
    return declaration;
  }

  /// Returns true if [arguments] can be accepted by [target]
  /// (not taking type checks into account).
  bool areArgumentsCompatible(
      FunctionTypedElement target, ast.Arguments arguments) {
    var positionals = arguments.positional;
    var parameters = target.parameters;
    const required = ParameterKind.REQUIRED; // For avoiding long lines.
    const named = ParameterKind.NAMED;
    // If the first unprovided parameter is required, there are too few
    // positional arguments.
    if (positionals.length < parameters.length &&
        parameters[positionals.length].parameterKind == required) {
      return false;
    }
    // If there are more positional arguments than parameters, or if the last
    // positional argument corresponds to a named parameter, there are too many
    // positional arguments.
    if (positionals.length > parameters.length) return false;
    if (positionals.isNotEmpty &&
        parameters[positionals.length - 1].parameterKind == named) {
      return false; // Too many positional arguments.
    }
    if (arguments.named.isEmpty) return true;
    int firstNamedParameter = positionals.length;
    while (firstNamedParameter < parameters.length &&
        parameters[firstNamedParameter].parameterKind != ParameterKind.NAMED) {
      ++firstNamedParameter;
    }
    namedLoop:
    for (int i = 0; i < arguments.named.length; ++i) {
      String name = arguments.named[i].name;
      for (int j = firstNamedParameter; j < parameters.length; ++j) {
        if (parameters[j].parameterKind == ParameterKind.NAMED &&
            parameters[j].name == name) {
          continue namedLoop;
        }
      }
      return false;
    }
    return true;
  }

  /// Throws a NoSuchMethodError corresponding to a call to [memberName] on
  /// [receiver] with the given [arguments].
  ///
  /// If provided, [candidateTarget] provides the expected arity and argument
  /// names for the best candidate target.
  ast.Expression buildThrowNoSuchMethodError(
      ast.Expression receiver, String memberName, ast.Arguments arguments,
      {Element candidateTarget}) {
    // TODO(asgerf): When we have better integration with patch files, use
    //   the internal constructor that provides a more detailed error message.
    ast.Expression candidateArgumentNames;
    if (candidateTarget is FunctionTypedElement) {
      candidateArgumentNames = new ast.ListLiteral(candidateTarget.parameters
          .map((p) => new ast.StringLiteral(p.name))
          .toList());
    } else {
      candidateArgumentNames = new ast.NullLiteral();
    }
    return new ast.Throw(new ast.ConstructorInvocation(
        loader.getCoreClassConstructorReference('NoSuchMethodError'),
        new ast.Arguments(<ast.Expression>[
          receiver,
          new ast.SymbolLiteral(memberName),
          new ast.ListLiteral(arguments.positional),
          new ast.MapLiteral(arguments.named.map((arg) {
            return new ast.MapEntry(new ast.SymbolLiteral(arg.name), arg.value);
          }).toList()),
          candidateArgumentNames
        ])));
  }

  ast.Expression buildThrowCompileTimeError(String message) {
    // The spec does not mandate a specific behavior in face of a compile-time
    // error.  We just throw a string.  The VM throws an uncatchable exception
    // for this case.
    // TOOD(asgerf): Should we add uncatchable exceptions to kernel?
    return new ast.Throw(new ast.StringLiteral(message));
  }

  ast.Expression buildThrowCompileTimeErrorFromCode(ErrorCode code,
      [List arguments]) {
    return buildThrowCompileTimeError(makeErrorMessage(code, arguments));
  }

  static final RegExp _errorMessagePattern = new RegExp(r'\{(\d+)\}');

  String makeErrorMessage(ErrorCode error, [List arguments]) {
    String message = error.message;
    if (arguments != null) {
      message = message.replaceAllMapped(_errorMessagePattern, (m) {
        String numberString = m.group(1);
        int index = int.parse(numberString);
        return arguments[index];
      });
    }
    return message;
  }

  /// Throws an exception that will be caught at the function level, to replace
  /// the entire function with a throw.
  emitCompileTimeError(ErrorCode error, [List arguments]) {
    throw new _CompilationError(makeErrorMessage(error, arguments));
  }

  ast.Expression buildThrowAbstractClassInstantiationError(String name) {
    return new ast.Throw(new ast.ConstructorInvocation(
        loader.getCoreClassConstructorReference(
            'AbstractClassInstantiationError'),
        new ast.Arguments(<ast.Expression>[new ast.StringLiteral(name)])));
  }

  ast.Expression buildThrowFallThroughError() {
    return new ast.Throw(new ast.ConstructorInvocation(
        loader.getCoreClassConstructorReference('FallThroughError'),
        new ast.Arguments.empty()));
  }

  emitInvalidConstant([ErrorCode error]) {
    error ??= CompileTimeErrorCode.INVALID_CONSTANT;
    return emitCompileTimeError(error);
  }

  internalError(String message) {
    throw 'Internal error when compiling $location: $message';
  }

  unsupportedFeature(String feature) {
    throw new _CompilationError('$feature is not supported');
  }

  ast.Expression buildAnnotation(Annotation annotation) {
    Element element = annotation.element;
    if (annotation.arguments == null) {
      var target = resolveConcreteGet(element, null);
      return target == null
          ? new ast.InvalidExpression()
          : new ast.StaticGet(target);
    } else if (element is ConstructorElement && element.isConst) {
      var target = resolveConstructor(element);
      return target == null
          ? new ast.InvalidExpression()
          : new ast.ConstructorInvocation(
              target, _expressionBuilder.buildArguments(annotation.arguments),
              isConst: true);
    } else {
      return new ast.InvalidExpression();
    }
  }

  void addTransformerFlag(int flags) {
    // Overridden by MemberScope.
  }

  /// True if the body of the given method must return nothing.
  bool hasVoidReturn(ExecutableElement element) {
    return (strongMode && element.returnType.isVoid) ||
        (element is PropertyAccessorElement && element.isSetter) ||
        element.name == '[]=';
  }

  bool bodyHasVoidReturn(FunctionBody body) {
    AstNode parent = body.parent;
    return parent is MethodDeclaration && hasVoidReturn(parent.element) ||
        parent is FunctionDeclaration && hasVoidReturn(parent.element);
  }
}

/// A scope in which class type parameters are in scope, while not in scope
/// of a specific member.
class ClassScope extends ExpressionScope {
  @override
  bool get allowClassTypeParameters => true;

  ClassScope(ReferenceLevelLoader loader, ast.Library library)
      : super(loader, library);
}

/// Translates expressions, statements, and other constructs into [ast] nodes.
///
/// Naming convention:
/// - `buildX` may not be given null as argument (it may crash the compiler).
/// - `buildOptionalX` returns null or an empty list if given null
/// - `buildMandatoryX` returns an invalid node if given null.
class MemberScope extends ExpressionScope {
  /// A reference to the member currently being upgraded to body level.
  final ast.Member currentMember;

  MemberScope(ReferenceLevelLoader loader, ast.Member currentMember)
      : currentMember = currentMember,
        super(loader, currentMember.enclosingLibrary) {
    assert(currentMember != null);
  }

  ast.Class get currentClass => currentMember.enclosingClass;

  bool get allowThis => _memberHasThis(currentMember);

  @override
  bool get allowClassTypeParameters {
    return currentMember.isInstanceMember || currentMember is ast.Constructor;
  }

  /// Returns a string for debugging use, indicating the location of the member
  /// being built.
  String get location {
    var library = currentMember.enclosingLibrary?.importUri ?? '<No Library>';
    var className = currentMember.enclosingClass == null
        ? null
        : (currentMember.enclosingClass?.name ?? '<Anonymous Class>');
    var member =
        currentMember.name?.name ?? '<Anonymous ${currentMember.runtimeType}>';
    return [library, className, member].join('::');
  }

  bool _memberHasThis(ast.Member member) {
    return member is ast.Procedure && !member.isStatic ||
        member is ast.Constructor;
  }

  void addTransformerFlag(int flags) {
    currentMember.transformerFlags |= flags;
  }
}

class LabelStack {
  final List<String> labels; // Contains null for unlabeled targets.
  final LabelStack next;
  final List<ast.Statement> jumps = <ast.Statement>[];
  bool isSwitchTarget = false;

  LabelStack(String label, this.next) : labels = <String>[label];
  LabelStack.unlabeled(this.next) : labels = <String>[null];
  LabelStack.switchCase(String label, this.next)
      : isSwitchTarget = true,
        labels = <String>[label];
  LabelStack.many(this.labels, this.next);
}

class StatementBuilder extends GeneralizingAstVisitor<ast.Statement> {
  final ExpressionScope scope;
  LabelStack breakStack, continueStack;

  StatementBuilder(this.scope, [this.breakStack, this.continueStack]);

  ast.Statement build(Statement node) {
    ast.Statement result = node.accept(this);
    result.fileOffset = _getOffset(node);
    return result;
  }

  ast.Statement buildOptional(Statement node) {
    ast.Statement result = node?.accept(this);
    result?.fileOffset = _getOffset(node);
    return result;
  }

  int _getOffset(AstNode node) {
    return node.offset;
  }

  ast.Statement buildInScope(
      Statement node, LabelStack breakNode, LabelStack continueNode) {
    var oldBreak = this.breakStack;
    var oldContinue = this.continueStack;
    breakStack = breakNode;
    continueStack = continueNode;
    var result = build(node);
    this.breakStack = oldBreak;
    this.continueStack = oldContinue;
    return result;
  }

  void buildBlockMember(Statement node, List<ast.Statement> output) {
    if (node is LabeledStatement &&
        node.statement is VariableDeclarationStatement) {
      // If a variable is labeled, its scope is part of the enclosing block.
      LabeledStatement labeled = node;
      node = labeled.statement;
    }
    if (node is VariableDeclarationStatement) {
      VariableDeclarationList list = node.variables;
      ast.DartType type = scope.buildOptionalTypeAnnotation(list.type);
      for (VariableDeclaration decl in list.variables) {
        LocalElement local = decl.element as dynamic; // Cross cast.
        output.add(scope.makeVariableDeclaration(local,
            type: type,
            initializer: scope.buildOptionalExpression(decl.initializer),
            equalsOffset: decl.equals?.offset));
      }
    } else {
      output.add(build(node));
    }
  }

  ast.Statement makeBreakTarget(ast.Statement node, LabelStack stackNode) {
    if (stackNode.jumps.isEmpty) return node;
    var labeled = new ast.LabeledStatement(node);
    for (var jump in stackNode.jumps) {
      (jump as ast.BreakStatement).target = labeled;
    }
    return labeled;
  }

  LabelStack findLabelTarget(String label, LabelStack stack) {
    while (stack != null) {
      if (stack.labels.contains(label)) return stack;
      stack = stack.next;
    }
    return null;
  }

  ast.Statement visitAssertStatement(AssertStatement node) {
    return new ast.AssertStatement(scope.buildExpression(node.condition),
        message: scope.buildOptionalExpression(node.message));
  }

  ast.Statement visitBlock(Block node) {
    List<ast.Statement> statements = <ast.Statement>[];
    for (Statement statement in node.statements) {
      buildBlockMember(statement, statements);
    }
    return new ast.Block(statements);
  }

  ast.Statement visitBreakStatement(BreakStatement node) {
    var stackNode = findLabelTarget(node.label?.name, breakStack);
    if (stackNode == null) {
      return node.label == null
          ? scope.emitCompileTimeError(ParserErrorCode.BREAK_OUTSIDE_OF_LOOP)
          : scope.emitCompileTimeError(
              CompileTimeErrorCode.LABEL_UNDEFINED, [node.label.name]);
    }
    var result = new ast.BreakStatement(null);
    stackNode.jumps.add(result);
    return result;
  }

  ast.Statement visitContinueStatement(ContinueStatement node) {
    var stackNode = findLabelTarget(node.label?.name, continueStack);
    if (stackNode == null) {
      return node.label == null
          ? scope.emitCompileTimeError(ParserErrorCode.CONTINUE_OUTSIDE_OF_LOOP)
          : scope.emitCompileTimeError(
              CompileTimeErrorCode.LABEL_UNDEFINED, [node.label.name]);
    }
    var result = stackNode.isSwitchTarget
        ? new ast.ContinueSwitchStatement(null)
        : new ast.BreakStatement(null);
    stackNode.jumps.add(result);
    return result;
  }

  void addLoopLabels(Statement loop, LabelStack continueNode) {
    AstNode parent = loop.parent;
    if (parent is LabeledStatement) {
      for (var label in parent.labels) {
        continueNode.labels.add(label.label.name);
      }
    }
  }

  ast.Statement visitDoStatement(DoStatement node) {
    LabelStack breakNode = new LabelStack.unlabeled(breakStack);
    LabelStack continueNode = new LabelStack.unlabeled(continueStack);
    addLoopLabels(node, continueNode);
    var body = buildInScope(node.body, breakNode, continueNode);
    var loop = new ast.DoStatement(makeBreakTarget(body, continueNode),
        scope.buildExpression(node.condition));
    return makeBreakTarget(loop, breakNode);
  }

  ast.Statement visitWhileStatement(WhileStatement node) {
    LabelStack breakNode = new LabelStack.unlabeled(breakStack);
    LabelStack continueNode = new LabelStack.unlabeled(continueStack);
    addLoopLabels(node, continueNode);
    var body = buildInScope(node.body, breakNode, continueNode);
    var loop = new ast.WhileStatement(scope.buildExpression(node.condition),
        makeBreakTarget(body, continueNode));
    return makeBreakTarget(loop, breakNode);
  }

  ast.Statement visitEmptyStatement(EmptyStatement node) {
    return new ast.EmptyStatement();
  }

  ast.Statement visitExpressionStatement(ExpressionStatement node) {
    return new ast.ExpressionStatement(scope.buildExpression(node.expression));
  }

  static String _getLabelName(Label label) {
    return label.label.name;
  }

  ast.Statement visitLabeledStatement(LabeledStatement node) {
    // Only set up breaks here.  Loops handle labeling on their own.
    var breakNode = new LabelStack.many(
        node.labels.map(_getLabelName).toList(), breakStack);
    var body = buildInScope(node.statement, breakNode, continueStack);
    return makeBreakTarget(body, breakNode);
  }

  static bool isBreakingExpression(ast.Expression node) {
    return node is ast.Throw || node is ast.Rethrow;
  }

  static bool isBreakingStatement(ast.Statement node) {
    return node is ast.BreakStatement ||
        node is ast.ContinueSwitchStatement ||
        node is ast.ReturnStatement ||
        node is ast.ExpressionStatement &&
            isBreakingExpression(node.expression);
  }

  ast.Statement visitSwitchStatement(SwitchStatement node) {
    // Group all cases into case blocks.  Use parallel lists to collect the
    // intermediate terms until we are ready to create the AST nodes.
    LabelStack breakNode = new LabelStack.unlabeled(breakStack);
    LabelStack continueNode = continueStack;
    var cases = <ast.SwitchCase>[];
    var bodies = <List<Statement>>[];
    var labelToNode = <String, ast.SwitchCase>{};
    ast.SwitchCase currentCase = null;
    for (var member in node.members) {
      if (currentCase != null && currentCase.isDefault) {
        var error = member is SwitchCase
            ? ParserErrorCode.SWITCH_HAS_CASE_AFTER_DEFAULT_CASE
            : ParserErrorCode.SWITCH_HAS_MULTIPLE_DEFAULT_CASES;
        return scope.emitCompileTimeError(error);
      }
      if (currentCase == null) {
        currentCase = new ast.SwitchCase(<ast.Expression>[], <int>[], null);
        cases.add(currentCase);
      }
      if (member is SwitchCase) {
        var expression = scope.buildExpression(member.expression);
        currentCase.expressions.add(expression..parent = currentCase);
        currentCase.expressionOffsets.add(expression.fileOffset);
      } else {
        currentCase.isDefault = true;
      }
      for (Label label in member.labels) {
        continueNode =
            new LabelStack.switchCase(label.label.name, continueNode);
        labelToNode[label.label.name] = currentCase;
      }
      if (member.statements?.isNotEmpty ?? false) {
        bodies.add(member.statements);
        currentCase = null;
      }
    }
    if (currentCase != null) {
      // Close off a trailing block.
      bodies.add(const <Statement>[]);
      currentCase = null;
    }
    // Now that the label environment is set up, build the bodies.
    var oldBreak = this.breakStack;
    var oldContinue = this.continueStack;
    this.breakStack = breakNode;
    this.continueStack = continueNode;
    for (int i = 0; i < cases.length; ++i) {
      var blockNodes = <ast.Statement>[];
      for (var statement in bodies[i]) {
        buildBlockMember(statement, blockNodes);
      }
      if (blockNodes.isEmpty || !isBreakingStatement(blockNodes.last)) {
        if (i < cases.length - 1) {
          blockNodes.add(
              new ast.ExpressionStatement(scope.buildThrowFallThroughError()));
        } else {
          var jump = new ast.BreakStatement(null);
          blockNodes.add(jump);
          breakNode.jumps.add(jump);
        }
      }
      cases[i].body = new ast.Block(blockNodes)..parent = cases[i];
    }
    // Unwind the stack of case labels and bind their jumps to the case target.
    while (continueNode != oldContinue) {
      for (var jump in continueNode.jumps) {
        (jump as ast.ContinueSwitchStatement).target =
            labelToNode[continueNode.labels.first];
      }
      continueNode = continueNode.next;
    }
    var expression = scope.buildExpression(node.expression);
    var result = new ast.SwitchStatement(expression, cases);
    this.breakStack = oldBreak;
    this.continueStack = oldContinue;
    return makeBreakTarget(result, breakNode);
  }

  ast.Statement visitForStatement(ForStatement node) {
    List<ast.VariableDeclaration> variables = <ast.VariableDeclaration>[];
    ast.Expression initialExpression;
    if (node.variables != null) {
      VariableDeclarationList list = node.variables;
      var type = scope.buildOptionalTypeAnnotation(list.type);
      for (var variable in list.variables) {
        LocalElement local = variable.element as dynamic; // Cross cast.
        variables.add(scope.makeVariableDeclaration(local,
            initializer: scope.buildOptionalExpression(variable.initializer),
            type: type,
            equalsOffset: variable.equals?.offset));
      }
    } else if (node.initialization != null) {
      initialExpression = scope.buildExpression(node.initialization);
    }
    var breakNode = new LabelStack.unlabeled(breakStack);
    var continueNode = new LabelStack.unlabeled(continueStack);
    addLoopLabels(node, continueNode);
    var body = buildInScope(node.body, breakNode, continueNode);
    var loop = new ast.ForStatement(
        variables,
        scope.buildOptionalExpression(node.condition),
        node.updaters.map(scope.buildExpression).toList(),
        makeBreakTarget(body, continueNode));
    loop = makeBreakTarget(loop, breakNode);
    if (initialExpression != null) {
      return new ast.Block(<ast.Statement>[
        new ast.ExpressionStatement(initialExpression),
        loop
      ]);
    }
    return loop;
  }

  DartType iterableElementType(DartType iterable) {
    if (iterable is InterfaceType) {
      var iterator = iterable.lookUpInheritedGetter('iterator')?.returnType;
      if (iterator is InterfaceType) {
        return iterator.lookUpInheritedGetter('current')?.returnType;
      }
    }
    return null;
  }

  DartType streamElementType(DartType stream) {
    if (stream is InterfaceType) {
      var class_ = stream.element;
      if (class_.library.isDartAsync &&
          class_.name == 'Stream' &&
          stream.typeArguments.length == 1) {
        return stream.typeArguments[0];
      }
    }
    return null;
  }

  ast.Statement visitForEachStatement(ForEachStatement node) {
    ast.VariableDeclaration variable;
    Accessor leftHand;
    if (node.loopVariable != null) {
      DeclaredIdentifier loopVariable = node.loopVariable;
      variable = scope.makeVariableDeclaration(loopVariable.element,
          type: scope.buildOptionalTypeAnnotation(loopVariable.type));
    } else if (node.identifier != null) {
      leftHand = scope.buildLeftHandValue(node.identifier);
      variable = new ast.VariableDeclaration(null, isFinal: true);
      if (scope.strongMode) {
        var containerType = node.iterable.staticType;
        DartType elementType = node.awaitKeyword != null
            ? streamElementType(containerType)
            : iterableElementType(containerType);
        if (elementType != null) {
          variable.type = scope.buildType(elementType);
        }
      }
    }
    var breakNode = new LabelStack.unlabeled(breakStack);
    var continueNode = new LabelStack.unlabeled(continueStack);
    addLoopLabels(node, continueNode);
    var body = buildInScope(node.body, breakNode, continueNode);
    if (leftHand != null) {
      // Desugar
      //
      //     for (x in e) BODY
      //
      // to
      //
      //     for (var tmp in e) {
      //       x = tmp;
      //       BODY
      //     }
      body = new ast.Block(<ast.Statement>[
        new ast.ExpressionStatement(leftHand
            .buildAssignment(new ast.VariableGet(variable), voidContext: true)),
        body
      ]);
    }
    var loop = new ast.ForInStatement(
        variable,
        scope.buildExpression(node.iterable),
        makeBreakTarget(body, continueNode),
        isAsync: node.awaitKeyword != null)
      ..fileOffset = node.offset;
    return makeBreakTarget(loop, breakNode);
  }

  ast.Statement visitIfStatement(IfStatement node) {
    return new ast.IfStatement(scope.buildExpression(node.condition),
        build(node.thenStatement), buildOptional(node.elseStatement));
  }

  ast.Statement visitReturnStatement(ReturnStatement node) {
    return new ast.ReturnStatement(
        scope.buildOptionalExpression(node.expression));
  }

  ast.Catch buildCatchClause(CatchClause node) {
    var exceptionVariable = node.exceptionParameter == null
        ? null
        : scope.makeVariableDeclaration(node.exceptionParameter.staticElement);
    var stackTraceVariable = node.stackTraceParameter == null
        ? null
        : scope.makeVariableDeclaration(node.stackTraceParameter.staticElement);
    return new ast.Catch(exceptionVariable, build(node.body),
        stackTrace: stackTraceVariable,
        guard: scope.buildOptionalTypeAnnotation(node.exceptionType) ??
            const ast.DynamicType());
  }

  ast.Statement visitTryStatement(TryStatement node) {
    ast.Statement statement = build(node.body);
    if (node.catchClauses.isNotEmpty) {
      statement = new ast.TryCatch(
          statement, node.catchClauses.map(buildCatchClause).toList());
    }
    if (node.finallyBlock != null) {
      statement = new ast.TryFinally(statement, build(node.finallyBlock));
    }
    return statement;
  }

  ast.Statement visitVariableDeclarationStatement(
      VariableDeclarationStatement node) {
    // This is only reached when a variable is declared in non-block level,
    // because visitBlock intercepts visits to its children.
    // An example where we hit this case is:
    //
    //   if (foo) var x = 5, y = x + 1;
    //
    // We wrap these in a block:
    //
    //   if (foo) {
    //     var x = 5;
    //     var y = x + 1;
    //   }
    //
    // Note that the use of a block here is required by the kernel language,
    // even if there is only one variable declaration.
    List<ast.Statement> statements = <ast.Statement>[];
    buildBlockMember(node, statements);
    return new ast.Block(statements);
  }

  ast.Statement visitYieldStatement(YieldStatement node) {
    return new ast.YieldStatement(scope.buildExpression(node.expression),
        isYieldStar: node.star != null);
  }

  ast.Statement visitFunctionDeclarationStatement(
      FunctionDeclarationStatement node) {
    var declaration = node.functionDeclaration;
    var expression = declaration.functionExpression;
    LocalElement element = declaration.element as dynamic; // Cross cast.
    return new ast.FunctionDeclaration(
        scope.makeVariableDeclaration(element,
            type: scope.buildType(declaration.element.type)),
        scope.buildFunctionNode(expression.parameters, expression.body,
            typeParameters: scope.buildOptionalTypeParameterList(
                expression.typeParameters,
                strongModeOnly: true),
            returnType: declaration.returnType))
      ..fileOffset = node.offset;
  }

  @override
  visitStatement(Statement node) {
    return scope.internalError('Unhandled statement ${node.runtimeType}');
  }
}

class ExpressionBuilder
    extends GeneralizingAstVisitor /* <ast.Expression | Accessor> */ {
  final ExpressionScope scope;
  ast.VariableDeclaration cascadeReceiver;
  ExpressionBuilder(this.scope);

  ast.Expression build(Expression node) {
    var result = node.accept(this);
    if (result is Accessor) {
      result = result.buildSimpleRead();
    }
    // For some method invocations we have already set a file offset to
    // override the default behavior of _getOffset.
    if (node is! MethodInvocation || result.fileOffset < 0) {
      result.fileOffset = _getOffset(node);
    }
    return result;
  }

  int _getOffset(AstNode node) {
    if (node is MethodInvocation) {
      return node.methodName.offset;
    } else if (node is InstanceCreationExpression) {
      return node.constructorName.offset;
    } else if (node is BinaryExpression) {
      return node.operator.offset;
    } else if (node is PrefixedIdentifier) {
      return node.identifier.offset;
    } else if (node is AssignmentExpression) {
      return _getOffset(node.leftHandSide);
    } else if (node is PropertyAccess) {
      return node.propertyName.offset;
    } else if (node is IsExpression) {
      return node.isOperator.offset;
    } else if (node is AsExpression) {
      return node.asOperator.offset;
    } else if (node is StringLiteral) {
      // Use a catch-all for StringInterpolation and AdjacentStrings:
      // the debugger stops at the end.
      return node.end;
    } else if (node is IndexExpression) {
      return node.leftBracket.offset;
    }
    return node.offset;
  }

  Accessor buildLeftHandValue(Expression node) {
    var result = node.accept(this);
    if (result is Accessor) {
      return result;
    } else {
      return new ReadOnlyAccessor(result, ast.TreeNode.noOffset);
    }
  }

  ast.Expression visitAsExpression(AsExpression node) {
    return new ast.AsExpression(
        build(node.expression), scope.buildTypeAnnotation(node.type));
  }

  ast.Expression visitAssignmentExpression(AssignmentExpression node) {
    bool voidContext = isInVoidContext(node);
    String operator = node.operator.value();
    var leftHand = buildLeftHandValue(node.leftHandSide);
    var rightHand = build(node.rightHandSide);
    if (operator == '=') {
      return leftHand.buildAssignment(rightHand, voidContext: voidContext);
    } else if (operator == '??=') {
      return leftHand.buildNullAwareAssignment(
          rightHand, scope.buildType(node.staticType),
          voidContext: voidContext);
    } else {
      // Cut off the trailing '='.
      var name = new ast.Name(operator.substring(0, operator.length - 1));
      return leftHand.buildCompoundAssignment(name, rightHand,
          offset: node.offset,
          voidContext: voidContext,
          interfaceTarget: scope.resolveInterfaceMethod(node.staticElement));
    }
  }

  ast.Expression visitAwaitExpression(AwaitExpression node) {
    return new ast.AwaitExpression(build(node.expression));
  }

  ast.Arguments buildSingleArgument(Expression node) {
    return new ast.Arguments(<ast.Expression>[build(node)]);
  }

  ast.Expression visitBinaryExpression(BinaryExpression node) {
    String operator = node.operator.value();
    if (operator == '&&' || operator == '||') {
      return new ast.LogicalExpression(
          build(node.leftOperand), operator, build(node.rightOperand));
    }
    if (operator == '??') {
      ast.Expression leftOperand = build(node.leftOperand);
      if (leftOperand is ast.VariableGet) {
        return new ast.ConditionalExpression(
            buildIsNull(leftOperand, offset: node.leftOperand.offset),
            build(node.rightOperand),
            new ast.VariableGet(leftOperand.variable),
            scope.getInferredType(node));
      } else {
        var variable = new ast.VariableDeclaration.forValue(leftOperand);
        return new ast.Let(
            variable,
            new ast.ConditionalExpression(
                buildIsNull(new ast.VariableGet(variable),
                    offset: leftOperand.fileOffset),
                build(node.rightOperand),
                new ast.VariableGet(variable),
                scope.getInferredType(node)));
      }
    }
    bool isNegated = false;
    if (operator == '!=') {
      isNegated = true;
      operator = '==';
    }
    ast.Expression expression;
    if (node.leftOperand is SuperExpression) {
      scope.addTransformerFlag(TransformerFlag.superCalls);
      expression = new ast.SuperMethodInvocation(
          new ast.Name(operator),
          buildSingleArgument(node.rightOperand),
          scope.resolveConcreteMethod(node.staticElement));
    } else {
      expression = new ast.MethodInvocation(
          build(node.leftOperand),
          new ast.Name(operator),
          buildSingleArgument(node.rightOperand),
          scope.resolveInterfaceMethod(node.staticElement));
    }
    return isNegated ? new ast.Not(expression) : expression;
  }

  ast.Expression visitBooleanLiteral(BooleanLiteral node) {
    return new ast.BoolLiteral(node.value);
  }

  ast.Expression visitDoubleLiteral(DoubleLiteral node) {
    return new ast.DoubleLiteral(node.value);
  }

  ast.Expression visitIntegerLiteral(IntegerLiteral node) {
    return new ast.IntLiteral(node.value);
  }

  ast.Expression visitNullLiteral(NullLiteral node) {
    return new ast.NullLiteral();
  }

  ast.Expression visitSimpleStringLiteral(SimpleStringLiteral node) {
    return new ast.StringLiteral(node.value);
  }

  ast.Expression visitStringLiteral(StringLiteral node) {
    return scope.buildStringLiteral(node);
  }

  static Object _getTokenValue(Token token) {
    return token.value();
  }

  ast.Expression visitSymbolLiteral(SymbolLiteral node) {
    String value = node.components.map(_getTokenValue).join('.');
    return new ast.SymbolLiteral(value);
  }

  ast.Expression visitCascadeExpression(CascadeExpression node) {
    var receiver = build(node.target);
    // If receiver is a variable it would be tempting to reuse it, but it
    // might be reassigned in one of the cascade sections.
    var receiverVariable = new ast.VariableDeclaration.forValue(receiver,
        type: scope.getInferredType(node.target));
    var oldReceiver = this.cascadeReceiver;
    cascadeReceiver = receiverVariable;
    ast.Expression result = new ast.VariableGet(receiverVariable);
    for (var section in node.cascadeSections.reversed) {
      var dummy = new ast.VariableDeclaration.forValue(build(section));
      result = new ast.Let(dummy, result);
    }
    cascadeReceiver = oldReceiver;
    return new ast.Let(receiverVariable, result);
  }

  ast.Expression makeCascadeReceiver() {
    assert(cascadeReceiver != null);
    return new ast.VariableGet(cascadeReceiver);
  }

  ast.Expression visitConditionalExpression(ConditionalExpression node) {
    return new ast.ConditionalExpression(
        build(node.condition),
        build(node.thenExpression),
        build(node.elseExpression),
        scope.getInferredType(node));
  }

  ast.Expression visitFunctionExpression(FunctionExpression node) {
    return new ast.FunctionExpression(scope.buildFunctionNode(
        node.parameters, node.body,
        typeParameters: scope.buildOptionalTypeParameterList(
            node.typeParameters,
            strongModeOnly: true),
        inferredReturnType: scope.getInferredReturnType(node)));
  }

  ast.Arguments buildArguments(ArgumentList valueArguments,
      {TypeArgumentList explicitTypeArguments,
      List<ast.DartType> inferTypeArguments()}) {
    var positional = <ast.Expression>[];
    var named = <ast.NamedExpression>[];
    for (var argument in valueArguments.arguments) {
      if (argument is NamedExpression) {
        named.add(new ast.NamedExpression(
            argument.name.label.name, build(argument.expression)));
      } else if (named.isNotEmpty) {
        return scope.emitCompileTimeError(
            ParserErrorCode.POSITIONAL_AFTER_NAMED_ARGUMENT);
      } else {
        positional.add(build(argument));
      }
    }
    List<ast.DartType> typeArguments;
    if (explicitTypeArguments != null) {
      typeArguments = scope.buildTypeArgumentList(explicitTypeArguments);
    } else if (inferTypeArguments != null) {
      typeArguments = inferTypeArguments();
    }
    return new ast.Arguments(positional, named: named, types: typeArguments);
  }

  ast.Arguments buildArgumentsForInvocation(InvocationExpression node) {
    if (scope.strongMode) {
      return buildArguments(node.argumentList,
          explicitTypeArguments: node.typeArguments,
          inferTypeArguments: () =>
              scope.getInferredInvocationTypeArguments(node));
    } else {
      return buildArguments(node.argumentList);
    }
  }

  static final ast.Name callName = new ast.Name('call');

  ast.Expression visitFunctionExpressionInvocation(
      FunctionExpressionInvocation node) {
    return new ast.MethodInvocation(
        build(node.function),
        callName,
        buildArgumentsForInvocation(node),
        scope.resolveInterfaceFunctionCallOnType(node.function.staticType));
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    switch (ElementKind.of(node.prefix.staticElement)) {
      case ElementKind.CLASS:
      case ElementKind.LIBRARY:
      case ElementKind.PREFIX:
      case ElementKind.IMPORT:
        if (node.identifier.staticElement != null) {
          // Should be resolved to a static access.
          // Do not invoke 'build', because the identifier should be seen as a
          // left-hand value or an expression depending on the context.
          return visitSimpleIdentifier(node.identifier);
        }
        // Unresolved access on a class or library.
        return scope.unresolvedAccess(node.identifier.name);

      case ElementKind.DYNAMIC:
      case ElementKind.FUNCTION_TYPE_ALIAS:
      case ElementKind.TYPE_PARAMETER:
      // TODO: Check with the spec to see exactly when a type literal can be
      // used in a property access without surrounding parentheses.
      // For now, just fall through to the property access case.

      case ElementKind.FIELD:
      case ElementKind.TOP_LEVEL_VARIABLE:
      case ElementKind.FUNCTION:
      case ElementKind.METHOD:
      case ElementKind.GETTER:
      case ElementKind.SETTER:
      case ElementKind.LOCAL_VARIABLE:
      case ElementKind.PARAMETER:
      case ElementKind.ERROR:
        Element element = node.identifier.staticElement;
        Element auxiliary = node.identifier.auxiliaryElements?.staticElement;
        return PropertyAccessor.make(
            build(node.prefix),
            scope.buildName(node.identifier),
            scope.resolveInterfaceGet(element, auxiliary),
            scope.resolveInterfaceSet(element, auxiliary));

      case ElementKind.UNIVERSE:
      case ElementKind.NAME:
      case ElementKind.CONSTRUCTOR:
      case ElementKind.EXPORT:
      case ElementKind.LABEL:
      default:
        return scope.internalError(
            'Unexpected element kind: ${node.prefix.staticElement}');
    }
  }

  bool isStatic(Element element) {
    if (element is ClassMemberElement) {
      return element.isStatic || element.enclosingElement == null;
    }
    if (element is PropertyAccessorElement) {
      return element.isStatic || element.enclosingElement == null;
    }
    if (element is FunctionElement) {
      return element.isStatic;
    }
    return false;
  }

  visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    switch (ElementKind.of(element)) {
      case ElementKind.CLASS:
      case ElementKind.DYNAMIC:
      case ElementKind.FUNCTION_TYPE_ALIAS:
      case ElementKind.TYPE_PARAMETER:
        return new ast.TypeLiteral(scope.buildTypeAnnotation(node));

      case ElementKind.ERROR: // This covers the case where nothing was found.
        if (!scope.allowThis) {
          return scope.unresolvedAccess(node.name);
        }
        return PropertyAccessor.make(
            scope.buildThis(), scope.buildName(node), null, null);

      case ElementKind.FIELD:
      case ElementKind.TOP_LEVEL_VARIABLE:
      case ElementKind.GETTER:
      case ElementKind.SETTER:
      case ElementKind.METHOD:
        Element auxiliary = node.auxiliaryElements?.staticElement;
        if (isStatic(element)) {
          return scope.staticAccess(node.name, element, auxiliary);
        }
        if (!scope.allowThis) {
          return scope.unresolvedAccess(node.name);
        }
        return PropertyAccessor.make(
            scope.buildThis(),
            scope.buildName(node),
            scope.resolveInterfaceGet(element, auxiliary),
            scope.resolveInterfaceSet(element, auxiliary));

      case ElementKind.FUNCTION:
        FunctionElement function = element;
        if (isTopLevelFunction(function)) {
          return scope.staticAccess(node.name, function);
        }
        if (function == function.library.loadLibraryFunction) {
          return scope.unsupportedFeature('Deferred loading');
        }
        return new VariableAccessor(
            scope.getVariableReference(function), null, ast.TreeNode.noOffset);

      case ElementKind.LOCAL_VARIABLE:
      case ElementKind.PARAMETER:
        VariableElement variable = element;
        var type = identical(node.staticType, variable.type)
            ? null
            : scope.buildType(node.staticType);
        return new VariableAccessor(
            scope.getVariableReference(element), type, ast.TreeNode.noOffset);

      case ElementKind.IMPORT:
      case ElementKind.LIBRARY:
      case ElementKind.PREFIX:
        return scope.emitCompileTimeError(
            CompileTimeErrorCode.PREFIX_IDENTIFIER_NOT_FOLLOWED_BY_DOT,
            [node.name]);

      case ElementKind.COMPILATION_UNIT:
      case ElementKind.CONSTRUCTOR:
      case ElementKind.EXPORT:
      case ElementKind.LABEL:
      case ElementKind.UNIVERSE:
      case ElementKind.NAME:
      default:
        return scope.internalError('Unexpected element kind: $element');
    }
  }

  visitIndexExpression(IndexExpression node) {
    Element element = node.staticElement;
    Element auxiliary = node.auxiliaryElements?.staticElement;
    if (node.isCascaded) {
      return IndexAccessor.make(
          makeCascadeReceiver(),
          build(node.index),
          scope.resolveInterfaceIndexGet(element, auxiliary),
          scope.resolveInterfaceIndexSet(element, auxiliary));
    } else if (node.target is SuperExpression) {
      scope.addTransformerFlag(TransformerFlag.superCalls);
      return new SuperIndexAccessor(
          build(node.index),
          scope.resolveConcreteIndexGet(element, auxiliary),
          scope.resolveConcreteIndexSet(element, auxiliary),
          ast.TreeNode.noOffset);
    } else {
      return IndexAccessor.make(
          build(node.target),
          build(node.index),
          scope.resolveInterfaceIndexGet(element, auxiliary),
          scope.resolveInterfaceIndexSet(element, auxiliary));
    }
  }

  /// Follows any number of redirecting factories, returning the effective
  /// target or `null` if a cycle is found.
  ///
  /// The returned element is a [Member] if the type arguments to the effective
  /// target are different from the original arguments.
  ConstructorElement getEffectiveFactoryTarget(ConstructorElement element) {
    ConstructorElement anchor = null;
    int n = 1;
    while (element.isFactory && element.redirectedConstructor != null) {
      element = element.redirectedConstructor;
      var base = ReferenceScope.getBaseElement(element);
      if (base == anchor) return null; // Cyclic redirection.
      if (n & ++n == 0) {
        anchor = base;
      }
    }
    return element;
  }

  /// Forces the list of type arguments to have the specified length. If the
  /// length was changed, all type arguments are changed to `dynamic`.
  void _coerceTypeArgumentArity(List<ast.DartType> typeArguments, int arity) {
    if (typeArguments.length != arity) {
      typeArguments.length = arity;
      typeArguments.fillRange(0, arity, const ast.DynamicType());
    }
  }

  ast.Expression visitInstanceCreationExpression(
      InstanceCreationExpression node) {
    ConstructorElement element = node.staticElement;
    ClassElement classElement = element?.enclosingElement;
    List<ast.DartType> inferTypeArguments() {
      var inferredType = scope.getInferredType(node);
      if (inferredType is ast.InterfaceType) {
        return inferredType.typeArguments.toList();
      }
      int numberOfTypeArguments =
          classElement == null ? 0 : classElement.typeParameters.length;
      return new List<ast.DartType>.filled(
          numberOfTypeArguments, const ast.DynamicType(),
          growable: true);
    }

    var arguments = buildArguments(node.argumentList,
        explicitTypeArguments: node.constructorName.type.typeArguments,
        inferTypeArguments: inferTypeArguments);
    ast.Expression noSuchMethodError() {
      return node.isConst
          ? scope.emitInvalidConstant()
          : scope.buildThrowNoSuchMethodError(
              new ast.NullLiteral(), '${node.constructorName}', arguments,
              candidateTarget: element);
    }

    if (element == null) {
      return noSuchMethodError();
    }
    assert(classElement != null);
    var redirect = getEffectiveFactoryTarget(element);
    if (redirect == null) {
      return scope.buildThrowCompileTimeError(
          CompileTimeErrorCode.RECURSIVE_FACTORY_REDIRECT.message);
    }
    if (redirect != element) {
      ast.InterfaceType returnType = scope.buildType(redirect.returnType);
      arguments.types
        ..clear()
        ..addAll(returnType.typeArguments);
      element = redirect;
      classElement = element.enclosingElement;
    }
    element = ReferenceScope.getBaseElement(element);
    if (node.isConst && !element.isConst) {
      return scope
          .emitInvalidConstant(CompileTimeErrorCode.CONST_WITH_NON_CONST);
    }
    if (classElement.isEnum) {
      return scope.emitCompileTimeError(CompileTimeErrorCode.INSTANTIATE_ENUM);
    }
    _coerceTypeArgumentArity(
        arguments.types, classElement.typeParameters.length);
    if (element.isFactory) {
      ast.Member target = scope.resolveConcreteMethod(element);
      if (target is ast.Procedure &&
          scope.areArgumentsCompatible(element, arguments)) {
        return new ast.StaticInvocation(target, arguments,
            isConst: node.isConst);
      } else {
        return noSuchMethodError();
      }
    }
    if (classElement.isAbstract) {
      return node.isConst
          ? scope.emitInvalidConstant()
          : scope.buildThrowAbstractClassInstantiationError(classElement.name);
    }
    ast.Constructor constructor = scope.resolveConstructor(element);
    if (constructor != null &&
        scope.areArgumentsCompatible(element, arguments)) {
      return new ast.ConstructorInvocation(constructor, arguments,
          isConst: node.isConst);
    } else {
      return noSuchMethodError();
    }
  }

  ast.Expression visitIsExpression(IsExpression node) {
    if (node.notOperator != null) {
      // Put offset on the IsExpression for "is!" cases:
      // As it is wrapped in a not, it won't get an offset otherwise.
      return new ast.Not(new ast.IsExpression(
          build(node.expression), scope.buildTypeAnnotation(node.type))
        ..fileOffset = _getOffset(node));
    } else {
      return new ast.IsExpression(
          build(node.expression), scope.buildTypeAnnotation(node.type));
    }
  }

  /// Emit a method invocation, either as a direct call `o.f(x)` or decomposed
  /// into a getter and function invocation `o.f.call(x)`.
  ast.Expression buildDecomposableMethodInvocation(ast.Expression receiver,
      ast.Name name, ast.Arguments arguments, Element targetElement) {
    // Try to emit a typed call to an interface method.
    ast.Procedure targetMethod = scope.resolveInterfaceMethod(targetElement);
    if (targetMethod != null) {
      return new ast.MethodInvocation(receiver, name, arguments, targetMethod);
    }
    // Try to emit a typed call to getter or field and call the returned
    // function.
    ast.Member targetGetter = scope.resolveInterfaceGet(targetElement, null);
    if (targetGetter != null) {
      return new ast.MethodInvocation(
          new ast.PropertyGet(receiver, name, targetGetter),
          callName,
          arguments,
          scope.resolveInterfaceFunctionCall(targetElement));
    }
    // Emit a dynamic call.
    return new ast.MethodInvocation(receiver, name, arguments);
  }

  ast.Expression visitMethodInvocation(MethodInvocation node) {
    Element element = node.methodName.staticElement;
    if (element != null && element == element.library?.loadLibraryFunction) {
      return scope.unsupportedFeature('Deferred loading');
    }
    var target = node.target;
    if (node.isCascaded) {
      return buildDecomposableMethodInvocation(
          makeCascadeReceiver(),
          scope.buildName(node.methodName),
          buildArgumentsForInvocation(node),
          element);
    } else if (target is SuperExpression) {
      scope.addTransformerFlag(TransformerFlag.superCalls);
      return new ast.SuperMethodInvocation(
          scope.buildName(node.methodName),
          buildArgumentsForInvocation(node),
          scope.resolveConcreteMethod(element));
    } else if (isLocal(element)) {
      // Set the offset directly: Normally the offset is at the start of the
      // method, but in this case, because we insert a '.call', we want it at
      // the end instead.
      return new ast.MethodInvocation(
          new ast.VariableGet(scope.getVariableReference(element)),
          callName,
          buildArgumentsForInvocation(node),
          scope.resolveInterfaceFunctionCall(element))
        ..fileOffset = node.methodName.end;
    } else if (isStaticMethod(element)) {
      var method = scope.resolveConcreteMethod(element);
      var arguments = buildArgumentsForInvocation(node);
      if (method == null || !scope.areArgumentsCompatible(element, arguments)) {
        return scope.buildThrowNoSuchMethodError(
            new ast.NullLiteral(), node.methodName.name, arguments,
            candidateTarget: element);
      }
      return new ast.StaticInvocation(method, arguments);
    } else if (isStaticVariableOrGetter(element)) {
      var method = scope.resolveConcreteGet(element, null);
      if (method == null) {
        return scope.buildThrowNoSuchMethodError(
            new ast.NullLiteral(), node.methodName.name, new ast.Arguments([]),
            candidateTarget: element);
      }
      // Set the offset directly: Normally the offset is at the start of the
      // method, but in this case, because we insert a '.call', we want it at
      // the end instead.
      return new ast.MethodInvocation(
          new ast.StaticGet(method),
          callName,
          buildArgumentsForInvocation(node),
          scope.resolveInterfaceFunctionCall(element))
        ..fileOffset = node.methodName.end;
    } else if (target == null && !scope.allowThis ||
        target is Identifier && target.staticElement is ClassElement ||
        target is Identifier && target.staticElement is PrefixElement) {
      return scope.buildThrowNoSuchMethodError(new ast.NullLiteral(),
          node.methodName.name, buildArgumentsForInvocation(node),
          candidateTarget: element);
    } else if (target == null) {
      return buildDecomposableMethodInvocation(
          scope.buildThis(),
          scope.buildName(node.methodName),
          buildArgumentsForInvocation(node),
          element);
    } else if (node.operator.value() == '?.') {
      var receiver = makeOrReuseVariable(build(target));
      return makeLet(
          receiver,
          new ast.ConditionalExpression(
              buildIsNull(new ast.VariableGet(receiver)),
              new ast.NullLiteral(),
              buildDecomposableMethodInvocation(
                  new ast.VariableGet(receiver),
                  scope.buildName(node.methodName),
                  buildArgumentsForInvocation(node),
                  element)
                ..fileOffset = node.methodName.offset,
              scope.buildType(node.staticType)));
    } else {
      return buildDecomposableMethodInvocation(
          build(node.target),
          scope.buildName(node.methodName),
          buildArgumentsForInvocation(node),
          element);
    }
  }

  ast.Expression visitNamedExpression(NamedExpression node) {
    return scope.internalError('Unexpected named expression');
  }

  ast.Expression visitParenthesizedExpression(ParenthesizedExpression node) {
    return build(node.expression);
  }

  bool isInVoidContext(Expression node) {
    AstNode parent = node.parent;
    return parent is ForStatement &&
            (parent.updaters.contains(node) || parent.initialization == node) ||
        parent is ExpressionStatement ||
        parent is ExpressionFunctionBody && scope.bodyHasVoidReturn(parent);
  }

  ast.Expression visitPostfixExpression(PostfixExpression node) {
    String operator = node.operator.value();
    switch (operator) {
      case '++':
      case '--':
        var leftHand = buildLeftHandValue(node.operand);
        var binaryOperator = new ast.Name(operator[0]);
        return leftHand.buildPostfixIncrement(binaryOperator,
            offset: node.operator.offset,
            voidContext: isInVoidContext(node),
            interfaceTarget: scope.resolveInterfaceMethod(node.staticElement));

      default:
        return scope.internalError('Invalid postfix operator $operator');
    }
  }

  ast.Expression visitPrefixExpression(PrefixExpression node) {
    String operator = node.operator.value();
    switch (operator) {
      case '-':
      case '~':
        var name = new ast.Name(operator == '-' ? 'unary-' : '~');
        if (node.operand is SuperExpression) {
          scope.addTransformerFlag(TransformerFlag.superCalls);
          return new ast.SuperMethodInvocation(name, new ast.Arguments.empty(),
              scope.resolveConcreteMethod(node.staticElement));
        }
        return new ast.MethodInvocation(
            build(node.operand),
            name,
            new ast.Arguments.empty(),
            scope.resolveInterfaceMethod(node.staticElement));

      case '!':
        return new ast.Not(build(node.operand));

      case '++':
      case '--':
        var leftHand = buildLeftHandValue(node.operand);
        var binaryOperator = new ast.Name(operator[0]);
        return leftHand.buildPrefixIncrement(binaryOperator,
            offset: node.offset,
            interfaceTarget: scope.resolveInterfaceMethod(node.staticElement));

      default:
        return scope.internalError('Invalid prefix operator $operator');
    }
  }

  visitPropertyAccess(PropertyAccess node) {
    Element element = node.propertyName.staticElement;
    Element auxiliary = node.propertyName.auxiliaryElements?.staticElement;
    var getter = scope.resolveInterfaceGet(element, auxiliary);
    var setter = scope.resolveInterfaceSet(element, auxiliary);
    Expression target = node.target;
    if (node.isCascaded) {
      return PropertyAccessor.make(makeCascadeReceiver(),
          scope.buildName(node.propertyName), getter, setter);
    } else if (node.target is SuperExpression) {
      scope.addTransformerFlag(TransformerFlag.superCalls);
      return new SuperPropertyAccessor(
          scope.buildName(node.propertyName),
          scope.resolveConcreteGet(element, auxiliary),
          scope.resolveConcreteSet(element, auxiliary),
          ast.TreeNode.noOffset);
    } else if (target is Identifier && target.staticElement is ClassElement) {
      // Note that this case also covers null-aware static access on a class,
      // which is equivalent to a regular static access.
      return scope.staticAccess(node.propertyName.name, element, auxiliary);
    } else if (node.operator.value() == '?.') {
      return new NullAwarePropertyAccessor(
          build(target),
          scope.buildName(node.propertyName),
          getter,
          setter,
          scope.buildType(node.staticType),
          ast.TreeNode.noOffset);
    } else {
      return PropertyAccessor.make(
          build(target), scope.buildName(node.propertyName), getter, setter);
    }
  }

  ast.Expression visitRethrowExpression(RethrowExpression node) {
    return new ast.Rethrow();
  }

  ast.Expression visitSuperExpression(SuperExpression node) {
    return scope
        .emitCompileTimeError(CompileTimeErrorCode.SUPER_IN_INVALID_CONTEXT);
  }

  ast.Expression visitThisExpression(ThisExpression node) {
    return scope.buildThis();
  }

  ast.Expression visitThrowExpression(ThrowExpression node) {
    return new ast.Throw(build(node.expression));
  }

  ast.Expression visitListLiteral(ListLiteral node) {
    ast.DartType type = node.typeArguments?.arguments?.isNotEmpty ?? false
        ? scope.buildTypeAnnotation(node.typeArguments.arguments[0])
        : scope.getInferredTypeArgument(node, 0);
    return new ast.ListLiteral(node.elements.map(build).toList(),
        typeArgument: type, isConst: node.constKeyword != null);
  }

  ast.Expression visitMapLiteral(MapLiteral node) {
    ast.DartType key, value;
    if (node.typeArguments != null && node.typeArguments.arguments.length > 1) {
      key = scope.buildTypeAnnotation(node.typeArguments.arguments[0]);
      value = scope.buildTypeAnnotation(node.typeArguments.arguments[1]);
    } else {
      key = scope.getInferredTypeArgument(node, 0);
      value = scope.getInferredTypeArgument(node, 1);
    }
    return new ast.MapLiteral(node.entries.map(buildMapEntry).toList(),
        keyType: key, valueType: value, isConst: node.constKeyword != null);
  }

  ast.MapEntry buildMapEntry(MapLiteralEntry node) {
    return new ast.MapEntry(build(node.key), build(node.value));
  }

  ast.Expression visitExpression(Expression node) {
    return scope.internalError('Unhandled expression ${node.runtimeType}');
  }
}

class StringLiteralPartBuilder extends GeneralizingAstVisitor<Null> {
  final ExpressionScope scope;
  final List<ast.Expression> output;
  StringLiteralPartBuilder(this.scope, this.output);

  void build(Expression node) {
    node.accept(this);
  }

  void buildInterpolationElement(InterpolationElement node) {
    node.accept(this);
  }

  visitSimpleStringLiteral(SimpleStringLiteral node) {
    output.add(new ast.StringLiteral(node.value));
  }

  visitAdjacentStrings(AdjacentStrings node) {
    node.strings.forEach(build);
  }

  visitStringInterpolation(StringInterpolation node) {
    node.elements.forEach(buildInterpolationElement);
  }

  visitInterpolationString(InterpolationString node) {
    output.add(new ast.StringLiteral(node.value));
  }

  visitInterpolationExpression(InterpolationExpression node) {
    output.add(scope.buildExpression(node.expression));
  }
}

class TypeAnnotationBuilder extends GeneralizingAstVisitor<ast.DartType> {
  final TypeScope scope;

  TypeAnnotationBuilder(this.scope);

  ast.DartType build(AstNode node) {
    return node.accept(this);
  }

  List<ast.DartType> buildList(Iterable<AstNode> node) {
    return node.map(build).toList();
  }

  /// Replace unbound type variables in [type] with 'dynamic' and convert
  /// to an [ast.DartType].
  ast.DartType buildClosedTypeFromDartType(DartType type) {
    return convertType(type, <TypeParameterElement>[]);
  }

  /// Convert to an [ast.DartType] and keep type variables.
  ast.DartType buildFromDartType(DartType type) {
    return convertType(type, null);
  }

  /// True if [parameter] should not be reified, because spec mode does not
  /// currently reify generic method type parameters.
  bool isUnreifiedTypeParameter(TypeParameterElement parameter) {
    return !scope.strongMode && parameter.enclosingElement is! ClassElement;
  }

  /// Converts [type] to an [ast.DartType], while replacing unbound type
  /// variables with 'dynamic'.
  ///
  /// If [boundVariables] is null, no type variables are replaced, otherwise all
  /// type variables except those in [boundVariables] are replaced.  In other
  /// words, it represents the bound variables, or "all variables" if omitted.
  ast.DartType convertType(
      DartType type, List<TypeParameterElement> boundVariables) {
    if (type is TypeParameterType) {
      if (isUnreifiedTypeParameter(type.element)) {
        return const ast.DynamicType();
      }
      if (boundVariables == null || boundVariables.contains(type)) {
        var typeParameter = scope.tryGetTypeParameterReference(type.element);
        if (typeParameter == null) {
          // The analyzer sometimes gives us a type parameter that was not
          // bound anywhere.  Make sure we do not emit a dangling reference.
          if (type.element.bound != null) {
            return convertType(type.element.bound, []);
          }
          return const ast.DynamicType();
        }
        if (!scope.allowClassTypeParameters &&
            typeParameter.parent is ast.Class) {
          return const ast.InvalidType();
        }
        return new ast.TypeParameterType(typeParameter);
      } else {
        return const ast.DynamicType();
      }
    } else if (type is InterfaceType) {
      var classNode = scope.getClassReference(type.element);
      if (type.typeArguments.length == 0) {
        return classNode.rawType;
      }
      if (type.typeArguments.length != classNode.typeParameters.length) {
        log.warning('Type parameter arity error in $type');
        return const ast.InvalidType();
      }
      return new ast.InterfaceType(
          classNode, convertTypeList(type.typeArguments, boundVariables));
    } else if (type is FunctionType) {
      // TODO: Avoid infinite recursion in case of illegal circular typedef.
      boundVariables?.addAll(type.typeParameters);
      var positionals =
          concatenate(type.normalParameterTypes, type.optionalParameterTypes);
      var result = new ast.FunctionType(
          convertTypeList(positionals, boundVariables),
          convertType(type.returnType, boundVariables),
          typeParameters:
              convertTypeParameterList(type.typeFormals, boundVariables),
          namedParameters:
              convertTypeMap(type.namedParameterTypes, boundVariables),
          requiredParameterCount: type.normalParameterTypes.length);
      boundVariables?.removeRange(
          boundVariables.length - type.typeParameters.length,
          boundVariables.length);
      return result;
    } else if (type.isUndefined) {
      log.warning('Unresolved type found in ${scope.location}');
      return const ast.InvalidType();
    } else if (type.isVoid) {
      return const ast.VoidType();
    } else if (type.isDynamic) {
      return const ast.DynamicType();
    } else {
      log.severe('Unexpected DartType: $type');
      return const ast.InvalidType();
    }
  }

  static Iterable<E> concatenate<E>(Iterable<E> x, Iterable<E> y) =>
      <Iterable<E>>[x, y].expand((z) => z);

  ast.TypeParameter convertTypeParameter(TypeParameterElement typeParameter,
      List<TypeParameterElement> boundVariables) {
    return scope.makeTypeParameter(typeParameter,
        bound: typeParameter.bound == null
            ? scope.defaultTypeParameterBound
            : convertType(typeParameter.bound, boundVariables));
  }

  List<ast.TypeParameter> convertTypeParameterList(
      Iterable<TypeParameterElement> typeParameters,
      List<TypeParameterElement> boundVariables) {
    if (typeParameters.isEmpty) return const <ast.TypeParameter>[];
    return typeParameters
        .map((tp) => convertTypeParameter(tp, boundVariables))
        .toList();
  }

  List<ast.DartType> convertTypeList(
      Iterable<DartType> types, List<TypeParameterElement> boundVariables) {
    if (types.isEmpty) return const <ast.DartType>[];
    return types.map((t) => convertType(t, boundVariables)).toList();
  }

  List<ast.NamedType> convertTypeMap(
      Map<String, DartType> types, List<TypeParameterElement> boundVariables) {
    if (types.isEmpty) return const <ast.NamedType>[];
    List<ast.NamedType> result = <ast.NamedType>[];
    types.forEach((name, type) {
      result.add(new ast.NamedType(name, convertType(type, boundVariables)));
    });
    sortAndRemoveDuplicates(result);
    return result;
  }

  ast.DartType visitSimpleIdentifier(SimpleIdentifier node) {
    Element element = node.staticElement;
    switch (ElementKind.of(element)) {
      case ElementKind.CLASS:
        return scope.getClassReference(element).rawType;

      case ElementKind.DYNAMIC:
        return const ast.DynamicType();

      case ElementKind.FUNCTION_TYPE_ALIAS:
        FunctionTypeAliasElement functionType = element;
        return buildClosedTypeFromDartType(functionType.type);

      case ElementKind.TYPE_PARAMETER:
        var typeParameter = scope.getTypeParameterReference(element);
        if (!scope.allowClassTypeParameters &&
            typeParameter.parent is ast.Class) {
          return const ast.InvalidType();
        }
        if (isUnreifiedTypeParameter(element)) {
          return const ast.DynamicType();
        }
        return new ast.TypeParameterType(typeParameter);

      case ElementKind.COMPILATION_UNIT:
      case ElementKind.CONSTRUCTOR:
      case ElementKind.EXPORT:
      case ElementKind.IMPORT:
      case ElementKind.LABEL:
      case ElementKind.LIBRARY:
      case ElementKind.PREFIX:
      case ElementKind.UNIVERSE:
      case ElementKind.ERROR: // This covers the case where nothing was found.
      case ElementKind.FIELD:
      case ElementKind.TOP_LEVEL_VARIABLE:
      case ElementKind.GETTER:
      case ElementKind.SETTER:
      case ElementKind.METHOD:
      case ElementKind.LOCAL_VARIABLE:
      case ElementKind.PARAMETER:
      case ElementKind.FUNCTION:
      case ElementKind.NAME:
      default:
        log.severe('Invalid type annotation: $element');
        return const ast.InvalidType();
    }
  }

  visitPrefixedIdentifier(PrefixedIdentifier node) {
    return build(node.identifier);
  }

  visitTypeName(TypeName node) {
    return buildFromDartType(node.type);
  }

  visitNode(AstNode node) {
    log.severe('Unexpected type annotation: $node');
    return new ast.InvalidType();
  }
}

class InitializerBuilder extends GeneralizingAstVisitor<ast.Initializer> {
  final MemberScope scope;

  InitializerBuilder(this.scope);

  ast.Initializer build(ConstructorInitializer node) {
    return node.accept(this);
  }

  visitConstructorFieldInitializer(ConstructorFieldInitializer node) {
    var target = scope.resolveField(node.fieldName.staticElement);
    if (target == null) {
      return new ast.InvalidInitializer();
    }
    return new ast.FieldInitializer(
        target, scope.buildExpression(node.expression));
  }

  visitSuperConstructorInvocation(SuperConstructorInvocation node) {
    var target = scope.resolveConstructor(node.staticElement);
    if (target == null) {
      return new ast.InvalidInitializer();
    }
    scope.addTransformerFlag(TransformerFlag.superCalls);
    return new ast.SuperInitializer(
        target, scope._expressionBuilder.buildArguments(node.argumentList));
  }

  visitRedirectingConstructorInvocation(RedirectingConstructorInvocation node) {
    var target = scope.resolveConstructor(node.staticElement);
    if (target == null) {
      return new ast.InvalidInitializer();
    }
    return new ast.RedirectingInitializer(
        target, scope._expressionBuilder.buildArguments(node.argumentList));
  }

  visitNode(AstNode node) {
    log.severe('Unexpected constructor initializer: ${node.runtimeType}');
    return new ast.InvalidInitializer();
  }
}

/// Brings a class from hierarchy level to body level.
//
// TODO(asgerf): Error recovery during class construction is currently handled
//   locally, but this can in theory break global invariants in the kernel IR.
//   To safely compile code with compile-time errors, we may need a recovery
//   pass to enforce all kernel invariants before it is given to the backend.
class ClassBodyBuilder extends GeneralizingAstVisitor<Null> {
  final ClassScope scope;
  final ExpressionScope annotationScope;
  final ast.Class currentClass;
  final ClassElement element;
  ast.Library get currentLibrary => currentClass.enclosingLibrary;

  ClassBodyBuilder(
      ReferenceLevelLoader loader, ast.Class currentClass, this.element)
      : this.currentClass = currentClass,
        scope = new ClassScope(loader, currentClass.enclosingLibrary),
        annotationScope =
            new ExpressionScope(loader, currentClass.enclosingLibrary);

  void build(CompilationUnitMember node) {
    if (node == null) {
      buildBrokenClass();
      return;
    }
    node.accept(this);
  }

  /// Builds an empty class for broken classes that have no AST.
  ///
  /// This should only be used to recover from a compile-time error.
  void buildBrokenClass() {
    currentClass.name = element.name;
    currentClass.supertype = scope.getRootClassReference().asRawSupertype;
    currentClass.constructors.add(
        new ast.Constructor(new ast.FunctionNode(new ast.InvalidStatement()))
          ..fileOffset = element.nameOffset);
  }

  void addAnnotations(List<Annotation> annotations) {
    // Class type parameters are not in scope in the annotation list.
    for (var annotation in annotations) {
      currentClass.addAnnotation(annotationScope.buildAnnotation(annotation));
    }
  }

  void _buildMemberBody(ast.Member member, Element element, AstNode node) {
    new MemberBodyBuilder(scope.loader, member, element).build(node);
  }

  /// True if the given class member should not be emitted, and does not
  /// correspond to any Kernel member.
  ///
  /// This is true for redirecting factories with a resolved target. These are
  /// always bypassed at the call site.
  bool _isIgnoredMember(ClassMember node) {
    if (node is ConstructorDeclaration && node.factoryKeyword != null) {
      var element = resolutionMap.elementDeclaredByConstructorDeclaration(node);
      return element.redirectedConstructor != null &&
          (element.isSynthetic || scope.loader.ignoreRedirectingFactories);
    } else {
      return false;
    }
  }

  visitClassDeclaration(ClassDeclaration node) {
    addAnnotations(node.metadata);
    ast.Class classNode = currentClass;
    assert(classNode.members.isEmpty); // All members will be added here.

    bool foundConstructor = false;
    for (var member in node.members) {
      if (_isIgnoredMember(member)) continue;
      if (member is FieldDeclaration) {
        for (var variable in member.fields.variables) {
          // Ignore fields inserted through error recovery.
          if (variable.isSynthetic || variable.length == 0) continue;
          var field = scope.getMemberReference(variable.element);
          classNode.addMember(field);
          _buildMemberBody(field, variable.element, variable);
        }
      } else {
        var memberNode = scope.getMemberReference(member.element);
        classNode.addMember(memberNode);
        _buildMemberBody(memberNode, member.element, member);
        if (member is ConstructorDeclaration) {
          foundConstructor = true;
        }
      }
    }

    if (!foundConstructor) {
      var defaultConstructor = scope.findDefaultConstructor(node.element);
      if (defaultConstructor != null) {
        assert(defaultConstructor.enclosingElement == node.element);
        if (!defaultConstructor.isSynthetic) {
          throw 'Non-synthetic default constructor not in list of members. '
              '$node $element $defaultConstructor';
        }
        var memberNode = scope.getMemberReference(defaultConstructor);
        classNode.addMember(memberNode);
        buildDefaultConstructor(memberNode, defaultConstructor);
      }
    }

    addDefaultInstanceFieldInitializers(classNode);
  }

  void buildDefaultConstructor(
      ast.Constructor constructor, ConstructorElement element) {
    var function = constructor.function;
    function.body = new ast.EmptyStatement()..parent = function;
    var class_ = element.enclosingElement;
    if (class_.supertype != null) {
      // DESIGN TODO: If the super class is a mixin application, we will link to
      // a constructor not in the immediate super class.  This is a problem due
      // to the fact that mixed-in fields come with initializers which need to
      // be executed by a constructor.  The mixin transformer takes care of
      // this by making forwarding constructors and the super initializers will
      // be rewritten to use them (see `transformations/mixin_full_resolution`).
      var superConstructor =
          scope.findDefaultConstructor(class_.supertype.element);
      var target = scope.resolveConstructor(superConstructor);
      if (target == null) {
        constructor.initializers
            .add(new ast.InvalidInitializer()..parent = constructor);
      } else {
        var arguments = new ast.Arguments.empty();
        constructor.initializers.add(
            new ast.SuperInitializer(target, arguments)..parent = constructor);
      }
    }
  }

  /// Adds initializers to instance fields that are have no initializer and are
  /// not initialized by all constructors in the class.
  void addDefaultInstanceFieldInitializers(ast.Class node) {
    List<ast.Field> uninitializedFields = new List<ast.Field>();
    for (var field in node.fields) {
      if (field.initializer != null || field.isStatic) continue;
      uninitializedFields.add(field);
    }
    if (uninitializedFields.isEmpty) return;
    constructorLoop:
    for (var constructor in node.constructors) {
      var remainingFields = uninitializedFields.toSet();
      for (var initializer in constructor.initializers) {
        if (initializer is ast.FieldInitializer) {
          remainingFields.remove(initializer.field);
        } else if (initializer is ast.RedirectingInitializer) {
          // The target constructor will be checked in another iteration.
          continue constructorLoop;
        }
      }
      for (var field in remainingFields) {
        if (field.initializer == null) {
          field.initializer = new ast.NullLiteral()..parent = field;
        }
      }
    }
  }

  /// True for the `values` field of an `enum` class.
  static bool _isValuesField(FieldElement field) => field.name == 'values';

  /// True for the `index` field of an `enum` class.
  static bool _isIndexField(FieldElement field) => field.name == 'index';

  visitEnumDeclaration(EnumDeclaration node) {
    addAnnotations(node.metadata);
    ast.Class classNode = currentClass;

    var intType = scope.loader.getCoreClassReference('int').rawType;
    var indexFieldElement = element.fields.firstWhere(_isIndexField);
    ast.Field indexField = scope.getMemberReference(indexFieldElement);
    indexField.type = intType;
    classNode.addMember(indexField);

    var stringType = scope.loader.getCoreClassReference('String').rawType;
    ast.Field nameField = new ast.Field(
        new ast.Name('_name', scope.currentLibrary),
        type: stringType,
        isFinal: true,
        fileUri: classNode.fileUri);
    classNode.addMember(nameField);

    var indexParameter = new ast.VariableDeclaration('index', type: intType);
    var nameParameter = new ast.VariableDeclaration('name', type: stringType);
    var function = new ast.FunctionNode(new ast.EmptyStatement(),
        positionalParameters: [indexParameter, nameParameter]);
    var superConstructor = scope.loader.getRootClassConstructorReference();
    var constructor = new ast.Constructor(function,
        name: new ast.Name(''),
        isConst: true,
        initializers: [
          new ast.FieldInitializer(
              indexField, new ast.VariableGet(indexParameter)),
          new ast.FieldInitializer(
              nameField, new ast.VariableGet(nameParameter)),
          new ast.SuperInitializer(superConstructor, new ast.Arguments.empty())
        ])
      ..fileOffset = element.nameOffset;
    classNode.addMember(constructor);

    int index = 0;
    var enumConstantFields = <ast.Field>[];
    for (var constant in node.constants) {
      ast.Field field = scope.getMemberReference(constant.element);
      field.initializer = new ast.ConstructorInvocation(
          constructor,
          new ast.Arguments([
            new ast.IntLiteral(index),
            new ast.StringLiteral('${classNode.name}.${field.name.name}')
          ]),
          isConst: true)
        ..parent = field;
      field.type = classNode.rawType;
      classNode.addMember(field);
      ++index;
      enumConstantFields.add(field);
    }

    // Add the 'values' field.
    var valuesFieldElement = element.fields.firstWhere(_isValuesField);
    ast.Field valuesField = scope.getMemberReference(valuesFieldElement);
    var enumType = classNode.rawType;
    valuesField.type = new ast.InterfaceType(
        scope.loader.getCoreClassReference('List'), <ast.DartType>[enumType]);
    valuesField.initializer = new ast.ListLiteral(
        enumConstantFields.map(_makeStaticGet).toList(),
        isConst: true,
        typeArgument: enumType)
      ..parent = valuesField;
    classNode.addMember(valuesField);

    // Add the 'toString()' method.
    var body = new ast.ReturnStatement(
        new ast.DirectPropertyGet(new ast.ThisExpression(), nameField));
    var toStringFunction = new ast.FunctionNode(body, returnType: stringType);
    var toStringMethod = new ast.Procedure(
        new ast.Name('toString'), ast.ProcedureKind.Method, toStringFunction,
        fileUri: classNode.fileUri);
    classNode.addMember(toStringMethod);
  }

  visitClassTypeAlias(ClassTypeAlias node) {
    addAnnotations(node.metadata);
    assert(node.withClause != null && node.withClause.mixinTypes.isNotEmpty);
    ast.Class classNode = currentClass;
    for (var constructor in element.constructors) {
      var constructorNode = scope.getMemberReference(constructor);
      classNode.addMember(constructorNode);
      buildMixinConstructor(constructorNode, constructor);
    }
  }

  void buildMixinConstructor(
      ast.Constructor constructor, ConstructorElement element) {
    var function = constructor.function;
    function.body = new ast.EmptyStatement()..parent = function;
    // Call the corresponding constructor in super class.
    ClassElement classElement = element.enclosingElement;
    var targetConstructor = classElement.supertype.element.constructors
        .firstWhere((c) => c.name == element.name);
    var positionalArguments = constructor.function.positionalParameters
        .map(_makeVariableGet)
        .toList();
    var namedArguments = constructor.function.namedParameters
        .map(_makeNamedExpressionFrom)
        .toList();
    constructor.initializers.add(new ast.SuperInitializer(
        scope.getMemberReference(targetConstructor),
        new ast.Arguments(positionalArguments, named: namedArguments))
      ..parent = constructor);
  }

  visitNode(AstNode node) {
    throw 'Unsupported class declaration: ${node.runtimeType}';
  }
}

/// Brings a member from reference level to body level.
class MemberBodyBuilder extends GeneralizingAstVisitor<Null> {
  final MemberScope scope;
  final Element element;
  ast.Member get currentMember => scope.currentMember;

  MemberBodyBuilder(
      ReferenceLevelLoader loader, ast.Member member, this.element)
      : scope = new MemberScope(loader, member);

  void build(AstNode node) {
    if (node != null) {
      currentMember.fileEndOffset = node.endToken.offset;
      node.accept(this);
    } else {
      buildBrokenMember();
    }
  }

  /// Builds an empty member.
  ///
  /// This should only be used to recover from a compile-time error.
  void buildBrokenMember() {
    var member = currentMember;
    member.name = new ast.Name(element.name, scope.currentLibrary);
    if (member is ast.Procedure) {
      member.function = new ast.FunctionNode(new ast.InvalidStatement())
        ..parent = member;
    } else if (member is ast.Constructor) {
      member.function = new ast.FunctionNode(new ast.InvalidStatement())
        ..parent = member;
    }
  }

  void addAnnotations(List<Annotation> annotations) {
    for (var annotation in annotations) {
      currentMember.addAnnotation(scope.buildAnnotation(annotation));
    }
  }

  void handleNativeBody(FunctionBody body) {
    if (body is NativeFunctionBody) {
      currentMember.isExternal = true;
      currentMember.addAnnotation(new ast.ConstructorInvocation(
          scope.loader.getCoreClassConstructorReference('ExternalName',
              library: 'dart:_internal'),
          new ast.Arguments(<ast.Expression>[
            new ast.StringLiteral(body.stringLiteral.stringValue)
          ]),
          isConst: true));
    }
  }

  visitConstructorDeclaration(ConstructorDeclaration node) {
    if (node.factoryKeyword != null) {
      buildFactoryConstructor(node);
    } else {
      buildGenerativeConstructor(node);
    }
  }

  void buildGenerativeConstructor(ConstructorDeclaration node) {
    if (currentMember is! ast.Constructor) {
      buildBrokenMember();
      return;
    }
    addAnnotations(node.metadata);
    ast.Constructor constructor = currentMember;
    constructor.function = scope.buildFunctionNode(node.parameters, node.body,
        inferredReturnType: const ast.VoidType())
      ..parent = constructor;
    handleNativeBody(node.body);
    if (node.body is EmptyFunctionBody && !constructor.isExternal) {
      var function = constructor.function;
      function.body = new ast.EmptyStatement()..parent = function;
    }
    for (var parameter in node.parameters.parameterElements) {
      if (parameter is FieldFormalParameterElement) {
        ast.Initializer initializer;
        if (parameter.field == null) {
          initializer = new ast.LocalInitializer(
              new ast.VariableDeclaration.forValue(scope
                  .buildThrowCompileTimeErrorFromCode(
                      CompileTimeErrorCode.INITIALIZER_FOR_NON_EXISTENT_FIELD,
                      [parameter.name])));
        } else {
          initializer = new ast.FieldInitializer(
              scope.getMemberReference(parameter.field),
              new ast.VariableGet(scope.getVariableReference(parameter)));
        }
        constructor.initializers.add(initializer..parent = constructor);
      }
    }
    bool hasExplicitConstructorCall = false;
    for (var initializer in node.initializers) {
      var node = scope.buildInitializer(initializer);
      constructor.initializers.add(node..parent = constructor);
      if (node is ast.SuperInitializer || node is ast.RedirectingInitializer) {
        hasExplicitConstructorCall = true;
      }
    }
    ClassElement classElement = resolutionMap
        .elementDeclaredByConstructorDeclaration(node)
        .enclosingElement;
    if (classElement.supertype != null && !hasExplicitConstructorCall) {
      ConstructorElement targetElement =
          scope.findDefaultConstructor(classElement.supertype.element);
      ast.Constructor target = scope.resolveConstructor(targetElement);
      ast.Initializer initializer = target == null
          ? new ast.InvalidInitializer()
          : new ast.SuperInitializer(
              target, new ast.Arguments(<ast.Expression>[]));
      constructor.initializers.add(initializer..parent = constructor);
    } else {
      moveSuperInitializerLast(constructor);
    }
  }

  void buildFactoryConstructor(ConstructorDeclaration node) {
    if (currentMember is! ast.Procedure) {
      buildBrokenMember();
      return;
    }
    addAnnotations(node.metadata);
    ast.Procedure procedure = currentMember;
    ClassElement classElement = resolutionMap
        .elementDeclaredByConstructorDeclaration(node)
        .enclosingElement;
    ast.Class classNode = procedure.enclosingClass;
    var types = getFreshTypeParameters(classNode.typeParameters);
    for (int i = 0; i < classElement.typeParameters.length; ++i) {
      scope.localTypeParameters[classElement.typeParameters[i]] =
          types.freshTypeParameters[i];
    }
    var inferredReturnType = types.freshTypeParameters.isEmpty
        ? classNode.rawType
        : new ast.InterfaceType(
            classNode,
            types.freshTypeParameters
                .map(makeTypeParameterType)
                .toList(growable: false));
    var function = scope.buildFunctionNode(node.parameters, node.body,
        typeParameters: types.freshTypeParameters,
        inferredReturnType: inferredReturnType);
    procedure.function = function..parent = procedure;
    handleNativeBody(node.body);
    if (node.redirectedConstructor != null) {
      // Add a new synthetic field to [classNode] for representing factory
      // constructors. This is used by the new frontend engine to support
      // resolving source code.
      //
      // The synthetic field looks like this:
      //
      //     final _redirecting# = [c1, ..., cn];
      //
      // Where each c1 ... cn are an instance of [StaticGet] whose target is
      // the redirecting factory created above. The new frontend engine reads
      // this field and rewrites them.
      //
      // TODO(ahe): Generate the correct factory body instead. This requires
      // access to default values from other files, we'll probably never do
      // that in this file, and instead rely on the new compiler for this.
      var element = resolutionMap.elementDeclaredByConstructorDeclaration(node);
      assert(!element.isSynthetic);
      var expression;
      if (node.element.redirectedConstructor != null) {
        assert(!scope.loader.ignoreRedirectingFactories);
        ConstructorElement element = node.element.redirectedConstructor;
        while (element.isFactory && element.redirectedConstructor != null) {
          element = element.redirectedConstructor;
        }
        ast.Member target = scope.getMemberReference(element);
        assert(target != null);
        expression = new ast.Let(
            new ast.VariableDeclaration.forValue(new ast.StaticGet(target)),
            new ast.InvalidExpression());
        ast.Name constructors =
            new ast.Name("_redirecting#", scope.currentLibrary);
        ast.Field constructorsField;
        for (ast.Field field in classNode.fields) {
          if (field.name == constructors) {
            constructorsField = field;
            break;
          }
        }
        if (constructorsField == null) {
          ast.ListLiteral literal = new ast.ListLiteral(<ast.Expression>[]);
          constructorsField = new ast.Field(constructors,
              isStatic: true, initializer: literal, fileUri: classNode.fileUri)
            ..fileOffset = classNode.fileOffset;
          classNode.addMember(constructorsField);
        }
        ast.ListLiteral literal = constructorsField.initializer;
        literal.expressions.add(new ast.StaticGet(procedure)..parent = literal);
      } else {
        var name = node.redirectedConstructor.type.name.name;
        if (node.redirectedConstructor.name != null) {
          name += '.' + node.redirectedConstructor.name.name;
        }
        // TODO(asgerf): Sometimes a TypeError should be thrown.
        expression = scope.buildThrowNoSuchMethodError(
            new ast.NullLiteral(), name, new ast.Arguments.empty());
      }
      var function = procedure.function;
      function.body = new ast.ExpressionStatement(expression)
        ..parent = function;
    }
  }

  visitMethodDeclaration(MethodDeclaration node) {
    addAnnotations(node.metadata);
    ast.Procedure procedure = currentMember;
    procedure.function = scope.buildFunctionNode(node.parameters, node.body,
        returnType: node.returnType,
        inferredReturnType: scope.buildType(
            resolutionMap.elementDeclaredByMethodDeclaration(node).returnType),
        typeParameters: scope.buildOptionalTypeParameterList(
            node.typeParameters,
            strongModeOnly: true))
      ..parent = procedure;
    handleNativeBody(node.body);
  }

  visitVariableDeclaration(VariableDeclaration node) {
    addAnnotations(node.metadata);
    ast.Field field = currentMember;
    field.type = scope.buildType(
        resolutionMap.elementDeclaredByVariableDeclaration(node).type);
    if (node.initializer != null) {
      field.initializer = scope.buildTopLevelExpression(node.initializer)
        ..parent = field;
    } else if (field.isStatic) {
      // Add null initializer to static fields without an initializer.
      // For instance fields, this is handled when building the class.
      field.initializer = new ast.NullLiteral()..parent = field;
    }
  }

  visitFunctionDeclaration(FunctionDeclaration node) {
    addAnnotations(node.metadata);
    var function = node.functionExpression;
    ast.Procedure procedure = currentMember;
    procedure.function = scope.buildFunctionNode(
        function.parameters, function.body,
        returnType: node.returnType,
        typeParameters: scope.buildOptionalTypeParameterList(
            function.typeParameters,
            strongModeOnly: true))
      ..parent = procedure;
    handleNativeBody(function.body);
  }

  visitNode(AstNode node) {
    log.severe('Unexpected class or library member: $node');
  }
}

/// Internal exception thrown from the expression or statement builder when a
/// compilation error is found.
///
/// This is then caught at the function level to replace the entire function
/// body (or field initializer) with a throw.
class _CompilationError {
  String message;

  _CompilationError(this.message);
}

/// Constructor alias for [ast.TypeParameterType], use instead of a closure.
ast.DartType makeTypeParameterType(ast.TypeParameter parameter) {
  return new ast.TypeParameterType(parameter);
}

/// Constructor alias for [ast.VariableGet], use instead of a closure.
ast.VariableGet _makeVariableGet(ast.VariableDeclaration variable) {
  return new ast.VariableGet(variable);
}

/// Constructor alias for [ast.StaticGet], use instead of a closure.
ast.StaticGet _makeStaticGet(ast.Field field) {
  return new ast.StaticGet(field);
}

/// Create a named expression with the name and value of the given variable.
ast.NamedExpression _makeNamedExpressionFrom(ast.VariableDeclaration variable) {
  return new ast.NamedExpression(variable.name, new ast.VariableGet(variable));
}

/// A [StaticAccessor] that throws a NoSuchMethodError when a suitable target
/// could not be resolved.
class _StaticAccessor extends StaticAccessor {
  final ExpressionScope scope;
  final String name;

  _StaticAccessor(
      this.scope, this.name, ast.Member readTarget, ast.Member writeTarget)
      : super(readTarget, writeTarget, ast.TreeNode.noOffset);

  @override
  makeInvalidRead() {
    return scope.buildThrowNoSuchMethodError(
        new ast.NullLiteral(), name, new ast.Arguments([]));
  }

  @override
  makeInvalidWrite(ast.Expression value) {
    return scope.buildThrowNoSuchMethodError(
        new ast.NullLiteral(), name, new ast.Arguments([value]));
  }
}

bool isTopLevelFunction(Element element) {
  return element is FunctionElement &&
      element.enclosingElement is CompilationUnitElement;
}

bool isLocalFunction(Element element) {
  return element is FunctionElement &&
      element.enclosingElement is! CompilationUnitElement &&
      element.enclosingElement is! LibraryElement;
}

bool isLocal(Element element) {
  return isLocalFunction(element) ||
      element is LocalVariableElement ||
      element is ParameterElement;
}

bool isInstanceMethod(Element element) {
  return element is MethodElement && !element.isStatic;
}

bool isStaticMethod(Element element) {
  return element is MethodElement && element.isStatic ||
      isTopLevelFunction(element);
}

bool isStaticVariableOrGetter(Element element) {
  element = desynthesizeGetter(element);
  return element is FieldElement && element.isStatic ||
      element is TopLevelVariableElement;
}

Element desynthesizeGetter(Element element) {
  if (element == null || !element.isSynthetic) return element;
  if (element is PropertyAccessorElement) return element.variable;
  if (element is FieldElement) return element.getter;
  return element;
}

Element desynthesizeSetter(Element element) {
  if (element == null || !element.isSynthetic) return element;
  if (element is PropertyAccessorElement) return element.variable;
  if (element is FieldElement) return element.setter;
  return element;
}

void sortAndRemoveDuplicates<T extends Comparable<T>>(List<T> list) {
  list.sort();
  int deleted = 0;
  for (int i = 1; i < list.length; ++i) {
    var item = list[i];
    if (list[i - 1].compareTo(item) == 0) {
      ++deleted;
    } else if (deleted > 0) {
      list[i - deleted] = item;
    }
  }
  if (deleted > 0) {
    list.length -= deleted;
  }
}
