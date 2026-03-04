// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Private named parameters can't be used in older language versions.

// @dart=3.10

import 'package:expect/expect.dart';

class C {
  final String _foo;

  C({required this._foo});
  //               ^^^^
  // [analyzer] SYNTACTIC_ERROR.EXPERIMENT_NOT_ENABLED
  // [cfe] The 'private-named-parameters' language feature is disabled for this library.
}

void main() {}
