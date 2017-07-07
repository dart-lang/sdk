// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vm;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../transformations/continuation.dart' as cont;
import '../transformations/erasure.dart';
import '../transformations/insert_covariance_checks.dart';
import '../transformations/insert_type_checks.dart';
import '../transformations/mixin_full_resolution.dart' as mix;
import '../transformations/sanitize_for_vm.dart';
import '../transformations/treeshaker.dart';
import 'targets.dart';

/// Specializes the kernel IR to the Dart VM.
class VmTarget extends Target {
  final TargetFlags flags;

  VmTarget(this.flags);

  bool get strongMode => flags.strongMode;

  /// The VM patch files are not strong mode clean, so we adopt a hybrid mode
  /// where the SDK is internally unchecked, but trusted to satisfy the types
  /// declared on its interface.
  bool get strongModeSdk => false;

  String get name => 'vm';

  // This is the order that bootstrap libraries are loaded according to
  // `runtime/vm/object_store.h`.
  List<String> get extraRequiredLibraries => const <String>[
        'dart:async',
        'dart:collection',
        'dart:convert',
        'dart:developer',
        'dart:_internal',
        'dart:isolate',
        'dart:math',

        // The library dart:mirrors may be ignored by the VM, e.g. when built in
        // PRODUCT mode.
        'dart:mirrors',

        'dart:profiler',
        'dart:typed_data',
        'dart:_builtin',
        'dart:nativewrappers',
        'dart:io',
      ];

  ClassHierarchy _hierarchy;

  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {
    var mixins = new mix.MixinFullResolution(this, coreTypes, hierarchy)
      ..transform(libraries);

    _hierarchy = mixins.hierarchy;
  }

  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {
    if (strongMode) {
      new InsertTypeChecks(coreTypes, _hierarchy).transformProgram(program);
      new InsertCovarianceChecks(coreTypes, _hierarchy)
          .transformProgram(program);
    }

    if (flags.treeShake) {
      performTreeShaking(coreTypes, program);
    }

    cont.transformProgram(coreTypes, program);

    if (strongMode) {
      performErasure(program);
    }

    new SanitizeForVM().transform(program);
  }

  void performTreeShaking(CoreTypes coreTypes, Program program) {
    new TreeShaker(coreTypes, _hierarchy, program,
            strongMode: strongMode, programRoots: flags.programRoots)
        .transform(program);
    _hierarchy = null; // Hierarchy must be recomputed.
  }

  void performErasure(Program program) {
    new Erasure().transform(program);
  }

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    // See [_InvocationMirror]
    // (../../../../runtime/lib/invocation_mirror_patch.dart).
    // The _InvocationMirror constructor takes the following arguments:
    // * Method name (a string).
    // * An arguments descriptor - a list consisting of:
    //   - length of passed type argument vector, 0 if none passed.
    //   - number of arguments (including receiver).
    //   - number of positional arguments (including receiver).
    //   - pairs (2 entries in the list) of
    //     * named arguments name.
    //     * index of named argument in arguments list.
    // * A list of arguments, where the first ones are the positional arguments.
    // * Whether it's a super invocation or not.

    int typeArgsLen = 0; // TODO(regis): Type arguments of generic function.
    int numPositionalArguments = arguments.positional.length;
    numPositionalArguments++; // Include the receiver.
    int numArguments = numPositionalArguments + arguments.named.length;
    List<Expression> argumentsDescriptor = [
      new IntLiteral(typeArgsLen)..fileOffset = offset,
      new IntLiteral(numArguments)..fileOffset = offset,
      new IntLiteral(numPositionalArguments)..fileOffset = offset,
    ];

    List<Expression> argumentsList = <Expression>[receiver];
    argumentsList.addAll(arguments.positional);

    for (NamedExpression argument in arguments.named) {
      argumentsDescriptor.add(
          new StringLiteral(argument.name)..fileOffset = argument.fileOffset);
      argumentsDescriptor.add(new IntLiteral(argumentsList.length)
        ..fileOffset = argument.fileOffset);
      argumentsList.add(argument.value);
    }

    Arguments constructorArguments = new Arguments([
      new StringLiteral(name)..fileOffset = offset,
      _fixedLengthList(argumentsDescriptor, arguments.fileOffset),
      _fixedLengthList(argumentsList, arguments.fileOffset),
      new BoolLiteral(isSuper)..fileOffset = arguments.fileOffset,
    ]);

    return new ConstructorInvocation(
        coreTypes.invocationMirrorDefaultConstructor, constructorArguments)
      ..fileOffset = offset;
  }

  @override
  Expression instantiateNoSuchMethodError(CoreTypes coreTypes,
      Expression receiver, String name, Arguments arguments, int offset,
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    int type = _invocationType(
        isMethod: isMethod,
        isGetter: isGetter,
        isSetter: isSetter,
        isField: isField,
        isLocalVariable: isLocalVariable,
        isDynamic: isDynamic,
        isSuper: isSuper,
        isStatic: isStatic,
        isConstructor: isConstructor,
        isTopLevel: isTopLevel);
    return new ConstructorInvocation(
        coreTypes.noSuchMethodErrorImplementationConstructor,
        new Arguments(<Expression>[
          receiver,
          new SymbolLiteral(name)..fileOffset = offset,
          new IntLiteral(type)..fileOffset = offset,
          _fixedLengthList(arguments.positional, arguments.fileOffset),
          new MapLiteral(new List<MapEntry>.from(
              arguments.named.map((NamedExpression arg) {
            return new MapEntry(
                new SymbolLiteral(arg.name)..fileOffset = arg.fileOffset,
                arg.value)
              ..fileOffset = arg.fileOffset;
          })))
            ..fileOffset = arguments.fileOffset,
          new NullLiteral()
        ]));
  }

  int _invocationType(
      {bool isMethod: false,
      bool isGetter: false,
      bool isSetter: false,
      bool isField: false,
      bool isLocalVariable: false,
      bool isDynamic: false,
      bool isSuper: false,
      bool isStatic: false,
      bool isConstructor: false,
      bool isTopLevel: false}) {
    // This is copied from [_InvocationMirror](
    // ../../../../../../runtime/lib/invocation_mirror_patch.dart).

    // Constants describing the invocation type.
    // _FIELD cannot be generated by regular invocation mirrors.
    const int _METHOD = 0;
    const int _GETTER = 1;
    const int _SETTER = 2;
    const int _FIELD = 3;
    const int _LOCAL_VAR = 4;
    // ignore: UNUSED_LOCAL_VARIABLE
    const int _TYPE_SHIFT = 0;
    const int _TYPE_BITS = 3;
    // ignore: UNUSED_LOCAL_VARIABLE
    const int _TYPE_MASK = (1 << _TYPE_BITS) - 1;

    // These values, except _DYNAMIC and _SUPER, are only used when throwing
    // NoSuchMethodError for compile-time resolution failures.
    const int _DYNAMIC = 0;
    const int _SUPER = 1;
    const int _STATIC = 2;
    const int _CONSTRUCTOR = 3;
    const int _TOP_LEVEL = 4;
    const int _CALL_SHIFT = _TYPE_BITS;
    const int _CALL_BITS = 3;
    // ignore: UNUSED_LOCAL_VARIABLE
    const int _CALL_MASK = (1 << _CALL_BITS) - 1;

    int type = -1;
    // For convenience, [isGetter] and [isSetter] takes precedence over
    // [isMethod].
    if (isGetter) {
      type = _GETTER;
    } else if (isSetter) {
      type = _SETTER;
    } else if (isMethod) {
      type = _METHOD;
    } else if (isField) {
      type = _FIELD;
    } else if (isLocalVariable) {
      type = _LOCAL_VAR;
    }

    if (isDynamic) {
      type |= (_DYNAMIC << _CALL_SHIFT);
    } else if (isSuper) {
      type |= (_SUPER << _CALL_SHIFT);
    } else if (isStatic) {
      type |= (_STATIC << _CALL_SHIFT);
    } else if (isConstructor) {
      type |= (_CONSTRUCTOR << _CALL_SHIFT);
    } else if (isTopLevel) {
      type |= (_TOP_LEVEL << _CALL_SHIFT);
    }

    return type;
  }

  Expression _fixedLengthList(List<Expression> elements, int offset) {
    // TODO(ahe): It's possible that it would be better to create a fixed-length
    // list first, and then populate it. That would create fewer objects. But as
    // this is currently only used in (statically resolved) no-such-method
    // handling, the current approach seems sufficient.
    return new MethodInvocation(
        new ListLiteral(elements)..fileOffset = offset,
        new Name("toList"),
        new Arguments(<Expression>[], named: <NamedExpression>[
          new NamedExpression("growable", new BoolLiteral(false))
        ]));
  }
}
