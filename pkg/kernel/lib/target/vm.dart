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
        'dart:vmservice_io',
        'dart:_vmservice',
        'dart:_builtin',
        'dart:nativewrappers',
        'dart:io',
      ];

  ClassHierarchy _hierarchy;

  void performModularTransformations(Program program) {
    var mixins = new mix.MixinFullResolution(this)..transform(program);

    _hierarchy = mixins.hierarchy;
  }

  void performGlobalTransformations(Program program) {
    var coreTypes = new CoreTypes(program);

    if (strongMode) {
      new InsertTypeChecks(hierarchy: _hierarchy, coreTypes: coreTypes)
          .transformProgram(program);
      new InsertCovarianceChecks(hierarchy: _hierarchy, coreTypes: coreTypes)
          .transformProgram(program);
    }

    if (flags.treeShake) {
      performTreeShaking(program);
    }

    cont.transformProgram(program);

    if (strongMode) {
      performErasure(program);
    }

    new SanitizeForVM().transform(program);
  }

  void performTreeShaking(Program program) {
    var coreTypes = new CoreTypes(program);
    new TreeShaker(program,
            hierarchy: _hierarchy,
            coreTypes: coreTypes,
            strongMode: strongMode,
            programRoots: flags.programRoots)
        .transform(program);
    _hierarchy = null; // Hierarchy must be recomputed.
  }

  void performErasure(Program program) {
    new Erasure().transform(program);
  }

  @override
  Expression instantiateInvocation(Member target, Expression receiver,
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

    return (target is Constructor
        ? new ConstructorInvocation(target, constructorArguments)
        : new StaticInvocation(target, constructorArguments))
      ..fileOffset = offset;
  }

  Expression _fixedLengthList(List<Expression> elements, int charOffset) {
    // TODO(ahe): It's possible that it would be better to create a fixed-length
    // list first, and then populate it. That would create fewer objects. But as
    // this is currently only used in (statically resolved) no-such-method
    // handling, the current approach seems sufficient.
    return new MethodInvocation(
        new ListLiteral(elements)..fileOffset = charOffset,
        new Name("toList"),
        new Arguments(<Expression>[], named: <NamedExpression>[
          new NamedExpression("growable", new BoolLiteral(false))
        ]));
  }
}
