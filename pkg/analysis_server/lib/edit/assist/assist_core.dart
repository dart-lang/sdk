// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analysis_server.edit.assist.assist_core;

import 'package:analysis_server/src/protocol.dart' show SourceChange;
import 'package:analyzer/src/generated/engine.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * A description of a single proposed assist.
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
  static final Comparator<Assist> SORT_BY_RELEVANCE = (Assist firstAssist,
          Assist secondAssist) =>
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
 * An object used to produce assists for a specific location.
 */
abstract class AssistContributor {
  /**
   * Return a list of assists for a location in the given [source]. The location
   * is specified by the [offset] and [length] of the selected region. The
   * [context] can be used to get additional information that is useful for
   * computing assists.
   */
  List<Assist> computeAssists(
      AnalysisContext context, Source source, int offset, int length);
}

/**
 * A description of a class of assists. Instances are intended to hold the
 * information that is common across a number of assists and to be shared by
 * those assists.
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
