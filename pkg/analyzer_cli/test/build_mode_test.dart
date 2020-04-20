// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:bazel_worker/testing.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveTests(WorkerLoopTest);
}

typedef _TestWorkerLoopAnalyze = void Function(CommandLineOptions options);

/// [AnalyzerWorkerLoop] for testing.
class TestAnalyzerWorkerLoop extends AnalyzerWorkerLoop {
  final _TestWorkerLoopAnalyze _analyze;

  TestAnalyzerWorkerLoop(AsyncWorkerConnection connection, [this._analyze])
      : super(MemoryResourceProvider(), connection);

  @override
  Future<void> analyze(CommandLineOptions options, inputs) async {
    if (_analyze != null) {
      _analyze(options);
    }
  }
}

@reflectiveTest
class WorkerLoopTest {
  final TestStdinAsync stdinStream = TestStdinAsync();
  final TestStdoutStream stdoutStream = TestStdoutStream();
  TestAsyncWorkerConnection connection;

  WorkerLoopTest() {
    connection = TestAsyncWorkerConnection(stdinStream, stdoutStream);
  }

  void setUp() {}

  Future<void> test_run() async {
    var request = WorkRequest();
    request.arguments.addAll([
      '--build-summary-input=/tmp/1.sum',
      '--build-summary-input=/tmp/2.sum',
      'package:foo/foo.dart|/inputs/foo/lib/foo.dart',
      'package:foo/bar.dart|/inputs/foo/lib/bar.dart',
    ]);
    stdinStream.addInputBytes(_serializeProto(request));
    stdinStream.close();

    await TestAnalyzerWorkerLoop(connection, (CommandLineOptions options) {
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
    expect(connection.responses, hasLength(1));

    var response = connection.responses[0];
    expect(response.exitCode, EXIT_CODE_OK, reason: response.output);
    expect(
        response.output,
        allOf(contains('errorSink a'), contains('errorSink a'),
            contains('outSink a'), contains('outSink b')));

    // Check that a serialized version was written to std out.
    expect(stdoutStream.writes, hasLength(1));
    expect(stdoutStream.writes[0], _serializeProto(response));
  }

  Future<void> test_run_invalidOptions() async {
    var request = WorkRequest();
    request.arguments.addAll(['--unknown-option', '/foo.dart', '/bar.dart']);
    stdinStream.addInputBytes(_serializeProto(request));
    stdinStream.close();
    await TestAnalyzerWorkerLoop(connection).run();
    expect(connection.responses, hasLength(1));

    var response = connection.responses[0];
    expect(response.exitCode, EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  Future<void> test_run_invalidRequest_noArgumentsInputs() async {
    stdinStream.addInputBytes(_serializeProto(WorkRequest()));
    stdinStream.close();

    await TestAnalyzerWorkerLoop(connection).run();
    expect(connection.responses, hasLength(1));

    var response = connection.responses[0];
    expect(response.exitCode, EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  Future<void> test_run_invalidRequest_randomBytes() async {
    stdinStream.addInputBytes([1, 2, 3]);
    stdinStream.close();
    await TestAnalyzerWorkerLoop(connection).run();
    expect(connection.responses, hasLength(1));

    var response = connection.responses[0];
    expect(response.exitCode, EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  Future<void> test_run_stopAtEOF() async {
    stdinStream.close();
    await TestAnalyzerWorkerLoop(connection).run();
  }

  List<int> _serializeProto(GeneratedMessage message) {
    var buffer = message.writeToBuffer();
    var writer = CodedBufferWriter();
    writer.writeInt32NoTag(buffer.length);

    var result = <int>[];
    result.addAll(writer.toBuffer());
    result.addAll(buffer);
    return result;
  }
}
