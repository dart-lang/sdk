// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:collection';

import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/java_io.dart';
import 'package:analyzer/src/generated/source.dart';

export 'package:analyzer/src/generated/source.dart';

/// Instances of the class `FileBasedSource` implement a source that represents
/// a file.
class FileBasedSource extends Source {
  /// Map from encoded URI/filepath pair to a unique integer identifier.  This
  /// identifier is used for equality tests and hash codes.
  ///
  /// The URI and filepath are joined into a pair by separating them with an '@'
  /// character.
  static final Map<String, int> _idTable = HashMap<String, int>();

  /// The URI from which this source was originally derived.
  @override
  final Uri uri;

  /// The unique ID associated with this [FileBasedSource].
  final int id;

  /// The file represented by this source.
  final JavaFile file;

  /// The cached absolute path of this source.
  String _absolutePath;

  /// The cached encoding for this source.
  String _encoding;

  /// Initialize a newly created source object to represent the given [file]. If
  /// a [uri] is given, then it will be used as the URI from which the source
  /// was derived, otherwise a `file:` URI will be created based on the [file].
  FileBasedSource(JavaFile file, [Uri uri])
      : uri = uri ?? file.toURI(),
        file = file,
        id = _idTable.putIfAbsent(
            '${uri ?? file.toURI()}@${file.getPath()}', () => _idTable.length);

  @override
  TimestampedData<String> get contents {
    return contentsFromFile;
  }

  /// Get the contents and timestamp of the underlying file.
  ///
  /// Clients should consider using the method [AnalysisContext.getContents]
  /// because contexts can have local overrides of the content of a source that
  /// the source is not aware of.
  ///
  /// @return the contents of the source paired with the modification stamp of
  /// the source
  /// @throws Exception if the contents of this source could not be accessed
  /// See [contents].
  TimestampedData<String> get contentsFromFile {
    return TimestampedData<String>(
        file.lastModified(), file.readAsStringSync());
  }

  @override
  String get encoding {
    return _encoding ??= uri.toString();
  }

  @override
  String get fullName {
    return _absolutePath ??= file.getAbsolutePath();
  }

  @override
  int get hashCode => uri.hashCode;

  @override
  bool get isInSystemLibrary => uri.scheme == DartUriResolver.DART_SCHEME;

  @override
  int get modificationStamp => file.lastModified();

  @override
  String get shortName => file.getName();

  @override
  UriKind get uriKind {
    String scheme = uri.scheme;
    return UriKind.fromScheme(scheme);
  }

  @override
  bool operator ==(Object object) {
    if (object is FileBasedSource) {
      return id == object.id;
    } else if (object is Source) {
      return uri == object.uri;
    }
    return false;
  }

  @override
  bool exists() => file.isFile();

  @override
  String toString() {
    if (file == null) {
      return "<unknown source>";
    }
    return file.getAbsolutePath();
  }
}
