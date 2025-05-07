// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset={N}]*/
class A {}

/*member: B.:[exact=B|powerset={N}]*/
class B extends A {}

/*member: C.:[exact=C|powerset={N}]*/
class C {}

/*member: main:[null|powerset={null}]*/
main() {
  invokeFunctions();
  invokeGenericClasses();
  invokeGenericMethods();
}

/*member: invokeFunction1:[subclass=A|powerset={N}]*/
invokeFunction1(A Function() /*[subclass=Closure|powerset={N}]*/ f) {
  return f();
}

/*member: invokeFunction2:[exact=B|powerset={N}]*/
invokeFunction2(B Function() /*[subclass=Closure|powerset={N}]*/ f) {
  return f();
}

/*member: invokeFunction3:[exact=C|powerset={N}]*/
invokeFunction3(C Function() /*[subclass=Closure|powerset={N}]*/ f) {
  return f();
}

/*member: genericFunction:[null|subclass=Object|powerset={null}{IN}]*/
T genericFunction<T>(T Function() /*[subclass=Closure|powerset={N}]*/ f) => f();

/*member: invokeGenericFunction1:[subclass=A|powerset={N}]*/
invokeGenericFunction1() {
  return genericFunction<A>(/*[exact=A|powerset={N}]*/ () => A());
}

/*member: invokeGenericFunction2:[exact=B|powerset={N}]*/
invokeGenericFunction2() {
  return genericFunction<B>(/*[exact=B|powerset={N}]*/ () => B());
}

/*member: invokeGenericFunction3:[exact=C|powerset={N}]*/
invokeGenericFunction3() {
  return genericFunction<C>(/*[exact=C|powerset={N}]*/ () => C());
}

/*member: invokeGenericLocalFunction1:[subclass=A|powerset={N}]*/
invokeGenericLocalFunction1() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}]*/ f) => f();
  return local<A>(/*[exact=A|powerset={N}]*/ () => A());
}

/*member: invokeGenericLocalFunction2:[exact=B|powerset={N}]*/
invokeGenericLocalFunction2() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}]*/ f) => f();
  return local<B>(/*[exact=B|powerset={N}]*/ () => B());
}

/*member: invokeGenericLocalFunction3:[exact=C|powerset={N}]*/
invokeGenericLocalFunction3() {
  /*[null|subclass=Object|powerset={null}{IN}]*/
  T local<T>(T Function() /*[subclass=Closure|powerset={N}]*/ f) => f();
  return local<C>(/*[exact=C|powerset={N}]*/ () => C());
}

/*member: invokeFunctions:[null|powerset={null}]*/
invokeFunctions() {
  invokeFunction1(/*[exact=A|powerset={N}]*/ () => A());
  invokeFunction2(/*[exact=B|powerset={N}]*/ () => B());
  invokeFunction3(/*[exact=C|powerset={N}]*/ () => C());
  invokeGenericFunction1();
  invokeGenericFunction2();
  invokeGenericFunction3();
  invokeGenericLocalFunction1();
  invokeGenericLocalFunction2();
  invokeGenericLocalFunction3();
}

class GenericClass<T> {
  /*member: GenericClass.field:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  final T field;

  /*member: GenericClass.functionTypedField:[subclass=Closure|powerset={N}]*/
  final T Function() functionTypedField;

  /*member: GenericClass.:[exact=GenericClass|powerset={N}]*/
  GenericClass(
    this. /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/ field,
  ) : functionTypedField =
          ( /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/ () =>
              field);

  /*member: GenericClass.getter:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  T get getter => /*[subclass=GenericClass|powerset={N}]*/ field;

  /*member: GenericClass.functionTypedGetter:[subclass=Closure|powerset={N}]*/
  T Function()
  get functionTypedGetter => /*[subclass=GenericClass|powerset={N}]*/
      functionTypedField;

  /*member: GenericClass.method:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  T method() => /*[subclass=GenericClass|powerset={N}]*/ field;

  /*member: GenericClass.functionTypedMethod:[subclass=Closure|powerset={N}]*/
  T Function() functionTypedMethod() => /*[subclass=GenericClass|powerset={N}]*/
      functionTypedField;
}

class GenericSubclass<T> extends GenericClass<T> {
  /*member: GenericSubclass.:[exact=GenericSubclass|powerset={N}]*/
  GenericSubclass(
    T /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
    field,
  ) : super(field);

  /*member: GenericSubclass.superField:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  superField() => super.field;

  /*member: GenericSubclass.superGetter:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  superGetter() => super.getter;

  /*member: GenericSubclass.superMethod:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  superMethod() => super.method();

  /*member: GenericSubclass.superFieldInvoke:[null|subclass=Object|powerset={null}{IN}]*/
  superFieldInvoke() => super.functionTypedField();

  /*member: GenericSubclass.superGetterInvoke:[null|subclass=Object|powerset={null}{IN}]*/
  superGetterInvoke() => super.functionTypedGetter();

  /*member: GenericSubclass.superMethodInvoke:[null|subclass=Object|powerset={null}{IN}]*/
  superMethodInvoke() => super.functionTypedMethod()();
}

/*member: invokeInstanceMethod1:[subclass=A|powerset={N}]*/
invokeInstanceMethod1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}]*/ method();

/*member: invokeInstanceMethod2:[exact=B|powerset={N}]*/
invokeInstanceMethod2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}]*/ method();

/*member: invokeInstanceMethod3:[exact=C|powerset={N}]*/
invokeInstanceMethod3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}]*/ method();

/*member: invokeInstanceGetter1:[subclass=A|powerset={N}]*/
invokeInstanceGetter1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}]*/ getter;

/*member: invokeInstanceGetter2:[exact=B|powerset={N}]*/
invokeInstanceGetter2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}]*/ getter;

/*member: invokeInstanceGetter3:[exact=C|powerset={N}]*/
invokeInstanceGetter3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*[exact=GenericClass|powerset={N}]*/ getter;

/*member: accessInstanceField1:[subclass=A|powerset={N}]*/
accessInstanceField1(GenericClass<A> /*[exact=GenericClass|powerset={N}]*/ c) =>
    c. /*[exact=GenericClass|powerset={N}]*/ field;

/*member: accessInstanceField2:[exact=B|powerset={N}]*/
accessInstanceField2(GenericClass<B> /*[exact=GenericClass|powerset={N}]*/ c) =>
    c. /*[exact=GenericClass|powerset={N}]*/ field;

/*member: accessInstanceField3:[exact=C|powerset={N}]*/
accessInstanceField3(GenericClass<C> /*[exact=GenericClass|powerset={N}]*/ c) =>
    c. /*[exact=GenericClass|powerset={N}]*/ field;

/*member: invokeSuperMethod1:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
invokeSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superMethod();

/*member: invokeSuperMethod2:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
invokeSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superMethod();

/*member: invokeSuperMethod3:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
invokeSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superMethod();

/*member: invokeSuperGetter1:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
invokeSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superGetter();

/*member: invokeSuperGetter2:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
invokeSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superGetter();

/*member: invokeSuperGetter3:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
invokeSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superGetter();

/*member: accessSuperField1:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
accessSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superField();

/*member: accessSuperField2:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
accessSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superField();

/*member: accessSuperField3:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
accessSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superField();

/*member: invokeFunctionTypedInstanceMethod1:[subclass=A|powerset={N}]*/
invokeFunctionTypedInstanceMethod1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod2:[exact=B|powerset={N}]*/
invokeFunctionTypedInstanceMethod2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod3:[exact=C|powerset={N}]*/
invokeFunctionTypedInstanceMethod3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset={N}]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceGetter1:[subclass=A|powerset={N}]*/
invokeFunctionTypedInstanceGetter1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}]*/ ();

/*member: invokeFunctionTypedInstanceGetter2:[exact=B|powerset={N}]*/
invokeFunctionTypedInstanceGetter2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}]*/ ();

/*member: invokeFunctionTypedInstanceGetter3:[exact=C|powerset={N}]*/
invokeFunctionTypedInstanceGetter3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset={N}]*/ ();

/*member: invokeFunctionTypedInstanceField1:[subclass=A|powerset={N}]*/
invokeFunctionTypedInstanceField1(
  GenericClass<A> /*[exact=GenericClass|powerset={N}]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}]*/ ();

/*member: invokeFunctionTypedInstanceField2:[exact=B|powerset={N}]*/
invokeFunctionTypedInstanceField2(
  GenericClass<B> /*[exact=GenericClass|powerset={N}]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}]*/ ();

/*member: invokeFunctionTypedInstanceField3:[exact=C|powerset={N}]*/
invokeFunctionTypedInstanceField3(
  GenericClass<C> /*[exact=GenericClass|powerset={N}]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset={N}]*/ ();

/*member: invokeFunctionTypedSuperMethod1:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod2:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod3:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperGetter1:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter2:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter3:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperField1:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField2:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField3:[null|subclass=Object|powerset={null}{IN}]*/
invokeFunctionTypedSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset={N}]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset={N}]*/ superFieldInvoke();

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

/*member: genericMethod:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
T genericMethod<T>(
  T /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  t,
) => t;

/*member: functionTypedGenericMethod:[subclass=Closure|powerset={N}]*/
T Function() functionTypedGenericMethod<T>(
  T /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  t,
) =>
    /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/ () =>
        t;

/*member: Class.:[exact=Class|powerset={N}]*/
class Class {
  /*member: Class.genericMethod:Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
  T genericMethod<T>(
    T /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
    t,
  ) => t;

  /*member: Class.functionTypedGenericMethod:[subclass=Closure|powerset={N}]*/
  T Function() functionTypedGenericMethod<T>(
    T /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/
    t,
  ) =>
      /*Union([exact=C|powerset={N}], [subclass=A|powerset={N}], powerset: {N})*/ () =>
          t;
}

/*member: Subclass.:[exact=Subclass|powerset={N}]*/
class Subclass extends Class {
  /*member: Subclass.superMethod1:[subclass=A|powerset={N}]*/
  superMethod1() {
    return super.genericMethod<A>(new A());
  }

  /*member: Subclass.superMethod2:[exact=B|powerset={N}]*/
  superMethod2() {
    return super.genericMethod<B>(new B());
  }

  /*member: Subclass.superMethod3:[exact=C|powerset={N}]*/
  superMethod3() {
    return super.genericMethod<C>(new C());
  }

  /*member: Subclass.functionTypedSuperMethod1:[subclass=A|powerset={N}]*/
  functionTypedSuperMethod1() {
    return super.functionTypedGenericMethod<A>(new A())();
  }

  /*member: Subclass.functionTypedSuperMethod2:[exact=B|powerset={N}]*/
  functionTypedSuperMethod2() {
    return super.functionTypedGenericMethod<B>(new B())();
  }

  /*member: Subclass.functionTypedSuperMethod3:[exact=C|powerset={N}]*/
  functionTypedSuperMethod3() {
    return super.functionTypedGenericMethod<C>(new C())();
  }
}

/*member: invokeGenericMethod1:[subclass=A|powerset={N}]*/
invokeGenericMethod1(A /*[exact=A|powerset={N}]*/ a) => genericMethod<A>(a);

/*member: invokeGenericMethod2:[exact=B|powerset={N}]*/
invokeGenericMethod2(B /*[exact=B|powerset={N}]*/ b) => genericMethod<B>(b);

/*member: invokeGenericMethod3:[exact=C|powerset={N}]*/
invokeGenericMethod3(C /*[exact=C|powerset={N}]*/ c) => genericMethod<C>(c);

/*member: invokeGenericInstanceMethod1:[subclass=A|powerset={N}]*/
invokeGenericInstanceMethod1() =>
    Class(). /*invoke: [exact=Class|powerset={N}]*/ genericMethod<A>(new A());

/*member: invokeGenericInstanceMethod2:[exact=B|powerset={N}]*/
invokeGenericInstanceMethod2() =>
    Class(). /*invoke: [exact=Class|powerset={N}]*/ genericMethod<B>(new B());

/*member: invokeGenericInstanceMethod3:[exact=C|powerset={N}]*/
invokeGenericInstanceMethod3() =>
    Class(). /*invoke: [exact=Class|powerset={N}]*/ genericMethod<C>(new C());

/*member: invokeGenericSuperMethod1:[subclass=A|powerset={N}]*/
invokeGenericSuperMethod1() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}]*/ superMethod1();

/*member: invokeGenericSuperMethod2:[exact=B|powerset={N}]*/
invokeGenericSuperMethod2() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}]*/ superMethod2();

/*member: invokeGenericSuperMethod3:[exact=C|powerset={N}]*/
invokeGenericSuperMethod3() =>
    Subclass(). /*invoke: [exact=Subclass|powerset={N}]*/ superMethod3();

/*member: invokeFunctionTypedGenericMethod1:[subclass=A|powerset={N}]*/
invokeFunctionTypedGenericMethod1(A /*[exact=A|powerset={N}]*/ a) =>
    functionTypedGenericMethod<A>(a)();

/*member: invokeFunctionTypedGenericMethod2:[exact=B|powerset={N}]*/
invokeFunctionTypedGenericMethod2(B /*[exact=B|powerset={N}]*/ b) =>
    functionTypedGenericMethod<B>(b)();

/*member: invokeFunctionTypedGenericMethod3:[exact=C|powerset={N}]*/
invokeFunctionTypedGenericMethod3(C /*[exact=C|powerset={N}]*/ c) =>
    functionTypedGenericMethod<C>(c)();

/*member: invokeFunctionTypedGenericInstanceMethod1:[subclass=A|powerset={N}]*/
invokeFunctionTypedGenericInstanceMethod1() =>
    Class()
        . /*invoke: [exact=Class|powerset={N}]*/ functionTypedGenericMethod<A>(
          new A(),
        )();

/*member: invokeFunctionTypedGenericInstanceMethod2:[exact=B|powerset={N}]*/
invokeFunctionTypedGenericInstanceMethod2() =>
    Class()
        . /*invoke: [exact=Class|powerset={N}]*/ functionTypedGenericMethod<B>(
          new B(),
        )();

/*member: invokeFunctionTypedGenericInstanceMethod3:[exact=C|powerset={N}]*/
invokeFunctionTypedGenericInstanceMethod3() =>
    Class()
        . /*invoke: [exact=Class|powerset={N}]*/ functionTypedGenericMethod<C>(
          new C(),
        )();

/*member: invokeFunctionTypedGenericSuperMethod1:[subclass=A|powerset={N}]*/
invokeFunctionTypedGenericSuperMethod1() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset={N}]*/ functionTypedSuperMethod1();

/*member: invokeFunctionTypedGenericSuperMethod2:[exact=B|powerset={N}]*/
invokeFunctionTypedGenericSuperMethod2() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset={N}]*/ functionTypedSuperMethod2();

/*member: invokeFunctionTypedGenericSuperMethod3:[exact=C|powerset={N}]*/
invokeFunctionTypedGenericSuperMethod3() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset={N}]*/ functionTypedSuperMethod3();

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
