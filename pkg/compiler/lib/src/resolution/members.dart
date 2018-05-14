// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.members;

import '../common.dart';
import '../elements/elements.dart';
import '../tree/tree.dart';
import 'scope.dart' show Scope;

/// Looks up [name] in [scope] and unwraps the result.
Element lookupInScope(
    DiagnosticReporter reporter, Node node, Scope scope, String name) {
  return Elements.unwrap(scope.lookup(name), reporter, node);
}
