// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=false*/

// @dart=2.6

/*class: Class1:Class1,Object*/
class Class1 {
  /*member: Class1.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: Class1.toString:String* Function()**/

  /*member: Class1.==:bool Function(dynamic)**/
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

// From language_2/mixin/bound_test:

/*class: AbstractExpression:AbstractExpression,Object*/
abstract class AbstractExpression {
  /*member: AbstractExpression.toString:String* Function()**/
  /*member: AbstractExpression.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: AbstractExpression.==:bool* Function(Object*)**/
}

/*class: ExpressionWithEval:ExpressionWithEval,Object*/
abstract class ExpressionWithEval {
  /*member: ExpressionWithEval.toString:String* Function()**/
  /*member: ExpressionWithEval.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: ExpressionWithEval.==:bool* Function(Object*)**/

  /*member: ExpressionWithEval.eval:int**/
  int get eval;
}

/*class: ExpressionWithStringConversion:ExpressionWithStringConversion,Object*/
abstract class ExpressionWithStringConversion {
  /*member: ExpressionWithStringConversion.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: ExpressionWithStringConversion.==:bool* Function(Object*)**/

  /*member: ExpressionWithStringConversion.toString:String* Function()**/
  String toString();
}

/*class: Expression:AbstractExpression,Expression,ExpressionWithEval,ExpressionWithStringConversion,Object*/
/*member: Expression.toString:String* Function()**/
/*member: Expression.eval:int**/
/*member: Expression.noSuchMethod:dynamic Function(Invocation*)**/
/*member: Expression.==:bool* Function(Object*)**/
abstract class Expression = AbstractExpression
    with ExpressionWithEval, ExpressionWithStringConversion;

// From co19_2/Mixins/Mixin_Application/superinterfaces_t01:

/*class: A2:A2,Object*/
abstract class A2 {
  /*member: A2.toString:String* Function()**/
  /*member: A2.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: A2.==:bool* Function(Object*)**/

  /*member: A2.a:int**/
  int get a;
}

/*class: B2:B2,Object*/
abstract class B2 {
  /*member: B2.toString:String* Function()**/
  /*member: B2.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: B2.==:bool* Function(Object*)**/

  /*member: B2.b:int**/
  int get b;
}

/*class: M2:A2,B2,M2,Object*/
abstract class M2 implements A2, B2 {
  /*member: M2.b:int**/
  /*member: M2.a:int**/
  /*member: M2.toString:String* Function()**/
  /*member: M2.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: M2.==:bool* Function(Object*)**/
}

/*class: S2:Object,S2*/
class S2 {
  /*member: S2.toString:String* Function()**/
  /*member: S2.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: S2.==:bool* Function(Object*)**/
}

/*class: C2:A2,B2,C2,M2,Object,S2*/
class /*error: MissingImplementationNotAbstract*/ C2 extends S2 with M2 {
  /*member: C2.b:int**/
  /*member: C2.a:int**/
  /*member: C2.toString:String* Function()**/
  /*member: C2.noSuchMethod:dynamic Function(Invocation*)**/
  /*member: C2.==:bool* Function(Object*)**/
}
