// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// The compiler previously crashed when using `--null-assertions` and tried to
/// insert a non-null assertion on record parameters.

// dart2jsOptions=--null-assertions

// @dart=2.19

import '52276_lib.dart';

main() => callFoo();
