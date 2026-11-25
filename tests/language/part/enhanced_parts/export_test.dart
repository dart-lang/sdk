// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// SharedOptions=--enable-experiment=enhanced-parts

import "export_lib.dart" as p;

void main() {
  // Check that all names are exported as expected.
  var vs = [
    p.cx,
    p.fx,
    p.vx,
    p.lx,
    p.gx,
    p.sx = 0,
    p.mx(),
    p.Cx(),
    p.Nx.x,
    p.Mx,
    p.Ex(0).x,
    p.Xx(0),
    p.Tx,
  ];
}
