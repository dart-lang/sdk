// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future<String> readResponse(HttpClientResponse response) {
  var completer = new Completer();
  var contents = new StringBuffer();
  response.transform(UTF8.decoder).listen((String data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

var tests = [
  // Write a file with the \r character in the filename.
  (VM vm) async {
    var fsId = 'test';
    var filePath = '/foo/b\rar.dart';
    var filePathBase64 = BASE64.encode(UTF8.encode(filePath));
    var fileContents = [0, 1, 2, 3, 4, 5, 6, 255];
    var fileContentsBase64 = BASE64.encode(fileContents);

    var result;
    // Create DevFS.
    result = await vm.invokeRpcNoUpgrade('_createDevFS', {'fsName': fsId});
    expect(result['type'], equals('FileSystem'));
    expect(result['name'], equals(fsId));
    expect(result['uri'], new isInstanceOf<String>());

    // Write the file by issuing an HTTP PUT.
    HttpClient client = new HttpClient();
    HttpClientRequest request =
        await client.putUrl(Uri.parse(serviceHttpAddress));
    request.headers.add('dev_fs_name', fsId);
    request.headers.add('dev_fs_path_b64', filePathBase64);
    request.add(GZIP.encode([9]));
    HttpClientResponse response = await request.close();
    String responseBody = await readResponse(response);
    result = JSON.decode(responseBody);
    expect(result['result']['type'], equals('Success'));

    // Trigger an error by issuing an HTTP PUT.
    request = await client.putUrl(Uri.parse(serviceHttpAddress));
    request.headers.add('dev_fs_name', fsId);
    // omit the 'dev_fs_path' parameter.
    request.write(GZIP.encode(fileContents));
    response = await request.close();
    responseBody = await readResponse(response);
    result = JSON.decode(responseBody);
    Map error = result['error']['data'];
    expect(error, isNotNull);
    expect(error['details'].contains("expects the 'path' parameter"), isTrue);

    // Write the file again but this time with the true file contents.
    client = new HttpClient();
    request = await client.putUrl(Uri.parse(serviceHttpAddress));
    request.headers.add('dev_fs_name', fsId);
    request.headers.add('dev_fs_path_b64', filePathBase64);
    request.add(GZIP.encode(fileContents));
    response = await request.close();
    responseBody = await readResponse(response);
    result = JSON.decode(responseBody);
    expect(result['result']['type'], equals('Success'));

    // Close the HTTP client.
    client.close();

    // Read the file back.
    result = await vm.invokeRpcNoUpgrade('_readDevFSFile', {
      'fsName': fsId,
      'path': filePath,
    });
    expect(result['type'], equals('FSFile'));
    expect(result['fileContents'], equals(fileContentsBase64));

    // List all the files in the file system.
    result = await vm.invokeRpcNoUpgrade('_listDevFSFiles', {
      'fsName': fsId,
    });
    expect(result['type'], equals('FSFileList'));
    expect(result['files'].length, equals(1));
    expect(result['files'][0]['name'], equals(filePath));

    // Delete DevFS.
    result = await vm.invokeRpcNoUpgrade('_deleteDevFS', {
      'fsName': fsId,
    });
    expect(result['type'], equals('Success'));
  },
];

main(args) async => runVMTests(args, tests);
