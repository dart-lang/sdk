// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
library kernel.target.vm;

import 'targets.dart';
import '../ast.dart';
import '../transformations/mixin_full_resolution.dart' as mix;

/// Specializes the kernel IR to the Dart VM.
class VmTarget extends Target {
  String get name => 'vm';

  void transformProgram(Program program) {
    new mix.MixinFullResolution().transform(program);
  }
}
