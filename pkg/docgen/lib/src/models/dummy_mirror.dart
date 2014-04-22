// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.dummy_mirror;

import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'indexable.dart';
import 'model_helpers.dart';

/// For types that we do not explicitly create or have not yet created in our
/// entity map (like core types).
class DummyMirror implements Indexable {
  final DeclarationMirror mirror;
  /// The library that contains this element, if any. Used as a hint to help
  /// determine which object we're referring to when looking up this mirror in
  /// our map.
  final Indexable owner;

  DummyMirror(this.mirror, [this.owner]);

  String get docName {
    if (mirror is LibraryMirror) {
      return getLibraryDocName(mirror);
    }
    var mirrorOwner = mirror.owner;
    if (mirrorOwner == null) return dart2js_util.qualifiedNameOf(mirror);
    var simpleName = dart2js_util.nameOf(mirror);
    if (mirror is MethodMirror && (mirror as MethodMirror).isConstructor) {
      // We name constructors specially -- repeating the class name and a
      // "-" to separate the constructor from its name (if any).
      simpleName = '${dart2js_util.nameOf(mirrorOwner)}-$simpleName';
    }
    return getDocgenObject(mirrorOwner, owner).docName + '.' +
        simpleName;
  }

  bool get isPrivate => mirror.isPrivate;

  String get packageName {
    var libMirror = _getOwningLibraryFromMirror(mirror);
    if (libMirror != null) {
      return getPackageName(libMirror);
    }
    return '';
  }

  String get packagePrefix => packageName == null || packageName.isEmpty ?
      '' : '$packageName/';

  // This is a known incomplete implementation of Indexable
  // overriding noSuchMethod to remove static warnings
  noSuchMethod(Invocation invocation) {
    throw new UnimplementedError(invocation.memberName.toString());
  }
}

LibraryMirror _getOwningLibraryFromMirror(DeclarationMirror mirror) {
  if (mirror == null) return null;
  if (mirror is LibraryMirror) return mirror;
  return _getOwningLibraryFromMirror(mirror.owner);
}
