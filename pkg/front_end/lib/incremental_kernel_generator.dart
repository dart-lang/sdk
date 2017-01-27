// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:front_end/src/base/processed_options.dart';
import 'package:front_end/src/incremental_kernel_generator_impl.dart';
import 'package:kernel/kernel.dart';

import 'compiler_options.dart';

/// Represents the difference between "old" and "new" states of a program.
///
/// Not intended to be implemented or extended by clients.
class DeltaProgram {
  /// The new state of the program.
  ///
  /// Libraries whose kernel representation is known to be unchanged since the
  /// last [DeltaProgram] are not included.
  final Map<Uri, Program> newState;

  DeltaProgram(this.newState);

  /// TODO(paulberry): add information about libraries that were removed.
}

/// Interface for generating an initial kernel representation of a program and
/// keeping it up to date as incremental changes are made.
///
/// This class maintains an internal "previous program state"; each
/// time [computeDelta] is called, it updates the previous program state and
/// produces a representation of what has changed.  When there are few changes,
/// a call to [computeDelta] should be much faster than compiling the whole
/// program from scratch.
///
/// This class also maintains a set of "valid sources", which is a (possibly
/// empty) subset of the sources constituting the previous program state.  Files
/// in this set are assumed to be unchanged since the last call to
/// [computeDelta].
///
/// Behavior is undefined if the client does not obey the following concurrency
/// restrictions:
/// - no two invocations of [computeDelta] may be outstanding at any given time.
/// - neither [invalidate] nor [invalidateAll] may be called while an invocation
///   of [computeDelta] is outstanding.
///
/// Not intended to be implemented or extended by clients.
abstract class IncrementalKernelGenerator {
  /// Creates an [IncrementalKernelGenerator] which is prepared to generate
  /// kernel representations of the program whose main library is in the given
  /// [source].
  ///
  /// No file system access is performed by this constructor; the initial
  /// "previous program state" is an empty program containing no code, and the
  /// initial set of valid sources is empty.  To obtain a kernel representation
  /// of the program, call [computeDelta].
  factory IncrementalKernelGenerator(Uri source, CompilerOptions options) =>
      new IncrementalKernelGeneratorImpl(source, new ProcessedOptions(options));

  /// Generates a kernel representation of the changes to the program, assuming
  /// that all valid sources are unchanged since the last call to
  /// [computeDelta].
  ///
  /// Source files in the set of valid sources are guaranteed not to be re-read
  /// from disk; they are assumed to be unchanged regardless of the state of the
  /// filesystem.
  ///
  /// If [watch] is not `null`, then when a source file is first used
  /// by [computeDelta], [watch] is called with the Uri of that source
  /// file and `used` == `true` indicating that the source file is being
  /// used when compiling the program. The content of the file is not read
  /// until the Future returned by [watch] completes. If during a subsequent
  /// call to [computeDelta], a source file that was being used is no longer
  /// used, then [watch] is called with the Uri of that source file and
  /// `used` == `false` indicating that the source file is no longer needed.
  /// Multiple invocations of [watch] may be running concurrently.
  ///
  /// If the future completes successfully, the previous file state is updated
  /// and the set of valid sources is set to the set of all sources in the
  /// program.
  ///
  /// If the future completes with an error (due to errors in the compiled
  /// source code), the caller may consider the previous file state and the set
  /// of valid sources to be unchanged; this means that once the user fixes the
  /// errors, it is safe to call [computeDelta] again.
  Future<DeltaProgram> computeDelta({Future<Null> watch(Uri uri, bool used)});

  /// Remove any source file(s) associated with the given file path from the set
  /// of valid sources.  This guarantees that those files will be re-read on the
  /// next call to [computeDelta]).
  void invalidate(String path);

  /// Remove all source files from the set of valid sources.  This guarantees
  /// that all files will be re-read on the next call to [computeDelta].
  ///
  /// Note that this does not erase the previous program state; the next time
  /// [computeDelta] is called, if parts of the program are discovered to be
  /// unchanged, parts of the previous program state will still be re-used to
  /// speed up compilation.
  void invalidateAll();
}
