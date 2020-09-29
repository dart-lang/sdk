// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

main() {
  print(field1a);
  print(field1b);
  print(field1c);

  print(field2a);
  print(field2b);
  print(field2c);

  print(field3a);
  print(field3b);
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

  print(field10a);
  print(field10b);
}

method() {}

class Class {
  const Class.generative();

  const factory Class.fact() = Class.generative;
}

/*member: field1a:complexity=constant,initial=IntConstant(0)*/
final field1a = 0;

/*member: field1b:complexity=constant,initial=IntConstant(0)*/
var field1b = 0;

const field1c = 0;

/*member: field2a:complexity=constant,initial=ListConstant([])*/
final field2a = const [];

/*member: field2b:complexity=constant,initial=ListConstant([])*/
var field2b = const [];

const field2c = const [];

/*member: field3a:complexity=eager*/
final field3a = [];

/*member: field3b:complexity=eager*/
var field3b = [];

/*member: field3c:complexity=eager*/
var field3c = [];

/*member: field3d:complexity=eager*/
var field3d = [1, 2, 3];

/*member: field3e:complexity=eager*/
var field3e = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method]
  ]
];

/*member: field3f:complexity=lazy*/
var field3f = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method()]
  ]
];

/*member: field3g:complexity=lazy*/
var field3g = [method()];

/*member: field3h:complexity=eager*/
var field3h = [1 + 3];

/*member: field4a:complexity=constant,initial=IntConstant(5)*/
final field4a = 2 + 3;

/*member: field4b:complexity=constant,initial=IntConstant(5)*/
var field4b = 2 + 3;

const field4c = 2 + 3;

/*member: field5a:complexity=constant,initial=FunctionConstant(method)*/
final field5a = method;

/*member: field5b:complexity=constant,initial=FunctionConstant(method)*/
var field5b = method;

const field5c = method;

/*member: field6a:complexity=constant,initial=ConstructedConstant(Class())*/
var field6a = const Class.generative();

/*member: field6b:complexity=constant,initial=ConstructedConstant(Class())*/
var field6b = const Class.fact();

/*member: field6c:complexity=lazy*/
var field6c = method();

/*member: field7a:complexity=eager*/
var field7a = {};

/*member: field7b:complexity=eager*/
var field7b = {0: 1};

/*member: field7c:complexity=eager*/
var field7c = {0: method};

/*member: field7d:complexity=lazy*/
var field7d = {0: method()};

/*member: field7e:complexity=lazy*/
var field7e = {method(): 0};

/*member: field8a:complexity=eager*/
var field8a = {};

/*member: field8b:complexity=eager*/
var field8b = {0};

/*member: field8c:complexity=eager*/
var field8c = {method};

/*member: field8d:complexity=lazy*/
var field8d = {method()};

/*member: field9a:complexity=eager*/
var field9a = [];

/*member: field9b:complexity=eager&fields=[field9a]*/
var field9b = field9a;

/*member: field9c:complexity=eager&fields=[field9b]*/
var field9c = [field9b];

/*member: field10a:complexity=eager&fields=[field10b]*/
int field10a = field10b;

/*member: field10b:complexity=eager&fields=[field10a]*/
int field10b = field10a;
