// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library for debugging helpers. The unittest analyze_unused_test checks that
/// the helper are not used in production code.

library dart2js.helpers;

import "dart:collection";
import 'dart:convert';
import '../dart2jslib.dart';
import '../util/util.dart';

part 'debug_collection.dart';
part 'trace.dart';
part 'expensive_map.dart';
part 'expensive_set.dart';
part 'stats.dart';
part 'track_map.dart';

/// Global flag to enable [debugPrint]. This should always be `true` by default
/// and be set to `false` as a means to temporarily turn off all debugging
/// printouts.
const bool DEBUG_PRINT_ENABLED = true;

/// Current indentation used by [debugPrint].
String _debugPrint_indentation = '';

/// The current indentation level of [debugPrint].
int get debugPrintIndentationLevel => _debugPrint_indentation.length;

/// If [DEBUG_PRINT_ENABLED] is `true` print [s] using the current identation
/// defined by [debugWrapPrint].
debugPrint(s) {
  if (DEBUG_PRINT_ENABLED) print('$_debugPrint_indentation$s');
}

/// Wraps the call to [f] with a print of 'start:$s' and 'end:$s' incrementing
/// the current indentation used by [debugPrint] during the execution of [f].
///
/// Use this to get a tree-like debug printout for nested calls.
debugWrapPrint(s, f()) {
  String previousIndentation = _debugPrint_indentation;
  debugPrint('start:$s');
  _debugPrint_indentation += ' ';
  var result = f();
  _debugPrint_indentation = previousIndentation;
  debugPrint('end:$s');
  return result;
}

/// Dummy method to mark breakpoints.
debugBreak() {}

/// Print a message with a source location.
reportHere(Compiler compiler, Spannable node, String debugMessage) {
  compiler.reportInfo(node,
      MessageKind.GENERIC, {'text': 'HERE: $debugMessage'});
}
