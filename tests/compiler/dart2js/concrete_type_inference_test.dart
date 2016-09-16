// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'package:expect/expect.dart';
import 'package:async_helper/async_helper.dart';
import 'compiler_helper.dart';

Future compileAndFind(String code, String name, check(compiler, element)) {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(code, uri);
  return compiler.run(uri).then((_) {
    var element = findElement(compiler, name);
    check(compiler, element);
  });
}

void checkPrintType(String expression, checkType(compiler, type)) {
  asyncTest(() => compileAndFind('main() { print($expression); }', 'print',
          (compiler, printElement) {
        var parameter = printElement.functionSignature.requiredParameters.first;
        var type = compiler.globalInference.results.typeOf(parameter);
        checkType(compiler, type);
      }));

  asyncTest(() =>
      compileAndFind('main() { var x = print; print($expression); }', 'print',
          (compiler, printElement) {
        var parameter = printElement.functionSignature.requiredParameters.first;
        var type = compiler.globalInference.results.typeOf(parameter);
        checkType(compiler, type);
      }));

  asyncTest(() => compileAndFind(
          'main() { print($expression); print($expression); }', 'print',
          (compiler, printElement) {
        var parameter = printElement.functionSignature.requiredParameters.first;
        var type = compiler.globalInference.results.typeOf(parameter);
        checkType(compiler, type);
      }));
}

void testBasicTypes() {
  checkPrintType('true', (compiler, type) {
    if (type.isForwarding) type = type.forwardTo;
    Expect.identical(compiler.commonMasks.boolType, type);
  });
  checkPrintType('1.5', (compiler, type) {
    Expect.identical(compiler.commonMasks.doubleType, type);
  });
  checkPrintType('1', (compiler, type) {
    Expect.identical(compiler.commonMasks.uint31Type, type);
  });
  checkPrintType('[]', (compiler, type) {
    if (type.isForwarding) type = type.forwardTo;
    Expect.identical(compiler.commonMasks.growableListType, type);
  });
  checkPrintType('null', (compiler, type) {
    Expect.identical(compiler.commonMasks.nullType, type);
  });
  checkPrintType('"foo"', (compiler, type) {
    Expect.isTrue(
        compiler.commonMasks.stringType.containsOnlyString(compiler.world));
  });
}

void testOptionalParameters() {
  compileAndFind('fisk(a, [b, c]) {} main() { fisk(1); }', 'fisk',
      (compiler, fiskElement) {
    var firstParameter = fiskElement.functionSignature.requiredParameters[0];
    var secondParameter = fiskElement.functionSignature.optionalParameters[0];
    var thirdParameter = fiskElement.functionSignature.optionalParameters[1];
    var commonMasks = compiler.commonMasks;
    var inference = compiler.globalInference;
    Expect.identical(
        commonMasks.uint31Type, inference.results.typeOf(firstParameter));
    Expect.identical(
        commonMasks.nullType, inference.results.typeOf(secondParameter));
    Expect.identical(
        commonMasks.nullType, inference.results.typeOf(thirdParameter));
  });
}

void main() {
  testBasicTypes();
  testOptionalParameters();
}
