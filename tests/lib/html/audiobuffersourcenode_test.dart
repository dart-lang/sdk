// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:web_audio';

import 'package:expect/minitest.dart';

main() {
  group('supported', () {
    test('supported', () {
      expect(AudioContext.supported, isTrue);
    });
  });

  group('functional', () {
    test('createBuffer', () {
      if (AudioContext.supported) {
        var ctx = new AudioContext();
        AudioBufferSourceNode node = ctx.createBufferSource();
        expect(node is AudioBufferSourceNode, isTrue);
        node.start(ctx.currentTime, 0, 2);
        expect(node is AudioBufferSourceNode, isTrue);
      }
    });
  });
}
