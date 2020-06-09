// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// This test checks that when a generic method from an opted-in library is
// overridden by a method from an opted-out library, the bounds are checked to
// be mutual subtypes, and not for equality.  Otherwise, it would be impossible
// to override a generic method with a default bound with another generic method
// with a default bound.

import './mixed_mode_hierarchy_generic_methods_lib.dart';
import "dart:async";

class B implements A<int> {
  then<B>() => Future<B>.value();
}

main() {}
