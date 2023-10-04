// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library source_file_provider;

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:front_end/src/api_unstable/dart2js.dart' as fe;

import '../compiler_api.dart' as api;
import 'colors.dart' as colors;
import 'common/metrics.dart';
import 'io/source_file.dart';

abstract class SourceFileByteReader {
  List<int> getBytes(String filename, {bool zeroTerminated = true});
}

abstract class SourceFileProvider implements api.CompilerInput {
  bool isWindows = (Platform.operatingSystem == 'windows');
  Uri cwd = Uri.base;
  int bytesRead = 0;
  int sourceBytesFromDill = 0;
  SourceFileByteReader byteReader;
  final Set<Uri> _registeredUris = {};
  final Map<Uri, Uri> _mappedUris = {};
  final bool disableByteCache;
  final Map<Uri, List<int>> _byteCache = {};

  SourceFileProvider(this.byteReader, {this.disableByteCache = true});

  Future<api.Input<List<int>>> readBytesFromUri(
      Uri resourceUri, api.InputKind inputKind) {
    if (!resourceUri.isAbsolute) {
      resourceUri = cwd.resolveUri(resourceUri);
    }
    if (resourceUri.isScheme('file')) {
      return _readFromFile(resourceUri, inputKind);
    } else {
      throw ArgumentError("Unknown scheme in uri '$resourceUri'");
    }
  }

  /// Adds [source] to the cache under the [resourceUri] key.
  api.Input<List<int>> _sourceToFile(
      Uri resourceUri, List<int> source, api.InputKind inputKind) {
    switch (inputKind) {
      case api.InputKind.UTF8:
        return Utf8BytesSourceFile(resourceUri, source);
      case api.InputKind.binary:
        return Binary(resourceUri, source);
    }
  }

  @override
  void registerUtf8ContentsForDiagnostics(Uri resourceUri, List<int> source) {
    if (!resourceUri.isAbsolute) {
      resourceUri = cwd.resolveUri(resourceUri);
    }

    registerUri(resourceUri);
    if (!disableByteCache) {
      _byteCache[resourceUri] = source;
    }
    sourceBytesFromDill += source.length;
  }

  /// Registers the URI and returns true if the URI is new.
  bool registerUri(Uri uri) {
    return _registeredUris.add(uri);
  }

  api.Input<List<int>> _readFromFileSync(Uri uri, api.InputKind inputKind) {
    final resourceUri = _mappedUris[uri] ?? uri;
    assert(resourceUri.isScheme('file'));
    List<int> source;
    try {
      source = byteReader.getBytes(resourceUri.toFilePath(),
          zeroTerminated: inputKind == api.InputKind.UTF8);
    } on FileSystemException catch (ex) {
      String? message = ex.osError?.message;
      String detail = message != null ? ' ($message)' : '';
      throw "Error reading '${relativizeUri(resourceUri)}' $detail";
    }
    if (registerUri(resourceUri)) {
      bytesRead += source.length;
    }
    if (resourceUri != uri) {
      registerUri(uri);
    }
    return _sourceToFile(Uri.parse(relativizeUri(uri)), source, inputKind);
  }

  /// Read [resourceUri] directly as a UTF-8 file. If reading fails, `null` is
  /// returned.
  api.Input<List<int>>? readUtf8FromFileSyncForTesting(Uri resourceUri) {
    try {
      return _readFromFileSync(resourceUri, api.InputKind.UTF8);
    } catch (e) {
      // Silence the error. The [resourceUri] was not requested by the user and
      // was only needed to give better error messages.
      return null;
    }
  }

  Future<api.Input<List<int>>> _readFromFile(
      Uri resourceUri, api.InputKind inputKind) {
    api.Input<List<int>> input;
    try {
      input = _readFromFileSync(resourceUri, inputKind);
    } catch (e) {
      return Future.error(e);
    }
    return Future.value(input);
  }

  /// Get the bytes for a previously accessed UTF-8 [Uri].
  api.Input<List<int>>? getUtf8SourceFile(Uri resourceUri) {
    if (!resourceUri.isAbsolute) {
      resourceUri = cwd.resolveUri(resourceUri);
    }

    if (_byteCache.containsKey(resourceUri)) {
      return _sourceToFile(
          resourceUri, _byteCache[resourceUri]!, api.InputKind.UTF8);
    }
    return resourceUri.isScheme('file')
        ? _readFromFileSync(resourceUri, api.InputKind.UTF8)
        : null;
  }

  String relativizeUri(Uri uri) => fe.relativizeUri(cwd, uri, isWindows);

  // Note: this includes also indirect sources that were used to create
  // `.dill` inputs to the compiler. This is OK, since this API is only
  // used to calculate DEPS for gn build systems.
  Iterable<Uri> getSourceUris() => [..._registeredUris, ..._mappedUris.keys];
}

class MemoryCopySourceFileByteReader implements SourceFileByteReader {
  const MemoryCopySourceFileByteReader();
  @override
  List<int> getBytes(String filename, {bool zeroTerminated = true}) {
    return readAll(filename, zeroTerminated: zeroTerminated);
  }
}

Uint8List readAll(String filename, {bool zeroTerminated = true}) {
  RandomAccessFile file = File(filename).openSync();
  int length = file.lengthSync();
  int bufferLength = length;
  if (zeroTerminated) {
    // +1 to have a 0 terminated list, see [Scanner].
    bufferLength++;
  }
  var buffer = Uint8List(bufferLength);
  file.readIntoSync(buffer, 0, length);
  file.closeSync();
  return buffer;
}

class CompilerSourceFileProvider extends SourceFileProvider {
  CompilerSourceFileProvider(
      {SourceFileByteReader byteReader = const MemoryCopySourceFileByteReader(),
      super.disableByteCache})
      : super(byteReader);

  @override
  Future<api.Input<List<int>>> readFromUri(Uri uri,
          {api.InputKind inputKind = api.InputKind.UTF8}) =>
      readBytesFromUri(uri, inputKind);
}

class FormattingDiagnosticHandler implements api.CompilerDiagnostics {
  late final SourceFileProvider provider;
  bool showWarnings = true;
  bool showHints = true;
  bool verbose = false;
  bool isAborting = false;
  bool enableColors = false;
  bool throwOnError = false;
  int throwOnErrorCount = 0;
  api.Diagnostic? lastKind = null;
  int fatalCount = 0;

  final int FATAL = api.Diagnostic.CRASH.ordinal | api.Diagnostic.ERROR.ordinal;
  final int INFO =
      api.Diagnostic.INFO.ordinal | api.Diagnostic.VERBOSE_INFO.ordinal;

  FormattingDiagnosticHandler();

  void registerFileProvider(SourceFileProvider provider) {
    this.provider = provider;
  }

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
      case api.Diagnostic.CONTEXT:
      case api.Diagnostic.INFO:
      case api.Diagnostic.VERBOSE_INFO:
        return 'Info: $message';
    }
    throw 'Unexpected diagnostic kind: $kind (${kind.ordinal})';
  }

  @override
  void report(var code, Uri? uri, int? begin, int? end, String message,
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
    String Function(String) color;
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
      color = colors.green;
    } else if (kind == api.Diagnostic.CONTEXT) {
      if (lastKind == api.Diagnostic.WARNING && !showWarnings) return;
      if (lastKind == api.Diagnostic.HINT && !showHints) return;
      color = colors.green;
    } else {
      throw 'Unknown kind: $kind (${kind.ordinal})';
    }
    if (!enableColors) {
      color = (String x) => x;
    }
    if (uri == null) {
      print('${color(message)}');
    } else {
      api.Input<List<int>>? file = provider.getUtf8SourceFile(uri);
      if (file is SourceFile && begin != null && end != null) {
        print(file.getLocationMessage(color(message), begin, end,
            colorize: color));
      } else {
        String position = begin != null && end != null && end - begin > 0
            ? '@$begin+${end - begin}'
            : '';
        print('${provider.relativizeUri(uri)}$position:\n'
            '${color(message)}');
      }
    }
    if (fatal && ++fatalCount >= throwOnErrorCount && throwOnError) {
      isAborting = true;
      throw _CompilationErrorError(message);
    }
  }
}

class _CompilationErrorError {
  final message;
  _CompilationErrorError(this.message);
  @override
  toString() => 'Aborted due to --throw-on-error: $message';
}

typedef MessageCallback = void Function(String message);

class RandomAccessFileOutputProvider implements api.CompilerOutput {
  // The file name to use for the main output. Also used as the filename prefix
  // for other URIs generated from this output provider. If `null` there is no
  // primary output but can still write other files.
  final Uri? out;
  final Uri? sourceMapOut;
  final MessageCallback onInfo;

  // TODO(48820): Make [onFailure] return `Never`. The value passed in for the
  // real compiler exits. [onFailure] is not specified or faked in some tests.
  final MessageCallback onFailure;

  int totalCharactersWritten = 0;
  int totalCharactersWrittenPrimary = 0;
  int totalCharactersWrittenJavaScript = 0;
  int totalDataWritten = 0;

  List<String> allOutputFiles = <String>[];

  RandomAccessFileOutputProvider(this.out, this.sourceMapOut,
      {this.onInfo = _ignore, this.onFailure = _ignore});

  static void _ignore(String message) {}

  Uri createUri(String name, String extension, api.OutputType type) {
    Uri uri;
    // TODO(johnniwinther): Unify handle of [name] and [extension] to prepare
    // for using a single, possibly relative, [uri] as input.
    switch (type) {
      case api.OutputType.js:
        if (name == '') {
          uri = out!;
        } else {
          uri = out!.resolve('$name.$extension');
        }
        break;
      case api.OutputType.sourceMap:
        if (name == '') {
          uri = sourceMapOut!;
        } else {
          uri = out!.resolve('$name.$extension');
        }
        break;
      case api.OutputType.jsPart:
        uri = out!.resolve('$name.$extension');
        break;
      case api.OutputType.deferredLoadIds:
        assert(name.isNotEmpty);
        return (out ?? Uri.base).resolve(name);
      case api.OutputType.dumpInfo:
      case api.OutputType.dumpUnusedLibraries:
      case api.OutputType.deferredMap:
      case api.OutputType.resourceIdentifiers:
        if (name == '') {
          name = out!.pathSegments.last;
        }
        if (extension == '') {
          uri = out!.resolve(name);
        } else {
          uri = out!.resolve('$name.$extension');
        }
        break;
      case api.OutputType.debug:
        if (name == '') {
          name = out!.pathSegments.last;
        }
        uri = out!.resolve('$name.$extension');
        break;
      default:
        onFailure('Unknown output type: $type');
        throw StateError('unreachable');
    }
    return uri;
  }

  @override
  api.OutputSink createOutputSink(
      String name, String extension, api.OutputType type) {
    Uri uri = createUri(name, extension, type);
    bool isPrimaryOutput = uri == out;

    if (!uri.isScheme('file')) {
      onFailure('Unhandled scheme ${uri.scheme} in $uri.');
    }

    RandomAccessFile output;
    try {
      output = (File(uri.toFilePath())..createSync(recursive: true))
          .openSync(mode: FileMode.write);
    } on FileSystemException catch (e) {
      onFailure('$e');
      // TODO(48820): Make onFailure return `Never`
      throw StateError('unreachable');
    }

    allOutputFiles.add(fe.relativizeUri(Uri.base, uri, Platform.isWindows));

    int charactersWritten = 0;

    void writeStringSync(String data) {
      // Write the data in chunks of 8kb, otherwise we risk running OOM.
      int chunkSize = 8 * 1024;

      int offset = 0;
      while (offset < data.length) {
        String chunk;
        int cut = offset + chunkSize;
        if (cut < data.length) {
          // Don't break the string in the middle of a code point encoded as two
          // surrogate pairs since `writeStringSync` will encode the unpaired
          // surrogates as U+FFFD REPLACEMENT CHARACTER.
          int lastCodeUnit = data.codeUnitAt(cut - 1);
          if (_isLeadSurrogate(lastCodeUnit)) {
            cut -= 1;
          }
          chunk = data.substring(offset, cut);
        } else {
          chunk = offset == 0 ? data : data.substring(offset);
        }
        output.writeStringSync(chunk);
        offset += chunk.length;
      }
      charactersWritten += data.length;
    }

    void onDone() {
      output.closeSync();
      totalCharactersWritten += charactersWritten;
      if (isPrimaryOutput) {
        totalCharactersWrittenPrimary += charactersWritten;
      }
      if (type == api.OutputType.js || type == api.OutputType.jsPart) {
        totalCharactersWrittenJavaScript += charactersWritten;
      }
    }

    return _OutputSinkWrapper(writeStringSync, onDone);
  }

  static bool _isLeadSurrogate(int codeUnit) => (codeUnit & 0xFC00) == 0xD800;

  @override
  api.BinaryOutputSink createBinarySink(Uri uri) {
    uri = Uri.base.resolveUri(uri);

    allOutputFiles.add(fe.relativizeUri(Uri.base, uri, Platform.isWindows));

    if (!uri.isScheme('file')) {
      onFailure('Unhandled scheme ${uri.scheme} in $uri.');
    }

    RandomAccessFile output;
    try {
      output = (File(uri.toFilePath())..createSync(recursive: true))
          .openSync(mode: FileMode.write);
    } on FileSystemException catch (e) {
      onFailure('$e');
      // TODO(48820): Make `onFailure` return `Never`.
      throw StateError('unreachable');
    }

    int bytesWritten = 0;

    void writeBytesSync(List<int> data, [int start = 0, int? end]) {
      output.writeFromSync(data, start, end);
      bytesWritten += (end ?? data.length) - start;
    }

    void onDone() {
      output.closeSync();
      totalDataWritten += bytesWritten;
    }

    return _BinaryOutputSinkWrapper(writeBytesSync, onDone);
  }
}

class RandomAccessBinaryOutputSink implements api.BinaryOutputSink {
  final RandomAccessFile output;

  RandomAccessBinaryOutputSink(Uri uri)
      : output = File.fromUri(uri).openSync(mode: FileMode.write);

  @override
  void add(List<int> buffer, [int start = 0, int? end]) {
    output.writeFromSync(buffer, start, end);
  }

  @override
  void close() {
    output.closeSync();
  }
}

class _OutputSinkWrapper extends api.OutputSink {
  void Function(String) onAdd;
  void Function() onClose;

  _OutputSinkWrapper(this.onAdd, this.onClose);

  @override
  void add(String data) => onAdd(data);

  @override
  void close() => onClose();
}

class _BinaryOutputSinkWrapper extends api.BinaryOutputSink {
  void Function(List<int>, [int, int?]) onWrite;
  void Function() onClose;

  _BinaryOutputSinkWrapper(this.onWrite, this.onClose);

  @override
  void add(List<int> data, [int start = 0, int? end]) =>
      onWrite(data, start, end);

  @override
  void close() => onClose();
}

/// Adapter to integrate dart2js in bazel.
///
/// To handle bazel's special layout:
///
///  * We specify a .dart_tool/package_config.json configuration file that
///    expands packages to their corresponding bazel location.
///    This way there is no need to create a pub
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

  BazelInputProvider(List<String> searchPaths, super.byteReader,
      {super.disableByteCache})
      : dirs = searchPaths.map(_resolve).toList();

  static Uri _resolve(String path) => Uri.base.resolve(path);

  @override
  Future<api.Input<List<int>>> readFromUri(Uri uri,
      {api.InputKind inputKind = api.InputKind.UTF8}) async {
    var resolvedUri = uri;
    var path = uri.path;
    if (path.startsWith('/bazel-root')) {
      path = path.substring('/bazel-root/'.length);
      for (var dir in dirs) {
        var file = dir.resolve(path);
        if (await File.fromUri(file).exists()) {
          resolvedUri = file;
          break;
        }
      }
    }
    api.Input<List<int>> result =
        await readBytesFromUri(resolvedUri, inputKind);
    if (uri != resolvedUri) {
      if (!resolvedUri.isAbsolute) {
        resolvedUri = cwd.resolveUri(resolvedUri);
      }
      _mappedUris[uri] = resolvedUri;
    }
    return result;
  }
}

/// Adapter to support one or more synthetic uri schemes.
///
/// These custom uris map to one or more real directories on the file system,
/// providing a merged view - or "overlay" file system.
///
/// This also allows for hermetic builds which do not encode machine specific
/// absolute uris by creating a synthetic "root" of the file system.
///
/// TODO(sigmund): Remove the [BazelInputProvider] in favor of this.
/// TODO(sigmund): Remove this and use the common `MultiRootFileSystem`
/// implementation.
class MultiRootInputProvider extends SourceFileProvider {
  final List<Uri> roots;
  final String markerScheme;

  MultiRootInputProvider(this.markerScheme, this.roots, super.byteReader,
      {super.disableByteCache});

  @override
  Future<api.Input<List<int>>> readFromUri(Uri uri,
      {api.InputKind inputKind = api.InputKind.UTF8}) async {
    var resolvedUri = uri;
    if (resolvedUri.isScheme(markerScheme)) {
      var path = resolvedUri.path;
      if (path.startsWith('/')) path = path.substring(1);
      for (var dir in roots) {
        var fileUri = dir.resolve(path);
        if (await File.fromUri(fileUri).exists()) {
          resolvedUri = fileUri;
          break;
        }
      }
    }
    api.Input<List<int>> result =
        await readBytesFromUri(resolvedUri, inputKind);
    _mappedUris[uri] = resolvedUri;
    return result;
  }
}

class DataReadMetrics extends MetricsBase {
  @override
  String get namespace => 'input';
  CountMetric inputBytes = CountMetric('inputBytes');
  CountMetric sourceBytes = CountMetric('sourceBytes');

  void addDataRead(api.CompilerInput input) {
    if (input is SourceFileProvider) {
      inputBytes.add(input.bytesRead);
      sourceBytes.add(input.sourceBytesFromDill);
      if (primary.isEmpty) {
        primary = [inputBytes, sourceBytes];
      }
    }
  }
}
