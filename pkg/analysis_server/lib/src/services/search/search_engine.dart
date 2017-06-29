// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:async';

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/src/generated/source.dart';

/**
 * Instances of the enum [MatchKind] represent the kind of reference that was
 * found when a match represents a reference to an element.
 */
class MatchKind {
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
   * If the [type] has subtypes, return the set of names of members which these
   * subtypes declare, possibly empty.  If the [type] does not have subtypes,
   * return `null`.
   */
  Future<Set<String>> membersOfSubtypes(ClassElement type);

  /**
   * Returns all subtypes of the given [type].
   *
   * [type] - the [ClassElement] being subtyped by the found matches.
   */
  Future<Set<ClassElement>> searchAllSubtypes(ClassElement type);

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
   * Returns direct subtypes of the given [type].
   *
   * [type] - the [ClassElement] being subtyped by the found matches.
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
abstract class SearchMatch {
  /**
   * Return the [Element] containing the match. Can return `null` if the unit
   * does not exist, or its element was invalidated, or the element cannot be
   * found, etc.
   */
  Element get element;

  /**
   * The absolute path of the file containing the match.
   */
  String get file;

  /**
   * Is `true` if field or method access is done using qualifier.
   */
  bool get isQualified;

  /**
   * Is `true` if the match is a resolved reference to some [Element].
   */
  bool get isResolved;

  /**
   * The kind of the match.
   */
  MatchKind get kind;

  /**
   * Return the [LibraryElement] for the [libraryUri] in the [context].
   */
  LibraryElement get libraryElement;

  /**
   * The library [Source] of the reference.
   */
  Source get librarySource;

  /**
   * The source range that was matched.
   */
  SourceRange get sourceRange;

  /**
   * The unit [Source] of the reference.
   */
  Source get unitSource;

  /**
   * Return elements of [matches] which has not-null elements.
   *
   * When [SearchMatch.element] is not `null` we cache its value, so it cannot
   * become `null` later.
   */
  static List<SearchMatch> withNotNullElement(List<SearchMatch> matches) {
    return matches.where((match) => match.element != null).toList();
  }
}
