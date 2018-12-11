// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' as io;

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:path/path.dart' as pathLib;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:watcher/watcher.dart';

import 'physical_file_system_test.dart' show BaseTest;

main() {
  if (!new bool.fromEnvironment('skipPhysicalResourceProviderTests')) {
    defineReflectiveSuite(() {
      defineReflectiveTests(PhysicalResourceProviderWatchTest);
    });
  }
}

@reflectiveTest
class PhysicalResourceProviderWatchTest extends BaseTest {
  test_watchFile_delete() {
    var path = pathLib.join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFile(path, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.deleteSync();
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        if (io.Platform.isWindows) {
          // See https://github.com/dart-lang/sdk/issues/23762
          // Not sure why this breaks under Windows, but testing to see whether
          // we are running Windows causes the type to change. For now we print
          // the type out of curiosity.
          print('PhysicalResourceProviderWatchTest:test_watchFile_delete '
              'received an event with type = ${changesReceived[0].type}');
        } else {
          expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        }
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFile_modify() {
    var path = pathLib.join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFile(path, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFolder_createFile() {
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      var path = pathLib.join(tempPath, 'foo');
      new io.File(path).writeAsStringSync('contents');
      return _delayed(() {
        // There should be an "add" event indicating that the file was added.
        // Depending on how long it took to write the contents, it may be
        // followed by "modify" events.
        expect(changesReceived, isNotEmpty);
        expect(changesReceived[0].type, equals(ChangeType.ADD));
        expect(changesReceived[0].path, equals(path));
        for (int i = 1; i < changesReceived.length; i++) {
          expect(changesReceived[i].type, equals(ChangeType.MODIFY));
          expect(changesReceived[i].path, equals(path));
        }
      });
    });
  }

  test_watchFolder_deleteFile() {
    var path = pathLib.join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.deleteSync();
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.REMOVE));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFolder_modifyFile() {
    var path = pathLib.join(tempPath, 'foo');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, hasLength(1));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  test_watchFolder_modifyFile_inSubDir() {
    var fooPath = pathLib.join(tempPath, 'foo');
    new io.Directory(fooPath).createSync();
    var path = pathLib.join(tempPath, 'bar');
    var file = new io.File(path);
    file.writeAsStringSync('contents 1');
    return _watchingFolder(tempPath, (changesReceived) {
      expect(changesReceived, hasLength(0));
      file.writeAsStringSync('contents 2');
      return _delayed(() {
        expect(changesReceived, anyOf(hasLength(1), hasLength(2)));
        expect(changesReceived[0].type, equals(ChangeType.MODIFY));
        expect(changesReceived[0].path, equals(path));
      });
    });
  }

  Future _delayed(computation()) {
    // Give the tests 1 second to detect the changes. While it may only
    // take up to a few hundred ms, a whole second gives a good margin
    // for when running tests.
    return new Future.delayed(new Duration(seconds: 1), computation);
  }

  _watchingFile(String path, test(List<WatchEvent> changesReceived)) {
    // Delay before we start watching the file.  This is necessary
    // because on MacOS, file modifications that occur just before we
    // start watching are sometimes misclassified as happening just after
    // we start watching.
    return _delayed(() {
      File file = PhysicalResourceProvider.INSTANCE.getResource(path);
      var changesReceived = <WatchEvent>[];
      var subscription = file.changes.listen(changesReceived.add);
      // Delay running the rest of the test to allow file.changes propagate.
      return _delayed(() => test(changesReceived)).whenComplete(() {
        subscription.cancel();
      });
    });
  }

  _watchingFolder(String path, test(List<WatchEvent> changesReceived)) {
    // Delay before we start watching the folder.  This is necessary
    // because on MacOS, file modifications that occur just before we
    // start watching are sometimes misclassified as happening just after
    // we start watching.
    return _delayed(() {
      Folder folder = PhysicalResourceProvider.INSTANCE.getResource(path);
      var changesReceived = <WatchEvent>[];
      var subscription = folder.changes.listen(changesReceived.add);
      // Delay running the rest of the test to allow folder.changes to
      // take a snapshot of the current directory state.  Otherwise it
      // won't be able to reliably distinguish new files from modified
      // ones.
      return _delayed(() => test(changesReceived)).whenComplete(() {
        subscription.cancel();
      });
    });
  }
}
