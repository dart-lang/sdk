// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.targets;

import '../ast.dart';
import '../core_types.dart';
import '../transformations/treeshaker.dart' show ProgramRoot;
import 'flutter.dart';
import 'vm.dart';
import 'vmcc.dart';
import 'vmreify.dart';

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

  /// Perform target-specific modular transformations.
  ///
  /// These transformations should not be whole-program transformations.  They
  /// should expect that the program will contain external libraries.
  void performModularTransformations(Program program);

  /// Perform target-specific whole-program transformations.
  ///
  /// These transformations should be optimizations and not required for
  /// correctness.  Everything should work if a simple and fast linker chooses
  /// not to apply these transformations.
  void performGlobalTransformations(Program program);

  /// Builds an expression that instantiates an [Invocation] that can be passed
  /// to [noSuchMethod].
  Expression instantiateInvocation(Member target, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper);

  String toString() => 'Target($name)';
}

class NoneTarget extends Target {
  final TargetFlags flags;

  NoneTarget(this.flags);

  bool get strongMode => flags.strongMode;
  String get name => 'none';
  List<String> get extraRequiredLibraries => <String>[];
  void performModularTransformations(Program program) {}
  void performGlobalTransformations(Program program) {}

  @override
  Expression instantiateInvocation(Member target, Expression receiver,
      String name, Arguments arguments, int offset, bool isSuper) {
    return new InvalidExpression();
  }
}
