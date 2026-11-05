// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that `--no-deprecated-js-interop` is plumbed through the frontend
/// server and `compute_kernel` to the dart2js and DDC targets.
library;

import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:front_end/src/api_unstable/compiler_state.dart';
import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;
import 'package:frontend_server/compute_kernel.dart';
import 'package:frontend_server/starter.dart';
import 'package:kernel/kernel.dart' show Library, loadComponentFromBinary;
import 'package:test/test.dart';

const String _deprecatedHtmlImportError =
    "Import of deprecated JS interop library 'dart:html' is not allowed.";

/// The error for `package:js`, which re-exports `dart:js_util`.
const String _deprecatedJsUtilImportError =
    "Import of deprecated JS interop library 'dart:js_util' is not allowed.";

final Uri _sdkRoot = computePlatformBinariesLocation();

/// The build output directory, which contains outlines (such as the dart2js
/// outline) that aren't shipped in the SDK.
final Uri _buildRoot = computePlatformBinariesLocation(forceBuildDir: true);

void main() {
  late Directory tempDir;
  late File packageConfig;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('deprecated_js_interop_test');
    packageConfig = _writePackage(tempDir);
  });

  tearDown(() {
    tempDir.deleteSync(recursive: true);
  });

  group('frontend server with dartdevc target', () {
    Future<_Result> compile(String library, {bool? deprecatedJsInterop}) =>
        _compileWithFrontendServer(
          tempDir,
          packageConfig,
          library,
          deprecatedJsInterop: deprecatedJsInterop,
        );

    test(
      'selects deprecated branch of conditional import by default',
      () async {
        _Result result = await compile('conditional.dart');
        expect(result.succeeded, isTrue, reason: result.output);
        expect(result.libraries, contains('package:hello/deprecated.dart'));
        expect(result.libraries, isNot(contains('package:hello/default.dart')));
      },
    );

    test(
      'selects default branch of conditional import when disabled',
      () async {
        _Result result = await compile(
          'conditional.dart',
          deprecatedJsInterop: false,
        );
        expect(result.succeeded, isTrue, reason: result.output);
        expect(result.libraries, contains('package:hello/default.dart'));
        expect(
          result.libraries,
          isNot(contains('package:hello/deprecated.dart')),
        );
      },
    );

    test('allows unconditional deprecated import by default', () async {
      _Result result = await compile('unconditional.dart');
      expect(result.succeeded, isTrue, reason: result.output);
    });

    test('rejects unconditional deprecated import when disabled', () async {
      _Result result = await compile(
        'unconditional.dart',
        deprecatedJsInterop: false,
      );
      expect(result.succeeded, isFalse);
      expect(result.output, contains(_deprecatedHtmlImportError));
    });

    _definePackageJsTests(compile);
  });

  for (final (String target, String outline) in [
    ('ddc', 'ddc_outline.dill'),
    ('dart2js_summary', 'dart2js_outline.dill'),
  ]) {
    group('compute_kernel with $target target', () {
      Uri sdkSummary = _buildRoot.resolve(outline);

      Future<_Result> compile(
        String library, {
        bool? deprecatedJsInterop,
        InitializedCompilerState? previousState,
      }) => _computeSummary(
        tempDir,
        packageConfig,
        target,
        sdkSummary,
        library,
        deprecatedJsInterop: deprecatedJsInterop,
        previousState: previousState,
      );

      test(
        'selects deprecated branch of conditional import by default',
        () async {
          _Result result = await compile('conditional.dart');
          expect(result.succeeded, isTrue, reason: result.output);
          expect(result.libraries, contains('package:hello/deprecated.dart'));
        },
      );

      test(
        'selects default branch of conditional import when disabled',
        () async {
          _Result result = await compile(
            'conditional.dart',
            deprecatedJsInterop: false,
          );
          expect(result.succeeded, isTrue, reason: result.output);
          expect(result.libraries, contains('package:hello/default.dart'));
          expect(
            result.libraries,
            isNot(contains('package:hello/deprecated.dart')),
          );
        },
      );

      test('rejects unconditional deprecated import when disabled', () async {
        _Result result = await compile(
          'unconditional.dart',
          deprecatedJsInterop: false,
        );
        expect(result.succeeded, isFalse);
        expect(result.output, contains(_deprecatedHtmlImportError));
      });

      test('does not reuse state across different flag values', () async {
        _Result enabled = await compile('unconditional.dart');
        expect(enabled.succeeded, isTrue, reason: enabled.output);

        _Result disabled = await compile(
          'unconditional.dart',
          deprecatedJsInterop: false,
          previousState: enabled.previousState,
        );
        expect(disabled.succeeded, isFalse);
        expect(disabled.output, contains(_deprecatedHtmlImportError));
      });

      _definePackageJsTests(compile);
    });
  }
}

/// Defines tests that `package:js` is allowed by default and rejected, through
/// its re-export of `dart:js_util`, when deprecated JS interop is disabled.
void _definePackageJsTests(
  Future<_Result> Function(String library, {bool? deprecatedJsInterop}) compile,
) {
  test('allows package:js by default', () async {
    _Result result = await compile('package_js.dart');
    expect(result.succeeded, isTrue, reason: result.output);
  });

  test('rejects package:js when disabled', () async {
    _Result result = await compile(
      'package_js.dart',
      deprecatedJsInterop: false,
    );
    expect(result.succeeded, isFalse);
    expect(result.output, contains(_deprecatedJsUtilImportError));
  });
}

/// The outcome of a single compilation.
class _Result {
  final bool succeeded;

  /// The diagnostics printed during compilation.
  final String output;

  /// The import URIs of the libraries in the output dill, or empty if no dill
  /// was written.
  final List<String> libraries;

  final InitializedCompilerState? previousState;

  new(this.succeeded, this.output, this.libraries, [this.previousState]);
}

/// Returns the `--[no-]deprecated-js-interop` argument for
/// [deprecatedJsInterop], if any.
List<String> _deprecatedJsInteropArgs(bool? deprecatedJsInterop) => [
  if (deprecatedJsInterop != null)
    deprecatedJsInterop
        ? '--deprecated-js-interop'
        : '--no-deprecated-js-interop',
];

Future<_Result> _compileWithFrontendServer(
  Directory tempDir,
  File packageConfig,
  String library, {
  bool? deprecatedJsInterop,
}) async {
  File dillFile = new File('${tempDir.path}/app.dill');
  StringBuffer output = new StringBuffer();
  int exitCode = await starter([
    '--sdk-root=${_sdkRoot.toFilePath()}',
    '--incremental',
    '--platform=${_sdkRoot.resolve('ddc_outline.dill').toFilePath()}',
    '--output-dill=${dillFile.path}',
    '--packages=${packageConfig.path}',
    '--target=dartdevc',
    ..._deprecatedJsInteropArgs(deprecatedJsInterop),
    'package:hello/$library',
  ], output: output);
  return new _Result(exitCode == 0, '$output', _readLibraries(dillFile));
}

Future<_Result> _computeSummary(
  Directory tempDir,
  File packageConfig,
  String target,
  Uri sdkSummary,
  String library, {
  bool? deprecatedJsInterop,
  InitializedCompilerState? previousState,
}) async {
  File outputFile = new File('${tempDir.path}/summary.dill');
  if (outputFile.existsSync()) outputFile.deleteSync();
  StringBuffer output = new StringBuffer();
  ComputeKernelResult result = await computeKernel(
    [
      '--output=${outputFile.path}',
      '--packages-file=${packageConfig.path}',
      '--dart-sdk-summary=${sdkSummary.toFilePath()}',
      '--target=$target',
      '--summary-only',
      '--reuse-compiler-result',
      '--use-incremental-compiler',
      '--source=package:hello/$library',
      ..._deprecatedJsInteropArgs(deprecatedJsInterop),
    ],
    isWorker: true,
    outputBuffer: output,
    inputDigests: {
      sdkSummary: const [0],
    },
    previousState: previousState,
  );
  return new _Result(
    result.succeeded,
    '$output',
    _readLibraries(outputFile),
    result.previousState,
  );
}

List<String> _readLibraries(File dillFile) {
  if (!dillFile.existsSync()) return const [];
  return [
    for (Library library in loadComponentFromBinary(dillFile.path).libraries)
      '${library.importUri}',
  ];
}

/// Writes `package:hello` into [tempDir] and returns its package config, which
/// also contains the SDK's `package:js`.
File _writePackage(Directory tempDir) {
  _writeLibrary(tempDir, 'default.dart', '''
const selected = 'default';
''');
  _writeLibrary(tempDir, 'deprecated.dart', '''
import 'dart:html';
const selected = 'deprecated';
''');
  _writeLibrary(tempDir, 'conditional.dart', '''
import 'default.dart' if (dart.library.html) 'deprecated.dart';
void main() => print(selected);
''');
  _writeLibrary(tempDir, 'unconditional.dart', '''
import 'dart:html';
void main() => print(window);
''');
  _writeLibrary(tempDir, 'package_js.dart', '''
import 'package:js/js.dart';
void main() => print(allowInterop);
''');
  return new File('${tempDir.path}/.dart_tool/package_config.json')
    ..createSync(recursive: true)
    ..writeAsStringSync(
      jsonEncode({
        'configVersion': 2,
        'packages': [
          {'name': 'hello', 'rootUri': '../lib', 'languageVersion': '3.10'},
          {'name': 'js', 'rootUri': '${_packageJsLibDirectory()}'},
        ],
      }),
    );
}

/// The `lib` directory of the SDK's `package:js`, resolved through the package
/// config of this test.
Uri _packageJsLibDirectory() =>
    Isolate.resolvePackageUriSync(Uri.parse('package:js/js.dart'))!
        .resolve('.');

void _writeLibrary(Directory tempDir, String name, String contents) {
  new File('${tempDir.path}/lib/$name')
    ..createSync(recursive: true)
    ..writeAsStringSync(contents);
}
