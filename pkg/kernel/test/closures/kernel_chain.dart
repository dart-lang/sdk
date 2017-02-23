// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

library test.kernel.closures.suite;

import 'dart:async' show Future;

import 'dart:io' show Directory, File, IOSink;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/kernel.dart' show loadProgramFromBinary;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:testing/testing.dart'
    show ChainContext, Result, StdioProcess, Step;

import 'package:kernel/ast.dart' show Library, Program;

import 'package:kernel/verifier.dart' show verifyProgram;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

Future<bool> fileExists(Uri base, String path) async {
  return await new File.fromUri(base.resolve(path)).exists();
}

class Print extends Step<Program, Program, ChainContext> {
  const Print();

  String get name => "print";

  Future<Result<Program>> run(Program program, _) async {
    StringBuffer sb = new StringBuffer();
    for (Library library in program.libraries) {
      Printer printer = new Printer(sb);
      if (library.importUri.scheme != "dart") {
        printer.writeLibraryFile(library);
      }
    }
    print("$sb");
    return pass(program);
  }
}

class SanityCheck extends Step<Program, Program, ChainContext> {
  const SanityCheck();

  String get name => "sanity check";

  Future<Result<Program>> run(Program program, _) async {
    try {
      verifyProgram(program);
      return pass(program);
    } catch (e, s) {
      return crash(e, s);
    }
  }
}

class MatchExpectation extends Step<Program, Program, ChainContext> {
  final String suffix;

  final bool updateExpectations;

  const MatchExpectation(this.suffix, {this.updateExpectations: true});

  String get name => "match expectations";

  Future<Result<Program>> run(Program program, _) async {
    Library library = program.libraries
        .firstWhere((Library library) => library.importUri.scheme != "dart");
    Uri uri = library.importUri;
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer).writeLibraryFile(library);

    File expectedFile = new File("${uri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != "$buffer".trim()) {
        if (!updateExpectations) {
          String diff = await runDiff(expectedFile.uri, "$buffer");
          return fail(null, "$uri doesn't match ${expectedFile.uri}\n$diff");
        }
      } else {
        return pass(program);
      }
    }
    if (updateExpectations) {
      await openWrite(expectedFile.uri, (IOSink sink) {
        sink.writeln("$buffer".trim());
      });
      return pass(program);
    } else {
      return fail(
          program,
          """
Please create file ${expectedFile.path} with this content:
$buffer""");
    }
  }
}

class WriteDill extends Step<Program, Uri, ChainContext> {
  const WriteDill();

  String get name => "write .dill";

  Future<Result<Uri>> run(Program program, _) async {
    Directory tmp = await Directory.systemTemp.createTemp();
    Uri uri = tmp.uri.resolve("generated.dill");
    File generated = new File.fromUri(uri);
    IOSink sink = generated.openWrite();
    try {
      new BinaryPrinter(sink).writeProgramFile(program);
      program.unbindCanonicalNames();
    } catch (e, s) {
      return fail(uri, e, s);
    } finally {
      print("Wrote `${generated.path}`");
      await sink.close();
    }
    return pass(uri);
  }
}

class ReadDill extends Step<Uri, Uri, ChainContext> {
  const ReadDill();

  String get name => "read .dill";

  Future<Result<Uri>> run(Uri uri, _) async {
    try {
      loadProgramFromBinary(uri.toFilePath());
    } catch (e, s) {
      return fail(uri, e, s);
    }
    return pass(uri);
  }
}

class Copy extends Step<Program, Program, ChainContext> {
  const Copy();

  String get name => "copy program";

  Future<Result<Program>> run(Program program, _) async {
    BytesCollector sink = new BytesCollector();
    new BinaryPrinter(sink).writeProgramFile(program);
    program.unbindCanonicalNames();
    Uint8List bytes = sink.collect();
    var newProgram = new Program();
    new BinaryBuilder(bytes).readProgram(newProgram);
    newProgram.unbindCanonicalNames();
    return pass(newProgram);
  }
}

class BytesCollector implements Sink<List<int>> {
  final List<List<int>> lists = <List<int>>[];

  int length = 0;

  void add(List<int> data) {
    lists.add(data);
    length += data.length;
  }

  Uint8List collect() {
    Uint8List result = new Uint8List(length);
    int offset = 0;
    for (List<int> list in lists) {
      result.setRange(offset, offset += list.length, list);
    }
    lists.clear();
    length = 0;
    return result;
  }

  void close() {}
}

Future<String> runDiff(Uri expected, String actual) async {
  StdioProcess process = await StdioProcess
      .run("diff", <String>["-u", expected.toFilePath(), "-"], input: actual);
  return process.output;
}

Future openWrite(Uri uri, f(IOSink sink)) async {
  IOSink sink = new File.fromUri(uri).openWrite();
  try {
    await f(sink);
  } finally {
    await sink.close();
  }
  print("Wrote $uri");
}
