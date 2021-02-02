// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*library: nnbd=true*/
library expressions;

import 'dart:math' deferred as prefix;

class Class {
  Class();
  Class.named();

  var field;
  get getter => 0;
  set setter(/*dynamic*/ _) {}
  method1() {}
  method2(/*dynamic*/ a) {}
  method3([/*dynamic*/ a]) {}
  method4(/*dynamic*/ a, [/*dynamic*/ b]) {}
  method5({/*dynamic*/ a}) {}
  method6(/*dynamic*/ a, {/*dynamic*/ b}) {}
  method7({/*dynamic*/ a, /*dynamic*/ b}) {}
  genericMethod1<T>() {}
  genericMethod2<T, S>() {}
  _privateMethod() {}

  static var staticField;
  static get staticGetter => 42;
  static set staticSetter(/*dynamic*/ _) {}
  static staticMethod() {}
}

class SubClass extends Class {
  /*member: SubClass.exprThis:this*/
  exprThis() => this;

  /*normal|limited.member: SubClass.exprSuperFieldGet:super.{Class.field}*/
  /*verbose.member: SubClass.exprSuperFieldGet:super.{expressions::Class.field}*/
  exprSuperFieldGet() => super.field;

  /*normal|limited.member: SubClass.exprSuperGetterGet:super.{Class.getter}*/
  /*verbose.member: SubClass.exprSuperGetterGet:super.{expressions::Class.getter}*/
  exprSuperGetterGet() => super.getter;

  /*normal|limited.member: SubClass.exprSuperMethodTearOff:super.{Class.method1}*/
  /*verbose.member: SubClass.exprSuperMethodTearOff:super.{expressions::Class.method1}*/
  exprSuperMethodTearOff() => super.method1;

  /*normal|limited.member: SubClass.exprSuperFieldSet:super.{Class.field} = 42*/
  /*verbose.member: SubClass.exprSuperFieldSet:super.{expressions::Class.field} = 42*/
  exprSuperFieldSet() => super.field = 42;

  /*normal|limited.member: SubClass.exprSuperSetterSet:super.{Class.setter} = 42*/
  /*verbose.member: SubClass.exprSuperSetterSet:super.{expressions::Class.setter} = 42*/
  exprSuperSetterSet() => super.setter = 42;

  /*normal|limited.member: SubClass.exprSuperMethodInvocation:super.{Class.method1}()*/
  /*verbose.member: SubClass.exprSuperMethodInvocation:super.{expressions::Class.method1}()*/
  exprSuperMethodInvocation() => super.method1();
}

class GenericClass<T, S> {
  GenericClass();
  GenericClass.named();
}

var topLevelField;
get topLevelGetter => 42;
set topLevelSetter(/*dynamic*/ _) {}
topLevelMethod() {}

T genericTopLevelMethod1<T>(T /*T%*/ t) => t;
T genericTopLevelMethod2<T, S>(T /*T%*/ t, S /*S%*/ s) => t;

/*member: exprNullLiteral:null*/
exprNullLiteral() => null;

/*member: exprBoolLiteralTrue:true*/
exprBoolLiteralTrue() => true;

/*member: exprBoolLiteralFalse:false*/
exprBoolLiteralFalse() => false;

/*member: exprIntLiteral:42*/
exprIntLiteral() => 42;

/*member: exprDoubleLiteral:3.14*/
exprDoubleLiteral() => 3.14;

/*member: exprStringLiteralEmpty:""*/
exprStringLiteralEmpty() => "";

/*member: exprStringLiteralNonEmpty:"foo"*/
exprStringLiteralNonEmpty() => "foo";

/*member: exprStringLiteralSingleQuote:"foo'bar'baz"*/
exprStringLiteralSingleQuote() => "foo'bar'baz";

/*member: exprStringLiteralDoubleQuote:"foo\"bar\"baz"*/
exprStringLiteralDoubleQuote() => 'foo"bar"baz';

/*member: exprStringLiteralSingleDoubleQuote:"foo\"bar'baz"*/
exprStringLiteralSingleDoubleQuote() => "foo\"bar\'baz";

/*member: exprStringLiteralEscapes:"\r\n\t\u0008\f\u0000"*/
exprStringLiteralEscapes() => "\r\n\t\b\f\u0000";

/*member: exprSymbolLiteral:#foo*/
exprSymbolLiteral() => #foo;

/*normal|limited.member: exprPrivateSymbolLiteral:#_bar*/
/*verbose.member: exprPrivateSymbolLiteral:#expressions::_bar*/
exprPrivateSymbolLiteral() => #_bar;

/*normal|limited.member: exprTypeLiteral:Object*/
/*verbose.member: exprTypeLiteral:dart.core::Object*/
exprTypeLiteral() => Object;

/*member: exprVariableGet:variable*/
exprVariableGet(variable) => variable;

/*member: exprVariableSet:variable = 42*/
exprVariableSet(variable) => variable = 42;

/*normal|limited.member: exprInstanceFieldGet:variable.{Class.field}*/
/*verbose.member: exprInstanceFieldGet:variable.{expressions::Class.field}*/
exprInstanceFieldGet(Class variable) => variable.field;

/*normal|limited.member: exprInstanceGetterGet:variable.{Class.getter}*/
/*verbose.member: exprInstanceGetterGet:variable.{expressions::Class.getter}*/
exprInstanceGetterGet(Class variable) => variable.getter;

/*normal|limited.member: exprInstanceMethodTearOff:variable.{Class.method1}*/
/*verbose.member: exprInstanceMethodTearOff:variable.{expressions::Class.method1}*/
exprInstanceMethodTearOff(Class variable) => variable.method1;

/*member: exprDynamicGet:variable.field*/
exprDynamicGet(variable) => variable.field;

/*normal|limited.member: exprObjectGet:variable.{Object.runtimeType}*/
/*verbose.member: exprObjectGet:variable.{dart.core::Object.runtimeType}*/
exprObjectGet(variable) => variable.runtimeType;

/*normal|limited.member: exprInstanceFieldSet:variable.{Class.field} = 42*/
/*verbose.member: exprInstanceFieldSet:variable.{expressions::Class.field} = 42*/
exprInstanceFieldSet(Class variable) => variable.field = 42;

/*normal|limited.member: exprInstanceSetterSet:variable.{Class.setter} = 42*/
/*verbose.member: exprInstanceSetterSet:variable.{expressions::Class.setter} = 42*/
exprInstanceSetterSet(Class variable) => variable.setter = 42;

/*member: exprDynamicSet:variable.field = 42*/
exprDynamicSet(variable) => variable.field = 42;

/*normal|limited.member: exprInstanceInvocation1:variable.{Class.method1}()*/
/*verbose.member: exprInstanceInvocation1:variable.{expressions::Class.method1}()*/
exprInstanceInvocation1(Class variable) => variable.method1();

/*normal|limited.member: exprInstanceInvocation2:variable.{Class.method2}(42)*/
/*verbose.member: exprInstanceInvocation2:variable.{expressions::Class.method2}(42)*/
exprInstanceInvocation2(Class variable) => variable.method2(42);

/*normal|limited.member: exprInstanceInvocation3a:variable.{Class.method3}()*/
/*verbose.member: exprInstanceInvocation3a:variable.{expressions::Class.method3}()*/
exprInstanceInvocation3a(Class variable) => variable.method3();

/*normal|limited.member: exprInstanceInvocation3b:variable.{Class.method3}(42)*/
/*verbose.member: exprInstanceInvocation3b:variable.{expressions::Class.method3}(42)*/
exprInstanceInvocation3b(Class variable) => variable.method3(42);

/*normal|limited.member: exprInstanceInvocation4a:variable.{Class.method4}(42)*/
/*verbose.member: exprInstanceInvocation4a:variable.{expressions::Class.method4}(42)*/
exprInstanceInvocation4a(Class variable) => variable.method4(42);

/*normal|limited.member: exprInstanceInvocation4b:variable.{Class.method4}(42, 87)*/
/*verbose.member: exprInstanceInvocation4b:variable.{expressions::Class.method4}(42, 87)*/
exprInstanceInvocation4b(Class variable) => variable.method4(42, 87);

/*normal|limited.member: exprInstanceInvocation5a:variable.{Class.method5}()*/
/*verbose.member: exprInstanceInvocation5a:variable.{expressions::Class.method5}()*/
exprInstanceInvocation5a(Class variable) => variable.method5();

/*normal|limited.member: exprInstanceInvocation5b:variable.{Class.method5}(a: 42)*/
/*verbose.member: exprInstanceInvocation5b:variable.{expressions::Class.method5}(a: 42)*/
exprInstanceInvocation5b(Class variable) => variable.method5(a: 42);

/*normal|limited.member: exprInstanceInvocation6a:variable.{Class.method6}(42)*/
/*verbose.member: exprInstanceInvocation6a:variable.{expressions::Class.method6}(42)*/
exprInstanceInvocation6a(Class variable) => variable.method6(42);

/*normal|limited.member: exprInstanceInvocation6b:variable.{Class.method6}(42, b: 87)*/
/*verbose.member: exprInstanceInvocation6b:variable.{expressions::Class.method6}(42, b: 87)*/
exprInstanceInvocation6b(Class variable) => variable.method6(42, b: 87);

/*normal|limited.member: exprInstanceInvocation7a:variable.{Class.method7}()*/
/*verbose.member: exprInstanceInvocation7a:variable.{expressions::Class.method7}()*/
exprInstanceInvocation7a(Class variable) => variable.method7();

/*normal|limited.member: exprInstanceInvocation7b:variable.{Class.method7}(a: 42)*/
/*verbose.member: exprInstanceInvocation7b:variable.{expressions::Class.method7}(a: 42)*/
exprInstanceInvocation7b(Class variable) => variable.method7(a: 42);

/*normal|limited.member: exprInstanceInvocation7c:variable.{Class.method7}(b: 87)*/
/*verbose.member: exprInstanceInvocation7c:variable.{expressions::Class.method7}(b: 87)*/
exprInstanceInvocation7c(Class variable) => variable.method7(b: 87);

/*normal|limited.member: exprInstanceInvocation7d:variable.{Class.method7}(a: 42, b: 87)*/
/*verbose.member: exprInstanceInvocation7d:variable.{expressions::Class.method7}(a: 42, b: 87)*/
exprInstanceInvocation7d(Class variable) => variable.method7(a: 42, b: 87);

/*normal|limited.member: exprInstanceInvocation7e:variable.{Class.method7}(b: 87, a: 42)*/
/*verbose.member: exprInstanceInvocation7e:variable.{expressions::Class.method7}(b: 87, a: 42)*/
exprInstanceInvocation7e(Class variable) => variable.method7(b: 87, a: 42);

/*normal|limited.member: exprGenericInvocation1a:variable.{Class.genericMethod1}<dynamic>()*/
/*verbose.member: exprGenericInvocation1a:variable.{expressions::Class.genericMethod1}<dynamic>()*/
exprGenericInvocation1a(Class variable) => variable.genericMethod1();

/*normal|limited.member: exprGenericInvocation1b:variable.{Class.genericMethod1}<int>()*/
/*verbose.member: exprGenericInvocation1b:variable.{expressions::Class.genericMethod1}<dart.core::int>()*/
exprGenericInvocation1b(Class variable) => variable.genericMethod1<int>();

/*normal|limited.member: exprGenericInvocation2a:variable.{Class.genericMethod2}<dynamic, dynamic>()*/
/*verbose.member: exprGenericInvocation2a:variable.{expressions::Class.genericMethod2}<dynamic, dynamic>()*/
exprGenericInvocation2a(Class variable) => variable.genericMethod2();

/*normal|limited.member: exprGenericInvocation2b:variable.{Class.genericMethod2}<int, String>()*/
/*verbose.member: exprGenericInvocation2b:variable.{expressions::Class.genericMethod2}<dart.core::int, dart.core::String>()*/
exprGenericInvocation2b(Class variable) =>
    variable.genericMethod2<int, String>();

/*member: exprDynamicInvocation:variable.method1()*/
exprDynamicInvocation(variable) => variable.method1();

/*normal|limited.member: exprObjectInvocation:variable.{Object.toString}()*/
/*verbose.member: exprObjectInvocation:variable.{dart.core::Object.toString}()*/
exprObjectInvocation(variable) => variable.toString();

/*normal|limited.member: exprPrivateInstanceInvocation:variable.{Class._privateMethod}()*/
/*verbose.member: exprPrivateInstanceInvocation:variable.{expressions::Class._privateMethod}()*/
exprPrivateInstanceInvocation(Class variable) => variable._privateMethod();

/*normal|limited.member: exprPrivateDynamicInvocation:variable._privateMethod()*/
/*verbose.member: exprPrivateDynamicInvocation:variable.expressions::_privateMethod()*/
exprPrivateDynamicInvocation(variable) => variable._privateMethod();

/*normal|limited.member: exprTopLevelFieldGet:topLevelField*/
/*verbose.member: exprTopLevelFieldGet:expressions::topLevelField*/
exprTopLevelFieldGet() => topLevelField;

/*normal|limited.member: exprTopLevelGetterGet:topLevelGetter*/
/*verbose.member: exprTopLevelGetterGet:expressions::topLevelGetter*/
exprTopLevelGetterGet() => topLevelGetter;

/*normal|limited.member: exprTopLevelMethodTearOff:topLevelMethod*/
/*verbose.member: exprTopLevelMethodTearOff:expressions::topLevelMethod*/
exprTopLevelMethodTearOff() => topLevelMethod;

/*normal|limited.member: exprTopLevelFieldSet:topLevelField = 42*/
/*verbose.member: exprTopLevelFieldSet:expressions::topLevelField = 42*/
exprTopLevelFieldSet() => topLevelField = 42;

/*normal|limited.member: exprTopLevelSetterSet:topLevelSetter = 42*/
/*verbose.member: exprTopLevelSetterSet:expressions::topLevelSetter = 42*/
exprTopLevelSetterSet() => topLevelSetter = 42;

/*normal|limited.member: exprTopLevelMethodInvocation:topLevelMethod()*/
/*verbose.member: exprTopLevelMethodInvocation:expressions::topLevelMethod()*/
exprTopLevelMethodInvocation() => topLevelMethod();

/*normal|limited.member: exprStaticFieldGet:Class.staticField*/
/*verbose.member: exprStaticFieldGet:expressions::Class.staticField*/
exprStaticFieldGet() => Class.staticField;

/*normal|limited.member: exprStaticGetterGet:Class.staticGetter*/
/*verbose.member: exprStaticGetterGet:expressions::Class.staticGetter*/
exprStaticGetterGet() => Class.staticGetter;

/*normal|limited.member: exprStaticMethodTearOff:Class.staticMethod*/
/*verbose.member: exprStaticMethodTearOff:expressions::Class.staticMethod*/
exprStaticMethodTearOff() => Class.staticMethod;

/*normal|limited.member: exprStaticFieldSet:Class.staticField = 42*/
/*verbose.member: exprStaticFieldSet:expressions::Class.staticField = 42*/
exprStaticFieldSet() => Class.staticField = 42;

/*normal|limited.member: exprStaticSetterSet:Class.staticSetter = 42*/
/*verbose.member: exprStaticSetterSet:expressions::Class.staticSetter = 42*/
exprStaticSetterSet() => Class.staticSetter = 42;

/*normal|limited.member: exprStaticMethodInvocation:Class.staticMethod()*/
/*verbose.member: exprStaticMethodInvocation:expressions::Class.staticMethod()*/
exprStaticMethodInvocation() => Class.staticMethod();

/*normal|limited.member: exprInstantiation1:genericTopLevelMethod1<int>*/
/*verbose.member: exprInstantiation1:expressions::genericTopLevelMethod1<dart.core::int>*/
int Function(int) exprInstantiation1 = genericTopLevelMethod1;

/*normal|limited.member: exprInstantiation2:genericTopLevelMethod2<bool, String>*/
/*verbose.member: exprInstantiation2:expressions::genericTopLevelMethod2<dart.core::bool, dart.core::String>*/
bool Function(bool, String) exprInstantiation2 = genericTopLevelMethod2;

/*member: exprNot:!b*/
exprNot(bool b) => !b;

/*member: exprAnd:a && b*/
exprAnd(bool a, bool b) => a && b;

/*member: exprOr:a || b*/
exprOr(bool a, bool b) => a || b;

/*normal|limited.member: exprConditional1:c ?{int} 0 : 1*/
/*verbose.member: exprConditional1:c ?{dart.core::int} 0 : 1*/
exprConditional1(bool c) => c ? 0 : 1;

/*normal|limited.member: exprConditional2:c ?{List<num>} <num>[] : <int>[]*/
/*verbose.member: exprConditional2:c ?{dart.core::List<dart.core::num>} <dart.core::num>[] : <dart.core::int>[]*/
exprConditional2(bool c) => c ? <num>[] : <int>[];

/*member: exprStringConcatenation:"foo${a}bar${b}"*/
exprStringConcatenation(int a, int b) => 'foo${a}bar$b';

/*normal|limited.member: exprNew:new Class()*/
/*verbose.member: exprNew:new expressions::Class()*/
exprNew() => new Class();

/*normal|limited.member: exprNewNamed:new Class.named()*/
/*verbose.member: exprNewNamed:new expressions::Class.named()*/
exprNewNamed() => new Class.named();

/*normal|limited.member: exprNewGeneric:new GenericClass<int, bool>()*/
/*verbose.member: exprNewGeneric:new expressions::GenericClass<dart.core::int, dart.core::bool>()*/
exprNewGeneric() => new GenericClass<int, bool>();

/*normal|limited.member: exprNewGenericNamed:new GenericClass<int, bool>.named()*/
/*verbose.member: exprNewGenericNamed:new expressions::GenericClass<dart.core::int, dart.core::bool>.named()*/
exprNewGenericNamed() => new GenericClass<int, bool>.named();

/*normal|limited.member: exprIs:o is List<int>*/
/*verbose.member: exprIs:o is{ForNonNullableByDefault} dart.core::List<dart.core::int>*/
exprIs(o) => o is List<int>;

/*normal|limited.member: exprAs:o as List<int>*/
/*verbose.member: exprAs:o as{ForNonNullableByDefault} dart.core::List<dart.core::int>*/
exprAs(o) => o as List<int>;

/*member: exprNullCheck:o!*/
exprNullCheck(o) => o!;

/*member: exprThrow:throw "foo"*/
exprThrow() => throw "foo";

/*member: exprEmptyList:<dynamic>[]*/
exprEmptyList() => [];

/*normal|limited.member: exprEmptyTypedList:<int>[]*/
/*verbose.member: exprEmptyTypedList:<dart.core::int>[]*/
exprEmptyTypedList() => <int>[];

/*normal|limited.member: exprList:<int>[0, 1]*/
/*verbose.member: exprList:<dart.core::int>[0, 1]*/
exprList() => [0, 1];

/*normal|limited.member: exprEmptySet:<int>{}*/
/*verbose.member: exprEmptySet:<dart.core::int>{}*/
exprEmptySet() => <int>{};

/*normal|limited.member: exprSet:<int>{0, 1}*/
/*verbose.member: exprSet:<dart.core::int>{0, 1}*/
exprSet() => {0, 1};

/*member: exprEmptyMap:<dynamic, dynamic>{}*/
exprEmptyMap() => {};

/*normal|limited.member: exprEmptyTypedMap:<int, String>{}*/
/*verbose.member: exprEmptyTypedMap:<dart.core::int, dart.core::String>{}*/
exprEmptyTypedMap() => <int, String>{};

/*normal|limited.member: exprMap:<int, String>{0: "foo", 1: "bar"}*/
/*verbose.member: exprMap:<dart.core::int, dart.core::String>{0: "foo", 1: "bar"}*/
exprMap() => {0: "foo", 1: "bar"};

/*member: exprAwait:await o*/
exprAwait(o) async => await o;

/*member: exprLoadLibrary:prefix.loadLibrary()*/
exprLoadLibrary() => prefix.loadLibrary();

/*normal|limited.member: exprCheckLibraryIsLoaded:let final dynamic #0 = prefix.checkLibraryIsLoaded() in max<int>(0, 1)*/
/*verbose.member: exprCheckLibraryIsLoaded:let final dynamic #0 = prefix.checkLibraryIsLoaded() in dart.math::max<dart.core::int>(0, 1)*/
exprCheckLibraryIsLoaded() => prefix.max(0, 1);

/*normal|limited.member: exprFunctionExpression:int (int i) => i*/
/*verbose.member: exprFunctionExpression:dart.core::int (dart.core::int i) => i*/
exprFunctionExpression() => (int i) => i;

/*normal.member: exprFunctionExpressionBlock:int (int i) {
  return i;
}*/
/*verbose.member: exprFunctionExpressionBlock:dart.core::int (dart.core::int i) {
  return i;
}*/
/*limited.member: exprFunctionExpressionBlock:int (int i) { return i; }*/
exprFunctionExpressionBlock() => (int i) {
      return i;
    };

/*normal|limited.member: exprGenericFunctionExpression:T% <T extends Object?>(T% t) => t*/
/*verbose.member: exprGenericFunctionExpression:T% <T extends dart.core::Object?>(T% t) => t*/
exprGenericFunctionExpression() => <T>(T t) => t;

/*normal.member: exprGenericFunctionExpressionBlock:T% <T extends Object?>(T% t) {
  return t;
}*/
/*verbose.member: exprGenericFunctionExpressionBlock:T% <T extends dart.core::Object?>(T% t) {
  return t;
}*/
/*limited.member: exprGenericFunctionExpressionBlock:T% <T extends Object?>(T% t) { return t; }*/
exprGenericFunctionExpressionBlock() => <T>(T t) {
      return t;
    };

/*normal|limited.member: exprNullAware:let final Class? #0 = variable in #0 == null ?{dynamic} null : #0{Class}.{Class.field}*/
/*verbose.member: exprNullAware:let final expressions::Class? #0 = variable in #0 == null ?{dynamic} null : #0{expressions::Class}.{expressions::Class.field}*/
exprNullAware(Class? variable) => variable?.field;

/*normal|limited.member: exprIfNull:let final int? #0 = i in #0 == null ?{int} 42 : #0{int}*/
/*verbose.member: exprIfNull:let final dart.core::int? #0 = i in #0 == null ?{dart.core::int} 42 : #0{dart.core::int}*/
exprIfNull(int? i) => i ?? 42;

/*normal|limited.member: exprNestedDeep:<Object>[1, <Object>[2, <Object>[3, <int>[4]]]]*/
/*verbose.member: exprNestedDeep:<dart.core::Object>[1, <dart.core::Object>[2, <dart.core::Object>[3, <dart.core::int>[4]]]]*/
exprNestedDeep() => [
      1,
      [
        2,
        [
          3,
          [4]
        ]
      ]
    ];

/*normal.member: exprNestedTooDeep:<Object>[1, <Object>[2, <Object>[3, <Object>[4, <int>[5]]]]]*/
/*verbose.member: exprNestedTooDeep:<dart.core::Object>[1, <dart.core::Object>[2, <dart.core::Object>[3, <dart.core::Object>[4, <dart.core::int>[5]]]]]*/
/*limited.member: exprNestedTooDeep:<Object>[1, <Object>[2, <Object>[3, <Object>[4, <int>[...]]]]]*/
exprNestedTooDeep() => [
      1,
      [
        2,
        [
          3,
          [
            4,
            [5]
          ]
        ]
      ]
    ];

/*normal|limited.member: exprManySiblings:<int>[1, 2, 3, 4]*/
/*verbose.member: exprManySiblings:<dart.core::int>[1, 2, 3, 4]*/
exprManySiblings() => [1, 2, 3, 4];

/*normal.member: exprTooManySiblings:<int>[1, 2, 3, 4, 5]*/
/*verbose.member: exprTooManySiblings:<dart.core::int>[1, 2, 3, 4, 5]*/
/*limited.member: exprTooManySiblings:<int>[...]*/
exprTooManySiblings() => [1, 2, 3, 4, 5];

/*normal|limited.member: exprPrecedence1:1.{int.unary-}().{num.*}(2).{num.+}(3.{num./}(4)).{double.-}(5)*/
/*verbose.member: exprPrecedence1:1.{dart.core::int.unary-}().{dart.core::num.*}(2).{dart.core::num.+}(3.{dart.core::num./}(4)).{dart.core::double.-}(5)*/
exprPrecedence1() => -1 * 2 + 3 / 4 - 5;

/*normal|limited.member: exprPrecedence2:1.{num.*}(2.{num.+}(3)).{num./}(4.{num.-}(5)).{double.unary-}()*/
/*verbose.member: exprPrecedence2:1.{dart.core::num.*}(2.{dart.core::num.+}(3)).{dart.core::num./}(4.{dart.core::num.-}(5)).{dart.core::double.unary-}()*/
exprPrecedence2() => -(1 * (2 + 3) / (4 - 5));

/*normal|limited.member: exprPrecedence3:b ?{int} 0 : 1.{num.+}(2)*/
/*verbose.member: exprPrecedence3:b ?{dart.core::int} 0 : 1.{dart.core::num.+}(2)*/
exprPrecedence3(bool b) => b ? 0 : 1 + 2;

/*normal|limited.member: exprPrecedence4:(b ?{int} 0 : 1).{num.+}(2)*/
/*verbose.member: exprPrecedence4:(b ?{dart.core::int} 0 : 1).{dart.core::num.+}(2)*/
exprPrecedence4(bool b) => (b ? 0 : 1) + 2;

/*member: exprAssignmentEqualsNull1:(a = b) == null*/
exprAssignmentEqualsNull1(String a, String b) => (a = b) == null;

/*member: exprAssignmentEqualsNull2:a = b == null*/
exprAssignmentEqualsNull2(bool a, String b) => a = b == null;

/*member: exprAssignmentEqualsNull3:a = b == null*/
exprAssignmentEqualsNull3(bool a, String b) => a = (b == null);

/*member: exprAssignmentEquals1:(a = b) == c*/
exprAssignmentEquals1(String a, String b, String c) => (a = b) == c;

/*member: exprAssignmentEquals2:a = b == c*/
exprAssignmentEquals2(bool a, String b, String c) => a = b == c;

/*member: exprAssignmentEquals3:a = b == c*/
exprAssignmentEquals3(bool a, String b, String c) => a = (b == c);
