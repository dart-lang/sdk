// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import '../common/test_helper.dart';
import 'private_rpc_common.dart';

Future<String> readResponse(HttpClientResponse response) {
  final completer = Completer<String>();
  final contents = StringBuffer();
  response.cast<List<int>>().transform(utf8.decoder).listen(
    (String data) {
      contents.write(data);
    },
    onDone: () => completer.complete(contents.toString()),
  );
  return completer.future;
}

final tests = <VMTest>[
  // Write a file with the \r character in the filename.
  (VmService service) async {
    const fsId = 'test';
    const filePath = '/foo/b\rar.dart';
    const fileContents = [0, 1, 2, 3, 4, 5, 6, 255];
    final filePathBase64 = base64Encode(utf8.encode(filePath));
    final fileContentsBase64 = base64Encode(fileContents);

    Future<Map<String, dynamic>> postToDevFS({
      required List<int> content,
      bool omitDevFsPath = false,
    }) async {
      final client = HttpClient();
      final request = await client.putUrl(Uri.parse(serviceHttpAddress));
      request.headers.add('dev_fs_name', fsId);
      if (!omitDevFsPath) {
        request.headers.add('dev_fs_path_b64', filePathBase64);
      }
      request.add(gzip.encode(content));
      final response = await request.close();
      final responseBody = await readResponse(response);
      client.close();
      return jsonDecode(responseBody);
    }

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

    // Write the file by issuing an HTTP PUT.
    result = await postToDevFS(content: [9]);
    if (result case {'result': final Map<String, dynamic> innerResult}) {
      expectSuccess(innerResult);
    } else {
      invalidResponse(result);
    }

    // Trigger an error by issuing an HTTP PUT.
    result = await postToDevFS(content: fileContents, omitDevFsPath: true);
    if (result
        case {
          'error': {
            'data': {
              'details': final String details,
            }
          }
        }) {
      expect(details.contains("expects the 'path' parameter"), true);
    } else {
      invalidResponse(result);
    }

    // Write the file again but this time with the true file contents.
    result = await postToDevFS(content: fileContents);
    if (result case {'result': final Map<String, dynamic> innerResult}) {
      expectSuccess(innerResult);
    } else {
      invalidResponse(result);
    }

    // Read the file back.
    result = await callMethod(
      service,
      '_readDevFSFile',
      args: {
        'fsName': fsId,
        'path': filePath,
      },
    );
    if (result case {'type': 'FSFile', 'fileContents': final String contents}) {
      expect(contents, fileContentsBase64);
    } else {
      invalidResponse(result);
    }

    // List all the files in the file system.
    result = await callMethod(
      service,
      '_listDevFSFiles',
      args: {
        'fsName': fsId,
      },
    );
    if (result case {'type': 'FSFileList', 'files': [{'name': filePath}]}) {
      // Expected
    } else {
      invalidResponse(result);
    }

    // Delete DevFS.
    result = await callMethod(
      service,
      '_deleteDevFS',
      args: {
        'fsName': fsId,
      },
    );
    expectSuccess(result);
  },
];

void main(args) => runVMTests(
      args,
      tests,
      'dev_fs_http_put_weird_char_test.dart',
    );
