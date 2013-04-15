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

void testWriteInt8ListAndView() {
  ReceivePort port = new ReceivePort();
  Int8List list = new Int8List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Int8List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
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


void testWriteUint8ListAndView() {
  ReceivePort port = new ReceivePort();
  Uint8List list = new Uint8List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Uint8List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
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


void testWriteUint8ClampedListAndView() {
  ReceivePort port = new ReceivePort();
  Uint8ClampedList list = new Uint8ClampedList(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Uint8ClampedList.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
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


void testWriteInt16ListAndView() {
  ReceivePort port = new ReceivePort();
  var list = new Int16List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Int16List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      var typed_data_content = new Uint8List(content.length);
      for (int i = 0; i < content.length; i++) {
        typed_data_content[i] = content[i];
      }
      Expect.listEquals(expected, new Int16List.view(typed_data_content));
      temp.deleteSync(recursive: true);
      port.close();
    });
  });
}


void testWriteUint16ListAndView() {
  ReceivePort port = new ReceivePort();
  var list = new Uint16List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Uint16List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      var typed_data_content = new Uint8List(content.length);
      for (int i = 0; i < content.length; i++) {
        typed_data_content[i] = content[i];
      }
      Expect.listEquals(expected, new Uint16List.view(typed_data_content));
      temp.deleteSync(recursive: true);
      port.close();
    });
  });
}


void testWriteInt32ListAndView() {
  ReceivePort port = new ReceivePort();
  var list = new Int32List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Int32List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      var typed_data_content = new Uint8List(content.length);
      for (int i = 0; i < content.length; i++) {
        typed_data_content[i] = content[i];
      }
      Expect.listEquals(expected, new Int32List.view(typed_data_content));
      temp.deleteSync(recursive: true);
      port.close();
    });
  });
}


void testWriteUint32ListAndView() {
  ReceivePort port = new ReceivePort();
  var list = new Uint32List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Uint32List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      var typed_data_content = new Uint8List(content.length);
      for (int i = 0; i < content.length; i++) {
        typed_data_content[i] = content[i];
      }
      Expect.listEquals(expected, new Uint32List.view(typed_data_content));
      temp.deleteSync(recursive: true);
      port.close();
    });
  });
}


void testWriteInt64ListAndView() {
  ReceivePort port = new ReceivePort();
  var list = new Int64List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Int64List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
        //      return raf.writeList(view, 0, 4);
        //}).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      //expected.addAll(view);
      var content = file.readAsBytesSync();
      var typed_data_content = new Uint8List(content.length);
      for (int i = 0; i < content.length; i++) {
        typed_data_content[i] = content[i];
      }
      Expect.listEquals(expected, new Int64List.view(typed_data_content));
      temp.deleteSync(recursive: true);
      port.close();
    });
  });
}


void testWriteUint64ListAndView() {
  ReceivePort port = new ReceivePort();
  var list = new Uint64List(8);
  for (int i = 0; i < 8; i++) list[i] = i;
  var view = new Uint64List.view(list.buffer, 2, 4);

  new Directory('').createTemp().then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, 8);
    }).then((raf) {
      return raf.writeFrom(view, 0, 4);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      var typed_data_content = new Uint8List(content.length);
      for (int i = 0; i < content.length; i++) {
        typed_data_content[i] = content[i];
      }
      Expect.listEquals(expected, new Uint64List.view(typed_data_content));
      temp.deleteSync(recursive: true);
      port.close();
    });
  });
}


main() {
  testWriteInt8ListAndView();
  testWriteUint8ListAndView();
  testWriteUint8ClampedListAndView();
  testWriteInt16ListAndView();
  testWriteUint16ListAndView();
  testWriteInt32ListAndView();
  testWriteUint32ListAndView();
  testWriteInt64ListAndView();
  testWriteUint64ListAndView();
}
