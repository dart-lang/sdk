// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of js_backend.namer;

abstract class _MinifiedFieldNamer implements Namer {
  _FieldNamingRegistry get fieldRegistry;

  // Returns a minimal name for the field that is globally unique along
  // the given element's class inheritance chain.
  //
  // The inheritance scope based naming might not yield a name. For instance,
  // this could be because the field belongs to a mixin. In such a case this
  // will return `null` and a normal field name has to be used.
  jsAst.Name? _minifiedInstanceFieldPropertyName(FieldEntity element) {
    if (_nativeData.hasFixedBackendName(element)) {
      return StringBackedName(_nativeData.getFixedBackendName(element)!);
    }

    _FieldNamingScope names;
    if (element is JContextField) {
      names = _FieldNamingScope.forBox(element.box, fieldRegistry);
    } else {
      final cls = element.enclosingClass!;
      names = _FieldNamingScope.forClass(cls, _closedWorld, fieldRegistry);
    }

    if (names.containsField(element)) {
      return names[element];
    }
    return null;
  }
}

/// Encapsulates the global state of field naming.
///
/// The field naming registry allocates names to be used along a path in the
/// inheritance hierarchy of fields, starting with the object class. The actual
/// hierarchy is encoded using instances of [_FieldNamingScope].
class _FieldNamingRegistry {
  final Namer namer;

  final Map<Entity, _FieldNamingScope> scopes = {};

  final Map<Entity, jsAst.Name> globalNames = {};

  int globalCount = 0;

  final List<jsAst.Name> nameStore = [];

  _FieldNamingRegistry(this.namer);

  // Returns the name to be used for a field with distance [index] from the
  // root of the object hierarchy. The distance thereby is computed as the
  // number of fields preceding the current field in its classes inheritance
  // chain.
  //
  // The implementation assumes that names are requested in order, that is the
  // name at position i+1 is requested after the name at position i was
  // requested.
  jsAst.Name getName(int index) {
    if (index >= nameStore.length) {
      // The namer usually does not use certain names as they clash with
      // existing properties on JS objects (see [_reservedNativeProperties]).
      // However, some of them are really short and safe to use for fields.
      // Thus, we shortcut the namer to use those first.
      assert(index == nameStore.length);
      if (index < MinifyNamer._reservedNativeProperties.length &&
          MinifyNamer._reservedNativeProperties[index].length <= 2) {
        nameStore.add(
            StringBackedName(MinifyNamer._reservedNativeProperties[index]));
      } else {
        nameStore.add(namer.getFreshName(namer.instanceScope, "field$index"));
      }
    }

    return nameStore[index];
  }
}

/// A [_FieldNamingScope] encodes a node in the inheritance tree of the current
/// class hierarchy. The root node typically is the node corresponding to the
/// `Object` class. It is used to assign a unique name to each field of a class.
/// Unique here means unique wrt. all fields along the path back to the root.
/// This is achieved at construction time via the [_fieldNameCounter] field that
/// counts the number of fields on the path to the root node that have been
/// encountered so far.
///
/// Obviously, this only works if no fields are added to a parent node after its
/// children have added their first field.
class _FieldNamingScope {
  final _FieldNamingScope? superScope;
  final Entity container;
  final Map<Entity, jsAst.Name> names = Maplet();
  final _FieldNamingRegistry registry;

  /// Naming counter used for fields of ordinary classes.
  late int _fieldNameCounter;

  /// The number of fields along the superclass chain that use inheritance
  /// based naming, including the ones allocated for this scope.
  int get inheritanceBasedFieldNameCounter => _fieldNameCounter;

  /// The number of locally used fields. Depending on the naming source
  /// (e.g. inheritance based or globally unique for mixins) this
  /// might be different from [inheritanceBasedFieldNameCounter].
  int get _localFieldNameCounter => _fieldNameCounter;
  void set _localFieldNameCounter(int val) {
    _fieldNameCounter = val;
  }

  factory _FieldNamingScope.forClass(
      ClassEntity cls, JClosedWorld world, _FieldNamingRegistry registry) {
    _FieldNamingScope? result = registry.scopes[cls];
    if (result != null) return result;

    if (world.isUsedAsMixin(cls)) {
      result = _MixinFieldNamingScope.mixin(cls, registry);
    } else {
      var superclass = world.elementEnvironment.getSuperClass(cls);
      if (superclass == null) {
        result = _FieldNamingScope.rootScope(cls, registry);
      } else {
        _FieldNamingScope superScope =
            _FieldNamingScope.forClass(superclass, world, registry);
        if (world.elementEnvironment.isMixinApplication(cls)) {
          result = _MixinFieldNamingScope.mixedIn(cls, superScope, registry);
        } else {
          result = _FieldNamingScope.inherit(cls, superScope, registry);
        }
      }
    }

    world.elementEnvironment.forEachClassMember(cls,
        (ClassEntity declarer, MemberEntity member) {
      // TODO(sra): Don't add elided names.
      if (member is FieldEntity && member.isInstanceMember) result!.add(member);
    });

    registry.scopes[cls] = result;
    return result;
  }

  factory _FieldNamingScope.forBox(Local box, _FieldNamingRegistry registry) {
    return registry.scopes
        .putIfAbsent(box, () => _BoxFieldNamingScope(box, registry));
  }

  _FieldNamingScope.rootScope(this.container, this.registry)
      : superScope = null,
        _fieldNameCounter = 0;

  _FieldNamingScope.inherit(
      this.container, _FieldNamingScope superScope, this.registry)
      : this.superScope = superScope {
    _fieldNameCounter = superScope.inheritanceBasedFieldNameCounter;
  }

  /// Checks whether [name] is already used in the current scope chain.
  _isNameUnused(jsAst.Name name) {
    return !names.values.contains(name) &&
        ((superScope == null) || superScope!._isNameUnused(name));
  }

  jsAst.Name _nextName() => registry.getName(_localFieldNameCounter++);

  jsAst.Name? operator [](Entity field) {
    final name = names[field];
    if (name == null && superScope != null) return superScope![field];
    return name;
  }

  void add(Entity field) {
    if (names.containsKey(field)) return;

    jsAst.Name value = _nextName();
    assert(_isNameUnused(value), failedAt(field));
    names[field] = value;
  }

  bool containsField(Entity field) => names.containsKey(field);
}

/// Field names for mixins have two constraints: They need to be unique in the
/// hierarchy of each application of a mixin and they need to be the same for
/// all applications of a mixin. To achieve this, we use global naming for
/// mixins from the same name pool as fields and add a `$` at the end to ensure
/// they do not collide with normal field names. The `$` sign is typically used
/// as a separator between method names and argument counts and does not appear
/// in generated names themselves.
class _MixinFieldNamingScope extends _FieldNamingScope {
  @override
  int get _localFieldNameCounter => registry.globalCount;
  @override
  void set _localFieldNameCounter(int val) {
    registry.globalCount = val;
  }

  @override
  Map<Entity, jsAst.Name> get names => registry.globalNames;

  _MixinFieldNamingScope.mixin(super.cls, super.registry) : super.rootScope();

  _MixinFieldNamingScope.mixedIn(
      super.container, super.superScope, super.registry)
      : super.inherit();

  @override
  jsAst.Name _nextName() {
    final proposed = super._nextName() as _NamerName;
    return CompoundName([proposed, Namer._literalDollar as _NamerName]);
  }
}

/// [BoxFieldElement] fields work differently in that they do not belong to an
/// actual class but an anonymous box associated to a [Local]. As there is no
/// inheritance chain, we do not need to compute fields a priori but can assign
/// names on the fly.
class _BoxFieldNamingScope extends _FieldNamingScope {
  _BoxFieldNamingScope(super.box, super.registry) : super.rootScope();

  @override
  bool containsField(_) => true;

  @override
  jsAst.Name operator [](Entity field) {
    if (!names.containsKey(field)) add(field);
    return names[field]!;
  }
}
