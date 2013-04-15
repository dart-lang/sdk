// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'fuzz' test the file APIs by providing unexpected type arguments. The test
// passes if the VM does not crash.

import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'fuzz_support.dart';

fuzzSyncMethods() {
  typeMapping.forEach((k, v) {
    doItSync(() {
      var f = new File(v);
      doItSync(f.existsSync);
      doItSync(f.createSync);
      doItSync(f.deleteSync);
      doItSync(f.directorySync);
      doItSync(f.lengthSync);
      doItSync(f.modifiedSync);
      doItSync(f.fullPathSync);
      doItSync(() => f.openRead().listen(() {}, onError: (e) {}));
      doItSync(f.readAsBytesSync);
      doItSync(f.readAsStringSync);
      doItSync(f.readAsLinesSync);
      typeMapping.forEach((k2, v2) {
        doItSync(() => f.openSync(mode: v2));
        doItSync(() => f.openWrite(mode: v2));
        doItSync(() => f.readAsStringSync(v2));
        doItSync(() => f.readAsLinesSync(v2));
      });
    });
  });
}

fuzzAsyncMethods() {
  var port = new ReceivePort();
  var futures = [];
  typeMapping.forEach((k, v) {
    doItSync(() {
      var f = new File(v);
      futures.add(doItAsync(f.exists));
      futures.add(doItAsync(f.delete));
      futures.add(doItAsync(f.directory));
      futures.add(doItAsync(f.length));
      futures.add(doItAsync(f.modified));
      futures.add(doItAsync(f.open));
      futures.add(doItAsync(f.fullPath));
      futures.add(doItAsync(f.readAsBytes));
      futures.add(doItAsync(f.readAsLines));
      futures.add(doItAsync(f.readAsString));
      typeMapping.forEach((k2, v2) {
        futures.add(doItAsync(() => f.open(v2)));
        futures.add(doItAsync(() => f.readAsString(v2)));
        futures.add(doItAsync(() => f.readAsLines(v2)));
      });
    });
  });
  Future.wait(futures).then((ignore) => port.close());
}


fuzzSyncRandomAccessMethods() {
  var d = new Directory('');
  var temp = d.createTempSync();
  var file = new File('${temp.path}/x');
  file.createSync();
  var modes = [ FileMode.READ, FileMode.WRITE, FileMode.APPEND ];
  for (var m in modes) {
    var opened = file.openSync(mode: m);
    typeMapping.forEach((k, v) {
      doItSync(() => opened.setPositionSync(v));
      doItSync(() => opened.truncateSync(v));
      doItSync(() => opened.writeByteSync(v));
    });
    for (var p in typePermutations(2)) {
      doItSync(() => opened.writeStringSync(p[0], p[1]));
    }
    for (var p in typePermutations(3)) {
      doItSync(() => opened.readIntoSync(p[0], p[1], p[2]));
      doItSync(() => opened.writeFromSync(p[0], p[1], p[2]));
    }
    opened.closeSync();
  }
  temp.deleteSync(recursive: true);
}

fuzzAsyncRandomAccessMethods() {
  var d = new Directory('');
  var temp = d.createTempSync();
  var file = new File('${temp.path}/x');
  file.createSync();
  var modes = [ FileMode.READ, FileMode.WRITE, FileMode.APPEND ];
  var futures = [];
  var openedFiles = [];
  for (var m in modes) {
    var opened = file.openSync(mode: m);
    openedFiles.add(opened);
    typeMapping.forEach((k, v) {
        futures.add(doItAsync(() => opened.setPosition(v)));
        futures.add(doItAsync(() => opened.truncate(v)));
        futures.add(doItAsync(() => opened.writeByte(v)));
    });
    for (var p in typePermutations(2)) {
      futures.add(doItAsync(() => opened.writeString(p[0], p[1])));
    }
    for (var p in typePermutations(3)) {
      futures.add(doItAsync(() => opened.readInto(p[0], p[1], p[2])));
      futures.add(doItAsync(() => opened.writeFrom(p[0], p[1], p[2])));
    }
  }
  Future.wait(futures).then((ignore) {
    for (var opened in openedFiles) {
      opened.closeSync();
    }
    temp.deleteSync(recursive: true);
  });
}

main() {
  fuzzSyncMethods();
  fuzzAsyncMethods();
  fuzzSyncRandomAccessMethods();
  fuzzAsyncRandomAccessMethods();
}
