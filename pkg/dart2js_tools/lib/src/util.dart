import 'dart:io';
import 'package:source_span/source_span.dart';
import 'dart2js_mapping.dart';

abstract class FileProvider {
  String sourcesFor(Uri uri);
  SourceFile fileFor(Uri uri);
  Dart2jsMapping mappingFor(Uri uri);
}

class CachingFileProvider implements FileProvider {
  final Map<Uri, String> _sources = {};
  final Map<Uri, SourceFile> _files = {};
  final Map<Uri, Dart2jsMapping> _mappings = {};
  final Logger logger;

  CachingFileProvider({this.logger});

  String sourcesFor(Uri uri) =>
      _sources[uri] ??= new File.fromUri(uri).readAsStringSync();

  SourceFile fileFor(Uri uri) =>
      _files[uri] ??= new SourceFile.fromString(sourcesFor(uri));

  Dart2jsMapping mappingFor(Uri uri) =>
      _mappings[uri] ??= parseMappingFor(uri, logger: logger);
}

/// A provider that converts `http:` URLs to a `file:` URI assuming that all
/// files were downloaded on the current working directory.
///
/// Typically used when downloading the source and source-map files and applying
/// deobfuscation locally for debugging purposes.
class DownloadedFileProvider extends CachingFileProvider {
  _localize(uri) {
    if (uri.scheme == 'http' || uri.scheme == 'https') {
      String filename = uri.path.substring(uri.path.lastIndexOf('/') + 1);
      return Uri.base.resolve(filename);
    }
    return uri;
  }

  String sourcesFor(Uri uri) => super.sourcesFor(_localize(uri));

  SourceFile fileFor(Uri uri) => super.fileFor(_localize(uri));

  Dart2jsMapping mappingFor(Uri uri) => super.mappingFor(_localize(uri));
}

class Logger {
  Set<String> _seenMessages = new Set<String>();
  log(String message) {
    if (_seenMessages.add(message)) {
      print(message);
    }
  }
}

var logger = Logger();
