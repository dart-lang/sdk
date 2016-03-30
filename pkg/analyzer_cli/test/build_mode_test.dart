// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer_cli.test.built_mode;

import 'dart:convert';

import 'package:analyzer_cli/src/build_mode.dart';
import 'package:analyzer_cli/src/driver.dart';
import 'package:analyzer_cli/src/options.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';
import 'package:typed_mock/typed_mock.dart';
import 'package:unittest/unittest.dart';

main() {
  defineReflectiveTests(WorkerLoopTest);
  defineReflectiveTests(WorkInputTest);
  defineReflectiveTests(WorkRequestTest);
}

typedef void _TestWorkerLoopAnalyze(CommandLineOptions options);

@reflectiveTest
class WorkerLoopTest {
  final _TestWorkerConnection connection = new _TestWorkerConnection();

  void setUp() {}

  test_run() {
    _setInputLine(JSON.encode({
      'arguments': [
        '--build-summary-input=/tmp/1.sum',
        '--build-summary-input=/tmp/2.sum',
        'package:foo/foo.dart|/inputs/foo/lib/foo.dart',
        'package:foo/bar.dart|/inputs/foo/lib/bar.dart'
      ],
    }));
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
    expect(connection.outputList[0], {
      'exit_code': WorkerLoop.EXIT_CODE_OK,
      'output': allOf(contains('errorSink a'), contains('errorSink a'),
          contains('outSink a'), contains('outSink b'))
    });
  }

  test_run_invalidOptions() {
    _setInputLine(JSON.encode({
      'arguments': ['--unknown-option', '/foo.dart', '/bar.dart',],
    }));
    new _TestWorkerLoop(connection).run();
    expect(connection.outputList, hasLength(1));
    expect(connection.outputList[0],
        {'exit_code': WorkerLoop.EXIT_CODE_ERROR, 'output': anything});
  }

  test_run_invalidRequest_noArgumentsInputs() {
    _setInputLine('{}');
    new _TestWorkerLoop(connection).run();
    expect(connection.outputList, hasLength(1));
    expect(connection.outputList[0],
        {'exit_code': WorkerLoop.EXIT_CODE_ERROR, 'output': anything});
  }

  test_run_invalidRequest_notJson() {
    _setInputLine('not a JSON string');
    new _TestWorkerLoop(connection).run();
    expect(connection.outputList, hasLength(1));
    expect(connection.outputList[0],
        {'exit_code': WorkerLoop.EXIT_CODE_ERROR, 'output': anything});
  }

  test_run_stopAtEOF() {
    when(connection.readLineSync()).thenReturnList([null]);
    new _TestWorkerLoop(connection).run();
  }

  void _setInputLine(String line) {
    when(connection.readLineSync()).thenReturnList([line, null]);
  }
}

@reflectiveTest
class WorkInputTest {
  test_fromJson() {
    WorkInput input = new WorkInput.fromJson({
      'path': '/my/path',
      'digest': [1, 2, 3, 4, 5]
    });
    expect(input.path, '/my/path');
    expect(input.digest, <int>[1, 2, 3, 4, 5]);
  }

  test_fromJson_digest_isMissing() {
    WorkInput input = new WorkInput.fromJson({'path': '/my/path',});
    expect(input.path, '/my/path');
    expect(input.digest, <int>[]);
  }

  test_fromJson_digest_isNotList() {
    expect(() {
      new WorkInput.fromJson({'path': '/my/path', 'digest': 0});
    }, throwsArgumentError);
  }

  test_fromJson_digest_isNotListOfInt() {
    expect(() {
      new WorkInput.fromJson({
        'path': '/my/path',
        'digest': ['a', 'b', 'c']
      });
    }, throwsArgumentError);
  }

  test_fromJson_path_isMissing() {
    expect(() {
      new WorkInput.fromJson({
        'digest': [1, 2, 3, 4, 5]
      });
    }, throwsArgumentError);
  }

  test_fromJson_path_isNotString() {
    expect(() {
      new WorkInput.fromJson({
        'path': 0,
        'digest': [1, 2, 3, 4, 5]
      });
    }, throwsArgumentError);
  }

  test_toJson() {
    WorkInput input = new WorkInput('/my/path', <int>[1, 2, 3, 4, 5]);
    Map<String, Object> json = input.toJson();
    expect(json, {
      'path': '/my/path',
      'digest': [1, 2, 3, 4, 5]
    });
  }

  test_toJson_withoutDigest() {
    WorkInput input = new WorkInput('/my/path', null);
    Map<String, Object> json = input.toJson();
    expect(json, {'path': '/my/path'});
  }
}

@reflectiveTest
class WorkRequestTest {
  test_fromJson() {
    WorkRequest request = new WorkRequest.fromJson({
      'arguments': ['--arg1', '--arg2', '--arg3'],
      'inputs': [
        {
          'path': '/my/path1',
          'digest': [11, 12, 13]
        },
        {
          'path': '/my/path2',
          'digest': [21, 22, 23]
        }
      ]
    });
    expect(request.arguments, ['--arg1', '--arg2', '--arg3']);
    expect(request.inputs, hasLength(2));
    expect(request.inputs[0].path, '/my/path1');
    expect(request.inputs[0].digest, <int>[11, 12, 13]);
    expect(request.inputs[1].path, '/my/path2');
    expect(request.inputs[1].digest, <int>[21, 22, 23]);
  }

  test_fromJson_arguments_isMissing() {
    WorkRequest request = new WorkRequest.fromJson({
      'inputs': [
        {
          'path': '/my/path1',
          'digest': [11, 12, 13]
        },
      ]
    });
    expect(request.arguments, isEmpty);
    expect(request.inputs, hasLength(1));
    expect(request.inputs[0].path, '/my/path1');
    expect(request.inputs[0].digest, <int>[11, 12, 13]);
  }

  test_fromJson_arguments_isNotList() {
    expect(() {
      new WorkRequest.fromJson({'arguments': 0, 'inputs': []});
    }, throwsArgumentError);
  }

  test_fromJson_arguments_isNotListOfString() {
    expect(() {
      new WorkRequest.fromJson({
        'arguments': [0, 1, 2],
        'inputs': []
      });
    }, throwsArgumentError);
  }

  test_fromJson_inputs_isMissing() {
    WorkRequest request = new WorkRequest.fromJson({
      'arguments': ['--arg1', '--arg2', '--arg3'],
    });
    expect(request.arguments, ['--arg1', '--arg2', '--arg3']);
    expect(request.inputs, hasLength(0));
  }

  test_fromJson_inputs_isNotList() {
    expect(() {
      new WorkRequest.fromJson({
        'arguments': ['--arg1', '--arg2', '--arg3'],
        'inputs': 0
      });
    }, throwsArgumentError);
  }

  test_fromJson_inputs_isNotListOfObject() {
    expect(() {
      new WorkRequest.fromJson({
        'arguments': ['--arg1', '--arg2', '--arg3'],
        'inputs': [0, 1, 2]
      });
    }, throwsArgumentError);
  }

  test_fromJson_noArgumentsInputs() {
    expect(() {
      new WorkRequest.fromJson({});
    }, throwsArgumentError);
  }

  test_toJson() {
    WorkRequest request = new WorkRequest(<String>[
      '--arg1',
      '--arg2',
      '--arg3'
    ], <WorkInput>[
      new WorkInput('/my/path1', <int>[11, 12, 13]),
      new WorkInput('/my/path2', <int>[21, 22, 23])
    ]);
    Map<String, Object> json = request.toJson();
    expect(json, {
      'arguments': ['--arg1', '--arg2', '--arg3'],
      'inputs': [
        {
          'path': '/my/path1',
          'digest': [11, 12, 13]
        },
        {
          'path': '/my/path2',
          'digest': [21, 22, 23]
        }
      ]
    });
  }
}

/**
 * [WorkerConnection] mock.
 */
class _TestWorkerConnection extends TypedMock implements WorkerConnection {
  final outputList = <Map<String, Object>>[];

  @override
  void writeJson(Map<String, Object> json) {
    outputList.add(json);
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
