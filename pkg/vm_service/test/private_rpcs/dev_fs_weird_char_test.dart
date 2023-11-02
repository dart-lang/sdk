// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/test_helper.dart';
import 'private_rpc_common.dart';

final tests = <VMTest>[
  // Write a file with the ? character in the filename.
  (VmService service) async {
    const fsId = 'test';
    const filePath = '/foo/bar?dat';
    final fileContents = base64Encode(utf8.encode('fileContents'));

    // Create DevFS.
    Map<String, dynamic> result = await callMethod(
      service,
      '_createDevFS',
      args: {'fsName': fsId},
    );
    if (result case {'type': 'FileSystem', 'name': fsId, 'uri': String _}) {
      // Expected
    } else {
      invalidResponse(result);
    }

    // Write the file.
    result = await callMethod(service, '_writeDevFSFile', args: {
      'fsName': fsId,
      'path': filePath,
      'fileContents': fileContents,
    });
    expectSuccess(result);

    // Read the file back.
    result = await callMethod(service, '_readDevFSFile', args: {
      'fsName': fsId,
      'path': filePath,
    });
    if (result case {'type': 'FSFile', 'fileContents': String contents}) {
      expect(contents, fileContents);
    } else {
      invalidResponse(result);
    }

    // List all the files in the file system.
    result = await callMethod(service, '_listDevFSFiles', args: {
      'fsName': fsId,
    });
    if (result
        case {
          'type': 'FSFileList',
          'files': [{'name': '/foo/bar?dat'}],
        }) {
      // Expected
    } else {
      invalidResponse(result);
    }

    // Delete DevFS.
    result = await callMethod(service, '_deleteDevFS', args: {
      'fsName': fsId,
    });
    expectSuccess(result);
  },
];

void main(List<String> args) => runVMTests(
      args,
      tests,
      'dev_fs_weird_char_test.dart',
    );
