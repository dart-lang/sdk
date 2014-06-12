// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'memory_compiler.dart';
import 'compiler_helper.dart' show findElement;

var SOURCES = const {
'AddAll.dart': """
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
'Union.dart': """
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
'ValueType.dart': """
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
'Propagation.dart': """
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
""",
'Bailout.dart': """
  var dict = makeMap([1,2]);
  var notInt = 0;
  var alsoNotInt = 0;

  makeMap(values) {
    return {'moo': values[0], 'boo': values[1]};
  }

  main () {
    dict['goo'] = 42;
    var closure = dictfun() => dict;
    notInt = closure()['boo'];
    alsoNotInt = dict['goo'];
    print("\$notInt and \$alsoNotInt.");
  }
"""};

void main() {
  asyncTest(() =>
    compileAndTest("AddAll.dart", (types, getType, compiler) {
      Expect.equals(getType('int'), types.uint31Type);
      Expect.equals(getType('anotherInt'), types.uint31Type);
      Expect.equals(getType('dynamic'), types.dynamicType);
      Expect.equals(getType('nullOrInt'), types.uint31Type.nullable());
    }));
  asyncTest(() => compileAndTest("Union.dart", (types, getType, compiler) {
    Expect.equals(getType('nullOrInt'), types.uint31Type.nullable());
    Expect.isTrue(getType('aString').containsOnlyString(compiler));
    Expect.equals(getType('doubleOrNull'), types.doubleType.nullable());
  }));
  asyncTest(() => 
    compileAndTest("ValueType.dart", (types, getType, compiler) {
      Expect.equals(getType('knownDouble'), types.doubleType);
      Expect.equals(getType('intOrNull'), types.uint31Type.nullable());
      Expect.equals(getType('justNull'), types.nullType);
    }));
  asyncTest(() => compileAndTest("Propagation.dart", (code) {
    Expect.isFalse(code.contains("J.\$add\$ns"));
  }, createCode: true));
  asyncTest(() => compileAndTest("Bailout.dart", (types, getType, compiler) {
    Expect.equals(getType('notInt'), types.dynamicType);
    Expect.equals(getType('alsoNotInt'), types.dynamicType);
    Expect.isFalse(getType('dict').isDictionary);
  }));
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
