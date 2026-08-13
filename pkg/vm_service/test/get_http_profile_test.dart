// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
// VMOptions=--timeline_streams=Dart

import 'dart:async';
import 'dart:convert';

import 'package:test/test.dart';
import 'package:vm_service/vm_service.dart';

import 'common/service_test_common.dart';
import 'get_http_profile_lib.dart' as testee_lib;

late VmService vmService;

Future<void> hasValidHttpRequests(HttpProfile profile, String method) async {
  final requests = profile.requests
      .where(
        (element) => element.method == method,
      )
      .toList();
  expect(requests.length, 10);

  for (final r in requests) {
    final fullRequest =
        await vmService.getHttpProfileRequest(r.isolateId, r.id);
    if (r.isRequestComplete) {
      final requestData = fullRequest.request!;

      if (r.request!.hasError) {
        void expectThrows(Function f) {
          try {
            f();
            fail('Excepted exception');
          } on HttpProfileRequestError {
            // Expected.
          }
        }

        expect(requestData.error, isNotNull);
        expect(requestData.error!.isNotEmpty, true);

        // Some data is available even if a request errored out.
        expect(r.events.length, greaterThanOrEqualTo(0));
        expect(fullRequest.requestBody!.length, greaterThanOrEqualTo(0));

        // Accessing the following properties should cause an exception for
        // requests which have encountered an error.
        expectThrows(() => requestData.contentLength);
        expectThrows(() => requestData.cookies);
        expectThrows(() => requestData.followRedirects);
        expectThrows(() => requestData.headers);
        expectThrows(() => requestData.maxRedirects);
        expectThrows(() => requestData.persistentConnection);
      } else {
        // Invoke all non-nullable getters to ensure each is present in the JSON
        // response.
        requestData.connectionInfo;
        requestData.contentLength;
        requestData.cookies;
        requestData.headers;
        expect(requestData.maxRedirects, greaterThanOrEqualTo(0));
        requestData.persistentConnection;
        // If proxyInfo is non-null, uri and port _must_ be non-null.
        if (requestData.proxyDetails != null) {
          final proxyInfo = requestData.proxyDetails!;
          expect(proxyInfo.host, true);
          expect(proxyInfo.port, true);
        }

        // Check body of request has been sent and recorded correctly.
        if (method == 'DELETE' || method == 'POST') {
          if (method == 'POST') {
            // add() was used
            expect(
              fullRequest.requestBody!,
              <int>[0, 1, 2],
            );
          } else {
            // write() was used.
            expect(
              utf8.decode(fullRequest.requestBody!),
              startsWith('$method http'),
            );
          }
        }

        if (r.isResponseComplete) {
          final responseData = r.response!;
          expect(responseData.statusCode, greaterThanOrEqualTo(100));
          expect(responseData.endTime, isNotNull);
          expect(responseData.startTime!, _isAfterOrSameAs(r.endTime!));
          expect(
            responseData.startTime!,
            _isBeforeOrSameAs(responseData.endTime!),
          );
          if (method != 'HEAD') {
            // The HEAD response has no body.
            expect(utf8.decode(fullRequest.responseBody!), method);
          }
          responseData.headers;
          responseData.compressionState;
          responseData.connectionInfo;
          responseData.contentLength;
          responseData.cookies;
          responseData.isRedirect;
          responseData.persistentConnection;
          responseData.reasonPhrase;
          responseData.redirects;
          expect(responseData.hasError, false);
          expect(responseData.error, null);
        }
      }
    }
  }
}

void hasValidHttpProfile(HttpProfile profile, String method) {
  expect(profile.requests.where((e) => e.method == method), hasLength(10));
}

Future<void> hasValidHttpCONNECTs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'CONNECT');
Future<void> hasValidHttpDELETEs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'DELETE');
Future<void> hasValidHttpGETs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'GET');
Future<void> hasValidHttpHEADs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'HEAD');
Future<void> hasValidHttpPATCHs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'PATCH');
Future<void> hasValidHttpPOSTs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'POST');
Future<void> hasValidHttpPUTs(HttpProfile profile) =>
    hasValidHttpRequests(profile, 'PUT');

void hasDefaultRequestHeaders(HttpProfile profile) {
  for (final request in profile.requests) {
    // Some requests are unable to complete due to the server closing after a
    // random delay. Don't try and inspect the request data from these
    // requests.
    if (!request.isRequestComplete) continue;
    if (!request.request!.hasError) {
      expect(request.request?.headers?['host'], isNotNull);
      expect(request.request?.headers?['user-agent'], isNotNull);
    }
  }
}

void hasCustomRequestHeaders(HttpProfile profile) {
  final requests = profile.requests.where((e) => e.method == 'GET').toList();
  for (final request in requests) {
    // Some requests are unable to complete due to the server closing after a
    // random delay. Don't try and inspect the request data from these
    // requests.
    if (!request.isRequestComplete) continue;
    if (!request.request!.hasError) {
      expect(request.request?.headers?['cookie-eater'], isNotNull);
    }
  }
}

void main([args = const <String>[]]) => IsolateTestHarness(
      'get_http_profile_lib.dart',
      args,
    ).addCustomTest((VmService service, IsolateRef isolateRef) async {
      vmService = service;
      final isolateId = isolateRef.id!;

      final httpProfile = await service.getHttpProfile(isolateId);
      expect(httpProfile.requests, hasLength(70));

      // Verify timeline events.
      await hasValidHttpCONNECTs(httpProfile);
      await hasValidHttpDELETEs(httpProfile);
      await hasValidHttpGETs(httpProfile);
      await hasValidHttpHEADs(httpProfile);
      await hasValidHttpPATCHs(httpProfile);
      await hasValidHttpPOSTs(httpProfile);
      await hasValidHttpPUTs(httpProfile);
      hasDefaultRequestHeaders(httpProfile);
      hasCustomRequestHeaders(httpProfile);
    }).run(testeeMain: testee_lib.main);

class _DateTimeMatcher extends Matcher {
  const _DateTimeMatcher(this._expected, this._condition);

  final DateTime _expected;

  final _DateTimeCondition _condition;

  @override
  Description describe(Description description) {
    return description.add('DateTime ${_condition.name} $_expected');
  }

  @override
  Description describeMismatch(
    Object? item,
    Description mismatchDescription,
    Map matchState,
    bool verbose,
  ) {
    if (item is! DateTime) return mismatchDescription;
    final difference = _condition == _DateTimeCondition.before
        ? item.difference(_expected)
        : _expected.difference(item);
    final actualRelation =
        _condition == _DateTimeCondition.before ? 'after' : 'before';
    return mismatchDescription
        .add('is ${difference.inMicroseconds} microseconds $actualRelation');
  }

  @override
  bool matches(Object? item, Map matchState) {
    if (item is! DateTime) {
      return false;
    }
    return switch (_condition) {
      _DateTimeCondition.before =>
        item.isBefore(_expected) || item.isAtSameMomentAs(_expected),
      _DateTimeCondition.after =>
        item.isAfter(_expected) || item.isAtSameMomentAs(_expected),
    };
  }
}

enum _DateTimeCondition {
  before,
  after;
}

_DateTimeMatcher _isBeforeOrSameAs(DateTime item) =>
    _DateTimeMatcher(item, _DateTimeCondition.before);
_DateTimeMatcher _isAfterOrSameAs(DateTime item) =>
    _DateTimeMatcher(item, _DateTimeCondition.after);
