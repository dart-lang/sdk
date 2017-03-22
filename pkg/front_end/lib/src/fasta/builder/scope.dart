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

  Map<String, Builder> forwardDeclaredLabels;

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
          ? new AccessErrorBuilder(name, builder, charOffset, fileUri)
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
          return new AccessErrorBuilder(name, builder, charOffset, fileUri);
        } else {
          return builder;
        }
      } else if (builder.isSetter) {
        return builder;
      } else {
        return new AccessErrorBuilder(name, builder, charOffset, fileUri);
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
        return new AmbiguousBuilder(name, builder, charOffset, fileUri);
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

  void forwardDeclareLabel(String name, Builder target) {
    declareLabel(name, target);
    forwardDeclaredLabels ??= <String, Builder>{};
    forwardDeclaredLabels[name] = target;
  }

  void claimLabel(String name) {
    if (forwardDeclaredLabels == null) return;
    forwardDeclaredLabels.remove(name);
    if (forwardDeclaredLabels.length == 0) {
      forwardDeclaredLabels = null;
    }
  }

  Map<String, Builder> get unclaimedForwardDeclarations {
    return forwardDeclaredLabels;
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

abstract class ProblemBuilder extends Builder {
  final String name;

  final Builder builder;

  ProblemBuilder(this.name, this.builder, int charOffset, Uri fileUri)
      : super(null, charOffset, fileUri);

  get target => null;

  bool get hasProblem => true;

  String get message;

  @override
  String get fullNameForErrors => name;
}

/// Represents a [builder] that's being accessed incorrectly. For example, an
/// attempt to write to a final field, or to read from a setter.
class AccessErrorBuilder extends ProblemBuilder {
  AccessErrorBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  Builder get parent => builder;

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

  String get message => "Access error: '$name'.";
}

class AmbiguousBuilder extends ProblemBuilder {
  AmbiguousBuilder(String name, Builder builder, int charOffset, Uri fileUri)
      : super(name, builder, charOffset, fileUri);

  String get message => "Duplicated named: '$name'.";
}
