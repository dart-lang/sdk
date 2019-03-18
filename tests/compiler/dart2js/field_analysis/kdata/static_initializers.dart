// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/*element: field1a:complexity=constant,initial=IntConstant(0)*/
final field1a = 0;

/*element: field1b:complexity=constant,initial=IntConstant(0)*/
var field1b = 0;

/*strong.element: field1c:complexity=constant,initial=IntConstant(0)*/
const field1c = 0;

/*element: field2a:complexity=constant,initial=ListConstant([])*/
final field2a = const [];

/*element: field2b:complexity=constant,initial=ListConstant([])*/
var field2b = const [];

/*strong.element: field2c:complexity=constant,initial=ListConstant([])*/
const field2c = const [];

/*element: field3a:complexity=eager*/
final field3a = [];

/*element: field3b:complexity=eager*/
var field3b = [];

/*element: field3c:complexity=eager*/
var field3c = [];

/*element: field3d:complexity=eager*/
var field3d = [1, 2, 3];

/*element: field3e:complexity=eager*/
var field3e = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method]
  ]
];

/*element: field3f:complexity=lazy*/
var field3f = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method()]
  ]
];

/*element: field3g:complexity=lazy*/
var field3g = [method()];

// TODO(johnniwinther): Recognize this as of eager complexity.
/*element: field3h:complexity=lazy*/
var field3h = [1 + 3];

// TODO(johnniwinther): Recognize `field4*` as of constant complexity.
/*element: field4a:complexity=lazy,initial=IntConstant(5)*/
final field4a = 2 + 3;

/*element: field4b:complexity=lazy,initial=IntConstant(5)*/
var field4b = 2 + 3;

/*strong.element: field4c:complexity=lazy,initial=IntConstant(5)*/
const field4c = 2 + 3;

/*element: field5a:complexity=constant,initial=FunctionConstant(method)*/
final field5a = method;

/*element: field5b:complexity=constant,initial=FunctionConstant(method)*/
var field5b = method;

/*strong.element: field5c:complexity=constant,initial=FunctionConstant(method)*/
const field5c = method;

/*element: field6a:complexity=constant,initial=ConstructedConstant(Class())*/
var field6a = const Class.generative();

/*element: field6b:complexity=constant,initial=ConstructedConstant(Class())*/
var field6b = const Class.fact();

/*element: field6c:complexity=lazy*/
var field6c = method();

/*element: field7a:complexity=eager*/
var field7a = {};

/*element: field7b:complexity=eager*/
var field7b = {0: 1};

/*element: field7c:complexity=eager*/
var field7c = {0: method};

/*element: field7d:complexity=lazy*/
var field7d = {0: method()};

/*element: field7e:complexity=lazy*/
var field7e = {method(): 0};

/*element: field8a:complexity=eager*/
var field8a = {};

/*element: field8b:complexity=eager*/
var field8b = {0};

/*element: field8c:complexity=eager*/
var field8c = {method};

/*element: field8d:complexity=lazy*/
var field8d = {method()};

/*element: field9a:complexity=eager*/
var field9a = [];

/*element: field9b:complexity=eager&fields=[field9a]*/
var field9b = field9a;

/*element: field9c:complexity=eager&fields=[field9b]*/
var field9c = [field9b];

/*element: field10a:complexity=eager&fields=[field10b]*/
int field10a = field10b;

/*element: field10b:complexity=eager&fields=[field10a]*/
int field10b = field10a;
