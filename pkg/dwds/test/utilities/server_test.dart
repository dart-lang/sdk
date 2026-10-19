// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('vm')
library;

import 'package:dwds/src/utilities/server.dart';
import 'package:test/test.dart';

void main() {
  group('startHttpServer', () {
    for (final hostname in ['any', 'localhost']) {
      test('binds an OS-assigned port on $hostname', () async {
        final server = await startHttpServer(hostname);
        addTearDown(server.close);
        expect(server.port, isNot(0));
      });

      test('falls back to another port on $hostname when the requested port is '
          'taken', () async {
        final holder = await startHttpServer(hostname);
        addTearDown(holder.close);

        final server = await startHttpServer(hostname, port: holder.port);
        addTearDown(server.close);
        expect(server.port, isNot(0));
        expect(server.port, isNot(holder.port));
      });
    }
  });
}
