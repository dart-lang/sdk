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
import 'util/output_util.dart';

abstract class SourceFileByteReader {
  Uint8List getBytes(String filename);
}

abstract class SourceFileProvider implements api.CompilerInput {
  bool get isWindows => Platform.operatingSystem == 'windows';
  Uri cwd = Uri.base;
  int bytesRead = 0;
  int sourceBytesFromDill = 0;
  SourceFileByteReader byteReader;
  final Set<Uri> _registeredUris = {};
  final Map<Uri, Uri> _mappedUris = {};
  final bool disableByteCache;
  final Map<Uri, Uint8List> _byteCache = {};

  SourceFileProvider(this.byteReader, {this.disableByteCache = true});

  Future<api.Input<Uint8List>> readBytesFromUri(
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
  api.Input<Uint8List> _sourceToFile(
      Uri resourceUri, Uint8List source, api.InputKind inputKind) {
    switch (inputKind) {
      case api.InputKind.UTF8:
        return Utf8BytesSourceFile(resourceUri, source);
      case api.InputKind.binary:
        return Binary(resourceUri, source);
    }
  }

  @override
  void registerUtf8ContentsForDiagnostics(Uri resourceUri, Uint8List source) {
    if (!resourceUri.isAbsolute) {
      resourceUri = cwd.resolveUri(resourceUri);
    }

    registerUri(resourceUri);

    // Source bytes can be empty when the dill has source content erased. In
    // that case we should read the file contents from disk if we need them.
    if (!disableByteCache && source.isNotEmpty) {
      _byteCache[resourceUri] = source;
    }
    sourceBytesFromDill += source.length;
  }

  /// Registers the URI and returns true if the URI is new.
  bool registerUri(Uri uri) {
    return _registeredUris.add(uri);
  }

  api.Input<Uint8List> _readFromFileSync(Uri uri, api.InputKind inputKind) {
    final resourceUri = _mappedUris[uri] ?? uri;
    assert(resourceUri.isScheme('file'));
    Uint8List source;
    try {
      source = byteReader.getBytes(resourceUri.toFilePath());
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

  api.Input<Uint8List>? _readFromFileSyncOrNull(
      Uri uri, api.InputKind inputKind) {
    try {
      return _readFromFileSync(uri, inputKind);
    } catch (_) {
      return null;
    }
  }

  /// Read [resourceUri] directly as a UTF-8 file. If reading fails, `null` is
  /// returned.
  api.Input<Uint8List>? readUtf8FromFileSyncForTesting(Uri resourceUri) {
    try {
      return _readFromFileSync(resourceUri, api.InputKind.UTF8);
    } catch (e) {
      // Silence the error. The [resourceUri] was not requested by the user and
      // was only needed to give better error messages.
      return null;
    }
  }

  Future<api.Input<Uint8List>> _readFromFile(
      Uri resourceUri, api.InputKind inputKind) {
    api.Input<Uint8List> input;
    try {
      input = _readFromFileSync(resourceUri, inputKind);
    } catch (e) {
      return Future.error(e);
    }
    return Future.value(input);
  }

  /// Get the bytes for a previously accessed UTF-8 [Uri].
  api.Input<Uint8List>? getUtf8SourceFile(Uri resourceUri) {
    if (!resourceUri.isAbsolute) {
      resourceUri = cwd.resolveUri(resourceUri);
    }

    if (_byteCache.containsKey(resourceUri)) {
      return _sourceToFile(
          resourceUri, _byteCache[resourceUri]!, api.InputKind.UTF8);
    }
    return resourceUri.isScheme('file')
        ? _readFromFileSyncOrNull(resourceUri, api.InputKind.UTF8)
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
  Uint8List getBytes(String filename) {
    return readAll(filename);
  }
}

Uint8List readAll(String filename) {
  return File(filename).readAsBytesSync();
}

class CompilerSourceFileProvider extends SourceFileProvider {
  CompilerSourceFileProvider(
      {SourceFileByteReader byteReader = const MemoryCopySourceFileByteReader(),
      super.disableByteCache})
      : super(byteReader);

  @override
  Future<api.Input<Uint8List>> readFromUri(Uri uri,
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

  final int FATAL = api.Diagnostic.crash.ordinal | api.Diagnostic.error.ordinal;
  final int INFO =
      api.Diagnostic.info.ordinal | api.Diagnostic.verboseInfo.ordinal;

  FormattingDiagnosticHandler();

  void registerFileProvider(SourceFileProvider provider) {
    this.provider = provider;
  }

  void info(String message,
      [api.Diagnostic kind = api.Diagnostic.verboseInfo]) {
    if (!verbose && kind == api.Diagnostic.verboseInfo) return;
    if (enableColors) {
      print('${colors.green("Info:")} $message');
    } else {
      print('Info: $message');
    }
  }

  /// Adds [kind] specific prefix to [message].
  String prefixMessage(String message, api.Diagnostic kind) {
    switch (kind) {
      case api.Diagnostic.error:
        return 'Error: $message';
      case api.Diagnostic.warning:
        return 'Warning: $message';
      case api.Diagnostic.hint:
        return 'Hint: $message';
      case api.Diagnostic.crash:
        return 'Internal Error: $message';
      case api.Diagnostic.context:
      case api.Diagnostic.info:
      case api.Diagnostic.verboseInfo:
        return 'Info: $message';
    }
  }

  @override
  void report(var code, Uri? uri, int? begin, int? end, String message,
      api.Diagnostic kind) {
    if (isAborting) return;
    isAborting = (kind == api.Diagnostic.crash);

    bool fatal = (kind.ordinal & FATAL) != 0;
    bool isInfo = (kind.ordinal & INFO) != 0;
    if (isInfo && uri == null && kind != api.Diagnostic.info) {
      info(message, kind);
      return;
    }

    message = prefixMessage(message, kind);

    // [lastKind] records the previous non-INFO kind we saw.
    // This is used to suppress info about a warning when warnings are
    // suppressed, and similar for hints.
    if (kind != api.Diagnostic.info) {
      lastKind = kind;
    }
    String Function(String) color;
    if (kind == api.Diagnostic.error) {
      color = colors.red;
    } else if (kind == api.Diagnostic.warning) {
      if (!showWarnings) return;
      color = colors.magenta;
    } else if (kind == api.Diagnostic.hint) {
      if (!showHints) return;
      color = colors.cyan;
    } else if (kind == api.Diagnostic.crash) {
      color = colors.red;
    } else if (kind == api.Diagnostic.info) {
      color = colors.green;
    } else if (kind == api.Diagnostic.context) {
      if (lastKind == api.Diagnostic.warning && !showWarnings) return;
      if (lastKind == api.Diagnostic.hint && !showHints) return;
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
      api.Input<Uint8List>? file = provider.getUtf8SourceFile(uri);
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
  final String message;
  _CompilationErrorError(this.message);
  @override
  String toString() => 'Aborted due to --throw-on-error: $message';
}

typedef OnInfo = void Function(String message);
typedef OnFailure = Never Function(String message);

class RandomAccessFileOutputProvider implements api.CompilerOutput {
  // The file name to use for the main output. Also used as the filename prefix
  // for other URIs generated from this output provider. If `null` there is no
  // primary output but can still write other files.
  final Uri? out;
  final Uri? sourceMapOut;
  final OnInfo onInfo;
  final OnFailure onFailure;

  int totalCharactersWritten = 0;
  int totalCharactersWrittenPrimary = 0;
  int totalCharactersWrittenJavaScript = 0;
  int totalDataWritten = 0;

  List<String> allOutputFiles = <String>[];

  RandomAccessFileOutputProvider(this.out, this.sourceMapOut,
      {required this.onInfo, required this.onFailure});

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
    }

    allOutputFiles.add(fe.relativizeUri(Uri.base, uri, Platform.isWindows));

    void onClose(int charactersWritten) {
      totalCharactersWritten += charactersWritten;
      if (isPrimaryOutput) {
        totalCharactersWrittenPrimary += charactersWritten;
      }
      if (type == api.OutputType.js || type == api.OutputType.jsPart) {
        totalCharactersWrittenJavaScript += charactersWritten;
      }
    }

    return BufferedStringSinkWrapper(
        FileStringOutputSink(output, onClose: onClose));
  }

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
    }

    void onClose(int bytesWritten) {
      totalDataWritten += bytesWritten;
    }

    return FileBinaryOutputSink(output, onClose: onClose);
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
  Future<api.Input<Uint8List>> readFromUri(Uri uri,
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
    api.Input<Uint8List> result =
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
  Future<api.Input<Uint8List>> readFromUri(Uri uri,
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
    api.Input<Uint8List> result =
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
