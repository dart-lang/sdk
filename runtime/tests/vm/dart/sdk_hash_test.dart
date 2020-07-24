// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:expect/expect.dart';

import 'snapshot_test_helper.dart';

// Keep in sync with pkg/kernel/lib/binary/tag.dart:
const tagComponentFile = [0x90, 0xAB, 0xCD, 0xEF];

Future<void> main(List<String> args) async {
  if (args.length == 1 && args[0] == '--child') {
    print('Hello, SDK Hash!');
    return;
  }

  final String sourcePath =
      path.join('runtime', 'tests', 'vm', 'dart_2', 'sdk_hash_test.dart');

  await withTempDir((String tmp) async {
    final String dillPath = path.join(tmp, 'test.dill');

    {
      final result = await Process.run(dart, [
        '--snapshot-kind=kernel',
        '--snapshot=$dillPath',
        sourcePath,
      ]);
      Expect.equals('', result.stderr);
      Expect.equals(0, result.exitCode);
      Expect.equals('', result.stdout);
    }

    {
      final result = await Process.run(dart, [dillPath, '--child']);
      Expect.equals('', result.stderr);
      Expect.equals(0, result.exitCode);
      Expect.equals('Hello, SDK Hash!', result.stdout.trim());
    }

    // Invalidate the SDK hash in the kernel dill:
    {
      final myFile = File(dillPath);
      Uint8List bytes = myFile.readAsBytesSync();
      // The SDK Hash is located after the ComponentFile and BinaryFormatVersion
      // tags (both UInt32).
      Expect.listEquals(tagComponentFile, bytes.sublist(0, 4));
      Expect.notEquals('0000000000', ascii.decode(bytes.sublist(8, 10)));
      // Flip the first byte in the hash:
      bytes[8] = ~bytes[8];
      myFile.writeAsBytesSync(bytes);
    }

    {
      final result = await Process.run(dart, [dillPath, '--child']);
      Expect.equals(
          'Can\'t load Kernel binary: Invalid SDK hash.', result.stderr.trim());
      Expect.equals(253, result.exitCode);
      Expect.equals('', result.stdout);
    }

    // Zero out the SDK hash in the kernel dill to disable the check:
    {
      final myFile = File(dillPath);
      Uint8List bytes = myFile.readAsBytesSync();
      bytes.setRange(8, 18, ascii.encode('0000000000'));
      myFile.writeAsBytesSync(bytes);
    }

    {
      final result = await Process.run(dart, [dillPath, '--child']);
      Expect.equals('', result.stderr);
      Expect.equals(0, result.exitCode);
      Expect.equals('Hello, SDK Hash!', result.stdout.trim());
    }
  });
}
