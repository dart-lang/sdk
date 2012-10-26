// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XHRCrossOriginTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
#import('dart:json');

main() {
  useHtmlConfiguration();

  test('XHR Cross-domain', () {
    var url = "http://localhost:9876/tests/html/xhr_cross_origin_data.txt";
    var xhr = new HttpRequest();
    xhr.open('GET', url, true);
    var validate = expectAsync1((data) {
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data, isMap);
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
    var url = "http://localhost:9876/tests/html/xhr_cross_origin_data.txt";
    new HttpRequest.get(url, expectAsync1((xhr) {
      var data = JSON.parse(xhr.response);
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data, isMap);
    }));
  });
}
