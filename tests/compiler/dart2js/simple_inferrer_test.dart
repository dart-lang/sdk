// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';

const String TEST = """
returnNum1(a) {
  if (a) return 1;
  else return 2.0;
}

returnNum2(a) {
  if (a) return 1.0;
  else return 2;
}

returnInt(a) {
  if (a) return 1;
  else return 2;
}

returnDouble(a) {
  if (a) return 1.0;
  else return 2.0;
}

returnGiveUp(a) {
  if (a) return 1;
  else return 'foo';
}

main() {
  returnNum1(true);
  returnNum2(true);
  returnInt(true);
  returnDouble(true);
  returnGiveUp(true);
}
""";

void main() {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  var element = findElement(compiler, 'returnNum1');
  Expect.equals(compiler.numClass, typesInferrer.returnTypeOf[element]);

  element = findElement(compiler, 'returnNum2');
  Expect.equals(compiler.numClass, typesInferrer.returnTypeOf[element]);

  element = findElement(compiler, 'returnInt');
  Expect.equals(compiler.intClass, typesInferrer.returnTypeOf[element]);

  element = findElement(compiler, 'returnDouble');
  Expect.equals(compiler.doubleClass, typesInferrer.returnTypeOf[element]);

  element = findElement(compiler, 'returnGiveUp');
  Expect.equals(typesInferrer.giveUpType, typesInferrer.returnTypeOf[element]);
}
