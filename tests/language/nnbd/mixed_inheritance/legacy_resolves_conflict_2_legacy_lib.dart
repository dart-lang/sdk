// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.6

// Import two null-safe classes `B` and `Bq` which contain the same member
// names with types which are compatible except that they differ in
// nullability. Declare legacy classes that embody a conflict by having
// both `B` and `Bq` as superinterfaces. The absence of errors in this test
// verifies that member signature compatibility in legacy libraries is done
// with respect to the nullability erased signatures.

import 'legacy_resolves_conflict_2_lib.dart';

// Naming convention: We iterate over all ways `B` and `Bq` can be direct
// superinterfaces of a class C, and the latter is named `C#` where `#` is
// simply a running counter (because it seems to be of limited value to
// encode the way `B` and `Bq` are used as superinterfaces). Note that `C2`
// and `C5` must be abstract, because we do not wish to declare any members
// in these classes such that they can be concrete.

class C0 extends B implements Bq {}

class C1 extends B with Bq {}

abstract class C2 implements B, Bq {}

class C3 extends Bq implements B {}

class C4 extends Bq with B {}

abstract class C5 implements Bq, B {}
