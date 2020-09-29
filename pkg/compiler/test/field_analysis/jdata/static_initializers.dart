// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  print(field1a);
  print(field1b);
  field1c = null;
  print(field1c);

  print(field2a);
  print(field2b);
  field2c = null;
  print(field2c);

  print(field3a);
  print(field3b);
  field3c = null;
  print(field3c);
  print(field3d);
  print(field3e);
  print(field3f);
  print(field3g);
  print(field3h);

  print(field4a);
  print(field4b);
  print(field4c);

  print(field5a);
  print(field5b);
  print(field5c);

  print(field6a);
  print(field6b);
  print(field6c);

  print(field7a);
  print(field7b);
  print(field7c);
  print(field7d);
  print(field7e);

  print(field8a);
  print(field8b);
  print(field8c);
  print(field8d);

  print(field9a);
  print(field9b);
  print(field9c);
  print(field9d);
  field9e = null;
  print(field9e);
  print(field9f);
  print(field9g);
  print(field9h);
  print(field9i);

  print(field10a);
  print(field10b);
}

method() {}

class Class {
  const Class.generative();

  const factory Class.fact() = Class.generative;
}

/*member: field1a:constant=IntConstant(0)*/
final field1a = 0;

/*member: field1b:constant=IntConstant(0)*/
var field1b = 0;

/*member: field1c:initial=IntConstant(0)*/
var field1c = 0;

/*member: field2a:constant=ListConstant([])*/
final field2a = const [];

/*member: field2b:constant=ListConstant([])*/
var field2b = const [];

/*member: field2c:initial=ListConstant([])*/
var field2c = const [];

/*member: field3a:eager,final*/
final field3a = [];

/*member: field3b:eager,final*/
var field3b = [];

/*member: field3c:eager*/
var field3c = [];

/*member: field3d:eager,final*/
var field3d = [1, 2, 3];

/*member: field3e:eager,final*/
var field3e = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method]
  ]
];

/*member: field3f:final,lazy*/
var field3f = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method()]
  ]
];

/*member: field3g:final,lazy*/
var field3g = [method()];

/*member: field3h:final,eager*/
var field3h = [1 + 3];

/*member: field4a:constant=IntConstant(5)*/
final field4a = 2 + 3;

/*member: field4b:constant=IntConstant(5)*/
var field4b = 2 + 3;

const field4c = 2 + 3;

/*member: field5a:constant=FunctionConstant(method)*/
final field5a = method;

/*member: field5b:constant=FunctionConstant(method)*/
var field5b = method;

const field5c = method;

/*member: field6a:constant=ConstructedConstant(Class())*/
var field6a = const Class.generative();

/*member: field6b:constant=ConstructedConstant(Class())*/
var field6b = const Class.fact();

/*member: field6c:final,lazy*/
var field6c = method();

/*member: field7a:eager,final*/
var field7a = {};

/*member: field7b:eager,final*/
var field7b = {0: 1};

/*member: field7c:eager,final*/
var field7c = {0: method};

/*member: field7d:final,lazy*/
var field7d = {0: method()};

/*member: field7e:final,lazy*/
var field7e = {method(): 0};

/*member: field8a:eager,final*/
var field8a = {};

/*member: field8b:eager,final*/
var field8b = {0};

/*member: field8c:eager,final*/
var field8c = {method};

/*member: field8d:final,lazy*/
var field8d = {method()};

/*member: field9g:eager=[field9d],final,index=1*/
var field9g = field9d;

/*member: field9a:eager,final*/
var field9a = [];

/*member: field9c:eager=[field9b],final,index=3*/
var field9c = [field9b];

/*member: field9b:eager=[field9a],final,index=2*/
var field9b = field9a;

// Because [field9g] is declared first and it depends upon [field9d], [field9d]
// must be created before [field9g] and thus has a lower index than, say,
// [field9b].
/*member: field9d:eager=[field9a],final,index=0*/
var field9d = [field9a];

/*member: field9e:eager*/
var field9e = [];

/*member: field9f:final,lazy*/
var field9f = field9e;

/*member: field9h:constant=ListConstant([])*/
var field9h = const [];

/*member: field9i:eager,final*/
var field9i = [field9h];

/*member: field10a:final,lazy*/
int field10a = field10b;

/*member: field10b:final,lazy*/
int field10b = field10a;
