// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "package:expect/expect.dart";
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
    var inferrer = compiler.typesTask.typesInferrer;
    Expect.identical(inferrer.boolType, type);
  });
  checkPrintType('1.0', (compiler, type) {
    var inferrer = compiler.typesTask.typesInferrer;
    Expect.identical(inferrer.doubleType, type);
  });
  checkPrintType('1', (compiler, type) {
    var inferrer = compiler.typesTask.typesInferrer;
    Expect.identical(inferrer.intType, type);
  });
  checkPrintType('[]', (compiler, type) {
    var inferrer = compiler.typesTask.typesInferrer;
    Expect.identical(inferrer.growableListType, type);
  });
  checkPrintType('null', (compiler, type) {
    var inferrer = compiler.typesTask.typesInferrer;
    Expect.identical(inferrer.nullType, type);
  });
  checkPrintType('"foo"', (compiler, type) {
    var inferrer = compiler.typesTask.typesInferrer;
    Expect.identical(inferrer.stringType, type);
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
        var typesTask = compiler.typesTask;
        var inferrer = typesTask.typesInferrer;
        Expect.identical(
            inferrer.intType,
            typesTask.getGuaranteedTypeOfElement(firstParameter));
        Expect.identical(
            inferrer.nullType,
            typesTask.getGuaranteedTypeOfElement(secondParameter));
        Expect.identical(
            inferrer.nullType,
            typesTask.getGuaranteedTypeOfElement(thirdParameter));
      });
}

void main() {
  testBasicTypes();
  testOptionalParameters();
}
