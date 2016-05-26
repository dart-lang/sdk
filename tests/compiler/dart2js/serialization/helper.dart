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

  const Arguments({
    this.filename,
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

  Future forEachTest(
      SerializedData serializedData,
      List<Test> tests,
      TestFunction testFunction) async {
    Uri entryPoint = Uri.parse('memory:main.dart');
    int first = start ?? 0;
    int last = end ?? tests.length - 1;

    for (int index = first; index <= last; index++) {
      Test test = TESTS[index];
      List<SerializedData> dataList =
          await preserializeData(serializedData, test);
      Map<String, String> sourceFiles = <String, String>{};
      sourceFiles.addAll(test.sourceFiles);
      if (test.preserializedSourceFiles != null) {
        sourceFiles.addAll(test.preserializedSourceFiles);
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

typedef Future TestFunction(
    Uri entryPoint,
    {Map<String, String> sourceFiles,
     List<Uri> resolutionInputs,
     int index,
     Test test,
     bool verbose});

Future<SerializedData> serializeDartCore(
    {Arguments arguments: const Arguments()}) async {
  Uri uri = Uri.parse('memory:${arguments.serializedDataFileName}');
  print('------------------------------------------------------------------');
  print('serialize dart:core');
  print('------------------------------------------------------------------');
  SerializedData serializedData;
  if (arguments.loadSerializedData) {
    File file = new File(arguments.serializedDataFileName);
    if (file.existsSync()) {
      print('Loading data from $file');
      serializedData = new SerializedData(uri, file.readAsStringSync());
    }
  }
  if (serializedData == null) {
    Compiler compiler = compilerFor(
        options: [Flags.analyzeAll]);
    compiler.serialization.supportSerialization = true;
    await compiler.run(Uris.dart_core);
    BufferedEventSink sink = new BufferedEventSink();
    compiler.serialization.serializeToSink(
        sink, compiler.libraryLoader.libraries);
    serializedData = new SerializedData(uri, sink.text);
    if (arguments.saveSerializedData) {
      File file = new File(arguments.serializedDataFileName);
      print('Saving data to $file');
      file.writeAsStringSync(serializedData.data);
    }
  }
  return serializedData;
}

class SerializedData {
  final Uri uri;
  final String data;

  SerializedData(this.uri, this.data);

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

String extractSerializedData(
    Compiler compiler, Iterable<LibraryElement> libraries) {
  BufferedEventSink sink = new BufferedEventSink();
  compiler.serialization.serializeToSink(sink, libraries);
  return sink.text;
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
  Compiler compiler = compilerFor(
      memorySourceFiles:
          serializedData.toMemorySourceFiles(test.preserializedSourceFiles),
      resolutionInputs: serializedData.toUris(),
      options: [Flags.analyzeOnly, Flags.analyzeMain]);
  compiler.librariesToAnalyzeWhenRun = uriList;
  compiler.serialization.supportSerialization = true;
  await compiler.run(null);
  List<LibraryElement> libraries = <LibraryElement>[];
  for (Uri uri in uriList) {
    libraries.add(compiler.libraryLoader.lookupLibrary(uri));
  }
  SerializedData additionalSerializedData =
      new SerializedData(Uri.parse('memory:additional.data'),
      extractSerializedData(compiler, libraries));
  return <SerializedData>[serializedData, additionalSerializedData];
}
