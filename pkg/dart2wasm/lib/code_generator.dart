// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show LinkedHashMap;

import 'package:dart2wasm/async.dart';
import 'package:dart2wasm/class_info.dart';
import 'package:dart2wasm/closures.dart';
import 'package:dart2wasm/dispatch_table.dart';
import 'package:dart2wasm/dynamic_forwarders.dart';
import 'package:dart2wasm/intrinsics.dart';
import 'package:dart2wasm/param_info.dart';
import 'package:dart2wasm/records.dart';
import 'package:dart2wasm/reference_extensions.dart';
import 'package:dart2wasm/sync_star.dart';
import 'package:dart2wasm/translator.dart';
import 'package:dart2wasm/types.dart';

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';

import 'package:wasm_builder/wasm_builder.dart' as w;

/// Main code generator for member bodies.
///
/// The [generate] method first collects all local functions and function
/// expressions in the body and then generates code for the body. Code for the
/// local functions and function expressions must be generated separately by
/// calling the [generateLambda] method on all lambdas in [closures].
///
/// A new [CodeGenerator] object must be created for each new member or lambda.
///
/// Every visitor method for an expression takes in the Wasm type that it is
/// expected to leave on the stack (or the special [voidMarker] to indicate that
/// it should leave nothing). It returns what it actually left on the stack. The
/// code generation for every expression or subexpression is done via the [wrap]
/// method, which emits appropriate conversion code if the produced type is not
/// a subtype of the expected type.
class CodeGenerator extends ExpressionVisitor1<w.ValueType, w.ValueType>
    with ExpressionVisitor1DefaultMixin<w.ValueType, w.ValueType>
    implements InitializerVisitor<void>, StatementVisitor<void> {
  final Translator translator;
  w.FunctionBuilder function;
  final Reference reference;
  late final List<w.Local> paramLocals;
  final w.Label? returnLabel;

  late final Intrinsifier intrinsifier;
  late final StaticTypeContext typeContext;

  late final Closures closures;

  bool exceptionLocationPrinted = false;

  final Map<VariableDeclaration, w.Local> locals = {};
  w.Local? thisLocal;
  w.Local? preciseThisLocal;
  w.Local? returnValueLocal;
  final Map<TypeParameter, w.Local> typeLocals = {};

  // Maps a classes' fields to corresponding locals so that we can update the
  // local directly if a field has both a default value and a FieldInitializer.
  final Map<Field, w.Local> fieldLocals = {};

  /// Finalizers to run on `return`.
  final List<TryBlockFinalizer> returnFinalizers = [];

  /// Finalizers to run on a `break`. `breakFinalizers[L].last` (which should
  /// always be present) is the `br` target for the label `L` that will run the
  /// finalizers, or break out of the loop.
  final LinkedHashMap<LabeledStatement, List<w.Label>> breakFinalizers =
      LinkedHashMap();

  final List<w.Label> tryLabels = [];

  final Map<SwitchCase, w.Label> switchLabels = {};

  /// Maps a switch statement to the information used when doing a backward
  /// jump to one of the cases in the switch statement
  final Map<SwitchStatement, SwitchBackwardJumpInfo> switchBackwardJumpInfos =
      {};

  /// Create a code generator for a member or one of its lambdas.
  ///
  /// The [paramLocals] and [returnLabel] parameters can be used to generate
  /// code for an inlined function by specifying the locals containing the
  /// parameters (instead of the function inputs) and the label to jump to on
  /// return (instead of emitting a `return` instruction).
  CodeGenerator(this.translator, this.function, this.reference,
      {List<w.Local>? paramLocals, this.returnLabel}) {
    this.paramLocals = paramLocals ?? function.locals.toList();
    intrinsifier = Intrinsifier(this);
    typeContext = StaticTypeContext(member, translator.typeEnvironment);
  }

  /// Factory constructor for instantiating a code generator appropriate for
  /// generating code for the given function. This will either return a
  /// [CodeGenerator] or a [SyncStarCodeGenerator].
  factory CodeGenerator.forFunction(
      Translator translator,
      FunctionNode? functionNode,
      w.FunctionBuilder function,
      Reference reference) {
    bool isSyncStar = functionNode?.asyncMarker == AsyncMarker.SyncStar &&
        !reference.isTearOffReference;
    bool isAsync = functionNode?.asyncMarker == AsyncMarker.Async &&
        !reference.isTearOffReference;
    bool isTypeChecker = reference.isTypeCheckerReference;

    if (!isTypeChecker && isSyncStar) {
      return SyncStarCodeGenerator(translator, function, reference);
    } else if (!isTypeChecker && isAsync) {
      return AsyncCodeGenerator(translator, function, reference);
    } else {
      return CodeGenerator(translator, function, reference);
    }
  }

  w.ModuleBuilder get m => translator.m;
  w.InstructionsBuilder get b => function.body;

  Member get member => reference.asMember;

  List<w.ValueType> get outputs =>
      returnLabel?.targetTypes ?? function.type.outputs;

  w.ValueType get returnType => translator.outputOrVoid(outputs);

  TranslatorOptions get options => translator.options;

  w.ValueType get voidMarker => translator.voidMarker;

  Types get types => translator.types;

  w.ValueType translateType(DartType type) => translator.translateType(type);

  w.Local addLocal(w.ValueType type) {
    return function.addLocal(type);
  }

  DartType dartTypeOf(Expression exp) {
    return exp.getStaticType(typeContext);
  }

  void unimplemented(
      TreeNode node, Object message, List<w.ValueType> expectedTypes) {
    final text = "Not implemented: $message at ${node.location}";
    print(text);
    b.comment(text);
    b.block(const [], expectedTypes);
    b.unreachable();
    b.end();
  }

  @override
  w.ValueType defaultExpression(Expression node, w.ValueType expectedType) {
    unimplemented(
        node, node.runtimeType, [if (expectedType != voidMarker) expectedType]);
    return expectedType;
  }

  /// Generate code for the member.
  void generate() {
    Member member = this.member;

    if (member is Constructor) {
      // Closures are built when constructor functions are added to worklist.
      closures = translator.constructorClosures[member.reference]!;
    } else {
      // Build closure information.
      closures = Closures(this.translator, this.member);
    }

    if (reference.isTearOffReference) {
      return generateTearOffGetter(member as Procedure);
    }

    if (reference.isTypeCheckerReference) {
      if (member is Field || (member is Procedure && member.isSetter)) {
        return _generateFieldSetterTypeCheckerMethod();
      } else {
        return _generateProcedureTypeCheckerMethod();
      }
    }

    if (intrinsifier.generateMemberIntrinsic(
        reference, function, paramLocals, returnLabel)) {
      b.end();
      return;
    }

    if (member.isExternal) {
      b.comment("Unimplemented external member $member at ${member.location}");
      if (member.isInstanceMember) {
        b.local_get(paramLocals[0]);
      } else {
        b.ref_null(w.HeapType.none);
      }
      translator.constants.instantiateConstant(
          function,
          b,
          SymbolConstant(member.name.text, null),
          translator.classInfo[translator.symbolClass]!.nonNullableType);
      call(translator
          .noSuchMethodErrorThrowUnimplementedExternalMemberError.reference);
      b.unreachable();
      b.end();
      return;
    }

    if (member is Constructor) {
      if (reference.isConstructorBodyReference) {
        return generateConstructorBody(reference);
      } else if (reference.isInitializerReference) {
        return generateInitializerList(reference);
      }

      return generateConstructorAllocator(member);
    }

    if (member is Field) {
      if (member.isStatic) {
        return generateStaticFieldInitializer(member);
      } else {
        return generateImplicitAccessor(member);
      }
    }

    assert(member.function!.asyncMarker != AsyncMarker.SyncStar);
    assert(member.function!.asyncMarker != AsyncMarker.Async);

    translator.membersBeingGenerated.add(member);
    generateBody(member);
    translator.membersBeingGenerated.remove(member);
  }

  void generateTearOffGetter(Procedure procedure) {
    _initializeThis(member.reference);
    DartType functionType = translator.getTearOffType(procedure);
    ClosureImplementation closure = translator.getTearOffClosure(procedure);
    w.StructType struct = closure.representation.closureStruct;

    ClassInfo info = translator.closureInfo;
    translator.functions.allocateClass(info.classId);

    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    b.local_get(paramLocals[0]); // `this` as context
    b.global_get(closure.vtable);
    types.makeType(this, functionType);
    b.struct_new(struct);
    b.end();
  }

  void generateStaticFieldInitializer(Field field) {
    // Static field initializer function
    assert(reference == field.fieldReference);
    closures.findCaptures(field);
    closures.collectContexts(field);
    closures.buildContexts();

    w.Global global = translator.globals.getGlobal(field);
    w.Global? flag = translator.globals.getGlobalInitializedFlag(field);
    wrap(field.initializer!, global.type.type);
    b.global_set(global);
    if (flag != null) {
      b.i32_const(1);
      b.global_set(flag);
    }
    b.global_get(global);
    translator.convertType(function, global.type.type, outputs.single);
    b.end();
  }

  void generateImplicitAccessor(Field field) {
    // Implicit getter or setter
    w.StructType struct = translator.classInfo[field.enclosingClass!]!.struct;
    int fieldIndex = translator.fieldIndex[field]!;
    w.ValueType fieldType = struct.fields[fieldIndex].type.unpacked;

    void getThis() {
      w.Local thisLocal = paramLocals[0];
      w.RefType structType = w.RefType.def(struct, nullable: false);
      b.local_get(thisLocal);
      translator.convertType(function, thisLocal.type, structType);
    }

    if (reference.isImplicitGetter) {
      // Implicit getter
      getThis();
      b.struct_get(struct, fieldIndex);
      translator.convertType(function, fieldType, returnType);
    } else {
      // Implicit setter
      w.Local valueLocal = paramLocals[1];
      getThis();
      b.local_get(valueLocal);
      translator.convertType(function, valueLocal.type, fieldType);
      b.struct_set(struct, fieldIndex);
    }
    b.end();
  }

  void _setupLocalParameters(Member member, ParameterInfo paramInfo,
      int parameterOffset, int implicitParams) {
    List<TypeParameter> typeParameters = member is Constructor
        ? member.enclosingClass.typeParameters
        : member.function!.typeParameters;
    for (int i = 0; i < typeParameters.length; i++) {
      typeLocals[typeParameters[i]] = paramLocals[parameterOffset + i];
    }

    void setupParamLocal(
        VariableDeclaration variable, int index, Constant? defaultValue) {
      w.Local local = paramLocals[implicitParams + index];
      locals[variable] = local;
      if (defaultValue == ParameterInfo.defaultValueSentinel) {
        // The default value for this parameter differs between implementations
        // within the same selector. This means that callers will pass the
        // default value sentinel to indicate that the parameter is not given.
        // The callee must check for the sentinel value and substitute the
        // actual default value.
        b.local_get(local);
        translator.constants.instantiateConstant(
            function, b, ParameterInfo.defaultValueSentinel, local.type);
        b.ref_eq();
        b.if_();
        wrap(variable.initializer!, local.type);
        b.local_set(local);
        b.end();
      }
    }

    List<VariableDeclaration> positional =
        member.function!.positionalParameters;
    for (int i = 0; i < positional.length; i++) {
      setupParamLocal(positional[i], i, paramInfo.positional[i]);
    }
    List<VariableDeclaration> named = member.function!.namedParameters;
    for (var param in named) {
      setupParamLocal(
          param, paramInfo.nameIndex[param.name]!, paramInfo.named[param.name]);
    }

    // For all parameters whose Wasm type has been forced to `externref` due to
    // this function being an export, internalize and cast the parameter to the
    // canonical representation type for its Dart type.
    locals.forEach((parameter, local) {
      DartType parameterType = parameter.type;
      if (local.type == w.RefType.extern(nullable: true) &&
          !(parameterType is InterfaceType &&
              parameterType.classNode == translator.wasmExternRefClass)) {
        w.Local newLocal = addLocal(translateType(parameterType));
        b.local_get(local);
        translator.convertType(function, local.type, newLocal.type);
        b.local_set(newLocal);
        locals[parameter] = newLocal;
      }
    });
  }

  void setupParameters(Reference reference) {
    Member member = reference.asMember;
    ParameterInfo paramInfo = translator.paramInfoFor(reference);

    int parameterOffset = _initializeThis(reference);
    int implicitParams = parameterOffset + paramInfo.typeParamCount;

    _setupLocalParameters(member, paramInfo, parameterOffset, implicitParams);
  }

  void setupParametersAndContexts(Reference reference) {
    setupParameters(reference);

    closures.findCaptures(member);
    closures.collectContexts(member);
    closures.buildContexts();

    allocateContext(member.function!);
    captureParameters();
  }

  void setupInitializerListParametersAndContexts(Reference reference) {
    setupParameters(reference);
    allocateContext(member);
    captureParameters();
  }

  void setupConstructorBodyParametersAndContexts(Reference reference) {
    Constructor member = reference.asConstructor;
    ParameterInfo paramInfo = translator.paramInfoFor(reference);

    // For constructor body functions, the first parameter is always the
    // receiver parameter, and the second parameter is a reference to the
    // current context (if it exists).
    Context? context = closures.contexts[member];
    bool hasConstructorContext = context != null;

    if (hasConstructorContext) {
      assert(!context.isEmpty);
      _initializeContextLocals(member, contextParamIndex: 1);
    }

    // Skips the receiver param (_initializeThis will return 1), and the
    // context param if this exists.
    int parameterOffset =
        _initializeThis(reference) + (hasConstructorContext ? 1 : 0);
    int implicitParams = parameterOffset + paramInfo.typeParamCount;

    _setupLocalParameters(member, paramInfo, parameterOffset, implicitParams);
    allocateContext(member.function);
  }

  void _setupDefaultFieldValues(ClassInfo info) {
    fieldLocals.clear();

    for (Field field in info.cls!.fields) {
      if (field.isInstanceMember && field.initializer != null) {
        int fieldIndex = translator.fieldIndex[field]!;
        w.Local local = addLocal(info.struct.fields[fieldIndex].type.unpacked);

        wrap(field.initializer!, info.struct.fields[fieldIndex].type.unpacked);
        b.local_set(local);
        fieldLocals[field] = local;
      }
    }
  }

  List<w.Local> _generateInitializers(Constructor member) {
    Class cls = member.enclosingClass;
    ClassInfo info = translator.classInfo[cls]!;
    List<w.Local> superclassFields = [];

    _setupDefaultFieldValues(info);

    // Generate initializer list
    for (Initializer initializer in member.initializers) {
      visitInitializer(initializer);

      if (initializer is SuperInitializer) {
        // Save super classes' fields to locals
        ClassInfo superInfo = info.superInfo!;

        for (w.ValueType outputType
            in superInfo.getClassFieldTypes().reversed) {
          w.Local local = addLocal(outputType);
          b.local_set(local);
          superclassFields.add(local);
        }
      } else if (initializer is RedirectingInitializer) {
        // Save redirected classes' fields to locals
        List<w.Local> redirectedFields = [];

        for (w.ValueType outputType in info.getClassFieldTypes().reversed) {
          w.Local local = addLocal(outputType);
          b.local_set(local);
          redirectedFields.add(local);
        }

        return redirectedFields.reversed.toList();
      }
    }

    List<w.Local> typeFields = [];

    for (TypeParameter typeParam in cls.typeParameters) {
      TypeParameter? match = info.typeParameterMatch[typeParam];

      if (match == null) {
        // Type is not contained in super class' fields
        typeFields.add(typeLocals[typeParam]!);
      }
    }

    List<w.Local> orderedFieldLocals = Map.fromEntries(
            fieldLocals.entries.toList()
              ..sort((x, y) => translator.fieldIndex[x.key]!
                  .compareTo(translator.fieldIndex[y.key]!)))
        .values
        .toList();

    return superclassFields.reversed.toList() + typeFields + orderedFieldLocals;
  }

  void generateTypeChecks(List<TypeParameter> typeParameters,
      FunctionNode function, ParameterInfo paramInfo) {
    if (translator.options.omitTypeChecks) {
      return;
    }

    for (TypeParameter typeParameter in typeParameters) {
      if (typeParameter.isCovariantByClass &&
          typeParameter.bound != translator.coreTypes.objectNullableRawType) {
        _generateTypeArgumentBoundCheck(typeParameter.name!,
            typeLocals[typeParameter]!, typeParameter.bound);
      }
    }

    // Local for the parameter type if any of the parameters need type checks
    w.Local? parameterExpectedTypeLocal;

    final int parameterOffset = thisLocal == null ? 0 : 1;
    final int implicitParams = parameterOffset + paramInfo.typeParamCount;
    void generateValueParameterCheck(VariableDeclaration variable, int index) {
      if (!variable.isCovariantByClass && !variable.isCovariantByDeclaration) {
        return;
      }
      final w.Local local = paramLocals[implicitParams + index];
      final typeLocal = parameterExpectedTypeLocal ??=
          addLocal(translator.classInfo[translator.typeClass]!.nonNullableType);
      _generateArgumentTypeCheck(
        variable.name!,
        () => b.local_get(local),
        () => types.makeType(this, variable.type),
        local,
        typeLocal,
      );
    }

    final List<VariableDeclaration> positional = function.positionalParameters;
    for (int i = 0; i < positional.length; i++) {
      generateValueParameterCheck(positional[i], i);
    }

    final List<VariableDeclaration> named = function.namedParameters;
    for (var param in named) {
      generateValueParameterCheck(param, paramInfo.nameIndex[param.name]!);
    }
  }

  List<w.Local> _getConstructorArgumentLocals(Reference target,
      [reverse = false]) {
    Constructor member = target.asConstructor;
    List<w.Local> constructorArgs = [];

    List<TypeParameter> typeParameters = member.enclosingClass.typeParameters;

    for (int i = 0; i < typeParameters.length; i++) {
      constructorArgs.add(typeLocals[typeParameters[i]]!);
    }

    List<VariableDeclaration> positional = member.function.positionalParameters;
    for (VariableDeclaration pos in positional) {
      constructorArgs.add(locals[pos]!);
    }

    Map<String, w.Local> namedArgs = {};
    List<VariableDeclaration> named = member.function.namedParameters;
    for (VariableDeclaration param in named) {
      namedArgs[param.name!] = locals[param]!;
    }

    final ParameterInfo paramInfo = translator.paramInfoFor(target);

    for (String name in paramInfo.names) {
      w.Local namedLocal = namedArgs[name]!;
      constructorArgs.add(namedLocal);
    }

    if (reverse) {
      return constructorArgs.reversed.toList();
    }

    return constructorArgs;
  }

  void generateBody(Member member) {
    assert(member is! Constructor);
    setupParametersAndContexts(member.reference);

    final List<TypeParameter> typeParameters = member.function!.typeParameters;
    generateTypeChecks(
        typeParameters, member.function!, translator.paramInfoFor(reference));

    Statement? body = member.function!.body;
    if (body != null) {
      visitStatement(body);
    }

    _implicitReturn();
    b.end();
  }

  // Generates a function for allocating an object. This calls the separate
  // initializer list and constructor body methods, and allocates a struct for
  // the object.
  void generateConstructorAllocator(Constructor member) {
    setupParameters(member.reference);

    final List<TypeParameter> typeParameters =
        member.enclosingClass.typeParameters;
    generateTypeChecks(
        typeParameters, member.function, translator.paramInfoFor(reference));

    w.FunctionType initializerMethodType =
        translator.functions.getFunctionType(member.initializerReference);

    List<w.Local> constructorArgs =
        _getConstructorArgumentLocals(member.reference);

    for (w.Local local in constructorArgs) {
      b.local_get(local);
    }

    b.comment("Direct call of '${member} Initializer'");
    call(member.initializerReference);

    ClassInfo info = translator.classInfo[member.enclosingClass]!;

    // Add evaluated fields to locals
    List<w.Local> orderedFieldLocals = [];

    List<w.FieldType> fieldTypes = info.struct.fields
        .sublist(FieldIndex.objectFieldBase)
        .reversed
        .toList();

    for (w.FieldType field in fieldTypes) {
      w.Local local = addLocal(field.type.unpacked);
      orderedFieldLocals.add(local);
      b.local_set(local);
    }

    Context? context = closures.contexts[member];
    w.Local? contextLocal = null;

    bool hasContext = context != null;

    if (hasContext) {
      assert(!context.isEmpty);
      w.ValueType contextRef = w.RefType.struct(nullable: true);
      contextLocal = addLocal(contextRef);
      b.local_set(contextLocal);
    }

    List<w.ValueType> initializerOutputTypes = initializerMethodType.outputs;
    int numConstructorBodyArgs = initializerOutputTypes.length -
        fieldTypes.length -
        (hasContext ? 1 : 0);

    // Pop all arguments to constructor body
    List<w.ValueType> constructorArgTypes =
        initializerOutputTypes.sublist(0, numConstructorBodyArgs);

    List<w.Local> constructorArguments = [];

    for (w.ValueType argType in constructorArgTypes.reversed) {
      w.Local local = addLocal(argType);
      b.local_set(local);
      constructorArguments.add(local);
    }

    // Set field values
    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);

    for (w.Local local in orderedFieldLocals.reversed) {
      b.local_get(local);
    }

    // create new struct with these fields and set to local
    w.Local temp = addLocal(info.nonNullableType);
    b.struct_new(info.struct);
    b.local_tee(temp);

    // Push context local if it is present
    if (contextLocal != null) {
      b.local_get(contextLocal);
    }

    // Push all constructor arguments
    for (w.Local constructorArg in constructorArguments) {
      b.local_get(constructorArg);
    }

    b.comment("Direct call of ${member} Constructor Body");
    call(member.constructorBodyReference);

    b.local_get(temp);
    b.end();
  }

  void setupLambdaParametersAndContexts(Lambda lambda) {
    FunctionNode functionNode = lambda.functionNode;
    _initializeContextLocals(functionNode);

    int paramIndex = 1;
    for (TypeParameter typeParam in functionNode.typeParameters) {
      typeLocals[typeParam] = paramLocals[paramIndex++];
    }
    for (VariableDeclaration param in functionNode.positionalParameters) {
      locals[param] = paramLocals[paramIndex++];
    }
    for (VariableDeclaration param in functionNode.namedParameters) {
      locals[param] = paramLocals[paramIndex++];
    }

    allocateContext(functionNode);
    captureParameters();
  }

  /// Generate code for the body of a lambda.
  w.BaseFunction generateLambda(Lambda lambda, Closures closures) {
    // Initialize closure information from enclosing member.
    this.closures = closures;

    assert(lambda.functionNode.asyncMarker != AsyncMarker.Async);

    setupLambdaParametersAndContexts(lambda);

    visitStatement(lambda.functionNode.body!);
    _implicitReturn();
    b.end();

    return function;
  }

  /// Initialize locals containing `this` in constructors and instance members.
  /// Returns the number of parameter locals taken up by the receiver parameter,
  /// i.e. the parameter offset for the first type parameter (or the first
  /// parameter if there are no type parameters).
  int _initializeThis(Reference reference) {
    Member member = reference.asMember;
    bool hasThis =
        member.isInstanceMember || reference.isConstructorBodyReference;
    if (hasThis) {
      thisLocal = paramLocals[0];
      assert(!thisLocal!.type.nullable);
      Class cls = member.enclosingClass!;
      w.StorageType? builtin = translator.builtinTypes[cls];
      w.ValueType thisType = translator.boxedClasses.containsKey(builtin)
          ? builtin as w.ValueType
          : translator.classInfo[cls]!.nonNullableType;
      if (translator.needsConversion(thisLocal!.type, thisType) &&
          !(cls == translator.objectInfo.cls ||
              cls == translator.ffiPointerClass ||
              translator.isFfiCompound(cls) ||
              translator.isWasmType(cls))) {
        preciseThisLocal = addLocal(thisType);
        b.local_get(thisLocal!);
        translator.convertType(function, thisLocal!.type, thisType);
        b.local_set(preciseThisLocal!);
      } else {
        preciseThisLocal = thisLocal!;
      }
      return 1;
    }
    return 0;
  }

  /// Initialize locals pointing to every context in the context chain of a
  /// closure, plus the locals containing `this` if `this` is captured by the
  /// closure.
  void _initializeContextLocals(TreeNode node, {int contextParamIndex = 0}) {
    Context? context = null;

    if (node is Constructor) {
      // The context parameter is for the constructor context.
      context = closures.contexts[node];
    } else {
      assert(node is FunctionNode);
      // The context parameter is for the parent context.
      context = closures.contexts[node]?.parent;
    }

    if (context != null) {
      assert(!context.isEmpty);
      w.RefType contextType = w.RefType.def(context.struct, nullable: false);

      b.local_get(paramLocals[contextParamIndex]);
      b.ref_cast(contextType);

      while (true) {
        w.Local contextLocal = addLocal(contextType);
        context!.currentLocal = contextLocal;

        if (context.parent != null || context.containsThis) {
          b.local_tee(contextLocal);
        } else {
          b.local_set(contextLocal);
        }

        if (context.containsThis) {
          thisLocal = addLocal(context
              .struct.fields[context.thisFieldIndex].type.unpacked
              .withNullability(false));
          preciseThisLocal = thisLocal;

          b.struct_get(context.struct, context.thisFieldIndex);
          b.ref_as_non_null();
          b.local_set(thisLocal!);

          if (context.parent != null) {
            b.local_get(contextLocal);
          }
        }

        if (context.parent == null) break;

        b.struct_get(context.struct, context.parentFieldIndex);
        b.ref_as_non_null();
        context = context.parent!;
        contextType = w.RefType.def(context.struct, nullable: false);
      }
    }
  }

  void _implicitReturn() {
    if (outputs.isNotEmpty) {
      w.ValueType returnType = outputs.single;
      if (returnType is w.RefType && returnType.nullable) {
        // Dart body may have an implicit return null.
        b.ref_null(returnType.heapType.bottomType);
      } else {
        // This point is unreachable, but the Wasm validator still expects the
        // stack to contain a value matching the Wasm function return type.
        b.block(const [], outputs);
        b.comment("Unreachable implicit return");
        b.unreachable();
        b.end();
      }
    }
  }

  void allocateContext(TreeNode node) {
    Context? context = closures.contexts[node];
    if (context != null && !context.isEmpty) {
      w.Local contextLocal =
          addLocal(w.RefType.def(context.struct, nullable: true));
      context.currentLocal = contextLocal;
      b.struct_new_default(context.struct);
      b.local_set(contextLocal);
      if (context.containsThis) {
        b.local_get(contextLocal);
        b.local_get(preciseThisLocal!);
        b.struct_set(context.struct, context.thisFieldIndex);
      }
      if (context.parent != null) {
        w.Local parentLocal = context.parent!.currentLocal;
        b.local_get(contextLocal);
        b.local_get(parentLocal);
        b.struct_set(context.struct, context.parentFieldIndex);
      }
    }
  }

  void captureParameters() {
    locals.forEach((variable, local) {
      Capture? capture = closures.captures[variable];
      if (capture != null) {
        b.local_get(capture.context.currentLocal);
        b.local_get(local);
        translator.convertType(function, local.type, capture.type);
        b.struct_set(capture.context.struct, capture.fieldIndex);
      }
    });
    typeLocals.forEach((parameter, local) {
      Capture? capture = closures.captures[parameter];
      if (capture != null) {
        b.local_get(capture.context.currentLocal);
        b.local_get(local);
        translator.convertType(function, local.type, capture.type);
        b.struct_set(capture.context.struct, capture.fieldIndex);
      }
    });
  }

  /// Helper function to throw a Wasm ref downcast error.
  void throwWasmRefError(String expected) {
    _emitString(expected);
    call(translator.stackTraceCurrent.reference);
    call(translator.throwWasmRefError.reference);
    b.unreachable();
  }

  /// Generates code for an expression plus conversion code to convert the
  /// result to the expected type if needed. All expression code generation goes
  /// through this method.
  w.ValueType wrap(Expression node, w.ValueType expectedType) {
    try {
      w.ValueType resultType = node.accept1(this, expectedType);
      translator.convertType(function, resultType, expectedType);
      return expectedType;
    } catch (_) {
      _printLocation(node);
      rethrow;
    }
  }

  void visitStatement(Statement node) {
    try {
      node.accept(this);
    } catch (_) {
      _printLocation(node);
      rethrow;
    }
  }

  void visitInitializer(Initializer node) {
    try {
      node.accept(this);
    } catch (_) {
      _printLocation(node);
      rethrow;
    }
  }

  void _printLocation(TreeNode node) {
    if (!exceptionLocationPrinted) {
      print("Exception in ${node.runtimeType} at ${node.location}");
      exceptionLocationPrinted = true;
    }
  }

  List<w.ValueType> call(Reference target) {
    if (translator.shouldInline(target)) {
      w.FunctionType targetFunctionType =
          translator.functions.getFunctionType(target);
      List<w.Local> inlinedLocals =
          targetFunctionType.inputs.map((t) => addLocal(t)).toList();
      for (w.Local local in inlinedLocals.reversed) {
        b.local_set(local);
      }
      w.Label block = b.block(const [], targetFunctionType.outputs);
      b.comment("Inlined ${target.asMember}");
      CodeGenerator(translator, function, target,
              paramLocals: inlinedLocals, returnLabel: block)
          .generate();
      return targetFunctionType.outputs;
    } else {
      w.BaseFunction targetFunction = translator.functions.getFunction(target);
      String access =
          target.isGetter ? "get" : (target.isSetter ? "set" : "call");
      b.comment("Direct $access of '${target.asMember}'");
      b.call(targetFunction);
      return targetFunction.type.outputs;
    }
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {}

  @override
  void visitAssertInitializer(AssertInitializer node) {
    visitStatement(node.statement);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    visitStatement(node.variable);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    Class cls = (node.parent as Constructor).enclosingClass;
    w.StructType struct = translator.classInfo[cls]!.struct;
    Field field = node.field;
    int fieldIndex = translator.fieldIndex[field]!;

    w.Local? local = fieldLocals[field];

    if (local == null) {
      local = addLocal(struct.fields[fieldIndex].type.unpacked);
    }

    wrap(node.value, struct.fields[fieldIndex].type.unpacked);
    b.local_set(local);
    fieldLocals[field] = local;
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    Class cls = (node.parent as Constructor).enclosingClass;

    final Member targetMember = node.targetReference.asMember;

    for (TypeParameter typeParam in cls.typeParameters) {
      types.makeType(
          this, TypeParameterType(typeParam, Nullability.nonNullable));
    }

    _visitArguments(node.arguments, targetMember.initializerReference,
        cls.typeParameters.length);

    b.comment("Direct call of '${targetMember} Redirected Initializer'");
    call(targetMember.initializerReference);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    Supertype? supertype =
        (node.parent as Constructor).enclosingClass.supertype;
    Supertype? supersupertype = node.target.enclosingClass.supertype;

    // Skip calls to the constructor for Object, as this is empty
    if (supersupertype != null) {
      final Member targetMember = node.targetReference.asMember;

      for (DartType typeArg in supertype!.typeArguments) {
        types.makeType(this, typeArg);
      }

      _visitArguments(node.arguments, targetMember.initializerReference,
          supertype.typeArguments.length);

      b.comment("Direct call of '${targetMember} Initializer'");
      call(targetMember.initializerReference);
    }
  }

  @override
  void visitBlock(Block node) {
    for (Statement statement in node.statements) {
      visitStatement(statement);
    }
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    w.Label label = b.block();
    breakFinalizers[node] = <w.Label>[label];
    visitStatement(node.body);
    breakFinalizers.remove(node);
    b.end();
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    b.br(breakFinalizers[node.target]!.last);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    if (node.type is VoidType) {
      if (node.initializer != null) {
        wrap(node.initializer!, voidMarker);
      }
      return;
    }
    w.ValueType type = translateType(node.type);
    w.Local? local;
    Capture? capture = closures.captures[node];
    if (capture == null || !capture.written) {
      local = addLocal(type);
      locals[node] = local;
    }

    // Handle variable initialization. Nullable variables have an implicit
    // initializer.
    if (node.initializer != null ||
        node.type.nullability == Nullability.nullable) {
      Expression initializer =
          node.initializer ?? ConstantExpression(NullConstant());
      if (capture != null) {
        w.ValueType expectedType = capture.written ? capture.type : local!.type;
        b.local_get(capture.context.currentLocal);
        wrap(initializer, expectedType);
        if (!capture.written) {
          b.local_tee(local!);
        }
        b.struct_set(capture.context.struct, capture.fieldIndex);
      } else {
        wrap(initializer, local!.type);
        b.local_set(local);
      }
    } else if (local != null && !local.type.defaultable) {
      // Uninitialized variable
      translator.globals.instantiateDummyValue(b, local.type);
      b.local_set(local);
    }
  }

  /// Initialize a variable [node] to an initial value which must be left on
  /// the stack by [pushInitialValue].
  ///
  /// This is similar to [visitVariableDeclaration] but it gives more control
  /// over how the variable is initialized.
  void initializeVariable(VariableDeclaration node, void pushInitialValue()) {
    final w.ValueType type = translateType(node.type);
    w.Local? local;
    final Capture? capture = closures.captures[node];
    if (capture == null || !capture.written) {
      local = addLocal(type);
      locals[node] = local;
    }

    if (capture != null) {
      b.local_get(capture.context.currentLocal);
      pushInitialValue();
      if (!capture.written) {
        b.local_tee(local!);
      }
      b.struct_set(capture.context.struct, capture.fieldIndex);
    } else {
      pushInitialValue();
      b.local_set(local!);
    }
  }

  @override
  void visitEmptyStatement(EmptyStatement node) {}

  @override
  void visitAssertStatement(AssertStatement node) {
    if (options.enableAsserts) {
      w.Label assertBlock = b.block();
      wrap(node.condition, w.NumType.i32);
      b.br_if(assertBlock);

      Expression? message = node.message;
      if (message != null) {
        wrap(message, translator.topInfo.nullableType);
      } else {
        b.ref_null(w.HeapType.none);
      }
      call(translator.throwAssertionError.reference);

      b.unreachable();
      b.end();
    }
  }

  @override
  void visitAssertBlock(AssertBlock node) {
    if (!options.enableAsserts) return;

    for (Statement statement in node.statements) {
      visitStatement(statement);
    }
  }

  @override
  void visitTryCatch(TryCatch node) {
    // It is not valid dart to have a try without a catch.
    assert(node.catches.isNotEmpty);

    // We lower a [TryCatch] to a wasm try block.
    w.Label try_ = b.try_();
    visitStatement(node.body);
    b.br(try_);

    // Note: We must wait to add the try block to the [tryLabels] stack until
    // after we have visited the body of the try. This is to handle the case of
    // a rethrow nested within a try nested within a catch, that is we need the
    // rethrow to target the last try block with a catch.
    tryLabels.add(try_);

    // Stash the original exception in a local so we can push it back onto the
    // stack after each type test. Also, store the stack trace in a local.
    w.Local thrownException = addLocal(translator.topInfo.nonNullableType);
    w.Local thrownStackTrace =
        addLocal(translator.stackTraceInfo.repr.nonNullableType);

    void emitCatchBlock(Catch catch_, bool emitGuard) {
      // For each catch node:
      //   1) Create a block for the catch.
      //   2) Push the caught exception onto the stack.
      //   3) Add a type test based on the guard of the catch.
      //   4) If the test fails, we jump to the next catch. Otherwise, we
      //      execute the body of the catch.
      w.Label catchBlock = b.block();
      DartType guard = catch_.guard;

      // Only emit the type test if the guard is not [Object].
      if (emitGuard) {
        b.local_get(thrownException);
        types.emitTypeTest(
            this, guard, translator.coreTypes.objectNonNullableRawType);
        b.i32_eqz();
        b.br_if(catchBlock);
      }

      final VariableDeclaration? exceptionDeclaration = catch_.exception;
      if (exceptionDeclaration != null) {
        initializeVariable(exceptionDeclaration, () {
          b.local_get(thrownException);
          // Type test passed, downcast the exception to the expected type.
          translator.convertType(
            function,
            thrownException.type,
            translator.translateType(exceptionDeclaration.type),
          );
        });
      }

      final VariableDeclaration? stackTraceDeclaration = catch_.stackTrace;
      if (stackTraceDeclaration != null) {
        initializeVariable(
            stackTraceDeclaration, () => b.local_get(thrownStackTrace));
      }

      visitStatement(catch_.body);

      // Jump out of the try entirely if we enter any catch block.
      b.br(try_);
      b.end(); // end catchBlock.
    }

    // Insert a catch instruction which will catch any thrown Dart
    // exceptions.
    b.catch_(translator.exceptionTag);

    b.local_set(thrownStackTrace);
    b.local_set(thrownException);
    for (final Catch catch_ in node.catches) {
      // Only insert type checks if the guard is not `Object`
      final bool shouldEmitGuard =
          catch_.guard != translator.coreTypes.objectNonNullableRawType;
      emitCatchBlock(catch_, shouldEmitGuard);
      if (!shouldEmitGuard) {
        // If we didn't emit a guard, we won't ever fall through to the
        // following catch blocks.
        break;
      }
    }
    // Rethrow if all the catch blocks fall through
    b.rethrow_(try_);

    bool guardCanMatchJSException(DartType guard) {
      if (guard is DynamicType) {
        return true;
      }
      if (guard is InterfaceType) {
        return translator.hierarchy
            .isSubInterfaceOf(translator.javaScriptErrorClass, guard.classNode);
      }
      if (guard is TypeParameterType) {
        return guardCanMatchJSException(guard.bound);
      }
      return false;
    }

    // If we have a catches that are generic enough to catch a JavaScript
    // error, we need to put that into a catch_all block.
    final Iterable<Catch> catchAllCatches =
        node.catches.where((c) => guardCanMatchJSException(c.guard));

    if (catchAllCatches.isNotEmpty) {
      // This catches any objects that aren't dart exceptions, such as
      // JavaScript exceptions or objects.
      b.catch_all();

      // We can't inspect the thrown object in a catch_all and get a stack
      // trace, so we just attach the current stack trace.
      call(translator.stackTraceCurrent.reference);
      b.local_set(thrownStackTrace);

      // We create a generic JavaScript error in this case.
      call(translator.javaScriptErrorFactory.reference);
      b.local_set(thrownException);

      for (final c in catchAllCatches) {
        // Type guards based on a type parameter are special, in that we cannot
        // statically determine whether a JavaScript error will always satisfy
        // the guard, so we should emit the type checking code for it. All
        // other guards will always match a JavaScript error, however, so no
        // need to emit type checks for those.
        final bool shouldEmitGuard = c.guard is TypeParameterType;
        emitCatchBlock(c, shouldEmitGuard);
        if (!shouldEmitGuard) {
          // If we didn't emit a guard, we won't ever fall through to the
          // following catch blocks.
          break;
        }
      }

      // Rethrow if the catch block falls through
      b.rethrow_(try_);
    }

    tryLabels.removeLast();
    b.end(); // end try_.
  }

  @override
  void visitTryFinally(TryFinally node) {
    // We lower a [TryFinally] to a number of nested blocks, depending on how
    // many different code paths we have that run the finally block.
    //
    // We emit the finalizer once in a catch, to handle the case where the try
    // throws. Once outside of the catch, to handle the case where the try does
    // not throw. If there is a return within the try block, then we emit the
    // finalizer one more time along with logic to continue walking up the
    // stack.
    //
    // A `break L` can run more than one finalizer, and each of those
    // finalizers will need to be run in a different `try` block. So for each
    // wrapping label we generate a block to run the finalizer on `break` and
    // then branch to the right Wasm block to either run the next finalizer or
    // break.

    // The block for the try-finally statement. Used as `br` target in normal
    // execution after the finalizer (no throws, returns, or breaks).
    w.Label tryFinallyBlock = b.block();

    // Create one block for each wrapping label
    for (final labelBlocks in breakFinalizers.values.toList().reversed) {
      labelBlocks.add(b.block());
    }

    // Continuation of this block runs the finalizer and returns (or jumps to
    // the next finalizer block). Used as `br` target on `return`.
    w.Label returnFinalizerBlock = b.block();
    returnFinalizers.add(TryBlockFinalizer(returnFinalizerBlock));

    w.Label tryBlock = b.try_();
    visitStatement(node.body);
    final bool mustHandleReturn =
        returnFinalizers.removeLast().mustHandleReturn;
    b.catch_(translator.exceptionTag);

    // `break` statements in the current finalizer and the rest will not run
    // the current finalizer, update the `break` targets
    final removedBreakTargets = <LabeledStatement, w.Label>{};
    for (final breakFinalizerEntry in breakFinalizers.entries) {
      removedBreakTargets[breakFinalizerEntry.key] =
          breakFinalizerEntry.value.removeLast();
    }

    // Run finalizer on exception
    visitStatement(node.finalizer);
    b.rethrow_(tryBlock);
    b.end(); // end tryBlock.

    // Run finalizer on normal execution (no breaks, throws, or returns)
    visitStatement(node.finalizer);
    b.br(tryFinallyBlock);
    b.end(); // end returnFinalizerBlock.

    // Run finalizer on `return`
    if (mustHandleReturn) {
      visitStatement(node.finalizer);
      if (returnFinalizers.isNotEmpty) {
        b.br(returnFinalizers.last.label);
      } else {
        if (returnValueLocal != null) {
          b.local_get(returnValueLocal!);
          translator.convertType(function, returnValueLocal!.type, returnType);
        }
        _returnFromFunction();
      }
    }

    // Generate finalizers for `break`s in the `try` block
    for (final removedBreakTargetEntry in removedBreakTargets.entries) {
      b.end();
      visitStatement(node.finalizer);
      b.br(breakFinalizers[removedBreakTargetEntry.key]!.last);
    }

    // Terminate `tryFinallyBlock`
    b.end();
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    wrap(node.expression, voidMarker);
  }

  bool _hasLogicalOperator(Expression condition) {
    while (condition is Not) {
      condition = condition.operand;
    }
    return condition is LogicalExpression;
  }

  void branchIf(Expression? condition, w.Label target,
      {required bool negated}) {
    if (condition == null) {
      if (!negated) b.br(target);
      return;
    }
    while (condition is Not) {
      negated = !negated;
      condition = condition.operand;
    }
    if (condition is LogicalExpression) {
      bool isConjunctive =
          (condition.operatorEnum == LogicalExpressionOperator.AND) ^ negated;
      if (isConjunctive) {
        w.Label conditionBlock = b.block();
        branchIf(condition.left, conditionBlock, negated: !negated);
        branchIf(condition.right, target, negated: negated);
        b.end();
      } else {
        branchIf(condition.left, target, negated: negated);
        branchIf(condition.right, target, negated: negated);
      }
    } else {
      wrap(condition!, w.NumType.i32);
      if (negated) {
        b.i32_eqz();
      }
      b.br_if(target);
    }
  }

  void _conditional(Expression condition, void then(), void otherwise()?,
      List<w.ValueType> result) {
    if (!_hasLogicalOperator(condition)) {
      // Simple condition
      wrap(condition, w.NumType.i32);
      b.if_(const [], result);
      then();
      if (otherwise != null) {
        b.else_();
        otherwise();
      }
      b.end();
    } else {
      // Complex condition
      w.Label ifBlock = b.block(const [], result);
      if (otherwise != null) {
        w.Label elseBlock = b.block();
        branchIf(condition, elseBlock, negated: true);
        then();
        b.br(ifBlock);
        b.end();
        otherwise();
      } else {
        branchIf(condition, ifBlock, negated: true);
        then();
      }
      b.end();
    }
  }

  @override
  void visitIfStatement(IfStatement node) {
    _conditional(
        node.condition,
        () => visitStatement(node.then),
        node.otherwise != null ? () => visitStatement(node.otherwise!) : null,
        const []);
  }

  @override
  void visitDoStatement(DoStatement node) {
    w.Label loop = b.loop();
    allocateContext(node);
    visitStatement(node.body);
    branchIf(node.condition, loop, negated: false);
    b.end();
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    w.Label block = b.block();
    w.Label loop = b.loop();
    branchIf(node.condition, block, negated: true);
    allocateContext(node);
    visitStatement(node.body);
    b.br(loop);
    b.end();
    b.end();
  }

  @override
  void visitForStatement(ForStatement node) {
    allocateContext(node);
    for (VariableDeclaration variable in node.variables) {
      visitStatement(variable);
    }
    w.Label block = b.block();
    w.Label loop = b.loop();
    branchIf(node.condition, block, negated: true);
    visitStatement(node.body);

    emitForStatementUpdate(node);

    b.br(loop);
    b.end();
    b.end();
  }

  void emitForStatementUpdate(ForStatement node) {
    Context? context = closures.contexts[node];
    if (context != null && !context.isEmpty) {
      // Create a new context for each iteration of the loop.
      w.Local oldContext = context.currentLocal;
      allocateContext(node);
      w.Local newContext = context.currentLocal;

      // Copy the values of captured loop variables to the new context.
      for (VariableDeclaration variable in node.variables) {
        Capture? capture = closures.captures[variable];
        if (capture != null) {
          assert(capture.context == context);
          b.local_get(newContext);
          b.local_get(oldContext);
          b.struct_get(context.struct, capture.fieldIndex);
          b.struct_set(context.struct, capture.fieldIndex);
        }
      }

      // Update the context local to point to the new context.
      b.local_get(newContext);
      b.local_set(oldContext);
    }

    for (Expression update in node.updates) {
      wrap(update, voidMarker);
    }
  }

  @override
  void visitForInStatement(ForInStatement node) {
    throw "ForInStatement should have been desugared: $node";
  }

  /// Handle the return from this function, either by jumping to [returnLabel]
  /// in the case this function was inlined or just inserting a return
  /// instruction.
  void _returnFromFunction() {
    if (returnLabel != null) {
      b.br(returnLabel!);
    } else {
      b.return_();
    }
  }

  @override
  void visitReturnStatement(ReturnStatement node) {
    Expression? expression = node.expression;
    if (expression != null) {
      wrap(expression, returnType);
    } else {
      translator.convertType(function, voidMarker, returnType);
    }

    // If we are wrapped in a [TryFinally] node then we have to run finalizers
    // as the stack unwinds. When we get to the top of the finalizer stack, we
    // will handle the return using [returnValueLocal] if this function returns
    // a value.
    if (returnFinalizers.isNotEmpty) {
      for (TryBlockFinalizer finalizer in returnFinalizers) {
        finalizer.mustHandleReturn = true;
      }
      if (returnType != voidMarker) {
        // Since the flow of the return value through the returnValueLocal
        // crosses control-flow constructs, the local needs to always have a
        // defaultable type in order for the Wasm code to validate.
        returnValueLocal ??= addLocal(returnType.withNullability(true));
        b.local_set(returnValueLocal!);
      }
      b.br(returnFinalizers.last.label);
    } else {
      _returnFromFunction();
    }
  }

  @override
  void visitSwitchStatement(SwitchStatement node) {
    // If we have an empty switch, just evaluate the expression for any
    // potential side effects. In this case, the return type does not matter.
    if (node.cases.isEmpty) {
      wrap(node.expression, voidMarker);
      return;
    }

    final switchInfo = SwitchInfo(this, node);

    bool isNullable = dartTypeOf(node.expression).isPotentiallyNullable;

    // When the type is nullable we use two variables: one for the nullable
    // value, one after the null check, with non-nullable type.
    w.Local switchValueNonNullableLocal = addLocal(switchInfo.nonNullableType);
    w.Local? switchValueNullableLocal =
        isNullable ? addLocal(switchInfo.nullableType) : null;

    // Initialize switch value local
    wrap(node.expression,
        isNullable ? switchInfo.nullableType : switchInfo.nonNullableType);
    b.local_set(
        isNullable ? switchValueNullableLocal! : switchValueNonNullableLocal);

    // Special cases
    SwitchCase? defaultCase = switchInfo.defaultCase;
    SwitchCase? nullCase = switchInfo.nullCase;

    // Create `loop` for backward jumps
    w.Label loopLabel = b.loop();

    // Set `switchValueLocal` for backward jumps
    w.Local switchValueLocal =
        isNullable ? switchValueNullableLocal! : switchValueNonNullableLocal;

    // Add backward jump info
    switchBackwardJumpInfos[node] =
        SwitchBackwardJumpInfo(switchValueLocal, loopLabel);

    // Set up blocks, in reverse order of cases so they end in forward order
    w.Label doneLabel = b.block();
    for (SwitchCase c in node.cases.reversed) {
      switchLabels[c] = b.block();
    }

    // Compute value and handle null
    if (isNullable) {
      w.Label nullLabel = nullCase != null
          ? switchLabels[nullCase]!
          : defaultCase != null
              ? switchLabels[defaultCase]!
              : doneLabel;
      b.local_get(switchValueNullableLocal!);
      b.br_on_null(nullLabel);
      translator.convertType(
          function,
          switchInfo.nullableType.withNullability(false),
          switchInfo.nonNullableType);
      b.local_set(switchValueNonNullableLocal);
    }

    // Compare against all case values
    for (SwitchCase c in node.cases) {
      for (Expression exp in c.expressions) {
        if (exp is NullLiteral ||
            exp is ConstantExpression && exp.constant is NullConstant) {
          // Null already checked, skip
        } else {
          wrap(exp, switchInfo.nonNullableType);
          b.local_get(switchValueNonNullableLocal);
          switchInfo.compare();
          b.br_if(switchLabels[c]!);
        }
      }
    }

    // No explicit cases matched
    if (node.isExplicitlyExhaustive) {
      b.unreachable();
    } else {
      w.Label defaultLabel =
          defaultCase != null ? switchLabels[defaultCase]! : doneLabel;
      b.br(defaultLabel);
    }

    // Emit case bodies
    for (SwitchCase c in node.cases) {
      b.end();
      // Remove backward jump target from forward jump labels
      switchLabels.remove(c);

      // Create a `loop` in default case to allow backward jumps to it
      if (c.isDefault) {
        switchBackwardJumpInfos[node]!.defaultLoopLabel = b.loop();
      }

      visitStatement(c.body);

      if (c.isDefault) {
        b.end(); // defaultLoopLabel
      }

      b.br(doneLabel);
    }
    b.end(); // doneLabel
    b.end(); // loopLabel

    // Remove backward jump info
    final removed = switchBackwardJumpInfos.remove(node);
    assert(removed != null);
  }

  @override
  void visitContinueSwitchStatement(ContinueSwitchStatement node) {
    w.Label? label = switchLabels[node.target];
    if (label != null) {
      b.br(label);
    } else {
      // Backward jump. Find the case literal in jump target, set the switched
      // values to the jump target's value, and loop.
      final SwitchCase targetSwitchCase = node.target;
      final SwitchStatement targetSwitch =
          targetSwitchCase.parent! as SwitchStatement;
      final SwitchBackwardJumpInfo targetInfo =
          switchBackwardJumpInfos[targetSwitch]!;
      if (targetSwitchCase.expressions.isEmpty) {
        // Default case
        assert(targetSwitchCase.isDefault);
        b.br(targetInfo.defaultLoopLabel!);
        return;
      }
      final Expression targetValue =
          targetSwitchCase.expressions[0]; // pick any of the values
      wrap(targetValue, targetInfo.switchValueLocal.type);
      b.local_set(targetInfo.switchValueLocal);
      b.br(targetInfo.loopLabel);
    }
  }

  @override
  void visitYieldStatement(YieldStatement node) {
    unimplemented(node, node.runtimeType, const []);
  }

  @override
  w.ValueType visitAwaitExpression(
      AwaitExpression node, w.ValueType expectedType) {
    throw 'Await expression in code generator: $node (${node.location})';
  }

  @override
  w.ValueType visitBlockExpression(
      BlockExpression node, w.ValueType expectedType) {
    visitStatement(node.body);
    return wrap(node.value, expectedType);
  }

  @override
  w.ValueType visitLet(Let node, w.ValueType expectedType) {
    visitStatement(node.variable);
    return wrap(node.body, expectedType);
  }

  @override
  w.ValueType visitThisExpression(
      ThisExpression node, w.ValueType expectedType) {
    return visitThis(expectedType);
  }

  w.ValueType visitThis(w.ValueType expectedType) {
    w.ValueType thisType = thisLocal!.type;
    w.ValueType preciseThisType = preciseThisLocal!.type;
    assert(!thisType.nullable);
    assert(!preciseThisType.nullable);
    if (!thisType.isSubtypeOf(expectedType) &&
        preciseThisType.isSubtypeOf(expectedType)) {
      b.local_get(preciseThisLocal!);
      return preciseThisType;
    } else {
      b.local_get(thisLocal!);
      return thisType;
    }
  }

  @override
  w.ValueType visitConstructorInvocation(
      ConstructorInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult =
        intrinsifier.generateConstructorIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    ClassInfo info = translator.classInfo[node.target.enclosingClass]!;
    translator.functions.allocateClass(info.classId);

    _visitArguments(node.arguments, node.targetReference, 0);

    return call(node.targetReference).single;
  }

  @override
  w.ValueType visitStaticInvocation(
      StaticInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult = intrinsifier.generateStaticIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    _visitArguments(node.arguments, node.targetReference, 0);
    return translator.outputOrVoid(call(node.targetReference));
  }

  Member _lookupSuperTarget(Member interfaceTarget, {required bool setter}) {
    return translator.hierarchy.getDispatchTarget(
        member.enclosingClass!.superclass!, interfaceTarget.name,
        setter: setter)!;
  }

  @override
  w.ValueType visitSuperMethodInvocation(
      SuperMethodInvocation node, w.ValueType expectedType) {
    Reference target =
        _lookupSuperTarget(node.interfaceTarget, setter: false).reference;
    w.FunctionType targetFunctionType =
        translator.functions.getFunctionType(target);
    w.ValueType receiverType = targetFunctionType.inputs.first;
    visitThis(receiverType);
    _visitArguments(node.arguments, target, 1);
    return translator.outputOrVoid(call(target));
  }

  @override
  w.ValueType visitInstanceInvocation(
      InstanceInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult = intrinsifier.generateInstanceIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    w.ValueType callWithNullCheck(
        Procedure target, void Function(w.ValueType) onNull) {
      late w.Label done;
      final w.ValueType resultType =
          _virtualCall(node, target, _VirtualCallKind.Call, (signature) {
        done = b.block(const [], signature.outputs);
        final w.Label nullReceiver = b.block();
        wrap(node.receiver, translator.topInfo.nullableType);
        b.br_on_null(nullReceiver);
      }, (_) {
        _visitArguments(node.arguments, node.interfaceTargetReference, 1);
      });
      b.br(done);
      b.end(); // end nullReceiver
      onNull(resultType);
      b.end();
      return resultType;
    }

    final Procedure target = node.interfaceTarget;
    if (node.kind == InstanceAccessKind.Object) {
      switch (target.name.text) {
        case "toString":
          return callWithNullCheck(
              target, (resultType) => wrap(StringLiteral("null"), resultType));
        case "noSuchMethod":
          return callWithNullCheck(target, (resultType) {
            // Object? receiver
            b.ref_null(translator.topInfo.struct);
            // Invocation invocation
            _visitArguments(node.arguments, node.interfaceTargetReference, 1);
            call(translator.noSuchMethodErrorThrowWithInvocation.reference);
          });
        default:
          unimplemented(node, "Nullable invocation of ${target.name.text}",
              [if (expectedType != voidMarker) expectedType]);
          return expectedType;
      }
    }

    Member? singleTarget = translator.singleTarget(node);
    if (singleTarget != null) {
      w.FunctionType targetFunctionType =
          translator.functions.getFunctionType(singleTarget.reference);
      wrap(node.receiver, targetFunctionType.inputs.first);
      _visitArguments(node.arguments, node.interfaceTargetReference, 1);
      return translator.outputOrVoid(call(singleTarget.reference));
    }
    return _virtualCall(node, target, _VirtualCallKind.Call,
        (signature) => wrap(node.receiver, signature.inputs.first), (_) {
      _visitArguments(node.arguments, node.interfaceTargetReference, 1);
    });
  }

  @override
  w.ValueType visitDynamicInvocation(
      DynamicInvocation node, w.ValueType expectedType) {
    // Call dynamic invocation forwarder
    final receiver = node.receiver;
    final typeArguments = node.arguments.types;
    final positionalArguments = node.arguments.positional;
    final namedArguments = node.arguments.named;
    final forwarder = translator.dynamicForwarders
        .getDynamicInvocationForwarder(node.name.text);

    // Evaluate receiver
    wrap(receiver, translator.topInfo.nullableType);
    final nullableReceiverLocal =
        function.addLocal(translator.topInfo.nullableType);
    b.local_set(nullableReceiverLocal);

    // Evaluate type arguments. Type argument list is growable as we may want
    // to add default bounds when the callee has type parameters but no type
    // arguments are passed.
    makeList(InterfaceType(translator.typeClass, Nullability.nonNullable),
        typeArguments.length, (elementType, elementIdx) {
      translator.types.makeType(this, typeArguments[elementIdx]);
    }, isGrowable: true);
    final typeArgsLocal = function.addLocal(
        translator.classInfo[translator.growableListClass]!.nonNullableType);
    b.local_set(typeArgsLocal);

    // Evaluate positional arguments
    makeList(DynamicType(), positionalArguments.length,
        (elementType, elementIdx) {
      wrap(positionalArguments[elementIdx], elementType);
    }, isGrowable: false);
    final positionalArgsLocal = function.addLocal(
        translator.classInfo[translator.fixedLengthListClass]!.nonNullableType);
    b.local_set(positionalArgsLocal);

    // Evaluate named arguments. The arguments need to be evaluated in the
    // order they appear in the AST, but need to be sorted based on names in
    // the argument list passed to the dynamic forwarder. Create a local for
    // each argument to allow adding values to the list in expected order.
    final List<MapEntry<String, w.Local>> namedArgumentLocals = [];
    for (final namedArgument in namedArguments) {
      wrap(namedArgument.value, translator.topInfo.nullableType);
      final argumentLocal = function.addLocal(translator.topInfo.nullableType);
      b.local_set(argumentLocal);
      namedArgumentLocals.add(MapEntry(namedArgument.name, argumentLocal));
    }
    namedArgumentLocals.sort((e1, e2) => e1.key.compareTo(e2.key));

    // Create named argument list
    makeList(DynamicType(), namedArguments.length * 2,
        (elementType, elementIdx) {
      if (elementIdx % 2 == 0) {
        final name = namedArgumentLocals[elementIdx ~/ 2].key;
        final w.ValueType symbolValueType =
            translator.classInfo[translator.symbolClass]!.nonNullableType;
        translator.constants.instantiateConstant(
            function, b, SymbolConstant(name, null), symbolValueType);
      } else {
        final local = namedArgumentLocals[elementIdx ~/ 2].value;
        b.local_get(local);
      }
    }, isGrowable: false);
    final namedArgsLocal = function.addLocal(
        translator.classInfo[translator.fixedLengthListClass]!.nonNullableType);
    b.local_set(namedArgsLocal);

    final nullBlock = b.block([], [translator.topInfo.nonNullableType]);
    b.local_get(nullableReceiverLocal);
    b.br_on_non_null(nullBlock);
    // Throw `NoSuchMethodError`. Normally this needs to happen via instance
    // invocation of `noSuchMethod` (done in [_callNoSuchMethod]), but we don't
    // have a `Null` class in dart2wasm so we throw directly.
    b.local_get(nullableReceiverLocal);
    createInvocationObject(translator, function, forwarder.memberName,
        typeArgsLocal, positionalArgsLocal, namedArgsLocal);

    call(translator.noSuchMethodErrorThrowWithInvocation.reference);
    b.unreachable();
    b.end(); // nullBlock

    b.local_get(typeArgsLocal);
    b.local_get(positionalArgsLocal);
    b.local_get(namedArgsLocal);
    b.call(forwarder.function);

    return translator.topInfo.nullableType;
  }

  @override
  w.ValueType visitEqualsCall(EqualsCall node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult = intrinsifier.generateEqualsIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    Member? singleTarget = translator.singleTarget(node);
    if (singleTarget == translator.coreTypes.objectEquals) {
      // Plain reference comparison
      wrap(node.left, w.RefType.eq(nullable: true));
      wrap(node.right, w.RefType.eq(nullable: true));
      b.ref_eq();
    } else {
      // Check operands for null, then call implementation
      bool leftNullable = dartTypeOf(node.left).isPotentiallyNullable;
      bool rightNullable = dartTypeOf(node.right).isPotentiallyNullable;
      w.RefType leftType = translator.topInfo.typeWithNullability(leftNullable);
      w.RefType rightType =
          translator.topInfo.typeWithNullability(rightNullable);
      w.Local leftLocal = addLocal(leftType);
      w.Local rightLocal = addLocal(rightType);
      w.Label? operandNull;
      w.Label? done;
      if (leftNullable || rightNullable) {
        done = b.block(const [], const [w.NumType.i32]);
        operandNull = b.block();
      }
      wrap(node.left, leftLocal.type);
      b.local_set(leftLocal);
      wrap(node.right, rightLocal.type);
      if (rightNullable) {
        b.local_tee(rightLocal);
        b.br_on_null(operandNull!);
        b.drop();
      } else {
        b.local_set(rightLocal);
      }

      void left([_]) {
        b.local_get(leftLocal);
        if (leftNullable) {
          b.br_on_null(operandNull!);
        }
      }

      void right([_]) {
        b.local_get(rightLocal);
        if (rightNullable) {
          b.ref_as_non_null();
        }
      }

      if (singleTarget != null) {
        left();
        right();
        call(singleTarget.reference);
      } else {
        _virtualCall(
          node,
          node.interfaceTarget,
          _VirtualCallKind.Call,
          left,
          right,
        );
      }
      if (leftNullable || rightNullable) {
        b.br(done!);
        b.end(); // operandNull
        if (leftNullable && rightNullable) {
          // Both sides nullable - compare references
          b.local_get(leftLocal);
          b.local_get(rightLocal);
          b.ref_eq();
        } else {
          // Only one side nullable - not equal if one is null
          b.i32_const(0);
        }
        b.end(); // done
      }
    }
    return w.NumType.i32;
  }

  @override
  w.ValueType visitEqualsNull(EqualsNull node, w.ValueType expectedType) {
    wrap(node.expression, const w.RefType.any(nullable: true));
    b.ref_is_null();
    return w.NumType.i32;
  }

  w.ValueType _virtualCall(
      TreeNode node,
      Member interfaceTarget,
      _VirtualCallKind kind,
      void pushReceiver(w.FunctionType signature),
      void pushArguments(w.FunctionType signature)) {
    SelectorInfo selector = translator.dispatchTable.selectorForTarget(
        interfaceTarget.referenceAs(
            getter: kind.isGetter, setter: kind.isSetter));
    assert(selector.name == interfaceTarget.name.text);

    pushReceiver(selector.signature);

    if (selector.targetCount == 1) {
      pushArguments(selector.signature);
      return translator.outputOrVoid(call(selector.singularTarget!));
    }

    int? offset = selector.offset;
    if (offset == null) {
      // Unreachable call
      assert(selector.targetCount == 0);
      b.comment("Virtual call of ${selector.name} with no targets"
          " at ${node.location}");
      b.drop();
      b.block(const [], selector.signature.outputs);
      b.unreachable();
      b.end();
      return translator.outputOrVoid(selector.signature.outputs);
    }

    // Receiver is already on stack.
    w.Local receiverVar = addLocal(selector.signature.inputs.first);
    assert(!receiverVar.type.nullable);
    b.local_tee(receiverVar);
    pushArguments(selector.signature);

    if (options.polymorphicSpecialization) {
      _polymorphicSpecialization(selector, receiverVar);
    } else {
      b.comment("Instance $kind of '${selector.name}'");
      b.local_get(receiverVar);
      b.struct_get(translator.topInfo.struct, FieldIndex.classId);
      if (offset != 0) {
        b.i32_const(offset);
        b.i32_add();
      }
      b.call_indirect(selector.signature, translator.dispatchTable.wasmTable);

      translator.functions.activateSelector(selector);
    }

    return translator.outputOrVoid(selector.signature.outputs);
  }

  void _polymorphicSpecialization(SelectorInfo selector, w.Local receiver) {
    Map<int, Reference> implementations = Map.from(selector.targets);
    implementations.removeWhere((id, target) => target.asMember.isAbstract);

    w.Local idVar = addLocal(w.NumType.i32);
    b.local_get(receiver);
    b.struct_get(translator.topInfo.struct, FieldIndex.classId);
    b.local_set(idVar);

    w.Label block =
        b.block(selector.signature.inputs, selector.signature.outputs);
    calls:
    while (Set.from(implementations.values).length > 1) {
      for (int id in implementations.keys) {
        Reference target = implementations[id]!;
        if (implementations.values.where((t) => t == target).length == 1) {
          // Single class id implements method.
          b.local_get(idVar);
          b.i32_const(id);
          b.i32_eq();
          b.if_(selector.signature.inputs, selector.signature.inputs);
          call(target);
          b.br(block);
          b.end();
          implementations.remove(id);
          continue calls;
        }
      }
      // Find class id that separates remaining classes in two.
      List<int> sorted = implementations.keys.toList()..sort();
      int pivotId = sorted.firstWhere(
          (id) => implementations[id] != implementations[sorted.first]);
      // Fail compilation if no such id exists.
      assert(sorted.lastWhere(
              (id) => implementations[id] != implementations[pivotId]) ==
          pivotId - 1);
      Reference target = implementations[sorted.first]!;
      b.local_get(idVar);
      b.i32_const(pivotId);
      b.i32_lt_u();
      b.if_(selector.signature.inputs, selector.signature.inputs);
      call(target);
      b.br(block);
      b.end();
      for (int id in sorted) {
        if (id == pivotId) break;
        implementations.remove(id);
      }
      continue calls;
    }
    // Call remaining implementation.
    Reference target = implementations.values.first;
    call(target);
    b.end();
  }

  @override
  w.ValueType visitVariableGet(VariableGet node, w.ValueType expectedType) {
    // Return `void` for a void [VariableGet].
    if (node.variable.type is VoidType) {
      return voidMarker;
    }
    w.Local? local = locals[node.variable];
    Capture? capture = closures.captures[node.variable];
    if (capture != null) {
      if (!capture.written && local != null) {
        b.local_get(local);
        return local.type;
      } else {
        b.local_get(capture.context.currentLocal);
        b.struct_get(capture.context.struct, capture.fieldIndex);
        return capture.type;
      }
    } else {
      if (local == null) {
        throw "Read of undefined variable ${node.variable}";
      }
      b.local_get(local);
      return local.type;
    }
  }

  @override
  w.ValueType visitVariableSet(VariableSet node, w.ValueType expectedType) {
    // Return `void` for a void [VariableSet].
    if (node.variable.type is VoidType) {
      return wrap(node.value, voidMarker);
    }
    w.Local? local = locals[node.variable];
    Capture? capture = closures.captures[node.variable];
    bool preserved = expectedType != voidMarker;
    if (capture != null) {
      assert(capture.written);
      b.local_get(capture.context.currentLocal);
      wrap(node.value, capture.type);
      if (preserved) {
        w.Local temp = addLocal(capture.type);
        b.local_tee(temp);
        b.struct_set(capture.context.struct, capture.fieldIndex);
        b.local_get(temp);
        return temp.type;
      } else {
        b.struct_set(capture.context.struct, capture.fieldIndex);
        return voidMarker;
      }
    } else {
      if (local == null) {
        throw "Write of undefined variable ${node.variable}";
      }
      wrap(node.value, local.type);
      if (preserved) {
        b.local_tee(local);
        return local.type;
      } else {
        b.local_set(local);
        return voidMarker;
      }
    }
  }

  @override
  w.ValueType visitStaticGet(StaticGet node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult =
        intrinsifier.generateStaticGetterIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    Member target = node.target;
    if (target is Field) {
      return translator.globals.readGlobal(b, target);
    } else {
      return translator.outputOrVoid(call(target.reference));
    }
  }

  @override
  w.ValueType visitStaticTearOff(StaticTearOff node, w.ValueType expectedType) {
    translator.constants.instantiateConstant(
        function, b, StaticTearOffConstant(node.target), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitStaticSet(StaticSet node, w.ValueType expectedType) {
    bool preserved = expectedType != voidMarker;
    Member target = node.target;
    if (target is Field) {
      w.Global global = translator.globals.getGlobal(target);
      w.Global? flag = translator.globals.getGlobalInitializedFlag(target);
      wrap(node.value, global.type.type);
      b.global_set(global);
      if (flag != null) {
        b.i32_const(1); // true
        b.global_set(flag);
      }
      if (preserved) {
        b.global_get(global);
        return global.type.type;
      } else {
        return voidMarker;
      }
    } else {
      w.FunctionType targetFunctionType =
          translator.functions.getFunctionType(target.reference);
      w.ValueType paramType = targetFunctionType.inputs.single;
      wrap(node.value, paramType);
      w.Local? temp;
      if (preserved) {
        temp = addLocal(paramType);
        b.local_tee(temp);
      }
      call(target.reference);
      if (preserved) {
        b.local_get(temp!);
        return temp.type;
      } else {
        return voidMarker;
      }
    }
  }

  @override
  w.ValueType visitSuperPropertyGet(
      SuperPropertyGet node, w.ValueType expectedType) {
    Member target = _lookupSuperTarget(node.interfaceTarget, setter: false);
    if (target is Procedure && !target.isGetter) {
      // Super tear-off
      w.StructType closureStruct = _pushClosure(
          translator.getTearOffClosure(target),
          translator.getTearOffType(target),
          () => visitThis(w.RefType.struct(nullable: false)));
      return w.RefType.def(closureStruct, nullable: false);
    }
    return _directGet(target, ThisExpression(), () => null);
  }

  @override
  w.ValueType visitSuperPropertySet(
      SuperPropertySet node, w.ValueType expectedType) {
    Member target = _lookupSuperTarget(node.interfaceTarget, setter: true);
    return _directSet(target, ThisExpression(), node.value,
        preserved: expectedType != voidMarker);
  }

  @override
  w.ValueType visitInstanceGet(InstanceGet node, w.ValueType expectedType) {
    Member target = node.interfaceTarget;
    if (node.kind == InstanceAccessKind.Object) {
      late w.Label doneLabel;
      w.ValueType resultType =
          _virtualCall(node, target, _VirtualCallKind.Get, (signature) {
        doneLabel = b.block(const [], signature.outputs);
        w.Label nullLabel = b.block();
        wrap(node.receiver, translator.topInfo.nullableType);
        b.br_on_null(nullLabel);
      }, (_) {});
      b.br(doneLabel);
      b.end(); // nullLabel
      switch (target.name.text) {
        case "hashCode":
          b.i64_const(2011);
          break;
        case "runtimeType":
          wrap(ConstantExpression(TypeLiteralConstant(NullType())), resultType);
          break;
        default:
          unimplemented(
              node, "Nullable get of ${target.name.text}", [resultType]);
          break;
      }
      b.end(); // doneLabel
      return resultType;
    }
    Member? singleTarget = translator.singleTarget(node);
    if (singleTarget != null) {
      return _directGet(singleTarget, node.receiver,
          () => intrinsifier.generateInstanceGetterIntrinsic(node));
    } else {
      return _virtualCall(node, target, _VirtualCallKind.Get,
          (signature) => wrap(node.receiver, signature.inputs.first), (_) {});
    }
  }

  @override
  w.ValueType visitDynamicGet(DynamicGet node, w.ValueType expectedType) {
    final receiver = node.receiver;
    final forwarder =
        translator.dynamicForwarders.getDynamicGetForwarder(node.name.text);

    // Evaluate receiver
    wrap(receiver, translator.topInfo.nullableType);
    final nullableReceiverLocal =
        function.addLocal(translator.topInfo.nullableType);
    b.local_set(nullableReceiverLocal);

    final nullBlock = b.block([], [translator.topInfo.nonNullableType]);
    b.local_get(nullableReceiverLocal);
    b.br_on_non_null(nullBlock);
    // Throw `NoSuchMethodError`. Normally this needs to happen via instance
    // invocation of `noSuchMethod` (done in [_callNoSuchMethod]), but we don't
    // have a `Null` class in dart2wasm so we throw directly.
    b.local_get(nullableReceiverLocal);
    createGetterInvocationObject(translator, function, forwarder.memberName);

    call(translator.noSuchMethodErrorThrowWithInvocation.reference);
    b.unreachable();
    b.end(); // nullBlock

    // Call get forwarder
    b.call(forwarder.function);

    return translator.topInfo.nullableType;
  }

  @override
  w.ValueType visitDynamicSet(DynamicSet node, w.ValueType expectedType) {
    final receiver = node.receiver;
    final value = node.value;
    final forwarder =
        translator.dynamicForwarders.getDynamicSetForwarder(node.name.text);

    // Evaluate receiver
    wrap(receiver, translator.topInfo.nullableType);
    final nullableReceiverLocal =
        function.addLocal(translator.topInfo.nullableType);
    b.local_set(nullableReceiverLocal);

    // Evaluate positional arg
    wrap(value, translator.topInfo.nullableType);
    final positionalArgLocal =
        function.addLocal(translator.topInfo.nullableType);
    b.local_set(positionalArgLocal);

    final nullBlock = b.block([], [translator.topInfo.nonNullableType]);
    b.local_get(nullableReceiverLocal);
    b.br_on_non_null(nullBlock);
    // Throw `NoSuchMethodError`. Normally this needs to happen via instance
    // invocation of `noSuchMethod` (done in [_callNoSuchMethod]), but we don't
    // have a `Null` class in dart2wasm so we throw directly.
    b.local_get(nullableReceiverLocal);
    createSetterInvocationObject(
        translator, function, forwarder.memberName, positionalArgLocal);

    call(translator.noSuchMethodErrorThrowWithInvocation.reference);
    b.unreachable();
    b.end(); // nullBlock

    // Call set forwarder
    b.local_get(positionalArgLocal);
    b.call(forwarder.function);

    return translator.topInfo.nullableType;
  }

  w.ValueType _directGet(
      Member target, Expression receiver, w.ValueType? Function() intrinsify) {
    w.ValueType? intrinsicResult = intrinsify();
    if (intrinsicResult != null) return intrinsicResult;

    if (target is Field) {
      ClassInfo info = translator.classInfo[target.enclosingClass]!;
      int fieldIndex = translator.fieldIndex[target]!;
      w.ValueType receiverType = info.nonNullableType;
      w.ValueType fieldType = info.struct.fields[fieldIndex].type.unpacked;
      wrap(receiver, receiverType);
      b.struct_get(info.struct, fieldIndex);
      return fieldType;
    } else {
      // Instance call of getter
      assert(target is Procedure && target.isGetter);
      w.FunctionType targetFunctionType =
          translator.functions.getFunctionType(target.reference);
      wrap(receiver, targetFunctionType.inputs.single);
      return translator.outputOrVoid(call(target.reference));
    }
  }

  @override
  w.ValueType visitInstanceTearOff(
      InstanceTearOff node, w.ValueType expectedType) {
    Member target = node.interfaceTarget;

    if (node.kind == InstanceAccessKind.Object) {
      late w.Label doneLabel;
      w.ValueType resultType =
          _virtualCall(node, target, _VirtualCallKind.Get, (signature) {
        doneLabel = b.block(const [], signature.outputs);
        w.Label nullLabel = b.block();
        wrap(node.receiver, translator.topInfo.nullableType);
        b.br_on_null(nullLabel);
        translator.convertType(
            function, translator.topInfo.nullableType, signature.inputs[0]);
      }, (_) {});
      b.br(doneLabel);
      b.end(); // nullLabel
      switch (target.name.text) {
        case "toString":
          wrap(
              ConstantExpression(
                  StaticTearOffConstant(translator.nullToString)),
              resultType);
          break;
        case "noSuchMethod":
          wrap(
              ConstantExpression(
                  StaticTearOffConstant(translator.nullNoSuchMethod)),
              resultType);
          break;
        default:
          unimplemented(
              node, "Nullable tear-off of ${target.name.text}", [resultType]);
          break;
      }
      b.end(); // doneLabel
      return resultType;
    }

    return _virtualCall(node, target, _VirtualCallKind.Get,
        (signature) => wrap(node.receiver, signature.inputs.first), (_) {});
  }

  @override
  w.ValueType visitInstanceSet(InstanceSet node, w.ValueType expectedType) {
    bool preserved = expectedType != voidMarker;
    w.Local? temp;
    Member? singleTarget = translator.singleTarget(node);
    if (singleTarget != null) {
      return _directSet(singleTarget, node.receiver, node.value,
          preserved: preserved);
    } else {
      _virtualCall(node, node.interfaceTarget, _VirtualCallKind.Set,
          (signature) => wrap(node.receiver, signature.inputs.first),
          (signature) {
        w.ValueType paramType = signature.inputs.last;
        wrap(node.value, paramType);
        if (preserved) {
          temp = addLocal(paramType);
          b.local_tee(temp!);
        }
      });
      if (preserved) {
        b.local_get(temp!);
        return temp!.type;
      } else {
        return voidMarker;
      }
    }
  }

  w.ValueType _directSet(Member target, Expression receiver, Expression value,
      {required bool preserved}) {
    w.Local? temp;
    if (target is Field) {
      ClassInfo info = translator.classInfo[target.enclosingClass]!;
      int fieldIndex = translator.fieldIndex[target]!;
      w.ValueType receiverType = info.nonNullableType;
      w.ValueType fieldType = info.struct.fields[fieldIndex].type.unpacked;
      wrap(receiver, receiverType);
      wrap(value, fieldType);
      if (preserved) {
        temp = addLocal(fieldType);
        b.local_tee(temp);
      }
      b.struct_set(info.struct, fieldIndex);
    } else {
      w.FunctionType targetFunctionType =
          translator.functions.getFunctionType(target.reference);
      w.ValueType paramType = targetFunctionType.inputs.last;
      wrap(receiver, targetFunctionType.inputs.first);
      wrap(value, paramType);
      if (preserved) {
        temp = addLocal(paramType);
        b.local_tee(temp);
      }
      call(target.reference);
    }
    if (preserved) {
      b.local_get(temp!);
      return temp.type;
    } else {
      return voidMarker;
    }
  }

  @override
  void visitFunctionDeclaration(FunctionDeclaration node) {
    Capture? capture = closures.captures[node.variable];
    bool locallyClosurized = closures.closurizedFunctions.contains(node);
    if (capture != null || locallyClosurized) {
      if (capture != null) {
        b.local_get(capture.context.currentLocal);
      }
      w.StructType struct = _instantiateClosure(node.function);
      if (locallyClosurized) {
        w.Local local = addLocal(w.RefType.def(struct, nullable: false));
        locals[node.variable] = local;
        if (capture != null) {
          b.local_tee(local);
        } else {
          b.local_set(local);
        }
      }
      if (capture != null) {
        b.struct_set(capture.context.struct, capture.fieldIndex);
      }
    }
  }

  @override
  w.ValueType visitFunctionExpression(
      FunctionExpression node, w.ValueType expectedType) {
    w.StructType struct = _instantiateClosure(node.function);
    return w.RefType.def(struct, nullable: false);
  }

  w.StructType _instantiateClosure(FunctionNode functionNode) {
    Lambda lambda = closures.lambdas[functionNode]!;
    ClosureImplementation closure = translator.getClosure(
        functionNode,
        lambda.function,
        ParameterInfo.fromLocalFunction(functionNode),
        "closure wrapper at ${functionNode.location}");
    return _pushClosure(
        closure,
        functionNode.computeFunctionType(Nullability.nonNullable),
        () => _pushContext(functionNode));
  }

  w.StructType _pushClosure(ClosureImplementation closure,
      DartType functionType, void pushContext()) {
    w.StructType struct = closure.representation.closureStruct;

    ClassInfo info = translator.closureInfo;
    translator.functions.allocateClass(info.classId);

    b.i32_const(info.classId);
    b.i32_const(initialIdentityHash);
    pushContext();
    b.global_get(closure.vtable);
    types.makeType(this, functionType);
    b.struct_new(struct);

    return struct;
  }

  void _pushContext(FunctionNode functionNode) {
    Context? context = closures.contexts[functionNode]?.parent;
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
      if (context.currentLocal.type.nullable) {
        b.ref_as_non_null();
      }
    } else {
      b.global_get(translator.globals.dummyStructGlobal); // Dummy context
    }
  }

  @override
  w.ValueType visitFunctionInvocation(
      FunctionInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult =
        intrinsifier.generateFunctionCallIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    if (node.kind == FunctionAccessKind.Function) {
      // Type of function is `Function`, without the argument types.
      return visitDynamicInvocation(
          DynamicInvocation(DynamicAccessKind.Dynamic, node.receiver, node.name,
              node.arguments),
          expectedType);
    }

    final Expression receiver = node.receiver;
    final Arguments arguments = node.arguments;

    int typeCount = arguments.types.length;
    int posArgCount = arguments.positional.length;
    List<String> argNames = arguments.named.map((a) => a.name).toList()..sort();
    ClosureRepresentation? representation = translator.closureLayouter
        .getClosureRepresentation(typeCount, posArgCount, argNames);
    if (representation == null) {
      // This is a dynamic function call with a signature that matches no
      // functions in the program.
      b.unreachable();
      return translator.topInfo.nullableType;
    }

    // Evaluate receiver
    w.StructType struct = representation.closureStruct;
    w.Local temp = addLocal(w.RefType.def(struct, nullable: false));
    wrap(receiver, temp.type);
    b.local_tee(temp);
    b.struct_get(struct, FieldIndex.closureContext);

    // Type arguments
    for (DartType typeArg in arguments.types) {
      types.makeType(this, typeArg);
    }

    // Positional arguments
    for (Expression arg in arguments.positional) {
      wrap(arg, translator.topInfo.nullableType);
    }

    // Named arguments
    final Map<String, w.Local> namedLocals = {};
    for (final namedArg in arguments.named) {
      final w.Local namedLocal = addLocal(translator.topInfo.nullableType);
      namedLocals[namedArg.name] = namedLocal;
      wrap(namedArg.value, namedLocal.type);
      b.local_set(namedLocal);
    }
    for (String name in argNames) {
      b.local_get(namedLocals[name]!);
    }

    // Call entry point in vtable
    int vtableFieldIndex =
        representation.fieldIndexForSignature(posArgCount, argNames);
    w.FunctionType functionType =
        representation.getVtableFieldType(vtableFieldIndex);
    b.local_get(temp);
    b.struct_get(struct, FieldIndex.closureVtable);
    b.struct_get(representation.vtableStruct, vtableFieldIndex);
    b.call_ref(functionType);
    return translator.topInfo.nullableType;
  }

  @override
  w.ValueType visitLocalFunctionInvocation(
      LocalFunctionInvocation node, w.ValueType expectedType) {
    var decl = node.variable.parent as FunctionDeclaration;
    Lambda lambda = closures.lambdas[decl.function]!;
    _pushContext(decl.function);
    Arguments arguments = node.arguments;
    visitArgumentsLists(arguments.positional, lambda.function.type,
        ParameterInfo.fromLocalFunction(decl.function), 1,
        typeArguments: arguments.types, named: arguments.named);
    b.comment("Local call of ${decl.variable.name}");
    b.call(lambda.function);
    return translator.outputOrVoid(lambda.function.type.outputs);
  }

  @override
  w.ValueType visitInstantiation(Instantiation node, w.ValueType expectedType) {
    DartType type = dartTypeOf(node.expression);
    if (type is FunctionType) {
      int typeCount = type.typeParameters.length;
      int posArgCount = type.positionalParameters.length;
      List<String> argNames = type.namedParameters.map((a) => a.name).toList();
      ClosureRepresentation representation = translator.closureLayouter
          .getClosureRepresentation(typeCount, posArgCount, argNames)!;

      // Operand closure
      w.RefType closureType =
          w.RefType.def(representation.closureStruct, nullable: false);
      w.Local closureTemp = addLocal(closureType);
      wrap(node.expression, closureType);
      b.local_tee(closureTemp);

      // Type arguments
      for (DartType typeArg in node.typeArguments) {
        types.makeType(this, typeArg);
      }

      // Instantiation function
      b.local_get(closureTemp);
      b.struct_get(representation.closureStruct, FieldIndex.closureVtable);
      b.struct_get(
          representation.vtableStruct, FieldIndex.vtableInstantiationFunction);

      // Call instantiation function
      b.call_ref(representation.instantiationFunctionType);
      return representation.instantiationFunctionType.outputs.single;
    } else {
      // Only other alternative is `NeverType`.
      assert(type is NeverType);
      b.unreachable();
      return voidMarker;
    }
  }

  @override
  w.ValueType visitLogicalExpression(
      LogicalExpression node, w.ValueType expectedType) {
    _conditional(node, () => b.i32_const(1), () => b.i32_const(0),
        const [w.NumType.i32]);
    return w.NumType.i32;
  }

  @override
  w.ValueType visitNot(Not node, w.ValueType expectedType) {
    wrap(node.operand, w.NumType.i32);
    b.i32_eqz();
    return w.NumType.i32;
  }

  @override
  w.ValueType visitConditionalExpression(
      ConditionalExpression node, w.ValueType expectedType) {
    _conditional(
        node.condition,
        () => wrap(node.then, expectedType),
        () => wrap(node.otherwise, expectedType),
        [if (expectedType != voidMarker) expectedType]);
    return expectedType;
  }

  @override
  w.ValueType visitNullCheck(NullCheck node, w.ValueType expectedType) {
    return _nullCheck(node.operand, translator.throwNullCheckError);
  }

  w.ValueType _nullCheck(Expression operand, Procedure errorProcedure) {
    w.ValueType operandType = translator.translateType(dartTypeOf(operand));
    w.ValueType nonNullOperandType = operandType.withNullability(false);
    w.Label nullCheckBlock = b.block(const [], [nonNullOperandType]);
    wrap(operand, operandType);

    // We lower a null check to a br_on_non_null, throwing a [TypeError] in the
    // null case.
    b.br_on_non_null(nullCheckBlock);
    call(translator.stackTraceCurrent.reference);
    call(errorProcedure.reference);
    b.unreachable();
    b.end();
    return nonNullOperandType;
  }

  void visitArgumentsLists(List<Expression> positional,
      w.FunctionType signature, ParameterInfo paramInfo, int signatureOffset,
      {List<DartType> typeArguments = const [],
      List<NamedExpression> named = const []}) {
    for (int i = 0; i < typeArguments.length; i++) {
      types.makeType(this, typeArguments[i]);
    }
    signatureOffset += typeArguments.length;
    for (int i = 0; i < positional.length; i++) {
      wrap(positional[i], signature.inputs[signatureOffset + i]);
    }
    // Default values for positional parameters
    for (int i = positional.length; i < paramInfo.positional.length; i++) {
      final w.ValueType type = signature.inputs[signatureOffset + i];
      translator.constants
          .instantiateConstant(function, b, paramInfo.positional[i]!, type);
    }
    // Named arguments
    final Map<String, w.Local> namedLocals = {};
    for (var namedArg in named) {
      final w.ValueType type = signature
          .inputs[signatureOffset + paramInfo.nameIndex[namedArg.name]!];
      final w.Local namedLocal = addLocal(type);
      namedLocals[namedArg.name] = namedLocal;
      wrap(namedArg.value, namedLocal.type);
      b.local_set(namedLocal);
    }
    for (String name in paramInfo.names) {
      w.Local? namedLocal = namedLocals[name];
      final w.ValueType type =
          signature.inputs[signatureOffset + paramInfo.nameIndex[name]!];
      if (namedLocal != null) {
        b.local_get(namedLocal);
      } else {
        translator.constants
            .instantiateConstant(function, b, paramInfo.named[name]!, type);
      }
    }
  }

  void _visitArguments(Arguments node, Reference target, int signatureOffset) {
    final w.FunctionType signature = translator.signatureFor(target);
    final ParameterInfo paramInfo = translator.paramInfoFor(target);
    visitArgumentsLists(node.positional, signature, paramInfo, signatureOffset,
        typeArguments: node.types, named: node.named);
  }

  @override
  w.ValueType visitStringConcatenation(
      StringConcatenation node, w.ValueType expectedType) {
    bool isConstantString(Expression expr) =>
        expr is StringLiteral ||
        (expr is ConstantExpression && expr.constant is StringConstant);

    String extractConstantString(Expression expr) {
      if (expr is StringLiteral) {
        return expr.value;
      } else {
        return ((expr as ConstantExpression).constant as StringConstant).value;
      }
    }

    if (node.expressions.every(isConstantString)) {
      StringBuffer result = StringBuffer();
      for (final expr in node.expressions) {
        result.write(extractConstantString(expr));
      }
      final expr = StringLiteral(result.toString());
      return visitStringLiteral(expr, expectedType);
    }

    makeListFromExpressions(
        node.expressions,
        InterfaceType(
            translator.coreTypes.stringClass, Nullability.nonNullable));
    return translator.outputOrVoid(call(translator.options.jsCompatibility
        ? translator.jsStringInterpolate.reference
        : translator.stringInterpolate.reference));
  }

  @override
  w.ValueType visitThrow(Throw node, w.ValueType expectedType) {
    // Front-end wraps the argument with `as Object` when necessary, so we can
    // assume non-nullable here.
    assert(!dartTypeOf(node.expression).isPotentiallyNullable);
    wrap(node.expression, translator.topInfo.nonNullableType);
    call(translator.stackTraceCurrent.reference);
    call(translator.errorThrow.reference);
    b.unreachable();
    return expectedType;
  }

  @override
  w.ValueType visitRethrow(Rethrow node, w.ValueType expectedType) {
    b.rethrow_(tryLabels.last);
    return expectedType;
  }

  @override
  w.ValueType visitConstantExpression(
      ConstantExpression node, w.ValueType expectedType) {
    translator.constants
        .instantiateConstant(function, b, node.constant, expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitNullLiteral(NullLiteral node, w.ValueType expectedType) {
    translator.constants
        .instantiateConstant(function, b, NullConstant(), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitStringLiteral(StringLiteral node, w.ValueType expectedType) {
    translator.constants.instantiateConstant(
        function, b, StringConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitBoolLiteral(BoolLiteral node, w.ValueType expectedType) {
    translator.constants.instantiateConstant(
        function, b, BoolConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitIntLiteral(IntLiteral node, w.ValueType expectedType) {
    translator.constants.instantiateConstant(
        function, b, IntConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitDoubleLiteral(DoubleLiteral node, w.ValueType expectedType) {
    translator.constants.instantiateConstant(
        function, b, DoubleConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitListLiteral(ListLiteral node, w.ValueType expectedType) {
    return makeListFromExpressions(node.expressions, node.typeArgument,
        isGrowable: true);
  }

  /// Allocate a Dart `List` with element type [typeArg], length [length] and
  /// push the list to the stack.
  ///
  /// [generateItem] will be called [length] times to initialize list elements.
  ///
  /// Concrete type of the list will be `_GrowableList` if [isGrowable] is
  /// true, `_List` otherwise.
  w.ValueType makeList(DartType typeArg, int length,
      void Function(w.ValueType, int) generateItem,
      {bool isGrowable = false}) {
    return translator.makeList(
        function, (b) => types.makeType(this, typeArg), length, generateItem,
        isGrowable: isGrowable);
  }

  w.ValueType makeListFromExpressions(
          List<Expression> expressions, DartType typeArg,
          {bool isGrowable = false}) =>
      makeList(typeArg, expressions.length,
          (w.ValueType elementType, int i) => wrap(expressions[i], elementType),
          isGrowable: isGrowable);

  @override
  w.ValueType visitMapLiteral(MapLiteral node, w.ValueType expectedType) {
    types.makeType(this, node.keyType);
    types.makeType(this, node.valueType);
    w.ValueType factoryReturnType =
        call(translator.mapFactory.reference).single;
    if (node.entries.isEmpty) {
      return factoryReturnType;
    }
    w.FunctionType mapPutType =
        translator.functions.getFunctionType(translator.mapPut.reference);
    w.ValueType putReceiverType = mapPutType.inputs[0];
    w.ValueType putKeyType = mapPutType.inputs[1];
    w.ValueType putValueType = mapPutType.inputs[2];
    w.Local mapLocal = addLocal(putReceiverType);
    translator.convertType(function, factoryReturnType, mapLocal.type);
    b.local_set(mapLocal);
    for (MapLiteralEntry entry in node.entries) {
      b.local_get(mapLocal);
      wrap(entry.key, putKeyType);
      wrap(entry.value, putValueType);
      call(translator.mapPut.reference);
      b.drop();
    }
    b.local_get(mapLocal);
    return mapLocal.type;
  }

  @override
  w.ValueType visitSetLiteral(SetLiteral node, w.ValueType expectedType) {
    types.makeType(this, node.typeArgument);
    w.ValueType factoryReturnType =
        call(translator.setFactory.reference).single;
    if (node.expressions.isEmpty) {
      return factoryReturnType;
    }
    w.FunctionType setAddType =
        translator.functions.getFunctionType(translator.setAdd.reference);
    w.ValueType addReceiverType = setAddType.inputs[0];
    w.ValueType addKeyType = setAddType.inputs[1];
    w.Local setLocal = addLocal(addReceiverType);
    translator.convertType(function, factoryReturnType, setLocal.type);
    b.local_set(setLocal);
    for (Expression element in node.expressions) {
      b.local_get(setLocal);
      wrap(element, addKeyType);
      call(translator.setAdd.reference);
      b.drop();
    }
    b.local_get(setLocal);
    return setLocal.type;
  }

  @override
  w.ValueType visitTypeLiteral(TypeLiteral node, w.ValueType expectedType) {
    return types.makeType(this, node.type);
  }

  @override
  w.ValueType visitIsExpression(IsExpression node, w.ValueType expectedType) {
    wrap(node.operand, translator.topInfo.nullableType);
    types.emitTypeTest(this, node.type, dartTypeOf(node.operand));
    return w.NumType.i32;
  }

  @override
  w.ValueType visitAsExpression(AsExpression node, w.ValueType expectedType) {
    if (translator.options.omitTypeChecks || node.isUnchecked) {
      return wrap(node.operand, expectedType);
    }

    w.Label asCheckBlock = b.block();
    wrap(node.operand, translator.topInfo.nullableType);
    w.Local operand = addLocal(translator.topInfo.nullableType);
    b.local_tee(operand);

    // We lower an `as` expression to a type test, throwing a [TypeError] if
    // the type test fails.
    types.emitTypeTest(this, node.type, dartTypeOf(node.operand));
    b.br_if(asCheckBlock);
    b.local_get(operand);
    types.makeType(this, node.type);
    call(translator.stackTraceCurrent.reference);
    call(translator.throwAsCheckError.reference);
    b.unreachable();
    b.end();
    b.local_get(operand);
    return operand.type;
  }

  @override
  w.ValueType visitLoadLibrary(LoadLibrary node, w.ValueType expectedType) {
    LibraryDependency import = node.import;
    _emitString(import.enclosingLibrary.importUri.toString());
    _emitString(import.name!);
    return translator.outputOrVoid(call(translator.loadLibrary.reference));
  }

  @override
  w.ValueType visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, w.ValueType expectedType) {
    LibraryDependency import = node.import;
    _emitString(import.enclosingLibrary.importUri.toString());
    _emitString(import.name!);
    return translator
        .outputOrVoid(call(translator.checkLibraryIsLoaded.reference));
  }

  /// Pushes the `_Type` object for a function or class type parameter to the
  /// stack and returns the value type of the object.
  w.ValueType instantiateTypeParameter(TypeParameter parameter) {
    w.ValueType resultType;

    // `this` will not be initialized yet for constructor initializer lists
    if (parameter.declaration is GenericFunction ||
        reference.isInitializerReference) {
      // Type argument to function
      w.Local? local = typeLocals[parameter];
      if (local != null) {
        b.local_get(local);
        resultType = local.type;
      } else {
        Capture capture = closures.captures[parameter]!;
        b.local_get(capture.context.currentLocal);
        b.struct_get(capture.context.struct, capture.fieldIndex);
        resultType = capture.type;
      }
    } else {
      // Type argument of class
      Class cls = parameter.declaration as Class;
      ClassInfo info = translator.classInfo[cls]!;
      int fieldIndex = translator.typeParameterIndex[parameter]!;
      visitThis(info.nonNullableType);
      b.struct_get(info.struct, fieldIndex);
      resultType = info.struct.fields[fieldIndex].type.unpacked;
    }
    translator.convertType(function, resultType, types.nonNullableTypeType);
    return types.nonNullableTypeType;
  }

  @override
  w.ValueType visitRecordLiteral(RecordLiteral node, w.ValueType expectedType) {
    final ClassInfo recordClassInfo =
        translator.getRecordClassInfo(node.recordType);
    translator.functions.allocateClass(recordClassInfo.classId);

    b.i32_const(recordClassInfo.classId);
    b.i32_const(initialIdentityHash);
    for (Expression positional in node.positional) {
      wrap(positional, translator.topInfo.nullableType);
    }
    for (NamedExpression named in node.named) {
      wrap(named.value, translator.topInfo.nullableType);
    }
    b.struct_new(recordClassInfo.struct);

    return recordClassInfo.nonNullableType;
  }

  @override
  w.ValueType visitRecordIndexGet(
      RecordIndexGet node, w.ValueType expectedType) {
    final RecordShape recordShape = RecordShape.fromType(node.receiverType);
    final ClassInfo recordClassInfo =
        translator.getRecordClassInfo(node.receiverType);
    translator.functions.allocateClass(recordClassInfo.classId);

    wrap(node.receiver, translator.topInfo.nonNullableType);
    b.ref_cast(w.RefType(recordClassInfo.struct, nullable: false));
    b.struct_get(
        recordClassInfo.struct, recordShape.getPositionalIndex(node.index));

    return translator.topInfo.nullableType;
  }

  @override
  w.ValueType visitRecordNameGet(RecordNameGet node, w.ValueType expectedType) {
    final RecordShape recordShape = RecordShape.fromType(node.receiverType);
    final ClassInfo recordClassInfo =
        translator.getRecordClassInfo(node.receiverType);
    translator.functions.allocateClass(recordClassInfo.classId);

    wrap(node.receiver, translator.topInfo.nonNullableType);
    b.ref_cast(w.RefType(recordClassInfo.struct, nullable: false));
    b.struct_get(recordClassInfo.struct, recordShape.getNameIndex(node.name));

    return translator.topInfo.nullableType;
  }

  // Generates a function for a constructor's body, where the allocated struct
  // object is passed to this function.
  void generateConstructorBody(Reference target) {
    assert(target.isConstructorBodyReference);
    Constructor member = target.asConstructor;

    setupConstructorBodyParametersAndContexts(target);

    int getStartIndexForSuperOrRedirectedConstructorArguments() {
      // Skips the receiver param and the current constructor's context
      // (if it exists)
      Context? context = closures.contexts[member];
      bool hasContext = context != null;

      if (hasContext) {
        assert(!context.isEmpty);
      }

      int numSkippedParams = hasContext ? 2 : 1;

      // Skips the current constructor's arguments
      int numConstructorArgs = _getConstructorArgumentLocals(target).length;

      return numSkippedParams + numConstructorArgs;
    }

    // Call super class' constructor body, or redirected constructor
    for (Initializer initializer in member.initializers) {
      if (initializer is SuperInitializer ||
          initializer is RedirectingInitializer) {
        Constructor target = initializer is SuperInitializer
            ? initializer.target
            : (initializer as RedirectingInitializer).target;

        Supertype? supersupertype = target.enclosingClass.supertype;

        if (supersupertype == null) {
          break;
        }

        int startIndex =
            getStartIndexForSuperOrRedirectedConstructorArguments();

        List<w.Local> superOrRedirectedConstructorArgs =
            paramLocals.sublist(startIndex);

        w.Local object = thisLocal!;
        b.local_get(object);

        for (w.Local local in superOrRedirectedConstructorArgs) {
          b.local_get(local);
        }

        call(target.constructorBodyReference);
        break;
      }
    }

    Statement? body = member.function.body;

    if (body != null) {
      visitStatement(body);
    }

    b.end();
  }

  // Generates a constructor's initializer list method, and returns:
  // 1. Arguments and contexts returned from a super or redirecting initializer
  //    method (in reverse order).
  // 2. Arguments for this constructor (in reverse order).
  // 3. A reference to the context for this constructor (or null if there is no
  //    context).
  // 4. Class fields (including superclass fields, excluding class id and
  //    identity hash).
  void generateInitializerList(Reference target) {
    assert(target.isInitializerReference);
    Constructor member = target.asConstructor;

    setupInitializerListParametersAndContexts(target);

    Class cls = member.enclosingClass;
    ClassInfo info = translator.classInfo[cls]!;

    List<w.Local> initializedFields = _generateInitializers(member);
    bool containsSuperInitializer = false;
    bool containsRedirectingInitializer = false;

    for (Initializer initializer in member.initializers) {
      if (initializer is SuperInitializer) {
        containsSuperInitializer = true;
      } else if (initializer is RedirectingInitializer) {
        containsRedirectingInitializer = true;
      }
    }

    if (cls.superclass != null && !containsRedirectingInitializer) {
      // checks if a SuperInitializer was dropped because the constructor body
      // throws an error
      if (!containsSuperInitializer) {
        b.unreachable();
        b.end();
        return;
      }

      // checks if a FieldInitializer was dropped because the constructor body
      // throws an error
      for (Field field in info.cls!.fields) {
        if (field.isInstanceMember && !fieldLocals.containsKey(field)) {
          b.unreachable();
          b.end();
          return;
        }
      }
    }

    // push constructor arguments
    List<w.Local> constructorArgs =
        _getConstructorArgumentLocals(member.reference, true);

    for (w.Local arg in constructorArgs) {
      b.local_get(arg);
    }

    // push reference to context
    Context? context = closures.contexts[member];
    if (context != null) {
      assert(!context.isEmpty);
      b.local_get(context.currentLocal);
    }

    // push initialized fields
    for (w.Local field in initializedFields) {
      b.local_get(field);
    }

    b.end();
  }

  /// Generate type checker method for a setter.
  ///
  /// This function will be called by a setter forwarder in a dynamic set to
  /// type check the setter argument before calling the actual setter.
  void _generateFieldSetterTypeCheckerMethod() {
    final receiverLocal = function.locals[0];
    final positionalArgLocal = function.locals[1];

    _initializeThis(member.reference);

    // Local for the argument.
    final argLocal = addLocal(translator.topInfo.nullableType);

    // Local for the expected type of the argument.
    final typeType =
        translator.classInfo[translator.typeClass]!.nonNullableType;
    final argTypeLocal = addLocal(typeType);

    final member_ = member;
    DartType paramType;
    if (member_ is Field) {
      paramType = member_.type;
    } else {
      paramType = (member_ as Procedure).setterType;
    }

    _generateArgumentTypeCheck(
      member.name.text,
      () => b.local_get(positionalArgLocal),
      () => types.makeType(this, paramType),
      argLocal,
      argTypeLocal,
    );

    ClassInfo info = translator.classInfo[member_.enclosingClass]!;
    if (member_ is Field) {
      int fieldIndex = translator.fieldIndex[member_]!;
      b.local_get(receiverLocal);
      translator.convertType(
          function, receiverLocal.type, info.nonNullableType);
      b.local_get(argLocal);
      translator.convertType(function, argLocal.type,
          info.struct.fields[fieldIndex].type.unpacked);
      b.struct_set(info.struct, fieldIndex);
    } else {
      final setterProcedure = member_ as Procedure;
      final setterProcedureWasmType =
          translator.functions.getFunctionType(setterProcedure.reference);
      final setterWasmInputs = setterProcedureWasmType.inputs;
      assert(setterWasmInputs.length == 2);
      b.local_get(receiverLocal);
      translator.convertType(function, receiverLocal.type, setterWasmInputs[0]);
      b.local_get(argLocal);
      translator.convertType(function, argLocal.type, setterWasmInputs[1]);
      call(setterProcedure.reference);
    }

    b.local_get(argLocal);
    b.end(); // end function
  }

  /// Generate type checker method for a method.
  ///
  /// This function will be called by an invocation forwarder in a dynamic
  /// invocation to type check parameters before calling the actual method.
  void _generateProcedureTypeCheckerMethod() {
    final receiverLocal = function.locals[0];
    final typeArgsLocal = function.locals[1];
    final positionalArgsLocal = function.locals[2];
    final namedArgsLocal = function.locals[3];

    _initializeThis(member.reference);

    final typeType =
        translator.classInfo[translator.typeClass]!.nonNullableType;

    final targetParamInfo = translator.paramInfoFor(member.reference);

    final procedure = member as Procedure;

    // Bind type parameters
    final memberTypeParams = procedure.function.typeParameters;
    assert(memberTypeParams.length == targetParamInfo.typeParamCount);

    if (memberTypeParams.isNotEmpty) {
      // Type argument list is either empty or have the right number of types
      // (checked by the forwarder).
      b.local_get(typeArgsLocal);
      translator.getListLength(b);
      b.i32_eqz();
      b.if_([], List.generate(memberTypeParams.length, (_) => typeType));
      // No type arguments passed, initialize with defaults
      for (final typeParam in memberTypeParams) {
        types.makeType(this, typeParam.defaultType);
      }
      b.else_();
      for (int typeParamIdx = 0;
          typeParamIdx < memberTypeParams.length;
          typeParamIdx += 1) {
        b.local_get(typeArgsLocal);
        translator.indexList(b, (b) => b.i32_const(typeParamIdx));
        translator.convertType(
            function, translator.topInfo.nullableType, typeType);
      }
      b.end();

      // Create locals for type parameters. These will be used by `makeType`
      // below when generating types of parameters, for type checks, and when
      // pushing the type parameters when calling the actual member.
      for (int typeParamIdx = memberTypeParams.length - 1;
          typeParamIdx >= 0;
          typeParamIdx -= 1) {
        final local = addLocal(typeType);
        b.local_set(local);
        typeLocals[memberTypeParams[typeParamIdx]] = local;
      }
    }

    if (!translator.options.omitTypeChecks) {
      // Check type parameter bounds
      for (TypeParameter typeParameter in memberTypeParams) {
        if (typeParameter.bound != translator.coreTypes.objectNullableRawType) {
          _generateTypeArgumentBoundCheck(typeParameter.name!,
              typeLocals[typeParameter]!, typeParameter.bound);
        }
      }

      // Check positional argument types
      final List<VariableDeclaration> memberPositionalParams =
          procedure.function.positionalParameters;

      // Local for the current argument being checked. Used to avoid indexing the
      // positional parameters array again when throwing type error.
      final argLocal = addLocal(translator.topInfo.nullableType);

      // Local for the expected type of the current positional arguments. Used to
      // avoid generating the type again when throwing type error.
      final argTypeLocal = addLocal(typeType);

      for (int positionalParamIdx = 0;
          positionalParamIdx < memberPositionalParams.length;
          positionalParamIdx += 1) {
        final param = memberPositionalParams[positionalParamIdx];
        _generateArgumentTypeCheck(
          param.name!,
          () {
            b.local_get(positionalArgsLocal);
            translator.indexList(b, (b) => b.i32_const(positionalParamIdx));
          },
          () {
            types.makeType(this, param.type);
          },
          argLocal,
          argTypeLocal,
        );
      }

      // Check named argument types
      final memberNamedParams = procedure.function.namedParameters;

      /// Maps a named parameter in the member's signature to the parameter's
      /// index in the array [namedArgsLocal].
      int mapNamedParameterToArrayIndex(String name) {
        int? idx;
        for (int i = 0; i < targetParamInfo.names.length; i += 1) {
          if (targetParamInfo.names[i] == name) {
            idx = i;
            break;
          }
        }
        return idx!;
      }

      for (int namedParamIdx = 0;
          namedParamIdx < memberNamedParams.length;
          namedParamIdx += 1) {
        final param = memberNamedParams[namedParamIdx];
        _generateArgumentTypeCheck(
          param.name!,
          () {
            b.local_get(namedArgsLocal);
            translator.indexList(b,
                (b) => b.i32_const(mapNamedParameterToArrayIndex(param.name!)));
          },
          () {
            types.makeType(this, param.type);
          },
          argLocal,
          argTypeLocal,
        );
      }
    }

    // Argument types are as expected, call the member function
    final w.FunctionType memberWasmFunctionType =
        translator.functions.getFunctionType(member.reference);
    final List<w.ValueType> memberWasmInputs = memberWasmFunctionType.inputs;

    b.local_get(receiverLocal);
    translator.convertType(function, receiverLocal.type, memberWasmInputs[0]);

    for (final typeParam in memberTypeParams) {
      b.local_get(typeLocals[typeParam]!);
    }

    int memberParamIdx =
        1 + targetParamInfo.typeParamCount; // skip receiver and type args

    void pushArgument(w.Local listLocal, int listIdx, int wasmInputIdx) {
      b.local_get(listLocal);
      translator.indexList(b, (b) => b.i32_const(listIdx));
      translator.convertType(function, translator.topInfo.nullableType,
          memberWasmInputs[wasmInputIdx]);
    }

    for (int positionalParamIdx = 0;
        positionalParamIdx < targetParamInfo.positional.length;
        positionalParamIdx += 1) {
      pushArgument(positionalArgsLocal, positionalParamIdx, memberParamIdx);
      memberParamIdx += 1;
    }

    for (int namedParamIdx = 0;
        namedParamIdx < targetParamInfo.names.length;
        namedParamIdx += 1) {
      pushArgument(namedArgsLocal, namedParamIdx, memberParamIdx);
      memberParamIdx += 1;
    }

    call(member.reference);

    translator.convertType(
        function,
        translator.outputOrVoid(memberWasmFunctionType.outputs),
        translator.topInfo.nullableType);

    b.return_();
    b.end();
  }

  /// Generate code that checks type of an argument against an expected type
  /// and throws a `TypeError` on failure.
  ///
  /// Does not expect any values on stack and does not leave any values on
  /// stack.
  ///
  /// Locals [argLocal] and [argExpectedTypeLocal] are used to store values
  /// pushed by [pushArg] and [pushArgExpectedType] and reuse the values.
  ///
  /// [argName] is used in the type error as the name of the argument that
  /// doesn't match the expected type.
  void _generateArgumentTypeCheck(
    String argName,
    void Function() pushArg,
    void Function() pushArgExpectedType,
    w.Local argLocal,
    w.Local argExpectedTypeLocal,
  ) {
    // Argument
    pushArg();
    b.local_tee(argLocal);

    // Expected type
    pushArgExpectedType();
    b.local_tee(argExpectedTypeLocal);

    // Check that argument type is subtype of expected type
    call(translator.isSubtype.reference);

    b.i32_eqz();
    b.if_();
    // Type check failed
    b.local_get(argLocal);
    b.local_get(argExpectedTypeLocal);
    _emitString(argName);
    call(translator.stackTraceCurrent.reference);
    call(translator.throwArgumentTypeCheckError.reference);
    b.unreachable();
    b.end();
  }

  void _generateTypeArgumentBoundCheck(
    String argName,
    w.Local typeLocal,
    DartType bound,
  ) {
    b.local_get(typeLocal);
    final boundLocal = function
        .addLocal(translator.classInfo[translator.typeClass]!.nonNullableType);
    types.makeType(this, bound);
    b.local_tee(boundLocal);
    call(translator.isTypeSubtype.reference);

    b.i32_eqz();
    b.if_();
    // Type check failed
    b.local_get(typeLocal);
    b.local_get(boundLocal);
    _emitString(argName);
    call(translator.stackTraceCurrent.reference);
    call(translator.throwTypeArgumentBoundCheckError.reference);
    b.unreachable();
    b.end();
  }

  void _emitString(String str) => wrap(StringLiteral(str),
      translator.translateType(translator.coreTypes.stringNonNullableRawType));

  @override
  void visitPatternSwitchStatement(PatternSwitchStatement node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw new UnsupportedError("CodeGenerator.visitPatternSwitchStatement");
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw new UnsupportedError("CodeGenerator.visitPatternVariableDeclaration");
  }

  @override
  void visitIfCaseStatement(IfCaseStatement node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw new UnsupportedError("CodeGenerator.visitIfCaseStatement");
  }

  void debugRuntimePrint(String s) {
    final printFunction =
        translator.functions.getFunction(translator.printToConsole.reference);
    translator.constants.instantiateConstant(
        function, b, StringConstant(s), printFunction.type.inputs[0]);
    b.call(printFunction);
  }

  @override
  void visitAuxiliaryStatement(AuxiliaryStatement node) {
    throw UnsupportedError(
        "Unsupported auxiliary statement ${node} (${node.runtimeType}).");
  }

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    throw new UnsupportedError(
        "Unsupported auxiliary initializer ${node} (${node.runtimeType}).");
  }
}

class TryBlockFinalizer {
  /// `br` target to run the finalizer
  final w.Label label;

  /// Whether the last finalizer in the chain should return. When this is
  /// `false` the block won't be used, as the block is for running finalizers
  /// when returning.
  bool mustHandleReturn = false;

  TryBlockFinalizer(this.label);
}

/// Holds information of a switch statement, to be used when doing a backward
/// jump to it
class SwitchBackwardJumpInfo {
  /// Wasm local for the value of the switched expression. For example, in a
  /// `switch` like:
  ///
  /// ```
  /// switch (expr) {
  ///   ...
  /// }
  /// ```
  ///
  /// This local holds the value of `expr`.
  ///
  /// This local is updated with a new value when doing backward jumps.
  final w.Local switchValueLocal;

  /// Label of the `loop` to use when doing backward jumps
  final w.Label loopLabel;

  /// When compiling a `default` case, label of the `loop` in the case body, to
  /// use when doing backward jumps to the same case.
  w.Label? defaultLoopLabel;

  SwitchBackwardJumpInfo(this.switchValueLocal, this.loopLabel)
      : defaultLoopLabel = null;
}

class SwitchInfo {
  /// Non-nullable Wasm type of the `switch` expression. Used when the
  /// expression is not nullable, and after the null check.
  late final w.ValueType nullableType;

  /// Nullable Wasm type of the `switch` expression. Only used when the
  /// expression is nullable.
  late final w.ValueType nonNullableType;

  /// Generates code that compares value of a `case` expression with the
  /// `switch` expression's value. Expects `case` and `switch` values to be on
  /// stack, in that order.
  late final void Function() compare;

  /// The `default: ...` case, if exists.
  late final SwitchCase? defaultCase;

  /// The `null: ...` case, if exists.
  late final SwitchCase? nullCase;

  SwitchInfo(CodeGenerator codeGen, SwitchStatement node) {
    final translator = codeGen.translator;

    final switchExprClass =
        translator.classForType(codeGen.dartTypeOf(node.expression));

    bool check<L extends Expression, C extends Constant>() =>
        node.cases.expand((c) => c.expressions).every((e) =>
            e is L ||
            e is NullLiteral ||
            (e is ConstantExpression &&
                (e.constant is C || e.constant is NullConstant) &&
                (translator.hierarchy.isSubInterfaceOf(
                    translator.classForType(codeGen.dartTypeOf(e)),
                    switchExprClass))));

    if (node.cases.every((c) =>
        c.expressions.isEmpty && c.isDefault ||
        c.expressions.every((e) =>
            e is NullLiteral ||
            e is ConstantExpression && e.constant is NullConstant))) {
      // default-only switch
      nonNullableType = w.RefType.eq(nullable: false);
      nullableType = w.RefType.eq(nullable: true);
      compare = () => throw "Comparison in default-only switch";
    } else if (check<BoolLiteral, BoolConstant>()) {
      // bool switch
      nonNullableType = w.NumType.i32;
      nullableType =
          translator.classInfo[translator.boxedBoolClass]!.nullableType;
      compare = () => codeGen.b.i32_eq();
    } else if (check<IntLiteral, IntConstant>()) {
      // int switch
      nonNullableType = w.NumType.i64;
      nullableType =
          translator.classInfo[translator.boxedIntClass]!.nullableType;
      compare = () => codeGen.b.i64_eq();
    } else if (check<StringLiteral, StringConstant>()) {
      // String switch
      nonNullableType = translator
          .classInfo[translator.coreTypes.stringClass]!.repr.nonNullableType;
      nullableType = translator
          .classInfo[translator.coreTypes.stringClass]!.repr.nullableType;
      compare = () => codeGen.call(translator.options.jsCompatibility
          ? translator.jsStringEquals.reference
          : translator.stringEquals.reference);
    } else {
      // Object switch
      nonNullableType = translator.topInfo.nonNullableType;
      nullableType = translator.topInfo.nullableType;
      compare =
          () => codeGen.call(translator.coreTypes.identicalProcedure.reference);
    }

    // Special cases
    defaultCase = node.cases
        .cast<SwitchCase?>()
        .firstWhere((c) => c!.isDefault, orElse: () => null);

    nullCase = node.cases.cast<SwitchCase?>().firstWhere(
        (c) => c!.expressions.any((e) =>
            e is NullLiteral ||
            e is ConstantExpression && e.constant is NullConstant),
        orElse: () => null);
  }
}

enum _VirtualCallKind {
  Get,
  Set,
  Call;

  String toString() {
    switch (this) {
      case _VirtualCallKind.Get:
        return "get";
      case _VirtualCallKind.Set:
        return "set";
      case _VirtualCallKind.Call:
        return "call";
    }
  }

  bool get isGetter => this == _VirtualCallKind.Get;

  bool get isSetter => this == _VirtualCallKind.Set;
}
