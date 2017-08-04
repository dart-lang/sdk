// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../mocks.dart';
import 'dart:async';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_constants.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

import '../analysis_abstract.dart';

main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(_AnalysisNotificationClosingLabelsTest);
  });
}

@reflectiveTest
class _AnalysisNotificationClosingLabelsTest extends AbstractAnalysisTest {
  List<ClosingLabel> lastLabels;

  Completer _labelsReceived;

  void subscribeForLabels() {
    addAnalysisSubscription(AnalysisService.CLOSING_LABELS, testFile);
  }

  Future waitForLabels(action()) {
    _labelsReceived = new Completer();
    action();
    return _labelsReceived.future;
  }

  void processNotification(Notification notification) {
    print(notification.toJson());
    if (notification.event == ANALYSIS_NOTIFICATION_CLOSING_LABELS) {
      var params =
          new AnalysisClosingLabelsParams.fromNotification(notification);
      if (params.file == testFile) {
        lastLabels = params.labels;
        _labelsReceived.complete(null);
      }
    }
  }

  @override
  void setUp() {
    super.setUp();
    createProject();
  }
}
