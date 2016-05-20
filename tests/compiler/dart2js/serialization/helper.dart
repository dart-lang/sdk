// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_helper;

import 'dart:async';
import 'dart:io';

import 'package:compiler/src/commandline_options.dart';
import 'package:compiler/src/common/names.dart';
import 'package:compiler/src/compiler.dart';

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

  Future forEachTest(List<Test> tests, Future f(int index, Test test)) async {
    int first = start ?? 0;
    int last = end ?? tests.length - 1;
    for (int index = first; index <= last; index++) {
      Test test = TESTS[index];
      await f(index, test);
    }
  }
}


Future<String> serializeDartCore(
    {Arguments arguments: const Arguments()}) async {
  print('------------------------------------------------------------------');
  print('serialize dart:core');
  print('------------------------------------------------------------------');
  String serializedData;
  if (arguments.loadSerializedData) {
    File file = new File(arguments.serializedDataFileName);
    if (file.existsSync()) {
      print('Loading data from $file');
      serializedData = file.readAsStringSync();
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
    serializedData = sink.text;
    if (arguments.saveSerializedData) {
      File file = new File(arguments.serializedDataFileName);
      print('Saving data to $file');
      file.writeAsStringSync(serializedData);
    }
  }
  return serializedData;
}
