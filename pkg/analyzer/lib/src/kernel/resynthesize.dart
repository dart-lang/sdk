// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/standard_ast_factory.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/handle.dart';
import 'package:analyzer/src/dart/element/type.dart';
import 'package:analyzer/src/dart/resolver/scope.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:front_end/src/base/resolve_relative_uri.dart';
import 'package:front_end/src/base/source.dart';
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart' as kernel;
import 'package:front_end/src/fasta/kernel/redirecting_factory_body.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/type_algebra.dart' as kernel;
import 'package:kernel/type_environment.dart' as kernel;
import 'package:path/path.dart' as pathos;

/**
 * Object that can resynthesize analyzer [LibraryElement] from Kernel.
 */
class KernelResynthesizer implements ElementResynthesizer {
  final AnalysisContextImpl _analysisContext;
  final kernel.TypeEnvironment _types;
  final Map<String, kernel.Library> _kernelMap;
  final Map<String, bool> _libraryExistMap;
  final Map<String, LibraryElementImpl> _libraryMap = {};

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  /// The type provider for this resynthesizer.
  SummaryTypeProvider _typeProvider;

  KernelResynthesizer(this._analysisContext, this._types, this._kernelMap,
      this._libraryExistMap) {
    _buildTypeProvider();
    _analysisContext.typeProvider = _typeProvider;
  }

  @override
  AnalysisContext get context => _analysisContext;

  /**
   * Return `true` if strong mode analysis should be used.
   */
  bool get strongMode => _analysisContext.analysisOptions.strongMode;

  /**
   * Return the `Type` type.
   */
  DartType get typeType => getLibrary('dart:core').getType('Type').type;

  @override
  Element getElement(ElementLocation location) {
    List<String> components = location.components;

    LibraryElementImpl library = getLibrary(components[0]);
    if (components.length == 1) {
      return library;
    }

    CompilationUnitElement unit;
    for (var libraryUnit in library.units) {
      if (libraryUnit.source.uri.toString() == components[1]) {
        unit = libraryUnit;
        break;
      }
    }
    if (unit == null) {
      throw new ArgumentError('Unable to find unit: $location');
    }
    if (components.length == 2) {
      return unit;
    }

    ElementImpl element = unit as ElementImpl;
    for (int i = 2; i < components.length; i++) {
      if (element == null) {
        throw new ArgumentError('Unable to find element: $location');
      }
      element = element.getChild(components[i]);
    }
    return element;
  }

  /**
   * Return the [ElementImpl] that corresponds to the given [name], or `null`
   * if the corresponding element cannot be found.
   */
  ElementImpl getElementFromCanonicalName(kernel.CanonicalName name) {
    if (name == null) return null;

    var components = new List<String>(5);
    var componentPtr = 0;
    for (var namePart = name;
        namePart != null && !namePart.isRoot;
        namePart = namePart.parent) {
      components[componentPtr++] = namePart.name;
    }

    String libraryUri = components[--componentPtr];
    String topKindOrClassName = components[--componentPtr];

    LibraryElementImpl library = getLibrary(libraryUri);
    if (library == null) return null;

    String takeElementName() {
      String publicNameOrLibraryUri = components[--componentPtr];
      if (publicNameOrLibraryUri == libraryUri) {
        return components[--componentPtr];
      } else {
        return publicNameOrLibraryUri;
      }
    }

    // Top-level element other than class.
    if (topKindOrClassName == '@fields' ||
        topKindOrClassName == '@methods' ||
        topKindOrClassName == '@getters' ||
        topKindOrClassName == '@setters' ||
        topKindOrClassName == '@typedefs') {
      String elementName = takeElementName();
      for (CompilationUnitElement unit in library.units) {
        CompilationUnitElementImpl unitImpl = unit;
        ElementImpl child = unitImpl.getChild(elementName);
        if (child != null) {
          return child;
        }
      }
      return null;
    }

    AbstractClassElementImpl classElement;
    for (CompilationUnitElement unit in library.units) {
      CompilationUnitElementImpl unitImpl = unit;
      classElement = unitImpl.getChild(topKindOrClassName);
      if (classElement != null) {
        break;
      }
    }
    if (classElement == null) return null;

    // If no more component, the class is the element.
    if (componentPtr == 0) return classElement;

    String kind = components[--componentPtr];
    String elementName = takeElementName();
    if (kind == '@methods') {
      return classElement.getMethod(elementName) as ElementImpl;
    } else if (kind == '@getters') {
      return classElement.getGetter(elementName) as ElementImpl;
    } else if (kind == '@setters') {
      return classElement.getSetter(elementName) as ElementImpl;
    } else if (kind == '@fields') {
      return classElement.getField(elementName) as ElementImpl;
    } else if (kind == '@constructors' || kind == '@factories') {
      if (elementName.isEmpty) {
        return classElement.unnamedConstructor as ElementImpl;
      }
      return classElement.getNamedConstructor(elementName) as ElementImpl;
    } else {
      throw new UnimplementedError('Internal error: $kind unexpected.');
    }
  }

  /**
   * Return the [LibraryElementImpl] for the given [uriStr], or `null` if
   * the library is not part of the Kernel libraries bundle.
   */
  LibraryElementImpl getLibrary(String uriStr) {
    return _libraryMap.putIfAbsent(uriStr, () {
      var kernel = _kernelMap[uriStr];
      if (kernel == null) return null;

      if (_libraryExistMap[uriStr] != true) {
        return _newSyntheticLibrary(uriStr);
      }

      var libraryContext =
          new _KernelLibraryResynthesizerContextImpl(this, kernel);

      // Build the library.
      LibraryElementImpl libraryElement = libraryContext._buildLibrary(uriStr);
      if (libraryElement == null) return null;

      // Build the defining unit.
      var definingUnit = libraryContext._buildUnit(null).unit;
      libraryElement.definingCompilationUnit = definingUnit;

      // Build units for parts.
      var parts = new List<CompilationUnitElementImpl>(kernel.parts.length);
      for (int i = 0; i < kernel.parts.length; i++) {
        var fileUri = kernel.fileUri.resolve(kernel.parts[i].partUri);
        var unitContext = libraryContext._buildUnit("$fileUri");
        parts[i] = unitContext.unit;
      }
      libraryElement.parts = parts;

      // Create the required `loadLibrary` function.
      if (uriStr != 'dart:core' && uriStr != 'dart:async') {
        libraryElement.createLoadLibraryFunction(_typeProvider);
      }

      return libraryElement;
    });
  }

  DartType getType(ElementImpl context, kernel.DartType kernelType) {
    if (kernelType is kernel.DynamicType) return DynamicTypeImpl.instance;
    if (kernelType is kernel.InvalidType) return UndefinedTypeImpl.instance;
    if (kernelType is kernel.BottomType) return BottomTypeImpl.instance;
    if (kernelType is kernel.VoidType) return VoidTypeImpl.instance;

    if (kernelType is kernel.InterfaceType) {
      var name = kernelType.className.canonicalName;
      if (!strongMode &&
          name.name == 'FutureOr' &&
          name.parent.name == 'dart:async') {
        return DynamicTypeImpl.instance;
      }
      return _getInterfaceType(context, name, kernelType.typeArguments);
    }

    if (kernelType is kernel.TypeParameterType) {
      kernel.TypeParameter kTypeParameter = kernelType.parameter;
      return _getTypeParameter(context, kTypeParameter).type;
    }

    if (kernelType is kernel.FunctionType) {
      return _getFunctionType(context, kernelType);
    }

    // TODO(scheglov) Support other kernel types.
    throw new UnimplementedError('For ${kernelType.runtimeType}');
  }

  void _buildTypeProvider() {
    var coreLibrary = getLibrary('dart:core');
    var asyncLibrary = getLibrary('dart:async');
    _typeProvider = new SummaryTypeProvider();
    _typeProvider.initializeCore(coreLibrary);
    _typeProvider.initializeAsync(asyncLibrary);
    // Now, when TypeProvider is ready, we can finalize core/async.
    coreLibrary.createLoadLibraryFunction(_typeProvider);
    asyncLibrary.createLoadLibraryFunction(_typeProvider);
  }

  /// Return the [FunctionType] that corresponds to the given [kernelType].
  FunctionType _getFunctionType(
      ElementImpl context, kernel.FunctionType kernelType) {
    if (kernelType.typedef != null) {
      return _getTypedefType(context, kernelType);
    }

    var element = new FunctionElementImpl('', -1);
    context.encloseElement(element);

    // Set type parameters.
    {
      List<kernel.TypeParameter> typeParameters = kernelType.typeParameters;
      int count = typeParameters.length;
      var astTypeParameters = new List<TypeParameterElement>(count);
      for (int i = 0; i < count; i++) {
        astTypeParameters[i] =
            new TypeParameterElementImpl.forKernel(element, typeParameters[i]);
      }
      element.typeParameters = astTypeParameters;
    }

    // Set formal parameters.
    var parameters = _getFunctionTypeParameters(kernelType);
    var positionalParameters = parameters[0];
    var namedParameters = parameters[1];
    var astParameters = ParameterElementImpl.forKernelParameters(
        element,
        kernelType.requiredParameterCount,
        positionalParameters,
        namedParameters);
    element.parameters = astParameters;

    element.returnType = getType(element, kernelType.returnType);

    return new FunctionTypeImpl(element);
  }

  InterfaceType _getInterfaceType(ElementImpl context,
      kernel.CanonicalName className, List<kernel.DartType> kernelArguments) {
    var libraryName = className.parent;
    var libraryElement = getLibrary(libraryName.name);
    ClassElement classElement = libraryElement.getType(className.name);
    classElement ??= libraryElement.getEnum(className.name);

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

  /**
   * Get the [Source] object for the given [uri].
   */
  Source _getSource(String uri) {
    return _sources.putIfAbsent(
        uri, () => _analysisContext.sourceFactory.forUri(uri));
  }

  /// Return the [FunctionType] for the given typedef based [kernelType].
  FunctionType _getTypedefType(
      ElementImpl context, kernel.FunctionType kernelType) {
    kernel.Typedef typedef = kernelType.typedef;

    GenericTypeAliasElementImpl typedefElement =
        getElementFromCanonicalName(typedef.canonicalName);
    GenericFunctionTypeElementImpl functionElement = typedefElement.function;

    kernel.FunctionType typedefType = typedef.type;
    var kernelTypeParameters = typedef.typeParameters.toList();
    kernelTypeParameters.addAll(typedefType.typeParameters);

    // If no type parameters, the raw type of the element will do.
    FunctionTypeImpl rawType = functionElement.type;
    if (kernelTypeParameters.isEmpty) {
      return rawType;
    }

    // Compute type arguments for kernel type parameters.
    var kernelMap = kernel.unifyTypes(typedefType.withoutTypeParameters,
        kernelType.withoutTypeParameters, kernelTypeParameters.toSet());

    // Prepare Analyzer type parameters, in the same order as kernel ones.
    var astTypeParameters = typedefElement.typeParameters.toList();
    astTypeParameters.addAll(functionElement.typeParameters);

    // Convert kernel type arguments into Analyzer types.
    int length = astTypeParameters.length;
    var usedTypeParameters = <TypeParameterElement>[];
    var usedTypeArguments = <DartType>[];
    for (var i = 0; i < length; i++) {
      var kernelParameter = kernelTypeParameters[i];
      var kernelArgument = kernelMap[kernelParameter];
      if (kernelArgument == null ||
          kernelArgument is kernel.TypeParameterType &&
              kernelArgument.parameter.parent == null) {
        continue;
      }
      TypeParameterElement astParameter = astTypeParameters[i];
      DartType astArgument = getType(context, kernelArgument);
      usedTypeParameters.add(astParameter);
      usedTypeArguments.add(astArgument);
    }

    if (usedTypeParameters.isEmpty) {
      return rawType;
    }

    // Replace Analyzer type parameters with type arguments.
    return rawType.substitute4(usedTypeParameters, usedTypeArguments);
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

  LibraryElementImpl _newSyntheticLibrary(String uriStr) {
    Source librarySource = _getSource(uriStr);
    if (librarySource == null) return null;

    LibraryElementImpl libraryElement =
        new LibraryElementImpl(context, '', -1, 0);
    libraryElement.isSynthetic = true;
    CompilationUnitElementImpl unitElement =
        new CompilationUnitElementImpl(librarySource.shortName);
    libraryElement.definingCompilationUnit = unitElement;
    unitElement.source = librarySource;
    unitElement.librarySource = librarySource;
    libraryElement.createLoadLibraryFunction(_typeProvider);
    libraryElement.publicNamespace = new Namespace({});
    libraryElement.exportNamespace = new Namespace({});
    return libraryElement;
  }

  /// Return the list with exactly two elements - positional and named
  /// parameter lists.
  static List<List<kernel.VariableDeclaration>> _getFunctionTypeParameters(
      kernel.FunctionType type) {
    int positionalCount = type.positionalParameters.length;
    var positionalParameters =
        new List<kernel.VariableDeclaration>(positionalCount);
    for (int i = 0; i < positionalCount; i++) {
      String name = i < type.positionalParameterNames.length
          ? type.positionalParameterNames[i]
          : 'arg_$i';
      positionalParameters[i] = new kernel.VariableDeclaration(name,
          type: type.positionalParameters[i]);
    }

    var namedParameters = type.namedParameters
        .map((k) => new kernel.VariableDeclaration(k.name, type: k.type))
        .toList(growable: false);

    return [positionalParameters, namedParameters];
  }
}

/**
 * This exception is thrown when we detect that the Kernel has a compilation
 * error, so we cannot resynthesize the constant expression.
 */
class _CompilationErrorFound {
  const _CompilationErrorFound();
}

/**
 * Builder of [Expression]s from [kernel.Expression]s.
 */
class _ExprBuilder {
  final _KernelUnitResynthesizerContextImpl _context;
  final ElementImpl _contextElement;

  _ExprBuilder(this._context, this._contextElement);

  Expression build(kernel.Expression expr) {
    try {
      return _build(expr);
    } on _CompilationErrorFound {
      return AstTestFactory.identifier3('#invalidConst');
    }
  }

  ConstructorInitializer buildInitializer(kernel.Initializer k) {
    if (k is kernel.FieldInitializer) {
      Expression value = build(k.value);
      ConstructorFieldInitializer initializer = AstTestFactory
          .constructorFieldInitializer(false, k.field.name.name, value);
      initializer.fieldName.staticElement = _getElement(k.fieldReference);
      return initializer;
    }

    if (k is kernel.AssertInitializer) {
      var body = k.statement;
      var condition = build(body.condition);
      var message = body.message != null ? build(body.message) : null;
      return AstTestFactory.assertInitializer(condition, message);
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

    if (k is kernel.ShadowInvalidInitializer) {
      return null;
    }

    throw new UnimplementedError('For ${k.runtimeType}');
  }

  Expression _build(kernel.Expression expr) {
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
          .map(_build)
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
      var elements = expr.expressions.map(_build).toList();
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
        Expression key = _build(entry.key);
        Expression value = _build(entry.value);
        entries[i] = AstTestFactory.mapLiteralEntry2(key, value);
      }

      return AstTestFactory.mapLiteral(keyword, typeArguments, entries);
    }

    // Invalid annotations are represented as Let.
    if (expr is kernel.Let) {
      kernel.Let let = expr;
      if (_isStaticError(let.variable.initializer) ||
          _isStaticError(let.body)) {
        throw const _CompilationErrorFound();
      }
    }

    // Stop if there is an error.
    if (_isStaticError(expr)) {
      throw const _CompilationErrorFound();
    }

    if (expr is kernel.StaticGet) {
      return _buildIdentifier(expr.targetReference, isGet: true);
    }

    if (expr is kernel.ThisExpression) {
      return AstTestFactory.thisExpression();
    }

    if (expr is kernel.PropertyGet) {
      Expression target = _build(expr.receiver);
      kernel.Reference reference = expr.interfaceTargetReference;
      SimpleIdentifier identifier = _buildSimpleIdentifier(reference);
      return AstTestFactory.propertyAccess(target, identifier);
    }

    if (expr is kernel.VariableGet) {
      String name = expr.variable.name;
      Element contextConstructor = _contextElement;
      if (contextConstructor is ConstructorElement) {
        SimpleIdentifier identifier = AstTestFactory.identifier3(name);
        ParameterElement parameter = contextConstructor.parameters.firstWhere(
            (parameter) => parameter.name == name,
            orElse: () => null);
        identifier.staticElement = parameter;
        return identifier;
      }
    }

    if (expr is kernel.ConditionalExpression) {
      var condition = _build(expr.condition);
      var then = _build(expr.then);
      var otherwise = _build(expr.otherwise);
      return AstTestFactory.conditionalExpression(condition, then, otherwise);
    }

    if (expr is kernel.Not) {
      kernel.Expression kernelOperand = expr.operand;
      var operand = _build(kernelOperand);
      return AstTestFactory.prefixExpression(TokenType.BANG, operand);
    }

    if (expr is kernel.LogicalExpression) {
      var operator = _toBinaryOperatorTokenType(expr.operator);
      var left = _build(expr.left);
      var right = _build(expr.right);
      return AstTestFactory.binaryExpression(left, operator, right);
    }

    if (expr is kernel.AsExpression && expr.isTypeError) {
      return _build(expr.operand);
    }

    if (expr is kernel.Let) {
      var body = expr.body;
      if (body is kernel.ConditionalExpression) {
        var condition = body.condition;
        var otherwiseExpr = body.otherwise;
        if (condition is kernel.MethodInvocation) {
          var equalsReceiver = condition.receiver;
          if (equalsReceiver is kernel.VariableGet &&
              condition.name.name == '==' &&
              condition.arguments.positional.length == 1 &&
              condition.arguments.positional[0] is kernel.NullLiteral &&
              otherwiseExpr is kernel.VariableGet &&
              otherwiseExpr.variable == equalsReceiver.variable) {
            var left = _build(expr.variable.initializer);
            var right = _build(body.then);
            return AstTestFactory.binaryExpression(
                left, TokenType.QUESTION_QUESTION, right);
          }
        }
      }
    }

    if (expr is kernel.MethodInvocation) {
      var left = _build(expr.receiver);
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
        var right = _build(args.single);
        return AstTestFactory.binaryExpression(left, operator, right);
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

      var kernelType =
          expr.getStaticType(_context.libraryContext.resynthesizer._types);
      var type = _context.getType(_contextElement, kernelType);
      TypeName typeName = _buildType(type);

      var constructorName = AstTestFactory.constructorName(
          typeName, element.name.isNotEmpty ? element.name : null);
      constructorName?.name?.staticElement = element;

      var keyword = expr.isConst ? Keyword.CONST : Keyword.NEW;
      var arguments = _toArguments(expr.arguments);
      return AstTestFactory.instanceCreationExpression(
          keyword, constructorName, arguments);
    }

    if (expr is kernel.TypeLiteral) {
      ElementImpl element;
      var kernelType = expr.type;
      if (kernelType is kernel.FunctionType) {
        element = _getElement(kernelType.typedefReference);
      } else {
        var type = _context.getType(_contextElement, kernelType);
        element = type.element;
      }
      var identifier = AstTestFactory.identifier3(element.name);
      identifier.staticElement = element;
      identifier.staticType = _context.libraryContext.resynthesizer.typeType;
      return identifier;
    }

    // TODO(scheglov): complete getExpression
    throw new UnimplementedError('kernel: (${expr.runtimeType}) $expr');
  }

  Identifier _buildIdentifier(kernel.Reference reference, {bool isGet: false}) {
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
      return AstTestFactory.identifier(classRef, property);
    } else {
      return property;
    }
  }

  SimpleIdentifier _buildSimpleIdentifier(kernel.Reference reference) {
    if (reference == null) {
      throw const _CompilationErrorFound();
    }
    String name = reference.canonicalName.name;
    SimpleIdentifier identifier = AstTestFactory.identifier3(name);
    Element element = _getElement(reference);
    identifier.staticElement = element;
    return identifier;
  }

  TypeAnnotation _buildType(DartType type) {
    List<TypeAnnotation> argumentNodes;
    if (type is ParameterizedType) {
      argumentNodes = _buildTypeArguments(type.typeArguments);
    }
    TypeName node = AstTestFactory.typeName4(type.name, argumentNodes);
    node.type = type;
    (node.name as SimpleIdentifier).staticElement = type.element;
    return node;
  }

  TypeArgumentList _buildTypeArgumentList(List<kernel.DartType> kernels) {
    int length = kernels.length;
    var types = new List<TypeAnnotation>(length);
    for (int i = 0; i < length; i++) {
      DartType type = _context.getType(_contextElement, kernels[i]);
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
    return _context.libraryContext.resynthesizer
        .getElementFromCanonicalName(reference?.canonicalName);
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
      arguments[i++] = _build(k);
    }

    for (kernel.NamedExpression k in kernelArguments.named) {
      var value = _build(k.value);
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

  /**
   * Return `true` if the given [expr] throws an instance of
   * `_ConstantExpressionError` defined in `dart:core`.
   */
  static bool _isStaticError(kernel.Expression expr) {
    return expr is kernel.InvalidExpression;
  }
}

/**
 * Implementation of [KernelLibraryResynthesizerContext].
 */
class _KernelLibraryResynthesizerContextImpl
    implements KernelLibraryResynthesizerContext {
  final KernelResynthesizer resynthesizer;

  @override
  final kernel.Library library;

  /**
   * The relative URI of the directory with the [library] file.
   * E.g. `sdk/lib/core` for `sdk/lib/core/core.dart`.
   */
  String libraryDirectoryUri;

  Source librarySource;
  LibraryElementImpl libraryElement;

  _KernelLibraryResynthesizerContextImpl(this.resynthesizer, this.library) {
    libraryDirectoryUri = pathos.url.dirname("${library.fileUri}");
  }

  @override
  kernel.Library get coreLibrary => resynthesizer._kernelMap['dart:core'];

  @override
  bool get hasExtUri {
    for (var dependency in library.dependencies) {
      if (dependency.isImport &&
          dependency.targetLibrary.importUri.isScheme('dart-ext')) {
        return true;
      }
    }
    return false;
  }

  @override
  Namespace buildExportNamespace() {
    Namespace publicNamespace = buildPublicNamespace();
    if (library.additionalExports.isEmpty) {
      return publicNamespace;
    }

    Map<String, Element> definedNames = publicNamespace.definedNames;
    for (kernel.Reference additionalExport in library.additionalExports) {
      var element = resynthesizer
          .getElementFromCanonicalName(additionalExport.canonicalName);
      if (element != null) {
        definedNames[element.name] = element;
      }
    }

    return new Namespace(definedNames);
  }

  @override
  Namespace buildPublicNamespace() {
    return new NamespaceBuilder()
        .createPublicNamespaceForLibrary(libraryElement);
  }

  @override
  LibraryElementImpl getLibrary(String uriStr) {
    return resynthesizer.getLibrary(uriStr);
  }

  LibraryElementImpl _buildLibrary(String uriStr) {
    librarySource = resynthesizer._getSource(uriStr);
    if (librarySource == null) return null;
    return libraryElement =
        new LibraryElementImpl.forKernel(resynthesizer._analysisContext, this);
  }

  _KernelUnitResynthesizerContextImpl _buildUnit(String fileUri) {
    var unitContext = new _KernelUnitResynthesizerContextImpl(
        this, fileUri ?? "${library.fileUri}");
    var unitElement = new CompilationUnitElementImpl.forKernel(
        libraryElement, unitContext, '<no name>');
    unitContext.unit = unitElement;
    unitElement.librarySource = librarySource;

    if (fileUri != null) {
      String absoluteUriStr;
      if (fileUri.startsWith('file://')) {
        // Compute the URI relative to the library directory.
        // E.g. when the library directory URI is `sdk/lib/core`, and the unit
        // URI is `sdk/lib/core/bool.dart`, the result is `bool.dart`.
        var relativeUri =
            pathos.url.relative(fileUri, from: libraryDirectoryUri);
        // Compute the absolute URI.
        // When the absolute library URI is `dart:core`, and the relative
        // URI is `bool.dart`, the result is `dart:core/bool.dart`.
        Uri absoluteUri =
            resolveRelativeUri(librarySource.uri, Uri.parse(relativeUri));
        absoluteUriStr = absoluteUri.toString();
      } else {
        // File URIs must have the "file" scheme.
        // But for invalid URIs, which cannot be even parsed, FrontEnd returns
        // URIs with the "org-dartlang-malformed-uri" scheme, and does not
        // resolve them to file URIs.
        // We don't have anything better than to use these URIs as is.
        absoluteUriStr = fileUri;
      }
      unitElement.source = resynthesizer._getSource(absoluteUriStr);
    } else {
      unitElement.source = librarySource;
    }

    unitContext.unit = unitElement;
    return unitContext;
  }
}

/**
 * Implementation of [KernelUnit].
 */
class _KernelUnitImpl implements KernelUnit {
  final _KernelUnitResynthesizerContextImpl context;

  List<kernel.Expression> _annotations;
  List<kernel.Class> _classes;
  List<kernel.Field> _fields;
  List<kernel.Procedure> _procedures;
  List<kernel.Typedef> _typedefs;

  _KernelUnitImpl(this.context);

  @override
  List<kernel.Expression> get annotations {
    if (_annotations == null) {
      for (var part in context.libraryContext.library.parts) {
        if ("${context.libraryContext.library.fileUri.resolve(part.partUri)}" ==
            context.fileUri) {
          return _annotations = part.annotations;
        }
      }
    }
    return _annotations ?? const <kernel.Expression>[];
  }

  @override
  List<kernel.Class> get classes =>
      _classes ??= context.libraryContext.library.classes
          .where((n) => "${n.fileUri}" == context.fileUri)
          .toList(growable: false);

  @override
  List<kernel.Field> get fields =>
      _fields ??= context.libraryContext.library.fields
          .where((n) => "${n.fileUri}" == context.fileUri)
          .toList(growable: false);

  @override
  List<kernel.Procedure> get procedures =>
      _procedures ??= context.libraryContext.library.procedures
          .where((n) => "${n.fileUri}" == context.fileUri)
          .toList(growable: false);

  @override
  List<kernel.Typedef> get typedefs =>
      _typedefs ??= context.libraryContext.library.typedefs
          .where((n) => "${n.fileUri}" == context.fileUri)
          .toList(growable: false);
}

/**
 * Implementation of [KernelUnitResynthesizerContext].
 */
class _KernelUnitResynthesizerContextImpl
    implements KernelUnitResynthesizerContext {
  static final Uri dartInternalUri = Uri.parse('dart:_internal');

  final _KernelLibraryResynthesizerContextImpl libraryContext;
  final String fileUri;

  CompilationUnitElementImpl unit;

  _KernelUnitResynthesizerContextImpl(this.libraryContext, this.fileUri);

  @override
  KernelUnit get kernelUnit => new _KernelUnitImpl(this);

  @override
  List<ElementAnnotation> buildAnnotations(
      List<kernel.Expression> expressions) {
    int length = expressions.length;
    if (length != 0) {
      var annotations = <ElementAnnotation>[];
      for (var expression in expressions) {
        if (_isSyntheticExternalNameAnnotation(expression)) continue;
        var annotation = _buildAnnotation(unit, expression);
        annotations.add(annotation);
      }
      return annotations;
    } else {
      return const <ElementAnnotation>[];
    }
  }

  @override
  UnitExplicitTopLevelAccessors buildTopLevelAccessors() {
    var accessorsData = new UnitExplicitTopLevelAccessors();
    var implicitVariables = <String, TopLevelVariableElementImpl>{};
    // Build explicit property accessors and implicit fields.
    for (var procedure in kernelUnit.procedures) {
      bool isGetter = procedure.kind == kernel.ProcedureKind.Getter;
      bool isSetter = procedure.kind == kernel.ProcedureKind.Setter;
      if (isGetter || isSetter) {
        var accessor =
            new PropertyAccessorElementImpl.forKernel(unit, procedure);
        accessorsData.accessors.add(accessor);

        // Create or update the implicit variable.
        String name = accessor.displayName;
        TopLevelVariableElementImpl variable = implicitVariables[name];
        if (variable == null) {
          variable = new TopLevelVariableElementImpl(name, -1);
          implicitVariables[name] = variable;
          variable.enclosingElement = unit;
          variable.isSynthetic = true;
          variable.isFinal = isGetter;
        } else {
          variable.isFinal = false;
        }

        // Attach the accessor to the variable.
        accessor.variable = variable;
        if (isGetter) {
          variable.getter = accessor;
        } else {
          variable.setter = accessor;
        }
      }
    }
    accessorsData.implicitVariables.addAll(implicitVariables.values);
    return accessorsData;
  }

  @override
  UnitExplicitTopLevelVariables buildTopLevelVariables() {
    List<kernel.Field> kernelFields = kernelUnit.fields;
    int numberOfVariables = kernelFields.length;
    var variablesData = new UnitExplicitTopLevelVariables(numberOfVariables);
    for (int i = 0; i < numberOfVariables; i++) {
      kernel.Field field = kernelFields[i];

      // Add the explicit variables.
      TopLevelVariableElementImpl variable;
      if (field.isConst && field.initializer != null) {
        variable = new ConstTopLevelVariableElementImpl.forKernel(unit, field);
      } else {
        variable = new TopLevelVariableElementImpl.forKernel(unit, field);
      }
      variablesData.variables[i] = variable;

      // Add the implicit accessors.
      variablesData.implicitAccessors
          .add(new PropertyAccessorElementImpl_ImplicitGetter(variable));
      if (!(variable.isConst || variable.isFinal)) {
        variablesData.implicitAccessors
            .add(new PropertyAccessorElementImpl_ImplicitSetter(variable));
      }
    }
    return variablesData;
  }

  @override
  ConstructorInitializer getConstructorInitializer(
      ConstructorElementImpl constructor, kernel.Initializer k) {
    if (k is kernel.FieldInitializer && k.isSynthetic ||
        k is kernel.SuperInitializer && k.isSynthetic) {
      return null;
    }
    return new _ExprBuilder(this, constructor).buildInitializer(k);
  }

  @override
  Expression getExpression(ElementImpl context, kernel.Expression expression) {
    return new _ExprBuilder(this, context).build(expression);
  }

  @override
  List<List<kernel.VariableDeclaration>> getFunctionTypeParameters(
      kernel.FunctionType type) {
    return KernelResynthesizer._getFunctionTypeParameters(type);
  }

  @override
  InterfaceType getInterfaceType(
      ElementImpl context, kernel.Supertype kernelType) {
    if (kernelType.classNode.isEnum) {
      return null;
    }
    return libraryContext.resynthesizer._getInterfaceType(
        context, kernelType.className.canonicalName, kernelType.typeArguments);
  }

  @override
  List<InterfaceType> getInterfaceTypes(
      ElementImpl context, List<kernel.Supertype> types) {
    var interfaceTypes = <InterfaceType>[];
    for (kernel.Supertype kernelType in types) {
      InterfaceType interfaceType = getInterfaceType(context, kernelType);
      if (interfaceType != null) {
        interfaceTypes.add(interfaceType);
      }
    }
    return interfaceTypes;
  }

  @override
  ConstructorElementImpl getRedirectedConstructor(
      kernel.Constructor kernelConstructor, kernel.Procedure kernelFactory) {
    if (kernelConstructor != null) {
      for (var initializer in kernelConstructor.initializers) {
        if (initializer is kernel.RedirectingInitializer) {
          return libraryContext.resynthesizer.getElementFromCanonicalName(
                  initializer.targetReference.canonicalName)
              as ConstructorElementImpl;
        }
      }
    }
    if (kernelFactory != null) {
      kernel.Statement body = kernelFactory.function.body;
      if (body is RedirectingFactoryBody) {
        kernel.Member target = body.target;
        if (target != null) {
          return libraryContext.resynthesizer
                  .getElementFromCanonicalName(target.reference.canonicalName)
              as ConstructorElementImpl;
        }
      }
    }
    return null;
  }

  @override
  DartType getType(ElementImpl context, kernel.DartType type) {
    return libraryContext.resynthesizer.getType(context, type);
  }

  ElementAnnotationImpl _buildAnnotation(
      CompilationUnitElementImpl unit, kernel.Expression expression) {
    ElementAnnotationImpl elementAnnotation = new ElementAnnotationImpl(unit);
    Expression constExpr = getExpression(unit, expression);
    if (constExpr is Identifier) {
      elementAnnotation.element = constExpr.staticElement;
      elementAnnotation.annotationAst = AstTestFactory.annotation(constExpr);
    } else if (constExpr is InstanceCreationExpression) {
      elementAnnotation.element = constExpr.staticElement;
      Identifier typeName = constExpr.constructorName.type.name;
      SimpleIdentifier constructorName = constExpr.constructorName.name;
      elementAnnotation.annotationAst = AstTestFactory.annotation2(
          typeName, constructorName, constExpr.argumentList)
        ..element = constExpr.staticElement;
    } else {
      throw new StateError(
          'Unexpected annotation type: ${constExpr.runtimeType}');
    }
    return elementAnnotation;
  }

  /// Fasta converts `native 'name'` clauses to `@ExternalName('name')`
  /// annotations. But we don't actually have these annotations in code. So,
  /// we need to skip them to avoid mismatch with AST.
  static bool _isSyntheticExternalNameAnnotation(kernel.Expression expr) {
    if (expr is kernel.ConstructorInvocation) {
      kernel.Constructor target = expr.target;
      return target != null &&
          target.enclosingClass.name == 'ExternalName' &&
          target.enclosingLibrary.importUri == dartInternalUri;
    }
    return false;
  }
}
