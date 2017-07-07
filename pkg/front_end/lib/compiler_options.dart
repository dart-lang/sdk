// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.compiler_options;

import 'package:front_end/src/base/performace_logger.dart';
import 'package:front_end/src/incremental/byte_store.dart';

import 'compilation_error.dart';
import 'file_system.dart';
import 'physical_file_system.dart';

/// Default error handler used by [CompilerOptions.onError].
void defaultErrorHandler(CompilationError error) => throw error;

/// Callback used to report errors encountered during compilation.
typedef void ErrorHandler(CompilationError error);

/// Front-end options relevant to compiler back ends.
///
/// Not intended to be implemented or extended by clients.
class CompilerOptions {
  /// The URI of the root of the Dart SDK (typically a "file:" URI).
  ///
  /// If `null`, the SDK will be searched for using
  /// [Platform.resolvedExecutable] as a starting point.
  ///
  /// This option is mutually exclusive with [sdkSummary].
  Uri sdkRoot;

  /// Map of `dart.xyz` libraries to URIs in the [fileSystem].
  /// E.g. {'core': 'file:///sdk/lib/core/core.dart'} (no `dart:` prefix).
  Map<String, Uri> dartLibraries = {};

  /// Callback to which compilation errors should be delivered.
  ///
  /// By default, the first error will be reported by throwing an exception of
  /// type [CompilationError].
  ErrorHandler onError = defaultErrorHandler;

  /// URI of the ".packages" file (typically a "file:" URI).
  ///
  /// If `null`, the ".packages" file will be found via the standard
  /// package_config search algorithm.
  ///
  /// If the URI's path component is empty (e.g. `new Uri()`), no packages file
  /// will be used.
  Uri packagesFileUri;

  /// URIs of input summary files (excluding the SDK summary; typically these
  /// will be "file:" URIs).  These files should all be linked summaries.  They
  /// should also be closed, in the sense that any libraries they reference
  /// should also appear in [inputSummaries] or [sdkSummary].
  List<Uri> inputSummaries = [];

  /// URI of the SDK summary file (typically a "file:" URI).
  ///
  /// This should be a linked summary.  If `null`, the SDK summary will be
  /// searched for at a default location within [sdkRoot].
  ///
  /// This option is mutually exclusive with [sdkRoot].  TODO(paulberry): if the
  /// VM does not contain a pickled copy of the SDK, we might need to change
  /// this.
  Uri sdkSummary;

  /// URI override map.
  ///
  /// This is a map from URIs that might appear in import/export/part statements
  /// to URIs that should be used to locate the corresponding files in the
  /// [fileSystem].  Any URI override listed in this map takes precedence over
  /// the URI resolution that would be implied by the packages file (see
  /// [packagesFileUri]) and/or [multiRoots].
  ///
  /// If a URI is not listed in this map, then the normal URI resolution
  /// algorithm will be used.
  ///
  /// TODO(paulberry): transition analyzer and dev_compiler to use the
  /// "multi-root:" mechanism, and then remove this.
  @deprecated
  Map<Uri, Uri> uriOverride = {};

  /// Multi-roots.
  ///
  /// Any Uri that resolves to "multi-root:///$rest" will be searched for
  /// at "$root/$rest", where "$root" is drawn from this list.
  ///
  /// Intended use: if the user has a Bazel workspace located at path
  /// "$workspace", this could be set to the file URIs corresponding to the
  /// paths for "$workspace", "$workspace/bazel-bin",
  /// and "$workspace/bazel-genfiles", effectively overlaying source and
  /// generated files.
  List<Uri> multiRoots = [];

  /// The declared variables for use by configurable imports and constant
  /// evaluation.
  Map<String, String> declaredVariables;

  /// The [FileSystem] which should be used by the front end to access files.
  ///
  /// All file system access performed by the front end goes through this
  /// mechanism, with one exception: if no value is specified for
  /// [packagesFileUri], the packages file is located using the actual physical
  /// file system.  TODO(paulberry): fix this.
  FileSystem fileSystem = PhysicalFileSystem.instance;

  /// The byte storage to get and put serialized data.
  ByteStore byteStore = new NullByteStore();

  /// The logger to report compilation progress.
  PerformanceLog logger = new PerformanceLog(new StringBuffer());

  /// Whether to generate code for the SDK when compiling a whole-program.
  bool compileSdk = false;

  /// Whether a modular build compiles only the files listed explicitly or if it
  /// compiles dependencies as well.
  ///
  /// This option is intended only for modular APIs like `kernelForBuildUnit`.
  /// These APIs by default ensure that builds are hermetic, where all files
  /// that will be compiled are listed explicitly and all other dependencies
  /// are covered by summary files.
  ///
  /// When this option is true, these APIs will treat any dependency that is
  /// not described in a summary as if it was explicitly listed as an input.
  bool chaseDependencies = false;

  /// Whether to interpret Dart sources in strong-mode.
  bool strongMode = true;

  // All options below are target-specific options.
  //
  // TODO(sigmund): revisit the right layout for these options. We might want to
  // split them out into a separate bag of options or provide factories for
  // common combinations of these options.

  /// Patch files to apply on the core libraries for a specific target platform.
  ///
  /// Keys on this map are expected to be `dart:*` URIs. The values can be
  /// either absolute or relative URIs. Absolute URIs are read directly, while
  /// relative URIs are resolved from the [sdkRoot].
  Map<Uri, List<Uri>> targetPatches = {};

  /// Additional core libraries to be loaded when building a program.
  // TODO(sigmund): delete. Ideally building a program only needs what's
  // reachable and we can use kernelForBuildUnit when creating a snapshot of the
  // SDK itself.
  List<Uri> additionalLibraries = [];
}
