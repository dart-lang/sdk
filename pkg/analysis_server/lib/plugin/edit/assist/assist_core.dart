// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer_plugin/protocol/protocol_common.dart'
    show SourceChange;

/**
 * A description of a single proposed assist.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class Assist {
  /**
   * An empty list of assists.
   */
  static const List<Assist> EMPTY_LIST = const <Assist>[];

  /**
   * A comparator that can be used to sort assists by their relevance. The most
   * relevant assists will be sorted before assists with a lower relevance.
   */
  static final Comparator<Assist> SORT_BY_RELEVANCE =
      (Assist firstAssist, Assist secondAssist) =>
          firstAssist.kind.relevance - secondAssist.kind.relevance;

  /**
   * A description of the assist being proposed.
   */
  final AssistKind kind;

  /**
   * The change to be made in order to apply the assist.
   */
  final SourceChange change;

  /**
   * Initialize a newly created assist to have the given [kind] and [change].
   */
  Assist(this.kind, this.change);

  @override
  String toString() {
    return 'Assist(kind=$kind, change=$change)';
  }
}

/**
 * An object used to provide context information for [AssistContributor]s.
 *
 * Clients may not extend, implement or mix-in this class.
 */
abstract class AssistContext {
  /**
   * The analysis driver used to access analysis results.
   */
  AnalysisDriver get analysisDriver;

  /**
   * The length of the selection.
   */
  int get selectionLength;

  /**
   * The start of the selection.
   */
  int get selectionOffset;

  /**
   * The source to get assists in.
   */
  Source get source;
}

/**
 * An object used to produce assists for a specific location.
 *
 * Clients may implement this class when implementing plugins.
 */
abstract class AssistContributor {
  /**
   * Completes with a list of assists for the given [context].
   */
  Future<List<Assist>> computeAssists(AssistContext context);
}

/**
 * A description of a class of assists. Instances are intended to hold the
 * information that is common across a number of assists and to be shared by
 * those assists.
 *
 * Clients may not extend, implement or mix-in this class.
 */
class AssistKind {
  /**
   * The name of this kind of assist, used for debugging.
   */
  final String name;

  /**
   * The relevance of this kind of assist for the kind of error being addressed.
   */
  final int relevance;

  /**
   * A human-readable description of the changes that will be applied by this
   * kind of assist.
   */
  final String message;

  /**
   * Initialize a newly created kind of assist to have the given [name],
   * [relevance] and [message].
   */
  const AssistKind(this.name, this.relevance, this.message);

  @override
  String toString() => name;
}
