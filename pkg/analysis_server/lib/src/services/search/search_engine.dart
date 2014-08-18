// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.search_engine;

import 'dart:async';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * Returns a new [SearchEngine] instance based on the given [Index].
 */
SearchEngine createSearchEngine(Index index) {
  return new SearchEngineImpl(index);
}


/**
 * Instances of the enum [MatchKind] represent the kind of reference that was
 * found when a match represents a reference to an element.
 */
class MatchKind {
  /**
   * A reference to an Angular element.
   */
  static const MatchKind ANGULAR_REFERENCE =
      const MatchKind('ANGULAR_REFERENCE');

  /**
   * A reference to an Angular element.
   */
  static const MatchKind ANGULAR_CLOSING_TAG_REFERENCE =
      const MatchKind('ANGULAR_CLOSING_TAG_REFERENCE');

  /**
   * A declaration of an element.
   */
  static const MatchKind DECLARATION = const MatchKind('DECLARATION');

  /**
   * A reference to an element in which it is being read.
   */
  static const MatchKind READ = const MatchKind('READ');

  /**
   * A reference to an element in which it is being both read and written.
   */
  static const MatchKind READ_WRITE = const MatchKind('READ_WRITE');

  /**
   * A reference to an element in which it is being written.
   */
  static const MatchKind WRITE = const MatchKind('WRITE');

  /**
   * A reference to an element in which it is being invoked.
   */
  static const MatchKind INVOCATION = const MatchKind('INVOCATION');

  /**
   * A reference to an element in which it is referenced.
   */
  static const MatchKind REFERENCE = const MatchKind('REFERENCE');

  final String name;

  const MatchKind(this.name);

  @override
  String toString() => name;
}


/**
 * The interface [SearchEngine] defines the behavior of objects that can be used
 * to search for various pieces of information.
 */
abstract class SearchEngine {
  /**
   * Returns declarations of elements with the given name.
   *
   * [name] - the name being declared by the found matches.
   */
  Future<List<SearchMatch>> searchElementDeclarations(String name);

  /**
   * Returns declarations of class members with the given name.
   *
   * [name] - the name being declared by the found matches.
   */
  Future<List<SearchMatch>> searchMemberDeclarations(String name);

  /**
   * Returns all resolved and unresolved qualified references to the class
   * members with given [name].
   *
   * [name] - the name being referenced by the found matches.
   */
  Future<List<SearchMatch>> searchMemberReferences(String name);

  /**
   * Returns references to the given [Element].
   *
   * [element] - the [Element] being referenced by the found matches.
   */
  Future<List<SearchMatch>> searchReferences(Element element);

  /**
   * Returns subtypes of the given [type].
   *
   * [type] - the [ClassElemnet] being subtyped by the found matches.
   */
  Future<List<SearchMatch>> searchSubtypes(ClassElement type);

  /**
   * Returns all the top-level declarations matching the given pattern.
   *
   * [pattern] the regular expression used to match the names of the
   *    declarations to be found.
   */
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern);
}

/**
 * Instances of the class [SearchMatch] represent a match found by
 * [SearchEngine].
 */
class SearchMatch {
  /**
   * The kind of the match.
   */
  final MatchKind kind;

  /**
   * The element containing the source range that was matched.
   */
  final Element element;

  /**
   * The source range that was matched.
   */
  final SourceRange sourceRange;

  /**
   * Is `true` if the match is a resolved reference to some [Element].
   */
  final bool isResolved;

  /**
   * Is `true` if field or method access is done using qualifier.
   */
  final bool isQualified;

  SearchMatch(this.kind, this.element, this.sourceRange, this.isResolved,
      this.isQualified);

  @override
  int get hashCode => JavaArrays.makeHashCode([element, sourceRange, kind]);

  @override
  bool operator ==(Object object) {
    if (identical(object, this)) {
      return true;
    }
    if (object is SearchMatch) {
      return kind == object.kind &&
          isResolved == object.isResolved &&
          isQualified == object.isQualified &&
          sourceRange == object.sourceRange &&
          element == object.element;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("SearchMatch(kind=");
    buffer.write(kind);
    buffer.write(", element=");
    buffer.write(element.displayName);
    buffer.write(", range=");
    buffer.write(sourceRange);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", isQualified=");
    buffer.write(isQualified);
    buffer.write(")");
    return buffer.toString();
  }
}
