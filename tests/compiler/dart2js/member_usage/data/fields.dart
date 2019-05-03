// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/*element: field1a:init,read*/
var field1a;

/*element: field1b:init,write*/
var field1b;

/*element: field1c:init,read,write*/
var field1c;

// Invocations of static/top level fields are converted into 'field1d.call(...)`
// so we don't have an invocation of the field but instead an additional dynamic
// call to 'call'.
/*element: field1d:init,read*/
var field1d;

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

// Invocations of static/top level getters are converted into
// 'field2d.call(...)` so we don't have an invocation of the field but instead
// an additional dynamic call to 'call'.
/*element: field2d:read*/
get field2d => 42;

set field2d(_) {}

class Class {
  /*element: Class.field1a:init,read*/
  var field1a;

  /*element: Class.field1b:init,write*/
  var field1b;

  /*element: Class.field1c:init,read,write*/
  var field1c;

  /*element: Class.field1d:init,invoke,read=static*/
  var field1d;

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

  /*element: Class.field2d:invoke,read=static*/
  get field2d => null;

  set field2d(_) {}

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
    field1d();

    field2a;
    field2b = 42;
    field2c = field2c;
    field2d();
  }
}

/*element: main:invoke*/
main() {
  field1a;
  field1b = 42;
  field1c = field1c;
  field1d();

  field2a;
  field2b = 42;
  field2c = field2c;
  field2d();

  new Class().test();
}
