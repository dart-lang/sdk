// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'compiler_helper.dart';
import 'parser_helper.dart';

const String TEST = """

class A {
  get foo => 'string';
  set foo(value) {}
  operator[](index) => 'string';
  operator[]=(index, value) {}
  
  returnString1() => foo--;
  returnNum1() => --foo;
  returnNum2() => foo -= 42;

  returnDynamic1() => this[index]--;
  returnNum3() => --this[index];
  returnNum4() => this[index] -= 42;

  returnDynamic2() => this.bar--;
  returnNum5() => --this.bar;
  returnNum6() => this.bar -= 42;
}

class B extends A {
  returnString1() => super.foo--;
  returnNum1() => --super.foo;
  returnNum2() => super.foo -= 42;

  returnDynamic1() => super[index]--;
  returnNum3() => --super[index];
  returnNum4() => super[index] -= 42;
}

main() {
  new A()..returnNum1()
         ..returnNum2()
         ..returnNum3()
         ..returnNum4()
         ..returnNum5()
         ..returnNum6()
         ..returnString1()
         ..returnDynamic1()
         ..returnDynamic2();

  new B()..returnNum1()
         ..returnNum2()
         ..returnNum3()
         ..returnNum4()
         ..returnString1()
         ..returnDynamic1();
}
""";

void main() {
  Uri uri = new Uri.fromComponents(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  compiler.runCompiler(uri);
  var typesInferrer = compiler.typesTask.typesInferrer;

  checkReturnInClass(String className, String methodName, type) {
    var cls = findElement(compiler, className);
    var element = cls.lookupLocalMember(buildSourceString(methodName));
    Expect.equals(type, typesInferrer.returnTypeOf[element]);
  }

  checkReturnInClass('A', 'returnNum1', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum2', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum3', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum4', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum5', typesInferrer.numType);
  checkReturnInClass('A', 'returnNum6', typesInferrer.numType);
  checkReturnInClass('A', 'returnDynamic1', typesInferrer.dynamicType);
  checkReturnInClass('A', 'returnDynamic2', typesInferrer.dynamicType);
  checkReturnInClass('A', 'returnString1', typesInferrer.stringType);

  checkReturnInClass('B', 'returnNum1', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum2', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum3', typesInferrer.numType);
  checkReturnInClass('B', 'returnNum4', typesInferrer.numType);
  checkReturnInClass('B', 'returnString1', typesInferrer.stringType);
  checkReturnInClass('B', 'returnDynamic1', typesInferrer.dynamicType);
}
