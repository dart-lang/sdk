// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/source/line_info.dart';
import 'package:analyzer/src/error/codes.dart';
import 'package:analyzer_plugin/plugin/fix_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    hide AnalysisError;
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/fixes/fixes.dart';
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';
import 'plugin_test.dart';

void main() {
  defineReflectiveTests(FixesMixinTest);
}

@reflectiveTest
class FixesMixinTest extends AbstractPluginTest {
  late String packagePath1;
  late String filePath1;
  late ContextRoot contextRoot1;

  @override
  ServerPlugin createPlugin() {
    return _TestServerPlugin(resourceProvider);
  }

  @override
  Future<void> setUp() async {
    await super.setUp();
    packagePath1 = convertPath('/package1');
    filePath1 = join(packagePath1, 'lib', 'test.dart');
    newFile(filePath1, '');
    contextRoot1 = ContextRoot(packagePath1, <String>[]);
  }

  Future<void> test_handleEditGetFixes() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var result =
        await plugin.handleEditGetFixes(EditGetFixesParams(filePath1, 13));
    expect(result, isNotNull);
    var fixes = result.fixes;
    expect(fixes, hasLength(1));
    expect(fixes[0].fixes, hasLength(3));
  }
}

class _TestFixContributor implements FixContributor {
  List<PrioritizedSourceChange> changes;

  _TestFixContributor(this.changes);

  @override
  Future<void> computeFixes(
      FixesRequest request, FixCollector collector) async {
    for (var change in changes) {
      collector.addFix(request.errorsToFix[0], change);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with FixesMixin {
  _TestServerPlugin(super.resourceProvider);

  PrioritizedSourceChange createChange() {
    return PrioritizedSourceChange(0, SourceChange(''));
  }

  @override
  List<FixContributor> getFixContributors(String path) {
    return <FixContributor>[
      _TestFixContributor(<PrioritizedSourceChange>[createChange()]),
      _TestFixContributor(
          <PrioritizedSourceChange>[createChange(), createChange()])
    ];
  }

  @override
  Future<FixesRequest> getFixesRequest(EditGetFixesParams parameters) async {
    var offset = parameters.offset;
    var diagnostic = Diagnostic.tmp(
      source: MockSource(),
      offset: 0,
      length: 0,
      diagnosticCode: CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT,
    );
    var result = MockResolvedUnitResult(
        lineInfo: LineInfo([0, 20]), errors: [diagnostic]);
    return DartFixesRequestImpl(resourceProvider, offset, [diagnostic], result);
  }
}
