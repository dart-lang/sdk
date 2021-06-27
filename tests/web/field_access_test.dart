// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test the all variants of field/property access/update are emitted.
//
// This is needed because getter/setters are now registered as read from and
// written to, respectively, instead of being invoked.

var field1a;

var field1b;

var field1c;

@pragma('dart2js:noInline')
get field2a => 42;

@pragma('dart2js:noInline')
set field2a(_) {}

@pragma('dart2js:noInline')
get field2b => 42;

@pragma('dart2js:noInline')
set field2b(_) {}

@pragma('dart2js:noInline')
get field2c => 42;

@pragma('dart2js:noInline')
set field2c(_) {}

class Class {
  @pragma('dart2js:noElision')
  var field1a;

  var field1b;

  var field1c;

  @pragma('dart2js:noInline')
  get field2a => 42;

  @pragma('dart2js:noInline')
  set field2a(_) {}

  @pragma('dart2js:noInline')
  get field2b => 42;

  @pragma('dart2js:noInline')
  set field2b(_) {}

  @pragma('dart2js:noInline')
  get field2c => 42;

  set field2c(_) {}

  var field3a = 0;

  var field3b;

  @pragma('dart2js:noInline')
  Class([this.field3b]);

  @pragma('dart2js:noInline')
  test() {
    field1a;
    field1b = 42;
    field1c = field1c;

    field2a;
    field2b = 42;
    field2c = field2c;
  }
}

main() {
  field1a;
  field1b = 42;
  field1c = field1c;

  field2a;
  field2b = 42;
  field2c = field2c;

  new Class().test();
}
