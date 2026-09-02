// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:async/async.dart';
import 'package:dartpad/src/worker_client.dart';

import '../../worker_harness.dart';

void main() {
  testDartWorkspace('watch add file', (ws) async {
    final watcher = ws.watch('.');
    final changes = StreamQueue(watcher.changes);
    await watcher.ready;

    await ws.writeFileFromText('main.dart', 'void main() {}');

    await check(changes).emits(
      (e) => e
        ..isA<FileAddedEvent>()
        ..uri.equals(ws.workspaceFolder.resolve('main.dart')),
    );

    await changes.cancel();
  });

  testDartWorkspace('watch modify file', (ws) async {
    await ws.writeFileFromText('main.dart', 'void main() {}');

    final watcher = ws.watch('.');
    final changes = StreamQueue(watcher.changes);
    await watcher.ready;

    await ws.writeFileFromText('main.dart', 'void main() { print("hello"); }');

    await check(changes).emits(
      (e) => e
        ..isA<FileModifiedEvent>()
        ..uri.equals(ws.workspaceFolder.resolve('main.dart')),
    );

    await changes.cancel();
  });

  testDartWorkspace('watch remove file', (ws) async {
    await ws.writeFileFromText('main.dart', 'void main() {}');

    final watcher = ws.watch('.');
    final changes = StreamQueue(watcher.changes);
    await watcher.ready;

    await ws.deleteFileSystemEntity('main.dart');

    await check(changes).emits(
      (e) => e
        ..isA<FileRemovedEvent>()
        ..uri.equals(ws.workspaceFolder.resolve('main.dart')),
    );

    await changes.cancel();
  });

  testDartWorkspace('watch folders', (ws) async {
    final watcher = ws.watch('.');
    final changes = StreamQueue(watcher.changes);
    await watcher.ready;

    await ws.createFolder('lib');

    await check(changes).emits(
      (e) => e
        ..isA<FileAddedEvent>()
        ..uri.equals(ws.workspaceFolder.resolve('lib')),
    );

    await ws.deleteFileSystemEntity('lib');

    await check(changes).emits(
      (e) => e
        ..isA<FileRemovedEvent>()
        ..uri.equals(ws.workspaceFolder.resolve('lib')),
    );

    await changes.cancel();
  });

  testDartWorkspace('watch specific file', (ws) async {
    await ws.writeFileFromText('main.dart', 'void main() {}');

    // Watch just the specific file
    final watcher = ws.watch('main.dart');
    final changes = StreamQueue(watcher.changes);
    await watcher.ready;

    await ws.writeFileFromText(
      'main.dart',
      'void main() { print("changed"); }',
    );

    await check(changes).emits(
      (e) => e
        ..isA<FileModifiedEvent>()
        ..uri.path.endsWith('main.dart'),
    );

    await changes.cancel();
  });

  testDartWorkspace('watch and pub get', (ws) async {
    // Watch the root to stress test and see everything being modified
    final watcher = ws.watch('/');
    final changes = StreamQueue(watcher.changes);
    await watcher.ready;

    await ws.writeFileFromText('pubspec.yaml', '''
      name: myapp
      publish_to: none
      dev_dependencies:
        foo:
      environment:
        sdk: ^3.11.0
    ''');

    // Ignore the log, just run the command
    await ws.pub(command: 'get');

    // pub get modifies many files. We can use `emitsThrough` to verify
    // the specific files we care about, ignoring the rest.

    await check(changes).emitsThrough(
      (e) => e
        ..isA<FileAddedEvent>()
        ..uri.path.startsWith('/pub-cache/')
        ..uri.path.endsWith('pubspec.yaml'),
    );

    await check(changes).emitsThrough(
      (e) => e
        ..isA<FileModifiedEvent>()
        ..uri.path.endsWith('pubspec.lock'),
    );

    await changes.cancel();
  });
}
