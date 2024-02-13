// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'package:dtd/dtd.dart';

void main(List<String> args) async {
  final url = args[0]; // pass the url as a param to the example
  final clientA = await DartToolingDaemon.connect(Uri.parse('ws://$url'));
  final clientB = await DartToolingDaemon.connect(Uri.parse('ws://$url'));

  clientA.onEvent('Foo').listen((event) {
    print('A Received $event from Foo Stream');
  });
  clientB.onEvent('Foo').listen((event) {
    print('B Received $event from Foo Stream');
  });

  await clientA.streamListen('Foo');
  await clientB.streamListen('Foo');

  await clientA.postEvent('Foo', 'kind1', {'event': 1});

  await clientB.postEvent('Foo', 'kind2', {'event': 2});

  // delayed so the Daemon connection is still up by the time the events come
  // back.
  await Future<void>.delayed(const Duration(seconds: 10));

  await clientA.close();
  await clientB.close();
}
