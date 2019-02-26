// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: field1a:init,read*/
var field1a;

/*element: field1b:init,write*/
var field1b;

/*element: field1c:init,read,write*/
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

class Class {
  /*element: Class.field1a:init,read*/
  var field1a;

  /*element: Class.field1b:init,write*/
  var field1b;

  /*element: Class.field1c:init,read,write*/
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

  /*element: Class.field3a:init*/
  var field3a = 0;

  /*element: Class.field3b:init*/
  var field3b;

  /*element: Class.:invoke=(0)*/
  Class([this.field3b]);

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
