// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XHRCrossOriginTest');
#import('../../lib/unittest/unittest.dart');
#import('../../lib/unittest/html_config.dart');
#import('dart:html');
#import('dart:json');

main() {
  useHtmlConfiguration();

  test('XHR Cross-domain', () {
    var xhr = new XMLHttpRequest();
    var url = "https://code.google.com/feeds/issues/p/dart/issues/full?alt=json";
    xhr.open('GET', url, true);
    var validate = expectAsync1((data) {
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data is Map, isTrue);
    });
    xhr.on.readyStateChange.add((e) {
      guardAsync(() {
        if (xhr.readyState == XMLHttpRequest.DONE) {
          validate(JSON.parse(xhr.response));
        }
      });
    });
    xhr.send();
  });

  test('XHR.get Cross-domain', () {
    var url = "https://code.google.com/feeds/issues/p/dart/issues/full?alt=json";
    new XMLHttpRequest.get(url, expectAsync1((xhr) {
      var data = JSON.parse(xhr.response);
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data is Map, isTrue);
    }));
  });
}
