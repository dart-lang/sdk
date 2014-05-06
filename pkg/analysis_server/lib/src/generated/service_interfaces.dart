// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library service.interfaces;

import 'package:analyzer/src/generated/java_core.dart' show Enum, StringUtils;
import 'package:analyzer/src/generated/source.dart' show Source;
import 'package:analysis_services/src/generated/proposal.dart';

/**
 * The interface `Element` defines the behavior of objects that represent an information for
 * an element.
 */
abstract class Element {
  /**
   * An empty array of elements.
   */
  static final List<Element> EMPTY_ARRAY = new List<Element>(0);

  /**
   * Return the id of the element, may be `null` if there is no resolution information
   * associated with this element.
   *
   * @return the id of the element
   */
  String get id;

  /**
   * Return the kind of the element.
   *
   * @return the kind of the element
   */
  ElementKind get kind;

  /**
   * Return the length of the element's name.
   *
   * @return the length of the element's name
   */
  int get length;

  /**
   * Return the name of the element.
   *
   * @return the name of the element
   */
  String get name;

  /**
   * Return the offset to the beginning of the element's name.
   *
   * @return the offset to the beginning of the element's name
   */
  int get offset;

  /**
   * Return the parameter list for the element, or `null` if the element is not a constructor,
   * method or function. If the element has zero arguments, the string `"()"` will be
   * returned.
   *
   * @return the parameter list for the element
   */
  String get parameters;

  /**
   * Return the return type of the element, or `null` if the element is not a method or
   * function. If the element does not have a declared return type then an empty string will be
   * returned.
   *
   * @return the return type of the element
   */
  String get returnType;

  /**
   * Return the source containing the element, not `null`.
   *
   * @return the source containing the element
   */
  Source get source;

  /**
   * Return `true` if the element is abstract.
   *
   * @return `true` if the element is abstract
   */
  bool get isAbstract;

  /**
   * Return `true` if the element is private.
   *
   * @return `true` if the element is private
   */
  bool get isPrivate;

  /**
   * Return `true` if the element is a class member and is a static element.
   *
   * @return `true` if the element is a static element
   */
  bool get isStatic;
}

/**
 * The enumeration `ElementKind` defines the various kinds of [Element]s.
 */
class ElementKind extends Enum<ElementKind> {
  static const ElementKind CLASS = const ElementKind('CLASS', 0);

  static const ElementKind CLASS_TYPE_ALIAS = const ElementKind('CLASS_TYPE_ALIAS', 1);

  static const ElementKind COMPILATION_UNIT = const ElementKind('COMPILATION_UNIT', 2);

  static const ElementKind CONSTRUCTOR = const ElementKind('CONSTRUCTOR', 3);

  static const ElementKind GETTER = const ElementKind('GETTER', 4);

  static const ElementKind FIELD = const ElementKind('FIELD', 5);

  static const ElementKind FUNCTION = const ElementKind('FUNCTION', 6);

  static const ElementKind FUNCTION_TYPE_ALIAS = const ElementKind('FUNCTION_TYPE_ALIAS', 7);

  static const ElementKind LIBRARY = const ElementKind('LIBRARY', 8);

  static const ElementKind METHOD = const ElementKind('METHOD', 9);

  static const ElementKind SETTER = const ElementKind('SETTER', 10);

  static const ElementKind TOP_LEVEL_VARIABLE = const ElementKind('TOP_LEVEL_VARIABLE', 11);

  static const ElementKind UNKNOWN = const ElementKind('UNKNOWN', 12);

  static const ElementKind UNIT_TEST_CASE = const ElementKind('UNIT_TEST_CASE', 13);

  static const ElementKind UNIT_TEST_GROUP = const ElementKind('UNIT_TEST_GROUP', 14);

  static const List<ElementKind> values = const [
      CLASS,
      CLASS_TYPE_ALIAS,
      COMPILATION_UNIT,
      CONSTRUCTOR,
      GETTER,
      FIELD,
      FUNCTION,
      FUNCTION_TYPE_ALIAS,
      LIBRARY,
      METHOD,
      SETTER,
      TOP_LEVEL_VARIABLE,
      UNKNOWN,
      UNIT_TEST_CASE,
      UNIT_TEST_GROUP];

  const ElementKind(String name, int ordinal) : super(name, ordinal);
}

/**
 * The interface `HighlightRegion` defines the behavior of objects representing a particular
 * syntactic or semantic meaning associated with a source region.
 */
abstract class HighlightRegion implements SourceRegion {
  /**
   * Return the type of highlight associated with the region.
   *
   * @return the type of highlight associated with the region
   */
  HighlightType get type;
}

/**
 * The enumeration `HighlightType` defines the kinds of highlighting that can be associated
 * with a region of text.
 */
class HighlightType extends Enum<HighlightType> {
  static const HighlightType ANNOTATION = const HighlightType('ANNOTATION', 0);

  static const HighlightType BUILT_IN = const HighlightType('BUILT_IN', 1);

  static const HighlightType CLASS = const HighlightType('CLASS', 2);

  static const HighlightType COMMENT_BLOCK = const HighlightType('COMMENT_BLOCK', 3);

  static const HighlightType COMMENT_DOCUMENTATION = const HighlightType('COMMENT_DOCUMENTATION', 4);

  static const HighlightType COMMENT_END_OF_LINE = const HighlightType('COMMENT_END_OF_LINE', 5);

  static const HighlightType CONSTRUCTOR = const HighlightType('CONSTRUCTOR', 6);

  static const HighlightType DIRECTIVE = const HighlightType('DIRECTIVE', 7);

  static const HighlightType DYNAMIC_TYPE = const HighlightType('DYNAMIC_TYPE', 8);

  static const HighlightType FIELD = const HighlightType('FIELD', 9);

  static const HighlightType FIELD_STATIC = const HighlightType('FIELD_STATIC', 10);

  static const HighlightType FUNCTION_DECLARATION = const HighlightType('FUNCTION_DECLARATION', 11);

  static const HighlightType FUNCTION = const HighlightType('FUNCTION', 12);

  static const HighlightType FUNCTION_TYPE_ALIAS = const HighlightType('FUNCTION_TYPE_ALIAS', 13);

  static const HighlightType GETTER_DECLARATION = const HighlightType('GETTER_DECLARATION', 14);

  static const HighlightType KEYWORD = const HighlightType('KEYWORD', 15);

  static const HighlightType IDENTIFIER_DEFAULT = const HighlightType('IDENTIFIER_DEFAULT', 16);

  static const HighlightType IMPORT_PREFIX = const HighlightType('IMPORT_PREFIX', 17);

  static const HighlightType LITERAL_BOOLEAN = const HighlightType('LITERAL_BOOLEAN', 18);

  static const HighlightType LITERAL_DOUBLE = const HighlightType('LITERAL_DOUBLE', 19);

  static const HighlightType LITERAL_INTEGER = const HighlightType('LITERAL_INTEGER', 20);

  static const HighlightType LITERAL_LIST = const HighlightType('LITERAL_LIST', 21);

  static const HighlightType LITERAL_MAP = const HighlightType('LITERAL_MAP', 22);

  static const HighlightType LITERAL_STRING = const HighlightType('LITERAL_STRING', 23);

  static const HighlightType LOCAL_VARIABLE_DECLARATION = const HighlightType('LOCAL_VARIABLE_DECLARATION', 24);

  static const HighlightType LOCAL_VARIABLE = const HighlightType('LOCAL_VARIABLE', 25);

  static const HighlightType METHOD_DECLARATION = const HighlightType('METHOD_DECLARATION', 26);

  static const HighlightType METHOD_DECLARATION_STATIC = const HighlightType('METHOD_DECLARATION_STATIC', 27);

  static const HighlightType METHOD = const HighlightType('METHOD', 28);

  static const HighlightType METHOD_STATIC = const HighlightType('METHOD_STATIC', 29);

  static const HighlightType PARAMETER = const HighlightType('PARAMETER', 30);

  static const HighlightType SETTER_DECLARATION = const HighlightType('SETTER_DECLARATION', 31);

  static const HighlightType TOP_LEVEL_VARIABLE = const HighlightType('TOP_LEVEL_VARIABLE', 32);

  static const HighlightType TYPE_NAME_DYNAMIC = const HighlightType('TYPE_NAME_DYNAMIC', 33);

  static const HighlightType TYPE_PARAMETER = const HighlightType('TYPE_PARAMETER', 34);

  static const List<HighlightType> values = const [
      ANNOTATION,
      BUILT_IN,
      CLASS,
      COMMENT_BLOCK,
      COMMENT_DOCUMENTATION,
      COMMENT_END_OF_LINE,
      CONSTRUCTOR,
      DIRECTIVE,
      DYNAMIC_TYPE,
      FIELD,
      FIELD_STATIC,
      FUNCTION_DECLARATION,
      FUNCTION,
      FUNCTION_TYPE_ALIAS,
      GETTER_DECLARATION,
      KEYWORD,
      IDENTIFIER_DEFAULT,
      IMPORT_PREFIX,
      LITERAL_BOOLEAN,
      LITERAL_DOUBLE,
      LITERAL_INTEGER,
      LITERAL_LIST,
      LITERAL_MAP,
      LITERAL_STRING,
      LOCAL_VARIABLE_DECLARATION,
      LOCAL_VARIABLE,
      METHOD_DECLARATION,
      METHOD_DECLARATION_STATIC,
      METHOD,
      METHOD_STATIC,
      PARAMETER,
      SETTER_DECLARATION,
      TOP_LEVEL_VARIABLE,
      TYPE_NAME_DYNAMIC,
      TYPE_PARAMETER];

  const HighlightType(String name, int ordinal) : super(name, ordinal);
}

/**
 * A [SourceSetKind#LIST] implementation of [SourceSet].
 */
class ListSourceSet implements SourceSet {
  /**
   * Creates a new list-based [SourceSet] instance.
   */
  static SourceSet create(Iterable<Source> sourceCollection) {
    List<Source> sources = new List.from(sourceCollection);
    return new ListSourceSet(sources);
  }

  /**
   * Creates a new list-based [SourceSet] instance.
   */
  static SourceSet create2(List<Source> sources) => new ListSourceSet(sources);

  final List<Source> sources;

  ListSourceSet(this.sources);

  @override
  SourceSetKind get kind => SourceSetKind.LIST;

  @override
  String toString() => "[${StringUtils.join(sources, ", ")}]";
}

/**
 * The interface `MinorRefactoringsConsumer` defines the behavior of objects that consume
 * minor refactorings [CorrectionProposal]s.
 */
abstract class MinorRefactoringsConsumer {
  /**
   * A set [CorrectionProposal]s has been computed.
   *
   * @param proposals an array of computed [CorrectionProposal]s
   * @param isLastResult is `true` if this is the last set of results
   */
  void computedProposals(List<CorrectionProposal> proposals, bool isLastResult);
}

/**
 * The interface `NavigationRegion` defines the behavior of objects representing a list of
 * elements with which a source region is associated.
 */
abstract class NavigationRegion implements SourceRegion {
  /**
   * An empty array of navigation regions.
   */
  static final List<NavigationRegion> EMPTY_ARRAY = new List<NavigationRegion>(0);

  /**
   * Return the elements associated with the region.
   *
   * @return the elements associated with the region
   */
  List<Element> get targets;
}

/**
 * The enumeration `NotificationKind` defines the kinds of notification clients may subscribe
 * for.
 */
class NotificationKind extends Enum<NotificationKind> {
  static const NotificationKind ERRORS = const NotificationKind('ERRORS', 0);

  static const NotificationKind HIGHLIGHTS = const NotificationKind('HIGHLIGHTS', 1);

  static const NotificationKind NAVIGATION = const NotificationKind('NAVIGATION', 2);

  static const NotificationKind OUTLINE = const NotificationKind('OUTLINE', 3);

  static const List<NotificationKind> values = const [ERRORS, HIGHLIGHTS, NAVIGATION, OUTLINE];

  const NotificationKind(String name, int ordinal) : super(name, ordinal);
}

/**
 * The interface `Outline` defines the behavior of objects that represent an outline for an
 * element.
 */
abstract class Outline {
  /**
   * An empty array of outlines.
   */
  static final List<Outline> EMPTY_ARRAY = new List<Outline>(0);

  /**
   * Return an array containing the children outline. The array will be empty if the outline has no
   * children.
   *
   * @return an array containing the children of the element
   */
  List<Outline> get children;

  /**
   * Return the information about the element.
   *
   * @return the information about the element
   */
  Element get element;

  /**
   * Return the outline that either physically or logically encloses this outline. This will be
   * `null` if this outline is a unit outline.
   *
   * @return the outline that encloses this outline
   */
  Outline get parent;

  /**
   * Return the source range associated with this outline.
   *
   * @return the source range associated with this outline
   */
  SourceRegion get sourceRegion;
}

/**
 * The interface `SearchResult` defines the behavior of objects that represent a search
 * result.
 */
abstract class SearchResult {
  /**
   * An empty array of [SearchResult]s.
   */
  static final List<SearchResult> EMPTY_ARRAY = new List<SearchResult>(0);

  /**
   * Return the kind to this result.
   *
   * @return the kind of this result
   */
  SearchResultKind get kind;

  /**
   * Return the length of the result.
   *
   * @return the length of the result
   */
  int get length;

  /**
   * Return the offset to the beginning of the result in [getSource].
   *
   * @return the offset to the beginning of the result
   */
  int get offset;

  /**
   * Return the path to this result starting with the element that encloses it, then for its
   * enclosing element, etc up to the library.
   *
   * @return the path to this result
   */
  List<Element> get path;

  /**
   * Return the source containing the result.
   *
   * @return the source containing the result
   */
  Source get source;
}

/**
 * The enumeration `SearchResultKind` defines the various kinds of [SearchResult].
 */
class SearchResultKind extends Enum<SearchResultKind> {
  /**
   * A reference to a constructor.
   */
  static const SearchResultKind CONSTRUCTOR_REFERENCE = const SearchResultKind('CONSTRUCTOR_REFERENCE', 0);

  /**
   * A reference to a field (from field formal parameter).
   */
  static const SearchResultKind FIELD_REFERENCE = const SearchResultKind('FIELD_REFERENCE', 1);

  /**
   * A reference to a field in which it is read.
   */
  static const SearchResultKind FIELD_READ = const SearchResultKind('FIELD_READ', 2);

  /**
   * A reference to a field in which it is written.
   */
  static const SearchResultKind FIELD_WRITE = const SearchResultKind('FIELD_WRITE', 3);

  /**
   * A reference to a function in which it is invoked.
   */
  static const SearchResultKind FUNCTION_INVOCATION = const SearchResultKind('FUNCTION_INVOCATION', 4);

  /**
   * A reference to a function in which it is referenced.
   */
  static const SearchResultKind FUNCTION_REFERENCE = const SearchResultKind('FUNCTION_REFERENCE', 5);

  /**
   * A reference to a method in which it is invoked.
   */
  static const SearchResultKind METHOD_INVOCATION = const SearchResultKind('METHOD_INVOCATION', 6);

  /**
   * A reference to a method in which it is referenced.
   */
  static const SearchResultKind METHOD_REFERENCE = const SearchResultKind('METHOD_REFERENCE', 7);

  /**
   * A reference to a property accessor.
   */
  static const SearchResultKind PROPERTY_ACCESSOR_REFERENCE = const SearchResultKind('PROPERTY_ACCESSOR_REFERENCE', 8);

  /**
   * A reference to a type.
   */
  static const SearchResultKind TYPE_REFERENCE = const SearchResultKind('TYPE_REFERENCE', 9);

  /**
   * A declaration of a variable.
   */
  static const SearchResultKind VARIABLE_DECLARATION = const SearchResultKind('VARIABLE_DECLARATION', 10);

  /**
   * A reference to a variable in which it is read.
   */
  static const SearchResultKind VARIABLE_READ = const SearchResultKind('VARIABLE_READ', 11);

  /**
   * A reference to a variable in which it is both read and written.
   */
  static const SearchResultKind VARIABLE_READ_WRITE = const SearchResultKind('VARIABLE_READ_WRITE', 12);

  /**
   * A reference to a variable in which it is written.
   */
  static const SearchResultKind VARIABLE_WRITE = const SearchResultKind('VARIABLE_WRITE', 13);

  static const List<SearchResultKind> values = const [
      CONSTRUCTOR_REFERENCE,
      FIELD_REFERENCE,
      FIELD_READ,
      FIELD_WRITE,
      FUNCTION_INVOCATION,
      FUNCTION_REFERENCE,
      METHOD_INVOCATION,
      METHOD_REFERENCE,
      PROPERTY_ACCESSOR_REFERENCE,
      TYPE_REFERENCE,
      VARIABLE_DECLARATION,
      VARIABLE_READ,
      VARIABLE_READ_WRITE,
      VARIABLE_WRITE];

  const SearchResultKind(String name, int ordinal) : super(name, ordinal);
}

/**
 * The interface `SearchReferencesConsumer` defines the behavior of objects that consume
 * [SearchResult]s.
 */
abstract class SearchResultsConsumer {
  /**
   * [SearchResult]s have been computed.
   *
   * @param contextId the identifier of the context to search within
   * @param source the [Source] with element
   * @param offset the offset within the `source`
   * @param searchResults an array of [SearchResult]s computed so far
   * @param isLastResult is `true` if this is the last set of results
   */
  void computedReferences(String contextId, Source source, int offset, List<SearchResult> searchResults, bool isLastResult);
}

/**
 * The interface `SourceRegion` defines the behavior of objects representing a range of
 * characters within a [Source].
 */
abstract class SourceRegion {
  /**
   * Check if <code>x</code> is in [offset, offset + length] interval.
   */
  bool containsInclusive(int x);

  /**
   * Return the length of the region.
   *
   * @return the length of the region
   */
  int get length;

  /**
   * Return the offset to the beginning of the region.
   *
   * @return the offset to the beginning of the region
   */
  int get offset;
}

/**
 * The interface `SourceSet` defines the behavior of objects that represent a set of
 * [Source]s.
 */
abstract class SourceSet {
  /**
   * An instance of [SourceSet] for [SourceSetKind#ALL].
   */
  static final SourceSet ALL = new _ImplicitSourceSet(SourceSetKind.ALL);

  /**
   * An instance of [SourceSet] for [SourceSetKind#NON_SDK].
   */
  static final SourceSet NON_SDK = new _ImplicitSourceSet(SourceSetKind.NON_SDK);

  /**
   * An instance of [SourceSet] for [SourceSetKind#EXPLICITLY_ADDED].
   */
  static final SourceSet EXPLICITLY_ADDED = new _ImplicitSourceSet(SourceSetKind.EXPLICITLY_ADDED);

  /**
   * Return the kind of the this source set.
   */
  SourceSetKind get kind;

  /**
   * Returns [Source]s that belong to this source set, if [SourceSetKind#LIST] is used;
   * an empty array otherwise.
   */
  List<Source> get sources;
}

/**
 * The enumeration `SourceSetKind` defines the kinds of [SourceSet]s.
 */
class SourceSetKind extends Enum<SourceSetKind> {
  static const SourceSetKind ALL = const SourceSetKind('ALL', 0);

  static const SourceSetKind NON_SDK = const SourceSetKind('NON_SDK', 1);

  static const SourceSetKind EXPLICITLY_ADDED = const SourceSetKind('EXPLICITLY_ADDED', 2);

  static const SourceSetKind LIST = const SourceSetKind('LIST', 3);

  static const List<SourceSetKind> values = const [ALL, NON_SDK, EXPLICITLY_ADDED, LIST];

  const SourceSetKind(String name, int ordinal) : super(name, ordinal);
}

/**
 * An implementation of [SourceSet] for some [SourceSetKind].
 */
class _ImplicitSourceSet implements SourceSet {
  final SourceSetKind kind;

  _ImplicitSourceSet(this.kind);

  @override
  List<Source> get sources => Source.EMPTY_ARRAY;

  @override
  String toString() => kind.toString();
}