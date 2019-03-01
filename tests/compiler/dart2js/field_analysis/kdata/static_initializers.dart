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

  print(field4a);
  print(field4b);
  print(field4c);
}

/*element: field1a:complexity=constant,initial=IntConstant(0)*/
final field1a = 0;

/*element: field1b:complexity=constant,initial=IntConstant(0)*/
var field1b = 0;

/*element: field1c:complexity=constant,initial=IntConstant(0)*/
const field1c = 0;

/*element: field2a:complexity=constant,initial=ListConstant([])*/
final field2a = const [];

/*element: field2b:complexity=constant,initial=ListConstant([])*/
var field2b = const [];

/*element: field2c:complexity=constant,initial=ListConstant([])*/
const field2c = const [];

/*element: field3a:complexity=lazy*/
final field3a = [];

/*element: field3b:complexity=lazy*/
var field3b = [];

/*element: field3c:complexity=lazy*/
var field3c = [];

// TODO(johnniwinther): Recognize these as of constant complexity.
/*element: field4a:complexity=lazy,initial=IntConstant(5)*/
final field4a = 2 + 3;

/*element: field4b:complexity=lazy,initial=IntConstant(5)*/
var field4b = 2 + 3;

/*element: field4c:complexity=lazy,initial=IntConstant(5)*/
const field4c = 2 + 3;
