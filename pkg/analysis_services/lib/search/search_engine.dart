// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.search_engine;

import 'dart:async';

import 'package:analysis_services/index/index.dart';
import 'package:analysis_services/src/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart';
import 'package:analyzer/src/generated/java_core.dart';
import 'package:analyzer/src/generated/source.dart';


/**
 * A [Comparator] that can be used to sort the [SearchMatch]s based on the names
 * of the matched elements.
 */
final Comparator<SearchMatch> SEARCH_MATCH_NAME_COMPARATOR =
    (SearchMatch firstMatch, SearchMatch secondMatch) {
  String firstName = firstMatch.element.displayName;
  String secondName = secondMatch.element.displayName;
  return firstName.compareTo(secondName);
};


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
   * A declaration of a class.
   */
  static const MatchKind CLASS_DECLARATION =
      const MatchKind('CLASS_DECLARATION');

  /**
   * A declaration of a class alias.
   */
  static const MatchKind CLASS_ALIAS_DECLARATION =
      const MatchKind('CLASS_ALIAS_DECLARATION');

  /**
   * A declaration of a constructor.
   */
  static const MatchKind CONSTRUCTOR_DECLARATION =
      const MatchKind('CONSTRUCTOR_DECLARATION');

  /**
   * A reference to a constructor in which the constructor is being referenced.
   */
  static const MatchKind CONSTRUCTOR_REFERENCE =
      const MatchKind('CONSTRUCTOR_REFERENCE');

  /**
   * A reference to a type in which the type was extended.
   */
  static const MatchKind EXTENDS_REFERENCE =
      const MatchKind('EXTENDS_REFERENCE');

  /**
   * A reference to a field in which the field's value is being invoked.
   */
  static const MatchKind FIELD_INVOCATION = const MatchKind('FIELD_INVOCATION');

  /**
   * A reference to a field (from field formal parameter).
   */
  static const MatchKind FIELD_REFERENCE = const MatchKind('FIELD_REFERENCE');

  /**
   * A reference to a field in which the field's value is being read.
   */
  static const MatchKind FIELD_READ = const MatchKind('FIELD_READ');

  /**
   * A reference to a field in which the field's value is being written.
   */
  static const MatchKind FIELD_WRITE = const MatchKind('FIELD_WRITE');

  /**
   * A declaration of a function.
   */
  static const MatchKind FUNCTION_DECLARATION =
      const MatchKind('FUNCTION_DECLARATION');

  /**
   * A reference to a function in which the function is being executed.
   */
  static const MatchKind FUNCTION_EXECUTION =
      const MatchKind('FUNCTION_EXECUTION');

  /**
   * A reference to a function in which the function is being referenced.
   */
  static const MatchKind FUNCTION_REFERENCE =
      const MatchKind('FUNCTION_REFERENCE');

  /**
   * A declaration of a function type.
   */
  static const MatchKind FUNCTION_TYPE_DECLARATION =
      const MatchKind('FUNCTION_TYPE_DECLARATION');

  /**
   * A reference to a function type.
   */
  static const MatchKind FUNCTION_TYPE_REFERENCE =
      const MatchKind('FUNCTION_TYPE_REFERENCE');

  /**
   * A reference to a type in which the type was implemented.
   */
  static const MatchKind IMPLEMENTS_REFERENCE =
      const MatchKind('IMPLEMENTS_REFERENCE');

  /**
   * A reference to a [ImportElement].
   */
  static const MatchKind IMPORT_REFERENCE = const MatchKind('IMPORT_REFERENCE');

  /**
   * A reference to a class that is implementing a specified type.
   */
  static const MatchKind INTERFACE_IMPLEMENTED =
      const MatchKind('INTERFACE_IMPLEMENTED');

  /**
   * A reference to a [LibraryElement].
   */
  static const MatchKind LIBRARY_REFERENCE =
      const MatchKind('LIBRARY_REFERENCE');

  /**
   * A reference to a method in which the method is being invoked.
   */
  static const MatchKind METHOD_INVOCATION =
      const MatchKind('METHOD_INVOCATION');

  /**
   * A reference to a method in which the method is being referenced.
   */
  static const MatchKind METHOD_REFERENCE = const MatchKind('METHOD_REFERENCE');

  /**
   * A declaration of a name.
   */
  static const MatchKind NAME_DECLARATION = const MatchKind('NAME_DECLARATION');

  /**
   * A reference to a name, resolved.
   */
  static const MatchKind NAME_REFERENCE_RESOLVED =
      const MatchKind('NAME_REFERENCE_RESOLVED');

  /**
   * An invocation of a name, resolved.
   */
  static const MatchKind NAME_INVOCATION_RESOLVED =
      const MatchKind('NAME_INVOCATION_RESOLVED');

  /**
   * A reference to a name in which the name's value is being read.
   */
  static const MatchKind NAME_READ_RESOLVED =
      const MatchKind('NAME_READ_RESOLVED');

  /**
   * A reference to a name in which the name's value is being read and written.
   */
  static const MatchKind NAME_READ_WRITE_RESOLVED =
      const MatchKind('NAME_READ_WRITE_RESOLVED');

  /**
   * A reference to a name in which the name's value is being written.
   */
  static const MatchKind NAME_WRITE_RESOLVED =
      const MatchKind('NAME_WRITE_RESOLVED');

  /**
   * An invocation of a name, unresolved.
   */
  static const MatchKind NAME_INVOCATION_UNRESOLVED =
      const MatchKind('NAME_INVOCATION_UNRESOLVED');

  /**
   * A reference to a name in which the name's value is being read.
   */
  static const MatchKind NAME_READ_UNRESOLVED =
      const MatchKind('NAME_READ_UNRESOLVED');

  /**
   * A reference to a name in which the name's value is being read and written.
   */
  static const MatchKind NAME_READ_WRITE_UNRESOLVED =
      const MatchKind('NAME_READ_WRITE_UNRESOLVED');

  /**
   * A reference to a name in which the name's value is being written.
   */
  static const MatchKind NAME_WRITE_UNRESOLVED =
      const MatchKind('NAME_WRITE_UNRESOLVED');

  /**
   * A reference to a name, unresolved.
   */
  static const MatchKind NAME_REFERENCE_UNRESOLVED =
      const MatchKind('NAME_REFERENCE_UNRESOLVED');

  /**
   * A reference to a named parameter in invocation.
   */
  static const MatchKind NAMED_PARAMETER_REFERENCE =
      const MatchKind('NAMED_PARAMETER_REFERENCE');

  /**
   * A reference to a property accessor.
   */
  static const MatchKind PROPERTY_ACCESSOR_REFERENCE =
      const MatchKind('PROPERTY_ACCESSOR_REFERENCE');

  /**
   * A reference to a type.
   */
  static const MatchKind TYPE_REFERENCE = const MatchKind('TYPE_REFERENCE');

  /**
   * A reference to a type parameter.
   */
  static const MatchKind TYPE_PARAMETER_REFERENCE =
      const MatchKind('TYPE_PARAMETER_REFERENCE');

  /**
   * A reference to a [CompilationUnitElement].
   */
  static const MatchKind UNIT_REFERENCE = const MatchKind('UNIT_REFERENCE');

  /**
   * A declaration of a variable.
   */
  static const MatchKind VARIABLE_DECLARATION =
      const MatchKind('VARIABLE_DECLARATION');

  /**
   * A reference to a variable in which the variable's value is being read.
   */
  static const MatchKind VARIABLE_READ = const MatchKind('VARIABLE_READ');

  /**
   * A reference to a variable in which the variable's value is being both read
   * and write.
   */
  static const MatchKind VARIABLE_READ_WRITE =
      const MatchKind('VARIABLE_READ_WRITE');

  /**
   * A reference to a variable in which the variables's value is being written.
   */
  static const MatchKind VARIABLE_WRITE = const MatchKind('VARIABLE_WRITE');

  /**
   * A reference to a type in which the type was mixed in.
   */
  static const MatchKind WITH_REFERENCE = const MatchKind('WITH_REFERENCE');

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
