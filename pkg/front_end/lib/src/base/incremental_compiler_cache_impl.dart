// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'dart:typed_data';

import 'package:kernel/ast.dart';

import 'incremental_compiler.dart' show IncrementalCompilerCache;
import 'incremental_serializer.dart';

// Coverage-ignore(suite): Not run.
abstract class AbstractIncrementalCompilerCache
    implements IncrementalCompilerCache {
  Uint8List? readFromId(String id);
  void writeToId(String id, Uint8List data);

  @override
  Uint8List? getCachedDillBytes(String transitiveDepsHash) {
    return readFromId(transitiveDepsHash);
  }

  @override
  void cacheLibraries(
    List<Library> libraries,
    String transitiveDepsHash,
    Component fromComponent,
  ) {
    writeToId(
      transitiveDepsHash,
      IncrementalSerializer.serialize(fromComponent, libraries),
    );
  }
}

// Coverage-ignore(suite): Not run.
class IncrementalCompilerCacheImpl extends AbstractIncrementalCompilerCache {
  final Directory directory;
  new(String directoryPath) : directory = new Directory(directoryPath);

  @override
  bool get mainDirectoryExists => directory.existsSync();

  @override
  Uint8List? readFromId(String id) {
    File file = new File.fromUri(directory.uri.resolve(id));
    if (!file.existsSync()) return null;
    return file.readAsBytesSync();
  }

  @override
  void writeToId(String id, Uint8List data) {
    // TODO(jensj): Possibly save under a different name and move the file once
    // finished writing like done in the analyzer.
    File file = new File.fromUri(directory.uri.resolve(id));
    file.createSync(recursive: true);
    file.writeAsBytesSync(data);
  }
}
