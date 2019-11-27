// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

import "dart:io" show ServerSocket;
import "dart:isolate";
import "dart:typed_data" show ByteData;

import "package:expect/expect.dart";
import "package:async_helper/async_helper.dart";

void main() async {
  final port = new ReceivePort();

  // Sending a socket object will result in an error.
  final socket = await ServerSocket.bind('localhost', 0);

  final x = new ByteData(4);
  for (int i = 0; i < 4; i++) {
    x.setUint8(i, i);
  }
  {
    final transferableFirst = TransferableTypedData.fromList([x]);
    Expect.throwsArgumentError(
        () => port.sendPort.send(<dynamic>[transferableFirst, socket]));
    // Once TransferableTypedData was sent even if attempt failed, it can't be
    // materialized.
    // This need to be changed so that on failed send we should not detach the
    // buffer form the transferrable. The order should not matter (i.e. if the
    // error happens before or after the serializer hits a transferrable object)

    final data1 = transferableFirst.materialize().asUint8List();
    Expect.equals(x.lengthInBytes, data1.length);
    for (int i = 0; i < data1.length; i++) {
      Expect.equals(i, data1[i]);
    }
  }
  {
    final transferableFirst = TransferableTypedData.fromList([x]);
    Expect.throwsArgumentError(() => port.sendPort
        .send(<dynamic>[transferableFirst, transferableFirst, socket]));
    // Once TransferableTypedData was sent even if attempt failed, it can't be
    // materialized.
    // This need to be changed so that on failed send we should not detach the
    // buffer form the transferrable. The order should not matter (i.e. if the
    // error happens before or after the serializer hits a transferrable object)

    final data1 = transferableFirst.materialize().asUint8List();
    Expect.equals(x.lengthInBytes, data1.length);
    for (int i = 0; i < data1.length; i++) {
      Expect.equals(i, data1[i]);
    }
  }

  {
    final transferableSecond = TransferableTypedData.fromList([x]);
    Expect.throwsArgumentError(
        () => port.sendPort.send(<dynamic>[socket, transferableSecond]));
    // Once TransferableTypedData was sent even if attempt failed, it can't be
    // materialized.
    final data2 = transferableSecond.materialize().asUint8List();
    Expect.equals(x.lengthInBytes, data2.length);
    for (int i = 0; i < data2.length; i++) {
      Expect.equals(i, data2[i]);
    }
  }

  {
    final transferableSecond = TransferableTypedData.fromList([x]);
    Expect.throwsArgumentError(() => port.sendPort
        .send(<dynamic>[socket, transferableSecond, transferableSecond]));
    // Once TransferableTypedData was sent even if attempt failed, it can't be
    // materialized.
    final data2 = transferableSecond.materialize().asUint8List();
    Expect.equals(x.lengthInBytes, data2.length);
    for (int i = 0; i < data2.length; i++) {
      Expect.equals(i, data2[i]);
    }
  }

  socket.close();
  port.close();
}
