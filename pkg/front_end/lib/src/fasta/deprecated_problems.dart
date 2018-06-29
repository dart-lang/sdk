// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.errors;

import 'dart:async' show Future;

import 'command_line_reporting.dart' show shouldThrowOn;

import 'crash.dart' show safeToString;

import 'messages.dart'
    show LocatedMessage, noLength, isVerbose, templateUnspecified;

import 'severity.dart' show Severity;

import 'crash.dart' show Crash, reportCrash, resetCrashReporting;

/// Used to report an error in input.
///
/// Avoid using this for reporting compile-time errors, instead use
/// `LibraryBuilder.addCompileTimeError` for those.
///
/// An input error is any error that isn't an internal error. We use the term
/// "input error" in favor of "user error". This way, if an input error isn't
/// handled correctly, the user will never see a stack trace that says "user
/// error".
dynamic deprecated_inputError(Uri uri, int charOffset, Object error) {
  if (shouldThrowOn(Severity.error) && isVerbose) {
    print(StackTrace.current);
  }
  throw new deprecated_InputError(uri, charOffset, error);
}

class deprecated_InputError {
  final Uri uri;

  final int charOffset;

  final Object error;

  deprecated_InputError(this.uri, int charOffset, this.error)
      : this.charOffset = charOffset ?? -1;

  toString() => "deprecated_InputError: $error";

  /// Converts [error] to a [LocatedMessage] using [templateUnspecified]. Using
  /// [templateUnspecified] is deprecated behavior.
  ///
  /// Static method to discourage use and requiring call-sites to include the
  /// text `deprecated_`.
  static LocatedMessage toMessage(deprecated_InputError error) {
    return templateUnspecified
        .withArguments(safeToString(error.error))
        .withLocation(error.uri, error.charOffset, noLength);
  }
}

// TODO(ahe): Move this method to crash.dart when it's no longer using
// [deprecated_InputError].
Future<T> withCrashReporting<T>(
    Future<T> Function() action, Uri Function() currentUri,
    {T Function(LocatedMessage) onInputError}) async {
  resetCrashReporting();
  try {
    return await action();
  } on Crash {
    rethrow;
  } on deprecated_InputError catch (e, s) {
    if (onInputError != null) {
      return onInputError(deprecated_InputError.toMessage(e));
    } else {
      return reportCrash(e, s, currentUri());
    }
  } catch (e, s) {
    return reportCrash(e, s, currentUri());
  }
}
