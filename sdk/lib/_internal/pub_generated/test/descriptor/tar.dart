// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library descriptor.tar;

import 'dart:async';

import 'package:path/path.dart' as path;
import 'package:scheduled_test/scheduled_test.dart';
import 'package:scheduled_test/descriptor.dart';

import '../../lib/src/io.dart';

/// Describes a tar file and its contents.
class TarFileDescriptor extends DirectoryDescriptor implements
    ReadableDescriptor {
  TarFileDescriptor(String name, List<Descriptor> contents)
      : super(name, contents);

  /// Creates the files and directories within this tar file, then archives
  /// them, compresses them, and saves the result to [parentDir].
  Future<String> create([String parent]) => schedule(() {
    if (parent == null) parent = defaultRoot;
    return withTempDir((tempDir) {
      return Future.wait(contents.map((entry) {
        return entry.create(tempDir);
      })).then((_) {
        var createdContents =
            listDir(tempDir, recursive: true, includeHidden: true);
        return createTarGz(createdContents, baseDir: tempDir).toBytes();
      }).then((bytes) {
        var file = path.join(parent, name);
        writeBinaryFile(file, bytes);
        return file;
      });
    });
  }, 'creating tar file:\n${describe()}');

  /// Validates that the `.tar.gz` file at [path] contains the expected
  /// contents.
  Future validate([String parent]) {
    throw new UnimplementedError("TODO(nweiz): implement this");
  }

  Stream<List<int>> read() {
    return new Stream<List<int>>.fromFuture(withTempDir((tempDir) {
      return create(
          tempDir).then((_) => readBinaryFile(path.join(tempDir, name)));
    }));
  }
}
