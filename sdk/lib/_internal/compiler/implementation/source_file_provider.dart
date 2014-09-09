// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_file_provider;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import '../compiler.dart' as api show Diagnostic;
import 'dart2js.dart' show AbortLeg;
import 'colors.dart' as colors;
import 'source_file.dart';
import 'filenames.dart';
import 'util/uri_extras.dart';
import 'dart:typed_data';

List<int> readAll(String filename) {
  var file = (new File(filename)).openSync();
  var length = file.lengthSync();
  // +1 to have a 0 terminated list, see [Scanner].
  var buffer = new Uint8List(length + 1);
  var bytes = file.readIntoSync(buffer, 0, length);
  file.closeSync();
  return buffer;
}

abstract class SourceFileProvider {
  bool isWindows = (Platform.operatingSystem == 'windows');
  Uri cwd = currentDirectory;
  Map<String, SourceFile> sourceFiles = <String, SourceFile>{};
  int dartCharactersRead = 0;

  Future<String> readStringFromUri(Uri resourceUri) {
    return readUtf8BytesFromUri(resourceUri).then(UTF8.decode);
  }

  Future<List<int>> readUtf8BytesFromUri(Uri resourceUri) {
    if (resourceUri.scheme != 'file') {
      throw new ArgumentError("Unknown scheme in uri '$resourceUri'");
    }
    List<int> source;
    try {
      source = readAll(resourceUri.toFilePath());
    } on FileSystemException catch (ex) {
      return new Future.error(
          "Error reading '${relativize(cwd, resourceUri, isWindows)}' "
          "(${ex.osError})");
    }
    dartCharactersRead += source.length;
    sourceFiles[resourceUri.toString()] =
        new CachingUtf8BytesSourceFile(relativizeUri(resourceUri), source);
    return new Future.value(source);
  }

  Future/*<List<int> | String>*/ call(Uri resourceUri);

  relativizeUri(Uri uri) => relativize(cwd, uri, isWindows);
}

class CompilerSourceFileProvider extends SourceFileProvider {
  Future<List<int>> call(Uri resourceUri) => readUtf8BytesFromUri(resourceUri);
}

class FormattingDiagnosticHandler {
  final SourceFileProvider provider;
  bool showWarnings = true;
  bool showHints = true;
  bool verbose = false;
  bool isAborting = false;
  bool enableColors = false;
  bool throwOnError = false;
  int throwOnErrorCount = 0;
  api.Diagnostic lastKind = null;
  int fatalCount = 0;

  final int FATAL = api.Diagnostic.CRASH.ordinal | api.Diagnostic.ERROR.ordinal;
  final int INFO =
      api.Diagnostic.INFO.ordinal | api.Diagnostic.VERBOSE_INFO.ordinal;

  FormattingDiagnosticHandler([SourceFileProvider provider])
      : this.provider =
          (provider == null) ? new CompilerSourceFileProvider() : provider;

  void info(var message, [api.Diagnostic kind = api.Diagnostic.VERBOSE_INFO]) {
    if (!verbose && kind == api.Diagnostic.VERBOSE_INFO) return;
    if (enableColors) {
      print('${colors.green("Info:")} $message');
    } else {
      print('Info: $message');
    }
  }

  /// Adds [kind] specific prefix to [message].
  String prefixMessage(String message, api.Diagnostic kind) {
    switch (kind) {
      case api.Diagnostic.ERROR:
        return 'Error: $message';
      case api.Diagnostic.WARNING:
        return 'Warning: $message';
      case api.Diagnostic.HINT:
        return 'Hint: $message';
      case api.Diagnostic.CRASH:
        return 'Internal Error: $message';
      case api.Diagnostic.INFO:
      case api.Diagnostic.VERBOSE_INFO:
        return 'Info: $message';
    }
    throw 'Unexpected diagnostic kind: $kind (${kind.ordinal})';
  }

  void diagnosticHandler(Uri uri, int begin, int end, String message,
                         api.Diagnostic kind) {
    // TODO(ahe): Remove this when source map is handled differently.
    if (identical(kind.name, 'source map')) return;

    if (isAborting) return;
    isAborting = (kind == api.Diagnostic.CRASH);

    bool fatal = (kind.ordinal & FATAL) != 0;
    bool isInfo = (kind.ordinal & INFO) != 0;
    if (isInfo && uri == null && kind != api.Diagnostic.INFO) {
      info(message, kind);
      return;
    }

    message = prefixMessage(message, kind);

    // [previousKind]/[lastKind] records the previous non-INFO kind we saw.
    // This is used to suppress info about a warning when warnings are
    // suppressed, and similar for hints.
    var previousKind = lastKind;
    if (kind != api.Diagnostic.INFO) {
      lastKind = kind;
    }
    var color;
    if (kind == api.Diagnostic.ERROR) {
      color = colors.red;
    } else if (kind == api.Diagnostic.WARNING) {
      if (!showWarnings) return;
      color = colors.magenta;
    } else if (kind == api.Diagnostic.HINT) {
      if (!showHints) return;
      color = colors.cyan;
    } else if (kind == api.Diagnostic.CRASH) {
      color = colors.red;
    } else if (kind == api.Diagnostic.INFO) {
      if (lastKind == api.Diagnostic.WARNING && !showWarnings) return;
      if (lastKind == api.Diagnostic.HINT && !showHints) return;
      color = colors.green;
    } else {
      throw 'Unknown kind: $kind (${kind.ordinal})';
    }
    if (!enableColors) {
      color = (x) => x;
    }
    if (uri == null) {
      print('${color(message)}');
    } else {
      SourceFile file = provider.sourceFiles[uri.toString()];
      if (file != null) {
        print(file.getLocationMessage(color(message), begin, end, true, color));
      } else {
        print('${provider.relativizeUri(uri)}@$begin+${end - begin}:'
              ' [$kind] ${color(message)}');
      }
    }
    if (fatal && ++fatalCount >= throwOnErrorCount && throwOnError) {
      isAborting = true;
      throw new AbortLeg(message);
    }
  }

  void call(Uri uri, int begin, int end, String message, api.Diagnostic kind) {
    return diagnosticHandler(uri, begin, end, message, kind);
  }
}
