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

  String sourcesFor(Uri uri) =>
      _sources[uri] ??= new File.fromUri(uri).readAsStringSync();

  SourceFile fileFor(Uri uri) =>
      _files[uri] ??= new SourceFile.fromString(sourcesFor(uri));

  Dart2jsMapping mappingFor(Uri uri) => _mappings[uri] ??= parseMappingFor(uri);
}

warn(String message) {
  if (_seenMessages.add(message)) {
    print(message);
  }
}

Set<String> _seenMessages = new Set<String>();
