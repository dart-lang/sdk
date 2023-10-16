// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/test_helper.dart';
import 'private_rpc_common.dart';
import 'private_rpc_error_codes.dart';

final tests = <VMTest>[
  (VmService service) async {
    var result = await callMethod(service, '_listDevFS');
    if (result case {'type': 'FileSystemList', 'fsNames': []}) {
      // Expected
    } else {
      invalidResponse(result);
    }

    const fsName = 'alpha';
    const params = {'fsName': fsName};
    result = await callMethod(
      service,
      '_createDevFS',
      args: params,
    );
    if (result case {'type': 'FileSystem', 'name': fsName, 'uri': String _}) {
      // Expected
    } else {
      invalidResponse(result);
    }

    result = await callMethod(service, '_listDevFS');
    if (result case {'type': 'FileSystemList', 'fsNames': [fsName]}) {
      // Expected
    } else {
      invalidResponse(result);
    }

    bool caughtException = false;
    try {
      await callMethod(service, '_createDevFS', args: params);
      fail('Unreachable');
    } on RPCError catch (e) {
      caughtException = true;
      expect(e.code, PrivateRpcErrorCodes.kFileSystemAlreadyExists.code);
      expect(e.details, "_createDevFS: file system 'alpha' already exists");
    }
    expect(caughtException, isTrue);

    result = await callMethod(service, '_deleteDevFS', args: params);
    expectSuccess(result);

    result = await callMethod(service, '_listDevFS');
    if (result case {'type': 'FileSystemList', 'fsNames': []}) {
      // Expected
    } else {
      invalidResponse(result);
    }

    caughtException = false;
    try {
      await callMethod(service, '_deleteDevFS', args: params);
      fail('Unreachable');
    } on RPCError catch (e) {
      expect(e.code, PrivateRpcErrorCodes.kFileSystemDoesNotExist.code);
      expect(e.details, "_deleteDevFS: file system 'alpha' does not exist");
    }
  },
  (VmService service) async {
    const fsId = 'banana';
    const filePath = '/foo/bar.dat';
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

    try {
      await callMethod(service, '_readDevFSFile', args: {
        'fsName': fsId,
        'path': filePath,
      });
      fail('Unreachable');
    } on RPCError catch (e) {
      expect(e.code, PrivateRpcErrorCodes.kFileDoesNotExist.code);
      expect(e.details, startsWith("_readDevFSFile: PathNotFoundException: "));
    }

    // Write a file.
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

    // The leading '/' is optional.
    result = await callMethod(service, '_readDevFSFile', args: {
      'fsName': fsId,
      'path': filePath.substring(1),
    });
    if (result case {'type': 'FSFile', 'fileContents': String contents}) {
      expect(contents, fileContents);
    }

    // Read a file outside of the fs.
    try {
      await callMethod(service, '_readDevFSFile', args: {
        'fsName': fsId,
        'path': '../foo',
      });
      fail('Unreachable');
    } on RPCError catch (e) {
      expect(e.code, RPCErrorKind.kInvalidParams.code);
      expect(e.details, "_readDevFSFile: invalid 'path' parameter: ../foo");
    }

    // Write a set of files.
    result = await callMethod(service, '_writeDevFSFiles', args: {
      'fsName': fsId,
      'files': [
        ['/a', base64Encode(utf8.encode('a_contents'))],
        ['/b', base64Encode(utf8.encode('b_contents'))]
      ]
    });
    expectSuccess(result);

    // Read one of the files back.
    result = await callMethod(service, '_readDevFSFile', args: {
      'fsName': fsId,
      'path': '/b',
    });

    if (result case {'type': 'FSFile', 'fileContents': String contents}) {
      expect(contents, base64Encode(utf8.encode('b_contents')));
    } else {
      invalidResponse(result);
    }

    // List all the files in the file system.
    result = await callMethod(service, '_listDevFSFiles', args: {
      'fsName': fsId,
    });
    if (result case {'type': 'FSFileList', 'files': [_, _, _]}) {
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
      'dev_fs_test.dart',
    );
