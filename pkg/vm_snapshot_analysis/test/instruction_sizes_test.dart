// Copyright (c) 2020, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io';

import 'package:test/test.dart';

import 'package:vm_snapshot_analysis/instruction_sizes.dart'
    as instruction_sizes;
import 'package:vm_snapshot_analysis/program_info.dart';
import 'package:vm_snapshot_analysis/utils.dart';

import 'utils.dart';

final testSource = {
  'input.dart': """
class K {
  final value;
  const K(this.value);
}

@pragma('vm:never-inline')
dynamic makeSomeClosures() {
  return [
    () => const K(0),
    () => const K(1),
    () => 11,
  ];
}

class A {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return const K(2);
  }
}

class B {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return const K(3);
  }
}

class C {
  static dynamic tornOff() async {
    return const K(4);
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
class K {
  final value;
  const K(this.value);
}

@pragma('vm:never-inline')
dynamic makeSomeClosures() {
  return [
    () => const K(0),
    () => const K(1),
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
    return const K(2);
  }
}

class B {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return const K(3);
  }
}

class C {
  static dynamic tornOff() async {
    return const K(4);
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
class K {
  final value;
  const K(this.value);
}

@pragma('vm:never-inline')
dynamic makeSomeClosures() {
  return [
    () => const K(0),
  ];
}

class A {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return const K(2);
  }
}

class B {
  @pragma('vm:never-inline')
  dynamic tornOff() {
    return const K(3);
  }
}

class C {
  static dynamic tornOff() async {
    return const K(4);
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

extension on Histogram {
  String bucketFor(String pkg, String lib, String cls, String fun) =>
      (this.bucketInfo as Bucketing).bucketFor(pkg, lib, cls, fun);
}

void main() async {
  if (!Platform.executable.contains('dart-sdk')) {
    // If we are not running from the prebuilt SDK then this test does nothing.
    return;
  }

  group('instruction-sizes', () {
    test('basic-parsing', () async {
      await withSymbolSizes('basic-parsing', testSource, (sizesJson) async {
        final json = await loadJson(File(sizesJson));
        final symbols = instruction_sizes.fromJson(json);
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

    test('program-info-from-sizes', () async {
      await withSymbolSizes('program-info-from-sizes', testSource,
          (sizesJson) async {
        final json = await loadJson(File(sizesJson));
        final info = loadProgramInfoFromJson(json);
        expect(info.root.children, contains('dart:core'));
        expect(info.root.children, contains('dart:typed_data'));
        expect(info.root.children, contains('package:input'));

        final inputLib = info.root.children['package:input']
            .children['package:input/input.dart'];
        expect(inputLib, isNotNull);
        expect(inputLib.children, contains('')); // Top-level class.
        expect(inputLib.children, contains('A'));
        expect(inputLib.children, contains('B'));
        expect(inputLib.children, contains('C'));

        final topLevel = inputLib.children[''];
        expect(topLevel.children, contains('makeSomeClosures'));
        expect(
            topLevel.children['makeSomeClosures'].children.length, equals(3));

        for (var name in [
          '[tear-off] tornOff',
          'tornOff',
          'Allocate A',
          '[tear-off-extractor] get:tornOff'
        ]) {
          expect(inputLib.children['A'].children, contains(name));
          expect(inputLib.children['A'].children[name].children, isEmpty);
        }

        for (var name in [
          '[tear-off] tornOff',
          'tornOff',
          'Allocate B',
          '[tear-off-extractor] get:tornOff'
        ]) {
          expect(inputLib.children['B'].children, contains(name));
          expect(inputLib.children['B'].children[name].children, isEmpty);
        }

        for (var name in ['tornOff{body}', 'tornOff', '[tear-off] tornOff']) {
          expect(inputLib.children['C'].children, contains(name));
          expect(inputLib.children['C'].children[name].children, isEmpty);
        }
      });
    });

    test('histograms', () async {
      await withSymbolSizes('histograms', testSource, (sizesJson) async {
        final json = await loadJson(File(sizesJson));
        final info = loadProgramInfoFromJson(json);
        final bySymbol = computeHistogram(info, HistogramType.bySymbol);
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketFor(
                'package:input', 'package:input/input.dart', 'A', 'tornOff')));
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketFor(
                'package:input', 'package:input/input.dart', 'B', 'tornOff')));
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketFor(
                'package:input', 'package:input/input.dart', 'C', 'tornOff')));

        final byClass = computeHistogram(info, HistogramType.byClass);
        expect(
            byClass.buckets,
            contains(byClass.bucketFor('package:input',
                'package:input/input.dart', 'A', 'does-not-matter')));
        expect(
            byClass.buckets,
            contains(byClass.bucketFor('package:input',
                'package:input/input.dart', 'B', 'does-not-matter')));
        expect(
            byClass.buckets,
            contains(byClass.bucketFor('package:input',
                'package:input/input.dart', 'C', 'does-not-matter')));

        final byLibrary = computeHistogram(info, HistogramType.byLibrary);
        expect(
            byLibrary.buckets,
            contains(byLibrary.bucketFor(
                'package:input',
                'package:input/input.dart',
                'does-not-matter',
                'does-not-matter')));

        final byPackage = computeHistogram(info, HistogramType.byPackage);
        expect(
            byPackage.buckets,
            contains(byPackage.bucketFor(
                'package:input',
                'package:input/does-not-matter.dart',
                'does-not-matter',
                'does-not-matter')));
      });
    });

    test('diff', () async {
      await withSymbolSizes('diff-1', testSource, (sizesJson) async {
        await withSymbolSizes('diff-2', testSourceModified,
            (modifiedSizesJson) async {
          final infoJson = await loadJson(File(sizesJson));
          final info = loadProgramInfoFromJson(infoJson);
          final modifiedJson = await loadJson(File(modifiedSizesJson));
          final modifiedInfo = loadProgramInfoFromJson(modifiedJson);
          final diff = computeDiff(info, modifiedInfo);

          expect(
              diffToJson(diff),
              equals({
                '#type': 'library',
                '@stubs': {'#type': 'library'},
                '@unknown': {'#type': 'library'},
                'package:input': {
                  '#type': 'package',
                  'package:input/input.dart': {
                    '#type': 'library',
                    '': {
                      '#type': 'class',
                      'makeSomeClosures': {
                        '#type': 'function',
                        '#size': greaterThan(0), // We added code here.
                        '<anonymous closure @180>': {
                          '#type': 'function',
                          '#size': greaterThan(0),
                        },
                      },
                      'main': {
                        '#type': 'function',
                        '#size': lessThan(0), // We removed code from main.
                      },
                    },
                    'A': {
                      '#type': 'class',
                      'tornOff': {
                        '#type': 'function',
                        '#size': greaterThan(0),
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
          final json = await loadJson(File(sizesJson));
          final info =
              loadProgramInfoFromJson(json, collapseAnonymousClosures: true);
          final modifiedJson = await loadJson(File(modifiedSizesJson));
          final modifiedInfo = loadProgramInfoFromJson(modifiedJson,
              collapseAnonymousClosures: true);
          final diff = computeDiff(info, modifiedInfo);

          expect(
              diffToJson(diff),
              equals({
                '#type': 'library',
                '@stubs': {'#type': 'library'},
                '@unknown': {'#type': 'library'},
                'package:input': {
                  '#type': 'package',
                  'package:input/input.dart': {
                    '#type': 'library',
                    '': {
                      '#type': 'class',
                      'makeSomeClosures': {
                        '#size': lessThan(0),
                        '#type': 'function',
                        '<anonymous closure>': {
                          '#size': lessThan(0),
                          '#type': 'function'
                        }
                      }
                    }
                  }
                }
              }));
        });
      });
    });
  });

  group('v8-profile', () {
    test('program-info-from-profile', () async {
      await withV8Profile('program-info-from-profile', testSource,
          (profileJson) async {
        final infoJson = await loadJson(File(profileJson));
        final info = loadProgramInfoFromJson(infoJson);
        expect(info.root.children, contains('dart:core'));
        expect(info.root.children, contains('dart:typed_data'));
        expect(info.root.children, contains('package:input'));

        final inputLib = info.root.children['package:input']
            .children['package:input/input.dart'];
        expect(inputLib, isNotNull);
        expect(inputLib.children, contains('::')); // Top-level class.
        expect(inputLib.children, contains('A'));
        expect(inputLib.children, contains('B'));
        expect(inputLib.children, contains('C'));

        final topLevel = inputLib.children['::'];
        expect(topLevel.children, contains('makeSomeClosures'));
        expect(
            topLevel.children['makeSomeClosures'].children.values
                .where((child) => child.type == NodeType.functionNode)
                .length,
            equals(3));

        for (var name in [
          'tornOff',
          'Allocate A',
          '[tear-off-extractor] get:tornOff'
        ]) {
          expect(inputLib.children['A'].children, contains(name));
        }
        expect(inputLib.children['A'].children['tornOff'].children,
            contains('[tear-off] tornOff'));

        for (var name in [
          'tornOff',
          'Allocate B',
          '[tear-off-extractor] get:tornOff'
        ]) {
          expect(inputLib.children['B'].children, contains(name));
        }
        expect(inputLib.children['B'].children['tornOff'].children,
            contains('[tear-off] tornOff'));

        final classC = inputLib.children['C'];
        expect(classC.children, contains('tornOff'));
        for (var name in ['tornOff{body}', '[tear-off] tornOff']) {
          expect(classC.children['tornOff'].children, contains(name));
        }

        // Verify that [ProgramInfoNode] owns its corresponding snapshot [Node].
        final classesOwnedByC = info.snapshotInfo.snapshot.nodes
            .where((n) => info.snapshotInfo.ownerOf(n) == classC)
            .where((n) => n.type == 'Class')
            .map((n) => n.name);
        expect(classesOwnedByC, equals(['C']));
      });
    });

    test('histograms', () async {
      await withV8Profile('histograms', testSource, (sizesJson) async {
        final infoJson = await loadJson(File(sizesJson));
        final info = loadProgramInfoFromJson(infoJson);
        final bySymbol = computeHistogram(info, HistogramType.bySymbol);
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketFor(
                'package:input', 'package:input/input.dart', 'A', 'tornOff')));
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketFor(
                'package:input', 'package:input/input.dart', 'B', 'tornOff')));
        expect(
            bySymbol.buckets,
            contains(bySymbol.bucketFor(
                'package:input', 'package:input/input.dart', 'C', 'tornOff')));

        final byClass = computeHistogram(info, HistogramType.byClass);
        expect(
            byClass.buckets,
            contains(byClass.bucketFor('package:input',
                'package:input/input.dart', 'A', 'does-not-matter')));
        expect(
            byClass.buckets,
            contains(byClass.bucketFor('package:input',
                'package:input/input.dart', 'B', 'does-not-matter')));
        expect(
            byClass.buckets,
            contains(byClass.bucketFor('package:input',
                'package:input/input.dart', 'C', 'does-not-matter')));

        final byLibrary = computeHistogram(info, HistogramType.byLibrary);
        expect(
            byLibrary.buckets,
            contains(byLibrary.bucketFor(
                'package:input',
                'package:input/input.dart',
                'does-not-matter',
                'does-not-matter')));

        final byPackage = computeHistogram(info, HistogramType.byPackage);
        expect(
            byPackage.buckets,
            contains(byPackage.bucketFor(
                'package:input',
                'package:input/does-not-matter.dart',
                'does-not-matter',
                'does-not-matter')));
      });
    });

    test('diff', () async {
      await withV8Profile('diff-1', testSource, (profileJson) async {
        await withV8Profile('diff-2', testSourceModified,
            (modifiedProfileJson) async {
          final infoJson = await loadJson(File(profileJson));
          final info = loadProgramInfoFromJson(infoJson);
          final modifiedJson = await loadJson(File(modifiedProfileJson));
          final modifiedInfo = loadProgramInfoFromJson(modifiedJson);
          final diff = computeDiff(info, modifiedInfo);

          expect(
              diffToJson(diff, keepOnlyInputPackage: true),
              equals({
                'package:input': {
                  '#type': 'package',
                  'package:input/input.dart': {
                    '#type': 'library',
                    '::': {
                      '#type': 'class',
                      'makeSomeClosures': {
                        '#type': 'function',
                        '#size': greaterThan(0),
                        '<anonymous closure @180>': {
                          '#type': 'function',
                          '#size': greaterThan(0),
                        },
                      },
                      'main': {
                        '#type': 'function',
                        '#size': lessThan(0),
                      },
                    },
                    'A': {
                      '#type': 'class',
                      'tornOff': {
                        '#type': 'function',
                        '#size': greaterThan(0),
                      },
                    }
                  }
                }
              }));
        });
      });
    });

    test('diff-collapsed', () async {
      await withV8Profile('diff-collapsed-1', testSource, (profileJson) async {
        await withV8Profile('diff-collapsed-2', testSourceModified2,
            (modifiedProfileJson) async {
          final infoJson = await loadJson(File(profileJson));
          final info = loadProgramInfoFromJson(infoJson,
              collapseAnonymousClosures: true);
          final modifiedJson = await loadJson(File(modifiedProfileJson));
          final modifiedInfo = loadProgramInfoFromJson(modifiedJson,
              collapseAnonymousClosures: true);
          final diff = computeDiff(info, modifiedInfo);

          expect(
              diffToJson(diff, keepOnlyInputPackage: true),
              equals({
                'package:input': {
                  '#type': 'package',
                  'package:input/input.dart': {
                    '#type': 'library',
                    '#size': lessThan(0),
                    'K': {'#size': isA<int>(), '#type': 'class'},
                    '::': {
                      '#type': 'class',
                      'makeSomeClosures': {
                        '#type': 'function',
                        '#size': lessThan(0),
                        '<anonymous closure>': {
                          '#type': 'function',
                          '#size': lessThan(0),
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
        Future Function(String sizesJson) f) =>
    withFlag(prefix, source, '--print_instructions_sizes_to', f);

Future withV8Profile(String prefix, Map<String, String> source,
        Future Function(String sizesJson) f) =>
    withFlag(prefix, source, '--write_v8_snapshot_profile_to', f);

// On Windows there is some issue with interpreting entry point URI as a package URI
// it instead gets interpreted as a file URI - which breaks comparison. So we
// simply ignore entry point library (main.dart).
Map<String, dynamic> diffToJson(ProgramInfo diff,
    {bool keepOnlyInputPackage = false}) {
  final diffJson = diff.toJson();
  diffJson.removeWhere((key, _) =>
      keepOnlyInputPackage ? key != 'package:input' : key.startsWith('file:'));
  return diffJson;
}
