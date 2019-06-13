// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  /*element: Super.field1:init,read=super*/
  var field1;

  /*element: Super.field2:init,write=super*/
  var field2;

  /*element: Super.field3:init,read=super*/
  var field3;

  /*element: Super.field4:init,read=super*/
  final field4;

  /*element: Super.field5:init,read=super*/
  final field5;

  /*element: Super.constructor1:invoke*/
  Super.constructor1(this.field4, this.field5);

  /*element: Super.constructor2:invoke=(0)*/
  Super.constructor2([this.field4, this.field5]);

  /*element: Super.constructor3:invoke=(1)*/
  Super.constructor3([this.field4, this.field5]);

  /*element: Super.method1:invoke=(1):super*/
  method1([a, b]) {}

  /*element: Super.method2:invoke,read=super*/
  method2([a, b]) {}

  /*element: Super.getter1:read=super*/
  get getter1 => null;

  /*element: Super.getter2:read=super*/
  get getter2 => null;

  /*element: Super.setter1=:write=super*/
  set setter1(_) {}

  /*element: Super.call:invoke=(0,a,b,c)*/
  void call({a, b, c, d}) {}
}

class Sub extends Super {
  /*element: Sub.constructor1:invoke=(1)*/
  Sub.constructor1([field4, field5]) : super.constructor1(field4, field5);

  /*element: Sub.constructor2:invoke*/
  Sub.constructor2() : super.constructor2();

  /*element: Sub.readSuperField:invoke*/
  readSuperField() {
    return super.field1;
  }

  /*element: Sub.writeSuperField:invoke*/
  writeSuperField() {
    super.field2 = null;
  }

  /*element: Sub.invokeSuperField:invoke*/
  invokeSuperField() {
    super.field3(a: 0);
  }

  /*element: Sub.readSuperFinalField:invoke*/
  readSuperFinalField() {
    return super.field4;
  }

  /*element: Sub.invokeSuperFinalField:invoke*/
  invokeSuperFinalField() {
    super.field5(b: 0);
  }

  /*element: Sub.invokeSuperMethod:invoke*/
  invokeSuperMethod() {
    super.method1(0);
  }

  /*element: Sub.readSuperMethod:invoke*/
  readSuperMethod() {
    return super.method2;
  }

  /*element: Sub.readSuperGetter:invoke*/
  readSuperGetter() {
    return super.getter1;
  }

  /*element: Sub.invokeSuperGetter:invoke*/
  invokeSuperGetter() {
    return super.getter2(c: 0);
  }

  /*element: Sub.writeSuperSetter:invoke*/
  writeSuperSetter() {
    super.setter1 = null;
  }
}

/*element: main:invoke*/
void main() {
  new Super.constructor3(null);
  new Sub.constructor1(null);
  new Sub.constructor2()
    ..readSuperField()
    ..writeSuperField()
    ..invokeSuperField()
    ..readSuperFinalField()
    ..invokeSuperFinalField()
    ..invokeSuperMethod()
    ..readSuperMethod()
    ..readSuperGetter()
    ..invokeSuperGetter()
    ..writeSuperSetter();
}
