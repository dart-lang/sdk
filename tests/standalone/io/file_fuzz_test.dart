// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// 'fuzz' test the file APIs by providing unexpected type arguments. The test
// passes if the VM does not crash.

#import('dart:io');
#import('dart:isolate');

final typeMapping = const {
  'null': null,
  'int': 0,
  'bigint': 18446744073709551617,
  'String': 'a',
  'FileMode': FileMode.READ,
  'num': 0.50,
  'List<int>': const [1, 2, 3],
  'Map<String, int>': const { "a": 23 }
};

typePermutations(int argCount) {
  var result = [];
  if (argCount == 2) {
    typeMapping.forEach((k, v) {
      typeMapping.forEach((k2, v2) {
        result.add([v, v2]);
      });
    });
  } else {
    Expect.isTrue(argCount == 3);
    typeMapping.forEach((k, v) {
      typeMapping.forEach((k2, v2) {
        typeMapping.forEach((k3, v3) {
          result.add([v, v2, v3]);
        });
      });
    });
  }
  return result;
}

// Perform sync operation and ignore all exceptions.
doItSync(Function f) {
  try { f(); } catch (var e) {}
}

// Perform async operation and transform the future for the operation
// into a future that never fails by treating errors as normal
// completion.
Future doItAsync(Function f) {
  // Ignore value and errors.
  var completer = new Completer();
  var future = f();
  future.handleException((e) {
    completer.complete(true);
    return true;
  });
  future.then((v) => completer.complete(true));
  return completer.future;
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
      doItSync(f.readAsTextSync);
      doItSync(f.readAsLinesSync);
      typeMapping.forEach((k2, v2) {
        doItSync(() => f.openSync(v2));
        doItSync(() => f.openOutputStream(v2).onError = (e) => null);
        doItSync(() => f.readAsTextSync(v2));
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
      futures.add(doItAsync(f.open));
      futures.add(doItAsync(f.fullPath));
      futures.add(doItAsync(f.readAsBytes));
      futures.add(doItAsync(f.readAsLines));
      futures.add(doItAsync(f.readAsText));
      typeMapping.forEach((k2, v2) {
        futures.add(doItAsync(() => f.open(v2)));
        futures.add(doItAsync(() => f.readAsText(v2)));
        futures.add(doItAsync(() => f.readAsLines(v2)));
      });
    });
  });
  Futures.wait(futures).then((ignore) => port.close());
}


// TODO(ager): Finish implementation.
fuzzSyncRandomAccessMethods() {
  var d = new Directory('');
  var temp = d.createTempSync();
  var file = new File('${temp.path}/x');
  file.createSync();
  var modes = [ FileMode.READ, FileMode.WRITE, FileMode.APPEND ];
  for (var m in modes) {
    var opened = file.openSync(m);
    typeMapping.forEach((k, v) {
      doItSync(() => opened.setPositionSync(v));
      doItSync(() => opened.writeByteSync(v));
    });
    for (var p in typePermutations(2)) {
      doItSync(() => opened.writeStringSync(p[0], p[1]));
    }
    for (var p in typePermutations(3)) {
      doItSync(() => opened.readListSync(p[0], p[1], p[2]));
      doItSync(() => opened.writeList(p[0], p[1], p[2]));
    }
    opened.closeSync();
  }
  temp.deleteRecursivelySync();
}

main() {
  fuzzSyncMethods();
  fuzzAsyncMethods();
  fuzzSyncRandomAccessMethods();
}
