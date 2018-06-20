// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.gen_bytecode;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/clone.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/external_name.dart' show getExternalName;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/transformations/constants.dart'
    show ConstantEvaluator, ConstantsBackend, EvaluationEnvironment;
import 'package:kernel/type_algebra.dart'
    show Substitution, containsTypeVariable;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:kernel/vm/constants_native_effects.dart'
    show VmConstantsBackend;
import 'package:vm/bytecode/assembler.dart';
import 'package:vm/bytecode/constant_pool.dart';
import 'package:vm/bytecode/dbc.dart';
import 'package:vm/bytecode/exceptions.dart';
import 'package:vm/bytecode/local_vars.dart' show LocalVariables;
import 'package:vm/metadata/bytecode.dart';

/// Flag to toggle generation of bytecode in kernel files.
const bool isKernelBytecodeEnabled = false;

/// Flag to toggle generation of bytecode in platform kernel files.
const bool isKernelBytecodeEnabledForPlatform = isKernelBytecodeEnabled;

const bool isTraceEnabled = false;

void generateBytecode(Component component,
    {bool strongMode: true, bool dropAST: false}) {
  final coreTypes = new CoreTypes(component);
  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
  final hierarchy = new ClassHierarchy(component,
      onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
  final typeEnvironment =
      new TypeEnvironment(coreTypes, hierarchy, strongMode: strongMode);
  final constantsBackend = new VmConstantsBackend(null, coreTypes);
  new BytecodeGenerator(component, coreTypes, hierarchy, typeEnvironment,
          constantsBackend, strongMode)
      .visitComponent(component);
  if (dropAST) {
    new DropAST().visitComponent(component);
  }
}

class BytecodeGenerator extends RecursiveVisitor<Null> {
  final Component component;
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final TypeEnvironment typeEnvironment;
  final ConstantsBackend constantsBackend;
  final bool strongMode;
  final BytecodeMetadataRepository metadata = new BytecodeMetadataRepository();

  Class enclosingClass;
  Member enclosingMember;
  Set<TypeParameter> classTypeParameters;
  Set<TypeParameter> functionTypeParameters;
  List<DartType> instantiatorTypeArguments;
  LocalVariables locals;
  ConstantEvaluator constantEvaluator;
  Map<LabeledStatement, Label> labeledStatements;
  Map<SwitchCase, Label> switchCases;
  Map<TryCatch, TryBlock> tryCatches;
  Map<TryFinally, List<FinallyBlock>> finallyBlocks;
  List<Label> yieldPoints;
  Map<TreeNode, int> contextLevels;
  List<ClosureBytecode> closures;
  ConstantPool cp;
  ConstantEmitter constantEmitter;
  BytecodeAssembler asm;
  List<BytecodeAssembler> savedAssemblers;

  BytecodeGenerator(this.component, this.coreTypes, this.hierarchy,
      this.typeEnvironment, this.constantsBackend, this.strongMode) {
    component.addMetadataRepository(metadata);
  }

  @override
  visitComponent(Component node) => node.visitChildren(this);

  @override
  visitLibrary(Library node) {
    if (node.isExternal) {
      return;
    }
    visitList(node.classes, this);
    visitList(node.procedures, this);
    visitList(node.fields, this);
  }

  @override
  visitClass(Class node) {
    visitList(node.constructors, this);
    visitList(node.procedures, this);
    visitList(node.fields, this);
  }

  @override
  defaultMember(Member node) {
    if (node.isAbstract) {
      return;
    }
    try {
      if (node is Field) {
        if (node.isStatic && node.initializer != null) {
          start(node);
          if (node.isConst) {
            _genPushConstExpr(node.initializer);
          } else {
            node.initializer.accept(this);
          }
          _genReturnTOS();
          end(node);
        }
      } else if ((node is Procedure && !node.isRedirectingFactoryConstructor) ||
          (node is Constructor)) {
        start(node);
        if (node is Constructor) {
          _genConstructorInitializers(node);
        }
        if (node.isExternal) {
          final String nativeName = getExternalName(node);
          if (nativeName == null) {
            return;
          }
          _genNativeCall(nativeName);
        } else {
          node.function?.body?.accept(this);
          // TODO(alexmarkov): figure out when 'return null' should be generated.
          _genPushNull();
        }
        _genReturnTOS();
        end(node);
      }
    } on UnsupportedOperationError catch (e) {
      if (isTraceEnabled) {
        print('Unable to generate bytecode for $node: $e');
      }
    }
  }

  void _genNativeCall(String nativeName) {
    final function = enclosingMember.function;
    assert(function != null);

    if (locals.hasTypeArgsVar) {
      asm.emitPush(locals.typeArgsVarIndexInFrame);
    } else if (enclosingMember is Procedure &&
        (enclosingMember as Procedure).isFactory) {
      // Null type arguments are passed to factory constructors even if class
      // is not generic. TODO(alexmarkov): Clean this up.
      _genPushNull();
    }
    if (locals.hasReceiver) {
      asm.emitPush(locals.getVarIndexInFrame(locals.receiverVar));
    }
    for (var param in function.positionalParameters) {
      asm.emitPush(locals.getVarIndexInFrame(param));
    }
    for (var param in function.namedParameters) {
      asm.emitPush(locals.getVarIndexInFrame(param));
    }

    final nativeEntryCpIndex = cp.add(new ConstantNativeEntry(nativeName));
    asm.emitNativeCall(nativeEntryCpIndex);
  }

  LibraryIndex _libraryIndex;
  LibraryIndex get libraryIndex =>
      _libraryIndex ??= new LibraryIndex.coreLibraries(component);

  Procedure _listFromLiteral;
  Procedure get listFromLiteral => _listFromLiteral ??=
      libraryIndex.getMember('dart:core', 'List', '_fromLiteral');

  Procedure _mapFromLiteral;
  Procedure get mapFromLiteral => _mapFromLiteral ??=
      libraryIndex.getMember('dart:core', 'Map', '_fromLiteral');

  Procedure _interpolateSingle;
  Procedure get interpolateSingle => _interpolateSingle ??=
      libraryIndex.getMember('dart:core', '_StringBase', '_interpolateSingle');

  Procedure _interpolate;
  Procedure get interpolate => _interpolate ??=
      libraryIndex.getMember('dart:core', '_StringBase', '_interpolate');

  Class _closureClass;
  Class get closureClass =>
      _closureClass ??= libraryIndex.getClass('dart:core', '_Closure');

  Procedure _objectInstanceOf;
  Procedure get objectInstanceOf => _objectInstanceOf ??=
      libraryIndex.getMember('dart:core', 'Object', '_instanceOf');

  Procedure _objectAs;
  Procedure get objectAs =>
      _objectAs ??= libraryIndex.getMember('dart:core', 'Object', '_as');

  Field _closureInstantiatorTypeArguments;
  Field get closureInstantiatorTypeArguments =>
      _closureInstantiatorTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_instantiator_type_arguments');

  Field _closureFunctionTypeArguments;
  Field get closureFunctionTypeArguments =>
      _closureFunctionTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_function_type_arguments');

  Field _closureFunction;
  Field get closureFunction => _closureFunction ??=
      libraryIndex.getMember('dart:core', '_Closure', '_function');

  Field _closureContext;
  Field get closureContext => _closureContext ??=
      libraryIndex.getMember('dart:core', '_Closure', '_context');

  Procedure _prependTypeArguments;
  Procedure get prependTypeArguments => _prependTypeArguments ??=
      libraryIndex.getTopLevelMember('dart:_internal', '_prependTypeArguments');

  void _genConstructorInitializers(Constructor node) {
    bool isRedirecting =
        node.initializers.any((init) => init is RedirectingInitializer);
    if (!isRedirecting) {
      for (var field in node.enclosingClass.fields) {
        if (!field.isStatic &&
            field.initializer != null &&
            !node.initializers.any(
                (init) => init is FieldInitializer && init.field == field)) {
          _genFieldInitializer(field, field.initializer);
        }
      }
    }
    visitList(node.initializers, this);
  }

  void _genFieldInitializer(Field field, Expression initializer) {
    if (initializer is NullLiteral) {
      return;
    }

    _genPushReceiver();
    initializer.accept(this);

    final int cpIndex = cp.add(new ConstantFieldOffset(field));
    asm.emitStoreFieldTOS(cpIndex);
  }

  void _genArguments(Expression receiver, Arguments arguments) {
    if (arguments.types.isNotEmpty) {
      _genTypeArguments(arguments.types);
    }
    receiver?.accept(this);
    visitList(arguments.positional, this);
    arguments.named.forEach((NamedExpression ne) => ne.value.accept(this));
  }

  void _genPushNull() {
    final cpIndex = cp.add(const ConstantNull());
    asm.emitPushConstant(cpIndex);
  }

  void _genPushInt(int value) {
    int cpIndex = cp.add(new ConstantInt(value));
    asm.emitPushConstant(cpIndex);
  }

  void _genPushConstExpr(Expression expr) {
    final constant = constantEvaluator.evaluate(expr);
    asm.emitPushConstant(constant.accept(constantEmitter));
  }

  void _genReturnTOS() {
    asm.emitReturnTOS();
  }

  void _genStaticCall(Member target, ConstantArgDesc argDesc, int totalArgCount,
      {bool isGet: false, bool isSet: false}) {
    assert(!isGet || !isSet);
    final argDescIndex = cp.add(argDesc);
    final kind = isGet
        ? InvocationKind.getter
        : (isSet ? InvocationKind.setter : InvocationKind.method);
    final icdataIndex =
        cp.add(new ConstantStaticICData(kind, target, argDescIndex));

    asm.emitPushConstant(icdataIndex);
    asm.emitIndirectStaticCall(totalArgCount, argDescIndex);
  }

  void _genStaticCallWithArgs(Member target, Arguments args,
      {bool hasReceiver: false, bool isFactory: false}) {
    final ConstantArgDesc argDesc = new ConstantArgDesc.fromArguments(args,
        hasReceiver: hasReceiver, isFactory: isFactory);

    int totalArgCount = args.positional.length + args.named.length;
    if (hasReceiver) {
      totalArgCount++;
    }
    if (args.types.isNotEmpty || isFactory) {
      // VM needs type arguments for every invocation of a factory constructor.
      // TODO(alexmarkov): Clean this up.
      totalArgCount++;
    }

    _genStaticCall(target, argDesc, totalArgCount);
  }

  bool hasTypeParameters(List<DartType> typeArgs) {
    final findTypeParams = new FindTypeParametersVisitor();
    return typeArgs.any((t) => t.accept(findTypeParams));
  }

  bool hasInstantiatorTypeArguments(Class c) {
    return c.typeParameters.isNotEmpty ||
        (c.superclass != null && hasInstantiatorTypeArguments(c.superclass));
  }

  void _genTypeArguments(List<DartType> typeArgs, {Class instantiatingClass}) {
    int typeArgsCPIndex() {
      int cpIndex = cp.add(new ConstantTypeArguments(typeArgs));
      if (instantiatingClass != null) {
        cpIndex = cp.add(new ConstantTypeArgumentsForInstanceAllocation(
            instantiatingClass, cpIndex));
      }
      return cpIndex;
    }

    if (typeArgs.isEmpty || !hasTypeParameters(typeArgs)) {
      asm.emitPushConstant(typeArgsCPIndex());
    } else {
      if (_canReuseInstantiatorTypeArguments(typeArgs, instantiatingClass)) {
        _genPushInstantiatorTypeArguments();
      } else {
        _genPushInstantiatorAndFunctionTypeArguments(typeArgs);
        asm.emitInstantiateTypeArgumentsTOS(1, typeArgsCPIndex());
      }
    }
  }

  void _genPushInstantiatorAndFunctionTypeArguments(List<DartType> types) {
    if (classTypeParameters != null &&
        types.any((t) => containsTypeVariable(t, classTypeParameters))) {
      assert(instantiatorTypeArguments != null);
      _genPushInstantiatorTypeArguments();
    } else {
      _genPushNull();
    }
    if (functionTypeParameters != null &&
        types.any((t) => containsTypeVariable(t, functionTypeParameters))) {
      _genPushFunctionTypeArguments();
    } else {
      _genPushNull();
    }
  }

  void _genPushInstantiatorTypeArguments() {
    if (instantiatorTypeArguments != null) {
      _genPushReceiver();
      final int cpIndex =
          cp.add(new ConstantTypeArgumentsFieldOffset(enclosingClass));
      asm.emitLoadFieldTOS(cpIndex);
    } else {
      _genPushNull();
    }
  }

  List<DartType> _flattenInstantiatorTypeArguments(
      Class instantiatedClass, List<DartType> typeArgs) {
    assert(typeArgs.length == instantiatedClass.typeParameters.length);

    List<DartType> flatTypeArgs;
    final supertype = instantiatedClass.supertype;
    if (supertype == null) {
      flatTypeArgs = <DartType>[];
    } else {
      final substitution =
          Substitution.fromPairs(instantiatedClass.typeParameters, typeArgs);
      flatTypeArgs = _flattenInstantiatorTypeArguments(supertype.classNode,
          substitution.substituteSupertype(supertype).typeArguments);
    }
    flatTypeArgs.addAll(typeArgs);
    return flatTypeArgs;
  }

  bool _canReuseInstantiatorTypeArguments(
      List<DartType> typeArgs, Class instantiatingClass) {
    if (instantiatorTypeArguments == null) {
      return false;
    }

    if (instantiatingClass != null) {
      typeArgs =
          _flattenInstantiatorTypeArguments(instantiatingClass, typeArgs);
    }

    if (typeArgs.length > instantiatorTypeArguments.length) {
      return false;
    }

    for (int i = 0; i < typeArgs.length; ++i) {
      if (typeArgs[i] != instantiatorTypeArguments[i]) {
        return false;
      }
    }

    return true;
  }

  void _genPushFunctionTypeArguments() {
    if (locals.hasTypeArgsVar) {
      asm.emitPush(locals.typeArgsVarIndexInFrame);
    } else {
      _genPushNull();
    }
  }

  void _genPushContextForVariable(VariableDeclaration variable,
      {int currentContextLevel}) {
    currentContextLevel ??= locals.currentContextLevel;
    int depth = currentContextLevel - locals.getContextLevelOfVar(variable);
    assert(depth >= 0);

    asm.emitPush(locals.contextVarIndexInFrame);
    if (depth > 0) {
      int cpIndex = cp.add(new ConstantContextOffset.parent());
      for (; depth > 0; --depth) {
        asm.emitLoadFieldTOS(cpIndex);
      }
    }
  }

  void _genPushContextIfCaptured(VariableDeclaration variable) {
    if (locals.isCaptured(variable)) {
      _genPushContextForVariable(variable);
    }
  }

  void _genLoadVar(VariableDeclaration v, {int currentContextLevel}) {
    if (locals.isCaptured(v)) {
      _genPushContextForVariable(v, currentContextLevel: currentContextLevel);
      final int cpIndex = cp.add(
          new ConstantContextOffset.variable(locals.getVarIndexInContext(v)));
      asm.emitLoadFieldTOS(cpIndex);
    } else {
      asm.emitPush(locals.getVarIndexInFrame(v));
    }
  }

  void _genPushReceiver() {
    // TODO(alexmarkov): generate more efficient access to receiver
    // even if it is captured.
    _genLoadVar(locals.receiverVar);
  }

  // Stores value into variable.
  // If variable is captured, context should be pushed before value.
  void _genStoreVar(VariableDeclaration variable) {
    if (locals.isCaptured(variable)) {
      final int cpIndex = cp.add(new ConstantContextOffset.variable(
          locals.getVarIndexInContext(variable)));
      asm.emitStoreFieldTOS(cpIndex);
    } else {
      asm.emitPopLocal(locals.getVarIndexInFrame(variable));
    }
  }

  /// Generates bool condition. Returns `true` if condition is negated.
  bool _genCondition(Node condition) {
    bool negated = false;
    if (condition is Not) {
      condition = (condition as Not).operand;
      negated = true;
    }
    condition.accept(this);
    // TODO(alexmarkov): bool check
    return negated;
  }

  void _genJumpIfFalse(bool negated, Label dest) {
    asm.emitPushConstant(cp.add(new ConstantBool(true)));
    if (negated) {
      asm.emitIfEqStrictTOS(); // if ((!condition) == true) ...
    } else {
      asm.emitIfNeStrictTOS(); // if (condition != true) ...
    }
    asm.emitJump(dest); // ... then jump dest
  }

  void _genJumpIfTrue(bool negated, Label dest) {
    _genJumpIfFalse(!negated, dest);
  }

  int _getDefaultParamConstIndex(VariableDeclaration param) {
    if (param.initializer == null) {
      return cp.add(const ConstantNull());
    }
    final constant = constantEvaluator.evaluate(param.initializer);
    return constant.accept(constantEmitter);
  }

  // Duplicates value on top of the stack using temporary variable with
  // given index.
  void _genDupTOS(int tempIndexInFrame) {
    // TODO(alexmarkov): Consider introducing Dup bytecode or keeping track of
    // expression stack depth.
    asm.emitStoreLocal(tempIndexInFrame);
    asm.emitPush(tempIndexInFrame);
  }

  /// Generates is-test for the value at TOS.
  void _genInstanceOf(DartType type) {
    // TODO(alexmarkov): generate _simpleInstanceOf if possible

    if (hasTypeParameters([type])) {
      _genPushInstantiatorAndFunctionTypeArguments([type]);
    } else {
      _genPushNull(); // Instantiator type arguments.
      _genPushNull(); // Function type arguments.
    }
    asm.emitPushConstant(cp.add(new ConstantType(type)));
    final argDescIndex = cp.add(new ConstantArgDesc(4));
    final icdataIndex = cp.add(new ConstantICData(
        InvocationKind.method, objectInstanceOf.name, argDescIndex));
    asm.emitInstanceCall1(4, icdataIndex);
  }

  void start(Member node) {
    enclosingClass = node.enclosingClass;
    enclosingMember = node;
    if (enclosingMember.isInstanceMember || enclosingMember is Constructor) {
      if (enclosingClass.typeParameters.isNotEmpty) {
        classTypeParameters =
            new Set<TypeParameter>.from(enclosingClass.typeParameters);
      }
      if (hasInstantiatorTypeArguments(enclosingClass)) {
        final typeParameters = enclosingClass.typeParameters
            .map((p) => new TypeParameterType(p))
            .toList();
        instantiatorTypeArguments =
            _flattenInstantiatorTypeArguments(enclosingClass, typeParameters);
      }
    }
    if (enclosingMember.function != null &&
        enclosingMember.function.typeParameters.isNotEmpty) {
      functionTypeParameters =
          new Set<TypeParameter>.from(enclosingMember.function.typeParameters);
    }
    locals = new LocalVariables(node);
    // TODO(alexmarkov): improve caching in ConstantEvaluator and reuse it
    constantEvaluator = new ConstantEvaluator(constantsBackend, typeEnvironment,
        coreTypes, strongMode, /* enableAsserts = */ true)
      ..env = new EvaluationEnvironment();
    labeledStatements = <LabeledStatement, Label>{};
    switchCases = <SwitchCase, Label>{};
    tryCatches = <TryCatch, TryBlock>{};
    finallyBlocks = <TryFinally, List<FinallyBlock>>{};
    yieldPoints = null; // Initialized when entering sync-yielding closure.
    contextLevels = <TreeNode, int>{};
    closures = <ClosureBytecode>[];
    cp = new ConstantPool();
    constantEmitter = new ConstantEmitter(cp);
    asm = new BytecodeAssembler();
    savedAssemblers = <BytecodeAssembler>[];

    locals.enterScope(node);
    assert(!locals.isSyncYieldingFrame);

    _genPrologue(node, node.function);
    _setupInitialContext(node.function);
    _genEqualsOperatorNullHandling(node);
  }

  // Generate additional code for 'operator ==' to handle nulls.
  void _genEqualsOperatorNullHandling(Member member) {
    if (member.name.name != '==' ||
        locals.numParameters != 2 ||
        member.enclosingClass == coreTypes.objectClass) {
      return;
    }

    Label done = new Label();

    _genLoadVar(member.function.positionalParameters[0]);
    _genPushNull();
    asm.emitIfNeStrictTOS();
    asm.emitJump(done);

    asm.emitPushConstant(cp.add(new ConstantBool(false)));
    _genReturnTOS();

    asm.bind(done);
  }

  void end(Member node) {
    metadata.mapping[node] =
        new BytecodeMetadata(cp, asm.bytecode, asm.exceptionsTable, closures);

    if (isTraceEnabled) {
      print('Generated bytecode for $node');
    }

    enclosingClass = null;
    enclosingMember = null;
    classTypeParameters = null;
    functionTypeParameters = null;
    instantiatorTypeArguments = null;
    locals = null;
    constantEvaluator = null;
    labeledStatements = null;
    switchCases = null;
    tryCatches = null;
    finallyBlocks = null;
    yieldPoints = null;
    contextLevels = null;
    closures = null;
    cp = null;
    constantEmitter = null;
    asm = null;
    savedAssemblers = null;
  }

  void _genPrologue(Node node, FunctionNode function) {
    if (locals.hasOptionalParameters) {
      final int numOptionalPositional = function.positionalParameters.length -
          function.requiredParameterCount;
      final int numOptionalNamed = function.namedParameters.length;
      final int numFixed =
          locals.numParameters - (numOptionalPositional + numOptionalNamed);

      asm.emitEntryOptional(numFixed, numOptionalPositional, numOptionalNamed);

      if (numOptionalPositional != 0) {
        assert(numOptionalNamed == 0);
        for (int i = 0; i < numOptionalPositional; i++) {
          final param = function
              .positionalParameters[function.requiredParameterCount + i];
          asm.emitLoadConstant(numFixed + i, _getDefaultParamConstIndex(param));
        }
      } else {
        assert(numOptionalNamed != 0);
        for (int i = 0; i < numOptionalNamed; i++) {
          final param = function.namedParameters[i];
          asm.emitLoadConstant(
              numFixed + i, cp.add(new ConstantString(param.name)));
          asm.emitLoadConstant(numFixed + i, _getDefaultParamConstIndex(param));
        }
      }

      asm.emitFrame(locals.frameSize - locals.numParameters);
    } else {
      asm.emitEntry(locals.frameSize);
    }
    asm.emitCheckStack();

    final bool isClosure =
        node is FunctionDeclaration || node is FunctionExpression;

    if (isClosure) {
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.add(new ConstantFieldOffset(closureContext)));
      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }

    if (locals.hasTypeArgsVar && isClosure) {
      if (function.typeParameters.isNotEmpty) {
        final int numParentTypeArgs = locals.numParentTypeArguments;
        asm.emitPush(locals.typeArgsVarIndexInFrame);
        asm.emitPush(locals.closureVarIndexInFrame);
        asm.emitLoadFieldTOS(
            cp.add(new ConstantFieldOffset(closureFunctionTypeArguments)));
        _genPushInt(numParentTypeArgs);
        _genPushInt(numParentTypeArgs + function.typeParameters.length);
        _genStaticCall(prependTypeArguments, new ConstantArgDesc(4), 4);
        asm.emitPopLocal(locals.typeArgsVarIndexInFrame);
      } else {
        asm.emitPush(locals.closureVarIndexInFrame);
        asm.emitLoadFieldTOS(
            cp.add(new ConstantFieldOffset(closureFunctionTypeArguments)));
        asm.emitPopLocal(locals.typeArgsVarIndexInFrame);
      }
    }

    if (isClosure || (node is Procedure && node.isInstanceMember)) {
      _checkArguments(function);
    }
  }

  void _setupInitialContext(FunctionNode function) {
    _allocateContextIfNeeded();

    if (locals.hasCapturedParameters) {
      // Copy captured parameters to their respective locations in the context.
      if (locals.hasReceiver) {
        _copyParamIfCaptured(locals.receiverVar);
      }
      function.positionalParameters.forEach(_copyParamIfCaptured);
      function.namedParameters.forEach(_copyParamIfCaptured);
    }
  }

  void _copyParamIfCaptured(VariableDeclaration variable) {
    if (locals.isCaptured(variable)) {
      _genPushContextForVariable(variable);
      asm.emitPush(locals.getOriginalParamSlotIndex(variable));
      _genStoreVar(variable);
      // TODO(alexmarkov): Do we need to store null at the original parameter
      // location?
    }
  }

  void _checkArguments(FunctionNode function) {
    for (var typeParam in function.typeParameters) {
      if (!typeEnvironment.isTop(typeParam.bound)) {
        final DartType type = new TypeParameterType(typeParam);
        _genPushInstantiatorAndFunctionTypeArguments([type, typeParam.bound]);
        asm.emitPushConstant(cp.add(new ConstantType(type)));
        asm.emitPushConstant(cp.add(new ConstantType(typeParam.bound)));
        asm.emitPushConstant(cp.add(new ConstantString(typeParam.name)));
        asm.emitAssertSubtype();
      }
    }
    function.positionalParameters.forEach(_genArgumentTypeCheck);
    function.namedParameters.forEach(_genArgumentTypeCheck);
  }

  void _genArgumentTypeCheck(VariableDeclaration variable) {
    if (typeEnvironment.isTop(variable.type)) {
      return;
    }
    if (locals.isCaptured(variable)) {
      asm.emitPush(locals.getOriginalParamSlotIndex(variable));
    } else {
      asm.emitPush(locals.getVarIndexInFrame(variable));
    }
    _genAssertAssignable(variable.type, name: variable.name);
    asm.emitDrop1();
  }

  void _genAssertAssignable(DartType type, {String name = ''}) {
    assert(!typeEnvironment.isTop(type));
    _genPushInstantiatorAndFunctionTypeArguments([type]);
    asm.emitPushConstant(cp.add(new ConstantType(type)));
    asm.emitPushConstant(cp.add(new ConstantString(name)));
    bool isIntOk = typeEnvironment.isSubtypeOf(typeEnvironment.intType, type);
    int subtypeTestCacheCpIndex = cp.add(new ConstantSubtypeTestCache());
    asm.emitAssertAssignable(isIntOk ? 1 : 0, subtypeTestCacheCpIndex);
  }

  void _pushAssemblerState() {
    savedAssemblers.add(asm);
    asm = new BytecodeAssembler();
  }

  void _popAssemblerState() {
    asm = savedAssemblers.removeLast();
  }

  int _genClosureBytecode(TreeNode node, String name, FunctionNode function) {
    _pushAssemblerState();

    locals.enterScope(node);

    if (function.typeParameters.isNotEmpty) {
      functionTypeParameters ??= new Set<TypeParameter>();
      functionTypeParameters.addAll(function.typeParameters);
    }

    List<Label> savedYieldPoints = yieldPoints;
    yieldPoints = locals.isSyncYieldingFrame ? <Label>[] : null;

    final int closureFunctionIndex = cp.add(new ConstantClosureFunction(
        name, new CloneWithoutBody().visitFunctionNode(function)));

    _genPrologue(node, function);

    Label continuationSwitchLabel;
    int continuationSwitchVar;
    if (locals.isSyncYieldingFrame) {
      continuationSwitchLabel = new Label();
      continuationSwitchVar = locals.scratchVarIndexInFrame;
      _genSyncYieldingPrologue(
          function, continuationSwitchLabel, continuationSwitchVar);
    }

    _setupInitialContext(function);

    // TODO(alexmarkov): support --causal_async_stacks.

    function.body.accept(this);

    // TODO(alexmarkov): figure out when 'return null' should be generated.
    _genPushNull();
    _genReturnTOS();

    if (locals.isSyncYieldingFrame) {
      _genSyncYieldingEpilogue(
          function, continuationSwitchLabel, continuationSwitchVar);
    }

    cp.add(new ConstantEndClosureFunctionScope());

    if (function.typeParameters.isNotEmpty) {
      functionTypeParameters.removeAll(function.typeParameters);
    }

    locals.leaveScope();

    closures.add(new ClosureBytecode(
        closureFunctionIndex, asm.bytecode, asm.exceptionsTable));

    _popAssemblerState();
    yieldPoints = savedYieldPoints;

    return closureFunctionIndex;
  }

  void _genSyncYieldingPrologue(FunctionNode function, Label continuationLabel,
      int switchVarIndexInFrame) {
    // switch_var = :await_jump_var
    _genLoadVar(locals.awaitJumpVar);
    asm.emitStoreLocal(switchVarIndexInFrame);

    // if (switch_var != 0) goto continuationLabel
    _genPushInt(0);
    asm.emitIfNeStrictNumTOS();
    asm.emitJump(continuationLabel);

    // Proceed to normal entry.
  }

  void _genSyncYieldingEpilogue(FunctionNode function, Label continuationLabel,
      int switchVarIndexInFrame) {
    asm.bind(continuationLabel);

    if (yieldPoints.isEmpty) {
      asm.emitTrap();
      return;
    }

    // context = :await_ctx_var
    _genLoadVar(locals.awaitContextVar);
    asm.emitPopLocal(locals.contextVarIndexInFrame);

    for (int i = 0; i < yieldPoints.length; i++) {
      // 0 is reserved for normal entry, yield points are counted from 1.
      final int index = i + 1;

      // if (switch_var == #index) goto yieldPoints[i]
      // There is no need to test switch_var for the last yield statement.
      if (i != yieldPoints.length - 1) {
        asm.emitPush(switchVarIndexInFrame);
        _genPushInt(index);
        asm.emitIfEqStrictNumTOS();
      }

      asm.emitJump(yieldPoints[i]);
    }
  }

  void _genAllocateClosureInstance(
      TreeNode node, int closureFunctionIndex, FunctionNode function) {
    // TODO(alexmarkov): Consider adding a bytecode to allocate closure.

    assert(closureClass.typeParameters.isEmpty);
    asm.emitAllocate(cp.add(new ConstantClass(closureClass)));

    final int temp = locals.tempIndexInFrame(node);
    asm.emitStoreLocal(temp);

    // TODO(alexmarkov): We need to fill _instantiator_type_arguments field
    // only if function signature uses instantiator type arguments.
    asm.emitPush(temp);
    _genPushInstantiatorTypeArguments();
    asm.emitStoreFieldTOS(
        cp.add(new ConstantFieldOffset(closureInstantiatorTypeArguments)));

    asm.emitPush(temp);
    _genPushFunctionTypeArguments();
    asm.emitStoreFieldTOS(
        cp.add(new ConstantFieldOffset(closureFunctionTypeArguments)));

    // TODO(alexmarkov): How to put Object::empty_type_arguments()
    // to _delayed_type_arguments?

    asm.emitPush(temp);
    asm.emitPushConstant(closureFunctionIndex);
    asm.emitStoreFieldTOS(cp.add(new ConstantFieldOffset(closureFunction)));

    asm.emitPush(temp);
    asm.emitPush(locals.contextVarIndexInFrame);
    asm.emitStoreFieldTOS(cp.add(new ConstantFieldOffset(closureContext)));
  }

  void _genClosure(TreeNode node, String name, FunctionNode function) {
    final int closureFunctionIndex = _genClosureBytecode(node, name, function);
    _genAllocateClosureInstance(node, closureFunctionIndex, function);
  }

  void _allocateContextIfNeeded() {
    final int contextSize = locals.currentContextSize;
    if (contextSize > 0) {
      asm.emitAllocateContext(contextSize);

      _genDupTOS(locals.scratchVarIndexInFrame);
      asm.emitPush(locals.contextVarIndexInFrame);
      asm.emitStoreFieldTOS(cp.add(new ConstantContextOffset.parent()));

      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }
  }

  void _enterScope(TreeNode node) {
    locals.enterScope(node);
    _allocateContextIfNeeded();
  }

  void _leaveScope() {
    if (locals.currentContextSize > 0) {
      _genUnwindContext(locals.currentContextLevel - 1);
    }
    locals.leaveScope();
  }

  void _genUnwindContext(int targetContextLevel) {
    int currentContextLevel = locals.currentContextLevel;
    assert(currentContextLevel >= targetContextLevel);
    while (currentContextLevel > targetContextLevel) {
      asm.emitPush(locals.contextVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.add(new ConstantContextOffset.parent()));
      asm.emitPopLocal(locals.contextVarIndexInFrame);
      --currentContextLevel;
    }
  }

  /// Returns the list of try-finally blocks between [from] and [to],
  /// ordered from inner to outer. If [to] is null, returns all enclosing
  /// try-finally blocks up to the function boundary.
  List<TryFinally> _getEnclosingTryFinallyBlocks(TreeNode from, TreeNode to) {
    List<TryFinally> blocks = <TryFinally>[];
    TreeNode node = from;
    for (;;) {
      if (node == to) {
        return blocks;
      }
      if (node == null || node is FunctionNode || node is Member) {
        if (to == null) {
          return blocks;
        } else {
          throw 'Unable to find node $to up from $from';
        }
      }
      // Inspect parent as we only need try-finally blocks enclosing [node]
      // in the body, and not in the finally-block.
      final parent = node.parent;
      if (parent is TryFinally && parent.body == node) {
        blocks.add(parent);
      }
      node = parent;
    }
  }

  /// Generates non-local transfer from inner node [from] into the outer
  /// node, executing finally blocks on the way out. [to] can be null,
  /// in such case all enclosing finally blocks are executed.
  /// [continuation] is invoked to generate control transfer code following
  /// the last finally block.
  void _generateNonLocalControlTransfer(
      TreeNode from, TreeNode to, GenerateContinuation continuation) {
    List<TryFinally> tryFinallyBlocks = _getEnclosingTryFinallyBlocks(from, to);

    // Add finally blocks to all try-finally from outer to inner.
    // The outermost finally block should generate continuation, each inner
    // finally block should proceed to a corresponding outer block.
    for (var tryFinally in tryFinallyBlocks.reversed) {
      final finallyBlock = new FinallyBlock(continuation);
      finallyBlocks[tryFinally].add(finallyBlock);

      final Label nextFinally = finallyBlock.entry;
      continuation = () {
        asm.emitJump(nextFinally);
      };
    }

    // Generate jump to the innermost finally (or to the original
    // continuation if there are no try-finally blocks).
    continuation();
  }

  @override
  defaultTreeNode(Node node) => throw new UnsupportedOperationError(
      'Unsupported node ${node.runtimeType}');

  @override
  visitAsExpression(AsExpression node) {
    node.operand.accept(this);

    final type = node.type;
    if (typeEnvironment.isTop(type)) {
      return;
    }
    if (node.isTypeError) {
      _genAssertAssignable(type);
    } else {
      _genPushInstantiatorAndFunctionTypeArguments([type]);
      asm.emitPushConstant(cp.add(new ConstantType(type)));
      final argDescIndex = cp.add(new ConstantArgDesc(4));
      final icdataIndex = cp.add(new ConstantICData(
          InvocationKind.method, objectAs.name, argDescIndex));
      asm.emitInstanceCall1(4, icdataIndex);
    }
  }

  @override
  visitBoolLiteral(BoolLiteral node) {
    final cpIndex = cp.add(new ConstantBool.fromLiteral(node));
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitIntLiteral(IntLiteral node) {
    final cpIndex = cp.add(new ConstantInt.fromLiteral(node));
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    final cpIndex = cp.add(new ConstantDouble.fromLiteral(node));
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    final Label otherwisePart = new Label();
    final Label done = new Label();
    final int temp = locals.tempIndexInFrame(node);

    final bool negated = _genCondition(node.condition);
    _genJumpIfFalse(negated, otherwisePart);

    node.then.accept(this);
    asm.emitPopLocal(temp);
    asm.emitJump(done);

    asm.bind(otherwisePart);
    node.otherwise.accept(this);
    asm.emitPopLocal(temp);

    asm.bind(done);
    asm.emitPush(temp);
  }

  @override
  visitConstructorInvocation(ConstructorInvocation node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }

    final constructedClass = node.constructedType.classNode;
    final classIndex = cp.add(new ConstantClass(constructedClass));

    if (hasInstantiatorTypeArguments(constructedClass)) {
      _genTypeArguments(node.arguments.types,
          instantiatingClass: constructedClass);
      asm.emitPushConstant(cp.add(new ConstantClass(constructedClass)));
      asm.emitAllocateT();
    } else {
      assert(node.arguments.types.isEmpty);
      asm.emitAllocate(classIndex);
    }

    _genDupTOS(locals.tempIndexInFrame(node));

    // Remove type arguments as they are only passed to instance allocation,
    // and not passed to a constructor.
    final args =
        new Arguments(node.arguments.positional, named: node.arguments.named);
    _genArguments(null, args);
    _genStaticCallWithArgs(node.target, args, hasReceiver: true);
    asm.emitDrop1();
  }

//  @override
//  visitDirectMethodInvocation(DirectMethodInvocation node) {
//  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    node.receiver.accept(this);
    final target = node.target;
    if (target is Field || (target is Procedure && target.isGetter)) {
      _genStaticCall(target, new ConstantArgDesc(1), 1, isGet: true);
    } else {
      throw new UnsupportedOperationError(
          'Unsupported DirectPropertyGet with ${target.runtimeType} $target');
    }
  }

//  @override
//  visitDirectPropertySet(DirectPropertySet node) {
//  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _genClosure(node, '<anonymous closure>', node.function);
  }

//  @override
//  visitInstantiation(Instantiation node) {
//  }
//
//  @override
//  visitInvalidExpression(InvalidExpression node) {
//  }

  @override
  visitIsExpression(IsExpression node) {
    node.operand.accept(this);
    _genInstanceOf(node.type);
  }

  @override
  visitLet(Let node) {
    _enterScope(node);
    node.variable.accept(this);
    node.body.accept(this);
    _leaveScope();
  }

  @override
  visitListLiteral(ListLiteral node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }

    _genTypeArguments([node.typeArgument]);

    _genDupTOS(locals.tempIndexInFrame(node));

    // TODO(alexmarkov): gen more efficient code for empty array
    _genPushInt(node.expressions.length);
    asm.emitCreateArrayTOS();
    final int temp = locals.tempIndexInFrame(node);
    asm.emitStoreLocal(temp);

    for (int i = 0; i < node.expressions.length; i++) {
      asm.emitPush(temp);
      _genPushInt(i);
      node.expressions[i].accept(this);
      asm.emitStoreIndexedTOS();
    }

    _genStaticCall(listFromLiteral, new ConstantArgDesc(1, numTypeArgs: 1), 2);
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    assert(node.operator == '||' || node.operator == '&&');

    final Label shortCircuit = new Label();
    final Label done = new Label();
    final int temp = locals.tempIndexInFrame(node);
    final isOR = (node.operator == '||');

    bool negated = _genCondition(node.left);
    asm.emitPushConstant(cp.add(new ConstantBool(true)));
    if (negated != isOR) {
      // OR: if (condition == true)
      // AND: if ((!condition) == true)
      asm.emitIfEqStrictTOS();
    } else {
      // OR: if ((!condition) != true)
      // AND: if (condition != true)
      asm.emitIfNeStrictTOS();
    }
    asm.emitJump(shortCircuit);

    negated = _genCondition(node.right);
    if (negated) {
      asm.emitBooleanNegateTOS();
    }
    asm.emitPopLocal(temp);
    asm.emitJump(done);

    asm.bind(shortCircuit);
    asm.emitPushConstant(cp.add(new ConstantBool(isOR)));
    asm.emitPopLocal(temp);

    asm.bind(done);
    asm.emitPush(temp);
  }

  @override
  visitMapLiteral(MapLiteral node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }

    _genTypeArguments([node.keyType, node.valueType]);

    if (node.entries.isEmpty) {
      asm.emitPushConstant(
          cp.add(new ConstantList(const DynamicType(), const [])));
    } else {
      _genTypeArguments([const DynamicType()]);
      _genPushInt(node.entries.length * 2);
      asm.emitCreateArrayTOS();

      final int temp = locals.tempIndexInFrame(node);
      asm.emitStoreLocal(temp);

      for (int i = 0; i < node.entries.length; i++) {
        // key
        asm.emitPush(temp);
        _genPushInt(i * 2);
        node.entries[i].key.accept(this);
        asm.emitStoreIndexedTOS();
        // value
        asm.emitPush(temp);
        _genPushInt(i * 2 + 1);
        node.entries[i].value.accept(this);
        asm.emitStoreIndexedTOS();
      }
    }

    _genStaticCall(mapFromLiteral, new ConstantArgDesc(1, numTypeArgs: 1), 2);
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    final args = node.arguments;
    _genArguments(node.receiver, args);
    // TODO(alexmarkov): fast path smi ops
    final argDescIndex =
        cp.add(new ConstantArgDesc.fromArguments(args, hasReceiver: true));
    final icdataIndex = cp.add(
        new ConstantICData(InvocationKind.method, node.name, argDescIndex));
    // TODO(alexmarkov): figure out when generate InstanceCall2 (2 checked arguments).
    asm.emitInstanceCall1(
        args.positional.length + args.named.length + 1, icdataIndex);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    node.receiver.accept(this);
    final argDescIndex = cp.add(new ConstantArgDesc(1));
    final icdataIndex = cp.add(
        new ConstantICData(InvocationKind.getter, node.name, argDescIndex));
    asm.emitInstanceCall1(1, icdataIndex);
  }

  @override
  visitPropertySet(PropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    node.receiver.accept(this);
    node.value.accept(this);
    asm.emitStoreLocal(temp);
    final argDescIndex = cp.add(new ConstantArgDesc(2));
    final icdataIndex = cp.add(
        new ConstantICData(InvocationKind.setter, node.name, argDescIndex));
    asm.emitInstanceCall1(2, icdataIndex);
    asm.emitDrop1();
    asm.emitPush(temp);
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    final args = node.arguments;
    _genArguments(new ThisExpression(), args);
    Member target =
        hierarchy.getDispatchTarget(enclosingClass.superclass, node.name);
    if (target == null) {
      throw new UnsupportedOperationError(
          'Unsupported SuperMethodInvocation without target');
    }
    if (target is Procedure && !target.isGetter) {
      _genStaticCallWithArgs(target, args);
    } else {
      throw new UnsupportedOperationError(
          'Unsupported SuperMethodInvocation with target ${target.runtimeType} $target');
    }
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    _genPushReceiver();
    Member target =
        hierarchy.getDispatchTarget(enclosingClass.superclass, node.name);
    if (target == null) {
      throw new UnsupportedOperationError(
          'Unsupported SuperPropertyGet without target');
    }
    if (target is Field || (target is Procedure && target.isGetter)) {
      _genStaticCall(target, new ConstantArgDesc(1), 1, isGet: true);
    } else {
      throw new UnsupportedOperationError(
          'Unsupported SuperPropertyGet with target ${target.runtimeType} $target');
    }
  }

//  @override
//  visitSuperPropertySet(SuperPropertySet node) {
//  }

  @override
  visitNot(Not node) {
    bool negated = _genCondition(node.operand);
    if (!negated) {
      asm.emitBooleanNegateTOS();
    }
  }

  @override
  visitNullLiteral(NullLiteral node) {
    final cpIndex = cp.add(const ConstantNull());
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitRethrow(Rethrow node) {
    TryCatch tryCatch;
    for (var parent = node.parent;; parent = parent.parent) {
      if (parent is Catch) {
        tryCatch = parent.parent as TryCatch;
        break;
      }
      if (parent == null || parent is FunctionNode) {
        throw 'Unable to find enclosing catch for $node';
      }
    }
    tryCatches[tryCatch].needsStackTrace = true;
    _genRethrow(tryCatch);
  }

  bool _hasTrivialInitializer(Field field) =>
      (field.initializer == null) ||
      (field.initializer is StringLiteral) ||
      (field.initializer is BoolLiteral) ||
      (field.initializer is IntLiteral) ||
      (field.initializer is NullLiteral);

  @override
  visitStaticGet(StaticGet node) {
    final target = node.target;
    if (target is Field) {
      if (target.isConst) {
        _genPushConstExpr(target.initializer);
      } else if (_hasTrivialInitializer(target)) {
        final fieldIndex = cp.add(new ConstantField(target));
        asm.emitPushConstant(
            fieldIndex); // TODO(alexmarkov): do we really need this?
        asm.emitPushStatic(fieldIndex);
      } else {
        _genStaticCall(target, new ConstantArgDesc(0), 0, isGet: true);
      }
    } else if (target is Procedure) {
      if (target.isGetter) {
        _genStaticCall(target, new ConstantArgDesc(0), 0, isGet: true);
      } else {
        final tearOffIndex = cp.add(new ConstantTearOff(target));
        asm.emitPushConstant(tearOffIndex);
      }
    } else {
      throw 'Unexpected target for StaticGet: ${target.runtimeType} $target';
    }
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    final args = node.arguments;
    if (node.target.isFactory && args.types.isEmpty) {
      // VM needs type arguments for every invocation of a factory constructor.
      // TODO(alexmarkov): Clean this up.
      _genPushNull();
    }
    _genArguments(null, args);
    _genStaticCallWithArgs(node.target, args, isFactory: node.target.isFactory);
  }

  @override
  visitStaticSet(StaticSet node) {
    node.value.accept(this);
    _genDupTOS(locals.tempIndexInFrame(node));
    final target = node.target;
    if (target is Field) {
      int cpIndex = cp.add(new ConstantField(target));
      asm.emitStoreStaticTOS(cpIndex);
    } else {
      _genStaticCall(target, new ConstantArgDesc(1), 1, isSet: true);
      asm.emitDrop1();
    }
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    if (node.expressions.length == 1) {
      node.expressions.single.accept(this);
      _genStaticCall(interpolateSingle, new ConstantArgDesc(1), 1);
    } else {
      _genPushNull();
      _genPushInt(node.expressions.length);
      asm.emitCreateArrayTOS();

      final int temp = locals.tempIndexInFrame(node);
      asm.emitStoreLocal(temp);

      for (int i = 0; i < node.expressions.length; i++) {
        asm.emitPush(temp);
        _genPushInt(i);
        node.expressions[i].accept(this);
        asm.emitStoreIndexedTOS();
      }

      _genStaticCall(interpolate, new ConstantArgDesc(1), 1);
    }
  }

  @override
  visitStringLiteral(StringLiteral node) {
    final cpIndex = cp.add(new ConstantString.fromLiteral(node));
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    final cpIndex = cp.add(new ConstantSymbol.fromLiteral(node));
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitThisExpression(ThisExpression node) {
    _genPushReceiver();
  }

  @override
  visitThrow(Throw node) {
    node.expression.accept(this);
    asm.emitThrow(0);
  }

  @override
  visitTypeLiteral(TypeLiteral node) {
    final DartType type = node.type;
    final int typeCPIndex = cp.add(new ConstantType(type));
    if (!hasTypeParameters([type])) {
      asm.emitPushConstant(typeCPIndex);
    } else {
      _genPushInstantiatorAndFunctionTypeArguments([type]);
      asm.emitInstantiateType(typeCPIndex);
    }
  }

  @override
  visitVariableGet(VariableGet node) {
    final v = node.variable;
    if (v.isConst) {
      _genPushConstExpr(v.initializer);
    } else {
      _genLoadVar(v);
    }
  }

  @override
  visitVariableSet(VariableSet node) {
    final v = node.variable;
    if (locals.isCaptured(v)) {
      _genPushContextForVariable(v);

      node.value.accept(this);

      // Preserve value.
      final int temp = locals.tempIndexInFrame(node);
      asm.emitStoreLocal(temp);

      _genStoreVar(v);

      asm.emitPush(temp);
    } else {
      node.value.accept(this);
      asm.emitStoreLocal(locals.getVarIndexInFrame(v));
    }
  }

//  @override
//  visitLoadLibrary(LoadLibrary node) {
//  }
//
//  @override
//  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
//  }
//
//  @override
//  visitVectorCreation(VectorCreation node) {
//  }
//
//  @override
//  visitVectorGet(VectorGet node) {
//  }
//
//  @override
//  visitVectorSet(VectorSet node) {
//  }
//
//  @override
//  visitVectorCopy(VectorCopy node) {
//  }
//
//  @override
//  visitClosureCreation(ClosureCreation node) {
//  }

  @override
  visitAssertStatement(AssertStatement node) {
    // TODO(alexmarkov): support asserts
  }

  @override
  visitBlock(Block node) {
    _enterScope(node);
    visitList(node.statements, this);
    _leaveScope();
  }

  @override
  visitAssertBlock(AssertBlock node) {
    // TODO(alexmarkov): support asserts
  }

  @override
  visitBreakStatement(BreakStatement node) {
    final targetLabel = labeledStatements[node.target] ??
        (throw 'Target label ${node.target} was not registered for break $node');
    final targetContextLevel = contextLevels[node.target];

    _generateNonLocalControlTransfer(node, node.target, () {
      _genUnwindContext(targetContextLevel);
      asm.emitJump(targetLabel);
    });
  }

  @override
  visitContinueSwitchStatement(ContinueSwitchStatement node) {
    final targetLabel = switchCases[node.target] ??
        (throw 'Target label ${node.target} was not registered for continue-switch $node');
    final targetContextLevel = contextLevels[node.target.parent];

    _generateNonLocalControlTransfer(node, node.target.parent, () {
      _genUnwindContext(targetContextLevel);
      asm.emitJump(targetLabel);
    });
  }

  @override
  visitDoStatement(DoStatement node) {
    final Label join = new Label();
    asm.bind(join);

    asm.emitCheckStack();

    node.body.accept(this);

    // TODO(alexmarkov): do we need to break this critical edge in CFG?
    bool negated = _genCondition(node.condition);
    _genJumpIfTrue(negated, join);
  }

  @override
  visitEmptyStatement(EmptyStatement node) {
    // no-op
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    node.expression.accept(this);
    asm.emitDrop1();
  }

  @override
  visitForInStatement(ForInStatement node) {
    node.iterable.accept(this);

    const kIterator = 'iterator'; // Iterable.iterator
    const kMoveNext = 'moveNext'; // Iterator.moveNext
    const kCurrent = 'current'; // Iterator.current

    asm.emitInstanceCall1(
        1,
        cp.add(new ConstantICData(InvocationKind.getter, new Name(kIterator),
            cp.add(new ConstantArgDesc(1)))));

    final iteratorTemp = locals.tempIndexInFrame(node);
    asm.emitPopLocal(iteratorTemp);

    final capturedIteratorVar = locals.capturedIteratorVar(node);
    if (capturedIteratorVar != null) {
      _genPushContextForVariable(capturedIteratorVar);
      asm.emitPush(iteratorTemp);
      _genStoreVar(capturedIteratorVar);
    }

    final Label done = new Label();
    final Label join = new Label();

    asm.bind(join);
    asm.emitCheckStack();

    if (capturedIteratorVar != null) {
      _genLoadVar(capturedIteratorVar);
      asm.emitStoreLocal(iteratorTemp);
    } else {
      asm.emitPush(iteratorTemp);
    }

    asm.emitInstanceCall1(
        1,
        cp.add(new ConstantICData(InvocationKind.method, new Name(kMoveNext),
            cp.add(new ConstantArgDesc(1)))));
    _genJumpIfFalse(/* negated = */ false, done);

    _enterScope(node);

    _genPushContextIfCaptured(node.variable);

    asm.emitPush(iteratorTemp);
    asm.emitInstanceCall1(
        1,
        cp.add(new ConstantICData(InvocationKind.getter, new Name(kCurrent),
            cp.add(new ConstantArgDesc(1)))));

    _genStoreVar(node.variable);

    node.body.accept(this);

    _leaveScope();
    asm.emitJump(join);

    asm.bind(done);
  }

  @override
  visitForStatement(ForStatement node) {
    _enterScope(node);

    visitList(node.variables, this);

    final Label done = new Label();
    final Label join = new Label();
    asm.bind(join);

    asm.emitCheckStack();

    if (node.condition != null) {
      bool negated = _genCondition(node.condition);
      _genJumpIfFalse(negated, done);
    }

    node.body.accept(this);

    if (locals.currentContextSize > 0) {
      asm.emitPush(locals.contextVarIndexInFrame);
      asm.emitCloneContext();
      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }

    for (var update in node.updates) {
      update.accept(this);
      asm.emitDrop1();
    }

    asm.emitJump(join);

    asm.bind(done);
    _leaveScope();
  }

  @override
  visitFunctionDeclaration(FunctionDeclaration node) {
    _genPushContextIfCaptured(node.variable);
    _genClosure(node, node.variable.name, node.function);
    _genStoreVar(node.variable);
  }

  @override
  visitIfStatement(IfStatement node) {
    final Label otherwisePart = new Label();

    final bool negated = _genCondition(node.condition);
    _genJumpIfFalse(negated, otherwisePart);

    node.then.accept(this);

    if (node.otherwise != null) {
      final Label done = new Label();
      asm.emitJump(done);
      asm.bind(otherwisePart);
      node.otherwise.accept(this);
      asm.bind(done);
    } else {
      asm.bind(otherwisePart);
    }
  }

  @override
  visitLabeledStatement(LabeledStatement node) {
    final label = new Label();
    labeledStatements[node] = label;
    contextLevels[node] = locals.currentContextLevel;
    node.body.accept(this);
    asm.bind(label);
    labeledStatements.remove(node);
    contextLevels.remove(node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    if (node.expression != null) {
      node.expression.accept(this);
    } else {
      _genPushNull();
    }

    // TODO(alexmarkov): Do we need to save return value
    // to a variable?
    _generateNonLocalControlTransfer(node, null, () {
      asm.emitReturnTOS();
    });
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    contextLevels[node] = locals.currentContextLevel;

    node.expression.accept(this);

    final int temp = locals.tempIndexInFrame(node);
    asm.emitPopLocal(temp);

    final Label done = new Label();
    final List<Label> caseLabels =
        new List<Label>.generate(node.cases.length, (_) => new Label());
    final equalsArgDesc = cp.add(new ConstantArgDesc(2));

    Label defaultLabel = done;
    for (int i = 0; i < node.cases.length; i++) {
      final SwitchCase switchCase = node.cases[i];
      final Label caseLabel = caseLabels[i];
      switchCases[switchCase] = caseLabel;

      if (switchCase.isDefault) {
        defaultLabel = caseLabel;
      } else {
        for (var expr in switchCase.expressions) {
          asm.emitPush(temp);
          _genPushConstExpr(expr);
          asm.emitInstanceCall2(
              2,
              cp.add(new ConstantICData(
                  InvocationKind.method, new Name('=='), equalsArgDesc)));
          _genJumpIfTrue(/* negated = */ false, caseLabel);
        }
      }
    }

    asm.emitJump(defaultLabel);

    for (int i = 0; i < node.cases.length; i++) {
      final SwitchCase switchCase = node.cases[i];
      final Label caseLabel = caseLabels[i];

      asm.bind(caseLabel);
      switchCase.body.accept(this);

      // Front-end issues a compile-time error if there is a fallthrough
      // between cases. Also, default case should be the last one.
    }

    asm.bind(done);
    node.cases.forEach(switchCases.remove);
    contextLevels.remove(node);
  }

  bool _isTryBlock(TreeNode node) => node is TryCatch || node is TryFinally;

  int _savedContextVar(TreeNode node) {
    assert(_isTryBlock(node));
    assert(locals.capturedSavedContextVar(node) == null);
    return locals.tempIndexInFrame(node, tempIndex: 0);
  }

  // Exception var occupies the same slot as saved context, so context
  // should be restored first, before loading exception.
  int _exceptionVar(TreeNode node) {
    assert(_isTryBlock(node));
    return locals.tempIndexInFrame(node, tempIndex: 0);
  }

  int _stackTraceVar(TreeNode node) {
    assert(_isTryBlock(node));
    return locals.tempIndexInFrame(node, tempIndex: 1);
  }

  _saveContextForTryBlock(TreeNode node) {
    if (!locals.hasContextVar) {
      return;
    }
    final capturedSavedContextVar = locals.capturedSavedContextVar(node);
    if (capturedSavedContextVar != null) {
      assert(locals.isSyncYieldingFrame);
      _genPushContextForVariable(capturedSavedContextVar);
      asm.emitPush(locals.contextVarIndexInFrame);
      _genStoreVar(capturedSavedContextVar);
    } else {
      asm.emitPush(locals.contextVarIndexInFrame);
      asm.emitPopLocal(_savedContextVar(node));
    }
  }

  _restoreContextForTryBlock(TreeNode node) {
    if (!locals.hasContextVar) {
      return;
    }
    final capturedSavedContextVar = locals.capturedSavedContextVar(node);
    if (capturedSavedContextVar != null) {
      // 1. Restore context from closure var.
      // This context has a context level at frame entry.
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.add(new ConstantFieldOffset(closureContext)));
      asm.emitPopLocal(locals.contextVarIndexInFrame);

      // 2. Restore context from captured :saved_try_context_var${depth}.
      assert(locals.isCaptured(capturedSavedContextVar));
      _genLoadVar(capturedSavedContextVar,
          currentContextLevel: locals.contextLevelAtEntry);
    } else {
      asm.emitPush(_savedContextVar(node));
    }
    asm.emitPopLocal(locals.contextVarIndexInFrame);
  }

  /// Start try block
  TryBlock _startTryBlock(TreeNode node) {
    assert(_isTryBlock(node));

    _saveContextForTryBlock(node);

    return asm.exceptionsTable.enterTryBlock(asm.offsetInWords);
  }

  /// End try block and start its handler.
  void _endTryBlock(TreeNode node, TryBlock tryBlock) {
    tryBlock.endPC = asm.offsetInWords;
    tryBlock.handlerPC = asm.offsetInWords;

    // TODO(alexmarkov): Consider emitting SetFrame to cut expression stack.
    // In such case, we need to save return value to a variable in visitReturn.

    _restoreContextForTryBlock(node);

    asm.emitMoveSpecial(_exceptionVar(node), SpecialIndex.exception);
    asm.emitMoveSpecial(_stackTraceVar(node), SpecialIndex.stackTrace);

    final capturedExceptionVar = locals.capturedExceptionVar(node);
    if (capturedExceptionVar != null) {
      _genPushContextForVariable(capturedExceptionVar);
      asm.emitPush(_exceptionVar(node));
      _genStoreVar(capturedExceptionVar);
    }

    final capturedStackTraceVar = locals.capturedStackTraceVar(node);
    if (capturedStackTraceVar != null) {
      _genPushContextForVariable(capturedStackTraceVar);
      asm.emitPush(_stackTraceVar(node));
      _genStoreVar(capturedStackTraceVar);
    }
  }

  void _genRethrow(TreeNode node) {
    final capturedExceptionVar = locals.capturedExceptionVar(node);
    if (capturedExceptionVar != null) {
      assert(locals.isCaptured(capturedExceptionVar));
      _genLoadVar(capturedExceptionVar);
    } else {
      asm.emitPush(_exceptionVar(node));
    }

    final capturedStackTraceVar = locals.capturedStackTraceVar(node);
    if (capturedStackTraceVar != null) {
      assert(locals.isCaptured(capturedStackTraceVar));
      _genLoadVar(capturedStackTraceVar);
    } else {
      asm.emitPush(_stackTraceVar(node));
    }

    asm.emitThrow(1);
  }

  @override
  visitTryCatch(TryCatch node) {
    final Label done = new Label();

    final TryBlock tryBlock = _startTryBlock(node);
    tryBlock.isSynthetic = node.isSynthetic;
    tryCatches[node] = tryBlock; // Used by rethrow.

    node.body.accept(this);
    asm.emitJump(done);

    _endTryBlock(node, tryBlock);

    final int exception = _exceptionVar(node);
    final int stackTrace = _stackTraceVar(node);

    bool hasCatchAll = false;

    for (Catch catchClause in node.catches) {
      tryBlock.types.add(cp.add(new ConstantType(catchClause.guard)));

      Label skipCatch;
      if (catchClause.guard == const DynamicType()) {
        hasCatchAll = true;
      } else {
        asm.emitPush(exception);
        _genInstanceOf(catchClause.guard);

        skipCatch = new Label();
        _genJumpIfFalse(/* negated = */ false, skipCatch);
      }

      _enterScope(catchClause);

      if (catchClause.exception != null) {
        _genPushContextIfCaptured(catchClause.exception);
        asm.emitPush(exception);
        _genStoreVar(catchClause.exception);
      }

      if (catchClause.stackTrace != null) {
        tryBlock.needsStackTrace = true;
        _genPushContextIfCaptured(catchClause.stackTrace);
        asm.emitPush(stackTrace);
        _genStoreVar(catchClause.stackTrace);
      }

      catchClause.body.accept(this);

      _leaveScope();
      asm.emitJump(done);

      if (skipCatch != null) {
        asm.bind(skipCatch);
      }
    }

    if (!hasCatchAll) {
      tryBlock.needsStackTrace = true;
      _genRethrow(node);
    }

    asm.bind(done);
    tryCatches.remove(node);
  }

  @override
  visitTryFinally(TryFinally node) {
    final TryBlock tryBlock = _startTryBlock(node);
    finallyBlocks[node] = <FinallyBlock>[];

    node.body.accept(this);

    // TODO(alexmarkov): Do not generate normal continuation if control
    // does not return from body.
    final normalContinuation =
        new FinallyBlock(() {/* do nothing (fall through) */});
    finallyBlocks[node].add(normalContinuation);
    asm.emitJump(normalContinuation.entry);

    _endTryBlock(node, tryBlock);

    tryBlock.types.add(cp.add(new ConstantType(const DynamicType())));

    node.finalizer.accept(this);

    tryBlock.needsStackTrace = true; // For rethrowing.
    _genRethrow(node);

    for (var finallyBlock in finallyBlocks[node]) {
      asm.bind(finallyBlock.entry);
      _restoreContextForTryBlock(node);
      node.finalizer.accept(this);
      finallyBlock.generateContinuation();
    }

    finallyBlocks.remove(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.isConst) {
      final Constant constant = constantEvaluator.evaluate(node.initializer);
      constantEvaluator.env.addVariableValue(node, constant);
    } else {
      final bool isCaptured = locals.isCaptured(node);
      if (isCaptured) {
        _genPushContextForVariable(node);
      }
      if (node.initializer != null) {
        node.initializer.accept(this);
      } else {
        _genPushNull();
      }
      if (isCaptured) {
        final int cpIndex = cp.add(new ConstantContextOffset.variable(
            locals.getVarIndexInContext(node)));
        asm.emitStoreFieldTOS(cpIndex);
      } else {
        asm.emitPopLocal(locals.getVarIndexInFrame(node));
      }
    }
  }

  @override
  visitWhileStatement(WhileStatement node) {
    final Label done = new Label();
    final Label join = new Label();
    asm.bind(join);

    asm.emitCheckStack();

    bool negated = _genCondition(node.condition);
    _genJumpIfFalse(negated, done);

    node.body.accept(this);

    asm.emitJump(join);

    asm.bind(done);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    if (!node.isNative) {
      throw 'YieldStatement must be desugared: $node';
    }

    // 0 is reserved for normal entry, yield points are counted from 1.
    final int yieldIndex = yieldPoints.length + 1;
    final Label continuationLabel = new Label();
    yieldPoints.add(continuationLabel);

    // :await_jump_var = #index
    assert(locals.isCaptured(locals.awaitJumpVar));
    _genPushContextForVariable(locals.awaitJumpVar);
    _genPushInt(yieldIndex);
    _genStoreVar(locals.awaitJumpVar);

    // :await_ctx_var = context
    assert(locals.isCaptured(locals.awaitContextVar));
    _genPushContextForVariable(locals.awaitContextVar);
    asm.emitPush(locals.contextVarIndexInFrame);
    _genStoreVar(locals.awaitContextVar);

    // return <expression>
    // Note: finally blocks are *not* executed on the way out.
    node.expression.accept(this);
    asm.emitReturnTOS();

    asm.bind(continuationLabel);

    if (enclosingMember.function.dartAsyncMarker == AsyncMarker.Async ||
        enclosingMember.function.dartAsyncMarker == AsyncMarker.AsyncStar) {
      final int exceptionParam = locals.asyncExceptionParamIndexInFrame;
      final int stackTraceParam = locals.asyncStackTraceParamIndexInFrame;

      // if (:exception != null) rethrow (:exception, :stack_trace)
      final Label cont = new Label();
      asm.emitIfEqNull(exceptionParam);
      asm.emitJump(cont);

      asm.emitPush(exceptionParam);
      asm.emitPush(stackTraceParam);
      asm.emitThrow(1);

      asm.bind(cont);
    }
  }

  @override
  visitFieldInitializer(FieldInitializer node) {
    _genFieldInitializer(node.field, node.value);
  }

  @override
  visitRedirectingInitializer(RedirectingInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    _genArguments(new ThisExpression(), args);
    _genStaticCallWithArgs(node.target, args, hasReceiver: true);
    asm.emitDrop1();
  }

  @override
  visitSuperInitializer(SuperInitializer node) {
    final args = node.arguments;
    assert(args.types.isEmpty);
    _genArguments(new ThisExpression(), args);
    // Re-resolve target due to partial mixin resolution.
    Member target;
    for (var replacement in enclosingClass.superclass.constructors) {
      if (node.target.name == replacement.name) {
        target = replacement;
        break;
      }
    }
    assert(target != null);
    _genStaticCallWithArgs(target, args, hasReceiver: true);
    asm.emitDrop1();
  }

//  @override
//  visitLocalInitializer(LocalInitializer node) {
//  }
//
//  @override
//  visitAssertInitializer(AssertInitializer node) {
//  }
//
//  @override
//  visitInvalidInitializer(InvalidInitializer node) {}

  @override
  visitConstantExpression(ConstantExpression node) {
    int cpIndex = node.constant.accept(constantEmitter);
    asm.emitPushConstant(cpIndex);
  }
}

class ConstantEmitter extends ConstantVisitor<int> {
  final ConstantPool cp;

  ConstantEmitter(this.cp);

  @override
  int defaultConstant(Constant node) => throw new UnsupportedOperationError(
      'Unsupported constant node ${node.runtimeType}');

  @override
  int visitNullConstant(NullConstant node) => cp.add(const ConstantNull());

  @override
  int visitBoolConstant(BoolConstant node) =>
      cp.add(new ConstantBool(node.value));

  @override
  int visitIntConstant(IntConstant node) => cp.add(new ConstantInt(node.value));

  @override
  int visitDoubleConstant(DoubleConstant node) =>
      cp.add(new ConstantDouble(node.value));

  @override
  int visitStringConstant(StringConstant node) =>
      cp.add(new ConstantString(node.value));

  @override
  int visitListConstant(ListConstant node) => cp.add(new ConstantList(
      node.typeArgument,
      new List<int>.from(node.entries.map((Constant c) => c.accept(this)))));

  @override
  int visitInstanceConstant(InstanceConstant node) =>
      cp.add(new ConstantInstance(
          node.klass,
          cp.add(new ConstantTypeArguments(node.typeArguments)),
          node.fieldValues.map<Reference, int>(
              (Reference fieldRef, Constant value) =>
                  new MapEntry(fieldRef, value.accept(this)))));

  @override
  int visitTearOffConstant(TearOffConstant node) =>
      cp.add(new ConstantTearOff(node.procedure));

//  @override
//  int visitTypeLiteralConstant(TypeLiteralConstant node) => defaultConstant(node);
}

class UnsupportedOperationError {
  final String message;
  UnsupportedOperationError(this.message);

  @override
  String toString() => message;
}

class FindTypeParametersVisitor extends DartTypeVisitor<bool> {
  bool visit(DartType type) => type.accept(this);

  @override
  bool defaultDartType(DartType node) =>
      throw 'Unexpected type ${node.runtimeType} $node';

  @override
  bool visitInvalidType(InvalidType node) => false;

  @override
  bool visitDynamicType(DynamicType node) => false;

  @override
  bool visitVoidType(VoidType node) => false;

  @override
  bool visitBottomType(BottomType node) => false;

  @override
  bool visitVectorType(VectorType node) => false;

  @override
  bool visitTypeParameterType(TypeParameterType node) => true;

  @override
  bool visitInterfaceType(InterfaceType node) =>
      node.typeArguments.any((t) => t.accept(this));

  @override
  bool visitTypedefType(TypedefType node) =>
      node.typeArguments.any((t) => t.accept(this));

  @override
  bool visitFunctionType(FunctionType node) =>
      node.typeParameters.isNotEmpty ||
      node.positionalParameters.any((t) => t.accept(this)) ||
      node.namedParameters.any((p) => p.type.accept(this));
}

// Drop kernel AST for members with bytecode.
class DropAST extends Transformer {
  BytecodeMetadataRepository metadata;

  @override
  TreeNode visitComponent(Component node) {
    metadata = node.metadata[new BytecodeMetadataRepository().tag];
    if (metadata != null) {
      return super.visitComponent(node);
    }
    return node;
  }

  @override
  TreeNode defaultMember(Member node) {
    if (_hasBytecode(node)) {
      if (node is Field) {
        node.initializer = null;
      } else if (node is Constructor) {
        node.initializers = <Initializer>[];
        node.function.body = null;
      } else if (node.function != null) {
        node.function.body = null;
      }
    }

    // Instance field initializers do not form separate functions, and bytecode
    // is not attached to instance fields (it is included into constructors).
    // When VM reads a constructor from kernel, it also reads and translates
    // instance field initializers. So, their ASTs can be dropped only if
    // bytecode was generated for all generative constructors.
    if (node is Field && !node.isStatic && node.initializer != null) {
      if (node.enclosingClass.constructors.every(_hasBytecode)) {
        node.initializer = null;
      }
    }

    return node;
  }

  bool _hasBytecode(Member node) => metadata.mapping.containsKey(node);
}

typedef void GenerateContinuation();

class FinallyBlock {
  final Label entry = new Label();
  final GenerateContinuation generateContinuation;

  FinallyBlock(this.generateContinuation);
}
