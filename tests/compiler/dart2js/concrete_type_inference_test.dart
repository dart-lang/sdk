// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';
import 'parser_helper.dart';

void compileAndFind(String code, String name,
                    check(compiler, element)) {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(code, uri);
  compiler.runCompiler(uri);
  var element = findElement(compiler, name);
  return check(compiler, element);
}

void checkPrintType(String expression, checkType(compiler, type)) {
  compileAndFind(
      'main() { print($expression); }',
      'print',
      (compiler, printElement) {
        var parameter =
          printElement.computeSignature(compiler).requiredParameters.head;
        var type = compiler.typesTask.getGuaranteedTypeOfElement(parameter);
        checkType(compiler, type);
      });

  compileAndFind(
      'main() { var x = print; print($expression); }',
      'print',
      (compiler, printElement) {
        var parameter =
          printElement.computeSignature(compiler).requiredParameters.head;
        var type = compiler.typesTask.getGuaranteedTypeOfElement(parameter);
        Expect.isNull(type);
      });

  compileAndFind(
      'main() { print($expression); print($expression); }',
      'print',
      (compiler, printElement) {
        var parameter =
          printElement.computeSignature(compiler).requiredParameters.head;
        var type = compiler.typesTask.getGuaranteedTypeOfElement(parameter);
        checkType(compiler, type);
      });
}

void testBasicTypes() {
  checkPrintType('true', (compiler, type) {
    var backend = compiler.backend;
    Expect.identical(backend.boolImplementation, type.exactType.element);
  });
  checkPrintType('1.0', (compiler, type) {
    var backend = compiler.backend;
    Expect.identical(backend.doubleImplementation, type.exactType.element);
  });
  checkPrintType('1', (compiler, type) {
    var backend = compiler.backend;
    Expect.identical(backend.intImplementation, type.exactType.element);
  });
  checkPrintType('[]', (compiler, type) {
    var backend = compiler.backend;
    Expect.identical(backend.listImplementation, type.exactType.element);
  });
  checkPrintType('null', (compiler, type) {
    var backend = compiler.backend;
    Expect.identical(backend.nullImplementation, type.exactType.element);
  });
  checkPrintType('"foo"', (compiler, type) {
    var backend = compiler.backend;
    Expect.identical(backend.stringImplementation, type.exactType.element);
  });
}

void testOptionalParameters() {
  compileAndFind(
      'fisk(a, [b, c]) {} main() { fisk(1); }',
      'fisk',
      (compiler, fiskElement) {
        var firstParameter =
          fiskElement.computeSignature(compiler).requiredParameters.head;
        var secondParameter =
          fiskElement.computeSignature(compiler).optionalParameters.head;
        var thirdParameter =
          fiskElement.computeSignature(compiler).optionalParameters.tail.head;
        Expect.identical(
            compiler.backend.intImplementation,
            compiler.typesTask.getGuaranteedTypeOfElement(firstParameter)
                .exactType.element);
        Expect.isNull(
            compiler.typesTask.getGuaranteedTypeOfElement(secondParameter));
        Expect.isNull(
            compiler.typesTask.getGuaranteedTypeOfElement(thirdParameter));
      });
}

void main() {
  testBasicTypes();
  testOptionalParameters();
}
