// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:typed_data';

import 'package:analyzer/file_system/file_system.dart';
import 'package:path/path.dart' as p;
import 'package:tar/tar.dart';

extension FolderExt on Folder {
  /// Create represented folder and parents recursively (if not exists).
  void createRecursively() {
    if (exists || isRoot) {
      return;
    }
    parent.createRecursively();
    create();
  }

  /// Extract [tarStream] into this [Folder].
  Future<void> extractTarStream(Stream<List<int>> tarStream) async {
    final reader = TarReader(tarStream);
    while (await reader.moveNext()) {
      final entry = reader.current;

      final relPath = p.posix.relative(
        p.posix.join('/', entry.name),
        from: '/',
      );
      if (relPath == '.') {
        continue;
      }

      if (entry.header.typeFlag == TypeFlag.dir) {
        getFolder(relPath).createRecursively();
      } else if (entry.header.typeFlag == TypeFlag.reg ||
          entry.header.typeFlag == TypeFlag.regA) {
        final file = getFile(relPath);
        file.parent.createRecursively();

        // Ensure that we copy the data, as TarReader may reuse buffers
        final builder = BytesBuilder(copy: true);
        await for (final chunk in entry.contents) {
          builder.add(chunk);
        }
        file.writeAsBytesSync(builder.takeBytes());
      }
    }
  }

  /// Create a tar-stream with everything inside this [Folder].
  Stream<List<int>> createTarStream() {
    final controller = StreamController<List<int>>();
    final tarSink = tarWritingSink(controller);
    final ctx = provider.pathContext;

    Future<void> addChildrenToTarSink(Folder dir) async {
      for (final child in dir.getChildren()) {
        final relPath = ctx.relative(child.path, from: path);
        final name = p.posix.joinAll(ctx.split(relPath));

        if (child is File) {
          tarSink.add(
            TarEntry.data(
              TarHeader(
                name: name,
                mode: 420, // 0644
                modified: DateTime.fromMillisecondsSinceEpoch(
                  child.modificationStamp,
                ).toUtc(),
              ),
              child.readAsBytesSync(),
            ),
          );
        } else if (child is Folder) {
          tarSink.add(
            TarEntry.data(
              TarHeader(
                name: '$name/',
                mode: 493, // 0755
                typeFlag: TypeFlag.dir,
                modified: DateTime.now().toUtc(),
              ),
              const [],
            ),
          );
          await addChildrenToTarSink(child);
        }
      }
    }

    unawaited(() async {
      try {
        await addChildrenToTarSink(this);
      } catch (e, st) {
        tarSink.addError(e, st);
      } finally {
        await tarSink.close();
      }
    }());

    return controller.stream;
  }
}
