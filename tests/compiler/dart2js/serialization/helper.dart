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

class Arguments {
  final String filename;
  final int index;
  final bool loadSerializedData;
  final bool saveSerializedData;
  final String serializedDataFileName;
  final bool verbose;

  const Arguments({
    this.filename,
    this.index,
    this.loadSerializedData: false,
    this.saveSerializedData: false,
    this.serializedDataFileName: 'out.data',
    this.verbose: false});

  factory Arguments.from(List<String> arguments) {
    String filename;
    int index;
    for (String arg in arguments) {
      if (!arg.startsWith('-')) {
        index = int.parse(arg);
        if (index == null) {
          filename = arg;
        }
      }
    }
    bool verbose = arguments.contains('-v');
    bool loadSerializedData = arguments.contains('-l');
    bool saveSerializedData = arguments.contains('-s');
    return new Arguments(
        filename: filename,
        index: index,
        verbose: verbose,
        loadSerializedData: loadSerializedData,
        saveSerializedData: saveSerializedData);
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
