// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/folding_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(FoldingMixinTest);
}

@reflectiveTest
class FoldingMixinTest with ResourceProviderMixin {
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

  Future<void> test_sendFoldingNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var notificationReceived = Completer<void>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      var params = AnalysisFoldingParams.fromNotification(notification);
      expect(params.file, filePath1);
      var regions = params.regions;
      expect(regions, hasLength(7));
      notificationReceived.complete();
    });
    await plugin.sendFoldingNotification(filePath1);
    await notificationReceived.future;
  }
}

class _TestFoldingContributor implements FoldingContributor {
  int regionCount;

  _TestFoldingContributor(this.regionCount);

  @override
  void computeFolding(FoldingRequest request, FoldingCollector collector) {
    for (var i = 0; i < regionCount; i++) {
      collector.addRegion(i * 20, 10, FoldingKind.FILE_HEADER);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with FoldingMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  List<FoldingContributor> getFoldingContributors(String path) {
    return <FoldingContributor>[
      _TestFoldingContributor(3),
      _TestFoldingContributor(4)
    ];
  }

  @override
  Future<FoldingRequest> getFoldingRequest(String path) async {
    var result = MockResolvedUnitResult(path: path);
    return DartFoldingRequestImpl(resourceProvider, result);
  }
}
