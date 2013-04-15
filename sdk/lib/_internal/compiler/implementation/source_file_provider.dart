// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_file_provider;

import 'dart:async';
import 'dart:uri';
import 'dart:io';
import 'dart:utf';

import '../compiler.dart' as api show Diagnostic;
import 'dart2js.dart' show AbortLeg;
import 'colors.dart' as colors;
import 'source_file.dart';
import 'filenames.dart';
import 'util/uri_extras.dart';

String readAll(String filename) {
  var file = (new File(filename)).openSync();
  var length = file.lengthSync();
  var buffer = new List<int>(length);
  var bytes = file.readIntoSync(buffer, 0, length);
  file.closeSync();
  return new String.fromCharCodes(new Utf8Decoder(buffer).decodeRest());
}

class SourceFileProvider {
  bool isWindows = (Platform.operatingSystem == 'windows');
  Uri cwd = getCurrentDirectory();
  Map<String, SourceFile> sourceFiles = <String, SourceFile>{};
  int dartCharactersRead = 0;

  Future<String> readStringFromUri(Uri resourceUri) {
    if (resourceUri.scheme != 'file') {
      throw new ArgumentError("Unknown scheme in uri '$resourceUri'");
    }
    String source;
    try {
      source = readAll(uriPathToNative(resourceUri.path));
    } on FileIOException catch (ex) {
      throw 'Error: Cannot read "${relativize(cwd, resourceUri, isWindows)}" '
            '(${ex.osError}).';
    }
    dartCharactersRead += source.length;
    sourceFiles[resourceUri.toString()] =
      new SourceFile(relativize(cwd, resourceUri, isWindows), source);
    return new Future.value(source);
  }
}

class FormattingDiagnosticHandler {
  final SourceFileProvider provider;
  bool showWarnings = true;
  bool verbose = false;
  bool isAborting = false;
  bool enableColors = false;
  bool throwOnError = false;

  final int FATAL = api.Diagnostic.CRASH.ordinal | api.Diagnostic.ERROR.ordinal;
  final int INFO =
      api.Diagnostic.INFO.ordinal | api.Diagnostic.VERBOSE_INFO.ordinal;

  FormattingDiagnosticHandler(SourceFileProvider this.provider);

  void info(var message, [api.Diagnostic kind = api.Diagnostic.VERBOSE_INFO]) {
    if (!verbose && identical(kind, api.Diagnostic.VERBOSE_INFO)) return;
    if (enableColors) {
      print('${colors.green("info:")} $message');
    } else {
      print('info: $message');
    }
  }

  void diagnosticHandler(Uri uri, int begin, int end, String message,
                         api.Diagnostic kind) {
    // TODO(ahe): Remove this when source map is handled differently.
    if (identical(kind.name, 'source map')) return;

    if (isAborting) return;
    isAborting = identical(kind, api.Diagnostic.CRASH);
    bool fatal = (kind.ordinal & FATAL) != 0;
    bool isInfo = (kind.ordinal & INFO) != 0;
    if (isInfo && uri == null && !identical(kind, api.Diagnostic.INFO)) {
      info(message, kind);
      return;
    }
    var color;
    if (!enableColors) {
      color = (x) => x;
    } else if (identical(kind, api.Diagnostic.ERROR)) {
      color = colors.red;
    } else if (identical(kind, api.Diagnostic.WARNING)) {
      color = colors.magenta;
    } else if (identical(kind, api.Diagnostic.LINT)) {
      color = colors.magenta;
    } else if (identical(kind, api.Diagnostic.CRASH)) {
      color = colors.red;
    } else if (identical(kind, api.Diagnostic.INFO)) {
      color = colors.green;
    } else {
      throw 'Unknown kind: $kind (${kind.ordinal})';
    }
    if (uri == null) {
      assert(fatal);
      print(color(message));
    } else if (fatal || showWarnings) {
      SourceFile file = provider.sourceFiles[uri.toString()];
      if (file == null) {
        throw '$uri: file is null';
      }
      print(file.getLocationMessage(color(message), begin, end, true, color));
    }
    if (fatal && throwOnError) {
      isAborting = true;
      throw new AbortLeg(message);
    }
  }
}


