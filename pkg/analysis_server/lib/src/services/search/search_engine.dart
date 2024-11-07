// Copyright (c) 2014, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/source/source.dart';
import 'package:analyzer/source/source_range.dart';
import 'package:analyzer/src/dart/analysis/driver.dart';
import 'package:analyzer/src/dart/analysis/file_state.dart';
import 'package:analyzer/src/dart/analysis/search.dart';
import 'package:analyzer/src/util/performance/operation_performance.dart';

/// Instances of the enum [MatchKind] represent the kind of reference that was
/// found when a match represents a reference to an element.
class MatchKind {
  /// A declaration of an element.
  static const MatchKind DECLARATION = MatchKind('DECLARATION');

  /// A reference to an element in which it is being read.
  static const MatchKind READ = MatchKind('READ');

  /// A reference to an element in which it is being both read and written.
  static const MatchKind READ_WRITE = MatchKind('READ_WRITE');

  /// A reference to an element in which it is being written.
  static const MatchKind WRITE = MatchKind('WRITE');

  /// A reference to an element in which it is being invoked.
  static const MatchKind INVOCATION = MatchKind('INVOCATION');

  /// An invocation of an enum constructor from an enum constant without
  /// arguments.
  static const MatchKind INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS =
      MatchKind('INVOCATION_BY_ENUM_CONSTANT_WITHOUT_ARGUMENTS');

  /// A reference to an element in which it is referenced.
  static const MatchKind REFERENCE = MatchKind.reference('REFERENCE');

  /// A tear-off reference to a constructor.
  static const MatchKind REFERENCE_BY_CONSTRUCTOR_TEAR_OFF =
      MatchKind.reference('REFERENCE_BY_CONSTRUCTOR_TEAR_OFF');

  /// A reference to an element in an extends clause.
  static const MatchKind REFERENCE_IN_EXTENDS_CLAUSE = MatchKind.reference(
    'REFERENCE_IN_EXTENDS_CLAUSE',
  );

  /// A reference to an element in an implements clause.
  static const MatchKind REFERENCE_IN_IMPLEMENTS_CLAUSE = MatchKind.reference(
    'REFERENCE_IN_IMPLEMENTS_CLAUSE',
  );

  /// A reference to an element in a with clause.
  static const MatchKind REFERENCE_IN_WITH_CLAUSE = MatchKind.reference(
    'REFERENCE_IN_WITH_CLAUSE',
  );

  /// A reference to an element in an on clause.
  static const MatchKind REFERENCE_IN_ON_CLAUSE = MatchKind.reference(
    'REFERENCE_IN_ON_CLAUSE',
  );

  final String name;

  final bool isReference;

  const MatchKind(this.name) : isReference = false;

  const MatchKind.reference(this.name) : isReference = true;

  @override
  String toString() => name;
}

/// The interface [SearchEngine] defines the behavior of objects that can be
/// used to search for various pieces of information.
abstract class SearchEngine {
  /// Adds all subtypes of the given [type] into [allSubtypes].
  ///
  /// If [allSubtypes] already contains an element it is assumed that it
  /// contains the entire subtree and the element won't be search on further.
  ///
  /// [type] - the [InterfaceElement] being subtyped by the found matches.
  Future<void> appendAllSubtypes(
    InterfaceElement type,
    Set<InterfaceElement> allSubtypes,
    OperationPerformanceImpl performance,
  );

  /// If the [type] has subtypes, return the set of names of members which these
  /// subtypes declare, possibly empty.  If the [type] does not have subtypes,
  /// return `null`.
  Future<Set<String>?> membersOfSubtypes(InterfaceElement type);

  /// Returns declarations of class members with the given name.
  ///
  /// [name] - the name being declared by the found matches.
  Future<List<SearchMatch>> searchMemberDeclarations(String name);

  /// Returns all resolved and unresolved qualified references to the class
  /// members with given [name].
  ///
  /// [name] - the name being referenced by the found matches.
  Future<List<SearchMatch>> searchMemberReferences(String name);

  /// Return the prefixes used to reference the [element] in any of the
  /// compilation units in the [library]. The returned set will include an empty
  /// string if the element is referenced without a prefix.
  Future<Set<String>> searchPrefixesUsedInLibrary(
    LibraryElement library,
    Element element,
  );

  /// Returns references to the given [Element].
  ///
  /// [element] - the [Element] being referenced by the found matches.
  Future<List<SearchMatch>> searchReferences(Element element);

  /// Returns direct subtypes of the given [type].
  ///
  /// [type] - the [ClassElement] being subtyped by the found matches.
  /// [cache] - the [SearchEngineCache] used to speeding up the computation. If
  ///    empty it will be filled out and can be used on any subsequent query.
  Future<List<SearchMatch>> searchSubtypes(
    InterfaceElement type,
    SearchEngineCache cache, {
    OperationPerformanceImpl? performance,
  });

  /// Returns all the top-level declarations matching the given pattern.
  ///
  /// [pattern] the regular expression used to match the names of the
  ///    declarations to be found.
  Future<List<SearchMatch>> searchTopLevelDeclarations(String pattern);
}

class SearchEngineCache {
  List<AnalysisDriver>? drivers;
  // TODO(jensj): Can `searchedFiles` be removed?
  SearchedFiles? searchedFiles;
  Map<AnalysisDriver, List<FileState>>? assignedFiles;
}

/// Instances of the class [SearchMatch] represent a match found by
/// [SearchEngine].
abstract class SearchMatch {
  /// Return the [Element] containing the match.
  Element get element;

  /// The absolute path of the file containing the match.
  String get file;

  /// Is `true` if field or method access is done using qualifier.
  bool get isQualified;

  /// Is `true` if the match is a resolved reference to some [Element].
  bool get isResolved;

  /// The kind of the match.
  MatchKind get kind;

  /// Return the [LibraryElement] for the [file].
  LibraryElement get libraryElement;

  /// The library [Source] of the reference.
  Source get librarySource;

  /// The source range that was matched.
  SourceRange get sourceRange;

  /// The unit [Source] of the reference.
  Source get unitSource;
}
