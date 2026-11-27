// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://github.com/dart-lang/sdk/issues/64872 and
// https://github.com/dart-lang/sdk/issues/63660.

// ignore: import_internal_library
import 'dart:_internal' show VMInternalsForTesting;
import 'dart:async';
import 'dart:io';
import 'dart:isolate';

void exitOnFirstEntry(String root) {
  for (int i = 0; i < 4; i++) {
    Directory(root).list(recursive: true).listen((_) {
      Isolate.exit();
    }, onError: (Object _) {});
  }
}

void exitImmediately(String root) {
  Directory(root).list(recursive: true).listen((_) {}, onError: (Object _) {});
  Isolate.exit();
}

void buildTree(Directory root) {
  // Batch size in Directory::ListNextRequest is 64 entries (kArraySize = 128).
  // 64 empty subdirectories ensures the first ListNextRequest fills the batch
  // and pushes all 64 unopened directories, so the second ListNextRequest does
  // 64 NamespaceScope + openat64 calls after the isolate exits.
  for (int i = 0; i < 64; i++) {
    Directory('${root.path}/dir_$i').createSync();
  }
}

Future<void> main() async {
  final root = Directory.systemTemp.createTempSync('dart_regress_64872');
  try {
    buildTree(root);

    final exitFutures = <Future<void>>[];

    Future<void> spawn(
      void Function(String) entry, {
      bool gcOnExit = false,
    }) async {
      final onExit = ReceivePort();
      await Isolate.spawn(entry, root.path, onExit: onExit.sendPort);
      exitFutures.add(
        onExit.first.then((_) {
          onExit.close();
          if (gcOnExit) {
            // ignore: undefined_unqualified_name_read
            VMInternalsForTesting.collectAllGarbage();
          }
        }),
      );
    }

    for (int i = 0; i < 20; i++) {
      await spawn(exitImmediately);
    }

    // Saturate the IOService thread pool (32 workers) so queued
    // directoryListNext requests outlive their isolates and run after
    // collectAllGarbage() finalizes the exited isolates' _NamespaceImpl.
    final spawns = <Future<void>>[];
    for (int i = 0; i < 64; i++) {
      spawns.add(spawn(exitOnFirstEntry, gcOnExit: true));
    }
    await Future.wait(spawns);
    await Future.wait(exitFutures);
    // ignore: undefined_unqualified_name_read
    VMInternalsForTesting.collectAllGarbage();
    await Future<void>.delayed(const Duration(milliseconds: 200));
  } finally {
    try {
      root.deleteSync(recursive: true);
    } catch (_) {}
  }
}
