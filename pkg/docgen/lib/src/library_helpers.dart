// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.library_helpers;

import 'package:logging/logging.dart';
import 'package:markdown/markdown.dart' as markdown;

import 'exports/source_mirrors.dart';
import 'exports/mirrors_util.dart' as dart2js_util;

import 'models/indexable.dart';
import 'models/library.dart';
import 'models/dummy_mirror.dart';

typedef DeclarationMirror LookupFunction(DeclarationSourceMirror declaration,
    String name);

/// Support for [:foo:]-style code comments to the markdown parser.
final List<markdown.InlineSyntax> MARKDOWN_SYNTAXES =
  [new markdown.CodeSyntax(r'\[:\s?((?:.|\n)*?)\s?:\]')];

bool get includePrivateMembers {
  if (_includePrivate == null) {
    throw new StateError('includePrivate has not been set');
  }
  return _includePrivate;
}

void set includePrivateMembers(bool value) {
  if (value == null) throw new ArgumentError('includePrivate cannot be null');
  _includePrivate = value;
}

bool _includePrivate;

/// Return true if this item and all of its owners are all visible.
bool isFullChainVisible(Indexable item) {
  return includePrivateMembers || (!item.isPrivate && (item.owner != null ?
      isFullChainVisible(item.owner) : true));
}

/// Logger for printing out progress of documentation generation.
final Logger logger = new Logger('Docgen');

/// The dart:core library, which contains all types that are always available
/// without import.
Library coreLibrary;

/// Set of libraries declared in the SDK, so libraries that can be accessed
/// when running dart by default.
Iterable<LibraryMirror> get sdkLibraries => _sdkLibraries;
Iterable<LibraryMirror> _sdkLibraries;

////// Top level resolution functions
/// Converts all [foo] references in comments to <a>libraryName.foo</a>.
markdown.Node globalFixReference(String name) {
  // Attempt the look up the whole name up in the scope.
  String elementName = findElementInScopeWithPrefix(name, '');
  if (elementName != null) {
    return new markdown.Element.text('a', elementName);
  }
  return fixComplexReference(name);
}

/// This is a more complex reference. Try to break up if its of the form A<B>
/// where A is an alphanumeric string and B is an A, a list of B ("B, B, B"),
/// or of the form A<B>. Note: unlike other the other markdown-style links,
/// all text inside the square brackets is treated as part of the link (aka
/// the * is interpreted literally as a *, not as a indicator for bold <em>.
///
/// Example: [foo&lt;_bar_>] will produce
/// <a>resolvedFoo</a>&lt;<a>resolved_bar_</a>> rather than an italicized
/// version of resolvedBar.
markdown.Node fixComplexReference(String name) {
  // Parse into multiple elements we can try to resolve.
  var tokens = _tokenizeComplexReference(name);

  // Produce an html representation of our elements. Group unresolved and
  // plain text are grouped into "link" elements so they display as code.
  final textElements = [' ', ',', '>', _LESS_THAN];
  var accumulatedHtml = '';

  for (var token in tokens) {
    bool added = false;
    if (!textElements.contains(token)) {
      String elementName = findElementInScopeWithPrefix(token, '');
      if (elementName != null) {
        accumulatedHtml += markdown.renderToHtml([new markdown.Element.text('a',
            elementName)]);
        added = true;
      }
    }
    if (!added) {
      accumulatedHtml += token;
    }
  }
  return new markdown.Text(accumulatedHtml);
}

String findElementInScopeWithPrefix(String name, String packagePrefix) {
  var lookupFunc = determineLookupFunc(name);
  // Look in the dart core library scope.
  var coreScope = coreLibrary == null ? null : lookupFunc(coreLibrary.mirror,
      name);
  if (coreScope != null) return packagePrefix + coreLibrary.docName;

  // If it's a reference that starts with a another library name, then it
  // looks for a match of that library name in the other sdk libraries.
  if (name.contains('.')) {
    var index = name.indexOf('.');
    var libraryName = name.substring(0, index);
    var remainingName = name.substring(index + 1);
    foundLibraryName(library) => library.uri.pathSegments[0] == libraryName;

    if (_sdkLibraries.any(foundLibraryName)) {
      var library = _sdkLibraries.singleWhere(foundLibraryName);
      // Look to see if it's a fully qualified library name.
      var scope = determineLookupFunc(remainingName)(library, remainingName);
      if (scope != null) {
        var result = getDocgenObject(scope);
        if (result is DummyMirror) {
          return packagePrefix + result.docName;
        } else {
          return result.packagePrefix + result.docName;
        }
      }
    }
  }
  return null;
}

/// Given a Dart2jsMirror, find the corresponding Docgen [MirrorBased] object.
///
/// We have this global lookup function to avoid re-implementing looking up
/// the scoping rules for comment resolution here (it is currently done in
/// mirrors). If no corresponding MirrorBased object is found, we return a
/// [DummyMirror] that simply returns the original mirror's qualifiedName
/// while behaving like a MirrorBased object.
Indexable getDocgenObject(DeclarationMirror mirror, [Indexable owner]) {
  Map<String, Indexable> docgenObj = lookupIndexableMap(mirror);

  if (docgenObj == null) {
    return new DummyMirror(mirror, owner);
  }

  var setToExamine = new Set();
  if (owner != null) {
    var firstSet = docgenObj[owner.docName];
    if (firstSet != null) setToExamine.add(firstSet);
    if (coreLibrary != null && docgenObj[coreLibrary.docName] != null) {
      setToExamine.add(docgenObj[coreLibrary.docName]);
    }
  } else {
    setToExamine.addAll(docgenObj.values);
  }

  Set<Indexable> results = new Set<Indexable>();
  for (Indexable indexable in setToExamine) {
    if (indexable.mirror.qualifiedName == mirror.qualifiedName &&
        indexable.isValidMirror(mirror)) {
      results.add(indexable);
    }
  }

  if (results.length > 0) {
    // This might occur if we didn't specify an "owner."
    return results.first;
  }
  return new DummyMirror(mirror, owner);
}

void initializeTopLevelLibraries(MirrorSystem mirrorSystem) {
  _sdkLibraries = mirrorSystem.libraries.values.where(
      (each) => each.uri.scheme == 'dart');
  coreLibrary = new Library(_sdkLibraries.singleWhere((lib) =>
      lib.uri.toString().startsWith('dart:core')));
}

/// For a given name, determine if we need to resolve it as a qualified name
/// or a simple name in the source mirors.
LookupFunction determineLookupFunc(String name) => name.contains('.') ?
  dart2js_util.lookupQualifiedInScope :
    (mirror, name) => mirror.lookupInScope(name);

/// Chunk the provided name into individual parts to be resolved. We take a
/// simplistic approach to chunking, though, we break at " ", ",", "&lt;"
/// and ">". All other characters are grouped into the name to be resolved.
/// As a result, these characters will all be treated as part of the item to
/// be resolved (aka the * is interpreted literally as a *, not as an
/// indicator for bold <em>.
List<String> _tokenizeComplexReference(String name) {
  var tokens = [];
  var append = false;
  var index = 0;
  while (index < name.length) {
    if (name.indexOf(_LESS_THAN, index) == index) {
      tokens.add(_LESS_THAN);
      append = false;
      index += _LESS_THAN.length;
    } else if (name[index] == ' ' || name[index] == ',' || name[index] == '>') {
      tokens.add(name[index]);
      append = false;
      index++;
    } else {
      if (append) {
        tokens[tokens.length - 1] = tokens.last + name[index];
      } else {
        tokens.add(name[index]);
        append = true;
      }
      index++;
    }
  }
  return tokens;
}

// HTML escaped version of '<' character.
const _LESS_THAN = '&lt;';
