// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'multi_export_lib1.dart' as lib;
import 'multi_export_lib2.dart' as lib;
import 'multi_export_lib3.dart' as lib;
import 'multi_export_lib4.dart' as lib;

main() {
  lib.SubClass1()..method();
  lib.SubClass2()..method();
  lib.SubClass3()..method();
  lib.SubClass4()..method();
}
