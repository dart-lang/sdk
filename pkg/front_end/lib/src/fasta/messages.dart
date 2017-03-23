// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.messages;

import 'package:kernel/ast.dart' show Location, Program;

import 'util/relativize.dart' show relativizeUri;

import 'compiler_context.dart' show CompilerContext;

import 'errors.dart' show InputError;

import 'colors.dart' show cyan, magenta;

const bool hideWarnings = false;

bool get errorsAreFatal => CompilerContext.current.options.errorsAreFatal;

bool get nitsAreFatal => CompilerContext.current.options.nitsAreFatal;

bool get warningsAreFatal => CompilerContext.current.options.warningsAreFatal;

bool get isVerbose => CompilerContext.current.options.verbose;

bool get hideNits => !isVerbose;

void warning(Uri uri, int charOffset, String message) {
  if (hideWarnings) return;
  print(format(uri, charOffset, colorWarning("Warning: $message")));
  if (warningsAreFatal) {
    if (isVerbose) print(StackTrace.current);
    throw new InputError(
        uri, charOffset, "Compilation aborted due to fatal warnings.");
  }
}

void nit(Uri uri, int charOffset, String message) {
  if (hideNits) return;
  print(format(uri, charOffset, colorNit("Nit: $message")));
  if (nitsAreFatal) {
    if (isVerbose) print(StackTrace.current);
    throw new InputError(
        uri, charOffset, "Compilation aborted due to fatal nits.");
  }
}

String colorWarning(String message) {
  // TODO(ahe): Colors need to be optional. Doesn't work well in Emacs or on
  // Windows.
  return magenta(message);
}

String colorNit(String message) {
  // TODO(ahe): Colors need to be optional. Doesn't work well in Emacs or on
  // Windows.
  return cyan(message);
}

String format(Uri uri, int charOffset, String message) {
  if (uri != null) {
    String path = relativizeUri(uri);
    String position =
        charOffset == -1 ? path : "${getLocation(path, charOffset)}";
    return "$position: $message";
  } else {
    return message;
  }
}

Location getLocation(String path, int charOffset) {
  if (CompilerContext.current.uriToSource[path] == null) {
    return new Location(path, 1, 1);
  }
  return new Program(null, CompilerContext.current.uriToSource)
      .getLocation(path, charOffset);
}
