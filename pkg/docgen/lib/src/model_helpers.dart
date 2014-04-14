// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.model_helpers;

import 'dart:collection';

import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/dart2js_mirrors.dart'
    as dart2js_mirrors;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/mirrors_util.dart'
    as dart2js_util;
import '../../../../sdk/lib/_internal/compiler/implementation/mirrors/source_mirrors.dart';
import '../../../../sdk/lib/_internal/libraries.dart';

import 'library_helpers.dart' show includePrivateMembers;
import 'models.dart';
import 'package_helpers.dart';

/// Returns a list of meta annotations assocated with a mirror.
List<Annotation> createAnnotations(DeclarationMirror mirror,
    Library owningLibrary) {
  var annotationMirrors = mirror.metadata
      .where((e) => e is dart2js_mirrors.Dart2JsConstructedConstantMirror);
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
  var outputMap = new SplayTreeMap();
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


/// Helper that maps [mirrors] to their simple name in map.
Map addAll(Map map, Iterable<DeclarationMirror> mirrors) {
  for (var mirror in mirrors) {
    map[dart2js_util.nameOf(mirror)] = mirror;
  }
  return map;
}

/// For the given library determine what items (if any) are exported.
///
/// Returns a Map with three keys: "classes", "methods", and "variables" the
/// values of which point to a map of exported name identifiers with values
/// corresponding to the actual DeclarationMirror.
Map<String, Map<String, DeclarationMirror>> calcExportedItems(
    LibrarySourceMirror library) {
  var exports = {};
  exports['classes'] = {};
  exports['methods'] = {};
  exports['variables'] = {};

  // Determine the classes, variables and methods that are exported for a
  // specific dependency.
  void _populateExports(LibraryDependencyMirror export, bool showExport) {
    if (!showExport) {
      // Add all items, and then remove the hidden ones.
      // Ex: "export foo hide bar"
      addAll(exports['classes'],
          dart2js_util.typesOf(export.targetLibrary.declarations));
      addAll(exports['methods'],
          export.targetLibrary.declarations.values.where(
              (mirror) => mirror is MethodMirror));
      addAll(exports['variables'],
          dart2js_util.variablesOf(export.targetLibrary.declarations));
    }
    for (CombinatorMirror combinator in export.combinators) {
      for (String identifier in combinator.identifiers) {
        var librarySourceMirror =
            export.targetLibrary as DeclarationSourceMirror;
        var declaration = librarySourceMirror.lookupInScope(identifier);
        if (declaration == null) {
          // Technically this should be a bug, but some of our packages
          // (such as the polymer package) are curently broken in this
          // way, so we just produce a warning.
          print('Warning identifier $identifier not found in library '
              '${dart2js_util.qualifiedNameOf(export.targetLibrary)}');
        } else {
          var subMap = exports['classes'];
          if (declaration is MethodMirror) {
            subMap = exports['methods'];
          } else if (declaration is VariableMirror) {
            subMap = exports['variables'];
          }
          if (showExport) {
            subMap[identifier] = declaration;
          } else {
            subMap.remove(identifier);
          }
        }
      }
    }
  }

  Iterable<LibraryDependencyMirror> exportList =
      library.libraryDependencies.where((lib) => lib.isExport);
  for (LibraryDependencyMirror export in exportList) {
    // If there is a show in the export, add only the show items to the
    // library. Ex: "export foo show bar"
    // Otherwise, add all items, and then remove the hidden ones.
    // Ex: "export foo hide bar"
    _populateExports(export,
        export.combinators.any((combinator) => combinator.isShow));
  }
  return exports;
}


/// Returns a map of [Variable] objects constructed from [mirrorMap].
/// The optional parameter [containingLibrary] is contains data for variables
/// defined at the top level of a library (potentially for exporting
/// purposes).
Map<String, Variable> createVariables(Iterable<VariableMirror> mirrors,
    Indexable owner) {
  var data = {};
  // TODO(janicejl): When map to map feature is created, replace the below
  // with a filter. Issue(#9590).
  mirrors.forEach((dart2js_mirrors.Dart2JsFieldMirror mirror) {
    if (includePrivateMembers || !isHidden(mirror)) {
      var mirrorName = dart2js_util.nameOf(mirror);
      data[mirrorName] = new Variable(mirrorName, mirror, owner);
    }
  });
  return data;
}

/// Returns a map of [Method] objects constructed from [mirrorMap].
/// The optional parameter [containingLibrary] is contains data for variables
/// defined at the top level of a library (potentially for exporting
/// purposes).
Map<String, Method> createMethods(Iterable<MethodMirror> mirrors,
    Indexable owner) {
  var group = new Map<String, Method>();
  mirrors.forEach((MethodMirror mirror) {
    if (includePrivateMembers || !mirror.isPrivate) {
      group[dart2js_util.nameOf(mirror)] = new Method(mirror, owner);
    }
  });
  return group;
}

/// Returns a map of [Parameter] objects constructed from [mirrorList].
Map<String, Parameter> createParameters(List<ParameterMirror> mirrorList,
    Indexable owner) {
  var data = {};
  mirrorList.forEach((ParameterMirror mirror) {
    data[dart2js_util.nameOf(mirror)] =
        new Parameter(mirror, owner.owningLibrary);
  });
  return data;
}

/// Returns a map of [Generic] objects constructed from the class mirror.
Map<String, Generic> createGenerics(TypeMirror mirror) {
  return new Map.fromIterable(mirror.typeVariables,
      key: (e) => dart2js_util.nameOf(e),
      value: (e) => new Generic(e));
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
