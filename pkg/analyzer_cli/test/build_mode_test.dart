// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.built_mode;

import 'dart:collection';
import 'dart:convert';
import 'dart:io';

import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:analyzer_cli/src/worker_protocol.pb.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

import 'utils.dart';

main() {
  defineReflectiveTests(WorkerLoopTest);
}

typedef void _TestWorkerLoopAnalyze(CommandLineOptions options);

@reflectiveTest
class WorkerLoopTest {
  final TestStdinStream stdinStream = new TestStdinStream();
  final TestStdoutStream stdoutStream = new TestStdoutStream();
  _TestWorkerConnection connection;

  WorkerLoopTest() {
    connection = new _TestWorkerConnection(this.stdinStream, this.stdoutStream);
  }

  void setUp() {}

  List<int> _serializeProto(GeneratedMessage message) {
    var buffer = message.writeToBuffer();

    var writer = new CodedBufferWriter();
    writer.writeInt32NoTag(buffer.length);
    writer.writeRawBytes(buffer);

    return writer.toBuffer();
  }

  test_run() {
    var request = new WorkRequest();
    request.arguments.addAll([
      '--build-summary-input=/tmp/1.sum',
      '--build-summary-input=/tmp/2.sum',
      'package:foo/foo.dart|/inputs/foo/lib/foo.dart',
      'package:foo/bar.dart|/inputs/foo/lib/bar.dart',
    ]);
    stdinStream.addInputBytes(_serializeProto(request));

    new _TestWorkerLoop(connection, (CommandLineOptions options) {
      expect(options.buildSummaryInputs,
          unorderedEquals(['/tmp/1.sum', '/tmp/2.sum']));
      expect(
          options.sourceFiles,
          unorderedEquals([
            'package:foo/foo.dart|/inputs/foo/lib/foo.dart',
            'package:foo/bar.dart|/inputs/foo/lib/bar.dart'
          ]));
      outSink.writeln('outSink a');
      errorSink.writeln('errorSink a');
      outSink.writeln('outSink b');
      errorSink.writeln('errorSink b');
    }).run();
    expect(connection.outputList, hasLength(1));

    var response = connection.outputList[0];
    expect(response.exitCode, WorkerLoop.EXIT_CODE_OK, reason: response.output);
    expect(
        response.output,
        allOf(contains('errorSink a'), contains('errorSink a'),
            contains('outSink a'), contains('outSink b')));

    // Check that a serialized version was written to std out.
    expect(stdoutStream.writes, hasLength(1));
    expect(stdoutStream.writes[0], _serializeProto(response));
  }

  test_run_invalidOptions() {
    var request = new WorkRequest();
    request.arguments.addAll(['--unknown-option', '/foo.dart', '/bar.dart']);
    stdinStream.addInputBytes(_serializeProto(request));
    new _TestWorkerLoop(connection).run();
    expect(connection.outputList, hasLength(1));

    var response = connection.outputList[0];
    expect(response.exitCode, WorkerLoop.EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  test_run_invalidRequest_noArgumentsInputs() {
    stdinStream.addInputBytes(_serializeProto(new WorkRequest()));

    new _TestWorkerLoop(connection).run();
    expect(connection.outputList, hasLength(1));

    var response = connection.outputList[0];
    expect(response.exitCode, WorkerLoop.EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  test_run_invalidRequest_randomBytes() {
    stdinStream.addInputBytes([1, 2, 3]);
    new _TestWorkerLoop(connection).run();
    expect(connection.outputList, hasLength(1));

    var response = connection.outputList[0];
    expect(response.exitCode, WorkerLoop.EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  test_run_stopAtEOF() {
    stdinStream.addInputBytes([-1]);
    new _TestWorkerLoop(connection).run();
  }
}

/**
 * A [StdWorkerConnection] which records its responses.
 */
class _TestWorkerConnection extends StdWorkerConnection {
  final outputList = <WorkResponse>[];

  _TestWorkerConnection(Stdin stdinStream, Stdout stdoutStream)
      : super(stdinStream, stdoutStream);

  @override
  void writeResponse(WorkResponse response) {
    super.writeResponse(response);
    outputList.add(response);
  }
}

/**
 * [WorkerLoop] for testing.
 */
class _TestWorkerLoop extends WorkerLoop {
  final _TestWorkerLoopAnalyze _analyze;

  _TestWorkerLoop(WorkerConnection connection, [this._analyze])
      : super(connection);

  @override
  void analyze(CommandLineOptions options) {
    if (_analyze != null) {
      _analyze(options);
    }
  }
}
