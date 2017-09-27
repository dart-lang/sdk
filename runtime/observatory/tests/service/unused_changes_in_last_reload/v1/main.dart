// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';

unchangedFunction() => "unchanged";
var unchangedField = "unchanged".toString();

removedFunction() => "removed";
var removedField = "removed".toString();

function() => "original value";
var uninitializedField = "original initializer".toString();
var fieldLiteralInitializer = "original initializer";
var initializedField = "original initializer".toString();
var neverReferencedField = "original initializer".toString();

// Not initially finalized.
class C {
  function() => "original value";
}

main() {
  new RawReceivePort();  // Keep alive.
  print(function());
  print(initializedField);
}
