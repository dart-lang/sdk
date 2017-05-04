// compile options: --emit-metadata
// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Run essentially the same test, but with emit-metadata compile option,
// which allows us to reflect on the fields.
import 'dart:mirrors';
import 'package:expect/expect.dart';

import 'field_metadata_test.dart' as field_metadata_test;
import 'field_metadata_test.dart' show Foo, Bar;

void main() {
  // Make sure the other test still works.
  field_metadata_test.main();

  // Check that we can now reflect on the annotations.
  dynamic f = new Foo();
  var members = reflect(f).type.declarations;
  var bar = members[#x].metadata.first.reflectee as Bar;
  Expect.equals(bar.name, 'bar');

  var baz = members[#y].metadata.first.reflectee as Bar;
  Expect.equals(baz.name, 'baz');
}
