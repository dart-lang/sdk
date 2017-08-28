// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/plugin/folding_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/folding/folding.dart';
import 'package:analyzer_plugin/utilities/folding/folding.dart';
import 'package:path/src/context.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(FoldingMixinTest);
}

@reflectiveTest
class FoldingMixinTest {
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

  test_sendFoldingNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    Completer<Null> notificationReceived = new Completer<Null>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      AnalysisFoldingParams params =
          new AnalysisFoldingParams.fromNotification(notification);
      expect(params.file, filePath1);
      List<FoldingRegion> regions = params.regions;
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
    for (int i = 0; i < regionCount; i++) {
      collector.addRegion(i * 20, 10, FoldingKind.COMMENT);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with FoldingMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  List<FoldingContributor> getFoldingContributors(String path) {
    return <FoldingContributor>[
      new _TestFoldingContributor(3),
      new _TestFoldingContributor(4)
    ];
  }

  @override
  Future<FoldingRequest> getFoldingRequest(String path) async {
    AnalysisResult result = new AnalysisResult(
        null, null, path, null, null, null, null, null, null, null, null);
    return new DartFoldingRequestImpl(resourceProvider, result);
  }
}
