// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:kernel/kernel.dart';
import 'package:kernel/transformations/mixin_full_resolution.dart';

import 'baseline_tester.dart';

class StrongModeTest extends TestTarget {
  @override
  List<String> get extraRequiredLibraries => [];

  @override
  String get name => 'strong-mode-test';

  @override
  bool get strongMode => true;

  @override
  void transformProgram(Program program) {
    new MixinFullResolution().transform(program);
  }
}

void main() {
  runBaselineTests('strong-mode', new StrongModeTest());
}
