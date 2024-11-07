// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analysis_server/src/lsp/lsp_packet_transformer.dart';
import 'package:test/test.dart';

void main() {
  group('lsp_packet_transformer', () {
    test('transforms data received as individual bytes', () async {
      var payload = '{ json payload }';
      var lspPacket = makeLspPacket(payload);
      var output =
          await Stream.fromIterable([
            lspPacket,
          ]).transform(LspPacketTransformer()).toList();
      expect(output, equals([payload]));
    });

    test('transforms data received in chunks', () async {
      var payload = '{ json\n payload\n  }';
      var lspPacket = makeLspPacket(payload);
      // Separate each byte into it's own "packet" to simulate chunked data
      // where all the bytes for a single LSP packet don't arrive in one
      // item to the stream.
      var dataPackets = lspPacket.map((b) => [b]);
      var output =
          await Stream.fromIterable(
            dataPackets,
          ).transform(LspPacketTransformer()).toList();
      expect(output, equals([payload]));
    });

    test('handles unicode characters', () async {
      // This file is saved as UTF8.
      var payload = '{ json payload 🎉 }';
      var lspPacket = makeLspPacket(payload);
      var output =
          await Stream.fromIterable([
            lspPacket,
          ]).transform(LspPacketTransformer()).toList();
      expect(output, equals([payload]));
    });

    test('accepts "utf-8" as an encoding', () async {
      var payload = '{ json payload 🎉 }';
      var lspPacket = makeLspPacket(
        payload,
        'application/vscode-jsonrpc; charset=utf-8',
      );
      var output =
          await Stream.fromIterable([
            lspPacket,
          ]).transform(LspPacketTransformer()).toList();
      expect(output, equals([payload]));
    });

    test('accepts "utf8" as an encoding', () async {
      var payload = '{ json payload 🎉 }';
      var lspPacket = makeLspPacket(
        payload,
        'application/vscode-jsonrpc; charset=utf8',
      );
      var output =
          await Stream.fromIterable([
            lspPacket,
          ]).transform(LspPacketTransformer()).toList();
      expect(output, equals([payload]));
    });

    test('accepts no encoding', () async {
      var payload = '{ json payload 🎉 }';
      var lspPacket = makeLspPacket(payload, 'application/vscode-jsonrpc;');
      var output =
          await Stream.fromIterable([
            lspPacket,
          ]).transform(LspPacketTransformer()).toList();
      expect(output, equals([payload]));
    });

    test('rejects invalid encoding', () async {
      var payload = '{ json payload }';
      var lspPacket = makeLspPacket(
        payload,
        'application/vscode-jsonrpc; charset=ascii',
      );
      var outputStream = Stream.fromIterable([
        lspPacket,
      ]).transform(LspPacketTransformer());

      await expectLater(
        outputStream.toList(),
        throwsA(const TypeMatcher<InvalidEncodingError>()),
      );
    });
  });
}

List<int> makeLspPacket(String json, [String? contentType]) {
  var utf8EncodedBody = utf8.encode(json);
  var header =
      'Content-Length: ${utf8EncodedBody.length}${contentType != null ? '\r\nContent-Type: $contentType' : ''}\r\n\r\n';
  var asciiEncodedHeader = ascii.encode(header);

  return asciiEncodedHeader.followedBy(utf8EncodedBody).toList();
}
