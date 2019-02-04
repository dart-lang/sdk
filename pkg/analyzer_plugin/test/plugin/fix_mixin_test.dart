// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/fix_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(FixesMixinTest);
}

@reflectiveTest
class FixesMixinTest with ResourceProviderMixin {
  String packagePath1;
  String filePath1;
  ContextRoot contextRoot1;

  MockChannel channel;
  _TestServerPlugin plugin;

  void setUp() {
    packagePath1 = convertPath('/package1');
    filePath1 = join(packagePath1, 'lib', 'test.dart');
    newFile(filePath1);
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
      collector.addFix(request.errorsToFix[0], change);
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
  List<FixContributor> getFixContributors(String path) {
    return <FixContributor>[
      new _TestFixContributor(<PrioritizedSourceChange>[createChange()]),
      new _TestFixContributor(
          <PrioritizedSourceChange>[createChange(), createChange()])
    ];
  }

  @override
  Future<FixesRequest> getFixesRequest(EditGetFixesParams parameters) async {
    int offset = parameters.offset;
    AnalysisError error = new AnalysisError(
        new MockSource(), 0, 0, CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT);
    var result = new MockResolvedUnitResult(
        lineInfo: new LineInfo([0, 20]), errors: [error]);
    return new DartFixesRequestImpl(resourceProvider, offset, [error], result);
  }
}
