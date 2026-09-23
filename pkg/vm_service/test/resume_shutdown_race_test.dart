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

void child(int i) {
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

Future<Map<String, Object?>> get(
  HttpClient client,
  String method,
  Map<String, String> arguments,
) async {
  final info = await Service.getInfo();
  final uri = info.serverUri!.replace(
    path: method,
    queryParameters: arguments.isEmpty ? null : arguments,
  );
  final request = await client.getUrl(uri);
  final response = await request.close();
  final string = await response.transform(utf8.decoder).join();
  return jsonDecode(string) as Map<String, Object?>;
}

Future<Never> resumer(Object? _) async {
  final client = HttpClient();
  try {
    // Wait for the main isolate and children to all be paused at exit.
    final paused = <String>[];
    do {
      try {
        paused.clear();
        final vmResult = await get(client, 'getVM', const <String, String>{});
        final vm = switch (vmResult['result']) {
          final Map<String, Object?> result => result,
          _ => vmResult,
        };
        if (vm case {'isolates': final List<Object?> isolates}) {
          for (final isolate in isolates) {
            if (isolate case {'id': final String id}) {
              final isolateResult = await get(
                client,
                'getIsolate',
                <String, String>{'isolateId': id},
              );
              final isolateData = switch (isolateResult['result']) {
                final Map<String, Object?> result => result,
                _ => isolateResult,
              };
              if (isolateData case {'pauseEvent': {'kind': 'PauseExit'}}) {
                paused.add(id);
              }
            }
          }
        }
      } catch (e) {
        print('Transient error in resumer: $e');
      }
      await Future<void>.delayed(const Duration(milliseconds: 10));
    } while (paused.length != childCount + 1);

    // Resume the main isolate and children. When the main isolate resumes, it
    // will exit and trigger VM shutdown. The VM shutdown will send the OOB kill
    // message to children and so race with the resume message. No matter how
    // the race resolves, the children should exit and the VM shutdown should
    // not hang with
    //    Attempt:138 waiting for isolate child to check in
    //    ...
    for (final id in paused) {
      try {
        final result = await get(
          client,
          'resume',
          <String, String>{'isolateId': id},
        );
        print(result);
      } catch (e) {
        // The VM or service may have shut down during the race.
        print('Error resuming $id: $e');
      }
    }
  } catch (e, st) {
    print(e);
    print(st);
    rethrow;
  } finally {
    client.close(force: true);
  }

  // This isolate itself will be paused-at-exit with no resume message coming,
  // but should exit because of the VM shutdown.
  throw StateError('Unreachable');
}
