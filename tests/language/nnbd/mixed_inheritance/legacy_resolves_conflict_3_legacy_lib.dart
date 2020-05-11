// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// Import two null-safe classes `B` and `Bq` which contain the same member
// names with types that are compatible except that they differ in nullability.
// Declare legacy classes that has either `B` or `Bq` as a superinterface.

// The absence of errors in this test is unremarkable (there are no conflicts),
// but it allows for a null-safe subtype to declare overriding members, cf.
// 'legacy_resolves_conflict_3_lib2.dart'.

import 'legacy_resolves_conflict_3_lib.dart';

// Naming convention: Class `C#`, where `#` is just a running counter, has
// a single legacy class (`B` or `Bq`) as a superinterface. The point is that
// we wish to test the treatment of a legacy class when there is no conflict
// among its opted-in superinterfaces: `C#` is considered to implement
// `A<int*>`, for all `#`.

class C0 extends B {}

class C1 with B {}

abstract class C2 implements B {}

class C3 extends Bq {}

class C4 with Bq {}

abstract class C5 implements Bq {}
