// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library for debugging helpers. The unittest analyze_unused_test checks that
/// the helper are not used in production code.

library dart2js.helpers;

import "dart:collection";
import '../dart2jslib.dart';
import '../util/util.dart';

part 'debug_collection.dart';
part 'trace.dart';
part 'expensive_map.dart';
part 'expensive_set.dart';

/// Print [s].
debugPrint(s) => print(s);

/// Print a message with a source location.
reportHere(Compiler compiler, Spannable node, String debugMessage) {
  compiler.reportInfo(node,
      MessageKind.GENERIC, {'text': 'HERE: $debugMessage'});
}
