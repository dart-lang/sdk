// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import "bad_import_2.dart" show a; // OK
import "bad_import_2.dart" show a as b show c; // Error
import "bad_import_2.dart" as b; // OK
