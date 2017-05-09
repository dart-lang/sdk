// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/file_system.dart';
import 'package:front_end/incremental_kernel_generator.dart';
import 'package:front_end/incremental_resolved_ast_generator.dart';
import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/dill/dill_target.dart';
import 'package:front_end/src/fasta/kernel/kernel_target.dart';
import 'package:front_end/src/fasta/ticker.dart';
import 'package:front_end/src/fasta/translate_uri.dart';
import 'package:kernel/kernel.dart' hide Source;

dynamic unimplemented() {
  // TODO(paulberry): get rid of this.
  throw new UnimplementedError();
}

/// Implementation of [IncrementalKernelGenerator].
///
/// TODO(scheglov) Update the documentation.
///
/// Theory of operation: an instance of [IncrementalResolvedAstGenerator] is
/// used to obtain resolved ASTs, and these are fed into kernel code generation
/// logic.
class IncrementalKernelGeneratorImpl implements IncrementalKernelGenerator {
  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// The compiler options, such as the [FileSystem], the SDK dill location,
  /// etc.
  final ProcessedOptions _options;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  TranslateUri _uriTranslator;

  /// The cached SDK kernel.
  DillTarget _sdkDillTarget;

  IncrementalKernelGeneratorImpl(this._entryPoint, this._options);

  @override
  Future<DeltaProgram> computeDelta(
      {Future<Null> watch(Uri uri, bool used)}) async {
    _uriTranslator ??= await _options.getUriTranslator();

    DillTarget sdkTarget = await _getSdkDillTarget();
    // TODO(scheglov) Use it to also serve other package kernels.

    KernelTarget kernelTarget = new KernelTarget(_options.fileSystem, sdkTarget,
        _uriTranslator, _options.strongMode, null);
    kernelTarget.read(_entryPoint);

    // TODO(scheglov) Replace with a better API.
    // Firstly, we don't "write" anything here.
    // Secondly, it catches all the exceptions and write them to `stderr`.
    // This is too interactive and not API-clients friendly.
    await kernelTarget.writeOutline(null);

    // TODO(scheglov) Replace with a better API.
    Program program = await kernelTarget.writeProgram(null);
    return new DeltaProgram(program);
  }

  @override
  void invalidate(String path) => unimplemented();

  @override
  void invalidateAll() => unimplemented();

  /// Return the [DillTarget] that is used inside of [KernelTarget] to
  /// resynthesize SDK libraries.
  Future<DillTarget> _getSdkDillTarget() async {
    if (_sdkDillTarget == null) {
      _sdkDillTarget =
          new DillTarget(new Ticker(isVerbose: false), _uriTranslator);
      // TODO(scheglov) Read the SDK kernel.
//      _sdkDillTarget.read(options.sdkSummary);
//      await _sdkDillTarget.writeOutline(null);
    } else {
//      Program sdkProgram = _sdkDillTarget.loader.program;
//      sdkProgram.visitChildren(new _ClearCanonicalNamesVisitor());
    }
    return _sdkDillTarget;
  }
}

///// Clears canonical names of [NamedNode] references.
//class _ClearCanonicalNamesVisitor extends Visitor {
//  defaultNode(Node node) {
//    if (node is NamedNode) {
//      node.reference.canonicalName = null;
//    }
//    node.visitChildren(this);
//  }
//}
