// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRCrossOriginTest;

import 'package:async_helper/async_helper.dart';
import 'package:async_helper/async_minitest.dart';
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

var port = crossOriginPort;
var host = '${window.location.protocol}//${window.location.hostname}:$port';

Future testGetCrossDomain() async {
  var gotError = false;
  var url = '$host/root_dart/tests/lib_2/html/xhr_cross_origin_data.txt';
  try {
    var xhr = await HttpRequest.request(url);
    var data = json.decode(xhr.response);
    expect(data.containsKey('feed'), isTrue);
    expect(data['feed'].containsKey('entry'), isTrue);
    expect(data, isMap);
  } catch (e) {
    // Consume errors when not supporting cross origin.
    gotError = true;
  }
  // Expect that we got an error when cross origin is not supported.
  expect(gotError, !HttpRequest.supportsCrossOrigin);
}

Future testRequestCrossOrigin() async {
  var url = '$host/root_dart/tests/lib_2/html/xhr_cross_origin_data.txt';
  var response = await HttpRequest.requestCrossOrigin(url);
  expect(response.contains('feed'), isTrue);
}

Future testRequestCrossOriginErrors() async {
  try {
    var response = await HttpRequest.requestCrossOrigin('does_not_exist');
    fail('404s should fail request.');
  } catch (_) {
    // Expected failure.
  }
}

void testCrossDomain() {
  var url = '$host/root_dart/tests/lib_2/html/xhr_cross_origin_data.txt';
  var xhr = new HttpRequest();
  xhr.open('GET', url, async: true);
  var validate = expectAsync((data) {
    expect(data.containsKey('feed'), isTrue);
    expect(data['feed'].containsKey('entry'), isTrue);
    expect(data, isMap);
  });
  xhr.onReadyStateChange.listen((e) {
    if (xhr.readyState == HttpRequest.DONE) {
      validate(json.decode(xhr.response));
    }
  });
  xhr.send();
}

Future testGetWithCredentialsCrossDomain() async {
  var url = '$host/root_dart/tests/lib_2/html/xhr_cross_origin_data.txt';
  var xhr = await HttpRequest.request(url, withCredentials: true);
  var data = json.decode(xhr.response);
  expect(data.containsKey('feed'), isTrue);
  expect(data['feed'].containsKey('entry'), isTrue);
  expect(data, isMap);
}

main() {
  test('supported', () {
    expect(HttpRequest.supportsCrossOrigin, isTrue);
  });

  asyncTest(() async {
    await testGetCrossDomain();
    await testRequestCrossOrigin();
    await testRequestCrossOriginErrors();
    // Skip the rest if not supported.
    if (!HttpRequest.supportsCrossOrigin) {
      return;
    }
    testCrossDomain();
    await testGetWithCredentialsCrossDomain();
  });
}
