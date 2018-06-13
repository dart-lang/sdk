// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: A.:[exact=A]*/
class A {}

/*element: B.:[exact=B]*/
class B extends A {}

/*element: C.:[exact=C]*/
class C {}

/*element: main:[null]*/
main() {
  invokeFunctions();
  invokeGenericClasses();
  invokeGenericMethods();
}

/*kernel.element: invokeFunction1:[null|subclass=Object]*/
/*strong.element: invokeFunction1:[null|subclass=A]*/
invokeFunction1(A Function() /*[subclass=Closure]*/ f) {
  return f();
}

/*kernel.element: invokeFunction2:[null|subclass=Object]*/
/*strong.element: invokeFunction2:[null|exact=B]*/
invokeFunction2(B Function() /*[subclass=Closure]*/ f) {
  return f();
}

/*kernel.element: invokeFunction3:[null|subclass=Object]*/
/*strong.element: invokeFunction3:[null|exact=C]*/
invokeFunction3(C Function() /*[subclass=Closure]*/ f) {
  return f();
}

/*element: genericFunction:[null|subclass=Object]*/
T genericFunction<T>(T Function() /*[subclass=Closure]*/ f) => f();

/*kernel.element: invokeGenericFunction1:[null|subclass=Object]*/
/*strong.element: invokeGenericFunction1:[null|subclass=A]*/
invokeGenericFunction1() {
  return genericFunction<A>(/*[exact=A]*/ () => new A());
}

/*kernel.element: invokeGenericFunction2:[null|subclass=Object]*/
/*strong.element: invokeGenericFunction2:[null|exact=B]*/
invokeGenericFunction2() {
  return genericFunction<B>(/*[exact=B]*/ () => new B());
}

/*kernel.element: invokeGenericFunction3:[null|subclass=Object]*/
/*strong.element: invokeGenericFunction3:[null|exact=C]*/
invokeGenericFunction3() {
  return genericFunction<C>(/*[exact=C]*/ () => new C());
}

/*kernel.element: invokeGenericLocalFunction1:[null|subclass=Object]*/
/*strong.element: invokeGenericLocalFunction1:[null|subclass=A]*/
invokeGenericLocalFunction1() {
  /*[null|subclass=Object]*/
  T local<T>(T Function() /*[subclass=Closure]*/ f) => f();
  return local<A>(/*[exact=A]*/ () => new A());
}

/*kernel.element: invokeGenericLocalFunction2:[null|subclass=Object]*/
/*strong.element: invokeGenericLocalFunction2:[null|exact=B]*/
invokeGenericLocalFunction2() {
  /*[null|subclass=Object]*/
  T local<T>(T Function() /*[subclass=Closure]*/ f) => f();
  return local<B>(/*[exact=B]*/ () => new B());
}

/*kernel.element: invokeGenericLocalFunction3:[null|subclass=Object]*/
/*strong.element: invokeGenericLocalFunction3:[null|exact=C]*/
invokeGenericLocalFunction3() {
  /*[null|subclass=Object]*/
  T local<T>(T Function() /*[subclass=Closure]*/ f) => f();
  return local<C>(/*[exact=C]*/ () => new C());
}

/*element: invokeFunctions:[null]*/
invokeFunctions() {
  invokeFunction1(/*[exact=A]*/ () => new A());
  invokeFunction2(/*[exact=B]*/ () => new B());
  invokeFunction3(/*[exact=C]*/ () => new C());
  invokeGenericFunction1();
  invokeGenericFunction2();
  invokeGenericFunction3();
  invokeGenericLocalFunction1();
  invokeGenericLocalFunction2();
  invokeGenericLocalFunction3();
}

class GenericClass<T> {
  /*element: GenericClass.field:Union([exact=C], [subclass=A])*/
  final T field;

  /*element: GenericClass.functionTypedField:[subclass=Closure]*/
  final T Function() functionTypedField;

  /*element: GenericClass.:[exact=GenericClass]*/
  GenericClass(this. /*Union([exact=C], [subclass=A])*/ field)
      : functionTypedField = (/*Union([exact=C], [subclass=A])*/ () => field);

  /*element: GenericClass.getter:Union([exact=C], [subclass=A])*/
  T get getter => /*[subclass=GenericClass]*/ field;

  /*element: GenericClass.functionTypedGetter:[subclass=Closure]*/
  T Function()
      get functionTypedGetter => /*[subclass=GenericClass]*/ functionTypedField;

  /*element: GenericClass.method:Union([exact=C], [subclass=A])*/
  T method() => /*[subclass=GenericClass]*/ field;

  /*element: GenericClass.functionTypedMethod:[subclass=Closure]*/
  T Function()
      functionTypedMethod() => /*[subclass=GenericClass]*/ functionTypedField;
}

class GenericSubclass<T> extends GenericClass<T> {
  /*element: GenericSubclass.:[exact=GenericSubclass]*/
  GenericSubclass(T /*Union([exact=C], [subclass=A])*/ field) : super(field);

  /*element: GenericSubclass.superField:Union([exact=C], [subclass=A])*/
  superField() => super.field;

  /*element: GenericSubclass.superGetter:Union([exact=C], [subclass=A])*/
  superGetter() => super.getter;

  /*element: GenericSubclass.superMethod:Union([exact=C], [subclass=A])*/
  superMethod() => super.method();

  /*element: GenericSubclass.superFieldInvoke:[null|subclass=Object]*/
  superFieldInvoke() => super.functionTypedField();

  /*element: GenericSubclass.superGetterInvoke:[null|subclass=Object]*/
  superGetterInvoke() => super.functionTypedGetter();

  /*element: GenericSubclass.superMethodInvoke:[null|subclass=Object]*/
  superMethodInvoke() => super.functionTypedMethod()();
}

/*kernel.element: invokeInstanceMethod1:Union([exact=C], [subclass=A])*/
/*strong.element: invokeInstanceMethod1:[subclass=A]*/
invokeInstanceMethod1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ method();

/*kernel.element: invokeInstanceMethod2:Union([exact=C], [subclass=A])*/
/*strong.element: invokeInstanceMethod2:[exact=B]*/
invokeInstanceMethod2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ method();

/*kernel.element: invokeInstanceMethod3:Union([exact=C], [subclass=A])*/
/*strong.element: invokeInstanceMethod3:[exact=C]*/
invokeInstanceMethod3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ method();

/*kernel.element: invokeInstanceGetter1:Union([exact=C], [subclass=A])*/
/*strong.element: invokeInstanceGetter1:[subclass=A]*/
invokeInstanceGetter1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ getter;

/*kernel.element: invokeInstanceGetter2:Union([exact=C], [subclass=A])*/
/*strong.element: invokeInstanceGetter2:[exact=B]*/
invokeInstanceGetter2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ getter;

/*kernel.element: invokeInstanceGetter3:Union([exact=C], [subclass=A])*/
/*strong.element: invokeInstanceGetter3:[exact=C]*/
invokeInstanceGetter3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ getter;

/*kernel.element: accessInstanceField1:Union([exact=C], [subclass=A])*/
/*strong.element: accessInstanceField1:[subclass=A]*/
accessInstanceField1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ field;

/*kernel.element: accessInstanceField2:Union([exact=C], [subclass=A])*/
/*strong.element: accessInstanceField2:[exact=B]*/
accessInstanceField2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ field;

/*kernel.element: accessInstanceField3:Union([exact=C], [subclass=A])*/
/*strong.element: accessInstanceField3:[exact=C]*/
accessInstanceField3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ field;

/*element: invokeSuperMethod1:Union([exact=C], [subclass=A])*/
invokeSuperMethod1(GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethod();

/*element: invokeSuperMethod2:Union([exact=C], [subclass=A])*/
invokeSuperMethod2(GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethod();

/*element: invokeSuperMethod3:Union([exact=C], [subclass=A])*/
invokeSuperMethod3(GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethod();

/*element: invokeSuperGetter1:Union([exact=C], [subclass=A])*/
invokeSuperGetter1(GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetter();

/*element: invokeSuperGetter2:Union([exact=C], [subclass=A])*/
invokeSuperGetter2(GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetter();

/*element: invokeSuperGetter3:Union([exact=C], [subclass=A])*/
invokeSuperGetter3(GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetter();

/*element: accessSuperField1:Union([exact=C], [subclass=A])*/
accessSuperField1(GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superField();

/*element: accessSuperField2:Union([exact=C], [subclass=A])*/
accessSuperField2(GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superField();

/*element: accessSuperField3:Union([exact=C], [subclass=A])*/
accessSuperField3(GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superField();

/*kernel.element: invokeFunctionTypedInstanceMethod1:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceMethod1:[null|subclass=A]*/
invokeFunctionTypedInstanceMethod1(
        GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedMethod()();

/*kernel.element: invokeFunctionTypedInstanceMethod2:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceMethod2:[null|exact=B]*/
invokeFunctionTypedInstanceMethod2(
        GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedMethod()();

/*kernel.element: invokeFunctionTypedInstanceMethod3:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceMethod3:[null|exact=C]*/
invokeFunctionTypedInstanceMethod3(
        GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedMethod()();

/*kernel.element: invokeFunctionTypedInstanceGetter1:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceGetter1:[null|subclass=A]*/
invokeFunctionTypedInstanceGetter1(
        GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedGetter();

/*kernel.element: invokeFunctionTypedInstanceGetter2:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceGetter2:[null|exact=B]*/
invokeFunctionTypedInstanceGetter2(
        GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedGetter();

/*kernel.element: invokeFunctionTypedInstanceGetter3:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceGetter3:[null|exact=C]*/
invokeFunctionTypedInstanceGetter3(
        GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedGetter();

/*kernel.element: invokeFunctionTypedInstanceField1:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceField1:[null|subclass=A]*/
invokeFunctionTypedInstanceField1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedField();

/*kernel.element: invokeFunctionTypedInstanceField2:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceField2:[null|exact=B]*/
invokeFunctionTypedInstanceField2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedField();

/*kernel.element: invokeFunctionTypedInstanceField3:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedInstanceField3:[null|exact=C]*/
invokeFunctionTypedInstanceField3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedField();

/*element: invokeFunctionTypedSuperMethod1:[null|subclass=Object]*/
invokeFunctionTypedSuperMethod1(
        GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethodInvoke();

/*element: invokeFunctionTypedSuperMethod2:[null|subclass=Object]*/
invokeFunctionTypedSuperMethod2(
        GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethodInvoke();

/*element: invokeFunctionTypedSuperMethod3:[null|subclass=Object]*/
invokeFunctionTypedSuperMethod3(
        GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethodInvoke();

/*element: invokeFunctionTypedSuperGetter1:[null|subclass=Object]*/
invokeFunctionTypedSuperGetter1(
        GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetterInvoke();

/*element: invokeFunctionTypedSuperGetter2:[null|subclass=Object]*/
invokeFunctionTypedSuperGetter2(
        GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetterInvoke();

/*element: invokeFunctionTypedSuperGetter3:[null|subclass=Object]*/
invokeFunctionTypedSuperGetter3(
        GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetterInvoke();

/*element: invokeFunctionTypedSuperField1:[null|subclass=Object]*/
invokeFunctionTypedSuperField1(
        GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superFieldInvoke();

/*element: invokeFunctionTypedSuperField2:[null|subclass=Object]*/
invokeFunctionTypedSuperField2(
        GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superFieldInvoke();

/*element: invokeFunctionTypedSuperField3:[null|subclass=Object]*/
invokeFunctionTypedSuperField3(
        GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superFieldInvoke();

/*element: invokeGenericClasses:[null]*/
invokeGenericClasses() {
  invokeInstanceMethod1(new GenericClass<A>(new A()));
  invokeInstanceMethod2(new GenericClass<B>(new B()));
  invokeInstanceMethod3(new GenericClass<C>(new C()));
  invokeInstanceGetter1(new GenericClass<A>(new A()));
  invokeInstanceGetter2(new GenericClass<B>(new B()));
  invokeInstanceGetter3(new GenericClass<C>(new C()));
  accessInstanceField1(new GenericClass<A>(new A()));
  accessInstanceField2(new GenericClass<B>(new B()));
  accessInstanceField3(new GenericClass<C>(new C()));

  invokeSuperMethod1(new GenericSubclass<A>(new A()));
  invokeSuperMethod2(new GenericSubclass<B>(new B()));
  invokeSuperMethod3(new GenericSubclass<C>(new C()));
  invokeSuperGetter1(new GenericSubclass<A>(new A()));
  invokeSuperGetter2(new GenericSubclass<B>(new B()));
  invokeSuperGetter3(new GenericSubclass<C>(new C()));
  accessSuperField1(new GenericSubclass<A>(new A()));
  accessSuperField2(new GenericSubclass<B>(new B()));
  accessSuperField3(new GenericSubclass<C>(new C()));

  invokeFunctionTypedInstanceMethod1(new GenericClass<A>(new A()));
  invokeFunctionTypedInstanceMethod2(new GenericClass<B>(new B()));
  invokeFunctionTypedInstanceMethod3(new GenericClass<C>(new C()));
  invokeFunctionTypedInstanceGetter1(new GenericClass<A>(new A()));
  invokeFunctionTypedInstanceGetter2(new GenericClass<B>(new B()));
  invokeFunctionTypedInstanceGetter3(new GenericClass<C>(new C()));
  invokeFunctionTypedInstanceField1(new GenericClass<A>(new A()));
  invokeFunctionTypedInstanceField2(new GenericClass<B>(new B()));
  invokeFunctionTypedInstanceField3(new GenericClass<C>(new C()));

  invokeFunctionTypedSuperMethod1(new GenericSubclass<A>(new A()));
  invokeFunctionTypedSuperMethod2(new GenericSubclass<B>(new B()));
  invokeFunctionTypedSuperMethod3(new GenericSubclass<C>(new C()));
  invokeFunctionTypedSuperGetter1(new GenericSubclass<A>(new A()));
  invokeFunctionTypedSuperGetter2(new GenericSubclass<B>(new B()));
  invokeFunctionTypedSuperGetter3(new GenericSubclass<C>(new C()));
  invokeFunctionTypedSuperField1(new GenericSubclass<A>(new A()));
  invokeFunctionTypedSuperField2(new GenericSubclass<B>(new B()));
  invokeFunctionTypedSuperField3(new GenericSubclass<C>(new C()));
}

/*element: genericMethod:Union([exact=C], [subclass=A])*/
T genericMethod<T>(T /*Union([exact=C], [subclass=A])*/ t) => t;

/*element: functionTypedGenericMethod:[subclass=Closure]*/
T Function() functionTypedGenericMethod<T>(
        T /*Union([exact=C], [subclass=A])*/ t) =>
    /*Union([exact=C], [subclass=A])*/ () => t;

/*element: Class.:[exact=Class]*/
class Class {
  /*element: Class.genericMethod:Union([exact=C], [subclass=A])*/
  T genericMethod<T>(T /*Union([exact=C], [subclass=A])*/ t) => t;

  /*element: Class.functionTypedGenericMethod:[subclass=Closure]*/
  T Function() functionTypedGenericMethod<T>(
          T /*Union([exact=C], [subclass=A])*/ t) =>
      /*Union([exact=C], [subclass=A])*/ () => t;
}

/*element: Subclass.:[exact=Subclass]*/
class Subclass extends Class {
  /*kernel.element: Subclass.superMethod1:Union([exact=C], [subclass=A])*/
  /*strong.element: Subclass.superMethod1:[subclass=A]*/
  superMethod1() {
    return super.genericMethod<A>(new A());
  }

  /*kernel.element: Subclass.superMethod2:Union([exact=C], [subclass=A])*/
  /*strong.element: Subclass.superMethod2:[exact=B]*/
  superMethod2() {
    return super.genericMethod<B>(new B());
  }

  /*kernel.element: Subclass.superMethod3:Union([exact=C], [subclass=A])*/
  /*strong.element: Subclass.superMethod3:[exact=C]*/
  superMethod3() {
    return super.genericMethod<C>(new C());
  }

  /*kernel.element: Subclass.functionTypedSuperMethod1:[null|subclass=Object]*/
  /*strong.element: Subclass.functionTypedSuperMethod1:[null|subclass=A]*/
  functionTypedSuperMethod1() {
    return super.functionTypedGenericMethod<A>(new A())();
  }

  /*kernel.element: Subclass.functionTypedSuperMethod2:[null|subclass=Object]*/
  /*strong.element: Subclass.functionTypedSuperMethod2:[null|exact=B]*/
  functionTypedSuperMethod2() {
    return super.functionTypedGenericMethod<B>(new B())();
  }

  /*kernel.element: Subclass.functionTypedSuperMethod3:[null|subclass=Object]*/
  /*strong.element: Subclass.functionTypedSuperMethod3:[null|exact=C]*/
  functionTypedSuperMethod3() {
    return super.functionTypedGenericMethod<C>(new C())();
  }
}

/*kernel.element: invokeGenericMethod1:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericMethod1:[subclass=A]*/
invokeGenericMethod1(A /*[exact=A]*/ a) => genericMethod<A>(a);

/*kernel.element: invokeGenericMethod2:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericMethod2:[exact=B]*/
invokeGenericMethod2(B /*[exact=B]*/ b) => genericMethod<B>(b);

/*kernel.element: invokeGenericMethod3:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericMethod3:[exact=C]*/
invokeGenericMethod3(C /*[exact=C]*/ c) => genericMethod<C>(c);

/*kernel.element: invokeGenericInstanceMethod1:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericInstanceMethod1:[subclass=A]*/
invokeGenericInstanceMethod1() =>
    new Class(). /*invoke: [exact=Class]*/ genericMethod<A>(new A());

/*kernel.element: invokeGenericInstanceMethod2:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericInstanceMethod2:[exact=B]*/
invokeGenericInstanceMethod2() =>
    new Class(). /*invoke: [exact=Class]*/ genericMethod<B>(new B());

/*kernel.element: invokeGenericInstanceMethod3:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericInstanceMethod3:[exact=C]*/
invokeGenericInstanceMethod3() =>
    new Class(). /*invoke: [exact=Class]*/ genericMethod<C>(new C());

/*kernel.element: invokeGenericSuperMethod1:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericSuperMethod1:[subclass=A]*/
invokeGenericSuperMethod1() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ superMethod1();

/*kernel.element: invokeGenericSuperMethod2:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericSuperMethod2:[exact=B]*/
invokeGenericSuperMethod2() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ superMethod2();

/*kernel.element: invokeGenericSuperMethod3:Union([exact=C], [subclass=A])*/
/*strong.element: invokeGenericSuperMethod3:[exact=C]*/
invokeGenericSuperMethod3() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ superMethod3();

/*kernel.element: invokeFunctionTypedGenericMethod1:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericMethod1:[null|subclass=A]*/
invokeFunctionTypedGenericMethod1(A /*[exact=A]*/ a) =>
    functionTypedGenericMethod<A>(a)();

/*kernel.element: invokeFunctionTypedGenericMethod2:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericMethod2:[null|exact=B]*/
invokeFunctionTypedGenericMethod2(B /*[exact=B]*/ b) =>
    functionTypedGenericMethod<B>(b)();

/*kernel.element: invokeFunctionTypedGenericMethod3:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericMethod3:[null|exact=C]*/
invokeFunctionTypedGenericMethod3(C /*[exact=C]*/ c) =>
    functionTypedGenericMethod<C>(c)();

/*kernel.element: invokeFunctionTypedGenericInstanceMethod1:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericInstanceMethod1:[null|subclass=A]*/
invokeFunctionTypedGenericInstanceMethod1() => new Class()
    . /*invoke: [exact=Class]*/ functionTypedGenericMethod<A>(new A())();

/*kernel.element: invokeFunctionTypedGenericInstanceMethod2:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericInstanceMethod2:[null|exact=B]*/
invokeFunctionTypedGenericInstanceMethod2() => new Class()
    . /*invoke: [exact=Class]*/ functionTypedGenericMethod<B>(new B())();

/*kernel.element: invokeFunctionTypedGenericInstanceMethod3:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericInstanceMethod3:[null|exact=C]*/
invokeFunctionTypedGenericInstanceMethod3() => new Class()
    . /*invoke: [exact=Class]*/ functionTypedGenericMethod<C>(new C())();

/*kernel.element: invokeFunctionTypedGenericSuperMethod1:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericSuperMethod1:[null|subclass=A]*/
invokeFunctionTypedGenericSuperMethod1() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ functionTypedSuperMethod1();

/*kernel.element: invokeFunctionTypedGenericSuperMethod2:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericSuperMethod2:[null|exact=B]*/
invokeFunctionTypedGenericSuperMethod2() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ functionTypedSuperMethod2();

/*kernel.element: invokeFunctionTypedGenericSuperMethod3:[null|subclass=Object]*/
/*strong.element: invokeFunctionTypedGenericSuperMethod3:[null|exact=C]*/
invokeFunctionTypedGenericSuperMethod3() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ functionTypedSuperMethod3();

/*element: invokeGenericMethods:[null]*/
invokeGenericMethods() {
  invokeGenericMethod1(new A());
  invokeGenericMethod2(new B());
  invokeGenericMethod3(new C());
  invokeGenericInstanceMethod1();
  invokeGenericInstanceMethod2();
  invokeGenericInstanceMethod3();
  invokeGenericSuperMethod1();
  invokeGenericSuperMethod2();
  invokeGenericSuperMethod3();

  invokeFunctionTypedGenericMethod1(new A());
  invokeFunctionTypedGenericMethod2(new B());
  invokeFunctionTypedGenericMethod3(new C());
  invokeFunctionTypedGenericInstanceMethod1();
  invokeFunctionTypedGenericInstanceMethod2();
  invokeFunctionTypedGenericInstanceMethod3();
  invokeFunctionTypedGenericSuperMethod1();
  invokeFunctionTypedGenericSuperMethod2();
  invokeFunctionTypedGenericSuperMethod3();
}
