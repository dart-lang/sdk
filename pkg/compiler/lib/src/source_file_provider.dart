// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_file_provider;

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';

import '../compiler.dart' as api show Diagnostic;
import '../compiler_new.dart' as api;
import '../compiler_new.dart';
import 'colors.dart' as colors;
import 'dart2js.dart' show AbortLeg;
import 'filenames.dart';
import 'io/source_file.dart';
import 'util/uri_extras.dart';

abstract class SourceFileProvider implements CompilerInput {
  bool isWindows = (Platform.operatingSystem == 'windows');
  Uri cwd = currentDirectory;
  Map<Uri, api.Input> utf8SourceFiles = <Uri, api.Input>{};
  Map<Uri, api.Input> binarySourceFiles = <Uri, api.Input>{};
  int dartCharactersRead = 0;

  Future<api.Input> readBytesFromUri(Uri resourceUri, api.InputKind inputKind) {
    api.Input input;
    switch (inputKind) {
      case api.InputKind.utf8:
        input = utf8SourceFiles[resourceUri];
        break;
      case api.InputKind.binary:
        input = binarySourceFiles[resourceUri];
        break;
    }
    if (input != null) return new Future.value(input);

    if (resourceUri.scheme == 'file') {
      return _readFromFile(resourceUri, inputKind);
    } else if (resourceUri.scheme == 'http' || resourceUri.scheme == 'https') {
      return _readFromHttp(resourceUri, inputKind);
    } else {
      throw new ArgumentError("Unknown scheme in uri '$resourceUri'");
    }
  }

  api.Input _readFromFileSync(Uri resourceUri, api.InputKind inputKind) {
    assert(resourceUri.scheme == 'file');
    List<int> source;
    try {
      source = readAll(resourceUri.toFilePath(),
          zeroTerminated: inputKind == api.InputKind.utf8);
    } on FileSystemException catch (ex) {
      String message = ex.osError?.message;
      String detail = message != null ? ' ($message)' : '';
      throw "Error reading '${relativizeUri(resourceUri)}' $detail";
    }
    dartCharactersRead += source.length;
    api.Input input;
    switch (inputKind) {
      case api.InputKind.utf8:
        input = utf8SourceFiles[resourceUri] = new CachingUtf8BytesSourceFile(
            resourceUri, relativizeUri(resourceUri), source);
        break;
      case api.InputKind.binary:
        input =
            binarySourceFiles[resourceUri] = new Binary(resourceUri, source);
        break;
    }
    return input;
  }

  /// Read [resourceUri] directly as a UTF-8 file. If reading fails, `null` is
  /// returned.
  api.Input autoReadFromFile(Uri resourceUri) {
    try {
      return _readFromFileSync(resourceUri, InputKind.utf8);
    } catch (e) {
      // Silence the error. The [resourceUri] was not requested by the user and
      // was only needed to give better error messages.
    }
    return null;
  }

  Future<api.Input> _readFromFile(Uri resourceUri, api.InputKind inputKind) {
    api.Input input;
    try {
      input = _readFromFileSync(resourceUri, inputKind);
    } catch (e) {
      return new Future.error(e);
    }
    return new Future.value(input);
  }

  Future<api.Input> _readFromHttp(Uri resourceUri, api.InputKind inputKind) {
    assert(resourceUri.scheme == 'http');
    HttpClient client = new HttpClient();
    return client
        .getUrl(resourceUri)
        .then((HttpClientRequest request) => request.close())
        .then((HttpClientResponse response) {
      if (response.statusCode != HttpStatus.OK) {
        String msg = 'Failure getting $resourceUri: '
            '${response.statusCode} ${response.reasonPhrase}';
        throw msg;
      }
      return response.toList();
    }).then((List<List<int>> splitContent) {
      int totalLength = splitContent.fold(0, (int old, List list) {
        return old + list.length;
      });
      Uint8List result = new Uint8List(totalLength);
      int offset = 0;
      for (List<int> contentPart in splitContent) {
        result.setRange(offset, offset + contentPart.length, contentPart);
        offset += contentPart.length;
      }
      dartCharactersRead += totalLength;
      api.Input input;
      switch (inputKind) {
        case api.InputKind.utf8:
          input = utf8SourceFiles[resourceUri] = new CachingUtf8BytesSourceFile(
              resourceUri, resourceUri.toString(), result);
          break;
        case api.InputKind.binary:
          input =
              binarySourceFiles[resourceUri] = new Binary(resourceUri, result);
          break;
      }
      return input;
    });
  }

  // TODO(johnniwinther): Remove this when no longer needed for the old compiler
  // API.
  Future /* <List<int> | String> */ call(Uri resourceUri) {
    throw "unimplemented";
  }

  relativizeUri(Uri uri) => relativize(cwd, uri, isWindows);

  SourceFile getUtf8SourceFile(Uri resourceUri) {
    return utf8SourceFiles[resourceUri];
  }

  Iterable<Uri> getSourceUris() {
    Set<Uri> uris = new Set<Uri>();
    uris.addAll(utf8SourceFiles.keys);
    uris.addAll(binarySourceFiles.keys);
    return uris;
  }
}

List<int> readAll(String filename, {bool zeroTerminated: true}) {
  RandomAccessFile file = (new File(filename)).openSync();
  int length = file.lengthSync();
  int bufferLength = length;
  if (zeroTerminated) {
    // +1 to have a 0 terminated list, see [Scanner].
    bufferLength++;
  }
  var buffer = new Uint8List(bufferLength);
  file.readIntoSync(buffer, 0, length);
  file.closeSync();
  return buffer;
}

class CompilerSourceFileProvider extends SourceFileProvider {
  // TODO(johnniwinther): Remove this when no longer needed for the old compiler
  // API.
  Future<List<int>> call(Uri resourceUri) =>
      readFromUri(resourceUri).then((input) => input.data);

  @override
  Future<api.Input<List<int>>> readFromUri(Uri uri,
          {InputKind inputKind: InputKind.utf8}) =>
      readBytesFromUri(uri, inputKind);
}

class FormattingDiagnosticHandler implements CompilerDiagnostics {
  final SourceFileProvider provider;
  bool showWarnings = true;
  bool showHints = true;
  bool verbose = false;
  bool isAborting = false;
  bool enableColors = false;
  bool throwOnError = false;
  bool autoReadFileUri = false;
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

  @override
  void report(var code, Uri uri, int begin, int end, String message,
      api.Diagnostic kind) {
    if (isAborting) return;
    isAborting = (kind == api.Diagnostic.CRASH);

    bool fatal = (kind.ordinal & FATAL) != 0;
    bool isInfo = (kind.ordinal & INFO) != 0;
    if (isInfo && uri == null && kind != api.Diagnostic.INFO) {
      info(message, kind);
      return;
    }

    message = prefixMessage(message, kind);

    // [lastKind] records the previous non-INFO kind we saw.
    // This is used to suppress info about a warning when warnings are
    // suppressed, and similar for hints.
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
      api.Input file = provider.getUtf8SourceFile(uri);
      if (file == null &&
          autoReadFileUri &&
          uri.scheme == 'file' &&
          uri.path.endsWith('.dart')) {
        // When reading from .dill files, the original source files haven't been
        // loaded. Load the file if possible to provide a better error message.
        file = provider.autoReadFromFile(uri);
      }
      if (file is SourceFile) {
        print(file.getLocationMessage(color(message), begin, end,
            colorize: color));
      } else {
        String position = end - begin > 0 ? '@$begin+${end - begin}' : '';
        print('${provider.relativizeUri(uri)}$position:\n'
            '${color(message)}');
      }
    }
    if (fatal && ++fatalCount >= throwOnErrorCount && throwOnError) {
      isAborting = true;
      throw new AbortLeg(message);
    }
  }

  // TODO(johnniwinther): Remove this when no longer needed for the old compiler
  // API.
  void call(Uri uri, int begin, int end, String message, api.Diagnostic kind) {
    return report(null, uri, begin, end, message, kind);
  }
}

typedef void MessageCallback(String message);

class RandomAccessFileOutputProvider implements CompilerOutput {
  final Uri out;
  final Uri sourceMapOut;
  final Uri resolutionOutput;
  final MessageCallback onInfo;
  final MessageCallback onFailure;

  int totalCharactersWritten = 0;
  int totalCharactersWrittenPrimary = 0;
  int totalCharactersWrittenJavaScript = 0;

  List<String> allOutputFiles = <String>[];

  RandomAccessFileOutputProvider(this.out, this.sourceMapOut,
      {this.onInfo, this.onFailure, this.resolutionOutput});

  static Uri computePrecompiledUri(Uri out) {
    String extension = 'precompiled.js';
    String outPath = out.path;
    if (outPath.endsWith('.js')) {
      outPath = outPath.substring(0, outPath.length - 3);
      return out.resolve('$outPath.$extension');
    } else {
      return out.resolve(extension);
    }
  }

  Uri createUri(String name, String extension, OutputType type) {
    Uri uri;
    // TODO(johnniwinther): Unify handle of [name] and [extension] to prepare
    // for using a single, possibly relative, [uri] as input.
    switch (type) {
      case OutputType.js:
        if (name == '') {
          uri = out;
        } else {
          uri = out.resolve('$name.$extension');
        }
        break;
      case OutputType.sourceMap:
        if (name == '') {
          uri = sourceMapOut;
        } else {
          uri = out.resolve('$name.$extension');
        }
        break;
      case OutputType.jsPart:
        uri = out.resolve('$name.$extension');
        break;
      case OutputType.serializationData:
        if (resolutionOutput == null) {
          onFailure('Serialization target unspecified.');
        }
        uri = resolutionOutput;
        break;
      case OutputType.info:
        if (name == '') {
          name = out.pathSegments.last;
        }
        if (extension == '') {
          uri = out.resolve(name);
        } else {
          uri = out.resolve('$name.$extension');
        }
        break;
      case OutputType.debug:
        uri = out.resolve('$name.$extension');
        break;
      default:
        onFailure('Unknown output type: $type');
    }
    return uri;
  }

  OutputSink createOutputSink(String name, String extension, OutputType type) {
    Uri uri = createUri(name, extension, type);
    bool isPrimaryOutput = uri == out;

    if (uri.scheme != 'file') {
      onFailure('Unhandled scheme ${uri.scheme} in $uri.');
    }

    RandomAccessFile output;
    try {
      output = new File(uri.toFilePath()).openSync(mode: FileMode.WRITE);
    } on FileSystemException catch (e) {
      onFailure('$e');
    }

    allOutputFiles.add(relativize(currentDirectory, uri, Platform.isWindows));

    int charactersWritten = 0;

    writeStringSync(String data) {
      // Write the data in chunks of 8kb, otherwise we risk running OOM.
      int chunkSize = 8 * 1024;

      int offset = 0;
      while (offset < data.length) {
        output.writeStringSync(
            data.substring(offset, math.min(offset + chunkSize, data.length)));
        offset += chunkSize;
      }
      charactersWritten += data.length;
    }

    onDone() {
      output.closeSync();
      totalCharactersWritten += charactersWritten;
      if (isPrimaryOutput) {
        totalCharactersWrittenPrimary += charactersWritten;
      }
      if (type == OutputType.js || type == OutputType.jsPart) {
        totalCharactersWrittenJavaScript += charactersWritten;
      }
    }

    return new _OutputSinkWrapper(writeStringSync, onDone);
  }
}

class _OutputSinkWrapper extends OutputSink {
  var onAdd, onClose;

  _OutputSinkWrapper(this.onAdd, this.onClose);

  void add(String data) => onAdd(data);

  void close() => onClose();
}

/// Adapter to integrate dart2js in bazel.
///
/// To handle bazel's special layout:
///
///  * We specify a .packages configuration file that expands packages to their
///    corresponding bazel location. This way there is no need to create a pub
///    cache prior to invoking dart2js.
///
///  * We provide an implicit mapping that can make all urls relative to the
///  bazel root.
///    To the compiler, URIs look like:
///      file:///bazel-root/a/b/c.dart
///
///    even though in the file system the file is located at:
///      file:///path/to/the/actual/bazel/root/a/b/c.dart
///
///    This mapping serves two purposes:
///      - It makes compiler results independent of the machine layout, which
///        enables us to share results across bazel runs and across machines.
///
///      - It hides the distinction between generated and source files. That way
///      we can use the standard package-resolution mechanism and ignore the
///      internals of how files are organized within bazel.
///
/// When invoking the compiler, bazel will use `package:` and
/// `file:///bazel-root/` URIs to specify entrypoints.
///
/// The mapping is specified using search paths relative to the current
/// directory. When this provider looks up a file, the bazel-root folder is
/// replaced by the first directory in the search path containing the file, if
/// any. For example, given the search path ".,bazel-bin/", and a URL
/// of the form `file:///bazel-root/a/b.dart`, this provider will check if the
/// file exists under "./a/b.dart", then check under "bazel-bin/a/b.dart".  If
/// none of the paths matches, it will attempt to load the file from
/// `/bazel-root/a/b.dart` which will likely fail.
class BazelInputProvider extends SourceFileProvider {
  final List<Uri> dirs;

  BazelInputProvider(List<String> searchPaths)
      : dirs = searchPaths.map(_resolve).toList();

  static _resolve(String path) => currentDirectory.resolve(path);

  @override
  Future<api.Input> readFromUri(Uri uri,
      {InputKind inputKind: InputKind.utf8}) async {
    var resolvedUri = uri;
    var path = uri.path;
    if (path.startsWith('/bazel-root')) {
      path = path.substring('/bazel-root/'.length);
      for (var dir in dirs) {
        var file = dir.resolve(path);
        if (await new File.fromUri(file).exists()) {
          resolvedUri = file;
          break;
        }
      }
    }
    api.Input result = await readBytesFromUri(resolvedUri, inputKind);
    switch (inputKind) {
      case InputKind.utf8:
        utf8SourceFiles[uri] = utf8SourceFiles[resolvedUri];
        break;
      case InputKind.binary:
        binarySourceFiles[uri] = binarySourceFiles[resolvedUri];
        break;
    }
    return result;
  }
}
