// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides a default implementation of the report and format methods of
/// [CompilerContext] that are suitable for command-line tools. The methods in
/// this library aren't intended to be called directly, instead, one should use
/// [CompilerContext].
library fasta.command_line_reporting;

import 'dart:io' show exitCode;

import 'dart:math' show min;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart' show Location;

import 'colors.dart' show green, magenta, red;

import 'compiler_context.dart' show CompilerContext;

import 'crash.dart' show Crash, safeToString;

import 'fasta_codes.dart' show LocatedMessage;

import 'messages.dart' show getLocation, getSourceLine;

import 'problems.dart' show DebugAbort, unhandled;

import 'severity.dart' show Severity, severityPrefixes;

import 'scanner/characters.dart' show $CARET, $SPACE, $TAB;

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
    String prefix = severityPrefixes[severity];
    String text =
        prefix == null ? message.message : "$prefix: ${message.message}";
    if (message.tip != null) {
      text += "\n${message.tip}";
    }
    if (CompilerContext.enableColors) {
      switch (severity) {
        case Severity.error:
        case Severity.internalProblem:
          text = red(text);
          break;

        case Severity.warning:
          text = magenta(text);
          break;

        case Severity.context:
          text = green(text);
          break;

        default:
          return unhandled("$severity", "format", -1, null);
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
        // TODO(askesc): Much more could be done to indent properly in the
        // presence of all sorts of unicode weirdness.
        // This handling covers the common case of single-width characters
        // indented with spaces and/or tabs, using no surrogates.
        int indentLength = location.column - 1;
        Uint8List indentation = new Uint8List(indentLength + length)
          ..fillRange(0, indentLength, $SPACE)
          ..fillRange(indentLength, indentLength + length, $CARET);
        int lengthInSourceLine = min(indentation.length, sourceLine.length);
        for (int i = 0; i < lengthInSourceLine; i++) {
          if (sourceLine.codeUnitAt(i) == $TAB) {
            indentation[i] = $TAB;
          }
        }
        String pointer = new String.fromCharCodes(indentation);
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
          location == null ? ":1" : ":${location.line}:${location.column}";
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

    case Severity.warning:
      return hideWarnings;

    default:
      return unhandled("$severity", "isHidden", -1, null);
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

    case Severity.warning:
      return CompilerContext.current.options.throwOnWarningsForDebugging;

    case Severity.context:
      return false;

    default:
      return unhandled("$severity", "shouldThrowOn", -1, null);
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
    throw new DebugAbort(uri, charOffset, severity, StackTrace.current);
  }
}

bool isCompileTimeError(Severity severity) {
  switch (severity) {
    case Severity.error:
    case Severity.internalProblem:
      return true;

    case Severity.errorLegacyWarning:
      return CompilerContext.current.options.strongMode;

    case Severity.warning:
    case Severity.context:
      return false;

    case Severity.ignored:
      break; // Fall-through to unhandled below.
  }
  return unhandled("$severity", "isCompileTimeError", -1, null);
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
