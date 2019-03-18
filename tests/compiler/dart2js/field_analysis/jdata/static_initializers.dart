// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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

/*element: field1a:constant=IntConstant(0)*/
final field1a = 0;

/*element: field1b:constant=IntConstant(0)*/
var field1b = 0;

/*element: field1c:initial=IntConstant(0)*/
var field1c = 0;

/*element: field2a:constant=ListConstant([])*/
final field2a = const [];

/*element: field2b:constant=ListConstant([])*/
var field2b = const [];

/*element: field2c:initial=ListConstant([])*/
var field2c = const [];

/*element: field3a:eager,final*/
final field3a = [];

/*element: field3b:eager,final*/
var field3b = [];

/*element: field3c:eager*/
var field3c = [];

/*element: field3d:eager,final*/
var field3d = [1, 2, 3];

/*element: field3e:eager,final*/
var field3e = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method]
  ]
];

/*element: field3f:final,lazy*/
var field3f = [
  1,
  2,
  [
    3,
    4,
    [5, 6, method()]
  ]
];

/*element: field3g:final,lazy*/
var field3g = [method()];

// TODO(johnniwinther): Recognize this as of eager complexity.
/*element: field3h:final,lazy*/
var field3h = [1 + 3];

/*element: field4a:constant=IntConstant(5)*/
final field4a = 2 + 3;

/*element: field4b:constant=IntConstant(5)*/
var field4b = 2 + 3;

/*element: field4c:constant=IntConstant(5)*/
const field4c = 2 + 3;

/*element: field5a:constant=FunctionConstant(method)*/
final field5a = method;

/*element: field5b:constant=FunctionConstant(method)*/
var field5b = method;

/*element: field5c:constant=FunctionConstant(method)*/
const field5c = method;

/*element: field6a:constant=ConstructedConstant(Class())*/
var field6a = const Class.generative();

/*element: field6b:constant=ConstructedConstant(Class())*/
var field6b = const Class.fact();

/*element: field6c:final,lazy*/
var field6c = method();

/*element: field7a:eager,final*/
var field7a = {};

/*element: field7b:eager,final*/
var field7b = {0: 1};

/*element: field7c:eager,final*/
var field7c = {0: method};

/*element: field7d:final,lazy*/
var field7d = {0: method()};

/*element: field7e:final,lazy*/
var field7e = {method(): 0};

/*element: field8a:eager,final*/
var field8a = {};

/*element: field8b:eager,final*/
var field8b = {0};

/*element: field8c:eager,final*/
var field8c = {method};

/*element: field8d:final,lazy*/
var field8d = {method()};

/*element: field9g:eager=[field9d],final,index=1*/
var field9g = field9d;

/*element: field9a:eager,final*/
var field9a = [];

/*element: field9c:eager=[field9b],final,index=3*/
var field9c = [field9b];

/*element: field9b:eager=[field9a],final,index=2*/
var field9b = field9a;

// Because [field9g] is declared first and it depends upon [field9d], [field9d]
// must be created before [field9g] and thus has a lower index than, say,
// [field9b].
/*element: field9d:eager=[field9a],final,index=0*/
var field9d = [field9a];

/*element: field9e:eager*/
var field9e = [];

/*element: field9f:final,lazy*/
var field9f = field9e;

/*element: field9h:constant=ListConstant([])*/
var field9h = const [];

/*element: field9i:eager,final*/
var field9i = [field9h];

/*element: field10a:final,lazy*/
int field10a = field10b;

/*element: field10b:final,lazy*/
int field10b = field10a;
