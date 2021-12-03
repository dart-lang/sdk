// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

/// [member] is an instance field.
///
/// [name] is the field name that the [Namer] has picked for this field's
/// storage, that is, the JavaScript property name.
///
/// [needsGetter] and [needsSetter] represent if a getter or a setter
/// respectively is needed.  There are many factors in this, for example, if the
/// accessor can be inlined.
///
/// [needsCheckedSetter] indicates that a checked getter is needed, and in this
/// case, [needsSetter] is always false. [needsCheckedSetter] is only true when
/// type assertions are enabled (checked mode).
typedef AcceptField = void Function(FieldEntity member, js.Name name,
    bool needsGetter, bool needsSetter, bool needsCheckedSetter);

class FieldVisitor {
  final JElementEnvironment _elementEnvironment;
  final CodegenWorld _codegenWorld;
  final NativeData _nativeData;
  final Namer _namer;
  final JClosedWorld _closedWorld;

  FieldVisitor(this._elementEnvironment, this._codegenWorld, this._nativeData,
      this._namer, this._closedWorld);

  /// Invokes [f] for each of the fields of [element].
  ///
  /// When visiting the instance fields of a class, the fields of its superclass
  /// are also visited if the class is instantiated.
  void visitFields(AcceptField f, ClassEntity cls) {
    assert(
        cls != null, failedAt(NO_LOCATION_SPANNABLE, 'Expected a ClassEntity'));

    bool isNativeClass = _nativeData.isNativeClass(cls);

    // If the class is never instantiated we still need to set it up for
    // inheritance purposes, but we can simplify its JavaScript constructor.
    bool isInstantiated =
        _codegenWorld.directlyInstantiatedClasses.contains(cls);

    void visitField(FieldEntity field, {ClassEntity holder}) {
      bool isMixinNativeField =
          isNativeClass && _elementEnvironment.isMixinApplication(holder);

      // See if we can dynamically create getters and setters.
      // We can only generate getters and setters for [element] since
      // the fields of super classes could be overwritten with getters or
      // setters.
      bool needsGetter = false;
      bool needsSetter = false;
      if (isMixinNativeField || holder == cls) {
        needsGetter = fieldNeedsGetter(field);
        needsSetter = fieldNeedsSetter(field);
      }

      if ((isInstantiated && !_nativeData.isNativeClass(cls)) ||
          needsGetter ||
          needsSetter) {
        js.Name fieldName = _namer.instanceFieldPropertyName(field);
        bool needsCheckedSetter = false;
        if (_closedWorld.annotationsData
                .getParameterCheckPolicy(field)
                .isEmitted &&
            needsSetter &&
            !canAvoidGeneratedCheckedSetter(field)) {
          needsCheckedSetter = true;
          needsSetter = false;
        }
        // Getters and setters with suffixes will be generated dynamically.
        f(field, fieldName, needsGetter, needsSetter, needsCheckedSetter);
      }
    }

    // TODO(kasperl): We should make sure to only emit one version of
    // overridden fields. Right now, we rely on the ordering so the
    // fields pulled in from mixins are replaced with the fields from
    // the class definition.

    // If a class is not instantiated then we add the field just so we can
    // generate the field getter/setter dynamically. Since this is only
    // allowed on fields that are in [element] we don't need to visit
    // superclasses for non-instantiated classes.
    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity holder, MemberEntity member) {
      if (cls != holder && !isInstantiated) return;
      if (member.isField && !member.isStatic) {
        visitField(member, holder: holder);
      }
    });
  }

  bool fieldNeedsGetter(FieldEntity field) {
    assert(field.isField);
    if (fieldAccessNeverThrows(field)) return false;
    return field.isInstanceMember && _codegenWorld.hasInvokedGetter(field);
  }

  bool fieldNeedsSetter(FieldEntity field) {
    assert(field.isField);
    if (fieldAccessNeverThrows(field)) return false;
    if (!field.isAssignable) return false;
    return field.isInstanceMember && _codegenWorld.hasInvokedSetter(field);
  }

  static bool fieldAccessNeverThrows(FieldEntity field) {
    return
        // We never access a field in a closure (a captured variable) without
        // knowing that it is there.  Therefore we don't need to use a getter
        // (that will throw if the getter method is missing), but can always
        // access the field directly.
        // TODO(johnniwinther): Return `true` JClosureField.
        false;
  }

  bool canAvoidGeneratedCheckedSetter(FieldEntity member) {
    // We never generate accessors for top-level/static fields.
    if (!member.isInstanceMember) return true;
    DartType type = _elementEnvironment.getFieldType(member);
    return _closedWorld.dartTypes.isTopType(type);
  }
}
