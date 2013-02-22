 // Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library interactive_test;

import 'dart:async';
import 'dart:html';
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_individual_config.dart';
import 'utils.dart';


main() {
  useHtmlIndividualConfiguration();

  group('Geolocation', () {
    futureTest('getCurrentPosition', () {
      return window.navigator.geolocation.getCurrentPosition().then(
        (position) {
          expect(position.coords.latitude, isNotNull);
          expect(position.coords.longitude, isNotNull);
          expect(position.coords.accuracy, isNotNull);
        });
    });

    futureTest('watchPosition', () {
      return window.navigator.geolocation.watchPosition().first.then(
        (position) {
          expect(position.coords.latitude, isNotNull);
          expect(position.coords.longitude, isNotNull);
          expect(position.coords.accuracy, isNotNull);
        });
    });
  });

  group('MediaStream', () {
    if (MediaStream.supported) {
      futureTest('getUserMedia', () {
        return window.navigator.getUserMedia(video: true).then((stream) {
          expect(stream,  isNotNull);

          var url = Url.createObjectUrl(stream);
          expect(url,  isNotNull);

          var video = new VideoElement()
            ..autoplay = true;

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
  });
}
