// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library smoke.test.codegen.common;

import 'package:smoke/codegen/generator.dart';
import 'package:unittest/unittest.dart';

checkResults(SmokeCodeGenerator generator, {List<String> imports: const [],
    String topLevel: '', String initCall}) {
  var allImports = []..addAll(DEFAULT_IMPORTS)..addAll(imports)..add('');
  var genImports = new StringBuffer();
  generator.writeImports(genImports);
  expect(genImports.toString(), allImports.join('\n'));

  var genTopLevel = new StringBuffer();
  generator.writeTopLevelDeclarations(genTopLevel);
  expect(genTopLevel.toString(), topLevel);

  var indentedCode = initCall.replaceAll("\n", "\n  ").trim();
  var genInitCall = new StringBuffer();
  generator.writeInitCall(genInitCall);
  expect(genInitCall.toString(), '  $indentedCode\n');
}
