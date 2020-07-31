// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/*member: A.:[exact=A]*/
class A {}

/*member: B.:[exact=B]*/
class B extends A {}

/*member: C.:[exact=C]*/
class C {}

/*member: main:[null]*/
main() {
  invokeFunctions();
  invokeGenericClasses();
  invokeGenericMethods();
}

/*member: invokeFunction1:[null|subclass=A]*/
invokeFunction1(A Function() /*[subclass=Closure]*/ f) {
  return f();
}

/*member: invokeFunction2:[null|exact=B]*/
invokeFunction2(B Function() /*[subclass=Closure]*/ f) {
  return f();
}

/*member: invokeFunction3:[null|exact=C]*/
invokeFunction3(C Function() /*[subclass=Closure]*/ f) {
  return f();
}

/*member: genericFunction:[null|subclass=Object]*/
T genericFunction<T>(T Function() /*[subclass=Closure]*/ f) => f();

/*member: invokeGenericFunction1:[null|subclass=A]*/
invokeGenericFunction1() {
  return genericFunction<A>(/*[exact=A]*/ () => new A());
}

/*member: invokeGenericFunction2:[null|exact=B]*/
invokeGenericFunction2() {
  return genericFunction<B>(/*[exact=B]*/ () => new B());
}

/*member: invokeGenericFunction3:[null|exact=C]*/
invokeGenericFunction3() {
  return genericFunction<C>(/*[exact=C]*/ () => new C());
}

/*member: invokeGenericLocalFunction1:[null|subclass=A]*/
invokeGenericLocalFunction1() {
  /*[null|subclass=Object]*/
  T local<T>(T Function() /*[subclass=Closure]*/ f) => f();
  return local<A>(/*[exact=A]*/ () => new A());
}

/*member: invokeGenericLocalFunction2:[null|exact=B]*/
invokeGenericLocalFunction2() {
  /*[null|subclass=Object]*/
  T local<T>(T Function() /*[subclass=Closure]*/ f) => f();
  return local<B>(/*[exact=B]*/ () => new B());
}

/*member: invokeGenericLocalFunction3:[null|exact=C]*/
invokeGenericLocalFunction3() {
  /*[null|subclass=Object]*/
  T local<T>(T Function() /*[subclass=Closure]*/ f) => f();
  return local<C>(/*[exact=C]*/ () => new C());
}

/*member: invokeFunctions:[null]*/
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
  /*member: GenericClass.field:Union([exact=C], [subclass=A])*/
  final T field;

  /*member: GenericClass.functionTypedField:[subclass=Closure]*/
  final T Function() functionTypedField;

  /*member: GenericClass.:[exact=GenericClass]*/
  GenericClass(this. /*Union([exact=C], [subclass=A])*/ field)
      : functionTypedField = (/*Union([exact=C], [subclass=A])*/ () => field);

  /*member: GenericClass.getter:Union([exact=C], [subclass=A])*/
  T get getter => /*[subclass=GenericClass]*/ field;

  /*member: GenericClass.functionTypedGetter:[subclass=Closure]*/
  T Function()
      get functionTypedGetter => /*[subclass=GenericClass]*/ functionTypedField;

  /*member: GenericClass.method:Union([exact=C], [subclass=A])*/
  T method() => /*[subclass=GenericClass]*/ field;

  /*member: GenericClass.functionTypedMethod:[subclass=Closure]*/
  T Function()
      functionTypedMethod() => /*[subclass=GenericClass]*/ functionTypedField;
}

class GenericSubclass<T> extends GenericClass<T> {
  /*member: GenericSubclass.:[exact=GenericSubclass]*/
  GenericSubclass(T /*Union([exact=C], [subclass=A])*/ field) : super(field);

  /*member: GenericSubclass.superField:Union([exact=C], [subclass=A])*/
  superField() => super.field;

  /*member: GenericSubclass.superGetter:Union([exact=C], [subclass=A])*/
  superGetter() => super.getter;

  /*member: GenericSubclass.superMethod:Union([exact=C], [subclass=A])*/
  superMethod() => super.method();

  /*member: GenericSubclass.superFieldInvoke:[null|subclass=Object]*/
  superFieldInvoke() => super.functionTypedField();

  /*member: GenericSubclass.superGetterInvoke:[null|subclass=Object]*/
  superGetterInvoke() => super.functionTypedGetter();

  /*member: GenericSubclass.superMethodInvoke:[null|subclass=Object]*/
  superMethodInvoke() => super.functionTypedMethod()();
}

/*member: invokeInstanceMethod1:[subclass=A]*/
invokeInstanceMethod1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ method();

/*member: invokeInstanceMethod2:[exact=B]*/
invokeInstanceMethod2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ method();

/*member: invokeInstanceMethod3:[exact=C]*/
invokeInstanceMethod3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ method();

/*member: invokeInstanceGetter1:[subclass=A]*/
invokeInstanceGetter1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ getter;

/*member: invokeInstanceGetter2:[exact=B]*/
invokeInstanceGetter2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ getter;

/*member: invokeInstanceGetter3:[exact=C]*/
invokeInstanceGetter3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ getter;

/*member: accessInstanceField1:[subclass=A]*/
accessInstanceField1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ field;

/*member: accessInstanceField2:[exact=B]*/
accessInstanceField2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ field;

/*member: accessInstanceField3:[exact=C]*/
accessInstanceField3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*[exact=GenericClass]*/ field;

/*member: invokeSuperMethod1:Union([exact=C], [subclass=A])*/
invokeSuperMethod1(GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethod();

/*member: invokeSuperMethod2:Union([exact=C], [subclass=A])*/
invokeSuperMethod2(GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethod();

/*member: invokeSuperMethod3:Union([exact=C], [subclass=A])*/
invokeSuperMethod3(GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethod();

/*member: invokeSuperGetter1:Union([exact=C], [subclass=A])*/
invokeSuperGetter1(GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetter();

/*member: invokeSuperGetter2:Union([exact=C], [subclass=A])*/
invokeSuperGetter2(GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetter();

/*member: invokeSuperGetter3:Union([exact=C], [subclass=A])*/
invokeSuperGetter3(GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetter();

/*member: accessSuperField1:Union([exact=C], [subclass=A])*/
accessSuperField1(GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superField();

/*member: accessSuperField2:Union([exact=C], [subclass=A])*/
accessSuperField2(GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superField();

/*member: accessSuperField3:Union([exact=C], [subclass=A])*/
accessSuperField3(GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superField();

/*member: invokeFunctionTypedInstanceMethod1:[null|subclass=A]*/
invokeFunctionTypedInstanceMethod1(
        GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod2:[null|exact=B]*/
invokeFunctionTypedInstanceMethod2(
        GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod3:[null|exact=C]*/
invokeFunctionTypedInstanceMethod3(
        GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c. /*invoke: [exact=GenericClass]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceGetter1:[null|subclass=A]*/
invokeFunctionTypedInstanceGetter1(
        GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c.functionTypedGetter /*invoke: [exact=GenericClass]*/ ();

/*member: invokeFunctionTypedInstanceGetter2:[null|exact=B]*/
invokeFunctionTypedInstanceGetter2(
        GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c.functionTypedGetter /*invoke: [exact=GenericClass]*/ ();

/*member: invokeFunctionTypedInstanceGetter3:[null|exact=C]*/
invokeFunctionTypedInstanceGetter3(
        GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c.functionTypedGetter /*invoke: [exact=GenericClass]*/ ();

/*member: invokeFunctionTypedInstanceField1:[null|subclass=A]*/
invokeFunctionTypedInstanceField1(GenericClass<A> /*[exact=GenericClass]*/ c) =>
    c.functionTypedField /*invoke: [exact=GenericClass]*/ ();

/*member: invokeFunctionTypedInstanceField2:[null|exact=B]*/
invokeFunctionTypedInstanceField2(GenericClass<B> /*[exact=GenericClass]*/ c) =>
    c.functionTypedField /*invoke: [exact=GenericClass]*/ ();

/*member: invokeFunctionTypedInstanceField3:[null|exact=C]*/
invokeFunctionTypedInstanceField3(GenericClass<C> /*[exact=GenericClass]*/ c) =>
    c.functionTypedField /*invoke: [exact=GenericClass]*/ ();

/*member: invokeFunctionTypedSuperMethod1:[null|subclass=Object]*/
invokeFunctionTypedSuperMethod1(
        GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod2:[null|subclass=Object]*/
invokeFunctionTypedSuperMethod2(
        GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod3:[null|subclass=Object]*/
invokeFunctionTypedSuperMethod3(
        GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperGetter1:[null|subclass=Object]*/
invokeFunctionTypedSuperGetter1(
        GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter2:[null|subclass=Object]*/
invokeFunctionTypedSuperGetter2(
        GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter3:[null|subclass=Object]*/
invokeFunctionTypedSuperGetter3(
        GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperField1:[null|subclass=Object]*/
invokeFunctionTypedSuperField1(
        GenericSubclass<A> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField2:[null|subclass=Object]*/
invokeFunctionTypedSuperField2(
        GenericSubclass<B> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField3:[null|subclass=Object]*/
invokeFunctionTypedSuperField3(
        GenericSubclass<C> /*[exact=GenericSubclass]*/ c) =>
    c. /*invoke: [exact=GenericSubclass]*/ superFieldInvoke();

/*member: invokeGenericClasses:[null]*/
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

/*member: genericMethod:Union([exact=C], [subclass=A])*/
T genericMethod<T>(T /*Union([exact=C], [subclass=A])*/ t) => t;

/*member: functionTypedGenericMethod:[subclass=Closure]*/
T Function() functionTypedGenericMethod<T>(
        T /*Union([exact=C], [subclass=A])*/ t) =>
    /*Union([exact=C], [subclass=A])*/ () => t;

/*member: Class.:[exact=Class]*/
class Class {
  /*member: Class.genericMethod:Union([exact=C], [subclass=A])*/
  T genericMethod<T>(T /*Union([exact=C], [subclass=A])*/ t) => t;

  /*member: Class.functionTypedGenericMethod:[subclass=Closure]*/
  T Function() functionTypedGenericMethod<T>(
          T /*Union([exact=C], [subclass=A])*/ t) =>
      /*Union([exact=C], [subclass=A])*/ () => t;
}

/*member: Subclass.:[exact=Subclass]*/
class Subclass extends Class {
  /*member: Subclass.superMethod1:[subclass=A]*/
  superMethod1() {
    return super.genericMethod<A>(new A());
  }

  /*member: Subclass.superMethod2:[exact=B]*/
  superMethod2() {
    return super.genericMethod<B>(new B());
  }

  /*member: Subclass.superMethod3:[exact=C]*/
  superMethod3() {
    return super.genericMethod<C>(new C());
  }

  /*member: Subclass.functionTypedSuperMethod1:[null|subclass=A]*/
  functionTypedSuperMethod1() {
    return super.functionTypedGenericMethod<A>(new A())();
  }

  /*member: Subclass.functionTypedSuperMethod2:[null|exact=B]*/
  functionTypedSuperMethod2() {
    return super.functionTypedGenericMethod<B>(new B())();
  }

  /*member: Subclass.functionTypedSuperMethod3:[null|exact=C]*/
  functionTypedSuperMethod3() {
    return super.functionTypedGenericMethod<C>(new C())();
  }
}

/*member: invokeGenericMethod1:[subclass=A]*/
invokeGenericMethod1(A /*[exact=A]*/ a) => genericMethod<A>(a);

/*member: invokeGenericMethod2:[exact=B]*/
invokeGenericMethod2(B /*[exact=B]*/ b) => genericMethod<B>(b);

/*member: invokeGenericMethod3:[exact=C]*/
invokeGenericMethod3(C /*[exact=C]*/ c) => genericMethod<C>(c);

/*member: invokeGenericInstanceMethod1:[subclass=A]*/
invokeGenericInstanceMethod1() =>
    new Class(). /*invoke: [exact=Class]*/ genericMethod<A>(new A());

/*member: invokeGenericInstanceMethod2:[exact=B]*/
invokeGenericInstanceMethod2() =>
    new Class(). /*invoke: [exact=Class]*/ genericMethod<B>(new B());

/*member: invokeGenericInstanceMethod3:[exact=C]*/
invokeGenericInstanceMethod3() =>
    new Class(). /*invoke: [exact=Class]*/ genericMethod<C>(new C());

/*member: invokeGenericSuperMethod1:[subclass=A]*/
invokeGenericSuperMethod1() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ superMethod1();

/*member: invokeGenericSuperMethod2:[exact=B]*/
invokeGenericSuperMethod2() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ superMethod2();

/*member: invokeGenericSuperMethod3:[exact=C]*/
invokeGenericSuperMethod3() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ superMethod3();

/*member: invokeFunctionTypedGenericMethod1:[null|subclass=A]*/
invokeFunctionTypedGenericMethod1(A /*[exact=A]*/ a) =>
    functionTypedGenericMethod<A>(a)();

/*member: invokeFunctionTypedGenericMethod2:[null|exact=B]*/
invokeFunctionTypedGenericMethod2(B /*[exact=B]*/ b) =>
    functionTypedGenericMethod<B>(b)();

/*member: invokeFunctionTypedGenericMethod3:[null|exact=C]*/
invokeFunctionTypedGenericMethod3(C /*[exact=C]*/ c) =>
    functionTypedGenericMethod<C>(c)();

/*member: invokeFunctionTypedGenericInstanceMethod1:[null|subclass=A]*/
invokeFunctionTypedGenericInstanceMethod1() => new Class()
    . /*invoke: [exact=Class]*/ functionTypedGenericMethod<A>(new A())();

/*member: invokeFunctionTypedGenericInstanceMethod2:[null|exact=B]*/
invokeFunctionTypedGenericInstanceMethod2() => new Class()
    . /*invoke: [exact=Class]*/ functionTypedGenericMethod<B>(new B())();

/*member: invokeFunctionTypedGenericInstanceMethod3:[null|exact=C]*/
invokeFunctionTypedGenericInstanceMethod3() => new Class()
    . /*invoke: [exact=Class]*/ functionTypedGenericMethod<C>(new C())();

/*member: invokeFunctionTypedGenericSuperMethod1:[null|subclass=A]*/
invokeFunctionTypedGenericSuperMethod1() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ functionTypedSuperMethod1();

/*member: invokeFunctionTypedGenericSuperMethod2:[null|exact=B]*/
invokeFunctionTypedGenericSuperMethod2() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ functionTypedSuperMethod2();

/*member: invokeFunctionTypedGenericSuperMethod3:[null|exact=C]*/
invokeFunctionTypedGenericSuperMethod3() =>
    new Subclass(). /*invoke: [exact=Subclass]*/ functionTypedSuperMethod3();

/*member: invokeGenericMethods:[null]*/
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
