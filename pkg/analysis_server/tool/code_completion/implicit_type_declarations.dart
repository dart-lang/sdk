// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/src/status/pages.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/dart/element/type.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:args/args.dart';
import 'package:meta/meta.dart';

/// Compute metrics to determine which untyped variable declarations can be used
/// to imply an expected context type, i.e. the RHS of 'var string = ^' could be
/// assumed to be a [String].
Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (validArguments(parser, result)) {
    var out = io.stdout;
    var rootPath = result.rest[0];
    out.writeln('Analyzing root: "$rootPath"');

    var computer = ImpliedTypeComputer();
    var stopwatch = Stopwatch();
    stopwatch.start();
    await computer.compute(rootPath, verbose: result['verbose']);
    stopwatch.stop();

    var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
    out.writeln('Metrics computed in $duration');
    computer.writeMetrics(out);
    await out.flush();
  }
  io.exit(0);
}

/// Create a parser that can be used to parse the command-line arguments.
ArgParser createArgParser() {
  var parser = ArgParser();
  parser.addOption(
    'help',
    abbr: 'h',
    help: 'Print this help message.',
  );
  parser.addFlag(
    'verbose',
    abbr: 'v',
    help: 'Print additional information about the analysis',
    negatable: false,
  );
  return parser;
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart implicit_type_declarations.dart [options] packagePath');
  print('');
  print('Compute implicit types in field declaration locations without a '
      'specified type.');
  print('');
  print(parser.usage);
}

/// Return `true` if the command-line arguments (represented by the [result] and
/// parsed by the [parser]) are valid.
bool validArguments(ArgParser parser, ArgResults result) {
  if (result.wasParsed('help')) {
    printUsage(parser);
    return false;
  } else if (result.rest.length != 1) {
    printUsage(parser, error: 'No package path specified.');
    return false;
  }
  var rootPath = result.rest[0];
  if (!io.Directory(rootPath).existsSync()) {
    printUsage(parser, error: 'The directory "$rootPath" does not exist.');
    return false;
  }
  return true;
}

/// An object that visits a compilation unit in order to record the data used to
/// compute the metrics.
class ImpliedTypeCollector extends RecursiveAstVisitor<void> {
  /// The implied type data being collected.
  ImpliedTypeData data;

  /// Initialize a newly created collector to add data points to the given
  /// [data].
  ImpliedTypeCollector(this.data);

  void handleVariableDeclaration(VariableDeclaration node, DartType dartType) {
    // If some untyped variable declaration
    if (node.equals != null && dartType == null ||
        (dartType != null && (dartType.isDynamic || dartType.isVoid))) {
      // And if we can determine the type on the RHS of the variable declaration
      var rhsType = node.initializer?.staticType;
      if (rhsType != null && !rhsType.isDynamic) {
        // Record the name with the type.
        data.recordImpliedType(
          node.name.name,
          rhsType.getDisplayString(withNullability: false),
        );
      }
    }
  }

  @override
  void visitVariableDeclarationList(VariableDeclarationList node) {
    for (var varDecl in node.variables) {
      handleVariableDeclaration(varDecl, node.type?.type);
    }
    return null;
  }
}

/// An object used to compute metrics for a single file or directory.
class ImpliedTypeComputer {
  /// The metrics data that was computed.
  final ImpliedTypeData data = ImpliedTypeData();

  /// Initialize a newly created metrics computer that can compute the metrics
  /// in one or more files and directories.
  ImpliedTypeComputer();

  /// Compute the metrics for the file(s) in the [rootPath].
  /// If [corpus] is true, treat rootPath as a container of packages, creating
  /// a new context collection for each subdirectory.
  Future<void> compute(String rootPath, {@required bool verbose}) async {
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final collector = ImpliedTypeCollector(data);
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot, collector, verbose: verbose);
    }
  }

  /// Write a report of the metrics that were computed to the [sink].
  void writeMetrics(StringSink sink) {
    data.impliedTypesMap.forEach((String name, Map<String, int> displayStrMap) {
      var sum = 0;
      displayStrMap.forEach((String displayStr, int count) {
        sum += count;
      });
      if (sum >= 5) {
        sink.writeln('$name $sum:');
        displayStrMap.forEach((String displayStr, int count) {
          sink.writeln('  $displayStr $count ${printPercentage(count / sum)}');
        });
      }
    });
  }

  /// Compute the metrics for the files in the context [root], creating a
  /// separate context collection to prevent accumulating memory. The metrics
  /// should be captured in the [collector]. Include additional details in the
  /// output if [verbose] is `true`.
  Future<void> _computeInContext(
      ContextRoot root, ImpliedTypeCollector collector,
      {@required bool verbose}) async {
    // Create a new collection to avoid consuming large quantities of memory.
    final collection = AnalysisContextCollection(
      includedPaths: root.includedPaths.toList(),
      excludedPaths: root.excludedPaths.toList(),
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    var context = collection.contexts[0];
    for (var filePath in context.contextRoot.analyzedFiles()) {
      if (AnalysisEngine.isDartFileName(filePath)) {
        try {
          var resolvedUnitResult =
              await context.currentSession.getResolvedUnit(filePath);
          //
          // Check for errors that cause the file to be skipped.
          //
          if (resolvedUnitResult == null) {
            print('File $filePath skipped because resolved unit was null.');
            if (verbose) {
              print('');
            }
            continue;
          } else if (resolvedUnitResult.state != ResultState.VALID) {
            print('File $filePath skipped because it could not be analyzed.');
            if (verbose) {
              print('');
            }
            continue;
          } else if (hasError(resolvedUnitResult)) {
            if (verbose) {
              print('File $filePath skipped due to errors:');
              for (var error in resolvedUnitResult.errors
                  .where((e) => e.severity == Severity.error)) {
                print('  ${error.toString()}');
              }
              print('');
            } else {
              print('File $filePath skipped due to analysis errors.');
            }
            continue;
          }

          resolvedUnitResult.unit.accept(collector);
        } catch (exception, stacktrace) {
          print('Exception caught analyzing: "$filePath"');
          print(exception);
          print(stacktrace);
        }
      }
    }
  }

  /// Return `true` if the [result] contains an error.
  static bool hasError(ResolvedUnitResult result) {
    for (var error in result.errors) {
      if (error.severity == Severity.error) {
        return true;
      }
    }
    return false;
  }
}

class ImpliedTypeData {
  Map<String, Map<String, int>> impliedTypesMap = {};

  /// Record the variable name with the type.
  void recordImpliedType(String name, String displayString) {
    assert(name != null);
    assert(displayString != null);
    var nameMap = impliedTypesMap.putIfAbsent(name, () => {});
    nameMap[displayString] = (nameMap[displayString] ?? 0) + 1;
  }
}
