// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/error/error.dart';
import 'package:analyzer/file_system/file_system.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceChange;
import 'package:analyzer_plugin/utilities/fixes/fixes.dart';

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
   * relevant fixes will be sorted before fixes with a lower relevance. Fixes
   * with the same relevance are sorted alphabetically.
   */
  static final Comparator<Fix> SORT_BY_RELEVANCE = (Fix a, Fix b) {
    if (a.kind.priority != b.kind.priority) {
      return a.kind.priority - b.kind.priority;
    }
    return a.change.message.compareTo(b.change.message);
  };

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
   * The analysis driver used to access analysis results.
   */
  AnalysisDriver get analysisDriver;

  /**
   * The error to fix, should be reported by the given [analysisDriver].
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
