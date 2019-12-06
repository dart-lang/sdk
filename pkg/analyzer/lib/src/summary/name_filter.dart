// Copyright (c) 2016, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';

/**
 * A [NameFilter] represents the set of filtering rules implied by zero or more
 * combinators in an `export` or `import` statement.
 */
class NameFilter {
  /**
   * A [NameFilter] representing no filtering at all (i.e. no combinators).
   */
  static final NameFilter identity = NameFilter._(hiddenNames: Set<String>());

  /**
   * If this [NameFilter] accepts a finite number of names and hides all
   * others, the (possibly empty) set of names it accepts.  Otherwise `null`.
   */
  final Set<String> shownNames;

  /**
   * If [shownNames] is `null`, the (possibly empty) set of names not accepted
   * by this filter (all other names are accepted).  If [shownNames] is not
   * `null`, then [hiddenNames] will be `null`.
   */
  final Set<String> hiddenNames;

  factory NameFilter({List<String> shows, List<String> hides}) {
    return NameFilter._(
      shownNames: shows?.toSet(),
      hiddenNames: hides?.toSet(),
    );
  }

  /**
   * Create a [NameFilter] based on the given [combinator].
   */
  factory NameFilter.forNamespaceCombinator(NamespaceCombinator combinator) {
    if (combinator is ShowElementCombinator) {
      return NameFilter._(shownNames: combinator.shownNames.toSet());
    } else if (combinator is HideElementCombinator) {
      return NameFilter._(hiddenNames: combinator.hiddenNames.toSet());
    } else {
      throw StateError('Unexpected combinator type ${combinator.runtimeType}');
    }
  }

  /**
   * Create a [NameFilter] based on the given (possibly empty) sequence of
   * [combinators].
   */
  factory NameFilter.forNamespaceCombinators(
      List<NamespaceCombinator> combinators) {
    NameFilter result = identity;
    for (NamespaceCombinator combinator in combinators) {
      result = result.merge(NameFilter.forNamespaceCombinator(combinator));
    }
    return result;
  }

  const NameFilter._({this.shownNames, this.hiddenNames});

  /**
   * Determine if the given [name] is accepted by this [NameFilter].
   */
  bool accepts(String name) {
    if (name.endsWith('=')) {
      name = name.substring(0, name.length - 1);
    }
    if (shownNames != null) {
      return shownNames.contains(name);
    } else {
      return !hiddenNames.contains(name);
    }
  }

  /**
   * Produce a new [NameFilter] by combining this [NameFilter] with another
   * one.  The new [NameFilter] will only accept names that would be accepted
   * by both input filters.
   */
  NameFilter merge(NameFilter other) {
    if (shownNames != null) {
      if (other.shownNames != null) {
        return NameFilter._(
            shownNames: shownNames.intersection(other.shownNames));
      } else {
        return NameFilter._(
            shownNames: shownNames.difference(other.hiddenNames));
      }
    } else {
      if (other.shownNames != null) {
        return NameFilter._(
            shownNames: other.shownNames.difference(hiddenNames));
      } else {
        return NameFilter._(hiddenNames: hiddenNames.union(other.hiddenNames));
      }
    }
  }
}
