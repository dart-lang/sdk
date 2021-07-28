// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:http/http.dart' as http;
import 'package:process/process.dart';
import 'package:test/test.dart';

/// A [Matcher] that check that the given [Response] has an expected identifier
/// and has an error.  The error code may optionally be checked.
Matcher isResponseFailure(String id, [RequestErrorCode? code]) =>
    _IsResponseFailure(id, code);

/// A [Matcher] that check that the given [Response] has an expected identifier
/// and no error.
Matcher isResponseSuccess(String id) => _IsResponseSuccess(id);

class MockHttpClient extends http.BaseClient {
  late Future<http.Response> Function(http.BaseRequest request) sendHandler;
  int sendHandlerCalls = 0;
  bool wasClosed = false;

  @override
  void close() {
    wasClosed = true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (wasClosed) {
      throw Exception('get() called after close()');
    }

    return sendHandler(request)
        .then((resp) => http.StreamedResponse(
            Stream.value(resp.body.codeUnits), resp.statusCode))
        .whenComplete(() => sendHandlerCalls++);
  }
}

class MockProcessManager implements ProcessManager {
  FutureOr<ProcessResult> Function(List<String> command,
          {String? dir, Map<String, String>? env})? runHandler =
      (command, {dir, env}) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  Future<ProcessResult> run(
    List<dynamic> command, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    Encoding stdoutEncoding = systemEncoding,
    Encoding stderrEncoding = systemEncoding,
  }) async {
    return runHandler!(command.cast<String>(),
        dir: workingDirectory, env: environment);
  }
}

class MockSource implements Source {
  @override
  final String fullName;

  MockSource({
    this.fullName = 'mocked.dart',
  });

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  String toString() => fullName;
}

class StringTypedMock {
  final String? _toString;

  StringTypedMock(this._toString);

  @override
  String toString() {
    return _toString ?? super.toString();
  }
}

/// A [Matcher] that check that there are no `error` in a given [Response].
class _IsResponseFailure extends Matcher {
  final String _id;
  final RequestErrorCode? _code;

  _IsResponseFailure(this._id, this._code);

  @override
  Description describe(Description description) {
    description =
        description.add('response with identifier "$_id" and an error');
    var code = _code;
    if (code != null) {
      description = description.add(' with code ${code.name}');
    }
    return description;
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    Response response = item;
    var id = response.id;
    var error = response.error;
    mismatchDescription.add('has identifier "$id"');
    if (error == null) {
      mismatchDescription.add(' and has no error');
    } else {
      mismatchDescription.add(' and has error code ${error.code.name}');
    }
    return mismatchDescription;
  }

  @override
  bool matches(item, Map matchState) {
    Response response = item;
    var error = response.error;
    if (response.id != _id || error == null) {
      return false;
    }
    if (_code != null && error.code != _code) {
      return false;
    }
    return true;
  }
}

/// A [Matcher] that check that there are no `error` in a given [Response].
class _IsResponseSuccess extends Matcher {
  final String _id;

  _IsResponseSuccess(this._id);

  @override
  Description describe(Description description) {
    return description
        .addDescriptionOf('response with identifier "$_id" and without error');
  }

  @override
  Description describeMismatch(
      item, Description mismatchDescription, Map matchState, bool verbose) {
    Response? response = item;
    if (response == null) {
      mismatchDescription.add('is null response');
    } else {
      var id = response.id;
      var error = response.error;
      mismatchDescription.add('has identifier "$id"');
      if (error != null) {
        mismatchDescription.add(' and has error $error');
      }
    }
    return mismatchDescription;
  }

  @override
  bool matches(item, Map matchState) {
    Response? response = item;
    return response != null && response.id == _id && response.error == null;
  }
}
