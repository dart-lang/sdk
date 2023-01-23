// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

/// [member] is an instance field.
///
/// [needsGetter] and [needsSetter] represent if a getter or a setter
/// respectively is needed.  There are many factors in this, for example, if the
/// accessor can be inlined.
///
/// [needsCheckedSetter] indicates that a checked getter is needed, and in this
/// case, [needsSetter] is always false. [needsCheckedSetter] is only true when
/// type assertions are enabled (checked mode).
typedef AcceptField = void Function(FieldEntity member, bool needsGetter,
    bool needsSetter, bool needsCheckedSetter);

class FieldVisitor {
  final JElementEnvironment _elementEnvironment;
  final CodegenWorld _codegenWorld;
  final NativeData _nativeData;
  final JClosedWorld _closedWorld;

  FieldVisitor(this._elementEnvironment, this._codegenWorld, this._nativeData,
      this._closedWorld);

  /// Invokes [f] for each of the fields of [cls].
  ///
  /// If the class is directly instantiated, the fields of the superclasses are
  /// also visited. These are required for creating a constructor that
  /// initializes all the fields of the class.
  ///
  /// If the class is not directly instantiated
  void visitFields(AcceptField f, ClassEntity cls) {
    bool isNativeClass = _nativeData.isNativeClass(cls);

    // If the class is never instantiated we still need to set it up for
    // inheritance purposes, but we can simplify its JavaScript constructor.
    bool isDirectlyInstantiated =
        _codegenWorld.directlyInstantiatedClasses.contains(cls);

    void visitField(FieldEntity field, {required ClassEntity holder}) {
      // Simple getters and setters are generated in the emitter rather than
      // being compiled through the SSA pipeline.
      bool needsGetter = false;
      bool needsSetter = false;

      // In the J-model, instance members of a mixin are copied into the mixin
      // application. At run time the methods are copied from the mixin's
      // prototype to the mixin application's prototype. So we don't want to
      // generate getters and setters for a field in a mixin application.
      //
      // A exception is when the mixin is used in a native class.
      //
      // TODO(sra): Figure out why native classes are different. It would seem
      // that the native class methods are on an interceptor class and therefore
      // the mixin application would be constructed just like any other class.
      //
      // TODO(49536): The only mixins-that-have-fields used on native classes
      // come from extending custom elements. Mixins used in, say, `dart:html`
      // have no fields. After removing custom elements, enforce that mixins in
      // native classes have no fields.
      bool isMixinApplication = _elementEnvironment.isMixinApplication(holder);
      bool isMixinNativeField = isNativeClass && isMixinApplication;

      // Generate getters and setters for fields of [cls] only, since the fields
      // of super classes are the responsibility of the superclass.
      if (isMixinNativeField || (cls == holder && !isMixinApplication)) {
        needsGetter = fieldNeedsGetter(field);
        needsSetter = fieldNeedsSetter(field);
      }

      if ((isDirectlyInstantiated && !isNativeClass) ||
          needsGetter ||
          needsSetter) {
        bool needsCheckedSetter = false;
        if (needsSetter &&
            _closedWorld.annotationsData
                .getParameterCheckPolicy(field)
                .isEmitted &&
            !_canAvoidGeneratedCheckedSetter(field)) {
          needsCheckedSetter = true;
          needsSetter = false;
        }
        // Getters and setters with suffixes will be generated dynamically.
        f(field, needsGetter, needsSetter, needsCheckedSetter);
      }
    }

    _elementEnvironment.forEachClassMember(cls,
        (ClassEntity holder, MemberEntity member) {
      // Classes that are not directly instantiated do not use the JavaScript
      // constructor function to allocate and initialize an object. We don't
      // need to visit the superclasses since their fields are not used by the
      // JavaScript constructor and their getters and setters are inherited.
      if (cls != holder && !isDirectlyInstantiated) return;

      if (member is FieldEntity && !member.isStatic) {
        visitField(member, holder: holder);
      }
    });
  }

  bool fieldNeedsGetter(FieldEntity field) {
    if (fieldAccessNeverThrows(field)) return false;
    return field.isInstanceMember && _codegenWorld.hasInvokedGetter(field);
  }

  bool fieldNeedsSetter(FieldEntity field) {
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

  bool _canAvoidGeneratedCheckedSetter(FieldEntity member) {
    // We never generate accessors for top-level/static fields.
    if (!member.isInstanceMember) return true;
    DartType type = _elementEnvironment.getFieldType(member);
    return _closedWorld.dartTypes.isTopType(type);
  }
}
