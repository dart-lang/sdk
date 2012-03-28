// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('d8_scanner_bench');
#import('../../node/node.dart');
#import('scannerlib.dart');
#import('scanner_implementation.dart');
#import('scanner_bench.dart');

d8_read(String filename) native 'return read(filename)';

class D8ScannerBench extends ScannerBench {
  int getBytes(String filename, void callback(bytes)) {
    // This actually returns a buffer, not a String.
    var s = d8_read(filename);
    callback(s);
    return s.length;
  }

  Scanner makeScanner(bytes) => new StringScanner(bytes);

  void checkExistence(String filename) {
  }
}

main() {
  new D8ScannerBench().main(argv);
}
