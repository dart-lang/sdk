// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.targets;

import '../ast.dart';
import '../class_hierarchy.dart';
import '../core_types.dart';
import '../transformations/treeshaker.dart' show ProgramRoot;
import 'flutter.dart' show FlutterTarget;
import 'vm.dart' show VmTarget;
import 'vm_fasta.dart' show VmFastaTarget;
import 'vmcc.dart' show VmClosureConvertedTarget;
import 'vmreify.dart' show VmGenericTypesReifiedTarget;

final List<String> targetNames = targets.keys.toList();

class TargetFlags {
  bool strongMode;
  bool treeShake;
  List<ProgramRoot> programRoots;
  Uri kernelRuntime;

  TargetFlags(
      {this.strongMode: false,
      this.treeShake: false,
      this.programRoots: const <ProgramRoot>[],
      this.kernelRuntime});
}

typedef Target _TargetBuilder(TargetFlags flags);

final Map<String, _TargetBuilder> targets = <String, _TargetBuilder>{
  'none': (TargetFlags flags) => new NoneTarget(flags),
  'vm': (TargetFlags flags) => new VmTarget(flags),
  'vm_fasta': (TargetFlags flags) => new VmFastaTarget(flags),
  'vmcc': (TargetFlags flags) => new VmClosureConvertedTarget(flags),
  'vmreify': (TargetFlags flags) => new VmGenericTypesReifiedTarget(flags),
  'flutter': (TargetFlags flags) => new FlutterTarget(flags),
};

Target getTarget(String name, TargetFlags flags) {
  var builder = targets[name];
  if (builder == null) return null;
  return builder(flags);
}

/// A target provides backend-specific options for generating kernel IR.
abstract class Target {
  String get name;

  /// A list of URIs of required libraries, not including dart:core.
  ///
  /// Libraries will be loaded in order.
  List<String> get extraRequiredLibraries => <String>[];

  /// Additional declared variables implied by this target.
  ///
  /// These can also be passed on the command-line of form `-D<name>=<value>`,
  /// and those provided on the command-line take precedence over those defined
  /// by the target.
  Map<String, String> get extraDeclaredVariables => const <String, String>{};

  /// Classes from the SDK whose interface is required for the modular
  /// transformations.
  Map<String, List<String>> get requiredSdkClasses => CoreTypes.requiredClasses;

  bool get strongMode;

  /// If true, the SDK should be loaded in strong mode.
  bool get strongModeSdk => strongMode;

  /// Perform target-specific modular transformations on the given program.
  ///
  /// These transformations should not be whole-program transformations.  They
  /// should expect that the program will contain external libraries.
  void performModularTransformationsOnProgram(
      CoreTypes coreTypes, ClassHierarchy hierarchy, Program program,
      {void logger(String msg)}) {
    performModularTransformationsOnLibraries(
        coreTypes, hierarchy, program.libraries,
        logger: logger);
  }

  /// Perform target-specific modular transformations on the given libraries.
  ///
  /// The intent of this method is to perform the transformations only on some
  /// subset of the program libraries and avoid packing them into a temporary
  /// [Program] instance to pass into [performModularTransformationsOnProgram].
  ///
  /// Note that the following should be equivalent:
  ///
  ///     target.performModularTransformationsOnProgram(coreTypes, program);
  ///
  /// and
  ///
  ///     target.performModularTransformationsOnLibraries(
  ///         coreTypes, program.libraries);
  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)});

  /// Perform target-specific whole-program transformations.
  ///
  /// These transformations should be optimizations and not required for
  /// correctness.  Everything should work if a simple and fast linker chooses
  /// not to apply these transformations.
  ///
  /// Note that [performGlobalTransformations] doesn't have -OnProgram and
  /// -OnLibraries alternatives, because the global knowledge required by the
  /// transformations is assumed to be retrieved from a [Program] instance.
  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)});

  /// Builds an expression that instantiates an [Invocation] that can be passed
  /// to [noSuchMethod].
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper);

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
      bool isTopLevel: false});

  /// Builds an expression that throws [error] as compile-time error. The
  /// target must be able to handle this expression in a constant expression.
  Expression throwCompileConstantError(CoreTypes coreTypes, Expression error) {
    // This method returns `const _ConstantExpressionError()._throw(error)`.
    int offset = error.fileOffset;
    var receiver = new ConstructorInvocation(
        coreTypes.constantExpressionErrorDefaultConstructor,
        new Arguments.empty()..fileOffset = offset,
        isConst: true)
      ..fileOffset = offset;
    return new MethodInvocation(
        receiver,
        new Name("_throw", coreTypes.coreLibrary),
        new Arguments(<Expression>[error])..fileOffset = error.fileOffset)
      ..fileOffset = offset;
  }

  /// Builds an expression that represents a compile-time error which is
  /// suitable for being passed to [throwCompileConstantError].
  Expression buildCompileTimeError(
      CoreTypes coreTypes, String message, int offset) {
    return new ConstructorInvocation(
        coreTypes.compileTimeErrorDefaultConstructor,
        new Arguments(<Expression>[new StringLiteral(message)])
          ..fileOffset = offset)
      ..fileOffset = offset;
  }

  String toString() => 'Target($name)';
}

class NoneTarget extends Target {
  final TargetFlags flags;

  NoneTarget(this.flags);

  bool get strongMode => flags.strongMode;
  String get name => 'none';
  List<String> get extraRequiredLibraries => <String>[];
  void performModularTransformationsOnLibraries(
      CoreTypes coreTypes, ClassHierarchy hierarchy, List<Library> libraries,
      {void logger(String msg)}) {}
  void performGlobalTransformations(CoreTypes coreTypes, Program program,
      {void logger(String msg)}) {}

  @override
  Expression instantiateInvocation(CoreTypes coreTypes, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    return new InvalidExpression();
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
    return new InvalidExpression();
  }
}
