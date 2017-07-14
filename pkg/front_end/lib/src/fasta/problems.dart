// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.problems;

import 'compiler_context.dart' show CompilerContext;

import 'messages.dart'
    show
        Message,
        templateInternalProblemUnexpected,
        templateInternalProblemUnhandled,
        templateInternalProblemUnimplemented,
        templateInternalProblemUnsupported;

import 'severity.dart' show Severity;

/// Used to report an internal error.
///
/// Internal errors should be avoided as best as possible, but are preferred
/// over assertion failures. The message should start with an upper-case letter
/// and contain a short description that may help a developer debug the issue.
/// This method should be called instead of using `throw`, as this allows us to
/// ensure that there are no throws anywhere else in the codebase.
///
/// Before printing the message, the string `"Internal error: "` is prepended.
dynamic internalProblem(Message message, int charOffset, Uri uri) {
  throw CompilerContext.current
      .format(message.withLocation(uri, charOffset), Severity.internalProblem);
}

dynamic unimplemented(String what, [int charOffset = -1, Uri uri = null]) {
  return internalProblem(
      templateInternalProblemUnimplemented.withArguments(what),
      charOffset,
      uri);
}

dynamic unhandled(String what, String where, int charOffset, Uri uri) {
  return internalProblem(
      templateInternalProblemUnhandled.withArguments(what, where),
      charOffset,
      uri);
}

dynamic unexpected(String expected, String actual, int charOffset, Uri uri) {
  return internalProblem(
      templateInternalProblemUnexpected.withArguments(expected, actual),
      charOffset,
      uri);
}

dynamic unsupported(String operation, int charOffset, Uri uri) {
  return internalProblem(
      templateInternalProblemUnsupported.withArguments(operation),
      charOffset,
      uri);
}
