// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async_helper/async_helper.dart';
import 'package:expect/expect.dart';

import 'compiler_helper.dart';
import 'type_mask_test_helper.dart';

const String TEST = """

class A {
  get foo => 'string';
  set foo(value) {}
  operator[](index) => 'string';
  operator[]=(index, value) {}

  returnDynamic1() => foo--;
  returnNum1() => --foo;
  returnNum2() => foo -= 42;

  returnDynamic2() => this[index]--;
  returnNum3() => --this[index];
  returnNum4() => this[index] -= 42;

  returnEmpty3() => this.bar--;
  returnEmpty1() => --this.bar;
  returnEmpty2() => this.bar -= 42;
}

class B extends A {
  get foo => 42;
  operator[](index) => 42;

  returnString1() => super.foo--;
  returnDynamic1() => --super.foo;
  returnDynamic2() => super.foo -= 42;

  returnString2() => super[index]--;
  returnDynamic3() => --super[index];
  returnDynamic4() => super[index] -= 42;
}

main() {
  new A()..returnNum1()
         ..returnNum2()
         ..returnNum3()
         ..returnNum4()
         ..returnNum5()
         ..returnNum6()
         ..returnDynamic1()
         ..returnDynamic2()
         ..returnDynamic3();

  new B()..returnString1()
         ..returnString2()
         ..returnDynamic1()
         ..returnDynamic2()
         ..returnDynamic3()
         ..returnDynamic4();
}
""";

void main() {
  Uri uri = new Uri(scheme: 'source');
  var compiler = compilerFor(TEST, uri);
  asyncTest(() => compiler.run(uri).then((_) {
        var typesInferrer = compiler.globalInference.typesInferrerInternal;
        var closedWorld = typesInferrer.closedWorld;
        var commonMasks = closedWorld.commonMasks;

        checkReturnInClass(String className, String methodName, type) {
          dynamic cls = findElement(compiler, className);
          var element = cls.lookupLocalMember(methodName);
          Expect.equals(
              type,
              simplify(
                  typesInferrer.getReturnTypeOfElement(element), closedWorld),
              methodName);
        }

        var subclassOfInterceptor = commonMasks.interceptorType;

        checkReturnInClass('A', 'returnNum1', commonMasks.numType);
        checkReturnInClass('A', 'returnNum2', commonMasks.numType);
        checkReturnInClass('A', 'returnNum3', commonMasks.numType);
        checkReturnInClass('A', 'returnNum4', commonMasks.numType);
        checkReturnInClass('A', 'returnEmpty1', const TypeMask.nonNullEmpty());
        checkReturnInClass('A', 'returnEmpty2', const TypeMask.nonNullEmpty());
        checkReturnInClass('A', 'returnDynamic1', subclassOfInterceptor);
        checkReturnInClass('A', 'returnDynamic2', subclassOfInterceptor);
        checkReturnInClass('A', 'returnEmpty3', const TypeMask.nonNullEmpty());

        checkReturnInClass('B', 'returnString1', commonMasks.stringType);
        checkReturnInClass('B', 'returnString2', commonMasks.stringType);
        checkReturnInClass(
            'B', 'returnDynamic1', const TypeMask.nonNullEmpty());
        checkReturnInClass(
            'B', 'returnDynamic2', const TypeMask.nonNullEmpty());
        checkReturnInClass(
            'B', 'returnDynamic3', const TypeMask.nonNullEmpty());
        checkReturnInClass(
            'B', 'returnDynamic4', const TypeMask.nonNullEmpty());
      }));
}
