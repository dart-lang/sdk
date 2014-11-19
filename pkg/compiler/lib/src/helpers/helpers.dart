// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library for debugging helpers. The unittest analyze_unused_test checks that
/// the helper are not used in production code.

library dart2js.helpers;

import 'dart:async' show EventSink;
import 'dart:collection';
import 'dart:convert';

import '../../compiler.dart';
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

/// Enables debug mode.
///
/// Sets the [DEBUG_MODE] to `true`.
void enableDebugMode() {
  DEBUG_MODE = true;
}

class _DebugIndentation extends Indentation {
  final String indentationUnit = " ";
}
_DebugIndentation _indentation = new _DebugIndentation();

/// Function signature of [debugPrint].
typedef DebugPrint(s);

/// If [DEBUG_PRINT_ENABLED] is `true` print [s] using the current identation.
DebugPrint get debugPrint {
  enableDebugMode();
  // TODO(johnniwinther): Maybe disable debug mode after the call.
  return _debugPrint;
}

/// Implementation of [debugPrint].
_debugPrint(s) {
  if (DEBUG_PRINT_ENABLED) print('${_indentation.indentation}$s');
}

/// Function signature of [debugWrapPrint].
typedef DebugWrapPrint(s, f());

/// Wraps the call to [f] with a print of 'start:$s' and 'end:$s' incrementing
/// the current indentation used by [debugPrint] during the execution of [f].
///
/// Use this to get a tree-like debug printout for nested calls.
DebugWrapPrint get debugWrapPrint {
  enableDebugMode();
  return _debugWrapPrint;
}

/// Implementation of [debugWrapPrint].
_debugWrapPrint(s, f()) {
  debugPrint('start:$s');
  var result = _indentation.indentBlock(f);
  debugPrint('end:$s');
  return result;
}

/// Dummy method to mark breakpoints.
debugBreak() {
  enableDebugMode();
}

/// Function signature of [reportHere].
typedef ReportHere(Compiler compiler, Spannable node, String debugMessage);

/// Print a message with a source location.
ReportHere get reportHere {
  enableDebugMode();
  return _reportHere;
}

/// Implementation of [reportHere]
_reportHere(Compiler compiler, Spannable node, String debugMessage) {
  compiler.reportInfo(node,
      MessageKind.GENERIC, {'text': 'HERE: $debugMessage'});
}
