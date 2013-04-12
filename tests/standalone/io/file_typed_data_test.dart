// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

import "package:expect/expect.dart";
import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:typeddata';

void testWriteUint8ListAndView() {
  ReceivePort port = new ReceivePort();
  Uint8List list = new Uint8List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Uint8List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeList(list, 0, 8);
    }).then((raf) {
      return raf.writeList(view, 0, 4);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      Expect.listEquals(expected, content);
      temp.deleteSync(recursive: true);
      port.close();
    });
  });
}


main() {
  testWriteUint8ListAndView();
}
