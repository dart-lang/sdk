// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Additional data model classes used by the summary builder.
///
/// The summary builder uses 4 pieces of data:
///
///   * Unlinked**Builders: builder classes for each piece of output in the
///     summary (see format.dart).
///
///   * A simplified expression syntax: model relevant pieces of initializers
///     and constants before serializing them (see expressions.dart).
///
///   * Lazy references: a way to model references on the fly so we can build
///     summaries in a single pass.
///
///   * Scopes: used to track the current context of the parser, used in great
///     part to easily resolve lazy references at the end of the build process.
library summary.src.scope;

import 'package:analyzer/src/summary/format.dart';
import 'package:analyzer/src/summary/idl.dart';

export 'package:analyzer/src/summary/api_signature.dart';
export 'package:analyzer/src/summary/format.dart';
export 'package:analyzer/src/summary/idl.dart';

export 'expressions.dart';
export 'visitor.dart';

class ClassScope extends TypeParameterScope {
  String className;
  UnlinkedClassBuilder currentClass = new UnlinkedClassBuilder();
  UnlinkedPublicNameBuilder publicName = new UnlinkedPublicNameBuilder();
  Set<String> members = new Set<String>();
  ClassScope(Scope parent) : super(parent);

  void computeReference(LazyEntityRef ref) {
    if (!members.contains(ref.name)) {
      return super.computeReference(ref);
    }
    ref.reference = top.serializeReference(
        top.serializeReference(null, className), ref.name);
  }

  toString() => "<class-scope: $className>";
}

class EnumScope extends Scope {
  final Scope parent;
  UnlinkedEnumBuilder currentEnum = new UnlinkedEnumBuilder();

  EnumScope(this.parent);

  void computeReference(LazyEntityRef ref) => throw "unexpected";
}

/// A lazily encoded reference.
///
/// References in summaries are encoded based on the scope where they appear.
/// Most top-level references can be encoded eagerly, but references in the
/// scope of a class need to check whether a name is a member of such class.
/// Because we don't have such list of members available upfront, we create
/// these lazy references and finalize them after we finish going through the
/// program.
class LazyEntityRef extends EntityRefBuilder {
  Scope scope;
  String name;
  bool wasExpanded = false;

  LazyEntityRef(this.name, this.scope) : super() {
    scope.top._toExpand.add(this);
  }
  @override
  int get paramReference {
    expand();
    return super.paramReference;
  }

  @override
  int get reference {
    expand();
    return super.reference;
  }

  expand() {
    if (!wasExpanded) {
      scope.computeReference(this);
      wasExpanded = true;
    }
  }
}

/// A nested lazy reference, modeling something like `a.b.c`.
class NestedLazyEntityRef extends LazyEntityRef {
  EntityRef prefix;
  NestedLazyEntityRef(this.prefix, String name, Scope scope)
      : super(name, scope.top);

  @override
  expand() {
    if (!wasExpanded) {
      super.reference = scope.top.serializeReference(prefix.reference, name);
      wasExpanded = true;
    }
  }
}

/// A scope corresponding to a scope in the program like units, classes, or
/// enums.
///
/// It is used to hold results that correspond to a given scope in the program
/// and to lazily resolve name references.
abstract class Scope {
  Scope get parent;

  TopScope get top {
    var s = this;
    while (s.parent != null) s = s.parent;
    return s;
  }

  void computeReference(LazyEntityRef ref);
}

/// Top scope, where the top-level unit is built.
class TopScope extends Scope {
  /// Results of parsing the unit.
  final UnlinkedUnitBuilder unit = new UnlinkedUnitBuilder(
      classes: [],
      enums: [],
      executables: [],
      exports: [],
      imports: [],
      parts: [],
      references: [new UnlinkedReferenceBuilder()],
      typedefs: [],
      variables: []);

  /// Stores publicly visible names exported from the unit.
  final UnlinkedPublicNamespaceBuilder publicNamespace =
      new UnlinkedPublicNamespaceBuilder(names: [], exports: [], parts: []);

  /// Lazy references that need to be expanded after all scope information is
  /// known.
  List<LazyEntityRef> _toExpand = [];

  final Map<int, Map<String, int>> nameToReference = <int, Map<String, int>>{};

  TopScope() {
    unit.publicNamespace = publicNamespace;
  }

  get parent => null;

  void computeReference(LazyEntityRef ref) {
    ref.reference = serializeReference(null, ref.name);
  }

  void expandLazyReferences() {
    _toExpand.forEach((r) => r.expand());
  }

  int serializeReference(int prefixIndex, String name) => nameToReference
          .putIfAbsent(prefixIndex, () => <String, int>{})
          .putIfAbsent(name, () {
        int index = unit.references.length;
        unit.references.add(new UnlinkedReferenceBuilder(
            prefixReference: prefixIndex, name: name));
        return index;
      });

  toString() => "<top-scope>";
}

class TypeParameterScope extends Scope {
  final Scope parent;
  List<String> typeParameters = [];

  TypeParameterScope(this.parent);

  void computeReference(LazyEntityRef ref) {
    var i = typeParameters.indexOf(ref.name);
    if (i < 0) return parent.computeReference(ref);
    // Note: there is no indexOffset here because we don't go into functions at
    // all (so there is no nesting of type-parameter scopes).
    ref.paramReference = typeParameters.length - i;
  }
}
