// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library trace;

import 'dart:uri';
import 'dart:math' as math;

import 'frame.dart';

final _patchRegExp = new RegExp(r"-patch$");

/// A stack trace, comprised of a list of stack frames.
class Trace implements StackTrace {
  // TODO(nweiz): make this read-only once issue 8321 is fixed.
  /// The stack frames that comprise this stack trace.
  final List<Frame> frames;

  /// Returns a human-readable representation of [stackTrace]. If [terse] is
  /// set, this folds together multiple stack frames from the Dart core
  /// libraries, so that only the core library method directly called from user
  /// code is visible (see [Trace.terse]).
  static String format(StackTrace stackTrace, {bool terse: true}) {
    var trace = new Trace.from(stackTrace);
    if (terse) trace = trace.terse;
    return trace.toString();
  }

  /// Returns the current stack trace.
  ///
  /// By default, the first frame of this trace will be the line where
  /// [Trace.current] is called. If [level] is passed, the trace will start that
  /// many frames up instead.
  factory Trace.current([int level=0]) {
    if (level < 0) {
      throw new ArgumentError("Argument [level] must be greater than or equal "
          "to 0.");
    }

    try {
      throw '';
    } catch (_, nativeTrace) {
      var trace = new Trace.from(nativeTrace);
      return new Trace(trace.frames.skip(level + 1));
    }
  }

  /// Returns a new stack trace containing the same data as [trace].
  ///
  /// If [trace] is a native [StackTrace], its data will be parsed out; if it's
  /// a [Trace], it will be returned as-is.
  factory Trace.from(StackTrace trace) {
    if (trace is Trace) return trace;
    return new Trace.parse(trace.toString());
  }

  /// Parses a string representation of a stack trace.
  ///
  /// [trace] should be formatted in the same way as native stack traces.
  Trace.parse(String trace)
      : this(trace.trim().split("\n").map((line) => new Frame.parse(line)));

  /// Returns a new [Trace] comprised of [frames].
  Trace(Iterable<Frame> frames)
      : frames = frames.toList();

  // TODO(nweiz): Keep track of which [Frame]s are part of the partial stack
  // trace and only print them.
  /// Returns a string representation of this stack trace.
  ///
  /// This is identical to [toString]. It will not be formatted in the manner of
  /// native stack traces.
  String get stackTrace => toString();

  /// Returns a string representation of this stack trace.
  ///
  /// This is identical to [toString]. It will not be formatted in the manner of
  /// native stack traces.
  String get fullStackTrace => toString();

  /// Returns a terser version of [this]. This is accomplished by folding
  /// together multiple stack frames from the core library, as in [foldFrames].
  /// Core library patches are also renamed to remove their `-patch` suffix.
  Trace get terse {
    return new Trace(foldFrames((frame) => frame.isCore).frames.map((frame) {
      if (!frame.isCore) return frame;
      var library = frame.library.replaceAll(_patchRegExp, '');
      return new Frame(
          Uri.parse(library), frame.line, frame.column, frame.member);
    }));
  }

  /// Returns a new [Trace] based on [this] where multiple stack frames matching
  /// [predicate] are folded together. This means that whenever there are
  /// multiple frames in a row that match [predicate], only the last one is
  /// kept.
  ///
  /// This is useful for limiting the amount of library code that appears in a
  /// stack trace by only showing user code and code that's called by user code.
  Trace foldFrames(bool predicate(frame)) {
    var newFrames = <Frame>[];
    for (var frame in frames.reversed) {
      if (!predicate(frame)) {
        newFrames.add(frame);
      } else if (newFrames.isEmpty || !predicate(newFrames.last)) {
        newFrames.add(new Frame(
            frame.uri, frame.line, frame.column, frame.member));
      }
    }

    return new Trace(newFrames.reversed);
  }

  /// Returns a human-readable string representation of [this].
  String toString() {
    if (frames.length == '') return '';

    // Figure out the longest path so we know how much to pad.
    var longest = frames.map((frame) => frame.location.length).reduce(math.max);

    // Print out the stack trace nicely formatted.
    return frames.map((frame) {
      return '${_padRight(frame.location, longest)}  ${frame.member}\n';
    }).join();
  }
}

/// Returns [string] with enough spaces added to the end to make it [length]
/// characters long.
String _padRight(String string, int length) {
  if (string.length >= length) return string;

  var result = new StringBuffer();
  result.write(string);
  for (var i = 0; i < length - string.length; i++) {
    result.write(' ');
  }

  return result.toString();
}
