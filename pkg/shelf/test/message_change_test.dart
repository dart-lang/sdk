// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library shelf.message_change_test;

import 'package:unittest/unittest.dart';

import 'package:shelf/shelf.dart';
import 'package:shelf/src/message.dart';

import 'test_util.dart';

void main() {
  group('Request', () {
    _testChange(({headers, context}) {
      return new Request('GET', LOCALHOST_URI, headers: headers,
          context: context);
    });
  });

  group('Response', () {
    _testChange(({headers, context}) {
      return new Response.ok(null, headers: headers,
          context: context);
    });
  });
}

/// Shared test method used by [Request] and [Response] tests to validate
/// the behavior of `change` with different `headers` and `context` values.
void _testChange(Message factory({Map<String, String> headers,
  Map<String, Object> context})) {
  test('with empty headers returns indentical instance', () {
    var request = factory(headers: {'header1': 'header value 1'});
    var copy = request.change(headers: {});

    expect(copy.headers, same(request.headers));
  });

  test('with empty context returns identical instance', () {
    var request = factory(context: {'context1': 'context value 1'});
    var copy = request.change(context: {});

    expect(copy.context, same(request.context));
  });

  test('new header values are added', () {
    var request = factory(headers: {'test':'test value'});
    var copy = request.change(headers: {'test2': 'test2 value'});

    expect(copy.headers, {'test':'test value', 'test2':'test2 value'});
  });

  test('existing header values are overwritten', () {
    var request = factory(headers: {'test':'test value'});
    var copy = request.change(headers: {'test': 'new test value'});

    expect(copy.headers, {'test':'new test value'});
  });

  test('new context values are added', () {
    var request = factory(context: {'test':'test value'});
    var copy = request.change(context: {'test2': 'test2 value'});

    expect(copy.context, {'test':'test value', 'test2':'test2 value'});
  });

  test('existing context values are overwritten', () {
    var request = factory(context: {'test':'test value'});
    var copy = request.change(context: {'test': 'new test value'});

    expect(copy.context, {'test':'new test value'});
  });
}
