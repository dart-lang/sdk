// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert' show utf8;

import 'package:http/http.dart';
import 'package:http/testing.dart';
import 'package:telemetry/crash_reporting.dart';
import 'package:test/test.dart';
import 'package:usage/usage.dart';

void main() {
  group('CrashReportSender', () {
    MockClient mockClient;
    AnalyticsMock analytics;

    Request request;

    setUp(() {
      mockClient = new MockClient((Request r) async {
        request = r;
        return new Response('crash-report-001', 200);
      });

      analytics = new AnalyticsMock()..enabled = true;
    });

    EnablementCallback shouldSend = () {
      return true;
    };

    test('general', () async {
      CrashReportSender sender = new CrashReportSender.prod(
          analytics.trackingId, shouldSend,
          httpClient: mockClient);

      await sender.sendReport('test-error', StackTrace.current);

      String body = utf8.decode(request.bodyBytes);
      expect(body, contains('String')); // error.runtimeType
      expect(body, contains('test-error'));
    });

    test('reportsSent', () async {
      CrashReportSender sender = new CrashReportSender.prod(
          analytics.trackingId, shouldSend,
          httpClient: mockClient);

      expect(sender.reportsSent, 0);

      await sender.sendReport('test-error', StackTrace.current);

      expect(sender.reportsSent, 1);

      String body = utf8.decode(request.bodyBytes);
      expect(body, contains('String'));
      expect(body, contains('test-error'));
    });

    test('contains message', () async {
      CrashReportSender sender = new CrashReportSender.prod(
          analytics.trackingId, shouldSend,
          httpClient: mockClient);

      await sender.sendReport('test-error', StackTrace.current,
          comment: 'additional message');

      String body = utf8.decode(request.bodyBytes);
      expect(body, contains('String'));
      expect(body, contains('test-error'));
      expect(body, contains('additional message'));
    });

    test('has attachments', () async {
      CrashReportSender sender = new CrashReportSender.prod(
          analytics.trackingId, shouldSend,
          httpClient: mockClient);

      await sender.sendReport(
        'test-error',
        StackTrace.current,
        attachments: [
          CrashReportAttachment.string(field: 'attachment-1', value: 'aaa'),
          CrashReportAttachment.string(field: 'attachment-2', value: 'bbb'),
        ],
      );

      String body = utf8.decode(request.bodyBytes);
      expect(body, contains('attachment-1'));
      expect(body, contains('aaa'));
      expect(body, contains('attachment-2'));
      expect(body, contains('bbb'));
    });

    test('has ptime', () async {
      CrashReportSender sender = new CrashReportSender.prod(
          analytics.trackingId, shouldSend,
          httpClient: mockClient);

      await sender.sendReport('test-error', StackTrace.current);

      String body = utf8.decode(request.bodyBytes);
      expect(body, contains('name="ptime"'));
    });
  });
}
