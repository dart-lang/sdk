// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a hacked-together client of the NNBD migration API, intended for
// early testing of the migration process.  It runs a small hardcoded set of
// packages through the migration engine and outputs statistics about the
// result of migration, as well as categories (and counts) of exceptions that
// occurred.

import 'dart:io';

import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:args/args.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:path/path.dart' as path;

import 'src/package.dart';

void main(List<String> args) async {
  ArgResults parsedArgs = parseArguments(args);

  Sdk sdk = Sdk(parsedArgs['sdk'] as String);

  warnOnNoAssertions();

  Playground playground =
      Playground(defaultPlaygroundPath, parsedArgs['clean'] as bool);

  List<Package> packages = [
    for (String package in parsedArgs['packages'] as Iterable<String>)
      SdkPackage(package),
    for (String package in parsedArgs['manual_packages'] as Iterable<String>)
      ManualPackage(package),
  ];

  var packageNames = parsedArgs['git_packages'] as Iterable<String>;
  await Future.wait(packageNames.map((n) async => packages.add(
      await GitPackage.gitPackageFactory(
          n, playground, parsedArgs['update'] as bool))));

  String categoryOfInterest =
      parsedArgs.rest.isEmpty ? null : parsedArgs.rest.single;

  var listener = _Listener(categoryOfInterest,
      printExceptionNodeOnly: parsedArgs['exception_node_only'] as bool);
  assert(listener.numExceptions == 0);
  var overallStartTime = DateTime.now();
  for (var package in packages) {
    print('Migrating $package');
    var startTime = DateTime.now();
    listener.currentPackage = package.name;
    var contextCollection = AnalysisContextCollectionImpl(
        includedPaths: package.migrationPaths, sdkPath: sdk.sdkPath);

    var files = <String>{};
    var previousExceptionCount = listener.numExceptions;
    for (var context in contextCollection.contexts) {
      var localFiles =
          context.contextRoot.analyzedFiles().where((s) => s.endsWith('.dart'));
      files.addAll(localFiles);
      var session = context.currentSession;
      LineInfo getLineInfo(String path) => session.getFile(path).lineInfo;
      var migration =
          NullabilityMigration(listener, getLineInfo, permissive: true);
      for (var file in localFiles) {
        var resolvedUnit = await session.getResolvedUnit(file);
        if (!resolvedUnit.errors.any((e) => e.severity == Severity.error)) {
          migration.prepareInput(resolvedUnit);
        } else {
          print('  Skipping $file; it has errors.');
        }
      }
      for (var file in localFiles) {
        var resolvedUnit = await session.getResolvedUnit(file);
        if (!resolvedUnit.errors.any((e) => e.severity == Severity.error)) {
          migration.processInput(resolvedUnit);
        }
      }
      for (var file in localFiles) {
        var resolvedUnit = await session.getResolvedUnit(file);
        if (!resolvedUnit.errors.any((e) => e.severity == Severity.error)) {
          migration.finalizeInput(resolvedUnit);
        }
      }
      migration.finish();
    }

    var endTime = DateTime.now();
    print('  Migrated $package in ${endTime.difference(startTime).inSeconds} '
        'seconds');
    print('  ${files.length} files found');
    var exceptionCount = listener.numExceptions - previousExceptionCount;
    print('  $exceptionCount exceptions in this package');
  }

  var overallDuration = DateTime.now().difference(overallStartTime);
  print('${packages.length} packages migrated in ${overallDuration.inSeconds} '
      'seconds');
  print('${listener.numTypesMadeNullable} types made nullable');
  print('${listener.numNullChecksAdded} null checks added');
  print('${listener.numVariablesMarkedLate} variables marked late');
  print('${listener.numInsertedCasts} casts inserted');
  print('${listener.numInsertedParenthesis} parenthesis groupings inserted');
  print('${listener.numMetaImportsAdded} meta imports added');
  print('${listener.numRequiredAnnotationsAdded} required annotations added');
  print('${listener.numDeadCodeSegmentsFound} dead code segments found');
  print('and ${listener.numOtherEdits} other edits not categorized');
  print('${listener.numExceptions} exceptions in '
      '${listener.groupedExceptions.length} categories');

  var sortedExceptions = [
    for (var entry in listener.groupedExceptions.entries)
      ExceptionCategory(entry.key, entry.value)
  ]..sort((category1, category2) => category2.count.compareTo(category1.count));
  var exceptionalPackages =
      sortedExceptions.expand((category) => category.packageNames).toSet();
  print('Packages with exceptions: $exceptionalPackages');
  print('Exception categories:');
  for (var category in sortedExceptions) {
    print('  $category');
  }

  if (categoryOfInterest == null) {
    print('\n(Note: to show stack traces & nodes for a particular failure,'
        ' rerun with a search string as an argument.)');
  }
}

ArgResults parseArguments(List<String> args) {
  ArgParser argParser = ArgParser();
  ArgResults parsedArgs;

  argParser.addFlag('clean',
      abbr: 'c',
      defaultsTo: false,
      help: 'Recursively delete the playground directory before beginning.');

  argParser.addFlag('help', abbr: 'h', help: 'Display options');

  argParser.addFlag('exception_node_only',
      defaultsTo: false,
      negatable: true,
      help: 'Only print the exception node instead of the full stack trace.');

  argParser.addFlag('update',
      abbr: 'u',
      defaultsTo: false,
      negatable: true,
      help: 'Auto-update fetched packages in the playground.');

  argParser.addOption('sdk',
      abbr: 's',
      defaultsTo: path.dirname(path.dirname(Platform.resolvedExecutable)),
      help: 'Select the root of the SDK to analyze against for this run '
          '(compiled with --nnbd).  For example: ../../xcodebuild/DebugX64NNBD/dart-sdk');

  argParser.addMultiOption(
    'git_packages',
    abbr: 'g',
    defaultsTo: [],
    help: 'Shallow-clone the given git repositories into a playground area,'
        ' run pub get on them, and migrate them.',
  );

  argParser.addMultiOption(
    'manual_packages',
    abbr: 'm',
    defaultsTo: [],
    help: 'Run migration against packages in these directories.  Does not '
        'run pub get, any git commands, or any other preparation.',
  );

  argParser.addMultiOption(
    'packages',
    abbr: 'p',
    defaultsTo: [],
    help: 'The list of SDK packages to run the migration against.',
  );

  try {
    parsedArgs = argParser.parse(args);
  } on ArgParserException {
    stderr.writeln(argParser.usage);
    exit(1);
  }
  if (parsedArgs['help'] as bool) {
    print(argParser.usage);
    exit(0);
  }

  if (parsedArgs.rest.length > 1) {
    throw 'invalid args. Specify *one* argument to get exceptions of interest.';
  }
  return parsedArgs;
}

void printWarning(String warn) {
  stderr.writeln('''
!!!
!!! Warning! $warn
!!!
''');
}

void warnOnNoAssertions() {
  try {
    assert(false);
  } catch (e) {
    return;
  }

  printWarning("You didn't --enable-asserts!");
}

class ExceptionCategory {
  final String topOfStack;
  final List<MapEntry<String, int>> exceptionCountPerPackage;

  ExceptionCategory(this.topOfStack, Map<String, int> exceptions)
      : exceptionCountPerPackage = exceptions.entries.toList()
          ..sort((e1, e2) => e2.value.compareTo(e1.value));

  int get count => exceptionCountPerPackage.length;

  List<String> get packageNames =>
      [for (var entry in exceptionCountPerPackage) entry.key];

  Iterable<String> get packageNamesAndCounts =>
      exceptionCountPerPackage.map((entry) => '${entry.key} x${entry.value}');

  String toString() => '$topOfStack (${packageNamesAndCounts.join(', ')})';
}

class _Listener implements NullabilityMigrationListener {
  /// Set this to `true` to cause just the exception nodes to be printed when
  /// `_Listener.categoryOfInterest` is non-null.  Set this to `false` to cause
  /// the full stack trace to be printed.
  final bool printExceptionNodeOnly;

  /// Set this to a non-null value to cause any exception to be printed in full
  /// if its category contains the string.
  final String categoryOfInterest;

  /// Exception mapped to a map of packages & exception counts.
  final groupedExceptions = <String, Map<String, int>>{};

  int numExceptions = 0;

  int numTypesMadeNullable = 0;

  int numVariablesMarkedLate = 0;

  int numInsertedCasts = 0;

  int numInsertedParenthesis = 0;

  int numNullChecksAdded = 0;

  int numMetaImportsAdded = 0;

  int numRequiredAnnotationsAdded = 0;

  int numDeadCodeSegmentsFound = 0;

  int numOtherEdits = 0;

  String currentPackage;

  _Listener(this.categoryOfInterest, {this.printExceptionNodeOnly = false});

  @override
  void addEdit(Source source, SourceEdit edit) {
    if (edit.replacement == '') {
      return;
    }

    if (edit.replacement.contains('!')) {
      ++numNullChecksAdded;
    }

    if (edit.replacement.contains('(')) {
      ++numInsertedParenthesis;
    }

    if (edit.replacement == '?' && edit.length == 0) {
      ++numTypesMadeNullable;
    } else if (edit.replacement == "import 'package:meta/meta.dart';\n" &&
        edit.length == 0) {
      ++numMetaImportsAdded;
    } else if (edit.replacement == 'required ' && edit.length == 0) {
      ++numRequiredAnnotationsAdded;
    } else if (edit.replacement == 'late ' && edit.length == 0) {
      ++numVariablesMarkedLate;
    } else if (edit.replacement.startsWith(' as ') && edit.length == 0) {
      ++numInsertedCasts;
    } else if ((edit.replacement == '/* ' ||
            edit.replacement == ' /*' ||
            edit.replacement == '; /*') &&
        edit.length == 0) {
      ++numDeadCodeSegmentsFound;
    } else if ((edit.replacement == '*/ ' ||
            edit.replacement == ' */' ||
            edit.replacement == ')' ||
            edit.replacement == '!' ||
            edit.replacement == '(') &&
        edit.length == 0) {
    } else {
      numOtherEdits++;
    }
  }

  @override
  void addSuggestion(String descriptions, Location location) {}

  @override
  void reportException(
      Source source, AstNode node, Object exception, StackTrace stackTrace) {
    var category = _classifyStackTrace(stackTrace.toString().split('\n'));
    String detail = '''
In file $source
While processing $node
Exception $exception
$stackTrace
''';
    if (categoryOfInterest != null && category.contains(categoryOfInterest)) {
      if (printExceptionNodeOnly) {
        print('$node');
      } else {
        print(detail);
      }
    }
    (groupedExceptions[category] ??= <String, int>{})
        .update(currentPackage, (value) => ++value, ifAbsent: () => 1);
    ++numExceptions;
  }

  String _classifyStackTrace(List<String> stackTrace) {
    for (var entry in stackTrace) {
      if (entry.contains('EdgeBuilder._unimplemented')) continue;
      if (entry.contains('_AssertionError._doThrowNew')) continue;
      if (entry.contains('_AssertionError._throwNew')) continue;
      if (entry.contains('NodeBuilder._unimplemented')) continue;
      if (entry.contains('Object.noSuchMethod')) continue;
      if (entry.contains('List.[] (dart:core-patch/growable_array.dart')) {
        continue;
      }
      return entry;
    }
    return '???';
  }
}
