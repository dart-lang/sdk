// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "optional_named_parameters_test.dart" show Application;

main() {
  // Only insert forwarders for generative constructors.
  new Application();
  //  ^^^^^^^^^^^
  // [analyzer] COMPILE_TIME_ERROR.NEW_WITH_UNDEFINED_CONSTRUCTOR_DEFAULT
  // [cfe] Couldn't find constructor 'Application'.
}
