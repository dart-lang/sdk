// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

@TestOn('mac-os')
library;

import 'dart:ffi';
import 'dart:io';

import 'package:cli_util/cli_logging.dart';
import 'package:dartdev/src/core.dart';
import 'package:dartdev/src/native_assets_macos.dart';
import 'package:test/test.dart';

/// What `install_name_tool` prints when a dylib's header has no room for the
/// larger load commands.
const loadCommandsDoNotFit = 'larger updated load commands do not fit';

void main() {
  late Directory tempDir;
  late Directory libDir;

  setUp(() async {
    final rawTempDir = await Directory.systemTemp.createTemp(
      'dartdev_install_names_',
    );
    tempDir = Directory(await rawTempDir.resolveSymbolicLinks());
    libDir = await Directory('${tempDir.path}/lib').create();
  });

  tearDown(() async {
    await Process.run('chmod', ['-R', 'u+w', tempDir.path]);
    await tempDir.delete(recursive: true);
  });

  /// Links `libb.dylib` (install name `@rpath/libb.dylib`) and, if [withA] is
  /// true, `liba.dylib` that links it by that name, into [directory].
  ///
  /// Without [padA] or [padB], the dylib is linked without
  /// `-headerpad_max_install_names`, so its header has no room for a longer
  /// install name.
  Future<void> linkDylibs(
    Directory directory, {
    bool withA = true,
    bool padA = true,
    bool padB = true,
    String fileNameB = 'libb.dylib',
  }) async {
    final bSource = File('${tempDir.path}/b.c')
      ..writeAsStringSync('''
static int counter = 0;
int b_value(void) { return 21; }
int b_count(void) { return ++counter; }
''');
    final aSource = File('${tempDir.path}/a.c')
      ..writeAsStringSync('''
int b_value(void);
int b_count(void);
int a_value(void) { return b_value() * 2; }
int a_count_through_b(void) { return b_count(); }
''');
    await _run('xcrun', [
      'clang',
      '-dynamiclib',
      if (padB) '-Wl,-headerpad_max_install_names',
      '-install_name',
      '@rpath/libb.dylib',
      '-o',
      '${directory.path}/$fileNameB',
      bSource.path,
    ]);
    if (withA) {
      await _run('xcrun', [
        'clang',
        '-dynamiclib',
        if (padA) '-Wl,-headerpad_max_install_names',
        '-install_name',
        '@rpath/liba.dylib',
        '${directory.path}/$fileNameB',
        '-o',
        '${directory.path}/liba.dylib',
        aSource.path,
      ]);
    }
  }

  List<({String assetId, Uri dylib})> codeAssets(
    Directory directory, {
    bool withA = true,
    String fileNameB = 'libb.dylib',
  }) => [
    if (withA)
      (
        assetId: 'package:repro/a',
        dylib: Uri.file('${directory.path}/liba.dylib'),
      ),
    (
      assetId: 'package:repro/b',
      dylib: Uri.file('${directory.path}/$fileNameB'),
    ),
  ];

  Future<String> rewrite(
    List<({String assetId, Uri dylib})> dylibs, {
    required bool relocatable,
  }) async {
    final logger = _RecordingLogger();
    await withLogger(
      logger,
      () => rewriteInstallNames(dylibs, relocatable: relocatable),
    );
    return logger.stderrBuffer.toString();
  }

  test('sets the install names of dylibs with room', () async {
    await linkDylibs(libDir);

    final stderr = await rewrite(codeAssets(libDir), relocatable: false);

    expect(stderr, isEmpty);
    expect(
      await _installName('${libDir.path}/liba.dylib'),
      '${libDir.path}/liba.dylib',
    );
    expect(
      await _installName('${libDir.path}/libb.dylib'),
      '${libDir.path}/libb.dylib',
    );
    expect(
      await _dependencies('${libDir.path}/liba.dylib'),
      contains('${libDir.path}/libb.dylib'),
    );
  });

  test('keeps the install name of a dylib without room', () async {
    await linkDylibs(libDir, padB: false);

    final stderr = await rewrite(codeAssets(libDir), relocatable: false);

    expect(
      stderr,
      'Warning: Code asset "package:repro/b" keeps its install name '
      '"@rpath/libb.dylib", because the header of libb.dylib has no room for '
      'its new install name and dependency paths. The asset still loads. '
      'Linking the dylib with -headerpad_max_install_names avoids this.\n',
    );
    expect(
      await _installName('${libDir.path}/libb.dylib'),
      '@rpath/libb.dylib',
    );
    // The dependencies of the other dylibs are still changed.
    expect(
      await _installName('${libDir.path}/liba.dylib'),
      '${libDir.path}/liba.dylib',
    );
    expect(
      await _dependencies('${libDir.path}/liba.dylib'),
      contains('${libDir.path}/libb.dylib'),
    );

    // The VM opens both by their absolute paths, in either order, and gets
    // one copy of libb.dylib.
    final a = DynamicLibrary.open('${libDir.path}/liba.dylib');
    final b = DynamicLibrary.open('${libDir.path}/libb.dylib');
    final aValue = a.lookupFunction<Int32 Function(), int Function()>(
      'a_value',
    );
    final aCountThroughB = a.lookupFunction<Int32 Function(), int Function()>(
      'a_count_through_b',
    );
    final bCount = b.lookupFunction<Int32 Function(), int Function()>(
      'b_count',
    );
    expect(aValue(), 42);
    expect([aCountThroughB(), bCount(), aCountThroughB()], [1, 2, 3]);
  });

  test(
    'fails for a dylib without room when its dependencies do not fit',
    () async {
      await linkDylibs(libDir, padA: false, padB: false);

      await expectLater(
        rewrite(codeAssets(libDir), relocatable: false),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            allOf(
              contains('liba.dylib, also after keeping its install name'),
              contains(loadCommandsDoNotFit),
            ),
          ),
        ),
      );
    },
  );

  test('fails for a dylib without room in a directory reached through a '
      'symlink', () async {
    await linkDylibs(libDir, withA: false, padB: false);
    final linkDir = Link('${tempDir.path}/link')..createSync(libDir.path);

    await expectLater(
      rewrite(
        codeAssets(Directory(linkDir.path), withA: false),
        relocatable: false,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains(loadCommandsDoNotFit),
            isNot(contains('also after keeping its install name')),
          ),
        ),
      ),
    );
    expect(
      await _installName('${libDir.path}/libb.dylib'),
      '@rpath/libb.dylib',
    );
  });

  test('fails for a dylib without room in dart build cli', () async {
    // `@rpath/lib/<file name>` must not fit either.
    const fileNameB = 'libb_with_a_name_too_long_for_its_header.dylib';
    await linkDylibs(libDir, withA: false, padB: false, fileNameB: fileNameB);

    await expectLater(
      rewrite(
        codeAssets(libDir, withA: false, fileNameB: fileNameB),
        relocatable: true,
      ),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains('id -> @rpath/lib/$fileNameB'),
            contains(loadCommandsDoNotFit),
            isNot(contains('also after keeping its install name')),
          ),
        ),
      ),
    );
  });

  test('fails on other install_name_tool errors', () async {
    await linkDylibs(libDir, withA: false);
    // install_name_tool writes a temporary file next to the dylib.
    await _run('chmod', ['a-w', libDir.path]);

    await expectLater(
      rewrite(codeAssets(libDir, withA: false), relocatable: false),
      throwsA(
        isA<Exception>().having(
          (e) => e.toString(),
          'message',
          allOf(
            contains("can't create output file"),
            isNot(contains(loadCommandsDoNotFit)),
            isNot(contains('also after keeping its install name')),
          ),
        ),
      ),
    );
  });
}

Future<String> _run(String executable, List<String> arguments) async {
  final result = await Process.run(executable, arguments);
  if (result.exitCode != 0) {
    throw Exception(
      '$executable ${arguments.join(' ')} failed:\n'
      '${result.stdout}${result.stderr}',
    );
  }
  return result.stdout as String;
}

Future<String> _installName(String dylib) async =>
    (await _run('otool', ['-D', dylib])).trim().split('\n').last.trim();

Future<List<String>> _dependencies(String dylib) async => [
  for (final line in (await _run('otool', [
    '-L',
    dylib,
  ])).trim().split('\n').skip(1))
    line.trim().split(' (compatibility').first,
];

final class _RecordingLogger implements Logger {
  final stderrBuffer = StringBuffer();

  @override
  Ansi get ansi => Ansi(false);

  @override
  bool get isVerbose => false;

  @override
  void stderr(String message) => stderrBuffer.writeln(message);

  @override
  void stdout(String message) {}

  @override
  void trace(String message) {}

  @override
  void write(String message) {}

  @override
  void writeCharCode(int charCode) {}

  @override
  Progress progress(String message) => throw UnimplementedError();

  @override
  void flush() {}
}
