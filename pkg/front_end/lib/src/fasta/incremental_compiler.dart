// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.incremental_compiler;

import 'dart:async' show Future;

import 'package:kernel/kernel.dart' show Program, loadProgramFromBytes;

import '../api_prototype/incremental_kernel_generator.dart'
    show DeltaProgram, IncrementalKernelGenerator;

import 'dill/dill_target.dart' show DillTarget;

import 'kernel/kernel_target.dart' show KernelTarget;

import 'compiler_context.dart' show CompilerContext;

import 'problems.dart' show unsupported;

import 'ticker.dart' show Ticker;

import 'uri_translator.dart' show UriTranslator;

abstract class DeprecatedIncrementalKernelGenerator
    implements IncrementalKernelGenerator {
  /// This does nothing. It will be deprecated.
  @override
  void acceptLastDelta() {}

  /// Always throws an error. Will be deprecated.
  @override
  void rejectLastDelta() => unsupported("rejectLastDelta", -1, null);

  /// Always throws an error. Will be deprecated.
  @override
  void reset() => unsupported("rejectLastDelta", -1, null);

  /// Always throws an error. Will be deprecated.
  @override
  void setState(String state) => unsupported("setState", -1, null);
}

abstract class DeprecatedDeltaProgram implements DeltaProgram {
  @override
  String get state => unsupported("state", -1, null);
}

class FastaDelta extends DeprecatedDeltaProgram {
  @override
  final Program newProgram;

  FastaDelta(this.newProgram);
}

class IncrementalCompiler extends DeprecatedIncrementalKernelGenerator {
  final CompilerContext context;

  final Ticker ticker;

  List<Uri> invalidatedUris = <Uri>[];

  DillTarget platform;

  IncrementalCompiler(this.context)
      : ticker = new Ticker(isVerbose: context.options.verbose);

  @override
  Future<FastaDelta> computeDelta({Uri entryPoint}) async {
    return context.runInContext<Future<FastaDelta>>((CompilerContext c) async {
      if (platform == null) {
        UriTranslator uriTranslator = await c.options.getUriTranslator();
        ticker.logMs("Read packages file");

        platform = new DillTarget(ticker, uriTranslator, c.options.target);
        List<int> bytes = await c.options.loadSdkSummaryBytes();
        if (bytes != null) {
          ticker.logMs("Read ${c.options.sdkSummary}");
          platform.loader.appendLibraries(loadProgramFromBytes(bytes),
              byteCount: bytes.length);
        }
        await platform.buildOutlines();
      }

      List<Uri> invalidatedUris = this.invalidatedUris.toList();
      this.invalidatedUris.clear();
      print("Changed URIs: ${invalidatedUris.join('\n')}");

      KernelTarget kernelTarget = new KernelTarget(
          c.fileSystem, false, platform, platform.uriTranslator,
          uriToSource: c.uriToSource);

      kernelTarget.read(entryPoint);

      await kernelTarget.buildOutlines();

      return new FastaDelta(
          await kernelTarget.buildProgram(verify: c.options.verify));
    });
  }

  @override
  void invalidate(Uri uri) {
    invalidatedUris.add(uri);
  }
}
