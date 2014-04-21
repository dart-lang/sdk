// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.owned_indexable;

import '../exports/mirrors_util.dart' as dart2js_util;
import '../exports/source_mirrors.dart';

import '../library_helpers.dart';
import '../mdn.dart';
import '../package_helpers.dart';

import 'annotation.dart';
import 'dummy_mirror.dart';
import 'indexable.dart';
import 'model_helpers.dart';

abstract class OwnedIndexable<TMirror extends DeclarationMirror>
    extends Indexable<TMirror> {
  /// List of the meta annotations on this item.
  final List<Annotation> annotations;

  /// The object one scope-level above which this item is defined.
  ///
  /// Ex: The owner for a top level class, would be its enclosing library.
  /// The owner of a local variable in a method would be the enclosing method.
  final Indexable owner;

  /// Returns this object's qualified name, but following the conventions
  /// we're using in Dartdoc, which is that library names with dots in them
  /// have them replaced with hyphens.
  String get docName => owner.docName + '.' + dart2js_util.nameOf(mirror);

  OwnedIndexable(DeclarationMirror mirror, Indexable owner)
      : annotations = createAnnotations(mirror, owner.owningLibrary),
        this.owner = owner,
        super(mirror);

  /// Generates MDN comments from database.json.
  String getMdnComment() {
    var domAnnotation = this.annotations.firstWhere(
        (e) => e.mirror.qualifiedName == #metadata.DomName,
        orElse: () => null);
    if (domAnnotation == null) return '';
    var domName = domAnnotation.parameters.single;

    return mdnComment(rootDirectory, logger, domName);
  }

  String get packagePrefix => owner.packagePrefix;

  String findElementInScope(String name) {
    var lookupFunc = determineLookupFunc(name);
    var result = lookupFunc(mirror, name);
    if (result != null) {
      result = getDocgenObject(result);
      if (result is DummyMirror) return packagePrefix + result.docName;
      return result.packagePrefix + result.docName;
    }

    if (owner != null) {
      var result = owner.findElementInScope(name);
      if (result != null) {
        return result;
      }
    }
    return super.findElementInScope(name);
  }
}
