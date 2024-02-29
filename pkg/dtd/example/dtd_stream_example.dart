// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:async';
import 'dart:convert';

import 'package:dtd/dtd.dart';

void main(List<String> args) async {
  final url = args[0]; // pass the url as a param to the example
  final clientA = await DartToolingDaemon.connect(Uri.parse(url));
  final clientB = await DartToolingDaemon.connect(Uri.parse(url));
  final aCompleter = Completer<void>();
  final bCompleter = Completer<void>();

  // Set up handlers for stream events. It is important that you do this before
  // calling [streamListen] to ensure you don't miss any events.
  clientA.onEvent('Foo').listen((event) {
    print(
      jsonEncode(
        {
          'step': 'Event A received',
          'event': event.data,
        },
      ),
    );
    aCompleter.complete();
  });
  clientB.onEvent('Foo').listen((event) {
    print(
      jsonEncode(
        {
          'step': 'Event B received',
          'event': event.data,
        },
      ),
    );
    bCompleter.complete();
  });

  // Subscribe the clients to the Foo stream.
  await clientA.streamListen('Foo');
  await clientB.streamListen('Foo');

  // Post an event to the Foo stream.
  await clientA.postEvent('Foo', 'kind1', {'event': 1});

  // Wait for the clients to receive the events
  await aCompleter.future;
  await bCompleter.future;

  await clientA.close();
  await clientB.close();
}
