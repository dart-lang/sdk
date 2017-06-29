// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/codegen.dart' show CodegenRegistry;
import '../common/names.dart';
import '../common_elements.dart';
import '../compiler.dart';
import '../constants/values.dart'
    show
        ConstantValue,
        InterceptorConstantValue,
        StringConstantValue,
        TypeConstantValue;
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/resolution_types.dart';
import '../elements/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../kernel/element_map.dart';
import '../native/native.dart' as native;
import '../resolution/tree_elements.dart';
import '../tree/nodes.dart' show Node;
import '../types/masks.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart' show SideEffects;
import '../universe/use.dart' show DynamicUse;
import '../universe/world_builder.dart' show CodegenWorldBuilder;
import '../world.dart';
import 'graph_builder.dart';
import 'jump_handler.dart';
import 'kernel_ast_adapter.dart';
import 'kernel_string_builder.dart';
import 'locals_handler.dart';
import 'loop_handler.dart';
import 'nodes.dart';
import 'ssa.dart';
import 'ssa_branch_builder.dart';
import 'switch_continue_analysis.dart';
import 'type_builder.dart';

class KernelSsaGraphBuilder extends ir.Visitor
    with GraphBuilder, SsaBuilderFieldMixin {
  final ir.Node target;
  final bool _targetIsConstructorBody;
  final MemberEntity targetElement;

  /// The root node of [targetElement]. This is used as the key into the
  /// [startFunction] of the locals handler.
  // TODO(johnniwinther,efortuna): Avoid the need for AST nodes in the locals
  // handler.
  final Node functionNode;
  final ClosedWorld closedWorld;
  final CodegenWorldBuilder _worldBuilder;
  final CodegenRegistry registry;
  final ClosureDataLookup closureDataLookup;

  /// Helper accessor for all kernel function-like targets (Procedure,
  /// FunctionExpression, FunctionDeclaration) of the inner FunctionNode itself.
  /// If the current target is not a function-like target, _targetFunction will
  /// be null.
  ir.FunctionNode _targetFunction;

  /// A stack of [ResolutionDartType]s that have been seen during inlining of
  /// factory constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HCreate]s inside the inline code and registered during code generation
  /// for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted) types
  // of the type variables in an environment (like the [LocalsHandler]).
  final List<InterfaceType> currentImplicitInstantiations = <InterfaceType>[];

  HInstruction rethrowableException;

  final Compiler compiler;

  @override
  JavaScriptBackend get backend => compiler.backend;

  @override
  TreeElements get elements => astAdapter.elements;

  SourceInformationBuilder sourceInformationBuilder;
  final KernelToElementMapForBuilding _elementMap;
  final KernelToTypeInferenceMap _typeInferenceMap;
  final KernelToLocalsMap localsMap;
  LoopHandler<ir.Node> loopHandler;
  TypeBuilder typeBuilder;

  final Map<ir.VariableDeclaration, HInstruction> letBindings =
      <ir.VariableDeclaration, HInstruction>{};

  /// True if we are visiting the expression of a throw statement; we assume
  /// this is a slow path.
  bool _inExpressionOfThrow = false;

  KernelSsaGraphBuilder(
      this.targetElement,
      ClassEntity contextClass,
      this.target,
      this.compiler,
      this._elementMap,
      this._typeInferenceMap,
      this.localsMap,
      this.closedWorld,
      this._worldBuilder,
      this.registry,
      this.closureDataLookup,
      // TODO(het): Should sourceInformationBuilder be in GraphBuilder?
      this.sourceInformationBuilder,
      this.functionNode,
      {bool targetIsConstructorBody: false})
      : this._targetIsConstructorBody = targetIsConstructorBody {
    this.loopHandler = new KernelLoopHandler(this);
    typeBuilder = new TypeBuilder(this);
    graph.element = targetElement;
    graph.sourceInformation =
        sourceInformationBuilder.buildVariableDeclaration();
    this.localsHandler = new LocalsHandler(this, targetElement, targetElement,
        contextClass, null, nativeData, interceptorData);
    _targetStack.add(targetElement);
  }

  @deprecated // Use [_elementMap] instead.
  KernelAstAdapter get astAdapter => _elementMap;

  CommonElements get _commonElements => _elementMap.commonElements;

  HGraph build() {
    return reporter.withCurrentElement(localsMap.currentMember, () {
      // TODO(het): no reason to do this here...
      HInstruction.idCounter = 0;
      if (target is ir.Procedure) {
        _targetFunction = (target as ir.Procedure).function;
        buildFunctionNode(_targetFunction);
      } else if (target is ir.Field) {
        if (handleConstantField(targetElement, registry, closedWorld)) {
          // No code is generated for `targetElement`: All references inline the
          // constant value.
          return null;
        } else if (targetElement.isStatic || targetElement.isTopLevel) {
          backend.constants.registerLazyStatic(targetElement);
        }
        buildField(target);
      } else if (target is ir.Constructor) {
        if (_targetIsConstructorBody) {
          buildConstructorBody(target);
        } else {
          buildConstructor(target);
        }
      } else if (target is ir.FunctionExpression) {
        _targetFunction = (target as ir.FunctionExpression).function;
        buildFunctionNode(_targetFunction);
      } else if (target is ir.FunctionDeclaration) {
        _targetFunction = (target as ir.FunctionDeclaration).function;
        buildFunctionNode(_targetFunction);
      } else {
        throw 'No case implemented to handle target: '
            '$target for $targetElement';
      }
      assert(graph.isValid());
      return graph;
    });
  }

  @override
  ConstantValue getFieldInitialConstantValue(FieldEntity field) {
    assert(field == targetElement);
    return _elementMap.getFieldConstantValue(target);
  }

  void buildField(ir.Field field) {
    openFunction();
    if (field.initializer != null) {
      field.initializer.accept(this);
      HInstruction fieldValue = pop();
      HInstruction checkInstruction = typeBuilder.potentiallyCheckOrTrustType(
          fieldValue, _getDartTypeIfValid(field.type));
      stack.add(checkInstruction);
    } else {
      stack.add(graph.addConstantNull(closedWorld));
    }
    HInstruction value = pop();
    closeAndGotoExit(new HReturn(value, null));
    closeFunction();
  }

  DartType _getDartTypeIfValid(ir.DartType type) {
    if (type is ir.InvalidType) return null;
    return _elementMap.getDartType(type);
  }

  /// Pops the most recent instruction from the stack and 'boolifies' it.
  ///
  /// Boolification is checking if the value is '=== true'.
  @override
  HInstruction popBoolified() {
    HInstruction value = pop();
    if (typeBuilder.checkOrTrustTypes) {
      ResolutionInterfaceType type = commonElements.boolType;
      return typeBuilder.potentiallyCheckOrTrustType(value, type,
          kind: HTypeConversion.BOOLEAN_CONVERSION_CHECK);
    }
    HInstruction result = new HBoolify(value, commonMasks.boolType);
    add(result);
    return result;
  }

  /// Extend current method parameters with parameters for the class type
  /// parameters.  If the class has type parameters but does not need them, bind
  /// to `dynamic` (represented as `null`) so the bindings are available for
  /// building types up the inheritance chain of generative constructors.
  void _addClassTypeVariablesIfNeeded(ir.Member constructor) {
    ir.Class enclosing = constructor.enclosingClass;
    ClassEntity cls = _elementMap.getClass(enclosing);
    bool needParameters;
    enclosing.typeParameters.forEach((ir.TypeParameter typeParameter) {
      TypeVariableType typeVariableType =
          _elementMap.getDartType(new ir.TypeParameterType(typeParameter));
      HInstruction param;
      needParameters ??= rtiNeed.classNeedsRti(cls);
      if (needParameters) {
        param = addParameter(typeVariableType.element, commonMasks.nonNullType);
      } else {
        // Unused, so bind to `dynamic`.
        param = graph.addConstantNull(closedWorld);
      }
      localsHandler.directLocals[
          localsHandler.getTypeVariableAsLocal(typeVariableType)] = param;
    });
  }

  /// Builds a generative constructor.
  ///
  /// Generative constructors are built in stages, in effect inlining the
  /// initializers and constructor bodies up the inheritance chain.
  ///
  ///  1. Extend method parameters with parameters the class's type parameters.
  ///
  ///  2. Add type checks for value parameters (might need result of (1)).
  ///
  ///  3. Walk inheritance chain to build bindings for type parameters of
  ///     superclasses and mixed-in classes.
  ///
  ///  4. Collect initializer values. Walk up inheritance chain to collect field
  ///     initializers from field declarations, initializing parameters and
  ///     initializer.
  ///
  ///  5. Create reified type information for instance.
  ///
  ///  6. Allocate instance and assign initializers and reified type information
  ///     to fields by calling JavaScript constructor.
  ///
  ///  7. Walk inheritance chain to call or inline constructor bodies.
  ///
  /// All the bindings are put in the constructor's locals handler. The
  /// implication is that a class cannot be extended or mixed-in twice. If we in
  /// future support repeated uses of a mixin class, we should do so by cloning
  /// the mixin class in the Kernel input.
  void buildConstructor(ir.Constructor constructor) {
    ir.Class constructedClass = constructor.enclosingClass;

    openFunction(constructor.function);
    _addClassTypeVariablesIfNeeded(constructor);

    // TODO(sra): Type parameter constraint checks.

    // TODO(sra): Checked mode parameter checks.

    // Collect field values for the current class.
    Map<FieldEntity, HInstruction> fieldValues =
        _collectFieldValues(constructedClass);
    List<ir.Constructor> constructorChain = <ir.Constructor>[];
    _buildInitializers(constructor, constructorChain, fieldValues);

    final constructorArguments = <HInstruction>[];
    // Doing this instead of fieldValues.forEach because we haven't defined the
    // order of the arguments here. We can define that with JElements.
    ClassEntity cls = _elementMap.getClass(constructedClass);
    InterfaceType thisType = _elementMap.elementEnvironment.getThisType(cls);
    _worldBuilder.forEachInstanceField(cls,
        (ClassEntity enclosingClass, FieldEntity member) {
      var value = fieldValues[member];
      assert(value != null, 'No value for field ${member}');
      constructorArguments.add(value);
    });

    // Create the runtime type information, if needed.
    bool hasRtiInput = backend.rtiNeed.classNeedsRtiField(cls);
    if (hasRtiInput) {
      // Read the values of the type arguments and create a HTypeInfoExpression
      // to set on the newly create object.
      List<HInstruction> typeArguments = <HInstruction>[];
      for (ir.DartType typeParameter
          in constructedClass.thisType.typeArguments) {
        HInstruction argument = localsHandler.readLocal(localsHandler
            .getTypeVariableAsLocal(_elementMap.getDartType(typeParameter)));
        typeArguments.add(argument);
      }

      HInstruction typeInfo = new HTypeInfoExpression(
          TypeInfoExpressionKind.INSTANCE,
          thisType,
          typeArguments,
          commonMasks.dynamicType);
      add(typeInfo);
      constructorArguments.add(typeInfo);
    }

    HInstruction newObject = new HCreate(
        cls, constructorArguments, new TypeMask.nonNullExact(cls, closedWorld),
        instantiatedTypes: <InterfaceType>[thisType], hasRtiInput: hasRtiInput);

    add(newObject);

    // Generate calls to the constructor bodies.

    for (ir.Constructor body in constructorChain.reversed) {
      if (_isEmptyStatement(body.function.body)) continue;

      List<HInstruction> bodyCallInputs = <HInstruction>[];
      bodyCallInputs.add(newObject);

      // Pass uncaptured arguments first, captured arguments in a box, then type
      // arguments.

      ConstructorElement constructorElement = _elementMap.getConstructor(body);

      void handleParameter(ir.VariableDeclaration node) {
        Local parameter = localsMap.getLocal(node);
        // If [parameter] is boxed, it will be a field in the box passed as the
        // last parameter. So no need to directly pass it.
        if (!localsHandler.isBoxed(parameter)) {
          bodyCallInputs.add(localsHandler.readLocal(parameter));
        }
      }

      // Provide the parameters to the generative constructor body.
      body.function.positionalParameters.forEach(handleParameter);
      body.function.namedParameters.toList()
        ..sort(namedOrdering)
        ..forEach(handleParameter);

      // If there are locals that escape (i.e. mutated in closures), we pass the
      // box to the constructor.
      ClosureScope scopeData = closureDataLookup
          .getClosureScope(constructorElement.resolvedAst.node);
      if (scopeData.requiresContextBox) {
        bodyCallInputs.add(localsHandler.readLocal(scopeData.context));
      }

      // Pass type arguments.
      ir.Class currentClass = body.enclosingClass;
      if (backend.rtiNeed.classNeedsRti(_elementMap.getClass(currentClass))) {
        for (ir.DartType typeParameter in currentClass.thisType.typeArguments) {
          HInstruction argument = localsHandler.readLocal(localsHandler
              .getTypeVariableAsLocal(_elementMap.getDartType(typeParameter)
                  as ResolutionTypeVariableType));
          bodyCallInputs.add(argument);
        }
      }

      _invokeConstructorBody(body, bodyCallInputs);
    }

    closeAndGotoExit(new HReturn(newObject, null));
    closeFunction();
  }

  static bool _isEmptyStatement(ir.Statement body) {
    if (body is ir.EmptyStatement) return true;
    if (body is ir.Block) return body.statements.every(_isEmptyStatement);
    return false;
  }

  void _invokeConstructorBody(
      ir.Constructor constructor, List<HInstruction> inputs) {
    // TODO(sra): Inline the constructor body.
    MemberEntity constructorBody =
        astAdapter.getConstructorBodyEntity(constructor);
    HInvokeConstructorBody invoke = new HInvokeConstructorBody(
        constructorBody, inputs, commonMasks.nonNullType);
    add(invoke);
  }

  /// Sets context for generating code that is the result of inlining
  /// [inlinedTarget].
  inlinedFrom(MemberEntity inlinedTarget, f()) {
    reporter.withCurrentElement(inlinedTarget, () {
      SourceInformationBuilder oldSourceInformationBuilder =
          sourceInformationBuilder;
      // TODO(sra): Update sourceInformationBuilder to Kernel.
      // sourceInformationBuilder =
      //   sourceInformationBuilder.forContext(resolvedAst);

      localsMap.enterInlinedMember(inlinedTarget);
      _targetStack.add(inlinedTarget);
      var result = f();
      sourceInformationBuilder = oldSourceInformationBuilder;
      _targetStack.removeLast();
      localsMap.leaveInlinedMember(inlinedTarget);
      return result;
    });
  }

  /// Maps the instance fields of a class to their SSA values.
  Map<FieldEntity, HInstruction> _collectFieldValues(ir.Class clazz) {
    Map<FieldEntity, HInstruction> fieldValues = <FieldEntity, HInstruction>{};

    for (ir.Field node in clazz.fields) {
      if (node.isInstanceMember) {
        FieldEntity field = _elementMap.getField(node);
        if (node.initializer == null) {
          fieldValues[field] = graph.addConstantNull(closedWorld);
        } else {
          // Gotta update the resolvedAst when we're looking at field values
          // outside the constructor.
          inlinedFrom(field, () {
            node.initializer.accept(this);
            fieldValues[field] = pop();
          });
        }
      }
    }

    return fieldValues;
  }

  /// Collects field initializers all the way up the inheritance chain.
  void _buildInitializers(
      ir.Constructor constructor,
      List<ir.Constructor> constructorChain,
      Map<FieldEntity, HInstruction> fieldValues) {
    assert(_elementMap.getConstructor(constructor) == localsMap.currentMember);
    constructorChain.add(constructor);

    var foundSuperOrRedirectCall = false;
    for (var initializer in constructor.initializers) {
      if (initializer is ir.FieldInitializer) {
        initializer.value.accept(this);
        fieldValues[_elementMap.getField(initializer.field)] = pop();
      } else if (initializer is ir.SuperInitializer) {
        assert(!foundSuperOrRedirectCall);
        foundSuperOrRedirectCall = true;
        _inlineSuperInitializer(
            initializer, constructorChain, fieldValues, constructor);
      } else if (initializer is ir.RedirectingInitializer) {
        assert(!foundSuperOrRedirectCall);
        foundSuperOrRedirectCall = true;
        _inlineRedirectingInitializer(
            initializer, constructorChain, fieldValues, constructor);
      } else if (initializer is ir.LocalInitializer) {
        assert(false, 'ir.LocalInitializer not handled');
      } else if (initializer is ir.InvalidInitializer) {
        assert(false, 'ir.InvalidInitializer not handled');
      }
    }

    if (!foundSuperOrRedirectCall) {
      assert(
          _elementMap.getClass(constructor.enclosingClass) ==
              _elementMap.commonElements.objectClass,
          'All constructors should have super- or redirecting- initializers,'
          ' except Object()');
    }
  }

  List<HInstruction> _normalizeAndBuildArguments(
      ir.FunctionNode function, ir.Arguments arguments) {
    var builtArguments = <HInstruction>[];
    var positionalIndex = 0;
    function.positionalParameters.forEach((ir.VariableDeclaration node) {
      if (positionalIndex < arguments.positional.length) {
        arguments.positional[positionalIndex++].accept(this);
        builtArguments.add(pop());
      } else {
        ConstantValue constantValue =
            _elementMap.getConstantValue(node.initializer, implicitNull: true);
        assert(
            constantValue != null,
            failedAt(_elementMap.getMethod(function.parent),
                'No constant computed for $node'));
        builtArguments.add(graph.addConstant(constantValue, closedWorld));
      }
    });
    function.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach((ir.VariableDeclaration node) {
        var correspondingNamed = arguments.named
            .firstWhere((named) => named.name == node.name, orElse: () => null);
        if (correspondingNamed != null) {
          correspondingNamed.value.accept(this);
          builtArguments.add(pop());
        } else {
          ConstantValue constantValue = _elementMap
              .getConstantValue(node.initializer, implicitNull: true);
          assert(
              constantValue != null,
              failedAt(_elementMap.getMethod(function.parent),
                  'No constant computed for $node'));
          builtArguments.add(graph.addConstant(constantValue, closedWorld));
        }
      });

    return builtArguments;
  }

  /// Creates localsHandler bindings for type parameters of a Supertype.
  void _bindSupertypeTypeParameters(ir.Supertype supertype) {
    ir.Class cls = supertype.classNode;
    var parameters = cls.typeParameters;
    var arguments = supertype.typeArguments;
    assert(arguments.length == parameters.length);

    for (int i = 0; i < parameters.length; i++) {
      ir.DartType argument = arguments[i];
      ir.TypeParameter parameter = parameters[i];

      localsHandler.updateLocal(
          localsHandler.getTypeVariableAsLocal(
              _elementMap.getDartType(new ir.TypeParameterType(parameter))),
          typeBuilder.analyzeTypeArgument(
              _elementMap.getDartType(argument), sourceElement));
    }
  }

  /// Inlines the given redirecting [constructor]'s initializers by collecting
  /// its field values and building its constructor initializers. We visit super
  /// constructors all the way up to the [Object] constructor.
  void _inlineRedirectingInitializer(
      ir.RedirectingInitializer initializer,
      List<ir.Constructor> constructorChain,
      Map<FieldEntity, HInstruction> fieldValues,
      ir.Constructor caller) {
    var superOrRedirectConstructor = initializer.target;
    var arguments = _normalizeAndBuildArguments(
        superOrRedirectConstructor.function, initializer.arguments);

    // Redirecting initializer already has [localsHandler] bindings for type
    // parameters from the redirecting constructor.

    // For redirecting constructors, the fields will be initialized later by the
    // effective target, so we don't do it here.

    _inlineSuperOrRedirectCommon(initializer, superOrRedirectConstructor,
        arguments, constructorChain, fieldValues, caller);
  }

  /// Inlines the given super [constructor]'s initializers by collecting its
  /// field values and building its constructor initializers. We visit super
  /// constructors all the way up to the [Object] constructor.
  void _inlineSuperInitializer(
      ir.SuperInitializer initializer,
      List<ir.Constructor> constructorChain,
      Map<FieldEntity, HInstruction> fieldValues,
      ir.Constructor caller) {
    var target = initializer.target;
    var arguments =
        _normalizeAndBuildArguments(target.function, initializer.arguments);

    ir.Class callerClass = caller.enclosingClass;
    _bindSupertypeTypeParameters(callerClass.supertype);
    if (callerClass.mixedInType != null) {
      _bindSupertypeTypeParameters(callerClass.mixedInType);
    }

    ir.Class cls = target.enclosingClass;

    inlinedFrom(_elementMap.getConstructor(target), () {
      fieldValues.addAll(_collectFieldValues(cls));
    });

    _inlineSuperOrRedirectCommon(
        initializer, target, arguments, constructorChain, fieldValues, caller);
  }

  void _inlineSuperOrRedirectCommon(
      ir.Initializer initializer,
      ir.Constructor constructor,
      List<HInstruction> arguments,
      List<ir.Constructor> constructorChain,
      Map<FieldEntity, HInstruction> fieldValues,
      ir.Constructor caller) {
    var index = 0;
    void handleParameter(ir.VariableDeclaration node) {
      Local parameter = localsMap.getLocal(node);
      HInstruction argument = arguments[index++];
      // Because we are inlining the initializer, we must update
      // what was given as parameter. This will be used in case
      // there is a parameter check expression in the initializer.
      parameters[parameter] = argument;
      localsHandler.updateLocal(parameter, argument);
    }

    constructor.function.positionalParameters.forEach(handleParameter);
    constructor.function.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach(handleParameter);

    // Set the locals handler state as if we were inlining the constructor.
    ConstructorEntity astElement = _elementMap.getConstructor(constructor);
    ClosureRepresentationInfo oldScopeInfo = localsHandler.scopeInfo;
    ClosureRepresentationInfo newScopeInfo =
        closureDataLookup.getScopeInfo(astElement);
    if (astElement is ConstructorElement) {
      // TODO(redemption): Support constructor (body) entities.
      ResolvedAst resolvedAst = astElement.resolvedAst;
      localsHandler.scopeInfo = newScopeInfo;
      if (resolvedAst.kind == ResolvedAstKind.PARSED) {
        localsHandler.enterScope(
            closureDataLookup.getClosureScope(resolvedAst.node),
            forGenerativeConstructorBody:
                astElement.isGenerativeConstructorBody);
      }
    }
    inlinedFrom(astElement, () {
      _buildInitializers(constructor, constructorChain, fieldValues);
    });
    localsHandler.scopeInfo = oldScopeInfo;
  }

  /// Builds generative constructor body.
  void buildConstructorBody(ir.Constructor constructor) {
    openFunction(constructor.function);
    _addClassTypeVariablesIfNeeded(constructor);
    constructor.function.body.accept(this);
    closeFunction();
  }

  /// Builds a SSA graph for FunctionNodes, found in FunctionExpressions and
  /// Procedures.
  void buildFunctionNode(ir.FunctionNode functionNode) {
    openFunction(functionNode);
    ir.TreeNode parent = functionNode.parent;
    if (parent is ir.Procedure && parent.kind == ir.ProcedureKind.Factory) {
      _addClassTypeVariablesIfNeeded(functionNode.parent);
    }

    // If [functionNode] is `operator==` we explicitly add a null check at the
    // beginning of the method. This is to avoid having call sites do the null
    // check.
    if (parent is ir.Procedure &&
        parent.kind == ir.ProcedureKind.Operator &&
        parent.name.name == '==') {
      FunctionEntity method = _elementMap.getMethod(parent);
      if (!backend.operatorEqHandlesNullArgument(method)) {
        handleIf(
          visitCondition: () {
            HParameterValue parameter = parameters.values.first;
            push(new HIdentity(parameter, graph.addConstantNull(closedWorld),
                null, commonMasks.boolType));
          },
          visitThen: () {
            closeAndGotoExit(new HReturn(
                graph.addConstantBool(false, closedWorld),
                // TODO(redemption): Provider source information like
                // `sourceInformationBuilder.buildImplicitReturn(method)`.
                null));
          },
          visitElse: null,
          // TODO(27394): Add sourceInformation via
          // `sourceInformationBuilder.buildIf(?)`.
        );
      }
    }
    functionNode.body.accept(this);
    closeFunction();
  }

  void addImplicitInstantiation(DartType type) {
    if (type != null) {
      currentImplicitInstantiations.add(type);
    }
  }

  void removeImplicitInstantiation(DartType type) {
    if (type != null) {
      currentImplicitInstantiations.removeLast();
    }
  }

  void openFunction([ir.FunctionNode function]) {
    Map<Local, TypeMask> parameterMap = <Local, TypeMask>{};
    if (function != null) {
      void handleParameter(ir.VariableDeclaration node) {
        Local local = localsMap.getLocal(node);
        parameterMap[local] =
            _typeInferenceMap.getInferredTypeOfParameter(local);
      }

      function.positionalParameters.forEach(handleParameter);
      function.namedParameters.toList()
        ..sort(namedOrdering)
        ..forEach(handleParameter);
    }

    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);

    localsHandler.startFunction(
        targetElement,
        closureDataLookup.getScopeInfo(targetElement),
        closureDataLookup.getClosureScope(functionNode),
        parameterMap,
        isGenerativeConstructorBody: _targetIsConstructorBody);
    close(new HGoto()).addSuccessor(block);

    open(block);
  }

  void closeFunction() {
    if (!isAborted()) closeAndGotoExit(new HGoto());
    graph.finalize();
  }

  @override
  void defaultExpression(ir.Expression expression) {
    // TODO(het): This is only to get tests working.
    _trap('Unhandled ir.${expression.runtimeType}  $expression');
  }

  @override
  void defaultStatement(ir.Statement statement) {
    _trap('Unhandled ir.${statement.runtimeType}  $statement');
    pop();
  }

  void _trap(String message) {
    HInstruction nullValue = graph.addConstantNull(closedWorld);
    HInstruction errorMessage = graph.addConstantString(message, closedWorld);
    HInstruction trap = new HForeignCode(js.js.parseForeignJS("#.#"),
        commonMasks.dynamicType, <HInstruction>[nullValue, errorMessage]);
    trap.sideEffects
      ..setAllSideEffects()
      ..setDependsOnSomething();
    push(trap);
  }

  /// Returns the current source element. This is used by the type builder.
  ///
  /// The returned element is a declaration element.
  // TODO(efortuna): Update this when we implement inlining.
  // TODO(sra): Re-implement type builder using Kernel types and the
  // `target` for context.
  @override
  MemberElement get sourceElement => _targetStack.last;

  List<MemberEntity> _targetStack = <MemberEntity>[];

  @override
  void visitCheckLibraryIsLoaded(ir.CheckLibraryIsLoaded checkLoad) {
    HInstruction prefixConstant =
        graph.addConstantString(checkLoad.import.name, closedWorld);
    PrefixElement prefixElement = astAdapter.getElement(checkLoad.import);
    HInstruction uriConstant = graph.addConstantString(
        prefixElement.deferredImport.uri.toString(), closedWorld);
    _pushStaticInvocation(
        _commonElements.checkDeferredIsLoaded,
        [prefixConstant, uriConstant],
        _typeInferenceMap
            .getReturnTypeOf(_commonElements.checkDeferredIsLoaded));
  }

  @override
  void visitLoadLibrary(ir.LoadLibrary loadLibrary) {
    // TODO(efortuna): Source information!
    push(new HInvokeStatic(
        commonElements.loadLibraryWrapper,
        [graph.addConstantString(loadLibrary.import.name, closedWorld)],
        commonMasks.nonNullType,
        targetCanThrow: false));
  }

  @override
  void visitBlock(ir.Block block) {
    assert(!isAborted());
    for (ir.Statement statement in block.statements) {
      statement.accept(this);
      if (!isReachable) {
        // The block has been aborted by a return or a throw.
        if (stack.isNotEmpty) {
          reporter.internalError(
              NO_LOCATION_SPANNABLE, 'Non-empty instruction stack.');
        }
        return;
      }
    }
    assert(!current.isClosed());
    if (stack.isNotEmpty) {
      reporter.internalError(
          NO_LOCATION_SPANNABLE, 'Non-empty instruction stack');
    }
  }

  @override
  void visitEmptyStatement(ir.EmptyStatement statement) {
    // Empty statement adds no instructions to current block.
  }

  @override
  void visitExpressionStatement(ir.ExpressionStatement exprStatement) {
    if (!isReachable) return;
    ir.Expression expression = exprStatement.expression;
    if (expression is ir.Throw) {
      // TODO(sra): Prevent generating a statement when inlining.
      _visitThrowExpression(expression.expression);
      handleInTryStatement();
      closeAndGotoExit(new HThrow(pop(), null));
    } else {
      expression.accept(this);
      pop();
    }
  }

  /// Returns true if the [type] is a valid return type for an asynchronous
  /// function.
  ///
  /// Asynchronous functions return a `Future`, and a valid return is thus
  /// either dynamic, Object, or Future.
  ///
  /// We do not accept the internal Future implementation class.
  bool isValidAsyncReturnType(DartType type) {
    // TODO(sigurdm): In an internal library a function could be declared:
    //
    // _FutureImpl foo async => 1;
    //
    // This should be valid (because the actual value returned from an async
    // function is a `_FutureImpl`), but currently false is returned in this
    // case.
    return type.isDynamic ||
        type == _commonElements.objectType ||
        (type is InterfaceType && type.element == _commonElements.futureClass);
  }

  @override
  void visitReturnStatement(ir.ReturnStatement returnStatement) {
    HInstruction value;
    if (returnStatement.expression == null) {
      value = graph.addConstantNull(closedWorld);
    } else {
      assert(_targetFunction != null && _targetFunction is ir.FunctionNode);
      returnStatement.expression.accept(this);
      value = pop();
      DartType returnType = _elementMap.getFunctionType(_targetFunction);
      if (_targetFunction.asyncMarker == ir.AsyncMarker.Async) {
        if (options.enableTypeAssertions &&
            !isValidAsyncReturnType(returnType)) {
          generateTypeError(
              returnStatement,
              "Async function returned a Future,"
              " was declared to return a ${returnType}.");
          pop();
          return;
        }
      } else {
        value = typeBuilder.potentiallyCheckOrTrustType(value, returnType);
      }
    }
    // TODO(het): Add source information
    handleInTryStatement();
    // TODO(het): Set a return value instead of closing the function when we
    // support inlining.
    closeAndGotoExit(new HReturn(value, null));
  }

  @override
  void visitForStatement(ir.ForStatement forStatement) {
    assert(isReachable);
    assert(forStatement.body != null);
    void buildInitializer() {
      for (ir.VariableDeclaration declaration in forStatement.variables) {
        declaration.accept(this);
      }
    }

    HInstruction buildCondition() {
      if (forStatement.condition == null) {
        return graph.addConstantBool(true, closedWorld);
      }
      forStatement.condition.accept(this);
      return popBoolified();
    }

    void buildUpdate() {
      for (ir.Expression expression in forStatement.updates) {
        expression.accept(this);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        pop();
      }
    }

    void buildBody() {
      forStatement.body.accept(this);
    }

    JumpTarget jumpTarget = localsMap.getJumpTargetForFor(forStatement);
    loopHandler.handleLoop(
        forStatement,
        localsMap.getLoopClosureScope(closureDataLookup, forStatement),
        jumpTarget,
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody);
  }

  @override
  void visitForInStatement(ir.ForInStatement forInStatement) {
    if (forInStatement.isAsync) {
      _buildAsyncForIn(forInStatement);
    }
    // If the expression being iterated over is a JS indexable type, we can
    // generate an optimized version of for-in that uses indexing.
    if (_typeInferenceMap.isJsIndexableIterator(forInStatement, closedWorld)) {
      _buildForInIndexable(forInStatement);
    } else {
      _buildForInIterator(forInStatement);
    }
  }

  /// Builds the graph for a for-in node with an indexable expression.
  ///
  /// In this case we build:
  ///
  ///    int end = a.length;
  ///    for (int i = 0;
  ///         i < a.length;
  ///         checkConcurrentModificationError(a.length == end, a), ++i) {
  ///      <declaredIdentifier> = a[i];
  ///      <body>
  ///    }
  _buildForInIndexable(ir.ForInStatement forInStatement) {
    SyntheticLocal indexVariable = localsHandler.createLocal('_i');

    // These variables are shared by initializer, condition, body and update.
    HInstruction array; // Set in buildInitializer.
    bool isFixed; // Set in buildInitializer.
    HInstruction originalLength = null; // Set for growable lists.

    HInstruction buildGetLength() {
      HGetLength result = new HGetLength(array, commonMasks.positiveIntType,
          isAssignable: !isFixed);
      add(result);
      return result;
    }

    void buildConcurrentModificationErrorCheck() {
      if (originalLength == null) return;
      // The static call checkConcurrentModificationError() is expanded in
      // codegen to:
      //
      //     array.length == _end || throwConcurrentModificationError(array)
      //
      HInstruction length = buildGetLength();
      push(new HIdentity(length, originalLength, null, commonMasks.boolType));
      _pushStaticInvocation(
          _commonElements.checkConcurrentModificationError,
          [pop(), array],
          _typeInferenceMap.getReturnTypeOf(
              _commonElements.checkConcurrentModificationError));
      pop();
    }

    void buildInitializer() {
      forInStatement.iterable.accept(this);
      array = pop();
      isFixed =
          _typeInferenceMap.isFixedLength(array.instructionType, closedWorld);
      localsHandler.updateLocal(
          indexVariable, graph.addConstantInt(0, closedWorld));
      originalLength = buildGetLength();
    }

    HInstruction buildCondition() {
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction length = buildGetLength();
      HInstruction compare =
          new HLess(index, length, null, commonMasks.boolType);
      add(compare);
      return compare;
    }

    void buildBody() {
      // If we had mechanically inlined ArrayIterator.moveNext(), it would have
      // inserted the ConcurrentModificationError check as part of the
      // condition.  It is not necessary on the first iteration since there is
      // no code between calls to `get iterator` and `moveNext`, so the test is
      // moved to the loop update.

      // Find a type for the element. Use the element type of the indexer of the
      // array, as this is stronger than the iterator's `get current` type, for
      // example, `get current` includes null.
      // TODO(sra): The element type of a container type mask might be better.
      TypeMask type = _typeInferenceMap.inferredIndexType(forInStatement);

      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction value = new HIndex(array, index, null, type);
      add(value);

      Local loopVariableLocal = localsMap.getLocal(forInStatement.variable);
      localsHandler.updateLocal(loopVariableLocal, value);
      // Hint to name loop value after name of loop variable.
      if (loopVariableLocal is! SyntheticLocal) {
        value.sourceElement ??= loopVariableLocal;
      }

      forInStatement.body.accept(this);
    }

    void buildUpdate() {
      // See buildBody as to why we check here.
      buildConcurrentModificationErrorCheck();

      // TODO(sra): It would be slightly shorter to generate `a[i++]` in the
      // body (and that more closely follows what an inlined iterator would do)
      // but the code is horrible as `i+1` is carried around the loop in an
      // additional variable.
      HInstruction index = localsHandler.readLocal(indexVariable);
      HInstruction one = graph.addConstantInt(1, closedWorld);
      HInstruction addInstruction =
          new HAdd(index, one, null, commonMasks.positiveIntType);
      add(addInstruction);
      localsHandler.updateLocal(indexVariable, addInstruction);
    }

    loopHandler.handleLoop(
        forInStatement,
        localsMap.getLoopClosureScope(closureDataLookup, forInStatement),
        localsMap.getJumpTargetForForIn(forInStatement),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody);
  }

  _buildForInIterator(ir.ForInStatement forInStatement) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator;
    //   while ($iter.moveNext()) {
    //     <variable> = $iter.current;
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;

    void buildInitializer() {
      TypeMask mask = _typeInferenceMap.typeOfIterator(forInStatement);
      forInStatement.iterable.accept(this);
      HInstruction receiver = pop();
      _pushDynamicInvocation(forInStatement, mask, <HInstruction>[receiver],
          selector: Selectors.iterator);
      iterator = pop();
    }

    HInstruction buildCondition() {
      TypeMask mask = _typeInferenceMap.typeOfIteratorMoveNext(forInStatement);
      _pushDynamicInvocation(forInStatement, mask, <HInstruction>[iterator],
          selector: Selectors.moveNext);
      return popBoolified();
    }

    void buildBody() {
      TypeMask mask = _typeInferenceMap.typeOfIteratorCurrent(forInStatement);
      _pushDynamicInvocation(forInStatement, mask, [iterator],
          selector: Selectors.current);
      Local loopVariableLocal = localsMap.getLocal(forInStatement.variable);
      HInstruction value = pop();
      localsHandler.updateLocal(loopVariableLocal, value);
      // Hint to name loop value after name of loop variable.
      if (loopVariableLocal is! SyntheticLocal) {
        value.sourceElement ??= loopVariableLocal;
      }
      forInStatement.body.accept(this);
    }

    loopHandler.handleLoop(
        forInStatement,
        localsMap.getLoopClosureScope(closureDataLookup, forInStatement),
        localsMap.getJumpTargetForForIn(forInStatement),
        buildInitializer,
        buildCondition,
        () {},
        buildBody);
  }

  void _buildAsyncForIn(ir.ForInStatement forInStatement) {
    // The async-for is implemented with a StreamIterator.
    HInstruction streamIterator;

    forInStatement.iterable.accept(this);
    _pushStaticInvocation(
        _commonElements.streamIteratorConstructor,
        [pop(), graph.addConstantNull(closedWorld)],
        _typeInferenceMap
            .getReturnTypeOf(_commonElements.streamIteratorConstructor));
    streamIterator = pop();

    void buildInitializer() {}

    HInstruction buildCondition() {
      TypeMask mask = _typeInferenceMap.typeOfIteratorMoveNext(forInStatement);
      _pushDynamicInvocation(forInStatement, mask, [streamIterator],
          selector: Selectors.moveNext);
      HInstruction future = pop();
      push(new HAwait(future, closedWorld.commonMasks.dynamicType));
      return popBoolified();
    }

    void buildBody() {
      TypeMask mask = _typeInferenceMap.typeOfIteratorCurrent(forInStatement);
      _pushDynamicInvocation(forInStatement, mask, [streamIterator],
          selector: Selectors.current);
      localsHandler.updateLocal(
          localsMap.getLocal(forInStatement.variable), pop());
      forInStatement.body.accept(this);
    }

    void buildUpdate() {}

    // Creates a synthetic try/finally block in case anything async goes amiss.
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(this);
    // Build fake try body:
    loopHandler.handleLoop(
        forInStatement,
        localsMap.getLoopClosureScope(closureDataLookup, forInStatement),
        localsMap.getJumpTargetForForIn(forInStatement),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody);

    void finalizerFunction() {
      _pushDynamicInvocation(forInStatement, null, [streamIterator],
          selector: Selectors.cancel);
      add(new HAwait(pop(), closedWorld.commonMasks.dynamicType));
    }

    tryBuilder
      ..closeTryBody()
      ..buildFinallyBlock(finalizerFunction)
      ..cleanUp();
  }

  HInstruction callSetRuntimeTypeInfo(
      HInstruction typeInfo, HInstruction newObject) {
    // Set the runtime type information on the object.
    FunctionEntity typeInfoSetterFn = _commonElements.setRuntimeTypeInfo;
    // TODO(efortuna): Insert source information in this static invocation.
    _pushStaticInvocation(typeInfoSetterFn, <HInstruction>[newObject, typeInfo],
        commonMasks.dynamicType);

    // The new object will now be referenced through the
    // `setRuntimeTypeInfo` call. We therefore set the type of that
    // instruction to be of the object's type.
    assert(
        stack.last is HInvokeStatic || stack.last == newObject,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE,
            "Unexpected `stack.last`: Found ${stack.last}, "
            "expected ${newObject} or an HInvokeStatic. "
            "State: typeInfo=$typeInfo, stack=$stack."));
    stack.last.instructionType = newObject.instructionType;
    return pop();
  }

  @override
  void visitWhileStatement(ir.WhileStatement whileStatement) {
    assert(isReachable);
    HInstruction buildCondition() {
      whileStatement.condition.accept(this);
      return popBoolified();
    }

    loopHandler.handleLoop(
        whileStatement,
        localsMap.getLoopClosureScope(closureDataLookup, whileStatement),
        localsMap.getJumpTargetForWhile(whileStatement),
        () {},
        buildCondition,
        () {}, () {
      whileStatement.body.accept(this);
    });
  }

  @override
  visitDoStatement(ir.DoStatement doStatement) {
    // TODO(efortuna): I think this can be rewritten using
    // LoopHandler.handleLoop with some tricks about when the "update" happens.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    LoopClosureScope loopClosureInfo =
        localsMap.getLoopClosureScope(closureDataLookup, doStatement);
    localsHandler.startLoop(loopClosureInfo);
    JumpTarget target = localsMap.getJumpTargetForDo(doStatement);
    JumpHandler jumpHandler = loopHandler.beginLoopHeader(doStatement, target);
    HLoopInformation loopInfo = current.loopInformation;
    HBasicBlock loopEntryBlock = current;
    HBasicBlock bodyEntryBlock = current;
    bool hasContinues = target != null && target.isContinueTarget;
    if (hasContinues) {
      // Add extra block to hang labels on.
      // It doesn't currently work if they are on the same block as the
      // HLoopInfo. The handling of HLabeledBlockInformation will visit a
      // SubGraph that starts at the same block again, so the HLoopInfo is
      // either handled twice, or it's handled after the labeled block info,
      // both of which generate the wrong code.
      // Using a separate block is just a simple workaround.
      bodyEntryBlock = openNewBlock();
    }
    localsHandler.enterLoopBody(loopClosureInfo);
    doStatement.body.accept(this);

    // If there are no continues we could avoid the creation of the condition
    // block. This could also lead to a block having multiple entries and exits.
    HBasicBlock bodyExitBlock;
    bool isAbortingBody = false;
    if (current != null) {
      bodyExitBlock = close(new HGoto());
    } else {
      isAbortingBody = true;
      bodyExitBlock = lastOpenedBlock;
    }

    SubExpression conditionExpression;
    bool loopIsDegenerate = isAbortingBody && !hasContinues;
    if (!loopIsDegenerate) {
      HBasicBlock conditionBlock = addNewBlock();

      List<LocalsHandler> continueHandlers = <LocalsHandler>[];
      jumpHandler
          .forEachContinue((HContinue instruction, LocalsHandler locals) {
        instruction.block.addSuccessor(conditionBlock);
        continueHandlers.add(locals);
      });

      if (!isAbortingBody) {
        bodyExitBlock.addSuccessor(conditionBlock);
      }

      if (!continueHandlers.isEmpty) {
        if (!isAbortingBody) continueHandlers.add(localsHandler);
        localsHandler =
            savedLocals.mergeMultiple(continueHandlers, conditionBlock);
        SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);
        List<LabelDefinition> labels = jumpHandler.labels;
        HSubGraphBlockInformation bodyInfo =
            new HSubGraphBlockInformation(bodyGraph);
        HLabeledBlockInformation info;
        if (!labels.isEmpty) {
          info =
              new HLabeledBlockInformation(bodyInfo, labels, isContinue: true);
        } else {
          info = new HLabeledBlockInformation.implicit(bodyInfo, target,
              isContinue: true);
        }
        bodyEntryBlock.setBlockFlow(info, conditionBlock);
      }
      open(conditionBlock);

      doStatement.condition.accept(this);
      assert(!isAborted());
      HInstruction conditionInstruction = popBoolified();
      HBasicBlock conditionEndBlock = close(
          new HLoopBranch(conditionInstruction, HLoopBranch.DO_WHILE_LOOP));

      HBasicBlock avoidCriticalEdge = addNewBlock();
      conditionEndBlock.addSuccessor(avoidCriticalEdge);
      open(avoidCriticalEdge);
      close(new HGoto());
      avoidCriticalEdge.addSuccessor(loopEntryBlock); // The back-edge.

      conditionExpression =
          new SubExpression(conditionBlock, conditionEndBlock);

      // Avoid a critical edge from the condition to the loop-exit body.
      HBasicBlock conditionExitBlock = addNewBlock();
      open(conditionExitBlock);
      close(new HGoto());
      conditionEndBlock.addSuccessor(conditionExitBlock);

      loopHandler.endLoop(
          loopEntryBlock, conditionExitBlock, jumpHandler, localsHandler);

      loopEntryBlock.postProcessLoopHeader();
      SubGraph bodyGraph = new SubGraph(loopEntryBlock, bodyExitBlock);
      HLoopBlockInformation loopBlockInfo = new HLoopBlockInformation(
          HLoopBlockInformation.DO_WHILE_LOOP,
          null,
          wrapExpressionGraph(conditionExpression),
          wrapStatementGraph(bodyGraph),
          null,
          loopEntryBlock.loopInformation.target,
          loopEntryBlock.loopInformation.labels,
          // TODO(redemption): Provide source information like:
          // sourceInformationBuilder.buildLoop(astAdapter.getNode(doStatement))
          null);
      loopEntryBlock.setBlockFlow(loopBlockInfo, current);
      loopInfo.loopBlockInformation = loopBlockInfo;
    } else {
      // Since the loop has no back edge, we remove the loop information on the
      // header.
      loopEntryBlock.loopInformation = null;

      if (jumpHandler.hasAnyBreak()) {
        // Null branchBlock because the body of the do-while loop always aborts,
        // so we never get to the condition.
        loopHandler.endLoop(loopEntryBlock, null, jumpHandler, localsHandler);

        // Since the body of the loop has a break, we attach a synthesized label
        // to the body.
        SubGraph bodyGraph = new SubGraph(bodyEntryBlock, bodyExitBlock);
        JumpTarget target = localsMap.getJumpTargetForDo(doStatement);
        LabelDefinition label =
            target.addLabel(null, 'loop', isBreakTarget: true);
        HLabeledBlockInformation info = new HLabeledBlockInformation(
            new HSubGraphBlockInformation(bodyGraph), <LabelDefinition>[label]);
        loopEntryBlock.setBlockFlow(info, current);
        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
  }

  @override
  void visitIfStatement(ir.IfStatement ifStatement) {
    handleIf(
        visitCondition: () => ifStatement.condition.accept(this),
        visitThen: () => ifStatement.then.accept(this),
        visitElse: () => ifStatement.otherwise?.accept(this));
  }

  void handleIf(
      {ir.Node node,
      void visitCondition(),
      void visitThen(),
      void visitElse(),
      SourceInformation sourceInformation}) {
    SsaBranchBuilder branchBuilder = new SsaBranchBuilder(this,
        node == null ? node : _elementMap.getSpannable(targetElement, node));
    branchBuilder.handleIf(visitCondition, visitThen, visitElse,
        sourceInformation: sourceInformation);
  }

  @override
  void visitAsExpression(ir.AsExpression asExpression) {
    asExpression.operand.accept(this);
    HInstruction expressionInstruction = pop();

    if (asExpression.type is ir.InvalidType) {
      generateTypeError(asExpression, 'invalid type');
      stack.add(expressionInstruction);
      return;
    }

    ResolutionDartType type = _elementMap.getDartType(asExpression.type);
    if (type.isMalformed) {
      if (type is MalformedType) {
        ErroneousElement element = type.element;
        generateTypeError(asExpression, element.message);
      } else {
        assert(type is MethodTypeVariableType);
        stack.add(expressionInstruction);
      }
    } else {
      HInstruction converted = typeBuilder.buildTypeConversion(
          expressionInstruction,
          localsHandler.substInContext(type),
          HTypeConversion.CAST_TYPE_CHECK);
      if (converted != expressionInstruction) {
        add(converted);
      }
      stack.add(converted);
    }
  }

  void generateError(ir.Node node, FunctionEntity function, String message,
      TypeMask typeMask) {
    HInstruction errorMessage = graph.addConstantString(message, closedWorld);
    // TODO(sra): Associate source info from [node].
    _pushStaticInvocation(function, [errorMessage], typeMask);
  }

  void generateTypeError(ir.Node node, String message) {
    generateError(node, _commonElements.throwTypeError, message,
        _typeInferenceMap.getReturnTypeOf(_commonElements.throwTypeError));
  }

  void generateUnsupportedError(ir.Node node, String message) {
    generateError(
        node,
        _commonElements.throwUnsupportedError,
        message,
        _typeInferenceMap
            .getReturnTypeOf(_commonElements.throwUnsupportedError));
  }

  @override
  void visitAssertStatement(ir.AssertStatement assertStatement) {
    if (!options.enableUserAssertions) return;
    if (assertStatement.message == null) {
      assertStatement.condition.accept(this);
      _pushStaticInvocation(_commonElements.assertHelper, <HInstruction>[pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertHelper));
      pop();
      return;
    }

    // if (assertTest(condition)) assertThrow(message);
    void buildCondition() {
      assertStatement.condition.accept(this);
      _pushStaticInvocation(_commonElements.assertTest, <HInstruction>[pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertTest));
    }

    void fail() {
      assertStatement.message.accept(this);
      _pushStaticInvocation(_commonElements.assertThrow, <HInstruction>[pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertThrow));
      pop();
    }

    handleIf(visitCondition: buildCondition, visitThen: fail);
  }

  /// Creates a [JumpHandler] for a statement. The node must be a jump
  /// target. If there are no breaks or continues targeting the statement,
  /// a special "null handler" is returned.
  ///
  /// [isLoopJump] is true when the jump handler is for a loop. This is used
  /// to distinguish the synthesized loop created for a switch statement with
  /// continue statements from simple switch statements.
  JumpHandler createJumpHandler(ir.TreeNode node, JumpTarget target,
      {bool isLoopJump: false}) {
    if (target == null) {
      // No breaks or continues to this node.
      return new NullJumpHandler(reporter);
    }
    if (isLoopJump && node is ir.SwitchStatement) {
      return new KernelSwitchCaseJumpHandler(this, target, node, localsMap);
    }

    return new JumpHandler(this, target);
  }

  @override
  void visitBreakStatement(ir.BreakStatement breakStatement) {
    assert(!isAborted());
    handleInTryStatement();
    JumpTarget target = localsMap.getJumpTargetForBreak(breakStatement);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    if (localsMap.generateContinueForBreak(breakStatement)) {
      if (handler.labels.isNotEmpty) {
        handler.generateContinue(handler.labels.first);
      } else {
        handler.generateContinue();
      }
    } else {
      if (handler.labels.isNotEmpty) {
        handler.generateBreak(handler.labels.first);
      } else {
        handler.generateBreak();
      }
    }
  }

  @override
  void visitLabeledStatement(ir.LabeledStatement labeledStatement) {
    ir.Statement body = labeledStatement.body;
    if (body is ir.WhileStatement ||
        body is ir.DoStatement ||
        body is ir.ForStatement ||
        body is ir.ForInStatement ||
        body is ir.SwitchStatement) {
      // loops and switches handle breaks on their own
      body.accept(this);
      return;
    }
    JumpTarget jumpTarget = localsMap.getJumpTargetForLabel(labeledStatement);
    if (jumpTarget == null) {
      // The label is not needed.
      body.accept(this);
      return;
    }

    JumpHandler handler = createJumpHandler(labeledStatement, jumpTarget);

    LocalsHandler beforeLocals = new LocalsHandler.from(localsHandler);

    HBasicBlock newBlock = openNewBlock();
    body.accept(this);
    SubGraph bodyGraph = new SubGraph(newBlock, lastOpenedBlock);

    HBasicBlock joinBlock = graph.addNewBlock();
    List<LocalsHandler> breakHandlers = <LocalsHandler>[];
    handler.forEachBreak((HBreak breakInstruction, LocalsHandler locals) {
      breakInstruction.block.addSuccessor(joinBlock);
      breakHandlers.add(locals);
    });

    if (!isAborted()) {
      goto(current, joinBlock);
      breakHandlers.add(localsHandler);
    }

    open(joinBlock);
    localsHandler = beforeLocals.mergeMultiple(breakHandlers, joinBlock);

    // There was at least one reachable break, so the label is needed.
    newBlock.setBlockFlow(
        new HLabeledBlockInformation(
            new HSubGraphBlockInformation(bodyGraph), handler.labels),
        joinBlock);
    handler.close();
  }

  /// Loop through the cases in a switch and create a mapping of case
  /// expressions to constants.
  Map<ir.Expression, ConstantValue> _buildSwitchCaseConstants(
      ir.SwitchStatement switchStatement) {
    Map<ir.Expression, ConstantValue> constants =
        new Map<ir.Expression, ConstantValue>();
    for (ir.SwitchCase switchCase in switchStatement.cases) {
      for (ir.Expression caseExpression in switchCase.expressions) {
        ConstantValue constant = _elementMap.getConstantValue(caseExpression);
        constants[caseExpression] = constant;
      }
    }
    return constants;
  }

  @override
  void visitContinueSwitchStatement(
      ir.ContinueSwitchStatement switchStatement) {
    handleInTryStatement();
    JumpTarget target =
        localsMap.getJumpTargetForContinueSwitch(switchStatement);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    assert(target.labels.isNotEmpty);
    handler.generateContinue(target.labels.first);
  }

  @override
  void visitSwitchStatement(ir.SwitchStatement switchStatement) {
    // The switch case indices must match those computed in
    // [KernelSwitchCaseJumpHandler].
    bool hasContinue = false;
    Map<ir.SwitchCase, int> caseIndex = new Map<ir.SwitchCase, int>();
    int switchIndex = 1;
    bool hasDefault = false;
    for (ir.SwitchCase switchCase in switchStatement.cases) {
      if (_isDefaultCase(switchCase)) {
        hasDefault = true;
      }
      if (SwitchContinueAnalysis.containsContinue(switchCase.body)) {
        hasContinue = true;
      }
      caseIndex[switchCase] = switchIndex;
      switchIndex++;
    }

    JumpHandler jumpHandler = createJumpHandler(
        switchStatement, localsMap.getJumpTargetForSwitch(switchStatement));
    if (!hasContinue) {
      // If the switch statement has no switch cases targeted by continue
      // statements we encode the switch statement directly.
      _buildSimpleSwitchStatement(switchStatement, jumpHandler);
    } else {
      _buildComplexSwitchStatement(
          switchStatement, jumpHandler, caseIndex, hasDefault);
    }
  }

  /// Helper for building switch statements.
  static bool _isDefaultCase(ir.SwitchCase switchCase) =>
      switchCase == null || switchCase.isDefault;

  /// Helper for building switch statements.
  HInstruction _buildExpression(ir.SwitchStatement switchStatement) {
    switchStatement.expression.accept(this);
    return pop();
  }

  /// Helper method for creating the list of constants that make up the
  /// switch case branches.
  List<ConstantValue> _getSwitchConstants(
      ir.SwitchStatement parentSwitch, ir.SwitchCase switchCase) {
    Map<ir.Expression, ConstantValue> constantsLookup =
        _buildSwitchCaseConstants(parentSwitch);
    List<ConstantValue> constantList = <ConstantValue>[];
    if (switchCase != null) {
      for (var expression in switchCase.expressions) {
        constantList.add(constantsLookup[expression]);
      }
    }
    return constantList;
  }

  /// Builds a simple switch statement which does not handle uses of continue
  /// statements to labeled switch cases.
  void _buildSimpleSwitchStatement(
      ir.SwitchStatement switchStatement, JumpHandler jumpHandler) {
    void buildSwitchCase(ir.SwitchCase switchCase) {
      switchCase.body.accept(this);
    }

    _handleSwitch(
        switchStatement,
        jumpHandler,
        _buildExpression,
        switchStatement.cases,
        _getSwitchConstants,
        _isDefaultCase,
        buildSwitchCase);
    jumpHandler.close();
  }

  /// Builds a switch statement that can handle arbitrary uses of continue
  /// statements to labeled switch cases.
  void _buildComplexSwitchStatement(
      ir.SwitchStatement switchStatement,
      JumpHandler jumpHandler,
      Map<ir.SwitchCase, int> caseIndex,
      bool hasDefault) {
    // If the switch statement has switch cases targeted by continue
    // statements we create the following encoding:
    //
    //   switch (e) {
    //     l_1: case e0: s_1; break;
    //     l_2: case e1: s_2; continue l_i;
    //     ...
    //     l_n: default: s_n; continue l_j;
    //   }
    //
    // is encoded as
    //
    //   var target;
    //   switch (e) {
    //     case e1: target = 1; break;
    //     case e2: target = 2; break;
    //     ...
    //     default: target = n; break;
    //   }
    //   l: while (true) {
    //    switch (target) {
    //       case 1: s_1; break l;
    //       case 2: s_2; target = i; continue l;
    //       ...
    //       case n: s_n; target = j; continue l;
    //     }
    //   }
    //
    // This is because JS does not have this same "continue label" semantics so
    // we encode it in the form of a state machine.

    JumpTarget switchTarget = localsMap.getJumpTargetForSwitch(switchStatement);
    localsHandler.updateLocal(switchTarget, graph.addConstantNull(closedWorld));

    var switchCases = switchStatement.cases;
    if (!hasDefault) {
      // Use null as the marker for a synthetic default clause.
      // The synthetic default is added because otherwise there would be no
      // good place to give a default value to the local.
      switchCases = new List<ir.SwitchCase>.from(switchCases);
      switchCases.add(null);
    }

    void buildSwitchCase(ir.SwitchCase switchCase) {
      if (switchCase != null) {
        // Generate 'target = i; break;' for switch case i.
        int index = caseIndex[switchCase];
        HInstruction value = graph.addConstantInt(index, closedWorld);
        localsHandler.updateLocal(switchTarget, value);
      } else {
        // Generate synthetic default case 'target = null; break;'.
        HInstruction nullValue = graph.addConstantNull(closedWorld);
        localsHandler.updateLocal(switchTarget, nullValue);
      }
      jumpTargets[switchTarget].generateBreak();
    }

    _handleSwitch(switchStatement, jumpHandler, _buildExpression, switchCases,
        _getSwitchConstants, _isDefaultCase, buildSwitchCase);
    jumpHandler.close();

    HInstruction buildCondition() => graph.addConstantBool(true, closedWorld);

    void buildSwitch() {
      HInstruction buildExpression(ir.SwitchStatement notUsed) {
        return localsHandler.readLocal(switchTarget);
      }

      List<ConstantValue> getConstants(
          ir.SwitchStatement parentSwitch, ir.SwitchCase switchCase) {
        return <ConstantValue>[constantSystem.createInt(caseIndex[switchCase])];
      }

      void buildSwitchCase(ir.SwitchCase switchCase) {
        switchCase.body.accept(this);
        if (!isAborted()) {
          // Ensure that we break the loop if the case falls through. (This
          // is only possible for the last case.)
          jumpTargets[switchTarget].generateBreak();
        }
      }

      // Pass a [NullJumpHandler] because the target for the contained break
      // is not the generated switch statement but instead the loop generated
      // in the call to [handleLoop] below.
      _handleSwitch(
          switchStatement, // nor is buildExpression.
          new NullJumpHandler(reporter),
          buildExpression,
          switchStatement.cases,
          getConstants,
          (_) => false, // No case is default.
          buildSwitchCase);
    }

    void buildLoop() {
      loopHandler.handleLoop(
          switchStatement,
          localsMap.getLoopClosureScope(closureDataLookup, switchStatement),
          switchTarget,
          () {},
          buildCondition,
          () {},
          buildSwitch);
    }

    if (hasDefault) {
      buildLoop();
    } else {
      // If the switch statement has no default case, surround the loop with
      // a test of the target. So:
      // `if (target) while (true) ...` If there's no default case, target is
      // null, so we don't drop into the while loop.
      void buildCondition() {
        js.Template code = js.js.parseForeignJS('#');
        push(new HForeignCode(
            code, commonMasks.boolType, [localsHandler.readLocal(switchTarget)],
            nativeBehavior: native.NativeBehavior.PURE));
      }

      handleIf(
          node: switchStatement,
          visitCondition: buildCondition,
          visitThen: buildLoop,
          visitElse: () => {});
    }
  }

  /// Creates a switch statement.
  ///
  /// [jumpHandler] is the [JumpHandler] for the created switch statement.
  /// [buildSwitchCase] creates the statements for the switch case.
  void _handleSwitch(
      ir.SwitchStatement switchStatement,
      JumpHandler jumpHandler,
      HInstruction buildExpression(ir.SwitchStatement statement),
      List<ir.SwitchCase> switchCases,
      List<ConstantValue> getConstants(
          ir.SwitchStatement parentSwitch, ir.SwitchCase switchCase),
      bool isDefaultCase(ir.SwitchCase switchCase),
      void buildSwitchCase(ir.SwitchCase switchCase)) {
    HBasicBlock expressionStart = openNewBlock();
    HInstruction expression = buildExpression(switchStatement);

    if (switchCases.isEmpty) {
      return;
    }

    HSwitch switchInstruction = new HSwitch(<HInstruction>[expression]);
    HBasicBlock expressionEnd = close(switchInstruction);
    LocalsHandler savedLocals = localsHandler;

    List<HStatementInformation> statements = <HStatementInformation>[];
    bool hasDefault = false;
    for (ir.SwitchCase switchCase in switchCases) {
      HBasicBlock block = graph.addNewBlock();
      for (ConstantValue constant
          in getConstants(switchStatement, switchCase)) {
        HConstant hConstant = graph.addConstant(constant, closedWorld);
        switchInstruction.inputs.add(hConstant);
        hConstant.usedBy.add(switchInstruction);
        expressionEnd.addSuccessor(block);
      }

      if (isDefaultCase(switchCase)) {
        // An HSwitch has n inputs and n+1 successors, the last being the
        // default case.
        expressionEnd.addSuccessor(block);
        hasDefault = true;
      }
      open(block);
      localsHandler = new LocalsHandler.from(savedLocals);
      buildSwitchCase(switchCase);
      statements.add(
          new HSubGraphBlockInformation(new SubGraph(block, lastOpenedBlock)));
    }

    // Add a join-block if necessary.
    // We create [joinBlock] early, and then go through the cases that might
    // want to jump to it. In each case, if we add [joinBlock] as a successor
    // of another block, we also add an element to [caseHandlers] that is used
    // to create the phis in [joinBlock].
    // If we never jump to the join block, [caseHandlers] will stay empty, and
    // the join block is never added to the graph.
    HBasicBlock joinBlock = new HBasicBlock();
    List<LocalsHandler> caseHandlers = <LocalsHandler>[];
    jumpHandler.forEachBreak((HBreak instruction, LocalsHandler locals) {
      instruction.block.addSuccessor(joinBlock);
      caseHandlers.add(locals);
    });
    jumpHandler.forEachContinue((HContinue instruction, LocalsHandler locals) {
      assert(
          false,
          failedAt(_elementMap.getSpannable(targetElement, switchStatement),
              'Continue cannot target a switch.'));
    });
    if (!isAborted()) {
      current.close(new HGoto());
      lastOpenedBlock.addSuccessor(joinBlock);
      caseHandlers.add(localsHandler);
    }
    if (!hasDefault) {
      // Always create a default case, to avoid a critical edge in the
      // graph.
      HBasicBlock defaultCase = addNewBlock();
      expressionEnd.addSuccessor(defaultCase);
      open(defaultCase);
      close(new HGoto());
      defaultCase.addSuccessor(joinBlock);
      caseHandlers.add(savedLocals);
      statements.add(new HSubGraphBlockInformation(
          new SubGraph(defaultCase, defaultCase)));
    }
    assert(caseHandlers.length == joinBlock.predecessors.length);
    if (caseHandlers.length != 0) {
      graph.addBlock(joinBlock);
      open(joinBlock);
      if (caseHandlers.length == 1) {
        localsHandler = caseHandlers[0];
      } else {
        localsHandler = savedLocals.mergeMultiple(caseHandlers, joinBlock);
      }
    } else {
      // The joinblock is not used.
      joinBlock = null;
    }

    HSubExpressionBlockInformation expressionInfo =
        new HSubExpressionBlockInformation(
            new SubExpression(expressionStart, expressionEnd));
    expressionStart.setBlockFlow(
        new HSwitchBlockInformation(
            expressionInfo, statements, jumpHandler.target, jumpHandler.labels),
        joinBlock);

    jumpHandler.close();
  }

  @override
  void visitConditionalExpression(ir.ConditionalExpression conditional) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this);
    brancher.handleConditional(
        () => conditional.condition.accept(this),
        () => conditional.then.accept(this),
        () => conditional.otherwise.accept(this));
  }

  @override
  void visitLogicalExpression(ir.LogicalExpression logicalExpression) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this);
    String operator = logicalExpression.operator;
    // ir.LogicalExpression claims to allow '??' as an operator but currently
    // that is expanded into a let-tree.
    assert(operator == '&&' || operator == '||');
    _handleLogicalExpression(logicalExpression.left,
        () => logicalExpression.right.accept(this), brancher, operator);
  }

  /// Optimizes logical binary expression where the left has the same logical
  /// binary operator.
  ///
  /// This method transforms the operator by optimizing the case where [left] is
  /// a logical "and" or logical "or". Then it uses [branchBuilder] to build the
  /// graph for the optimized expression.
  ///
  /// For example, `(x && y) && z` is transformed into `x && (y && z)`:
  ///
  void _handleLogicalExpression(ir.Expression left, void visitRight(),
      SsaBranchBuilder brancher, String operator) {
    if (left is ir.LogicalExpression && left.operator == operator) {
      ir.Expression innerLeft = left.left;
      ir.Expression middle = left.right;
      _handleLogicalExpression(
          innerLeft,
          () =>
              _handleLogicalExpression(middle, visitRight, brancher, operator),
          brancher,
          operator);
    } else {
      brancher.handleLogicalBinary(() => left.accept(this), visitRight,
          isAnd: operator == '&&');
    }
  }

  @override
  void visitIntLiteral(ir.IntLiteral intLiteral) {
    stack.add(graph.addConstantInt(intLiteral.value, closedWorld));
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral doubleLiteral) {
    stack.add(graph.addConstantDouble(doubleLiteral.value, closedWorld));
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral boolLiteral) {
    stack.add(graph.addConstantBool(boolLiteral.value, closedWorld));
  }

  @override
  void visitStringLiteral(ir.StringLiteral stringLiteral) {
    stack.add(graph.addConstantString(stringLiteral.value, closedWorld));
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral symbolLiteral) {
    stack.add(graph.addConstant(
        _elementMap.getConstantValue(symbolLiteral), closedWorld));
    registry?.registerConstSymbol(symbolLiteral.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral nullLiteral) {
    stack.add(graph.addConstantNull(closedWorld));
  }

  /// Set the runtime type information if necessary.
  HInstruction _setListRuntimeTypeInfoIfNeeded(
      HInstruction object, ir.ListLiteral listLiteral) {
    InterfaceType type = localsHandler.substInContext(_commonElements
        .listType(_elementMap.getDartType(listLiteral.typeArgument)));
    if (!rtiNeed.classNeedsRti(type.element) || type.treatAsRaw) {
      return object;
    }
    List<HInstruction> arguments = <HInstruction>[];
    for (DartType argument in type.typeArguments) {
      arguments.add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
    }
    // TODO(15489): Register at codegen.
    registry?.registerInstantiation(type);
    return callSetRuntimeTypeInfoWithTypeArguments(type, arguments, object);
  }

  @override
  void visitListLiteral(ir.ListLiteral listLiteral) {
    HInstruction listInstruction;
    if (listLiteral.isConst) {
      listInstruction = graph.addConstant(
          _elementMap.getConstantValue(listLiteral), closedWorld);
    } else {
      List<HInstruction> elements = <HInstruction>[];
      for (ir.Expression element in listLiteral.expressions) {
        element.accept(this);
        elements.add(pop());
      }
      listInstruction =
          new HLiteralList(elements, commonMasks.extendableArrayType);
      add(listInstruction);
      listInstruction =
          _setListRuntimeTypeInfoIfNeeded(listInstruction, listLiteral);
    }

    TypeMask type = _typeInferenceMap.typeOfListLiteral(
        targetElement, listLiteral, closedWorld);
    if (!type.containsAll(closedWorld)) {
      listInstruction.instructionType = type;
    }
    stack.add(listInstruction);
  }

  @override
  void visitMapLiteral(ir.MapLiteral mapLiteral) {
    if (mapLiteral.isConst) {
      stack.add(graph.addConstant(
          _elementMap.getConstantValue(mapLiteral), closedWorld));
      return;
    }

    // The map literal constructors take the key-value pairs as a List
    List<HInstruction> constructorArgs = <HInstruction>[];
    for (ir.MapEntry mapEntry in mapLiteral.entries) {
      mapEntry.accept(this);
      constructorArgs.add(pop());
      constructorArgs.add(pop());
    }

    // The constructor is a procedure because it's a factory.
    FunctionEntity constructor;
    List<HInstruction> inputs = <HInstruction>[];
    if (constructorArgs.isEmpty) {
      constructor = _commonElements.mapLiteralConstructorEmpty;
    } else {
      constructor = _commonElements.mapLiteralConstructor;
      HLiteralList argList =
          new HLiteralList(constructorArgs, commonMasks.extendableArrayType);
      add(argList);
      inputs.add(argList);
    }

    assert(
        constructor is ConstructorEntity && constructor.isFactoryConstructor);

    InterfaceType type = localsHandler.substInContext(_commonElements.mapType(
        _elementMap.getDartType(mapLiteral.keyType),
        _elementMap.getDartType(mapLiteral.valueType)));
    ClassEntity cls = constructor.enclosingClass;

    if (rtiNeed.classNeedsRti(cls)) {
      List<HInstruction> typeInputs = <HInstruction>[];
      type.typeArguments.forEach((DartType argument) {
        typeInputs
            .add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
      });

      // We lift this common call pattern into a helper function to save space
      // in the output.
      if (typeInputs.every((HInstruction input) => input.isNull())) {
        if (constructorArgs.isEmpty) {
          constructor = _commonElements.mapLiteralUntypedEmptyMaker;
        } else {
          constructor = _commonElements.mapLiteralUntypedMaker;
        }
      } else {
        inputs.addAll(typeInputs);
      }
    }

    // If runtime type information is needed and the map literal has no type
    // parameters, 'constructor' is a static function that forwards the call to
    // the factory constructor without type parameters.
    assert(constructor.isFunction ||
        (constructor is ConstructorEntity && constructor.isFactoryConstructor));

    // The instruction type will always be a subtype of the mapLiteralClass, but
    // type inference might discover a more specific type, or find nothing (in
    // dart2js unit tests).

    TypeMask mapType = new TypeMask.nonNullSubtype(
        _commonElements.mapLiteralClass, closedWorld);
    TypeMask returnTypeMask = _typeInferenceMap.getReturnTypeOf(constructor);
    TypeMask instructionType =
        mapType.intersection(returnTypeMask, closedWorld);

    addImplicitInstantiation(type);
    _pushStaticInvocation(constructor, inputs, instructionType);
    removeImplicitInstantiation(type);
  }

  @override
  void visitMapEntry(ir.MapEntry mapEntry) {
    // Visit value before the key because each will push an expression to the
    // stack, so when we pop them off, the key is popped first, then the value.
    mapEntry.value.accept(this);
    mapEntry.key.accept(this);
  }

  @override
  void visitTypeLiteral(ir.TypeLiteral typeLiteral) {
    ir.DartType type = typeLiteral.type;
    if (type is ir.InterfaceType || type is ir.DynamicType) {
      ConstantValue constant = _elementMap.getConstantValue(typeLiteral);
      stack.add(graph.addConstant(constant, closedWorld));
      return;
    }
    // For other types (e.g. TypeParameterType, function types from expanded
    // typedefs), look-up or construct a reified type representation and convert
    // to a RuntimeType.

    // TODO(sra): Convert the type logic here to use ir.DartType.
    ResolutionDartType dartType = _elementMap.getDartType(type);
    dartType = localsHandler.substInContext(dartType);
    HInstruction value = typeBuilder
        .analyzeTypeArgument(dartType, sourceElement, sourceInformation: null);
    _pushStaticInvocation(_commonElements.runtimeTypeToString,
        <HInstruction>[value], commonMasks.stringType);
    _pushStaticInvocation(
        _commonElements.createRuntimeType,
        <HInstruction>[pop()],
        _typeInferenceMap.getReturnTypeOf(_commonElements.createRuntimeType));
  }

  @override
  void visitStaticGet(ir.StaticGet staticGet) {
    ir.Member staticTarget = staticGet.target;
    if (staticTarget is ir.Procedure &&
        staticTarget.kind == ir.ProcedureKind.Getter) {
      FunctionEntity getter = _elementMap.getMember(staticTarget);
      // Invoke the getter
      _pushStaticInvocation(getter, const <HInstruction>[],
          _typeInferenceMap.getReturnTypeOf(getter));
    } else if (staticTarget is ir.Field) {
      FieldEntity field = _elementMap.getField(staticTarget);
      ConstantValue value = _elementMap.getFieldConstantValue(staticTarget);
      if (value != null) {
        if (!field.isAssignable) {
          stack.add(graph.addConstant(value, closedWorld));
        } else {
          push(new HStatic(field, _typeInferenceMap.getInferredTypeOf(field)));
        }
      } else {
        push(
            new HLazyStatic(field, _typeInferenceMap.getInferredTypeOf(field)));
      }
    } else {
      MemberEntity member = _elementMap.getMember(staticTarget);
      push(new HStatic(member, _typeInferenceMap.getInferredTypeOf(member)));
    }
  }

  @override
  void visitStaticSet(ir.StaticSet staticSet) {
    staticSet.value.accept(this);
    HInstruction value = pop();

    ir.Member staticTarget = staticSet.target;
    if (staticTarget is ir.Procedure) {
      FunctionEntity setter = _elementMap.getMember(staticTarget);
      // Invoke the setter
      _pushStaticInvocation(setter, <HInstruction>[value],
          _typeInferenceMap.getReturnTypeOf(setter));
      pop();
    } else {
      add(new HStaticStore(
          _elementMap.getMember(staticTarget),
          typeBuilder.potentiallyCheckOrTrustType(
              value, _getDartTypeIfValid(staticTarget.setterType))));
    }
    stack.add(value);
  }

  @override
  void visitPropertyGet(ir.PropertyGet propertyGet) {
    propertyGet.receiver.accept(this);
    HInstruction receiver = pop();

    _pushDynamicInvocation(propertyGet,
        _typeInferenceMap.typeOfGet(propertyGet), <HInstruction>[receiver]);
  }

  @override
  void visitVariableGet(ir.VariableGet variableGet) {
    ir.VariableDeclaration variable = variableGet.variable;
    HInstruction letBinding = letBindings[variable];
    if (letBinding != null) {
      stack.add(letBinding);
      return;
    }

    Local local = localsMap.getLocal(variableGet.variable);
    stack.add(localsHandler.readLocal(local));
  }

  @override
  void visitPropertySet(ir.PropertySet propertySet) {
    propertySet.receiver.accept(this);
    HInstruction receiver = pop();
    propertySet.value.accept(this);
    HInstruction value = pop();

    _pushDynamicInvocation(
        propertySet,
        _typeInferenceMap.typeOfSet(propertySet, closedWorld),
        <HInstruction>[receiver, value]);

    pop();
    stack.add(value);
  }

  @override
  void visitSuperPropertySet(ir.SuperPropertySet propertySet) {
    propertySet.value.accept(this);
    HInstruction value = pop();

    if (propertySet.interfaceTarget == null) {
      _generateSuperNoSuchMethod(
          propertySet,
          _elementMap.getSelector(propertySet).name + "=",
          <HInstruction>[value]);
    } else {
      _buildInvokeSuper(
          _elementMap.getSelector(propertySet),
          _elementMap.getClass(_containingClass(propertySet)),
          _elementMap.getMember(propertySet.interfaceTarget),
          <HInstruction>[value]);
    }
  }

  @override
  void visitVariableSet(ir.VariableSet variableSet) {
    variableSet.value.accept(this);
    HInstruction value = pop();
    _visitLocalSetter(variableSet.variable, value);
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration declaration) {
    Local local = localsMap.getLocal(declaration);
    if (declaration.initializer == null) {
      HInstruction initialValue = graph.addConstantNull(closedWorld);
      localsHandler.updateLocal(local, initialValue);
    } else {
      declaration.initializer.accept(this);
      HInstruction initialValue = pop();

      _visitLocalSetter(declaration, initialValue);

      // Ignore value
      pop();
    }
  }

  void _visitLocalSetter(ir.VariableDeclaration variable, HInstruction value) {
    Local local = localsMap.getLocal(variable);

    // Give the value a name if it doesn't have one already.
    if (value.sourceElement == null) {
      value.sourceElement = local;
    }

    stack.add(value);
    localsHandler.updateLocal(
        local,
        typeBuilder.potentiallyCheckOrTrustType(
            value, _getDartTypeIfValid(variable.type)));
  }

  @override
  void visitLet(ir.Let let) {
    ir.VariableDeclaration variable = let.variable;
    variable.initializer.accept(this);
    HInstruction initializedValue = pop();
    // TODO(sra): Apply inferred type information.
    letBindings[variable] = initializedValue;
    let.body.accept(this);
  }

  /// Extracts the list of instructions for the positional subset of arguments.
  List<HInstruction> _visitPositionalArguments(ir.Arguments arguments) {
    List<HInstruction> result = <HInstruction>[];
    for (ir.Expression argument in arguments.positional) {
      argument.accept(this);
      result.add(pop());
    }
    return result;
  }

  /// Builds the list of instructions for the expressions in the arguments to a
  /// dynamic target (member function).  Dynamic targets use stubs to add
  /// defaulted arguments, so (unlike static targets) we do not add the default
  /// values.
  List<HInstruction> _visitArgumentsForDynamicTarget(
      Selector selector, ir.Arguments arguments) {
    List<HInstruction> values = _visitPositionalArguments(arguments);

    if (arguments.named.isEmpty) return values;

    var namedValues = <String, HInstruction>{};
    for (ir.NamedExpression argument in arguments.named) {
      argument.value.accept(this);
      namedValues[argument.name] = pop();
    }
    for (String name in selector.callStructure.getOrderedNamedArguments()) {
      values.add(namedValues[name]);
    }

    return values;
  }

  /// Build argument list in canonical order for a static [target], including
  /// filling in the default argument value.
  List<HInstruction> _visitArgumentsForStaticTarget(
      ir.FunctionNode target, ir.Arguments arguments) {
    // Visit arguments in source order, then re-order and fill in defaults.
    var values = _visitPositionalArguments(arguments);

    while (values.length < target.positionalParameters.length) {
      ir.VariableDeclaration parameter =
          target.positionalParameters[values.length];
      values.add(_defaultValueForParameter(parameter));
    }

    if (target.namedParameters.isNotEmpty) {
      var namedValues = <String, HInstruction>{};
      for (ir.NamedExpression argument in arguments.named) {
        argument.value.accept(this);
        namedValues[argument.name] = pop();
      }

      // Visit named arguments in parameter-position order, selecting provided
      // or default value.
      // TODO(sra): Ensure the stored order is canonical so we don't have to
      // sort. The old builder uses CallStructure.makeArgumentList which depends
      // on the old element model.
      var namedParameters = target.namedParameters.toList()
        ..sort((ir.VariableDeclaration a, ir.VariableDeclaration b) =>
            a.name.compareTo(b.name));
      for (ir.VariableDeclaration parameter in namedParameters) {
        HInstruction value = namedValues[parameter.name];
        if (value == null) {
          values.add(_defaultValueForParameter(parameter));
        } else {
          values.add(value);
          namedValues.remove(parameter.name);
        }
      }
      assert(namedValues.isEmpty);
    } else {
      assert(arguments.named.isEmpty);
    }

    return values;
  }

  void _addTypeArguments(List<HInstruction> values, ir.Arguments arguments) {
    // need to translate type to
    for (ir.DartType type in arguments.types) {
      values.add(typeBuilder.analyzeTypeArgument(
          _elementMap.getDartType(type), sourceElement));
    }
  }

  HInstruction _defaultValueForParameter(ir.VariableDeclaration parameter) {
    ConstantValue constant =
        _elementMap.getConstantValue(parameter.initializer, implicitNull: true);
    assert(constant != null, failedAt(CURRENT_ELEMENT_SPANNABLE));
    return graph.addConstant(constant, closedWorld);
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation invocation) {
    ir.Procedure target = invocation.target;
    if (_elementMap.isForeignLibrary(target.enclosingLibrary)) {
      handleInvokeStaticForeign(invocation, target);
      return;
    }
    FunctionEntity function = _elementMap.getMember(target);
    TypeMask typeMask = _typeInferenceMap.getReturnTypeOf(function);

    // TODO(sra): For JS interop external functions, use a different function to
    // build arguments.
    List<HInstruction> arguments =
        _visitArgumentsForStaticTarget(target.function, invocation.arguments);

    if (function is ConstructorEntity && function.isFactoryConstructor) {
      if (function.isExternal && function.isFromEnvironmentConstructor) {
        if (invocation.isConst) {
          // Just like all const constructors (see visitConstructorInvocation).
          stack.add(graph.addConstant(
              _elementMap.getConstantValue(invocation), closedWorld));
        } else {
          generateUnsupportedError(
              invocation,
              '${function.enclosingClass.name}.${function.name} '
              'can only be used as a const constructor');
        }
        return;
      }

      // Factory constructors take type parameters; other static methods ignore
      // them.
      if (backend.rtiNeed.classNeedsRti(function.enclosingClass)) {
        _addTypeArguments(arguments, invocation.arguments);
      }
    }

    _pushStaticInvocation(function, arguments, typeMask);
  }

  void handleInvokeStaticForeign(
      ir.StaticInvocation invocation, ir.Procedure target) {
    String name = target.name.name;
    if (name == 'JS') {
      handleForeignJs(invocation);
    } else if (name == 'JS_CURRENT_ISOLATE_CONTEXT') {
      handleForeignJsCurrentIsolateContext(invocation);
    } else if (name == 'JS_CALL_IN_ISOLATE') {
      handleForeignJsCallInIsolate(invocation);
    } else if (name == 'DART_CLOSURE_TO_JS') {
      handleForeignDartClosureToJs(invocation, 'DART_CLOSURE_TO_JS');
    } else if (name == 'RAW_DART_FUNCTION_REF') {
      handleForeignRawFunctionRef(invocation, 'RAW_DART_FUNCTION_REF');
    } else if (name == 'JS_SET_STATIC_STATE') {
      handleForeignJsSetStaticState(invocation);
    } else if (name == 'JS_GET_STATIC_STATE') {
      handleForeignJsGetStaticState(invocation);
    } else if (name == 'JS_GET_NAME') {
      handleForeignJsGetName(invocation);
    } else if (name == 'JS_EMBEDDED_GLOBAL') {
      handleForeignJsEmbeddedGlobal(invocation);
    } else if (name == 'JS_BUILTIN') {
      handleForeignJsBuiltin(invocation);
    } else if (name == 'JS_GET_FLAG') {
      handleForeignJsGetFlag(invocation);
    } else if (name == 'JS_EFFECT') {
      stack.add(graph.addConstantNull(closedWorld));
    } else if (name == 'JS_INTERCEPTOR_CONSTANT') {
      handleJsInterceptorConstant(invocation);
    } else if (name == 'JS_STRING_CONCAT') {
      handleJsStringConcat(invocation);
    } else {
      reporter.internalError(
          _elementMap.getSpannable(targetElement, invocation),
          "Unknown foreign: ${name}");
    }
  }

  bool _unexpectedForeignArguments(
      ir.StaticInvocation invocation, int minPositional,
      [int maxPositional]) {
    String pluralizeArguments(int count) {
      if (count == 0) return 'no arguments';
      if (count == 1) return 'one argument';
      if (count == 2) return 'two arguments';
      return '$count arguments';
    }

    String name() => invocation.target.name.name;

    ir.Arguments arguments = invocation.arguments;
    bool bad = false;
    if (arguments.types.isNotEmpty) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: '${name()}' does not take type arguments."});
      bad = true;
    }
    if (arguments.positional.length < minPositional) {
      String phrase = pluralizeArguments(minPositional);
      if (maxPositional != minPositional) phrase = 'at least $phrase';
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: Too few arguments. '${name()}' takes $phrase."});
      bad = true;
    }
    if (maxPositional != null && arguments.positional.length > maxPositional) {
      String phrase = pluralizeArguments(maxPositional);
      if (maxPositional != minPositional) phrase = 'at most $phrase';
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: Too many arguments. '${name()}' takes $phrase."});
      bad = true;
    }
    if (arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: '${name()}' does not take named arguments."});
      bad = true;
    }
    return bad;
  }

  /// Returns the value of the string argument. The argument must evaluate to a
  /// constant.  If there is an error, the error is reported and `null` is
  /// returned.
  String _foreignConstantStringArgument(
      ir.StaticInvocation invocation, int position, String methodName,
      [String adjective = '']) {
    ir.Expression argument = invocation.arguments.positional[position];
    argument.accept(this);
    HInstruction instruction = pop();

    if (!instruction.isConstantString()) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, argument),
          MessageKind.GENERIC, {
        'text': "Error: Expected String constant as ${adjective}argument "
            "to '$methodName'."
      });
      return null;
    }

    HConstant hConstant = instruction;
    StringConstantValue stringConstant = hConstant.constant;
    return stringConstant.primitiveValue;
  }

  void handleForeignJsCurrentIsolateContext(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 0, 0)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (!backendUsage.isIsolateInUse) {
      // If the isolate library is not used, we just generate code
      // to fetch the static state.
      String name = namer.staticStateHolder;
      push(new HForeignCode(
          js.js.parseForeignJS(name), commonMasks.dynamicType, <HInstruction>[],
          nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
    } else {
      // Call a helper method from the isolate library. The isolate library uses
      // its own isolate structure that encapsulates the isolate structure used
      // for binding to methods.
      FunctionEntity target = _commonElements.currentIsolate;
      if (target == null) {
        reporter.internalError(
            _elementMap.getSpannable(targetElement, invocation),
            'Isolate library and compiler mismatch.');
      }
      _pushStaticInvocation(target, <HInstruction>[], commonMasks.dynamicType);
    }
  }

  void handleForeignJsCallInIsolate(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);

    if (!backendUsage.isIsolateInUse) {
      // If the isolate library is not used, we ignore the isolate argument and
      // just invoke the closure.
      push(new HInvokeClosure(new Selector.callClosure(0),
          <HInstruction>[inputs[1]], commonMasks.dynamicType));
    } else {
      // Call a helper method from the isolate library.
      FunctionEntity callInIsolate = _commonElements.callInIsolate;
      if (callInIsolate == null) {
        reporter.internalError(
            _elementMap.getSpannable(targetElement, invocation),
            'Isolate library and compiler mismatch.');
      }
      _pushStaticInvocation(callInIsolate, inputs, commonMasks.dynamicType);
    }
  }

  void handleForeignDartClosureToJs(
      ir.StaticInvocation invocation, String name) {
    // TODO(sra): Do we need to wrap the closure in something that saves the
    // current isolate?
    handleForeignRawFunctionRef(invocation, name);
  }

  void handleForeignRawFunctionRef(
      ir.StaticInvocation invocation, String name) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    ir.Expression closure = invocation.arguments.positional.single;
    String problem = 'requires a static method or top-level method';
    if (closure is ir.StaticGet) {
      ir.Member staticTarget = closure.target;
      if (staticTarget is ir.Procedure) {
        if (staticTarget.kind == ir.ProcedureKind.Method) {
          ir.FunctionNode function = staticTarget.function;
          if (function != null &&
              function.requiredParameterCount ==
                  function.positionalParameters.length &&
              function.namedParameters.isEmpty) {
            push(new HForeignCode(
                js.js.expressionTemplateYielding(emitter
                    .staticFunctionAccess(_elementMap.getMethod(staticTarget))),
                commonMasks.dynamicType,
                <HInstruction>[],
                nativeBehavior: native.NativeBehavior.PURE,
                foreignFunction: _elementMap.getMethod(staticTarget)));
            return;
          }
          problem = 'does not handle a closure with optional parameters';
        }
      }
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, invocation),
        MessageKind.GENERIC,
        {'text': "'$name' $problem."});
    stack.add(graph.addConstantNull(closedWorld)); // Result expected on stack.
    return;
  }

  void handleForeignJsSetStaticState(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);

    String isolateName = namer.staticStateHolder;
    SideEffects sideEffects = new SideEffects.empty();
    sideEffects.setAllSideEffects();
    push(new HForeignCode(js.js.parseForeignJS("$isolateName = #"),
        commonMasks.dynamicType, inputs,
        nativeBehavior: native.NativeBehavior.CHANGES_OTHER,
        effects: sideEffects));
  }

  void handleForeignJsGetStaticState(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 0, 0)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    push(new HForeignCode(js.js.parseForeignJS(namer.staticStateHolder),
        commonMasks.dynamicType, <HInstruction>[],
        nativeBehavior: native.NativeBehavior.DEPENDS_OTHER));
  }

  void handleForeignJsGetName(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    ir.Node argument = invocation.arguments.positional.first;
    argument.accept(this);
    HInstruction instruction = pop();

    if (instruction is HConstant) {
      js.Name name =
          _elementMap.getNameForJsGetName(instruction.constant, namer);
      stack.add(graph.addConstantStringFromName(name, closedWorld));
      return;
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, argument),
        MessageKind.GENERIC,
        {'text': 'Error: Expected a JsGetName enum value.'});
    // Result expected on stack.
    stack.add(graph.addConstantNull(closedWorld));
  }

  void handleForeignJsEmbeddedGlobal(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    String globalName = _foreignConstantStringArgument(
        invocation, 1, 'JS_EMBEDDED_GLOBAL', 'second ');
    js.Template expr = js.js.expressionTemplateYielding(
        emitter.generateEmbeddedGlobalAccess(globalName));

    native.NativeBehavior nativeBehavior =
        _elementMap.getNativeBehaviorForJsEmbeddedGlobalCall(invocation);
    assert(
        nativeBehavior != null,
        failedAt(_elementMap.getSpannable(targetElement, invocation),
            "No NativeBehavior for $invocation"));

    TypeMask ssaType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);
    push(new HForeignCode(expr, ssaType, const <HInstruction>[],
        nativeBehavior: nativeBehavior));
  }

  void handleForeignJsBuiltin(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<ir.Expression> arguments = invocation.arguments.positional;
    ir.Expression nameArgument = arguments[1];

    nameArgument.accept(this);
    HInstruction instruction = pop();

    js.Template template;
    if (instruction is HConstant) {
      template =
          _elementMap.getJsBuiltinTemplate(instruction.constant, emitter);
    }
    if (template == null) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, nameArgument),
          MessageKind.GENERIC,
          {'text': 'Error: Expected a JsBuiltin enum value.'});
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    List<HInstruction> inputs = <HInstruction>[];
    for (ir.Expression argument in arguments.skip(2)) {
      argument.accept(this);
      inputs.add(pop());
    }

    native.NativeBehavior nativeBehavior =
        _elementMap.getNativeBehaviorForJsBuiltinCall(invocation);
    assert(
        nativeBehavior != null,
        failedAt(_elementMap.getSpannable(targetElement, invocation),
            "No NativeBehavior for $invocation"));

    TypeMask ssaType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);
    push(new HForeignCode(template, ssaType, inputs,
        nativeBehavior: nativeBehavior));
  }

  void handleForeignJsGetFlag(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      stack.add(
          // Result expected on stack.
          graph.addConstantBool(false, closedWorld));
      return;
    }
    String name = _foreignConstantStringArgument(invocation, 0, 'JS_GET_FLAG');
    bool value = getFlagValue(name);
    if (value == null) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': 'Error: Unknown internal flag "$name".'});
    } else {
      stack.add(graph.addConstantBool(value, closedWorld));
    }
  }

  void handleJsInterceptorConstant(ir.StaticInvocation invocation) {
    // Single argument must be a TypeConstant which is converted into a
    // InterceptorConstant.
    if (_unexpectedForeignArguments(invocation, 1, 1)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    ir.Expression argument = invocation.arguments.positional.single;
    argument.accept(this);
    HInstruction argumentInstruction = pop();
    if (argumentInstruction is HConstant) {
      ConstantValue argumentConstant = argumentInstruction.constant;
      if (argumentConstant is TypeConstantValue &&
          argumentConstant.representedType is InterfaceType) {
        InterfaceType type = argumentConstant.representedType;
        // TODO(sra): Check that type is a subclass of [Interceptor].
        ConstantValue constant = new InterceptorConstantValue(type.element);
        HInstruction instruction = graph.addConstant(constant, closedWorld);
        stack.add(instruction);
        return;
      }
    }

    reporter.reportErrorMessage(
        _elementMap.getSpannable(targetElement, invocation),
        MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    stack.add(graph.addConstantNull(closedWorld));
  }

  void handleForeignJs(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    native.NativeBehavior nativeBehavior =
        _elementMap.getNativeBehaviorForJsCall(invocation);
    assert(
        nativeBehavior != null,
        failedAt(_elementMap.getSpannable(targetElement, invocation),
            "No NativeBehavior for $invocation"));

    List<HInstruction> inputs = <HInstruction>[];
    for (ir.Expression argument in invocation.arguments.positional.skip(2)) {
      argument.accept(this);
      inputs.add(pop());
    }

    if (nativeBehavior.codeTemplate.positionalArgumentCount != inputs.length) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC, {
        'text': 'Mismatch between number of placeholders'
            ' and number of arguments.'
      });
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }

    if (native.HasCapturedPlaceholders.check(nativeBehavior.codeTemplate.ast)) {
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.JS_PLACEHOLDER_CAPTURE);
    }

    TypeMask ssaType =
        _typeInferenceMap.typeFromNativeBehavior(nativeBehavior, closedWorld);

    SourceInformation sourceInformation = null;
    push(new HForeignCode(nativeBehavior.codeTemplate, ssaType, inputs,
        isStatement: !nativeBehavior.codeTemplate.isExpression,
        effects: nativeBehavior.sideEffects,
        nativeBehavior: nativeBehavior)
      ..sourceInformation = sourceInformation);
  }

  void handleJsStringConcat(ir.StaticInvocation invocation) {
    if (_unexpectedForeignArguments(invocation, 2, 2)) {
      // Result expected on stack.
      stack.add(graph.addConstantNull(closedWorld));
      return;
    }
    List<HInstruction> inputs = _visitPositionalArguments(invocation.arguments);
    push(new HStringConcat(inputs[0], inputs[1], commonMasks.stringType));
  }

  void _pushStaticInvocation(
      MemberEntity target, List<HInstruction> arguments, TypeMask typeMask) {
    HInvokeStatic instruction = new HInvokeStatic(target, arguments, typeMask,
        targetCanThrow: !closedWorld.getCannotThrow(target));
    if (currentImplicitInstantiations.isNotEmpty) {
      instruction.instantiatedTypes =
          new List<InterfaceType>.from(currentImplicitInstantiations);
    }
    instruction.sideEffects = closedWorld.getSideEffectsOfElement(target);

    push(instruction);
  }

  void _pushDynamicInvocation(
      ir.Node node, TypeMask mask, List<HInstruction> arguments,
      {Selector selector}) {
    HInstruction receiver = arguments.first;
    List<HInstruction> inputs = <HInstruction>[];

    selector ??= _elementMap.getSelector(node);

    bool isIntercepted =
        closedWorld.interceptorData.isInterceptedSelector(selector);

    if (isIntercepted) {
      HInterceptor interceptor = _interceptorFor(receiver);
      inputs.add(interceptor);
    }
    inputs.addAll(arguments);

    TypeMask type = _typeInferenceMap.selectorTypeOf(selector, mask);
    if (selector.isGetter) {
      push(new HInvokeDynamicGetter(selector, mask, null, inputs, type));
    } else if (selector.isSetter) {
      push(new HInvokeDynamicSetter(selector, mask, null, inputs, type));
    } else {
      push(new HInvokeDynamicMethod(
          selector, mask, inputs, type, isIntercepted));
    }
  }

  @override
  visitFunctionNode(ir.FunctionNode node) {
    Local methodElement = _elementMap.getLocalFunction(node);
    ClosureRepresentationInfo closureInfo =
        closureDataLookup.getClosureRepresentationInfo(methodElement);
    ClassEntity closureClassEntity = closureInfo.closureClassEntity;

    List<HInstruction> capturedVariables = <HInstruction>[];
    closureInfo.createdFieldEntities.forEach((Local capturedLocal) {
      assert(capturedLocal != null);
      capturedVariables.add(localsHandler.readLocal(capturedLocal));
    });

    TypeMask type = new TypeMask.nonNullExact(closureClassEntity, closedWorld);
    // TODO(efortuna): Add source information here.
    push(new HCreate(closureClassEntity, capturedVariables, type,
        callMethod: closureInfo.callMethod, localFunction: methodElement));
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration declaration) {
    assert(isReachable);
    declaration.function.accept(this);
    Local localFunction = _elementMap.getLocalFunction(declaration.function);
    localsHandler.updateLocal(localFunction, pop());
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression funcExpression) {
    funcExpression.function.accept(this);
  }

  // TODO(het): Decide when to inline
  @override
  void visitMethodInvocation(ir.MethodInvocation invocation) {
    invocation.receiver.accept(this);
    HInstruction receiver = pop();
    Selector selector = _elementMap.getSelector(invocation);
    _pushDynamicInvocation(
        invocation,
        _typeInferenceMap.typeOfInvocation(invocation, closedWorld),
        <HInstruction>[receiver]..addAll(
            _visitArgumentsForDynamicTarget(selector, invocation.arguments)));
  }

  HInterceptor _interceptorFor(HInstruction intercepted) {
    HInterceptor interceptor =
        new HInterceptor(intercepted, commonMasks.nonNullType);
    add(interceptor);
    return interceptor;
  }

  static ir.Class _containingClass(ir.TreeNode node) {
    while (node != null) {
      if (node is ir.Class) return node;
      node = node.parent;
    }
    return null;
  }

  void _generateSuperNoSuchMethod(ir.Expression invocation, String publicName,
      List<HInstruction> arguments) {
    Selector selector = _elementMap.getSelector(invocation);
    ClassEntity containingClass =
        _elementMap.getClass(_containingClass(invocation));
    FunctionEntity noSuchMethod =
        _elementMap.getSuperNoSuchMethod(containingClass);
    if (backendUsage.isInvokeOnUsed &&
        noSuchMethod.enclosingClass != _commonElements.objectClass) {
      // Register the call as dynamic if [noSuchMethod] on the super
      // class is _not_ the default implementation from [Object] (it might be
      // overridden in the super class, but it might have a different number of
      // arguments), in case the [noSuchMethod] implementation calls
      // [JSInvocationMirror._invokeOn].
      // TODO(johnniwinther): Register this more precisely.
      registry?.registerDynamicUse(new DynamicUse(selector, null));
    }

    ConstantValue nameConstant = constantSystem.createString(publicName);

    js.Name internalName = namer.invocationName(selector);

    var argumentsInstruction =
        new HLiteralList(arguments, commonMasks.extendableArrayType);
    add(argumentsInstruction);

    var argumentNames = new List<HInstruction>();
    for (String argumentName in selector.namedArguments) {
      ConstantValue argumentNameConstant =
          constantSystem.createString(argumentName);
      argumentNames.add(graph.addConstant(argumentNameConstant, closedWorld));
    }
    var argumentNamesInstruction =
        new HLiteralList(argumentNames, commonMasks.extendableArrayType);
    add(argumentNamesInstruction);

    ConstantValue kindConstant =
        constantSystem.createInt(selector.invocationMirrorKind);

    _pushStaticInvocation(
        _commonElements.createInvocationMirror,
        [
          graph.addConstant(nameConstant, closedWorld),
          graph.addConstantStringFromName(internalName, closedWorld),
          graph.addConstant(kindConstant, closedWorld),
          argumentsInstruction,
          argumentNamesInstruction
        ],
        commonMasks.dynamicType);

    _buildInvokeSuper(Selectors.noSuchMethod_, containingClass, noSuchMethod,
        <HInstruction>[pop()]);
  }

  HInstruction _buildInvokeSuper(Selector selector, ClassEntity containingClass,
      MemberEntity target, List<HInstruction> arguments) {
    // TODO(efortuna): Add source information.
    HInstruction receiver = localsHandler.readThis();

    List<HInstruction> inputs = <HInstruction>[];
    if (closedWorld.interceptorData.isInterceptedSelector(selector)) {
      inputs.add(_interceptorFor(receiver));
    }
    inputs.add(receiver);
    inputs.addAll(arguments);

    TypeMask typeMask;
    if (target is FunctionEntity) {
      typeMask = _typeInferenceMap.getReturnTypeOf(target);
    } else {
      typeMask = closedWorld.commonMasks.dynamicType;
    }
    HInstruction instruction = new HInvokeSuper(
        target, containingClass, selector, inputs, typeMask, null,
        isSetter: selector.isSetter || selector.isIndexSet);
    instruction.sideEffects =
        closedWorld.getSideEffectsOfSelector(selector, null);
    push(instruction);
    return instruction;
  }

  @override
  void visitSuperPropertyGet(ir.SuperPropertyGet propertyGet) {
    if (propertyGet.interfaceTarget == null) {
      _generateSuperNoSuchMethod(propertyGet,
          _elementMap.getSelector(propertyGet).name, const <HInstruction>[]);
    } else {
      _buildInvokeSuper(
          _elementMap.getSelector(propertyGet),
          _elementMap.getClass(_containingClass(propertyGet)),
          _elementMap.getMember(propertyGet.interfaceTarget),
          const <HInstruction>[]);
    }
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation invocation) {
    List<HInstruction> arguments = _visitArgumentsForStaticTarget(
        invocation.interfaceTarget.function, invocation.arguments);
    _buildInvokeSuper(
        _elementMap.getSelector(invocation),
        _elementMap.getClass(_containingClass(invocation)),
        _elementMap.getMethod(invocation.interfaceTarget),
        arguments);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation invocation) {
    ir.Constructor target = invocation.target;
    if (invocation.isConst) {
      ConstantValue constant = _elementMap.getConstantValue(invocation);
      stack.add(graph.addConstant(constant, closedWorld));
      return;
    }

    // TODO(sra): For JS-interop targets, process arguments differently.
    List<HInstruction> arguments =
        _visitArgumentsForStaticTarget(target.function, invocation.arguments);
    ConstructorEntity constructor = _elementMap.getConstructor(target);
    ClassEntity cls = constructor.enclosingClass;
    if (backend.rtiNeed.classNeedsRti(cls)) {
      _addTypeArguments(arguments, invocation.arguments);
    }
    TypeMask typeMask = new TypeMask.nonNullExact(cls, closedWorld);
    InterfaceType type = _elementMap.createInterfaceType(
        target.enclosingClass, invocation.arguments.types);
    addImplicitInstantiation(type);
    _pushStaticInvocation(constructor, arguments, typeMask);
    removeImplicitInstantiation(type);
  }

  @override
  void visitIsExpression(ir.IsExpression isExpression) {
    isExpression.operand.accept(this);
    HInstruction expression = pop();
    pushIsTest(isExpression, isExpression.type, expression);
  }

  void pushIsTest(ir.Node node, ir.DartType type, HInstruction expression) {
    // Note: The call to "unalias" this type like in the original SSA builder is
    // unnecessary in kernel because Kernel has no notion of typedef.
    // TODO(efortuna): Add test for this.

    if (type is ir.InvalidType) {
      // TODO(sra): Make InvalidType carry a message.
      generateTypeError(node, 'invalid type');
      pop();
      stack.add(graph.addConstantBool(true, closedWorld));
      return;
    }

    if (type is ir.DynamicType) {
      stack.add(graph.addConstantBool(true, closedWorld));
      return;
    }

    DartType typeValue =
        localsHandler.substInContext(_elementMap.getDartType(type));

    if (type is ir.FunctionType) {
      HInstruction representation =
          typeBuilder.analyzeTypeArgument(typeValue, sourceElement);
      List<HInstruction> inputs = <HInstruction>[
        expression,
        representation,
      ];
      _pushStaticInvocation(
          _commonElements.functionTypeTest, inputs, commonMasks.boolType);
      HInstruction call = pop();
      push(new HIs.compound(typeValue, expression, call, commonMasks.boolType));
      return;
    }

    if (type is ir.TypeParameterType) {
      HInstruction runtimeType =
          typeBuilder.addTypeVariableReference(typeValue, sourceElement);
      _pushStaticInvocation(_commonElements.checkSubtypeOfRuntimeType,
          <HInstruction>[expression, runtimeType], commonMasks.boolType);
      push(
          new HIs.variable(typeValue, expression, pop(), commonMasks.boolType));
      return;
    }

    if (_isInterfaceWithNoDynamicTypes(type)) {
      InterfaceType interfaceType = typeValue;
      HInstruction representations = typeBuilder
          .buildTypeArgumentRepresentations(typeValue, sourceElement);
      add(representations);
      ClassEntity element = interfaceType.element;
      js.Name operator = namer.operatorIs(element);
      HInstruction isFieldName =
          graph.addConstantStringFromName(operator, closedWorld);
      HInstruction asFieldName = closedWorld.hasAnyStrictSubtype(element)
          ? graph.addConstantStringFromName(
              namer.substitutionName(element), closedWorld)
          : graph.addConstantNull(closedWorld);
      List<HInstruction> inputs = <HInstruction>[
        expression,
        isFieldName,
        representations,
        asFieldName
      ];
      _pushStaticInvocation(
          _commonElements.checkSubtype, inputs, commonMasks.boolType);
      push(
          new HIs.compound(typeValue, expression, pop(), commonMasks.boolType));
      return;
    }

    if (backend.hasDirectCheckFor(closedWorld.commonElements, typeValue)) {
      push(new HIs.direct(typeValue, expression, commonMasks.boolType));
      return;
    }
    // The interceptor is not always needed.  It is removed by optimization
    // when the receiver type or tested type permit.
    push(new HIs.raw(typeValue, expression, _interceptorFor(expression),
        commonMasks.boolType));
    return;
  }

  bool _isInterfaceWithNoDynamicTypes(ir.DartType type) {
    bool isMethodTypeVariableType(ir.DartType typeArgType) {
      return (typeArgType is ir.TypeParameterType &&
          typeArgType.parameter.parent is ir.FunctionNode);
    }

    return type is ir.InterfaceType &&
        type.typeArguments.any((ir.DartType typeArgType) =>
            typeArgType is! ir.DynamicType &&
            typeArgType is! ir.InvalidType &&
            !isMethodTypeVariableType(type));
  }

  @override
  void visitThrow(ir.Throw throwNode) {
    _visitThrowExpression(throwNode.expression);
    if (isReachable) {
      handleInTryStatement();
      push(new HThrowExpression(pop(), null));
      isReachable = false;
    }
  }

  void _visitThrowExpression(ir.Expression expression) {
    bool old = _inExpressionOfThrow;
    try {
      _inExpressionOfThrow = true;
      expression.accept(this);
    } finally {
      _inExpressionOfThrow = old;
    }
  }

  void visitYieldStatement(ir.YieldStatement yieldStatement) {
    yieldStatement.expression.accept(this);
    add(new HYield(pop(), yieldStatement.isYieldStar));
  }

  @override
  void visitAwaitExpression(ir.AwaitExpression await) {
    await.operand.accept(this);
    HInstruction awaited = pop();
    // TODO(herhut): Improve this type.
    push(new HAwait(awaited, closedWorld.commonMasks.dynamicType));
  }

  @override
  void visitRethrow(ir.Rethrow rethrowNode) {
    HInstruction exception = rethrowableException;
    if (exception == null) {
      exception = graph.addConstantNull(closedWorld);
      reporter.internalError(
          _elementMap.getSpannable(targetElement, rethrowNode),
          'rethrowableException should not be null.');
    }
    handleInTryStatement();
    SourceInformation sourceInformation = null;
    closeAndGotoExit(new HThrow(exception, sourceInformation, isRethrow: true));
    // ir.Rethrow is an expression so we need to push a value - a constant with
    // no type.
    stack.add(graph.addConstantUnreachable(closedWorld));
  }

  @override
  void visitThisExpression(ir.ThisExpression thisExpression) {
    stack.add(localsHandler.readThis());
  }

  @override
  void visitNot(ir.Not not) {
    not.operand.accept(this);
    push(new HNot(popBoolified(), commonMasks.boolType));
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation stringConcat) {
    KernelStringBuilder stringBuilder = new KernelStringBuilder(this);
    stringConcat.accept(stringBuilder);
    stack.add(stringBuilder.result);
  }

  @override
  void visitTryCatch(ir.TryCatch tryCatch) {
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(this);
    tryCatch.body.accept(this);
    tryBuilder
      ..closeTryBody()
      ..buildCatch(tryCatch)
      ..cleanUp();
  }

  /// `try { ... } catch { ... } finally { ... }` statements are a little funny
  /// because a try can have one or both of {catch|finally}. The way this is
  /// encoded in kernel AST are two separate classes with no common superclass
  /// aside from Statement. If a statement has both `catch` and `finally`
  /// clauses then it is encoded in kernel as so that the TryCatch is the body
  /// statement of the TryFinally. To produce more efficient code rather than
  /// nested try statements, the visitors avoid one potential level of
  /// recursion.
  @override
  void visitTryFinally(ir.TryFinally tryFinally) {
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(this);

    // We do these shenanigans to produce better looking code that doesn't
    // have nested try statements.
    if (tryFinally.body is ir.TryCatch) {
      ir.TryCatch tryCatch = tryFinally.body;
      tryCatch.body.accept(this);
      tryBuilder
        ..closeTryBody()
        ..buildCatch(tryCatch);
    } else {
      tryFinally.body.accept(this);
      tryBuilder.closeTryBody();
    }

    tryBuilder
      ..buildFinallyBlock(() {
        tryFinally.finalizer.accept(this);
      })
      ..cleanUp();
  }
}

/// Class in charge of building try, catch and/or finally blocks. This handles
/// the instructions that need to be output and the dominator calculation of
/// this sequence of code.
class TryCatchFinallyBuilder {
  HBasicBlock enterBlock;
  HBasicBlock startTryBlock;
  HBasicBlock endTryBlock;
  HBasicBlock startCatchBlock;
  HBasicBlock endCatchBlock;
  HBasicBlock startFinallyBlock;
  HBasicBlock endFinallyBlock;
  HBasicBlock exitBlock;
  HTry tryInstruction;
  HLocalValue exception;
  KernelSsaGraphBuilder kernelBuilder;

  /// True if the code surrounding this try statement was also part of a
  /// try/catch/finally statement.
  bool previouslyInTryStatement;

  SubGraph bodyGraph;
  SubGraph catchGraph;
  SubGraph finallyGraph;

  // The original set of locals that were defined before this try block.
  // The catch block and the finally block must not reuse the existing locals
  // handler. None of the variables that have been defined in the body-block
  // will be used, but for loops we will add (unnecessary) phis that will
  // reference the body variables. This makes it look as if the variables were
  // used in a non-dominated block.
  LocalsHandler originalSavedLocals;

  TryCatchFinallyBuilder(this.kernelBuilder) {
    tryInstruction = new HTry();
    originalSavedLocals = new LocalsHandler.from(kernelBuilder.localsHandler);
    enterBlock = kernelBuilder.openNewBlock();
    kernelBuilder.close(tryInstruction);
    previouslyInTryStatement = kernelBuilder.inTryStatement;
    kernelBuilder.inTryStatement = true;

    startTryBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startTryBlock);
  }

  void _addExitTrySuccessor(successor) {
    if (successor == null) return;
    // Iterate over all blocks created inside this try/catch, and
    // attach successor information to blocks that end with
    // [HExitTry].
    for (int i = startTryBlock.id; i < successor.id; i++) {
      HBasicBlock block = kernelBuilder.graph.blocks[i];
      var last = block.last;
      if (last is HExitTry) {
        block.addSuccessor(successor);
      }
    }
  }

  void _addOptionalSuccessor(block1, block2) {
    if (block2 != null) block1.addSuccessor(block2);
  }

  /// Helper function to set up basic block successors for try-catch-finally
  /// sequences.
  void _setBlockSuccessors() {
    // Setup all successors. The entry block that contains the [HTry]
    // has 1) the body, 2) the catch, 3) the finally, and 4) the exit
    // blocks as successors.
    enterBlock.addSuccessor(startTryBlock);
    _addOptionalSuccessor(enterBlock, startCatchBlock);
    _addOptionalSuccessor(enterBlock, startFinallyBlock);
    enterBlock.addSuccessor(exitBlock);

    // The body has either the catch or the finally block as successor.
    if (endTryBlock != null) {
      assert(startCatchBlock != null || startFinallyBlock != null);
      endTryBlock.addSuccessor(
          startCatchBlock != null ? startCatchBlock : startFinallyBlock);
      endTryBlock.addSuccessor(exitBlock);
    }

    // The catch block has either the finally or the exit block as
    // successor.
    endCatchBlock?.addSuccessor(
        startFinallyBlock != null ? startFinallyBlock : exitBlock);

    // The finally block has the exit block as successor.
    endFinallyBlock?.addSuccessor(exitBlock);

    // If a block inside try/catch aborts (eg with a return statement),
    // we explicitly mark this block a predecessor of the catch
    // block and the finally block.
    _addExitTrySuccessor(startCatchBlock);
    _addExitTrySuccessor(startFinallyBlock);
  }

  /// Build the finally{} clause of a try/{catch}/finally statement. Note this
  /// does not examine the body of the try clause, only the finally portion.
  void buildFinallyBlock(void buildFinalizer()) {
    kernelBuilder.localsHandler = new LocalsHandler.from(originalSavedLocals);
    startFinallyBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startFinallyBlock);
    buildFinalizer();
    if (!kernelBuilder.isAborted()) {
      endFinallyBlock = kernelBuilder.close(new HGoto());
    }
    tryInstruction.finallyBlock = startFinallyBlock;
    finallyGraph =
        new SubGraph(startFinallyBlock, kernelBuilder.lastOpenedBlock);
  }

  void closeTryBody() {
    // We use a [HExitTry] instead of a [HGoto] for the try block
    // because it will have multiple successors: the join block, and
    // the catch or finally block.
    if (!kernelBuilder.isAborted()) {
      endTryBlock = kernelBuilder.close(new HExitTry());
    }
    bodyGraph = new SubGraph(startTryBlock, kernelBuilder.lastOpenedBlock);
  }

  void buildCatch(ir.TryCatch tryCatch) {
    kernelBuilder.localsHandler = new LocalsHandler.from(originalSavedLocals);
    startCatchBlock = kernelBuilder.graph.addNewBlock();
    kernelBuilder.open(startCatchBlock);
    // Note that the name of this local is irrelevant.
    SyntheticLocal local = kernelBuilder.localsHandler.createLocal('exception');
    exception = new HLocalValue(local, kernelBuilder.commonMasks.nonNullType);
    kernelBuilder.add(exception);
    HInstruction oldRethrowableException = kernelBuilder.rethrowableException;
    kernelBuilder.rethrowableException = exception;

    kernelBuilder._pushStaticInvocation(
        kernelBuilder._commonElements.exceptionUnwrapper,
        [exception],
        kernelBuilder._typeInferenceMap
            .getReturnTypeOf(kernelBuilder._commonElements.exceptionUnwrapper));
    HInvokeStatic unwrappedException = kernelBuilder.pop();
    tryInstruction.exception = exception;
    int catchesIndex = 0;

    void pushCondition(ir.Catch catchBlock) {
      // `guard` is often `dynamic`, which generates `true`.
      kernelBuilder.pushIsTest(
          catchBlock.exception, catchBlock.guard, unwrappedException);
    }

    void visitThen() {
      ir.Catch catchBlock = tryCatch.catches[catchesIndex];
      catchesIndex++;
      if (catchBlock.exception != null) {
        LocalVariableElement exceptionVariable =
            kernelBuilder.localsMap.getLocal(catchBlock.exception);
        kernelBuilder.localsHandler
            .updateLocal(exceptionVariable, unwrappedException);
      }
      if (catchBlock.stackTrace != null) {
        kernelBuilder._pushStaticInvocation(
            kernelBuilder._commonElements.traceFromException,
            [exception],
            kernelBuilder._typeInferenceMap.getReturnTypeOf(
                kernelBuilder._commonElements.traceFromException));
        HInstruction traceInstruction = kernelBuilder.pop();
        LocalVariableElement traceVariable =
            kernelBuilder.localsMap.getLocal(catchBlock.stackTrace);
        kernelBuilder.localsHandler
            .updateLocal(traceVariable, traceInstruction);
      }
      catchBlock.body.accept(kernelBuilder);
    }

    void visitElse() {
      if (catchesIndex >= tryCatch.catches.length) {
        kernelBuilder.closeAndGotoExit(new HThrow(
            exception, exception.sourceInformation,
            isRethrow: true));
      } else {
        // TODO(efortuna): Make SsaBranchBuilder handle kernel elements, and
        // pass tryCatch in here as the "diagnosticNode".
        kernelBuilder.handleIf(
            visitCondition: () {
              pushCondition(tryCatch.catches[catchesIndex]);
            },
            visitThen: visitThen,
            visitElse: visitElse);
      }
    }

    ir.Catch firstBlock = tryCatch.catches[catchesIndex];
    // TODO(efortuna): Make SsaBranchBuilder handle kernel elements, and then
    // pass tryCatch in here as the "diagnosticNode".
    kernelBuilder.handleIf(
        visitCondition: () {
          pushCondition(firstBlock);
        },
        visitThen: visitThen,
        visitElse: visitElse);
    if (!kernelBuilder.isAborted()) {
      endCatchBlock = kernelBuilder.close(new HGoto());
    }

    kernelBuilder.rethrowableException = oldRethrowableException;
    tryInstruction.catchBlock = startCatchBlock;
    catchGraph = new SubGraph(startCatchBlock, kernelBuilder.lastOpenedBlock);
  }

  void cleanUp() {
    exitBlock = kernelBuilder.graph.addNewBlock();
    _setBlockSuccessors();

    // Use the locals handler not altered by the catch and finally
    // blocks.
    kernelBuilder.localsHandler = originalSavedLocals;
    kernelBuilder.open(exitBlock);
    enterBlock.setBlockFlow(
        new HTryBlockInformation(
            kernelBuilder.wrapStatementGraph(bodyGraph),
            exception,
            kernelBuilder.wrapStatementGraph(catchGraph),
            kernelBuilder.wrapStatementGraph(finallyGraph)),
        exitBlock);
    kernelBuilder.inTryStatement = previouslyInTryStatement;
  }
}
