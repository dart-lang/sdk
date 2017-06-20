// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Library for debugging helpers. The unittest analyze_unused_test checks that
/// the helper are not used in production code.

library dart2js.helpers;

import '../common.dart';
import '../diagnostics/invariant.dart' show DEBUG_MODE;
import '../util/util.dart';
import 'trace.dart';

export 'debug_collection.dart';
export 'expensive_map.dart';
export 'expensive_set.dart';
export 'stats.dart';
export 'trace.dart';
export 'track_map.dart';

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
typedef ReportHere(
    DiagnosticReporter reporter, Spannable node, String debugMessage);

/// Print a message with a source location.
ReportHere get reportHere {
  enableDebugMode();
  return _reportHere;
}

/// Implementation of [reportHere]
_reportHere(DiagnosticReporter reporter, Spannable node, String debugMessage) {
  reporter
      .reportInfo(node, MessageKind.GENERIC, {'text': 'HERE: $debugMessage'});
}

/// Set of tracked objects used by [track] and [ifTracked].
var _trackedObjects = new Set<Object>();

/// Global default value for the `printTrace` option of [track] and [ifTracked].
bool trackWithTrace = false;

/// If [doTrack] is `true`, add [object] to the set of tracked objects.
///
/// If tracked, [message] is printed along the hash code and toString of
/// [object]. If [printTrace] is `true` a trace printed additionally.
/// If [printTrace] is `null`, [trackWithTrace] determines whether a trace is
/// printed.
///
/// [object] is returned as the result of the method.
track(bool doTrack, Object object, String message, {bool printTrace}) {
  if (!doTrack) return object;
  _trackedObjects.add(object);
  String msg = 'track: ${object.hashCode}:$object:$message';
  if (printTrace == null) printTrace = trackWithTrace;
  if (printTrace) {
    trace(msg);
  } else {
    debugPrint(msg);
  }
  return object;
}

/// Returns `true` if [object] is in the set of tracked objects.
///
/// If [message] is provided it is printed along the hash code and toString of
/// [object]. If [printTrace] is `true` a trace printed additionally. If
/// [printTrace] is `null`, [trackWithTrace] determines whether a trace is
/// printed.
bool ifTracked(Object object, {String message, bool printTrace}) {
  if (_trackedObjects.contains(object)) {
    if (message != null) {
      String msg = 'tracked: ${object.hashCode}:$object:$message';
      if (printTrace == null) printTrace = trackWithTrace;
      if (printTrace) {
        trace(msg);
      } else {
        debugPrint(msg);
      }
    }
    return true;
  }
  return false;
}
