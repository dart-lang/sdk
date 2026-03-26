// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/lsp_protocol/protocol.dart' as lsp;
import 'package:analysis_server/src/session_logger/log_entry.dart';
import 'package:analysis_server/src/session_logger/log_normalizer.dart';
import 'package:language_server_protocol/protocol_generated.dart';
import 'package:language_server_protocol/protocol_special.dart';
import 'package:path/path.dart' as path;
import 'package:test/test.dart';
import 'package:test_reflective_loader/test_reflective_loader.dart';

void main() {
  defineReflectiveSuite(() {
    defineReflectiveTests(LogNormalizerTest);
  });
}

@reflectiveTest
class LogNormalizerTest {
  var inputPath = path.style == path.Style.windows ? r'C:\test' : '/test';

  @SkippedTest(reason: 'Manual benchmark for testing performance/changes')
  void test_normalize_benchmark() {
    const numIterations = 5;
    const numPaths = 250;
    const payloadSizeBytes = 1024 * 1024 * 2; // 2MB

    for (var iteration = 0; iteration < numIterations; iteration++) {
      var normalizer = LogNormalizer();

      // Generate some paths as replacements (simulating context roots in the
      // workspace).
      var paths = <String>[];
      for (var i = 0; i < numPaths; i++) {
        var folderPath = path.join(inputPath, 'foo$i', 'bar$i');
        paths.add(folderPath);
        normalizer.addPathReplacement(folderPath, '{{folder-$i}}');
      }

      // Generate a payload.
      var buffer = StringBuffer();
      for (var i = 0; buffer.length < payloadSizeBytes; i++) {
        buffer
          ..write('before')
          ..write(paths[i % paths.length])
          ..write('after');
      }

      var input = buffer.toString();
      var stopwatch = Stopwatch()..start();
      var output = normalizer.normalize(input);
      stopwatch.stop();

      expect(output, isNotEmpty);
      expect(output, isNot(contains('file:///foo')));
      expect(output, contains('{{folder-1}}'));

      print(
        'Normalizer took ${stopwatch.elapsedMilliseconds}ms to '
        'replace ${paths.length} paths in payload of ${buffer.length} bytes.',
      );
    }
  }

  void test_normalize_caseInsensitive() {
    var normalizer = LogNormalizer();
    normalizer.addPathReplacement('old_value', 'new_value');

    var input = 'x OLD_VALUE x';
    var expected = 'x new_value x';

    expect(normalizer.normalize(input), expected);
  }

  /// On Windows, file URIs might have the colons in drive letters escaped:
  ///
  /// file:///C:/foo
  /// file:///C%3A/foo
  void test_normalize_handlesEscapedColons() {
    if (path.style != path.Style.windows) return;

    var normalizer = LogNormalizer();
    normalizer.addPathReplacement(r'C:\test', 'new_value');

    var input = r'x file:///C:/test x file:///C%3A/test x file:///C%3a/test x';
    var expected = 'x new_value x new_value x new_value x';

    expect(normalizer.normalize(input), expected);
  }

  void test_normalize_handlesPathsAndUris() {
    var normalizer = LogNormalizer();

    normalizer.addPathReplacement(inputPath, 'new_value');

    var input = 'x $inputPath x ${Uri.file(inputPath)} x';
    var expected = 'x new_value x new_value x';

    expect(normalizer.normalize(input), expected);
  }

  void test_normalize_includesAllLspFields() {
    var rootPath = path.join(inputPath, 'rootPath');
    var rootUri = Uri.file(path.join(inputPath, 'rootUri'));
    var workspaceFolderUri = Uri.file(path.join(inputPath, 'workspaceFolder'));

    var normalizer = LogNormalizer();
    normalizer.addLspWorkspaceReplacements(
      Message(
        lsp.RequestMessage(
          id: Either2<int, String>.t1(0),
          jsonrpc: jsonRpcVersion,
          method: Method.initialize,
          params: lsp.InitializeParams(
            capabilities: ClientCapabilities(),
            rootPath: rootPath,
            rootUri: rootUri,
            workspaceFolders: [
              WorkspaceFolder(name: '', uri: workspaceFolderUri),
              // Include a non-file scheme to ensure we don't throw.
              WorkspaceFolder(name: '', uri: Uri.https('example.org')),
            ],
          ).toJson(),
        ).toJson(),
      ),
    );

    var input = '$rootPath$rootUri$workspaceFolderUri';
    var expected = '{{rootPath}}{{rootUri}}{{workspaceFolder-0}}';

    expect(normalizer.normalize(input), expected);
  }

  void test_normalize_replacesAll() {
    var normalizer = LogNormalizer();
    normalizer.addPathReplacement('old_value', 'new_value');

    var input = 'x old_value x' * 10;
    var expected = 'x new_value x' * 10;

    expect(normalizer.normalize(input), expected);
  }
}
