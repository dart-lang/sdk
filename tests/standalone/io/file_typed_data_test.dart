// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
//
// Dart test program for testing file I/O.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import "package:async_helper/async_helper.dart";
import "package:expect/expect.dart";

void testWriteInt8ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Int8List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  Int8List list = new Int8List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Int8List.view(list.buffer,
                               OFFSET_IN_BYTES_FOR_VIEW,
                               VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, LIST_LENGTH);
    }).then((raf) {
      return raf.writeFrom(view, 0, VIEW_LENGTH);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      Expect.listEquals(expected, content);
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteUint8ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Uint8List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  Uint8List list = new Uint8List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Uint8List.view(list.buffer,
                                OFFSET_IN_BYTES_FOR_VIEW,
                                VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, LIST_LENGTH);
    }).then((raf) {
      return raf.writeFrom(view, 0, VIEW_LENGTH);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      Expect.listEquals(expected, content);
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteUint8ClampedListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Uint8ClampedList.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  Uint8ClampedList list = new Uint8ClampedList(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Uint8ClampedList.view(list.buffer,
                                       OFFSET_IN_BYTES_FOR_VIEW,
                                       VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(list, 0, LIST_LENGTH);
    }).then((raf) {
      return raf.writeFrom(view, 0, VIEW_LENGTH);
    }).then((raf) {
      return raf.close();
    }).then((_) {
      var expected = [];
      expected.addAll(list);
      expected.addAll(view);
      var content = file.readAsBytesSync();
      Expect.listEquals(expected, content);
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteInt16ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int LIST_LENGTH_IN_BYTES = LIST_LENGTH * Int16List.BYTES_PER_ELEMENT;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Int16List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  const int VIEW_LENGTH_IN_BYTES = VIEW_LENGTH * Int16List.BYTES_PER_ELEMENT;
  var list = new Int16List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Int16List.view(list.buffer,
                                OFFSET_IN_BYTES_FOR_VIEW,
                                VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(new Uint8List.view(list.buffer),
                           0,
                           LIST_LENGTH_IN_BYTES);
    }).then((raf) {
      return raf.writeFrom(new Uint8List.view(view.buffer,
                                              view.offsetInBytes,
                                              view.lengthInBytes),
                           0,
                           VIEW_LENGTH_IN_BYTES);
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
      Expect.listEquals(expected,
                        new Int16List.view(typed_data_content.buffer));
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteUint16ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int LIST_LENGTH_IN_BYTES = LIST_LENGTH * Uint16List.BYTES_PER_ELEMENT;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Uint16List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  const int VIEW_LENGTH_IN_BYTES = VIEW_LENGTH * Uint16List.BYTES_PER_ELEMENT;
  var list = new Uint16List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Uint16List.view(list.buffer,
                                 OFFSET_IN_BYTES_FOR_VIEW,
                                 VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(new Uint8List.view(list.buffer),
                           0,
                           LIST_LENGTH_IN_BYTES);
    }).then((raf) {
      return raf.writeFrom(new Uint8List.view(view.buffer,
                                              view.offsetInBytes,
                                              view.lengthInBytes),
                           0,
                           VIEW_LENGTH_IN_BYTES);
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
      Expect.listEquals(expected,
                        new Uint16List.view(typed_data_content.buffer));
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteInt32ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int LIST_LENGTH_IN_BYTES = LIST_LENGTH * Int32List.BYTES_PER_ELEMENT;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Int32List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  const int VIEW_LENGTH_IN_BYTES = VIEW_LENGTH * Int32List.BYTES_PER_ELEMENT;
  var list = new Int32List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Int32List.view(list.buffer,
                                OFFSET_IN_BYTES_FOR_VIEW,
                                VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(new Uint8List.view(list.buffer),
                           0,
                           LIST_LENGTH_IN_BYTES);
    }).then((raf) {
      return raf.writeFrom(new Uint8List.view(view.buffer,
                                              view.offsetInBytes,
                                              view.lengthInBytes),
                           0,
                           VIEW_LENGTH_IN_BYTES);
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
      Expect.listEquals(expected,
                        new Int32List.view(typed_data_content.buffer));
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteUint32ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int LIST_LENGTH_IN_BYTES = LIST_LENGTH * Int32List.BYTES_PER_ELEMENT;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Int32List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  const int VIEW_LENGTH_IN_BYTES = VIEW_LENGTH * Int32List.BYTES_PER_ELEMENT;
  var list = new Uint32List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Uint32List.view(list.buffer,
                                 OFFSET_IN_BYTES_FOR_VIEW,
                                 VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(new Uint8List.view(list.buffer),
                           0,
                           LIST_LENGTH_IN_BYTES);
    }).then((raf) {
      return raf.writeFrom(new Uint8List.view(view.buffer,
                                              view.offsetInBytes,
                                              view.lengthInBytes),
                           0,
                           VIEW_LENGTH_IN_BYTES);
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
      Expect.listEquals(expected,
                        new Uint32List.view(typed_data_content.buffer));
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteInt64ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int LIST_LENGTH_IN_BYTES = LIST_LENGTH * Int64List.BYTES_PER_ELEMENT;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Int64List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  const int VIEW_LENGTH_IN_BYTES = VIEW_LENGTH * Int64List.BYTES_PER_ELEMENT;
  var list = new Int64List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Int64List.view(list.buffer,
                                OFFSET_IN_BYTES_FOR_VIEW,
                                VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(new Uint8List.view(list.buffer),
                           0,
                           LIST_LENGTH_IN_BYTES);
    }).then((raf) {
      return raf.writeFrom(new Uint8List.view(view.buffer,
                                              view.offsetInBytes,
                                              view.lengthInBytes),
                           0,
                           VIEW_LENGTH_IN_BYTES);
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
      Expect.listEquals(expected,
                        new Int64List.view(typed_data_content.buffer));
      temp.deleteSync(recursive: true);
      asyncEnd();
    });
  });
}


void testWriteUint64ListAndView() {
  asyncStart();
  const int LIST_LENGTH = 8;
  const int LIST_LENGTH_IN_BYTES = LIST_LENGTH * Uint64List.BYTES_PER_ELEMENT;
  const int OFFSET_IN_BYTES_FOR_VIEW = 2 * Uint64List.BYTES_PER_ELEMENT;
  const int VIEW_LENGTH = 4;
  const int VIEW_LENGTH_IN_BYTES = VIEW_LENGTH * Uint64List.BYTES_PER_ELEMENT;
  var list = new Uint64List(LIST_LENGTH);
  for (int i = 0; i < LIST_LENGTH; i++) list[i] = i;
  var view = new Uint64List.view(list.buffer,
                                 OFFSET_IN_BYTES_FOR_VIEW,
                                 VIEW_LENGTH);

  Directory.systemTemp.createTemp('dart_file_typed_data').then((temp) {
    var file = new File("${temp.path}/test");
    file.open(mode: FileMode.WRITE).then((raf) {
      return raf.writeFrom(new Uint8List.view(list.buffer),
                           0,
                           LIST_LENGTH_IN_BYTES);
    }).then((raf) {
      return raf.writeFrom(new Uint8List.view(view.buffer,
                                              view.offsetInBytes,
                                              view.lengthInBytes),
                           0,
                           VIEW_LENGTH_IN_BYTES);
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
      Expect.listEquals(expected,
                        new Uint64List.view(typed_data_content.buffer));
      temp.deleteSync(recursive: true);
      asyncEnd();
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
