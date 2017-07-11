// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This library defines individual world impacts.
///
/// We call these building blocks `uses`. Each `use` is a single impact of the
/// world. Some example uses are:
///
///  * an invocation of a top level function
///  * a call to the `foo()` method on an unknown class.
///  * an instantiation of class T
///
/// The different compiler stages combine these uses into `WorldImpact` objects,
/// which are later used to construct a closed-world understanding of the
/// program.
library dart2js.universe.use;

import '../closure.dart' show BoxFieldElement;
import '../common.dart';
import '../constants/values.dart';
import '../elements/types.dart';
import '../elements/elements.dart' show Element;
import '../elements/entities.dart';
import '../util/util.dart' show Hashing;
import '../world.dart' show World;
import 'call_structure.dart' show CallStructure;
import 'selector.dart' show Selector;
import 'world_builder.dart' show ReceiverConstraint;

enum DynamicUseKind {
  INVOKE,
  GET,
  SET,
}

/// The use of a dynamic property. [selector] defined the name and kind of the
/// property and [mask] defines the known constraint for the object on which
/// the property is accessed.
class DynamicUse {
  final Selector selector;
  final ReceiverConstraint mask;

  DynamicUse(this.selector, this.mask);

  bool appliesUnnamed(MemberEntity element, World world) {
    return selector.appliesUnnamed(element) &&
        (mask == null || mask.canHit(element, selector, world));
  }

  DynamicUseKind get kind {
    if (selector.isGetter) {
      return DynamicUseKind.GET;
    } else if (selector.isSetter) {
      return DynamicUseKind.SET;
    } else {
      return DynamicUseKind.INVOKE;
    }
  }

  int get hashCode => selector.hashCode * 13 + mask.hashCode * 17;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! DynamicUse) return false;
    return selector == other.selector && mask == other.mask;
  }

  String toString() => '$selector,$mask';
}

enum StaticUseKind {
  GENERAL,
  STATIC_TEAR_OFF,
  SUPER_TEAR_OFF,
  SUPER_FIELD_SET,
  FIELD_GET,
  FIELD_SET,
  CLOSURE,
  CONSTRUCTOR_INVOKE,
  CONST_CONSTRUCTOR_INVOKE,
  REDIRECTION,
  DIRECT_INVOKE,
  DIRECT_USE,
  INLINING,
}

/// Statically known use of an [Element].
// TODO(johnniwinther): Create backend-specific implementations with better
// invariants.
class StaticUse {
  final Entity element;
  final StaticUseKind kind;
  final int hashCode;
  final DartType type;

  StaticUse.internal(Entity element, StaticUseKind kind, [DartType type = null])
      : this.element = element,
        this.kind = kind,
        this.type = type,
        this.hashCode = Hashing.objectsHash(element, kind, type) {
    assert(
        !(element is Element && !element.isDeclaration),
        failedAt(element,
            "Static use element $element must be the declaration element."));
  }

  /// Invocation of a static or top-level [element] with the given
  /// [callStructure].
  factory StaticUse.staticInvoke(
      FunctionEntity element, CallStructure callStructure) {
    // TODO(johnniwinther): Use the [callStructure].
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static invoke element $element must be a top-level "
            "or static method."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Closurization of a static or top-level function [element].
  factory StaticUse.staticTearOff(FunctionEntity element) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static tear-off element $element must be a top-level "
            "or static method."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_TEAR_OFF);
  }

  /// Read access of a static or top-level field or getter [element].
  factory StaticUse.staticGet(MemberEntity element) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static get element $element must be a top-level "
            "or static method."));
    assert(
        element.isField || element.isGetter,
        failedAt(element,
            "Static get element $element must be a field or a getter."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Write access of a static or top-level field or setter [element].
  factory StaticUse.staticSet(MemberEntity element) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static set element $element "
            "must be a top-level or static method."));
    assert(
        element.isField || element.isSetter,
        failedAt(element,
            "Static set element $element must be a field or a setter."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Invocation of the lazy initializer for a static or top-level field
  /// [element].
  factory StaticUse.staticInit(FieldEntity element) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static init element $element must be a top-level "
            "or static method."));
    assert(element.isField,
        failedAt(element, "Static init element $element must be a field."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Invocation of a super method [element] with the given [callStructure].
  factory StaticUse.superInvoke(
      FunctionEntity element, CallStructure callStructure) {
    // TODO(johnniwinther): Use the [callStructure].
    assert(
        element.isInstanceMember,
        failedAt(element,
            "Super invoke element $element must be an instance method."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Read access of a super field or getter [element].
  factory StaticUse.superGet(MemberEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(
            element, "Super get element $element must be an instance method."));
    assert(
        element.isField || element.isGetter,
        failedAt(element,
            "Super get element $element must be a field or a getter."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Write access of a super field [element].
  factory StaticUse.superFieldSet(FieldEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(
            element, "Super set element $element must be an instance method."));
    assert(element.isField,
        failedAt(element, "Super set element $element must be a field."));
    return new StaticUse.internal(element, StaticUseKind.SUPER_FIELD_SET);
  }

  /// Write access of a super setter [element].
  factory StaticUse.superSetterSet(FunctionEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(
            element, "Super set element $element must be an instance method."));
    assert(element.isSetter,
        failedAt(element, "Super set element $element must be a setter."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Closurization of a super method [element].
  factory StaticUse.superTearOff(FunctionEntity element) {
    assert(
        element.isInstanceMember && element.isFunction,
        failedAt(element,
            "Super invoke element $element must be an instance method."));
    return new StaticUse.internal(element, StaticUseKind.SUPER_TEAR_OFF);
  }

  /// Invocation of a constructor [element] through a this or super
  /// constructor call with the given [callStructure].
  factory StaticUse.superConstructorInvoke(
      ConstructorEntity element, CallStructure callStructure) {
    // TODO(johnniwinther): Use the [callStructure].
    assert(
        element.isGenerativeConstructor,
        failedAt(
            element,
            "Constructor invoke element $element must be a "
            "generative constructor."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Invocation of a constructor (body) [element] through a this or super
  /// constructor call with the given [callStructure].
  factory StaticUse.constructorBodyInvoke(
      ConstructorBodyEntity element, CallStructure callStructure) {
    // TODO(johnniwinther): Use the [callStructure].
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Direct invocation of a method [element] with the given [callStructure].
  factory StaticUse.directInvoke(
      FunctionEntity element, CallStructure callStructure) {
    // TODO(johnniwinther): Use the [callStructure].
    assert(
        element.isInstanceMember,
        failedAt(element,
            "Direct invoke element $element must be an instance member."));
    assert(element.isFunction,
        failedAt(element, "Direct invoke element $element must be a method."));
    return new StaticUse.internal(element, StaticUseKind.DIRECT_INVOKE);
  }

  /// Direct read access of a field or getter [element].
  factory StaticUse.directGet(MemberEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(element,
            "Direct get element $element must be an instance member."));
    assert(
        element.isField || element.isGetter,
        failedAt(element,
            "Direct get element $element must be a field or a getter."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Direct write access of a field [element].
  factory StaticUse.directSet(FieldEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(element,
            "Direct set element $element must be an instance member."));
    assert(element.isField,
        failedAt(element, "Direct set element $element must be a field."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Constructor invocation of [element] with the given [callStructure].
  factory StaticUse.constructorInvoke(
      ConstructorEntity element, CallStructure callStructure) {
    assert(
        element.isConstructor,
        failedAt(element,
            "Constructor invocation element $element must be a constructor."));
    // TODO(johnniwinther): Use the [callStructure].
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Constructor invocation of [element] with the given [callStructure] on
  /// [type].
  factory StaticUse.typedConstructorInvoke(
      ConstructorEntity element, CallStructure callStructure, DartType type) {
    assert(type != null,
        failedAt(element, "No type provided for constructor invocation."));
    assert(
        element.isConstructor,
        failedAt(
            element,
            "Typed constructor invocation element $element "
            "must be a constructor."));
    // TODO(johnniwinther): Use the [callStructure].
    return new StaticUse.internal(
        element, StaticUseKind.CONSTRUCTOR_INVOKE, type);
  }

  /// Constant constructor invocation of [element] with the given
  /// [callStructure] on [type].
  factory StaticUse.constConstructorInvoke(
      ConstructorEntity element, CallStructure callStructure, DartType type) {
    assert(type != null,
        failedAt(element, "No type provided for constructor invocation."));
    assert(
        element.isConstructor,
        failedAt(
            element,
            "Const constructor invocation element $element "
            "must be a constructor."));
    // TODO(johnniwinther): Use the [callStructure].
    return new StaticUse.internal(
        element, StaticUseKind.CONST_CONSTRUCTOR_INVOKE, type);
  }

  /// Constructor redirection to [element] on [type].
  factory StaticUse.constructorRedirect(
      ConstructorEntity element, InterfaceType type) {
    assert(type != null,
        failedAt(element, "No type provided for constructor redirection."));
    assert(
        element.isConstructor,
        failedAt(element,
            "Constructor redirection element $element must be a constructor."));
    return new StaticUse.internal(element, StaticUseKind.REDIRECTION, type);
  }

  /// Initialization of an instance field [element].
  factory StaticUse.fieldInit(FieldEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(
            element, "Field init element $element must be an instance field."));
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Read access of an instance field or boxed field [element].
  factory StaticUse.fieldGet(FieldEntity element) {
    assert(
        element.isInstanceMember || element is BoxFieldElement,
        failedAt(element,
            "Field init element $element must be an instance or boxed field."));
    return new StaticUse.internal(element, StaticUseKind.FIELD_GET);
  }

  /// Write access of an instance field or boxed field [element].
  factory StaticUse.fieldSet(FieldEntity element) {
    assert(
        element.isInstanceMember || element is BoxFieldElement,
        failedAt(element,
            "Field init element $element must be an instance or boxed field."));
    return new StaticUse.internal(element, StaticUseKind.FIELD_SET);
  }

  /// Read of a local function [element].
  factory StaticUse.closure(Local element) {
    return new StaticUse.internal(element, StaticUseKind.CLOSURE);
  }

  /// Use of [element] through reflection.
  factory StaticUse.mirrorUse(MemberEntity element) {
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Implicit method/constructor invocation of [element] created by the
  /// backend.
  factory StaticUse.implicitInvoke(FunctionEntity element) {
    return new StaticUse.internal(element, StaticUseKind.GENERAL);
  }

  /// Direct use of [element] as done with `--analyze-all` and `--analyze-main`.
  factory StaticUse.directUse(Entity element) {
    return new StaticUse.internal(element, StaticUseKind.DIRECT_USE);
  }

  /// Inlining of [element].
  factory StaticUse.inlining(FunctionEntity element) {
    return new StaticUse.internal(element, StaticUseKind.INLINING);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! StaticUse) return false;
    return element == other.element && kind == other.kind && type == other.type;
  }

  String toString() => 'StaticUse($element,$kind,$type)';
}

enum TypeUseKind {
  IS_CHECK,
  AS_CAST,
  CHECKED_MODE_CHECK,
  CATCH_TYPE,
  TYPE_LITERAL,
  INSTANTIATION,
  MIRROR_INSTANTIATION,
  NATIVE_INSTANTIATION,
}

/// Use of a [ResolutionDartType].
class TypeUse {
  final DartType type;
  final TypeUseKind kind;
  final int hashCode;

  TypeUse.internal(DartType type, TypeUseKind kind)
      : this.type = type,
        this.kind = kind,
        this.hashCode = Hashing.objectHash(type, Hashing.objectHash(kind));

  /// [type] used in an is check, like `e is T` or `e is! T`.
  factory TypeUse.isCheck(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.IS_CHECK);
  }

  /// [type] used in an as cast, like `e as T`.
  factory TypeUse.asCast(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.AS_CAST);
  }

  /// [type] used as a type annotation, like `T foo;`.
  factory TypeUse.checkedModeCheck(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.CHECKED_MODE_CHECK);
  }

  /// [type] used in a on type catch clause, like `try {} on T catch (e) {}`.
  factory TypeUse.catchType(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.CATCH_TYPE);
  }

  /// [type] used as a type literal, like `foo() => T;`.
  factory TypeUse.typeLiteral(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.TYPE_LITERAL);
  }

  /// [type] used in an instantiation, like `new T();`.
  factory TypeUse.instantiation(InterfaceType type) {
    return new TypeUse.internal(type, TypeUseKind.INSTANTIATION);
  }

  /// [type] used in an instantiation through mirrors.
  factory TypeUse.mirrorInstantiation(InterfaceType type) {
    return new TypeUse.internal(type, TypeUseKind.MIRROR_INSTANTIATION);
  }

  /// [type] used in a native instantiation.
  factory TypeUse.nativeInstantiation(InterfaceType type) {
    return new TypeUse.internal(type, TypeUseKind.NATIVE_INSTANTIATION);
  }

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! TypeUse) return false;
    return type == other.type && kind == other.kind;
  }

  String toString() => 'TypeUse($type,$kind)';
}

enum ConstantUseKind {
  // A constant that is directly accessible in code.
  DIRECT,
  // A constant that is only accessible through other constants.
  INDIRECT,
}

/// Use of a [ConstantValue].
class ConstantUse {
  final ConstantValue value;
  final ConstantUseKind kind;
  final int hashCode;

  ConstantUse._(this.value, this.kind)
      : this.hashCode = Hashing.objectHash(value, kind.hashCode);

  /// Constant used as the initial value of a field.
  ConstantUse.init(ConstantValue value) : this._(value, ConstantUseKind.DIRECT);

  /// Type constant used for registration of custom elements.
  ConstantUse.customElements(TypeConstantValue value)
      : this._(value, ConstantUseKind.DIRECT);

  /// Constant used through a lookup map.
  ConstantUse.lookupMap(ConstantValue value)
      : this._(value, ConstantUseKind.INDIRECT);

  /// Constant used through mirrors.
  // TODO(johnniwinther): Maybe if this is `DIRECT` and we can avoid the
  // extra calls to `addCompileTimeConstantForEmission`.
  ConstantUse.mirrors(ConstantValue value)
      : this._(value, ConstantUseKind.INDIRECT);

  /// Constant used for accessing type variables through mirrors.
  ConstantUse.typeVariableMirror(ConstantValue value)
      : this._(value, ConstantUseKind.DIRECT);

  /// Constant literal used on code.
  ConstantUse.literal(ConstantValue value)
      : this._(value, ConstantUseKind.DIRECT);

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ConstantUse) return false;
    return value == other.value;
  }

  String toString() => 'ConstantUse(${value.toStructuredText()},$kind)';
}
