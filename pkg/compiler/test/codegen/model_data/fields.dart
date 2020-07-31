// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

var field1a;

var field1b;

var field1c;

/*member: field2a:params=0*/
@pragma('dart2js:noInline')
get field2a => 42;

@pragma('dart2js:noInline')
set field2a(_) {}

@pragma('dart2js:noInline')
get field2b => 42;

/*member: field2b=:params=1*/
@pragma('dart2js:noInline')
set field2b(_) {}

/*member: field2c:params=0*/
@pragma('dart2js:noInline')
get field2c => 42;

/*member: field2c=:params=1*/
@pragma('dart2js:noInline')
set field2c(_) {}

class Class {
  /*member: Class.field1a:emitted*/
  @pragma('dart2js:noElision')
  var field1a;

  /*member: Class.field1b:elided*/
  var field1b;

  /*member: Class.field1c:emitted*/
  var field1c;

  /*member: Class.field2a:params=0*/
  @pragma('dart2js:noInline')
  get field2a => 42;

  @pragma('dart2js:noInline')
  set field2a(_) {}

  @pragma('dart2js:noInline')
  get field2b => 42;

  /*member: Class.field2b=:params=1*/
  @pragma('dart2js:noInline')
  set field2b(_) {}

  /*member: Class.field2c:params=0*/
  @pragma('dart2js:noInline')
  get field2c => 42;

  set field2c(_) {}

  /*member: Class.field3a:elided*/
  var field3a = 0;

  /*member: Class.field3b:elided*/
  var field3b;

  /*member: Class.:params=0*/
  @pragma('dart2js:noInline')
  Class([this.field3b]);

  /*member: Class.test:calls=[get$field2a(0),get$field2c(0),set$field2b(1)],params=0*/
  @pragma('dart2js:noInline')
  test() {
    field1a;
    field1b = 42;
    field1c = field1c;

    field2a;
    field2b = 42;
    field2c = field2c;
  }
}

/*member: main:calls=[Class$(0),field2a(0),field2b(1),field2c(0),field2c0(1),test$0(0)],params=0*/
main() {
  field1a;
  field1b = 42;
  field1c = field1c;

  field2a;
  field2b = 42;
  field2c = field2c;

  new Class().test();
}
