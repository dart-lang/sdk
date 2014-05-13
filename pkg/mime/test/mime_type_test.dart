// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:math' as math;

import 'package:unittest/unittest.dart';
import 'package:mime/mime.dart';
import 'package:mime/src/magic_number.dart';

void _expectMimeType(String path,
                    String expectedMimeType,
                    {List<int> headerBytes,
                     MimeTypeResolver resolver}) {
  String mimeType;
  if (resolver == null) {
    mimeType = lookupMimeType(path, headerBytes: headerBytes);
  } else {
    mimeType = resolver.lookup(path, headerBytes: headerBytes);
  }

  expect(mimeType, expectedMimeType);
}

void main() {
  group('global-lookup', () {
    test('by-path', () {
      _expectMimeType('file.dart', 'application/dart');
      // Test mixed-case
      _expectMimeType('file.DaRT', 'application/dart');
      _expectMimeType('file.html', 'text/html');
      _expectMimeType('file.xhtml', 'application/xhtml+xml');
      _expectMimeType('file.jpeg', 'image/jpeg');
      _expectMimeType('file.jpg', 'image/jpeg');
      _expectMimeType('file.png', 'image/png');
      _expectMimeType('file.gif', 'image/gif');
      _expectMimeType('file.cc', 'text/x-c');
      _expectMimeType('file.c', 'text/x-c');
      _expectMimeType('file.css', 'text/css');
      _expectMimeType('file.js', 'application/javascript');
      _expectMimeType('file.ps', 'application/postscript');
      _expectMimeType('file.pdf', 'application/pdf');
      _expectMimeType('file.tiff', 'image/tiff');
      _expectMimeType('file.tif', 'image/tiff');
    });

    test('unknown-mime-type', () {
      _expectMimeType('file.unsupported-extension', null);
    });

    test('by-header-bytes', () {
      _expectMimeType('file.jpg',
                     'image/png',
                     headerBytes: [0x89, 0x50, 0x4E, 0x47,
                                   0x0D, 0x0A, 0x1A, 0x0A]);
      _expectMimeType('file.jpg',
                     'image/gif',
                     headerBytes: [0x47, 0x49, 0x46, 0x38, 0x39,
                                   0x61, 0x0D, 0x0A, 0x1A, 0x0A]);
      _expectMimeType('file.gif',
                     'image/jpeg',
                     headerBytes: [0xFF, 0xD8, 0x46, 0x38, 0x39,
                                   0x61, 0x0D, 0x0A, 0x1A, 0x0A]);
      _expectMimeType('file.mp4',
                     'video/mp4',
                     headerBytes: [0x00, 0x00, 0x00, 0x04, 0x66, 0x74,
                                   0x79, 0x70, 0x33, 0x67, 0x70, 0x35]);
    });
  });

  group('custom-resolver', () {
    test('override-extension', () {
      var resolver = new MimeTypeResolver();
      resolver.addExtension('jpg', 'my-mime-type');
      _expectMimeType('file.jpg', 'my-mime-type', resolver: resolver);
    });

    test('fallthrough-extension', () {
      var resolver = new MimeTypeResolver();
      resolver.addExtension('jpg2', 'my-mime-type');
      _expectMimeType('file.jpg', 'image/jpeg', resolver: resolver);
    });

    test('with-mask', () {
      var resolver = new MimeTypeResolver.empty();
      resolver.addMagicNumber([0x01, 0x02, 0x03],
                              'my-mime-type',
                              mask: [0x01, 0xFF, 0xFE]);
      _expectMimeType('file',
                     'my-mime-type',
                     headerBytes: [0x01, 0x02, 0x03],
                     resolver: resolver);
      _expectMimeType('file',
                     null,
                     headerBytes: [0x01, 0x03, 0x03],
                     resolver: resolver);
      _expectMimeType('file',
                     'my-mime-type',
                     headerBytes: [0xFF, 0x02, 0x02],
                     resolver: resolver);
    });
  });

  test('default magic number', () {
    var actualMaxBytes = DEFAULT_MAGIC_NUMBERS.fold(0, (previous, magic) {
      return math.max(previous, magic.numbers.length);
    });

    expect(defaultMagicNumbersMaxLength, actualMaxBytes);
  });
}
