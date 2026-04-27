// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@Tags(['daily'])
@TestOn('vm')
@Timeout(Duration(minutes: 2))
library;

import 'package:dwds/expression_compiler.dart';
import 'package:test/test.dart';

import 'expression_compiler_service_common.dart';

void main() async {
  testAll(
    compilerOptions: CompilerOptions(
      moduleFormat: ModuleFormat.ddc,
      canaryFeatures: true,
      experiments: const <String>[],
    ),
  );
}
