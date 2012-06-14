// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/** Provides client-side behavior for generated docs. */
#library('client-live-nav');

#import('dart:html');
#import('dart:json');
#import('frog/lang.dart', prefix: 'frog');
#import('classify.dart');
#import('markdown.dart', prefix: 'md');

#source('client-shared.dart');

// The names of the library and type that this page documents.
String currentLibrary = null;
String currentType = null;

// What we need to prefix relative URLs with to get them to work.
String prefix = '';

main() {
  // Figure out where we are.
  final body = document.query('body');
  currentLibrary = body.dataAttributes['library'];
  currentType = body.dataAttributes['type'];
  prefix = (currentType != null) ? '../' : '';

  enableCodeBlocks();

  // Request the navigation data so we can build the HTML for it.
  new XMLHttpRequest.get('${prefix}nav.json', (request) {
    buildNavigation(JSON.parse(request.responseText));
  });
}

/** Turns [name] into something that's safe to use as a file name. */
String sanitize(String name) => name.replaceAll(':', '_').replaceAll('/', '_');

/**
 * Takes [libraries], a JSON object representing a set of libraries and builds
 * the appropriate navigation DOM for it relative to the current library and
 * type.
 */
buildNavigation(libraries) {
  final libraryNames = libraries.getKeys();
  libraryNames.sort((a, b) => a.compareTo(b));

  final html = new StringBuffer();
  for (final libraryName in libraryNames) {
    html.add('<h2><div class="icon-library"></div>');
    if (currentLibrary == libraryName && currentType == null) {
      html.add('<strong>${md.escapeHtml(libraryName)}</strong>');
    } else {
      final url = '$prefix${sanitize(libraryName)}.html';
      html.add('<a href="$url">${md.escapeHtml(libraryName)}</a>');
    }
    html.add('</h2>');

    // Only list the types for the current library.
    if (currentLibrary == libraryName) {
      buildLibraryNavigation(html, libraries[libraryName]);
    }
  }

  // Insert it into the DOM.
  final navElement = document.query('.nav');
  navElement.innerHTML = html.toString();
}

/** Writes the navigation for the types contained by [library] to [html]. */
buildLibraryNavigation(StringBuffer html, library) {
  // Show the exception types separately.
  final types = [];
  final exceptions = [];

  for (final type in library) {
    if (type['name'].endsWith('Exception')) {
      exceptions.add(type);
    } else {
      types.add(type);
    }
  }

  if (types.length == 0 && exceptions.length == 0) return;

  writeType(String icon, type) {
    html.add('<li>');
    if (currentType == type['name']) {
      html.add(
          '<div class="icon-$icon"></div><strong>${type["name"]}</strong>');
    } else {
      html.add(
          '''
          <a href="$prefix${type["url"]}">
            <div class="icon-$icon"></div>${type["name"]}
          </a>
          ''');
    }
    html.add('</li>');
  }

  html.add('<ul class="icon">');
  types.forEach((type) => writeType(type['kind'], type));
  exceptions.forEach((type) => writeType('exception', type));
  html.add('</ul>');
}