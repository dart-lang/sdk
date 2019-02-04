// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

Future<String> readResponse(HttpClientResponse response) {
  var completer = new Completer<String>();
  var contents = new StringBuffer();
  response.transform(utf8.decoder).listen((String data) {
    contents.write(data);
  }, onDone: () => completer.complete(contents.toString()));
  return completer.future;
}

var tests = <VMTest>[
  // Write a file with the ? character in the filename.
  (VM vm) async {
    var fsId = 'test';
    // NOTE: When using the URI encoding scheme, paths cannot be absolute.
    var filePath = 'foo/bar.dat';
    var fileUri = Uri.parse(filePath);
    var fileUriBase64 = base64Encode(utf8.encode(fileUri.toString()));
    var fileContents = [0, 1, 2, 3, 4, 5, 6, 255];
    var fileContentsBase64 = base64Encode(fileContents);

    var filePath2 = 'baz/boo.dat';
    var fileUri2 = Uri.parse(filePath2);

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
    request.headers.add('dev_fs_uri_b64', fileUriBase64);
    request.add(gzip.encode([9]));
    HttpClientResponse response = await request.close();
    String responseBody = await readResponse(response);
    result = jsonDecode(responseBody);
    print(result);
    expect(result['result']['type'], equals('Success'));

    // Trigger an error by issuing an HTTP PUT.
    request = await client.putUrl(Uri.parse(serviceHttpAddress));
    request.headers.add('dev_fs_name', fsId);
    // omit the 'dev_fs_path' parameter.
    request.write(gzip.encode(fileContents));
    response = await request.close();
    responseBody = await readResponse(response);
    result = jsonDecode(responseBody);
    Map error = result['error']['data'];
    expect(error, isNotNull);
    expect(error['details'].contains("expects the 'path' parameter"), isTrue);

    // Write the file again but this time with the true file contents.
    client = new HttpClient();
    request = await client.putUrl(Uri.parse(serviceHttpAddress));
    request.headers.add('dev_fs_name', fsId);
    request.headers.add('dev_fs_uri_b64', fileUriBase64);
    request.add(gzip.encode(fileContents));
    response = await request.close();
    responseBody = await readResponse(response);
    result = jsonDecode(responseBody);
    expect(result['result']['type'], equals('Success'));

    // Close the HTTP client.
    client.close();

    // Read the file back.
    result = await vm.invokeRpcNoUpgrade('_readDevFSFile', {
      'fsName': fsId,
      'uri': fileUri.toString(),
    });
    expect(result['type'], equals('FSFile'));
    expect(result['fileContents'], equals(fileContentsBase64));

    // Write a second file via URI.
    result = await vm.invokeRpcNoUpgrade('_writeDevFSFile', {
      'fsName': fsId,
      'uri': fileUri2.toString(),
      'fileContents': fileContentsBase64
    });

    // Read the second file back.
    result = await vm.invokeRpcNoUpgrade('_readDevFSFile', {
      'fsName': fsId,
      'uri': fileUri2.toString(),
    });
    expect(result['type'], equals('FSFile'));
    expect(result['fileContents'], equals(fileContentsBase64));

    // Delete DevFS.
    result = await vm.invokeRpcNoUpgrade('_deleteDevFS', {
      'fsName': fsId,
    });
    expect(result['type'], equals('Success'));
  },
];

main(args) async => runVMTests(args, tests);
