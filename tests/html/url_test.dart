// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('url_test');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');

main() {
  useHtmlConfiguration();

  Blob createImageBlob() {
    var canvas = new CanvasElement();
    canvas.width = 100;
    canvas.height = 100;

    var context = canvas.context2d;
    context.fillStyle = 'red';
    context.fillRect(0, 0, canvas.width, canvas.height);

    var dataUri = canvas.toDataURL('image/png');
    var byteString = window.atob(dataUri.split(',')[1]);
    var mimeString = dataUri.split(',')[0].split(':')[1].split(';')[0];

    var arrayBuffer = new ArrayBuffer(byteString.length);
    var dataArray = new Uint8Array.fromBuffer(arrayBuffer);
    for (var i = 0; i < byteString.length; i++) {
      dataArray[i] = byteString.charCodeAt(i);
    }

    var blob = new Blob([arrayBuffer], 'image/png');
    return blob;
  }

  group('blob', () {
    test('createObjectUrl', () {
      var blob = createImageBlob();
      var url = window.createObjectUrl(blob);
      expect(url.length, greaterThan(0));
      expect(url, startsWith('blob:'));

      var img = new ImageElement();
      img.on.load.add(expectAsync1((_) {
        expect(img.complete, true);
      }));
      img.on.error.add((_) {
        guardAsync(() {
          expect(true, isFalse, reason: 'URL failed to load.');
        });
      });
      img.src = url;
    });

    test('revokeObjectUrl', () {
      var blob = createImageBlob();
      var url = window.createObjectUrl(blob);
      expect(url, startsWith('blob:'));
      window.revokeObjectUrl(url);

      var img = new ImageElement();
      // Image should fail to load since the URL was revoked.
      img.on.error.add(expectAsync1((_) {
      }));
      img.on.load.add((_) {
        guardAsync(() {
          expect(true, isFalse, reason: 'URL should not have loaded.');
        });
      });
      img.src = url;
    });

  });
}
