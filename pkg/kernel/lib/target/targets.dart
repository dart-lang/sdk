// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.targets;

import '../ast.dart';
import 'vm.dart';

final List<Target> targets = [new NoneTarget(), new VmTarget()];
final List<String> targetNames = targets.map((t) => t.name).toList();

Target getTargetByName(String name) {
  return targets.firstWhere((t) => name == t.name, orElse: () => null);
}

/// A target provides backend-specific options for generating kernel IR.
abstract class Target {
  String get name;

  /// A list of URIs of required libraries, not including dart:core.
  ///
  /// Libraries will be loaded in order.
  List<String> get extraRequiredLibraries;

  void transformProgram(Program program);

  String toString() => 'Target($name)';
}

class NoneTarget extends Target {
  String get name => 'none';
  List<String> get extraRequiredLibraries => <String>[];
  void transformProgram(Program program) {}
}
