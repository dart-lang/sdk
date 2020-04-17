// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// Verify that conflicting implemented interfaces are resolved at a legacy
// class `C`, and an opted-in class can extend or implement `C` without
// incurring an error.

import 'package:expect/expect.dart';
import 'legacy_resolves_conflict_1_legacy_lib.dart';
import 'legacy_resolves_conflict_1_lib2.dart';

void main() {
  // Ensure that no class is eliminated by tree-shaking.
  Expect.isNotNull([
    De0, De0q, Di0, De1, De1q, Di1, De2, De2q, Di2, De3, //
    De3q, Di3, De4, De4q, Di4, De5, De5q, Di5, De6, De6q, //
    Di6, De7, De7q, Di7, De8, De8q, Di8, De9, De9q, Di9, //
    De10, De10q, Di10, De11, De11q, Di11, De12, De12q, Di12, De13, //
    De13q, Di13, De14, De14q, Di14, De15, De15q, Di15, De16, De16q, //
    Di16, De17, De17q, Di17, De18, De18q, Di18, De19, De19q, Di19, //
    De20, De20q, Di20, De21, De21q, Di21, De22, De22q, Di22, De23, //
    De23q, Di23, De24, De24q, Di24, De25, De25q, Di25, De26, De26q, //
    Di26, De27, De27q, Di27, De28, De28q, Di28, De29, De29q, Di29, //
    De30, De30q, Di30, De31, De31q, Di31, De32, De32q, Di32, De33, //
    De33q, Di33, De34, De34q, Di34, De35, De35q, Di35, De36, De36q, //
    Di36, De37, De37q, Di37, De38, De38q, Di38, De39, De39q, Di39, //
    De40, De40q, Di40, De41, De41q, Di41, De42, De42q, Di42, De43, //
    De43q, Di43, De44, De44q, Di44, De45, De45q, Di45, De46, De46q, //
    Di46, De47, De47q, Di47, De48, De48q, Di48, De49, De49q, Di49, //
    De50, De50q, Di50, De51, De51q, Di51, De52, De52q, Di52, De53, //
    De53q, Di53, De54, De54q, Di54, De55, De55q, Di55, De56, De56q, //
    Di56, De57, De57q, Di57, De58, De58q, Di58, De59, De59q, Di59, //
    De60, De60q, Di60, De61, De61q, Di61, De62, De62q, Di62, De63, //
    De63q, Di63, //
  ]);

  // Verify that concrete legacy classes implement `A<int*>`, thus allowing
  // `m(null).isEven` with no compile-time errors, but expect a dynamic error
  // because every implementation of `m` returns its argument.
  Expect.throws(() => C0().m(null).isEven);
  Expect.throws(() => C2().m(null).isEven);
  Expect.throws(() => C4().m(null).isEven);
  Expect.throws(() => C6().m(null).isEven);
  Expect.throws(() => C8().m(null).isEven);
  Expect.throws(() => C10().m(null).isEven);
  Expect.throws(() => C12().m(null).isEven);
  Expect.throws(() => C14().m(null).isEven);
  Expect.throws(() => C16().m(null).isEven);
  Expect.throws(() => C18().m(null).isEven);
  Expect.throws(() => C20().m(null).isEven);
  Expect.throws(() => C22().m(null).isEven);
  Expect.throws(() => C24().m(null).isEven);
  Expect.throws(() => C26().m(null).isEven);
  Expect.throws(() => C28().m(null).isEven);
  Expect.throws(() => C30().m(null).isEven);
  Expect.throws(() => C32().m(null).isEven);
  Expect.throws(() => C34().m(null).isEven);
  Expect.throws(() => C36().m(null).isEven);
  Expect.throws(() => C38().m(null).isEven);
  Expect.throws(() => C40().m(null).isEven);
  Expect.throws(() => C42().m(null).isEven);
  Expect.throws(() => C44().m(null).isEven);
  Expect.throws(() => C46().m(null).isEven);
  Expect.throws(() => C48().m(null).isEven);
  Expect.throws(() => C50().m(null).isEven);
  Expect.throws(() => C52().m(null).isEven);
  Expect.throws(() => C54().m(null).isEven);
  Expect.throws(() => C56().m(null).isEven);
  Expect.throws(() => C58().m(null).isEven);
  Expect.throws(() => C60().m(null).isEven);
  Expect.throws(() => C62().m(null).isEven);

  // Perform a similar check on the abstract classes.
  void testAbstractClasses(
      C1 c1,
      C3 c3,
      C5 c5,
      C7 c7,
      C9 c9,
      C11 c11,
      C13 c13,
      C15 c15,
      C17 c17,
      C19 c19,
      C21 c21,
      C23 c23,
      C25 c25,
      C27 c27,
      C29 c29,
      C31 c31,
      C33 c33,
      C35 c35,
      C37 c37,
      C39 c39,
      C41 c41,
      C43 c43,
      C45 c45,
      C47 c47,
      C49 c49,
      C51 c51,
      C53 c53,
      C55 c55,
      C57 c57,
      C59 c59,
      C61 c61,
      C63 c63) {
    c1.m(null).isEven;
    c3.m(null).isEven;
    c5.m(null).isEven;
    c7.m(null).isEven;
    c9.m(null).isEven;
    c11.m(null).isEven;
    c13.m(null).isEven;
    c15.m(null).isEven;
    c17.m(null).isEven;
    c19.m(null).isEven;
    c21.m(null).isEven;
    c23.m(null).isEven;
    c25.m(null).isEven;
    c27.m(null).isEven;
    c29.m(null).isEven;
    c31.m(null).isEven;
    c33.m(null).isEven;
    c35.m(null).isEven;
    c37.m(null).isEven;
    c39.m(null).isEven;
    c41.m(null).isEven;
    c43.m(null).isEven;
    c45.m(null).isEven;
    c47.m(null).isEven;
    c49.m(null).isEven;
    c51.m(null).isEven;
    c53.m(null).isEven;
    c55.m(null).isEven;
    c57.m(null).isEven;
    c59.m(null).isEven;
    c61.m(null).isEven;
    c63.m(null).isEven;
  }

  // Ensure that `testAbstractClasses` is not eliminated by tree-shaking,
  // but don't call it (so we avoid the need for actual arguments).
  print(testAbstractClasses);
}
