// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.targets;

import '../ast.dart';

import 'vm.dart';
import 'flutter.dart';

final List<String> targetNames = targets.keys.toList();

class TargetFlags {
  bool strongMode;
  TargetFlags({this.strongMode: false});
}

typedef Target _TargetBuilder(TargetFlags flags);

final Map<String, _TargetBuilder> targets = <String, _TargetBuilder>{
  'none': (TargetFlags flags) => new NoneTarget(flags),
  'vm': (TargetFlags flags) => new VmTarget(flags),
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

  bool get strongMode;

  /// If true, the SDK should be loaded in strong mode.
  bool get strongModeSdk => strongMode;

  void transformProgram(Program program);

  String toString() => 'Target($name)';
}

class NoneTarget extends Target {
  final TargetFlags flags;

  NoneTarget(this.flags);

  bool get strongMode => flags.strongMode;
  String get name => 'none';
  List<String> get extraRequiredLibraries => <String>[];
  void transformProgram(Program program) {}
}
