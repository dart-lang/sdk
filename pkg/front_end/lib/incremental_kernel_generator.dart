// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/fasta/compiler_context.dart';
import 'package:front_end/src/incremental_kernel_generator_impl.dart';
import 'package:front_end/src/minimal_incremental_kernel_generator.dart';
import 'package:kernel/kernel.dart';

import 'compiler_options.dart';

/// The type of the function that clients can pass to track used files.
///
/// When a file is first used during compilation, this function is called with
/// the [Uri] of that file and [used] == `true`. The content of the file is not
/// read until the [Future] returned by the function completes. If, during a
/// subsequent compilation, a file that was being used is no longer used, then
/// the function is called with the [Uri] of that file and [used] == `false`.
///
/// Multiple invocations of may be running concurrently.
///
typedef Future<Null> WatchUsedFilesFn(Uri uri, bool used);

/// Represents the difference between "old" and "new" states of a program.
///
/// Not intended to be implemented or extended by clients.
class DeltaProgram {
  /// The state of the program.
  ///
  /// It should be treated as opaque data by the clients. Its only purpose is
  /// to be passed to [IncrementalKernelGeneratorImpl.setState].
  final String state;

  /// The new program.
  ///
  /// It includes full kernels for changed libraries and for libraries that
  /// are affected by the transitive change of API in the changed libraries.
  ///
  /// For VM reload purposes we need to provide also full kernels for the
  /// libraries that are transitively imported by the entry point and
  /// transitively import a changed library.
  ///
  /// Also includes external references to other libraries that were not
  /// modified or affected.
  final Program newProgram;

  DeltaProgram(this.state, this.newProgram);
}

/// Interface for generating an initial kernel representation of a program and
/// keeping it up to date as incremental changes are made.
///
/// This class maintains an internal "current program state"; each time
/// [computeDelta] is called, it computes the "last program state" and libraries
/// that were affected relative to the "current program state".  When there are
/// few changes, a call to [computeDelta] should be much faster than compiling
/// the whole program from scratch.
///
/// Each invocation of [computeDelta] must be followed by invocation of either
/// [acceptLastDelta] or [rejectLastDelta].  [acceptLastDelta] makes the
/// "last program state" the "current program state".  [rejectLastDelta] simply
/// discards the "last program state", so that the "current program state"
/// stays the same.
///
/// This class also maintains a set of "valid sources", which is a (possibly
/// empty) subset of the sources constituting the previous program state.  Files
/// in this set are assumed to be unchanged since the last call to
/// [computeDelta].
///
/// Behavior is undefined if the client does not obey the following concurrency
/// restrictions:
/// - no two invocations of [computeDelta] may be outstanding at any given time.
/// - [invalidate] may not be called while an invocation of [computeDelta] is
///   outstanding.
///
/// Not intended to be implemented or extended by clients.
abstract class IncrementalKernelGenerator {
  /// Notify the generator that the last [DeltaProgram] returned from the
  /// [computeDelta] was accepted.  So, the "last program state" becomes the
  /// "current program state", and the next invocation of [computeDelta] will
  /// not include the libraries of the last delta, unless these libraries are
  /// affected by [invalidate] since the last [computeDelta].
  void acceptLastDelta();

  /// Generates a kernel representation of the changes to the program, assuming
  /// that all valid sources are unchanged since the last call to
  /// [computeDelta].
  ///
  /// Source files in the set of valid sources are guaranteed not to be re-read
  /// from disk; they are assumed to be unchanged regardless of the state of the
  /// filesystem.
  ///
  /// If the future completes successfully, the previous file state is updated
  /// and the set of valid sources is set to the set of all sources in the
  /// program.
  ///
  /// If the future completes with an error (due to errors in the compiled
  /// source code), the caller may consider the previous file state and the set
  /// of valid sources to be unchanged; this means that once the user fixes the
  /// errors, it is safe to call [computeDelta] again.
  ///
  /// Each invocation of [computeDelta] must be followed by invocation of
  /// either [acceptLastDelta] or [rejectLastDelta].
  Future<DeltaProgram> computeDelta();

  /// Remove the file associated with the given file [uri] from the set of
  /// valid files.  This guarantees that those files will be re-read on the
  /// next call to [computeDelta]).
  void invalidate(Uri uri);

  /// Notify the generator that the last [DeltaProgram] returned from the
  /// [computeDelta] was rejected.  The "last program state" is discarded and
  /// the "current program state" is kept unchanged.
  void rejectLastDelta();

  /// Notify the generator that the client wants to reset the "current program
  /// state" to nothing, so that the next invocation of [computeDelta] will
  /// include all the program libraries.  Neither [acceptLastDelta] nor
  /// [rejectLastDelta] are allowed after this method until the next
  /// [computeDelta] invocation.
  void reset();

  /// Set the "current program state", so that the next invocation of
  /// [computeDelta] will include only libraries changed since this [state].
  ///
  /// The [state] must be a value returned in [DeltaProgram.state].
  void setState(String state);

  /// Creates an [IncrementalKernelGenerator] which is prepared to generate
  /// kernel representations of the program whose main library is in the given
  /// [entryPoint].
  ///
  /// The initial "previous program state" is an empty program containing no
  /// code, and the initial set of valid sources is empty.  To obtain a kernel
  /// representation of the program, call [computeDelta].
  static Future<IncrementalKernelGenerator> newInstance(
      CompilerOptions options, Uri entryPoint,
      {WatchUsedFilesFn watch, bool useMinimalGenerator: false}) async {
    var processedOptions = new ProcessedOptions(options, false, [entryPoint]);
    return await CompilerContext.runWithOptions(processedOptions, (_) async {
      var uriTranslator = await processedOptions.getUriTranslator();
      var sdkOutlineBytes = await processedOptions.loadSdkSummaryBytes();
      if (useMinimalGenerator) {
        return new MinimalIncrementalKernelGenerator(
            processedOptions, uriTranslator, sdkOutlineBytes, entryPoint,
            watch: watch);
      } else {
        return new IncrementalKernelGeneratorImpl(
            processedOptions, uriTranslator, sdkOutlineBytes, entryPoint,
            watch: watch);
      }
    });
  }
}
