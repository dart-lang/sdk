// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_helper;

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/filenames.dart';

import '../memory_compiler.dart';
import 'test_data.dart';

const String DEFAULT_DATA_FILE_NAME = 'out.data';

class Arguments {
  final String filename;
  final int start;
  final int end;
  final bool loadSerializedData;
  final bool saveSerializedData;
  final String serializedDataFileName;
  final bool verbose;

  const Arguments(
      {this.filename,
      this.start,
      this.end,
      this.loadSerializedData: false,
      this.saveSerializedData: false,
      this.serializedDataFileName: DEFAULT_DATA_FILE_NAME,
      this.verbose: false});

  factory Arguments.from(List<String> arguments) {
    String filename;
    int start;
    int end;
    for (String arg in arguments) {
      if (!arg.startsWith('-')) {
        int index = int.parse(arg, onError: (_) => null);
        if (index == null) {
          filename = arg;
        } else if (start == null) {
          start = index;
        } else {
          end = index;
        }
      }
    }
    bool verbose = arguments.contains('-v');
    bool loadSerializedData = arguments.contains('-l');
    bool saveSerializedData = arguments.contains('-s');
    if (arguments.contains('--auto')) {
      File file = new File(DEFAULT_DATA_FILE_NAME);
      if (file.existsSync()) {
        loadSerializedData = true;
      } else {
        saveSerializedData = true;
      }
    }
    return new Arguments(
        filename: filename,
        start: start,
        end: end,
        verbose: verbose,
        loadSerializedData: loadSerializedData,
        saveSerializedData: saveSerializedData);
  }

  Uri get uri {
    if (filename != null) {
      return Uri.base.resolve(nativeToUriPath(filename));
    }
    return null;
  }

  Future forEachTest(SerializedData serializedData, List<Test> tests,
      TestFunction testFunction) async {
    Uri entryPoint = Uri.parse('memory:main.dart');
    int first = start ?? 0;
    int last = end ?? tests.length;

    for (int index = first; index < last; index++) {
      Test test = TESTS[index];
      List<SerializedData> dataList =
          await preserializeData(serializedData, test);
      Map<String, String> sourceFiles = <String, String>{};
      sourceFiles.addAll(test.sourceFiles);
      if (test.preserializedSourceFiles != null) {
        sourceFiles.addAll(test.preserializedSourceFiles);
      }
      if (test.unserializedSourceFiles != null) {
        sourceFiles.addAll(test.unserializedSourceFiles);
      }
      List<Uri> resolutionInputs = <Uri>[];
      for (SerializedData data in dataList) {
        data.expandMemorySourceFiles(sourceFiles);
        data.expandUris(resolutionInputs);
      }
      await testFunction(entryPoint,
          sourceFiles: sourceFiles,
          resolutionInputs: resolutionInputs,
          index: index,
          test: test,
          verbose: verbose);
    }
  }
}

typedef Future TestFunction(Uri entryPoint,
    {Map<String, String> sourceFiles,
    List<Uri> resolutionInputs,
    int index,
    Test test,
    bool verbose});

Future<SerializedData> serializeDartCore(
    {Arguments arguments: const Arguments()}) {
  return measure('dart:core', 'serialize', () async {
    Uri uri = Uri.parse('memory:${arguments.serializedDataFileName}');
    SerializedData serializedData;
    if (arguments.loadSerializedData) {
      File file = new File(arguments.serializedDataFileName);
      if (file.existsSync()) {
        print('Loading data from $file');
        serializedData = new SerializedData(uri, file.readAsStringSync());
      }
    } else {
      SerializationResult result =
          await serialize(Uris.dart_core, dataUri: uri);
      serializedData = result.serializedData;
    }
    if (arguments.saveSerializedData) {
      File file = new File(arguments.serializedDataFileName);
      print('Saving data to $file');
      file.writeAsStringSync(serializedData.data);
    }
    return serializedData;
  });
}

class SerializationResult {
  final Compiler compiler;
  final SerializedData serializedData;

  SerializationResult(this.compiler, this.serializedData);
}

Future<SerializationResult> serialize(Uri entryPoint,
    {Map<String, String> memorySourceFiles: const <String, String>{},
    List<Uri> resolutionInputs: const <Uri>[],
    Uri dataUri,
    bool deserializeCompilationDataForTesting: false}) async {
  if (dataUri == null) {
    dataUri = Uri.parse('memory:${DEFAULT_DATA_FILE_NAME}');
  }
  OutputCollector outputCollector = new OutputCollector();
  Compiler compiler = compilerFor(
      options: [Flags.resolveOnly],
      memorySourceFiles: memorySourceFiles,
      resolutionInputs: resolutionInputs,
      outputProvider: outputCollector);
  compiler.serialization.deserializeCompilationDataForTesting =
      deserializeCompilationDataForTesting;
  await compiler.run(entryPoint);
  SerializedData serializedData =
      new SerializedData(dataUri, outputCollector.getOutput('', 'data'));
  return new SerializationResult(compiler, serializedData);
}

class SerializedData {
  final Uri uri;
  final String data;

  SerializedData(this.uri, this.data) {
    assert(uri != null);
    assert(data != null);
  }

  Map<String, String> toMemorySourceFiles([Map<String, String> input]) {
    Map<String, String> sourceFiles = <String, String>{};
    if (input != null) {
      sourceFiles.addAll(input);
    }
    expandMemorySourceFiles(sourceFiles);
    return sourceFiles;
  }

  void expandMemorySourceFiles(Map<String, String> sourceFiles) {
    if (uri.scheme == 'memory') {
      sourceFiles[uri.path] = data;
    }
  }

  List<Uri> toUris([List<Uri> input]) {
    List<Uri> uris = <Uri>[];
    if (input != null) {
      uris.addAll(input);
    }
    expandUris(uris);
    return uris;
  }

  void expandUris(List<Uri> uris) {
    uris.add(uri);
  }
}

Future<List<SerializedData>> preserializeData(
    SerializedData serializedData, Test test) async {
  if (test == null ||
      test.preserializedSourceFiles == null ||
      test.preserializedSourceFiles.isEmpty) {
    return <SerializedData>[serializedData];
  }

  List<Uri> uriList = <Uri>[];
  for (String key in test.preserializedSourceFiles.keys) {
    uriList.add(Uri.parse('memory:$key'));
  }
  Map<String, String> sourceFiles = serializedData.toMemorySourceFiles();
  sourceFiles.addAll(test.preserializedSourceFiles);
  if (test.unserializedSourceFiles != null) {
    sourceFiles.addAll(test.unserializedSourceFiles);
  }
  Uri additionalDataUri = Uri.parse('memory:additional.data');
  SerializedData additionalSerializedData;
  if (test.sourceFiles.isEmpty) {
    SerializationResult result = await serialize(uriList.first,
        memorySourceFiles: sourceFiles,
        resolutionInputs: serializedData.toUris(),
        dataUri: additionalDataUri);
    additionalSerializedData = result.serializedData;
  } else {
    OutputCollector outputCollector = new OutputCollector();
    Compiler compiler = compilerFor(
        entryPoint: test.sourceFiles.isEmpty ? uriList.first : null,
        memorySourceFiles: sourceFiles,
        resolutionInputs: serializedData.toUris(),
        options: [Flags.resolveOnly],
        outputProvider: outputCollector);
    compiler.librariesToAnalyzeWhenRun = uriList;
    await compiler.run(null);
    List<LibraryElement> libraries = <LibraryElement>[];
    for (Uri uri in uriList) {
      libraries.add(compiler.libraryLoader.lookupLibrary(uri));
    }
    additionalSerializedData = new SerializedData(
        additionalDataUri, outputCollector.getOutput('', 'data'));
  }
  return <SerializedData>[serializedData, additionalSerializedData];
}

class MeasurementResult {
  final String title;
  final String taskTitle;
  final int elapsedMilliseconds;

  MeasurementResult(this.title, this.taskTitle, this.elapsedMilliseconds);
}

final List<MeasurementResult> measurementResults = <MeasurementResult>[];

/// Print all store [measurementResults] grouped by title and sorted by
/// decreasing execution time.
void printMeasurementResults() {
  Map<String, int> totals = <String, int>{};

  for (MeasurementResult result in measurementResults) {
    totals.putIfAbsent(result.title, () => 0);
    totals[result.title] += result.elapsedMilliseconds;
  }

  List<String> sorted = totals.keys.toList();
  sorted.sort((a, b) => -totals[a].compareTo(totals[b]));

  int paddingLength = '${totals[sorted.first]}'.length;

  String pad(int value) {
    String text = '$value';
    return '${' ' * (paddingLength - text.length)}$text';
  }

  print('================================================================');
  print('Summary:');
  for (String task in sorted) {
    int time = totals[task];
    print('${pad(time)}ms $task');
  }

  measurementResults.clear();
}

/// Measure execution of [task], print the result and store it in
/// [measurementResults] for a summary.
Future measure(String title, String taskTitle, Future task()) async {
  Stopwatch stopwatch = new Stopwatch()..start();
  print('================================================================');
  print('$taskTitle: $title');
  print('----------------------------------------------------------------');
  var result = await task();
  stopwatch.stop();
  int elapsedMilliseconds = stopwatch.elapsedMilliseconds;
  print('$taskTitle: $title: ${elapsedMilliseconds}ms');
  measurementResults
      .add(new MeasurementResult(title, taskTitle, elapsedMilliseconds));
  return result;
}
