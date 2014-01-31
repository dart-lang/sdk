// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that reflection works on intercepted types.

import 'dart:mirrors';
import 'package:expect/expect.dart';

main() {
  // Make sure that reflecting on values of intercepted/native classes does
  // not crash.
  var intMembers = reflect(123).type.instanceMembers;
  Expect.isTrue(intMembers.containsKey(#compareTo));
  Expect.isTrue(intMembers.length > 15);
  // TODO(karlklose): reenable after fixing dartbug.com/16389
  // var listMembers = reflect([]).type.instanceMembers;
  // Expect.isTrue(listMembers.containsKey(#join));
  // Expect.isTrue(listMembers.length > 15);
  var stringMembers = reflect('hest').type.instanceMembers;
  Expect.isTrue(stringMembers.containsKey(#contains));
  Expect.isTrue(stringMembers.length > 15);
}
