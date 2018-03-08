// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides a default implementation of the report and format methods of
/// [CompilerContext] that are suitable for command-line tools. The methods in
/// this library aren't intended to be called directly, instead, one should use
/// [CompilerContext].
library fasta.command_line_reporting;

import 'dart:io' show exitCode;

import 'package:kernel/ast.dart' show Location;

import 'colors.dart' show cyan, green, magenta, red;

import 'compiler_context.dart' show CompilerContext;

import 'deprecated_problems.dart'
    show Crash, deprecated_InputError, safeToString;

import 'fasta_codes.dart' show LocatedMessage;

import 'messages.dart' show getLocation, getSourceLine, isVerbose;

import 'problems.dart' show unexpected;

import 'severity.dart' show Severity;

import 'util/relativize.dart' show relativizeUri;

const bool hideWarnings = false;

/// Formats [message] as a string that is suitable for output from a
/// command-line tool. This includes source snippets and different colors based
/// on [severity].
String format(LocatedMessage message, Severity severity, {Location location}) {
  try {
    int length = message.length;
    if (length < 1) {
      // TODO(ahe): Throw in this situation. It is normally an error caused by
      // empty names.
      length = 1;
    }
    String text =
        "${severityName(severity, capitalized: true)}: ${message.message}";
    if (message.tip != null) {
      text += "\n${message.tip}";
    }
    if (CompilerContext.enableColors) {
      switch (severity) {
        case Severity.error:
        case Severity.internalProblem:
          text = red(text);
          break;

        case Severity.nit:
          text = cyan(text);
          break;

        case Severity.warning:
          text = magenta(text);
          break;

        case Severity.context:
          text = green(text);
          break;

        default:
          return unexpected("$severity", "format", -1, null);
      }
    }

    if (message.uri != null) {
      String path = relativizeUri(message.uri);
      int offset = message.charOffset;
      location ??= (offset == -1 ? null : getLocation(message.uri, offset));
      String sourceLine = getSourceLine(location);
      if (sourceLine == null) {
        sourceLine = "";
      } else if (sourceLine.isNotEmpty) {
        String indentation = " " * (location.column - 1);
        String pointer = indentation + ("^" * length);
        if (pointer.length > sourceLine.length) {
          // Truncate the carets to handle messages that span multiple lines.
          int pointerLength = sourceLine.length;
          // Add one to cover the case of a parser error pointing to EOF when
          // the last line doesn't end with a newline. For messages spanning
          // multiple lines, this also provides a minor visual clue that can be
          // useful for debugging Fasta.
          pointerLength += 1;
          pointer = pointer.substring(0, pointerLength);
          pointer += "...";
        }
        sourceLine = "\n$sourceLine\n$pointer";
      }
      String position =
          location == null ? "" : ":${location.line}:${location.column}";
      return "$path$position: $text$sourceLine";
    } else {
      return text;
    }
  } catch (error, trace) {
    print("Crash when formatting: "
        "[${message.code.name}] ${safeToString(message.message)}\n"
        "${safeToString(error)}\n"
        "$trace");
    throw new Crash(message.uri, message.charOffset, error, trace);
  }
}

/// Are problems of [severity] suppressed?
bool isHidden(Severity severity) {
  switch (severity) {
    case Severity.error:
    case Severity.internalProblem:
    case Severity.context:
      return false;

    case Severity.nit:
      return !isVerbose;

    case Severity.warning:
      return hideWarnings;

    default:
      return unexpected("$severity", "isHidden", -1, null);
  }
}

/// Are problems of [severity] fatal? That is, should the compiler terminate
/// immediately?
bool shouldThrowOn(Severity severity) {
  switch (severity) {
    case Severity.error:
      return CompilerContext.current.options.throwOnErrorsForDebugging;

    case Severity.internalProblem:
      return true;

    case Severity.nit:
      return CompilerContext.current.options.throwOnNitsForDebugging;

    case Severity.warning:
      return CompilerContext.current.options.throwOnWarningsForDebugging;

    case Severity.context:
      return false;

    default:
      return unexpected("$severity", "shouldThrowOn", -1, null);
  }
}

/// Convert [severity] to a name that can be used to prefix a message.
String severityName(Severity severity, {bool capitalized: false}) {
  switch (severity) {
    case Severity.error:
      return capitalized ? "Error" : "error";

    case Severity.internalProblem:
      return capitalized ? "Internal problem" : "internal problem";

    case Severity.nit:
      return capitalized ? "Nit" : "nit";

    case Severity.warning:
      return capitalized ? "Warning" : "warning";

    case Severity.context:
      return capitalized ? "Context" : "context";

    default:
      return unexpected("$severity", "severityName", -1, null);
  }
}

/// Print a formatted message and throw when errors are treated as fatal.
/// Also set [exitCode] depending on the value of
/// `CompilerContext.current.options.setExitCodeOnProblem`.
void _printAndThrowIfDebugging(
    String text, Severity severity, Uri uri, int charOffset) {
  // I believe we should only set it if we are reporting something, if we are
  // formatting to embed the error in the program, then we probably don't want
  // to do it in format.
  // Note: I also want to limit dependencies to dart:io for when we use the FE
  // outside of the VM. This default reporting is likely not going to be used in
  // that context, but the default formatter is.
  if (CompilerContext.current.options.setExitCodeOnProblem) {
    exitCode = 1;
  }
  print(text);
  if (shouldThrowOn(severity)) {
    if (isVerbose) print(StackTrace.current);
    // TODO(sigmund,ahe): ensure there is no circularity when InputError is
    // handled.
    throw new deprecated_InputError(uri, charOffset,
        "Compilation aborted due to fatal ${severityName(severity)}.");
  }
}

bool isCompileTimeError(Severity severity) {
  switch (severity) {
    case Severity.error:
    case Severity.internalProblem:
      return true;

    case Severity.errorLegacyWarning:
      return CompilerContext.current.options.strongMode;

    case Severity.nit:
    case Severity.warning:
    case Severity.context:
      return false;
  }
  return unexpected("$severity", "isCompileTimeError", -1, null);
}

/// Report [message] unless [severity] is suppressed (see [isHidden]). Throws
/// an exception if [severity] is fatal (see [isFatal]).
///
/// This method isn't intended to be called directly. Use
/// [CompilerContext.report] instead.
void report(LocatedMessage message, Severity severity) {
  if (isHidden(severity)) return;
  if (isCompileTimeError(severity)) {
    CompilerContext.current.logError(message, severity);
  }
  _printAndThrowIfDebugging(
      format(message, severity), severity, message.uri, message.charOffset);
}
