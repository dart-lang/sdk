// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';

import 'package:async_helper/async_minitest.dart';
import 'package:async_helper/async_helper.dart';

// NOTE: To test enable chrome://flags/#enable-experimental-web-platform-features

testUserMediaAudio(Future userMediaFuture) async {
  try {
    var mediaStream = await userMediaFuture;
    expect(mediaStream, isNotNull);
    expect(mediaStream is MediaStream, true);
    var devices = window.navigator.mediaDevices!;
    var enumDevices = await devices.enumerateDevices();
    expect(enumDevices.length > 1, true);
    for (var device in enumDevices) {
      var goodDevLabel = device.label.endsWith('Built-in Output') ||
          device.label.endsWith('Built-in Microphone');
      expect(goodDevLabel, true);
    }
  } on DomException catch (e) {
    // Could fail if bot machine doesn't support audio or video.
    expect(e.name == DomException.NOT_FOUND, true);
  }
}

testUserMediaVideo(Future userMediaFuture) async {
  try {
    var mediaStream = await userMediaFuture;
    expect(mediaStream, isNotNull);

    var url = Url.createObjectUrlFromStream(mediaStream);
    expect(url, isNotNull);

    var video = new VideoElement()..autoplay = true;

    var completer = new Completer();
    video.onError.listen((e) {
      completer.completeError(e);
    });
    video.onPlaying.first.then((e) {
      completer.complete(video);
    });

    document.body!.append(video);
    video.src = url;

    await completer.future;
  } on DomException catch (e) {
    // Could fail if bot machine doesn't support audio or video.
    expect(e.name == DomException.NOT_FOUND, true);
  }
}

main() {
  if (MediaStream.supported) {
    test('getUserMedia audio', () async {
      await testUserMediaAudio(window.navigator
          .getUserMedia(audio: true)); // Deprecated way to get a media stream.
      await testUserMediaAudio(
          window.navigator.mediaDevices!.getUserMedia({'audio': true}));
    });

    test('getUserMedia', () async {
      await testUserMediaVideo(window.navigator
          .getUserMedia(video: true)); // Deprecated way to get a media stream.
      await testUserMediaVideo(
          window.navigator.mediaDevices!.getUserMedia({'video': true}));
    });

    test('getUserMediaComplexConstructor', () async {
      var videoOptions = {
        'mandatory': {'minAspectRatio': 1.333, 'maxAspectRatio': 1.334},
        'optional': [
          {'minFrameRate': 60},
          {'maxWidth': 640}
        ]
      };
      await testUserMediaVideo(window.navigator.getUserMedia(
          video: videoOptions)); // Deprecated way to get a media stream.
      await testUserMediaVideo(
          window.navigator.mediaDevices!.getUserMedia({'video': videoOptions}));
    });
  }
}
