// Copyright (c) 2025, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// All kinds of top-level declarations that can be imported.
// Duplicate of lib_decl.dart used to test conflicting exports.

const int cx = 0;
final int fx = 0;
int vx = 0;
late int lx = 0;
int get gx => 0;
set sx(int _) {}
int mx() => 0;

class Cx {}

enum Nx { x }

mixin Mx {}

extension Ex on Object {
  int get x => 0;
}

extension type Xx(int _) {}

typedef Tx = int;
