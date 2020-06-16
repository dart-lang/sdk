// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:test/test.dart';

import 'package:vm/snapshot/instruction_sizes.dart' as instruction_sizes;
import 'package:vm/snapshot/program_info.dart';

final dart2native = () {
  final sdkBin = path.dirname(Platform.executable);
  final dart2native =
      path.join(sdkBin, Platform.isWindows ? 'dart2native.bat' : 'dart2native');

  if (!File(dart2native).existsSync()) {
    throw 'Failed to locate dart2native in the SDK';
  }

  return path.canonicalize(dart2native);
}();

void main() async {
  if (!Platform.executable.contains('dart-sdk')) {
    // If we are not running from the prebuilt SDK then this test does nothing.
    return;
  }

  group('instruction-sizes', () {
    final testSource = {
      'input.dart': """
@pragma('vm:never-inline')
dynamic makeSomeClosures() {
  return [
    () => true,
    () => false,
    () => 11,
  ];
}

class A {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return true;
  }
}

class B {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return false;
  }
}

class C {
  static dynamic tornOff() async {
    return true;
  }
}

@pragma('vm:never-inline')
Function tearOff(dynamic o) {
  return o.tornOff;
}

void main(List<String> args) {
  for (var cl in makeSomeClosures()) {
    print(cl());
  }
  print(tearOff(args.isEmpty ? A() : B()));
  print(C.tornOff);
}
"""
    };

    // Almost exactly the same source as above, but with few modifications
    // marked with a 'modified' comment.
    final testSourceModified = {
      'input.dart': """
@pragma('vm:never-inline')
dynamic makeSomeClosures() {
  return [
    () => true,
    () => false,
    () => 11,
    () => {},  // modified
  ];
}

class A {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    for (var cl in makeSomeClosures()) {  // modified
      print(cl());                        // modified
    }                                     // modified
    return true;
  }
}

class B {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return false;
  }
}

class C {
  static dynamic tornOff() async {
    return true;
  }
}

@pragma('vm:never-inline')
Function tearOff(dynamic o) {
  return o.tornOff;
}

void main(List<String> args) {
  // modified
  print(tearOff(args.isEmpty ? A() : B()));
  print(C.tornOff);
}
"""
    };

    final testSourceModified2 = {
      'input.dart': """
@pragma('vm:never-inline')
dynamic makeSomeClosures() {
  return [
    () => 0,
  ];
}

class A {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return true;
  }
}

class B {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return false;
  }
}

class C {
  static dynamic tornOff() async {
    return true;
  }
}

@pragma('vm:never-inline')
Function tearOff(dynamic o) {
  return o.tornOff;
}

void main(List<String> args) {
  for (var cl in makeSomeClosures()) {
    print(cl());
  }
  print(tearOff(args.isEmpty ? A() : B()));
  print(C.tornOff);
}
"""
    };

    test('basic-parsing', () async {
      await withSymbolSizes('basic-parsing', testSource, (sizesJson) async {
        final symbols = await instruction_sizes.load(File(sizesJson));
        expect(symbols, isNotNull,
            reason: 'Sizes file was successfully parsed');
        expect(symbols.length, greaterThan(0),
            reason: 'Sizes file is non-empty');

        // Check for duplicated symbols (using both raw and scrubbed names).
        // Maps below contain mappings library-uri -> class-name -> names.
        final symbolRawNames = <String, Map<String, Set<String>>>{};
        final symbolScrubbedNames = <String, Map<String, Set<String>>>{};

        Set<String> getSetOfNames(Map<String, Map<String, Set<String>>> map,
            String libraryUri, String className) {
          return map
              .putIfAbsent(libraryUri ?? '', () => {})
              .putIfAbsent(className ?? '', () => {});
        }

        for (var sym in symbols) {
          expect(
              getSetOfNames(symbolRawNames, sym.libraryUri, sym.className)
                  .add(sym.name.raw),
              isTrue,
              reason:
                  'All symbols should have unique names (within libraries): ${sym.name.raw}');
          expect(
              getSetOfNames(symbolScrubbedNames, sym.libraryUri, sym.className)
                  .add(sym.name.scrubbed),
              isTrue,
              reason: 'Scrubbing the name should not make it non-unique');
        }

        // Check for expected names which should appear in the output.
        final inputDartSymbolNames =
            symbolScrubbedNames['package:input/input.dart'];
        expect(inputDartSymbolNames, isNotNull,
            reason: 'Symbols from input.dart are included into sizes output');

        expect(inputDartSymbolNames[''], isNotNull,
            reason: 'Should include top-level members from input.dart');
        expect(inputDartSymbolNames[''], contains('makeSomeClosures'));
        final closures = inputDartSymbolNames[''].where(
            (name) => name.startsWith('makeSomeClosures.<anonymous closure'));
        expect(closures.length, 3,
            reason: 'There are three closures inside makeSomeClosure');

        expect(inputDartSymbolNames['A'], isNotNull,
            reason: 'Should include class A members from input.dart');
        expect(inputDartSymbolNames['A'], contains('tornOff'));
        expect(inputDartSymbolNames['A'], contains('[tear-off] tornOff'));
        expect(inputDartSymbolNames['A'],
            contains('[tear-off-extractor] get:tornOff'));

        expect(inputDartSymbolNames['B'], isNotNull,
            reason: 'Should include class B members from input.dart');
        expect(inputDartSymbolNames['B'], contains('tornOff'));
        expect(inputDartSymbolNames['B'], contains('[tear-off] tornOff'));
        expect(inputDartSymbolNames['B'],
            contains('[tear-off-extractor] get:tornOff'));

        // Presence of async modifier should not cause tear-off name to end
        // with {body}.
        expect(inputDartSymbolNames['C'], contains('[tear-off] tornOff'));

        // Check that output does not contain '[unknown stub]'
        expect(symbolRawNames[''][''], isNot(contains('[unknown stub]')),
            reason: 'All stubs must be named');
      });
    });

    test('program-info', () async {
      await withSymbolSizes('program-info', testSource, (sizesJson) async {
        final info = await instruction_sizes.loadProgramInfo(File(sizesJson));
        expect(info.libraries, contains('dart:core'));
        expect(info.libraries, contains('dart:typed_data'));
        expect(info.libraries, contains('package:input/input.dart'));

        final inputLib = info.libraries['package:input/input.dart'];
        expect(inputLib.classes, contains('')); // Top-level class.
        expect(inputLib.classes, contains('A'));
        expect(inputLib.classes, contains('B'));
        expect(inputLib.classes, contains('C'));

        final topLevel = inputLib.classes[''];
        expect(topLevel.functions, contains('makeSomeClosures'));
        expect(
            topLevel.functions['makeSomeClosures'].closures.length, equals(3));

        for (var name in [
          '[tear-off] tornOff',
          'tornOff',
          'Allocate A',
          '[tear-off-extractor] get:tornOff'
        ]) {
          expect(inputLib.classes['A'].functions, contains(name));
          expect(inputLib.classes['A'].functions[name].closures, isEmpty);
        }

        for (var name in [
          '[tear-off] tornOff',
          'tornOff',
          'Allocate B',
          '[tear-off-extractor] get:tornOff'
        ]) {
          expect(inputLib.classes['B'].functions, contains(name));
          expect(inputLib.classes['B'].functions[name].closures, isEmpty);
        }

        for (var name in ['tornOff{body}', 'tornOff', '[tear-off] tornOff']) {
          expect(inputLib.classes['C'].functions, contains(name));
          expect(inputLib.classes['C'].functions[name].closures, isEmpty);
        }
      });
    });

    test('histograms', () async {
      await withSymbolSizes('histograms', testSource, (sizesJson) async {
        final info = await instruction_sizes.loadProgramInfo(File(sizesJson));
        final bySymbol =
            SizesHistogram.from(info, (size) => size, HistogramType.bySymbol);
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketing
                .bucketFor('package:input/input.dart', 'A', 'tornOff')));
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketing
                .bucketFor('package:input/input.dart', 'B', 'tornOff')));
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketing
                .bucketFor('package:input/input.dart', 'C', 'tornOff')));

        final byClass =
            SizesHistogram.from(info, (size) => size, HistogramType.byClass);
        expect(
            byClass.buckets,
            contains(byClass.bucketing.bucketFor(
                'package:input/input.dart', 'A', 'does-not-matter')));
        expect(
            byClass.buckets,
            contains(byClass.bucketing.bucketFor(
                'package:input/input.dart', 'B', 'does-not-matter')));
        expect(
            byClass.buckets,
            contains(byClass.bucketing.bucketFor(
                'package:input/input.dart', 'C', 'does-not-matter')));

        final byLibrary =
            SizesHistogram.from(info, (size) => size, HistogramType.byLibrary);
        expect(
            byLibrary.buckets,
            contains(byLibrary.bucketing.bucketFor('package:input/input.dart',
                'does-not-matter', 'does-not-matter')));

        final byPackage =
            SizesHistogram.from(info, (size) => size, HistogramType.byPackage);
        expect(
            byPackage.buckets,
            contains(byPackage.bucketing.bucketFor(
                'package:input/does-not-matter.dart',
                'does-not-matter',
                'does-not-matter')));
      });
    });

    // On Windows there is some issue with interpreting entry point URI as a package URI
    // it instead gets interpreted as a file URI - which breaks comparison. So we
    // simply ignore entry point library (main.dart).
    Map<String, dynamic> diffToJson(ProgramInfo<SymbolDiff> diff) {
      final diffJson = diff.toJson((diff) => diff.inBytes);
      final libraries = diffJson['libraries'] as Map<String, dynamic>;
      libraries.removeWhere((key, _) => key.endsWith('main.dart'));
      return diffJson;
    }

    test('diff', () async {
      await withSymbolSizes('diff-1', testSource, (sizesJson) async {
        await withSymbolSizes('diff-2', testSourceModified,
            (modifiedSizesJson) async {
          final info = await instruction_sizes.loadProgramInfo(File(sizesJson));
          final modifiedInfo =
              await instruction_sizes.loadProgramInfo(File(modifiedSizesJson));
          final diff = computeDiff(info, modifiedInfo);

          expect(
              diffToJson(diff),
              equals({
                'stubs': {},
                'libraries': {
                  'package:input/input.dart': {
                    '': {
                      'makeSomeClosures': {
                        'info': greaterThan(0), // We added code here.
                        'closures': {
                          '<anonymous closure @118>': {
                            'info': greaterThan(0),
                          },
                        },
                      },
                      'main': {
                        'info': lessThan(0), // We removed code from main.
                      },
                    },
                    'A': {
                      'tornOff': {
                        'info': greaterThan(0),
                      },
                    }
                  }
                }
              }));
        });
      });
    });

    test('diff-collapsed', () async {
      await withSymbolSizes('diff-collapsed-1', testSource, (sizesJson) async {
        await withSymbolSizes('diff-collapsed-2', testSourceModified2,
            (modifiedSizesJson) async {
          final info = await instruction_sizes.loadProgramInfo(File(sizesJson),
              collapseAnonymousClosures: true);
          final modifiedInfo = await instruction_sizes.loadProgramInfo(
              File(modifiedSizesJson),
              collapseAnonymousClosures: true);
          final diff = computeDiff(info, modifiedInfo);

          expect(
              diffToJson(diff),
              equals({
                'stubs': {},
                'libraries': {
                  'package:input/input.dart': {
                    '': {
                      'makeSomeClosures': {
                        'info': lessThan(0), // We removed code here.
                        'closures': {
                          '<anonymous closure>': {
                            'info': lessThan(0),
                          },
                        },
                      },
                    },
                  }
                }
              }));
        });
      });
    });
  });
}

Future withSymbolSizes(String prefix, Map<String, String> source,
    Future Function(String sizesJson) f) {
  return withTempDir(prefix, (dir) async {
    final outputBinary = path.join(dir, 'output.exe');
    final sizesJson = path.join(dir, 'sizes.json');
    final packages = path.join(dir, '.packages');
    final mainDart = path.join(dir, 'main.dart');

    // Create test input.
    for (var file in source.entries) {
      await File(path.join(dir, file.key)).writeAsString(file.value);
    }
    await File(packages).writeAsString('''
input:./
''');
    await File(mainDart).writeAsString('''
import 'package:input/input.dart' as input;

void main(List<String> args) => input.main(args);
''');

    // Compile input.dart to native and output instruction sizes.
    final result = await Process.run(dart2native, [
      '-o',
      outputBinary,
      '--packages=$packages',
      '--extra-gen-snapshot-options=--print_instructions_sizes_to=$sizesJson',
      mainDart,
    ]);

    expect(result.exitCode, equals(0), reason: '''
Compilation completed successfully.

stdout: ${result.stdout}
stderr: ${result.stderr}
''');
    expect(File(outputBinary).existsSync(), isTrue,
        reason: 'Output binary exists');
    expect(File(sizesJson).existsSync(), isTrue,
        reason: 'Instruction sizes output exists');

    await f(sizesJson);
  });
}

Future withTempDir(String prefix, Future Function(String dir) f) async {
  final tempDir =
      Directory.systemTemp.createTempSync('instruction-sizes-test-${prefix}');
  try {
    await f(tempDir.path);
  } finally {
    tempDir.deleteSync(recursive: true);
  }
}
