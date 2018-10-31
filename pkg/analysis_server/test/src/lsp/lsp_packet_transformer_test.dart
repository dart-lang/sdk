// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/lsp/lsp_packet_transformer.dart';
import 'package:test/test.dart';

main() {
  group('lsp_packet_transformer', () {
    test('transforms data received as individual bytes', () async {
      final payload = '{ json payload }';
      final lspPacket = makeLspPacket(payload);
      final codeUnits = lspPacket.codeUnits;
      final output = await new Stream.fromIterable([codeUnits])
          .transform(new LspPacketTransformer())
          .toList();
      expect(output, equals([payload]));
    });

    test('transforms data received as lines', () async {
      final payload = '{ json payload }';
      final lspPacketLines =
          makeLspPacket(payload).split('\n').map((l) => '$l\n');
      // Convert to a List<List<int>>, each item being a line represented as
      // a list of codeUnits.
      final codeUnits = lspPacketLines.map((l) => l.codeUnits).toList();
      final output = await new Stream.fromIterable(codeUnits)
          .transform(new LspPacketTransformer())
          .toList();
      expect(output, equals([payload]));
    });

    test('decodes data using the correct encoding', () async {
      // TODO(dantup): Re-encode string with different encodings and ensure
      // they decode correctly.
    });
  });
}

String makeLspPacket(String json, [String contentType]) {
  return 'Content-Length: ${json.length}\r\n' +
      (contentType != null ? 'Content-Type: $contentType\r\n' : '') +
      '\r\n$json';
}
