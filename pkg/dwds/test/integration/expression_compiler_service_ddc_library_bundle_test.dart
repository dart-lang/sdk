// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:dwds/expression_compiler.dart';
import 'package:dwds_test_common/integration/expression_compiler_service.dart';

void main() async {
  testAll(
    compilerOptions: CompilerOptions(
      moduleFormat: ModuleFormat.ddc,
      canaryFeatures: true,
      experiments: const <String>[],
    ),
  );
}
