// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
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
import '../utilities/flutter_util.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(FlutterNotificationOutlineTest);
  });
}

@reflectiveTest
class FlutterNotificationOutlineTest extends AbstractAnalysisTest {
  Folder flutterFolder;

  final Map<FlutterService, List<String>> flutterSubscriptions = {};

  Completer _outlineReceived = new Completer();
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
    Request request =
        new FlutterSetSubscriptionsParams(flutterSubscriptions).toRequest('0');
    handleSuccessfulRequest(request, handler: flutterHandler);
  }

  Future prepareOutline() {
    addFlutterSubscription(FlutterService.OUTLINE, testFile);
    return _outlineReceived.future;
  }

  void processNotification(Notification notification) {
    if (notification.event == FLUTTER_NOTIFICATION_OUTLINE) {
      var params = new FlutterOutlineParams.fromNotification(notification);
      if (params.file == testFile) {
        outline = params.outline;
        _outlineReceived.complete(null);
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
    flutterFolder = configureFlutterPackage(resourceProvider);
  }

  test_children() async {
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
    FlutterOutline unitOutline = outline;

    FlutterOutline myWidgetOutline = unitOutline.children[0];
    expect(myWidgetOutline.kind, FlutterOutlineKind.DART_ELEMENT);
    expect(myWidgetOutline.dartElement.name, 'MyWidget');

    FlutterOutline buildOutline = myWidgetOutline.children[0];
    expect(buildOutline.kind, FlutterOutlineKind.DART_ELEMENT);
    expect(buildOutline.dartElement.name, 'build');

    FlutterOutline columnOutline = buildOutline.children[0];
    expect(columnOutline.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(columnOutline.className, 'Column');
    expect(columnOutline.children, hasLength(2));

    FlutterOutline textOutlineA = columnOutline.children[0];
    expect(textOutlineA.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textOutlineA.className, 'Text');
    expect(textOutlineA.offset, code.indexOf("const Text('aaa')"));

    FlutterOutline textOutlineB = columnOutline.children[1];
    expect(textOutlineB.kind, FlutterOutlineKind.NEW_INSTANCE);
    expect(textOutlineB.className, 'Text');
    expect(textOutlineB.offset, code.indexOf("const Text('bbb')"));
  }
}
