// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:convert';

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
  late LogNormalizer normalizer;
  late String inputPath;
  late Uri inputUri;
  String get inputUriString => inputUri.toString();

  void setUp() {
    normalizer = LogNormalizer();
    inputPath = path.style == path.Style.windows ? r'C:\test' : '/test';
    inputUri = path.toUri(inputPath);
  }

  void test_denormalize() {
    var root = inputPath;
    var rootFile = path.join(inputPath, 'file');
    var nestedProject1 = path.join(inputPath, 'project1');
    var nestedProject1File = path.join(nestedProject1, 'file');
    var nestedProject2 = path.join(inputPath, 'project2');
    var nestedProject2File = path.join(nestedProject2, 'file');
    var externalProject1 = path.normalize(
      path.join(inputPath, '..', 'externalProject1'),
    );
    var externalProject1File = path.join(externalProject1, 'file');

    normalizer.addReplacementsForPath(root, 'root');
    normalizer.addReplacementsForPath(nestedProject1, 'nestedProject1');
    normalizer.addReplacementsForPath(nestedProject2, 'nestedProject2');
    normalizer.addReplacementsForPath(externalProject1, 'externalProject1');

    var inputPaths = [
      root,
      rootFile,
      nestedProject1,
      nestedProject1File,
      nestedProject2,
      nestedProject2File,
      externalProject1,
      externalProject1File,
    ];

    // For each tested path, include multiple variations we'd expect to be
    // replaced
    var pathList = inputPaths
        .expand(
          // JSON encode each path in a list so that we have correct escaping
          // to ensure that we restore the correct escaping.
          (inputPath) => [
            inputPath,
            inputPath.toUpperCase(),
            inputPath.toLowerCase(),
            Uri.file(inputPath).toString(),
            Uri.file(inputPath.toUpperCase()).toString(),
            Uri.file(inputPath.toLowerCase()).toString(),
          ],
        )
        .toList();
    var testInput = {'paths': pathList};

    // Expect normalize + denormalize to be the same if we ignore case (we
    // ignore case during normalization, so we can't reverse the case to what
    // it was).
    expect(
      normalizer.denormalize(normalizer.normalize(testInput)).toLowerCase(),
      jsonEncode(testInput).toLowerCase(),
    );
  }

  @SkippedTest(reason: 'Manual benchmark for testing performance/changes')
  void test_normalize_benchmark() {
    // Total number of iterations of the test
    const numIterations = 5;

    // Number of normalize calls within each iteration. The first normalize
    // will be slower for each iteration (after any change to the replacement
    // set) because it rebuilds the regex.
    //
    // We use a relatively large number here because in reality, the regex
    // rebuilds will be very infrequent and the normalize calls will happen on
    // every single request/response.
    const numNormalizes = 100;

    const numPaths = 250;
    const payloadSizeBytes = 1024 * 1024 * 2; // 2MB

    print('Replacing $numPaths paths in payload of $payloadSizeBytes bytes');
    for (var iteration = 1; iteration <= numIterations; iteration++) {
      // Generate some paths as replacements (simulating context roots in the
      // workspace).
      var paths = <String>[];
      for (var i = 0; i < numPaths; i++) {
        var folderPath = path.join(inputPath, 'foo$i', 'bar$i');
        paths.add(folderPath);
        normalizer.addReplacementsForPath(folderPath, 'folder-$i');
      }

      // Generate a large payload that is a JSON array of maps that include
      // file paths in keys, values and list entries.
      var entries = <Map<String, Object?>>[];
      var payloadSize = 0;
      for (var i = 0; payloadSize < payloadSizeBytes; i++) {
        var filePath = paths[i % paths.length];
        var entry = {
          filePath: 'filePathAsKey',
          'filePathAsValue': filePath,
          'filePathInList': [filePath],
        };
        entries.add(entry);
        payloadSize += jsonEncode(entry).length + 2;
      }
      var input = {'entries': entries};

      // Record first normalize individually because it incurrs the cost of the
      // regex compilation.
      var stopwatch = Stopwatch()..start();
      var output = normalizer.normalize(input);
      stopwatch.stop();
      var firstCallMs = stopwatch.elapsedMilliseconds;

      // Verify some expected replacements.
      expect(output, isNotEmpty);
      expect(output, isNot(contains(anyOf(paths))));
      expect(
        output,
        isNot(contains(anyOf(paths.map((p) => Uri.file(p).toString())))),
      );
      expect(
        output,
        allOf(
          contains('{{folder-1:filePath}}'),
          contains('{{folder-2:filePath}}'),
          contains('{{folder-3:filePath}}'),
        ),
      );

      // Time additional calls once the regex is compiled.
      stopwatch
        ..reset()
        ..start();
      for (var n = 1; n < numNormalizes; n++) {
        normalizer.normalize(input);
      }
      stopwatch.stop();

      print(
        'Iteration #$iteration, First: ${firstCallMs.ceil()}ms, '
        'Rest: ${(stopwatch.elapsedMilliseconds / (numNormalizes - 1)).ceil()}ms',
      );
    }
  }

  void test_normalize_caseInsensitive() {
    normalizer.addReplacementsForPath(inputPath.toLowerCase(), 'new_value');

    var input = [inputPath.toUpperCase(), inputUriString.toUpperCase()];
    var expected = ['{{new_value:filePath}}', '{{new_value}}'];

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  void test_normalize_encoding_ampersands() {
    var encodedPath = path.join(inputPath, 'uri&encoding&quirks');
    normalizer.addReplacementsForPath(encodedPath, 'new_value');

    var uriString = Uri.file(encodedPath).toString();
    var vsCodeEncodedUriString = uriString.replaceAll('&', '%26');
    var input = {
      vsCodeEncodedUriString: 'uriAsKey',
      'uriAsValue': vsCodeEncodedUriString,
      'uriInList': [vsCodeEncodedUriString],
    };
    var expected = {
      '{{new_value}}': 'uriAsKey',
      'uriAsValue': '{{new_value}}',
      'uriInList': ['{{new_value}}'],
    };

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// On Windows, file URIs might have the colons in drive letters escaped:
  ///
  /// file:///C:/foo
  /// file:///C%3A/foo
  void test_normalize_encoding_colons() {
    if (path.style != path.Style.windows) return;

    normalizer.addReplacementsForPath(r'C:\test', 'new_value');

    var input = ['file:///C:/test', 'file:///C%3A/test', 'file:///C%3a/test'];
    var expected = ['{{new_value}}', '{{new_value}}', '{{new_value}}'];

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  void test_normalize_handlesPathsAndUris() {
    normalizer.addReplacementsForPath(inputPath, 'workspaceFolder0');

    var testPath = path.join(inputPath, 'a', 'b.dart');
    var testUri = Uri.file(testPath);
    var testPayload = {'filePath': testPath, 'fileUri': testUri.toString()};

    var expected = {
      'filePath': path.join('{{workspaceFolder0:filePath}}', 'a', 'b.dart'),
      'fileUri': '{{workspaceFolder0}}/a/b.dart',
    };

    expect(normalizer.normalize(testPayload), jsonEncode(expected));
  }

  void test_normalize_includesAllLspFields() {
    var rootPath = path.join(inputPath, 'rootPath');
    var rootUri = Uri.file(path.join(inputPath, 'rootUri'));
    var workspaceFolderUri = Uri.file(path.join(inputPath, 'workspaceFolder'));

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

    var input = [rootPath, rootUri.toString(), workspaceFolderUri.toString()];
    var expected = [
      '{{rootPath:filePath}}',
      '{{rootUri}}',
      '{{workspaceFolder-0}}',
    ];

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  void test_normalize_listValues() {
    normalizer.addReplacementsForPath(inputPath, 'new_value');

    var testPath = path.join(inputPath, 'a', 'b.dart');
    var testUri = Uri.file(testPath).toString();
    var input = [testPath, testUri];
    var expected = [
      path.join('{{new_value:filePath}}', 'a', 'b.dart'),
      '{{new_value}}/a/b.dart',
    ];

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  void test_normalize_mapKeys() {
    normalizer.addReplacementsForPath(inputPath, 'new_value');

    var pathKey = path.join(inputPath, 'a', 'b.dart');
    var uriKey = Uri.file(pathKey).toString();
    var input = {pathKey: 'pathKey', uriKey: 'uriKey'};
    var expected = {
      path.join('{{new_value:filePath}}', 'a', 'b.dart'): 'pathKey',
      '{{new_value}}/a/b.dart': 'uriKey',
    };

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  void test_normalize_mapValues() {
    normalizer.addReplacementsForPath(inputPath, 'new_value');

    var testPath = path.join(inputPath, 'a', 'b.dart');
    var testUri = Uri.file(testPath).toString();
    var input = {'path': testPath, 'uri': testUri};
    var expected = {
      'path': path.join('{{new_value:filePath}}', 'a', 'b.dart'),
      'uri': '{{new_value}}/a/b.dart',
    };

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// When there are nested paths that have different replacements, ensure they
  /// are replaced correctly (and that the parent replacement is not made as
  /// a prefix to the child paths).
  void test_normalize_nestedPaths_posix() {
    normalizer = LogNormalizer();
    // Add nested path both before and after to ensure we handle both cases.
    normalizer.addReplacementsForPath('/root/nested1', 'n1');
    normalizer.addReplacementsForPath('/root', 'r1');
    normalizer.addReplacementsForPath('/root/nested2', 'n2');

    var input = ['/root/nested1', '/root', '/root/nested2'];
    var expected = ['{{n1:filePath}}', '{{r1:filePath}}', '{{n2:filePath}}'];

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// When there are nested paths that have different replacements, ensure they
  /// are replaced correctly (and that the parent replacement is not made as
  /// a prefix to the child paths).
  void test_normalize_nestedPaths_windows() {
    normalizer = LogNormalizer();
    // Add nested path both before and after to ensure we handle both cases.
    normalizer.addReplacementsForPath(r'C:\root\nested1', 'n1');
    normalizer.addReplacementsForPath(r'C:\root', 'r1');
    normalizer.addReplacementsForPath(r'C:\root\nested2', 'n2');

    var input = [r'C:\root\nested1', r'C:\root', r'C:\root\nested2'];
    var expected = ['{{n1:filePath}}', '{{r1:filePath}}', '{{n2:filePath}}'];

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// A replacement for `/a` should not replace substrings of other paths that
  /// contain `/a`.
  ///
  void test_normalize_overlappingPaths_posix() {
    // This only applies to posix paths because absolute Windows paths can't be
    // substrings (and prefix matches are tested by the nestedPaths tests).
    normalizer = LogNormalizer();

    normalizer.addReplacementsForPath('/ab', 'ab');
    normalizer.addReplacementsForPath('/a', 'a');
    normalizer.addReplacementsForPath('/ac', 'ac');

    var input = ['/a', '/ab', '/ac', '/abc', '/abcd', '/b/a/ab/'];
    var expected = [
      '{{a:filePath}}',
      '{{ab:filePath}}',
      '{{ac:filePath}}',
      '/abc',
      '/abcd',
      '/b/a/ab/',
    ];

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// Paths will be replaced even if they don't have a trailing path separator
  /// if they are the end of the string.
  void test_normalize_path_quoted() {
    normalizer.addReplacementsForPath(inputPath, 'replaced');

    var input = ' "$inputPath" ';
    var expected = ' "{{replaced:filePath}}" ';

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// Paths will be replaced when they have a trailing path separator.
  void test_normalize_path_quotedWithTrailingSeparator() {
    normalizer.addReplacementsForPath(inputPath, 'replaced');

    var input = ' "$inputPath${path.separator}foo" ';
    var expected = ' "{{replaced:filePath}}${path.separator}foo" ';

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// Unquoted paths will not be replaced, because we only replace full paths
  /// and require a leading quote and a trailing quote or path separator to
  /// match.
  void test_normalize_path_unquoted() {
    normalizer.addReplacementsForPath(inputPath, 'replaced');

    var input = ' $inputPath "$inputPath $inputPath${path.separator} ';
    var expected = input;

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  void test_normalize_replacesAll() {
    normalizer.addReplacementsForPath(inputPath, 'new_value');

    var input = List.filled(10, inputPath);
    var expected = List.filled(10, '{{new_value:filePath}}');

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// Uris will be replaced without a trailing uri separator if they are the
  /// end of the string.
  void test_normalize_uri_quoted() {
    normalizer.addReplacementsForPath(inputPath, 'replaced');

    var input = inputUri.toString();
    var expected = '{{replaced}}';

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// Uris will be replaced with a trailing uri separator.
  void test_normalize_uri_quotedWithTrailingSeparator() {
    normalizer.addReplacementsForPath(inputPath, 'replaced');

    var input = '${inputUri.toString()}/foo';
    var expected = '{{replaced}}/foo';

    expect(normalizer.normalize(input), jsonEncode(expected));
  }

  /// Unquoted uris in the JSON will not be replaced, because we only replace
  /// full uris and require a leading quote and a trailing quote or uri
  /// separator to match.
  void test_normalize_uri_unquoted() {
    normalizer.addReplacementsForPath(inputPath, 'replaced');

    var input = ' $inputUri "$inputUri $inputUri/ ';
    var expected = input;

    expect(normalizer.normalize(input), jsonEncode(expected));
  }
}
