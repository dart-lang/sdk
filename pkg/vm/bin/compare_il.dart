// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a helper script which performs IL matching for AOT IL tests.
// See runtime/docs/infra/il_tests.md for more information.

import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:mirrors';

import 'package:collection/collection.dart';

import 'package:vm/testing/il_matchers.dart';

void main(List<String> args) async {
  getName = MirrorSystem.getName;

  if (args.length < 2 || args.length > 3) {
    throw 'Usage: compare_il <*_il_test.dart> <output.il> [<renames.json>]';
  }

  final testFile = args[0];
  final ilFile = args[1];
  final renamesFile = args.length == 3 ? args[2] : null;

  final rename = _loadRenames(renamesFile);
  final graphs = _loadGraphs(ilFile, rename);
  final tests = await _loadTestCases(testFile);

  Map<String, FlowGraph> findMatchingGraphs(String name, String? closureName) {
    final closureSuffix = closureName != null ? '_${rename(closureName)}' : '';
    final suffix = '_${rename(name)}${closureSuffix}';
    return graphs.entries.firstWhere((f) => f.key.contains(suffix)).value;
  }

  for (var test in tests) {
    test.run(findMatchingGraphs(test.name, test.closureName));
  }

  exit(0); // Success.
}

class TestCase {
  final String name;
  final String? closureName;
  final String phasesFilter;
  final LibraryMirror library;

  late final phases =
      phasesFilter.split(',').expand(_expandPhasePattern).toList();

  TestCase({
    required this.name,
    this.closureName,
    required this.phasesFilter,
    required this.library,
  });

  late final fullName = name + (closureName != null ? '_$closureName' : '');

  void run(Map<String, FlowGraph> graphs) {
    print('matching IL (${phases.join(', ')}) for $fullName');
    library.invoke(MirrorSystem.getSymbol('matchIL\$$fullName'),
        phases.map((phase) => graphs[phase]!).toList());
    print('... ok');
  }

  /// Parses phase filter components (same format as --compiler-passes flag).
  static List<String> _expandPhasePattern(String pattern) {
    bool printBefore = false, printAfter = false;
    switch (pattern[0]) {
      case '[':
        printBefore = true;
        break;
      case ']':
        printAfter = true;
        break;
      case '*':
        printBefore = printAfter = true;
        break;
    }

    final phaseName =
        (printBefore || printAfter) ? pattern.substring(1) : pattern;

    if (!printBefore && !printAfter) {
      printAfter = true;
    }

    return [
      if (printBefore) 'Before $phaseName',
      if (printAfter) 'After $phaseName',
    ];
  }
}

/// Extracts test cases from the given file by looking for functions
/// marked with @pragma('vm:testing:print-flow-graph', ...).
Future<Set<TestCase>> _loadTestCases(String testFile) async {
  final mirrorSystem = currentMirrorSystem();
  final library =
      await mirrorSystem.isolate.loadUri(File(testFile).absolute.uri);

  pragma? getPragma(DeclarationMirror decl, String name) => decl.metadata
      .map((m) => m.reflectee)
      .whereType<pragma>()
      .firstWhereOrNull((p) => p.name == name);

  final cases = LinkedHashSet<TestCase>(
    equals: (a, b) => a.fullName == b.fullName,
    hashCode: (a) => a.fullName.hashCode,
  );

  void processDeclaration(DeclarationMirror decl) {
    TestCase? testCase;
    pragma? p = getPragma(decl, 'vm:testing:print-flow-graph');
    if (p != null) {
      final name = MirrorSystem.getName(decl.simpleName);
      testCase = TestCase(
        name: name,
        phasesFilter: (p.options as String?) ?? 'AllocateRegisters',
        library: library,
      );
    }
    p = getPragma(decl, 'vm:testing:match-inner-flow-graph');
    if (p != null) {
      final name = MirrorSystem.getName(decl.simpleName);
      final closureName = p.options as String;
      testCase = TestCase(
        name: name,
        closureName: closureName,
        phasesFilter: 'AllocateRegisters',
        library: library,
      );
    }
    if (testCase != null) {
      final added = cases.add(testCase);
      if (!added) throw 'duplicate test case with name ${testCase.fullName}';
    }
  }

  for (var decl in library.declarations.values) {
    if (decl is ClassMirror) {
      decl.declarations.values.forEach(processDeclaration);
    } else {
      processDeclaration(decl);
    }
  }

  return cases;
}

Map<String, Map<String, FlowGraph>> _loadGraphs(String ilFile, Renamer rename) {
  final graphs = <String, Map<String, FlowGraph>>{};

  for (var graph in File(ilFile).readAsLinesSync()) {
    final m = jsonDecode(graph) as Map<String, dynamic>;
    graphs.putIfAbsent(m['f'], () => {})[m['p']] =
        FlowGraph(m['b'], m['desc'], m['flags'], rename: rename);
  }

  return graphs;
}

Renamer _loadRenames(String? renamesFile) {
  // Load renames map if present.
  if (renamesFile == null) {
    return (v) => v;
  }

  final list =
      (jsonDecode(File(renamesFile).readAsStringSync()) as List).cast<String>();

  final renamesMap = <String, String>{
    for (var i = 0; i < list.length; i += 2) list[i]: list[i + 1],
  };

  return (v) => renamesMap[v] ?? v;
}
