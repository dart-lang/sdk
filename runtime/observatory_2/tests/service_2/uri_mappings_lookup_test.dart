// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:observatory_2/service_io.dart';
import 'package:test/test.dart';

import 'test_helper.dart';

final tests = <IsolateTest>[
  (Isolate isolate) async {
    final scriptUri =
        'file://${Directory.current.path}/runtime/observatory_2/tests/service_2/uri_mappings_lookup_test.dart';
    final unresolvedUris = <String>[
      'package:does_not_exist/does_not_exist.dart', // invalid URI -> null
      'dart:io', // dart:io -> org-dartlang-sdk:///sdk/lib/io/io.dart
      'package:pool/pool.dart', // package:pool/pool.dart -> file:///some_dir/pool/lib/pool.dart
      scriptUri, // file:///abc.dart -> file:///abc.dart
      if (Platform.isWindows || Platform.isMacOS) scriptUri.toUpperCase(),
    ];

    var result = await isolate.invokeRpcNoUpgrade('lookupResolvedPackageUris', {
      'uris': unresolvedUris,
    });
    expect(result['uris'], isNotNull);
    var uris = result['uris'].cast<String>();
    expect(uris.length, unresolvedUris.length);
    expect(uris[0], isNull);
    expect(uris[1], 'org-dartlang-sdk:///sdk/lib/io/io.dart');
    expect(uris[2], startsWith('file:///'));
    expect(uris[2], endsWith('third_party/pkg/pool/lib/pool.dart'));
    expect(uris[3], scriptUri);
    if (Platform.isWindows || Platform.isMacOS) {
      expect(uris[4], scriptUri);
    }

    result = await isolate.invokeRpcNoUpgrade('lookupPackageUris', {
      'uris': [
        'does_not_exist.dart',
        ...uris.sublist(1, 4),
        if (Platform.isWindows || Platform.isMacOS) scriptUri.toUpperCase(),
      ]
    });
    expect(result['uris'], isNotNull);
    uris = result['uris'].cast<String>();
    expect(uris.length, unresolvedUris.length);
    expect(uris[0], isNull);
    expect(uris[1], unresolvedUris[1]);
    expect(uris[2], unresolvedUris[2]);
    expect(uris[3], unresolvedUris[3]);
    if (Platform.isWindows || Platform.isMacOS) {
      expect(uris[4], scriptUri);
    }
  },
];

void main(args) => runIsolateTests(args, tests);
