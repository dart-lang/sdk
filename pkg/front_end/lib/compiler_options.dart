// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library front_end.compiler_options;

import 'compilation_error.dart';
import 'file_system.dart';

/// Callback used to report errors encountered during compilation.
typedef void ErrorHandler(CompilationError error);

/// Front-end options relevant to compiler back ends.
///
/// Not intended to be implemented or extended by clients.
class CompilerOptions {
  /// The path to the Dart SDK.
  ///
  /// If `null`, the SDK will be searched for using
  /// [Platform.resolvedExecutable] as a starting point.
  ///
  /// This option is mutually exclusive with [sdkSummary].
  String sdkPath;

  /// Callback to which compilation errors should be delivered.
  ///
  /// If `null`, the first error will be reported by throwing an exception of
  /// type [CompilationError].
  ErrorHandler onError;

  /// Path to the ".packages" file.
  ///
  /// If `null`, the ".packages" file will be found via the standard
  /// package_config search algorithm.
  String packagesFilePath;

  /// Paths to the input summary files (excluding the SDK summary).  These files
  /// should all be linked summaries.  They should also be closed, in the sense
  /// that any libraries they reference should also appear in [inputSummaries]
  /// or [sdkSummary].
  List<String> inputSummaries = [];

  /// Path to the SDK summary file.
  ///
  /// This should be a linked summary.  If `null`, the SDK summary will be
  /// searched for at a default location within [sdkPath].
  ///
  /// This option is mutually exclusive with [sdkPath].  TODO(paulberry): if the
  /// VM does not contain a pickled copy of the SDK, we might need to change
  /// this.
  String sdkSummary;

  /// URI override map.
  ///
  /// This is a map from Uri to file path.  Any URI override listed in this map
  /// takes precedence over the URI resolution that would be implied by the
  /// packages file (see [packagesFilePath]) and/or [bazelRoots].
  ///
  /// If a URI is not listed in this map, then the normal URI resolution
  /// algorithm will be used.
  ///
  /// TODO(paulberry): transition analyzer and dev_compiler to use the
  /// "file:///bazel-root" mechanism, and then remove this.
  @deprecated
  Map<Uri, String> uriOverride = {};

  /// Bazel roots.
  ///
  /// Any Uri that resolves to "file:///bazel-root/$rest" will be searched for
  /// at "$root/$rest" ("$root\\$rest" in Windows), where "$root" is drawn from
  /// this list.  If the file is not found at any of those locations, the URI
  /// "file:///bazel-root/$rest" will be used directly.
  ///
  /// Intended use: if the Bazel workspace is located at path "$workspace", this
  /// could be set to `['$workspace', '$workspace/bazel-bin',
  /// '$workspace/bazel-genfiles']`, effectively overlaying source and generated
  /// files.
  List<String> bazelRoots = [];

  /// Sets the platform bit, which determines which patch files should be
  /// applied to the SDK.
  ///
  /// The value should be a power of two, and should match the `PLATFORM` bit
  /// flags in sdk/lib/_internal/sdk_library_metadata/lib/libraries.dart.  If
  /// zero, no patch files will be applied.
  int platformBit;

  /// The declared variables for use by configurable imports and constant
  /// evaluation.
  Map<String, String> declaredVariables;

  /// The [FileSystem] which should be used by the front end to access files.
  ///
  /// TODO(paulberry): once an implementation of [FileSystem] has been created
  /// which uses the actual physical file system, make that the default.
  ///
  /// All file system access performed by the front end goes through this
  /// mechanism, with one exception: if no value is specified for
  /// [packagesFilePath], the packages file is located using the actual physical
  /// file system.  TODO(paulberry): fix this.
  FileSystem fileSystem;
}
