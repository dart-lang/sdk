// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}{O}{N}]*/
class A {}

/*member: B.:[exact=B|powerset={N}{O}{N}]*/
class B extends A {}

/*member: C.:[exact=C|powerset={N}{O}{N}]*/
class C {}

/*member: main:[null|powerset={null}]*/
main() {
  invokeFunctions();
  invokeGenericClasses();
  invokeGenericMethods();
}

/*member: invokeFunction1:[subclass=A|powerset={N}{O}{N}]*/
invokeFunction1(A Function() /*[subclass=Closure|powerset={N}{O}{N}]*/ f) {
  return f();
}

/*member: invokeFunction2:[exact=B|powerset={N}{O}{N}]*/
invokeFunction2(B Function() /*[subclass=Closure|powerset={N}{O}{N}]*/ f) {
  return f();
}

/*member: invokeFunction3:[exact=C|powerset={N}{O}{N}]*/
invokeFunction3(C Function() /*[subclass=Closure|powerset={N}{O}{N}]*/ f) {
  return f();
}

/*member: genericFunction:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
T genericFunction<T>(
  T Function() /*[subclass=Closure|powerset={N}{O}{N}]*/ f,
) => f();

/*member: invokeGenericFunction1:[subclass=A|powerset={N}{O}{N}]*/
invokeGenericFunction1() {
  return genericFunction<A>(/*[exact=A|powerset={N}{O}{N}]*/ () => A());
}

/*member: invokeGenericFunction2:[exact=B|powerset={N}{O}{N}]*/
invokeGenericFunction2() {
  return genericFunction<B>(/*[exact=B|powerset={N}{O}{N}]*/ () => B());
}

/*member: invokeGenericFunction3:[exact=C|powerset={N}{O}{N}]*/
invokeGenericFunction3() {
  return genericFunction<C>(/*[exact=C|powerset={N}{O}{N}]*/ () => C());
}

/*member: invokeGenericLocalFunction1:[subclass=A|powerset={N}{O}{N}]*/
invokeGenericLocalFunction1() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();
  return local<A>(/*[exact=A|powerset={N}{O}{N}]*/ () => A());
}

/*member: invokeGenericLocalFunction2:[exact=B|powerset={N}{O}{N}]*/
invokeGenericLocalFunction2() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();
  return local<B>(/*[exact=B|powerset={N}{O}{N}]*/ () => B());
}

/*member: invokeGenericLocalFunction3:[exact=C|powerset={N}{O}{N}]*/
invokeGenericLocalFunction3() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}{O}{N}]*/ f) => f();
  return local<C>(/*[exact=C|powerset={N}{O}{N}]*/ () => C());
}

/*member: invokeFunctions:[null|powerset={null}]*/
invokeFunctions() {
  invokeFunction1(/*[exact=A|powerset={N}{O}{N}]*/ () => A());
  invokeFunction2(/*[exact=B|powerset={N}{O}{N}]*/ () => B());
  invokeFunction3(/*[exact=C|powerset={N}{O}{N}]*/ () => C());
  invokeGenericFunction1();
  invokeGenericFunction2();
  invokeGenericFunction3();
  invokeGenericLocalFunction1();
  invokeGenericLocalFunction2();
  invokeGenericLocalFunction3();
}

class GenericClass<T> {
  /*member: GenericClass.field:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  final T field;

  /*member: GenericClass.functionTypedField:[subclass=Closure|powerset={N}{O}{N}]*/
  final T Function() functionTypedField;

  /*member: GenericClass.:[exact=GenericClass|powerset={N}{O}{N}]*/
  GenericClass(
    this. /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ field,
  ) : functionTypedField =
          ( /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ () =>
              field);

  /*member: GenericClass.getter:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  T get getter => /*[subclass=GenericClass|powerset={N}{O}{N}]*/ field;

  /*member: GenericClass.functionTypedGetter:[subclass=Closure|powerset={N}{O}{N}]*/
  T Function()
  get functionTypedGetter => /*[subclass=GenericClass|powerset={N}{O}{N}]*/
      functionTypedField;

  /*member: GenericClass.method:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  T method() => /*[subclass=GenericClass|powerset={N}{O}{N}]*/ field;

  /*member: GenericClass.functionTypedMethod:[subclass=Closure|powerset={N}{O}{N}]*/
  T Function()
  functionTypedMethod() => /*[subclass=GenericClass|powerset={N}{O}{N}]*/
      functionTypedField;
}

class GenericSubclass<T> extends GenericClass<T> {
  /*member: GenericSubclass.:[exact=GenericSubclass|powerset={N}{O}{N}]*/
  GenericSubclass(
    T /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
    field,
  ) : super(field);

  /*member: GenericSubclass.superField:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  superField() => super.field;

  /*member: GenericSubclass.superGetter:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  superGetter() => super.getter;

  /*member: GenericSubclass.superMethod:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  superMethod() => super.method();

  /*member: GenericSubclass.superFieldInvoke:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  superFieldInvoke() => super.functionTypedField();

  /*member: GenericSubclass.superGetterInvoke:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  superGetterInvoke() => super.functionTypedGetter();

  /*member: GenericSubclass.superMethodInvoke:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
  superMethodInvoke() => super.functionTypedMethod()();
}

/*member: invokeInstanceMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeInstanceMethod1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ method();

/*member: invokeInstanceMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeInstanceMethod2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ method();

/*member: invokeInstanceMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeInstanceMethod3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ method();

/*member: invokeInstanceGetter1:[subclass=A|powerset={N}{O}{N}]*/
invokeInstanceGetter1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}{N}]*/ getter;

/*member: invokeInstanceGetter2:[exact=B|powerset={N}{O}{N}]*/
invokeInstanceGetter2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}{N}]*/ getter;

/*member: invokeInstanceGetter3:[exact=C|powerset={N}{O}{N}]*/
invokeInstanceGetter3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}{N}]*/ getter;

/*member: accessInstanceField1:[subclass=A|powerset={N}{O}{N}]*/
accessInstanceField1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}{N}]*/ field;

/*member: accessInstanceField2:[exact=B|powerset={N}{O}{N}]*/
accessInstanceField2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}{N}]*/ field;

/*member: accessInstanceField3:[exact=C|powerset={N}{O}{N}]*/
accessInstanceField3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}{N}]*/ field;

/*member: invokeSuperMethod1:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
invokeSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superMethod();

/*member: invokeSuperMethod2:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
invokeSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superMethod();

/*member: invokeSuperMethod3:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
invokeSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superMethod();

/*member: invokeSuperGetter1:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
invokeSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superGetter();

/*member: invokeSuperGetter2:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
invokeSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superGetter();

/*member: invokeSuperGetter3:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
invokeSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superGetter();

/*member: accessSuperField1:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
accessSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superField();

/*member: accessSuperField2:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
accessSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superField();

/*member: accessSuperField3:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
accessSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superField();

/*member: invokeFunctionTypedInstanceMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceMethod1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceMethod2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceMethod3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceGetter1:[subclass=A|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceGetter1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c
    .functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ ();

/*member: invokeFunctionTypedInstanceGetter2:[exact=B|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceGetter2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c
    .functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ ();

/*member: invokeFunctionTypedInstanceGetter3:[exact=C|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceGetter3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) => c
    .functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ ();

/*member: invokeFunctionTypedInstanceField1:[subclass=A|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceField1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) =>
    c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ ();

/*member: invokeFunctionTypedInstanceField2:[exact=B|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceField2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) =>
    c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ ();

/*member: invokeFunctionTypedInstanceField3:[exact=C|powerset={N}{O}{N}]*/
invokeFunctionTypedInstanceField3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}{N}]*/ c,
) =>
    c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}{O}{N}]*/ ();

/*member: invokeFunctionTypedSuperMethod1:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod2:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod3:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperGetter1:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter2:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter3:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperField1:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField2:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField3:[null|subclass=Object|powerset={null}{IN}{GFUO}{IMN}]*/
invokeFunctionTypedSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}{N}]*/ c,
) => c
    . /*invoke: [exact=GenericSubclass|powerset={N}{O}{N}]*/ superFieldInvoke();

/*member: invokeGenericClasses:[null|powerset={null}]*/
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

/*member: genericMethod:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
T genericMethod<T>(
  T /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  t,
) => t;

/*member: functionTypedGenericMethod:[subclass=Closure|powerset={N}{O}{N}]*/
T Function() functionTypedGenericMethod<T>(
  T /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  t,
) =>
    /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ () =>
        t;

/*member: Class.:[exact=Class|powerset={N}{O}{N}]*/
class Class {
  /*member: Class.genericMethod:Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
  T genericMethod<T>(
    T /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
    t,
  ) => t;

  /*member: Class.functionTypedGenericMethod:[subclass=Closure|powerset={N}{O}{N}]*/
  T Function() functionTypedGenericMethod<T>(
    T /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/
    t,
  ) =>
      /*Union([exact=C|powerset={N}{O}{N}], [subclass=A|powerset={N}{O}{N}], powerset: {N}{O}{N})*/ () =>
          t;
}

/*member: Subclass.:[exact=Subclass|powerset={N}{O}{N}]*/
class Subclass extends Class {
  /*member: Subclass.superMethod1:[subclass=A|powerset={N}{O}{N}]*/
  superMethod1() {
    return super.genericMethod<A>(new A());
  }

  /*member: Subclass.superMethod2:[exact=B|powerset={N}{O}{N}]*/
  superMethod2() {
    return super.genericMethod<B>(new B());
  }

  /*member: Subclass.superMethod3:[exact=C|powerset={N}{O}{N}]*/
  superMethod3() {
    return super.genericMethod<C>(new C());
  }

  /*member: Subclass.functionTypedSuperMethod1:[subclass=A|powerset={N}{O}{N}]*/
  functionTypedSuperMethod1() {
    return super.functionTypedGenericMethod<A>(new A())();
  }

  /*member: Subclass.functionTypedSuperMethod2:[exact=B|powerset={N}{O}{N}]*/
  functionTypedSuperMethod2() {
    return super.functionTypedGenericMethod<B>(new B())();
  }

  /*member: Subclass.functionTypedSuperMethod3:[exact=C|powerset={N}{O}{N}]*/
  functionTypedSuperMethod3() {
    return super.functionTypedGenericMethod<C>(new C())();
  }
}

/*member: invokeGenericMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeGenericMethod1(A /*[exact=A|powerset={N}{O}{N}]*/ a) =>
    genericMethod<A>(a);

/*member: invokeGenericMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeGenericMethod2(B /*[exact=B|powerset={N}{O}{N}]*/ b) =>
    genericMethod<B>(b);

/*member: invokeGenericMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeGenericMethod3(C /*[exact=C|powerset={N}{O}{N}]*/ c) =>
    genericMethod<C>(c);

/*member: invokeGenericInstanceMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeGenericInstanceMethod1() => Class()
    . /*invoke: [exact=Class|powerset={N}{O}{N}]*/ genericMethod<A>(new A());

/*member: invokeGenericInstanceMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeGenericInstanceMethod2() => Class()
    . /*invoke: [exact=Class|powerset={N}{O}{N}]*/ genericMethod<B>(new B());

/*member: invokeGenericInstanceMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeGenericInstanceMethod3() => Class()
    . /*invoke: [exact=Class|powerset={N}{O}{N}]*/ genericMethod<C>(new C());

/*member: invokeGenericSuperMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeGenericSuperMethod1() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}{O}{N}]*/ superMethod1();

/*member: invokeGenericSuperMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeGenericSuperMethod2() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}{O}{N}]*/ superMethod2();

/*member: invokeGenericSuperMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeGenericSuperMethod3() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}{O}{N}]*/ superMethod3();

/*member: invokeFunctionTypedGenericMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericMethod1(A /*[exact=A|powerset={N}{O}{N}]*/ a) =>
    functionTypedGenericMethod<A>(a)();

/*member: invokeFunctionTypedGenericMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericMethod2(B /*[exact=B|powerset={N}{O}{N}]*/ b) =>
    functionTypedGenericMethod<B>(b)();

/*member: invokeFunctionTypedGenericMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericMethod3(C /*[exact=C|powerset={N}{O}{N}]*/ c) =>
    functionTypedGenericMethod<C>(c)();

/*member: invokeFunctionTypedGenericInstanceMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericInstanceMethod1() => Class()
    . /*invoke: [exact=Class|powerset={N}{O}{N}]*/ functionTypedGenericMethod<
      A
    >(new A())();

/*member: invokeFunctionTypedGenericInstanceMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericInstanceMethod2() => Class()
    . /*invoke: [exact=Class|powerset={N}{O}{N}]*/ functionTypedGenericMethod<
      B
    >(new B())();

/*member: invokeFunctionTypedGenericInstanceMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericInstanceMethod3() => Class()
    . /*invoke: [exact=Class|powerset={N}{O}{N}]*/ functionTypedGenericMethod<
      C
    >(new C())();

/*member: invokeFunctionTypedGenericSuperMethod1:[subclass=A|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericSuperMethod1() => Subclass()
    . /*invoke: [exact=Subclass|powerset={N}{O}{N}]*/ functionTypedSuperMethod1();

/*member: invokeFunctionTypedGenericSuperMethod2:[exact=B|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericSuperMethod2() => Subclass()
    . /*invoke: [exact=Subclass|powerset={N}{O}{N}]*/ functionTypedSuperMethod2();

/*member: invokeFunctionTypedGenericSuperMethod3:[exact=C|powerset={N}{O}{N}]*/
invokeFunctionTypedGenericSuperMethod3() => Subclass()
    . /*invoke: [exact=Subclass|powerset={N}{O}{N}]*/ functionTypedSuperMethod3();

/*member: invokeGenericMethods:[null|powerset={null}]*/
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
