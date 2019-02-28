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

/*element: field3a:*/
final field3a = [];

/*element: field3b:*/
var field3b = [];

/*element: field3c:*/
var field3c = [];
