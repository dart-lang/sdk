// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.model_helpers;

import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirrors.dart'
    as dart2js_mirrors;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../../sdk/lib/_internal/libraries.dart';

import 'models.dart';
import 'package_helpers.dart';

/// Returns a list of meta annotations assocated with a mirror.
List<Annotation> createAnnotations(DeclarationMirror mirror, Library
  owningLibrary) {
  var annotationMirrors = mirror.metadata.where((e) => e is
      dart2js_mirrors.Dart2JsConstructedConstantMirror);
  var annotations = [];
  annotationMirrors.forEach((annotation) {
    var docgenAnnotation = new Annotation(annotation, owningLibrary);
    if (!_SKIPPED_ANNOTATIONS.contains(dart2js_util.qualifiedNameOf(
        docgenAnnotation.mirror))) {
      annotations.add(docgenAnnotation);
    }
  });
  return annotations;
}

/// A declaration is private if itself is private, or the owner is private.
// Issue(12202) - A declaration is public even if it's owner is private.
bool isHidden(DeclarationSourceMirror mirror) {
  if (mirror is LibraryMirror) {
    return _isLibraryPrivate(mirror);
  } else if (mirror.owner is LibraryMirror) {
    return (mirror.isPrivate || _isLibraryPrivate(mirror.owner) ||
        mirror.isNameSynthetic);
  } else {
    return (mirror.isPrivate || isHidden(mirror.owner) ||
        mirror.isNameSynthetic);
  }
}

/// Transforms the map by calling toMap on each value in it.
Map recurseMap(Map inputMap) {
  var outputMap = {};
  inputMap.forEach((key, value) {
    if (value is Map) {
      outputMap[key] = recurseMap(value);
    } else {
      outputMap[key] = value.toMap();
    }
  });
  return outputMap;
}

Map filterMap(Map map, Function test) {
  var exported = new Map();
  map.forEach((key, value) {
    if (test(key, value)) exported[key] = value;
  });
  return exported;
}

/// Read a pubspec and return the library name given a [LibraryMirror].
String getPackageName(LibraryMirror mirror) {
  if (mirror.uri.scheme != 'file') return '';
  var rootdir = getPackageDirectory(mirror);
  if (rootdir == null) return '';
  return packageNameFor(rootdir);
}

/// Annotations that we do not display in the viewer.
const List<String> _SKIPPED_ANNOTATIONS = const [
  'metadata.DocsEditable', '_js_helper.JSName', '_js_helper.Creates',
  '_js_helper.Returns'
];

/// Returns true if a library name starts with an underscore, and false
/// otherwise.
///
/// An example that starts with _ is _js_helper.
/// An example that contains ._ is dart._collection.dev
bool _isLibraryPrivate(dart2js_mirrors.Dart2JsLibraryMirror mirror) {
  // This method is needed because LibraryMirror.isPrivate returns `false` all
  // the time.
  var sdkLibrary = LIBRARIES[dart2js_util.nameOf(mirror)];
  if (sdkLibrary != null) {
    return !sdkLibrary.documented;
  } else if (dart2js_util.nameOf(mirror).startsWith('_') || dart2js_util.nameOf(
      mirror).contains('._')) {
    return true;
  }
  return false;
}
