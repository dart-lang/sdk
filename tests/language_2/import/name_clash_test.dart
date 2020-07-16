// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Check that a library name clash is not an error.

import "name_clash_lib1.dart";
import "name_clash_lib2.dart";

export "name_clash_lib1.dart";
export "name_clash_lib2.dart";

main() {}
