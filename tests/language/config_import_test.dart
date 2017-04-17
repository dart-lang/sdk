// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// DartOptions=-Did=true -Ddotted.id=some_string -Dlots.of.dots.In.id=false
// VMOptions=-Did=true -Ddotted.id=some_string -Dlots.of.dots.In.id=false

import 'package:expect/expect.dart';

import 'config_import_lib1a.dart'
    if (id) 'config_import_lib1b.dart'
    if (not.set.id) 'config_import_lib1c.dart';

import 'config_import_lib2a.dart'
    if (not.set.id) 'config_import_lib2b.dart'
    if (not.set.either) 'config_import_lib2c.dart';

import 'config_import_lib3a.dart'
    if (dotted.id == "some_string") 'config_import_lib3b.dart'
    if (id) 'config_import_lib3c.dart';

import 'config_import_lib4a.dart'
    if (lots.of.dots.In.id == "other") 'config_import_lib4b.dart'
    if (lots.of.dots.In.id == "false") 'config_import_lib4c.dart';

main() {
  Expect.equals("b", lib1());
  Expect.equals("a", lib2());
  Expect.equals("b", lib3());
  Expect.equals("c", lib4());
}
