// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library search.search_result;

import 'package:analysis_server/src/protocol2.dart';
import 'package:analysis_server/src/services/search/search_engine.dart';
import 'package:analyzer/src/generated/element.dart' as engine;


SearchResult searchResultFromMatch(SearchMatch match) {
  SearchResultKind kind = new SearchResultKind.fromEngine(match.kind);
  Location location = new Location.fromMatch(match);
  List<Element> path = _computePath(match.element);
  return new SearchResult(location, kind, !match.isResolved, path);
}

List<Element> _computePath(engine.Element element) {
  List<Element> path = <Element>[];
  while (element != null) {
    path.add(new Element.fromEngine(element));
    element = element.enclosingElement;
  }
  return path;
}
