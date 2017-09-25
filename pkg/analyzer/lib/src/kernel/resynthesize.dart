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
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
import 'package:analyzer/src/generated/testing/ast_test_factory.dart';
import 'package:analyzer/src/summary/summary_sdk.dart';
import 'package:front_end/src/base/source.dart';
import 'package:front_end/src/fasta/kernel/redirecting_factory_body.dart';
import 'package:kernel/kernel.dart' as kernel;
import 'package:kernel/type_environment.dart' as kernel;
import 'package:front_end/src/fasta/kernel/kernel_shadow_ast.dart' as kernel;

/**
 * Object that can resynthesize analyzer [LibraryElement] from Kernel.
 */
class KernelResynthesizer implements ElementResynthesizer {
  final AnalysisContextImpl _analysisContext;
  final kernel.TypeEnvironment _types;
  final Map<String, kernel.Library> _kernelMap;
  final Map<String, LibraryElementImpl> _libraryMap = {};

  /**
   * Cache of [Source] objects that have already been converted from URIs.
   */
  final Map<String, Source> _sources = <String, Source>{};

  /// The type provider for this resynthesizer.
  SummaryTypeProvider _typeProvider;

  KernelResynthesizer(this._analysisContext, this._types, this._kernelMap) {
    _buildTypeProvider();
    _analysisContext.typeProvider = _typeProvider;
  }

  @override
  AnalysisContext get context => _analysisContext;

  /**
   * Return the `Type` type.
   */
  DartType get typeType => getLibrary('dart:core').getType('Type').type;

  /**
   * Return `true` if strong mode analysis should be used.
   */
  bool get strongMode => _analysisContext.analysisOptions.strongMode;

  @override
  Element getElement(ElementLocation location) {
    List<String> components = location.components;
    if (components.length != 1) {
      throw new ArgumentError('Only library access is implemented.');
    }
    return getLibrary(components[0]);
  }

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
      LibraryElementImpl libraryElement = libraryContext._buildLibrary(uriStr);

      // Build the defining unit.
      var definingUnit = libraryContext._buildUnit(null).unit;
      libraryElement.definingCompilationUnit = definingUnit;

      // Build units for parts.
      var parts = new List<CompilationUnitElementImpl>(kernel.parts.length);
      for (int i = 0; i < kernel.parts.length; i++) {
        var fileUri = kernel.parts[i].fileUri;
        var unitContext = libraryContext._buildUnit(fileUri);
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

  /**
   * Return the [ElementImpl] that corresponds to the given [name], or `null`
   * if the corresponding element cannot be found.
   */
  ElementImpl _getElement(kernel.CanonicalName name) {
    if (name == null) return null;
    kernel.CanonicalName parentName = name.parent;

    // If the parent is the root, then this name is a library.
    if (parentName.isRoot) {
      return getLibrary(name.name);
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
    } else if (parentName.name == '@typedefs') {
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
    if (parentElement is AbstractClassElementImpl) {
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

    throw new UnimplementedError(
        'Internal error: ${parentElement.runtimeType} unexpected.');
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
  final _KernelUnitResynthesizerContextImpl _context;
  final ElementImpl _contextElement;

  _ExprBuilder(this._context, this._contextElement);

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
            var left = build(expr.variable.initializer);
            var right = build(body.then);
            return AstTestFactory.binaryExpression(
                left, TokenType.QUESTION_QUESTION, right);
          }
        }
      }
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
      var type = _context.getType(_contextElement, expr.type);
      var identifier = AstTestFactory.identifier3(type.element.name);
      identifier.staticElement = type.element;
      identifier.staticType = _context.libraryContext.resynthesizer.typeType;
      return identifier;
    }

    // Invalid annotations are represented as Let.
    if (expr is kernel.Let &&
        expr.variable.initializer is kernel.ShadowSyntheticExpression) {
      expr = (expr as kernel.Let).variable.initializer;
    }

    // Synthetic expression representing a constant error.
    if (expr is kernel.ShadowSyntheticExpression) {
      var desugared = expr.desugared;
      if (desugared is kernel.MethodInvocation) {
        if (desugared.name.name == '_throw') {
          var receiver = desugared.receiver;
          if (receiver is kernel.ConstructorInvocation &&
              receiver.target.enclosingClass.name ==
                  '_ConstantExpressionError') {
            return AstTestFactory.identifier3('#invalidConst');
          }
        }
      }
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

    if (k is kernel.LocalInitializer) {
      var invocation = k.variable.initializer;
      if (invocation is kernel.MethodInvocation) {
        var receiver = invocation.receiver;
        if (receiver is kernel.FunctionExpression &&
            invocation.name.name == 'call') {
          var body = receiver.function.body;
          if (body is kernel.AssertStatement) {
            var condition = build(body.condition);
            var message = body.message != null ? build(body.message) : null;
            return AstTestFactory.assertInitializer(condition, message);
          }
        }
      }
      throw new StateError('Expected assert initializer $k');
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
    if (type is DynamicTypeImpl || type is TypeParameterType) {
      var identifier = AstTestFactory.identifier3(type.name)
        ..staticElement = type.element
        ..staticType = type;
      return AstTestFactory.typeName3(identifier)..type = type;
    }
    // TODO(scheglov) Implement for other types.
    throw new UnimplementedError('type: (${type.runtimeType}) $type');
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
        ._getElement(reference?.canonicalName);
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
  final KernelResynthesizer resynthesizer;

  @override
  final kernel.Library library;

  Source librarySource;
  LibraryElementImpl libraryElement;

  _KernelLibraryResynthesizerContextImpl(this.resynthesizer, this.library);

  @override
  kernel.Library get coreLibrary => resynthesizer._kernelMap['dart:core'];

  @override
  LibraryElementImpl getLibrary(String uriStr) {
    return resynthesizer.getLibrary(uriStr);
  }

  LibraryElementImpl _buildLibrary(String uriStr) {
    librarySource = resynthesizer._getSource(uriStr);
    return libraryElement =
        new LibraryElementImpl.forKernel(resynthesizer._analysisContext, this);
  }

  _KernelUnitResynthesizerContextImpl _buildUnit(String fileUri) {
    var unitContext = new _KernelUnitResynthesizerContextImpl(
        this, fileUri ?? library.fileUri);
    var unitElement = new CompilationUnitElementImpl.forKernel(
        libraryElement, unitContext, '<no name>');
    unitContext.unit = unitElement;
    unitElement.librarySource = librarySource;
    unitElement.source =
        fileUri != null ? resynthesizer._getSource(fileUri) : librarySource;
    unitContext.unit = unitElement;
    return unitContext;
  }
}

/**
 * Implementation of [KernelUnit].
 */
class _KernelUnitImpl implements KernelUnit {
  final _KernelUnitResynthesizerContextImpl context;

  List<kernel.Class> _classes;
  List<kernel.Field> _fields;
  List<kernel.Procedure> _procedures;
  List<kernel.Typedef> _typedefs;

  _KernelUnitImpl(this.context);

  @override
  List<kernel.Class> get classes =>
      _classes ??= context.libraryContext.library.classes
          .where((n) => n.fileUri == context.fileUri)
          .toList(growable: false);

  @override
  List<kernel.Field> get fields =>
      _fields ??= context.libraryContext.library.fields
          .where((n) => n.fileUri == context.fileUri)
          .toList(growable: false);

  @override
  List<kernel.Procedure> get procedures =>
      _procedures ??= context.libraryContext.library.procedures
          .where((n) => n.fileUri == context.fileUri)
          .toList(growable: false);

  @override
  List<kernel.Typedef> get typedefs =>
      _typedefs ??= context.libraryContext.library.typedefs
          .where((n) => n.fileUri == context.fileUri)
          .toList(growable: false);
}

/**
 * Implementation of [KernelUnitResynthesizerContext].
 */
class _KernelUnitResynthesizerContextImpl
    implements KernelUnitResynthesizerContext {
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
      var annotations = new List<ElementAnnotation>(length);
      for (int i = 0; i < length; i++) {
        annotations[i] = _buildAnnotation(unit, expressions[i]);
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

  @override
  InterfaceType getInterfaceType(
      ElementImpl context, kernel.Supertype kernelType) {
    if (kernelType.classNode.isEnum) {
      return null;
    }
    return _getInterfaceType(
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
          return libraryContext.resynthesizer
                  ._getElement(initializer.targetReference.canonicalName)
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
                  ._getElement(target.reference.canonicalName)
              as ConstructorElementImpl;
        }
      }
    }
    return null;
  }

  DartType getType(ElementImpl context, kernel.DartType kernelType) {
    if (kernelType is kernel.DynamicType) return DynamicTypeImpl.instance;
    if (kernelType is kernel.InvalidType) return DynamicTypeImpl.instance;
    if (kernelType is kernel.VoidType) return VoidTypeImpl.instance;

    if (kernelType is kernel.InterfaceType) {
      var name = kernelType.className.canonicalName;
      if (!libraryContext.resynthesizer.strongMode &&
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
      if (kernelType.typedef != null) {
        FunctionTypeAliasElementImpl element = libraryContext.resynthesizer
            ._getElement(kernelType.typedef.canonicalName);
        return element.type;
      }

      if (context is ParameterElementImpl) {
        var typeElement =
            new GenericFunctionTypeElementImpl.forKernel(context, kernelType);
        return typeElement.type;
      } else {
        var functionElement = new FunctionElementImpl.synthetic([], null);
        functionElement.enclosingElement = context;

        functionElement.typeParameters = kernelType.typeParameters.map((k) {
          return new TypeParameterElementImpl.forKernel(functionElement, k);
        }).toList(growable: false);

        var parameters = getFunctionTypeParameters(kernelType);
        functionElement.parameters = ParameterElementImpl.forKernelParameters(
            functionElement,
            kernelType.requiredParameterCount,
            parameters[0],
            parameters[1]);

        functionElement.returnType =
            getType(functionElement, kernelType.returnType);
        return functionElement.type;
      }
    }

    // TODO(scheglov) Support other kernel types.
    throw new UnimplementedError('For ${kernelType.runtimeType}');
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

  InterfaceType _getInterfaceType(ElementImpl context,
      kernel.CanonicalName className, List<kernel.DartType> kernelArguments) {
    var libraryName = className.parent;
    var libraryElement = libraryContext.getLibrary(libraryName.name);
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
