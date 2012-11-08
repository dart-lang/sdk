// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'fuzz' test the directory APIs by providing unexpected type
// arguments. The test passes if the VM does not crash.

#import('dart:io');
#import('dart:isolate');

#import('fuzz_support.dart');

fuzzSyncMethods() {
  typeMapping.forEach((k, v) {
    doItSync(() {
      var d = new Directory(v);
      doItSync(d.existsSync);
      doItSync(d.createSync);
      doItSync(d.deleteSync);
      doItSync(() {
        d.createTempSync().deleteSync();
      });
      doItSync(() {
        // Let's be a little careful. If the directory exists we don't
        // want to delete it and all its contents.
        if (!d.existsSync()) d.deleteSync(recursive: true);
      });
      typeMapping.forEach((k2, v2) {
        doItSync(() => d.renameSync(v2));
        doItSync(() => d.list(v2).onError = (e) => null);
      });
    });
  });
}

fuzzAsyncMethods() {
  var port = new ReceivePort();
  var futures = [];
  typeMapping.forEach((k, v) {
    var d = new Directory(v);
    futures.add(doItAsync(d.exists));
    futures.add(doItAsync(d.create));
    futures.add(doItAsync(d.delete));
    futures.add(doItAsync(() {
      return d.createTemp().chain((temp) {
        return temp.delete();
      });
    }));
    futures.add(doItAsync(() {
      return d.exists().chain((res) {
        if (!res) return d.delete(recursive: true);
        return new Future.immediate(true);
      });
    }));
    typeMapping.forEach((k2, v2) {
      futures.add(doItAsync(() => d.rename(v2)));
    });
  });
  Futures.wait(futures).then((ignore) => port.close());
}

main() {
  fuzzSyncMethods();
  fuzzAsyncMethods();
}
