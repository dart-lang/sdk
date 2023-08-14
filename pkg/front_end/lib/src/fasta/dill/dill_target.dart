// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:_fe_analyzer_shared/src/messages/severity.dart' show Severity;

import 'package:kernel/ast.dart' show Source;

import 'package:kernel/target/targets.dart' show Target;

import '../../base/processed_options.dart' show ProcessedOptions;

import '../compiler_context.dart' show CompilerContext;

import '../kernel/benchmarker.dart' show BenchmarkPhases, Benchmarker;

import '../messages.dart' show FormattedMessage, LocatedMessage, Message;

import '../ticker.dart' show Ticker;

import '../uri_translator.dart' show UriTranslator;

import '../target_implementation.dart' show TargetImplementation;

import 'dill_loader.dart' show DillLoader;

class DillTarget extends TargetImplementation {
  final Ticker ticker;

  bool isLoaded = false;

  late final DillLoader loader;

  final UriTranslator uriTranslator;

  @override
  final Target backendTarget;

  @override
  final CompilerContext context = CompilerContext.current;

  /// Shared with [CompilerContext].
  final Map<Uri, Source> uriToSource = CompilerContext.current.uriToSource;

  final Benchmarker? benchmarker;

  DillTarget(this.ticker, this.uriTranslator, this.backendTarget,
      {this.benchmarker}) {
    loader = new DillLoader(this);
  }

  void loadExtraRequiredLibraries(DillLoader loader) {
    for (String uri in backendTarget.extraRequiredLibraries) {
      loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
    }
    if (context.compilingPlatform) {
      for (String uri in backendTarget.extraRequiredLibrariesPlatform) {
        loader.read(Uri.parse(uri), 0, accessor: loader.coreLibrary);
      }
    }
  }

  FormattedMessage createFormattedMessage(
      Message message,
      int charOffset,
      int length,
      Uri? fileUri,
      List<LocatedMessage>? messageContext,
      Severity severity,
      {List<Uri>? involvedFiles}) {
    ProcessedOptions processedOptions = context.options;
    return processedOptions.format(
        fileUri != null
            ? message.withLocation(fileUri, charOffset, length)
            : message.withoutLocation(),
        severity,
        messageContext,
        involvedFiles: involvedFiles);
  }

  void buildOutlines({bool suppressFinalizationErrors = false}) {
    if (loader.libraries.isNotEmpty) {
      benchmarker?.enterPhase(BenchmarkPhases.dill_buildOutlines);
      loader.buildOutlines();
      benchmarker?.enterPhase(BenchmarkPhases.dill_finalizeExports);
      loader.finalizeExports(
          suppressFinalizationErrors: suppressFinalizationErrors);
      benchmarker?.enterPhase(BenchmarkPhases.unknownDillTarget);
    }
    isLoaded = true;
  }
}
