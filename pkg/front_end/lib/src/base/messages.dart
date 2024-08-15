// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.messages;

import 'package:kernel/ast.dart' show Location, Source;

import '../codes/cfe_codes.dart';
import 'compiler_context.dart' show CompilerContext;

export '../codes/cfe_codes.dart';

Location? getLocation(CompilerContext context, Uri uri, int charOffset) {
  return context.uriToSource[uri]?.getLocation(uri, charOffset);
}

String? getSourceLine(CompilerContext context, Location? location,
    [Map<Uri, Source>? uriToSource]) {
  if (location == null) return null;
  uriToSource ??= context.uriToSource;
  return uriToSource[location.file]?.getTextLine(location.line);
}

// Coverage-ignore(suite): Not run.
String? getSourceLineFromMap(Location location, Map<Uri, Source> uriToSource) {
  return uriToSource[location.file]?.getTextLine(location.line);
}

abstract interface class ProblemReporting {
  /// Add a problem with a severity determined by the severity of the message.
  ///
  /// If [fileUri] is null, it defaults to `this.fileUri`.
  ///
  /// See `Loader.addMessage` for an explanation of the
  /// arguments passed to this method.
  void addProblem(Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false});
}
