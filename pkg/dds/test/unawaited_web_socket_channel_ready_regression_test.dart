// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// Regression test for https://dartbug.com/55731.

import 'package:dds/dds.dart';
import 'package:test/test.dart';

void main() async {
  // We previously were not awaiting [WebSocketChannel.ready], which meant that
  // when it completed with an error, it made the program terminate instead of
  // making the return value of [startDartDevelopmentService] complete with an
  // error.
  test(
      'Trying to connect to an invalid remote VM Service makes the return '
      'value of startDartDevelopmentService complete with an error', () async {
    try {
      await DartDevelopmentService.startDartDevelopmentService(
        Uri.parse('http://bogus.local'),
      );
      fail('Unexpected successful connection');
    } on DartDevelopmentServiceException catch (e) {
      expect(e.errorCode, DartDevelopmentServiceException.connectionError);
      expect(e.toString().contains('WebSocketChannelException'), true);
    }
  });
}
