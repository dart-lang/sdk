// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dev_compiler.src.in_memory;

import 'package:analyzer/src/generated/ast.dart';
import 'package:analyzer/src/generated/engine.dart' show TimestampedData;
import 'package:analyzer/src/generated/source.dart';
import 'package:path/path.dart' as path;
import 'package:source_span/source_span.dart';

import 'dependency_graph.dart' show runtimeFilesForServerMode;

/// Uri resolver that can load test files from memory.
class InMemoryUriResolver extends UriResolver {
  final Map<Uri, InMemorySource> files = <Uri, InMemorySource>{};

  /// Whether to represent a non-existing file with a [TestSource] (default
  /// behavior from analyzer), or to use null (possible when overriding the
  /// package-url-resolvers.)
  final bool representNonExistingFiles;

  InMemoryUriResolver(Map<String, String> allFiles,
      {this.representNonExistingFiles: true}) {
    allFiles.forEach((key, value) {
      var uri = key.startsWith('package:') ? Uri.parse(key) : new Uri.file(key);
      files[uri] = new InMemorySource(uri, value);
    });

    // TODO(vsm): Separate flag here?
    if (representNonExistingFiles) {
      runtimeFilesForServerMode.forEach((filepath) {
        var uri = Uri.parse('/dev_compiler_runtime/$filepath');
        files[uri] =
            new InMemorySource(uri, '/* test contents of $filepath */');
      });
    }
  }

  Source resolveAbsolute(Uri uri) {
    if (uri.scheme != 'file' && uri.scheme != 'package') return null;
    if (!representNonExistingFiles) return files[uri];
    return files.putIfAbsent(uri, () => new InMemorySource(uri, null));
  }
}

class InMemoryContents implements TimestampedData<String> {
  int modificationTime;
  String data;

  InMemoryContents(this.modificationTime, this.data);
}

/// An in memory source file.
class InMemorySource implements Source {
  final Uri uri;
  InMemoryContents contents;
  final SourceFile _file;
  final UriKind uriKind;

  InMemorySource(uri, contents)
      : uri = uri,
        contents = new InMemoryContents(1, contents),
        _file = contents != null ? new SourceFile(contents, url: uri) : null,
        uriKind = uri.scheme == 'file' ? UriKind.FILE_URI : UriKind.PACKAGE_URI;

  bool exists() => contents.data != null;

  Source get source => this;

  String _encoding;
  String get encoding => _encoding != null ? _encoding : (_encoding = '$uri');

  String get fullName => uri.path;

  int get modificationStamp => contents.modificationTime;
  String get shortName => path.basename(uri.path);

  operator ==(other) => other is InMemorySource && uri == other.uri;
  int get hashCode => uri.hashCode;
  bool get isInSystemLibrary => false;

  Uri resolveRelativeUri(Uri relativeUri) => uri.resolveUri(relativeUri);

  SourceSpan spanFor(AstNode node) {
    final begin = node is AnnotatedNode
        ? node.firstTokenAfterCommentAndMetadata.offset
        : node.offset;
    return _file.span(begin, node.end);
  }

  String toString() => '[$runtimeType: $uri]';
}
