// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer_plugin/plugin/highlights_mixin.dart';
import 'package:analyzer_plugin/plugin/plugin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/highlights/highlights.dart';
import 'package:analyzer_plugin/utilities/highlights/highlights.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';
import 'plugin_test.dart';

void main() {
  defineReflectiveTests(HighlightsMixinTest);
}

@reflectiveTest
class HighlightsMixinTest extends AbstractPluginTest {
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

  Future<void> test_sendHighlightsNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var notificationReceived = Completer<void>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      var params = AnalysisHighlightsParams.fromNotification(notification);
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
    for (var i = 0; i < elementCount; i++) {
      collector.addRegion(i, 20, HighlightRegionType.METHOD_DECLARATION);
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with HighlightsMixin {
  _TestServerPlugin(super.resourceProvider);

  @override
  List<HighlightsContributor> getHighlightsContributors(String path) {
    return <HighlightsContributor>[
      _TestHighlightsContributor(2),
      _TestHighlightsContributor(3)
    ];
  }

  @override
  Future<HighlightsRequest> getHighlightsRequest(String path) async {
    var result = MockResolvedUnitResult(path: path);
    return DartHighlightsRequestImpl(resourceProvider, result);
  }
}
