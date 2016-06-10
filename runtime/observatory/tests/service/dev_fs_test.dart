// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--error_on_bad_type --error_on_bad_override

import 'dart:async';
import 'dart:convert';
import 'package:observatory/service_io.dart';
import 'package:unittest/unittest.dart';
import 'test_helper.dart';

var tests = [
  (VM vm) async {
    var result = await vm.invokeRpcNoUpgrade('_listDevFS', {});
    expect(result['type'], equals('FSList'));
    expect(result['fsNames'].toString(), equals("[]"));

    var params = {
      'fsName': 'alpha'
    };
    result = await vm.invokeRpcNoUpgrade('_createDevFS', params);
    expect(result['type'], equals('Success'));

    result = await vm.invokeRpcNoUpgrade('_listDevFS', {});
    expect(result['type'], equals('FSList'));
    expect(result['fsNames'].toString(), equals('[alpha]'));

    bool caughtException;
    try {
      await vm.invokeRpcNoUpgrade('_createDevFS', params);
      expect(false, isTrue, reason:'Unreachable');
    } on ServerRpcException catch(e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kFileSystemAlreadyExists));
      expect(e.message, "_createDevFS: file system 'alpha' already exists");
    }
    expect(caughtException, isTrue);

    result = await vm.invokeRpcNoUpgrade('_deleteDevFS', params);
    expect(result['type'], equals('Success'));

    result = await vm.invokeRpcNoUpgrade('_listDevFS', {});
    expect(result['type'], equals('FSList'));
    expect(result['fsNames'].toString(), equals("[]"));

    caughtException = false;
    try {
      await vm.invokeRpcNoUpgrade('_deleteDevFS', params);
      expect(false, isTrue, reason:'Unreachable');
    } on ServerRpcException catch(e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kFileSystemDoesNotExist));
      expect(e.message, "_deleteDevFS: file system 'alpha' does not exist");
    }
    expect(caughtException, isTrue);
  },

  (VM vm) async {
    var fsId = 'banana';
    var filePath = '/foobar.dat';
    var fileContents = BASE64.encode(UTF8.encode('fileContents'));

    var result;
    // Create DevFS.
    result = await vm.invokeRpcNoUpgrade('_createDevFS', {
        'fsName': fsId
            });
    expect(result['type'], equals('Success'));

    bool caughtException = false;
    try {
      await vm.invokeRpcNoUpgrade('_readDevFSFile', {
        'fsName': fsId,
        'path': filePath,
      });
      expect(false, isTrue, reason:'Unreachable');
    } on ServerRpcException catch(e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kFileDoesNotExist));
      expect(e.message,
             "_readDevFSFile: file 'dart-devfs://banana//foobar.dat' "
             "does not exist");
    }
    expect(caughtException, isTrue);

    // Write a file.
    result = await vm.invokeRpcNoUpgrade('_writeDevFSFile', {
        'fsName': fsId,
        'path': filePath,
        'fileContents': fileContents
    });
    expect(result['type'], equals('Success'));

    // Read the file back.
    result = await vm.invokeRpcNoUpgrade('_readDevFSFile', {
        'fsName': fsId,
        'path': filePath,
    });
    expect(result['type'], equals('FSFile'));
    expect(result['fileContents'], equals(fileContents));

    // Read a malformed path back.
    caughtException = false;
    try {
      result = await vm.invokeRpcNoUpgrade('_readDevFSFile', {
          'fsName': fsId,
          'path': filePath.substring(1)  // Strip the leading '/'.
      });
    } on ServerRpcException catch(e) {
      caughtException = true;
      expect(e.code, equals(ServerRpcException.kInvalidParams));
      expect(e.message,
             "_readDevFSFile: file system path \'foobar.dat\' "
             "must begin with a /");
    }
    expect(caughtException, isTrue);

    expect(result['type'], equals('FSFile'));
    expect(result['fileContents'], equals(fileContents));

    // Write a set of files.
    result = await vm.invokeRpcNoUpgrade('_writeDevFSFiles', {
        'fsName': fsId,
        'files': [
          ['/a', BASE64.encode(UTF8.encode('a_contents'))],
          ['/b', BASE64.encode(UTF8.encode('b_contents'))]
        ]
    });
    expect(result['type'], equals('Success'));

    // Read one of the files back.
    result = await vm.invokeRpcNoUpgrade('_readDevFSFile', {
        'fsName': fsId,
        'path': '/b',
    });
    expect(result['type'], equals('FSFile'));
    expect(result['fileContents'],
           equals(BASE64.encode(UTF8.encode('b_contents'))));

    // List all the files in the file system.
    result = await vm.invokeRpcNoUpgrade('_listDevFSFiles', {
        'fsName': fsId,
    });
    expect(result['type'], equals('FSFilesList'));
    expect(result['files'].length, equals(3));

    // Delete DevFS.
    result = await vm.invokeRpcNoUpgrade('_deleteDevFS', {
        'fsName': fsId,
    });
    expect(result['type'], equals('Success'));
  },
];

main(args) async => runVMTests(args, tests);
