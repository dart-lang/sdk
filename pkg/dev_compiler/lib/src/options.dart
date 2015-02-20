// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Set of flags and options passed to the compiler
library ddc.src.options;

import 'package:ddc/config.dart';

/// Options used by ddc's TypeResolver.
class ResolverOptions {
  /// Whether to resolve 'package:' uris using the multi-package resolver.
  final bool useMultiPackage;

  /// Package root when resolving 'package:' urls the standard way.
  final String packageRoot;

  /// List of paths used for the multi-package resolver.
  final List<String> packagePaths;

  /// Whether to infer return types and field types from overriden members.
  final bool inferFromOverrides;

  /// Whether to infer types for consts and static fields by looking at
  /// identifiers on the RHS. For example, in a constant declaration like:
  ///
  ///      const A = B;
  ///
  /// We can infer the type of `A` based on the type of `B`. The current
  /// implementation of this inference is limited and will only work if `B` is
  /// defined in a different library than `A`. Because this might be surprising
  /// to users, this is turned off by default.
  final bool inferStaticsFromIdentifiers;

  /// Whether to ignore ordering issues and do a best effort in inference. When
  /// false, inference of top-levels and statics is limited to only consider
  /// expressions in the RHS for which the type is known precisely without
  /// regard of the ordering in which we apply inference. Turning this flag on
  /// will consider more expressions, including expressions where the RHS is
  /// another identifier (which [inferStaticsFromIdentifiers]).
  ///
  /// Note: this option is experimental will be removed once we have a proper
  /// implementation of inference in the future, which should handle all
  /// ordering concerns.
  final bool inferInNonStableOrder;

  /// Restrict inference of fields and top-levels to those that are final and
  /// const.
  final bool onlyInferConstsAndFinalFields;

  ResolverOptions({this.useMultiPackage: false, this.packageRoot: 'packages/',
      this.packagePaths: const [], this.inferFromOverrides: true,
      this.inferStaticsFromIdentifiers: false,
      this.inferInNonStableOrder: false,
      this.onlyInferConstsAndFinalFields: false});
}

// TODO(vsm): Merge RulesOptions and TypeOptions
/// Options used by ddc's RestrictedRules.
class RulesOptions extends TypeOptions {
  /// Whether to use covariant generics
  final bool covariantGenerics;

  /// Whether to inject casts between Dart assignable types.
  final bool relaxedCasts;

  RulesOptions({this.covariantGenerics: true, this.relaxedCasts: true});
}

/// General options used by the dev compiler.
class CompilerOptions implements RulesOptions, ResolverOptions {
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
  @override
  final bool covariantGenerics;

  /// Whether to inject casts between Dart assignable types.
  @override
  final bool relaxedCasts;

  /// Whether to resolve 'package:' uris using the multi-package resolver.
  @override
  final bool useMultiPackage;

  /// Package root when resolving 'package:' urls the standard way.
  @override
  final String packageRoot;

  /// List of paths used for the multi-package resolver.
  @override
  final List<String> packagePaths;

  /// Whether to infer return types and field types from overriden members.
  @override
  final bool inferFromOverrides;

  /// Whether to infer types for consts and static fields by looking at
  /// identifiers on the RHS.
  @override
  final bool inferStaticsFromIdentifiers;

  /// Whether to ignore ordering issue, and do a best effort in inference.
  @override
  final bool inferInNonStableOrder;

  /// Restrict inference of fields and top-levels to those that are final and
  /// const.
  @override
  final bool onlyInferConstsAndFinalFields;

  /// List of non-nullable types.
  @override
  final List<String> nonnullableTypes;

  CompilerOptions({this.checkSdk: false, this.dumpInfo: false,
      this.dumpInfoFile, this.dumpSrcDir, this.forceCompile: false,
      this.formatOutput: false, this.outputDir, this.outputDart: false,
      this.useColors: true, this.covariantGenerics: true,
      this.relaxedCasts: true, this.useMultiPackage: false,
      this.packageRoot: 'packages/', this.packagePaths: const [],
      this.inferFromOverrides: true, this.inferStaticsFromIdentifiers: false,
      this.inferInNonStableOrder: false,
      this.onlyInferConstsAndFinalFields: false,
      this.nonnullableTypes: TypeOptions.NONNULLABLE_TYPES});
}
