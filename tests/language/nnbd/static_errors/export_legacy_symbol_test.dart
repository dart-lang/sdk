// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=non-nullable

import 'export_legacy_symbol_opted_out_library.dart';

export 'export_legacy_symbol_opted_out_library.dart'; //# 01: compile-time error

export 'export_legacy_symbol_opted_out_library.dart' hide LegacyClass; //# 02: ok

main() {}
