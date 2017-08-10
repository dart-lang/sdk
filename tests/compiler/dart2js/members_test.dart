// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library members_test;

import 'package:expect/expect.dart';
import "package:async_helper/async_helper.dart";
import 'type_test_helper.dart';
import 'package:compiler/src/elements/resolution_types.dart';
import "package:compiler/src/elements/elements.dart"
    show ClassElement, MemberSignature;
import "package:compiler/src/elements/names.dart";
import "package:compiler/src/resolution/class_members.dart"
    show MembersCreator, DeclaredMember, ErroneousMember, SyntheticMember;

void main() {
  testClassMembers();
  testInterfaceMembers();
  testClassVsInterfaceMembers();
  testMixinMembers();
  testMixinMembersWithoutImplements();
}

MemberSignature getMember(ResolutionInterfaceType cls, String name,
    {bool isSetter: false, int checkType: CHECK_INTERFACE}) {
  Name memberName = new Name(name, cls.element.library, isSetter: isSetter);
  MemberSignature member = checkType == CHECK_CLASS
      ? cls.element.lookupClassMember(memberName)
      : cls.element.lookupInterfaceMember(memberName);
  if (member != null) {
    Expect.equals(memberName, member.name);
  }
  return member;
}

/// Check interface member only.
const int CHECK_INTERFACE = 0;

/// Check class member only.
const int CHECK_CLASS = 1;

/// Check that there is no class member for the interface member.
const int NO_CLASS_MEMBER = 2;

/// Check that the interface member is also a class member.
const int ALSO_CLASS_MEMBER = 3;

/**
 * Checks [member] or interface member [name] of the declaration of [cls].
 *
 * If [inheritFrom] is set, the member from [cls] must be identical to the
 * member from [inheritedFrom].
 *
 * Otherwise, the properties of member are checked against the values of
 * [isStatic], [isSetter], [isGetter], [declarer], [type] and
 * [functionType].
 *
 * If [synthesizedFrom] or [erroneousFrom] is not `null`, the member is checked
 * to be synthesized for the corresponding members found on the type is
 * [synthesizedFrom] or  or [erroneousFrom], respectively.
 * Otherwise, if [declarer] is `null`, the declarer is checked to be [cls], and
 * if [declarer] is not `null`, the declarer is checked to be [declarer].
 * If [type] is `null` it is checked that the type of the member is also the
 * member type, otherwise the type is checked to be [type].
 *
 * If [isClassMember] is `true` it is checked that the member is also a class
 * member.
 */
MemberSignature checkMember(ResolutionInterfaceType cls, String name,
    {bool isStatic: false,
    bool isSetter: false,
    bool isGetter: false,
    ResolutionInterfaceType declarer,
    ResolutionDartType type,
    ResolutionFunctionType functionType,
    ResolutionInterfaceType inheritedFrom,
    List<ResolutionInterfaceType> synthesizedFrom,
    List<ResolutionInterfaceType> erroneousFrom,
    int checkType: ALSO_CLASS_MEMBER}) {
  String memberKind = checkType == CHECK_CLASS ? 'class' : 'interface';
  MemberSignature member =
      getMember(cls, name, isSetter: isSetter, checkType: checkType);
  Expect.isNotNull(member, "No $memberKind member '$name' in $cls.");
  Name memberName = member.name;
  if (checkType == ALSO_CLASS_MEMBER) {
    MemberSignature classMember = cls.element.lookupClassMember(memberName);
    Expect.isNotNull(classMember, "No class member '$memberName' in $cls.");
    Expect.equals(member, classMember);
  } else if (checkType == NO_CLASS_MEMBER) {
    Expect.isNull(cls.element.lookupClassMember(memberName));
  }

  if (inheritedFrom != null) {
    DeclaredMember inherited = checkType == CHECK_CLASS
        ? inheritedFrom.element.lookupClassMember(memberName)
        : inheritedFrom.element.lookupInterfaceMember(memberName);
    Expect.isNotNull(
        inherited, "No $memberKind member '$memberName' in $inheritedFrom.");
    Expect.equals(inherited.inheritFrom(inheritedFrom), member);
  } else {
    if (erroneousFrom != null || synthesizedFrom != null) {
      Expect.notEquals(
          checkType,
          CHECK_CLASS,
          "Arguments 'erroneousFrom' and 'synthesizedFrom' only apply "
          "to interface members.");
      if (synthesizedFrom != null) {
        Expect.isTrue(
            member is SyntheticMember, "Member '$member' is not synthesized.");
      } else {
        Expect.isTrue(
            member is ErroneousMember, "Member '$member' is not erroneous.");
      }
      Set<MemberSignature> members = new Set<MemberSignature>();
      List from = synthesizedFrom != null ? synthesizedFrom : erroneousFrom;
      for (ResolutionInterfaceType type in from) {
        DeclaredMember inheritedMember =
            type.element.lookupInterfaceMember(memberName);
        Expect.isNotNull(inheritedMember);
        members.add(inheritedMember.inheritFrom(type));
      }
      Expect.setEquals(members, member.declarations);
    } else if (declarer != null) {
      DeclaredMember declared = member;
      Expect.equals(
          declarer,
          declared.declarer,
          "Unexpected declarer '${declared.declarer}' of $memberKind member "
          "'$member'. Expected '${declarer}'.");
    } else {
      DeclaredMember declared = member;
      Expect.equals(cls.element, declared.element.enclosingClass);
      Expect.equals(cls, declared.declarer);
    }
    Expect.equals(isSetter, member.isSetter);
    Expect.equals(isGetter, member.isGetter);
    if (type != null) {
      Expect.equals(type, member.type,
          "Unexpected type of $memberKind member '$member'.");
    }
    if (functionType != null) {
      if (type == null) {
        Expect.equals(member.type, member.functionType,
            "Unexpected type of $memberKind member '$member'.");
      }
      Expect.equals(functionType, member.functionType,
          "Unexpected member type of $memberKind member '$member'.");
    }
  }
  return member;
}

void checkMemberCount(ResolutionInterfaceType cls, int expectedCount,
    {bool interfaceMembers: true}) {
  int count = 0;
  if (interfaceMembers) {
    cls.element.forEachInterfaceMember((_) => count++);
  } else {
    cls.element.forEachClassMember((_) => count++);
  }
  Expect.equals(expectedCount, count);
}

void testClassMembers() {
  asyncTest(() => TypeEnvironment.create(r"""
    abstract class A {
      int field;
      final finalField = 0;
      static var staticField;

      int get getter => 0;
      get abstractGetter;
      void set setter(int _) {}
      set abstractSetter(_);

      method() {}
      abstractMethod();
      static staticMethod() {}
    }
    class B<T> {
      T field;
      void method(T t) {}
      static staticMethod() {}
      toString([T t]) {}
    }
    class C<S> extends B<S> {}
    class D extends C<int> {}
    class E extends D {}
    """, compileMode: CompileMode.memory).then((env) {
        ResolutionInterfaceType bool_ = env['bool'];
        ResolutionInterfaceType String_ = env['String'];
        ResolutionInterfaceType int_ = env['int'];
        ResolutionDynamicType dynamic_ = env['dynamic'];
        ResolutionVoidType void_ = env['void'];
        ResolutionInterfaceType Type_ = env['Type'];
        ResolutionInterfaceType Invocation_ = env['Invocation'];

        ResolutionInterfaceType Object_ = env['Object'];
        checkMemberCount(Object_, 5 /*declared*/, interfaceMembers: true);
        checkMemberCount(Object_, 5 /*declared*/, interfaceMembers: false);

        checkMember(Object_, '==',
            functionType: env.functionType(bool_, [dynamic_]));
        checkMember(Object_, 'hashCode',
            isGetter: true,
            type: int_,
            functionType: env.functionType(int_, []));
        checkMember(Object_, 'noSuchMethod',
            functionType: env.functionType(dynamic_, [Invocation_]));
        checkMember(Object_, 'runtimeType',
            isGetter: true,
            type: Type_,
            functionType: env.functionType(Type_, []));
        checkMember(Object_, 'toString',
            functionType: env.functionType(String_, []));

        ResolutionInterfaceType A = env['A'];
        MembersCreator.computeAllClassMembers(env.resolution, A.element);

        checkMemberCount(A, 5 /*inherited*/ + 9 /*non-static declared*/,
            interfaceMembers: true);
        checkMemberCount(
            A,
            5 /*inherited*/ +
                9 /*non-abstract declared*/ +
                3 /* abstract declared */,
            interfaceMembers: false);

        checkMember(A, '==', inheritedFrom: Object_);
        checkMember(A, 'hashCode', inheritedFrom: Object_);
        checkMember(A, 'noSuchMethod', inheritedFrom: Object_);
        checkMember(A, 'runtimeType', inheritedFrom: Object_);
        checkMember(A, 'toString', inheritedFrom: Object_);

        checkMember(A, 'field',
            isGetter: true,
            type: int_,
            functionType: env.functionType(int_, []));
        checkMember(A, 'field',
            isSetter: true,
            type: int_,
            functionType: env.functionType(void_, [int_]));
        checkMember(A, 'finalField',
            isGetter: true,
            type: dynamic_,
            functionType: env.functionType(dynamic_, []));
        checkMember(A, 'staticField',
            isGetter: true,
            isStatic: true,
            checkType: CHECK_CLASS,
            type: dynamic_,
            functionType: env.functionType(dynamic_, []));
        checkMember(A, 'staticField',
            isSetter: true,
            isStatic: true,
            checkType: CHECK_CLASS,
            type: dynamic_,
            functionType: env.functionType(void_, [dynamic_]));

        checkMember(A, 'getter',
            isGetter: true,
            type: int_,
            functionType: env.functionType(int_, []));
        checkMember(A, 'abstractGetter',
            isGetter: true,
            type: dynamic_,
            functionType: env.functionType(dynamic_, []));
        checkMember(A, 'setter',
            isSetter: true,
            type: int_,
            functionType: env.functionType(void_, [int_]));
        checkMember(A, 'abstractSetter',
            isSetter: true,
            type: dynamic_,
            functionType: env.functionType(dynamic_, [dynamic_]));

        checkMember(A, 'method', functionType: env.functionType(dynamic_, []));
        checkMember(A, 'abstractMethod',
            functionType: env.functionType(dynamic_, []));
        checkMember(A, 'staticMethod',
            checkType: CHECK_CLASS,
            isStatic: true,
            functionType: env.functionType(dynamic_, []));

        ClassElement B = env.getElement('B');
        MembersCreator.computeAllClassMembers(env.resolution, B);
        ResolutionInterfaceType B_this = B.thisType;
        ResolutionTypeVariableType B_T = B_this.typeArguments.first;
        checkMemberCount(B_this, 4 /*inherited*/ + 4 /*non-static declared*/,
            interfaceMembers: true);
        checkMemberCount(B_this, 4 /*inherited*/ + 5 /*declared*/,
            interfaceMembers: false);

        checkMember(B_this, '==', inheritedFrom: Object_);
        checkMember(B_this, 'hashCode', inheritedFrom: Object_);
        checkMember(B_this, 'noSuchMethod', inheritedFrom: Object_);
        checkMember(B_this, 'runtimeType', inheritedFrom: Object_);

        checkMember(B_this, 'field',
            isGetter: true, type: B_T, functionType: env.functionType(B_T, []));
        checkMember(B_this, 'field',
            isSetter: true,
            type: B_T,
            functionType: env.functionType(void_, [B_T]));
        checkMember(B_this, 'method',
            functionType: env.functionType(void_, [B_T]));
        checkMember(B_this, 'staticMethod',
            checkType: CHECK_CLASS,
            isStatic: true,
            functionType: env.functionType(dynamic_, []));
        checkMember(B_this, 'toString',
            functionType:
                env.functionType(dynamic_, [], optionalParameters: [B_T]));

        ClassElement C = env.getElement('C');
        MembersCreator.computeAllClassMembers(env.resolution, C);
        ResolutionInterfaceType C_this = C.thisType;
        ResolutionTypeVariableType C_S = C_this.typeArguments.first;
        checkMemberCount(C_this, 8 /*inherited*/, interfaceMembers: true);
        checkMemberCount(C_this, 8 /*inherited*/, interfaceMembers: false);
        ResolutionInterfaceType B_S = instantiate(B, [C_S]);

        checkMember(C_this, '==', inheritedFrom: Object_);
        checkMember(C_this, 'hashCode', inheritedFrom: Object_);
        checkMember(C_this, 'noSuchMethod', inheritedFrom: Object_);
        checkMember(C_this, 'runtimeType', inheritedFrom: Object_);

        checkMember(C_this, 'field',
            isGetter: true,
            declarer: B_S,
            type: C_S,
            functionType: env.functionType(C_S, []));
        checkMember(C_this, 'field',
            isSetter: true,
            declarer: B_S,
            type: C_S,
            functionType: env.functionType(void_, [C_S]));
        checkMember(C_this, 'method',
            declarer: B_S, functionType: env.functionType(void_, [C_S]));
        checkMember(C_this, 'toString',
            declarer: B_S,
            functionType:
                env.functionType(dynamic_, [], optionalParameters: [C_S]));

        ResolutionInterfaceType D = env['D'];
        MembersCreator.computeAllClassMembers(env.resolution, D.element);
        checkMemberCount(D, 8 /*inherited*/, interfaceMembers: true);
        checkMemberCount(D, 8 /*inherited*/, interfaceMembers: false);
        ResolutionInterfaceType B_int = instantiate(B, [int_]);

        checkMember(D, '==', inheritedFrom: Object_);
        checkMember(D, 'hashCode', inheritedFrom: Object_);
        checkMember(D, 'noSuchMethod', inheritedFrom: Object_);
        checkMember(D, 'runtimeType', inheritedFrom: Object_);

        checkMember(D, 'field',
            isGetter: true,
            declarer: B_int,
            type: int_,
            functionType: env.functionType(int_, []));
        checkMember(D, 'field',
            isSetter: true,
            declarer: B_int,
            type: int_,
            functionType: env.functionType(void_, [int_]));
        checkMember(D, 'method',
            declarer: B_int, functionType: env.functionType(void_, [int_]));
        checkMember(D, 'toString',
            declarer: B_int,
            functionType:
                env.functionType(dynamic_, [], optionalParameters: [int_]));

        ResolutionInterfaceType E = env['E'];
        MembersCreator.computeAllClassMembers(env.resolution, E.element);
        checkMemberCount(E, 8 /*inherited*/, interfaceMembers: true);
        checkMemberCount(E, 8 /*inherited*/, interfaceMembers: false);

        checkMember(E, '==', inheritedFrom: Object_);
        checkMember(E, 'hashCode', inheritedFrom: Object_);
        checkMember(E, 'noSuchMethod', inheritedFrom: Object_);
        checkMember(E, 'runtimeType', inheritedFrom: Object_);

        checkMember(E, 'field',
            isGetter: true,
            declarer: B_int,
            type: int_,
            functionType: env.functionType(int_, []));
        checkMember(E, 'field',
            isSetter: true,
            declarer: B_int,
            type: int_,
            functionType: env.functionType(void_, [int_]));
        checkMember(E, 'method',
            declarer: B_int, functionType: env.functionType(void_, [int_]));
        checkMember(E, 'toString',
            declarer: B_int,
            functionType:
                env.functionType(dynamic_, [], optionalParameters: [int_]));
      }));
}

void testInterfaceMembers() {
  asyncTest(() => TypeEnvironment.create(r"""
    abstract class A {
      num method1();
      void method2();
      void method3();
      void method4();
      method5(a);
      method6(a);
      method7(a);
      method8(a, b);
      method9(a, b, c);
      method10(a, {b, c});
      method11(a, {b, c});
      num get getter1;
      num get getter2;
      void set setter1(num _);
      void set setter2(num _);
      void set setter3(num _);
      get getterAndMethod;
    }
    abstract class B {
      int method1();
      int method2();
      num method3();
      num method4();
      method5([a]);
      method6([a, b]);
      method7(a, [b]);
      method8([a]);
      method9(a, [b]);
      method10(a, {c, d});
      method11(a, b, {c, d});
      num get getter1;
      int get getter2;
      void set setter1(num _);
      set setter2(num _);
      void set setter3(int _);
      getterAndMethod();
    }
    abstract class C {
      int method3();
      num method4();
    }
    abstract class D implements A, B, C {}
    """).then((env) {
        ResolutionDynamicType dynamic_ = env['dynamic'];
        ResolutionVoidType void_ = env['void'];
        ResolutionInterfaceType num_ = env['num'];

        ResolutionInterfaceType A = env['A'];
        ResolutionInterfaceType B = env['B'];
        ResolutionInterfaceType C = env['C'];
        ResolutionInterfaceType D = env['D'];

        // Ensure that members have been computed on all classes.
        MembersCreator.computeAllClassMembers(env.resolution, D.element);

        // A: num method1()
        // B: int method1()
        // D: dynamic method1() -- synthesized from A and B.
        checkMember(D, 'method1',
            synthesizedFrom: [A, B],
            functionType: env.functionType(dynamic_, []),
            checkType: NO_CLASS_MEMBER);

        // A: void method2()
        // B: int method2()
        // D: int method2() -- inherited from B
        checkMember(D, 'method2', inheritedFrom: B, checkType: NO_CLASS_MEMBER);

        // A: void method3()
        // B: num method3()
        // C: int method3()
        // D: dynamic method3() -- synthesized from A, B, and C.
        checkMember(D, 'method3',
            synthesizedFrom: [A, B, C],
            functionType: env.functionType(dynamic_, []),
            checkType: NO_CLASS_MEMBER);

        // A: void method4()
        // B: num method4()
        // C: num method4()
        // D: num method4() -- synthesized from B and C.
        checkMember(D, 'method4',
            synthesizedFrom: [B, C],
            functionType: env.functionType(num_, []),
            checkType: NO_CLASS_MEMBER);

        // A: method5(a)
        // B: method5([a])
        // D: method5([a]) -- inherited from B
        checkMember(D, 'method5', inheritedFrom: B, checkType: NO_CLASS_MEMBER);

        // A: method6(a)
        // B: method6([a, b])
        // D: method6([a, b]) -- inherited from B
        checkMember(D, 'method6', inheritedFrom: B, checkType: NO_CLASS_MEMBER);

        // A: method7(a)
        // B: method7(a, [b])
        // D: method7(a, [b]) -- inherited from B
        checkMember(D, 'method7', inheritedFrom: B, checkType: NO_CLASS_MEMBER);

        // A: method8(a, b)
        // B: method8([a])
        // D: method8([a, b]) -- synthesized from A and B.
        checkMember(D, 'method8',
            synthesizedFrom: [A, B],
            functionType: env.functionType(dynamic_, [],
                optionalParameters: [dynamic_, dynamic_]),
            checkType: NO_CLASS_MEMBER);

        // A: method9(a, b, c)
        // B: method9(a, [b])
        // D: method9(a, [b, c]) -- synthesized from A and B.
        checkMember(D, 'method9',
            synthesizedFrom: [A, B],
            functionType: env.functionType(dynamic_, [dynamic_],
                optionalParameters: [dynamic_, dynamic_]),
            checkType: NO_CLASS_MEMBER);

        // A: method10(a, {b, c})
        // B: method10(a, {c, d})
        // D: method10(a, {b, c, d}) -- synthesized from A and B.
        checkMember(D, 'method10',
            synthesizedFrom: [A, B],
            functionType: env.functionType(dynamic_, [dynamic_],
                namedParameters: {'b': dynamic_, 'c': dynamic_, 'd': dynamic_}),
            checkType: NO_CLASS_MEMBER);

        // A: method11(a, {b, c})
        // B: method11(a, b, {c, d})
        // D: method11(a, [b], {c, d}) -- synthesized from A and B.
        // TODO(johnniwinther): Change to check synthesized member when function
        // types with both optional and named parameters are supported.
        Expect.isNull(getMember(D, 'method11'));
        /*checkMember(D, 'method11',
        synthesizedFrom: [A, B],
        functionType: env.functionType(dynamic_, [dynamic_],
                                       optionalParameters: [dynamic_],
                                       namedParameters: {'c': dynamic_,
                                                         'd': dynamic_,}),
        checkType: NO_CLASS_MEMBER);*/

        // A: num get getter1
        // B: num get getter1
        // D: num get getter1 -- synthesized from A and B.
        checkMember(D, 'getter1',
            isGetter: true,
            synthesizedFrom: [A, B],
            type: num_,
            functionType: env.functionType(num_, []),
            checkType: NO_CLASS_MEMBER);

        // A: num get getter2
        // B: int get getter2
        // D: dynamic get getter2 -- synthesized from A and B.
        checkMember(D, 'getter2',
            isGetter: true,
            synthesizedFrom: [A, B],
            type: dynamic_,
            functionType: env.functionType(dynamic_, []),
            checkType: NO_CLASS_MEMBER);

        // A: void set setter1(num _)
        // B: void set setter1(num _)
        // D: void set setter1(num _) -- synthesized from A and B.
        checkMember(D, 'setter1',
            isSetter: true,
            synthesizedFrom: [A, B],
            type: num_,
            functionType: env.functionType(void_, [num_]),
            checkType: NO_CLASS_MEMBER);

        // A: void set setter2(num _)
        // B: set setter2(num _)
        // D: dynamic set setter2(dynamic _) -- synthesized from A and B.
        checkMember(D, 'setter2',
            isSetter: true,
            synthesizedFrom: [A, B],
            type: dynamic_,
            functionType: env.functionType(dynamic_, [dynamic_]),
            checkType: NO_CLASS_MEMBER);

        // A: void set setter3(num _)
        // B: void set setter3(int _)
        // D: dynamic set setter3(dynamic _) -- synthesized from A and B.
        checkMember(D, 'setter3',
            isSetter: true,
            synthesizedFrom: [A, B],
            type: dynamic_,
            functionType: env.functionType(dynamic_, [dynamic_]),
            checkType: NO_CLASS_MEMBER);

        // A: get getterAndMethod
        // B: getterAndMethod()
        // D: nothing inherited
        checkMember(D, 'getterAndMethod',
            erroneousFrom: [A, B], checkType: NO_CLASS_MEMBER);
      }));
}

void testClassVsInterfaceMembers() {
  asyncTest(() => TypeEnvironment.create(r"""
    class A {
      method1() {}
      method2() {}
    }
    abstract class B {
      method1();
      method2(a);
    }
    abstract class C extends A implements B {}
    """).then((env) {
        ResolutionDynamicType dynamic_ = env['dynamic'];

        ResolutionInterfaceType A = env['A'];
        ResolutionInterfaceType B = env['B'];
        ResolutionInterfaceType C = env['C'];

        // Ensure that members have been computed on all classes.
        MembersCreator.computeAllClassMembers(env.resolution, C.element);

        // A: method1()
        // B: method1()
        // C class: method1() -- inherited from A.
        // C interface: dynamic method1() -- synthesized from A and B.
        MemberSignature interfaceMember = checkMember(C, 'method1',
            checkType: CHECK_INTERFACE,
            synthesizedFrom: [A, B],
            functionType: env.functionType(dynamic_, []));
        MemberSignature classMember =
            checkMember(C, 'method1', checkType: CHECK_CLASS, inheritedFrom: A);
        Expect.notEquals(interfaceMember, classMember);

        // A: method2()
        // B: method2(a)
        // C class: method2() -- inherited from A.
        // C interface: dynamic method2([a]) -- synthesized from A and B.
        interfaceMember = checkMember(C, 'method2',
            checkType: CHECK_INTERFACE,
            synthesizedFrom: [A, B],
            functionType:
                env.functionType(dynamic_, [], optionalParameters: [dynamic_]));
        classMember =
            checkMember(C, 'method2', checkType: CHECK_CLASS, inheritedFrom: A);
        Expect.notEquals(interfaceMember, classMember);
      }));
}

void testMixinMembers() {
  asyncTest(() => TypeEnvironment.create(r"""
    class A<T> {
      method1() {}
      method2() {}
      method3(T a) {}
      method4(T a) {}
    }
    abstract class B<S> {
      method1();
      method2(a);
      method3(S a) {}
    }
    abstract class C<U, V> extends Object with A<U> implements B<V> {}
    """).then((env) {
        ResolutionDynamicType dynamic_ = env['dynamic'];

        ClassElement A = env.getElement('A');
        ClassElement B = env.getElement('B');
        ClassElement C = env.getElement('C');
        ResolutionInterfaceType C_this = C.thisType;
        ResolutionTypeVariableType C_U = C_this.typeArguments[0];
        ResolutionTypeVariableType C_V = C_this.typeArguments[1];
        ResolutionInterfaceType A_U = instantiate(A, [C_U]);
        ResolutionInterfaceType B_V = instantiate(B, [C_V]);

        // Ensure that members have been computed on all classes.
        MembersCreator.computeAllClassMembers(env.resolution, C);

        // A: method1()
        // B: method1()
        // C class: method1() -- inherited from A.
        // C interface: dynamic method1() -- synthesized from A and B.
        MemberSignature interfaceMember = checkMember(C_this, 'method1',
            checkType: CHECK_INTERFACE,
            synthesizedFrom: [A_U, B_V],
            functionType: env.functionType(dynamic_, []));
        MemberSignature classMember = checkMember(C_this, 'method1',
            checkType: CHECK_CLASS, inheritedFrom: A_U);
        Expect.notEquals(interfaceMember, classMember);

        // A: method2()
        // B: method2(a)
        // C class: method2() -- inherited from A.
        // C interface: dynamic method2([a]) -- synthesized from A and B.
        interfaceMember = checkMember(C_this, 'method2',
            checkType: CHECK_INTERFACE,
            synthesizedFrom: [A_U, B_V],
            functionType:
                env.functionType(dynamic_, [], optionalParameters: [dynamic_]));
        classMember = checkMember(C_this, 'method2',
            checkType: CHECK_CLASS, inheritedFrom: A_U);
        Expect.notEquals(interfaceMember, classMember);

        // A: method3(U a)
        // B: method3(V a)
        // C class: method3(U a) -- inherited from A.
        // C interface: dynamic method3(a) -- synthesized from A and B.
        interfaceMember = checkMember(C_this, 'method3',
            checkType: CHECK_INTERFACE,
            synthesizedFrom: [A_U, B_V],
            functionType: env.functionType(dynamic_, [dynamic_]));
        classMember = checkMember(C_this, 'method3',
            checkType: CHECK_CLASS, inheritedFrom: A_U);
        Expect.notEquals(interfaceMember, classMember);

        // A: method4(U a)
        // B: --
        // C class: method4(U a) -- inherited from A.
        // C interface: method4(U a) -- inherited from A.
        checkMember(C_this, 'method4',
            checkType: ALSO_CLASS_MEMBER, inheritedFrom: A_U);
      }));
}

void testMixinMembersWithoutImplements() {
  asyncTest(() => TypeEnvironment.create(r"""
    abstract class A {
      m();
    }
    abstract class B implements A {
    }
    abstract class C extends Object with B {}
    """).then((env) {
        ResolutionDynamicType dynamic_ = env['dynamic'];

        ResolutionInterfaceType A = env['A'];
        ResolutionInterfaceType C = env['C'];

        // Ensure that members have been computed on all classes.
        MembersCreator.computeAllClassMembers(env.resolution, C.element);

        checkMember(C, 'm',
            checkType: NO_CLASS_MEMBER,
            inheritedFrom: A,
            functionType: env.functionType(dynamic_, []));
      }));
}
