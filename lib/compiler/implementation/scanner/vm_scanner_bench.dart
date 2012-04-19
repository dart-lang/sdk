// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('vm_scanner_bench');
#import('dart:io');
#import('scannerlib.dart');
#import('scanner_implementation.dart');
#import('scanner_bench.dart');
#import('../../../utf/utf.dart');
#import('../util/characters.dart');
#source('byte_strings.dart');
#source('byte_array_scanner.dart');

class VmScannerBench extends ScannerBench {
  int getBytes(String filename, void callback(List<int> bytes)) {
    var file = (new File(filename)).openSync(FileMode.READ);
    int size = file.lengthSync();
    List<int> bytes = new ByteArray(size + 1);
    file.readListSync(bytes, 0, size);
    bytes[size] = $EOF;
    file.closeSync();
    callback(bytes);
    return bytes.length - 1;
  }

  void checkExistence(String filename) {
    File file = new File(filename);
    if (!file.existsSync()) {
      print("no such file: ${filename}");
    }
  }

  Scanner makeScanner(bytes) => new ByteArrayScanner(bytes);
}

main() {
  new VmScannerBench().main(argv);
}
