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
class Variable extends OwnedIndexable {

  bool isFinal;
  bool isStatic;
  bool isConst;
  DocGenType type;
  String _variableName;

  factory Variable(String variableName, VariableMirror mirror,
      Indexable owner) {
    var variable = getDocgenObject(mirror);
    if (variable is DummyMirror) {
      return new Variable._(variableName, mirror, owner);
    }
    return variable;
  }

  Variable._(this._variableName, VariableMirror mirror, Indexable owner) :
      super(mirror, owner) {
    isFinal = mirror.isFinal;
    isStatic = mirror.isStatic;
    isConst = mirror.isConst;
    type = new DocGenType(mirror.type, owner.owningLibrary);
  }

  String get name => _variableName;

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

  get comment {
    if (commentField != null) return commentField;
    if (owner is Class) {
      (owner as Class).ensureComments();
    }
    return super.comment;
  }

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

  bool isValidMirror(DeclarationMirror mirror) => mirror is VariableMirror;
}
