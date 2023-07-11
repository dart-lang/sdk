// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:analysis_server/protocol/protocol.dart';
import 'package:analysis_server/protocol/protocol_generated.dart';
import 'package:analysis_server/src/utilities/process.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:http/http.dart' as http;
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

class MockProcess implements Process {
  static int killedExitCode = -1;

  final int _pid;
  final _exitCodeCompleter = Completer<int>();
  final String _stdout, _stderr;

  MockProcess(this._pid, FutureOr<int> exitCode, this._stdout, this._stderr) {
    Future.value(exitCode).then(_exitCodeCompleter.complete);
  }

  @override
  Future<int> get exitCode => _exitCodeCompleter.future;

  @override
  int get pid => _pid;

  @override
  Stream<List<int>> get stderr => Stream<List<int>>.value(utf8.encode(_stderr));

  @override
  Stream<List<int>> get stdout => Stream<List<int>>.value(utf8.encode(_stdout));

  @override
  bool kill([ProcessSignal signal = ProcessSignal.sigterm]) {
    _exitCodeCompleter.complete(killedExitCode);
    return true;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }
}

class MockProcessRunner implements ProcessRunner {
  FutureOr<Process> Function(String executable, List<String> arguments,
          {String? dir, Map<String, String>? env}) startHandler =
      (executable, arguments, {dir, env}) => throw UnimplementedError();

  @override
  dynamic noSuchMethod(Invocation invocation) {
    return super.noSuchMethod(invocation);
  }

  @override
  Future<Process> start(
    String executable,
    List<String> arguments, {
    String? workingDirectory,
    Map<String, String>? environment,
    bool includeParentEnvironment = true,
    bool runInShell = false,
    ProcessStartMode mode = ProcessStartMode.normal,
  }) async {
    return await startHandler(executable, arguments,
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
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map<Object?, Object?> matchState, bool verbose) {
    var response = item as Response;
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
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    var response = item as Response;
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
  Description describeMismatch(Object? item, Description mismatchDescription,
      Map<Object?, Object?> matchState, bool verbose) {
    var response = item as Response?;
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
  bool matches(Object? item, Map<Object?, Object?> matchState) {
    var response = item as Response?;
    return response != null && response.id == _id && response.error == null;
  }
}
