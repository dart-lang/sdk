// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.hijack_test;

import 'dart:async';

import 'package:unittest/unittest.dart';
import 'package:shelf/shelf.dart';

import 'test_util.dart';

void main() {
  test('hijacking a non-hijackable request throws a StateError', () {
    expect(() => new Request('GET', LOCALHOST_URI).hijack((_, __) => null),
        throwsStateError);
  });

  test('hijacking a hijackable request throws a HijackException and calls '
      'onHijack', () {
    var request = new Request('GET', LOCALHOST_URI,
        onHijack: expectAsync((callback) {
      var streamController = new StreamController();
      streamController.add([1, 2, 3]);
      streamController.close();

      var sinkController = new StreamController();
      expect(sinkController.stream.first, completion(equals([4, 5, 6])));

      callback(streamController.stream, sinkController);
    }));

    expect(() => request.hijack(expectAsync((stream, sink) {
      expect(stream.first, completion(equals([1, 2, 3])));
      sink.add([4, 5, 6]);
      sink.close();
    })), throwsA(new isInstanceOf<HijackException>()));
  });

  test('hijacking a hijackable request twice throws a StateError', () {
    // Assert that the [onHijack] callback is only called once.
    var request = new Request('GET', LOCALHOST_URI,
        onHijack: expectAsync((_) => null, count: 1));

    expect(() => request.hijack((_, __) => null),
        throwsA(new isInstanceOf<HijackException>()));

    expect(() => request.hijack((_, __) => null), throwsStateError);
  });

  group('calling change', () {
    test('hijacking a non-hijackable request throws a StateError', () {
      var request = new Request('GET', LOCALHOST_URI);
      var newRequest = request.change();
      expect(() => newRequest.hijack((_, __) => null),
          throwsStateError);
    });

    test('hijacking a hijackable request throws a HijackException and calls '
        'onHijack', () {
      var request = new Request('GET', LOCALHOST_URI,
          onHijack: expectAsync((callback) {
        var streamController = new StreamController();
        streamController.add([1, 2, 3]);
        streamController.close();

        var sinkController = new StreamController();
        expect(sinkController.stream.first, completion(equals([4, 5, 6])));

        callback(streamController.stream, sinkController);
      }));

      var newRequest = request.change();

      expect(() => newRequest.hijack(expectAsync((stream, sink) {
        expect(stream.first, completion(equals([1, 2, 3])));
        sink.add([4, 5, 6]);
        sink.close();
      })), throwsA(new isInstanceOf<HijackException>()));
    });

    test('hijacking the original request after calling change throws a '
        'StateError', () {
      // Assert that the [onHijack] callback is only called once.
      var request = new Request('GET', LOCALHOST_URI,
          onHijack: expectAsync((_) => null, count: 1));

      var newRequest = request.change();

      expect(() => newRequest.hijack((_, __) => null),
          throwsA(new isInstanceOf<HijackException>()));

      expect(() => request.hijack((_, __) => null), throwsStateError);
    });
  });
}
