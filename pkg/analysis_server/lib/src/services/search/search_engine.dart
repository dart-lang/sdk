// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library services.search_engine;

import 'dart:async';

import 'package:analysis_server/src/services/index/index.dart';
import 'package:analysis_server/src/services/search/search_engine_internal.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/src/dart/element/element.dart';
import 'package:analyzer/src/generated/engine.dart' show AnalysisContext;
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
   * Returns all subtypes of the given [type].
   *
   * [type] - the [ClassElement] being subtyped by the found matches.
   */
  Future<List<SearchMatch>> searchAllSubtypes(ClassElement type);

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
class SearchMatch {
  /**
   * The [AnalysisContext] containing the match.
   */
  final AnalysisContext context;

  /**
   * The URI of the source of the library containing the match.
   */
  final String libraryUri;

  /**
   * The URI of the source of the unit containing the match.
   */
  final String unitUri;

  /**
   * The kind of the match.
   */
  final MatchKind kind;

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

  Source _librarySource;
  Source _unitSource;
  LibraryElement _libraryElement;
  Element _element;

  SearchMatch(this.context, this.libraryUri, this.unitUri, this.kind,
      this.sourceRange, this.isResolved, this.isQualified);

  /**
   * Return the [Element] containing the match.
   */
  Element get element {
    if (_element == null) {
      CompilationUnitElement unitElement =
          context.getCompilationUnitElement(unitSource, librarySource);
      _ContainingElementFinder finder =
          new _ContainingElementFinder(sourceRange.offset);
      unitElement.accept(finder);
      _element = finder.containingElement;
    }
    return _element;
  }

  /**
   * The absolute path of the file containing the match.
   */
  String get file => unitSource.fullName;

  @override
  int get hashCode =>
      JavaArrays.makeHashCode([libraryUri, unitUri, kind, sourceRange]);

  /**
   * Return the [LibraryElement] for the [libraryUri] in the [context].
   */
  LibraryElement get libraryElement {
    _libraryElement ??= context.getLibraryElement(librarySource);
    return _libraryElement;
  }

  /**
   * The library [Source] of the reference.
   */
  Source get librarySource {
    _librarySource ??= context.sourceFactory.forUri(libraryUri);
    return _librarySource;
  }

  /**
   * The unit [Source] of the reference.
   */
  Source get unitSource {
    _unitSource ??= context.sourceFactory.forUri(unitUri);
    return _unitSource;
  }

  @override
  bool operator ==(Object object) {
    if (identical(object, this)) {
      return true;
    }
    if (object is SearchMatch) {
      return kind == object.kind &&
          libraryUri == object.libraryUri &&
          unitUri == object.unitUri &&
          isResolved == object.isResolved &&
          isQualified == object.isQualified &&
          sourceRange == object.sourceRange;
    }
    return false;
  }

  @override
  String toString() {
    StringBuffer buffer = new StringBuffer();
    buffer.write("SearchMatch(kind=");
    buffer.write(kind);
    buffer.write(", libraryUri=");
    buffer.write(libraryUri);
    buffer.write(", unitUri=");
    buffer.write(unitUri);
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

/**
 * A visitor that finds the deep-most [Element] that contains the [offset].
 */
class _ContainingElementFinder extends GeneralizingElementVisitor {
  final int offset;
  Element containingElement;

  _ContainingElementFinder(this.offset);

  visitElement(Element element) {
    if (element is ElementImpl) {
      if (element.codeOffset != null &&
          element.codeOffset <= offset &&
          offset <= element.codeOffset + element.codeLength) {
        containingElement = element;
        super.visitElement(element);
      }
    }
  }
}
