// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/test_utilities/resource_provider_mixin.dart';
import 'package:analyzer_plugin/plugin/navigation_mixin.dart';
import 'package:analyzer_plugin/protocol/protocol.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:analyzer_plugin/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/src/utilities/navigation/navigation.dart';
import 'package:analyzer_plugin/utilities/navigation/navigation.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import 'mocks.dart';

void main() {
  defineReflectiveTests(NavigationMixinTest);
}

@reflectiveTest
class NavigationMixinTest with ResourceProviderMixin {
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

  test_handleAnalysisGetNavigation() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    AnalysisGetNavigationResult result =
        await plugin.handleAnalysisGetNavigation(
            new AnalysisGetNavigationParams(filePath1, 1, 2));
    expect(result, isNotNull);
    expect(result.files, hasLength(1));
    expect(result.targets, hasLength(1));
    expect(result.regions, hasLength(2));
  }

  test_sendNavigationNotification() async {
    await plugin.handleAnalysisSetContextRoots(
        new AnalysisSetContextRootsParams([contextRoot1]));

    Completer<void> notificationReceived = new Completer<void>();
    channel.listen(null, onNotification: (Notification notification) {
      expect(notification, isNotNull);
      AnalysisNavigationParams params =
          new AnalysisNavigationParams.fromNotification(notification);
      expect(params.files, hasLength(1));
      expect(params.targets, hasLength(1));
      expect(params.regions, hasLength(2));
      notificationReceived.complete();
    });
    await plugin.sendNavigationNotification(filePath1);
    await notificationReceived.future;
  }
}

class _TestNavigationContributor implements NavigationContributor {
  int regionCount;

  _TestNavigationContributor(this.regionCount);

  @override
  void computeNavigation(
      NavigationRequest request, NavigationCollector collector) {
    for (int i = 0; i < regionCount; i++) {
      collector.addRegion(
          i, 5, ElementKind.METHOD, new Location('a', 5, 5, 1, 5));
    }
  }
}

class _TestServerPlugin extends MockServerPlugin with NavigationMixin {
  _TestServerPlugin(ResourceProvider resourceProvider)
      : super(resourceProvider);

  @override
  List<NavigationContributor> getNavigationContributors(String path) {
    return <NavigationContributor>[
      new _TestNavigationContributor(2),
      new _TestNavigationContributor(1)
    ];
  }

  @override
  Future<NavigationRequest> getNavigationRequest(
      AnalysisGetNavigationParams parameters) async {
    var result = new MockResolvedUnitResult(path: parameters.file);
    return new DartNavigationRequestImpl(
        resourceProvider, parameters.offset, parameters.length, result);
  }
}
