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
import '../dump_info.dart';
import '../elements/elements.dart' show ErroneousElement;
import '../elements/entities.dart';
import '../elements/jumps.dart';
import '../elements/resolution_types.dart'
    show MalformedType, MethodTypeVariableType;
import '../elements/types.dart';
import '../io/source_information.dart';
import '../js/js.dart' as js;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../js_backend/runtime_types.dart' show RuntimeTypesSubstitutions;
import '../js_emitter/js_emitter.dart' show NativeEmitter;
import '../js_model/locals.dart'
    show forEachOrderedParameter, GlobalLocalsMap, JumpVisitor;
import '../kernel/element_map.dart';
import '../kernel/kernel_backend_strategy.dart';
import '../native/native.dart' as native;
import '../resolution/tree_elements.dart';
import '../types/masks.dart';
import '../types/types.dart';
import '../universe/selector.dart';
import '../universe/side_effects.dart' show SideEffects;
import '../universe/use.dart' show ConstantUse, DynamicUse, StaticUse;
import '../universe/world_builder.dart' show CodegenWorldBuilder;
import '../world.dart';
import 'graph_builder.dart';
import 'jump_handler.dart';
import 'kernel_string_builder.dart';
import 'locals_handler.dart';
import 'loop_handler.dart';
import 'nodes.dart';
import 'ssa.dart';
import 'ssa_branch_builder.dart';
import 'switch_continue_analysis.dart';
import 'type_builder.dart';

// TODO(johnniwinther): Merge this with [KernelInliningState].
class StackFrame {
  final StackFrame parent;
  final MemberEntity member;
  final AsyncMarker asyncMarker;
  final KernelToLocalsMap localsMap;
  final KernelToTypeInferenceMap typeInferenceMap;
  final SourceInformationBuilder<ir.Node> sourceInformationBuilder;

  StackFrame(this.parent, this.member, this.asyncMarker, this.localsMap,
      this.typeInferenceMap, this.sourceInformationBuilder);
}

class KernelSsaGraphBuilder extends ir.Visitor
    with GraphBuilder, SsaBuilderFieldMixin {
  final MemberEntity targetElement;

  final ClosedWorld closedWorld;
  final CodegenWorldBuilder _worldBuilder;
  final CodegenRegistry registry;
  final ClosureDataLookup closureDataLookup;

  /// A stack of [InterfaceType]s that have been seen during inlining of
  /// factory constructors.  These types are preserved in [HInvokeStatic]s and
  /// [HCreate]s inside the inline code and registered during code generation
  /// for these nodes.
  // TODO(karlklose): consider removing this and keeping the (substituted) types
  // of the type variables in an environment (like the [LocalsHandler]).
  final List<InterfaceType> currentImplicitInstantiations = <InterfaceType>[];

  /// Used to report information about inlining (which occurs while building the
  /// SSA graph), when dump-info is enabled.
  final InfoReporter _infoReporter;

  HInstruction rethrowableException;

  final Compiler compiler;

  @override
  JavaScriptBackend get backend => compiler.backend;

  @override
  TreeElements get elements =>
      throw new UnsupportedError('KernelSsaGraphBuilder.elements');

  final SourceInformationStrategy<ir.Node> _sourceInformationStrategy;
  final KernelToElementMapForBuilding _elementMap;
  final GlobalTypeInferenceResults _globalInferenceResults;
  final GlobalLocalsMap _globalLocalsMap;
  LoopHandler<ir.Node> loopHandler;
  TypeBuilder typeBuilder;

  final NativeEmitter nativeEmitter;

  // [ir.Let] and [ir.LocalInitializer] bindings.
  final Map<ir.VariableDeclaration, HInstruction> letBindings =
      <ir.VariableDeclaration, HInstruction>{};

  /// True if we are visiting the expression of a throw statement; we assume
  /// this is a slow path.
  bool _inExpressionOfThrow = false;

  final List<KernelInliningState> _inliningStack = <KernelInliningState>[];
  Local _returnLocal;
  DartType _returnType;
  bool _inLazyInitializerExpression = false;

  StackFrame _currentFrame;

  KernelSsaGraphBuilder(
      this.targetElement,
      InterfaceType instanceType,
      this.compiler,
      this._elementMap,
      this._globalInferenceResults,
      this._globalLocalsMap,
      this.closedWorld,
      this._worldBuilder,
      this.registry,
      this.closureDataLookup,
      this.nativeEmitter,
      this._sourceInformationStrategy)
      : _infoReporter = compiler.dumpInfoTask {
    _enterFrame(targetElement);
    this.loopHandler = new KernelLoopHandler(this);
    typeBuilder = new KernelTypeBuilder(this, _elementMap, _globalLocalsMap);
    graph.element = targetElement;
    graph.sourceInformation =
        _sourceInformationBuilder.buildVariableDeclaration();
    this.localsHandler = new LocalsHandler(this, targetElement, targetElement,
        instanceType, nativeData, interceptorData);
  }

  KernelToLocalsMap get localsMap => _currentFrame.localsMap;

  CommonElements get _commonElements => _elementMap.commonElements;

  KernelToTypeInferenceMap get _typeInferenceMap =>
      _currentFrame.typeInferenceMap;

  SourceInformationBuilder get _sourceInformationBuilder =>
      _currentFrame.sourceInformationBuilder;

  void _enterFrame(MemberEntity member) {
    AsyncMarker asyncMarker = AsyncMarker.SYNC;
    ir.FunctionNode function = getFunctionNode(_elementMap, member);
    if (function != null) {
      asyncMarker = getAsyncMarker(function);
    }
    _currentFrame = new StackFrame(
        _currentFrame,
        member,
        asyncMarker,
        _globalLocalsMap.getLocalsMap(member),
        new KernelToTypeInferenceMapImpl(member, _globalInferenceResults),
        _currentFrame != null
            ? _currentFrame.sourceInformationBuilder.forContext(member)
            : _sourceInformationStrategy.createBuilderForContext(member));
  }

  void _leaveFrame() {
    _currentFrame = _currentFrame.parent;
  }

  HGraph build() {
    return reporter.withCurrentElement(localsMap.currentMember, () {
      // TODO(het): no reason to do this here...
      HInstruction.idCounter = 0;
      MemberDefinition definition =
          _elementMap.getMemberDefinition(targetElement);

      switch (definition.kind) {
        case MemberKind.regular:
        case MemberKind.closureCall:
          ir.Node target = definition.node;
          if (target is ir.Procedure) {
            if (target.isExternal) {
              buildExternalFunctionNode(
                  _ensureDefaultArgumentValues(target.function));
            } else {
              buildFunctionNode(_ensureDefaultArgumentValues(target.function));
            }
          } else if (target is ir.Field) {
            if (handleConstantField(targetElement, registry, closedWorld)) {
              // No code is generated for `targetElement`: All references inline
              // the constant value.
              return null;
            } else if (targetElement.isStatic || targetElement.isTopLevel) {
              backend.constants.registerLazyStatic(targetElement);
            }
            buildField(target);
          } else if (target is ir.FunctionExpression) {
            buildFunctionNode(_ensureDefaultArgumentValues(target.function));
          } else if (target is ir.FunctionDeclaration) {
            buildFunctionNode(_ensureDefaultArgumentValues(target.function));
          } else {
            throw 'No case implemented to handle target: '
                '$target for $targetElement';
          }
          break;
        case MemberKind.constructor:
          ir.Constructor constructor = definition.node;
          _ensureDefaultArgumentValues(constructor.function);
          buildConstructor(constructor);
          break;
        case MemberKind.constructorBody:
          ir.Constructor constructor = definition.node;
          _ensureDefaultArgumentValues(constructor.function);
          buildConstructorBody(constructor);
          break;
        case MemberKind.closureField:
          failedAt(targetElement, "Unexpected closure field: $targetElement");
          break;
      }
      assert(graph.isValid());

      if (backend.tracer.isEnabled) {
        MemberEntity member = definition.member;
        String name = member.name;
        if (member.isInstanceMember ||
            member.isConstructor ||
            member.isStatic) {
          name = "${member.enclosingClass.name}.$name";
          if (definition.kind == MemberKind.constructorBody) {
            name += " (body)";
          }
        }
        backend.tracer.traceCompilation(name);
        backend.tracer.traceGraph('builder', graph);
      }

      return graph;
    });
  }

  ir.FunctionNode _ensureDefaultArgumentValues(ir.FunctionNode function) {
    // Register all [function]'s default argument values.
    //
    // Default values might be (or contain) functions that are not referenced
    // from anywhere else so we need to ensure these are enqueued.  Stubs and
    // `Function.apply` data are created after the codegen queue is closed, so
    // we force these functions into the queue by registering the constants as
    // used in advance. See language/cyclic_default_values_test.dart for an
    // example.
    //
    // TODO(sra): We could be more precise if stubs and `Function.apply` data
    // were generated by the codegen enqueuer. In practice even in huge programs
    // there are only very small number of constants created here that are not
    // actually used.
    void registerDefaultValue(ir.VariableDeclaration node) {
      ConstantValue constantValue =
          _elementMap.getConstantValue(node.initializer, implicitNull: true);
      assert(
          constantValue != null,
          failedAt(_elementMap.getMethod(function.parent),
              'No constant computed for $node'));
      registry?.registerConstantUse(new ConstantUse.init(constantValue));
    }

    function.positionalParameters
        .skip(function.requiredParameterCount)
        .forEach(registerDefaultValue);
    function.namedParameters.forEach(registerDefaultValue);
    return function;
  }

  @override
  ConstantValue getFieldInitialConstantValue(FieldEntity field) {
    assert(field == targetElement);
    return _elementMap.getFieldConstantValue(field);
  }

  void buildField(ir.Field field) {
    _inLazyInitializerExpression = field.isStatic;
    openFunction();
    if (field.isInstanceMember && options.enableTypeAssertions) {
      HInstruction thisInstruction = localsHandler.readThis(
          sourceInformation: _sourceInformationBuilder.buildGet(field));
      // Use dynamic type because the type computed by the inferrer is
      // narrowed to the type annotation.
      FieldEntity fieldEntity = _elementMap.getMember(field);
      HInstruction parameter =
          new HParameterValue(fieldEntity, commonMasks.dynamicType);
      // Add the parameter as the last instruction of the entry block.
      // If the method is intercepted, we want the actual receiver
      // to be the first parameter.
      graph.entry.addBefore(graph.entry.last, parameter);
      HInstruction value = typeBuilder.potentiallyCheckOrTrustType(
          parameter, _getDartTypeIfValid(field.type));
      add(new HFieldSet(fieldEntity, thisInstruction, value));
    } else {
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
      closeAndGotoExit(
          new HReturn(value, _sourceInformationBuilder.buildReturn(field)));
    }
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
      InterfaceType type = commonElements.boolType;
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
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildCreate(constructor);
    ir.Class constructedClass = constructor.enclosingClass;

    if (_inliningStack.isEmpty) {
      openFunction(constructor.function);
    }
    _addClassTypeVariablesIfNeeded(constructor);
    _potentiallyAddFunctionParameterTypeChecks(constructor.function);

    // [fieldValues] accumulates the field initializer values, which may be
    // overwritten by initializer-list initializers.
    Map<FieldEntity, HInstruction> fieldValues = <FieldEntity, HInstruction>{};
    List<ir.Constructor> constructorChain = <ir.Constructor>[];
    _buildInitializers(constructor, constructorChain, fieldValues);

    List<HInstruction> constructorArguments = <HInstruction>[];
    // Doing this instead of fieldValues.forEach because we haven't defined the
    // order of the arguments here. We can define that with JElements.
    ClassEntity cls = _elementMap.getClass(constructedClass);
    bool isCustomElement = nativeData.isNativeOrExtendsNative(cls) &&
        !nativeData.isJsInteropClass(cls);
    InterfaceType thisType = _elementMap.elementEnvironment.getThisType(cls);
    List<FieldEntity> fields = <FieldEntity>[];
    _worldBuilder.forEachInstanceField(cls,
        (ClassEntity enclosingClass, FieldEntity member) {
      var value = fieldValues[member];
      if (value == null) {
        assert(isCustomElement || reporter.hasReportedError,
            'No initializer value for field ${member}');
      } else {
        fields.add(member);
        DartType type = _elementMap.elementEnvironment.getFieldType(member);
        type = localsHandler.substInContext(type);
        constructorArguments
            .add(typeBuilder.potentiallyCheckOrTrustType(value, type));
      }
    });

    HInstruction newObject;
    if (isCustomElement) {
      // Bulk assign to the initialized fields.
      newObject = graph.explicitReceiverParameter;
      // Null guard ensures an error if we are being called from an explicit
      // 'new' of the constructor instead of via an upgrade. It is optimized out
      // if there are field initializers.
      add(new HFieldGet(null, newObject, commonMasks.dynamicType,
          isAssignable: false));
      for (int i = 0; i < fields.length; i++) {
        add(new HFieldSet(fields[i], newObject, constructorArguments[i]));
      }
    } else {
      // Create the runtime type information, if needed.
      bool hasRtiInput = closedWorld.rtiNeed.classNeedsRtiField(cls);
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

      newObject = new HCreate(cls, constructorArguments,
          new TypeMask.nonNullExact(cls, closedWorld), sourceInformation,
          instantiatedTypes: <InterfaceType>[thisType],
          hasRtiInput: hasRtiInput);

      add(newObject);
    }

    HInstruction interceptor;
    // Generate calls to the constructor bodies.
    for (ir.Constructor body in constructorChain.reversed) {
      if (_isEmptyStatement(body.function.body)) continue;

      List<HInstruction> bodyCallInputs = <HInstruction>[];
      if (isCustomElement) {
        if (interceptor == null) {
          ConstantValue constant = new InterceptorConstantValue(cls);
          interceptor = graph.addConstant(constant, closedWorld);
        }
        bodyCallInputs.add(interceptor);
      }
      bodyCallInputs.add(newObject);

      // Pass uncaptured arguments first, captured arguments in a box, then type
      // arguments.

      ConstructorEntity constructorElement = _elementMap.getConstructor(body);

      inlinedFrom(constructorElement, () {
        void handleParameter(ir.VariableDeclaration node) {
          Local parameter = localsMap.getLocalVariable(node);
          // If [parameter] is boxed, it will be a field in the box passed as
          // the last parameter. So no need to directly pass it.
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
        CapturedScope scopeData =
            closureDataLookup.getCapturedScope(constructorElement);
        if (scopeData.requiresContextBox) {
          bodyCallInputs.add(localsHandler.readLocal(scopeData.context));
        }

        // Pass type arguments.
        ir.Class currentClass = body.enclosingClass;
        if (closedWorld.rtiNeed
            .classNeedsRti(_elementMap.getClass(currentClass))) {
          for (ir.DartType typeParameter
              in currentClass.thisType.typeArguments) {
            HInstruction argument = localsHandler.readLocal(
                localsHandler.getTypeVariableAsLocal(
                    _elementMap.getDartType(typeParameter)));
            bodyCallInputs.add(argument);
          }
        }

        ConstructorBodyEntity constructorBody =
            _elementMap.getConstructorBody(body);
        if (!isCustomElement && // TODO(13836): Fix inlining.
            _tryInlineMethod(constructorBody, null, null, bodyCallInputs,
                constructor, sourceInformation)) {
          pop();
        } else {
          _invokeConstructorBody(
              body,
              bodyCallInputs,
              _sourceInformationBuilder
                  .buildDeclaration(_elementMap.getMember(constructor)));
        }
      });
    }

    if (_inliningStack.isEmpty) {
      closeAndGotoExit(new HReturn(newObject, sourceInformation));
      closeFunction();
    } else {
      localsHandler.updateLocal(_returnLocal, newObject,
          sourceInformation: sourceInformation);
    }
  }

  static bool _isEmptyStatement(ir.Statement body) {
    if (body is ir.EmptyStatement) return true;
    if (body is ir.Block) return body.statements.every(_isEmptyStatement);
    return false;
  }

  void _invokeConstructorBody(ir.Constructor constructor,
      List<HInstruction> inputs, SourceInformation sourceInformation) {
    // TODO(sra): Inline the constructor body.
    MemberEntity constructorBody = _elementMap.getConstructorBody(constructor);
    HInvokeConstructorBody invoke = new HInvokeConstructorBody(
        constructorBody, inputs, commonMasks.nonNullType, sourceInformation);
    add(invoke);
  }

  /// Sets context for generating code that is the result of inlining
  /// [inlinedTarget].
  inlinedFrom(MemberEntity inlinedTarget, f()) {
    reporter.withCurrentElement(inlinedTarget, () {
      _enterFrame(inlinedTarget);
      var result = f();
      _leaveFrame();
      return result;
    });
  }

  /// Collects the values for field initializers for the direct fields of
  /// [clazz].
  void _collectFieldValues(
      ir.Class clazz, Map<FieldEntity, HInstruction> fieldValues) {
    ClassEntity cls = _elementMap.getClass(clazz);
    _worldBuilder.forEachDirectInstanceField(cls, (FieldEntity field) {
      MemberDefinition definition = _elementMap.getMemberDefinition(field);
      ir.Field node;
      switch (definition.kind) {
        case MemberKind.regular:
          node = definition.node;
          break;
        default:
          failedAt(field, "Unexpected member definition $definition.");
      }
      if (node.initializer == null) {
        // Unassigned fields of native classes are not initialized to
        // prevent overwriting pre-initialized native properties.
        if (!nativeData.isNativeOrExtendsNative(cls)) {
          fieldValues[field] = graph.addConstantNull(closedWorld);
        }
      } else if (node.initializer is! ir.NullLiteral ||
          !nativeData.isNativeClass(cls)) {
        // Compile the initializer in the context of the field so we know that
        // class type parameters are accessed as values.
        // TODO(sra): It would be sufficient to know the context was a field
        // initializer.
        inlinedFrom(field, () {
          node.initializer.accept(this);
          fieldValues[field] = pop();
        });
      }
    });
  }

  static bool isRedirectingConstructor(ir.Constructor constructor) =>
      constructor.initializers
          .any((initializer) => initializer is ir.RedirectingInitializer);

  /// Collects field initializers all the way up the inheritance chain.
  void _buildInitializers(
      ir.Constructor constructor,
      List<ir.Constructor> constructorChain,
      Map<FieldEntity, HInstruction> fieldValues) {
    assert(
        _elementMap.getConstructor(constructor) == localsMap.currentMember,
        failedAt(
            localsMap.currentMember,
            'Expected ${localsMap.currentMember} '
            'but found ${_elementMap.getConstructor(constructor)}.'));
    constructorChain.add(constructor);

    if (!isRedirectingConstructor(constructor)) {
      // Compute values for field initializers, but only if this is not a
      // redirecting constructor, since the target will compute the fields.
      _collectFieldValues(constructor.enclosingClass, fieldValues);
    }
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
        // LocalInitializer is like a let-expression that is in scope for the
        // rest of the initializers.
        ir.VariableDeclaration variable = initializer.variable;
        assert(variable.isFinal);
        variable.initializer.accept(this);
        HInstruction value = pop();
        // TODO(sra): Apply inferred type information.
        letBindings[variable] = value;
      } else if (initializer is ir.AssertInitializer) {
        // Assert in initializer is currently not supported in dart2js.
        // TODO(johnniwinther): Support assert in initializer.
      } else if (initializer is ir.InvalidInitializer) {
        assert(false, 'ir.InvalidInitializer not handled');
      } else {
        assert(false, 'Unhandled initializer ir.${initializer.runtimeType}');
      }
    }

    if (!foundSuperOrRedirectCall) {
      assert(
          _elementMap.getClass(constructor.enclosingClass) ==
                  _elementMap.commonElements.objectClass ||
              constructor.initializers.any(_ErroneousInitializerVisitor.check),
          'All constructors should have super- or redirecting- initializers,'
          ' except Object()'
          ' ${constructor.initializers}');
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
    ir.Supertype supertype = callerClass.supertype;

    if (callerClass.mixedInType != null) {
      _bindSupertypeTypeParameters(callerClass.mixedInType);
      _collectFieldValues(callerClass.mixedInType.classNode, fieldValues);
    }

    // The class of the super-constructor may not be the supertype class. In
    // this case, we must go up the class hierarchy until we reach the class
    // containing the super-constructor.
    while (supertype.classNode != target.enclosingClass) {
      _bindSupertypeTypeParameters(supertype);

      if (supertype.classNode.mixedInType != null) {
        _bindSupertypeTypeParameters(supertype.classNode.mixedInType);
      }

      // Fields from unnamed mixin application classes (ie Object&Foo) get
      // "collected" with the regular supertype fields, so we must bind type
      // parameters from both the supertype and the supertype's mixin classes
      // before collecting the field values.
      _collectFieldValues(supertype.classNode, fieldValues);
      supertype = supertype.classNode.supertype;
    }
    _bindSupertypeTypeParameters(supertype);
    supertype = supertype.classNode.supertype;

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

    ConstructorEntity element = _elementMap.getConstructor(constructor);
    ScopeInfo oldScopeInfo = localsHandler.scopeInfo;
    inlinedFrom(element, () {
      void handleParameter(ir.VariableDeclaration node) {
        Local parameter = localsMap.getLocalVariable(node);
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
      ScopeInfo newScopeInfo = closureDataLookup.getScopeInfo(element);
      localsHandler.scopeInfo = newScopeInfo;
      localsHandler.enterScope(closureDataLookup.getCapturedScope(element),
          _sourceInformationBuilder.buildDeclaration(element));
      _buildInitializers(constructor, constructorChain, fieldValues);
    });
    localsHandler.scopeInfo = oldScopeInfo;
  }

  /// Builds generative constructor body.
  void buildConstructorBody(ir.Constructor constructor) {
    openFunction(constructor.function);
    _addClassTypeVariablesIfNeeded(constructor);
    _potentiallyAddFunctionParameterTypeChecks(constructor.function);
    constructor.function.body.accept(this);
    closeFunction();
  }

  /// Builds a SSA graph for FunctionNodes, found in FunctionExpressions and
  /// Procedures.
  void buildFunctionNode(ir.FunctionNode functionNode) {
    openFunction(functionNode);
    ir.TreeNode parent = functionNode.parent;
    if (parent is ir.Procedure && parent.kind == ir.ProcedureKind.Factory) {
      _addClassTypeVariablesIfNeeded(parent);
    }
    _potentiallyAddFunctionParameterTypeChecks(functionNode);

    // If [functionNode] is `operator==` we explicitly add a null check at the
    // beginning of the method. This is to avoid having call sites do the null
    // check.
    if (parent is ir.Procedure &&
        parent.kind == ir.ProcedureKind.Operator &&
        parent.name.name == '==') {
      FunctionEntity method = _elementMap.getMethod(parent);
      if (!_commonElements.operatorEqHandlesNullArgument(method)) {
        handleIf(
            visitCondition: () {
              HParameterValue parameter = parameters.values.first;
              push(new HIdentity(parameter, graph.addConstantNull(closedWorld),
                  null, commonMasks.boolType));
            },
            visitThen: () {
              closeAndGotoExit(new HReturn(
                  graph.addConstantBool(false, closedWorld),
                  _sourceInformationBuilder.buildReturn(functionNode)));
            },
            visitElse: null,
            sourceInformation: _sourceInformationBuilder.buildIf(functionNode));
      }
    }
    functionNode.body.accept(this);
    closeFunction();
  }

  void _potentiallyAddFunctionParameterTypeChecks(ir.FunctionNode function) {
    // Put the type checks in the first successor of the entry,
    // because that is where the type guards will also be inserted.
    // This way we ensure that a type guard will dominate the type
    // check.
    MemberDefinition definition =
        _elementMap.getMemberDefinition(targetElement);
    bool nodeIsConstructorBody = definition.kind == MemberKind.constructorBody;

    void _handleParameter(ir.VariableDeclaration variable) {
      Local local = localsMap.getLocalVariable(variable);
      if (nodeIsConstructorBody &&
          closureDataLookup.getCapturedScope(targetElement).isBoxed(local)) {
        // If local is boxed, then `variable` will be a field inside the box
        // passed as the last parameter, so no need to update our locals
        // handler or check types at this point.
        return;
      }
      HInstruction newParameter = localsHandler.directLocals[local];
      newParameter = typeBuilder.potentiallyCheckOrTrustType(
          newParameter, _getDartTypeIfValid(variable.type));
      localsHandler.directLocals[local] = newParameter;
    }

    function.positionalParameters.forEach(_handleParameter);
    function.namedParameters.toList()..forEach(_handleParameter);
  }

  /// Builds a SSA graph for FunctionNodes of external methods.
  void buildExternalFunctionNode(ir.FunctionNode functionNode) {
    // TODO(johnniwinther): Non-js-interop external functions should
    // throw a runtime error.
    assert(functionNode.body == null);
    openFunction(functionNode);
    ir.TreeNode parent = functionNode.parent;
    if (parent is ir.Procedure && parent.kind == ir.ProcedureKind.Factory) {
      _addClassTypeVariablesIfNeeded(parent);
    }
    _potentiallyAddFunctionParameterTypeChecks(functionNode);

    if (closedWorld.nativeData.isNativeMember(targetElement)) {
      nativeEmitter.nativeMethods.add(targetElement);
      String nativeName;
      if (closedWorld.nativeData.hasFixedBackendName(targetElement)) {
        nativeName = closedWorld.nativeData.getFixedBackendName(targetElement);
      } else {
        nativeName = targetElement.name;
      }

      String templateReceiver = '';
      List<String> templateArguments = <String>[];
      List<HInstruction> inputs = <HInstruction>[];
      if (targetElement.isInstanceMember) {
        templateReceiver = '#.';
        inputs.add(localsHandler.readThis(
            sourceInformation:
                _sourceInformationBuilder.buildGet(functionNode)));
      }

      for (ir.VariableDeclaration param in functionNode.positionalParameters) {
        templateArguments.add('#');
        Local local = localsMap.getLocalVariable(param);
        // Convert Dart function to JavaScript function.
        HInstruction argument = localsHandler.readLocal(local);
        ir.DartType type = param.type;
        if (type is ir.FunctionType) {
          int arity = type.positionalParameters.length;
          _pushStaticInvocation(
              _commonElements.closureConverter,
              [argument, graph.addConstantInt(arity, closedWorld)],
              commonMasks.dynamicType);
          argument = pop();
        }
        inputs.add(argument);
      }

      String arguments = templateArguments.join(',');

      // TODO(sra): Use declared type or NativeBehavior type.
      TypeMask typeMask = commonMasks.dynamicType;
      String template;
      if (targetElement.isGetter) {
        template = '${templateReceiver}$nativeName';
      } else if (targetElement.isSetter) {
        template = '${templateReceiver}$nativeName = ${arguments}';
      } else {
        template = '${templateReceiver}$nativeName(${arguments})';
      }

      push(new HForeignCode(
          js.js.uncachedExpressionTemplate(template), typeMask, inputs,
          effects: new SideEffects()));
      // TODO(johnniwinther): Provide source information.
      HInstruction value = pop();
      if (targetElement.isSetter) {
        value = graph.addConstantNull(closedWorld);
      }
      close(new HReturn(
              value, _sourceInformationBuilder.buildReturn(functionNode)))
          .addSuccessor(graph.exit);
    }
    // TODO(sra): Handle JS-interop methods.
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
        Local local = localsMap.getLocalVariable(node);
        parameterMap[local] =
            _typeInferenceMap.getInferredTypeOfParameter(local);
      }

      function.positionalParameters.forEach(handleParameter);
      function.namedParameters.toList()
        ..sort(namedOrdering)
        ..forEach(handleParameter);
      _returnType = _elementMap.getDartType(function.returnType);
    }

    HBasicBlock block = graph.addNewBlock();
    open(graph.entry);

    localsHandler.startFunction(
        targetElement,
        closureDataLookup.getScopeInfo(targetElement),
        closureDataLookup.getCapturedScope(targetElement),
        parameterMap,
        _sourceInformationBuilder.buildDeclaration(targetElement),
        isGenerativeConstructorBody: targetElement is ConstructorBodyEntity);
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
  MemberEntity get sourceElement => _currentFrame.member;

  @override
  void visitCheckLibraryIsLoaded(ir.CheckLibraryIsLoaded checkLoad) {
    HInstruction prefixConstant =
        graph.addConstantString(checkLoad.import.name, closedWorld);
    String uri = _elementMap.getDeferredUri(checkLoad.import);
    HInstruction uriConstant = graph.addConstantString(uri, closedWorld);
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
        commonElements.loadDeferredLibrary,
        [graph.addConstantString(loadLibrary.import.name, closedWorld)],
        commonMasks.nonNullType,
        targetCanThrow: false));
  }

  @override
  void visitBlock(ir.Block block) {
    assert(!isAborted());
    if (!isReachable) return; // This can only happen when inlining.
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
  void visitEmptyStatement(ir.EmptyStatement node) {
    // Empty statement adds no instructions to current block.
  }

  @override
  void visitExpressionStatement(ir.ExpressionStatement node) {
    if (!isReachable) return;
    ir.Expression expression = node.expression;
    if (expression is ir.Throw && _inliningStack.isEmpty) {
      _visitThrowExpression(expression.expression);
      handleInTryStatement();
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildThrow(node.expression);
      closeAndGotoExit(new HThrow(pop(), sourceInformation));
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
  void visitReturnStatement(ir.ReturnStatement node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildReturn(node);
    HInstruction value;
    if (node.expression == null) {
      value = graph.addConstantNull(closedWorld);
    } else {
      node.expression.accept(this);
      value = pop();
      if (_currentFrame.asyncMarker == AsyncMarker.ASYNC) {
        if (options.enableTypeAssertions &&
            !isValidAsyncReturnType(_returnType)) {
          generateTypeError(
              "Async function returned a Future,"
              " was declared to return a ${_returnType}.",
              sourceInformation);
          pop();
          return;
        }
      } else {
        value = typeBuilder.potentiallyCheckOrTrustType(value, _returnType);
      }
    }
    handleInTryStatement();
    _emitReturn(value, sourceInformation);
  }

  @override
  void visitForStatement(ir.ForStatement node) {
    assert(isReachable);
    assert(node.body != null);
    void buildInitializer() {
      for (ir.VariableDeclaration declaration in node.variables) {
        declaration.accept(this);
      }
    }

    HInstruction buildCondition() {
      if (node.condition == null) {
        return graph.addConstantBool(true, closedWorld);
      }
      node.condition.accept(this);
      return popBoolified();
    }

    void buildUpdate() {
      for (ir.Expression expression in node.updates) {
        expression.accept(this);
        assert(!isAborted());
        // The result of the update instruction isn't used, and can just
        // be dropped.
        pop();
      }
    }

    void buildBody() {
      node.body.accept(this);
    }

    JumpTarget jumpTarget = localsMap.getJumpTargetForFor(node);
    loopHandler.handleLoop(
        node,
        localsMap.getCapturedLoopScope(closureDataLookup, node),
        jumpTarget,
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody,
        _sourceInformationBuilder.buildLoop(node));
  }

  @override
  void visitForInStatement(ir.ForInStatement node) {
    if (node.isAsync) {
      _buildAsyncForIn(node);
    } else if (_typeInferenceMap.isJsIndexableIterator(node, closedWorld)) {
      // If the expression being iterated over is a JS indexable type, we can
      // generate an optimized version of for-in that uses indexing.
      _buildForInIndexable(node);
    } else {
      _buildForInIterator(node);
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
  _buildForInIndexable(ir.ForInStatement node) {
    SyntheticLocal indexVariable = localsHandler.createLocal('_i');

    // These variables are shared by initializer, condition, body and update.
    HInstruction array; // Set in buildInitializer.
    bool isFixed; // Set in buildInitializer.
    HInstruction originalLength = null; // Set for growable lists.

    HInstruction buildGetLength(SourceInformation sourceInformation) {
      HGetLength result = new HGetLength(array, commonMasks.positiveIntType,
          isAssignable: !isFixed)
        ..sourceInformation = sourceInformation;
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
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildForInMoveNext(node);
      HInstruction length = buildGetLength(sourceInformation);
      push(new HIdentity(length, originalLength, null, commonMasks.boolType)
        ..sourceInformation = sourceInformation);
      _pushStaticInvocation(
          _commonElements.checkConcurrentModificationError,
          [pop(), array],
          _typeInferenceMap.getReturnTypeOf(
              _commonElements.checkConcurrentModificationError),
          sourceInformation: sourceInformation);
      pop();
    }

    void buildInitializer() {
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildForInIterator(node);

      node.iterable.accept(this);
      array = pop();
      isFixed =
          _typeInferenceMap.isFixedLength(array.instructionType, closedWorld);
      localsHandler.updateLocal(
          indexVariable, graph.addConstantInt(0, closedWorld),
          sourceInformation: sourceInformation);
      originalLength = buildGetLength(sourceInformation);
    }

    HInstruction buildCondition() {
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildForInMoveNext(node);
      HInstruction index = localsHandler.readLocal(indexVariable,
          sourceInformation: sourceInformation);
      HInstruction length = buildGetLength(sourceInformation);
      HInstruction compare =
          new HLess(index, length, null, commonMasks.boolType)
            ..sourceInformation = sourceInformation;
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
      TypeMask type = _typeInferenceMap.inferredIndexType(node);

      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildForInCurrent(node);
      HInstruction index = localsHandler.readLocal(indexVariable,
          sourceInformation: sourceInformation);
      HInstruction value = new HIndex(array, index, null, type)
        ..sourceInformation = sourceInformation;
      add(value);

      Local loopVariableLocal = localsMap.getLocalVariable(node.variable);
      localsHandler.updateLocal(loopVariableLocal, value,
          sourceInformation: sourceInformation);
      // Hint to name loop value after name of loop variable.
      if (loopVariableLocal is! SyntheticLocal) {
        value.sourceElement ??= loopVariableLocal;
      }

      node.body.accept(this);
    }

    void buildUpdate() {
      // See buildBody as to why we check here.
      buildConcurrentModificationErrorCheck();

      // TODO(sra): It would be slightly shorter to generate `a[i++]` in the
      // body (and that more closely follows what an inlined iterator would do)
      // but the code is horrible as `i+1` is carried around the loop in an
      // additional variable.
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildForInSet(node);
      HInstruction index = localsHandler.readLocal(indexVariable,
          sourceInformation: sourceInformation);
      HInstruction one = graph.addConstantInt(1, closedWorld);
      HInstruction addInstruction =
          new HAdd(index, one, null, commonMasks.positiveIntType)
            ..sourceInformation = sourceInformation;
      add(addInstruction);
      localsHandler.updateLocal(indexVariable, addInstruction,
          sourceInformation: sourceInformation);
    }

    loopHandler.handleLoop(
        node,
        localsMap.getCapturedLoopScope(closureDataLookup, node),
        localsMap.getJumpTargetForForIn(node),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody,
        _sourceInformationBuilder.buildLoop(node));
  }

  _buildForInIterator(ir.ForInStatement node) {
    // Generate a structure equivalent to:
    //   Iterator<E> $iter = <iterable>.iterator;
    //   while ($iter.moveNext()) {
    //     <variable> = $iter.current;
    //     <body>
    //   }

    // The iterator is shared between initializer, condition and body.
    HInstruction iterator;

    void buildInitializer() {
      TypeMask mask = _typeInferenceMap.typeOfIterator(node);
      node.iterable.accept(this);
      HInstruction receiver = pop();
      _pushDynamicInvocation(
          node,
          mask,
          Selectors.iterator,
          <HInstruction>[receiver],
          _sourceInformationBuilder.buildForInIterator(node));
      iterator = pop();
    }

    HInstruction buildCondition() {
      TypeMask mask = _typeInferenceMap.typeOfIteratorMoveNext(node);
      _pushDynamicInvocation(
          node,
          mask,
          Selectors.moveNext,
          <HInstruction>[iterator],
          _sourceInformationBuilder.buildForInMoveNext(node));
      return popBoolified();
    }

    void buildBody() {
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildForInCurrent(node);
      TypeMask mask = _typeInferenceMap.typeOfIteratorCurrent(node);
      _pushDynamicInvocation(
          node, mask, Selectors.current, [iterator], sourceInformation);

      Local loopVariableLocal = localsMap.getLocalVariable(node.variable);
      HInstruction value = typeBuilder.potentiallyCheckOrTrustType(
          pop(), _getDartTypeIfValid(node.variable.type));
      localsHandler.updateLocal(loopVariableLocal, value,
          sourceInformation: sourceInformation);
      // Hint to name loop value after name of loop variable.
      if (loopVariableLocal is! SyntheticLocal) {
        value.sourceElement ??= loopVariableLocal;
      }
      node.body.accept(this);
    }

    loopHandler.handleLoop(
        node,
        localsMap.getCapturedLoopScope(closureDataLookup, node),
        localsMap.getJumpTargetForForIn(node),
        buildInitializer,
        buildCondition,
        () {},
        buildBody,
        _sourceInformationBuilder.buildLoop(node));
  }

  void _buildAsyncForIn(ir.ForInStatement node) {
    // The async-for is implemented with a StreamIterator.
    HInstruction streamIterator;

    node.iterable.accept(this);
    _pushStaticInvocation(
        _commonElements.streamIteratorConstructor,
        [pop(), graph.addConstantNull(closedWorld)],
        _typeInferenceMap
            .getReturnTypeOf(_commonElements.streamIteratorConstructor));
    streamIterator = pop();

    void buildInitializer() {}

    HInstruction buildCondition() {
      TypeMask mask = _typeInferenceMap.typeOfIteratorMoveNext(node);
      _pushDynamicInvocation(node, mask, Selectors.moveNext, [streamIterator],
          _sourceInformationBuilder.buildForInMoveNext(node));
      HInstruction future = pop();
      push(new HAwait(future, closedWorld.commonMasks.dynamicType));
      return popBoolified();
    }

    void buildBody() {
      TypeMask mask = _typeInferenceMap.typeOfIteratorCurrent(node);
      _pushDynamicInvocation(node, mask, Selectors.current, [streamIterator],
          _sourceInformationBuilder.buildForInIterator(node));
      localsHandler.updateLocal(
          localsMap.getLocalVariable(node.variable), pop());
      node.body.accept(this);
    }

    void buildUpdate() {}

    // Creates a synthetic try/finally block in case anything async goes amiss.
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(
        this, _sourceInformationBuilder.buildLoop(node));
    // Build fake try body:
    loopHandler.handleLoop(
        node,
        localsMap.getCapturedLoopScope(closureDataLookup, node),
        localsMap.getJumpTargetForForIn(node),
        buildInitializer,
        buildCondition,
        buildUpdate,
        buildBody,
        _sourceInformationBuilder.buildLoop(node));

    void finalizerFunction() {
      _pushDynamicInvocation(node, null, Selectors.cancel, [streamIterator],
          _sourceInformationBuilder.buildGeneric(node));
      add(new HAwait(pop(), closedWorld.commonMasks.dynamicType));
    }

    tryBuilder
      ..closeTryBody()
      ..buildFinallyBlock(finalizerFunction)
      ..cleanUp();
  }

  HInstruction callSetRuntimeTypeInfo(HInstruction typeInfo,
      HInstruction newObject, SourceInformation sourceInformation) {
    // Set the runtime type information on the object.
    FunctionEntity typeInfoSetterFn = _commonElements.setRuntimeTypeInfo;
    // TODO(efortuna): Insert source information in this static invocation.
    _pushStaticInvocation(typeInfoSetterFn, <HInstruction>[newObject, typeInfo],
        commonMasks.dynamicType,
        sourceInformation: sourceInformation);

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
  void visitWhileStatement(ir.WhileStatement node) {
    assert(isReachable);
    HInstruction buildCondition() {
      node.condition.accept(this);
      return popBoolified();
    }

    loopHandler.handleLoop(
        node,
        localsMap.getCapturedLoopScope(closureDataLookup, node),
        localsMap.getJumpTargetForWhile(node),
        () {},
        buildCondition,
        () {}, () {
      node.body.accept(this);
    }, _sourceInformationBuilder.buildLoop(node));
  }

  @override
  visitDoStatement(ir.DoStatement node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildLoop(node);
    // TODO(efortuna): I think this can be rewritten using
    // LoopHandler.handleLoop with some tricks about when the "update" happens.
    LocalsHandler savedLocals = new LocalsHandler.from(localsHandler);
    CapturedLoopScope loopClosureInfo =
        localsMap.getCapturedLoopScope(closureDataLookup, node);
    localsHandler.startLoop(loopClosureInfo, sourceInformation);
    JumpTarget target = localsMap.getJumpTargetForDo(node);
    JumpHandler jumpHandler = loopHandler.beginLoopHeader(node, target);
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
    localsHandler.enterLoopBody(loopClosureInfo, sourceInformation);
    node.body.accept(this);

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

      node.condition.accept(this);
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
          sourceInformation);
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
        JumpTarget target = localsMap.getJumpTargetForDo(node);
        LabelDefinition label =
            target.addLabel(null, 'loop', isBreakTarget: true);
        HLabeledBlockInformation info = new HLabeledBlockInformation(
            new HSubGraphBlockInformation(bodyGraph), <LabelDefinition>[label]);
        loopEntryBlock.setBlockFlow(info, current);
        jumpHandler.forEachBreak((HBreak breakInstruction, _) {
          HBasicBlock block = breakInstruction.block;
          block.addAtExit(new HBreak.toLabel(label, sourceInformation));
          block.remove(breakInstruction);
        });
      }
    }
    jumpHandler.close();
  }

  @override
  void visitIfStatement(ir.IfStatement node) {
    handleIf(
        visitCondition: () => node.condition.accept(this),
        visitThen: () => node.then.accept(this),
        visitElse: () => node.otherwise?.accept(this),
        sourceInformation: _sourceInformationBuilder.buildIf(node));
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
  void visitAsExpression(ir.AsExpression node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildAs(node);
    node.operand.accept(this);
    HInstruction expressionInstruction = pop();

    if (node.type is ir.InvalidType) {
      generateTypeError('invalid type', sourceInformation);
      return;
    }

    DartType type = _elementMap.getDartType(node.type);
    if (type.isMalformed) {
      // TODO(johnniwinther): This branch is no longer needed.
      if (type is MalformedType) {
        ErroneousElement element = type.element;
        generateTypeError(element.message, sourceInformation);
      } else {
        assert(type is MethodTypeVariableType);
        stack.add(expressionInstruction);
      }
    } else {
      HInstruction converted = typeBuilder.buildTypeConversion(
          expressionInstruction,
          localsHandler.substInContext(type),
          HTypeConversion.CAST_TYPE_CHECK,
          sourceInformation: sourceInformation);
      if (converted != expressionInstruction) {
        add(converted);
      }
      stack.add(converted);
    }
  }

  void generateError(FunctionEntity function, String message, TypeMask typeMask,
      SourceInformation sourceInformation) {
    HInstruction errorMessage = graph.addConstantString(message, closedWorld);
    // TODO(sra): Associate source info from [node].
    _pushStaticInvocation(function, [errorMessage], typeMask);
  }

  void generateTypeError(String message, SourceInformation sourceInformation) {
    generateError(
        _commonElements.throwTypeError,
        message,
        _typeInferenceMap.getReturnTypeOf(_commonElements.throwTypeError),
        sourceInformation);
  }

  void generateUnsupportedError(
      String message, SourceInformation sourceInformation) {
    generateError(
        _commonElements.throwUnsupportedError,
        message,
        _typeInferenceMap
            .getReturnTypeOf(_commonElements.throwUnsupportedError),
        sourceInformation);
  }

  @override
  void visitAssertStatement(ir.AssertStatement node) {
    if (!options.enableUserAssertions) return;
    if (node.message == null) {
      node.condition.accept(this);
      _pushStaticInvocation(_commonElements.assertHelper, <HInstruction>[pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertHelper));
      pop();
      return;
    }

    // if (assertTest(condition)) assertThrow(message);
    void buildCondition() {
      node.condition.accept(this);
      _pushStaticInvocation(_commonElements.assertTest, <HInstruction>[pop()],
          _typeInferenceMap.getReturnTypeOf(_commonElements.assertTest));
    }

    void fail() {
      node.message.accept(this);
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
  void visitBreakStatement(ir.BreakStatement node) {
    assert(!isAborted());
    handleInTryStatement();
    JumpTarget target = localsMap.getJumpTargetForBreak(node);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildGoto(node);
    if (localsMap.generateContinueForBreak(node)) {
      if (handler.labels.isNotEmpty) {
        handler.generateContinue(sourceInformation, handler.labels.first);
      } else {
        handler.generateContinue(sourceInformation);
      }
    } else {
      if (handler.labels.isNotEmpty) {
        handler.generateBreak(sourceInformation, handler.labels.first);
      } else {
        handler.generateBreak(sourceInformation);
      }
    }
  }

  @override
  void visitLabeledStatement(ir.LabeledStatement node) {
    ir.Statement body = node.body;
    if (JumpVisitor.canBeBreakTarget(body)) {
      // loops and switches handle breaks on their own
      body.accept(this);
      return;
    }
    JumpTarget jumpTarget = localsMap.getJumpTargetForLabel(node);
    if (jumpTarget == null) {
      // The label is not needed.
      body.accept(this);
      return;
    }

    JumpHandler handler = createJumpHandler(node, jumpTarget);

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
  void visitContinueSwitchStatement(ir.ContinueSwitchStatement node) {
    handleInTryStatement();
    JumpTarget target = localsMap.getJumpTargetForContinueSwitch(node);
    assert(target != null);
    JumpHandler handler = jumpTargets[target];
    assert(handler != null);
    assert(target.labels.isNotEmpty);
    handler.generateContinue(
        _sourceInformationBuilder.buildGoto(node), target.labels.first);
  }

  @override
  void visitSwitchStatement(ir.SwitchStatement node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildSwitch(node);
    // The switch case indices must match those computed in
    // [KernelSwitchCaseJumpHandler].
    bool hasContinue = false;
    Map<ir.SwitchCase, int> caseIndex = new Map<ir.SwitchCase, int>();
    int switchIndex = 1;
    bool hasDefault = false;
    for (ir.SwitchCase switchCase in node.cases) {
      if (_isDefaultCase(switchCase)) {
        hasDefault = true;
      }
      if (SwitchContinueAnalysis.containsContinue(switchCase.body)) {
        hasContinue = true;
      }
      caseIndex[switchCase] = switchIndex;
      switchIndex++;
    }

    JumpHandler jumpHandler =
        createJumpHandler(node, localsMap.getJumpTargetForSwitch(node));
    if (!hasContinue) {
      // If the switch statement has no switch cases targeted by continue
      // statements we encode the switch statement directly.
      _buildSimpleSwitchStatement(node, jumpHandler, sourceInformation);
    } else {
      _buildComplexSwitchStatement(
          node, jumpHandler, caseIndex, hasDefault, sourceInformation);
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
  void _buildSimpleSwitchStatement(ir.SwitchStatement switchStatement,
      JumpHandler jumpHandler, SourceInformation sourceInformation) {
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
        buildSwitchCase,
        sourceInformation);
    jumpHandler.close();
  }

  /// Builds a switch statement that can handle arbitrary uses of continue
  /// statements to labeled switch cases.
  void _buildComplexSwitchStatement(
      ir.SwitchStatement switchStatement,
      JumpHandler jumpHandler,
      Map<ir.SwitchCase, int> caseIndex,
      bool hasDefault,
      SourceInformation sourceInformation) {
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
      SourceInformation caseSourceInformation = sourceInformation;
      if (switchCase != null) {
        caseSourceInformation = _sourceInformationBuilder.buildGoto(switchCase);
        // Generate 'target = i; break;' for switch case i.
        int index = caseIndex[switchCase];
        HInstruction value = graph.addConstantInt(index, closedWorld);
        localsHandler.updateLocal(switchTarget, value,
            sourceInformation: caseSourceInformation);
      } else {
        // Generate synthetic default case 'target = null; break;'.
        HInstruction nullValue = graph.addConstantNull(closedWorld);
        localsHandler.updateLocal(switchTarget, nullValue,
            sourceInformation: caseSourceInformation);
      }
      jumpTargets[switchTarget].generateBreak(caseSourceInformation);
    }

    _handleSwitch(
        switchStatement,
        jumpHandler,
        _buildExpression,
        switchCases,
        _getSwitchConstants,
        _isDefaultCase,
        buildSwitchCase,
        sourceInformation);
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
          jumpTargets[switchTarget].generateBreak(sourceInformation);
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
          buildSwitchCase,
          sourceInformation);
    }

    void buildLoop() {
      loopHandler.handleLoop(
          switchStatement,
          localsMap.getCapturedLoopScope(closureDataLookup, switchStatement),
          switchTarget,
          () {},
          buildCondition,
          () {},
          buildSwitch,
          _sourceInformationBuilder.buildLoop(switchStatement));
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
          visitElse: () => {},
          sourceInformation: sourceInformation);
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
      void buildSwitchCase(ir.SwitchCase switchCase),
      SourceInformation sourceInformation) {
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
      if (!isAborted() &&
          // TODO(johnniwinther): Reinsert this if `isReachable` is no longer
          // set to `false` when `_tryInlineMethod` sees an always throwing
          // method.
          //switchCase == switchCases.last &&
          !isDefaultCase(switchCase)) {
        // If there is no default, we will add one later to avoid
        // the critical edge. So we generate a break statement to make
        // sure the last case does not fall through to the default case.
        jumpHandler.generateBreak(sourceInformation);
      }
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
        new HSwitchBlockInformation(expressionInfo, statements,
            jumpHandler.target, jumpHandler.labels, sourceInformation),
        joinBlock);

    jumpHandler.close();
  }

  @override
  void visitConditionalExpression(ir.ConditionalExpression node) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this);
    brancher.handleConditional(() => node.condition.accept(this),
        () => node.then.accept(this), () => node.otherwise.accept(this));
  }

  @override
  void visitLogicalExpression(ir.LogicalExpression node) {
    SsaBranchBuilder brancher = new SsaBranchBuilder(this);
    String operator = node.operator;
    // ir.LogicalExpression claims to allow '??' as an operator but currently
    // that is expanded into a let-tree.
    assert(operator == '&&' || operator == '||');
    _handleLogicalExpression(node.left, () => node.right.accept(this), brancher,
        operator, _sourceInformationBuilder.buildBinary(node));
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
  void _handleLogicalExpression(
      ir.Expression left,
      void visitRight(),
      SsaBranchBuilder brancher,
      String operator,
      SourceInformation sourceInformation) {
    if (left is ir.LogicalExpression && left.operator == operator) {
      ir.Expression innerLeft = left.left;
      ir.Expression middle = left.right;
      _handleLogicalExpression(
          innerLeft,
          () => _handleLogicalExpression(middle, visitRight, brancher, operator,
              _sourceInformationBuilder.buildBinary(middle)),
          brancher,
          operator,
          sourceInformation);
    } else {
      brancher.handleLogicalBinary(
          () => left.accept(this), visitRight, sourceInformation,
          isAnd: operator == '&&');
    }
  }

  @override
  void visitIntLiteral(ir.IntLiteral node) {
    stack.add(graph.addConstantInt(node.value, closedWorld));
  }

  @override
  void visitDoubleLiteral(ir.DoubleLiteral node) {
    stack.add(graph.addConstantDouble(node.value, closedWorld));
  }

  @override
  void visitBoolLiteral(ir.BoolLiteral node) {
    stack.add(graph.addConstantBool(node.value, closedWorld));
  }

  @override
  void visitStringLiteral(ir.StringLiteral node) {
    stack.add(graph.addConstantString(node.value, closedWorld));
  }

  @override
  void visitSymbolLiteral(ir.SymbolLiteral node) {
    stack.add(
        graph.addConstant(_elementMap.getConstantValue(node), closedWorld));
    registry?.registerConstSymbol(node.value);
  }

  @override
  void visitNullLiteral(ir.NullLiteral node) {
    stack.add(graph.addConstantNull(closedWorld));
  }

  /// Set the runtime type information if necessary.
  HInstruction _setListRuntimeTypeInfoIfNeeded(HInstruction object,
      InterfaceType type, SourceInformation sourceInformation) {
    if (!rtiNeed.classNeedsRti(type.element) || type.treatAsRaw) {
      return object;
    }
    List<HInstruction> arguments = <HInstruction>[];
    for (DartType argument in type.typeArguments) {
      arguments.add(typeBuilder.analyzeTypeArgument(argument, sourceElement));
    }
    // TODO(15489): Register at codegen.
    registry?.registerInstantiation(type);
    return callSetRuntimeTypeInfoWithTypeArguments(
        type, arguments, object, sourceInformation);
  }

  @override
  void visitListLiteral(ir.ListLiteral node) {
    HInstruction listInstruction;
    if (node.isConst) {
      listInstruction =
          graph.addConstant(_elementMap.getConstantValue(node), closedWorld);
    } else {
      List<HInstruction> elements = <HInstruction>[];
      for (ir.Expression element in node.expressions) {
        element.accept(this);
        elements.add(pop());
      }
      listInstruction = buildLiteralList(elements);
      add(listInstruction);
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildListLiteral(node);
      InterfaceType type = localsHandler.substInContext(
          _commonElements.listType(_elementMap.getDartType(node.typeArgument)));
      listInstruction = _setListRuntimeTypeInfoIfNeeded(
          listInstruction, type, sourceInformation);
    }

    TypeMask type =
        _typeInferenceMap.typeOfListLiteral(targetElement, node, closedWorld);
    if (!type.containsAll(closedWorld)) {
      listInstruction.instructionType = type;
    }
    stack.add(listInstruction);
  }

  @override
  void visitMapLiteral(ir.MapLiteral node) {
    if (node.isConst) {
      stack.add(
          graph.addConstant(_elementMap.getConstantValue(node), closedWorld));
      return;
    }

    // The map literal constructors take the key-value pairs as a List
    List<HInstruction> constructorArgs = <HInstruction>[];
    for (ir.MapEntry mapEntry in node.entries) {
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
      HLiteralList argList = buildLiteralList(constructorArgs);
      add(argList);
      inputs.add(argList);
    }

    assert(
        constructor is ConstructorEntity && constructor.isFactoryConstructor);

    InterfaceType type = localsHandler.substInContext(_commonElements.mapType(
        _elementMap.getDartType(node.keyType),
        _elementMap.getDartType(node.valueType)));
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
  void visitTypeLiteral(ir.TypeLiteral node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildGet(node);
    ir.DartType type = node.type;
    if (type is ir.InterfaceType ||
        type is ir.DynamicType ||
        type is ir.TypedefType ||
        type is ir.FunctionType) {
      ConstantValue constant = _elementMap.getConstantValue(node);
      stack.add(graph.addConstant(constant, closedWorld,
          sourceInformation: sourceInformation));
      return;
    }
    assert(
        type is ir.TypeParameterType,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE, "Unexpected type literal ${node}."));
    // For other types (e.g. TypeParameterType, function types from expanded
    // typedefs), look-up or construct a reified type representation and convert
    // to a RuntimeType.

    DartType dartType = _elementMap.getDartType(type);
    dartType = localsHandler.substInContext(dartType);
    HInstruction value = typeBuilder.analyzeTypeArgument(
        dartType, sourceElement,
        sourceInformation: sourceInformation);
    _pushStaticInvocation(_commonElements.runtimeTypeToString,
        <HInstruction>[value], commonMasks.stringType,
        sourceInformation: sourceInformation);
    _pushStaticInvocation(
        _commonElements.createRuntimeType,
        <HInstruction>[pop()],
        _typeInferenceMap.getReturnTypeOf(_commonElements.createRuntimeType),
        sourceInformation: sourceInformation);
  }

  @override
  void visitStaticGet(ir.StaticGet node) {
    ir.Member staticTarget = node.target;
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildGet(node);
    if (staticTarget is ir.Procedure &&
        staticTarget.kind == ir.ProcedureKind.Getter) {
      FunctionEntity getter = _elementMap.getMember(staticTarget);
      // Invoke the getter
      _pushStaticInvocation(getter, const <HInstruction>[],
          _typeInferenceMap.getReturnTypeOf(getter),
          sourceInformation: sourceInformation);
    } else if (staticTarget is ir.Field) {
      FieldEntity field = _elementMap.getField(staticTarget);
      ConstantValue value = _elementMap.getFieldConstantValue(field);
      if (value != null) {
        if (!field.isAssignable) {
          stack.add(graph.addConstant(value, closedWorld,
              sourceInformation: sourceInformation));
        } else {
          push(new HStatic(field, _typeInferenceMap.getInferredTypeOf(field),
              sourceInformation));
        }
      } else {
        push(new HLazyStatic(field, _typeInferenceMap.getInferredTypeOf(field),
            sourceInformation));
      }
    } else {
      MemberEntity member = _elementMap.getMember(staticTarget);
      push(new HStatic(member, _typeInferenceMap.getInferredTypeOf(member),
          sourceInformation));
    }
  }

  @override
  void visitStaticSet(ir.StaticSet node) {
    node.value.accept(this);
    HInstruction value = pop();

    ir.Member staticTarget = node.target;
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
  void visitPropertyGet(ir.PropertyGet node) {
    node.receiver.accept(this);
    HInstruction receiver = pop();

    _pushDynamicInvocation(
        node,
        _typeInferenceMap.typeOfGet(node),
        new Selector.getter(_elementMap.getName(node.name)),
        <HInstruction>[receiver],
        _sourceInformationBuilder.buildGet(node));
  }

  @override
  void visitVariableGet(ir.VariableGet node) {
    ir.VariableDeclaration variable = node.variable;
    HInstruction letBinding = letBindings[variable];
    if (letBinding != null) {
      stack.add(letBinding);
      return;
    }

    Local local = localsMap.getLocalVariable(node.variable);
    stack.add(localsHandler.readLocal(local,
        sourceInformation: _sourceInformationBuilder.buildGet(node)));
  }

  @override
  void visitPropertySet(ir.PropertySet node) {
    node.receiver.accept(this);
    HInstruction receiver = pop();
    node.value.accept(this);
    HInstruction value = pop();

    _pushDynamicInvocation(
        node,
        _typeInferenceMap.typeOfSet(node, closedWorld),
        new Selector.setter(_elementMap.getName(node.name)),
        <HInstruction>[receiver, value],
        _sourceInformationBuilder.buildAssignment(node));

    pop();
    stack.add(value);
  }

  @override
  void visitDirectPropertyGet(ir.DirectPropertyGet node) {
    node.receiver.accept(this);
    HInstruction receiver = pop();

    // Fake direct call with a dynamic call.
    // TODO(sra): Implement direct invocations properly.
    _pushDynamicInvocation(
        node,
        _typeInferenceMap.typeOfDirectGet(node),
        new Selector.getter(_elementMap.getMember(node.target).memberName),
        <HInstruction>[receiver],
        _sourceInformationBuilder.buildGet(node));
  }

  @override
  void visitDirectPropertySet(ir.DirectPropertySet node) {
    throw new UnimplementedError('ir.DirectPropertySet');
  }

  @override
  void visitDirectMethodInvocation(ir.DirectMethodInvocation node) {
    throw new UnimplementedError('ir.DirectMethodInvocation');
  }

  @override
  void visitSuperPropertySet(ir.SuperPropertySet node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildAssignment(node);
    node.value.accept(this);
    HInstruction value = pop();

    if (node.interfaceTarget == null) {
      _generateSuperNoSuchMethod(node, _elementMap.getSelector(node).name + "=",
          <HInstruction>[value], sourceInformation);
    } else {
      _buildInvokeSuper(
          _elementMap.getSelector(node),
          _elementMap.getClass(_containingClass(node)),
          _elementMap.getMember(node.interfaceTarget),
          <HInstruction>[value],
          sourceInformation);
    }
    pop();
    stack.add(value);
  }

  @override
  void visitVariableSet(ir.VariableSet node) {
    node.value.accept(this);
    HInstruction value = pop();
    _visitLocalSetter(
        node.variable, value, _sourceInformationBuilder.buildAssignment(node));
  }

  @override
  void visitVariableDeclaration(ir.VariableDeclaration node) {
    Local local = localsMap.getLocalVariable(node);
    if (node.initializer == null) {
      HInstruction initialValue = graph.addConstantNull(closedWorld);
      localsHandler.updateLocal(local, initialValue);
    } else {
      node.initializer.accept(this);
      HInstruction initialValue = pop();

      _visitLocalSetter(
          node, initialValue, _sourceInformationBuilder.buildAssignment(node));

      // Ignore value
      pop();
    }
  }

  void _visitLocalSetter(ir.VariableDeclaration variable, HInstruction value,
      SourceInformation sourceInformation) {
    Local local = localsMap.getLocalVariable(variable);

    // Give the value a name if it doesn't have one already.
    if (value.sourceElement == null) {
      value.sourceElement = local;
    }

    stack.add(value);
    localsHandler.updateLocal(
        local,
        typeBuilder.potentiallyCheckOrTrustType(
            value, _getDartTypeIfValid(variable.type)),
        sourceInformation: sourceInformation);
  }

  @override
  void visitLet(ir.Let node) {
    ir.VariableDeclaration variable = node.variable;
    variable.initializer.accept(this);
    HInstruction initializedValue = pop();
    // TODO(sra): Apply inferred type information.
    letBindings[variable] = initializedValue;
    node.body.accept(this);
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

  /// Build the argument list for JS-interop invocations, which have slightly
  /// different semantics than dart because of JS's null vs undefined and lack
  /// of named arguments. Return null if the arguments could not be correctly
  /// parsed because the user provided code with named parameters in a JS (non
  /// factory) function.
  List<HInstruction> _visitArgumentsForNativeStaticTarget(
      ir.FunctionNode target, ir.Arguments arguments) {
    // Visit arguments in source order, then re-order and fill in defaults.
    var values = _visitPositionalArguments(arguments);

    if (target.namedParameters.isNotEmpty) {
      // Only anonymous factory constructors involving JS interop are allowed to
      // have named parameters. Otherwise, throw an error.
      FunctionEntity function = _elementMap.getMember(target.parent);
      if (function is ConstructorEntity && function.isFactoryConstructor) {
        // TODO(sra): Have a "CompiledArguments" structure to just update with
        // what values we have rather than creating a map and de-populating it.
        var namedValues = <String, HInstruction>{};
        for (ir.NamedExpression argument in arguments.named) {
          argument.value.accept(this);
          namedValues[argument.name] = pop();
        }

        // Visit named arguments in parameter-position order, selecting provided
        // or default value.
        // TODO(sra): Ensure the stored order is canonical so we don't have to
        // sort. The old builder uses CallStructure.makeArgumentList which
        // depends on the old element model.
        var namedParameters = target.namedParameters.toList()
          ..sort((ir.VariableDeclaration a, ir.VariableDeclaration b) =>
              a.name.compareTo(b.name));
        for (ir.VariableDeclaration parameter in namedParameters) {
          HInstruction value = namedValues[parameter.name];
          values.add(value);
          if (value != null) {
            namedValues.remove(parameter.name);
          }
        }
        assert(namedValues.isEmpty);
      } else {
        // Throw an error because JS cannot handle named parameters.
        reporter.reportErrorMessage(
            _elementMap.getSpannable(targetElement, target),
            MessageKind.JS_INTEROP_METHOD_WITH_NAMED_ARGUMENTS,
            {'method': function.name});
        return null;
      }
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

  void _addTypeArguments(List<HInstruction> values, ir.Arguments arguments,
      SourceInformation sourceInformation) {
    // need to translate type to
    for (ir.DartType type in arguments.types) {
      values.add(typeBuilder.analyzeTypeArgument(
          _elementMap.getDartType(type), sourceElement,
          sourceInformation: sourceInformation));
    }
  }

  HInstruction _defaultValueForParameter(ir.VariableDeclaration parameter) {
    ConstantValue constant =
        _elementMap.getConstantValue(parameter.initializer, implicitNull: true);
    assert(constant != null, failedAt(CURRENT_ELEMENT_SPANNABLE));
    return graph.addConstant(constant, closedWorld);
  }

  @override
  void visitStaticInvocation(ir.StaticInvocation node) {
    ir.Procedure target = node.target;
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildCall(node, node);
    if (_elementMap.isForeignLibrary(target.enclosingLibrary)) {
      handleInvokeStaticForeign(node, target);
      return;
    }
    FunctionEntity function = _elementMap.getMember(target);
    TypeMask typeMask = _typeInferenceMap.getReturnTypeOf(function);

    List<HInstruction> arguments = closedWorld.nativeData
            .isJsInteropMember(function)
        ? _visitArgumentsForNativeStaticTarget(target.function, node.arguments)
        : _visitArgumentsForStaticTarget(target.function, node.arguments);

    // Error in the arguments provided. Do not process further.
    if (arguments == null) {
      stack.add(graph.addConstantNull(closedWorld)); // Result expected on stack
      return;
    }

    if (function is ConstructorEntity && function.isFactoryConstructor) {
      handleInvokeFactoryConstructor(
          node, function, typeMask, arguments, sourceInformation);
      return;
    }

    // Static methods currently ignore the type parameters.
    _pushStaticInvocation(function, arguments, typeMask,
        sourceInformation: sourceInformation);
  }

  void handleInvokeFactoryConstructor(
      ir.StaticInvocation invocation,
      ConstructorEntity function,
      TypeMask typeMask,
      List<HInstruction> arguments,
      SourceInformation sourceInformation) {
    if (function.isExternal && function.isFromEnvironmentConstructor) {
      if (invocation.isConst) {
        // Just like all const constructors (see visitConstructorInvocation).
        stack.add(graph.addConstant(
            _elementMap.getConstantValue(invocation), closedWorld,
            sourceInformation: sourceInformation));
      } else {
        generateUnsupportedError(
            '${function.enclosingClass.name}.${function.name} '
            'can only be used as a const constructor',
            sourceInformation);
      }
      return;
    }

    bool isFixedList = false; // Any fixed list, e.g. new List(10),  UInt8List.

    // Recognize `new List()` and `new List(n)`.
    bool isFixedListConstructorCall = false;
    bool isGrowableListConstructorCall = false;
    if (commonElements.isUnnamedListConstructor(function) &&
        invocation.arguments.named.isEmpty) {
      int argumentCount = invocation.arguments.positional.length;
      isFixedListConstructorCall = argumentCount == 1;
      isGrowableListConstructorCall = argumentCount == 0;
      isFixedList = isFixedListConstructorCall;
    }

    InterfaceType instanceType = _elementMap.createInterfaceType(
        invocation.target.enclosingClass, invocation.arguments.types);
    if (_checkAllTypeVariableBounds(
        function, instanceType, sourceInformation)) {
      return;
    }

    TypeMask resultType = typeMask;

    bool isJSArrayTypedConstructor =
        function == commonElements.jsArrayTypedConstructor;

    _inferredTypeOfNewList(ir.StaticInvocation node) {
      MemberEntity element = sourceElement is ConstructorBodyEntity
          ? (sourceElement as ConstructorBodyEntity).constructor
          : sourceElement;
      ;
      return globalInferenceResults
              .resultOfMember(element)
              .typeOfNewList(node) ??
          commonMasks.dynamicType;
    }

    if (isFixedListConstructorCall) {
      assert(arguments.length == 1);
      HInstruction lengthInput = arguments.first;
      if (!lengthInput.isNumber(closedWorld)) {
        HTypeConversion conversion = new HTypeConversion(
            null,
            HTypeConversion.ARGUMENT_TYPE_CHECK,
            commonMasks.numType,
            lengthInput,
            sourceInformation);
        add(conversion);
        lengthInput = conversion;
      }
      js.Template code = js.js.parseForeignJS('new Array(#)');
      var behavior = new native.NativeBehavior();

      var expectedType =
          _elementMap.getDartType(invocation.getStaticType(null));
      behavior.typesInstantiated.add(expectedType);
      behavior.typesReturned.add(expectedType);

      // The allocation can throw only if the given length is a double or
      // outside the unsigned 32 bit range.
      // TODO(sra): Array allocation should be an instruction so that canThrow
      // can depend on a length type discovered in optimization.
      bool canThrow = true;
      if (lengthInput.isUInt32(closedWorld)) {
        canThrow = false;
      }

      var inferredType = _inferredTypeOfNewList(invocation);
      resultType = inferredType.containsAll(closedWorld)
          ? commonMasks.fixedListType
          : inferredType;
      HForeignCode foreign = new HForeignCode(code, resultType, arguments,
          nativeBehavior: behavior,
          throwBehavior: canThrow
              ? native.NativeThrowBehavior.MAY
              : native.NativeThrowBehavior.NEVER)
        ..sourceInformation = sourceInformation;
      push(foreign);
      // TODO(redemption): Global type analysis tracing may have determined that
      // the fixed-length property is never checked. If so, we can avoid marking
      // the array.
      {
        js.Template code = js.js.parseForeignJS(r'#.fixed$length = Array');
        // We set the instruction as [canThrow] to avoid it being dead code.
        // We need a finer grained side effect.
        add(new HForeignCode(code, commonMasks.nullType, [stack.last],
            throwBehavior: native.NativeThrowBehavior.MAY));
      }
    } else if (isGrowableListConstructorCall) {
      push(buildLiteralList(<HInstruction>[]));
      var inferredType = _inferredTypeOfNewList(invocation);
      resultType = inferredType.containsAll(closedWorld)
          ? commonMasks.growableListType
          : inferredType;
      stack.last.instructionType = resultType;
    } else if (isJSArrayTypedConstructor) {
      // TODO(sra): Instead of calling the identity-like factory constructor,
      // simply select the single argument.
      // Factory constructors take type parameters.
      if (closedWorld.rtiNeed.classNeedsRti(function.enclosingClass)) {
        _addTypeArguments(arguments, invocation.arguments, sourceInformation);
      }
      _pushStaticInvocation(function, arguments, typeMask,
          sourceInformation: sourceInformation);
    } else {
      // Factory constructors take type parameters.
      if (closedWorld.rtiNeed.classNeedsRti(function.enclosingClass)) {
        _addTypeArguments(arguments, invocation.arguments, sourceInformation);
      }
      instanceType = localsHandler.substInContext(instanceType);
      addImplicitInstantiation(instanceType);
      _pushStaticInvocation(function, arguments, typeMask,
          sourceInformation: sourceInformation, instanceType: instanceType);
    }

    HInstruction newInstance = stack.last;

    if (isFixedList) {
      // If we inlined a constructor the call-site-specific type from type
      // inference (e.g. a container type) will not be on the node. Store the
      // more specialized type on the allocation.
      newInstance.instructionType = resultType;
      graph.allocatedFixedLists.add(newInstance);
    }

    if (rtiNeed.classNeedsRti(commonElements.listClass) &&
        (isFixedListConstructorCall ||
            isGrowableListConstructorCall ||
            isJSArrayTypedConstructor)) {
      InterfaceType type = _elementMap.createInterfaceType(
          invocation.target.enclosingClass, invocation.arguments.types);
      stack
          .add(_setListRuntimeTypeInfoIfNeeded(pop(), type, sourceInformation));
    }
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
      [int maxPositional, int typeArgumentCount = 0]) {
    String pluralizeArguments(int count, [String adjective = '']) {
      if (count == 0) return 'no ${adjective}arguments';
      if (count == 1) return 'one ${adjective}argument';
      if (count == 2) return 'two ${adjective}arguments';
      return '$count ${adjective}arguments';
    }

    String name() => invocation.target.name.name;

    ir.Arguments arguments = invocation.arguments;
    bool bad = false;
    if (arguments.types.length != typeArgumentCount) {
      String expected = pluralizeArguments(typeArgumentCount, 'type ');
      String actual = pluralizeArguments(arguments.types.length, 'type ');
      reporter.reportErrorMessage(
          _elementMap.getSpannable(targetElement, invocation),
          MessageKind.GENERIC,
          {'text': "Error: '${name()}' takes $expected, not $actual."});
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
    if (_unexpectedForeignArguments(invocation, 2, null, 1)) {
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
    HInstruction code = new HForeignCode(
        nativeBehavior.codeTemplate, ssaType, inputs,
        isStatement: !nativeBehavior.codeTemplate.isExpression,
        effects: nativeBehavior.sideEffects,
        nativeBehavior: nativeBehavior)
      ..sourceInformation = sourceInformation;
    push(code);

    DartType type = _getDartTypeIfValid(invocation.arguments.types.single);
    TypeMask trustedMask = typeBuilder.trustTypeMask(type);

    if (trustedMask != null) {
      // We only allow the type argument to narrow `dynamic`, which probably
      // comes from an unspecified return type in the NativeBehavior.
      if (code.instructionType.containsAll(closedWorld)) {
        // Overwrite the type with the narrower type.
        code.instructionType = trustedMask;
      } else if (trustedMask.containsMask(code.instructionType, closedWorld)) {
        // It is acceptable for the type parameter to be broader than the
        // specified type.
      } else {
        reporter.reportErrorMessage(
            _elementMap.getSpannable(targetElement, invocation),
            MessageKind.GENERIC, {
          'text': 'Type argument too narrow for specified behavior type '
              '(${trustedMask} does not allow '
              'all values in ${code.instructionType})'
        });
      }
    }
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
      MemberEntity target, List<HInstruction> arguments, TypeMask typeMask,
      {SourceInformation sourceInformation, InterfaceType instanceType}) {
    // TODO(redemption): Pass current node if needed.
    if (_tryInlineMethod(target, null, null, arguments, null, sourceInformation,
        instanceType: instanceType)) {
      return;
    }

    var instruction;
    if (closedWorld.nativeData.isJsInteropMember(target)) {
      instruction = _invokeJsInteropFunction(target, arguments);
    } else {
      instruction = new HInvokeStatic(target, arguments, typeMask,
          targetCanThrow: !closedWorld.getCannotThrow(target))
        ..sourceInformation = sourceInformation;

      if (currentImplicitInstantiations.isNotEmpty) {
        instruction.instantiatedTypes =
            new List<InterfaceType>.from(currentImplicitInstantiations);
      }
      instruction.sideEffects = closedWorld.getSideEffectsOfElement(target);
    }
    push(instruction);
  }

  void _pushDynamicInvocation(ir.Node node, TypeMask mask, Selector selector,
      List<HInstruction> arguments, SourceInformation sourceInformation) {
    // We prefer to not inline certain operations on indexables,
    // because the constant folder will handle them better and turn
    // them into simpler instructions that allow further
    // optimizations.
    bool isOptimizableOperationOnIndexable(
        Selector selector, MemberEntity element) {
      bool isLength = selector.isGetter && selector.name == "length";
      if (isLength || selector.isIndex) {
        return closedWorld.isSubtypeOf(
            element.enclosingClass, commonElements.jsIndexableClass);
      } else if (selector.isIndexSet) {
        return closedWorld.isSubtypeOf(
            element.enclosingClass, commonElements.jsMutableIndexableClass);
      } else {
        return false;
      }
    }

    bool isOptimizableOperation(Selector selector, MemberEntity element) {
      ClassEntity cls = element.enclosingClass;
      if (isOptimizableOperationOnIndexable(selector, element)) return true;
      if (!interceptorData.interceptedClasses.contains(cls)) return false;
      if (selector.isOperator) return true;
      if (selector.isSetter) return true;
      if (selector.isIndex) return true;
      if (selector.isIndexSet) return true;
      if (element == commonElements.jsArrayAdd ||
          element == commonElements.jsArrayRemoveLast ||
          element == commonElements.jsStringSplit) {
        return true;
      }
      return false;
    }

    MemberEntity element = closedWorld.locateSingleElement(selector, mask);
    if (element != null &&
        !element.isField &&
        !(element.isGetter && selector.isCall) &&
        !(element.isFunction && selector.isGetter) &&
        !isOptimizableOperation(selector, element)) {
      if (_tryInlineMethod(
          element, selector, mask, arguments, node, sourceInformation)) {
        return;
      }
    }

    HInstruction receiver = arguments.first;
    List<HInstruction> inputs = <HInstruction>[];

    selector ??= _elementMap.getSelector(node);

    bool isIntercepted =
        closedWorld.interceptorData.isInterceptedSelector(selector);

    if (isIntercepted) {
      HInterceptor interceptor = _interceptorFor(receiver, sourceInformation);
      inputs.add(interceptor);
    }
    inputs.addAll(arguments);

    TypeMask type = _typeInferenceMap.selectorTypeOf(selector, mask);
    if (selector.isGetter) {
      push(new HInvokeDynamicGetter(
          selector, mask, null, inputs, type, sourceInformation));
    } else if (selector.isSetter) {
      push(new HInvokeDynamicSetter(
          selector, mask, null, inputs, type, sourceInformation));
    } else {
      push(new HInvokeDynamicMethod(
          selector, mask, inputs, type, sourceInformation, isIntercepted));
    }
  }

  HForeignCode _invokeJsInteropFunction(
      FunctionEntity element, List<HInstruction> arguments) {
    assert(closedWorld.nativeData.isJsInteropMember(element));
    nativeEmitter.nativeMethods.add(element);

    if (element is ConstructorEntity &&
        element.isFactoryConstructor &&
        nativeData.isAnonymousJsInteropClass(element.enclosingClass)) {
      // Factory constructor that is syntactic sugar for creating a JavaScript
      // object literal.
      ConstructorEntity constructor = element;
      ParameterStructure params = constructor.parameterStructure;
      int i = 0;
      int positions = 0;
      var filteredArguments = <HInstruction>[];
      var parameterNameMap = new Map<String, js.Expression>();
      params.namedParameters.forEach((String parameterName) {
        // TODO(jacobr): consider throwing if parameter names do not match
        // names of properties in the class.
        HInstruction argument = arguments[i];
        if (argument != null) {
          filteredArguments.add(argument);
          var jsName = nativeData.computeUnescapedJSInteropName(parameterName);
          parameterNameMap[jsName] = new js.InterpolatedExpression(positions++);
        }
        i++;
      });
      var codeTemplate =
          new js.Template(null, js.objectLiteral(parameterNameMap));

      var nativeBehavior = new native.NativeBehavior()
        ..codeTemplate = codeTemplate;
      if (options.trustJSInteropTypeAnnotations) {
        InterfaceType thisType = _elementMap.elementEnvironment
            .getThisType(constructor.enclosingClass);
        nativeBehavior.typesReturned.add(thisType);
      }
      // TODO(efortuna): Source information.
      return new HForeignCode(
          codeTemplate, commonMasks.dynamicType, filteredArguments,
          nativeBehavior: nativeBehavior);
    }

    var target = new HForeignCode(
        js.js.parseForeignJS("${nativeData.getFixedBackendMethodPath(element)}."
            "${nativeData.getFixedBackendName(element)}"),
        commonMasks.dynamicType,
        <HInstruction>[]);
    add(target);
    // Strip off trailing arguments that were not specified.
    // we could assert that the trailing arguments are all null.
    // TODO(jacobr): rewrite named arguments to an object literal matching
    // the factory constructor case.
    arguments = arguments.where((arg) => arg != null).toList();
    var inputs = <HInstruction>[target]..addAll(arguments);

    var nativeBehavior = new native.NativeBehavior()
      ..sideEffects.setAllSideEffects();

    DartType type = element is ConstructorEntity
        ? _elementMap.elementEnvironment.getThisType(element.enclosingClass)
        : _elementMap.elementEnvironment.getFunctionType(element).returnType;
    // Native behavior effects here are similar to native/behavior.dart.
    // The return type is dynamic if we don't trust js-interop type
    // declarations.
    nativeBehavior.typesReturned.add(
        options.trustJSInteropTypeAnnotations ? type : const DynamicType());

    // The allocation effects include the declared type if it is native (which
    // includes js interop types).
    if (type is InterfaceType && nativeData.isNativeClass(type.element)) {
      nativeBehavior.typesInstantiated.add(type);
    }

    // It also includes any other JS interop type if we don't trust the
    // annotation or if is declared too broad.
    if (!options.trustJSInteropTypeAnnotations ||
        type == commonElements.objectType ||
        type is DynamicType) {
      nativeBehavior.typesInstantiated.add(_elementMap.elementEnvironment
          .getThisType(commonElements.jsJavaScriptObjectClass));
    }

    String template;
    if (element.isGetter) {
      template = '#';
    } else if (element.isSetter) {
      template = '# = #';
    } else {
      var args = new List.filled(arguments.length, '#').join(',');
      template = element.isConstructor ? "new #($args)" : "#($args)";
    }
    js.Template codeTemplate = js.js.parseForeignJS(template);
    nativeBehavior.codeTemplate = codeTemplate;

    // TODO(efortuna): Add source information.
    return new HForeignCode(codeTemplate, commonMasks.dynamicType, inputs,
        nativeBehavior: nativeBehavior);
  }

  @override
  visitFunctionNode(ir.FunctionNode node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildCreate(node);
    ClosureRepresentationInfo closureInfo =
        localsMap.getClosureRepresentationInfo(closureDataLookup, node.parent);
    ClassEntity closureClassEntity = closureInfo.closureClassEntity;

    List<HInstruction> capturedVariables = <HInstruction>[];
    _worldBuilder.forEachInstanceField(closureClassEntity,
        (_, FieldEntity field) {
      capturedVariables
          .add(localsHandler.readLocal(closureInfo.getLocalForField(field)));
    });

    TypeMask type = new TypeMask.nonNullExact(closureClassEntity, closedWorld);
    // TODO(efortuna): Add source information here.
    push(new HCreate(
        closureClassEntity, capturedVariables, type, sourceInformation,
        callMethod: closureInfo.callMethod));
  }

  @override
  visitFunctionDeclaration(ir.FunctionDeclaration declaration) {
    assert(isReachable);
    declaration.function.accept(this);
    Local local = localsMap.getLocalVariable(declaration.variable);
    localsHandler.updateLocal(local, pop());
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression funcExpression) {
    funcExpression.function.accept(this);
  }

  @override
  void visitMethodInvocation(ir.MethodInvocation invocation) {
    invocation.receiver.accept(this);
    HInstruction receiver = pop();
    Selector selector = _elementMap.getSelector(invocation);
    _pushDynamicInvocation(
        invocation,
        _typeInferenceMap.typeOfInvocation(invocation, closedWorld),
        selector,
        <HInstruction>[receiver]..addAll(
            _visitArgumentsForDynamicTarget(selector, invocation.arguments)),
        _sourceInformationBuilder.buildCall(invocation.receiver, invocation));
  }

  HInterceptor _interceptorFor(
      HInstruction intercepted, SourceInformation sourceInformation) {
    HInterceptor interceptor =
        new HInterceptor(intercepted, commonMasks.nonNullType)
          ..sourceInformation = sourceInformation;
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
      List<HInstruction> arguments, SourceInformation sourceInformation) {
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

    var argumentsInstruction = buildLiteralList(arguments);
    add(argumentsInstruction);

    var argumentNames = new List<HInstruction>();
    for (String argumentName in selector.namedArguments) {
      ConstantValue argumentNameConstant =
          constantSystem.createString(argumentName);
      argumentNames.add(graph.addConstant(argumentNameConstant, closedWorld));
    }
    var argumentNamesInstruction = buildLiteralList(argumentNames);
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
        <HInstruction>[pop()], sourceInformation);
  }

  HInstruction _buildInvokeSuper(
      Selector selector,
      ClassEntity containingClass,
      MemberEntity target,
      List<HInstruction> arguments,
      SourceInformation sourceInformation) {
    HInstruction receiver =
        localsHandler.readThis(sourceInformation: sourceInformation);

    List<HInstruction> inputs = <HInstruction>[];
    if (closedWorld.interceptorData.isInterceptedSelector(selector)) {
      inputs.add(_interceptorFor(receiver, sourceInformation));
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
        target, containingClass, selector, inputs, typeMask, sourceInformation,
        isSetter: selector.isSetter || selector.isIndexSet);
    instruction.sideEffects =
        closedWorld.getSideEffectsOfSelector(selector, null);
    push(instruction);
    return instruction;
  }

  @override
  void visitSuperPropertyGet(ir.SuperPropertyGet node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildGet(node);
    if (node.interfaceTarget == null) {
      _generateSuperNoSuchMethod(node, _elementMap.getSelector(node).name,
          const <HInstruction>[], sourceInformation);
    } else {
      _buildInvokeSuper(
          _elementMap.getSelector(node),
          _elementMap.getClass(_containingClass(node)),
          _elementMap.getMember(node.interfaceTarget),
          const <HInstruction>[],
          sourceInformation);
    }
  }

  @override
  void visitSuperMethodInvocation(ir.SuperMethodInvocation node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildCall(node, node);
    if (node.interfaceTarget == null) {
      var selector = _elementMap.getSelector(node);
      var arguments = _visitArgumentsForDynamicTarget(selector, node.arguments);
      _generateSuperNoSuchMethod(
          node, selector.name, arguments, sourceInformation);
      return;
    }
    List<HInstruction> arguments = _visitArgumentsForStaticTarget(
        node.interfaceTarget.function, node.arguments);
    _buildInvokeSuper(
        _elementMap.getSelector(node),
        _elementMap.getClass(_containingClass(node)),
        _elementMap.getMethod(node.interfaceTarget),
        arguments,
        sourceInformation);
  }

  /// In checked mode checks the [type] of [node] to be well-bounded.
  /// Returns `true` if an error can be statically determined.
  ///
  /// We do this at the call site rather that in the constructor body so that we
  /// can perform *static* analysis errors/warnings rather than only dynamic
  /// ones from the type pararameters passed in to the constructors. This also
  /// performs all checks for the instantiated class and all of its supertypes
  /// (extended and inherited) at this single call site because interface type
  /// variable constraints (when applicable) need to be checked but will not
  /// have a constructor body that gets inlined to execute.
  bool _checkAllTypeVariableBounds(ConstructorEntity constructor,
      InterfaceType type, SourceInformation sourceInformation) {
    if (!options.enableTypeAssertions) return false;

    // This map keeps track of what checks we perform as we walk up the
    // inheritance chain so that we don't check the same thing more than once.
    Map<DartType, Set<DartType>> seenChecksMap =
        new Map<DartType, Set<DartType>>();
    bool knownInvalidBounds = false;

    void _addTypeVariableBoundCheck(InterfaceType instance,
        DartType typeArgument, TypeVariableType typeVariable, DartType bound) {
      if (knownInvalidBounds) return;

      int subtypeRelation = types.computeSubtypeRelation(typeArgument, bound);
      if (subtypeRelation == DartTypes.IS_SUBTYPE) return;

      String message = "Can't create an instance of malbounded type '$type': "
          "'${typeArgument}' is not a subtype of bound '${bound}' for "
          "type variable '${typeVariable}' of type "
          "${type == instance
              ? "'${types.getThisType(type.element)}'"
              : "'${types.getThisType(instance.element)}' on the supertype "
                "'${instance}' of '${type}'"
            }.";
      if (subtypeRelation == DartTypes.NOT_SUBTYPE) {
        generateTypeError(message, sourceInformation);
        knownInvalidBounds = true;
        return;
      } else if (subtypeRelation == DartTypes.MAYBE_SUBTYPE) {
        Set<DartType> seenChecks =
            seenChecksMap.putIfAbsent(typeArgument, () => new Set<DartType>());
        if (!seenChecks.contains(bound)) {
          seenChecks.add(bound);
          _assertIsSubtype(typeArgument, bound, message);
        }
      }
    }

    types.checkTypeVariableBounds(type, _addTypeVariableBoundCheck);
    if (knownInvalidBounds) {
      return true;
    }
    for (InterfaceType supertype
        in types.getSupertypes(constructor.enclosingClass)) {
      InterfaceType instance = types.asInstanceOf(type, supertype.element);
      types.checkTypeVariableBounds(instance, _addTypeVariableBoundCheck);
      if (knownInvalidBounds) {
        return true;
      }
    }
    return false;
  }

  void _assertIsSubtype(DartType subtype, DartType supertype, String message) {
    HInstruction subtypeInstruction = typeBuilder.analyzeTypeArgument(
        localsHandler.substInContext(subtype), sourceElement);
    HInstruction supertypeInstruction = typeBuilder.analyzeTypeArgument(
        localsHandler.substInContext(supertype), sourceElement);
    HInstruction messageInstruction =
        graph.addConstantString(message, closedWorld);
    FunctionEntity element = commonElements.assertIsSubtype;
    var inputs = <HInstruction>[
      subtypeInstruction,
      supertypeInstruction,
      messageInstruction
    ];
    HInstruction assertIsSubtype =
        new HInvokeStatic(element, inputs, subtypeInstruction.instructionType);
    registry?.registerTypeVariableBoundsSubtypeCheck(subtype, supertype);
    add(assertIsSubtype);
  }

  @override
  void visitConstructorInvocation(ir.ConstructorInvocation node) {
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildNew(node);
    ir.Constructor target = node.target;
    if (node.isConst) {
      ConstantValue constant = _elementMap.getConstantValue(node);
      stack.add(graph.addConstant(constant, closedWorld,
          sourceInformation: sourceInformation));
      return;
    }

    ConstructorEntity constructor = _elementMap.getConstructor(target);
    ClassEntity cls = constructor.enclosingClass;
    TypeMask typeMask = new TypeMask.nonNullExact(cls, closedWorld);
    InterfaceType instanceType = _elementMap.createInterfaceType(
        target.enclosingClass, node.arguments.types);

    if (_checkAllTypeVariableBounds(
        constructor, instanceType, sourceInformation)) {
      return;
    }

    // TODO(sra): For JS-interop targets, process arguments differently.
    List<HInstruction> arguments = <HInstruction>[];
    if (constructor.isGenerativeConstructor &&
        nativeData.isNativeOrExtendsNative(constructor.enclosingClass) &&
        !nativeData.isJsInteropMember(constructor)) {
      // Native class generative constructors take a pre-constructed object.
      arguments.add(graph.addConstantNull(closedWorld));
    }
    arguments.addAll(
        _visitArgumentsForStaticTarget(target.function, node.arguments));
    if (commonElements.isSymbolConstructor(constructor)) {
      constructor = commonElements.symbolValidatedConstructor;
    }
    if (closedWorld.rtiNeed.classNeedsRti(cls)) {
      _addTypeArguments(arguments, node.arguments, sourceInformation);
    }
    instanceType = localsHandler.substInContext(instanceType);
    addImplicitInstantiation(instanceType);
    _pushStaticInvocation(constructor, arguments, typeMask,
        sourceInformation: sourceInformation, instanceType: instanceType);
    removeImplicitInstantiation(instanceType);
  }

  @override
  void visitIsExpression(ir.IsExpression node) {
    node.operand.accept(this);
    HInstruction expression = pop();
    pushIsTest(node.type, expression, _sourceInformationBuilder.buildIs(node));
  }

  void pushIsTest(ir.DartType type, HInstruction expression,
      SourceInformation sourceInformation) {
    // Note: The call to "unalias" this type like in the original SSA builder is
    // unnecessary in kernel because Kernel has no notion of typedef.
    // TODO(efortuna): Add test for this.

    if (type is ir.InvalidType) {
      // TODO(sra): Make InvalidType carry a message.
      generateTypeError('invalid type', sourceInformation);
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

    if (typeValue is FunctionType) {
      HInstruction representation =
          typeBuilder.analyzeTypeArgument(typeValue, sourceElement);
      List<HInstruction> inputs = <HInstruction>[
        expression,
        representation,
      ];
      _pushStaticInvocation(
          _commonElements.functionTypeTest, inputs, commonMasks.boolType,
          sourceInformation: sourceInformation);
      HInstruction call = pop();
      push(new HIs.compound(typeValue, expression, call, commonMasks.boolType,
          sourceInformation));
      return;
    }

    if (typeValue is TypeVariableType) {
      HInstruction runtimeType =
          typeBuilder.addTypeVariableReference(typeValue, sourceElement);
      _pushStaticInvocation(_commonElements.checkSubtypeOfRuntimeType,
          <HInstruction>[expression, runtimeType], commonMasks.boolType,
          sourceInformation: sourceInformation);
      push(new HIs.variable(typeValue, expression, pop(), commonMasks.boolType,
          sourceInformation));
      return;
    }

    if (RuntimeTypesSubstitutions.hasTypeArguments(typeValue)) {
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
          _commonElements.checkSubtype, inputs, commonMasks.boolType,
          sourceInformation: sourceInformation);
      push(new HIs.compound(typeValue, expression, pop(), commonMasks.boolType,
          sourceInformation));
      return;
    }

    if (backend.hasDirectCheckFor(closedWorld.commonElements, typeValue)) {
      push(new HIs.direct(
          typeValue, expression, commonMasks.boolType, sourceInformation));
      return;
    }
    // The interceptor is not always needed.  It is removed by optimization
    // when the receiver type or tested type permit.
    push(new HIs.raw(
        typeValue,
        expression,
        _interceptorFor(expression, sourceInformation),
        commonMasks.boolType,
        sourceInformation));
    return;
  }

  @override
  void visitThrow(ir.Throw node) {
    _visitThrowExpression(node.expression);
    if (isReachable) {
      SourceInformation sourceInformation =
          _sourceInformationBuilder.buildThrow(node);
      handleInTryStatement();
      push(new HThrowExpression(pop(), sourceInformation));
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

  void visitYieldStatement(ir.YieldStatement node) {
    node.expression.accept(this);
    add(new HYield(
        pop(), node.isYieldStar, _sourceInformationBuilder.buildYield(node)));
  }

  @override
  void visitAwaitExpression(ir.AwaitExpression node) {
    node.operand.accept(this);
    HInstruction awaited = pop();
    // TODO(herhut): Improve this type.
    push(new HAwait(awaited, closedWorld.commonMasks.dynamicType)
      ..sourceInformation = _sourceInformationBuilder.buildAwait(node));
  }

  @override
  void visitRethrow(ir.Rethrow node) {
    HInstruction exception = rethrowableException;
    if (exception == null) {
      exception = graph.addConstantNull(closedWorld);
      reporter.internalError(_elementMap.getSpannable(targetElement, node),
          'rethrowableException should not be null.');
    }
    handleInTryStatement();
    SourceInformation sourceInformation =
        _sourceInformationBuilder.buildThrow(node);
    closeAndGotoExit(new HThrow(exception, sourceInformation, isRethrow: true));
    // ir.Rethrow is an expression so we need to push a value - a constant with
    // no type.
    stack.add(graph.addConstantUnreachable(closedWorld));
  }

  @override
  void visitThisExpression(ir.ThisExpression node) {
    stack.add(localsHandler.readThis(
        sourceInformation: _sourceInformationBuilder.buildGet(node)));
  }

  @override
  void visitNot(ir.Not node) {
    node.operand.accept(this);
    push(new HNot(popBoolified(), commonMasks.boolType)
      ..sourceInformation = _sourceInformationBuilder.buildUnary(node));
  }

  @override
  void visitStringConcatenation(ir.StringConcatenation stringConcat) {
    KernelStringBuilder stringBuilder = new KernelStringBuilder(this);
    stringConcat.accept(stringBuilder);
    stack.add(stringBuilder.result);
  }

  @override
  void visitTryCatch(ir.TryCatch node) {
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(
        this, _sourceInformationBuilder.buildTry(node));
    node.body.accept(this);
    tryBuilder
      ..closeTryBody()
      ..buildCatch(node)
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
  void visitTryFinally(ir.TryFinally node) {
    TryCatchFinallyBuilder tryBuilder = new TryCatchFinallyBuilder(
        this, _sourceInformationBuilder.buildTry(node));

    // We do these shenanigans to produce better looking code that doesn't
    // have nested try statements.
    if (node.body is ir.TryCatch) {
      ir.TryCatch tryCatch = node.body;
      tryCatch.body.accept(this);
      tryBuilder
        ..closeTryBody()
        ..buildCatch(tryCatch);
    } else {
      node.body.accept(this);
      tryBuilder.closeTryBody();
    }

    tryBuilder
      ..buildFinallyBlock(() {
        node.finalizer.accept(this);
      })
      ..cleanUp();
  }

  /**
   * Try to inline [element] within the correct context of the builder. The
   * insertion point is the state of the builder.
   */
  bool _tryInlineMethod(
      FunctionEntity function,
      Selector selector,
      TypeMask mask,
      List<HInstruction> providedArguments,
      ir.Node currentNode,
      SourceInformation sourceInformation,
      {InterfaceType instanceType}) {
    // TODO(johnniwinther,sra): Remove this when inlining is more mature.
    if (function.library.canonicalUri.scheme == 'dart') {
      // Temporarily disable inlining of platform libraries.
      return false;
    }
    if (function.isExternal) {
      // Don't inline external methods; these should just fail at runtime.
      return false;
    }

    if (nativeData.isJsInteropMember(function) &&
        !(function is ConstructorEntity && function.isFactoryConstructor)) {
      // We only inline factory JavaScript interop constructors.
      return false;
    }

    if (compiler.elementHasCompileTimeError(function)) return false;

    bool insideLoop = loopDepth > 0 || graph.calledInLoop;

    // Bail out early if the inlining decision is in the cache and we can't
    // inline (no need to check the hard constraints).
    bool cachedCanBeInlined =
        inlineCache.canInline(function, insideLoop: insideLoop);
    if (cachedCanBeInlined == false) return false;

    bool meetsHardConstraints() {
      if (options.disableInlining) return false;

      assert(
          selector != null ||
              function.isStatic ||
              function.isTopLevel ||
              function.isConstructor ||
              function is ConstructorBodyEntity,
          failedAt(function, "Missing selector for inlining of $function."));
      if (selector != null) {
        if (!selector.applies(function)) return false;
        if (mask != null && !mask.canHit(function, selector, closedWorld)) {
          return false;
        }
      }

      if (nativeData.isJsInteropMember(function)) return false;

      // Don't inline operator== methods if the parameter can be null.
      if (function.name == '==') {
        if (function.enclosingClass != commonElements.objectClass &&
            providedArguments[1].canBeNull()) {
          return false;
        }
      }

      // Generative constructors of native classes should not be called directly
      // and have an extra argument that causes problems with inlining.
      if (function is ConstructorEntity &&
          function.isGenerativeConstructor &&
          nativeData.isNativeOrExtendsNative(function.enclosingClass)) {
        return false;
      }

      // A generative constructor body is not seen by global analysis,
      // so we should not query for its type.
      if (function is! ConstructorBodyEntity) {
        if (globalInferenceResults.resultOfMember(function).throwsAlways) {
          // TODO(johnniwinther): It seems wrong to set `isReachable` to `false`
          // since we are _not_ going to inline [function]. This has
          // implications in switch cases where we might need to insert a
          // `break` that was skipped due to `isReachable` being `false`.
          isReachable = false;
          return false;
        }
      }

      return true;
    }

    bool doesNotContainCode() {
      // A function with size 1 does not contain any code.
      return InlineWeeder.canBeInlined(_elementMap, function, 1,
          enableUserAssertions: options.enableUserAssertions);
    }

    bool reductiveHeuristic() {
      // The call is on a path which is executed rarely, so inline only if it
      // does not make the program larger.
      if (_isCalledOnce(function)) {
        return InlineWeeder.canBeInlined(_elementMap, function, null,
            enableUserAssertions: options.enableUserAssertions);
      }
      // TODO(sra): Measure if inlining would 'reduce' the size.  One desirable
      // case we miss by doing nothing is inlining very simple constructors
      // where all fields are initialized with values from the arguments at this
      // call site.  The code is slightly larger (`new Foo(1)` vs `Foo$(1)`) but
      // that usually means the factory constructor is left unused and not
      // emitted.
      // We at least inline bodies that are empty (and thus have a size of 1).
      return doesNotContainCode();
    }

    bool heuristicSayGoodToGo() {
      // Don't inline recursively
      if (_inliningStack.any((entry) => entry.function == function)) {
        return false;
      }

      // TODO(redemption): Do we still need this?
      //if (function.isSynthesized) return true;

      // Don't inline across deferred import to prevent leaking code. The only
      // exception is an empty function (which does not contain code).
      bool hasOnlyNonDeferredImportPaths = backend.outputUnitData
          .hasOnlyNonDeferredImportPaths(compiler.currentElement, function);

      if (!hasOnlyNonDeferredImportPaths) {
        return doesNotContainCode();
      }

      // Do not inline code that is rarely executed unless it reduces size.
      if (_inExpressionOfThrow || _inLazyInitializerExpression) {
        return reductiveHeuristic();
      }

      if (cachedCanBeInlined == true) {
        // We may have forced the inlining of some methods. Therefore check
        // if we can inline this method regardless of size.
        String reason;
        assert(
            (reason = InlineWeeder.cannotBeInlinedReason(
                    _elementMap, function, null,
                    allowLoops: true,
                    enableUserAssertions: options.enableUserAssertions)) ==
                null,
            failedAt(function, "Cannot inline $function: $reason"));
        return true;
      }

      int numParameters = function.parameterStructure.totalParameters;
      int maxInliningNodes;
      if (insideLoop) {
        maxInliningNodes = InlineWeeder.INLINING_NODES_INSIDE_LOOP +
            InlineWeeder.INLINING_NODES_INSIDE_LOOP_ARG_FACTOR * numParameters;
      } else {
        maxInliningNodes = InlineWeeder.INLINING_NODES_OUTSIDE_LOOP +
            InlineWeeder.INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR * numParameters;
      }

      // If a method is called only once, and all the methods in the
      // inlining stack are called only once as well, we know we will
      // save on output size by inlining this method.
      if (_isCalledOnce(function)) {
        maxInliningNodes = null;
      }
      bool canInline = InlineWeeder.canBeInlined(
          _elementMap, function, maxInliningNodes,
          enableUserAssertions: options.enableUserAssertions);
      if (canInline) {
        inlineCache.markAsInlinable(function, insideLoop: insideLoop);
      } else {
        inlineCache.markAsNonInlinable(function, insideLoop: insideLoop);
      }
      return canInline;
    }

    void doInlining() {
      registry
          .registerStaticUse(new StaticUse.inlining(function, instanceType));

      // Add an explicit null check on the receiver before doing the
      // inlining. We use [element] to get the same name in the
      // NoSuchMethodError message as if we had called it.
      if (function.isInstanceMember &&
          function is! ConstructorBodyEntity &&
          (mask == null || mask.isNullable)) {
        add(new HFieldGet(null, providedArguments[0], commonMasks.dynamicType,
            isAssignable: false)
          ..sourceInformation = sourceInformation);
      }
      List<HInstruction> compiledArguments = _completeCallArgumentsList(
          function, selector, providedArguments, currentNode);
      _enterInlinedMethod(function, compiledArguments, instanceType);
      inlinedFrom(function, () {
        if (!isReachable) {
          _emitReturn(graph.addConstantNull(closedWorld), sourceInformation);
        } else {
          _doInline(function);
        }
      });
      _leaveInlinedMethod();
    }

    if (meetsHardConstraints() && heuristicSayGoodToGo()) {
      doInlining();
      _infoReporter?.reportInlined(
          function,
          _inliningStack.isEmpty
              ? targetElement
              : _inliningStack.last.function);
      return true;
    }

    return false;
  }

  /// Returns a complete argument list for a call of [function].
  List<HInstruction> _completeCallArgumentsList(
      FunctionEntity function,
      Selector selector,
      List<HInstruction> providedArguments,
      ir.Node currentNode) {
    assert(providedArguments != null);

    bool isInstanceMember = function.isInstanceMember;
    // For static calls, [providedArguments] is complete, default arguments
    // have been included if necessary, see [makeStaticArgumentList].
    if (!isInstanceMember ||
        currentNode == null || // In erroneous code, currentNode can be null.
        _providedArgumentsKnownToBeComplete(currentNode) ||
        function is ConstructorBodyEntity ||
        selector.isGetter) {
      // For these cases, the provided argument list is known to be complete.
      return providedArguments;
    } else {
      return _completeDynamicCallArgumentsList(
          selector, function, providedArguments);
    }
  }

  /// Returns a complete argument list for a dynamic call of [function]. The
  /// initial argument list [providedArguments], created by
  /// [addDynamicSendArgumentsToList], does not include values for default
  /// arguments used in the call. The reason is that the target function (which
  /// defines the defaults) is not known.
  ///
  /// However, inlining can only be performed when the target function can be
  /// resolved statically. The defaults can therefore be included at this point.
  ///
  /// The [providedArguments] list contains first all positional arguments, then
  /// the provided named arguments (the named arguments that are defined in the
  /// [selector]) in a specific order (see [addDynamicSendArgumentsToList]).
  List<HInstruction> _completeDynamicCallArgumentsList(Selector selector,
      FunctionEntity function, List<HInstruction> providedArguments) {
    assert(selector.applies(function));
    ParameterStructure parameterStructure = function.parameterStructure;
    List<String> selectorArgumentNames =
        selector.callStructure.getOrderedNamedArguments();
    List<HInstruction> compiledArguments = new List<HInstruction>(
        parameterStructure.totalParameters + 1); // Plus one for receiver.

    compiledArguments[0] = providedArguments[0]; // Receiver.
    int index = 1;
    int namedArgumentIndex = 0;
    int firstProvidedNamedArgument;
    _worldBuilder.forEachParameter(function,
        (DartType type, String name, ConstantValue defaultValue) {
      if (index <= parameterStructure.positionalParameters) {
        if (index < providedArguments.length) {
          compiledArguments[index] = providedArguments[index];
        } else {
          assert(defaultValue != null,
              failedAt(function, 'No constant computed for parameter $name'));
          compiledArguments[index] =
              graph.addConstant(defaultValue, closedWorld);
        }
      } else {
        // Example:
        //     void foo(a, {b, d, c})
        //     foo(0, d = 1, b = 2)
        //
        // providedArguments = [0, 2, 1]
        // selectorArgumentNames = [b, d]
        // parameterStructure.namedParameters = [b, c, d]
        //
        // For each parameter name in the signature, if the argument name
        // matches we use the next provided argument, otherwise we get the
        // default.
        firstProvidedNamedArgument ??= index;
        if (namedArgumentIndex < selectorArgumentNames.length &&
            name == selectorArgumentNames[namedArgumentIndex]) {
          // The named argument was provided in the function invocation.
          compiledArguments[index] = providedArguments[
              firstProvidedNamedArgument + namedArgumentIndex++];
        } else {
          assert(defaultValue != null,
              failedAt(function, 'No constant computed for parameter $name'));
          compiledArguments[index] =
              graph.addConstant(defaultValue, closedWorld);
        }
      }
      index++;
    });
    return compiledArguments;
  }

  /// This method is invoked before inlining the body of [function] into this
  /// [SsaGraphBuilder].
  void _enterInlinedMethod(FunctionEntity function,
      List<HInstruction> compiledArguments, InterfaceType instanceType) {
    KernelInliningState state = new KernelInliningState(
        function,
        _returnLocal,
        _returnType,
        stack,
        localsHandler,
        inTryStatement,
        _isCalledOnce(function));
    _inliningStack.add(state);

    // Setting up the state of the (AST) builder is performed even when the
    // inlined function is in IR, because the irInliner uses the [returnElement]
    // of the AST builder.
    _setupStateForInlining(function, compiledArguments, instanceType);
  }

  /// This method sets up the local state of the builder for inlining
  /// [function]. The arguments of the function are inserted into the
  /// [localsHandler].
  ///
  /// When inlining a function, [:return:] statements are not emitted as
  /// [HReturn] instructions. Instead, the value of a synthetic element is
  /// updated in the [localsHandler]. This function creates such an element and
  /// stores it in the [_returnLocal] field.
  void _setupStateForInlining(FunctionEntity function,
      List<HInstruction> compiledArguments, InterfaceType instanceType) {
    localsHandler = new LocalsHandler(
        this,
        function,
        function,
        instanceType ?? _elementMap.getMemberThisType(function),
        nativeData,
        interceptorData);
    localsHandler.scopeInfo = closureDataLookup.getScopeInfo(function);
    _returnLocal = new SyntheticLocal("result", function, function);
    localsHandler.updateLocal(_returnLocal, graph.addConstantNull(closedWorld));

    inTryStatement = false; // TODO(lry): why? Document.

    int argumentIndex = 0;
    if (function.isInstanceMember) {
      localsHandler.updateLocal(localsHandler.scopeInfo.thisLocal,
          compiledArguments[argumentIndex++]);
    }

    forEachOrderedParameter(_globalLocalsMap, _elementMap, function,
        (Local parameter) {
      HInstruction argument = compiledArguments[argumentIndex++];
      localsHandler.updateLocal(parameter, argument);
    });

    ClassEntity enclosing = function.enclosingClass;
    if ((function.isConstructor || function is ConstructorBodyEntity) &&
        rtiNeed.classNeedsRti(enclosing)) {
      InterfaceType thisType =
          _elementMap.elementEnvironment.getThisType(enclosing);
      thisType.typeArguments.forEach((_typeVariable) {
        TypeVariableType typeVariable = _typeVariable;
        HInstruction argument = compiledArguments[argumentIndex++];
        localsHandler.updateLocal(
            localsHandler.getTypeVariableAsLocal(typeVariable), argument);
      });
    }
    assert(argumentIndex == compiledArguments.length);

    _returnType =
        _elementMap.elementEnvironment.getFunctionType(function).returnType;
    stack = <HInstruction>[];

    _insertTraceCall(function);
    _insertCoverageCall(function);
  }

  void _leaveInlinedMethod() {
    HInstruction result = localsHandler.readLocal(_returnLocal);
    KernelInliningState state = _inliningStack.removeLast();
    _restoreState(state);
    stack.add(result);
  }

  void _restoreState(KernelInliningState state) {
    localsHandler = state.oldLocalsHandler;
    _returnLocal = state.oldReturnLocal;
    inTryStatement = state.inTryStatement;
    _returnType = state.oldReturnType;
    assert(stack.isEmpty);
    stack = state.oldStack;
  }

  bool _providedArgumentsKnownToBeComplete(ir.Node currentNode) {
    /* When inlining the iterator methods generated for a [:for-in:] loop, the
     * [currentNode] is the [ForIn] tree. The compiler-generated iterator
     * invocations are known to have fully specified argument lists, no default
     * arguments are used. See invocations of [pushInvokeDynamic] in
     * [visitForIn].
     */
    // TODO(redemption): Is this valid here?
    return currentNode is ir.ForInStatement;
  }

  void _emitReturn(HInstruction value, SourceInformation sourceInformation) {
    if (_inliningStack.isEmpty) {
      closeAndGotoExit(new HReturn(value, sourceInformation));
    } else {
      localsHandler.updateLocal(_returnLocal, value);
    }
  }

  void _doInline(FunctionEntity function) {
    _visitInlinedFunction(function);
  }

  /// Run this builder on the body of the [function] to be inlined.
  void _visitInlinedFunction(FunctionEntity function) {
    typeBuilder.potentiallyCheckInlinedParameterTypes(function);

    MemberDefinition definition = _elementMap.getMemberDefinition(function);
    switch (definition.kind) {
      case MemberKind.constructor:
        buildConstructor(definition.node);
        return;
      case MemberKind.constructorBody:
        ir.Constructor constructor = definition.node;
        constructor.function.body.accept(this);
        return;
      case MemberKind.regular:
        ir.Node node = definition.node;
        if (node is ir.Constructor) {
          node.function.body.accept(this);
          return;
        } else if (node is ir.Procedure) {
          node.function.body.accept(this);
          return;
        }
        break;
      case MemberKind.closureCall:
        ir.Node node = definition.node;
        if (node is ir.FunctionExpression) {
          node.function.body.accept(this);
          return;
        } else if (node is ir.FunctionDeclaration) {
          node.function.body.accept(this);
          return;
        }
        break;
      default:
        break;
    }
    failedAt(function, "Unexpected inlined function: $definition");
  }

  bool get _allInlinedFunctionsCalledOnce {
    return _inliningStack.isEmpty || _inliningStack.last.allFunctionsCalledOnce;
  }

  bool _isFunctionCalledOnce(FunctionEntity element) {
    // ConstructorBodyElements are not in the type inference graph.
    if (element is ConstructorBodyEntity) return false;
    return globalInferenceResults.resultOfMember(element).isCalledOnce;
  }

  bool _isCalledOnce(FunctionEntity element) {
    return _allInlinedFunctionsCalledOnce && _isFunctionCalledOnce(element);
  }

  void _insertTraceCall(FunctionEntity element) {
    if (JavaScriptBackend.TRACE_METHOD == 'console') {
      if (element == commonElements.traceHelper) return;
      n(e) => e == null ? '' : e.name;
      String name = "${n(element.library)}:${n(element.enclosingClass)}."
          "${n(element)}";
      HConstant nameConstant = graph.addConstantString(name, closedWorld);
      add(new HInvokeStatic(commonElements.traceHelper,
          <HInstruction>[nameConstant], commonMasks.dynamicType));
    }
  }

  void _insertCoverageCall(FunctionEntity element) {
    if (JavaScriptBackend.TRACE_METHOD == 'post') {
      if (element == commonElements.traceHelper) return;
      // TODO(sigmund): create a better uuid for elements.
      HConstant idConstant =
          graph.addConstantInt(element.hashCode, closedWorld);
      HConstant nameConstant =
          graph.addConstantString(element.name, closedWorld);
      add(new HInvokeStatic(commonElements.traceHelper,
          <HInstruction>[idConstant, nameConstant], commonMasks.dynamicType));
    }
  }
}

class KernelInliningState {
  final FunctionEntity function;
  final Local oldReturnLocal;
  final DartType oldReturnType;
  final List<HInstruction> oldStack;
  final LocalsHandler oldLocalsHandler;
  final bool inTryStatement;
  final bool allFunctionsCalledOnce;

  KernelInliningState(
      this.function,
      this.oldReturnLocal,
      this.oldReturnType,
      this.oldStack,
      this.oldLocalsHandler,
      this.inTryStatement,
      this.allFunctionsCalledOnce);
}

class InlineWeeder extends ir.Visitor {
  // Invariant: *INSIDE_LOOP* > *OUTSIDE_LOOP*
  static const INLINING_NODES_OUTSIDE_LOOP = 15;
  static const INLINING_NODES_OUTSIDE_LOOP_ARG_FACTOR = 3;
  static const INLINING_NODES_INSIDE_LOOP = 42;
  static const INLINING_NODES_INSIDE_LOOP_ARG_FACTOR = 4;

  static bool canBeInlined(KernelToElementMapForBuilding elementMap,
      FunctionEntity function, int maxInliningNodes,
      {bool allowLoops: false, bool enableUserAssertions: null}) {
    return cannotBeInlinedReason(elementMap, function, maxInliningNodes,
            allowLoops: allowLoops,
            enableUserAssertions: enableUserAssertions) ==
        null;
  }

  static String cannotBeInlinedReason(KernelToElementMapForBuilding elementMap,
      FunctionEntity function, int maxInliningNodes,
      {bool allowLoops: false, bool enableUserAssertions: null}) {
    // TODO(redemption): Implement inlining heuristic.
    InlineWeeder visitor = new InlineWeeder(maxInliningNodes, allowLoops);
    ir.FunctionNode node = getFunctionNode(elementMap, function);
    node.accept(visitor);
    if (function.isConstructor) {
      MemberDefinition definition = elementMap.getMemberDefinition(function);
      ir.Node node = definition.node;
      if (node is ir.Constructor) {
        node.initializers.forEach((n) => n.accept(visitor));
      }
    }
    return visitor.tooDifficultReason;
  }

  final int maxInliningNodes; // `null` for unbounded.
  final bool allowLoops;

  bool seenReturn = false;
  int nodeCount = 0;
  String tooDifficultReason;
  bool get tooDifficult => tooDifficultReason != null;

  InlineWeeder(this.maxInliningNodes, this.allowLoops);

  bool registerNode() {
    if (maxInliningNodes == null) return true;
    if (nodeCount++ > maxInliningNodes) {
      tooDifficultReason = 'too many nodes';
      return false;
    }
    return true;
  }

  defaultNode(ir.Node node) {
    if (tooDifficult) return;
    if (!registerNode()) return;
    if (seenReturn) {
      tooDifficultReason = 'code after return';
      return;
    }
    node.visitChildren(this);
  }

  visitReturnStatement(ir.ReturnStatement node) {
    if (seenReturn) {
      tooDifficultReason = 'code after return';
      return;
    }
    node.visitChildren(this);
    seenReturn = true;
  }

  visitThrow(ir.Throw node) {
    if (seenReturn) {
      tooDifficultReason = 'code after return';
    }
    node.visitChildren(this);
  }

  _handleLoop() {
    // It's actually not difficult to inline a method with a loop, but
    // our measurements show that it's currently better to not inline a
    // method that contains a loop.
    if (!allowLoops) tooDifficultReason = 'loop';
    // TODO(johnniwinther): Shouldn't the loop body have been counted here? It
    // isn't in the AST based inline weeder.
  }

  visitForStatement(ir.ForStatement node) {
    _handleLoop();
  }

  visitForInStatement(ir.ForInStatement node) {
    _handleLoop();
  }

  visitWhileStatement(ir.WhileStatement node) {
    _handleLoop();
  }

  visitDoStatement(ir.DoStatement node) {
    _handleLoop();
  }

  visitTryCatch(ir.TryCatch node) {
    if (tooDifficult) return;
    tooDifficultReason = 'try';
  }

  visitTryFinally(ir.TryFinally node) {
    if (tooDifficult) return;
    tooDifficultReason = 'try';
  }

  visitFunctionExpression(ir.FunctionExpression node) {
    if (!registerNode()) return;
    tooDifficultReason = 'closure';
  }

  visitFunctionDeclaration(ir.FunctionDeclaration node) {
    if (!registerNode()) return;
    tooDifficultReason = 'closure';
  }

  visitFunctionNode(ir.FunctionNode node) {
    if (node.asyncMarker != ir.AsyncMarker.Sync) {
      tooDifficultReason = 'async/await';
      return;
    }
    node.visitChildren(this);
  }
}

/// Class in charge of building try, catch and/or finally blocks. This handles
/// the instructions that need to be output and the dominator calculation of
/// this sequence of code.
class TryCatchFinallyBuilder {
  final KernelSsaGraphBuilder kernelBuilder;
  final SourceInformation trySourceInformation;

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

  TryCatchFinallyBuilder(this.kernelBuilder, this.trySourceInformation) {
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
    exception = new HLocalValue(local, kernelBuilder.commonMasks.nonNullType)
      ..sourceInformation = trySourceInformation;
    kernelBuilder.add(exception);
    HInstruction oldRethrowableException = kernelBuilder.rethrowableException;
    kernelBuilder.rethrowableException = exception;

    kernelBuilder._pushStaticInvocation(
        kernelBuilder._commonElements.exceptionUnwrapper,
        [exception],
        kernelBuilder._typeInferenceMap
            .getReturnTypeOf(kernelBuilder._commonElements.exceptionUnwrapper),
        sourceInformation: trySourceInformation);
    HInvokeStatic unwrappedException = kernelBuilder.pop();
    tryInstruction.exception = exception;
    int catchesIndex = 0;

    void pushCondition(ir.Catch catchBlock) {
      // `guard` is often `dynamic`, which generates `true`.
      kernelBuilder.pushIsTest(catchBlock.guard, unwrappedException,
          kernelBuilder._sourceInformationBuilder.buildCatch(catchBlock));
    }

    void visitThen() {
      ir.Catch catchBlock = tryCatch.catches[catchesIndex];
      catchesIndex++;
      if (catchBlock.exception != null) {
        Local exceptionVariable =
            kernelBuilder.localsMap.getLocalVariable(catchBlock.exception);
        kernelBuilder.localsHandler.updateLocal(
            exceptionVariable, unwrappedException,
            sourceInformation:
                kernelBuilder._sourceInformationBuilder.buildCatch(catchBlock));
      }
      if (catchBlock.stackTrace != null) {
        kernelBuilder._pushStaticInvocation(
            kernelBuilder._commonElements.traceFromException,
            [exception],
            kernelBuilder._typeInferenceMap.getReturnTypeOf(
                kernelBuilder._commonElements.traceFromException));
        HInstruction traceInstruction = kernelBuilder.pop();
        Local traceVariable =
            kernelBuilder.localsMap.getLocalVariable(catchBlock.stackTrace);
        kernelBuilder.localsHandler.updateLocal(traceVariable, traceInstruction,
            sourceInformation:
                kernelBuilder._sourceInformationBuilder.buildCatch(catchBlock));
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
        ir.Catch nextCatch = tryCatch.catches[catchesIndex];
        kernelBuilder.handleIf(
            visitCondition: () {
              pushCondition(nextCatch);
            },
            visitThen: visitThen,
            visitElse: visitElse,
            sourceInformation:
                kernelBuilder._sourceInformationBuilder.buildCatch(nextCatch));
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
        visitElse: visitElse,
        sourceInformation:
            kernelBuilder._sourceInformationBuilder.buildCatch(firstBlock));
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

class KernelTypeBuilder extends TypeBuilder {
  KernelToElementMapForBuilding _elementMap;
  GlobalLocalsMap _globalLocalsMap;

  KernelTypeBuilder(
      GraphBuilder builder, this._elementMap, this._globalLocalsMap)
      : super(builder);

  ClassTypeVariableAccess computeTypeVariableAccess(MemberEntity member) {
    return _elementMap.getClassTypeVariableAccessForMember(member);
  }

  /// In checked mode, generate type tests for the parameters of the inlined
  /// function.
  void potentiallyCheckInlinedParameterTypes(FunctionEntity function) {
    if (!checkOrTrustTypes) return;

    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(function);
    forEachOrderedParameter(_globalLocalsMap, _elementMap, function,
        (Local parameter) {
      HInstruction argument = builder.localsHandler.readLocal(parameter);
      potentiallyCheckOrTrustType(
          argument, localsMap.getLocalType(_elementMap, parameter));
    });
  }
}

class _ErroneousInitializerVisitor extends ir.Visitor<bool> {
  _ErroneousInitializerVisitor();

  // TODO(30809): Use const constructor.
  static bool check(ir.Initializer initializer) =>
      initializer.accept(new _ErroneousInitializerVisitor());

  bool defaultInitializer(ir.Node node) => false;

  bool visitInvalidInitializer(ir.InvalidInitializer node) => true;

  bool visitLocalInitializer(ir.LocalInitializer node) {
    return node.variable.initializer?.accept(this) ?? false;
  }

  // Expressions: Does the expression always throw?
  bool defaultExpression(ir.Expression node) => false;

  bool visitThrow(ir.Throw node) => true;

  // TODO(sra): We might need to match other expressions that always throw but
  // in a subexpression.
}

/// Special [JumpHandler] implementation used to handle continue statements
/// targeting switch cases.
class KernelSwitchCaseJumpHandler extends SwitchCaseJumpHandler {
  KernelSwitchCaseJumpHandler(GraphBuilder builder, JumpTarget target,
      ir.SwitchStatement switchStatement, KernelToLocalsMap localsMap)
      : super(builder, target) {
    // The switch case indices must match those computed in
    // [KernelSsaBuilder.buildSwitchCaseConstants].
    // Switch indices are 1-based so we can bypass the synthetic loop when no
    // cases match simply by branching on the index (which defaults to null).
    // TODO
    int switchIndex = 1;
    for (ir.SwitchCase switchCase in switchStatement.cases) {
      JumpTarget continueTarget =
          localsMap.getJumpTargetForSwitchCase(switchCase);
      if (continueTarget != null) {
        targetIndexMap[continueTarget] = switchIndex;
        assert(builder.jumpTargets[continueTarget] == null);
        builder.jumpTargets[continueTarget] = this;
      }
      switchIndex++;
    }
  }
}
