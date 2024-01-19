// Copyright (c) 2015, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'clients/test_all.dart' as clients;
import 'context/test_all.dart' as context;
import 'dart/test_all.dart' as dart;
import 'dartdoc/test_all.dart' as dartdoc;
import 'diagnostics/test_all.dart' as diagnostics;
import 'fasta/test_all.dart' as fasta;
import 'hint/test_all.dart' as hint;
import 'lint/test_all.dart' as lint;
import 'manifest/test_all.dart' as manifest;
import 'options/test_all.dart' as options;
import 'pubspec/test_all.dart' as pubspec;
import 'services/test_all.dart' as services;
import 'source/test_all.dart' as source;
import 'summary/test_all.dart' as summary;
import 'task/test_all.dart' as task;
import 'test_utilities/test_all.dart' as test_utilities;
import 'util/test_all.dart' as util;
import 'utilities/test_all.dart' as utilities;
import 'wolf/test_all.dart' as wolf;
import 'workspace/test_all.dart' as workspace;

main() {
  defineReflectiveSuite(() {
    clients.main();
    context.main();
    dart.main();
    dartdoc.main();
    diagnostics.main();
    fasta.main();
    hint.main();
    lint.main();
    manifest.main();
    options.main();
    pubspec.main();
    services.main();
    source.main();
    summary.main();
    task.main();
    test_utilities.main();
    util.main();
    utilities.main();
    wolf.main();
    workspace.main();
  }, name: 'src');
}
