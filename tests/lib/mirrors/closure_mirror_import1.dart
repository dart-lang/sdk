// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library closure_mirror_import1;

export "closure_mirror_import2.dart" show firstGlobalVariableInImport2;

var globalVariableInImport1 = "globalVariableInImport1";

globalFunctionInImport1() => "globalFunctionInImport1";

class StaticClass {
  static var staticField = "staticField";

  static staticFunctionInStaticClass() => "staticFunctionInStaticClass";
}
