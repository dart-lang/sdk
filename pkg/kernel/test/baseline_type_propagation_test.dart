// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/transformations/mixin_full_resolution.dart';
import 'package:kernel/type_propagation/builder.dart';
import 'package:kernel/type_propagation/solver.dart';
import 'package:kernel/type_propagation/visualizer.dart';

import 'baseline_tester.dart';

class TypePropagationTest extends TestTarget {
  @override
  Annotator annotator;

  @override
  List<String> get extraRequiredLibraries => [];

  @override
  String get name => 'type-propagation-test';

  @override
  bool get strongMode => false;

  @override
  List<String> transformProgram(Program program) {
    new MixinFullResolution().transform(program);
    var visualizer = new Visualizer(program);
    var builder = new Builder(program, visualizer: visualizer);
    var solver = new Solver(builder);
    solver.solve();
    visualizer.solver = solver;
    annotator = new TextAnnotator(visualizer);
    return const <String>[];
  }
}

void main() {
  runBaselineTests('type-propagation', new TypePropagationTest());
}
