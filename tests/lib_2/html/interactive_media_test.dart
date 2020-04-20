// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_minitest.dart';
import 'package:async_helper/async_helper.dart';

// NOTE: To test enable chrome://flags/#enable-experimental-web-platform-features

main() async {
  if (MediaStream.supported) {
    test('getUserMedia audio', () async {
      try {
        var mediaStream = await window.navigator.getUserMedia(audio: true);
        expect(mediaStream, isNotNull);
        expect(mediaStream is MediaStream, true);
        var devices = window.navigator.mediaDevices;
        var enumDevices = await devices.enumerateDevices();
        expect(enumDevices.length > 1, true);
        for (var device in enumDevices) {
          var goodDevLabel = device.label.endsWith('Built-in Output') ||
              device.label.endsWith('Built-in Microphone');
          expect(goodDevLabel, true);
        }
      } catch (e) {
        // Could fail if bot machine doesn't support audio or video.
        expect(e.name == DomException.NOT_FOUND, true);
      }
    });

    test('getUserMedia', () {
      return window.navigator.getUserMedia(video: true).then((stream) {
        expect(stream, isNotNull);

        var url = Url.createObjectUrlFromStream(stream);
        expect(url, isNotNull);

        var video = new VideoElement()..autoplay = true;

        var completer = new Completer();
        video.onError.listen((e) {
          completer.completeError(e);
        });
        video.onPlaying.first.then((e) {
          completer.complete(video);
        });

        document.body.append(video);
        video.src = url;

        return completer.future;
      }).catchError((e) {
        // Could fail if bot machine doesn't support audio or video.
        expect(e.name == DomException.NOT_FOUND, true);
      });
    });

    test('getUserMediaComplexConstructor', () {
      return window.navigator.getUserMedia(video: {
        'mandatory': {'minAspectRatio': 1.333, 'maxAspectRatio': 1.334},
        'optional': [
          {'minFrameRate': 60},
          {'maxWidth': 640}
        ]
      }).then((stream) {
        expect(stream, isNotNull);

        var url = Url.createObjectUrlFromStream(stream);
        expect(url, isNotNull);

        var video = new VideoElement()..autoplay = true;

        var completer = new Completer();
        video.onError.listen((e) {
          completer.completeError(e);
        });
        video.onPlaying.first.then((e) {
          completer.complete(video);
        });

        document.body.append(video);
        video.src = url;

        return completer.future;
      }).catchError((e) {
        // Could fail if bot machine doesn't support audio or video.
        expect(e.name == DomException.NOT_FOUND, true);
      });
    });
  }
}
