// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: field1a:read,write*/
var field1a;

/*element: field1b:read,write*/
var field1b;

/*element: field1c:read,write*/
var field1c;

/*element: field2a:read*/
get field2a => 42;

set field2a(_) {}

get field2b => 42;

/*element: field2b=:write*/
set field2b(_) {}

/*element: field2c:read*/
get field2c => 42;

/*element: field2c=:write*/
set field2c(_) {}

/*element: Class.:invoke*/
class Class {
  /*element: Class.field1a:read,write*/
  var field1a;

  /*element: Class.field1b:read,write*/
  var field1b;

  /*element: Class.field1c:read,write*/
  var field1c;

  /*element: Class.field2a:read*/
  get field2a => 42;

  set field2a(_) {}

  get field2b => 42;

  /*element: Class.field2b=:write*/
  set field2b(_) {}

  /*element: Class.field2c:read*/
  get field2c => 42;

  /*element: Class.field2c=:write*/
  set field2c(_) {}

  /*element: Class.test:invoke*/
  test() {
    field1a;
    field1b = 42;
    field1c = field1c;

    field2a;
    field2b = 42;
    field2c = field2c;
  }
}

/*element: main:invoke*/
main() {
  field1a;
  field1b = 42;
  field1c = field1c;

  field2a;
  field2b = 42;
  field2c = field2c;

  new Class().test();
}
