// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.plugin.edit.fix.fix_core;

import 'dart:async';

import 'package:analysis_server/plugin/protocol/protocol.dart'
    show SourceChange;
import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/generated/engine.dart';

/**
 * A description of a single proposed fix for some problem.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Fix {
  /**
   * An empty list of fixes.
   */
  static const List<Fix> EMPTY_LIST = const <Fix>[];

  /**
   * A comparator that can be used to sort fixes by their relevance. The most
   * relevant fixes will be sorted before fixes with a lower relevance.
   */
  static final Comparator<Fix> SORT_BY_RELEVANCE =
      (Fix firstFix, Fix secondFix) =>
          firstFix.kind.relevance - secondFix.kind.relevance;

  /**
   * A description of the fix being proposed.
   */
  final FixKind kind;

  /**
   * The change to be made in order to apply the fix.
   */
  final SourceChange change;

  /**
   * Initialize a newly created fix to have the given [kind] and [change].
   */
  Fix(this.kind, this.change);

  @override
  String toString() {
    return 'Fix(kind=$kind, change=$change)';
  }
}

/**
 * An object used to provide context information for [FixContributor]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class FixContext {
  /**
   * The [AnalysisContext] to get fixes in.
   */
  AnalysisContext get analysisContext;

  /**
   * The error to fix, should be reported in the given [analysisContext].
   */
  AnalysisError get error;

  /**
   * The [ResourceProvider] to access files and folders.
   */
  ResourceProvider get resourceProvider;
}

/**
 * An object used to produce fixes for a specific error. Fix contributors are
 * long-lived objects and must not retain any state between invocations of
 * [computeFixes].
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class FixContributor {
  /**
   * Return a list of fixes for the given [context].
   */
  Future<List<Fix>> computeFixes(FixContext context);
}

/**
 * A description of a class of fixes. Instances are intended to hold the
 * information that is common across a number of fixes and to be shared by those
 * fixes. For example, if an unnecessary cast is found then one of the suggested
 * fixes will be to remove the cast. If there are multiple unnecessary casts in
 * a single file, then there will be multiple fixes, one per occurrence, but
 * they will all share the same kind.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class FixKind {
  /**
   * The name of this kind of fix, used for debugging.
   */
  final String name;

  /**
   * The relevance of this kind of fix for the kind of error being addressed.
   */
  final int relevance;

  /**
   * A human-readable description of the changes that will be applied by this
   * kind of fix.
   */
  final String message;

  /**
   * Initialize a newly created kind of fix to have the given [name],
   * [relevance] and [message].
   */
  const FixKind(this.name, this.relevance, this.message);

  @override
  String toString() => name;
}
