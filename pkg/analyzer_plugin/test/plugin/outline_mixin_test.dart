// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/outline_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/outline/outline.dart';
import 'package:analyzer_plugin/utilities/outline/outline.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(OutlineMixinTest);
}

@reflectiveTest
class OutlineMixinTest with ResourceProviderMixin {
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

  Future<void> test_sendOutlineNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        AnalysisSetContextRootsParams([contextRoot1]));

    var notificationReceived = Completer<void>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      var params = AnalysisOutlineParams.fromNotification(notification);
      expect(params.file, filePath1);
      expect(params.outline, hasLength(3));
      notificationReceived.complete();
    });
    await plugin.sendOutlineNotification(filePath1);
    await notificationReceived.future;
  }
}

class _TestOutlineContributor implements OutlineContributor {
  int elementCount;

  _TestOutlineContributor(this.elementCount);

  @override
  void computeOutline(OutlineRequest request, OutlineCollector collector) {
    for (var i = 0; i < elementCount; i++) {
      collector.startElement(Element(ElementKind.METHOD, 'm$i', 0), 20 * i, 20);
      collector.endElement();
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with OutlineMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  List<OutlineContributor> getOutlineContributors(String path) {
    return <OutlineContributor>[
      _TestOutlineContributor(2),
      _TestOutlineContributor(1)
    ];
  }

  @override
  Future<OutlineRequest> getOutlineRequest(String path) async {
    var result = MockResolvedUnitResult(path: path);
    return DartOutlineRequestImpl(resourceProvider, result);
  }
}
