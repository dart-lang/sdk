// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'fuzz' test the file APIs by providing unexpected type arguments. The test
// passes if the VM does not crash.

#import('dart:io');

final typeMapping = const {
  'int': 0,
  'String': 'a',
  'FileMode': FileMode.READ,
  'num': 0.50,
  'List<int>': const [1, 2, 3]
};

doItSync(Function f) {
  // Ignore all exceptions.
  try { f(); } catch (var e) {}
}

fuzzSyncMethods() {
  typeMapping.forEach((k, v) {
    doItSync(() {
      var f = new File(v);
      doItSync(f.existsSync);
      doItSync(f.createSync);
      doItSync(f.deleteSync);
      doItSync(f.directorySync);
      doItSync(f.lengthSync);
      doItSync(f.fullPathSync);
      doItSync(() => f.openInputStream().onError = (e) => null);
      doItSync(f.readAsBytesSync);
      typeMapping.forEach((k2, v2) {
        doItSync(() => f.openSync(v2));
        doItSync(() => f.openOutputStream(v2).onError = (e) => null);
        doItSync(() => f.readAsTextSync(v2));
        doItSync(() => f.readAsLinesSync(v2));
      });
    });
  });
}

main() {
  fuzzSyncMethods();
}
