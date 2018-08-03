// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Test that it is not a compile-time error to reexport the same elements
// through different paths.

library duplicate_export_test;

export 'duplicate_import_liba.dart';
export 'duplicate_export_liba.dart'; // reexports 'duplicate_import_liba.dart'.

void main() {}
