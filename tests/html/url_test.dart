// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library url_test;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_config.dart';
import 'dart:html';
import 'dart:typed_data';

main() {
  useHtmlConfiguration();

  Blob createImageBlob() {
    var canvas = new CanvasElement();
    canvas.width = 100;
    canvas.height = 100;

    var context = canvas.context2D;
    context.fillStyle = 'red';
    context.fillRect(0, 0, canvas.width, canvas.height);

    var dataUri = canvas.toDataUrl('image/png');
    var byteString = window.atob(dataUri.split(',')[1]);
    var mimeString = dataUri.split(',')[0].split(':')[1].split(';')[0];

    var arrayBuffer = new Uint8List(byteString.length);
    var dataArray = new Uint8List.view(arrayBuffer.buffer);
    for (var i = 0; i < byteString.length; i++) {
      dataArray[i] = byteString.codeUnitAt(i);
    }

    var blob = new Blob([arrayBuffer], 'image/png');
    return blob;
  }

  group('blob', () {
    test('createObjectUrlFromBlob', () {
      var blob = createImageBlob();
      var url = Url.createObjectUrlFromBlob(blob);
      expect(url.length, greaterThan(0));
      expect(url, startsWith('blob:'));

      var img = new ImageElement();
      img.onLoad.listen(expectAsync((_) {
        expect(img.complete, true);
      }));
      img.onError.listen((_) {
        fail('URL failed to load.');
      });
      img.src = url;
    });

    test('revokeObjectUrl', () {
      var blob = createImageBlob();
      var url = Url.createObjectUrlFromBlob(blob);
      expect(url, startsWith('blob:'));
      Url.revokeObjectUrl(url);

      var img = new ImageElement();
      // Image should fail to load since the URL was revoked.
      img.onError.listen(expectAsync((_) {}));
      img.onLoad.listen((_) {
        fail('URL should not have loaded.');
      });
      img.src = url;
    });
  });
}
