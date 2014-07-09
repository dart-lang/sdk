// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This code was auto-generated, is not intended to be edited, and is subject to
// significant change. Please see the README file for more information.

library engine.search_engine;

import 'dart:async';

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
 * Instances of the enum [MatchKind] represent the kind of reference that was
 * found when a match represents a reference to an element.
 */
class MatchKind extends Enum<MatchKind> {
  /**
   * A reference to an Angular element.
   */
  static const MatchKind ANGULAR_REFERENCE = const MatchKind(
      'ANGULAR_REFERENCE', 0);

  /**
   * A reference to an Angular element.
   */
  static const MatchKind ANGULAR_CLOSING_TAG_REFERENCE = const MatchKind(
      'ANGULAR_CLOSING_TAG_REFERENCE', 1);

  /**
   * A declaration of a class.
   */
  static const MatchKind CLASS_DECLARATION = const MatchKind(
      'CLASS_DECLARATION', 2);

  /**
   * A declaration of a class alias.
   */
  static const MatchKind CLASS_ALIAS_DECLARATION = const MatchKind(
      'CLASS_ALIAS_DECLARATION', 3);

  /**
   * A declaration of a constructor.
   */
  static const MatchKind CONSTRUCTOR_DECLARATION = const MatchKind(
      'CONSTRUCTOR_DECLARATION', 4);

  /**
   * A reference to a constructor in which the constructor is being referenced.
   */
  static const MatchKind CONSTRUCTOR_REFERENCE = const MatchKind(
      'CONSTRUCTOR_REFERENCE', 5);

  /**
   * A reference to a type in which the type was extended.
   */
  static const MatchKind EXTENDS_REFERENCE = const MatchKind(
      'EXTENDS_REFERENCE', 6);

  /**
   * A reference to a field in which the field's value is being invoked.
   */
  static const MatchKind FIELD_INVOCATION = const MatchKind('FIELD_INVOCATION',
      7);

  /**
   * A reference to a field (from field formal parameter).
   */
  static const MatchKind FIELD_REFERENCE = const MatchKind('FIELD_REFERENCE',
      8);

  /**
   * A reference to a field in which the field's value is being read.
   */
  static const MatchKind FIELD_READ = const MatchKind('FIELD_READ', 9);

  /**
   * A reference to a field in which the field's value is being written.
   */
  static const MatchKind FIELD_WRITE = const MatchKind('FIELD_WRITE', 10);

  /**
   * A declaration of a function.
   */
  static const MatchKind FUNCTION_DECLARATION = const MatchKind(
      'FUNCTION_DECLARATION', 11);

  /**
   * A reference to a function in which the function is being executed.
   */
  static const MatchKind FUNCTION_EXECUTION = const MatchKind(
      'FUNCTION_EXECUTION', 12);

  /**
   * A reference to a function in which the function is being referenced.
   */
  static const MatchKind FUNCTION_REFERENCE = const MatchKind(
      'FUNCTION_REFERENCE', 13);

  /**
   * A declaration of a function type.
   */
  static const MatchKind FUNCTION_TYPE_DECLARATION = const MatchKind(
      'FUNCTION_TYPE_DECLARATION', 14);

  /**
   * A reference to a function type.
   */
  static const MatchKind FUNCTION_TYPE_REFERENCE = const MatchKind(
      'FUNCTION_TYPE_REFERENCE', 15);

  /**
   * A reference to a type in which the type was implemented.
   */
  static const MatchKind IMPLEMENTS_REFERENCE = const MatchKind(
      'IMPLEMENTS_REFERENCE', 16);

  /**
   * A reference to a [ImportElement].
   */
  static const MatchKind IMPORT_REFERENCE = const MatchKind('IMPORT_REFERENCE',
      17);

  /**
   * A reference to a class that is implementing a specified type.
   */
  static const MatchKind INTERFACE_IMPLEMENTED = const MatchKind(
      'INTERFACE_IMPLEMENTED', 18);

  /**
   * A reference to a [LibraryElement].
   */
  static const MatchKind LIBRARY_REFERENCE = const MatchKind(
      'LIBRARY_REFERENCE', 19);

  /**
   * A reference to a method in which the method is being invoked.
   */
  static const MatchKind METHOD_INVOCATION = const MatchKind(
      'METHOD_INVOCATION', 20);

  /**
   * A reference to a method in which the method is being referenced.
   */
  static const MatchKind METHOD_REFERENCE = const MatchKind('METHOD_REFERENCE',
      21);

  /**
   * A declaration of a name.
   */
  static const MatchKind NAME_DECLARATION = const MatchKind('NAME_DECLARATION',
      22);

  /**
   * A reference to a name, resolved.
   */
  static const MatchKind NAME_REFERENCE_RESOLVED = const MatchKind(
      'NAME_REFERENCE_RESOLVED', 23);

  /**
   * An invocation of a name, resolved.
   */
  static const MatchKind NAME_INVOCATION_RESOLVED = const MatchKind(
      'NAME_INVOCATION_RESOLVED', 24);

  /**
   * A reference to a name in which the name's value is being read.
   */
  static const MatchKind NAME_READ_RESOLVED = const MatchKind(
      'NAME_READ_RESOLVED', 25);

  /**
   * A reference to a name in which the name's value is being read and written.
   */
  static const MatchKind NAME_READ_WRITE_RESOLVED = const MatchKind(
      'NAME_READ_WRITE_RESOLVED', 26);

  /**
   * A reference to a name in which the name's value is being written.
   */
  static const MatchKind NAME_WRITE_RESOLVED = const MatchKind(
      'NAME_WRITE_RESOLVED', 27);

  /**
   * An invocation of a name, unresolved.
   */
  static const MatchKind NAME_INVOCATION_UNRESOLVED = const MatchKind(
      'NAME_INVOCATION_UNRESOLVED', 28);

  /**
   * A reference to a name in which the name's value is being read.
   */
  static const MatchKind NAME_READ_UNRESOLVED = const MatchKind(
      'NAME_READ_UNRESOLVED', 29);

  /**
   * A reference to a name in which the name's value is being read and written.
   */
  static const MatchKind NAME_READ_WRITE_UNRESOLVED = const MatchKind(
      'NAME_READ_WRITE_UNRESOLVED', 30);

  /**
   * A reference to a name in which the name's value is being written.
   */
  static const MatchKind NAME_WRITE_UNRESOLVED = const MatchKind(
      'NAME_WRITE_UNRESOLVED', 31);

  /**
   * A reference to a name, unresolved.
   */
  static const MatchKind NAME_REFERENCE_UNRESOLVED = const MatchKind(
      'NAME_REFERENCE_UNRESOLVED', 32);

  /**
   * A reference to a named parameter in invocation.
   */
  static const MatchKind NAMED_PARAMETER_REFERENCE = const MatchKind(
      'NAMED_PARAMETER_REFERENCE', 33);

  /**
   * A reference to a property accessor.
   */
  static const MatchKind PROPERTY_ACCESSOR_REFERENCE = const MatchKind(
      'PROPERTY_ACCESSOR_REFERENCE', 34);

  /**
   * A reference to a type.
   */
  static const MatchKind TYPE_REFERENCE = const MatchKind('TYPE_REFERENCE', 35);

  /**
   * A reference to a type parameter.
   */
  static const MatchKind TYPE_PARAMETER_REFERENCE = const MatchKind(
      'TYPE_PARAMETER_REFERENCE', 36);

  /**
   * A reference to a [CompilationUnitElement].
   */
  static const MatchKind UNIT_REFERENCE = const MatchKind('UNIT_REFERENCE', 37);

  /**
   * A declaration of a variable.
   */
  static const MatchKind VARIABLE_DECLARATION = const MatchKind(
      'VARIABLE_DECLARATION', 38);

  /**
   * A reference to a variable in which the variable's value is being read.
   */
  static const MatchKind VARIABLE_READ = const MatchKind('VARIABLE_READ', 39);

  /**
   * A reference to a variable in which the variable's value is being both read
   * and write.
   */
  static const MatchKind VARIABLE_READ_WRITE = const MatchKind(
      'VARIABLE_READ_WRITE', 40);

  /**
   * A reference to a variable in which the variables's value is being written.
   */
  static const MatchKind VARIABLE_WRITE = const MatchKind('VARIABLE_WRITE', 41);

  /**
   * A reference to a type in which the type was mixed in.
   */
  static const MatchKind WITH_REFERENCE = const MatchKind('WITH_REFERENCE', 42);

  static const List<MatchKind> values = const [ANGULAR_REFERENCE,
      ANGULAR_CLOSING_TAG_REFERENCE, CLASS_DECLARATION, CLASS_ALIAS_DECLARATION,
      CONSTRUCTOR_DECLARATION, CONSTRUCTOR_REFERENCE, EXTENDS_REFERENCE,
      FIELD_INVOCATION, FIELD_REFERENCE, FIELD_READ, FIELD_WRITE,
      FUNCTION_DECLARATION, FUNCTION_EXECUTION, FUNCTION_REFERENCE,
      FUNCTION_TYPE_DECLARATION, FUNCTION_TYPE_REFERENCE, IMPLEMENTS_REFERENCE,
      IMPORT_REFERENCE, INTERFACE_IMPLEMENTED, LIBRARY_REFERENCE, METHOD_INVOCATION,
      METHOD_REFERENCE, NAME_DECLARATION, NAME_REFERENCE_RESOLVED,
      NAME_INVOCATION_RESOLVED, NAME_READ_RESOLVED, NAME_READ_WRITE_RESOLVED,
      NAME_WRITE_RESOLVED, NAME_INVOCATION_UNRESOLVED, NAME_READ_UNRESOLVED,
      NAME_READ_WRITE_UNRESOLVED, NAME_WRITE_UNRESOLVED, NAME_REFERENCE_UNRESOLVED,
      NAMED_PARAMETER_REFERENCE, PROPERTY_ACCESSOR_REFERENCE, TYPE_REFERENCE,
      TYPE_PARAMETER_REFERENCE, UNIT_REFERENCE, VARIABLE_DECLARATION, VARIABLE_READ,
      VARIABLE_READ_WRITE, VARIABLE_WRITE, WITH_REFERENCE];

  const MatchKind(String name, int ordinal) : super(name, ordinal);
}


/**
 * The interface [SearchEngine] defines the behavior of objects that can be used
 * to search for various pieces of information.
 */
abstract class SearchEngine {
//  /**
//   * Returns types assigned to the given field or top-level variable.
//   *
//   * [variable] - the field or top-level variable to find assigned types for.
//   */
//  Future<Set<DartType>> searchAssignedTypes(PropertyInducingElement variable);

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
  bool qualified = false;

  SearchMatch(this.kind, this.element, this.sourceRange, this.isResolved);

  @override
  int get hashCode => JavaArrays.makeHashCode([element, sourceRange, kind]);

  @override
  bool operator ==(Object object) {
    if (identical(object, this)) {
      return true;
    }
    if (object is SearchMatch) {
      return kind == object.kind && isResolved == object.isResolved && qualified
          == object.qualified && sourceRange == object.sourceRange && element ==
          object.element;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("SearchMatch(kind=");
    buffer.write(kind);
    buffer.write(", isResolved=");
    buffer.write(isResolved);
    buffer.write(", element=");
    buffer.write(element.displayName);
    buffer.write(", range=");
    buffer.write(sourceRange);
    buffer.write(", qualified=");
    buffer.write(qualified);
    buffer.write(")");
    return buffer.toString();
  }
}
