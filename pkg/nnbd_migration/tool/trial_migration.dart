// Copyright (c) 2019, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This is a hacked-together client of the NNBD migration API, intended for
// early testing of the migration process.  It runs a small hardcoded set of
// packages through the migration engine and outputs statistics about the
// result of migration, as well as categories (and counts) of exceptions that
// occurred.

import 'dart:convert';
import 'dart:io';

import 'package:analyzer/src/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart';
import 'package:args/args.dart';
import 'package:nnbd_migration/nnbd_migration.dart';
import 'package:path/path.dart' as path;

main(List<String> args) async {
  ArgParser argParser = ArgParser();
  ArgResults parsedArgs;

  argParser.addFlag('help', abbr: 'h', help: 'Display options');

  argParser.addOption('sdk',
      abbr: 's',
      defaultsTo: path.dirname(path.dirname(Platform.resolvedExecutable)),
      help: 'Select the root of the SDK to analyze against for this run '
          '(compiled with --nnbd).  For example: ../../xcodebuild/DebugX64NNBD/dart-sdk');

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

  String sdkPath = path.canonicalize(parsedArgs['sdk'] as String);

  warnOnNoAssertions();
  warnOnNoSdkNnbd(sdkPath);

  String categoryOfInterest =
      parsedArgs.rest.isEmpty ? null : parsedArgs.rest.single;
  var rootUri = Platform.script.resolve('../../..');
  var listener = _Listener(categoryOfInterest);
  for (var testPath in [
    'third_party/pkg/charcode',
    'third_party/pkg/collection',
    'third_party/pkg/logging',
    'pkg/meta',
    'third_party/pkg/path',
    'third_party/pkg/term_glyph',
    'third_party/pkg/typed_data',
    'third_party/pkg/async',
    'third_party/pkg/source_span',
    'third_party/pkg/stack_trace',
    'third_party/pkg/matcher',
    'third_party/pkg/stream_channel',
    'third_party/pkg/boolean_selector',
    'third_party/pkg/test/pkgs/test_api',
  ]) {
    print('Migrating $testPath');
    var testUri = rootUri.resolve(testPath);
    var contextCollection = AnalysisContextCollectionImpl(
        includedPaths: [testUri.toFilePath()], sdkPath: sdkPath);
    var context = contextCollection.contexts.single;
    var files = context.contextRoot
        .analyzedFiles()
        .where((s) => s.endsWith('.dart'))
        .toList();
    print('  ${files.length} files found');
    var previousExceptionCount = listener.numExceptions;
    var migration = NullabilityMigration(listener, permissive: true);
    for (var file in files) {
      var resolvedUnit = await context.currentSession.getResolvedUnit(file);
      migration.prepareInput(resolvedUnit);
    }
    for (var file in files) {
      var resolvedUnit = await context.currentSession.getResolvedUnit(file);
      migration.processInput(resolvedUnit);
    }
    migration.finish();
    var exceptionCount = listener.numExceptions - previousExceptionCount;
    print('  $exceptionCount exceptions in this package');
  }
  print('${listener.numTypesMadeNullable} types made nullable');
  print('${listener.numNullChecksAdded} null checks added');
  print('${listener.numMetaImportsAdded} meta imports added');
  print('${listener.numRequiredAnnotationsAdded} required annotations added');
  print('${listener.numDeadCodeSegmentsFound} dead code segments found');
  print('${listener.numExceptions} exceptions in '
      '${listener.groupedExceptions.length} categories');
  print('Exception categories:');
  var sortedExceptions = listener.groupedExceptions.entries.toList();
  sortedExceptions.sort((e1, e2) => e2.value.length.compareTo(e1.value.length));
  for (var entry in sortedExceptions) {
    print('  ${entry.key} (x${entry.value.length})');
  }

  if (categoryOfInterest == null) {
    print('\n(Note: to show stack traces & nodes for a particular failure,'
        ' rerun with a search string as an argument.)');
  }
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

void warnOnNoSdkNnbd(String sdkPath) {
  // TODO(jcollins-g): contact eng-prod for a more foolproof detection method
  String libraries = path.join(sdkPath, 'lib', 'libraries.json');
  try {
    var decodedJson = JsonDecoder().convert(File(libraries).readAsStringSync());
    if ((decodedJson['comment:1'] as String).contains('sdk_nnbd')) return;
  } on Exception {
    printWarning('Unable to determine whether this SDK supports NNBD');
    return;
  }
  printWarning('SDK at $sdkPath not compiled with --nnbd, use --sdk option');
}

class _Listener implements NullabilityMigrationListener {
  /// Set this to `true` to cause just the exception nodes to be printed when
  /// `_Listener.categoryOfInterest` is non-null.  Set this to `false` to cause
  /// the full stack trace to be printed.
  /// TODO(mfairhurst): make this a cli flag?
  static const bool printExceptionNodeOnly = false;

  /// Set this to a non-null value to cause any exception to be printed in full
  /// if its category contains the string.
  final String categoryOfInterest;

  final groupedExceptions = <String, List<String>>{};

  int numExceptions = 0;

  int numTypesMadeNullable = 0;

  int numNullChecksAdded = 0;

  int numMetaImportsAdded = 0;

  int numRequiredAnnotationsAdded = 0;

  int numDeadCodeSegmentsFound = 0;

  _Listener(this.categoryOfInterest);

  @override
  void addEdit(SingleNullabilityFix fix, SourceEdit edit) {
    if (edit.replacement == '?' && edit.length == 0) {
      ++numTypesMadeNullable;
    } else if (edit.replacement == '!' && edit.length == 0) {
      ++numNullChecksAdded;
    } else if (edit.replacement == "import 'package:meta/meta.dart';\n" &&
        edit.length == 0) {
      ++numMetaImportsAdded;
    } else if (edit.replacement == 'required ' && edit.length == 0) {
      ++numRequiredAnnotationsAdded;
    } else if ((edit.replacement == '/* ' ||
            edit.replacement == ' /*' ||
            edit.replacement == '; /*') &&
        edit.length == 0) {
      ++numDeadCodeSegmentsFound;
    } else if ((edit.replacement == '*/ ' || edit.replacement == ' */') &&
        edit.length == 0) {
      // Already counted
    } else {
      print('addEdit($fix, $edit)');
    }
  }

  @override
  void addFix(SingleNullabilityFix fix) {}

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
    (groupedExceptions[category] ??= []).add(detail);
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
