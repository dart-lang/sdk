// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.messages;

import 'package:kernel/ast.dart' show Library, Location, Source;

import '../codes/cfe_codes.dart';
import '../source/source_loader.dart';
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

/// [ProblemReporting] that registers the messages on a [Library] node.
class LibraryProblemReporting implements ProblemReporting {
  final SourceLoader _loader;
  final Uri _fileUri;

  LibraryProblemReporting(this._loader, this._fileUri);

  /// Problems in this [Library] encoded as json objects.
  ///
  /// Note that this field can be null, and by convention should be null if the
  /// list is empty.
  List<String>? _problemsAsJson;

  Library? _library;

  @override
  void addProblem(Message message, int charOffset, int length, Uri? fileUri,
      {bool wasHandled = false,
      List<LocatedMessage>? context,
      Severity? severity,
      bool problemOnLibrary = false}) {
    // Coverage-ignore(suite): Not run.
    fileUri ??= _fileUri;

    FormattedMessage? formattedMessage = _loader.addProblem(
        message, charOffset, length, fileUri,
        wasHandled: wasHandled,
        context: context,
        severity: severity,
        problemOnLibrary: true);
    if (formattedMessage != null) {
      (_problemsAsJson ??= (_library?.problemsAsJson ??= []) ?? [])
          .add(formattedMessage.toJsonString());
    }
  }

  void registerLibrary(Library library) {
    assert(_library == null, "Library has already been register for $this.");
    _library = library;
    if (_problemsAsJson != null) {
      (library.problemsAsJson ??= []).addAll(_problemsAsJson!);
    }
    _problemsAsJson = library.problemsAsJson;
  }

  @override
  String toString() => '$runtimeType(fileUri=$_fileUri)';
}
