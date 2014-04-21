// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.typedef;

import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'dummy_mirror.dart';
import 'library.dart';
import 'model_helpers.dart';
import 'generic.dart';
import 'parameter.dart';
import 'owned_indexable.dart';

class Typedef extends OwnedIndexable<TypedefMirror> {
  final String returnType;

  final Map<String, Parameter> parameters;

  /// Generic information about the typedef.
  final Map<String, Generic> generics;

  /// Returns the [Library] for the given [mirror] if it has already been
  /// created, else creates it.
  factory Typedef(TypedefMirror mirror, Library owningLibrary) {
    var aTypedef = getDocgenObject(mirror, owningLibrary);
    if (aTypedef is DummyMirror) {
      aTypedef = new Typedef._(mirror, owningLibrary);
    }
    return aTypedef;
  }

  Typedef._(TypedefMirror mirror, Library owningLibrary)
      : returnType = getDocgenObject(mirror.referent.returnType).docName,
        generics = createGenerics(mirror),
        parameters = createParameters(mirror.referent.parameters,
            owningLibrary),
        super(mirror, owningLibrary);

  Map toMap() {
    var map = {
      'name': name,
      'qualifiedName': qualifiedName,
      'comment': comment,
      'return': returnType,
      'parameters': recurseMap(parameters),
      'annotations': annotations.map((a) => a.toMap()).toList(),
      'generics': recurseMap(generics)
    };

    // Typedef is displayed on the library page as a class, so a preview is
    // added manually
    var pre = preview;
    if (pre != null) map['preview'] = pre;

    return map;
  }

  String get typeName => 'typedef';

  bool isValidMirror(DeclarationMirror mirror) => mirror is TypedefMirror;
}
