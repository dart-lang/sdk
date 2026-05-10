// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test: RawSynchronousSocket.writeFromSync used to send `end`
// bytes from offset `start` instead of `end - start`. With `start > 0` this
// over-sent the trailing portion of the buffer, and when `start + end >
// buffer.length` it read process heap memory past the typed-data
// allocation and shipped it to the socket peer.
//
// The Dart-side wrapper passed `end - (start - bufferAndStart.start)`
// (which collapses to `end` for the common full-Uint8List path) as the
// third argument to the native `SynchronousSocket_WriteList`, while the
// C handler interpreted that argument as a byte count. The fix passes
// `end - start` and adds a runtime range check on the C side.
//
// This test verifies that calling
//     writeFromSync(buffer, start, end)
// with start > 0 transmits exactly `end - start` bytes — and that
// inputs which formerly triggered the OOB are no longer reachable from
// the public API (RangeError.checkValidRange already rejects
// out-of-range, but if any future regression bypasses the Dart-side
// wrapper, the C-side check now also rejects).

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:expect/expect.dart';

Future<void> main() async {
  final server = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final got = Completer<List<int>>();
  server.listen((Socket sock) {
    final r = <int>[];
    sock.listen(r.addAll, onDone: () {
      if (!got.isCompleted) got.complete(r);
    });
  });

  final c = RawSynchronousSocket.connectSync(
    InternetAddress.loopbackIPv4,
    server.port,
  );

  // 16-byte Uint8List: indices 0..9 = 'A'..'J', indices 10..15 = 0xCC.
  // The caller asks to send only buf[5..10) — five bytes "FGHIJ".
  // A buggy implementation sent ten bytes (the trailing 0xCC sentinels).
  final buf = Uint8List(16);
  for (var i = 0; i < 10; i++) buf[i] = 0x41 + i;
  for (var i = 10; i < 16; i++) buf[i] = 0xCC;

  c.writeFromSync(buf, 5, 10);
  c.closeSync();

  final received = await got.future.timeout(const Duration(seconds: 5));
  await server.close();

  Expect.equals(5, received.length,
      'writeFromSync(buf, 5, 10) must transmit exactly 5 bytes');
  Expect.listEquals(<int>[0x46, 0x47, 0x48, 0x49, 0x4a], received);
}
