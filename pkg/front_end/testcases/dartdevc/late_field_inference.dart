// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

final a1 = a2;

late final a2 = 0;

final b1 = E.b2;

final c1 = () {
  c2 = 0;
};

late var c2 = 0;

final d1 = E.d2;

final e1 = () {
  E.e2 = 0;
};

// TODO(johnniwinther): Support these erroneous cases.
// final f1 = 0.f2;
//
// final g1 = () {
//   0.g2 = 0;
// };

extension E on int {
  static late final b2 = 0;

  static final d2 = 0;

  static late var e2 = 0;

  // TODO(johnniwinther): Support these erroneous cases.
  // var f2 = 0;
  //
  // var g2 = 0;
}
