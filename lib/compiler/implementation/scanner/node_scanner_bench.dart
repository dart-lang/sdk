// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('node_scanner_bench');
#import('../../node/node.dart');
#import('scannerlib.dart');
#import('scanner_implementation.dart');
#import('scanner_bench.dart');
#import('../../../utf/utf.dart');
#source('byte_strings.dart');
#source('byte_array_scanner.dart');

class NodeScannerBench extends ScannerBench {
  int getBytes(String filename, void callback(bytes)) {
    // This actually returns a buffer, not a String.
    var s = fs.readFileSync(filename, null);
    callback(s);
    return s.length;
  }

  Scanner makeScanner(bytes) => new InflexibleByteArrayScanner(bytes);

  void checkExistence(String filename) {
    if (!path.existsSync(filename)) {
      throw "no such file: ${filename}";
    }
  }
}

class InflexibleByteArrayScanner extends ByteArrayScanner {
  InflexibleByteArrayScanner(List<int> bytes) : super(bytes);

  int byteAt(int index) => (bytes.length > index) ? bytes[index] : $EOF;

  int advance() {
    // This method should be equivalent to the one in super. However,
    // this is a *HOT* method and V8 performs better if it is easy to
    // inline.
    int index = ++byteOffset;
    int next = (bytes.length > index) ? bytes[index] : $EOF;
    return next;
  }
}

main() {
  new NodeScannerBench().main(argv);
}
