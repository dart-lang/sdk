// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';
import 'compiler_helper.dart' show findElement;

var SOURCES = const {
'testAddAll.dart': """
  var dictionaryA = {'string': "aString", 'int': 42, 'double': 21.5,
                     'list': []};
  var dictionaryB = {'string': "aString", 'int': 42, 'double': 21.5,
                     'list': []};
  var otherDict = {'stringTwo' : "anotherString", 'intTwo' : 84};
  var int = 0;
  var anotherInt = 0;
  var nullOrInt = 0;
  var dynamic = 0;

  main() {
    dictionaryA.addAll(otherDict);
    dictionaryB.addAll({'stringTwo' : "anotherString", 'intTwo' : 84});
    int = dictionaryB['int'];
    anotherInt = otherDict['intTwo'];
    dynamic = dictionaryA['int'];
    nullOrInt = dictionaryB['intTwo'];
  }
""",
'testUnion.dart': """
  var dictionaryA = {'string': "aString", 'int': 42, 'double': 21.5,
                     'list': []};
  var dictionaryB = {'string': "aString", 'intTwo': 42, 'list': []};
  var nullOrInt = 0;
  var aString = "";
  var doubleOrNull = 22.2;
  var key = "string";

  main() {
    var union = dictionaryA['foo'] ? dictionaryA : dictionaryB;
    nullOrInt = union['intTwo'];
    aString = union['string'];
    doubleOrNull = union['double'];
  }
""",
'testValueType.dart': """
  var dictionary = {'string': "aString", 'int': 42, 'double': 21.5, 'list': []};
  var keyD = 'double';
  var keyI = 'int';
  var keyN = 'notFoundInMap';
  var knownDouble = 42.2;
  var intOrNull = dictionary[keyI];
  var justNull = dictionary[keyN];

  main() {
    knownDouble = dictionary[keyD];
    var x = [intOrNull, justNull];
  }
""",
'testPropagation.dart': """
  class A {
    A();
    foo(value) {
      return value['anInt'];
    }
  }

  class B {
    B();
    foo(value) {
      return 0;
    }
  }

  main() {
    var dictionary = {'anInt': 42, 'aString': "theString"};
    var it;
    if ([true, false][0]) {
      it = new A();
    } else {
      it = new B();
    }
    print(it.foo(dictionary) + 2);
  }
"""};

void main() {
  asyncTest(() =>
    compileAndTest("testAddAll.dart", (types, getType, compiler) {
      Expect.equals(getType('int'), types.uint31Type);
      Expect.equals(getType('anotherInt'), types.uint31Type);
      Expect.equals(getType('dynamic'), types.dynamicType);
      Expect.equals(getType('nullOrInt'), types.uint31Type.nullable());
    }).then((_) => compileAndTest("testUnion.dart", (types, getType, compiler) {
      Expect.equals(getType('nullOrInt'), types.uint31Type.nullable());
      Expect.isTrue(getType('aString').containsOnlyString(compiler));
      Expect.equals(getType('doubleOrNull'), types.doubleType.nullable());
    })).then((_) => compileAndTest("testValueType.dart",
        (types, getType, compiler) {
      Expect.equals(getType('knownDouble'), types.doubleType);
      Expect.equals(getType('intOrNull'), types.uint31Type.nullable());
      Expect.equals(getType('justNull'), types.nullType);
    })).then((_) => compileAndTest("testPropagation.dart", (code) {
      Expect.isFalse(code.contains("J.\$add\$ns"));
    }, createCode: true))
  );
}

compileAndTest(source, checker, {createCode: false}) {
  var compiler = compilerFor(SOURCES);
  compiler.stopAfterTypeInference = !createCode;
  var uri = Uri.parse('memory:'+source);
  return compiler.runCompiler(uri).then((_) {
    var typesTask = compiler.typesTask;
    var typesInferrer = typesTask.typesInferrer;
    getType(String name) {
      var element = findElement(compiler, name);
      return typesInferrer.getTypeOfElement(element);
    }
    if (!createCode) {
      checker(typesTask, getType, compiler);
    } else {
      var element = compiler.mainApp.findExported('main');
      var code = compiler.backend.assembleCode(element);
      checker(code);
    }
  });
}
