// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/string_source.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:nnbd_migration/src/edit_plan.dart';
import 'package:nnbd_migration/src/front_end/migration_summary.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(MigrationSummaryTestPosix);
    defineReflectiveTests(MigrationSummaryTestWindows);
  });
}

abstract class MigrationSummaryTestBase {
  MemoryResourceProvider get resourceProvider;
}

mixin MigrationSummaryTestCases on MigrationSummaryTestBase {
  test_summarize_changes_by_file() {
    var summaryPath = resourceProvider.convertPath('/summary.json');
    var rootPath = resourceProvider.convertPath('/project');
    var summary = MigrationSummary(summaryPath, resourceProvider, rootPath);
    summary.recordChanges(
        StringSource('', resourceProvider.convertPath('/project/lib/foo.dart')),
        {
          0: [
            AtomicEdit.insert('x',
                info: AtomicEditInfo(
                    NullabilityFixDescription.makeTypeNullable('int'),
                    const {}))
          ]
        });
    summary.write();
    var json =
        jsonDecode(resourceProvider.getFile(summaryPath).readAsStringSync());
    var separator = resourceProvider.pathContext.separator;
    expect(json['changes']['byPath'], {
      'lib${separator}foo.dart': {'makeTypeNullable': 1}
    });
  }
}

@reflectiveTest
class MigrationSummaryTestPosix extends MigrationSummaryTestBase
    with MigrationSummaryTestCases {
  @override
  final MemoryResourceProvider resourceProvider =
      MemoryResourceProvider(context: path.posix);
}

@reflectiveTest
class MigrationSummaryTestWindows extends MigrationSummaryTestBase
    with MigrationSummaryTestCases {
  @override
  final MemoryResourceProvider resourceProvider =
      MemoryResourceProvider(context: path.windows);
}
