// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.model_helpers;

import 'dart:collection';

import 'package:compiler/src/constants/expressions.dart';

import '../exports/dart2js_mirrors.dart' as dart2js_mirrors;
import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';
import '../exports/libraries.dart';

import '../library_helpers.dart' show includePrivateMembers;
import '../package_helpers.dart';

import 'annotation.dart';
import 'generic.dart';
import 'indexable.dart';
import 'library.dart';
import 'method.dart';
import 'parameter.dart';
import 'variable.dart';

String getLibraryDocName(LibraryMirror mirror) {
  var dotsFixed = dart2js_util.qualifiedNameOf(mirror).replaceAll('.', '-');
  if (dotsFixed.startsWith('dart-dom-')) {
    return dotsFixed.replaceFirst("dart-dom-", "dart:");
  } else if (dotsFixed.startsWith("dart-")) {
    return dotsFixed.replaceFirst("dart-", "dart:");
  } else {
    return dotsFixed;
  }
}

/// Expand the method map [mapToExpand] into a more detailed map that
/// separates out setters, getters, constructors, operators, and methods.
Map expandMethodMap(Map<String, Method> mapToExpand) => {
  'setters': recurseMap(_filterMap(mapToExpand,
      (key, val) => val.mirror.isSetter)),
  'getters': recurseMap(_filterMap(mapToExpand,
      (key, val) => val.mirror.isGetter)),
  'constructors': recurseMap(_filterMap(mapToExpand,
      (key, val) => val.mirror.isConstructor)),
  'operators': recurseMap(_filterMap(mapToExpand,
      (key, val) => val.mirror.isOperator)),
  'methods': recurseMap(_filterMap(mapToExpand,
      (key, val) => val.mirror.isRegularMethod && !val.mirror.isOperator))
};

String getDefaultValue(ParameterMirror mirror) {
  if (!mirror.hasDefaultValue) return null;
  return '${mirror.defaultValue}';
}

/// Returns a list of meta annotations assocated with a mirror.
List<Annotation> createAnnotations(DeclarationMirror mirror,
    Library owningLibrary) {
  var annotations = [];
  var info = new AnnotationInfo(mirror, owningLibrary);
  for (var expr in dart2js_mirrors.BackDoor.metadataSyntaxOf(mirror)) {
    var docgenAnnotation = expr.accept(const AnnotationCreator(), info);
    if (docgenAnnotation != null &&
        !_SKIPPED_ANNOTATIONS.contains(
            dart2js_util.qualifiedNameOf(docgenAnnotation.mirror))) {
      annotations.add(docgenAnnotation);
    }
  }
  return annotations;
}

class AnnotationInfo {
  final Mirror mirror;
  final Library owningLibrary;

  AnnotationInfo(this.mirror, this.owningLibrary);
}

class AnnotationCreator
    extends ConstantExpressionVisitor<AnnotationInfo, Annotation> {

  const AnnotationCreator();

  Annotation createAnnotation(var element,
                              AnnotationInfo context,
                              [List<String> parameters = const <String>[]]) {
    var mirror =
        dart2js_mirrors.BackDoor.getMirrorFromElement(context.mirror, element);
    if (mirror != null) {
      return new Annotation(context.owningLibrary, mirror, parameters);
    }
    return null;
  }

  @override
  Annotation visitBinary(BinaryConstantExpression exp,
                         [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitConcatenate(ConcatenateConstantExpression exp,
                              [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitConditional(ConditionalConstantExpression exp,
                              [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitConstructed(ConstructedConstantExpresssion exp,
                              [AnnotationInfo context]) {
    return createAnnotation(exp.target, context,
        exp.arguments.map((a) => a.getText()).toList());
  }

  @override
  Annotation visitFunction(FunctionConstantExpression exp,
                           [AnnotationInfo context]) {
    return createAnnotation(exp.element, context);
  }

  @override
  Annotation visitList(ListConstantExpression exp,
                       [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitMap(MapConstantExpression exp,
                      [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitPrimitive(PrimitiveConstantExpression exp,
                            [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitSymbol(SymbolConstantExpression exp,
                         [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitType(TypeConstantExpression exp,
                       [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitUnary(UnaryConstantExpression exp,
                        [AnnotationInfo context]) {
    return null;
  }

  @override
  Annotation visitVariable(VariableConstantExpression exp,
                           [AnnotationInfo context]) {
    return createAnnotation(exp.element, context);
  }
}

/// A declaration is private if itself is private, or the owner is private.
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
  var outputMap = new LinkedHashMap();
  inputMap.forEach((key, value) {
    if (value is Map) {
      outputMap[key] = recurseMap(value);
    } else {
      outputMap[key] = value.toMap();
    }
  });
  return outputMap;
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
  exports['classes'] = new SplayTreeMap();
  exports['methods'] = new SplayTreeMap();
  exports['variables'] = new SplayTreeMap();

  // Determine the classes, variables and methods that are exported for a
  // specific dependency.
  void _populateExports(LibraryDependencyMirror export, bool showExport) {
    var transitiveExports = calcExportedItems(export.targetLibrary);
    exports['classes'].addAll(transitiveExports['classes']);
    exports['methods'].addAll(transitiveExports['methods']);
    exports['variables'].addAll(transitiveExports['variables']);
    // If there is a show in the export, add only the show items to the
    // library. Ex: "export foo show bar"
    // Otherwise, add all items, and then remove the hidden ones.
    // Ex: "export foo hide bar"

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
  var data = new SplayTreeMap<String, Variable>();
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
  var group = new SplayTreeMap<String, Method>();
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

Map _filterMap(Map map, bool test(k, v)) {
  var exported = new SplayTreeMap();
  map.forEach((key, value) {
    if (test(key, value)) exported[key] = value;
  });
  return exported;
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
