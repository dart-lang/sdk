// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/analysis/results.dart' hide AnalysisResult;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/plugin/fix_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:path/src/context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(FixesMixinTest);
}

@reflectiveTest
class FixesMixinTest {
  MemoryResourceProvider resourceProvider = new MemoryResourceProvider();

  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  MockChannel channel;
  _TestServerPlugin plugin;

  void setUp() {
    Context pathContext = resourceProvider.pathContext;

    packagePath1 = resourceProvider.convertPath('/package1');
    filePath1 = pathContext.join(packagePath1, 'lib', 'test.dart');
    resourceProvider.newFile(filePath1, '');
    contextRoot1 = new ContextRoot(packagePath1, <String>[]);

    channel = new MockChannel();
    plugin = new _TestServerPlugin(resourceProvider);
    plugin.start(channel);
  }

  test_handleEditGetFixes() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    EditGetFixesResult result =
        await plugin.handleEditGetFixes(new EditGetFixesParams(filePath1, 13));
    expect(result, isNotNull);
    List<AnalysisErrorFixes> fixes = result.fixes;
    expect(fixes, hasLength(1));
    expect(fixes[0].fixes, hasLength(3));
  }
}

class _TestFixContributor implements FixContributor {
  List<PrioritizedSourceChange> changes;

  _TestFixContributor(this.changes);

  @override
  void computeFixes(FixesRequest request, FixCollector collector) {
    for (PrioritizedSourceChange change in changes) {
      collector.addFix(request.error, change);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with FixesMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  PrioritizedSourceChange createChange() {
    return new PrioritizedSourceChange(0, new SourceChange(''));
  }

  @override
  List<FixContributor> getFixContributors(AnalysisDriverGeneric driver) {
    return <FixContributor>[
      new _TestFixContributor(<PrioritizedSourceChange>[createChange()]),
      new _TestFixContributor(
          <PrioritizedSourceChange>[createChange(), createChange()])
    ];
  }

  @override
  Future<ResolveResult> getResolveResultForFixes(
      AnalysisDriverGeneric driver, String path) async {
    AnalysisError error = new AnalysisError(
        new MockSource(), 0, 0, CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT);
    return new AnalysisResult(null, null, null, null, null, null,
        new LineInfo([0, 20]), null, null, [error], null);
  }
}
