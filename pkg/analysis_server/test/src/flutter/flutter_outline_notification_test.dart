// Copyright (c) 2018, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/flutter/flutter_domain.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../../analysis_abstract.dart';
import '../utilities/mock_packages.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterNotificationOutlineTest);
  });
}

@reflectiveTest
class FlutterNotificationOutlineTest extends AbstractAnalysisTest {
  Folder flutterFolder;

  final Map<FlutterService, List<String>> flutterSubscriptions = {};

  final Completer<void> _outlineReceived = Completer();
  FlutterOutline outline;

  FlutterDomainHandler get flutterHandler =>
      server.handlers.singleWhere((handler) => handler is FlutterDomainHandler);

  void addFlutterSubscription(FlutterService service, String file) {
    // add file to subscription
    var files = analysisSubscriptions[service];
    if (files == null) {
      files = <String>[];
      flutterSubscriptions[service] = files;
    }
    files.add(file);
    // set subscriptions
    var request =
        FlutterSetSubscriptionsParams(flutterSubscriptions).toRequest('0');
    handleSuccessfulRequest(request, handler: flutterHandler);
  }

  Future prepareOutline() {
    addFlutterSubscription(FlutterService.OUTLINE, testFile);
    return _outlineReceived.future;
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == FLUTTER_NOTIFICATION_OUTLINE) {
      var params = FlutterOutlineParams.fromNotification(notification);
      if (params.file == testFile) {
        outline = params.outline;
        _outlineReceived.complete();
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    flutterFolder = MockPackages.instance.addFlutter(resourceProvider);
  }

  Future<void> test_children() async {
    newFile('$projectPath/.packages', content: '''
flutter:${flutterFolder.toUri()}
''');
    newFile('$projectPath/analysis_options.yaml', content: '''
analyzer:
  strong-mode: true
''');
    var code = '''
import 'package:flutter/widgets.dart';

class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new Column(children: [
      const Text('aaa'),
      const Text('bbb'),
    ]);
  }
}
''';
    addTestFile(code);
    await prepareOutline();
    var unitOutline = outline;

    var myWidgetOutline = unitOutline.children[0];
    expect(myWidgetOutline.kind, FlutterOutlineKind.DART_ELEMENT);
    expect(myWidgetOutline.dartElement.name, 'MyWidget');

    var buildOutline = myWidgetOutline.children[0];
    expect(buildOutline.kind, FlutterOutlineKind.DART_ELEMENT);
    expect(buildOutline.dartElement.name, 'build');

    var columnOutline = buildOutline.children[0];
    expect(columnOutline.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(columnOutline.className, 'Column');
    expect(columnOutline.children, hasLength(2));

    var textOutlineA = columnOutline.children[0];
    expect(textOutlineA.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textOutlineA.className, 'Text');
    expect(textOutlineA.offset, code.indexOf("const Text('aaa')"));

    var textOutlineB = columnOutline.children[1];
    expect(textOutlineB.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textOutlineB.className, 'Text');
    expect(textOutlineB.offset, code.indexOf("const Text('bbb')"));
  }
}
