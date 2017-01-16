// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library fasta.scope;

import 'builder.dart' show
    Builder,
    MixedAccessor;

import '../errors.dart' show
    internalError;

class Scope {
  final Map<String, Builder> local;

  final Scope parent;

  final bool isModifiable;

  Scope(this.local, this.parent, {this.isModifiable: true});

  Scope createNestedScope({bool isModifiable: true}) {
    return new Scope(<String, Builder>{}, this, isModifiable: isModifiable);
  }

  Builder lookup(String name) {
    Builder builder = local[name];
    if (builder != null) {
      if (builder.next != null) return lookupAmbiguous(name, builder, false);
      return builder.isSetter ? new AccessErrorBuilder(builder) : builder;
    } else {
      return parent?.lookup(name);
    }
  }

  Builder lookupSetter(String name) {
    Builder builder = local[name];
    if (builder != null) {
      if (builder.next != null) return lookupAmbiguous(name, builder, true);
      if (builder.isField) {
        if (builder.isFinal) {
          return new AccessErrorBuilder(builder);
        } else {
          return builder;
        }
      } else if (builder.isSetter) {
        return builder;
      } else {
        return new AccessErrorBuilder(builder);
      }
    } else {
      return parent?.lookupSetter(name);
    }
  }

  Builder lookupAmbiguous(String name, Builder builder, bool setter) {
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
        return new AmbiguousBuilder(builder);
      }
      current = current.next;
    }
    assert(getterBuilder != null);
    assert(setterBuilder != null);
    return setter ? setterBuilder : getterBuilder;
  }

  // TODO(ahe): Rename to extend or something.
  void operator[]= (String name, Builder member) {
    if (isModifiable) {
      local[name] = member;
    } else {
      internalError("Can't extend an unmodifiable scope.");
    }
  }
}

class AccessErrorBuilder extends Builder {
  final Builder builder;

  AccessErrorBuilder(this.builder);

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

  AmbiguousBuilder(this.builder);

  get target => null;

  bool get hasProblem => true;
}
