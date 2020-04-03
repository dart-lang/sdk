// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--enable-isolate-groups
// VMOptions=--no-enable-isolate-groups

// https://github.com/dart-lang/sdk/issues/35778

import "dart:async";
import "dart:isolate";
import "dart:typed_data";
import "package:expect/expect.dart";

void child(replyPort) {
  print("Child start");

  replyPort.send(const <List>[]);
  replyPort.send(const <Map>[]);
  replyPort.send(const <Null>[]);
  replyPort.send(const <Object>[]);
  replyPort.send(const <String>[]);
  replyPort.send(const <bool>[]);
  replyPort.send(const <double>[]);
  replyPort.send(const <int>[]);
  replyPort.send(const <num>[]);

  replyPort.send(const <List, List>{});
  replyPort.send(const <List, Map>{});
  replyPort.send(const <List, Null>{});
  replyPort.send(const <List, Object>{});
  replyPort.send(const <List, String>{});
  replyPort.send(const <List, bool>{});
  replyPort.send(const <List, double>{});
  replyPort.send(const <List, int>{});
  replyPort.send(const <List, num>{});

  replyPort.send(const <Map, List>{});
  replyPort.send(const <Map, Map>{});
  replyPort.send(const <Map, Null>{});
  replyPort.send(const <Map, Object>{});
  replyPort.send(const <Map, String>{});
  replyPort.send(const <Map, bool>{});
  replyPort.send(const <Map, double>{});
  replyPort.send(const <Map, int>{});
  replyPort.send(const <Map, num>{});

  replyPort.send(const <Null, List>{});
  replyPort.send(const <Null, Map>{});
  replyPort.send(const <Null, Null>{});
  replyPort.send(const <Null, Object>{});
  replyPort.send(const <Null, String>{});
  replyPort.send(const <Null, bool>{});
  replyPort.send(const <Null, double>{});
  replyPort.send(const <Null, int>{});
  replyPort.send(const <Null, num>{});

  replyPort.send(const <Object, List>{});
  replyPort.send(const <Object, Map>{});
  replyPort.send(const <Object, Null>{});
  replyPort.send(const <Object, Object>{});
  replyPort.send(const <Object, String>{});
  replyPort.send(const <Object, bool>{});
  replyPort.send(const <Object, double>{});
  replyPort.send(const <Object, int>{});
  replyPort.send(const <Object, num>{});

  replyPort.send(const <String, List>{});
  replyPort.send(const <String, Map>{});
  replyPort.send(const <String, Null>{});
  replyPort.send(const <String, Object>{});
  replyPort.send(const <String, String>{});
  replyPort.send(const <String, bool>{});
  replyPort.send(const <String, double>{});
  replyPort.send(const <String, int>{});
  replyPort.send(const <String, num>{});

  replyPort.send(const <bool, List>{});
  replyPort.send(const <bool, Map>{});
  replyPort.send(const <bool, Null>{});
  replyPort.send(const <bool, Object>{});
  replyPort.send(const <bool, String>{});
  replyPort.send(const <bool, bool>{});
  replyPort.send(const <bool, double>{});
  replyPort.send(const <bool, int>{});
  replyPort.send(const <bool, num>{});

  replyPort.send(const <double, List>{});
  replyPort.send(const <double, Map>{});
  replyPort.send(const <double, Null>{});
  replyPort.send(const <double, Object>{});
  replyPort.send(const <double, String>{});
  replyPort.send(const <double, bool>{});
  replyPort.send(const <double, double>{});
  replyPort.send(const <double, int>{});
  replyPort.send(const <double, num>{});

  replyPort.send(const <int, List>{});
  replyPort.send(const <int, Map>{});
  replyPort.send(const <int, Null>{});
  replyPort.send(const <int, Object>{});
  replyPort.send(const <int, String>{});
  replyPort.send(const <int, bool>{});
  replyPort.send(const <int, double>{});
  replyPort.send(const <int, int>{});
  replyPort.send(const <int, num>{});

  replyPort.send(const <num, List>{});
  replyPort.send(const <num, Map>{});
  replyPort.send(const <num, Null>{});
  replyPort.send(const <num, Object>{});
  replyPort.send(const <num, String>{});
  replyPort.send(const <num, bool>{});
  replyPort.send(const <num, double>{});
  replyPort.send(const <num, int>{});
  replyPort.send(const <num, num>{});

  print("Child done");
}

Future<void> main(List<String> args) async {
  print("Parent start");

  ReceivePort port = new ReceivePort();
  Isolate.spawn(child, port.sendPort);
  StreamIterator<dynamic> incoming = new StreamIterator<dynamic>(port);

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int>[]));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num>[]));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <List, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Map, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Null, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <Object, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <String, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <bool, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <double, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <int, num>{}));

  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, List>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, Map>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, Null>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, Object>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, String>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, bool>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, double>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, int>{}));
  Expect.isTrue(await incoming.moveNext());
  Expect.isTrue(identical(incoming.current, const <num, num>{}));

  port.close();
  print("Parent done");
}
