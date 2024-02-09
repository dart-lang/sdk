// Copyright (c) 2023, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final x = 'scope-marker';

class Class {
  var field;

  Class.empty()
      : field = /*
   class=Class,
   member=empty
  */
            x {
    /*
     class=Class,
     member=empty
    */
    x;
  }

  Class.oneParameter(a)
      : field = /*
   class=Class,
   member=oneParameter,
   variables=[a]
  */
            x {
    /*
     class=Class,
     member=oneParameter,
     variables=[a]
    */
    x;
  }

  Class.twoParameters(a, b)
      : field = /*
   class=Class,
   member=twoParameters,
   variables=[
    a,
    b]
  */
            x {
    /*
     class=Class,
     member=twoParameters,
     variables=[
      a,
      b]
    */
    x;
  }

  Class.optionalParameter(a, [b])
      : field = /*
   class=Class,
   member=optionalParameter,
   variables=[
    a,
    b]
  */
            x {
    /*
     class=Class,
     member=optionalParameter,
     variables=[
      a,
      b]
    */
    x;
  }

  Class.namedParameter(a, {b})
      : field = /*
   class=Class,
   member=namedParameter,
   variables=[
    a,
    b]
  */
            x {
    /*
     class=Class,
     member=namedParameter,
     variables=[
      a,
      b]
    */
    x;
  }
}

class Foo2<E extends num> {
  var field;

  factory Foo2.foo(E a) {
    /*
     class=Foo2,
     member=foo,
     static,
     typeParameters=[
      Foo2.E,
      Foo2.foo.E],
     variables=[a]
    */
    x;
    return new Foo2._();
  }

  Foo2._()
      : field = /*
   class=Foo2,
   member=_,
   typeParameters=[Foo2.E]
  */
            x {
    /*
     class=Foo2,
     member=_,
     typeParameters=[Foo2.E]
    */
    x;
  }

  static bar(dynamic a) {
    // E not legal here --- it doesn't have E!
    /*
     class=Foo2,
     member=bar,
     static,
     typeParameters=[Foo2.E],
     variables=[a]
    */
    x;
  }

  static baz<E extends String>(E a) {
    // E legal here, but it's a new one --- this one doesn't extend num!
    /*
     class=Foo2,
     member=baz,
     static,
     typeParameters=[
      Foo2.E,
      Foo2.baz.E],
     variables=[a]
    */
    x;
  }

  void foo2(E e) {
    void bar2<E extends String>(E e) {
      void baz2<E extends List>(E e) {
        print(e.length);
        /*
         class=Foo2,
         member=foo2,
         typeParameters=[
          Foo2.E,
          Foo2.foo2.bar2.E,
          Foo2.foo2.bar2.baz2.E],
         variables=[
          bar2,
          baz2,
          e]
        */
        x;
      }

      print(e.runes);
      /*
       class=Foo2,
       member=foo2,
       typeParameters=[
        Foo2.E,
        Foo2.foo2.bar2.E],
       variables=[
        bar2,
        baz2,
        e]
      */
      x;
    }

    print(e.abs());
    /*
     class=Foo2,
     member=foo2,
     typeParameters=[Foo2.E],
     variables=[
      bar2,
      e]
    */
    x;
  }
}
