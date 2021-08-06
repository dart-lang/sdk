// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'fuzz' test the directory APIs by providing unexpected type
// arguments. The test passes if the VM does not crash.

import 'dart:async';
import 'dart:io';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

import 'fuzz_support.dart';
import 'file_write_only_test.dart' show withTempDir, withTempDirSync;

fuzzSyncMethods() {
  withTempDirSync('dart_directory_fuzz', (temp) {
    typeMapping.forEach((k, v) {
      doItSync(() {
        Directory.systemTemp.createTempSync("${temp.path}/${v as String}")
            .deleteSync();
      });
      Directory? directory;
      doItSync(() => directory = new Directory("${temp.path}/${v as String}"));
      if (directory == null) return;
      final d = directory!;
      doItSync(d.existsSync);
      doItSync(d.createSync);
      doItSync(d.deleteSync);
      doItSync(d.listSync);
      doItSync(() {
        d.createTempSync('tempdir').deleteSync();
      });
      doItSync(() {
        // Let's be a little careful. If the directory exists we don't
        // want to delete it and all its contents.
        if (!d.existsSync()) d.deleteSync(recursive: true);
      });
      typeMapping.forEach((k2, v2) {
        doItSync(() => d.renameSync(v2 as String));
        doItSync(() => d.listSync(recursive: v2 as bool));
      });
    });
  });
}

fuzzAsyncMethods() async {
  asyncStart();
  await withTempDir('dart_directory_fuzz', (temp) async {
    final futures = <Future>[];
    typeMapping.forEach((k, v) {
      futures.add(doItAsync(() {
        Directory.systemTemp.createTempSync("${temp.path}/${v as String}")
            .deleteSync();
      }));
      if (v is! String) {
        return;
      }
      var d = new Directory("${temp.path}/$v");
      futures.add(doItAsync(d.exists));
      futures.add(doItAsync(d.create));
      futures.add(doItAsync(d.delete));
      futures.add(doItAsync(() {
        return d.createTemp('tempdir').then((temp) {
          return temp.delete();
        });
      }));
      futures.add(doItAsync(() {
        return d.exists().then((res) {
          if (!res) return d.delete(recursive: true);
          return new Future.value(true);
        });
      }));
      typeMapping.forEach((k2, v2) {
        futures.add(doItAsync(() => d.rename(v2 as String)));
        futures.add(doItAsync(() {
          d.list(recursive: v2 as bool).listen((_) {}, onError: (e) => null);
        }));
      });
    });
    await Future.wait(futures).then((_) => asyncEnd());
  });
}

main() {
  fuzzSyncMethods();
  fuzzAsyncMethods();
}
