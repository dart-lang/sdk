// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'problems.dart' show DebugAbort;
import 'uri_offset.dart';

/// Tracks if there has been a crash reported through [reportCrash]. Should be
/// reset between each compilation by calling [resetCrashReporting].
bool hasCrashed = false;

/// Tracks the first source URI that has been read and is used as a fall-back
/// for [reportCrash]. Should be reset between each compilation by calling
/// [resetCrashReporting].
Uri? firstSourceUri;

class Crash {
  final Uri? uri;

  final int? charOffset;

  final Object error;

  final StackTrace? trace;

  bool _hasBeenReported = false;

  Crash(this.uri, this.charOffset, this.error, this.trace);

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    if (uri != null) {
      sb.write("Crash when compiling $uri");
      if (charOffset != null && charOffset != -1) {
        sb.write(" at character offset $charOffset:\n");
      } else {
        sb.write(":\n");
      }
    } else {
      sb.write("Crash when compiling:\n");
    }
    sb.write(error);
    sb.write("\n");
    return sb.toString();
  }
}

void resetCrashReporting() {
  firstSourceUri = null;
  hasCrashed = false;
}

Future<T> reportCrash<T>(error, StackTrace trace, [Uri? uri, int? charOffset]) {
  if (hasCrashed) {
    // Coverage-ignore-block(suite): Not run.
    return new Future<T>.error(error, trace);
  }
  if (error is Crash) {
    // Coverage-ignore-block(suite): Not run.
    trace = error.trace ?? trace;
    uri = error.uri ?? uri;
    charOffset = error.charOffset ?? charOffset;
    error._hasBeenReported = true;
    error = error.error;
  }
  uri ??= firstSourceUri;
  hasCrashed = true;
  return new Future<T>.error(
    new Crash(uri, charOffset, error, trace).._hasBeenReported = true,
    trace,
  );
}

// Coverage-ignore(suite): Not run.
String safeToString(Object object) {
  try {
    return "$object";
  } catch (e) {
    return "Error when converting ${object.runtimeType} to string.";
  }
}

Future<T> withCrashReporting<T>(
  Future<T> Function() action,
  UriOffset? Function() currentUriOffset,
) async {
  resetCrashReporting();
  try {
    return await action();
  } on DebugAbort {
    rethrow;
  } catch (e, s) {
    if (e is Crash &&
        // Coverage-ignore(suite): Not run.
        e._hasBeenReported) {
      rethrow;
    }
    UriOffset? uriOffset = currentUriOffset();
    return reportCrash(e, s, uriOffset?.fileUri, uriOffset?.fileOffset);
  }
}
