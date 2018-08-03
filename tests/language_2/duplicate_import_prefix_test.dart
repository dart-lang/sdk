// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Importing with a duplicate prefix is allowed.

import "duplicate_import_liba.dart" as a;
import "duplicate_import_libb.dart" as a;

void main() {}
