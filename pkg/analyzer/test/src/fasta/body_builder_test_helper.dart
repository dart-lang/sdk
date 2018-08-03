// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:io' show File;

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/dart/element/type.dart';
import "package:front_end/src/api_prototype/front_end.dart";
import "package:front_end/src/api_prototype/memory_file_system.dart";
import "package:front_end/src/base/processed_options.dart";
import "package:front_end/src/compute_platform_binaries_location.dart";
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import "package:front_end/src/fasta/fasta_codes.dart";
import "package:front_end/src/fasta/kernel/kernel_target.dart";
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/uri_translator_impl.dart';
import 'package:kernel/class_hierarchy.dart' as kernel;
import 'package:kernel/core_types.dart' as kernel;
import 'package:kernel/kernel.dart' as kernel;
import 'package:test/test.dart';

Element _buildElement(kernel.Class coreType) {
  ClassElementImpl element =
      new ClassElementImpl(coreType.name, coreType.fileOffset);
  element.typeParameters = coreType.typeParameters.map((parameter) {
    TypeParameterElementImpl element =
        new TypeParameterElementImpl(parameter.name, parameter.fileOffset);
    element.type = new TypeParameterTypeImpl(element);
    return element;
  }).toList();
  return element;
}

class CompilerTestContext extends CompilerContext {
  KernelTarget kernelTarget;

  CompilerTestContext(ProcessedOptions options) : super(options);

  Uri get entryPoint => options.inputs.single;

  static Future<T> runWithTestOptions<T>(
      Future<T> action(CompilerTestContext c)) async {
    // TODO(danrubel): Consider HybridFileSystem.
    final MemoryFileSystem fs =
        new MemoryFileSystem(Uri.parse("org-dartlang-test:///"));

    /// The custom URI used to locate the dill file in the MemoryFileSystem.
    final Uri sdkSummary = fs.currentDirectory.resolve("vm_platform.dill");

    /// The in memory test code URI
    final Uri entryPoint = fs.currentDirectory.resolve("main.dart");

    // Read the dill file containing kernel platform summaries into memory.
    List<int> sdkSummaryBytes = await new File.fromUri(
            computePlatformBinariesLocation().resolve("vm_platform.dill"))
        .readAsBytes();
    fs.entityForUri(sdkSummary).writeAsBytesSync(sdkSummaryBytes);

    final CompilerOptions optionBuilder = new CompilerOptions()
      ..strongMode = false // TODO(danrubel): enable strong mode.
      ..reportMessages = true
      ..verbose = false
      ..fileSystem = fs
      ..sdkSummary = sdkSummary
      ..onProblem = (FormattedMessage problem, Severity severity,
          List<FormattedMessage> context) {
        // TODO(danrubel): Capture problems and check against expectations.
//        print(problem.formatted);
      };

    final ProcessedOptions options =
        new ProcessedOptions(optionBuilder, [entryPoint]);

    UriTranslatorImpl uriTranslator = await options.getUriTranslator();

    return await new CompilerTestContext(options)
        .runInContext<T>((CompilerContext _c) async {
      CompilerTestContext c = _c;
      DillTarget dillTarget = new DillTarget(
          new Ticker(isVerbose: false), uriTranslator, options.target);

      c.kernelTarget = new KernelTarget(fs, true, dillTarget, uriTranslator);

      // Load the dill file containing platform code.
      dillTarget.loader.read(Uri.parse('dart:core'), -1, fileUri: sdkSummary);
      kernel.Component sdkComponent =
          kernel.loadComponentFromBytes(sdkSummaryBytes);
      dillTarget.loader
          .appendLibraries(sdkComponent, byteCount: sdkSummaryBytes.length);
      await dillTarget.buildOutlines();
      await c.kernelTarget.buildOutlines();
      c.kernelTarget.computeCoreTypes();
      assert(c.kernelTarget.loader.coreTypes != null);

      // Initialize the typeProvider if types should be resolved.
      Map<String, Element> map = <String, Element>{};
      var coreTypes = c.kernelTarget.loader.coreTypes;
      for (var coreType in [
        coreTypes.boolClass,
        coreTypes.doubleClass,
        coreTypes.functionClass,
        coreTypes.futureClass,
        coreTypes.futureOrClass,
        coreTypes.intClass,
        coreTypes.iterableClass,
        coreTypes.iteratorClass,
        coreTypes.listClass,
        coreTypes.mapClass,
        coreTypes.nullClass,
        coreTypes.numClass,
        coreTypes.objectClass,
        coreTypes.stackTraceClass,
        coreTypes.streamClass,
        coreTypes.stringClass,
        coreTypes.symbolClass,
        coreTypes.typeClass
      ]) {
        map[coreType.name] = _buildElement(coreType);
      }

      T result;
      Completer<T> completer = new Completer<T>();
      // Since we're using `package:test_reflective_loader`, we can't rely on
      // normal async behavior, as `defineReflectiveSuite` doesn't return a
      // future. However, since it's built on top of `package:test`, we can
      // obtain a future that completes when all the tests are done using
      // `tearDownAll`. This allows this function to complete no earlier than
      // when the tests are done. This is important, as we don't want to call
      // `CompilerContext.clear` before then.
      tearDownAll(() => completer.complete(result));
      result = await action(c);
      return completer.future;
    });
  }

  static CompilerTestContext get current => CompilerContext.current;
}
