// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Requirements=nnbd-weak

// Verifies that a member declared in a null-safe class which overrides
// a legacy member with the same name gets a null-safe signature instead of
// inheriting the legacy signature from the super-interface (concretely,
// it is not the signature from `A<int*>`).

import 'legacy_resolves_conflict_1_lib2.dart';

void main() {
  // All classes named `De..` override `m`. The ones whose name ends in `q`
  // do not admit invoking `isEven`; the remaining ones do not admit passing
  // null as the parameter to `m`.

  De0().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De0q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De1().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De1q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De2().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De2q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De3().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De3q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De4().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De4q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De5().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De5q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De6().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De6q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De7().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De7q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De8().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De8q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De9().m(null).isEven;
//        ^
// [analyzer] unspecified
// [cfe] unspecified

  De9q().m(null).isEven;
//               ^
// [analyzer] unspecified
// [cfe] unspecified

  De10().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De10q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De11().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De11q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De12().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De12q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De13().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De13q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De14().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De14q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De15().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De15q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De16().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De16q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De17().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De17q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De18().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De18q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De19().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De19q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De20().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De20q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De21().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De21q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De22().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De22q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De23().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De23q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De24().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De24q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De25().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De25q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De26().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De26q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De27().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De27q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De28().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De28q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De29().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De29q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De30().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De30q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De31().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De31q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De32().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De32q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De33().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De33q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De34().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De34q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De35().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De35q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De36().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De36q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De37().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De37q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De38().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De38q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De39().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De39q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De40().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De40q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De41().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De41q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De42().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De42q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De43().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De43q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De44().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De44q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De45().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De45q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De46().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De46q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De47().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De47q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De48().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De48q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De49().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De49q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De50().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De50q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De51().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De51q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De52().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De52q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De53().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De53q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De54().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De54q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De55().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De55q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De56().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De56q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De57().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De57q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De58().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De58q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De59().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De59q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De60().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De60q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De61().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De61q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De62().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De62q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified

  De63().m(null).isEven;
//         ^
// [analyzer] unspecified
// [cfe] unspecified

  De63q().m(null).isEven;
//                ^
// [analyzer] unspecified
// [cfe] unspecified
}
