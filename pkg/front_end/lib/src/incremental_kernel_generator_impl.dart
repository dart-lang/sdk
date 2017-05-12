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
import 'package:front_end/src/incremental/file_state.dart';
import 'package:kernel/kernel.dart' hide Source;
import 'package:kernel/target/vm.dart';

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
  /// The compiler options, such as the [FileSystem], the SDK dill location,
  /// etc.
  final ProcessedOptions _options;

  /// The object that knows how to resolve "package:" and "dart:" URIs.
  final TranslateUri _uriTranslator;

  /// The current file system state.
  final FileSystemState _fsState;

  /// The URI of the program entry point.
  final Uri _entryPoint;

  /// The set of absolute file URIs that were reported through [invalidate]
  /// and not checked for actual changes yet.
  final Set<Uri> _invalidatedFiles = new Set<Uri>();

  /// The cached SDK kernel.
  DillTarget _sdkDillTarget;

  IncrementalKernelGeneratorImpl(
      this._options, this._uriTranslator, this._entryPoint)
      : _fsState = new FileSystemState(_options.fileSystem, _uriTranslator);

  @override
  Future<DeltaProgram> computeDelta(
      {Future<Null> watch(Uri uri, bool used)}) async {
    await _ensureVmLibrariesLoaded();
    await _refreshInvalidatedFiles();

    // Ensure that the graph starting at the entry point is ready.
    await _fsState.getFile(_entryPoint);

    DillTarget sdkTarget = await _getSdkDillTarget();
    // TODO(scheglov) Use it to also serve other package kernels.

    KernelTarget kernelTarget = new KernelTarget(_fsState.fileSystemView,
        sdkTarget, _uriTranslator, _options.strongMode, null);
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
  void invalidate(Uri uri) {
    _invalidatedFiles.add(uri);
  }

  @override
  void invalidateAll() => unimplemented();

  /// Fasta unconditionally loads all VM libraries.  In order to be able to
  /// serve them using the file system view, we need to ask [_fsState] for
  /// the corresponding files.
  Future<Null> _ensureVmLibrariesLoaded() async {
    List<String> extraLibraries = new VmTarget(null).extraRequiredLibraries;
    for (String absoluteUriStr in extraLibraries) {
      Uri absoluteUri = Uri.parse(absoluteUriStr);
      Uri fileUri = _uriTranslator.translate(absoluteUri);
      await _fsState.getFile(fileUri);
    }
  }

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

  /// Refresh all the invalidated files and update dependencies.
  Future<Null> _refreshInvalidatedFiles() async {
    for (Uri fileUri in _invalidatedFiles) {
      FileState file = await _fsState.getFile(fileUri);
      await file.refresh();
    }
    _invalidatedFiles.clear();
  }
}
