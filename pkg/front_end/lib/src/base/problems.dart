// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart'
    show Severity, severityTexts;
import 'package:kernel/ast.dart' show FileUriNode, TreeNode;

import 'command_line_reporting.dart' as command_line_reporting;
import 'messages.dart'
    show
        LocatedMessage,
        Message,
        noLength,
        templateInternalProblemDebugAbort,
        templateInternalProblemUnexpected,
        templateInternalProblemUnhandled,
        templateInternalProblemUnimplemented,
        templateInternalProblemUnsupported;

// Coverage-ignore(suite): Not run.
class DebugAbort {
  final LocatedMessage message;

  DebugAbort(Uri? uri, int charOffset, Severity severity, StackTrace trace)
      : message = uri != null
            ? templateInternalProblemDebugAbort
                .withArguments(severityTexts[severity]!, "$trace")
                .withLocation(uri, charOffset, noLength)
            : templateInternalProblemDebugAbort
                .withArguments(severityTexts[severity]!, "$trace")
                .withoutLocation();

  @override
  String toString() => "DebugAbort: ${message.problemMessage}";
}

// Coverage-ignore(suite): Not run.
/// Used to report an internal error.
///
/// Internal errors should be avoided as best as possible, but are preferred
/// over assertion failures. The message should start with an upper-case letter
/// and contain a short description that may help a developer debug the issue.
/// This method should be called instead of using `throw`, as this allows us to
/// ensure that there are no throws anywhere else in the codebase.
///
/// Before printing the message, the string `"Internal error: "` is prepended.
Never internalProblem(Message message, int charOffset, Uri? uri) {
  if (uri != null) {
    throw command_line_reporting
        .formatNoSourceLine(message.withLocation(uri, charOffset, noLength),
            Severity.internalProblem)
        .plain;
  } else {
    throw command_line_reporting
        .formatNoSourceLine(message.withoutLocation(), Severity.internalProblem)
        .plain;
  }
}

// Coverage-ignore(suite): Not run.
Never unimplemented(String what, int charOffset, Uri? uri) {
  return internalProblem(
      templateInternalProblemUnimplemented.withArguments(what),
      charOffset,
      uri);
}

// Coverage-ignore(suite): Not run.
Never unhandled(String what, String where, int charOffset, Uri? uri) {
  return internalProblem(
      templateInternalProblemUnhandled.withArguments(what, where),
      charOffset,
      uri);
}

// Coverage-ignore(suite): Not run.
Never unexpected(String expected, String actual, int charOffset, Uri? uri) {
  return internalProblem(
      templateInternalProblemUnexpected.withArguments(expected, actual),
      charOffset,
      uri);
}

// Coverage-ignore(suite): Not run.
Never unsupported(String operation, int charOffset, Uri? uri) {
  return internalProblem(
      templateInternalProblemUnsupported.withArguments(operation),
      charOffset,
      uri);
}

// Coverage-ignore(suite): Not run.
Uri? getFileUri(TreeNode node) {
  TreeNode? parent = node;
  do {
    if (parent is FileUriNode) return parent.fileUri;
    parent = parent!.parent;
  } while (parent is TreeNode);
  return null;
}
