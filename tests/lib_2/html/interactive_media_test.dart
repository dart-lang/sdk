// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';
import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'utils.dart';

main() {
  useHtmlIndividualConfiguration();

  if (MediaStream.supported) {
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
      });
    });
  }
}
