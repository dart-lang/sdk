// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.problems;

import 'messages.dart'
    show
        Message,
        deprecated_format,
        templateUnexpected,
        templateUnhandled,
        templateUnimplemented,
        templateUnsupported;

/// Used to report an internal error.
///
/// Internal errors should be avoided as best as possible, but are preferred
/// over assertion failures. The message should contain a short description
/// that may help a developer debug the issue.  This method should be called
/// instead of using `throw`, as this allows us to ensure that there are no
/// throws anywhere else in the codebase.
dynamic internalProblem(Message message, int charOffset, Uri uri) {
  String text = "Internal problem: ${message.message}";
  if (uri == null && charOffset == -1) {
    throw text;
  } else {
    throw deprecated_format(uri, charOffset, text);
  }
}

dynamic unimplemented(String what, int charOffset, Uri uri) {
  return internalProblem(
      templateUnimplemented.withArguments(what), charOffset, uri);
}

dynamic unhandled(String what, String where, int charOffset, Uri uri) {
  return internalProblem(
      templateUnhandled.withArguments(what, where), charOffset, uri);
}

dynamic unexpected(String expected, String actual, int charOffset, Uri uri) {
  return internalProblem(
      templateUnexpected.withArguments(expected, actual), charOffset, uri);
}

dynamic unsupported(String operation, int charOffset, Uri uri) {
  return internalProblem(
      templateUnsupported.withArguments(operation), charOffset, uri);
}
