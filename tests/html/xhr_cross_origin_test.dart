// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRCrossOriginTest;

import 'package:unittest/unittest.dart';
import 'package:unittest/html_individual_config.dart';
import 'dart:html';
import "dart:convert";

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
  useHtmlIndividualConfiguration();

  group('supported', () {
    test('supported', () {
      expect(HttpRequest.supportsCrossOrigin, isTrue);
    });
  });

  group('functional', () {
    var port = crossOriginPort;
    var host = '${window.location.protocol}//${window.location.hostname}:$port';

    test('XHR.get Cross-domain', () {
      var gotError = false;
      var url = '$host/root_dart/tests/html/xhr_cross_origin_data.txt';
      return HttpRequest.request(url).then((xhr) {
        var data = JSON.decode(xhr.response);
        expect(data, contains('feed'));
        expect(data['feed'], contains('entry'));
        expect(data, isMap);
      }).catchError((error) {}, test: (error) {
        gotError = true;
        // Consume errors when not supporting cross origin.
        return !HttpRequest.supportsCrossOrigin;
      }).whenComplete(() {
        // Expect that we got an error when cross origin is not supported.
        expect(gotError, !HttpRequest.supportsCrossOrigin);
      });
    });

    test('XHR.requestCrossOrigin', () {
      var url = '$host/root_dart/tests/html/xhr_cross_origin_data.txt';
      return HttpRequest.requestCrossOrigin(url).then((response) {
        expect(response, contains('feed'));
      });
    });

    test('XHR.requestCrossOrigin errors', () {
      var gotError = false;
      return HttpRequest.requestCrossOrigin('does_not_exist').then((response) {
        expect(true, isFalse, reason: '404s should fail request.');
      }).catchError((error) {}, test: (error) {
        gotError = true;
        return true;
      }).whenComplete(() {
        expect(gotError, isTrue);
      });
    });

    // Skip the rest if not supported.
    if (!HttpRequest.supportsCrossOrigin) {
      return;
    }

    test('XHR Cross-domain', () {
      var url = '$host/root_dart/tests/html/xhr_cross_origin_data.txt';
      var xhr = new HttpRequest();
      xhr.open('GET', url, async: true);
      var validate = expectAsync((data) {
        expect(data, contains('feed'));
        expect(data['feed'], contains('entry'));
        expect(data, isMap);
      });
      xhr.onReadyStateChange.listen((e) {
        if (xhr.readyState == HttpRequest.DONE) {
          validate(JSON.decode(xhr.response));
        }
      });
      xhr.send();
    });

    test('XHR.getWithCredentials Cross-domain', () {
      var url = '$host/root_dart/tests/html/xhr_cross_origin_data.txt';
      return HttpRequest.request(url, withCredentials: true).then((xhr) {
        var data = JSON.decode(xhr.response);
        expect(data, contains('feed'));
        expect(data['feed'], contains('entry'));
        expect(data, isMap);
      });
    });
  });
}
