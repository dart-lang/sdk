// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

#library('XHRTest');
#import('../../pkg/unittest/unittest.dart');
#import('../../pkg/unittest/html_config.dart');
#import('dart:html');
#import('dart:json');

main() {
  useHtmlConfiguration();

  test('XHR No file', () {
    HttpRequest xhr = new HttpRequest();
    xhr.open("GET", "NonExistingFile", true);
    xhr.on.readyStateChange.add(expectAsync1((event) {
      if (xhr.readyState == HttpRequest.DONE) {
        expect(xhr.status, equals(0));
        expect(xhr.responseText, equals(''));
      }
    }));
    xhr.send();
  });

  test('XHR.get No file', () {
    new HttpRequest.get("NonExistingFile", expectAsync1((xhr) {
      expect(xhr.readyState, equals(HttpRequest.DONE));
      expect(xhr.status, equals(0));
      expect(xhr.responseText, equals(''));
    }));
  });
}
