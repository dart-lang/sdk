// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.search_result;

import 'package:analysis_server/src/computer/element.dart';
import 'package:analysis_server/src/constants.dart';
import 'package:analysis_server/src/services/json.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart' as engine;


/**
 * A single result from a search request.
 */
class SearchResult implements HasToJson {
  /**
   * The kind of element that was found or the kind of reference that was found.
   */
  final SearchResultKind kind;

  /**
   * Is `true` if the result is a potential match but cannot be confirmed to be
   * a match.
   *
   * For example, if all references to a method `m` defined in some class were
   * requested, and a reference to a method `m` from an unknown class were
   * found, it would be marked as being a potential match.
   */
  final bool isPotential;

  /**
   * The location of the code that matched the search criteria.
   */
  final Location location;

  /**
   * The elements that contain the result, starting with the most immediately
   * enclosing ancestor and ending with the library.
   */
  final List<Element> path;

  SearchResult(this.kind, this.isPotential, this.location, this.path);

  factory SearchResult.fromJson(Map<String, Object> map) {
    SearchResultKind kind = new SearchResultKind.fromName(map[KIND]);
    bool isPotential = map[IS_POTENTIAL];
    Location location = new Location.fromJson(map[LOCATION]);
    List<Map<String, Object>> pathJson = map[PATH];
    List<Element> path = pathJson.map((json) {
      return new Element.fromJson(json);
    }).toList();
    return new SearchResult(kind, isPotential, location, path);
  }

  factory SearchResult.fromMatch(SearchMatch match) {
    SearchResultKind kind = new SearchResultKind.fromEngine(match.kind);
    Location location =
        new Location.fromOffset(
            match.element,
            match.sourceRange.offset,
            match.sourceRange.length);
    List<Element> path = _computePath(match.element);
    return new SearchResult(kind, !match.isResolved, location, path);
  }

  Map<String, Object> toJson() {
    return {
      KIND: kind.name,
      IS_POTENTIAL: isPotential,
      LOCATION: location.toJson(),
      PATH: path.map(Element.asJson).toList()
    };
  }

  @override
  String toString() => toJson().toString();

  static Map<String, Object> asJson(SearchResult result) {
    return result.toJson();
  }

  static List<Element> _computePath(engine.Element element) {
    List<Element> path = <Element>[];
    while (element != null) {
      path.add(new Element.fromEngine(element));
      element = element.enclosingElement;
    }
    return path;
  }
}


/**
 * An enumeration of the kinds of search results returned by the search domain.
 */
class SearchResultKind {
  static const DECLARATION = const SearchResultKind('DECLARATION');
  static const READ = const SearchResultKind('READ');
  static const READ_WRITE = const SearchResultKind('READ_WRITE');
  static const WRITE = const SearchResultKind('WRITE');
  static const INVOCATION = const SearchResultKind('INVOCATION');
  static const REFERENCE = const SearchResultKind('REFERENCE');
  static const UNKNOWN = const SearchResultKind('UNKNOWN');

  final String name;

  const SearchResultKind(this.name);

  factory SearchResultKind.fromEngine(MatchKind kind) {
    if (kind == MatchKind.DECLARATION) {
      return DECLARATION;
    }
    if (kind == MatchKind.READ) {
      return READ;
    }
    if (kind == MatchKind.READ_WRITE) {
      return READ_WRITE;
    }
    if (kind == MatchKind.WRITE) {
      return WRITE;
    }
    if (kind == MatchKind.INVOCATION) {
      return INVOCATION;
    }
    if (kind == MatchKind.REFERENCE) {
      return REFERENCE;
    }
    return UNKNOWN;
  }

  factory SearchResultKind.fromName(String name) {
    if (name == DECLARATION.name) {
      return DECLARATION;
    }
    if (name == READ.name) {
      return READ;
    }
    if (name == READ_WRITE.name) {
      return READ_WRITE;
    }
    if (name == WRITE.name) {
      return WRITE;
    }
    if (name == INVOCATION.name) {
      return INVOCATION;
    }
    if (name == REFERENCE.name) {
      return REFERENCE;
    }
    return UNKNOWN;
  }

  @override
  String toString() => name;
}
