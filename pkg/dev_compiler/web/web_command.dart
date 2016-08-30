// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.
@JS()
library dev_compiler.web.web_command;

import 'dart:async';
import 'dart:html' show HttpRequest;
import 'dart:convert' show BASE64;

import 'package:analyzer/file_system/file_system.dart' show ResourceUriResolver;
import 'package:analyzer/file_system/memory_file_system.dart'
    show MemoryResourceProvider;
import 'package:analyzer/src/context/context.dart' show AnalysisContextImpl;
import 'package:analyzer/src/generated/source.dart' show DartUriResolver;
import 'package:analyzer/src/summary/idl.dart' show PackageBundle;
import 'package:analyzer/src/summary/package_bundle_reader.dart'
    show
        SummaryDataStore,
        InSummaryUriResolver,
        InputPackagesResultProvider,
        InSummarySource;
import 'package:analyzer/src/summary/summary_sdk.dart' show SummaryBasedDartSdk;

import 'package:args/command_runner.dart';

import 'package:dev_compiler/src/analyzer/context.dart' show AnalyzerOptions;
import 'package:dev_compiler/src/compiler/compiler.dart'
    show BuildUnit, CompilerOptions, JSModuleFile, ModuleCompiler;

import 'package:dev_compiler/src/compiler/module_builder.dart';
import 'package:js/js.dart';

typedef void MessageHandler(Object message);

/// The command for invoking the modular compiler.
class WebCompileCommand extends Command {
  get name => 'compile';

  get description => 'Compile a set of Dart files into a JavaScript module.';
  final MessageHandler messageHandler;

  WebCompileCommand({MessageHandler messageHandler})
      : this.messageHandler = messageHandler ?? print {
    CompilerOptions.addArguments(argParser);
    AnalyzerOptions.addArguments(argParser);
  }

  @override
  Function run() {
    return requestSummaries;
  }

  void requestSummaries(String sdkUrl, List<String> summaryUrls,
      Function onCompileReady, Function onError) {
    HttpRequest.request(sdkUrl).then((sdkRequest) {
      var sdkResponse = sdkRequest.responseText;
      var sdkBytes = BASE64.decode(sdkResponse);

      // Map summary URLs to HttpRequests.
      var summaryRequests = summaryUrls
          .map((summary) => new Future(() => HttpRequest.request(summary)));

      Future.wait(summaryRequests).then((summaryResponses) {
        // Map summary responses to summary bytes.
        var summaryBytes = <List<int>>[];
        for (var response in summaryResponses) {
          summaryBytes.add(BASE64.decode(response.responseText));
        }

        var compileFn = setUpCompile(sdkBytes, summaryBytes, summaryUrls);
        onCompileReady(compileFn);
      }).catchError((error) => onError('Summaries failed to load: $error'));
    }).catchError(
        (error) => onError('Dart sdk summaries failed to load: $error'));
  }

  Function setUpCompile(List<int> sdkBytes, List<List<int>> summaryBytes,
      List<String> summaryUrls) {
    var resourceProvider = new MemoryResourceProvider();
    var resourceUriResolver = new ResourceUriResolver(resourceProvider);

    var packageBundle = new PackageBundle.fromBuffer(sdkBytes);
    var webDartSdk = new SummaryBasedDartSdk.fromBundle(
        true, packageBundle, resourceProvider);
    var sdkResolver = new DartUriResolver(webDartSdk);

    var summaryDataStore = new SummaryDataStore([]);
    for (var i = 0; i < summaryBytes.length; i++) {
      var bytes = summaryBytes[i];
      var url = summaryUrls[i];
      var summaryBundle = new PackageBundle.fromBuffer(bytes);
      summaryDataStore.addBundle(url, summaryBundle);
    }
    var summaryResolver = new InSummaryUriResolver(resourceProvider, summaryDataStore);

    var fileResolvers = [summaryResolver, resourceUriResolver];

    var compiler = new ModuleCompiler(
        new AnalyzerOptions(dartSdkPath: '/dart-sdk'),
        sdkResolver: sdkResolver,
        fileResolvers: fileResolvers,
        resourceProvider: resourceProvider);

    (compiler.context as AnalysisContextImpl).resultProvider =
        new InputPackagesResultProvider(compiler.context, summaryDataStore);

    var compilerOptions = new CompilerOptions.fromArguments(argResults);

    var compileFn = (String dart, int number) {
      // Create a new virtual File that contains the given Dart source.
      resourceProvider.newFile("/expression${number}.dart", dart);

      var unit = new BuildUnit("expression${number}", "",
          ["file:///expression${number}.dart"], _moduleForLibrary);

      JSModuleFile module = compiler.compile(unit, compilerOptions);
      module.errors.forEach(messageHandler);

      if (!module.isValid) throw new CompileErrorException();

      var code =
          module.getCode(ModuleFormat.amd, unit.name, unit.name + '.map');
      return code.code;
    };

    return allowInterop(compileFn);
  }
}

// Given path, determine corresponding dart library.
String _moduleForLibrary(source) {
  if (source is InSummarySource) {
    return source.summaryPath.substring(1).replaceAll('.api.ds', '');
  }
  return source.toString().substring(1).replaceAll('.dart', '');
}

/// Thrown when the input source code has errors.
class CompileErrorException implements Exception {
  toString() => '\nPlease fix all errors before compiling (warnings are okay).';
}
