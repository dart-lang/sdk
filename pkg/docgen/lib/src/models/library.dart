// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.library;

import 'dart:io';

import 'package:markdown/markdown.dart' as markdown;

import '../exports/source_mirrors.dart';
import '../exports/mirrors_util.dart' as dart2js_util;

import '../library_helpers.dart';
import '../package_helpers.dart';

import 'class.dart';
import 'dummy_mirror.dart';
import 'indexable.dart';
import 'method.dart';
import 'model_helpers.dart';
import 'typedef.dart';
import 'variable.dart';

/// A class containing contents of a Dart library.
class Library extends Indexable {
  final Map<String, Class> classes = {};
  final Map<String, Typedef> typedefs = {};
  final Map<String, Class> errors = {};

  /// Top-level variables in the library.
  Map<String, Variable> variables;

  /// Top-level functions in the library.
  Map<String, Method> functions;

  String packageName = '';
  bool _hasBeenCheckedForPackage = false;
  String packageIntro;

  Indexable get owner => const _LibraryOwner();

  Library get owningLibrary => this;

  /// Returns the [Library] for the given [mirror] if it has already been
  /// created, else creates it.
  factory Library(LibraryMirror mirror) {
    var library = getDocgenObject(mirror);
    if (library is DummyMirror) {
      library = new Library._(mirror);
    }
    return library;
  }

  Library._(LibraryMirror libraryMirror) : super(libraryMirror) {
    var exported = calcExportedItems(libraryMirror);
    var exportedClasses = addAll(exported['classes'],
        dart2js_util.typesOf(libraryMirror.declarations));
    updateLibraryPackage(mirror);
    exportedClasses.forEach((String mirrorName, TypeMirror mirror) {
      if (mirror is TypedefMirror) {
        // This is actually a Dart2jsTypedefMirror, and it does define value,
        // but we don't have visibility to that type.
        if (includePrivateMembers || !mirror.isPrivate) {
          typedefs[dart2js_util.nameOf(mirror)] = new Typedef(mirror, this);
        }
      } else if (mirror is ClassMirror) {
        var clazz = new Class(mirror, this);

        if (clazz.isError()) {
          errors[dart2js_util.nameOf(mirror)] = clazz;
        } else {
          classes[dart2js_util.nameOf(mirror)] = clazz;
        }
      } else {
        throw new ArgumentError(
            '${dart2js_util.nameOf(mirror)} - no class type match. ');
      }
    });
    this.functions = createMethods(addAll(exported['methods'],
        libraryMirror.declarations.values.where(
            (mirror) => mirror is MethodMirror)).values, this);
    this.variables = createVariables(addAll(exported['variables'],
        dart2js_util.variablesOf(libraryMirror.declarations)).values, this);
  }

  /// Look for the specified name starting with the current member, and
  /// progressively working outward to the current library scope.
  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);
    var libraryScope = lookupFunc(mirror, name);
    if (libraryScope != null) {
      var result = getDocgenObject(libraryScope, this);
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }
    return super.findElementInScope(name);
  }

  String getMdnComment() => '';

  /// For a library's [mirror], determine the name of the package (if any) we
  /// believe it came from (because of its file URI).
  ///
  /// If no package could be determined, we return an empty string.
  void updateLibraryPackage(LibraryMirror mirror) {
    if (mirror == null) return;
    if (_hasBeenCheckedForPackage) return;
    _hasBeenCheckedForPackage = true;
    if (mirror.uri.scheme != 'file') return;
    packageName = getPackageName(mirror);
    // Associate the package readme with all the libraries. This is a bit
    // wasteful, but easier than trying to figure out which partial match
    // is best.
    packageIntro = _packageIntro(getPackageDirectory(mirror));
  }

  String _packageIntro(packageDir) {
    if (packageDir == null) return null;
    var dir = new Directory(packageDir);
    var files = dir.listSync();
    var readmes = files.where((FileSystemEntity each) => (each is File &&
        each.path.substring(packageDir.length + 1, each.path.length)
          .startsWith('README'))).toList();
    if (readmes.isEmpty) return '';
    // If there are multiples, pick the shortest name.
    readmes.sort((a, b) => a.path.length.compareTo(b.path.length));
    var readme = readmes.first;
    var linkResolver = (name) => globalFixReference(name);
    var contents = markdown.markdownToHtml(readme
      .readAsStringSync(), linkResolver: linkResolver,
      inlineSyntaxes: MARKDOWN_SYNTAXES);
    return contents;
  }

  String get packagePrefix => packageName == null || packageName.isEmpty ?
      '' : '$packageName/';

  Map get previewMap {
    var map = {'packageName': packageName};
    map.addAll(super.previewMap);
    if (packageIntro != null) {
      map['packageIntro'] = packageIntro;
    }
    var version = packageVersion(mirror);
    if (version != '' && version != null) map['version'] = version;
    return map;
  }

  String get name => docName;

  String get docName => getLibraryDocName(mirror);

  /// Generates a map describing the [Library] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'variables': recurseMap(variables),
    'functions': expandMethodMap(functions),
    'classes': {
      'class': classes.values.where((c) => c.isVisible)
        .map((e) => e.previewMap).toList(),
      'typedef': recurseMap(typedefs),
      'error': errors.values.where((e) => e.isVisible)
          .map((e) => e.previewMap).toList()
    },
    'packageName': packageName,
    'packageIntro': packageIntro
  };

  String get typeName => 'library';

  bool isValidMirror(DeclarationMirror mirror) => mirror is LibraryMirror;
}

/// Dummy implementation of Indexable to represent the owner of a Library.
class _LibraryOwner implements Indexable {
  const _LibraryOwner();

  String get docName => '';

  bool get isPrivate => false;

  Indexable get owner => null;

  // This is a known incomplete implementation of Indexable
  // overriding noSuchMethod to remove static warnings
  noSuchMethod(Invocation invocation) {
    throw new UnimplementedError(invocation.memberName.toString());
  }
}
