// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection' show LinkedHashMap;

import 'package:kernel/ast.dart';
import 'package:kernel/type_environment.dart';
import 'package:wasm_builder/wasm_builder.dart' as w;

import 'async.dart';
import 'class_info.dart';
import 'closures.dart';
import 'dispatch_table.dart';
import 'dynamic_forwarders.dart';
import 'intrinsics.dart';
import 'param_info.dart';
import 'records.dart';
import 'reference_extensions.dart';
import 'sync_star.dart';
import 'translator.dart';
import 'types.dart';

abstract class CodeGenerator {
  // The two parameters here are used for inlining:
  //
  // If the user
  //
  //   * inlines the code, it will provide locals and a return label
  //
  //   * doesn't inline (i.e. makes new function with this code) it will provide
  //     the parameters of the function and no return label.
  //
  void generate(
      w.InstructionsBuilder b, List<w.Local> paramLocals, w.Label? returnLabel);
}

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
/// code generation for every expression or subexpression is done via the
/// [translateExpression] method, which emits appropriate conversion code if the
/// produced type is not a subtype of the expected type.
abstract class AstCodeGenerator
    extends ExpressionVisitor1<w.ValueType, w.ValueType>
    with
        ExpressionVisitor1DefaultMixin<w.ValueType, w.ValueType>,
        ExpressionVisitor1ExperimentExclusionMixin<w.ValueType, w.ValueType>,
        StatementVisitorExperimentExclusionMixin<void>
    implements InitializerVisitor<void>, StatementVisitor<void>, CodeGenerator {
  final Translator translator;
  final w.FunctionType functionType;
  final Member enclosingMember;

  // To be initialized in `generate()`
  late w.InstructionsBuilder b;
  late final List<w.Local> paramLocals;
  late final w.Label? returnLabel;

  late final Intrinsifier intrinsifier = Intrinsifier(this);
  late final StaticTypeContext typeContext =
      StaticTypeContext(enclosingMember, translator.typeEnvironment);

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

  final List<({w.Local exceptionLocal, w.Local stackTraceLocal})>
      tryBlockLocals = [];

  final Map<SwitchCase, w.Label> switchLabels = {};

  /// Maps a switch statement to the information used when doing a backward
  /// jump to one of the cases in the switch statement
  final Map<SwitchStatement, SwitchBackwardJumpInfo> switchBackwardJumpInfos =
      {};

  /// Create a code generator for a member or one of its lambdas.
  AstCodeGenerator(this.translator, this.functionType, this.enclosingMember);

  List<w.ValueType> get outputs => functionType.outputs;

  w.ValueType get returnType => translator.outputOrVoid(outputs);

  TranslatorOptions get options => translator.options;

  w.ValueType get voidMarker => translator.voidMarker;

  Types get types => translator.types;

  w.ValueType translateType(DartType type) => translator.translateType(type);

  w.Local addLocal(w.ValueType type, {String? name}) =>
      b.addLocal(type, name: name);

  DartType dartTypeOf(Expression exp) {
    if (exp is ConstantExpression) {
      // For constant expressions `getStaticType` returns often `DynamicType`
      // instead of a more precise type. See http://dartbug.com/60368
      return exp.constant.getType(typeContext);
    }
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

  Source? _sourceMapSource;
  int _sourceMapFileOffset = TreeNode.noOffset;

  /// Update the [Source] for the AST nodes being compiled.
  ///
  /// The [Source] is used to resolve [TreeNode.fileOffset]s to file URI, line,
  /// and column numbers, to be able to generate source mappings, in
  /// [setSourceMapFileOffset].
  ///
  /// Setting this `null` disables source mapping for the instructions being
  /// generated.
  ///
  /// This should be called before [setSourceMapFileOffset] as the file offset
  /// passed to that function is resolved using the [Source].
  ///
  /// Returns the old [Source], which can be used to restore the source mapping
  /// after visiting a sub-tree.
  Source? setSourceMapSource(Source? source) {
    final old = _sourceMapSource;
    _sourceMapSource = source;
    return old;
  }

  /// Update the source location of the AST nodes being compiled in the source
  /// map.
  ///
  /// When the offset is [TreeNode.noOffset], this disables mapping the
  /// generated instructions.
  ///
  /// Returns the old file offset, which can be used to restore the source
  /// mapping after vising a sub-tree.
  int setSourceMapFileOffset(int fileOffset) {
    if (!b.recordSourceMaps) {
      final old = _sourceMapFileOffset;
      _sourceMapFileOffset = fileOffset;
      return old;
    }
    if (fileOffset == TreeNode.noOffset) {
      b.stopSourceMapping();
      final old = _sourceMapFileOffset;
      _sourceMapFileOffset = fileOffset;
      return old;
    }
    final source = _sourceMapSource!;
    final fileUri = source.fileUri!;
    final location = source.getLocation(fileUri, fileOffset);
    final old = _sourceMapFileOffset;
    _sourceMapFileOffset = fileOffset;
    b.startSourceMapping(fileUri, location.line - 1, location.column - 1,
        enclosingMember.name.text);
    return old;
  }

  /// Calls [setSourceMapSource] and [setSourceMapFileOffset].
  (Source?, int) setSourceMapSourceAndFileOffset(
      Source? source, int fileOffset) {
    final oldSource = setSourceMapSource(source);
    final oldFileOffset = setSourceMapFileOffset(fileOffset);
    return (oldSource, oldFileOffset);
  }

  /// Generate code while preventing recursive inlining.
  @override
  void generate(w.InstructionsBuilder b, List<w.Local> paramLocals,
      w.Label? returnLabel) {
    this.b = b;
    this.paramLocals = paramLocals;
    this.returnLabel = returnLabel;

    translator.membersBeingGenerated.add(enclosingMember);
    generateInternal();
    translator.membersBeingGenerated.remove(enclosingMember);
  }

  // Generate the body.
  void generateInternal();

  void _setupLocalParameters(Member member, ParameterInfo paramInfo,
      int parameterOffset, int implicitParams,
      {bool isForwarder = false, bool canSafelyOmitImplicitChecks = false}) {
    final memberFunction = member.function!;

    final (
      :typeParameters,
      :typeParametersToTypeCheck,
      :positional,
      :positionalToTypeCheck,
      :named,
      :namedToTypeCheck
    ) = translator.getParametersToCheck(member);

    for (int i = 0; i < typeParameters.length; i++) {
      final typeParameter = typeParameters[i];
      typeLocals[typeParameter] = paramLocals[parameterOffset + i];
    }
    final mayNeedToCheckTypes = translator.needToCheckTypesFor(member);
    if (mayNeedToCheckTypes) {
      for (int i = 0; i < typeParametersToTypeCheck.length; i++) {
        final typeParameter = typeParametersToTypeCheck[i];
        if (translator.needToCheckTypeParameter(typeParameter)) {
          _generateTypeArgumentBoundCheck(typeParameter.name!,
              typeLocals[typeParameter]!, typeParameter.bound);
        }
      }
    }

    void setupParamLocal(
        DartType variableTypeToCheck,
        VariableDeclaration variable,
        int index,
        Constant? defaultValue,
        bool isRequired) {
      final localIndex = implicitParams + index;
      w.Local local = paramLocals[localIndex];
      final variableName = variable.name;
      if (variableName != null && variableName.isNotEmpty) {
        b.localNames[local.index] = variableName;
      }
      if (defaultValue == ParameterInfo.defaultValueSentinel) {
        // The default value for this parameter differs between implementations
        // within the same selector. This means that callers will pass the
        // default value sentinel to indicate that the parameter is not given.
        // The callee must check for the sentinel value and substitute the
        // actual default value.
        //
        // NOTE: The default sentinel is a dummy instance of the wasm type of
        // the parameter in the function signature. This type may be a super
        // type of the kind of arguments we actually see in practice.
        // (e.g. we may know that only nullable one byte strings can flow into
        // the argument, but the wasm type may be of object type). So we first
        // have to handle sentinel before we can downcast the value.
        b.local_get(local);
        translator.constants.instantiateConstant(
            b, ParameterInfo.defaultValueSentinel, local.type);
        b.ref_eq();
        b.if_();
        translateExpression(variable.initializer!, local.type);
        b.local_set(local);
        b.end();
      }
      if (!isForwarder) {
        // TFA may have inferred a very precise type for the incoming arguments,
        // but the wasm function parameter type may not reflect this (e.g. due
        // to upper-bounding in dispatch table row building)
        // => This means, we may need to do a downcast here.
        final incomingArgumentType =
            translator.translateTypeOfParameter(variable, isRequired);
        if (!local.type.isSubtypeOf(incomingArgumentType)) {
          final newLocal = addLocal(incomingArgumentType);
          b.local_get(local);
          translator.convertType(b, local.type, newLocal.type);
          b.local_set(newLocal);
          local = newLocal;
        }
      }
      if (mayNeedToCheckTypes) {
        if (translator.needToCheckParameter(variable,
            uncheckedEntry: canSafelyOmitImplicitChecks)) {
          final boxedType = variable.type.isPotentiallyNullable
              ? translator.topType
              : translator.topTypeNonNullable;
          w.Local operand = local;
          if (!operand.type.isSubtypeOf(boxedType)) {
            final boxedOperand = addLocal(boxedType);
            b.local_get(operand);
            translator.convertType(b, operand.type, boxedOperand.type);
            b.local_set(boxedOperand);
            operand = boxedOperand;
          }
          b.local_get(operand);
          _generateArgumentTypeCheck(
            variable.name!,
            operand.type as w.RefType,
            variableTypeToCheck,
          );
        }
      }
      if (!isForwarder && !variable.isFinal) {
        // We now have a precise local that can contain the values passed by
        // callers, but the body may assign less precise types to this variable,
        // so we may introduce another local variable that is less precise.
        // => Binaryen will simplify the above downcast and this upcast.
        final variableType = translator.translateTypeOfLocalVariable(variable);
        if (!variableType.isSubtypeOf(local.type)) {
          w.Local newLocal = addLocal(variableType);
          b.local_get(local);
          translator.convertType(b, local.type, newLocal.type);
          b.local_set(newLocal);
          local = newLocal;
        }
      }

      locals[variable] = local;
    }

    for (int i = 0; i < positional.length; i++) {
      final bool isRequired = i < memberFunction.requiredParameterCount;
      final typeToCheck = positionalToTypeCheck[i].type;
      setupParamLocal(
          typeToCheck, positional[i], i, paramInfo.positional[i], isRequired);
    }
    for (var param in named) {
      final typeToCheck = identical(named, namedToTypeCheck)
          ? param.type
          : namedToTypeCheck.singleWhere((n) => n.name == param.name).type;
      setupParamLocal(typeToCheck, param, paramInfo.nameIndex[param.name]!,
          paramInfo.named[param.name], param.isRequired);
    }

    // For all parameters whose Wasm type has been forced to `externref` due to
    // this function being an export, internalize and cast the parameter to the
    // canonical representation type for its Dart type.
    locals.forEach((parameter, local) {
      DartType parameterType = parameter.type;
      if (local.type == w.RefType.extern(nullable: true) &&
          !(parameterType is InterfaceType &&
              parameterType.classNode == translator.wasmExternRefClass)) {
        w.Local newLocal =
            addLocal(translateType(parameterType), name: parameter.name);
        b.local_get(local);
        translator.convertType(b, local.type, newLocal.type);
        b.local_set(newLocal);
        locals[parameter] = newLocal;
      }
    });
  }

  void setupParameters(Reference reference,
      {bool isForwarder = false, bool canSafelyOmitImplicitChecks = false}) {
    Member member = reference.asMember;
    ParameterInfo paramInfo = translator.paramInfoForDirectCall(reference);

    int parameterOffset = _initializeThis(reference);
    int implicitParams = parameterOffset + paramInfo.typeParamCount;

    _setupLocalParameters(member, paramInfo, parameterOffset, implicitParams,
        isForwarder: isForwarder,
        canSafelyOmitImplicitChecks: canSafelyOmitImplicitChecks);
  }

  void setupParametersForNormalEntry(Member member) {
    setupParameters(member.reference,
        canSafelyOmitImplicitChecks: !translator.needToCheckTypesFor(member));
  }

  void setupParametersForCheckedEntry(Member member) {
    assert(member.isInstanceMember);
    assert(translator.needToCheckTypesFor(member));
    setupParameters(member.checkedEntryReference,
        canSafelyOmitImplicitChecks: false);
  }

  void setupParametersForUncheckedEntry(Member member) {
    assert(member.isInstanceMember);
    assert(translator.needToCheckTypesFor(member));
    setupParameters(member.uncheckedEntryReference,
        canSafelyOmitImplicitChecks: true);
  }

  void setupContexts(Member member) {
    allocateContext(member.function!);
    captureParameters();
  }

  void _setupDefaultFieldValues(ClassInfo info) {
    fieldLocals.clear();

    for (Field field in info.cls!.fields) {
      if (field.isInstanceMember && field.initializer != null) {
        final source = field.enclosingComponent!.uriToSource[field.fileUri]!;
        final (oldSource, oldFileOffset) =
            setSourceMapSourceAndFileOffset(source, field.fileOffset);

        int fieldIndex = translator.fieldIndex[field]!;
        w.Local local = addLocal(info.struct.fields[fieldIndex].type.unpacked);

        translateExpression(
            field.initializer!, info.struct.fields[fieldIndex].type.unpacked);
        b.local_set(local);
        fieldLocals[field] = local;

        setSourceMapSourceAndFileOffset(oldSource, oldFileOffset);
      }
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

    final ParameterInfo paramInfo = translator.paramInfoForDirectCall(target);

    for (String name in paramInfo.names) {
      w.Local namedLocal = namedArgs[name]!;
      constructorArgs.add(namedLocal);
    }

    if (reverse) {
      return constructorArgs.reversed.toList();
    }

    return constructorArgs;
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

  /// Initialize locals containing `this` in constructors and instance members.
  /// Returns the number of parameter locals taken up by the receiver parameter,
  /// i.e. the parameter offset for the first type parameter (or the first
  /// parameter if there are no type parameters).
  int _initializeThis(Reference reference) {
    Member member = reference.asMember;
    final hasThis =
        member.isInstanceMember || reference.isConstructorBodyReference;
    if (hasThis) {
      thisLocal = paramLocals[0];
      b.localNames[thisLocal!.index] = "this";
      final preciseThisType = translator.preciseThisFor(member);
      if (translator.needsConversion(thisLocal!.type, preciseThisType)) {
        preciseThisLocal = addLocal(preciseThisType, name: "preciseThis");
        b.local_get(thisLocal!);
        translator.convertType(b, thisLocal!.type, preciseThisType);
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
    Context? context;

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
          thisLocal = addLocal(
              context.struct.fields[context.thisFieldIndex].type.unpacked
                  .withNullability(false),
              name: "this");
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
        b.comment("Unreachable implicit return");
        b.unreachable();
      }
    }
  }

  void allocateContext(TreeNode node) {
    Context? context = closures.contexts[node];
    if (context == null || context.isEmpty) return;

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

  void captureParameters() {
    locals.forEach((variable, local) {
      Capture? capture = closures.captures[variable];
      if (capture != null) {
        b.local_get(capture.context.currentLocal);
        b.local_get(local);
        translator.convertType(b, local.type, capture.type);
        b.struct_set(capture.context.struct, capture.fieldIndex);
      }
    });
    typeLocals.forEach((parameter, local) {
      Capture? capture = closures.captures[parameter];
      if (capture != null) {
        b.local_get(capture.context.currentLocal);
        b.local_get(local);
        translator.convertType(b, local.type, capture.type);
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
  w.ValueType translateExpression(Expression node, w.ValueType expectedType) {
    var sourceUpdated = false;
    Source? oldSource;
    if (node is FileUriNode) {
      final source =
          node.enclosingComponent!.uriToSource[(node as FileUriNode).fileUri]!;
      oldSource = setSourceMapSource(source);
      sourceUpdated = true;
    }
    final oldFileOffset = setSourceMapFileOffset(node.fileOffset);
    try {
      w.ValueType resultType = node.accept1(this, expectedType);
      translator.convertType(b, resultType, expectedType);
      return expectedType;
    } catch (_) {
      _printLocation(node);
      rethrow;
    } finally {
      if (sourceUpdated) {
        setSourceMapSource(oldSource);
      }
      setSourceMapFileOffset(oldFileOffset);
    }
  }

  void translateStatement(Statement node) {
    final oldFileOffset = setSourceMapFileOffset(node.fileOffset);
    try {
      node.accept(this);
    } catch (_) {
      _printLocation(node);
      rethrow;
    } finally {
      setSourceMapFileOffset(oldFileOffset);
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
    return translator.callReference(target, b);
  }

  @override
  void visitInvalidInitializer(InvalidInitializer node) {}

  @override
  void visitAssertInitializer(AssertInitializer node) {
    translateStatement(node.statement);
  }

  @override
  void visitLocalInitializer(LocalInitializer node) {
    translateStatement(node.variable);
  }

  @override
  void visitFieldInitializer(FieldInitializer node) {
    Class cls = (node.parent as Constructor).enclosingClass;
    w.StructType struct = translator.classInfo[cls]!.struct;
    Field field = node.field;
    int fieldIndex = translator.fieldIndex[field]!;

    w.Local? local = fieldLocals[field];

    local ??= addLocal(struct.fields[fieldIndex].type.unpacked);

    translateExpression(node.value, struct.fields[fieldIndex].type.unpacked);
    b.local_set(local);
    fieldLocals[field] = local;
  }

  @override
  void visitRedirectingInitializer(RedirectingInitializer node) {
    Class cls = (node.parent as Constructor).enclosingClass;

    for (TypeParameter typeParam in cls.typeParameters) {
      types.makeType(
          this, TypeParameterType(typeParam, Nullability.nonNullable));
    }

    final targetMember = node.targetReference.asMember;
    final target = targetMember.initializerReference;
    _visitArguments(node.arguments, translator.signatureForDirectCall(target),
        translator.paramInfoForDirectCall(target), cls.typeParameters.length);

    b.comment("Direct call of '$targetMember Redirected Initializer'");
    call(target);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    Supertype? supertype =
        (node.parent as Constructor).enclosingClass.supertype;
    Supertype? supersupertype = node.target.enclosingClass.supertype;

    // Skip calls to the constructor for Object, as this is empty
    if (supersupertype != null) {
      for (DartType typeArg in supertype!.typeArguments) {
        types.makeType(this, typeArg);
      }

      final targetMember = node.targetReference.asMember;
      final target = targetMember.initializerReference;
      _visitArguments(
          node.arguments,
          translator.signatureForDirectCall(target),
          translator.paramInfoForDirectCall(target),
          supertype.typeArguments.length);

      b.comment("Direct call of '$targetMember Initializer'");
      call(target);
    }
  }

  @override
  void visitBlock(Block node) {
    for (Statement statement in node.statements) {
      translateStatement(statement);
    }
  }

  @override
  void visitLabeledStatement(LabeledStatement node) {
    w.Label label = b.block();
    breakFinalizers[node] = <w.Label>[label];
    translateStatement(node.body);
    breakFinalizers.remove(node);
    b.end();
  }

  @override
  void visitBreakStatement(BreakStatement node) {
    b.br(breakFinalizers[node.target]!.last);
  }

  @override
  void visitVariableDeclaration(VariableDeclaration node) {
    final w.ValueType type = translator.translateTypeOfLocalVariable(node);
    w.Local? local;
    Capture? capture = closures.captures[node];
    if (capture == null || !capture.written) {
      local = addLocal(type, name: node.name);
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
        translateExpression(initializer, expectedType);
        if (!capture.written) {
          b.local_tee(local!);
        }
        b.struct_set(capture.context.struct, capture.fieldIndex);
      } else {
        translateExpression(initializer, local!.type);
        b.local_set(local);
      }
    } else if (local != null && !local.type.defaultable) {
      // Uninitialized variable
      translator
          .getDummyValuesCollectorForModule(b.moduleBuilder)
          .instantiateDummyValue(b, local.type);
      b.local_set(local);
    }
  }

  /// Initialize a variable [node] to an initial value which must be left on
  /// the stack by [pushInitialValue].
  ///
  /// This is similar to [visitVariableDeclaration] but it gives more control
  /// over how the variable is initialized.
  void initializeVariable(
      VariableDeclaration node, void Function() pushInitialValue) {
    final w.ValueType type = translator.translateTypeOfLocalVariable(node);
    w.Local? local;
    final Capture? capture = closures.captures[node];
    if (capture == null || !capture.written) {
      local = addLocal(type, name: node.name);
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
      translateExpression(node.condition, w.NumType.i32);
      b.br_if(assertBlock);

      Expression? message = node.message;
      if (message != null) {
        translateExpression(message, translator.topType);
      } else {
        b.ref_null(w.HeapType.none);
      }
      final Location? location = node.location;
      final w.RefType stringRefType = translator.stringTypeNullable;
      if (location != null) {
        instantiateConstant(
          StringConstant(location.file.toString()),
          stringRefType,
        );
        b.i64_const(location.line);
        b.i64_const(location.column);
        final String sourceString =
            node.enclosingComponent!.uriToSource[location.file]!.text;
        final String conditionString = sourceString.substring(
            node.conditionStartOffset, node.conditionEndOffset);
        instantiateConstant(
          StringConstant(conditionString),
          stringRefType,
        );
      } else {
        b.ref_null(stringRefType.heapType);
        b.i64_const(0);
        b.i64_const(0);
        b.ref_null(stringRefType.heapType);
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
      translateStatement(statement);
    }
  }

  @override
  void visitTryCatch(TryCatch node) {
    // It is not valid Dart to have a try without a catch.
    assert(node.catches.isNotEmpty);

    final w.RefType exceptionType = translator.topTypeNonNullable;
    final w.RefType stackTraceType = translator.stackTraceType;

    final w.Label wrapperBlock = b.block();

    // Create a block target for each Dart `catch` block, to be able to share
    // code when generating a `catch` and `catch_all` for the same Dart `catch`
    // block, when the block can catch both Dart and JS exceptions.
    // The `end` for the Wasm `try` block works as the first exception handler
    // target.
    List<w.Label> catchBlockLabels = List.generate(node.catches.length - 1,
        (i) => b.block([], [exceptionType, stackTraceType]),
        growable: true);

    w.Label try_ = b.try_([], [exceptionType, stackTraceType]);
    catchBlockLabels.add(try_);

    catchBlockLabels = catchBlockLabels.reversed.toList();

    translateStatement(node.body);
    b.br(wrapperBlock);

    // Stash the original exception in a local so we can push it back onto the
    // stack after each type test. Also, store the stack trace in a local.
    w.Local thrownException = addLocal(exceptionType);
    w.Local thrownStackTrace = addLocal(stackTraceType);

    tryBlockLocals.add(
        (exceptionLocal: thrownException, stackTraceLocal: thrownStackTrace));

    void emitCatchBlock(
        w.Label catchBlockTarget, Catch catch_, bool emitGuard) {
      // For each catch node:
      //   1) Create a block for the catch.
      //   2) Push the caught exception onto the stack.
      //   3) Add a type test based on the guard of the catch.
      //   4) If the test fails, we jump to the next catch. Otherwise, we
      //      jump to the block for the body of the catch.
      w.Label catchBlock = b.block();
      DartType guard = catch_.guard;

      // Only emit the type test if the guard is not [Object].
      if (emitGuard) {
        b.local_get(thrownException);
        types.emitIsTest(this, guard,
            translator.coreTypes.objectNonNullableRawType, catch_.location);
        b.i32_eqz();
        b.br_if(catchBlock);
      }

      b.local_get(thrownException);
      b.local_get(thrownStackTrace);
      b.br(catchBlockTarget);

      b.end(); // end catchBlock.
    }

    // Insert a catch instruction which will catch any thrown Dart
    // exceptions.
    b.catch_legacy(translator.getExceptionTag(b.moduleBuilder));

    b.local_set(thrownStackTrace);
    b.local_set(thrownException);
    for (int catchBlockIndex = 0;
        catchBlockIndex < node.catches.length;
        catchBlockIndex += 1) {
      final catch_ = node.catches[catchBlockIndex];
      // Only insert type checks if the guard is not `Object`
      final bool shouldEmitGuard =
          catch_.guard != translator.coreTypes.objectNonNullableRawType;
      emitCatchBlock(
          catchBlockLabels[catchBlockIndex], catch_, shouldEmitGuard);
      if (!shouldEmitGuard) {
        // If we didn't emit a guard, we won't ever fall through to the
        // following catch blocks.
        break;
      }
    }

    // Rethrow if all the catch blocks fall through
    b.rethrow_(try_);

    // If we have a catches that are generic enough to catch a JavaScript
    // error, we need to put that into a catch_all block.
    if (node.catches
        .any((c) => guardCanMatchJSException(translator, c.guard))) {
      // This catches any objects that aren't dart exceptions, such as
      // JavaScript exceptions or objects.
      b.catch_all_legacy();

      // We can't inspect the thrown object in a catch_all and get a stack
      // trace, so we just attach the current stack trace.
      call(translator.stackTraceCurrent.reference);
      b.local_set(thrownStackTrace);

      // We create a generic JavaScript error in this case.
      call(translator.javaScriptErrorFactory.reference);
      b.local_set(thrownException);

      for (int catchBlockIndex = 0;
          catchBlockIndex < node.catches.length;
          catchBlockIndex += 1) {
        final catch_ = node.catches[catchBlockIndex];
        if (!guardCanMatchJSException(translator, catch_.guard)) {
          continue;
        }
        // Type guards based on a type parameter are special, in that we cannot
        // statically determine whether a JavaScript error will always satisfy
        // the guard, so we should emit the type checking code for it. All
        // other guards will always match a JavaScript error, however, so no
        // need to emit type checks for those.
        final bool shouldEmitGuard = catch_.guard is TypeParameterType;
        emitCatchBlock(
            catchBlockLabels[catchBlockIndex], catch_, shouldEmitGuard);
        if (!shouldEmitGuard) {
          // If we didn't emit a guard, we won't ever fall through to the
          // following catch blocks.
          break;
        }
      }

      // Rethrow if the catch block falls through
      b.rethrow_(try_);
    }

    for (Catch catch_ in node.catches) {
      b.end();
      b.local_set(thrownStackTrace);
      b.local_set(thrownException);

      final VariableDeclaration? exceptionDeclaration = catch_.exception;
      if (exceptionDeclaration != null) {
        initializeVariable(exceptionDeclaration, () {
          b.local_get(thrownException);
          // Type test passed, downcast the exception to the expected type.
          translator.convertType(
            b,
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

      translateStatement(catch_.body);
      b.br(wrapperBlock);
    }

    tryBlockLocals.removeLast();
    b.end(); // end tryWrapper
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

    // Create one block for each wrapping label.
    for (final labelBlocks in breakFinalizers.values.toList().reversed) {
      labelBlocks.add(b.block());
    }

    // Continuation of this block runs the finalizer and returns (or jumps to
    // the next finalizer block). Used as `br` target on `return`.
    w.Label returnFinalizerBlock = b.block();
    returnFinalizers.add(TryBlockFinalizer(returnFinalizerBlock));

    w.Label tryBlock = b.try_();
    translateStatement(node.body);

    final bool mustHandleReturn =
        returnFinalizers.removeLast().mustHandleReturn;

    // `break` statements in the current finalizer and the rest will not run
    // the current finalizer, update the `break` targets.
    final removedBreakTargets = <LabeledStatement, w.Label>{};
    for (final breakFinalizerEntry in breakFinalizers.entries) {
      removedBreakTargets[breakFinalizerEntry.key] =
          breakFinalizerEntry.value.removeLast();
    }

    // Handle Dart exceptions.
    b.catch_legacy(translator.getExceptionTag(b.moduleBuilder));
    translateStatement(node.finalizer);
    b.rethrow_(tryBlock);

    // Handle JS exceptions.
    b.catch_all_legacy();
    translateStatement(node.finalizer);
    b.rethrow_(tryBlock);

    b.end(); // tryBlock

    // Run finalizer on normal execution (no breaks, throws, or returns).
    translateStatement(node.finalizer);
    b.br(tryFinallyBlock);
    b.end(); // returnFinalizerBlock

    // Run the finalizer on `return`.
    if (mustHandleReturn) {
      translateStatement(node.finalizer);
      if (returnFinalizers.isNotEmpty) {
        b.br(returnFinalizers.last.label);
      } else {
        if (returnValueLocal != null) {
          b.local_get(returnValueLocal!);
          translator.convertType(b, returnValueLocal!.type, returnType);
        }
        _returnFromFunction();
      }
    }

    // Generate finalizers for `break`s in the `try` block.
    for (final removedBreakTargetEntry in removedBreakTargets.entries) {
      b.end();
      translateStatement(node.finalizer);
      b.br(breakFinalizers[removedBreakTargetEntry.key]!.last);
    }

    b.end(); // tryFinallyBlock
  }

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    translateExpression(node.expression, voidMarker);
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
      translateExpression(condition!, w.NumType.i32);
      if (negated) {
        b.i32_eqz();
      }
      b.br_if(target);
    }
  }

  void _conditional(Expression condition, void Function() then,
      void Function()? otherwise, List<w.ValueType> result) {
    if (!_hasLogicalOperator(condition)) {
      // Simple condition
      translateExpression(condition, w.NumType.i32);
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
        () => translateStatement(node.then),
        node.otherwise != null
            ? () => translateStatement(node.otherwise!)
            : null,
        const []);
  }

  @override
  void visitDoStatement(DoStatement node) {
    w.Label loop = b.loop();
    allocateContext(node);
    translateStatement(node.body);
    branchIf(node.condition, loop, negated: false);
    b.end();
  }

  @override
  void visitWhileStatement(WhileStatement node) {
    w.Label block = b.block();
    w.Label loop = b.loop();
    allocateContext(node);
    branchIf(node.condition, block, negated: true);
    translateStatement(node.body);
    b.br(loop);
    b.end();
    b.end();
  }

  @override
  void visitForStatement(ForStatement node) {
    allocateContext(node);
    for (VariableDeclaration variable in node.variables) {
      translateStatement(variable);
    }
    w.Label block = b.block();
    w.Label loop = b.loop();
    branchIf(node.condition, block, negated: true);
    translateStatement(node.body);

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
      translateExpression(update, voidMarker);
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
      translateExpression(expression, returnType);
    } else {
      translator.convertType(b, voidMarker, returnType);
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
        returnValueLocal ??=
            addLocal(returnType.withNullability(true), name: "returnValue");
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
      translateExpression(node.expression, voidMarker);
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
    translateExpression(node.expression,
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
      translator.convertType(b, switchInfo.nullableType.withNullability(false),
          switchInfo.nonNullableType);
      b.local_set(switchValueNonNullableLocal);
    }

    final dynamicTypeGuard = switchInfo.dynamicTypeGuard;
    if (dynamicTypeGuard != null) {
      final success = b.block(const [], [translator.topTypeNonNullable]);
      dynamicTypeGuard(switchValueNonNullableLocal, success);
      b.br(switchLabels[defaultCase] ?? doneLabel);
      b.end();
    }

    final brTable = switchInfo.brTable;
    if (brTable != null) {
      // Map each entry in the range to the appropriate jump table entry.
      final indexBlocks = <w.Label>[];
      final defaultLabel =
          defaultCase != null ? switchLabels[defaultCase]! : doneLabel;
      for (int i = brTable.minValue; i <= brTable.maxValue; ++i) {
        final c = brTable.caseMap[i];
        indexBlocks.add(c == null ? defaultLabel : switchLabels[c]!);
      }

      brTable.emitBrTableExpr(b, switchValueNonNullableLocal);

      b.br_table(indexBlocks, defaultLabel);
    } else {
      // Compare against all case values
      for (SwitchCase c in node.cases) {
        for (Expression exp in c.expressions) {
          if (exp is NullLiteral ||
              exp is ConstantExpression && exp.constant is NullConstant) {
            // Null already checked, skip
          } else {
            switchInfo.compare(
              switchValueNonNullableLocal,
              () => translateExpression(exp, switchInfo.nonNullableType),
            );
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

      translateStatement(c.body);

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
      translateExpression(targetValue, targetInfo.switchValueLocal.type);
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
    translateStatement(node.body);
    return translateExpression(node.value, expectedType);
  }

  w.ModuleBuilder? _activeDeferredLoadingGuard;

  @override
  w.ValueType visitLet(Let node, w.ValueType expectedType) {
    translateStatement(node.variable);

    final oldGuard = _activeDeferredLoadingGuard;
    final newGuard = _recognizeDeferredModuleGuard(node);
    if (newGuard != null) {
      _activeDeferredLoadingGuard = newGuard;
    }
    final result = translateExpression(node.body, expectedType);
    _activeDeferredLoadingGuard = oldGuard;
    return result;
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
    if (thisType.isSubtypeOf(expectedType)) {
      b.local_get(thisLocal!);
      return thisType;
    }
    if (preciseThisType.isSubtypeOf(expectedType)) {
      b.local_get(preciseThisLocal!);
      return preciseThisType;
    }
    // A user of `this` may have more precise type information, in which case
    // we downcast it here.
    b.local_get(thisLocal!);
    translator.convertType(b, thisType, expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitConstructorInvocation(
      ConstructorInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult =
        intrinsifier.generateConstructorIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    ClassInfo info = translator.classInfo[node.target.enclosingClass]!;
    translator.functions.recordClassAllocation(info.classId);

    final target = node.targetReference;
    _visitArguments(node.arguments, translator.signatureForDirectCall(target),
        translator.paramInfoForDirectCall(target), 0);

    return call(target).single;
  }

  @override
  w.ValueType visitStaticInvocation(
      StaticInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult = intrinsifier.generateStaticIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    final target = node.targetReference;
    _visitArguments(node.arguments, translator.signatureForDirectCall(target),
        translator.paramInfoForDirectCall(target), 0);
    return translator.outputOrVoid(call(target));
  }

  Member _lookupSuperTarget(Member interfaceTarget, {required bool setter}) {
    final staticTarget = translator.hierarchy.getDispatchTarget(
        enclosingMember.enclosingClass!.superclass!, interfaceTarget.name,
        setter: setter);
    if (staticTarget != null) return staticTarget;

    // During dynamic module compilation a mixin might include a super call to
    // an abstract class with no implementations yet.
    assert(translator.dynamicModuleSupportEnabled);
    return interfaceTarget;
  }

  @override
  w.ValueType visitSuperMethodInvocation(
      SuperMethodInvocation node, w.ValueType expectedType) {
    Reference target = translator.getFunctionEntry(
        _lookupSuperTarget(node.interfaceTarget, setter: false).reference,
        uncheckedEntry: true);
    w.FunctionType targetFunctionType =
        translator.signatureForDirectCall(target);
    final w.ValueType receiverType = translator.preciseThisFor(target.asMember);

    // When calling `==` and the argument is potentially nullable, check if the
    // argument is `null`.
    if (node.name.text == '==') {
      assert(node.arguments.positional.length == 1);
      assert(node.arguments.named.isEmpty);
      final argument = node.arguments.positional[0];
      if (dartTypeOf(argument).isPotentiallyNullable) {
        w.Label resultBlock = b.block(const [], const [w.NumType.i32]);

        w.ValueType argumentType = targetFunctionType.inputs[1];
        // `==` arguments are non-nullable.
        assert(argumentType.nullable == false);

        final argumentNullBlock = b.block(const [], const []);

        visitThis(receiverType);
        translateExpression(argument, argumentType.withNullability(true));
        b.br_on_null(argumentNullBlock);

        final resultType = translator.outputOrVoid(call(target));
        // `super ==` should return bool.
        assert(resultType == w.NumType.i32);
        b.br(resultBlock);

        b.end(); // argumentNullBlock

        b.i32_const(0); // false
        b.br(resultBlock);

        b.end(); // resultBlock
        return w.NumType.i32;
      }
    }

    visitThis(receiverType);
    _visitArguments(node.arguments, translator.signatureForDirectCall(target),
        translator.paramInfoForDirectCall(target), 1);
    return translator.outputOrVoid(call(target));
  }

  @override
  w.ValueType visitInstanceInvocation(
      InstanceInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult = intrinsifier.generateInstanceIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    final useUncheckedEntry =
        translator.canUseUncheckedEntry(node.receiver, node);

    w.ValueType callWithNullCheck(
        Procedure target, void Function(w.ValueType) onNull) {
      late w.Label done;
      final w.ValueType resultType =
          _virtualCall(node, target, _VirtualCallKind.Call, (signature) {
        done = b.block(const [], signature.outputs);
        final w.Label nullReceiver = b.block();
        translateExpression(node.receiver, translator.topType);
        b.br_on_null(nullReceiver);
      }, (w.FunctionType signature, ParameterInfo paramInfo) {
        _visitArguments(node.arguments, signature, paramInfo, 1);
      }, useUncheckedEntry: useUncheckedEntry);
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
              target,
              (resultType) =>
                  translateExpression(StringLiteral("null"), resultType));
        case "noSuchMethod":
          return callWithNullCheck(target, (resultType) {
            final target = node.interfaceTargetReference;
            final signature = translator.signatureForDirectCall(target);
            final paramInfo = translator.paramInfoForDirectCall(target);

            // Object? receiver
            b.ref_null(translator.topType.heapType);
            // Invocation invocation
            _visitArguments(node.arguments, signature, paramInfo, 1);
            call(translator.noSuchMethodErrorThrowWithInvocation.reference);
          });
        default:
          unimplemented(node, "Nullable invocation of ${target.name.text}",
              [if (expectedType != voidMarker) expectedType]);
          return expectedType;
      }
    }

    Member? singleTarget = translator.singleTarget(node);

    // Custom devirtualization because TFA doesn't correctly devirtualize index
    // accesses on constant lists (see https://dartbug.com/60313)
    if (singleTarget == null &&
        target.kind == ProcedureKind.Operator &&
        target.name.text == '[]') {
      final receiver = node.receiver;
      if (receiver is ConstantExpression && receiver.constant is ListConstant) {
        singleTarget = translator.listBaseIndexOperator;
      }
    }

    if (singleTarget != null) {
      final target = translator.getFunctionEntry(singleTarget.reference,
          uncheckedEntry: useUncheckedEntry);
      final signature = translator.signatureForDirectCall(target);
      final paramInfo = translator.paramInfoForDirectCall(target);
      translateExpression(node.receiver, signature.inputs.first);
      _visitArguments(node.arguments, signature, paramInfo, 1);

      return translator.outputOrVoid(call(target));
    }
    return _virtualCall(
        node,
        target,
        _VirtualCallKind.Call,
        (signature) =>
            translateExpression(node.receiver, signature.inputs.first),
        (w.FunctionType signature, ParameterInfo paramInfo) {
      _visitArguments(node.arguments, signature, paramInfo, 1);
    }, useUncheckedEntry: useUncheckedEntry);
  }

  @override
  w.ValueType visitDynamicInvocation(
      DynamicInvocation node, w.ValueType expectedType) {
    // Call dynamic invocation forwarder
    final receiver = node.receiver;
    final typeArguments = node.arguments.types;
    final positionalArguments = node.arguments.positional;
    final namedArguments = node.arguments.named;
    final memberName = node.name;
    final callShape = CallShape(
        memberName,
        typeArguments.length,
        positionalArguments.length,
        namedArguments.map((n) => n.name).toList()..sort());
    final forwarder = translator
        .getDynamicForwardersForModule(b.moduleBuilder)
        .getDynamicInvocationForwarder(callShape);

    // Evaluate receiver
    translateExpression(receiver, translator.topType);

    // Evaluate type arguments.
    for (final typeArgument in typeArguments) {
      translator.types.makeType(this, typeArgument);
    }

    // Evaluate positional arguments
    for (final argument in positionalArguments) {
      translateExpression(argument, translator.topType);
    }

    // Evaluate named arguments. The arguments need to be evaluated in the
    // order they appear in the AST, but need to be sorted based on names in
    // the argument list passed to the dynamic forwarder. Create a local for
    // each argument to allow adding values to the list in expected order.
    final namedArgumentLocals = <String, w.Local>{};
    for (final namedArgument in namedArguments) {
      translateExpression(namedArgument.value, translator.topType);
      final argumentLocal = addLocal(translator.topType);
      b.local_set(argumentLocal);
      namedArgumentLocals[namedArgument.name] = argumentLocal;
    }

    // Load named arguments in sorted order.
    for (final name in callShape.named) {
      b.local_get(namedArgumentLocals[name]!);
    }

    translator.callFunction(forwarder.function, b);

    return translator.topType;
  }

  @override
  w.ValueType visitEqualsCall(EqualsCall node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult = intrinsifier.generateEqualsIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    final leftType = translator.translateType(dartTypeOf(node.left));
    Member? singleTarget = translator.singleTarget(node);
    if (singleTarget == translator.coreTypes.objectEquals ||
        // If leftType is not a Dart type (or builtin value type) then use
        // reference equality (e.g. the vtable type is not a subtype of
        // topType).
        (leftType is w.RefType && !leftType.isSubtypeOf(translator.topType))) {
      // Plain reference comparison
      translateExpression(node.left, w.RefType.eq(nullable: true));
      translateExpression(node.right, w.RefType.eq(nullable: true));
      b.ref_eq();
    } else {
      // Check operands for null, then call implementation
      bool leftNullable = dartTypeOf(node.left).isPotentiallyNullable;
      bool rightNullable = dartTypeOf(node.right).isPotentiallyNullable;
      w.RefType leftType = translator.topType.withNullability(leftNullable);
      w.RefType rightType = translator.topType.withNullability(rightNullable);
      w.Local leftLocal = addLocal(leftType);
      w.Local rightLocal = addLocal(rightType);
      w.Label? operandNull;
      w.Label? done;
      if (leftNullable || rightNullable) {
        done = b.block(const [], const [w.NumType.i32]);
        operandNull = b.block();
      }
      translateExpression(node.left, leftLocal.type);
      b.local_set(leftLocal);
      translateExpression(node.right, rightLocal.type);
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

      void right([_, __]) {
        b.local_get(rightLocal);
        if (rightNullable) {
          b.ref_as_non_null();
        }
      }

      final useUncheckedEntry =
          translator.canUseUncheckedEntry(node.left, node);
      if (singleTarget != null) {
        left();
        right();
        call(translator.getFunctionEntry(singleTarget.reference,
            uncheckedEntry: useUncheckedEntry));
      } else {
        _virtualCall(
          node,
          node.interfaceTarget,
          _VirtualCallKind.Call,
          left,
          right,
          useUncheckedEntry: useUncheckedEntry,
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
    translateExpression(node.expression, const w.RefType.any(nullable: true));
    b.ref_is_null();
    return w.NumType.i32;
  }

  w.ValueType _virtualCall(
      TreeNode node,
      Member interfaceTarget,
      _VirtualCallKind kind,
      void Function(w.FunctionType signature) pushReceiver,
      void Function(w.FunctionType signature, ParameterInfo) pushArguments,
      {required bool useUncheckedEntry}) {
    assert(kind != _VirtualCallKind.Get || !useUncheckedEntry);
    final reference = interfaceTarget.referenceAs(
        getter: kind.isGetter, setter: kind.isSetter);
    final dispatchTable = translator.dispatchTableForTarget(reference);
    SelectorInfo selector = dispatchTable.selectorForTarget(reference);
    final signature = selector.signature;
    final name = selector.entryPointName(useUncheckedEntry);
    assert(selector.name == interfaceTarget.name.text);

    pushReceiver(signature);

    final targets = selector.targets(unchecked: useUncheckedEntry);
    List<({Range range, Reference target})> targetRanges = targets.targetRanges;
    List<({Range range, Reference target})> staticDispatchRanges =
        targets.staticDispatchRanges;

    // NOTE: Keep this in sync with
    // `dynamic_forwarders.dart:generateNoSuchMethodCall`.
    final bool noTarget =
        targetRanges.isEmpty && !selector.isDynamicSubmoduleOverridable;
    final bool directCall =
        targetRanges.length == 1 && staticDispatchRanges.length == 1;
    final callPolymorphicDispatcher =
        !directCall && staticDispatchRanges.isNotEmpty;

    if (noTarget) {
      // Unreachable call
      b.comment("Virtual call of $name with no targets"
          " at ${node.location}");
      pushArguments(signature, selector.paramInfo);
      for (int i = 0; i < signature.inputs.length; ++i) {
        b.drop();
      }
      b.block(const [], signature.outputs);
      b.unreachable();
      b.end();
      return translator.outputOrVoid(signature.outputs);
    }
    if (directCall) {
      final target = translator.getFunctionEntry(targetRanges[0].target,
          uncheckedEntry: useUncheckedEntry);
      final directCallSignature = translator.signatureForDirectCall(target);
      final paramInfo = translator.paramInfoForDirectCall(target);
      pushArguments(directCallSignature, paramInfo);
      return translator.outputOrVoid(call(target));
    }

    // Receiver is already on stack.
    w.Local receiverVar = addLocal(signature.inputs.first);
    assert(!receiverVar.type.nullable);
    b.local_tee(receiverVar);
    if (callPolymorphicDispatcher) {
      b.loadClassId(translator, receiverVar.type);
      b.local_get(receiverVar);
    }
    pushArguments(signature, selector.paramInfo);

    if (callPolymorphicDispatcher) {
      b.invoke(translator
          .getPolymorphicDispatchersForModule(b.moduleBuilder)
          .getPolymorphicDispatcher(selector,
              useUncheckedEntry: useUncheckedEntry));
    } else {
      b.comment("Instance $kind of '$name'");
      b.local_get(receiverVar);
      translator.callDispatchTable(b, selector,
          interfaceTarget: reference,
          useUncheckedEntry: useUncheckedEntry,
          table: dispatchTable);
    }

    return translator.outputOrVoid(signature.outputs);
  }

  @override
  w.ValueType visitVariableGet(VariableGet node, w.ValueType expectedType) {
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
    w.Local? local = locals[node.variable];
    Capture? capture = closures.captures[node.variable];
    bool preserved = expectedType != voidMarker;
    if (capture != null) {
      assert(capture.written);
      b.local_get(capture.context.currentLocal);
      translateExpression(node.value, capture.type);
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
      translateExpression(node.value, local.type);
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

    return translator.outputOrVoid(call(node.targetReference));
  }

  @override
  w.ValueType visitStaticTearOff(StaticTearOff node, w.ValueType expectedType) {
    instantiateConstant(StaticTearOffConstant(node.target), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitStaticSet(StaticSet node, w.ValueType expectedType) {
    bool preserved = expectedType != voidMarker;
    Member target = node.target;
    final reference =
        target is Field ? target.setterReference! : target.reference;
    w.ValueType paramType =
        translator.signatureForDirectCall(reference).inputs.single;
    translateExpression(node.value, paramType);
    if (!preserved) {
      call(node.targetReference);
      return voidMarker;
    }
    w.Local temp = addLocal(paramType);
    b.local_tee(temp);

    call(reference);
    b.local_get(temp);
    return temp.type;
  }

  @override
  w.ValueType visitSuperPropertyGet(
      SuperPropertyGet node, w.ValueType expectedType) {
    Member target = _lookupSuperTarget(node.interfaceTarget, setter: false);
    if (target is Procedure && !target.isGetter) {
      // Super tear-off
      w.StructType closureStruct = _pushClosure(
          translator.getTearOffClosure(target, b.moduleBuilder),
          translator.getTearOffType(target),
          () => visitThis(w.RefType.struct(nullable: false)));
      return w.RefType.def(closureStruct, nullable: false);
    }
    return _directGet(target, ThisExpression());
  }

  @override
  w.ValueType visitSuperPropertySet(
      SuperPropertySet node, w.ValueType expectedType) {
    Member target = _lookupSuperTarget(node.interfaceTarget, setter: true);
    return _directSet(target, ThisExpression(), node.value,
        preserved: expectedType != voidMarker, useUncheckedEntry: true);
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
        translateExpression(node.receiver, translator.topType);
        b.br_on_null(nullLabel);
      }, (_, __) {}, useUncheckedEntry: false);
      b.br(doneLabel);
      b.end(); // nullLabel
      switch (target.name.text) {
        case "hashCode":
          b.i64_const(2011);
          break;
        case "runtimeType":
          translateExpression(
              ConstantExpression(TypeLiteralConstant(NullType())), resultType);
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
      final intrinsic = intrinsifier.generateInstanceGetterIntrinsic(node);
      if (intrinsic != null) return intrinsic;

      return _directGet(singleTarget, node.receiver);
    } else {
      return _virtualCall(
          node,
          target,
          _VirtualCallKind.Get,
          (signature) =>
              translateExpression(node.receiver, signature.inputs.first),
          (_, __) {},
          useUncheckedEntry: false);
    }
  }

  @override
  w.ValueType visitDynamicGet(DynamicGet node, w.ValueType expectedType) {
    final receiver = node.receiver;
    final memberName = node.name;
    final forwarder = translator
        .getDynamicForwardersForModule(b.moduleBuilder)
        .getDynamicGetForwarder(memberName);

    // Evaluate receiver
    translateExpression(receiver, translator.topType);

    // Call get forwarder
    translator.callFunction(forwarder.function, b);

    return translator.topType;
  }

  @override
  w.ValueType visitDynamicSet(DynamicSet node, w.ValueType expectedType) {
    final receiver = node.receiver;
    final value = node.value;
    final memberName = node.name;
    final forwarder = translator
        .getDynamicForwardersForModule(b.moduleBuilder)
        .getDynamicSetForwarder(memberName);

    translateExpression(receiver, translator.topType);
    translateExpression(value, translator.topType);
    translator.callFunction(forwarder.function, b);

    return translator.topType;
  }

  w.ValueType _directGet(Member target, Expression receiver) {
    if (target is Field) {
      ClassInfo info = translator.classInfo[target.enclosingClass]!;
      int fieldIndex = translator.fieldIndex[target]!;
      w.ValueType receiverType = info.nonNullableType;
      w.ValueType fieldType = info.struct.fields[fieldIndex].type.unpacked;
      translateExpression(receiver, receiverType);
      b.struct_get(info.struct, fieldIndex);
      return fieldType;
    } else {
      // Instance call of getter
      assert(target is Procedure && target.isGetter);
      w.FunctionType targetFunctionType =
          translator.signatureForDirectCall(target.reference);
      translateExpression(receiver, targetFunctionType.inputs.single);
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
        translateExpression(node.receiver, translator.topType);
        b.br_on_null(nullLabel);
        translator.convertType(b, translator.topType, signature.inputs[0]);
      }, (_, __) {}, useUncheckedEntry: false);
      b.br(doneLabel);
      b.end(); // nullLabel
      switch (target.name.text) {
        case "toString":
          translateExpression(
              ConstantExpression(
                  StaticTearOffConstant(translator.nullToString)),
              resultType);
          break;
        case "noSuchMethod":
          translateExpression(
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

    return _virtualCall(
        node,
        target,
        _VirtualCallKind.Get,
        (signature) =>
            translateExpression(node.receiver, signature.inputs.first),
        (_, __) {},
        useUncheckedEntry: false);
  }

  @override
  w.ValueType visitInstanceSet(InstanceSet node, w.ValueType expectedType) {
    bool preserved = expectedType != voidMarker;
    w.Local? temp;
    Member? singleTarget = translator.singleTarget(node);
    final useUncheckedEntry =
        translator.canUseUncheckedEntry(node.receiver, node);
    if (singleTarget != null) {
      return _directSet(singleTarget, node.receiver, node.value,
          preserved: preserved, useUncheckedEntry: useUncheckedEntry);
    } else {
      _virtualCall(
          node,
          node.interfaceTarget,
          _VirtualCallKind.Set,
          (signature) =>
              translateExpression(node.receiver, signature.inputs.first),
          (signature, _) {
        w.ValueType paramType = signature.inputs.last;
        translateExpression(node.value, paramType);
        if (preserved) {
          temp = addLocal(paramType);
          b.local_tee(temp!);
        }
      }, useUncheckedEntry: useUncheckedEntry);
      if (preserved) {
        b.local_get(temp!);
        return temp!.type;
      } else {
        return voidMarker;
      }
    }
  }

  w.ValueType _directSet(Member target, Expression receiver, Expression value,
      {required bool preserved, required bool useUncheckedEntry}) {
    w.Local? temp;
    final Reference reference = translator.getFunctionEntry(
        (target is Field)
            ? target.setterReference!
            : (target as Procedure).reference,
        uncheckedEntry: useUncheckedEntry);
    final w.FunctionType targetFunctionType =
        translator.signatureForDirectCall(reference);
    final w.ValueType paramType = targetFunctionType.inputs.last;
    translateExpression(receiver, targetFunctionType.inputs.first);
    translateExpression(value, paramType);
    if (preserved) {
      temp = addLocal(paramType);
      b.local_tee(temp);
    }
    call(reference);
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
        b.moduleBuilder,
        ParameterInfo.fromLocalFunction(functionNode),
        "closure wrapper at ${functionNode.location}");
    return _pushClosure(
        closure,
        functionNode.computeFunctionType(Nullability.nonNullable),
        () => _pushContext(functionNode));
  }

  w.StructType _pushClosure(ClosureImplementation closure,
      DartType functionType, void Function() pushContext) {
    w.StructType struct = closure.representation.closureStruct;

    ClassInfo info = translator.closureInfo;
    translator.functions.recordClassAllocation(info.classId);

    b.pushObjectHeaderFields(translator, info);
    pushContext();
    translator.globals.readGlobal(b, closure.vtable);
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
      translator.globals.readGlobal(
          b,
          translator
              .getDummyValuesCollectorForModule(b.moduleBuilder)
              .dummyStructGlobal); // Dummy context
    }
  }

  @override
  w.ValueType visitFunctionInvocation(
      FunctionInvocation node, w.ValueType expectedType) {
    w.ValueType? intrinsicResult =
        intrinsifier.generateFunctionCallIntrinsic(node);
    if (intrinsicResult != null) return intrinsicResult;

    if (node.kind == FunctionAccessKind.Function ||
        translator.dynamicModuleSupportEnabled) {
      // Type of function is `Function`, without the argument types.
      return visitDynamicInvocation(
          DynamicInvocation(DynamicAccessKind.Dynamic, node.receiver, node.name,
              node.arguments),
          expectedType);
    }

    List<String> argNames = node.arguments.named.map((a) => a.name).toList()
      ..sort();
    ClosureRepresentation? representation = translator.closureLayouter
        .getClosureRepresentation(node.arguments.types.length,
            node.arguments.positional.length, argNames);
    if (representation == null) {
      // This is a dynamic function call with a signature that matches no
      // functions in the program.
      b.unreachable();
      return translator.topType;
    }

    final SingleClosureTarget? directClosureCall =
        translator.singleClosureTarget(node, representation, typeContext);

    if (directClosureCall != null) {
      return _generateDirectClosureCall(
          node, representation, directClosureCall);
    }

    return _generateClosureInvocation(node, representation);
  }

  w.ValueType _generateDirectClosureCall(FunctionInvocation node,
      ClosureRepresentation representation, SingleClosureTarget closureTarget) {
    final closureStruct = representation.closureStruct;
    final closureStructRef = w.RefType.def(closureStruct, nullable: false);
    final signature = closureTarget.signature;
    final paramInfo = closureTarget.paramInfo;
    final member = closureTarget.member;
    final lambdaFunction = closureTarget.lambdaFunction;

    if (lambdaFunction == null) {
      if (paramInfo.takesContextOrReceiver) {
        translateExpression(node.receiver, closureStructRef);
        b.struct_get(closureStruct, FieldIndex.closureContext);
        translator.convertType(b, closureContextFieldType, signature.inputs[0]);
        _visitArguments(node.arguments, signature, paramInfo, 1);
      } else {
        _visitArguments(node.arguments, signature, paramInfo, 0);
      }
      return translator.outputOrVoid(call(translator
          .getFunctionEntry(member.reference, uncheckedEntry: false)));
    } else {
      assert(paramInfo.takesContextOrReceiver);
      translateExpression(node.receiver, closureStructRef);
      b.struct_get(closureStruct, FieldIndex.closureContext);
      translator.convertType(b, closureContextFieldType, signature.inputs[0]);
      _visitArguments(node.arguments, signature, paramInfo, 1);
      return translator
          .outputOrVoid(translator.callFunction(lambdaFunction, b));
    }
  }

  w.ValueType _generateClosureInvocation(
      FunctionInvocation node, ClosureRepresentation representation) {
    final closureStruct = representation.closureStruct;

    // Evaluate receiver
    w.Local closureLocal =
        addLocal(w.RefType.def(closureStruct, nullable: false));
    translateExpression(node.receiver, closureLocal.type);
    b.local_tee(closureLocal);
    b.struct_get(closureStruct, FieldIndex.closureContext);

    // Type arguments
    for (DartType typeArg in node.arguments.types) {
      types.makeType(this, typeArg);
    }

    // Positional arguments
    for (Expression arg in node.arguments.positional) {
      translateExpression(arg, translator.topType);
    }

    // Named arguments
    final List<String> argNames =
        node.arguments.named.map((a) => a.name).toList()..sort();
    final Map<String, w.Local> namedLocals = {};
    for (final namedArg in node.arguments.named) {
      final w.Local namedLocal = addLocal(translator.topType);
      namedLocals[namedArg.name] = namedLocal;
      translateExpression(namedArg.value, namedLocal.type);
      b.local_set(namedLocal);
    }
    for (String name in argNames) {
      b.local_get(namedLocals[name]!);
    }

    final int vtableFieldIndex = representation.fieldIndexForSignature(
        node.arguments.positional.length, argNames);
    final w.FunctionType functionType =
        representation.getVtableFieldType(vtableFieldIndex);

    // Call entry point in vtable
    b.local_get(closureLocal);
    b.struct_get(closureStruct, FieldIndex.closureVtable);
    b.struct_get(representation.vtableStruct, vtableFieldIndex);
    b.call_ref(functionType);

    return translator.topType;
  }

  @override
  w.ValueType visitLocalFunctionInvocation(
      LocalFunctionInvocation node, w.ValueType expectedType) {
    var decl = node.variable.parent as FunctionDeclaration;
    Lambda lambda = closures.lambdas[decl.function]!;
    _pushContext(decl.function);
    Arguments arguments = node.arguments;
    _visitArguments(arguments, lambda.function.type,
        ParameterInfo.fromLocalFunction(decl.function), 1);
    b.comment("Local call of ${decl.variable.name}");
    translator.callFunction(lambda.function, b);
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
      translateExpression(node.expression, closureType);
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
    translateExpression(node.operand, w.NumType.i32);
    b.i32_eqz();
    return w.NumType.i32;
  }

  @override
  w.ValueType visitConditionalExpression(
      ConditionalExpression node, w.ValueType expectedType) {
    _conditional(
        node.condition,
        () => translateExpression(node.then, expectedType),
        () => translateExpression(node.otherwise, expectedType),
        [if (expectedType != voidMarker) expectedType]);
    return expectedType;
  }

  @override
  w.ValueType visitNullCheck(NullCheck node, w.ValueType expectedType) {
    w.ValueType operandType =
        translator.translateType(dartTypeOf(node.operand));
    w.ValueType nonNullOperandType = operandType.withNullability(false);

    // In rare cases the operand is non-nullable but TFA doesn't optimize away
    // the null check. If the operand is an unboxed type, the br_on_non_null
    // would fail to compile.
    if (!operandType.nullable) {
      translateExpression(node.operand, operandType);
      return nonNullOperandType;
    }
    w.Label nullCheckBlock = b.block(const [], [nonNullOperandType]);
    translateExpression(node.operand, operandType);

    // We lower a null check to a br_on_non_null, throwing a [TypeError] in
    // the null case.
    b.br_on_non_null(nullCheckBlock);
    call(translator.throwNullCheckErrorWithCurrentStack.reference);
    b.unreachable();
    b.end();
    return nonNullOperandType;
  }

  void _visitArguments(Arguments node, w.FunctionType signature,
      ParameterInfo paramInfo, int signatureOffset) {
    // Type arguments
    for (int i = 0; i < node.types.length; i++) {
      types.makeType(this, node.types[i]);
    }
    signatureOffset += node.types.length;

    // Positional arguments
    for (int i = 0; i < node.positional.length; i++) {
      translateExpression(
          node.positional[i], signature.inputs[signatureOffset + i]);
    }
    // Push default values for optional positional parameters.
    for (int i = node.positional.length; i < paramInfo.positional.length; i++) {
      final w.ValueType type = signature.inputs[signatureOffset + i];
      instantiateConstant(paramInfo.positional[i]!, type);
    }

    // Named arguments. Store evaluated arguments in locals to be able to
    // re-order them based on the `ParameterInfo`.
    final Map<String, w.Local> namedLocals = {};
    for (var namedArg in node.named) {
      final w.ValueType type = signature
          .inputs[signatureOffset + paramInfo.nameIndex[namedArg.name]!];
      final w.Local namedLocal = addLocal(type);
      namedLocals[namedArg.name] = namedLocal;
      translateExpression(namedArg.value, namedLocal.type);
      b.local_set(namedLocal);
    }
    // Re-order named arguments and push default values for optional named
    // parameters.
    for (String name in paramInfo.names) {
      w.Local? namedLocal = namedLocals[name];
      final w.ValueType type =
          signature.inputs[signatureOffset + paramInfo.nameIndex[name]!];
      if (namedLocal != null) {
        b.local_get(namedLocal);
      } else {
        instantiateConstant(paramInfo.named[name]!, type);
      }
    }
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

    final expressions = node.expressions;
    if (expressions.every(isConstantString)) {
      StringBuffer result = StringBuffer();
      for (final expr in expressions) {
        result.write(extractConstantString(expr));
      }
      final expr = StringLiteral(result.toString());
      return visitStringLiteral(expr, expectedType);
    }

    late final Procedure target;

    // We have special cases for 1/2/3/4 arguments.
    if (expressions.length <= 4) {
      final nullableObjectType =
          translator.translateType(translator.coreTypes.objectNullableRawType);
      for (final expression in expressions) {
        translateExpression(expression, nullableObjectType);
      }
      if (expressions.length == 1) {
        target = translator.jsStringInterpolate1;
      } else if (expressions.length == 2) {
        target = translator.jsStringInterpolate2;
      } else if (expressions.length == 3) {
        target = translator.jsStringInterpolate3;
      } else {
        assert(expressions.length == 4);
        target = translator.jsStringInterpolate4;
      }
    } else {
      final nullableObjectType = translator.coreTypes.objectNullableRawType;
      makeArrayFromExpressions(expressions, nullableObjectType);
      target = translator.jsStringInterpolate;
    }
    return translator.outputOrVoid(call(target.reference));
  }

  @override
  w.ValueType visitThrow(Throw node, w.ValueType expectedType) {
    // Front-end wraps the argument with `as Object` when necessary, so we can
    // assume non-nullable here.
    assert(!dartTypeOf(node.expression).isPotentiallyNullable);
    translateExpression(node.expression, translator.topTypeNonNullable);
    call(translator.errorThrowWithCurrentStackTrace.reference);
    b.unreachable();
    return expectedType;
  }

  @override
  w.ValueType visitRethrow(Rethrow node, w.ValueType expectedType) {
    final exceptionLocals = tryBlockLocals.last;
    b.local_get(exceptionLocals.exceptionLocal);
    b.local_get(exceptionLocals.stackTraceLocal);
    b.throw_(translator.getExceptionTag(b.moduleBuilder));
    return expectedType;
  }

  @override
  w.ValueType visitConstantExpression(
      ConstantExpression node, w.ValueType expectedType) {
    instantiateConstant(node.constant, expectedType);
    return expectedType;
  }

  w.ModuleBuilder? _recognizeDeferredModuleGuard(Let let) {
    if (!translator.options.enableDeferredLoading &&
        !translator.options.enableMultiModuleStressTestMode) {
      return null;
    }

    // TODO(http://dartbug.com/61764): Find better way to do this.
    //
    // If we have somewhere in the parent chain of [node] a
    //
    //   let
    //     _ = checkLibraryIsLoadedFromLoadId(<id>)
    //   in
    //     <body>
    //
    // Then we know that the constant use in <body> can only happen after the
    // given <id> was loaded, i.e. the constant use is deferred-load-guarded
    // by <id>.
    final init = let.variable.initializer;
    if (init is StaticInvocation) {
      final target = init.target;
      if (target == translator.checkLibraryIsLoadedFromLoadId) {
        final args = init.arguments.positional;
        final loadId = (args[0] as IntLiteral).value;
        return translator.moduleForLoadId(
            enclosingMember.enclosingLibrary, loadId);
      }
    }
    return null;
  }

  @override
  w.ValueType visitNullLiteral(NullLiteral node, w.ValueType expectedType) {
    instantiateConstant(NullConstant(), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitStringLiteral(StringLiteral node, w.ValueType expectedType) {
    instantiateConstant(StringConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitBoolLiteral(BoolLiteral node, w.ValueType expectedType) {
    instantiateConstant(BoolConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitIntLiteral(IntLiteral node, w.ValueType expectedType) {
    instantiateConstant(IntConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitDoubleLiteral(DoubleLiteral node, w.ValueType expectedType) {
    instantiateConstant(DoubleConstant(node.value), expectedType);
    return expectedType;
  }

  @override
  w.ValueType visitListLiteral(ListLiteral node, w.ValueType expectedType) {
    final useSharedCreator = types.isTypeConstant(node.typeArgument);

    final passType = !useSharedCreator;
    final passArray = node.expressions.isNotEmpty;

    final targetReference = passArray
        ? translator.growableListFromWasmArray.reference
        : translator.growableListEmpty.reference;

    final target = useSharedCreator
        ? translator
            .getPartialInstantiatorForModule(b.moduleBuilder)
            .getOneTypeArgumentForwarder(targetReference, node.typeArgument,
                'create${passArray ? '' : 'Empty'}List<${node.typeArgument}>')
        : translator.functions.getFunction(targetReference);

    if (passType) {
      types.makeType(this, node.typeArgument);
    }
    if (passArray) {
      makeArrayFromExpressions(node.expressions,
          translator.coreTypes.objectRawType(Nullability.nullable));
    }

    translator.callFunction(target, b);

    return target.type.outputs.single;
  }

  w.ValueType makeArrayFromExpressions(
      List<Expression> expressions, InterfaceType elementType) {
    return makeArray(
        translator.arrayTypeForDartType(elementType, mutable: true),
        expressions.length, (w.ValueType type, int i) {
      translateExpression(expressions[i], type);
    });
  }

  w.ValueType makeArray(w.ArrayType arrayType, int length,
      void Function(w.ValueType, int) generateItem) {
    return translator.makeArray(b, arrayType, length, generateItem);
  }

  @override
  w.ValueType visitMapLiteral(MapLiteral node, w.ValueType expectedType) {
    final useSharedCreator = types.isTypeConstant(node.keyType) &&
        types.isTypeConstant(node.valueType);

    final passTypes = !useSharedCreator;
    final passArray = node.entries.isNotEmpty;

    final targetReference = passArray
        ? translator.mapFromWasmArray.reference
        : translator.mapFactory.reference;

    final target = useSharedCreator
        ? translator
            .getPartialInstantiatorForModule(b.moduleBuilder)
            .getTwoTypeArgumentForwarder(
                targetReference,
                node.keyType,
                node.valueType,
                'create${passArray ? '' : 'Empty'}'
                'Map<${node.keyType}, ${node.valueType}>')
        : translator.functions.getFunction(targetReference);

    if (passTypes) {
      types.makeType(this, node.keyType);
      types.makeType(this, node.valueType);
    }
    if (passArray) {
      makeArray(translator.nullableObjectArrayType, 2 * node.entries.length,
          (elementType, elementIndex) {
        final index = elementIndex ~/ 2;
        final entry = node.entries[index];
        if (elementIndex % 2 == 0) {
          translateExpression(entry.key, elementType);
        } else {
          translateExpression(entry.value, elementType);
        }
      });
    }
    translator.callFunction(target, b);

    return target.type.outputs.single;
  }

  @override
  w.ValueType visitSetLiteral(SetLiteral node, w.ValueType expectedType) {
    final useSharedCreator = types.isTypeConstant(node.typeArgument);

    final passType = !useSharedCreator;
    final passArray = node.expressions.isNotEmpty;

    final targetReference = passArray
        ? translator.setFromWasmArray.reference
        : translator.setFactory.reference;

    final target = useSharedCreator
        ? translator
            .getPartialInstantiatorForModule(b.moduleBuilder)
            .getOneTypeArgumentForwarder(targetReference, node.typeArgument,
                'create${passArray ? '' : 'Empty'}Set<${node.typeArgument}>')
        : translator.functions.getFunction(targetReference);

    if (passType) {
      types.makeType(this, node.typeArgument);
    }
    if (passArray) {
      makeArrayFromExpressions(node.expressions,
          translator.coreTypes.objectRawType(Nullability.nullable));
    }
    translator.callFunction(target, b);

    return target.type.outputs.single;
  }

  @override
  w.ValueType visitTypeLiteral(TypeLiteral node, w.ValueType expectedType) {
    return types.makeType(this, node.type);
  }

  @override
  w.ValueType visitIsExpression(IsExpression node, w.ValueType expectedType) {
    final operandType = dartTypeOf(node.operand);
    final boxedOperandType = operandType.isPotentiallyNullable
        ? translator.topType
        : translator.topTypeNonNullable;
    translateExpression(node.operand, boxedOperandType);
    types.emitIsTest(this, node.type, operandType, node.location);
    return w.NumType.i32;
  }

  @override
  w.ValueType visitAsExpression(AsExpression node, w.ValueType expectedType) {
    final isImplicitCheck =
        (node.isTypeError || node.isCovarianceCheck || node.isForDynamic);
    if (node.isUnchecked ||
        (translator.options.omitImplicitTypeChecks && isImplicitCheck) ||
        (translator.options.omitExplicitTypeChecks && !isImplicitCheck)) {
      return translateExpression(node.operand, expectedType);
    }

    final operandType = dartTypeOf(node.operand);
    final boxedOperandType = operandType.isPotentiallyNullable
        ? translator.topType
        : translator.topTypeNonNullable;
    translateExpression(node.operand, boxedOperandType);
    return types.emitAsCheck(this, node.isCovarianceCheck, node.type,
        operandType, boxedOperandType, node.location);
  }

  @override
  w.ValueType visitLoadLibrary(LoadLibrary node, w.ValueType expectedType) {
    throw UnsupportedError(
        'LoadLibrary should be lowered by modular transformer.');
  }

  @override
  w.ValueType visitCheckLibraryIsLoaded(
      CheckLibraryIsLoaded node, w.ValueType expectedType) {
    throw UnsupportedError(
        'CheckLibraryIsLoaded should be lowered by modular transformer.');
  }

  /// Pushes the `_Type` object for a function or class type parameter to the
  /// stack and returns the value type of the object.
  w.ValueType instantiateTypeParameter(TypeParameter parameter) {
    w.ValueType resultType;

    w.Local? local = typeLocals[parameter];
    Capture? capture = closures.captures[parameter];
    if (local != null) {
      b.local_get(local);
      resultType = local.type;
    } else if (capture != null) {
      Capture capture = closures.captures[parameter]!;
      b.local_get(capture.context.currentLocal);
      b.struct_get(capture.context.struct, capture.fieldIndex);
      resultType = capture.type;
    } else {
      Class cls = parameter.declaration as Class;
      ClassInfo info = translator.classInfo[cls]!;
      int fieldIndex = translator.typeParameterIndex[parameter]!;
      visitThis(info.nonNullableType);
      b.struct_get(info.struct, fieldIndex);
      resultType = info.struct.fields[fieldIndex].type.unpacked;
    }

    translator.convertType(b, resultType, types.nonNullableTypeType);
    return types.nonNullableTypeType;
  }

  @override
  w.ValueType visitRecordLiteral(RecordLiteral node, w.ValueType expectedType) {
    final ClassInfo recordClassInfo =
        translator.getRecordClassInfo(node.recordType);
    translator.functions.recordClassAllocation(recordClassInfo.classId);

    b.pushObjectHeaderFields(translator, recordClassInfo);
    for (Expression positional in node.positional) {
      translateExpression(positional, translator.topType);
    }
    for (NamedExpression named in node.named) {
      translateExpression(named.value, translator.topType);
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

    translateExpression(node.receiver, translator.topTypeNonNullable);
    b.ref_cast(w.RefType(recordClassInfo.struct, nullable: false));
    b.struct_get(
        recordClassInfo.struct, recordShape.getPositionalIndex(node.index));

    return translator.topType;
  }

  @override
  w.ValueType visitRecordNameGet(RecordNameGet node, w.ValueType expectedType) {
    final RecordShape recordShape = RecordShape.fromType(node.receiverType);
    final ClassInfo recordClassInfo =
        translator.getRecordClassInfo(node.receiverType);

    translateExpression(node.receiver, translator.topTypeNonNullable);
    b.ref_cast(w.RefType(recordClassInfo.struct, nullable: false));
    b.struct_get(recordClassInfo.struct, recordShape.getNameIndex(node.name));

    return translator.topType;
  }

  @override
  w.ValueType visitFileUriExpression(
      FileUriExpression node, w.ValueType expectedType) {
    return translateExpression(node.expression, expectedType);
  }

  /// Generate code that checks type of an argument against an expected type
  /// and throws a `TypeError` on failure.
  ///
  /// Expects a boxed object (whose type is to be checked) on the stack.
  ///
  /// [argName] is used in the type error as the name of the argument that
  /// doesn't match the expected type.
  void _generateArgumentTypeCheck(
    String argName,
    w.RefType argumentType,
    DartType testedAgainstType,
  ) {
    if (translator.options.minify) {
      // We don't need to include the name in the error message, so we can use
      // the optimized `as` checks.
      types.emitAsCheck(this, false, testedAgainstType,
          translator.coreTypes.objectNullableRawType, argumentType);
      b.drop();
    } else {
      final argLocal = b.addLocal(argumentType);
      b.local_tee(argLocal);
      types.emitIsTest(
          this, testedAgainstType, translator.coreTypes.objectNullableRawType);
      b.i32_eqz();
      b.if_();
      b.local_get(argLocal);
      types.makeType(this, testedAgainstType);
      _emitString(argName);
      call(translator.stackTraceCurrent.reference);
      call(translator.throwArgumentTypeCheckError.reference);
      b.unreachable();
      b.end();
    }
  }

  void _generateTypeArgumentBoundCheck(
    String argName,
    w.Local typeLocal,
    DartType bound,
  ) {
    b.local_get(typeLocal);
    final boundLocal = b.addLocal(translator.runtimeTypeType);
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

  void _emitString(String str) => translateExpression(StringLiteral(str),
      translator.translateType(translator.coreTypes.stringNonNullableRawType));

  @override
  void visitPatternSwitchStatement(PatternSwitchStatement node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError("CodeGenerator.visitPatternSwitchStatement");
  }

  @override
  void visitPatternVariableDeclaration(PatternVariableDeclaration node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError("CodeGenerator.visitPatternVariableDeclaration");
  }

  @override
  void visitIfCaseStatement(IfCaseStatement node) {
    // This node is internal to the front end and removed by the constant
    // evaluator.
    throw UnsupportedError("CodeGenerator.visitIfCaseStatement");
  }

  void debugRuntimePrint(String s) {
    final printFunction =
        translator.functions.getFunction(translator.printToConsole.reference);
    translator.constants.instantiateConstant(
        b, StringConstant(s), printFunction.type.inputs[0]);
    translator.callFunction(printFunction, b);
  }

  @override
  void visitAuxiliaryStatement(AuxiliaryStatement node) {
    throw UnsupportedError(
        "Unsupported auxiliary statement $node (${node.runtimeType}).");
  }

  @override
  void visitAuxiliaryInitializer(AuxiliaryInitializer node) {
    throw UnsupportedError(
        "Unsupported auxiliary initializer $node (${node.runtimeType}).");
  }

  void emitUnimplementedExternalError(Member member) {
    b.comment("Unimplemented external member $member at ${member.location}");
    if (member.isInstanceMember) {
      b.local_get(paramLocals[0]);
    } else {
      b.ref_null(w.HeapType.none);
    }
    translator.constants.instantiateConstant(
        b,
        translator.symbols.methodSymbolFromName(member.name),
        translator.classInfo[translator.symbolClass]!.nonNullableType);
    call(translator
        .noSuchMethodErrorThrowUnimplementedExternalMemberError.reference);
    b.unreachable();
  }

  void instantiateConstant(Constant constant, w.ValueType expectedType) {
    translator.constants.instantiateConstant(
      b,
      constant,
      expectedType,
      deferredModuleGuard: _activeDeferredLoadingGuard,
    );
  }
}

CodeGenerator getMemberCodeGenerator(Translator translator,
    w.FunctionBuilder functionBuilder, Reference memberReference) {
  final member = memberReference.asMember;
  final asyncMarker = member.function?.asyncMarker ?? AsyncMarker.Sync;
  final codeGen = getInlinableMemberCodeGenerator(
      translator, asyncMarker, functionBuilder.type, memberReference);
  if (codeGen != null) return codeGen;

  final procedure = member as Procedure;

  if (asyncMarker == AsyncMarker.SyncStar) {
    return SyncStarProcedureCodeGenerator(
        translator, functionBuilder, procedure);
  }
  assert(asyncMarker == AsyncMarker.Async);
  return AsyncProcedureCodeGenerator(translator, functionBuilder, procedure);
}

CodeGenerator getLambdaCodeGenerator(Translator translator, Lambda lambda,
    Member enclosingMember, Closures enclosingMemberClosures) {
  final asyncMarker = lambda.functionNode.asyncMarker;

  if (asyncMarker == AsyncMarker.Async) {
    return AsyncLambdaCodeGenerator(
        translator, enclosingMember, lambda, enclosingMemberClosures);
  }
  if (asyncMarker == AsyncMarker.SyncStar) {
    return SyncStarLambdaCodeGenerator(
        translator, enclosingMember, lambda, enclosingMemberClosures);
  }
  assert(asyncMarker == AsyncMarker.Sync);
  return SynchronousLambdaCodeGenerator(
      translator, enclosingMember, lambda, enclosingMemberClosures);
}

/// Returns a [CodeGenerator] for the given member iff that member can be
/// inlined.
CodeGenerator? getInlinableMemberCodeGenerator(Translator translator,
    AsyncMarker asyncMarker, w.FunctionType functionType, Reference reference) {
  final Member member = reference.asMember;

  if (reference.isTearOffReference) {
    return TearOffCodeGenerator(translator, functionType, member);
  }
  if (reference.isTypeCheckerReference) {
    return TypeCheckerCodeGenerator(translator, functionType, member);
  }

  if (member is Constructor) {
    if (reference.isConstructorBodyReference) {
      return ConstructorCodeGenerator(translator, functionType, member);
    } else if (reference.isInitializerReference) {
      return InitializerListCodeGenerator(translator, functionType, member);
    } else {
      return ConstructorAllocatorCodeGenerator(
          translator, functionType, member);
    }
  }

  if (member is Field) {
    if (member.isStatic) {
      if (reference.isImplicitGetter || reference.isImplicitSetter) {
        return StaticFieldImplicitAccessorCodeGenerator(
            translator, functionType, member, reference.isImplicitGetter);
      }
      return StaticFieldInitializerCodeGenerator(
          translator, functionType, member);
    }
    final useUncheckedEntry = reference.isUncheckedEntryReference;
    return ImplicitFieldAccessorCodeGenerator(translator, functionType, member,
        reference.isImplicitGetter, useUncheckedEntry);
  }

  if (member is Procedure && asyncMarker == AsyncMarker.Sync) {
    return SynchronousProcedureCodeGenerator(
        translator, functionType, member, reference.entryKind);
  }
  assert(
      asyncMarker == AsyncMarker.SyncStar || asyncMarker == AsyncMarker.Async);
  return null;
}

class SynchronousProcedureCodeGenerator extends AstCodeGenerator {
  final Procedure member;
  final EntryPoint kind;

  SynchronousProcedureCodeGenerator(Translator translator,
      w.FunctionType functionType, this.member, this.kind)
      : super(translator, functionType, member) {
    assert(
        !translator.needToCheckTypesFor(member) || kind != EntryPoint.normal);
  }

  @override
  void generateInternal() {
    final source = member.enclosingComponent!.uriToSource[member.fileUri]!;
    setSourceMapSourceAndFileOffset(source, member.fileOffset);

    if (intrinsifier.generateMemberIntrinsic(
        member.reference, functionType, paramLocals, returnLabel)) {
      b.end();
      return;
    }

    if (member.isExternal) {
      emitUnimplementedExternalError(member);
      b.end();
      return;
    }

    closures = translator.getClosures(member);

    switch (kind) {
      case EntryPoint.normal:
        b.comment('Normal Entry');
        _makeNonMultiEntryPointFunction();
      case EntryPoint.checked:
        b.comment('Checked Entry');
        _makeMultipleEntryPoint(true);
      case EntryPoint.unchecked:
        b.comment('Unchecked Entry');
        _makeMultipleEntryPoint(false);
      case EntryPoint.body:
        b.comment('Body for Checked & Unchecked Entry');
        _makeMultipleEntryPointSharedBody();
        break;
    }
  }

  void _makeMultipleEntryPoint(bool checked) {
    final function = member.function;
    final signature = translator.signatureForDirectCall(member.bodyReference);
    if (checked) {
      setupParametersForCheckedEntry(member);
    } else {
      setupParametersForUncheckedEntry(member);
    }

    int arg = 0;
    visitThis(signature.inputs[arg++]);
    for (final parameter in function.typeParameters) {
      final r = instantiateTypeParameter(parameter);
      translator.convertType(b, r, signature.inputs[arg++]);
    }
    for (final parameter in function.positionalParameters) {
      final local = locals[parameter]!;
      b.local_get(local);
      translator.convertType(b, local.type, signature.inputs[arg++]);
    }
    for (final parameter in function.namedParameters) {
      final local = locals[parameter]!;
      b.local_get(local);
      translator.convertType(b, local.type, signature.inputs[arg++]);
    }

    final outputs = call(member.bodyReference);
    if (outputs.isNotEmpty) {
      translator.convertType(b, outputs.single, functionType.outputs.single);
    }
    _returnFromFunction();
    b.end();
  }

  void _makeMultipleEntryPointSharedBody() {
    final function = member.function;
    final typeParameters = function.typeParameters;
    final positionals = function.positionalParameters;
    final named = function.namedParameters;

    int param = _initializeThis(member.reference);

    for (int i = 0; i < typeParameters.length; i++) {
      final typeParameter = typeParameters[i];
      typeLocals[typeParameter] = paramLocals[param++];
    }
    void setupParameter(VariableDeclaration parameter) {
      // The body may assign less precise types to the parameter variable than
      // what the caller provides.
      w.Local local = paramLocals[param++];
      if (translator.typeOfCheckedParameterVariable(parameter) !=
          parameter.type) {
        final newLocal = addLocal(translator.translateType(parameter.type));
        b.local_get(local);
        translator.convertType(b, local.type, newLocal.type);
        b.local_set(newLocal);
        local = newLocal;
      }
      locals[parameter] = local;
    }

    for (int i = 0; i < positionals.length; i++) {
      setupParameter(positionals[i]);
    }
    for (int i = 0; i < named.length; i++) {
      setupParameter(named[i]);
    }

    setupContexts(member);
    Statement? body = member.function.body;
    if (body != null) {
      translateStatement(body);
    }

    _implicitReturn();
    b.end();
  }

  void _makeNonMultiEntryPointFunction() {
    setupParametersForNormalEntry(member);
    setupContexts(member);
    Statement? body = member.function.body;
    if (body != null) {
      translateStatement(body);
    }
    _implicitReturn();
    b.end();
    return;
  }
}

class TearOffCodeGenerator extends AstCodeGenerator {
  final Member member;

  TearOffCodeGenerator(
      Translator translator, w.FunctionType functionType, this.member)
      : super(translator, functionType, member);

  @override
  void generateInternal() {
    // Initialize [Closures] without [Closures.captures]: [Closures.captures] is
    // used by `makeType` below, when generating runtime types of type
    // parameters of the function type, but the type parameters are not
    // captured, always loaded from the `this` struct.
    closures = translator.getClosures(member, findCaptures: false);

    _initializeThis(member.reference);
    Procedure procedure = member as Procedure;
    DartType functionType = translator.getTearOffType(procedure);
    ClosureImplementation closure =
        translator.getTearOffClosure(procedure, b.moduleBuilder);
    w.StructType struct = closure.representation.closureStruct;

    ClassInfo info = translator.closureInfo;
    translator.functions.recordClassAllocation(info.classId);

    b.pushObjectHeaderFields(translator, info);
    b.local_get(paramLocals[0]); // `this` as context
    // The closure requires a struct value so box `this` if necessary.
    translator.convertType(b, paramLocals[0].type,
        struct.fields[FieldIndex.closureContext].type.unpacked);
    translator.globals.readGlobal(b, closure.vtable);
    types.makeType(this, functionType);
    b.struct_new(struct);
    b.end();
  }
}

class TypeCheckerCodeGenerator extends AstCodeGenerator {
  final Member member;

  TypeCheckerCodeGenerator(
      Translator translator, w.FunctionType functionType, this.member)
      : super(translator, functionType, member);

  @override
  void generateInternal() {
    // Initialize [Closures] without [Closures.captures]: Similar to
    // [TearOffCodeGenerator], type parameters will be loaded from the `this`
    // struct.
    closures = translator.getClosures(member, findCaptures: false);
    if (member is Field ||
        (member is Procedure && (member as Procedure).isSetter)) {
      _generateFieldSetterTypeCheckerMethod();
    } else {
      _generateProcedureTypeCheckerMethod();
    }
  }

  /// Generate type checker method for a method.
  ///
  /// This function will be called by an invocation forwarder in a dynamic
  /// invocation to type check parameters before calling the actual method.
  void _generateProcedureTypeCheckerMethod() {
    final receiverLocal = paramLocals[0];
    final typeArgsLocal = paramLocals[1];
    final positionalArgsLocal = paramLocals[2];
    final namedArgsLocal = paramLocals[3];

    _initializeThis(member.reference);

    final typeType =
        translator.classInfo[translator.typeClass]!.nonNullableType;

    final target =
        translator.getFunctionEntry(member.reference, uncheckedEntry: false);
    final targetParamInfo = translator.paramInfoForDirectCall(target);

    final procedure = member as Procedure;

    // Bind type parameters
    final memberTypeParams = procedure.function.typeParameters;
    assert(memberTypeParams.length == targetParamInfo.typeParamCount);

    if (memberTypeParams.isNotEmpty) {
      // Type argument list is either empty or have the right number of types
      // (checked by the forwarder).
      b.local_get(typeArgsLocal);
      b.array_len();
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
        b.i32_const(typeParamIdx);
        b.array_get(translator.typeArrayType);
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

    if (!translator.options.omitImplicitTypeChecks) {
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

      for (int positionalParamIdx = 0;
          positionalParamIdx < memberPositionalParams.length;
          positionalParamIdx += 1) {
        final param = memberPositionalParams[positionalParamIdx];
        b.local_get(positionalArgsLocal);
        b.i32_const(positionalParamIdx);
        b.array_get(translator.nullableObjectArrayType);
        _generateArgumentTypeCheck(param.name!, translator.topType, param.type);
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
        b.local_get(namedArgsLocal);
        b.i32_const(mapNamedParameterToArrayIndex(param.name!));
        b.array_get(translator.nullableObjectArrayType);
        _generateArgumentTypeCheck(param.name!, translator.topType, param.type);
      }
    }

    // Argument types are as expected, call the member function
    final w.FunctionType memberWasmFunctionType =
        translator.signatureForDirectCall(target);
    final List<w.ValueType> memberWasmInputs = memberWasmFunctionType.inputs;

    b.local_get(receiverLocal);
    translator.convertType(b, receiverLocal.type, memberWasmInputs[0]);

    for (final typeParam in memberTypeParams) {
      b.local_get(typeLocals[typeParam]!);
    }

    int memberParamIdx =
        1 + targetParamInfo.typeParamCount; // skip receiver and type args

    void pushArgument(w.Local listLocal, int listIdx, int wasmInputIdx) {
      b.local_get(listLocal);
      b.i32_const(listIdx);
      b.array_get(translator.nullableObjectArrayType);
      translator.convertType(
          b, translator.topType, memberWasmInputs[wasmInputIdx]);
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

    call(target);

    translator.convertType(
        b,
        translator.outputOrVoid(memberWasmFunctionType.outputs),
        translator.topType);

    b.return_();
    b.end();
  }

  /// Generate type checker method for a setter.
  ///
  /// This function will be called by a setter forwarder in a dynamic set to
  /// type check the setter argument before calling the actual setter.
  void _generateFieldSetterTypeCheckerMethod() {
    final receiverLocal = paramLocals[0];
    final positionalArgLocal = paramLocals[1];

    _initializeThis(member.reference);

    final member_ = member;
    DartType paramType;
    if (member_ is Field) {
      paramType = member_.type;
    } else {
      paramType = (member_ as Procedure).setterType;
    }

    if (!translator.options.omitImplicitTypeChecks) {
      b.local_get(positionalArgLocal);
      _generateArgumentTypeCheck(
        member.name.text,
        positionalArgLocal.type as w.RefType,
        paramType,
      );
    }

    ClassInfo info = translator.classInfo[member_.enclosingClass]!;
    if (member_ is Field) {
      int fieldIndex = translator.fieldIndex[member_]!;
      b.local_get(receiverLocal);
      translator.convertType(b, receiverLocal.type, info.nonNullableType);
      b.local_get(positionalArgLocal);
      translator.convertType(b, positionalArgLocal.type,
          info.struct.fields[fieldIndex].type.unpacked);
      b.struct_set(info.struct, fieldIndex);
    } else {
      final setterProcedure = member_ as Procedure;
      final target = translator.getFunctionEntry(setterProcedure.reference,
          uncheckedEntry: false);
      final setterProcedureWasmType = translator.signatureForDirectCall(target);
      final setterWasmInputs = setterProcedureWasmType.inputs;
      assert(setterWasmInputs.length == 2);
      b.local_get(receiverLocal);
      translator.convertType(b, receiverLocal.type, setterWasmInputs[0]);
      b.local_get(positionalArgLocal);
      translator.convertType(b, positionalArgLocal.type, setterWasmInputs[1]);
      call(target);
    }

    b.local_get(positionalArgLocal);
    b.end(); // end function
  }
}

class InitializerListCodeGenerator extends AstCodeGenerator {
  final Constructor member;

  InitializerListCodeGenerator(
      Translator translator, w.FunctionType functionType, this.member)
      : super(translator, functionType, member);

  @override
  void generateInternal() {
    // Closures are built when constructor functions are added to worklist.
    closures = translator.constructorClosures[member.reference]!;

    final source = member.enclosingComponent!.uriToSource[member.fileUri]!;
    setSourceMapSourceAndFileOffset(source, member.fileOffset);

    if (member.isExternal) {
      emitUnimplementedExternalError(member);
    } else {
      generateInitializerList();
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
  void generateInitializerList() {
    _setupInitializerListParametersAndContexts();

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
        return;
      }

      // checks if a FieldInitializer was dropped because the constructor body
      // throws an error
      for (Field field in info.cls!.fields) {
        if (field.isInstanceMember && !fieldLocals.containsKey(field)) {
          b.unreachable();
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
  }

  void _setupInitializerListParametersAndContexts() {
    setupParameters(member.initializerReference, isForwarder: true);
    allocateContext(member);
    captureParameters();
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
}

class ConstructorAllocatorCodeGenerator extends AstCodeGenerator {
  final Constructor member;

  ConstructorAllocatorCodeGenerator(
      Translator translator, w.FunctionType functionType, this.member)
      : super(translator, functionType, member);

  @override
  void generateInternal() {
    // Closures are built when constructor functions are added to worklist.
    closures = translator.constructorClosures[member.reference]!;

    final source = member.enclosingComponent!.uriToSource[member.fileUri]!;
    setSourceMapSourceAndFileOffset(source, member.fileOffset);

    generateConstructorAllocator();
  }

  // Generates a function for allocating an object. This calls the separate
  // initializer list and constructor body methods, and allocates a struct for
  // the object.
  void generateConstructorAllocator() {
    setupParameters(member.reference, isForwarder: true);

    w.FunctionType initializerMethodType =
        translator.signatureForDirectCall(member.initializerReference);

    List<w.Local> constructorArgs =
        _getConstructorArgumentLocals(member.reference);

    for (w.Local local in constructorArgs) {
      b.local_get(local);
    }

    b.comment("Direct call of '$member Initializer'");
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
    w.Local? contextLocal;

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
    b.pushObjectHeaderFields(translator, info);

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

    b.comment("Direct call of $member Constructor Body");
    call(member.constructorBodyReference);

    b.local_get(temp);
    b.end();
  }
}

class ConstructorCodeGenerator extends AstCodeGenerator {
  final Constructor member;

  ConstructorCodeGenerator(
      Translator translator, w.FunctionType functionType, this.member)
      : super(translator, functionType, member);

  @override
  void generateInternal() {
    // Closures are built when constructor functions are added to worklist.
    closures = translator.constructorClosures[member.reference]!;

    final source = member.enclosingComponent!.uriToSource[member.fileUri]!;
    setSourceMapSourceAndFileOffset(source, member.fileOffset);

    generateConstructorBody();
  }

  // Generates a function for a constructor's body, where the allocated struct
  // object is passed to this function.
  void generateConstructorBody() {
    _setupConstructorBodyParametersAndContexts();

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
      int numConstructorArgs =
          _getConstructorArgumentLocals(member.constructorBodyReference).length;

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
      translateStatement(body);
    }

    b.end();
  }

  void _setupConstructorBodyParametersAndContexts() {
    ParameterInfo paramInfo =
        translator.paramInfoForDirectCall(member.constructorBodyReference);

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
    int parameterOffset = _initializeThis(member.constructorBodyReference) +
        (hasConstructorContext ? 1 : 0);
    int implicitParams = parameterOffset + paramInfo.typeParamCount;

    _setupLocalParameters(member, paramInfo, parameterOffset, implicitParams);
    allocateContext(member.function);
  }
}

class StaticFieldInitializerCodeGenerator extends AstCodeGenerator {
  final Field field;

  StaticFieldInitializerCodeGenerator(
      Translator translator, w.FunctionType functionType, this.field)
      : super(translator, functionType, field);

  @override
  void generateInternal() {
    final source = field.enclosingComponent!.uriToSource[field.fileUri]!;
    setSourceMapSourceAndFileOffset(source, field.fileOffset);

    // Static field initializer function
    closures = translator.getClosures(field);

    w.Global global = translator.globals.getGlobalForStaticField(field);
    w.Global? flag = translator.globals.getGlobalInitializedFlag(field);
    translateExpression(field.initializer!, global.type.type);
    b.global_set(global);
    if (flag != null) {
      b.i32_const(1);
      b.global_set(flag);
    }
    b.global_get(global);
    translator.convertType(b, global.type.type, outputs.single);
    b.end();
  }
}

/// Will eagerly initialize a static field as part of the module's start
/// function.
class EagerStaticFieldInitializerCodeGenerator extends AstCodeGenerator {
  final Field field;
  final w.Global global;

  EagerStaticFieldInitializerCodeGenerator(
      Translator translator, this.field, this.global)
      : super(translator, w.FunctionType([], []), field);

  @override
  void generateInternal() {
    final source = field.enclosingComponent!.uriToSource[field.fileUri]!;
    setSourceMapSourceAndFileOffset(source, field.fileOffset);

    translateExpression(field.initializer!, global.type.type);
    b.global_set(global);
  }
}

class StaticFieldImplicitAccessorCodeGenerator extends AstCodeGenerator {
  final Field field;
  final bool isImplicitGetter;

  StaticFieldImplicitAccessorCodeGenerator(Translator translator,
      w.FunctionType functionType, this.field, this.isImplicitGetter)
      : super(translator, functionType, field);

  @override
  void generateInternal() {
    final global = translator.globals.getGlobalForStaticField(field);
    final flag = translator.globals.getGlobalInitializedFlag(field);
    if (isImplicitGetter) {
      final initFunction =
          translator.functions.getExistingFunction(field.fieldReference);
      _generateGetter(global, flag, initFunction);
    } else {
      _generateSetter(global, flag);
    }
    b.end();
  }

  void _generateGetter(
      w.Global global, w.Global? flag, w.BaseFunction? initFunction) {
    if (initFunction == null) {
      // Statically initialized
      b.global_get(global);
    } else {
      if (flag != null) {
        // Explicit initialization flag
        b.global_get(flag);
        b.if_(const [], [global.type.type]);
        b.global_get(global);
        b.else_();
        translator.callFunction(initFunction, b);
        b.end();
      } else {
        // Null signals uninitialized
        w.Label block = b.block(const [], [initFunction.type.outputs.single]);
        b.global_get(global);
        b.br_on_non_null(block);
        translator.callFunction(initFunction, b);
        b.end();
      }
    }
  }

  void _generateSetter(w.Global global, w.Global? flag) {
    b.local_get(paramLocals.single);
    b.global_set(global);
    if (flag != null) {
      b.i32_const(1); // true
      b.global_set(flag);
    }
  }
}

class ImplicitFieldAccessorCodeGenerator extends AstCodeGenerator {
  final Field field;
  final bool isImplicitGetter;
  final bool useUncheckedEntry;

  ImplicitFieldAccessorCodeGenerator(
    Translator translator,
    w.FunctionType functionType,
    this.field,
    this.isImplicitGetter,
    this.useUncheckedEntry,
  ) : super(translator, functionType, field);

  @override
  void generateInternal() {
    thisLocal = preciseThisLocal = paramLocals[0];

    // Conceptually not needed for implicit accessors, but currently the code
    // that instantiates types uses closure information to see whether a type
    // parameter was captured (and loads it from context chain) or not (and
    // loads it directly from `this`).
    closures = translator.getClosures(field, findCaptures: false);

    final source = field.enclosingComponent!.uriToSource[field.fileUri]!;
    setSourceMapSourceAndFileOffset(source, field.fileOffset);

    // Implicit getter or setter
    w.StructType struct = translator.classInfo[field.enclosingClass!]!.struct;
    w.RefType structType = w.RefType.def(struct, nullable: false);
    int fieldIndex = translator.fieldIndex[field]!;
    w.ValueType fieldType = struct.fields[fieldIndex].type.unpacked;

    void getThis() {
      w.Local thisLocal = paramLocals[0];
      b.local_get(thisLocal);
      translator.convertType(b, thisLocal.type, structType);
    }

    if (isImplicitGetter) {
      // Implicit getter
      getThis();
      b.struct_get(struct, fieldIndex);
      translator.convertType(b, fieldType, returnType);
    } else {
      // Implicit setter
      w.Local valueLocal = paramLocals[1];
      getThis();

      if (translator.needToCheckTypesFor(field) &&
          translator.needToCheckImplicitSetterValue(field,
              uncheckedEntry: useUncheckedEntry)) {
        final boxedType = field.type.isPotentiallyNullable
            ? translator.topType
            : translator.topTypeNonNullable;
        w.Local operand = valueLocal;
        if (!operand.type.isSubtypeOf(boxedType)) {
          final boxedOperand = addLocal(boxedType);
          b.local_get(operand);
          translator.convertType(b, operand.type, boxedOperand.type);
          b.local_set(boxedOperand);
          operand = boxedOperand;
        }
        b.local_get(operand);
        _generateArgumentTypeCheck(
          field.name.text,
          operand.type as w.RefType,
          field.type,
        );
      }

      b.local_get(valueLocal);
      translator.convertType(b, valueLocal.type, fieldType);
      b.struct_set(struct, fieldIndex);
      assert(functionType.outputs.isEmpty);
    }
    b.end();
  }
}

class SynchronousLambdaCodeGenerator extends AstCodeGenerator {
  final Lambda lambda;
  final Closures enclosingMemberClosures;

  SynchronousLambdaCodeGenerator(Translator translator, Member enclosingMember,
      this.lambda, this.enclosingMemberClosures)
      : super(translator, lambda.function.type, enclosingMember);

  @override
  void generateInternal() {
    closures = enclosingMemberClosures;

    setSourceMapSource(lambda.functionNodeSource);

    assert(lambda.functionNode.asyncMarker != AsyncMarker.Async);

    setupLambdaParametersAndContexts(lambda);

    translateStatement(lambda.functionNode.body!);
    _implicitReturn();
    b.end();
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

/// Info needed to represent a switch statement using a br_table instruction.
///
/// This is used for switches on integers and enums (using their indicies). We
/// map each option to an index in the jump table and then jump directly to the
/// target case. This is much faster than iteratively comparing each cases's
/// expression to the switch expression.
///
/// Sometimes switches over ranges of ints are sparse enough that a table would
/// bloat the code compared to the iterative comparison.
class BrTableInfo {
  // At least 50% of the [min, max] must be occupied for us to use `br_table`.
  static const double _minimumTableOccupancy = 0.5;
  // This is the maximum size where it's always worth it to use a br_table.
  // If the br_table is bigger than this then we start to check sparseness.
  // Below this point we always accept the potential code size hit.
  static const int _maxSparseSize = 50;

  int get rangeSize => _rangeSize(minValue, maxValue);
  final int minValue;
  final int maxValue;
  final void Function(w.Local switchExprLocal) _brTableExpr;
  final Map<int, SwitchCase> caseMap;

  BrTableInfo._(this.minValue, this.maxValue, this.caseMap, this._brTableExpr)
      : assert(!_isTooSparse(minValue, maxValue, caseMap));

  /// Heuristically validate whether the provided table would be too sparse and
  /// if so return null. Otherwise return the expected table.
  static BrTableInfo? build(Map<int, SwitchCase> caseMap,
      void Function(w.Local switchExprLocal) brTableExpr,
      {required int minValue, required int maxValue}) {
    // Validate the table density and size is worth putting into a br_table.
    if (_isTooSparse(minValue, maxValue, caseMap)) return null;

    return BrTableInfo._(minValue, maxValue, caseMap, brTableExpr);
  }

  static bool _isTooSparse(int min, int max, Map<int, SwitchCase> caseMap) {
    int rangeSize = _rangeSize(min, max);
    return (caseMap.length / rangeSize) < _minimumTableOccupancy &&
        rangeSize > _maxSparseSize;
  }

  static int _rangeSize(int min, int max) => max - min + 1;

  void emitBrTableExpr(w.InstructionsBuilder b, w.Local switchExprLocal) {
    _brTableExpr(switchExprLocal);
    // Normalize on 0.
    if (minValue != 0) {
      b.i64_const(minValue);
      b.i64_sub();
    }
    // Now that we've normalized on 0 it should be safe to switch to i32.
    b.i32_wrap_i64();
  }
}

class SwitchInfo {
  /// Non-nullable Wasm type of the `switch` expression. Used when the
  /// expression is not nullable, and after the null check.
  late final w.ValueType nullableType;

  /// Nullable Wasm type of the `switch` expression. Only used when the
  /// expression is nullable.
  late final w.ValueType nonNullableType;

  /// Generates code that will br on [successLabel] if [switchExprLocal] has the
  /// correct type for the case checks on this switch. Only set for switches
  /// where the switch expression is dynamic.
  void Function(w.Local switchExprLocal, w.Label successLabel)?
      dynamicTypeGuard;

  /// Generates code that compares value of a `case` expression with the
  /// `switch` expression's value. Calls [pushCaseExpr] once.
  late final void Function(
      w.Local switchExprLocal, w.ValueType Function() pushCaseExpr) compare;

  /// The `default: ...` case, if exists.
  late final SwitchCase? defaultCase;

  /// The `null: ...` case, if exists.
  late final SwitchCase? nullCase;

  /// Info needed to compile this switch statement into a wasm br_table. If null
  /// this switch statement should not use a br_table and should use comparison
  /// based case matching instead.
  BrTableInfo? brTable;

  SwitchInfo(AstCodeGenerator codeGen, SwitchStatement node) {
    final translator = codeGen.translator;

    final switchExprType = codeGen.dartTypeOf(node.expression);

    final switchExprClass = translator.classForType(switchExprType);

    bool check<L extends Expression, C extends Constant>() =>
        node.cases.expand((c) => c.expressions).every((e) =>
            e is L ||
            e is NullLiteral ||
            (e is ConstantExpression &&
                ((e.constant is C &&
                        (translator.hierarchy.isSubInterfaceOf(
                            translator.classForType(codeGen.dartTypeOf(e)),
                            switchExprClass))) ||
                    e.constant is NullConstant)));

    // Type objects should be compared using `==` rather than identity even
    // though the specification is not very clear about it. In language versions
    // >=3.0 CFE would desugar such switches to a sequence of `if` statements
    // using `==`, but for language versions <3.0 it would simply emit
    // `SwitchStatement` and expect back-end to handle types specially if
    // required. See #60375 for more details.
    bool canInvokeTypeEquality() =>
        translator.typeEnvironment.isSubtypeOf(
            switchExprType, translator.coreTypes.typeNullableRawType) ||
        node.cases.expand((c) => c.expressions).any((e) =>
            translator.typeEnvironment.isSubtypeOf(codeGen.dartTypeOf(e),
                translator.coreTypes.typeNonNullableRawType));

    if (node.cases.every((c) =>
        c.expressions.isEmpty && c.isDefault ||
        c.expressions.every((e) =>
            e is NullLiteral ||
            e is ConstantExpression && e.constant is NullConstant))) {
      // default-only switch
      nonNullableType = w.RefType.eq(nullable: false);
      nullableType = w.RefType.eq(nullable: true);
      compare = (switchExprLocal, pushCaseExpr) =>
          throw "Comparison in default-only switch";
    } else if (canInvokeTypeEquality()) {
      nonNullableType = translator.runtimeTypeType;
      nullableType = translator.runtimeTypeTypeNullable;
      compare = (switchExprLocal, pushCaseExpr) {
        // Virtual call to `Type.==`.
        codeGen._virtualCall(
            node, translator.coreTypes.objectEquals, _VirtualCallKind.Call,
            (functionType) {
          codeGen.b.local_get(switchExprLocal);
        }, (functionType, paramInfo) {
          pushCaseExpr();
        }, useUncheckedEntry: false);
      };
    } else if (switchExprType is DynamicType) {
      // Per spec, compare with `<case expr> == <switch expr>`. For performance,
      // if we know that the cases all have the same type, we call the case
      // expression's `==` implementation directly (instead of virtually calling
      // `Object.==`).
      //
      // Note: this could be improved by directly calling a different `==` in
      // each of the cases based on the case value. For now we only directly
      // call a `==` if all of the cases have a compatible type.
      nonNullableType = translator.topTypeNonNullable;
      nullableType = translator.topType;
      final Member equalsMember;
      if (check<BoolLiteral, BoolConstant>()) {
        equalsMember = translator.boxedBoolEquals;
      } else if (check<IntLiteral, IntConstant>()) {
        equalsMember = translator.boxedIntEquals;
      } else if (check<StringLiteral, StringConstant>()) {
        equalsMember = translator.jsStringEquals;
      } else {
        compare = (switchExprLocal, pushCaseExpr) {
          // Virtual call to `Object.==`.
          codeGen._virtualCall(node, codeGen.translator.coreTypes.objectEquals,
              _VirtualCallKind.Call, (functionType) {
            codeGen.b.local_get(switchExprLocal);
          }, (functionType, paramInfo) {
            pushCaseExpr();
          }, useUncheckedEntry: false);
        };
        _initializeSpecialCases(node);
        return;
      }

      final equalsMemberSignature =
          translator.signatureForDirectCall(equalsMember.reference);

      // Per spec, `==` can't have type, or extra (optional) positional and
      // named arguments. So we don't have to check `ParamInfo` for it and
      // add missing optional parameters.
      assert(equalsMemberSignature.inputs.length == 2);

      dynamicTypeGuard = (switchExprLocal, successLabel) {
        codeGen.b.local_get(switchExprLocal);
        codeGen.b.br_on_cast(
            successLabel,
            switchExprLocal.type as w.RefType,
            equalsMemberSignature.inputs[0]
                .withNullability(switchExprLocal.type.nullable) as w.RefType);
        codeGen.b.drop();
      };

      compare = (switchExprLocal, pushCaseExpr) {
        final caseExprType = pushCaseExpr();
        translator.convertType(
            codeGen.b, caseExprType, equalsMemberSignature.inputs[0]);

        codeGen.b.local_get(switchExprLocal);
        translator.convertType(
            codeGen.b, switchExprLocal.type, equalsMemberSignature.inputs[1]);

        codeGen.call(equalsMember.reference);
      };
    } else if (check<BoolLiteral, BoolConstant>()) {
      // bool switch
      nonNullableType = w.NumType.i32;
      nullableType =
          translator.classInfo[translator.boxedBoolClass]!.nullableType;
      compare = (switchExprLocal, pushCaseExpr) {
        codeGen.b.local_get(switchExprLocal);
        pushCaseExpr();
        codeGen.b.i32_eq();
      };
    } else if (check<IntLiteral, IntConstant>()) {
      // int switch
      nonNullableType = w.NumType.i64;
      nullableType =
          translator.classInfo[translator.boxedIntClass]!.nullableType;

      // Calculate the range covered by the cases and create the jump table.
      int? minValue;
      int? maxValue;
      Map<int, SwitchCase> caseMap = {};
      for (final c in node.cases) {
        for (final e in c.expressions) {
          if (e is NullLiteral ||
              (e is ConstantExpression && e.constant is NullConstant)) {
            // Null already handled above.
            continue;
          }

          final value = e is IntLiteral
              ? e.value
              : ((e as ConstantExpression).constant as IntConstant).value;

          caseMap[value] = c;
          if (minValue == null || value < minValue) minValue = value;
          if (maxValue == null || value > maxValue) maxValue = value;
        }
      }
      if (maxValue != null) {
        brTable = BrTableInfo.build(
            minValue: minValue!,
            maxValue: maxValue,
            caseMap, (switchExprLocal) {
          codeGen.b.local_get(switchExprLocal);
        });
      }

      // Provide a compare as a fallback in case the range is too sparse.
      compare = (switchExprLocal, pushCaseExpr) {
        codeGen.b.local_get(switchExprLocal);
        pushCaseExpr();
        codeGen.b.i64_eq();
      };
    } else if (check<StringLiteral, StringConstant>()) {
      // String switch
      nonNullableType = translator.stringType;
      nullableType = translator.stringTypeNullable;
      compare = (switchExprLocal, pushCaseExpr) {
        codeGen.b.local_get(switchExprLocal);
        pushCaseExpr();
        codeGen.call(translator.jsStringEquals.reference);
      };
    } else if (switchExprClass.isEnum) {
      // If this is an applicable switch over enums, create a jump table.
      bool isValid = true;
      var caseMap = <int, SwitchCase>{};
      int? minIndex;
      int? maxIndex;
      outer:
      for (final c in node.cases) {
        for (final e in c.expressions) {
          if (e is NullLiteral ||
              (e is ConstantExpression && e.constant is NullConstant)) {
            // Null already handled above.
            continue;
          }
          if (e is! ConstantExpression) {
            isValid = false;
            break outer;
          }
          final constant = e.constant;
          if (constant is! InstanceConstant) {
            isValid = false;
            break outer;
          }
          if (constant.classNode != switchExprClass) {
            isValid = false;
            break outer;
          }
          final enumIndex =
              (constant.fieldValues[translator.enumIndexField.fieldReference]
                      as IntConstant)
                  .value;
          caseMap[enumIndex] = c;
          if (maxIndex == null || enumIndex > maxIndex) maxIndex = enumIndex;
          if (minIndex == null || enumIndex < minIndex) minIndex = enumIndex;
        }
      }

      if (isValid && maxIndex != null) {
        brTable = BrTableInfo.build(
            minValue: minIndex!,
            maxValue: maxIndex,
            caseMap, (switchExprLocal) {
          codeGen.b.local_get(switchExprLocal);
          codeGen.call(translator.enumIndexField.getterReference);
        });
      }

      if (brTable == null) {
        // Object identity switch
        nonNullableType = translator.topTypeNonNullable;
        nullableType = translator.topType;
      } else {
        nonNullableType =
            translator.classInfo[switchExprClass]!.nonNullableType;
        nullableType = translator.classInfo[switchExprClass]!.nullableType;
      }

      // Set compare anyway for state machine handling
      compare = (switchExprLocal, pushCaseExpr) {
        codeGen.b.local_get(switchExprLocal);
        pushCaseExpr();
        codeGen.call(translator.coreTypes.identicalProcedure.reference);
      };
    } else {
      // Object identity switch
      nonNullableType = translator.topTypeNonNullable;
      nullableType = translator.topType;
      compare = (switchExprLocal, pushCaseExpr) {
        codeGen.b.local_get(switchExprLocal);
        pushCaseExpr();
        codeGen.call(translator.coreTypes.identicalProcedure.reference);
      };
    }

    _initializeSpecialCases(node);
  }

  void _initializeSpecialCases(SwitchStatement node) {
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

  @override
  String toString() {
    return switch (this) {
      _VirtualCallKind.Get => "get",
      _VirtualCallKind.Set => "set",
      _VirtualCallKind.Call => "call"
    };
  }

  bool get isGetter => this == _VirtualCallKind.Get;

  bool get isSetter => this == _VirtualCallKind.Set;
}

extension MacroAssembler on w.InstructionsBuilder {
  /// If the given [outputs] of a call contain bottom types then we will emit an
  /// `unreachable` instruction.
  ///
  /// This can help wasm compilers / wasm runtimes to optimize things more as
  /// they know control flow has ended here.
  List<w.ValueType> emitUnreachableIfNoResult(List<w.ValueType> outputs) {
    for (int i = 0; i < outputs.length; ++i) {
      final output = outputs[i];
      if (output is w.RefType &&
          output.heapType == w.HeapType.none &&
          !output.nullable) {
        unreachable();
        break;
      }
    }
    return outputs;
  }

  void incrementingLoop(
      {required void Function() pushStart,
      required void Function() pushLimit,
      required void Function(w.Local) genBody,
      int step = 1}) {
    final endLoop = block();
    final limitVar = addLocal(w.NumType.i32);
    final loopVar = addLocal(w.NumType.i32);
    pushLimit();
    local_set(limitVar);
    pushStart();
    local_set(loopVar);

    final loopLabel = loop();
    local_get(loopVar);
    local_get(limitVar);
    i32_ge_u();
    br_if(endLoop);

    genBody(loopVar);
    local_get(loopVar);
    i32_const(step);
    i32_add();
    local_set(loopVar);
    br(loopLabel);
    end();
    end();
  }

  /// [ref Array] [ref Array] -> [ref Array]
  ///
  /// Takes the two arrays on the stack and concatenates them into a single
  /// array. They both must have the same type provided as [arrayRefType].
  /// Uses [pushDefaultElement] as the filler element that holds space in the
  /// array until values are copied over.
  void concatenateWasmArrays(w.ArrayType arrayType,
      {required void Function(
              w.InstructionsBuilder b, w.Local oldArray, w.Local newArray)
          pushDefaultElement}) {
    final arrayRefType = w.RefType(arrayType, nullable: false);
    final newArray = addLocal(arrayRefType);
    final oldArray = addLocal(arrayRefType);
    final newArrayLen = addLocal(w.NumType.i32);
    final oldArrayLen = addLocal(w.NumType.i32);
    final joinedArray = addLocal(arrayRefType);

    local_set(newArray);
    local_set(oldArray);
    pushDefaultElement(this, oldArray, newArray);
    local_get(newArray);
    array_len();
    local_set(newArrayLen);
    local_get(oldArray);
    array_len();
    local_tee(oldArrayLen);
    local_get(newArrayLen);
    i32_add();
    array_new(arrayType);
    local_tee(joinedArray);
    i32_const(0);
    local_get(oldArray);
    i32_const(0);
    local_get(oldArrayLen);
    array_copy(arrayType, arrayType);
    local_get(joinedArray);
    local_get(oldArrayLen);
    local_get(newArray);
    i32_const(0);
    local_get(newArrayLen);
    array_copy(arrayType, arrayType);
    local_get(joinedArray);
    end();
  }

  /// `[i32] -> [i32]`
  ///
  /// Consumes a `i32` class ID, leaves an `i32` as `bool` for whether
  /// the class ID is in the given list of ranges.
  void emitClassIdRangeCheck(List<Range> ranges) {
    final rangeValues = ranges.map((r) => (range: r, value: null)).toList();
    classIdSearch<Null>(rangeValues, [w.NumType.i32], (_) {
      i32_const(1);
    }, () {
      i32_const(0);
    });
  }

  /// `[i32] -> [outputs]`
  ///
  /// Consumes a `i32` class ID and checks whether it lies within one of the
  /// given [ranges] using a linear or binary search.
  ///
  /// The [ranges] have to be non-empty, non-overlapping and sorted.
  ///
  /// Calls [match] on a matching value and [miss] if provided and no match was
  /// found.
  ///
  /// Assumes [match] and [miss] leave [outputs] on the stack.
  void classIdSearch<T>(
      List<({Range range, T value})> ranges,
      List<w.ValueType> outputs,
      void Function(T) match,
      void Function()? miss) {
    final bool linearSearch = ranges.length <= 3;
    if (traceEnabled) {
      comment('Class id ${linearSearch ? 'linear' : 'binary'} search:');
      for (final (:range, :value) in ranges) {
        comment('  - $range -> $value');
      }
    }
    if (linearSearch) {
      _linearClassIdSearch<T>(ranges, outputs, match, miss);
    } else {
      _binaryClassIdSearch<T>(ranges, outputs, match, miss);
    }
  }

  void _binaryClassIdSearch<T>(
      List<({Range range, T value})> ranges,
      List<w.ValueType> outputs,
      void Function(T) match,
      void Function()? miss) {
    assert(ranges.isNotEmpty || miss != null);
    if (miss != null && ranges.isEmpty) {
      drop();
      miss();
      return;
    }

    w.Local classId = addLocal(w.NumType.i32);
    local_set(classId);

    final done = block([], outputs);
    final fail = block();
    void search(int left, int right, Range searchArea) {
      if (left == right) {
        final entry = ranges[left];
        final range = entry.range;
        assert(searchArea.containsRange(range));
        if (miss == null || range.containsRange(searchArea)) {
          match(entry.value);
          br(done);
          return;
        }
        local_get(classId);
        if (range.length == 1) {
          i32_const(range.start);
          i32_eq();
        } else {
          if (searchArea.end <= range.end) {
            i32_const(range.start);
            i32_ge_u();
          } else if (range.start <= searchArea.start) {
            i32_const(range.end);
            i32_le_u();
          } else {
            i32_const(range.start);
            i32_sub();
            i32_const(range.length);
            i32_lt_u();
          }
        }
        if_();
        match(entry.value);
        br(done);
        end();
        br(fail);
        return;
      }
      final mid = (left + right) ~/ 2;
      final midRange = ranges[mid].range;

      local_get(classId);
      i32_const(midRange.end);
      i32_le_u();
      if_();
      search(left, mid, Range(searchArea.start, midRange.end));
      end();
      search(mid + 1, right, Range(midRange.end + 1, searchArea.end));
    }

    search(0, ranges.length - 1, Range(0, 0xffffffff));
    end(); // fail
    if (miss != null) {
      miss();
      br(done);
    } else {
      unreachable();
    }
    end(); // done
  }

  void _linearClassIdSearch<T>(
      List<({Range range, T value})> ranges,
      List<w.ValueType> outputs,
      void Function(T) match,
      void Function()? miss) {
    assert(ranges.isNotEmpty || miss != null);
    if (miss != null && ranges.isEmpty) {
      drop();
      miss();
      return;
    }

    w.Local classId = addLocal(w.NumType.i32);
    local_set(classId);
    final done = block([], outputs);
    for (final (:range, :value) in ranges) {
      local_get(classId);
      i32_const(range.start);
      if (range.length == 1) {
        i32_eq();
      } else {
        i32_sub();
        i32_const(range.length);
        i32_lt_u();
      }
      if_();
      match(value);
      br(done);
      end();
    }
    if (miss != null) {
      miss();
      br(done);
    } else {
      unreachable();
    }
    end(); // done
  }

  /// `[ref _Closure] -> [i32]`
  ///
  /// Given a closure reference returns whether the closure is an
  /// instantiation.
  void emitInstantiationClosureCheck(Translator translator) {
    ref_cast(w.RefType(translator.closureLayouter.closureBaseStruct,
        nullable: false));
    struct_get(translator.closureLayouter.closureBaseStruct,
        FieldIndex.closureContext);
    ref_test(w.RefType(
        translator.closureLayouter.instantiationContextBaseStruct,
        nullable: false));
  }

  /// `[ref _Closure] -> [ref #ClosureBase]`
  ///
  /// Given an instantiation closure returns the instantiated closure.
  void emitGetInstantiatedClosure(Translator translator) {
    // instantiation.context
    ref_cast(w.RefType(translator.closureLayouter.closureBaseStruct,
        nullable: false));
    struct_get(translator.closureLayouter.closureBaseStruct,
        FieldIndex.closureContext);

    // instantiation.context.inner
    ref_cast(w.RefType(
        translator.closureLayouter.instantiationContextBaseStruct,
        nullable: false));
    struct_get(translator.closureLayouter.instantiationContextBaseStruct,
        FieldIndex.instantiationContextInner);
  }

  /// `[ref _Closure] -> [i32]`
  ///
  /// Given a closure returns whether the closure is a tear-off.
  void emitTearOffCheck(Translator translator) {
    ref_cast(w.RefType(translator.closureLayouter.closureBaseStruct,
        nullable: false));
    struct_get(translator.closureLayouter.closureBaseStruct,
        FieldIndex.closureContext);
    ref_test(translator.topTypeNonNullable);
  }

  /// `[ref _Closure] -> [ref #Top]`
  ///
  /// Given a closure returns the receiver of the closure.
  void emitGetTearOffReceiver(Translator translator) {
    ref_cast(w.RefType(translator.closureLayouter.closureBaseStruct,
        nullable: false));
    struct_get(translator.closureLayouter.closureBaseStruct,
        FieldIndex.closureContext);
    ref_cast(translator.topTypeNonNullable);
  }

  /// `[ref _Closure] -> [ref Any]
  ///
  /// Given a closure returns the vtable of the closure.
  void emitGetClosureVtable(Translator translator) {
    ref_cast(w.RefType(translator.closureLayouter.closureBaseStruct,
        nullable: false));
    struct_get(
        translator.closureLayouter.closureBaseStruct, FieldIndex.closureVtable);
  }

  /// Will restore all context locals and `this` from a suspend state.
  void restoreSuspendStateContext(
      w.Local suspendStateLocal,
      w.StructType suspendStateStruct,
      int suspendStateContextField,
      Closures closures,
      Context? context,
      w.Local? thisLocal,
      {FunctionNode? cloneContextFor}) {
    if (context != null) {
      assert(!context.isEmpty);
      local_get(suspendStateLocal);
      struct_get(suspendStateStruct, suspendStateContextField);
      ref_cast(context.currentLocal.type as w.RefType);
      local_set(context.currentLocal);
      if (context.owner == cloneContextFor) {
        context.currentLocal =
            cloneFunctionLevelContext(closures, context, cloneContextFor!);
      }
      restoreThisAndContextChain(context, thisLocal);
    }
  }

  /// Will restore the parent context chain and `this` (if captured)
  ///
  /// Assumes the innermost context is already loaded.
  void restoreThisAndContextChain(
      Context innermostContext, w.Local? thisLocal) {
    bool restoredThis = false;

    Context? context = innermostContext;
    while (context != null) {
      if (context.containsThis) {
        assert(!restoredThis);
        local_get(context.currentLocal);
        struct_get(context.struct, context.thisFieldIndex);
        ref_as_non_null();
        local_set(thisLocal!);
        restoredThis = true;
      }

      final parent = context.parent;
      if (parent != null) {
        assert(!parent.isEmpty);
        local_get(context.currentLocal);
        struct_get(context.struct, context.parentFieldIndex);
        ref_as_non_null();
        local_set(parent.currentLocal);
      }
      context = parent;
    }
  }

  /// Clones the [context] and returns a local to the clone it.
  ///
  /// It is assumed that the context is a function-level context.
  w.Local cloneFunctionLevelContext(
      Closures closures, Context context, FunctionNode functionNode) {
    final w.Local srcContext = context.currentLocal;
    final w.Local destContext = addLocal(context.currentLocal.type);

    struct_new_default(context.struct);
    local_set(destContext);

    void copyCapture(TreeNode node) {
      Capture? capture = closures.captures[node];
      if (capture != null) {
        assert(capture.context == context);
        local_get(destContext);
        local_get(srcContext);
        struct_get(context.struct, capture.fieldIndex);
        struct_set(context.struct, capture.fieldIndex);
      }
    }

    if (context.containsThis) {
      local_get(destContext);
      local_get(srcContext);
      struct_get(context.struct, context.thisFieldIndex);
      struct_set(context.struct, context.thisFieldIndex);
    }
    if (context.parent != null) {
      local_get(destContext);
      local_get(srcContext);
      struct_get(context.struct, context.parentFieldIndex);
      struct_set(context.struct, context.parentFieldIndex);
    }
    functionNode.positionalParameters.forEach(copyCapture);
    functionNode.namedParameters.forEach(copyCapture);
    functionNode.typeParameters.forEach(copyCapture);

    return destContext;
  }

  List<w.ValueType> invoke(CallTarget target, {bool forceInline = false}) {
    if (target.supportsInlining && (target.shouldInline || forceInline)) {
      final List<w.Local> inlinedLocals =
          target.signature.inputs.map((t) => addLocal(t)).toList();
      for (w.Local local in inlinedLocals.reversed) {
        local_set(local);
      }
      final w.Label callBlock = block(const [], target.signature.outputs);
      comment('Inlined ${target.name}');
      target.inliningCodeGen.generate(this, inlinedLocals, callBlock);
    } else {
      comment('Direct call to ${target.name}');
      call(target.function);
    }
    return emitUnreachableIfNoResult(target.signature.outputs);
  }

  /// Pushes fields common to all Dart objects (class id, id hash).
  void pushObjectHeaderFields(Translator translator, ClassInfo classInfo) {
    pushClassIdToStack(translator, classInfo.classId);
    i32_const(initialIdentityHash);
  }

  void pushClassIdToStack(Translator translator, ClassId classId) {
    switch (classId) {
      case AbsoluteClassId():
        i32_const(classId.value);
      case RelativeClassId():
        i32_const(classId.relativeValue);
        translator.pushModuleId(this);
        translator.callReference(translator.globalizeClassId.reference, this);
    }
  }

  void loadClassId(Translator translator, w.ValueType receiverType) {
    assert(!receiverType.nullable);
    assert(receiverType.isSubtypeOf(translator.topTypeNonNullable));
    struct_get(
        translator.classInfoCollector.topInfo.struct, FieldIndex.classId);
  }
}

/// A call target that may be called with a direct call or may be inlined.
abstract class CallTarget {
  /// The wasm signature of the call target (that may be called or inlined).
  final w.FunctionType signature;

  CallTarget(this.signature);

  /// Whether this call target supports inlining.
  bool get supportsInlining => false;

  /// Whether we should inline (different call targets may have semantic
  /// knowledge about how big the body would be and whether we should inline or
  /// not).
  bool get shouldInline => false;

  /// The code generator to use for inlining the body.
  CodeGenerator get inliningCodeGen => throw 'No inlining support (yet).';

  /// The name of this target
  ///
  /// The inliner can use this to emit comments for the inlined target.
  String get name;

  /// The wasm target function to call.
  ///
  /// This should only be accessed if caller intents to call it, as it will
  /// enqueue the function in the compilation queue.
  w.BaseFunction get function;
}

class AstCallTarget extends CallTarget {
  final Translator _translator;
  final Reference _reference;

  AstCallTarget(super.signature, this._translator, this._reference);

  @override
  String get name => _translator.functions.getFunctionName(_reference);

  @override
  bool get supportsInlining => _translator.supportsInlining(_reference);

  @override
  bool get shouldInline => _translator.shouldInline(_reference, signature);

  @override
  CodeGenerator get inliningCodeGen => getInlinableMemberCodeGenerator(
      _translator, AsyncMarker.Sync, signature, _reference)!;

  @override
  w.BaseFunction get function => _translator.functions.getFunction(_reference);
}

bool guardCanMatchJSException(Translator translator, DartType guard) {
  if (guard is DynamicType) {
    return true;
  }
  if (guard is InterfaceType) {
    return translator.hierarchy
        .isSubInterfaceOf(translator.javaScriptErrorClass, guard.classNode);
  }
  if (guard is TypeParameterType) {
    return guardCanMatchJSException(translator, guard.bound);
  }
  return false;
}
