// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// VMOptions=--pause-isolates-on-exit --enable-vm-service=0 --disable-service-auth-codes

// See b/271314180.

import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'dart:isolate';

const childCount = 4;

void child(i) {
  print('Child $i');
  // Paused-at-exit.
}

void main() {
  for (int i = 0; i < childCount; i++) {
    Isolate.spawn(child, i);
  }
  Isolate.spawn(resumer, null);
  print('Parent');
  // Paused-at-exit.
}

Future<Map<String, dynamic>> get(
  String method,
  Map<String, dynamic> arguments,
) async {
  final info = await Service.getInfo();
  final uri = info.serverUri!.replace(path: method, queryParameters: arguments);
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    final response = await request.close();
    final string = await response.transform(utf8.decoder).join();
    return jsonDecode(string);
  } finally {
    client.close();
  }
}

Future<Never> resumer(_) async {
  try {
    // Wait for the main isolate and children to all be paused at exit.
    final paused = <String>[];
    do {
      paused.clear();
      final vm = (await get('getVM', {}))['result'];
      for (Map<String, dynamic> isolate in vm['isolates']) {
        final id = isolate['id'];
        isolate = (await get('getIsolate', {'isolateId': id}))['result'];
        if ((isolate['pauseEvent'] != null) &&
            (isolate['pauseEvent']['kind'] == 'PauseExit')) {
          paused.add(id);
        }
      }
    } while (paused.length != childCount + 1);

    // Resume the main isolate and children. When the main isolate resumes, it
    // will exit and trigger VM shutdown. The VM shutdown will send the OOB kill
    // message to children and so race with the resume message. No matter how
    // the race resolves, the children should exit and the VM shutdown should
    // not hang with
    //    Attempt:138 waiting for isolate child to check in
    //    ...
    for (final id in paused) {
      await get('resume', {'isolateId': id}).then((v) => print(v));
    }
  } catch (e, st) {
    print(e);
    print(st);
    rethrow;
  }

  // This isolate itself will be paused-at-exit with no resume message coming,
  // but should exit because of the VM shutdown.
  throw StateError('Unreachable');
}
