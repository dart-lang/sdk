// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.built_mode;

import 'package:analyzer/file_system/memory_file_system.dart';
import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:bazel_worker/bazel_worker.dart';
import 'package:bazel_worker/testing.dart';
import 'package:protobuf/protobuf.dart';
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

main() {
  defineReflectiveTests(WorkerLoopTest);
}

typedef void _TestWorkerLoopAnalyze(CommandLineOptions options);

/**
 * [AnalyzerWorkerLoop] for testing.
 */
class TestAnalyzerWorkerLoop extends AnalyzerWorkerLoop {
  final _TestWorkerLoopAnalyze _analyze;

  TestAnalyzerWorkerLoop(AsyncWorkerConnection connection, [this._analyze])
      : super(new MemoryResourceProvider(), connection);

  @override
  void analyze(CommandLineOptions options) {
    if (_analyze != null) {
      _analyze(options);
    }
  }
}

@reflectiveTest
class WorkerLoopTest {
  final TestStdinAsync stdinStream = new TestStdinAsync();
  final TestStdoutStream stdoutStream = new TestStdoutStream();
  TestAsyncWorkerConnection connection;

  WorkerLoopTest() {
    connection =
        new TestAsyncWorkerConnection(this.stdinStream, this.stdoutStream);
  }

  void setUp() {}

  test_run() async {
    var request = new WorkRequest();
    request.arguments.addAll([
      '--build-summary-input=/tmp/1.sum',
      '--build-summary-input=/tmp/2.sum',
      'package:foo/foo.dart|/inputs/foo/lib/foo.dart',
      'package:foo/bar.dart|/inputs/foo/lib/bar.dart',
    ]);
    stdinStream.addInputBytes(_serializeProto(request));
    stdinStream.close();

    await new TestAnalyzerWorkerLoop(connection, (CommandLineOptions options) {
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

  test_run_invalidOptions() async {
    var request = new WorkRequest();
    request.arguments.addAll(['--unknown-option', '/foo.dart', '/bar.dart']);
    stdinStream.addInputBytes(_serializeProto(request));
    stdinStream.close();
    await new TestAnalyzerWorkerLoop(connection).run();
    expect(connection.responses, hasLength(1));

    var response = connection.responses[0];
    expect(response.exitCode, EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  test_run_invalidRequest_noArgumentsInputs() async {
    stdinStream.addInputBytes(_serializeProto(new WorkRequest()));
    stdinStream.close();

    await new TestAnalyzerWorkerLoop(connection).run();
    expect(connection.responses, hasLength(1));

    var response = connection.responses[0];
    expect(response.exitCode, EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  test_run_invalidRequest_randomBytes() async {
    stdinStream.addInputBytes([1, 2, 3]);
    stdinStream.close();
    await new TestAnalyzerWorkerLoop(connection).run();
    expect(connection.responses, hasLength(1));

    var response = connection.responses[0];
    expect(response.exitCode, EXIT_CODE_ERROR);
    expect(response.output, anything);
  }

  test_run_stopAtEOF() async {
    stdinStream.close();
    await new TestAnalyzerWorkerLoop(connection).run();
  }

  List<int> _serializeProto(GeneratedMessage message) {
    var buffer = message.writeToBuffer();

    var writer = new CodedBufferWriter();
    writer.writeInt32NoTag(buffer.length);
    writer.writeRawBytes(buffer);

    return writer.toBuffer();
  }
}
