// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE.md file.

// TODO(ahe): Copied from closure_conversion branch of kernel, remove this file
// when closure_conversion is merged with master.

library fasta.testing.kernel_chain;

import 'dart:async' show Future;

import 'dart:io' show Directory, File, IOSink;

import 'dart:typed_data' show Uint8List;

import 'package:kernel/ast.dart' show Library, Component;

import 'package:kernel/binary/ast_to_binary.dart' show BinaryPrinter;

import 'package:kernel/binary/ast_from_binary.dart' show BinaryBuilder;

import 'package:kernel/error_formatter.dart' show ErrorFormatter;

import 'package:kernel/kernel.dart' show loadComponentFromBinary;

import 'package:kernel/naive_type_checker.dart' show StrongModeTypeChecker;

import 'package:kernel/target/targets.dart' show Target;

import 'package:kernel/text/ast_to_text.dart' show Printer;

import 'package:testing/testing.dart'
    show ChainContext, Result, StdioProcess, Step, TestDescription;

import 'package:front_end/src/api_prototype/front_end.dart';

import 'package:front_end/src/base/processed_options.dart'
    show ProcessedOptions;

import 'package:front_end/src/compute_platform_binaries_location.dart'
    show computePlatformBinariesLocation;

import '../compiler_context.dart';

import '../kernel/verifier.dart' show verifyComponent;

class Print extends Step<Component, Component, ChainContext> {
  const Print();

  String get name => "print";

  Future<Result<Component>> run(Component component, _) async {
    StringBuffer sb = new StringBuffer();
    for (Library library in component.libraries) {
      Printer printer = new Printer(sb);
      if (library.importUri.scheme != "dart" &&
          library.importUri.scheme != "package") {
        printer.writeLibraryFile(library);
      }
    }
    print("$sb");
    return pass(component);
  }
}

class Verify extends Step<Component, Component, ChainContext> {
  final bool fullCompile;

  const Verify(this.fullCompile);

  String get name => "verify";

  Future<Result<Component>> run(
      Component component, ChainContext context) async {
    var options = new ProcessedOptions(new CompilerOptions());
    return await CompilerContext.runWithOptions(options, (_) async {
      var errors = verifyComponent(component,
          isOutline: !fullCompile, skipPlatform: true);
      if (errors.isEmpty) {
        return pass(component);
      } else {
        return new Result<Component>(
            null, context.expectationSet["VerificationError"], errors, null);
      }
    });
  }
}

class TypeCheck extends Step<Component, Component, ChainContext> {
  const TypeCheck();

  String get name => "typeCheck";

  Future<Result<Component>> run(
      Component component, ChainContext context) async {
    var errorFormatter = new ErrorFormatter();
    var checker =
        new StrongModeTypeChecker(errorFormatter, component, ignoreSdk: true);
    checker.checkComponent(component);
    if (errorFormatter.numberOfFailures == 0) {
      return pass(component);
    } else {
      errorFormatter.failures.forEach(print);
      print('------- Found ${errorFormatter.numberOfFailures} errors -------');
      return new Result<Component>(
          null,
          context.expectationSet["TypeCheckError"],
          '${errorFormatter.numberOfFailures} type errors',
          null);
    }
  }
}

class MatchExpectation extends Step<Component, Component, ChainContext> {
  final String suffix;

  // TODO(ahe): This is true by default which doesn't match well with the class
  // name.
  final bool updateExpectations;

  const MatchExpectation(this.suffix, {this.updateExpectations: false});

  String get name => "match expectations";

  Future<Result<Component>> run(Component component, _) async {
    Library library = component.libraries
        .firstWhere((Library library) => library.importUri.scheme != "dart");
    Uri uri = library.importUri;
    Uri base = uri.resolve(".");
    StringBuffer buffer = new StringBuffer();
    new Printer(buffer).writeLibraryFile(library);
    String actual = "$buffer".replaceAll("$base", "org-dartlang-testcase:///");
    actual = actual.replaceAll("\\n", "\n");
    File expectedFile = new File("${uri.toFilePath()}$suffix");
    if (await expectedFile.exists()) {
      String expected = await expectedFile.readAsString();
      if (expected.trim() != actual.trim()) {
        if (!updateExpectations) {
          String diff = await runDiff(expectedFile.uri, actual);
          return fail(null, "$uri doesn't match ${expectedFile.uri}\n$diff");
        }
      } else {
        return pass(component);
      }
    }
    if (updateExpectations) {
      await openWrite(expectedFile.uri, (IOSink sink) {
        sink.writeln(actual.trim());
      });
      return pass(component);
    } else {
      return fail(component, """
Please create file ${expectedFile.path} with this content:
$actual""");
    }
  }
}

class WriteDill extends Step<Component, Uri, ChainContext> {
  const WriteDill();

  String get name => "write .dill";

  Future<Result<Uri>> run(Component component, _) async {
    Directory tmp = await Directory.systemTemp.createTemp();
    Uri uri = tmp.uri.resolve("generated.dill");
    File generated = new File.fromUri(uri);
    IOSink sink = generated.openWrite();
    try {
      try {
        new BinaryPrinter(sink).writeComponentFile(component);
      } finally {
        component.unbindCanonicalNames();
      }
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
      loadComponentFromBinary(uri.toFilePath());
    } catch (e, s) {
      return fail(uri, e, s);
    }
    return pass(uri);
  }
}

class Copy extends Step<Component, Component, ChainContext> {
  const Copy();

  String get name => "copy component";

  Future<Result<Component>> run(Component component, _) async {
    BytesCollector sink = new BytesCollector();
    new BinaryPrinter(sink).writeComponentFile(component);
    component.unbindCanonicalNames();
    Uint8List bytes = sink.collect();
    new BinaryBuilder(bytes).readComponent(component);
    return pass(component);
  }
}

/// A `package:testing` step that runs the `package:front_end` compiler to
/// generate a kernel component for an individual file.
///
/// Most options are hard-coded, but if necessary they could be moved to the
/// [CompileContext] object in the future.
class Compile extends Step<TestDescription, Component, CompileContext> {
  const Compile();

  String get name => "fasta compilation";

  Future<Result<Component>> run(
      TestDescription description, CompileContext context) async {
    Result<Component> result;
    reportError(CompilationMessage error) {
      result ??= fail(null, error.message);
    }

    Uri sdk = Uri.base.resolve("sdk/");
    var options = new CompilerOptions()
      ..sdkRoot = sdk
      ..compileSdk = true
      ..packagesFileUri = Uri.base.resolve('.packages')
      ..strongMode = context.strongMode
      ..onError = reportError;
    if (context.target != null) {
      options.target = context.target;
      // Do not link platform.dill, but recompile the platform libraries. This
      // ensures that if target defines extra libraries that those get included
      // too.
    } else {
      options.linkedDependencies = [
        computePlatformBinariesLocation().resolve("vm_platform.dill"),
      ];
    }
    Component p = await kernelForProgram(description.uri, options);
    return result ??= pass(p);
  }
}

abstract class CompileContext implements ChainContext {
  bool get strongMode;
  Target get target;
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
  StdioProcess process = await StdioProcess.run(
      "git", <String>["diff", "--no-index", "-u", expected.toFilePath(), "-"],
      input: actual, runInShell: true);
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
