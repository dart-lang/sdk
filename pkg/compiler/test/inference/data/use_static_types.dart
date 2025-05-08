// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}{O}]*/
class A {}

/*member: B.:[exact=B|powerset={N}{O}]*/
class B extends A {}

/*member: C.:[exact=C|powerset={N}{O}]*/
class C {}

/*member: main:[null|powerset={null}]*/
main() {
  invokeFunctions();
  invokeGenericClasses();
  invokeGenericMethods();
}

/*member: invokeFunction1:[subclass=A|powerset={N}{O}]*/
invokeFunction1(A Function() /*[subclass=Closure|powerset={N}{O}]*/ f) {
  return f();
}

/*member: invokeFunction2:[exact=B|powerset={N}{O}]*/
invokeFunction2(B Function() /*[subclass=Closure|powerset={N}{O}]*/ f) {
  return f();
}

/*member: invokeFunction3:[exact=C|powerset={N}{O}]*/
invokeFunction3(C Function() /*[subclass=Closure|powerset={N}{O}]*/ f) {
  return f();
}

/*member: genericFunction:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
T genericFunction<T>(T Function() /*[subclass=Closure|powerset={N}{O}]*/ f) => f();

/*member: invokeGenericFunction1:[subclass=A|powerset={N}{O}]*/
invokeGenericFunction1() {
  return genericFunction<A>(/*[exact=A|powerset={N}{O}]*/ () => A());
}

/*member: invokeGenericFunction2:[exact=B|powerset={N}{O}]*/
invokeGenericFunction2() {
  return genericFunction<B>(/*[exact=B|powerset={N}{O}]*/ () => B());
}

/*member: invokeGenericFunction3:[exact=C|powerset={N}{O}]*/
invokeGenericFunction3() {
  return genericFunction<C>(/*[exact=C|powerset={N}{O}]*/ () => C());
}

/*member: invokeGenericLocalFunction1:[subclass=A|powerset={N}{O}]*/
invokeGenericLocalFunction1() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}{O}]*/ f) => f();
  return local<A>(/*[exact=A|powerset={N}{O}]*/ () => A());
}

/*member: invokeGenericLocalFunction2:[exact=B|powerset={N}{O}]*/
invokeGenericLocalFunction2() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}{O}]*/ f) => f();
  return local<B>(/*[exact=B|powerset={N}{O}]*/ () => B());
}

/*member: invokeGenericLocalFunction3:[exact=C|powerset={N}{O}]*/
invokeGenericLocalFunction3() {
  /*[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}{O}]*/ f) => f();
  return local<C>(/*[exact=C|powerset={N}{O}]*/ () => C());
}

/*member: invokeFunctions:[null|powerset={null}]*/
invokeFunctions() {
  invokeFunction1(/*[exact=A|powerset={N}{O}]*/ () => A());
  invokeFunction2(/*[exact=B|powerset={N}{O}]*/ () => B());
  invokeFunction3(/*[exact=C|powerset={N}{O}]*/ () => C());
  invokeGenericFunction1();
  invokeGenericFunction2();
  invokeGenericFunction3();
  invokeGenericLocalFunction1();
  invokeGenericLocalFunction2();
  invokeGenericLocalFunction3();
}

class GenericClass<T> {
  /*member: GenericClass.field:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  final T field;

  /*member: GenericClass.functionTypedField:[subclass=Closure|powerset={N}{O}]*/
  final T Function() functionTypedField;

  /*member: GenericClass.:[exact=GenericClass|powerset={N}{O}]*/
  GenericClass(
    this. /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/ field,
  ) : functionTypedField =
          ( /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/ () =>
              field);

  /*member: GenericClass.getter:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  T get getter => /*[subclass=GenericClass|powerset={N}{O}]*/ field;

  /*member: GenericClass.functionTypedGetter:[subclass=Closure|powerset={N}{O}]*/
  T Function()
  get functionTypedGetter => /*[subclass=GenericClass|powerset={N}{O}]*/
      functionTypedField;

  /*member: GenericClass.method:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  T method() => /*[subclass=GenericClass|powerset={N}{O}]*/ field;

  /*member: GenericClass.functionTypedMethod:[subclass=Closure|powerset={N}{O}]*/
  T Function() functionTypedMethod() => /*[subclass=GenericClass|powerset={N}{O}]*/
      functionTypedField;
}

class GenericSubclass<T> extends GenericClass<T> {
  /*member: GenericSubclass.:[exact=GenericSubclass|powerset={N}{O}]*/
  GenericSubclass(
    T /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
    field,
  ) : super(field);

  /*member: GenericSubclass.superField:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  superField() => super.field;

  /*member: GenericSubclass.superGetter:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  superGetter() => super.getter;

  /*member: GenericSubclass.superMethod:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  superMethod() => super.method();

  /*member: GenericSubclass.superFieldInvoke:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  superFieldInvoke() => super.functionTypedField();

  /*member: GenericSubclass.superGetterInvoke:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  superGetterInvoke() => super.functionTypedGetter();

  /*member: GenericSubclass.superMethodInvoke:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
  superMethodInvoke() => super.functionTypedMethod()();
}

/*member: invokeInstanceMethod1:[subclass=A|powerset={N}{O}]*/
invokeInstanceMethod1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}]*/ method();

/*member: invokeInstanceMethod2:[exact=B|powerset={N}{O}]*/
invokeInstanceMethod2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}]*/ method();

/*member: invokeInstanceMethod3:[exact=C|powerset={N}{O}]*/
invokeInstanceMethod3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}]*/ method();

/*member: invokeInstanceGetter1:[subclass=A|powerset={N}{O}]*/
invokeInstanceGetter1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}]*/ getter;

/*member: invokeInstanceGetter2:[exact=B|powerset={N}{O}]*/
invokeInstanceGetter2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}]*/ getter;

/*member: invokeInstanceGetter3:[exact=C|powerset={N}{O}]*/
invokeInstanceGetter3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}{O}]*/ getter;

/*member: accessInstanceField1:[subclass=A|powerset={N}{O}]*/
accessInstanceField1(GenericClass<A> /*[exact=GenericClass|powerset={N}{O}]*/ c) =>
    c. /*[exact=GenericClass|powerset={N}{O}]*/ field;

/*member: accessInstanceField2:[exact=B|powerset={N}{O}]*/
accessInstanceField2(GenericClass<B> /*[exact=GenericClass|powerset={N}{O}]*/ c) =>
    c. /*[exact=GenericClass|powerset={N}{O}]*/ field;

/*member: accessInstanceField3:[exact=C|powerset={N}{O}]*/
accessInstanceField3(GenericClass<C> /*[exact=GenericClass|powerset={N}{O}]*/ c) =>
    c. /*[exact=GenericClass|powerset={N}{O}]*/ field;

/*member: invokeSuperMethod1:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
invokeSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superMethod();

/*member: invokeSuperMethod2:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
invokeSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superMethod();

/*member: invokeSuperMethod3:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
invokeSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superMethod();

/*member: invokeSuperGetter1:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
invokeSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superGetter();

/*member: invokeSuperGetter2:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
invokeSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superGetter();

/*member: invokeSuperGetter3:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
invokeSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superGetter();

/*member: accessSuperField1:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
accessSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superField();

/*member: accessSuperField2:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
accessSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superField();

/*member: accessSuperField3:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
accessSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superField();

/*member: invokeFunctionTypedInstanceMethod1:[subclass=A|powerset={N}{O}]*/
invokeFunctionTypedInstanceMethod1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod2:[exact=B|powerset={N}{O}]*/
invokeFunctionTypedInstanceMethod2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod3:[exact=C|powerset={N}{O}]*/
invokeFunctionTypedInstanceMethod3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}{O}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceGetter1:[subclass=A|powerset={N}{O}]*/
invokeFunctionTypedInstanceGetter1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}{O}]*/ ();

/*member: invokeFunctionTypedInstanceGetter2:[exact=B|powerset={N}{O}]*/
invokeFunctionTypedInstanceGetter2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}{O}]*/ ();

/*member: invokeFunctionTypedInstanceGetter3:[exact=C|powerset={N}{O}]*/
invokeFunctionTypedInstanceGetter3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}{O}]*/ ();

/*member: invokeFunctionTypedInstanceField1:[subclass=A|powerset={N}{O}]*/
invokeFunctionTypedInstanceField1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}{O}]*/ ();

/*member: invokeFunctionTypedInstanceField2:[exact=B|powerset={N}{O}]*/
invokeFunctionTypedInstanceField2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}{O}]*/ ();

/*member: invokeFunctionTypedInstanceField3:[exact=C|powerset={N}{O}]*/
invokeFunctionTypedInstanceField3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}{O}]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}{O}]*/ ();

/*member: invokeFunctionTypedSuperMethod1:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod2:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod3:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperGetter1:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter2:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter3:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperField1:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField2:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField3:[null|subclass=Object|powerset={null}{IN}{GFUO}]*/
invokeFunctionTypedSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}{O}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}{O}]*/ superFieldInvoke();

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

/*member: genericMethod:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
T genericMethod<T>(
  T /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  t,
) => t;

/*member: functionTypedGenericMethod:[subclass=Closure|powerset={N}{O}]*/
T Function() functionTypedGenericMethod<T>(
  T /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  t,
) =>
    /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/ () =>
        t;

/*member: Class.:[exact=Class|powerset={N}{O}]*/
class Class {
  /*member: Class.genericMethod:Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
  T genericMethod<T>(
    T /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
    t,
  ) => t;

  /*member: Class.functionTypedGenericMethod:[subclass=Closure|powerset={N}{O}]*/
  T Function() functionTypedGenericMethod<T>(
    T /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/
    t,
  ) =>
      /*Union([exact=C|powerset={N}{O}], [subclass=A|powerset={N}{O}], powerset: {N}{O})*/ () =>
          t;
}

/*member: Subclass.:[exact=Subclass|powerset={N}{O}]*/
class Subclass extends Class {
  /*member: Subclass.superMethod1:[subclass=A|powerset={N}{O}]*/
  superMethod1() {
    return super.genericMethod<A>(new A());
  }

  /*member: Subclass.superMethod2:[exact=B|powerset={N}{O}]*/
  superMethod2() {
    return super.genericMethod<B>(new B());
  }

  /*member: Subclass.superMethod3:[exact=C|powerset={N}{O}]*/
  superMethod3() {
    return super.genericMethod<C>(new C());
  }

  /*member: Subclass.functionTypedSuperMethod1:[subclass=A|powerset={N}{O}]*/
  functionTypedSuperMethod1() {
    return super.functionTypedGenericMethod<A>(new A())();
  }

  /*member: Subclass.functionTypedSuperMethod2:[exact=B|powerset={N}{O}]*/
  functionTypedSuperMethod2() {
    return super.functionTypedGenericMethod<B>(new B())();
  }

  /*member: Subclass.functionTypedSuperMethod3:[exact=C|powerset={N}{O}]*/
  functionTypedSuperMethod3() {
    return super.functionTypedGenericMethod<C>(new C())();
  }
}

/*member: invokeGenericMethod1:[subclass=A|powerset={N}{O}]*/
invokeGenericMethod1(A /*[exact=A|powerset={N}{O}]*/ a) => genericMethod<A>(a);

/*member: invokeGenericMethod2:[exact=B|powerset={N}{O}]*/
invokeGenericMethod2(B /*[exact=B|powerset={N}{O}]*/ b) => genericMethod<B>(b);

/*member: invokeGenericMethod3:[exact=C|powerset={N}{O}]*/
invokeGenericMethod3(C /*[exact=C|powerset={N}{O}]*/ c) => genericMethod<C>(c);

/*member: invokeGenericInstanceMethod1:[subclass=A|powerset={N}{O}]*/
invokeGenericInstanceMethod1() =>
    Class(). /*invoke: [exact=Class|powerset={N}{O}]*/ genericMethod<A>(new A());

/*member: invokeGenericInstanceMethod2:[exact=B|powerset={N}{O}]*/
invokeGenericInstanceMethod2() =>
    Class(). /*invoke: [exact=Class|powerset={N}{O}]*/ genericMethod<B>(new B());

/*member: invokeGenericInstanceMethod3:[exact=C|powerset={N}{O}]*/
invokeGenericInstanceMethod3() =>
    Class(). /*invoke: [exact=Class|powerset={N}{O}]*/ genericMethod<C>(new C());

/*member: invokeGenericSuperMethod1:[subclass=A|powerset={N}{O}]*/
invokeGenericSuperMethod1() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}{O}]*/ superMethod1();

/*member: invokeGenericSuperMethod2:[exact=B|powerset={N}{O}]*/
invokeGenericSuperMethod2() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}{O}]*/ superMethod2();

/*member: invokeGenericSuperMethod3:[exact=C|powerset={N}{O}]*/
invokeGenericSuperMethod3() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}{O}]*/ superMethod3();

/*member: invokeFunctionTypedGenericMethod1:[subclass=A|powerset={N}{O}]*/
invokeFunctionTypedGenericMethod1(A /*[exact=A|powerset={N}{O}]*/ a) =>
    functionTypedGenericMethod<A>(a)();

/*member: invokeFunctionTypedGenericMethod2:[exact=B|powerset={N}{O}]*/
invokeFunctionTypedGenericMethod2(B /*[exact=B|powerset={N}{O}]*/ b) =>
    functionTypedGenericMethod<B>(b)();

/*member: invokeFunctionTypedGenericMethod3:[exact=C|powerset={N}{O}]*/
invokeFunctionTypedGenericMethod3(C /*[exact=C|powerset={N}{O}]*/ c) =>
    functionTypedGenericMethod<C>(c)();

/*member: invokeFunctionTypedGenericInstanceMethod1:[subclass=A|powerset={N}{O}]*/
invokeFunctionTypedGenericInstanceMethod1() =>
    Class()
        . /*invoke: [exact=Class|powerset={N}{O}]*/ functionTypedGenericMethod<A>(
          new A(),
        )();

/*member: invokeFunctionTypedGenericInstanceMethod2:[exact=B|powerset={N}{O}]*/
invokeFunctionTypedGenericInstanceMethod2() =>
    Class()
        . /*invoke: [exact=Class|powerset={N}{O}]*/ functionTypedGenericMethod<B>(
          new B(),
        )();

/*member: invokeFunctionTypedGenericInstanceMethod3:[exact=C|powerset={N}{O}]*/
invokeFunctionTypedGenericInstanceMethod3() =>
    Class()
        . /*invoke: [exact=Class|powerset={N}{O}]*/ functionTypedGenericMethod<C>(
          new C(),
        )();

/*member: invokeFunctionTypedGenericSuperMethod1:[subclass=A|powerset={N}{O}]*/
invokeFunctionTypedGenericSuperMethod1() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset={N}{O}]*/ functionTypedSuperMethod1();

/*member: invokeFunctionTypedGenericSuperMethod2:[exact=B|powerset={N}{O}]*/
invokeFunctionTypedGenericSuperMethod2() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset={N}{O}]*/ functionTypedSuperMethod2();

/*member: invokeFunctionTypedGenericSuperMethod3:[exact=C|powerset={N}{O}]*/
invokeFunctionTypedGenericSuperMethod3() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset={N}{O}]*/ functionTypedSuperMethod3();

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
