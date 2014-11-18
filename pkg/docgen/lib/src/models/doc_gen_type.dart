// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.doc_gen_type;

import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'library.dart';
import 'mirror_based.dart';

/// Docgen wrapper around the mirror for a return type, and/or its generic
/// type parameters.
///
/// Return types are of a form [outer]<[inner]>.
/// If there is no [inner] part, [inner] will be an empty list.
///
/// For example:
///        int size()
///          "return" :
///            - "outer" : "dart:core.int"
///              "inner" :
///
///        List<String> toList()
///          "return" :
///            - "outer" : "dart:core.List"
///              "inner" :
///                - "outer" : "dart:core.String"
///                  "inner" :
///
///        Map<String, List<int>>
///          "return" :
///            - "outer" : "dart:core.Map"
///              "inner" :
///                - "outer" : "dart:core.String"
///                  "inner" :
///                - "outer" : "dart:core.List"
///                  "inner" :
///                    - "outer" : "dart:core.int"
///                      "inner" :
class DocGenType extends MirrorBased {
  final TypeMirror mirror;
  final Library owningLibrary;

  DocGenType(this.mirror, this.owningLibrary);

  Map toMap() {
    var result = getDocgenObject(mirror, owningLibrary);
    return {
      // We may encounter types whose corresponding library has not been
      // processed yet, so look up with the owningLibrary at the last moment.
      'outer': result.packagePrefix + result.docName,
      'inner': _createTypeGenerics(mirror).map((e) => e.toMap()).toList(),
    };
  }

  /// Returns a list of [DocGenType] objects constructed from TypeMirrors.
  List<DocGenType> _createTypeGenerics(TypeMirror mirror) {
    if (mirror is! ClassMirror) return [];
    return mirror.typeArguments
        .map((e) => new DocGenType(e, owningLibrary))
        .toList();
  }
}
