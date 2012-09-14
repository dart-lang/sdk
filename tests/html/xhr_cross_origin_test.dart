// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XHRCrossOriginTest');
#import('../../pkg/unittest/lib/unittest.dart');
#import('../../pkg/unittest/lib/html_config.dart');
#import('dart:html');
#import('dart:json');

main() {
  useHtmlConfiguration();

  test('XHR Cross-domain', () {
    var xhr = new HttpRequest();
    var url = "https://code.google.com/feeds/issues/p/dart/issues/full?alt=json";
    xhr.open('GET', url, true);
    var validate = expectAsync1((data) {
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data is Map, isTrue);
    });
    xhr.on.readyStateChange.add((e) {
      guardAsync(() {
        if (xhr.readyState == HttpRequest.DONE) {
          validate(JSON.parse(xhr.response));
        }
      });
    });
    xhr.send();
  });

  test('XHR.get Cross-domain', () {
    var url = "https://code.google.com/feeds/issues/p/dart/issues/full?alt=json";
    new HttpRequest.get(url, expectAsync1((xhr) {
      var data = JSON.parse(xhr.response);
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data is Map, isTrue);
    }));
  });
}
