// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Declarations taken from
//    language/nnbd/mixed_inheritance/legacy_resolves_conflict_3_test

import 'mixin_from_opt_in_out_in_lib1.dart';
import 'mixin_from_opt_in_out_in_lib2.dart';

// Member signatures: B.
class DiB0 extends C0 implements B {}

// Member signatures: Bq.
class DiBq0 extends C0 implements Bq {}

// Member signatures: B.
class DwB0 extends C0 with B {}

// Member signatures: Bq.
class DwBq0 extends C0 with Bq {}

// Member signatures: legacy.
class DiB3 extends C3 implements B {}

// Member signatures: legacy.
class DiBq3 extends C3 implements Bq {}

// Member signatures: B.
class DwB3 extends C3 with B {}

// Member signatures: Bq.
class DwBq3 extends C3 with Bq {}

main() {}
