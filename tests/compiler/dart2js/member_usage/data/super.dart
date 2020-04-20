// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

class Super {
  /*member: Super.field1:init,read=super*/
  var field1;

  /*member: Super.field2:init,write=super*/
  var field2;

  /*member: Super.field3:init,read=super*/
  var field3;

  /*member: Super.field4:init,read=super*/
  final field4;

  /*member: Super.field5:init,read=super*/
  final field5;

  /*member: Super.constructor1:invoke*/
  Super.constructor1(this.field4, this.field5);

  /*member: Super.constructor2:invoke=(0)*/
  Super.constructor2([this.field4, this.field5]);

  /*member: Super.constructor3:invoke=(1)*/
  Super.constructor3([this.field4, this.field5]);

  /*member: Super.method1:invoke=(1):super*/
  method1([a, b]) {}

  /*member: Super.method2:invoke,read=super*/
  method2([a, b]) {}

  /*member: Super.getter1:read=super*/
  get getter1 => null;

  /*member: Super.getter2:read=super*/
  get getter2 => null;

  /*member: Super.setter1=:write=super*/
  set setter1(_) {}

  /*member: Super.call:invoke=(0,a,b,c)*/
  void call({a, b, c, d}) {}
}

class Sub extends Super {
  /*member: Sub.constructor1:invoke=(1)*/
  Sub.constructor1([field4, field5]) : super.constructor1(field4, field5);

  /*member: Sub.constructor2:invoke*/
  Sub.constructor2() : super.constructor2();

  /*member: Sub.readSuperField:invoke*/
  readSuperField() {
    return super.field1;
  }

  /*member: Sub.writeSuperField:invoke*/
  writeSuperField() {
    super.field2 = null;
  }

  /*member: Sub.invokeSuperField:invoke*/
  invokeSuperField() {
    super.field3(a: 0);
  }

  /*member: Sub.readSuperFinalField:invoke*/
  readSuperFinalField() {
    return super.field4;
  }

  /*member: Sub.invokeSuperFinalField:invoke*/
  invokeSuperFinalField() {
    super.field5(b: 0);
  }

  /*member: Sub.invokeSuperMethod:invoke*/
  invokeSuperMethod() {
    super.method1(0);
  }

  /*member: Sub.readSuperMethod:invoke*/
  readSuperMethod() {
    return super.method2;
  }

  /*member: Sub.readSuperGetter:invoke*/
  readSuperGetter() {
    return super.getter1;
  }

  /*member: Sub.invokeSuperGetter:invoke*/
  invokeSuperGetter() {
    return super.getter2(c: 0);
  }

  /*member: Sub.writeSuperSetter:invoke*/
  writeSuperSetter() {
    super.setter1 = null;
  }
}

/*member: main:invoke*/
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
