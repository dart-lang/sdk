// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Provides a default implementation of the report and format methods of
/// [CompilerContext] that are suitable for command-line tools. The methods in
/// this library aren't intended to be called directly, instead, one should use
/// [CompilerContext].
library fasta.command_line_reporting;

import 'dart:math' show min;
import 'dart:typed_data' show Uint8List;

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show Severity, severityPrefixes;
import 'package:_fe_analyzer_shared/src/scanner/characters.dart'
    show $CARET, $SPACE, $TAB;
import 'package:_fe_analyzer_shared/src/util/colors.dart'
    show green, magenta, red, yellow;
import 'package:_fe_analyzer_shared/src/util/relativize.dart'
    show isWindows, relativizeUri;
import 'package:kernel/ast.dart' show Location, Source, TreeNode;

import '../codes/cfe_codes.dart' show LocatedMessage, PlainAndColorizedString;
import '../compute_platform_binaries_location.dart' show translateSdk;
import 'compiler_context.dart' show CompilerContext;
import 'crash.dart' show Crash, safeToString;
import 'messages.dart' show getLocation, getSourceLine, getSourceLineFromMap;
import 'problems.dart' show unhandled;
import 'processed_options.dart' show ProcessedOptions;

const bool hideWarnings = false;

// TODO(jensj): Reduce code duplication of all the format methods.

/// Formats [message] as two strings that is suitable for output from a
/// command-line tool. This includes source snippets and - in the colorized
/// version - different colors based on [severity].
PlainAndColorizedString format(
    CompilerContext context, LocatedMessage message, Severity severity,
    {Location? location}) {
  try {
    int length = message.length;
    if (length < 1) {
      // TODO(ahe): Throw in this situation. It is normally an error caused by
      // empty names.
      length = 1;
    }
    final String messageTextPlain = _createMessageText(severity, message);
    String messageTextColorized =
        _colorizeMessageText(severity, messageTextPlain);

    if (message.uri != null) {
      String path = relativizeUri(
          Uri.base, translateSdk(context, message.uri!), isWindows);
      int offset = message.charOffset;
      location ??=
          (offset == -1 ? null : getLocation(context, message.uri!, offset));
      if (location?.line == TreeNode.noOffset) {
        location = null;
      }
      String? sourceLine = getSourceLine(context, location);
      return new PlainAndColorizedString(
        formatErrorMessage(
            sourceLine, location, length, path, messageTextPlain),
        formatErrorMessage(
            sourceLine, location, length, path, messageTextColorized),
      );
    } else {
      return new PlainAndColorizedString(
        messageTextPlain,
        messageTextColorized,
      );
    }
  } catch (error, trace) {
    // Coverage-ignore-block(suite): Not run.
    print("Crash when formatting: "
        "[${message.code.name}] ${safeToString(message.problemMessage)}\n"
        "${safeToString(error)}\n"
        "$trace");
    throw new Crash(message.uri, message.charOffset, error, trace);
  }
}

// Coverage-ignore(suite): Not run.
/// Formats [message] as two strings that is suitable for output from a
/// command-line tool. This includes source snippets and - in the colorized
/// version - different colors based on [severity].
PlainAndColorizedString formatWithLocationNoSdk(
    LocatedMessage message, Severity severity,
    {required Location location, required Map<Uri, Source> uriToSource}) {
  int length = message.length;
  if (length < 1) {
    // TODO(ahe): Throw in this situation. It is normally an error caused by
    // empty names.
    length = 1;
  }
  final String messageTextPlain = _createMessageText(severity, message);
  String messageTextColorized =
      _colorizeMessageText(severity, messageTextPlain);

  if (message.uri != null) {
    String path = relativizeUri(Uri.base, message.uri!, isWindows);
    String? sourceLine = getSourceLineFromMap(location, uriToSource);
    return new PlainAndColorizedString(
      formatErrorMessage(sourceLine, location, length, path, messageTextPlain),
      formatErrorMessage(
          sourceLine, location, length, path, messageTextColorized),
    );
  } else {
    return new PlainAndColorizedString(
      messageTextPlain,
      messageTextColorized,
    );
  }
}

/// Formats [message] as two strings that is suitable for output from a
/// command-line tool. This includes source snippets and - in the colorized
/// version - different colors based on [severity].
///
/// Used without [CompilerContext] but gives the same output when file can't be
/// looked up in uriToSource anyway, or we don't have or can get any
/// line-position for it.
PlainAndColorizedString formatNoSourceLine(
    LocatedMessage message, Severity severity) {
  int length = message.length;
  if (length < 1) {
    // TODO(ahe): Throw in this situation. It is normally an error caused by
    // empty names.
    length = 1;
  }
  final String messageTextPlain = _createMessageText(severity, message);
  String messageTextColorized =
      _colorizeMessageText(severity, messageTextPlain);

  if (message.uri != null) {
    // Coverage-ignore-block(suite): Not run.
    String path = relativizeUri(Uri.base, message.uri!, isWindows);
    return new PlainAndColorizedString(
      formatErrorMessage(null, null, length, path, messageTextPlain),
      formatErrorMessage(null, null, length, path, messageTextColorized),
    );
  } else {
    return new PlainAndColorizedString(
      messageTextPlain,
      messageTextColorized,
    );
  }
}

String _createMessageText(Severity severity, LocatedMessage message) {
  String? prefix = severityPrefixes[severity];
  String messageText = prefix == null
      ?
      // Coverage-ignore(suite): Not run.
      message.problemMessage
      : "$prefix: ${message.problemMessage}";
  if (message.correctionMessage != null) {
    messageText += "\n${message.correctionMessage}";
  }
  return messageText;
}

String _colorizeMessageText(Severity severity, String messageTextPlain) {
  switch (severity) {
    case Severity.error:
    case Severity.internalProblem:
      return red(messageTextPlain);

    case Severity.warning:
      // Coverage-ignore(suite): Not run.
      return magenta(messageTextPlain);

    case Severity.context:
      return green(messageTextPlain);

    // Coverage-ignore(suite): Not run.
    case Severity.info:
      return yellow(messageTextPlain);

    // Coverage-ignore(suite): Not run.
    case Severity.ignored:
      throw unhandled("$severity", "format", -1, null);
  }
}

String formatErrorMessage(String? sourceLine, Location? location,
    int squigglyLength, String? path, String messageText) {
  if (sourceLine == null || location == null) {
    sourceLine = "";
  } else if (sourceLine.isNotEmpty) {
    // TODO(askesc): Much more could be done to indent properly in the
    // presence of all sorts of unicode weirdness.
    // This handling covers the common case of single-width characters
    // indented with spaces and/or tabs, using no surrogates.
    int indentLength = location.column - 1;
    Uint8List indentation = new Uint8List(indentLength + squigglyLength)
      ..fillRange(0, indentLength, $SPACE)
      ..fillRange(indentLength, indentLength + squigglyLength, $CARET);
    int lengthInSourceLine = min(indentation.length, sourceLine.length);
    for (int i = 0; i < lengthInSourceLine; i++) {
      if (sourceLine.codeUnitAt(i) == $TAB) {
        // Coverage-ignore-block(suite): Not run.
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
      location == null ? "" : ":${location.line}:${location.column}";
  return "$path$position: $messageText$sourceLine";
}

/// Are problems of [severity] suppressed?
bool isHidden(Severity severity) {
  switch (severity) {
    case Severity.error:
    // Coverage-ignore(suite): Not run.
    case Severity.internalProblem:
    // Coverage-ignore(suite): Not run.
    case Severity.context:
    // Coverage-ignore(suite): Not run.
    case Severity.info:
      return false;

    // Coverage-ignore(suite): Not run.
    case Severity.warning:
      return hideWarnings;
    // Coverage-ignore(suite): Not run.
    case Severity.ignored:
      return true;
  }
}

/// Are problems of [severity] fatal? That is, should the compiler terminate
/// immediately?
bool shouldThrowOn(ProcessedOptions options, Severity severity) {
  switch (severity) {
    case Severity.error:
      return options.throwOnErrorsForDebugging;

    // Coverage-ignore(suite): Not run.
    case Severity.internalProblem:
      return true;

    // Coverage-ignore(suite): Not run.
    case Severity.warning:
      return options.throwOnWarningsForDebugging;

    // Coverage-ignore(suite): Not run.
    case Severity.info:
    case Severity.ignored:
    case Severity.context:
      return false;
  }
}
