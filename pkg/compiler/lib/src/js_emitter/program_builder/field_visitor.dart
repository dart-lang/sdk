// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dart2js.js_emitter.program_builder;

/**
 * [member] is a field (instance, static, or top level).
 *
 * [name] is the field name that the [Namer] has picked for this field's
 * storage, that is, the JavaScript property name.
 *
 * [accessorName] is the name of the accessor. For instance fields this is
 * mostly the same as [name] except when [member] is shadowing a field in its
 * superclass.  For other fields, they are rarely the same.
 *
 * [needsGetter] and [needsSetter] represent if a getter or a setter
 * respectively is needed.  There are many factors in this, for example, if the
 * accessor can be inlined.
 *
 * [needsCheckedSetter] indicates that a checked getter is needed, and in this
 * case, [needsSetter] is always false. [needsCheckedSetter] is only true when
 * type assertions are enabled (checked mode).
 */
typedef void AcceptField(FieldEntity member, js.Name name, js.Name accessorName,
    bool needsGetter, bool needsSetter, bool needsCheckedSetter);

class FieldVisitor {
  final CompilerOptions _options;
  final ElementEnvironment _elementEnvironment;
  final CodegenWorldBuilder _codegenWorldBuilder;
  final NativeData _nativeData;
  final MirrorsData _mirrorsData;
  final Namer _namer;
  final ClosedWorld _closedWorld;

  FieldVisitor(
      this._options,
      this._elementEnvironment,
      this._codegenWorldBuilder,
      this._nativeData,
      this._mirrorsData,
      this._namer,
      this._closedWorld);

  /**
   * Invokes [f] for each of the fields of [element].
   *
   * [element] must be a [ClassElement] or a [LibraryElement].
   *
   * If [element] is a [ClassElement], the static fields of the class are
   * visited if [visitStatics] is true and the instance fields are visited if
   * [visitStatics] is false.
   *
   * If [element] is a [LibraryElement], [visitStatics] must be true.
   *
   * When visiting the instance fields of a class, the fields of its superclass
   * are also visited if the class is instantiated.
   *
   * Invariant: [element] must be a declaration element.
   */
  void visitFields(AcceptField f,
      {bool visitStatics: false, LibraryEntity library, ClassEntity cls}) {
    assert(!(library is LibraryElement && !library.isDeclaration),
        failedAt(library));
    assert(!(cls is ClassElement && !cls.isDeclaration), failedAt(cls));

    bool isNativeClass = false;
    bool isLibrary = false;
    bool isInstantiated = false;
    if (cls != null) {
      isNativeClass = _nativeData.isNativeClass(cls);

      // If the class is never instantiated we still need to set it up for
      // inheritance purposes, but we can simplify its JavaScript constructor.
      isInstantiated =
          _codegenWorldBuilder.directlyInstantiatedClasses.contains(cls);
    } else if (library != null) {
      isLibrary = true;
      assert(visitStatics, failedAt(library));
    } else {
      failedAt(NO_LOCATION_SPANNABLE,
          'Expected a ClassElement or a LibraryElement.');
    }

    void visitField(FieldEntity field, {ClassEntity holder}) {
      assert(!(field is FieldElement && !field.isDeclaration), failedAt(field));

      bool isMixinNativeField =
          isNativeClass && _elementEnvironment.isMixinApplication(holder);

      // See if we can dynamically create getters and setters.
      // We can only generate getters and setters for [element] since
      // the fields of super classes could be overwritten with getters or
      // setters.
      bool needsGetter = false;
      bool needsSetter = false;
      if (isLibrary || isMixinNativeField || holder == cls) {
        needsGetter = fieldNeedsGetter(field);
        needsSetter = fieldNeedsSetter(field);
      }

      if ((isInstantiated && !_nativeData.isNativeClass(cls)) ||
          needsGetter ||
          needsSetter) {
        js.Name accessorName = _namer.fieldAccessorName(field);
        js.Name fieldName = _namer.fieldPropertyName(field);
        bool needsCheckedSetter = false;
        if (_options.enableTypeAssertions &&
            needsSetter &&
            !canAvoidGeneratedCheckedSetter(field)) {
          needsCheckedSetter = true;
          needsSetter = false;
        }
        // Getters and setters with suffixes will be generated dynamically.
        f(field, fieldName, accessorName, needsGetter, needsSetter,
            needsCheckedSetter);
      }
    }

    if (isLibrary) {
      _elementEnvironment.forEachLibraryMember(library, (MemberEntity member) {
        if (member.isField) visitField(member);
      });
    } else if (visitStatics) {
      _elementEnvironment.forEachClassMember(cls,
          (ClassEntity holder, MemberEntity member) {
        if (cls == holder && member.isField && member.isStatic) {
          visitField(member, holder: holder);
        }
      });
    } else {
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
  }

  bool fieldNeedsGetter(FieldEntity field) {
    assert(field.isField);
    if (fieldAccessNeverThrows(field)) return false;
    if (_mirrorsData.shouldRetainGetter(field)) return true;
    return field.enclosingClass != null &&
        _codegenWorldBuilder.hasInvokedGetter(field, _closedWorld);
  }

  bool fieldNeedsSetter(FieldEntity field) {
    assert(field.isField);
    if (fieldAccessNeverThrows(field)) return false;
    if (!field.isAssignable) return false;
    if (_mirrorsData.shouldRetainSetter(field)) return true;
    return field.enclosingClass != null &&
        _codegenWorldBuilder.hasInvokedSetter(field, _closedWorld);
  }

  static bool fieldAccessNeverThrows(FieldEntity field) {
    return
        // We never access a field in a closure (a captured variable) without
        // knowing that it is there.  Therefore we don't need to use a getter
        // (that will throw if the getter method is missing), but can always
        // access the field directly.
        field is ClosureFieldElement;
  }

  bool canAvoidGeneratedCheckedSetter(FieldElement member) {
    // We never generate accessors for top-level/static fields.
    if (!member.isInstanceMember) return true;
    ResolutionDartType type = member.type;
    return type.treatAsDynamic || type.isObject;
  }
}
