// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/mixin_full_resolution.dart';

import 'baseline_tester.dart';

class SpecModeTest extends TestTarget {
  @override
  List<String> get extraRequiredLibraries => [];

  @override
  String get name => 'spec-mode-test';

  @override
  bool get strongMode => false;

  @override
  List<String> performModularTransformations(Program program) {
    new MixinFullResolution().transform(program);
    return const <String>[];
  }

  @override
  List<String> performGlobalTransformations(Program program) {
    return const <String>[];
  }
}

void main() {
  runBaselineTests('spec-mode', new SpecModeTest());
}
