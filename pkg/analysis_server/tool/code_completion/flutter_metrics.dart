// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:io' as io;

import 'package:analysis_server/src/utilities/flutter.dart';
import 'package:analyzer/dart/analysis/analysis_context_collection.dart';
import 'package:analyzer/dart/analysis/context_root.dart';
import 'package:analyzer/dart/analysis/results.dart';
import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';
import 'package:analyzer/diagnostic/diagnostic.dart';
import 'package:analyzer/file_system/physical_file_system.dart';
import 'package:analyzer/src/generated/engine.dart';
import 'package:args/args.dart';

/// Compute and print information about flutter packages.
Future<void> main(List<String> args) async {
  var parser = createArgParser();
  var result = parser.parse(args);

  if (validArguments(parser, result)) {
    var out = io.stdout;
    var rootPath = result.rest[0];
    out.writeln('Analyzing root: "$rootPath"');

    var computer = FlutterMetricsComputer();
    var stopwatch = Stopwatch()..start();
    await computer.compute(rootPath);
    stopwatch.stop();
    var duration = Duration(milliseconds: stopwatch.elapsedMilliseconds);
    out.writeln('');
    out.writeln('Analysis performed in $duration');
    computer.writeResults(out);
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
  return parser;
}

/// Print usage information for this tool.
void printUsage(ArgParser parser, {String error}) {
  if (error != null) {
    print(error);
    print('');
  }
  print('usage: dart flutter_metrics.dart [options] packagePath');
  print('');
  print('Compute and print information about flutter packages.');
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
    printUsage(parser, error: 'No directory path specified.');
    return false;
  }
  var rootPath = result.rest[0];
  if (!io.Directory(rootPath).existsSync()) {
    printUsage(parser, error: 'The directory "$rootPath" does not exist.');
    return false;
  }
  return true;
}

/// An object that records the data as it is being computed.
class FlutterData {
  /// The total number of widget creation expressions found.
  int totalWidgetCount = 0;

  /// A table mapping the name of a widget class to the number of times in
  /// which an instance of that class is created.
  Map<String, int> widgetCounts = {};

  /// A table mapping the name of a widget class and the name of the parent
  /// widget to the number of times the widget was created as a child of the
  /// parent.
  Map<String, Map<String, int>> parentData = {};

  /// A table mapping the name of the parent widget and the name of a widget
  /// class to the number of times the parent had a widget of the given kind.
  Map<String, Map<String, int>> childData = {};

  /// Initialize a newly created set of data to be empty.
  FlutterData();

  /// Record that an instance of the [childWidget] was created. If the instance
  /// creation expression is an argument in another widget constructor
  /// invocation, then the [parentWidget] is the name of the enclosing class.
  void recordWidgetCreation(String childWidget, String parentWidget) {
    totalWidgetCount++;
    widgetCounts[childWidget] = (widgetCounts[childWidget] ?? 0) + 1;

    if (parentWidget != null) {
      var parentMap = parentData.putIfAbsent(childWidget, () => {});
      parentMap[parentWidget] = (parentMap[parentWidget] ?? 0) + 1;

      var childMap = childData.putIfAbsent(parentWidget, () => {});
      childMap[childWidget] = (childMap[childWidget] ?? 0) + 1;
    }
  }
}

/// An object that visits a compilation unit in order to record the data being
/// collected.
class FlutterDataCollector extends RecursiveAstVisitor<void> {
  /// The data being collected.
  final FlutterData data;

  /// The object used to determine Flutter-specific features.
  Flutter flutter;

  /// The name of the most deeply widget class whose constructor invocation we
  /// are within.
  String parentWidget;

  /// Initialize a newly created collector to add data points to the given
  /// [data].
  FlutterDataCollector(this.data);

  @override
  void visitInstanceCreationExpression(InstanceCreationExpression node) {
    var previousParentWidget = parentWidget;
    if (flutter.isWidgetCreation(node)) {
      var element = node.constructorName.staticElement;
      if (element == null) {
        throw StateError(
            'Unresolved constructor name: ${node.constructorName}');
      }
      var childWidget = element.enclosingElement.name;
      if (!element.librarySource.uri
          .toString()
          .startsWith('package:flutter/')) {
        childWidget = 'user-defined';
      }
      data.recordWidgetCreation(childWidget, parentWidget);
      parentWidget = childWidget;
    }
    super.visitInstanceCreationExpression(node);
    parentWidget = previousParentWidget;
  }
}

/// An object used to compute metrics for a single file or directory.
class FlutterMetricsComputer {
  /// The resource provider used to access the files being analyzed.
  final PhysicalResourceProvider resourceProvider =
      PhysicalResourceProvider.INSTANCE;

  /// The data that was computed.
  final FlutterData data = FlutterData();

  /// Initialize a newly created metrics computer that can compute the metrics
  /// in one or more files and directories.
  FlutterMetricsComputer();

  /// Compute the metrics for the file(s) in the [rootPath].
  Future<void> compute(String rootPath) async {
    final collection = AnalysisContextCollection(
      includedPaths: [rootPath],
      resourceProvider: PhysicalResourceProvider.INSTANCE,
    );
    final collector = FlutterDataCollector(data);
    for (var context in collection.contexts) {
      await _computeInContext(context.contextRoot, collector);
    }
  }

  /// Write a report of the metrics that were computed to the [sink].
  void writeResults(StringSink sink) {
    _writeWidgetCounts(sink);
    _writeChildData(sink);
    _writeParentData(sink);
  }

  /// Compute the metrics for the files in the context [root], creating a
  /// separate context collection to prevent accumulating memory. The metrics
  /// should be captured in the [collector].
  Future<void> _computeInContext(
      ContextRoot root, FlutterDataCollector collector) async {
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
            print('');
            print('File $filePath skipped because of an internal error.');
            continue;
          } else if (resolvedUnitResult.state != ResultState.VALID) {
            print('');
            print('File $filePath skipped because it could not be analyzed.');
            continue;
          } else if (hasError(resolvedUnitResult)) {
            print('');
            print('File $filePath skipped due to errors:');
            for (var error in resolvedUnitResult.errors) {
              print('  ${error.toString()}');
            }
            continue;
          }

          collector.flutter = Flutter.instance;
          resolvedUnitResult.unit.accept(collector);
        } catch (exception, stackTrace) {
          print('');
          print('Exception caught analyzing: "$filePath"');
          print(exception);
          print(stackTrace);
        }
      }
    }
  }

  /// Compute and format a percentage for the fraction [value] / [total].
  String _formatPercent(int value, int total) {
    var percent = ((value / total) * 100).toStringAsFixed(1);
    if (percent.length == 3) {
      percent = '  $percent';
    } else if (percent.length == 4) {
      percent = ' $percent';
    }
    return percent;
  }

  /// Write the child data to the [sink].
  void _writeChildData(StringSink sink) {
    sink.writeln('');
    sink.writeln('The number of times a widget had a given child.');
    _writeStructureData(sink, data.childData);
  }

  /// Write the parent data to the [sink].
  void _writeParentData(StringSink sink) {
    sink.writeln('');
    sink.writeln('The number of times a widget had a given parent.');
    _writeStructureData(sink, data.parentData);
  }

  /// Write the structure data in the [structureMap] to the [sink].
  void _writeStructureData(
      StringSink sink, Map<String, Map<String, int>> structureMap) {
    var outerKeys = structureMap.keys.toList()..sort();
    for (var outerKey in outerKeys) {
      sink.writeln(outerKey);
      var innerMap = structureMap[outerKey];
      var entries = innerMap.entries.toList();
      entries.sort((first, second) => second.value.compareTo(first.value));
      var total = entries.fold(
          0, (previousValue, entry) => previousValue + entry.value);
      for (var entry in entries) {
        var percent = _formatPercent(entry.value, total);
        sink.writeln('  $percent%: ${entry.key} (${entry.value})');
      }
    }
  }

  /// Write the widget count data to the [sink].
  void _writeWidgetCounts(StringSink sink) {
    sink.writeln('');
    sink.writeln('Widget classes by frequency of instantiation');

    var total = data.totalWidgetCount;
    var entries = data.widgetCounts.entries.toList();
    entries.sort((first, second) => second.value.compareTo(first.value));
    for (var entry in entries) {
      var percent = _formatPercent(entry.value, total);
      sink.writeln('  $percent%: ${entry.key} (${entry.value})');
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
