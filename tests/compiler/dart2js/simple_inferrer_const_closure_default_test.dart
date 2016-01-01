// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';



const String TEST = """

// [defaultFn_i] is called only via [foo_i]'s default value with a small integer.

defaultFn1(a) => a;
defaultFn2(a) => a;
defaultFn3(a) => a;
defaultFn4(a) => a;
defaultFn5(a) => a;
defaultFn6(a) => a;

foo1([fn = defaultFn1]) => fn(54);
foo2({fn: defaultFn2}) => fn(54);
foo3([fn = defaultFn3]) => fn(54);
foo4({fn: defaultFn4}) => fn(54);
foo5([fn = defaultFn5]) => fn(54);
foo6({fn: defaultFn6}) => fn(54);

main() {
  // Direct calls.
  foo1();
  foo2();
  // Indirect calls.
  (foo3)();
  (foo4)();
  // Calls via Function.apply.
  Function.apply(foo5, []);
  Function.apply(foo6, []);
}
""";


void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
    var typesInferrer = compiler.typesTask.typesInferrer;

    checkArgument(String functionName, type) {
      var functionElement = findElement(compiler, functionName);
      var signature = functionElement.functionSignature;
      var element = signature.requiredParameterCount > 0
          ? signature.requiredParameters.first
          : signature.optionalParameters.first;
      Expect.equals(type,
          simplify(typesInferrer.getTypeOfElement(element), compiler),
          functionName);
    }

    checkOptionalArgument(String functionName, type) {
      var functionElement = findElement(compiler, functionName);
      var signature = functionElement.functionSignature;
      var element = signature.optionalParameters.first;
      Expect.equals(type,
          simplify(typesInferrer.getTypeOfElement(element), compiler),
          functionName);
    }

    checkArgument('foo1', compiler.typesTask.functionType);   /// 01: ok
    checkArgument('foo2', compiler.typesTask.functionType);   /// 02: ok
    checkArgument('foo3', compiler.typesTask.functionType);   /// 03: ok
    checkArgument('foo4', compiler.typesTask.functionType);   /// 04: ok
    checkArgument('foo5', compiler.typesTask.dynamicType);    /// 05: ok
    checkArgument('foo6', compiler.typesTask.dynamicType);    /// 06: ok

    checkArgument('defaultFn1', compiler.typesTask.uint31Type);   /// 07: ok
    checkArgument('defaultFn2', compiler.typesTask.uint31Type);   /// 08: ok
    checkArgument('defaultFn3', compiler.typesTask.uint31Type);   /// 09: ok
    checkArgument('defaultFn4', compiler.typesTask.uint31Type);   /// 10: ok
    checkArgument('defaultFn5', compiler.typesTask.uint31Type);   /// 11: ok
    checkArgument('defaultFn6', compiler.typesTask.uint31Type);   /// 12: ok
  }));
}
