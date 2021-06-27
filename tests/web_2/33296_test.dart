// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

import 'dart:js';
import 'dart:html'; // TODO(33316): Remove.
import "package:expect/expect.dart";

main() {
  var f = () => [];
  Expect.isTrue(f is List Function());
  Expect.isFalse(f is int Function(int));

  var g = allowInterop(f);
  // g is inferred to have the same type as f.
  Expect.isTrue(g is List Function());
  // The JavaScriptFunction matches any function type.
  Expect.isTrue(g is int Function(int));

  if (false) new DivElement(); // TODO(33316): Remove.
}
