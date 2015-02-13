// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Set of flags and options passed to the compiler
library ddc.src.options;

/// Options used by ddc's TypeResolver.
class ResolverOptions {
  /// Whether to resolve 'package:' uris using the multi-package resolver.
  final bool useMultiPackage;

  /// Package root when resolving 'package:' urls the standard way.
  final String packageRoot;

  /// List of paths used for the multi-package resolver.
  final List<String> packagePaths;

  ResolverOptions({this.useMultiPackage: false, this.packageRoot: 'packages/',
      this.packagePaths: const []});
}

/// Options used by ddc's RestrictedRules.
class RulesOptions {
  /// Whether to use covariant generics
  final bool covariantGenerics;

  /// Whether to inject casts between Dart assignable types.
  final bool relaxedCasts;

  RulesOptions({this.covariantGenerics: true, this.relaxedCasts: true});
}

/// General options used by the dev compiler.
class CompilerOptions implements RulesOptions {
  /// Whether to check the sdk libraries.
  final bool checkSdk;

  /// Whether to dump summary information on the console.
  final bool dumpInfo;

  /// If not null, path to a file that will store a json representation of the
  /// summary information (only used if [dumpInfo] is true).
  final String dumpInfoFile;

  /// Directory where to dump the orignal but formatted Dart sources. This is
  /// mainly used to make it easier to compare input and output files.
  final String dumpSrcDir;

  /// Whether to force compilation of code with static errors.
  final bool forceCompile;

  /// Whether to run the dart_style formatter on the generated Dart code.
  final bool formatOutput;

  /// Output directory for generated code.
  final String outputDir;

  /// Whether to emit Dart output (false means to emit JS output).
  final bool outputDart;

  /// Whether to use colors when interacting on the console.
  final bool useColors;

  /// Whether to use covariant generics
  final bool covariantGenerics;

  /// Whether to inject casts between Dart assignable types.
  final bool relaxedCasts;

  CompilerOptions({this.checkSdk: false, this.dumpInfo: false,
      this.dumpInfoFile, this.dumpSrcDir, this.forceCompile: false,
      this.formatOutput: false, this.outputDir, this.outputDart: false,
      this.useColors: true, this.covariantGenerics: true,
      this.relaxedCasts: true});
}
