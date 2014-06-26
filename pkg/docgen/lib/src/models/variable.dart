// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library docgen.models.variable;

import '../exports/source_mirrors.dart';

import '../library_helpers.dart';

import 'class.dart';
import 'doc_gen_type.dart';
import 'dummy_mirror.dart';
import 'indexable.dart';
import 'owned_indexable.dart';


/// A class containing properties of a Dart variable.
class Variable extends OwnedIndexable<VariableMirror> {
  final bool isFinal;
  final bool isStatic;
  final bool isConst;
  final DocGenType type;
  final String name;

  factory Variable(String name, VariableMirror mirror, Indexable owner) {
    var variable = getDocgenObject(mirror, owner);
    if (variable is DummyMirror) {
      return new Variable._(name, mirror, owner);
    }
    return variable;
  }

  Variable._(this.name, VariableMirror mirror, Indexable owner)
      : isFinal = mirror.isFinal,
        isStatic = mirror.isStatic,
        isConst = mirror.isConst,
        type = new DocGenType(mirror.type, owner.owningLibrary),
        super(mirror, owner);

  /// Generates a map describing the [Variable] object.
  Map toMap() => {
    'name': name,
    'qualifiedName': qualifiedName,
    'comment': comment,
    'final': isFinal,
    'static': isStatic,
    'constant': isConst,
    'type': new List.filled(1, type.toMap()),
    'annotations': annotations.map((a) => a.toMap()).toList()
  };

  String get typeName => 'property';

  String get comment {
    if (commentField != null) return commentField;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    return super.comment;
  }

  bool isValidMirror(DeclarationMirror mirror) => mirror is VariableMirror;
}
