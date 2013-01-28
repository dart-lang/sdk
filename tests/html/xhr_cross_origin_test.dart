// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRCrossOriginTest;
import '../../pkg/unittest/lib/unittest.dart';
import '../../pkg/unittest/lib/html_config.dart';
import 'dart:html';
import 'dart:json' as json;

/**
 * Examine the value of "crossOriginPort" as passed in from the url from
 * [window.location] to determine what the cross-origin port is for
 * this test.
 */
 // TODO(efortuna): If we need to use this function frequently, make a
 // url_analyzer library that is part of test.dart that these tests can import.
int get crossOriginPort {
  var searchUrl = window.location.search;
  var crossOriginStr = 'crossOriginPort=';
  var index = searchUrl.indexOf(crossOriginStr);
  var nextArg = searchUrl.indexOf('&', index);
  return int.parse(searchUrl.substring(index + crossOriginStr.length,
      nextArg == -1 ? searchUrl.length : nextArg));
}

main() {
  useHtmlConfiguration();

  var port = crossOriginPort;

  test('XHR Cross-domain', () {
    var url = "http://localhost:$port/tests/html/xhr_cross_origin_data.txt";
    var xhr = new HttpRequest();
    xhr.open('GET', url, true);
    var validate = expectAsync1((data) {
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data, isMap);
    });
    xhr.onReadyStateChange.listen((e) {
      guardAsync(() {
        if (xhr.readyState == HttpRequest.DONE) {
          validate(json.parse(xhr.response));
        }
      });
    });
    xhr.send();
  });

  test('XHR.get Cross-domain', () {
    var url = "http://localhost:$port/tests/html/xhr_cross_origin_data.txt";
    new HttpRequest.get(url, expectAsync1((xhr) {
      var data = json.parse(xhr.response);
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data, isMap);
    }));
  });

  test('XHR.getWithCredentials Cross-domain', () {
    var url = "http://localhost:$port/tests/html/xhr_cross_origin_data.txt";
    new HttpRequest.getWithCredentials(url, expectAsync1((xhr) {
      var data = json.parse(xhr.response);
      expect(data, contains('feed'));
      expect(data['feed'], contains('entry'));
      expect(data, isMap);
    }));
  });
}
