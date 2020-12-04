// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

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
    contextRoot1 = ContextRoot(packagePath1, <String>[]);

    channel = MockChannel();
    plugin = _TestServerPlugin(resourceProvider);
    plugin.start(channel);
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
  void computeFixes(FixesRequest request, FixCollector collector) {
    for (var change in changes) {
      collector.addFix(request.errorsToFix[0], change);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with FixesMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

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
    var error = AnalysisError(
        MockSource(), 0, 0, CompileTimeErrorCode.AWAIT_IN_WRONG_CONTEXT);
    var result =
        MockResolvedUnitResult(lineInfo: LineInfo([0, 20]), errors: [error]);
    return DartFixesRequestImpl(resourceProvider, offset, [error], result);
  }
}
