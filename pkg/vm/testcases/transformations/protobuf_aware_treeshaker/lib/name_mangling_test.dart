// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test/test.dart';

import 'generated/name_mangling.pb.dart';

main() {
  NameManglingKeep n = NameManglingKeep.fromBuffer([]);
  if (n.hasClone_10()) {
    print("Has clone field");
  }
}
