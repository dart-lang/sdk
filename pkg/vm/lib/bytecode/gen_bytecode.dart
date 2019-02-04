// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library vm.bytecode.gen_bytecode;

import 'dart:math' show min;

import 'package:kernel/ast.dart' hide MapEntry;
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/external_name.dart' show getExternalName;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/transformations/constants.dart'
    show
        ConstantEvaluator,
        ConstantsBackend,
        EvaluationEnvironment,
        ErrorReporter;
import 'package:kernel/type_algebra.dart'
    show Substitution, containsTypeVariable;
import 'package:kernel/type_environment.dart' show TypeEnvironment;
import 'package:kernel/vm/constants_native_effects.dart'
    show VmConstantsBackend;
import 'assembler.dart';
import 'bytecode_serialization.dart' show StringTable;
import 'constant_pool.dart';
import 'dbc.dart';
import 'exceptions.dart';
import 'local_vars.dart' show LocalVariables;
import 'nullability_detector.dart' show NullabilityDetector;
import 'object_table.dart' show ObjectHandle, ObjectTable, NameAndType;
import 'recognized_methods.dart' show RecognizedMethods;
import '../constants_error_reporter.dart' show ForwardConstantEvaluationErrors;
import '../metadata/bytecode.dart';

// This symbol is used as the name in assert assignable's to indicate it comes
// from an explicit 'as' check.  This will cause the runtime to throw the right
// exception.
const String symbolForTypeCast = ' in type cast';

void generateBytecode(
  Component component, {
  bool emitSourcePositions: false,
  bool omitAssertSourcePositions: false,
  bool useFutureBytecodeFormat: false,
  Map<String, String> environmentDefines: const <String, String>{},
  ErrorReporter errorReporter,
  List<Library> libraries,
}) {
  final coreTypes = new CoreTypes(component);
  void ignoreAmbiguousSupertypes(Class cls, Supertype a, Supertype b) {}
  final hierarchy = new ClassHierarchy(component,
      onAmbiguousSupertypes: ignoreAmbiguousSupertypes);
  final typeEnvironment = new TypeEnvironment(coreTypes, hierarchy);
  final constantsBackend = new VmConstantsBackend(coreTypes);
  final errorReporter = new ForwardConstantEvaluationErrors(typeEnvironment);
  libraries ??= component.libraries;
  final bytecodeGenerator = new BytecodeGenerator(
      component,
      coreTypes,
      hierarchy,
      typeEnvironment,
      constantsBackend,
      environmentDefines,
      emitSourcePositions,
      omitAssertSourcePositions,
      useFutureBytecodeFormat,
      errorReporter);
  for (var library in libraries) {
    bytecodeGenerator.visitLibrary(library);
  }
}

class BytecodeGenerator extends RecursiveVisitor<Null> {
  final Component component;
  final CoreTypes coreTypes;
  final ClassHierarchy hierarchy;
  final TypeEnvironment typeEnvironment;
  final ConstantsBackend constantsBackend;
  final Map<String, String> environmentDefines;
  final bool emitSourcePositions;
  final bool omitAssertSourcePositions;
  final bool useFutureBytecodeFormat;
  final ErrorReporter errorReporter;
  final BytecodeMetadataRepository metadata = new BytecodeMetadataRepository();
  final RecognizedMethods recognizedMethods;
  final int formatVersion;
  StringTable stringTable;
  ObjectTable objectTable;
  NullabilityDetector nullabilityDetector;

  Class enclosingClass;
  Member enclosingMember;
  FunctionNode enclosingFunction;
  FunctionNode parentFunction;
  bool isClosure;
  Set<TypeParameter> classTypeParameters;
  List<TypeParameter> functionTypeParameters;
  Set<TypeParameter> functionTypeParametersSet;
  List<DartType> instantiatorTypeArguments;
  LocalVariables locals;
  ConstantEvaluator constantEvaluator;
  Map<LabeledStatement, Label> labeledStatements;
  Map<SwitchCase, Label> switchCases;
  Map<TryCatch, TryBlock> tryCatches;
  Map<TryFinally, List<FinallyBlock>> finallyBlocks;
  List<Label> yieldPoints;
  Map<TreeNode, int> contextLevels;
  List<ClosureDeclaration> closures;
  Set<Field> initializedFields;
  List<ObjectHandle> nullableFields;
  ConstantPool cp;
  ConstantEmitter constantEmitter;
  BytecodeAssembler asm;
  List<BytecodeAssembler> savedAssemblers;
  bool hasErrors;
  int currentLoopDepth;

  BytecodeGenerator(
      this.component,
      this.coreTypes,
      this.hierarchy,
      this.typeEnvironment,
      this.constantsBackend,
      this.environmentDefines,
      this.emitSourcePositions,
      this.omitAssertSourcePositions,
      this.useFutureBytecodeFormat,
      this.errorReporter)
      : recognizedMethods = new RecognizedMethods(typeEnvironment),
        formatVersion = useFutureBytecodeFormat
            ? futureBytecodeFormatVersion
            : stableBytecodeFormatVersion {
    nullabilityDetector = new NullabilityDetector(recognizedMethods);
    component.addMetadataRepository(metadata);

    metadata.bytecodeComponent = new BytecodeComponent(formatVersion);
    metadata.mapping[component] = metadata.bytecodeComponent;

    stringTable = metadata.bytecodeComponent.stringTable;
    objectTable = metadata.bytecodeComponent.objectTable;
    objectTable.coreTypes = coreTypes;
  }

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
        if (node.isStatic && !_hasTrivialInitializer(node)) {
          start(node);
          if (node.isConst) {
            _genPushConstExpr(node.initializer);
          } else {
            _generateNode(node.initializer);
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
          _generateNode(node.function?.body);
          // BytecodeAssembler eliminates this bytecode if it is unreachable.
          asm.emitPushNull();
        }
        _genReturnTOS();
        end(node);
      }
    } on BytecodeLimitExceededException {
      // Do not generate bytecode and fall back to using kernel AST.
      hasErrors = true;
      end(node);
    }
  }

  void _genNativeCall(String nativeName) {
    final function = enclosingMember.function;
    assert(function != null);

    if (locals.hasFactoryTypeArgsVar) {
      asm.emitPush(locals.getVarIndexInFrame(locals.factoryTypeArgsVar));
    } else if (locals.hasFunctionTypeArgsVar) {
      asm.emitPush(locals.functionTypeArgsVarIndexInFrame);
    }
    if (locals.hasReceiver) {
      asm.emitPush(locals.getVarIndexInFrame(locals.receiverVar));
    }
    for (var param in function.positionalParameters) {
      asm.emitPush(locals.getVarIndexInFrame(param));
    }
    // Native methods access their parameters by indices, so
    // native wrappers should pass arguments in the original declaration
    // order instead of sorted order.
    for (var param in locals.originalNamedParameters) {
      asm.emitPush(locals.getVarIndexInFrame(param));
    }

    final nativeEntryCpIndex = cp.addNativeEntry(nativeName);
    asm.emitNativeCall(nativeEntryCpIndex);
  }

  LibraryIndex get libraryIndex => coreTypes.index;

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

  Procedure _objectSimpleInstanceOf;
  Procedure get objectSimpleInstanceOf => _objectSimpleInstanceOf ??=
      libraryIndex.getMember('dart:core', 'Object', '_simpleInstanceOf');

  Field _closureInstantiatorTypeArguments;
  Field get closureInstantiatorTypeArguments =>
      _closureInstantiatorTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_instantiator_type_arguments');

  Field _closureFunctionTypeArguments;
  Field get closureFunctionTypeArguments =>
      _closureFunctionTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_function_type_arguments');

  Field _closureDelayedTypeArguments;
  Field get closureDelayedTypeArguments =>
      _closureDelayedTypeArguments ??= libraryIndex.getMember(
          'dart:core', '_Closure', '_delayed_type_arguments');

  Field _closureFunction;
  Field get closureFunction => _closureFunction ??=
      libraryIndex.getMember('dart:core', '_Closure', '_function');

  Field _closureContext;
  Field get closureContext => _closureContext ??=
      libraryIndex.getMember('dart:core', '_Closure', '_context');

  Procedure _prependTypeArguments;
  Procedure get prependTypeArguments => _prependTypeArguments ??=
      libraryIndex.getTopLevelMember('dart:_internal', '_prependTypeArguments');

  Procedure _boundsCheckForPartialInstantiation;
  Procedure get boundsCheckForPartialInstantiation =>
      _boundsCheckForPartialInstantiation ??= libraryIndex.getTopLevelMember(
          'dart:_internal', '_boundsCheckForPartialInstantiation');

  Procedure _futureValue;
  Procedure get futureValue =>
      _futureValue ??= libraryIndex.getMember('dart:async', 'Future', 'value');

  Procedure _throwNewAssertionError;
  Procedure get throwNewAssertionError => _throwNewAssertionError ??=
      libraryIndex.getMember('dart:core', '_AssertionError', '_throwNew');

  Procedure _allocateInvocationMirror;
  Procedure get allocateInvocationMirror =>
      _allocateInvocationMirror ??= libraryIndex.getMember(
          'dart:core', '_InvocationMirror', '_allocateInvocationMirror');

  Procedure _unsafeCast;
  Procedure get unsafeCast => _unsafeCast ??=
      libraryIndex.getTopLevelMember('dart:_internal', 'unsafeCast');

  void _recordSourcePosition(TreeNode node) {
    if (emitSourcePositions) {
      asm.currentSourcePosition = node.fileOffset;
    }
  }

  void _generateNode(TreeNode node) {
    if (node == null) {
      return;
    }
    final savedSourcePosition = asm.currentSourcePosition;
    _recordSourcePosition(node);
    node.accept(this);
    asm.currentSourcePosition = savedSourcePosition;
  }

  void _generateNodeList(List<TreeNode> nodes) {
    nodes.forEach(_generateNode);
  }

  void _genConstructorInitializers(Constructor node) {
    final bool isRedirecting =
        node.initializers.any((init) => init is RedirectingInitializer);

    if (!isRedirecting) {
      initializedFields = new Set<Field>();
      for (var field in node.enclosingClass.fields) {
        if (!field.isStatic && field.initializer != null) {
          _genFieldInitializer(field, field.initializer);
        }
      }
    }

    _generateNodeList(node.initializers);

    if (!isRedirecting) {
      nullableFields = <ObjectHandle>[];
      for (var field in node.enclosingClass.fields) {
        if (!field.isStatic && !initializedFields.contains(field)) {
          nullableFields.add(objectTable.getHandle(field));
        }
      }
      initializedFields = null; // No more initialized fields, please.
    }
  }

  void _genFieldInitializer(Field field, Expression initializer) {
    assert(!field.isStatic);

    if (initializer is NullLiteral && !initializedFields.contains(field)) {
      return;
    }

    _genPushReceiver();
    _generateNode(initializer);

    final int cpIndex = cp.addInstanceField(field);
    asm.emitStoreFieldTOS(cpIndex);

    initializedFields.add(field);
  }

  void _genArguments(Expression receiver, Arguments arguments) {
    if (arguments.types.isNotEmpty) {
      _genTypeArguments(arguments.types);
    }
    _generateNode(receiver);
    _generateNodeList(arguments.positional);
    arguments.named.forEach((NamedExpression ne) => _generateNode(ne.value));
  }

  void _genPushBool(bool value) {
    if (value) {
      asm.emitPushTrue();
    } else {
      asm.emitPushFalse();
    }
  }

  void _genPushInt(int value) {
    if (value.bitLength + 1 <= 16) {
      asm.emitPushInt(value);
    } else {
      asm.emitPushConstant(cp.addInt(value));
    }
  }

  Constant _evaluateConstantExpression(Expression expr) {
    if (expr is ConstantExpression) {
      return expr.constant;
    }
    final constant = constantEvaluator.evaluate(expr);
    if (constant is UnevaluatedConstant &&
        constant.expression is InvalidExpression) {
      // Compile-time error is already reported. Proceed with compilation
      // in order to report errors in other constant expressions.
      hasErrors = true;
      return new NullConstant();
    }
    return constant;
  }

  void _genPushConstExpr(Expression expr) {
    final constant = _evaluateConstantExpression(expr);
    if (constant is NullConstant) {
      asm.emitPushNull();
    } else if (constant is BoolConstant) {
      _genPushBool(constant.value);
    } else if (constant is IntConstant) {
      _genPushInt(constant.value);
    } else {
      asm.emitPushConstant(constant.accept(constantEmitter));
    }
  }

  void _genReturnTOS() {
    asm.emitReturnTOS();
  }

  void _genStaticCall(Member target, int argDescIndex, int totalArgCount,
      {bool isGet: false, bool isSet: false}) {
    assert(!isGet || !isSet);
    final kind = isGet
        ? InvocationKind.getter
        : (isSet ? InvocationKind.setter : InvocationKind.method);
    final icdataIndex = cp.addStaticICData(kind, target, argDescIndex);

    asm.emitPushConstant(icdataIndex);
    asm.emitIndirectStaticCall(totalArgCount, argDescIndex);
  }

  void _genStaticCallWithArgs(Member target, Arguments args,
      {bool hasReceiver: false, bool isFactory: false}) {
    final int argDescIndex = cp.addArgDescByArguments(args,
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

    _genStaticCall(target, argDescIndex, totalArgCount);
  }

  bool hasFreeTypeParameters(List<DartType> typeArgs) {
    final findTypeParams = new FindFreeTypeParametersVisitor();
    return typeArgs.any((t) => t.accept(findTypeParams));
  }

  void _genTypeArguments(List<DartType> typeArgs, {Class instantiatingClass}) {
    int typeArgsCPIndex() {
      if (instantiatingClass != null) {
        return cp.addTypeArgumentsForInstanceAllocation(
            instantiatingClass, typeArgs);
      } else {
        return cp.addTypeArguments(typeArgs);
      }
    }

    if (typeArgs.isEmpty || !hasFreeTypeParameters(typeArgs)) {
      asm.emitPushConstant(typeArgsCPIndex());
    } else {
      final flattenedTypeArgs = (instantiatingClass != null &&
              (instantiatorTypeArguments != null ||
                  functionTypeParameters != null))
          ? _flattenInstantiatorTypeArguments(instantiatingClass, typeArgs)
          : typeArgs;
      if (_canReuseInstantiatorTypeArguments(flattenedTypeArgs)) {
        _genPushInstantiatorTypeArguments();
      } else if (_canReuseFunctionTypeArguments(flattenedTypeArgs)) {
        _genPushFunctionTypeArguments();
      } else {
        _genPushInstantiatorAndFunctionTypeArguments(typeArgs);
        // TODO(alexmarkov): Optimize type arguments instantiation
        // by passing rA = 1 in InstantiateTypeArgumentsTOS.
        // For this purpose, we need to detect if type arguments
        // would be all-dynamic in case of all-dynamic instantiator and
        // function type arguments.
        // Corresponding check is implemented in VM in
        // TypeArguments::IsRawWhenInstantiatedFromRaw.
        asm.emitInstantiateTypeArgumentsTOS(0, typeArgsCPIndex());
      }
    }
  }

  void _genPushInstantiatorAndFunctionTypeArguments(List<DartType> types) {
    if (classTypeParameters != null &&
        types.any((t) => containsTypeVariable(t, classTypeParameters))) {
      assert(instantiatorTypeArguments != null);
      _genPushInstantiatorTypeArguments();
    } else {
      asm.emitPushNull();
    }
    if (functionTypeParametersSet != null &&
        types.any((t) => containsTypeVariable(t, functionTypeParametersSet))) {
      _genPushFunctionTypeArguments();
    } else {
      asm.emitPushNull();
    }
  }

  void _genPushInstantiatorTypeArguments() {
    if (instantiatorTypeArguments != null) {
      if (locals.hasFactoryTypeArgsVar) {
        assert(enclosingMember is Procedure &&
            (enclosingMember as Procedure).isFactory);
        _genLoadVar(locals.factoryTypeArgsVar);
      } else {
        _genPushReceiver();
        final int cpIndex = cp.addTypeArgumentsField(enclosingClass);
        asm.emitLoadTypeArgumentsField(cpIndex);
      }
    } else {
      asm.emitPushNull();
    }
  }

  bool _canReuseSuperclassTypeArguments(List<DartType> superTypeArgs,
      List<TypeParameter> typeParameters, int overlap) {
    for (int i = 0; i < overlap; ++i) {
      final superTypeArg = superTypeArgs[superTypeArgs.length - overlap + i];
      if (!(superTypeArg is TypeParameterType &&
          superTypeArg.parameter == typeParameters[i])) {
        return false;
      }
    }
    return true;
  }

  List<DartType> _flattenInstantiatorTypeArguments(
      Class instantiatedClass, List<DartType> typeArgs) {
    final typeParameters = instantiatedClass.typeParameters;
    assert(typeArgs.length == typeParameters.length);

    final supertype = instantiatedClass.supertype;
    if (supertype == null) {
      return typeArgs;
    }

    final superTypeArgs = _flattenInstantiatorTypeArguments(
        supertype.classNode, supertype.typeArguments);

    // Shrink type arguments by reusing portion of superclass type arguments
    // if there is an overlapping. This optimization should be consistent with
    // VM in order to correctly reuse instantiator type arguments.
    int overlap = min(superTypeArgs.length, typeArgs.length);
    for (; overlap > 0; --overlap) {
      if (_canReuseSuperclassTypeArguments(
          superTypeArgs, typeParameters, overlap)) {
        break;
      }
    }

    final substitution = Substitution.fromPairs(typeParameters, typeArgs);

    List<DartType> flatTypeArgs = <DartType>[];
    flatTypeArgs
        .addAll(superTypeArgs.map((t) => substitution.substituteType(t)));
    flatTypeArgs.addAll(typeArgs.getRange(overlap, typeArgs.length));

    return flatTypeArgs;
  }

  bool _canReuseInstantiatorTypeArguments(List<DartType> typeArgs) {
    if (instantiatorTypeArguments == null) {
      return false;
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

  bool _canReuseFunctionTypeArguments(List<DartType> typeArgs) {
    if (functionTypeParameters == null) {
      return false;
    }

    if (typeArgs.length > functionTypeParameters.length) {
      return false;
    }

    for (int i = 0; i < typeArgs.length; ++i) {
      final typeArg = typeArgs[i];
      if (!(typeArg is TypeParameterType &&
          typeArg.parameter == functionTypeParameters[i])) {
        return false;
      }
    }

    return true;
  }

  void _genPushFunctionTypeArguments() {
    if (locals.hasFunctionTypeArgsVar) {
      asm.emitPush(locals.functionTypeArgsVarIndexInFrame);
    } else {
      asm.emitPushNull();
    }
  }

  void _genPushContextForVariable(VariableDeclaration variable,
      {int currentContextLevel}) {
    currentContextLevel ??= locals.currentContextLevel;
    int depth = currentContextLevel - locals.getContextLevelOfVar(variable);
    assert(depth >= 0);

    asm.emitPush(locals.contextVarIndexInFrame);
    if (depth > 0) {
      for (; depth > 0; --depth) {
        asm.emitLoadContextParent();
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
      asm.emitLoadContextVar(
          locals.getVarContextId(v), locals.getVarIndexInContext(v));
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
      asm.emitStoreContextVar(locals.getVarContextId(variable),
          locals.getVarIndexInContext(variable));
    } else {
      asm.emitPopLocal(locals.getVarIndexInFrame(variable));
    }
  }

  /// Generates bool condition. Returns `true` if condition is negated.
  bool _genCondition(Expression condition) {
    bool negated = false;
    if (condition is Not) {
      condition = (condition as Not).operand;
      negated = true;
    }
    _generateNode(condition);
    if (nullabilityDetector.isNullable(condition)) {
      asm.emitAssertBoolean(0);
    }
    return negated;
  }

  void _genJumpIfFalse(bool negated, Label dest) {
    if (negated) {
      asm.emitJumpIfTrue(dest);
    } else {
      asm.emitJumpIfFalse(dest);
    }
  }

  void _genJumpIfTrue(bool negated, Label dest) {
    _genJumpIfFalse(!negated, dest);
  }

  /// Returns value of the given expression if it is a bool constant.
  /// Otherwise, returns `null`.
  bool _constantConditionValue(Expression condition) {
    // TODO(dartbug.com/34585): use constant evaluator to evaluate
    // expressions in a non-constant context.
    if (condition is Not) {
      final operand = _constantConditionValue(condition.operand);
      return (operand != null) ? !operand : null;
    }
    if (condition is BoolLiteral) {
      return condition.value;
    }
    Constant constant;
    if (condition is ConstantExpression) {
      constant = condition.constant;
    } else if ((condition is StaticGet && condition.target.isConst) ||
        (condition is StaticInvocation && condition.isConst) ||
        (condition is VariableGet && condition.variable.isConst)) {
      constant = _evaluateConstantExpression(condition);
    }
    if (constant is BoolConstant) {
      return constant.value;
    }
    return null;
  }

  void _genConditionAndJumpIf(Expression condition, bool value, Label dest) {
    final bool constantValue = _constantConditionValue(condition);
    if (constantValue != null) {
      if (constantValue == value) {
        asm.emitJump(dest);
      }
      return;
    }
    bool negated = _genCondition(condition);
    if (value) {
      _genJumpIfTrue(negated, dest);
    } else {
      _genJumpIfFalse(negated, dest);
    }
  }

  int _getDefaultParamConstIndex(VariableDeclaration param) {
    if (param.initializer == null) {
      return cp.addNull();
    }
    final constant = _evaluateConstantExpression(param.initializer);
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
    if (typeEnvironment.isTop(type)) {
      asm.emitDrop1();
      asm.emitPushTrue();
      return;
    }

    if (type is InterfaceType && type.typeArguments.isEmpty) {
      assert(type.classNode.typeParameters.isEmpty);
      asm.emitPushConstant(cp.addType(type));
      final argDescIndex = cp.addArgDesc(2);
      final icdataIndex = cp.addInterfaceCall(
          InvocationKind.method, objectSimpleInstanceOf.name, argDescIndex);
      asm.emitInterfaceCall(2, icdataIndex);
      return;
    }

    if (hasFreeTypeParameters([type])) {
      _genPushInstantiatorAndFunctionTypeArguments([type]);
    } else {
      asm.emitPushNull(); // Instantiator type arguments.
      asm.emitPushNull(); // Function type arguments.
    }
    asm.emitPushConstant(cp.addType(type));
    final argDescIndex = cp.addArgDesc(4);
    final icdataIndex = cp.addInterfaceCall(
        InvocationKind.method, objectInstanceOf.name, argDescIndex);
    asm.emitInterfaceCall(4, icdataIndex);
  }

  void start(Member node) {
    enclosingClass = node.enclosingClass;
    enclosingMember = node;
    enclosingFunction = node.function;
    parentFunction = null;
    isClosure = false;
    hasErrors = false;
    if ((node is Procedure && !node.isStatic) || node is Constructor) {
      typeEnvironment.thisType = enclosingClass.thisType;
    }
    final isFactory = node is Procedure && node.isFactory;
    if (node.isInstanceMember || node is Constructor || isFactory) {
      if (enclosingClass.typeParameters.isNotEmpty) {
        classTypeParameters =
            new Set<TypeParameter>.from(enclosingClass.typeParameters);
        // Treat type arguments of factory constructors as class
        // type parameters.
        if (isFactory) {
          classTypeParameters.addAll(node.function.typeParameters);
        }
      }
      if (hasInstantiatorTypeArguments(enclosingClass)) {
        final typeParameters = (isFactory
                ? node.function.typeParameters
                : enclosingClass.typeParameters)
            .map((p) => new TypeParameterType(p))
            .toList();
        instantiatorTypeArguments =
            _flattenInstantiatorTypeArguments(enclosingClass, typeParameters);
      }
    }
    if (enclosingFunction != null &&
        enclosingFunction.typeParameters.isNotEmpty) {
      functionTypeParameters =
          new List<TypeParameter>.from(enclosingFunction.typeParameters);
      functionTypeParametersSet = functionTypeParameters.toSet();
    }
    locals = new LocalVariables(node);
    // TODO(alexmarkov): improve caching in ConstantEvaluator and reuse it
    constantEvaluator = new ConstantEvaluator(
        constantsBackend,
        environmentDefines,
        typeEnvironment,
        coreTypes,
        /* enableAsserts = */ true,
        errorReporter)
      ..env = new EvaluationEnvironment();
    labeledStatements = <LabeledStatement, Label>{};
    switchCases = <SwitchCase, Label>{};
    tryCatches = <TryCatch, TryBlock>{};
    finallyBlocks = <TryFinally, List<FinallyBlock>>{};
    yieldPoints = null; // Initialized when entering sync-yielding closure.
    contextLevels = <TreeNode, int>{};
    closures = <ClosureDeclaration>[];
    initializedFields = null; // Tracked for constructors only.
    nullableFields = const <ObjectHandle>[];
    cp = new ConstantPool(stringTable, objectTable);
    constantEmitter = new ConstantEmitter(cp);
    asm = new BytecodeAssembler();
    savedAssemblers = <BytecodeAssembler>[];
    currentLoopDepth = 0;

    locals.enterScope(node);
    assert(!locals.isSyncYieldingFrame);

    _recordSourcePosition(node);
    _genPrologue(node, node.function);
    _setupInitialContext(node.function);
    if (node is Procedure && node.isInstanceMember) {
      _checkArguments(node.function);
    }
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
    asm.emitJumpIfNotNull(done);

    asm.emitPushFalse();
    _genReturnTOS();

    asm.bind(done);
  }

  void end(Member node) {
    if (!hasErrors) {
      metadata.mapping[node] = new MemberBytecode(cp, asm.bytecode,
          asm.exceptionsTable, asm.sourcePositions, nullableFields, closures);
    }

    typeEnvironment.thisType = null;
    enclosingClass = null;
    enclosingMember = null;
    enclosingFunction = null;
    parentFunction = null;
    isClosure = null;
    classTypeParameters = null;
    functionTypeParameters = null;
    functionTypeParametersSet = null;
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
    initializedFields = null;
    nullableFields = null;
    cp = null;
    constantEmitter = null;
    asm = null;
    savedAssemblers = null;
    hasErrors = false;
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
          final param = locals.sortedNamedParameters[i];
          asm.emitLoadConstant(numFixed + i, cp.addString(param.name));
          asm.emitLoadConstant(numFixed + i, _getDefaultParamConstIndex(param));
        }
      }

      asm.emitFrame(locals.frameSize - locals.numParameters);
    } else if (isClosure) {
      asm.emitEntryFixed(locals.numParameters, locals.frameSize);
    } else {
      asm.emitEntry(locals.frameSize);
    }
    asm.emitCheckStack(0);

    if (isClosure) {
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.addInstanceField(closureContext));
      asm.emitPopLocal(locals.contextVarIndexInFrame);
    }

    if (locals.hasFunctionTypeArgsVar) {
      if (function.typeParameters.isNotEmpty) {
        assert(!(node is Procedure && node.isFactory));

        Label done = new Label();

        if (isClosure) {
          _handleDelayedTypeArguments(done);
        }

        asm.emitCheckFunctionTypeArgs(function.typeParameters.length,
            locals.functionTypeArgsVarIndexInFrame);

        _handleDefaultTypeArguments(function, done);

        asm.bind(done);
      }

      if (isClosure) {
        if (function.typeParameters.isNotEmpty) {
          final int numParentTypeArgs = locals.numParentTypeArguments;
          asm.emitPush(locals.functionTypeArgsVarIndexInFrame);
          asm.emitPush(locals.closureVarIndexInFrame);
          asm.emitLoadFieldTOS(
              cp.addInstanceField(closureFunctionTypeArguments));
          _genPushInt(numParentTypeArgs);
          _genPushInt(numParentTypeArgs + function.typeParameters.length);
          _genStaticCall(prependTypeArguments, cp.addArgDesc(4), 4);
          asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
        } else {
          asm.emitPush(locals.closureVarIndexInFrame);
          asm.emitLoadFieldTOS(
              cp.addInstanceField(closureFunctionTypeArguments));
          asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
        }
      }
    }
  }

  void _handleDelayedTypeArguments(Label doneCheckingTypeArguments) {
    Label noDelayedTypeArgs = new Label();

    asm.emitPush(locals.closureVarIndexInFrame);
    asm.emitLoadFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));
    asm.emitStoreLocal(locals.functionTypeArgsVarIndexInFrame);
    asm.emitPushConstant(cp.addEmptyTypeArguments());
    asm.emitJumpIfEqStrict(noDelayedTypeArgs);

    // There are non-empty delayed type arguments, and they are stored
    // into function type args variable already.
    // Just verify that there are no passed type arguments.
    asm.emitCheckFunctionTypeArgs(0, locals.scratchVarIndexInFrame);
    asm.emitJump(doneCheckingTypeArguments);

    asm.bind(noDelayedTypeArgs);
  }

  void _handleDefaultTypeArguments(
      FunctionNode function, Label doneCheckingTypeArguments) {
    bool hasNonDynamicDefaultTypes = function.typeParameters.any(
        (p) => p.defaultType != null && p.defaultType != const DynamicType());
    if (!hasNonDynamicDefaultTypes) {
      return;
    }

    asm.emitJumpIfNotZeroTypeArgs(doneCheckingTypeArguments);

    List<DartType> defaultTypes = function.typeParameters
        .map((p) => p.defaultType ?? const DynamicType())
        .toList();

    // Load parent function type arguments if they are used to
    // instantiate default types.
    if (isClosure &&
        defaultTypes
            .any((t) => containsTypeVariable(t, functionTypeParametersSet))) {
      asm.emitPush(locals.closureVarIndexInFrame);
      asm.emitLoadFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));
      asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
    }

    _genTypeArguments(defaultTypes);
    asm.emitPopLocal(locals.functionTypeArgsVarIndexInFrame);
  }

  void _setupInitialContext(FunctionNode function) {
    _allocateContextIfNeeded();

    if (locals.hasCapturedParameters) {
      // Copy captured parameters to their respective locations in the context.
      if (!isClosure) {
        if (locals.hasFactoryTypeArgsVar) {
          _copyParamIfCaptured(locals.factoryTypeArgsVar);
        }
        if (locals.hasCapturedReceiverVar) {
          _genPushContextForVariable(locals.capturedReceiverVar);
          asm.emitPush(locals.getVarIndexInFrame(locals.receiverVar));
          _genStoreVar(locals.capturedReceiverVar);
        }
      }
      function.positionalParameters.forEach(_copyParamIfCaptured);
      locals.sortedNamedParameters.forEach(_copyParamIfCaptured);
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

  // TODO(alexmarkov): Revise if we need to AOT-compile from bytecode.
  bool get canSkipTypeChecksForNonCovariantArguments =>
      !isClosure && enclosingMember.name.name != 'call';

  Member _getForwardingStubSuperTarget() {
    if (!isClosure) {
      final member = enclosingMember;
      if (member.isInstanceMember &&
          member is Procedure &&
          member.isForwardingStub) {
        return member.forwardingStubSuperTarget;
      }
    }
    return null;
  }

  // Types in a target of a forwarding stub are encoded in terms of target type
  // parameters. Substitute them with host type parameters to be able
  // to use them (e.g. instantiate) in the context of host.
  Substitution _getForwardingSubstitution(
      FunctionNode host, Member forwardingTarget) {
    if (forwardingTarget == null) {
      return null;
    }
    final Class targetClass = forwardingTarget.enclosingClass;
    final Supertype instantiatedTargetClass =
        hierarchy.getClassAsInstanceOf(enclosingClass, targetClass);
    if (instantiatedTargetClass == null) {
      throw 'Class $targetClass is not found among implemented interfaces of'
          ' $enclosingClass (for forwarding stub $enclosingMember)';
    }
    assert(instantiatedTargetClass.classNode == targetClass);
    assert(instantiatedTargetClass.typeArguments.length ==
        targetClass.typeParameters.length);
    final Map<TypeParameter, DartType> map =
        new Map<TypeParameter, DartType>.fromIterables(
            targetClass.typeParameters, instantiatedTargetClass.typeArguments);
    if (forwardingTarget.function != null) {
      final targetTypeParameters = forwardingTarget.function.typeParameters;
      assert(host.typeParameters.length == targetTypeParameters.length);
      for (int i = 0; i < targetTypeParameters.length; ++i) {
        map[targetTypeParameters[i]] =
            new TypeParameterType(host.typeParameters[i]);
      }
    }
    return Substitution.fromMap(map);
  }

  /// If member being compiled is a forwarding stub, then returns type
  /// parameter bounds to check for the forwarding stub target.
  Map<TypeParameter, DartType> _getForwardingBounds(FunctionNode function,
      Member forwardingTarget, Substitution forwardingSubstitution) {
    if (function.typeParameters.isEmpty || forwardingTarget == null) {
      return null;
    }
    final forwardingBounds = <TypeParameter, DartType>{};
    for (int i = 0; i < function.typeParameters.length; ++i) {
      DartType bound = forwardingSubstitution
          .substituteType(forwardingTarget.function.typeParameters[i].bound);
      forwardingBounds[function.typeParameters[i]] = bound;
    }
    return forwardingBounds;
  }

  /// If member being compiled is a forwarding stub, then returns parameter
  /// types to check for the forwarding stub target.
  Map<VariableDeclaration, DartType> _getForwardingParameterTypes(
      FunctionNode function,
      Member forwardingTarget,
      Substitution forwardingSubstitution) {
    if (forwardingTarget == null) {
      return null;
    }

    if (forwardingTarget is Field) {
      if ((enclosingMember as Procedure).isGetter) {
        return const <VariableDeclaration, DartType>{};
      } else {
        // Forwarding stub for a covariant field setter.
        assert((enclosingMember as Procedure).isSetter);
        assert(function.typeParameters.isEmpty &&
            function.positionalParameters.length == 1 &&
            function.namedParameters.length == 0);
        return <VariableDeclaration, DartType>{
          function.positionalParameters.single:
              forwardingSubstitution.substituteType(forwardingTarget.type)
        };
      }
    }

    final forwardingParams = <VariableDeclaration, DartType>{};
    for (int i = 0; i < function.positionalParameters.length; ++i) {
      DartType type = forwardingSubstitution.substituteType(
          forwardingTarget.function.positionalParameters[i].type);
      forwardingParams[function.positionalParameters[i]] = type;
    }
    for (var hostParam in function.namedParameters) {
      VariableDeclaration targetParam = forwardingTarget
          .function.namedParameters
          .firstWhere((p) => p.name == hostParam.name);
      forwardingParams[hostParam] =
          forwardingSubstitution.substituteType(targetParam.type);
    }
    return forwardingParams;
  }

  void _checkArguments(FunctionNode function) {
    // When checking arguments of a forwarding stub, we need to use parameter
    // types (and bounds of type parameters) from stub's target.
    // These more accurate type checks is the sole purpose of a forwarding stub.
    final forwardingTarget = _getForwardingStubSuperTarget();
    final forwardingSubstitution =
        _getForwardingSubstitution(function, forwardingTarget);
    final forwardingBounds = _getForwardingBounds(
        function, forwardingTarget, forwardingSubstitution);
    final forwardingParamTypes = _getForwardingParameterTypes(
        function, forwardingTarget, forwardingSubstitution);

    for (var typeParam in function.typeParameters) {
      _genTypeParameterBoundCheck(typeParam, forwardingBounds);
    }
    for (var param in function.positionalParameters) {
      _genArgumentTypeCheck(param, forwardingParamTypes);
    }
    for (var param in locals.sortedNamedParameters) {
      _genArgumentTypeCheck(param, forwardingParamTypes);
    }
  }

  void _genTypeParameterBoundCheck(TypeParameter typeParam,
      Map<TypeParameter, DartType> forwardingTypeParameterBounds) {
    if (canSkipTypeChecksForNonCovariantArguments &&
        !typeParam.isGenericCovariantImpl) {
      return;
    }
    final DartType bound = (forwardingTypeParameterBounds != null)
        ? forwardingTypeParameterBounds[typeParam]
        : typeParam.bound;
    if (typeEnvironment.isTop(bound)) {
      return;
    }
    final DartType type = new TypeParameterType(typeParam);
    _genPushInstantiatorAndFunctionTypeArguments([type, bound]);
    asm.emitPushConstant(cp.addType(type));
    asm.emitPushConstant(cp.addType(bound));
    asm.emitPushConstant(cp.addString(typeParam.name));
    asm.emitAssertSubtype();
  }

  void _genArgumentTypeCheck(VariableDeclaration variable,
      Map<VariableDeclaration, DartType> forwardingParameterTypes) {
    if (canSkipTypeChecksForNonCovariantArguments &&
        !variable.isCovariant &&
        !variable.isGenericCovariantImpl) {
      return;
    }
    final DartType type = (forwardingParameterTypes != null)
        ? forwardingParameterTypes[variable]
        : variable.type;
    if (typeEnvironment.isTop(type)) {
      return;
    }
    if (locals.isCaptured(variable)) {
      asm.emitPush(locals.getOriginalParamSlotIndex(variable));
    } else {
      asm.emitPush(locals.getVarIndexInFrame(variable));
    }
    _genAssertAssignable(type, name: variable.name);
    asm.emitDrop1();
  }

  void _genAssertAssignable(DartType type, {String name = ''}) {
    assert(!typeEnvironment.isTop(type));
    asm.emitPushConstant(cp.addType(type));
    _genPushInstantiatorAndFunctionTypeArguments([type]);
    asm.emitPushConstant(cp.addString(name));
    bool isIntOk = typeEnvironment.isSubtypeOf(typeEnvironment.intType, type);
    int subtypeTestCacheCpIndex = cp.addSubtypeTestCache();
    asm.emitAssertAssignable(isIntOk ? 1 : 0, subtypeTestCacheCpIndex);
  }

  void _pushAssemblerState() {
    savedAssemblers.add(asm);
    asm = new BytecodeAssembler();
  }

  void _popAssemblerState() {
    asm = savedAssemblers.removeLast();
  }

  void _evaluateDefaultParameterValue(VariableDeclaration param) {
    if (param.initializer != null && param.initializer is! BasicLiteral) {
      final constant = _evaluateConstantExpression(param.initializer);
      param.initializer = new ConstantExpression(constant)..parent = param;
    }
  }

  int _genClosureBytecode(TreeNode node, String name, FunctionNode function) {
    _pushAssemblerState();

    locals.enterScope(node);

    final savedParentFunction = parentFunction;
    parentFunction = enclosingFunction;
    final savedIsClosure = isClosure;
    isClosure = true;
    enclosingFunction = function;
    final savedLoopDepth = currentLoopDepth;
    currentLoopDepth = 0;

    if (function.typeParameters.isNotEmpty) {
      functionTypeParameters ??= new List<TypeParameter>();
      functionTypeParameters.addAll(function.typeParameters);
      functionTypeParametersSet = functionTypeParameters.toSet();
    }

    List<Label> savedYieldPoints = yieldPoints;
    yieldPoints = locals.isSyncYieldingFrame ? <Label>[] : null;

    // Replace default values of optional parameters with constants,
    // as default value expressions could use local const variables which
    // are not available in bytecode.
    function.positionalParameters.forEach(_evaluateDefaultParameterValue);
    locals.sortedNamedParameters.forEach(_evaluateDefaultParameterValue);

    final int closureIndex = closures.length;
    objectTable.declareClosure(function, enclosingMember, closureIndex);
    final List<NameAndType> parameters = function.positionalParameters
        .followedBy(function.namedParameters)
        .map((v) => new NameAndType(objectTable.getNameHandle(null, v.name),
            objectTable.getHandle(v.type)))
        .toList();
    final ClosureDeclaration closure = new ClosureDeclaration(
        objectTable
            .getHandle(savedIsClosure ? parentFunction : enclosingMember),
        objectTable.getNameHandle(null, name),
        function.typeParameters
            .map((tp) => new NameAndType(
                objectTable.getNameHandle(null, tp.name),
                objectTable.getHandle(tp.bound)))
            .toList(),
        function.requiredParameterCount,
        function.namedParameters.length,
        parameters,
        objectTable.getHandle(function.returnType));
    closures.add(closure);

    final int closureFunctionIndex = cp.addClosureFunction(closureIndex);

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
    _checkArguments(function);

    // TODO(alexmarkov): support --causal_async_stacks.

    _generateNode(function.body);

    // BytecodeAssembler eliminates this bytecode if it is unreachable.
    asm.emitPushNull();
    _genReturnTOS();

    if (locals.isSyncYieldingFrame) {
      _genSyncYieldingEpilogue(
          function, continuationSwitchLabel, continuationSwitchVar);
    }

    cp.addEndClosureFunctionScope();

    if (function.typeParameters.isNotEmpty) {
      functionTypeParameters.length -= function.typeParameters.length;
      functionTypeParametersSet = functionTypeParameters.toSet();
    }

    enclosingFunction = parentFunction;
    parentFunction = savedParentFunction;
    isClosure = savedIsClosure;
    currentLoopDepth = savedLoopDepth;

    locals.leaveScope();

    closure.bytecode = new ClosureBytecode(
        asm.bytecode, asm.exceptionsTable, asm.sourcePositions);

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
    asm.emitJumpIfNeStrict(continuationLabel);

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
        asm.emitJumpIfEqStrict(yieldPoints[i]);
      } else {
        asm.emitJump(yieldPoints[i]);
      }
    }
  }

  void _genAllocateClosureInstance(
      TreeNode node, int closureFunctionIndex, FunctionNode function) {
    // TODO(alexmarkov): Consider adding a bytecode to allocate closure.

    assert(closureClass.typeParameters.isEmpty);
    asm.emitAllocate(cp.addClass(closureClass));

    final int temp = locals.tempIndexInFrame(node);
    asm.emitStoreLocal(temp);

    // TODO(alexmarkov): We need to fill _instantiator_type_arguments field
    // only if function signature uses instantiator type arguments.
    asm.emitPush(temp);
    _genPushInstantiatorTypeArguments();
    asm.emitStoreFieldTOS(
        cp.addInstanceField(closureInstantiatorTypeArguments));

    asm.emitPush(temp);
    _genPushFunctionTypeArguments();
    asm.emitStoreFieldTOS(cp.addInstanceField(closureFunctionTypeArguments));

    asm.emitPush(temp);
    asm.emitPushConstant(cp.addEmptyTypeArguments());
    asm.emitStoreFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));

    asm.emitPush(temp);
    asm.emitPushConstant(closureFunctionIndex);
    asm.emitStoreFieldTOS(cp.addInstanceField(closureFunction));

    asm.emitPush(temp);
    asm.emitPush(locals.contextVarIndexInFrame);
    asm.emitStoreFieldTOS(cp.addInstanceField(closureContext));
  }

  void _genClosure(TreeNode node, String name, FunctionNode function) {
    final int closureFunctionIndex = _genClosureBytecode(node, name, function);
    _genAllocateClosureInstance(node, closureFunctionIndex, function);
  }

  void _allocateContextIfNeeded() {
    final int contextSize = locals.currentContextSize;
    if (contextSize > 0) {
      asm.emitAllocateContext(locals.currentContextId, contextSize);

      if (locals.currentContextLevel > 0) {
        _genDupTOS(locals.scratchVarIndexInFrame);
        asm.emitPush(locals.contextVarIndexInFrame);
        asm.emitStoreContextParent();
      }

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
      asm.emitLoadContextParent();
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

  /// Appends chained [FinallyBlock]s to each try-finally in the given
  /// list [tryFinallyBlocks] (ordered from inner to outer).
  /// [continuation] is invoked to generate control transfer code following
  /// the last finally block.
  void _addFinallyBlocks(
      List<TryFinally> tryFinallyBlocks, GenerateContinuation continuation) {
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

  /// Generates non-local transfer from inner node [from] into the outer
  /// node, executing finally blocks on the way out. [to] can be null,
  /// in such case all enclosing finally blocks are executed.
  /// [continuation] is invoked to generate control transfer code following
  /// the last finally block.
  void _generateNonLocalControlTransfer(
      TreeNode from, TreeNode to, GenerateContinuation continuation) {
    List<TryFinally> tryFinallyBlocks = _getEnclosingTryFinallyBlocks(from, to);
    _addFinallyBlocks(tryFinallyBlocks, continuation);
  }

  // For certain expressions wrapped into ExpressionStatement we can
  // omit pushing result on the stack.
  bool isExpressionWithoutResult(Expression expr) =>
      expr.parent is ExpressionStatement &&
      (expr is VariableSet ||
          expr is PropertySet ||
          expr is StaticSet ||
          expr is SuperPropertySet ||
          expr is DirectPropertySet);

  void _createArgumentsArray(int temp, List<DartType> typeArgs,
      List<Expression> args, bool storeLastArgumentToTemp) {
    final int totalCount = (typeArgs.isNotEmpty ? 1 : 0) + args.length;

    _genTypeArguments([const DynamicType()]);
    _genPushInt(totalCount);
    asm.emitCreateArrayTOS();

    asm.emitStoreLocal(temp);

    int index = 0;
    if (typeArgs.isNotEmpty) {
      asm.emitPush(temp);
      _genPushInt(index++);
      _genTypeArguments(typeArgs);
      asm.emitStoreIndexedTOS();
    }

    for (Expression arg in args) {
      asm.emitPush(temp);
      _genPushInt(index++);
      _generateNode(arg);
      if (storeLastArgumentToTemp && index == totalCount) {
        // Arguments array in 'temp' is replaced with the last argument
        // in order to return result of RHS value in case of setter.
        asm.emitStoreLocal(temp);
      }
      asm.emitStoreIndexedTOS();
    }
  }

  void _genNoSuchMethodForSuperCall(String name, int temp, int argDescCpIndex,
      List<DartType> typeArgs, List<Expression> args,
      {bool storeLastArgumentToTemp: false}) {
    // Receiver for noSuchMethod() call.
    _genPushReceiver();

    // Argument 0 for _allocateInvocationMirror(): function name.
    asm.emitPushConstant(cp.addString(name));

    // Argument 1 for _allocateInvocationMirror(): arguments descriptor.
    asm.emitPushConstant(argDescCpIndex);

    // Argument 2 for _allocateInvocationMirror(): list of arguments.
    _createArgumentsArray(temp, typeArgs, args, storeLastArgumentToTemp);

    // Argument 3 for _allocateInvocationMirror(): isSuperInvocation flag.
    asm.emitPushTrue();

    _genStaticCall(allocateInvocationMirror, cp.addArgDesc(4), 4);

    final Member target = hierarchy.getDispatchTarget(
        enclosingClass.superclass, new Name('noSuchMethod'));
    assert(target != null);
    _genStaticCall(target, cp.addArgDesc(2), 2);
  }

  @override
  defaultTreeNode(Node node) => throw new UnsupportedOperationError(
      'Unsupported node ${node.runtimeType}');

  @override
  visitAsExpression(AsExpression node) {
    _generateNode(node.operand);

    final type = node.type;
    if (typeEnvironment.isTop(type)) {
      return;
    }

    _genAssertAssignable(type, name: node.isTypeError ? '' : symbolForTypeCast);
  }

  @override
  visitBoolLiteral(BoolLiteral node) {
    _genPushBool(node.value);
  }

  @override
  visitIntLiteral(IntLiteral node) {
    _genPushInt(node.value);
  }

  @override
  visitDoubleLiteral(DoubleLiteral node) {
    final cpIndex = cp.addDouble(node.value);
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitConditionalExpression(ConditionalExpression node) {
    final Label otherwisePart = new Label();
    final Label done = new Label();
    final int temp = locals.tempIndexInFrame(node);

    _genConditionAndJumpIf(node.condition, false, otherwisePart);

    _generateNode(node.then);
    asm.emitPopLocal(temp);
    asm.emitJump(done);

    asm.bind(otherwisePart);
    _generateNode(node.otherwise);
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
    final classIndex = cp.addClass(constructedClass);

    if (hasInstantiatorTypeArguments(constructedClass)) {
      _genTypeArguments(node.arguments.types,
          instantiatingClass: constructedClass);
      asm.emitPushConstant(cp.addClass(constructedClass));
      asm.emitAllocateT();
    } else {
      assert(node.arguments.types.isEmpty);
      asm.emitAllocate(classIndex);
    }

    _genDupTOS(locals.tempIndexInFrame(node));

    // Remove type arguments as they are only passed to instance allocation,
    // and not passed to a constructor.
    final args =
        new Arguments(node.arguments.positional, named: node.arguments.named)
          ..parent = node;
    _genArguments(null, args);
    _genStaticCallWithArgs(node.target, args, hasReceiver: true);
    asm.emitDrop1();
  }

  @override
  visitDirectMethodInvocation(DirectMethodInvocation node) {
    final args = node.arguments;
    _genArguments(node.receiver, args);
    final target = node.target;
    if (target is Procedure && !target.isGetter && !target.isSetter) {
      _genStaticCallWithArgs(target, args, hasReceiver: true);
    } else {
      throw new UnsupportedOperationError(
          'Unsupported DirectMethodInvocation with target ${target.runtimeType} $target');
    }
  }

  @override
  visitDirectPropertyGet(DirectPropertyGet node) {
    _generateNode(node.receiver);
    final target = node.target;
    if (target is Field || (target is Procedure && target.isGetter)) {
      _genStaticCall(target, cp.addArgDesc(1), 1, isGet: true);
    } else {
      throw new UnsupportedOperationError(
          'Unsupported DirectPropertyGet with ${target.runtimeType} $target');
    }
  }

  @override
  visitDirectPropertySet(DirectPropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    _generateNode(node.receiver);
    _generateNode(node.value);

    if (hasResult) {
      asm.emitStoreLocal(temp);
    }

    final target = node.target;
    assert(target is Field || (target is Procedure && target.isSetter));
    _genStaticCall(target, cp.addArgDesc(2), 2, isSet: true);
    asm.emitDrop1();

    if (hasResult) {
      asm.emitPush(temp);
    }
  }

  @override
  visitFunctionExpression(FunctionExpression node) {
    _genClosure(node, '<anonymous closure>', node.function);
  }

  @override
  visitInstantiation(Instantiation node) {
    final int oldClosure = locals.tempIndexInFrame(node, tempIndex: 0);
    final int newClosure = locals.tempIndexInFrame(node, tempIndex: 1);
    final int typeArguments = locals.tempIndexInFrame(node, tempIndex: 2);

    _generateNode(node.expression);
    asm.emitStoreLocal(oldClosure);

    _genTypeArguments(node.typeArguments);
    asm.emitStoreLocal(typeArguments);

    _genStaticCall(boundsCheckForPartialInstantiation, cp.addArgDesc(2), 2);
    asm.emitDrop1();

    assert(closureClass.typeParameters.isEmpty);
    asm.emitAllocate(cp.addClass(closureClass));
    asm.emitStoreLocal(newClosure);

    asm.emitPush(typeArguments);
    asm.emitStoreFieldTOS(cp.addInstanceField(closureDelayedTypeArguments));

    // Copy the rest of the fields from old closure to a new closure.
    final fieldsToCopy = <Field>[
      closureInstantiatorTypeArguments,
      closureFunctionTypeArguments,
      closureFunction,
      closureContext,
    ];

    for (Field field in fieldsToCopy) {
      final fieldOffsetCpIndex = cp.addInstanceField(field);
      asm.emitPush(newClosure);
      asm.emitPush(oldClosure);
      asm.emitLoadFieldTOS(fieldOffsetCpIndex);
      asm.emitStoreFieldTOS(fieldOffsetCpIndex);
    }

    asm.emitPush(newClosure);
  }

  @override
  visitIsExpression(IsExpression node) {
    _generateNode(node.operand);
    _genInstanceOf(node.type);
  }

  @override
  visitLet(Let node) {
    _enterScope(node);
    _generateNode(node.variable);
    _generateNode(node.body);
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
      _generateNode(node.expressions[i]);
      asm.emitStoreIndexedTOS();
    }

    // List._fromLiteral is a factory constructor.
    // Type arguments passed to a factory constructor are counted as a normal
    // argument and not counted in number of type arguments.
    assert(listFromLiteral.isFactory);
    _genStaticCall(listFromLiteral, cp.addArgDesc(2, numTypeArgs: 0), 2);
  }

  @override
  visitLogicalExpression(LogicalExpression node) {
    assert(node.operator == '||' || node.operator == '&&');

    final Label shortCircuit = new Label();
    final Label done = new Label();
    final int temp = locals.tempIndexInFrame(node);
    final isOR = (node.operator == '||');

    _genConditionAndJumpIf(node.left, isOR, shortCircuit);

    bool negated = _genCondition(node.right);
    if (negated) {
      asm.emitBooleanNegateTOS();
    }
    asm.emitPopLocal(temp);
    asm.emitJump(done);

    asm.bind(shortCircuit);
    _genPushBool(isOR);
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
      asm.emitPushConstant(cp.addList(const DynamicType(), const []));
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
        _generateNode(node.entries[i].key);
        asm.emitStoreIndexedTOS();
        // value
        asm.emitPush(temp);
        _genPushInt(i * 2 + 1);
        _generateNode(node.entries[i].value);
        asm.emitStoreIndexedTOS();
      }
    }

    // Map._fromLiteral is a factory constructor.
    // Type arguments passed to a factory constructor are counted as a normal
    // argument and not counted in number of type arguments.
    assert(mapFromLiteral.isFactory);
    _genStaticCall(mapFromLiteral, cp.addArgDesc(2, numTypeArgs: 0), 2);
  }

  void _genMethodInvocationUsingSpecializedBytecode(
      Opcode opcode, MethodInvocation node) {
    switch (opcode) {
      case Opcode.kEqualsNull:
        if (node.receiver is NullLiteral) {
          _generateNode(node.arguments.positional.single);
        } else {
          _generateNode(node.receiver);
        }
        break;

      case Opcode.kNegateInt:
        _generateNode(node.receiver);
        break;

      case Opcode.kAddInt:
      case Opcode.kSubInt:
      case Opcode.kMulInt:
      case Opcode.kTruncDivInt:
      case Opcode.kModInt:
      case Opcode.kBitAndInt:
      case Opcode.kBitOrInt:
      case Opcode.kBitXorInt:
      case Opcode.kShlInt:
      case Opcode.kShrInt:
      case Opcode.kCompareIntEq:
      case Opcode.kCompareIntGt:
      case Opcode.kCompareIntLt:
      case Opcode.kCompareIntGe:
      case Opcode.kCompareIntLe:
        _generateNode(node.receiver);
        _generateNode(node.arguments.positional.single);
        break;

      default:
        throw 'Unexpected specialized bytecode $opcode';
    }

    asm.emitBytecode0(opcode);
  }

  void _genInstanceCall(int totalArgCount, int icdataCpIndex, bool isDynamic) {
    if (isDynamic) {
      asm.emitDynamicCall(totalArgCount, icdataCpIndex);
    } else {
      asm.emitInterfaceCall(totalArgCount, icdataCpIndex);
    }
  }

  @override
  visitMethodInvocation(MethodInvocation node) {
    final Opcode opcode = recognizedMethods.specializedBytecodeFor(node);
    if (opcode != null) {
      _genMethodInvocationUsingSpecializedBytecode(opcode, node);
      return;
    }
    final args = node.arguments;
    final isDynamic = node.interfaceTarget == null;
    _genArguments(node.receiver, args);
    final argDescIndex = cp.addArgDescByArguments(args, hasReceiver: true);
    final icdataIndex = cp.addInstanceCall(
        InvocationKind.method, node.name, argDescIndex,
        isDynamic: isDynamic);
    final totalArgCount = args.positional.length +
        args.named.length +
        1 /* receiver */ +
        (args.types.isNotEmpty ? 1 : 0) /* type arguments */;
    _genInstanceCall(totalArgCount, icdataIndex, isDynamic);
  }

  @override
  visitPropertyGet(PropertyGet node) {
    _generateNode(node.receiver);
    final isDynamic = node.interfaceTarget == null;
    final argDescIndex = cp.addArgDesc(1);
    final icdataIndex = cp.addInstanceCall(
        InvocationKind.getter, node.name, argDescIndex,
        isDynamic: isDynamic);
    _genInstanceCall(1, icdataIndex, isDynamic);
  }

  @override
  visitPropertySet(PropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    _generateNode(node.receiver);
    _generateNode(node.value);

    if (hasResult) {
      asm.emitStoreLocal(temp);
    }

    final isDynamic = node.interfaceTarget == null;
    final argDescIndex = cp.addArgDesc(2);
    final icdataIndex = cp.addInstanceCall(
        InvocationKind.setter, node.name, argDescIndex,
        isDynamic: isDynamic);
    _genInstanceCall(2, icdataIndex, isDynamic);
    asm.emitDrop1();

    if (hasResult) {
      asm.emitPush(temp);
    }
  }

  @override
  visitSuperMethodInvocation(SuperMethodInvocation node) {
    final args = node.arguments;
    final Member target =
        hierarchy.getDispatchTarget(enclosingClass.superclass, node.name);
    if (target == null) {
      final int temp = locals.tempIndexInFrame(node);
      _genNoSuchMethodForSuperCall(
          node.name.name,
          temp,
          cp.addArgDescByArguments(args, hasReceiver: true),
          args.types,
          <Expression>[new ThisExpression()]
            ..addAll(args.positional)
            ..addAll(args.named.map((x) => x.value)));
      return;
    }
    _genArguments(new ThisExpression(), args);
    _genStaticCallWithArgs(target, args, hasReceiver: true);
  }

  @override
  visitSuperPropertyGet(SuperPropertyGet node) {
    final Member target =
        hierarchy.getDispatchTarget(enclosingClass.superclass, node.name);
    if (target == null) {
      final int temp = locals.tempIndexInFrame(node);
      _genNoSuchMethodForSuperCall(node.name.name, temp, cp.addArgDesc(1), [],
          <Expression>[new ThisExpression()]);
      return;
    }
    _genPushReceiver();
    _genStaticCall(target, cp.addArgDesc(1), 1, isGet: true);
  }

  @override
  visitSuperPropertySet(SuperPropertySet node) {
    final int temp = locals.tempIndexInFrame(node);
    final bool hasResult = !isExpressionWithoutResult(node);

    final Member target = hierarchy
        .getDispatchTarget(enclosingClass.superclass, node.name, setter: true);
    if (target == null) {
      _genNoSuchMethodForSuperCall(node.name.name, temp, cp.addArgDesc(2), [],
          <Expression>[new ThisExpression(), node.value],
          storeLastArgumentToTemp: hasResult);
    } else {
      _genPushReceiver();
      _generateNode(node.value);

      if (hasResult) {
        asm.emitStoreLocal(temp);
      }

      assert(target is Field || (target is Procedure && target.isSetter));
      _genStaticCall(target, cp.addArgDesc(2), 2, isSet: true);
    }

    asm.emitDrop1();

    if (hasResult) {
      asm.emitPush(temp);
    }
  }

  @override
  visitNot(Not node) {
    bool negated = _genCondition(node.operand);
    if (!negated) {
      asm.emitBooleanNegateTOS();
    }
  }

  @override
  visitNullLiteral(NullLiteral node) {
    asm.emitPushNull();
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
      (field.initializer is DoubleLiteral) ||
      (field.initializer is NullLiteral);

  @override
  visitStaticGet(StaticGet node) {
    final target = node.target;
    if (target is Field) {
      if (target.isConst) {
        _genPushConstExpr(target.initializer);
      } else if (_hasTrivialInitializer(target)) {
        final fieldIndex = cp.addStaticField(target);
        asm.emitPushConstant(
            fieldIndex); // TODO(alexmarkov): do we really need this?
        asm.emitPushStatic(fieldIndex);
      } else {
        _genStaticCall(target, cp.addArgDesc(0), 0, isGet: true);
      }
    } else if (target is Procedure) {
      if (target.isGetter) {
        _genStaticCall(target, cp.addArgDesc(0), 0, isGet: true);
      } else {
        final tearOffIndex = cp.addTearOff(target);
        asm.emitPushConstant(tearOffIndex);
      }
    } else {
      throw 'Unexpected target for StaticGet: ${target.runtimeType} $target';
    }
  }

  @override
  visitStaticInvocation(StaticInvocation node) {
    if (node.isConst) {
      _genPushConstExpr(node);
      return;
    }
    Arguments args = node.arguments;
    final target = node.target;
    if (target == unsafeCast) {
      // The result of the unsafeCast() intrinsic method is its sole argument,
      // without any additional checks or type casts.
      assert(args.named.isEmpty);
      _generateNode(args.positional.single);
      return;
    }
    if (target.isFactory) {
      final constructedClass = target.enclosingClass;
      if (hasInstantiatorTypeArguments(constructedClass)) {
        _genTypeArguments(args.types, instantiatingClass: constructedClass);
      } else {
        assert(args.types.isEmpty);
        // VM needs type arguments for every invocation of a factory
        // constructor. TODO(alexmarkov): Clean this up.
        asm.emitPushNull();
      }
      args =
          new Arguments(node.arguments.positional, named: node.arguments.named)
            ..parent = node;
    }
    _genArguments(null, args);
    _genStaticCallWithArgs(target, args, isFactory: target.isFactory);
  }

  @override
  visitStaticSet(StaticSet node) {
    final bool hasResult = !isExpressionWithoutResult(node);

    _generateNode(node.value);

    if (hasResult) {
      _genDupTOS(locals.tempIndexInFrame(node));
    }

    final target = node.target;
    if (target is Field) {
      int cpIndex = cp.addStaticField(target);
      asm.emitStoreStaticTOS(cpIndex);
    } else {
      _genStaticCall(target, cp.addArgDesc(1), 1, isSet: true);
      asm.emitDrop1();
    }
  }

  @override
  visitStringConcatenation(StringConcatenation node) {
    if (node.expressions.length == 1) {
      _generateNode(node.expressions.single);
      _genStaticCall(interpolateSingle, cp.addArgDesc(1), 1);
    } else {
      asm.emitPushNull();
      _genPushInt(node.expressions.length);
      asm.emitCreateArrayTOS();

      final int temp = locals.tempIndexInFrame(node);
      asm.emitStoreLocal(temp);

      for (int i = 0; i < node.expressions.length; i++) {
        asm.emitPush(temp);
        _genPushInt(i);
        _generateNode(node.expressions[i]);
        asm.emitStoreIndexedTOS();
      }

      _genStaticCall(interpolate, cp.addArgDesc(1), 1);
    }
  }

  @override
  visitStringLiteral(StringLiteral node) {
    final cpIndex = cp.addString(node.value);
    asm.emitPushConstant(cpIndex);
  }

  @override
  visitSymbolLiteral(SymbolLiteral node) {
    _genPushConstExpr(node);
  }

  @override
  visitThisExpression(ThisExpression node) {
    _genPushReceiver();
  }

  @override
  visitThrow(Throw node) {
    _generateNode(node.expression);
    asm.emitThrow(0);
  }

  @override
  visitTypeLiteral(TypeLiteral node) {
    final DartType type = node.type;
    final int typeCPIndex = cp.addType(type);
    if (!hasFreeTypeParameters([type])) {
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
    final bool hasResult = !isExpressionWithoutResult(node);

    if (locals.isCaptured(v)) {
      _genPushContextForVariable(v);

      _generateNode(node.value);

      final int temp = locals.tempIndexInFrame(node);
      if (hasResult) {
        asm.emitStoreLocal(temp);
      }

      _genStoreVar(v);

      if (hasResult) {
        asm.emitPush(temp);
      }
    } else {
      _generateNode(node.value);

      final int localIndex = locals.getVarIndexInFrame(v);
      if (hasResult) {
        asm.emitStoreLocal(localIndex);
      } else {
        asm.emitPopLocal(localIndex);
      }
    }
  }

  void _genFutureNull() {
    asm.emitPushNull();
    _genStaticCall(futureValue, cp.addArgDesc(1), 1);
  }

  @override
  visitLoadLibrary(LoadLibrary node) {
    _genFutureNull();
  }

  @override
  visitCheckLibraryIsLoaded(CheckLibraryIsLoaded node) {
    _genFutureNull();
  }

  @override
  visitAssertStatement(AssertStatement node) {
    final Label done = new Label();
    asm.emitJumpIfNoAsserts(done);

    _genConditionAndJumpIf(node.condition, true, done);

    _genPushInt(omitAssertSourcePositions ? 0 : node.conditionStartOffset);
    _genPushInt(omitAssertSourcePositions ? 0 : node.conditionEndOffset);

    if (node.message != null) {
      _generateNode(node.message);
    } else {
      asm.emitPushNull();
    }

    _genStaticCall(throwNewAssertionError, cp.addArgDesc(3), 3);
    asm.emitDrop1();

    asm.bind(done);
  }

  @override
  visitBlock(Block node) {
    _enterScope(node);
    _generateNodeList(node.statements);
    _leaveScope();
  }

  @override
  visitAssertBlock(AssertBlock node) {
    final Label done = new Label();
    asm.emitJumpIfNoAsserts(done);

    _enterScope(node);
    _generateNodeList(node.statements);
    _leaveScope();

    asm.bind(done);
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
    if (asm.isUnreachable) {
      // Bail out before binding a label which allows backward jumps,
      // as it is not handled by local unreachable code elimination.
      return;
    }

    final Label join = new Label(allowsBackwardJumps: true);
    asm.bind(join);

    asm.emitCheckStack(++currentLoopDepth);

    _generateNode(node.body);

    _genConditionAndJumpIf(node.condition, true, join);

    --currentLoopDepth;
  }

  @override
  visitEmptyStatement(EmptyStatement node) {
    // no-op
  }

  @override
  visitExpressionStatement(ExpressionStatement node) {
    final expr = node.expression;
    _generateNode(expr);
    if (!isExpressionWithoutResult(expr)) {
      asm.emitDrop1();
    }
  }

  @override
  visitForInStatement(ForInStatement node) {
    _generateNode(node.iterable);

    const kIterator = 'iterator'; // Iterable.iterator
    const kMoveNext = 'moveNext'; // Iterator.moveNext
    const kCurrent = 'current'; // Iterator.current

    // Front-end inserts implicit cast (type check) which ensures that
    // result of iterable expression is Iterable<dynamic>.
    asm.emitInterfaceCall(
        1,
        cp.addInterfaceCall(
            InvocationKind.getter, new Name(kIterator), cp.addArgDesc(1)));

    final iteratorTemp = locals.tempIndexInFrame(node);
    asm.emitPopLocal(iteratorTemp);

    final capturedIteratorVar = locals.capturedIteratorVar(node);
    if (capturedIteratorVar != null) {
      _genPushContextForVariable(capturedIteratorVar);
      asm.emitPush(iteratorTemp);
      _genStoreVar(capturedIteratorVar);
    }

    if (asm.isUnreachable) {
      // Bail out before binding a label which allows backward jumps,
      // as it is not handled by local unreachable code elimination.
      return;
    }

    final Label done = new Label();
    final Label join = new Label(allowsBackwardJumps: true);

    asm.bind(join);
    asm.emitCheckStack(++currentLoopDepth);

    if (capturedIteratorVar != null) {
      _genLoadVar(capturedIteratorVar);
      asm.emitStoreLocal(iteratorTemp);
    } else {
      asm.emitPush(iteratorTemp);
    }

    asm.emitInterfaceCall(
        1,
        cp.addInterfaceCall(
            InvocationKind.method, new Name(kMoveNext), cp.addArgDesc(1)));
    _genJumpIfFalse(/* negated = */ false, done);

    _enterScope(node);

    _genPushContextIfCaptured(node.variable);

    asm.emitPush(iteratorTemp);
    asm.emitInterfaceCall(
        1,
        cp.addInterfaceCall(
            InvocationKind.getter, new Name(kCurrent), cp.addArgDesc(1)));

    _genStoreVar(node.variable);

    _generateNode(node.body);

    _leaveScope();
    asm.emitJump(join);

    asm.bind(done);
    --currentLoopDepth;
  }

  @override
  visitForStatement(ForStatement node) {
    _enterScope(node);
    try {
      _generateNodeList(node.variables);

      if (asm.isUnreachable) {
        // Bail out before binding a label which allows backward jumps,
        // as it is not handled by local unreachable code elimination.
        return;
      }

      final Label done = new Label();
      final Label join = new Label(allowsBackwardJumps: true);
      asm.bind(join);

      asm.emitCheckStack(++currentLoopDepth);

      if (node.condition != null) {
        _genConditionAndJumpIf(node.condition, false, done);
      }

      _generateNode(node.body);

      if (locals.currentContextSize > 0) {
        asm.emitPush(locals.contextVarIndexInFrame);
        asm.emitCloneContext(
            locals.currentContextId, locals.currentContextSize);
        asm.emitPopLocal(locals.contextVarIndexInFrame);
      }

      for (var update in node.updates) {
        _generateNode(update);
        asm.emitDrop1();
      }

      asm.emitJump(join);

      asm.bind(done);
      --currentLoopDepth;
    } finally {
      _leaveScope();
    }
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

    _genConditionAndJumpIf(node.condition, false, otherwisePart);

    _generateNode(node.then);

    if (node.otherwise != null) {
      final Label done = new Label();
      asm.emitJump(done);
      asm.bind(otherwisePart);
      _generateNode(node.otherwise);
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
    _generateNode(node.body);
    asm.bind(label);
    labeledStatements.remove(node);
    contextLevels.remove(node);
  }

  @override
  visitReturnStatement(ReturnStatement node) {
    final expr = node.expression ?? new NullLiteral();

    final List<TryFinally> tryFinallyBlocks =
        _getEnclosingTryFinallyBlocks(node, null);
    if (tryFinallyBlocks.isEmpty) {
      _generateNode(expr);
      asm.emitReturnTOS();
    } else {
      if (expr is BasicLiteral) {
        _addFinallyBlocks(tryFinallyBlocks, () {
          _generateNode(expr);
          asm.emitReturnTOS();
        });
      } else {
        // Keep return value in a variable as try-catch statements
        // inside finally can zap expression stack.
        _generateNode(node.expression);
        asm.emitPopLocal(locals.returnVarIndexInFrame);

        _addFinallyBlocks(tryFinallyBlocks, () {
          asm.emitPush(locals.returnVarIndexInFrame);
          asm.emitReturnTOS();
        });
      }
    }
  }

  @override
  visitSwitchStatement(SwitchStatement node) {
    contextLevels[node] = locals.currentContextLevel;

    _generateNode(node.expression);

    if (asm.isUnreachable) {
      // Bail out before binding labels which allow backward jumps,
      // as they are not handled by local unreachable code elimination.
      return;
    }

    final int temp = locals.tempIndexInFrame(node);
    asm.emitPopLocal(temp);

    final Label done = new Label();
    final List<Label> caseLabels = new List<Label>.generate(
        node.cases.length, (_) => new Label(allowsBackwardJumps: true));
    final equalsArgDesc = cp.addArgDesc(2);

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
          asm.emitInterfaceCall(
              2,
              cp.addInterfaceCall(
                  InvocationKind.method, new Name('=='), equalsArgDesc));
          _genJumpIfTrue(/* negated = */ false, caseLabel);
        }
      }
    }

    asm.emitJump(defaultLabel);

    for (int i = 0; i < node.cases.length; i++) {
      final SwitchCase switchCase = node.cases[i];
      final Label caseLabel = caseLabels[i];

      asm.bind(caseLabel);
      _generateNode(switchCase.body);

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
      asm.emitLoadFieldTOS(cp.addInstanceField(closureContext));
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

    // Exception handlers are reachable although there are no labels or jumps.
    asm.isUnreachable = false;

    asm.emitSetFrame(locals.frameSize);

    _restoreContextForTryBlock(node);

    asm.emitMoveSpecial(SpecialIndex.exception, _exceptionVar(node));
    asm.emitMoveSpecial(SpecialIndex.stackTrace, _stackTraceVar(node));

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
    if (asm.isUnreachable) {
      return;
    }

    final Label done = new Label();

    final TryBlock tryBlock = _startTryBlock(node);
    tryBlock.isSynthetic = node.isSynthetic;
    tryCatches[node] = tryBlock; // Used by rethrow.

    _generateNode(node.body);
    asm.emitJump(done);

    _endTryBlock(node, tryBlock);

    final int exception = _exceptionVar(node);
    final int stackTrace = _stackTraceVar(node);

    bool hasCatchAll = false;

    for (Catch catchClause in node.catches) {
      tryBlock.types.add(cp.addType(catchClause.guard));

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

      _generateNode(catchClause.body);

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
    if (asm.isUnreachable) {
      return;
    }

    final TryBlock tryBlock = _startTryBlock(node);
    finallyBlocks[node] = <FinallyBlock>[];

    _generateNode(node.body);

    if (!asm.isUnreachable) {
      final normalContinuation = new FinallyBlock(() {
        /* do nothing (fall through) */
      });
      finallyBlocks[node].add(normalContinuation);
      asm.emitJump(normalContinuation.entry);
    }

    _endTryBlock(node, tryBlock);

    tryBlock.types.add(cp.addType(const DynamicType()));

    _generateNode(node.finalizer);

    tryBlock.needsStackTrace = true; // For rethrowing.
    _genRethrow(node);

    for (var finallyBlock in finallyBlocks[node]) {
      asm.bind(finallyBlock.entry);
      _restoreContextForTryBlock(node);
      _generateNode(node.finalizer);
      finallyBlock.generateContinuation();
    }

    finallyBlocks.remove(node);
  }

  @override
  visitVariableDeclaration(VariableDeclaration node) {
    if (node.isConst) {
      final Constant constant = _evaluateConstantExpression(node.initializer);
      constantEvaluator.env.addVariableValue(node, constant);
    } else {
      final bool isCaptured = locals.isCaptured(node);
      if (isCaptured) {
        _genPushContextForVariable(node);
      }
      if (node.initializer != null) {
        _generateNode(node.initializer);
      } else {
        asm.emitPushNull();
      }
      _genStoreVar(node);
    }
  }

  @override
  visitWhileStatement(WhileStatement node) {
    if (asm.isUnreachable) {
      // Bail out before binding a label which allows backward jumps,
      // as it is not handled by local unreachable code elimination.
      return;
    }

    final Label done = new Label();
    final Label join = new Label(allowsBackwardJumps: true);
    asm.bind(join);

    asm.emitCheckStack(++currentLoopDepth);

    _genConditionAndJumpIf(node.condition, false, done);

    _generateNode(node.body);

    asm.emitJump(join);
    --currentLoopDepth;

    asm.bind(done);
  }

  @override
  visitYieldStatement(YieldStatement node) {
    if (!node.isNative) {
      throw 'YieldStatement must be desugared: $node';
    }

    if (asm.isUnreachable) {
      return;
    }

    // 0 is reserved for normal entry, yield points are counted from 1.
    final int yieldIndex = yieldPoints.length + 1;
    final Label continuationLabel = new Label(allowsBackwardJumps: true);
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
    _generateNode(node.expression);
    asm.emitReturnTOS();

    asm.bind(continuationLabel);

    if (parentFunction.dartAsyncMarker == AsyncMarker.Async ||
        parentFunction.dartAsyncMarker == AsyncMarker.AsyncStar) {
      final int exceptionParam = locals.asyncExceptionParamIndexInFrame;
      final int stackTraceParam = locals.asyncStackTraceParamIndexInFrame;

      // if (:exception != null) rethrow (:exception, :stack_trace)
      final Label cont = new Label();
      asm.emitPush(exceptionParam);
      asm.emitJumpIfNull(cont);

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

  @override
  visitLocalInitializer(LocalInitializer node) {
    _generateNode(node.variable);
  }

  @override
  visitAssertInitializer(AssertInitializer node) {
    _generateNode(node.statement);
  }

  @override
  visitConstantExpression(ConstantExpression node) {
    _genPushConstExpr(node);
  }
}

class ConstantEmitter extends ConstantVisitor<int> {
  final ConstantPool cp;

  ConstantEmitter(this.cp);

  @override
  int defaultConstant(Constant node) => throw new UnsupportedOperationError(
      'Unsupported constant node ${node.runtimeType}');

  @override
  int visitNullConstant(NullConstant node) => cp.addNull();

  @override
  int visitBoolConstant(BoolConstant node) => cp.addBool(node.value);

  @override
  int visitIntConstant(IntConstant node) => cp.addInt(node.value);

  @override
  int visitDoubleConstant(DoubleConstant node) => cp.addDouble(node.value);

  @override
  int visitStringConstant(StringConstant node) => cp.addString(node.value);

  @override
  int visitSymbolConstant(SymbolConstant node) =>
      cp.addSymbol(node.libraryReference?.asLibrary, node.name);

  @override
  int visitListConstant(ListConstant node) => cp.addList(node.typeArgument,
      new List<int>.from(node.entries.map((Constant c) => c.accept(this))));

  @override
  int visitInstanceConstant(InstanceConstant node) => cp.addInstance(
      node.classNode,
      hasInstantiatorTypeArguments(node.classNode)
          ? cp.addTypeArgumentsForInstanceAllocation(
              node.classNode, node.typeArguments)
          : cp.addNull(),
      node.fieldValues.map<Field, int>((Reference fieldRef, Constant value) =>
          new MapEntry(fieldRef.asField, value.accept(this))));

  @override
  int visitTearOffConstant(TearOffConstant node) =>
      cp.addTearOff(node.procedure);

  @override
  int visitTypeLiteralConstant(TypeLiteralConstant node) =>
      cp.addType(node.type);

  @override
  int visitPartialInstantiationConstant(PartialInstantiationConstant node) =>
      cp.addPartialTearOffInstantiation(
          node.tearOffConstant.accept(this), cp.addTypeArguments(node.types));
}

class UnsupportedOperationError {
  final String message;
  UnsupportedOperationError(this.message);

  @override
  String toString() => message;
}

class FindFreeTypeParametersVisitor extends DartTypeVisitor<bool> {
  Set<TypeParameter> _declaredTypeParameters;

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
  bool visitTypeParameterType(TypeParameterType node) =>
      _declaredTypeParameters == null ||
      !_declaredTypeParameters.contains(node.parameter);

  @override
  bool visitInterfaceType(InterfaceType node) =>
      node.typeArguments.any((t) => t.accept(this));

  @override
  bool visitTypedefType(TypedefType node) =>
      node.typeArguments.any((t) => t.accept(this));

  @override
  bool visitFunctionType(FunctionType node) {
    if (node.typeParameters.isNotEmpty) {
      _declaredTypeParameters ??= new Set<TypeParameter>();
      _declaredTypeParameters.addAll(node.typeParameters);
    }

    final bool result = node.positionalParameters.any((t) => t.accept(this)) ||
        node.namedParameters.any((p) => p.type.accept(this)) ||
        node.returnType.accept(this);

    if (node.typeParameters.isNotEmpty) {
      _declaredTypeParameters.removeAll(node.typeParameters);
    }

    return result;
  }
}

typedef void GenerateContinuation();

class FinallyBlock {
  final Label entry = new Label();
  final GenerateContinuation generateContinuation;

  FinallyBlock(this.generateContinuation);
}

bool hasInstantiatorTypeArguments(Class c) {
  return c.typeParameters.isNotEmpty ||
      (c.superclass != null && hasInstantiatorTypeArguments(c.superclass));
}
