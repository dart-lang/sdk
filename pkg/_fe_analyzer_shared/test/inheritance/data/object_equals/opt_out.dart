// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

/*class: Class1:Class1,Object*/
class Class1 {
  /*member: Class1.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class1.toString:String* Function()**/

  /*member: Class1.==:bool! Function(dynamic)**/
  operator ==(other) => true;
}

/*class: Class2a:Class2a,Object*/
abstract class Class2a {
  /*member: Class2a.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class2a.toString:String* Function()**/

  /*member: Class2a.==:bool* Function(Object*)**/
  bool operator ==(Object other);
}

/*class: Class2b:Class2a,Class2b,Object*/
class Class2b extends Class2a {
  /*member: Class2b.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class2b.toString:String* Function()**/
  /*member: Class2b.==:bool* Function(Object*)**/
}

/*class: Class3a:Class3a,Object*/
class Class3a {
  /*member: Class3a.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class3a.toString:String* Function()**/
  /*member: Class3a.==:bool* Function(Object*)**/
}

/*class: Class3b:Class3a,Class3b,Object*/
abstract class Class3b extends Class3a {
  /*member: Class3b.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class3b.toString:String* Function()**/

  /*member: Class3b.==:bool* Function(Object*)**/
  bool operator ==(Object other);
}

/*class: Class3c:Class3a,Class3b,Class3c,Object*/
class Class3c extends Class3b {
  /*member: Class3c.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class3c.toString:String* Function()**/
  /*member: Class3c.==:bool* Function(Object*)**/
}

/*class: Foo:Foo,Object*/
class Foo extends /*error: TypeNotFound*/ Unresolved {
  /*member: Foo.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Foo.toString:String* Function()**/
  /*member: Foo.==:bool* Function(Object*)**/
}

/*class: A:A,Object*/
abstract class A {
  /*member: A.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: A.==:bool* Function(Object*)**/

  /*member: A.toString:String* Function({bool* withNullability})**/
  String toString({bool withNullability = false}) {
    return '';
  }
}

/*class: B:A,B,Object*/
abstract class B implements A {
  /*member: B.toString:String* Function({bool* withNullability})**/
  /*member: B.==:bool* Function(Object*)**/

  /*member: B.noSuchMethod:dynamic Function(Invocation*)**/
  noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}
