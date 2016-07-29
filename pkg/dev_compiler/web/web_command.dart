// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
import 'dart:html' show HttpRequest;
import 'dart:convert' show BASE64;

import 'package:analyzer/file_system/file_system.dart'
    show ResourceProvider, ResourceUriResolver;
import 'package:analyzer/file_system/memory_file_system.dart'
    show MemoryResourceProvider;
import 'package:analyzer/src/context/cache.dart'
    show AnalysisCache, CachePartition;
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/generated/engine.dart'
    show AnalysisContext, AnalysisEngine, TimestampedData;
import 'package:analyzer/src/generated/sdk.dart'
    show DartSdk, SdkLibrary, SdkLibraryImpl;
import 'package:analyzer/src/generated/source.dart'
    show DartUriResolver, Source, SourceFactory, UriKind;
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;

import 'package:args/command_runner.dart';

import 'package:dev_compiler/src/analyzer/context.dart' show AnalyzerOptions;
import 'package:dev_compiler/src/compiler/compiler.dart'
    show BuildUnit, CompilerOptions, JSModuleFile, ModuleCompiler;

typedef void MessageHandler(Object message);
typedef String CompileFn(String dart);
typedef void OnLoadFn(CompileFn compile);

/// The command for invoking the modular compiler.
class WebCompileCommand extends Command {
  get name => 'compile';
  get description => 'Compile a set of Dart files into a JavaScript module.';
  final MessageHandler messageHandler;
  final OnLoadFn onload;

  WebCompileCommand(this.onload, {MessageHandler messageHandler})
      : this.messageHandler = messageHandler ?? print {
    CompilerOptions.addArguments(argParser);
    AnalyzerOptions.addArguments(argParser);
  }

  @override
  void run() {
    var request = new HttpRequest();

    request.onReadyStateChange.listen((_) {
      if (request.readyState == HttpRequest.DONE &&
          (request.status == 200 || request.status == 0)) {
        var response = request.responseText;
        var sdkBytes = BASE64.decode(response);
        var result = setUpCompile(sdkBytes);
        onload(result);
      }
    });

    request.open('get', 'dart_sdk.sum');
    request.send();
  }

  CompileFn setUpCompile(List<int> sdkBytes) {
    var resourceProvider = new MemoryResourceProvider();
    var packageBundle = new PackageBundle.fromBuffer(sdkBytes);
    var webDartSdk = new SummaryBasedDartSdk.fromBundle(
        true, packageBundle, resourceProvider);

    var sdkResolver = new DartUriResolver(webDartSdk);
    var fileResolvers = [new ResourceUriResolver(resourceProvider)];

    var compiler = new ModuleCompiler(
        new AnalyzerOptions(dartSdkPath: '/dart-sdk'),
        sdkResolver: sdkResolver,
        fileResolvers: fileResolvers,
        resourceProvider: resourceProvider);

    var compilerOptions = new CompilerOptions.fromArguments(argResults);

    var number = 0;

    return (String dart) {
      // Create a new virtual File that contains the given Dart source.
      number++;
      resourceProvider.newFile("/expression$number.dart", dart);

      var unit =
          new BuildUnit("", "", ["file:///expression$number.dart"], null);

      JSModuleFile module = compiler.compile(unit, compilerOptions);
      module.errors.forEach(messageHandler);

      if (!module.isValid) throw new CompileErrorException();
      return module.code;
    };
  }
}

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}
