// Copyright (c) 2026, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Tests that `--no-deprecated-js-interop` makes imports of the deprecated JS
/// interop libraries an error, and that dart2js reports the shortest import
/// paths through which each such import is reached from the entrypoint.

import 'dart:convert';
import 'dart:typed_data';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/util/memory_compiler.dart';
import 'package:expect/async_helper.dart';
import 'package:expect/expect.dart';

/// A program in which `dart:html` is reachable through two chains (one of
/// which goes through an import cycle and is longer) and `dart:js_util`
/// through one.
const Map<String, String> _sources = {
  'main.dart': '''
import 'a.dart';

void main() => a();
''',
  'a.dart': '''
import 'b.dart';
import 'c.dart';

void a() {
  b();
  c();
}
''',
  'b.dart': '''
import 'dart:html';
import 'a.dart';

void b() => print(window);
''',
  'c.dart': '''
import 'dart:js_util';
import 'b.dart';

void c() => print(globalThis);
''',
};

/// A program in which a library that imports `dart:html` also imports the
/// entrypoint, forming an import cycle through the entrypoint.
const Map<String, String> _cycleThroughEntrypointSources = {
  'main.dart': '''
import 'a.dart';

void main() => a();
''',
  'a.dart': '''
import 'dart:html';
import 'main.dart';

void a() => print(window);
''',
};

/// The package config for [_packageSources].
final String _packageConfig = jsonEncode({
  'configVersion': 2,
  'packages': [
    for (final name in ['app', 'foo', 'bar', 'qux', 'baz', 'clean'])
      {'name': name, 'rootUri': '/$name/', 'packageUri': 'lib/'},
  ],
});

/// A program in the `app` package whose entrypoint is outside of `lib/`, and
/// that imports deprecated JS interop libraries directly, through its own
/// libraries, and through other packages.
///
/// `package:foo` reaches `dart:js_util` through a diamond of its own
/// libraries, and `package:baz` is imported by both `package:bar` and
/// `package:qux`, so its subtree is only shown once. `package:clean` is
/// imported by the entrypoint and by `package:bar` but doesn't reach any
/// deprecated JS interop library, so it isn't shown.
final Map<String, String> _packageSources = {
  '/.dart_tool/package_config.json': _packageConfig,
  '/app/web/main.dart': '''
import 'dart:html';
import 'package:app/app.dart';
import 'package:clean/clean.dart';
import 'src/view.dart';

void main() {}
''',
  '/app/web/src/view.dart': '''
import 'package:bar/bar.dart';
import 'package:qux/qux.dart';
''',
  '/app/lib/app.dart': '''
import 'src/widgets.dart';
''',
  '/app/lib/src/widgets.dart': '''
import 'package:foo/foo.dart';
''',
  '/foo/lib/foo.dart': '''
import 'src/a.dart';
import 'src/b.dart';
''',
  '/foo/lib/src/a.dart': '''
import 'c.dart';
''',
  '/foo/lib/src/b.dart': '''
import 'c.dart';
''',
  '/foo/lib/src/c.dart': '''
import 'dart:js_util';
''',
  '/bar/lib/bar.dart': '''
import 'package:baz/baz.dart';
import 'package:clean/clean.dart';
''',
  '/qux/lib/qux.dart': '''
import 'package:baz/baz.dart';
''',
  '/baz/lib/baz.dart': '''
import 'dart:svg';
''',
  '/clean/lib/clean.dart': '''
import 'dart:js_interop';
import 'src/helpers.dart';
''',
  '/clean/lib/src/helpers.dart': '''
import 'dart:async';
''',
};

/// A program whose libraries form a ladder of [layerCount] layers of two
/// libraries, where the entrypoint and each library import both libraries of
/// the next layer, and the last layer imports `dart:html`.
///
/// There are 2^[layerCount] shortest paths to `dart:html`.
Map<String, String> _ladderSources(int layerCount) {
  String importsOfLayer(int layer) => layer == layerCount
      ? "import 'dart:html';\n"
      : "import '${layer}_a.dart';\nimport '${layer}_b.dart';\n";
  return {
    'main.dart': '${importsOfLayer(0)}\nvoid main() {}\n',
    for (var layer = 0; layer < layerCount; layer++)
      for (final side in ['a', 'b'])
        '${layer}_$side.dart': importsOfLayer(layer + 1),
  };
}

void main() {
  asyncTest(() async {
    await _testDeprecatedJsInteropEnabled();
    await _testDeprecatedJsInteropDisabled();
    await _testCycleThroughEntrypoint();
    await _testDeprecatedJsInteropDisabledFromDill();
    await _testPackagesGrouped();
    await _testRepeatedSubtreesShownOnce();
    await _testPackageJs();
  });
}

Future<DiagnosticCollector> _compile(
  List<String> options, {
  Uri? entryPoint,
  Map<String, String> sources = _sources,
  Uri? packageConfig,
}) async {
  final collector = DiagnosticCollector();
  await runCompiler(
    entryPoint: entryPoint ?? Uri.parse('memory:main.dart'),
    memorySourceFiles: sources,
    diagnosticHandler: collector,
    options: options,
    packageConfig: packageConfig,
  );
  return collector;
}

Future<void> _testDeprecatedJsInteropEnabled() async {
  final collector = await _compile([]);
  Expect.isTrue(collector.errors.isEmpty, '${collector.errors}');
  Expect.isTrue(_importPathInfos(collector).isEmpty, '${collector.infos}');
}

/// The tree of import paths to deprecated JS interop libraries in [_sources].
const List<String> _sourcesTreeLines = [
  'main library',
  '└── memory:a.dart',
  '    ├── memory:b.dart',
  '    │   └── dart:html',
  '    └── memory:c.dart',
  '        └── dart:js_util',
];

Future<void> _testDeprecatedJsInteropDisabled() async {
  final collector = await _compile([Flags.noDeprecatedJsInterop]);

  _expectDeprecatedImportErrors({'dart:html', 'dart:js_util'}, collector);
  _expectImportPathInfo(_sourcesTreeLines, collector);
}

/// Checks that an import back to the entrypoint doesn't crash the compiler
/// and isn't shown as part of the tree.
Future<void> _testCycleThroughEntrypoint() async {
  final collector = await _compile([
    Flags.noDeprecatedJsInterop,
  ], sources: _cycleThroughEntrypointSources);

  _expectDeprecatedImportErrors({'dart:html'}, collector);
  _expectImportPathInfo([
    'main library',
    '└── memory:a.dart',
    '    └── dart:html',
  ], collector);
}

/// Checks that compilation fails when the deprecated JS interop imports are
/// in a `.dill` file, for which the CFE reports no errors.
Future<void> _testDeprecatedJsInteropDisabledFromDill() async {
  const dillName = 'main.dill';
  final dill = await _compileToDill(_sources, dillName);
  final collector = DiagnosticCollector();
  final result = await runCompiler(
    entryPoint: Uri.parse('memory:main.dart'),
    memorySourceFiles: {dillName: dill},
    diagnosticHandler: collector,
    options: [
      '${Flags.inputDill}=memory:$dillName',
      Flags.noDeprecatedJsInterop,
    ],
  );

  Expect.isFalse(result.isSuccess);
  Expect.listEquals([
    _unreportedImportsError(_sourcesTreeLines),
  ], collector.errors.map((error) => error.text).toList());
  Expect.isTrue(_importPathInfos(collector).isEmpty, '${collector.infos}');
}

/// Compiles [sources] to a `.dill` file named [dillName] with deprecated JS
/// interop enabled, and returns its bytes.
Future<Uint8List> _compileToDill(
  Map<String, String> sources,
  String dillName,
) async {
  final output = OutputCollector();
  final result = await runCompiler(
    entryPoint: Uri.parse('memory:main.dart'),
    memorySourceFiles: sources,
    outputProvider: output,
    options: ['${Flags.stage}=cfe', '--out=$dillName'],
  );
  Expect.isTrue(result.isSuccess);
  return Uint8List.fromList(output.binaryOutputMap.values.first.list);
}

Future<void> _testPackagesGrouped() async {
  final collector = await _compile(
    [Flags.noDeprecatedJsInterop],
    entryPoint: Uri.parse('memory:/app/web/main.dart'),
    sources: _packageSources,
    packageConfig: Uri.parse('memory:/.dart_tool/package_config.json'),
  );

  _expectDeprecatedImportErrors({
    'dart:html',
    'dart:js_util',
    'dart:svg',
  }, collector);
  _expectImportPathInfo([
    'main library',
    '├── dart:html',
    '├── package:app/app.dart',
    '│   └── package:app/src/widgets.dart',
    '│       └── package:foo',
    '│           └── dart:js_util',
    '└── memory:/app/web/src/view.dart',
    '    ├── package:bar',
    '    │   └── package:baz',
    '    │       └── dart:svg',
    '    └── package:qux',
    '        └── package:baz (see above)',
  ], collector);
}

/// Checks that the tree grows linearly with the size of the import graph, even
/// when the number of shortest paths grows exponentially.
Future<void> _testRepeatedSubtreesShownOnce({int layerCount = 20}) async {
  final collector = await _compile([
    Flags.noDeprecatedJsInterop,
  ], sources: _ladderSources(layerCount));

  _expectDeprecatedImportErrors({'dart:html'}, collector);
  final lines = _importPathInfos(collector).single.split('\n');
  // In every layer but the last, the second library lists both libraries of
  // the next layer as `(see above)`.
  final repeatedLines = lines.where((line) => line.endsWith(' (see above)'));
  Expect.equals(2 * (layerCount - 1), repeatedLines.length, '$lines');
  // The heading, the root, and four lines per layer: each library is listed
  // once with its children and once as `(see above)`, except that the first
  // layer is only imported by the root and the last layer's children are the
  // two imports of `dart:html`.
  Expect.equals(4 * layerCount + 2, lines.length, '$lines');
}

/// A program importing the deprecated `package:js`, which is resolved using
/// the SDK's package config.
const Map<String, String> _packageJsSources = {
  'main.dart': "import 'package:js/js.dart';\n\nvoid main() {}\n",
};

/// Checks that `package:js` is allowed by default and disallowed by
/// `--no-deprecated-js-interop` through its re-export of `dart:js_util`.
Future<void> _testPackageJs() async {
  final enabledCollector = await _compile([], sources: _packageJsSources);
  Expect.isTrue(enabledCollector.errors.isEmpty, '${enabledCollector.errors}');

  final collector = await _compile([
    Flags.noDeprecatedJsInterop,
  ], sources: _packageJsSources);
  _expectDeprecatedImportErrors({'dart:js_util'}, collector);
  _expectImportPathInfo([
    'main library',
    '└── package:js',
    '    └── dart:js_util',
  ], collector);
}

/// Expects that the only errors reported are for imports of the deprecated JS
/// interop libraries [uris].
void _expectDeprecatedImportErrors(
  Set<String> uris,
  DiagnosticCollector collector,
) {
  Expect.setEquals(
    uris.map(_deprecatedImportError),
    collector.errors.map((error) => error.text).toSet(),
  );
}

/// Expects that a single info reports the import paths to deprecated JS
/// interop libraries as the tree with the lines [treeLines].
void _expectImportPathInfo(
  List<String> treeLines,
  DiagnosticCollector collector,
) {
  Expect.listEquals([
    _importPathsMessage(treeLines),
  ], _importPathInfos(collector));
}

/// Returns the text of the message reporting the import paths to deprecated
/// JS interop libraries as the tree with the lines [treeLines].
String _importPathsMessage(List<String> treeLines) => [
  'Deprecated JS interop libraries are imported through:',
  for (final line in treeLines) '  $line',
].join('\n');

/// Returns the text of the infos reporting the import paths to deprecated JS
/// interop libraries.
List<String> _importPathInfos(DiagnosticCollector collector) => [
  for (final info in collector.infos)
    if (info.text.contains('imported through')) info.text,
];

/// Returns the text of the error reported by the CFE for an import of the
/// deprecated JS interop library [uri].
String _deprecatedImportError(String uri) => [
  "Import of deprecated JS interop library '$uri' is not allowed.",
  'Deprecated JS interop libraries are planned for removal in Dart 4.0.',
  _migrationHint,
].join('\n');

/// Returns the text of the error reported by dart2js for imports of
/// deprecated JS interop libraries that the CFE didn't report, reached through
/// the tree with the lines [treeLines].
String _unreportedImportsError(List<String> treeLines) => [
  'Imports of deprecated JS interop libraries are not allowed.',
  _importPathsMessage(treeLines),
  _migrationHint,
].join('\n');

/// Explains how to fix imports of deprecated JS interop libraries.
const String _migrationHint =
    "Migrate to 'package:web' and 'dart:js_interop' (see "
    'https://dart.dev/interop/js-interop/past-js-interop), or temporarily '
    "enable the 'deprecated-js-interop' option.";
