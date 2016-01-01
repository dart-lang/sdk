// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.index.indexable_file;

import 'package:analysis_server/src/provisional/index/index_core.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * An [IndexableObject] which is used to index references to a file.
 */
class IndexableFile implements IndexableObject {
  /**
   * The path of the file to be indexed.
   */
  @override
  final String path;

  /**
   * Initialize a newly created indexable file to represent the given [path].
   */
  IndexableFile(this.path);

  @override
  String get filePath => path;

  @override
  IndexableObjectKind get kind => IndexableFileKind.INSTANCE;

  @override
  int get offset => -1;

  @override
  bool operator ==(Object object) =>
      object is IndexableFile && object.path == path;

  @override
  String toString() => path;
}

/**
 * The kind of an indexable file.
 */
class IndexableFileKind implements IndexableObjectKind<IndexableFile> {
  /**
   * The unique instance of this class.
   */
  static final IndexableFileKind INSTANCE =
      new IndexableFileKind._(IndexableObjectKind.nextIndex);

  /**
   * The index uniquely identifying this kind.
   */
  final int index;

  /**
   * Initialize a newly created kind to have the given [index].
   */
  IndexableFileKind._(this.index) {
    IndexableObjectKind.register(this);
  }

  @override
  IndexableFile decode(AnalysisContext context, String filePath, int offset) {
    return new IndexableFile(filePath);
  }

  @override
  int encodeHash(StringToInt stringToInt, IndexableFile indexable) {
    String path = indexable.path;
    return stringToInt(path);
  }
}
