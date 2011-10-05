// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Imported library has source file with library tags.

#library("Script2NegativeLib");
#import("ScriptLib.dart");
#source("Script2NegativeSource.dart");

class A {
  var a;
}
