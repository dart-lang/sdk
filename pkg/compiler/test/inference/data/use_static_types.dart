// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*member: A.:[exact=A|powerset=0]*/
class A {}

/*member: B.:[exact=B|powerset=0]*/
class B extends A {}

/*member: C.:[exact=C|powerset=0]*/
class C {}

/*member: main:[null|powerset=1]*/
main() {
  invokeFunctions();
  invokeGenericClasses();
  invokeGenericMethods();
}

/*member: invokeFunction1:[subclass=A|powerset=0]*/
invokeFunction1(A Function() /*[subclass=Closure|powerset=0]*/ f) {
  return f();
}

/*member: invokeFunction2:[exact=B|powerset=0]*/
invokeFunction2(B Function() /*[subclass=Closure|powerset=0]*/ f) {
  return f();
}

/*member: invokeFunction3:[exact=C|powerset=0]*/
invokeFunction3(C Function() /*[subclass=Closure|powerset=0]*/ f) {
  return f();
}

/*member: genericFunction:[null|subclass=Object|powerset=1]*/
T genericFunction<T>(T Function() /*[subclass=Closure|powerset=0]*/ f) => f();

/*member: invokeGenericFunction1:[subclass=A|powerset=0]*/
invokeGenericFunction1() {
  return genericFunction<A>(/*[exact=A|powerset=0]*/ () => A());
}

/*member: invokeGenericFunction2:[exact=B|powerset=0]*/
invokeGenericFunction2() {
  return genericFunction<B>(/*[exact=B|powerset=0]*/ () => B());
}

/*member: invokeGenericFunction3:[exact=C|powerset=0]*/
invokeGenericFunction3() {
  return genericFunction<C>(/*[exact=C|powerset=0]*/ () => C());
}

/*member: invokeGenericLocalFunction1:[subclass=A|powerset=0]*/
invokeGenericLocalFunction1() {
  /*[null|subclass=Object|powerset=1]*/
  T local<T>(T Function() /*[subclass=Closure|powerset=0]*/ f) => f();
  return local<A>(/*[exact=A|powerset=0]*/ () => A());
}

/*member: invokeGenericLocalFunction2:[exact=B|powerset=0]*/
invokeGenericLocalFunction2() {
  /*[null|subclass=Object|powerset=1]*/
  T local<T>(T Function() /*[subclass=Closure|powerset=0]*/ f) => f();
  return local<B>(/*[exact=B|powerset=0]*/ () => B());
}

/*member: invokeGenericLocalFunction3:[exact=C|powerset=0]*/
invokeGenericLocalFunction3() {
  /*[null|subclass=Object|powerset=1]*/
  T local<T>(T Function() /*[subclass=Closure|powerset=0]*/ f) => f();
  return local<C>(/*[exact=C|powerset=0]*/ () => C());
}

/*member: invokeFunctions:[null|powerset=1]*/
invokeFunctions() {
  invokeFunction1(/*[exact=A|powerset=0]*/ () => A());
  invokeFunction2(/*[exact=B|powerset=0]*/ () => B());
  invokeFunction3(/*[exact=C|powerset=0]*/ () => C());
  invokeGenericFunction1();
  invokeGenericFunction2();
  invokeGenericFunction3();
  invokeGenericLocalFunction1();
  invokeGenericLocalFunction2();
  invokeGenericLocalFunction3();
}

class GenericClass<T> {
  /*member: GenericClass.field:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
  final T field;

  /*member: GenericClass.functionTypedField:[subclass=Closure|powerset=0]*/
  final T Function() functionTypedField;

  /*member: GenericClass.:[exact=GenericClass|powerset=0]*/
  GenericClass(
    this. /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ field,
  ) : functionTypedField =
          ( /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ () =>
              field);

  /*member: GenericClass.getter:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
  T get getter => /*[subclass=GenericClass|powerset=0]*/ field;

  /*member: GenericClass.functionTypedGetter:[subclass=Closure|powerset=0]*/
  T Function() get functionTypedGetter => /*[subclass=GenericClass|powerset=0]*/
      functionTypedField;

  /*member: GenericClass.method:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
  T method() => /*[subclass=GenericClass|powerset=0]*/ field;

  /*member: GenericClass.functionTypedMethod:[subclass=Closure|powerset=0]*/
  T Function() functionTypedMethod() => /*[subclass=GenericClass|powerset=0]*/
      functionTypedField;
}

class GenericSubclass<T> extends GenericClass<T> {
  /*member: GenericSubclass.:[exact=GenericSubclass|powerset=0]*/
  GenericSubclass(
    T /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
    field,
  ) : super(field);

  /*member: GenericSubclass.superField:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
  superField() => super.field;

  /*member: GenericSubclass.superGetter:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
  superGetter() => super.getter;

  /*member: GenericSubclass.superMethod:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
  superMethod() => super.method();

  /*member: GenericSubclass.superFieldInvoke:[null|subclass=Object|powerset=1]*/
  superFieldInvoke() => super.functionTypedField();

  /*member: GenericSubclass.superGetterInvoke:[null|subclass=Object|powerset=1]*/
  superGetterInvoke() => super.functionTypedGetter();

  /*member: GenericSubclass.superMethodInvoke:[null|subclass=Object|powerset=1]*/
  superMethodInvoke() => super.functionTypedMethod()();
}

/*member: invokeInstanceMethod1:[subclass=A|powerset=0]*/
invokeInstanceMethod1(GenericClass<A> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*invoke: [exact=GenericClass|powerset=0]*/ method();

/*member: invokeInstanceMethod2:[exact=B|powerset=0]*/
invokeInstanceMethod2(GenericClass<B> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*invoke: [exact=GenericClass|powerset=0]*/ method();

/*member: invokeInstanceMethod3:[exact=C|powerset=0]*/
invokeInstanceMethod3(GenericClass<C> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*invoke: [exact=GenericClass|powerset=0]*/ method();

/*member: invokeInstanceGetter1:[subclass=A|powerset=0]*/
invokeInstanceGetter1(GenericClass<A> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*[exact=GenericClass|powerset=0]*/ getter;

/*member: invokeInstanceGetter2:[exact=B|powerset=0]*/
invokeInstanceGetter2(GenericClass<B> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*[exact=GenericClass|powerset=0]*/ getter;

/*member: invokeInstanceGetter3:[exact=C|powerset=0]*/
invokeInstanceGetter3(GenericClass<C> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*[exact=GenericClass|powerset=0]*/ getter;

/*member: accessInstanceField1:[subclass=A|powerset=0]*/
accessInstanceField1(GenericClass<A> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*[exact=GenericClass|powerset=0]*/ field;

/*member: accessInstanceField2:[exact=B|powerset=0]*/
accessInstanceField2(GenericClass<B> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*[exact=GenericClass|powerset=0]*/ field;

/*member: accessInstanceField3:[exact=C|powerset=0]*/
accessInstanceField3(GenericClass<C> /*[exact=GenericClass|powerset=0]*/ c) =>
    c. /*[exact=GenericClass|powerset=0]*/ field;

/*member: invokeSuperMethod1:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
invokeSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superMethod();

/*member: invokeSuperMethod2:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
invokeSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superMethod();

/*member: invokeSuperMethod3:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
invokeSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superMethod();

/*member: invokeSuperGetter1:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
invokeSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superGetter();

/*member: invokeSuperGetter2:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
invokeSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superGetter();

/*member: invokeSuperGetter3:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
invokeSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superGetter();

/*member: accessSuperField1:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
accessSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superField();

/*member: accessSuperField2:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
accessSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superField();

/*member: accessSuperField3:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
accessSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superField();

/*member: invokeFunctionTypedInstanceMethod1:[subclass=A|powerset=0]*/
invokeFunctionTypedInstanceMethod1(
  GenericClass<A> /*[exact=GenericClass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset=0]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod2:[exact=B|powerset=0]*/
invokeFunctionTypedInstanceMethod2(
  GenericClass<B> /*[exact=GenericClass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset=0]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceMethod3:[exact=C|powerset=0]*/
invokeFunctionTypedInstanceMethod3(
  GenericClass<C> /*[exact=GenericClass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericClass|powerset=0]*/ functionTypedMethod()();

/*member: invokeFunctionTypedInstanceGetter1:[subclass=A|powerset=0]*/
invokeFunctionTypedInstanceGetter1(
  GenericClass<A> /*[exact=GenericClass|powerset=0]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset=0]*/ ();

/*member: invokeFunctionTypedInstanceGetter2:[exact=B|powerset=0]*/
invokeFunctionTypedInstanceGetter2(
  GenericClass<B> /*[exact=GenericClass|powerset=0]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset=0]*/ ();

/*member: invokeFunctionTypedInstanceGetter3:[exact=C|powerset=0]*/
invokeFunctionTypedInstanceGetter3(
  GenericClass<C> /*[exact=GenericClass|powerset=0]*/ c,
) => c.functionTypedGetter /*invoke: [exact=GenericClass|powerset=0]*/ ();

/*member: invokeFunctionTypedInstanceField1:[subclass=A|powerset=0]*/
invokeFunctionTypedInstanceField1(
  GenericClass<A> /*[exact=GenericClass|powerset=0]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset=0]*/ ();

/*member: invokeFunctionTypedInstanceField2:[exact=B|powerset=0]*/
invokeFunctionTypedInstanceField2(
  GenericClass<B> /*[exact=GenericClass|powerset=0]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset=0]*/ ();

/*member: invokeFunctionTypedInstanceField3:[exact=C|powerset=0]*/
invokeFunctionTypedInstanceField3(
  GenericClass<C> /*[exact=GenericClass|powerset=0]*/ c,
) => c.functionTypedField /*invoke: [exact=GenericClass|powerset=0]*/ ();

/*member: invokeFunctionTypedSuperMethod1:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperMethod1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod2:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperMethod2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperMethod3:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperMethod3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superMethodInvoke();

/*member: invokeFunctionTypedSuperGetter1:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperGetter1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter2:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperGetter2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperGetter3:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperGetter3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superGetterInvoke();

/*member: invokeFunctionTypedSuperField1:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperField1(
  GenericSubclass<A> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField2:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperField2(
  GenericSubclass<B> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superFieldInvoke();

/*member: invokeFunctionTypedSuperField3:[null|subclass=Object|powerset=1]*/
invokeFunctionTypedSuperField3(
  GenericSubclass<C> /*[exact=GenericSubclass|powerset=0]*/ c,
) => c. /*invoke: [exact=GenericSubclass|powerset=0]*/ superFieldInvoke();

/*member: invokeGenericClasses:[null|powerset=1]*/
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

/*member: genericMethod:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
T genericMethod<T>(
  T /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ t,
) => t;

/*member: functionTypedGenericMethod:[subclass=Closure|powerset=0]*/
T Function() functionTypedGenericMethod<T>(
  T /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ t,
) =>
    /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ () =>
        t;

/*member: Class.:[exact=Class|powerset=0]*/
class Class {
  /*member: Class.genericMethod:Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/
  T genericMethod<T>(
    T /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ t,
  ) => t;

  /*member: Class.functionTypedGenericMethod:[subclass=Closure|powerset=0]*/
  T Function() functionTypedGenericMethod<T>(
    T /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ t,
  ) =>
      /*Union([exact=C|powerset=0], [subclass=A|powerset=0], powerset: 0)*/ () =>
          t;
}

/*member: Subclass.:[exact=Subclass|powerset=0]*/
class Subclass extends Class {
  /*member: Subclass.superMethod1:[subclass=A|powerset=0]*/
  superMethod1() {
    return super.genericMethod<A>(new A());
  }

  /*member: Subclass.superMethod2:[exact=B|powerset=0]*/
  superMethod2() {
    return super.genericMethod<B>(new B());
  }

  /*member: Subclass.superMethod3:[exact=C|powerset=0]*/
  superMethod3() {
    return super.genericMethod<C>(new C());
  }

  /*member: Subclass.functionTypedSuperMethod1:[subclass=A|powerset=0]*/
  functionTypedSuperMethod1() {
    return super.functionTypedGenericMethod<A>(new A())();
  }

  /*member: Subclass.functionTypedSuperMethod2:[exact=B|powerset=0]*/
  functionTypedSuperMethod2() {
    return super.functionTypedGenericMethod<B>(new B())();
  }

  /*member: Subclass.functionTypedSuperMethod3:[exact=C|powerset=0]*/
  functionTypedSuperMethod3() {
    return super.functionTypedGenericMethod<C>(new C())();
  }
}

/*member: invokeGenericMethod1:[subclass=A|powerset=0]*/
invokeGenericMethod1(A /*[exact=A|powerset=0]*/ a) => genericMethod<A>(a);

/*member: invokeGenericMethod2:[exact=B|powerset=0]*/
invokeGenericMethod2(B /*[exact=B|powerset=0]*/ b) => genericMethod<B>(b);

/*member: invokeGenericMethod3:[exact=C|powerset=0]*/
invokeGenericMethod3(C /*[exact=C|powerset=0]*/ c) => genericMethod<C>(c);

/*member: invokeGenericInstanceMethod1:[subclass=A|powerset=0]*/
invokeGenericInstanceMethod1() =>
    Class(). /*invoke: [exact=Class|powerset=0]*/ genericMethod<A>(new A());

/*member: invokeGenericInstanceMethod2:[exact=B|powerset=0]*/
invokeGenericInstanceMethod2() =>
    Class(). /*invoke: [exact=Class|powerset=0]*/ genericMethod<B>(new B());

/*member: invokeGenericInstanceMethod3:[exact=C|powerset=0]*/
invokeGenericInstanceMethod3() =>
    Class(). /*invoke: [exact=Class|powerset=0]*/ genericMethod<C>(new C());

/*member: invokeGenericSuperMethod1:[subclass=A|powerset=0]*/
invokeGenericSuperMethod1() =>
    Subclass(). /*invoke: [exact=Subclass|powerset=0]*/ superMethod1();

/*member: invokeGenericSuperMethod2:[exact=B|powerset=0]*/
invokeGenericSuperMethod2() =>
    Subclass(). /*invoke: [exact=Subclass|powerset=0]*/ superMethod2();

/*member: invokeGenericSuperMethod3:[exact=C|powerset=0]*/
invokeGenericSuperMethod3() =>
    Subclass(). /*invoke: [exact=Subclass|powerset=0]*/ superMethod3();

/*member: invokeFunctionTypedGenericMethod1:[subclass=A|powerset=0]*/
invokeFunctionTypedGenericMethod1(A /*[exact=A|powerset=0]*/ a) =>
    functionTypedGenericMethod<A>(a)();

/*member: invokeFunctionTypedGenericMethod2:[exact=B|powerset=0]*/
invokeFunctionTypedGenericMethod2(B /*[exact=B|powerset=0]*/ b) =>
    functionTypedGenericMethod<B>(b)();

/*member: invokeFunctionTypedGenericMethod3:[exact=C|powerset=0]*/
invokeFunctionTypedGenericMethod3(C /*[exact=C|powerset=0]*/ c) =>
    functionTypedGenericMethod<C>(c)();

/*member: invokeFunctionTypedGenericInstanceMethod1:[subclass=A|powerset=0]*/
invokeFunctionTypedGenericInstanceMethod1() =>
    Class(). /*invoke: [exact=Class|powerset=0]*/ functionTypedGenericMethod<A>(
      new A(),
    )();

/*member: invokeFunctionTypedGenericInstanceMethod2:[exact=B|powerset=0]*/
invokeFunctionTypedGenericInstanceMethod2() =>
    Class(). /*invoke: [exact=Class|powerset=0]*/ functionTypedGenericMethod<B>(
      new B(),
    )();

/*member: invokeFunctionTypedGenericInstanceMethod3:[exact=C|powerset=0]*/
invokeFunctionTypedGenericInstanceMethod3() =>
    Class(). /*invoke: [exact=Class|powerset=0]*/ functionTypedGenericMethod<C>(
      new C(),
    )();

/*member: invokeFunctionTypedGenericSuperMethod1:[subclass=A|powerset=0]*/
invokeFunctionTypedGenericSuperMethod1() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset=0]*/ functionTypedSuperMethod1();

/*member: invokeFunctionTypedGenericSuperMethod2:[exact=B|powerset=0]*/
invokeFunctionTypedGenericSuperMethod2() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset=0]*/ functionTypedSuperMethod2();

/*member: invokeFunctionTypedGenericSuperMethod3:[exact=C|powerset=0]*/
invokeFunctionTypedGenericSuperMethod3() =>
    Subclass()
        . /*invoke: [exact=Subclass|powerset=0]*/ functionTypedSuperMethod3();

/*member: invokeGenericMethods:[null|powerset=1]*/
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
