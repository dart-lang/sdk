// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.8

// This library creates a legacy class which extends the generic class hierarchy
// defined in the imported library.  This is used to test how upper bounds
// behave when some super-interfaces come from opted in libraries and some from
// legacy libraries.

import 'superinterfaces_null_safe_lib.dart';

class Legacy extends Generic<int> {
  int legacyMethod() => 3;
}

var legacy = Legacy();
