// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library XHRTest;

import 'dart:async';
import 'dart:convert';
import 'dart:html';
import 'dart:typed_data';

import 'package:async_helper/async_minitest.dart';
import 'package:async_helper/async_helper.dart';

// Cache blocker is a workaround for:
// https://code.google.com/p/dart/issues/detail?id=11834
var cacheBlocker = new DateTime.now().millisecondsSinceEpoch;
var url = '/root_dart/tests/lib_2/html/xhr_cross_origin_data.txt?'
    'cacheBlock=$cacheBlocker';

void validate200Response(xhr) {
  expect(xhr.status, 200);
  var data = json.decode(xhr.responseText);
  expect(data.containsKey('feed'), isTrue);
  expect(data['feed'].containsKey('entry'), isTrue);
  expect(data, isMap);
}

void validate404(xhr) {
  expect(xhr.status, 404);
  // We cannot say much about xhr.responseText, most HTTP servers will
  // include an HTML page explaining the error to a human.
  String responseText = xhr.responseText;
  expect(responseText, isNotNull);
}

Future testXhrNoFile() async {
  HttpRequest xhr = new HttpRequest();
  xhr.open("GET", "NonExistingFile", async: true);
  var completer = new Completer<void>();
  xhr.onReadyStateChange.listen((event) {
    if (!completer.isCompleted && xhr.readyState == HttpRequest.DONE) {
      completer.complete();
      validate404(xhr);
    }
  });
  xhr.send();
  await completer;
}

Future testXhrFile() async {
  var loadEndCalled = false;

  var xhr = new HttpRequest();
  xhr.open('GET', url, async: true);
  var completer = new Completer<void>();
  xhr.onReadyStateChange.listen((e) {
    if (!completer.isCompleted && xhr.readyState == HttpRequest.DONE) {
      completer.complete();
      validate200Response(xhr);

      Timer.run(expectAsync(() {
        expect(loadEndCalled, HttpRequest.supportsLoadEndEvent);
      }));
    }
  });

  xhr.onLoadEnd.listen((ProgressEvent e) {
    loadEndCalled = true;
  });
  xhr.send();
  await completer;
}

Future testRequestNoFile() async {
  try {
    await HttpRequest.request('NonExistingFile');
    fail('Request should not have succeeded.');
  } catch (error) {
    HttpRequest xhr = error.target;
    expect(xhr.readyState, HttpRequest.DONE);
    validate404(xhr);
  }
}

Future testRequestFile() async {
  var xhr = await HttpRequest.request(url);
  expect(xhr.readyState, HttpRequest.DONE);
  validate200Response(xhr);
}

Future testRequestOnProgress() async {
  var progressCalled = false;
  var xhr = await HttpRequest.request(url, onProgress: (_) {
    progressCalled = true;
  });
  expect(xhr.readyState, HttpRequest.DONE);
  expect(progressCalled, HttpRequest.supportsProgressEvent);
  validate200Response(xhr);
}

Future testRequestWithCredentialsNoFile() async {
  try {
    await HttpRequest.request('NonExistingFile', withCredentials: true);
    fail('Request should not have succeeded.');
  } catch (error) {
    HttpRequest xhr = error.target;
    expect(xhr.readyState, HttpRequest.DONE);
    validate404(xhr);
  }
}

Future testRequestWithCredentialsFile() async {
  try {
    HttpRequest xhr = await HttpRequest.request(url, withCredentials: true);
    expect(xhr.readyState, HttpRequest.DONE);
    validate200Response(xhr);
  } catch (_) {
    fail('Request should succeed.');
  }
}

Future testGetStringFile() => HttpRequest.getString(url);

Future testGetStringNoFile() async {
  try {
    await HttpRequest.getString('NonExistingFile');
    fail('Succeeded for non-existing file.');
  } catch (error) {
    HttpRequest xhr = error.target;
    expect(xhr.readyState, HttpRequest.DONE);
    validate404(xhr);
  }
}

Future testRequestResponseTypeArrayBuffer() async {
  if (Platform.supportsTypedData) {
    var xhr = await HttpRequest.request(url,
        responseType: 'arraybuffer',
        requestHeaders: {'Content-Type': 'text/xml'});
    expect(xhr.status, 200);
    var byteBuffer = xhr.response;
    expect(byteBuffer, isInstanceOf<ByteBuffer>());
    expect(byteBuffer, isNotNull);
  }
}

Future testOverrideMimeType() async {
  bool gotError = false;
  try {
    await HttpRequest.request(url, mimeType: 'application/binary');
  } catch (_) {
    gotError = true;
  }
  expect(gotError, !HttpRequest.supportsOverrideMimeType);
}

Future testXhrUpload() async {
  if (Platform.supportsTypedData) {
    var xhr = new HttpRequest();
    var progressCalled = false;
    xhr.upload.onProgress.listen((e) {
      progressCalled = true;
    });

    xhr.open(
        'POST', '${window.location.protocol}//${window.location.host}/echo');

    // 10MB of payload data w/ a bit of data to make sure it
    // doesn't get compressed to nil.
    var data = new Uint8List(1 * 1024 * 1024);
    for (var i = 0; i < data.length; ++i) {
      data[i] = i & 0xFF;
    }
    xhr.send(new Uint8List.view(data.buffer));

    await xhr.onLoad.first;
    expect(progressCalled, isTrue, reason: 'onProgress should be fired');
  }
}

Future testXhrPostFormData() async {
  var data = {'name': 'John', 'time': '2 pm'};

  var parts = [];
  for (var key in data.keys) {
    parts.add('${Uri.encodeQueryComponent(key)}='
        '${Uri.encodeQueryComponent(data[key])}');
  }
  var encodedData = parts.join('&');

  var xhr = await HttpRequest.postFormData(
      '${window.location.protocol}//${window.location.host}/echo', data);
  expect(xhr.responseText, encodedData);
}

Future testRequestResponseTypeBlob() async {
  if (Platform.supportsTypedData) {
    var xhr = await HttpRequest.request(url, responseType: 'blob');
    expect(xhr.status, 200);
    var blob = xhr.response;
    expect(blob is Blob, isTrue);
    expect(blob, isNotNull);
  }
}

Future testResponseTypeJson() async {
  var url = '${window.location.protocol}//${window.location.host}/echo';
  var data = {
    'key': 'value',
    'a': 'b',
    'one': 2,
  };

  var xhr = await HttpRequest.request(url,
      method: 'POST', sendData: json.encode(data), responseType: 'json');
  expect(xhr.status, 200);
  var jsonResponse = xhr.response;
  expect(jsonResponse, data);
}

Future testResponseHeaders() async {
  var xhr = await HttpRequest.request(url);
  var contentTypeHeader = xhr.responseHeaders['content-type'];
  expect(contentTypeHeader, isNotNull);
  // Should be like: 'text/plain; charset=utf-8'
  expect(contentTypeHeader.contains('text/plain'), isTrue);
  expect(contentTypeHeader.contains('charset=utf-8'), isTrue);
}

main() {
  test('supportsProgressEvent', () {
    expect(HttpRequest.supportsProgressEvent, isTrue);
  });

  test('supportsOnLoadEnd', () {
    expect(HttpRequest.supportsLoadEndEvent, isTrue);
  });

  test('supportsOverrideMimeType', () {
    expect(HttpRequest.supportsOverrideMimeType, isTrue);
  });

  asyncTest(() async {
    await testXhrNoFile();
    await testXhrFile();
    await testRequestNoFile();
    await testRequestFile();
    await testRequestOnProgress();
    await testRequestWithCredentialsNoFile();
    await testRequestWithCredentialsFile();
    await testGetStringFile();
    await testGetStringNoFile();
    await testRequestResponseTypeArrayBuffer();
    await testOverrideMimeType();
    await testXhrUpload();
    await testXhrPostFormData();

    await testRequestResponseTypeBlob();

    await testResponseTypeJson();

    await testResponseHeaders();
  });
}
