// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope;

import 'builder.dart' show Builder, MixedAccessor;

import '../errors.dart' show internalError;

class Scope {
  /// Names declared in this scope.
  final Map<String, Builder> local;

  /// The scope that this scope is nested within, or `null` if this is the top
  /// level scope.
  final Scope parent;

  /// Indicates whether an attempt to declare new names in this scope should
  /// succeed.
  final bool isModifiable;

  Map<String, Builder> labels;

  Scope(this.local, this.parent, {this.isModifiable: true});

  Scope createNestedScope({bool isModifiable: true}) {
    return new Scope(<String, Builder>{}, this, isModifiable: isModifiable);
  }

  Builder lookup(String name, int charOffset, Uri fileUri) {
    Builder builder = local[name];
    if (builder != null) {
      if (builder.next != null) {
        return lookupAmbiguous(name, builder, false, charOffset, fileUri);
      }
      return builder.isSetter
          ? new AccessErrorBuilder(builder, charOffset, fileUri)
          : builder;
    } else {
      return parent?.lookup(name, charOffset, fileUri);
    }
  }

  Builder lookupSetter(String name, int charOffset, Uri fileUri) {
    Builder builder = local[name];
    if (builder != null) {
      if (builder.next != null) {
        return lookupAmbiguous(name, builder, true, charOffset, fileUri);
      }
      if (builder.isField) {
        if (builder.isFinal) {
          return new AccessErrorBuilder(builder, charOffset, fileUri);
        } else {
          return builder;
        }
      } else if (builder.isSetter) {
        return builder;
      } else {
        return new AccessErrorBuilder(builder, charOffset, fileUri);
      }
    } else {
      return parent?.lookupSetter(name, charOffset, fileUri);
    }
  }

  Builder lookupAmbiguous(
      String name, Builder builder, bool setter, int charOffset, Uri fileUri) {
    assert(builder.next != null);
    if (builder is MixedAccessor) {
      return setter ? builder.setter : builder.getter;
    }
    Builder setterBuilder;
    Builder getterBuilder;
    Builder current = builder;
    while (current != null) {
      if (current.isGetter && getterBuilder == null) {
        getterBuilder = current;
      } else if (current.isSetter && setterBuilder == null) {
        setterBuilder = current;
      } else {
        return new AmbiguousBuilder(builder, charOffset, fileUri);
      }
      current = current.next;
    }
    assert(getterBuilder != null);
    assert(setterBuilder != null);
    return setter ? setterBuilder : getterBuilder;
  }

  bool hasLocalLabel(String name) => labels != null && labels.containsKey(name);

  void declareLabel(String name, Builder target) {
    if (isModifiable) {
      labels ??= <String, Builder>{};
      labels[name] = target;
    } else {
      internalError("Can't extend an unmodifiable scope.");
    }
  }

  Builder lookupLabel(String name) {
    return (labels == null ? null : labels[name]) ?? parent?.lookupLabel(name);
  }

  // TODO(ahe): Rename to extend or something.
  void operator []=(String name, Builder member) {
    if (isModifiable) {
      local[name] = member;
    } else {
      internalError("Can't extend an unmodifiable scope.");
    }
  }
}

class AccessErrorBuilder extends Builder {
  final Builder builder;

  AccessErrorBuilder(this.builder, int charOffset, Uri fileUri)
      : super(null, charOffset, fileUri);

  Builder get parent => builder;

  get target => null;

  bool get isFinal => builder.isFinal;

  bool get isField => builder.isField;

  bool get isRegularMethod => builder.isRegularMethod;

  bool get isGetter => !builder.isGetter;

  bool get isSetter => !builder.isSetter;

  bool get isInstanceMember => builder.isInstanceMember;

  bool get isStatic => builder.isStatic;

  bool get isTopLevel => builder.isTopLevel;

  bool get isTypeDeclaration => builder.isTypeDeclaration;

  bool get isLocal => builder.isLocal;

  bool get hasProblem => true;
}

class AmbiguousBuilder extends Builder {
  final Builder builder;

  AmbiguousBuilder(this.builder, int charOffset, Uri fileUri)
      : super(null, charOffset, fileUri);

  get target => null;

  bool get hasProblem => true;
}
