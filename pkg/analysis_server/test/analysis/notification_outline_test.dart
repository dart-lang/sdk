// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(AnalysisNotificationOutlineTest);
  });
}

@reflectiveTest
class AnalysisNotificationOutlineTest extends AbstractAnalysisTest {
  FileKind fileKind;
  String libraryName;
  Outline outline;

  final Completer<void> _outlineReceived = Completer();
  Completer _highlightsReceived = Completer();

  Future prepareOutline() {
    addAnalysisSubscription(AnalysisService.OUTLINE, testFile);
    return _outlineReceived.future;
  }

  @override
  void processNotification(Notification notification) {
    if (notification.event == ANALYSIS_NOTIFICATION_OUTLINE) {
      var params = AnalysisOutlineParams.fromNotification(notification);
      if (params.file == testFile) {
        fileKind = params.kind;
        libraryName = params.libraryName;
        outline = params.outline;
        _outlineReceived.complete();
      }
    }
    if (notification.event == ANALYSIS_NOTIFICATION_HIGHLIGHTS) {
      var params = AnalysisHighlightsParams.fromNotification(notification);
      if (params.file == testFile) {
        _highlightsReceived?.complete(null);
        _highlightsReceived = null;
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }

  Future<void> test_afterAnalysis() async {
    addTestFile('''
class AAA {
}
class BBB {
}
''');
    await waitForTasksFinished();
    expect(outline, isNull);
    await prepareOutline();
    var unitOutline = outline;
    var outlines = unitOutline.children;
    expect(outlines, hasLength(2));
  }

  Future<void> test_libraryName_hasLibraryDirective() async {
    addTestFile('''
library my.lib;
''');
    await prepareOutline();
    expect(fileKind, FileKind.LIBRARY);
    expect(libraryName, 'my.lib');
  }

  @failingTest
  Future<void> test_libraryName_hasLibraryPartOfDirectives() async {
    // This appears to have broken with the move to the new analysis driver.
    addTestFile('''
part of lib.in.part.of;
library my.lib;
''');
    await prepareOutline();
    expect(fileKind, FileKind.LIBRARY);
    expect(libraryName, 'my.lib');
  }

  Future<void> test_libraryName_hasPartOfDirective() async {
    addTestFile('''
part of my.lib;
''');
    await prepareOutline();
    expect(fileKind, FileKind.PART);
    expect(libraryName, 'my.lib');
  }

  Future<void> test_libraryName_noDirectives() async {
    addTestFile('''
class A {}
''');
    await prepareOutline();
    expect(fileKind, FileKind.LIBRARY);
    expect(libraryName, isNull);
  }

  Future<void> test_subscribeWhenCachedResultIsAvailable() async {
    // https://github.com/dart-lang/sdk/issues/30238
    // We need to get notifications for new subscriptions even when the
    // file is a priority file, and there is a cached result available.
    addTestFile('''
class A {}
class B {}
''');

    // Make the file a priority one and subscribe for other notification.
    // This will pre-cache the analysis result for the file.
    setPriorityFiles([testFile]);
    addAnalysisSubscription(AnalysisService.HIGHLIGHTS, testFile);
    await _highlightsReceived.future;

    // Now subscribe for outline notification, we must get it even though
    // the result which is used is pre-cached, and not a newly computed.
    await prepareOutline();
    expect(outline.children, hasLength(2));
  }
}
