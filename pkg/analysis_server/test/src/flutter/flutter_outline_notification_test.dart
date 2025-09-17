// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_server_base.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterNotificationOutlineTest);
  });
}

@reflectiveTest
class FlutterNotificationOutlineTest extends PubPackageAnalysisServerTest {
  final Completer<void> _outlineReceived = Completer();
  late FlutterOutline outline;

  Future<void> addFlutterSubscription(FlutterService service, File file) async {
    await handleSuccessfulRequest(
      FlutterSetSubscriptionsParams({
        service: [file.path],
      }).toRequest('0', clientUriConverter: server.uriConverter),
    );
  }

  Future<void> prepareOutline() async {
    await addFlutterSubscription(FlutterService.OUTLINE, testFile);
    return _outlineReceived.future;
  }

  @override
  void processNotification(Notification notification) {
    super.processNotification(notification);
    if (notification.event == FLUTTER_NOTIFICATION_OUTLINE) {
      var params = FlutterOutlineParams.fromNotification(
        notification,
        clientUriConverter: server.uriConverter,
      );
      if (params.file == testFile.path) {
        outline = params.outline;
        _outlineReceived.complete();
      }
    }
  }

  @override
  Future<void> setUp() async {
    super.setUp();
    writeTestPackageConfig(flutter: true);
    await setRoots(included: [workspaceRootPath], excluded: []);
  }

  Future<void> test_children() async {
    newAnalysisOptionsYamlFile(testPackageRootPath, '''
analyzer:
  strong-mode: true
''');
    await pumpEventQueue();
    await server.onAnalysisComplete;

    addTestFile('''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(children: [
      /*0*/const Text('aaa'),
      /*1*/const Text('bbb'),
    ]);
  }
}
''');

    await prepareOutline();
    var unitOutline = outline;

    var myWidgetOutline = unitOutline.children![0];
    expect(myWidgetOutline.kind, FlutterOutlineKind.DART_ELEMENT);
    expect(myWidgetOutline.dartElement!.name, 'MyWidget');

    var buildOutline = myWidgetOutline.children![0];
    expect(buildOutline.kind, FlutterOutlineKind.DART_ELEMENT);
    expect(buildOutline.dartElement!.name, 'build');

    var columnOutline = buildOutline.children![0];
    expect(columnOutline.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(columnOutline.className, 'Column');
    expect(columnOutline.children, hasLength(2));

    var textOutlineA = columnOutline.children![0];
    expect(textOutlineA.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textOutlineA.className, 'Text');
    expect(textOutlineA.offset, parsedPositions[0].offset);

    var textOutlineB = columnOutline.children![1];
    expect(textOutlineB.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textOutlineB.className, 'Text');
    expect(textOutlineB.offset, parsedPositions[1].offset);
  }
}
