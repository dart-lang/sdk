// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library frame;

import 'dart:uri';

import 'package:pathos/path.dart' as path;

import 'trace.dart';
import 'utils.dart';

final _nativeFrameRegExp = new RegExp(
    r'^#\d+\s+([^\s].*) \((.+):(\d+):(\d+)\)$');

/// A single stack frame. Each frame points to a precise location in Dart code.
class Frame {
  /// The URI of the file in which the code is located.
  ///
  /// This URI will usually have the scheme `dart`, `file`, `http`, or `https`.
  final Uri uri;

  /// The line number on which the code location is located.
  final int line;

  /// The column number of the code location.
  final int column;

  /// The name of the member in which the code location occurs.
  ///
  /// Anonymous closures are represented as `<fn>` in this member string.
  final String member;

  /// Whether this stack frame comes from the Dart core libraries.
  bool get isCore => uri.scheme == 'dart';

  /// Returns a human-friendly description of the library that this stack frame
  /// comes from.
  ///
  /// This will usually be the string form of [uri], but a relative path will be
  /// used if possible.
  String get library {
    // TODO(nweiz): handle relative URIs here as well once pathos supports that.
    if (uri.scheme != 'file') return uri.toString();
    return path.relative(fileUriToPath(uri));
  }

  /// Returns the name of the package this stack frame comes from, or `null` if
  /// this stack frame doesn't come from a `package:` URL.
  String get package {
    if (uri.scheme != 'package') return null;
    return uri.path.split('/').first;
  }

  /// A human-friendly description of the code location.
  ///
  /// For Dart core libraries, this will omit the line and column information,
  /// since those are useless for baked-in libraries.
  String get location {
    if (isCore) return library;
    return '$library $line:$column';
  }

  /// Returns a single frame of the current stack.
  ///
  /// By default, this will return the frame above the current method. If
  /// [level] is `0`, it will return the current method's frame; if [level] is
  /// higher than `1`, it will return higher frames.
  factory Frame.caller([int level=1]) {
    if (level < 0) {
      throw new ArgumentError("Argument [level] must be greater than or equal "
          "to 0.");
    }

    return new Trace.current(level + 1).frames.first;
  }

  /// Parses a string representation of a stack frame.
  ///
  /// [frame] should be formatted in the same way as a native stack trace frame.
  factory Frame.parse(String frame) {
    var match = _nativeFrameRegExp.firstMatch(frame);
    if (match == null) {
      throw new FormatException("Couldn't parse stack trace line '$frame'.");
    }

    var uri = new Uri.fromString(match[2]);
    var member = match[1].replaceAll("<anonymous closure>", "<fn>");
    return new Frame(uri, int.parse(match[3]), int.parse(match[4]), member);
  }

  Frame(this.uri, this.line, this.column, this.member);

  String toString() => '$location in $member';
}
