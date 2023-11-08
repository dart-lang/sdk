// Copyright (c) 2023, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io';

import 'package:expect/expect.dart';
import 'package:path/path.dart' as path;

import 'isolates/reload_utils.dart';

Future main() async {
  if (!currentVmSupportsReload) return;

  await withTempDir((String tempDir) async {
    final filename = path.join(tempDir, 'testee.dart');
    File(filename).writeAsStringSync(dartTestFile('AA', 'BB'));

    final helper = await launchOn(filename);
    await helper.waitUntilStdoutContains('READY :-)');

    final json = await helper.invokeServiceExtension('ext.myextension');
    print('Got result: "$json"');
    Expect.isTrue(json['identical'] as bool);
    Expect.equals('BB', json['value']);

    final int exitCode = await helper.close();
    Expect.equals(0, exitCode);
  });
}

String dartTestFile(String zoneKey, String zoneValue) => '''
import 'dart:async';
import 'dart:convert';
import 'dart:isolate';
import 'dart:developer';

const token = '__token__';

void main() {
  print('Waiting for reload');
  final rp = ReceivePort();
  runZoned(() {
    final expectedZone = Zone.current;
    registerExtension('ext.myextension', (_, __) async {
      final zonesIdentical = identical(expectedZone,  Zone.current);
      final zoneValue = Zone.current['$zoneKey'];
      final result = {
        'identical': zonesIdentical,
        'value' : '$zoneValue',
      };
      rp.close();
      return ServiceExtensionResponse.result(json.encode(result));
    });
  }, zoneValues: {'$zoneKey': '$zoneValue'});
  print('READY :-)');
}
''';
