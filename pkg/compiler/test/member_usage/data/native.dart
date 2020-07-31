// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

// ignore: import_internal_library
import 'dart:_js_helper';

/*member: field2a:read*/
@JSName('field2a')
get field2a => 42;

@JSName('field2a')
set field2a(_) {}

@JSName('field2b')
get field2b => 42;

/*member: field2b=:write*/
@JSName('field2b')
set field2b(_) {}

/*member: field2c:read*/
@JSName('field2c')
get field2c => 42;

/*member: field2c=:write*/
@JSName('field2c')
set field2c(_) {}

@Native('Class')
class Class {
  /*member: Class.field1a:read*/
  var field1a;

  /*member: Class.field1b:write*/
  var field1b;

  /*member: Class.field1c:read,write*/
  var field1c;

  /*member: Class.field2a:read*/
  get field2a => 42;

  set field2a(_) {}

  get field2b => 42;

  /*member: Class.field2b=:write*/
  set field2b(_) {}

  /*member: Class.field2c:read*/
  get field2c => 42;

  /*member: Class.field2c=:write*/
  set field2c(_) {}

  var field3a = 0;

  /*member: Class.field3b:init*/
  var field3b;

  /*member: Class.:invoke=(0)*/
  Class([this.field3b]);

  /*member: Class.test:invoke*/
  test() {
    field1a;
    field1b = 42;
    field1c = field1c;

    field2a;
    field2b = 42;
    field2c = field2c;
  }
}

/*member: main:invoke*/
main() {
  field2a;
  field2b = 42;
  field2c = field2c;

  new Class().test();
}
