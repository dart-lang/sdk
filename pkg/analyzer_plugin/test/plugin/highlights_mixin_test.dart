// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/highlights_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(HighlightsMixinTest);
}

@reflectiveTest
class HighlightsMixinTest with ResourceProviderMixin {
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

  test_sendHighlightsNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    Completer<void> notificationReceived = new Completer<void>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      AnalysisHighlightsParams params =
          new AnalysisHighlightsParams.fromNotification(notification);
      expect(params.file, filePath1);
      expect(params.regions, hasLength(5));
      notificationReceived.complete();
    });
    await plugin.sendHighlightsNotification(filePath1);
    await notificationReceived.future;
  }
}

class _TestHighlightsContributor implements HighlightsContributor {
  int elementCount;

  _TestHighlightsContributor(this.elementCount);

  @override
  void computeHighlights(
      HighlightsRequest request, HighlightsCollector collector) {
    for (int i = 0; i < elementCount; i++) {
      collector.addRegion(i, 20, HighlightRegionType.METHOD_DECLARATION);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with HighlightsMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  List<HighlightsContributor> getHighlightsContributors(String path) {
    return <HighlightsContributor>[
      new _TestHighlightsContributor(2),
      new _TestHighlightsContributor(3)
    ];
  }

  @override
  Future<HighlightsRequest> getHighlightsRequest(String path) async {
    var result = new MockResolvedUnitResult(path: path);
    return new DartHighlightsRequestImpl(resourceProvider, result);
  }
}
