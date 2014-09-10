// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that deferred loader analyzer doesn't trip over unused classes.

import "package:expect/expect.dart";
import 'dart:async';

import 'deferred_class_library.dart' deferred as lib;

class Base {}

class DerivedNotUsed extends Base {}

main() {
}
