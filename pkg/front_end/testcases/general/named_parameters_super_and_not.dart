// Copyright (c) 2022, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Super {
  Super.named(num x, {bool y = false, String? z});
}

class SubNamed extends Super {
  SubNamed.namedAnywhere(double x, String z, {super.y}) : super.named(z: z, x);
}

main() {}
