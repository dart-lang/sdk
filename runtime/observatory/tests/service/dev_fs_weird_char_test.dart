// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:convert';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [
  // Write a file with the ? character in the filename.
  (VM vm) async {
    var fsId = 'test';
    var filePath = '/foo/bar?dat';
    var fileContents = base64.encode(utf8.encode('fileContents'));

    var result;
    // Create DevFS.
    result = await vm.invokeRpcNoUpgrade('_createDevFS', {'fsName': fsId});
    expect(result['type'], equals('FileSystem'));
    expect(result['name'], equals(fsId));
    expect(result['uri'], new isInstanceOf<String>());

    // Write the file.
    result = await vm.invokeRpcNoUpgrade('_writeDevFSFile',
        {'fsName': fsId, 'path': filePath, 'fileContents': fileContents});
    expect(result['type'], equals('Success'));

    // Read the file back.
    result = await vm.invokeRpcNoUpgrade('_readDevFSFile', {
      'fsName': fsId,
      'path': filePath,
    });
    expect(result['type'], equals('FSFile'));
    expect(result['fileContents'], equals(fileContents));

    // List all the files in the file system.
    result = await vm.invokeRpcNoUpgrade('_listDevFSFiles', {
      'fsName': fsId,
    });
    expect(result['type'], equals('FSFileList'));
    expect(result['files'].length, equals(1));
    expect(result['files'][0]['name'], equals('/foo/bar?dat'));

    // Delete DevFS.
    result = await vm.invokeRpcNoUpgrade('_deleteDevFS', {
      'fsName': fsId,
    });
    expect(result['type'], equals('Success'));
  },
];

main(args) async => runVMTests(args, tests);
