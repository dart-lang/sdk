// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart=2.6

import "continue_inference_after_error_lib.dart" as lib;

class C {}

test() {
  lib(new C().missing());
}

main() {}
