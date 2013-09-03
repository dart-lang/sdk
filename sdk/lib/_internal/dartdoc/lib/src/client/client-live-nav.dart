// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Provides client-side behavior for generated docs. */
library client;

import 'dart:html';
import 'dart:convert';
// TODO(rnystrom): Use "package:" URL (#4968).
import '../../classify.dart';
import '../../markdown.dart' as md;
import '../dartdoc/nav.dart';
import 'dropdown.dart';
import 'search.dart';
import 'client-shared.dart';

main() {
  setup();

  // Request the navigation data so we can build the HTML for it.
  HttpRequest.getString('${prefix}nav.json').then((text) {
    var json = JSON.decode(text);
    buildNavigation(json);
    setupSearch(json);
  });
}


/**
 * Takes [libraries], a JSON array representing a set of libraries and builds
 * the appropriate navigation DOM for it relative to the current library and
 * type.
 */
buildNavigation(List libraries) {
  final html = new StringBuffer();
  for (Map libraryInfo in libraries) {
    String libraryName = libraryInfo[NAME];
    html.write('<h2><div class="icon-library"></div>');
    if (currentLibrary == libraryName && currentType == null) {
      html.write('<strong>${md.escapeHtml(libraryName)}</strong>');
    } else {
      final url = getLibraryUrl(libraryName);
      html.write('<a href="$url">${md.escapeHtml(libraryName)}</a>');
    }
    html.write('</h2>');

    // Only list the types for the current library.
    if (currentLibrary == libraryName && libraryInfo.containsKey(TYPES)) {
      buildLibraryNavigation(html, libraryInfo);
    }
  }

  // Insert it into the DOM.
  final navElement = document.query('.nav');
  navElement.innerHtml = html.toString();
}

/** Writes the navigation for the types contained by [library] to [html]. */
buildLibraryNavigation(StringBuffer html, Map libraryInfo) {
  // Show the exception types separately.
  final types = [];
  final exceptions = [];

  for (Map typeInfo in libraryInfo[TYPES]) {
    var name = typeInfo[NAME];
    if (name.endsWith('Exception') || name.endsWith('Error')) {
      exceptions.add(typeInfo);
    } else {
      types.add(typeInfo);
    }
  }

  if (types.length == 0 && exceptions.length == 0) return;

  writeType(String icon, Map typeInfo) {
    html.write('<li>');
    if (currentType == typeInfo[NAME]) {
      html.write(
          '<div class="icon-$icon"></div><strong>${getTypeName(typeInfo)}</strong>');
    } else {
      html.write(
          '''
          <a href="${getTypeUrl(currentLibrary, typeInfo)}">
            <div class="icon-$icon"></div>${getTypeName(typeInfo)}
          </a>
          ''');
    }
    html.write('</li>');
  }

  html.write('<ul class="icon">');
  types.forEach((typeInfo) =>
      writeType(kindToString(typeInfo[KIND]), typeInfo));
  exceptions.forEach((typeInfo) => writeType('exception', typeInfo));
  html.write('</ul>');
}
