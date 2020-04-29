// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'package:async_helper/async_helper.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/entities.dart';
import 'package:compiler/src/elements/types.dart';
import 'package:compiler/src/world.dart';
import 'package:expect/expect.dart';
import '../helpers/element_lookup.dart';
import '../helpers/memory_compiler.dart';

const String source = '''
abstract class I<T> {
  T method();
}

class A<T> implements I<T> {
  noSuchMethod(_) => null;
}

class B<T> extends I<T> {
  noSuchMethod(_) => null;
}

abstract class C1<T> implements I<T> {
}

class C2<T> extends C1<T> {
  noSuchMethod(_) => null;
}

abstract class D1<T> implements I<T> {
}

abstract class D2<T> extends D1<T> {
  noSuchMethod(_) => null;
}

class D3<T> extends D2<T> {
}

class E1<T> {
  T method() => null;
}

abstract class E2<T> implements I<T> {
  noSuchMethod(_) => null;
}

class E3<T> extends E1<T> with E2<T> {
}

class F1<T> {
  T method() => null;
}

class F2<T> implements I<T> {
  noSuchMethod(_) => null;
}

class F3<T> extends F1<T> with F2<T> {
}

abstract class G1<T> {
  T method();
}

abstract class G2<T> implements I<T> {
  noSuchMethod(_) => null;
}

class G3<T> extends G1<T> with G2<T> {
}

abstract class H1<T> {
  T method();
}

abstract class H2<T> implements I<T> {
  noSuchMethod(_) => null;
}

class H3<T> extends H1<T> with H2<T> {
  method() => null;
}

main() {
  new A();
  new B();
  new C2();
  new D3();
  new E1();
  new E3();
  new F1();
  new F2();
  new F3();
  new G3();
  new H3();
  dynamic d;
  d.method();
}
''';

main() {
  asyncTest(() async {
    CompilationResult result =
        await runCompiler(memorySourceFiles: {'main.dart': source});
    Expect.isTrue(result.isSuccess);
    Compiler compiler = result.compiler;
    JClosedWorld closedWorld = compiler.backendClosedWorldForTesting;

    void check(String className,
        {bool hasMethod, bool isAbstract: false, String declaringClass}) {
      MemberEntity member =
          findClassMember(closedWorld, className, 'method', required: false);
      if (hasMethod) {
        Expect.isNotNull(
            member, "Missing member 'method' in class '$className'.");
        Expect.equals(isAbstract, member.isAbstract,
            "Unexpected abstract-ness on method $member.");
        ClassEntity cls = findClass(closedWorld, declaringClass);
        if (cls != member.enclosingClass) {
          print("Unexpected declaring class $member. "
              "Found ${member.enclosingClass}, expected $cls.");
        }
        Expect.equals(
            cls,
            member.enclosingClass,
            "Unexpected declaring class $member. "
            "Found ${member.enclosingClass}, expected $cls.");
        DartType type;
        if (member.isFunction) {
          type =
              closedWorld.elementEnvironment.getFunctionType(member).returnType;
        } else if (member.isGetter) {
          type =
              closedWorld.elementEnvironment.getFunctionType(member).returnType;
        } else if (member.isSetter) {
          type = closedWorld.elementEnvironment
              .getFunctionType(member)
              .parameterTypes
              .first;
        }
        type = type.withoutNullability;
        Expect.isTrue(type is TypeVariableType,
            "Unexpected member type for $member: $type");
        TypeVariableType typeVariable = type;
        Expect.equals(
            cls,
            typeVariable.element.typeDeclaration,
            "Unexpected type declaration for $typeVariable for $member. "
            "Expected $cls, found ${typeVariable.element.typeDeclaration}.");
      } else {
        Expect.isNull(member,
            "Unexpected member 'method' in class '$className': $member.");
      }
    }

    check('I', hasMethod: true, isAbstract: true, declaringClass: 'I');
    check('A', hasMethod: true, declaringClass: 'A');
    check('B', hasMethod: true, declaringClass: 'B');
    check('C1', hasMethod: false);
    check('C2', hasMethod: true, declaringClass: 'C2');
    check('D1', hasMethod: false);
    check('D2', hasMethod: false);
    check('D3', hasMethod: true, declaringClass: 'D3');
    check('E1', hasMethod: true, declaringClass: 'E1');
    check('E2', hasMethod: false);
    check('E3', hasMethod: true, declaringClass: 'E1');
    check('F1', hasMethod: true, declaringClass: 'F1');
    check('F2', hasMethod: true, declaringClass: 'F2');
    check('F3', hasMethod: true, declaringClass: 'F1');
    check('G1', hasMethod: true, isAbstract: true, declaringClass: 'G1');
    check('G2', hasMethod: false);
    check('G3', hasMethod: true, declaringClass: 'G3');
    check('H1', hasMethod: true, isAbstract: true, declaringClass: 'H1');
    check('H2', hasMethod: false);
    check('H3', hasMethod: true, declaringClass: 'H3');
  });
}
