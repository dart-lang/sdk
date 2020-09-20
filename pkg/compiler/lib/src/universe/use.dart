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

import '../common.dart';
import '../constants/values.dart';
import '../elements/types.dart';
import '../elements/entities.dart';
import '../inferrer/abstract_value_domain.dart';
import '../serialization/serialization.dart';
import '../js_model/closure.dart';
import '../util/util.dart' show equalElements, Hashing;
import 'call_structure.dart' show CallStructure;
import 'selector.dart' show Selector;
import 'world_builder.dart' show StrongModeConstraint;

enum DynamicUseKind {
  INVOKE,
  GET,
  SET,
}

/// The use of a dynamic property. [selector] defined the name and kind of the
/// property and [receiverConstraint] defines the known constraint for the
/// object on which the property is accessed.
class DynamicUse {
  static const String tag = 'dynamic-use';

  final Selector selector;
  final Object receiverConstraint;
  final List<DartType> _typeArguments;

  DynamicUse(this.selector, this.receiverConstraint, this._typeArguments) {
    assert(
        selector.callStructure.typeArgumentCount ==
            (_typeArguments?.length ?? 0),
        "Type argument count mismatch. Selector has "
        "${selector.callStructure.typeArgumentCount} but "
        "${_typeArguments?.length ?? 0} were passed.");
  }

  DynamicUse withReceiverConstraint(Object otherReceiverConstraint) {
    if (otherReceiverConstraint == receiverConstraint) {
      return this;
    }
    return DynamicUse(selector, otherReceiverConstraint, _typeArguments);
  }

  factory DynamicUse.readFromDataSource(DataSource source) {
    source.begin(tag);
    Selector selector = Selector.readFromDataSource(source);
    bool hasConstraint = source.readBool();
    Object receiverConstraint;
    if (hasConstraint) {
      receiverConstraint = source.readAbstractValue();
    }
    List<DartType> typeArguments = source.readDartTypes(emptyAsNull: true);
    source.end(tag);
    return new DynamicUse(selector, receiverConstraint, typeArguments);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    selector.writeToDataSink(sink);
    sink.writeBool(receiverConstraint != null);
    if (receiverConstraint != null) {
      if (receiverConstraint is AbstractValue) {
        sink.writeAbstractValue(receiverConstraint);
      } else {
        throw new UnsupportedError(
            "Unsupported receiver constraint: ${receiverConstraint}");
      }
    }
    sink.writeDartTypes(_typeArguments, allowNull: true);
    sink.end(tag);
  }

  /// Short textual representation use for testing.
  String get shortText {
    StringBuffer sb = new StringBuffer();
    if (receiverConstraint != null) {
      var constraint = receiverConstraint;
      if (constraint is StrongModeConstraint) {
        if (constraint.isThis) {
          sb.write('this:');
        } else if (constraint.isExact) {
          sb.write('exact:');
        }
        sb.write(constraint.cls.name);
      } else {
        sb.write(constraint);
      }
      sb.write('.');
    }
    sb.write(selector.name);
    if (typeArguments != null && typeArguments.isNotEmpty) {
      sb.write('<');
      sb.write(typeArguments.join(','));
      sb.write('>');
    }
    if (selector.isCall) {
      sb.write(selector.callStructure.shortText);
    } else if (selector.isSetter) {
      sb.write('=');
    }
    return sb.toString();
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

  List<DartType> get typeArguments => _typeArguments ?? const <DartType>[];

  @override
  int get hashCode => Hashing.listHash(
      typeArguments, Hashing.objectsHash(selector, receiverConstraint));

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! DynamicUse) return false;
    return selector == other.selector &&
        receiverConstraint == other.receiverConstraint &&
        equalElements(typeArguments, other.typeArguments);
  }

  @override
  String toString() => '$selector,$receiverConstraint,$typeArguments';
}

enum StaticUseKind {
  STATIC_TEAR_OFF,
  SUPER_TEAR_OFF,
  SUPER_FIELD_SET,
  SUPER_GET,
  SUPER_SETTER_SET,
  SUPER_INVOKE,
  INSTANCE_FIELD_GET,
  INSTANCE_FIELD_SET,
  CLOSURE,
  CLOSURE_CALL,
  CALL_METHOD,
  CONSTRUCTOR_INVOKE,
  CONST_CONSTRUCTOR_INVOKE,
  DIRECT_INVOKE,
  INLINING,
  STATIC_INVOKE,
  STATIC_GET,
  STATIC_SET,
  FIELD_INIT,
  FIELD_CONSTANT_INIT,
}

/// Statically known use of an [Entity].
// TODO(johnniwinther): Create backend-specific implementations with better
// invariants.
class StaticUse {
  static const String tag = 'static-use';

  final Entity element;
  final StaticUseKind kind;
  @override
  final int hashCode;
  final InterfaceType type;
  final CallStructure callStructure;
  final ImportEntity deferredImport;
  final ConstantValue constant;
  final List<DartType> typeArguments;

  StaticUse.internal(Entity element, this.kind,
      {this.type,
      this.callStructure,
      this.deferredImport,
      this.typeArguments,
      this.constant})
      : this.element = element,
        this.hashCode = Hashing.listHash([
          element,
          kind,
          type,
          Hashing.listHash(typeArguments),
          callStructure,
          deferredImport,
          constant
        ]);

  bool _checkGenericInvariants() {
    assert(
        (callStructure?.typeArgumentCount ?? 0) == (typeArguments?.length ?? 0),
        failedAt(
            element,
            "Type argument count mismatch. Call structure has "
            "${callStructure?.typeArgumentCount ?? 0} but "
            "${typeArguments?.length ?? 0} were passed in $this."));
    return true;
  }

  factory StaticUse.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberEntity element = source.readMember();
    StaticUseKind kind = source.readEnum(StaticUseKind.values);
    InterfaceType type = source.readDartType(allowNull: true);
    CallStructure callStructure =
        source.readValueOrNull(() => CallStructure.readFromDataSource(source));
    ImportEntity deferredImport = source.readImportOrNull();
    ConstantValue constant = source.readConstantOrNull();
    List<DartType> typeArguments = source.readDartTypes(emptyAsNull: true);
    source.end(tag);
    return new StaticUse.internal(element, kind,
        type: type,
        callStructure: callStructure,
        deferredImport: deferredImport,
        constant: constant,
        typeArguments: typeArguments);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    assert(element is MemberEntity, "Unsupported entity: $element");
    sink.writeMember(element);
    sink.writeEnum(kind);
    sink.writeDartType(type, allowNull: true);
    sink.writeValueOrNull(
        callStructure, (CallStructure c) => c.writeToDataSink(sink));
    sink.writeImportOrNull(deferredImport);
    sink.writeConstantOrNull(constant);
    sink.writeDartTypes(typeArguments, allowNull: true);
    sink.end(tag);
  }

  /// Short textual representation use for testing.
  String get shortText {
    StringBuffer sb = new StringBuffer();
    switch (kind) {
      case StaticUseKind.INSTANCE_FIELD_SET:
      case StaticUseKind.SUPER_FIELD_SET:
      case StaticUseKind.SUPER_SETTER_SET:
      case StaticUseKind.STATIC_SET:
        sb.write('set:');
        break;
      case StaticUseKind.FIELD_INIT:
        sb.write('init:');
        break;
      case StaticUseKind.CLOSURE:
        sb.write('def:');
        break;
      default:
    }
    if (element is MemberEntity) {
      MemberEntity member = element;
      if (member.enclosingClass != null) {
        sb.write(member.enclosingClass.name);
        sb.write('.');
      }
    }
    if (element.name == null) {
      sb.write('<anonymous>');
    } else {
      sb.write(element.name);
    }
    if (typeArguments != null && typeArguments.isNotEmpty) {
      sb.write('<');
      sb.write(typeArguments.join(','));
      sb.write('>');
    }
    if (callStructure != null) {
      sb.write('(');
      sb.write(callStructure.positionalArgumentCount);
      if (callStructure.namedArgumentCount > 0) {
        sb.write(',');
        sb.write(callStructure.getOrderedNamedArguments().join(','));
      }
      sb.write(')');
    }
    if (deferredImport != null) {
      sb.write('{');
      sb.write(deferredImport.name);
      sb.write('}');
    }
    if (constant != null) {
      sb.write('=');
      sb.write(constant.toStructuredText(null));
    }
    return sb.toString();
  }

  /// Invocation of a static or top-level [element] with the given
  /// [callStructure].
  factory StaticUse.staticInvoke(
      FunctionEntity element, CallStructure callStructure,
      [List<DartType> typeArguments, ImportEntity deferredImport]) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static invoke element $element must be a top-level "
            "or static method."));
    assert(element.isFunction,
        failedAt(element, "Static get element $element must be a function."));
    assert(
        callStructure != null,
        failedAt(element,
            "Not CallStructure for static invocation of element $element."));

    StaticUse staticUse = new StaticUse.internal(
        element, StaticUseKind.STATIC_INVOKE,
        callStructure: callStructure,
        typeArguments: typeArguments,
        deferredImport: deferredImport);
    assert(staticUse._checkGenericInvariants());
    return staticUse;
  }

  /// Closurization of a static or top-level function [element].
  factory StaticUse.staticTearOff(FunctionEntity element,
      [ImportEntity deferredImport]) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static tear-off element $element must be a top-level "
            "or static method."));
    assert(element.isFunction,
        failedAt(element, "Static get element $element must be a function."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_TEAR_OFF,
        deferredImport: deferredImport);
  }

  /// Read access of a static or top-level field or getter [element].
  factory StaticUse.staticGet(MemberEntity element,
      [ImportEntity deferredImport]) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static get element $element must be a top-level "
            "or static field or getter."));
    assert(
        element.isField || element.isGetter,
        failedAt(element,
            "Static get element $element must be a field or a getter."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_GET,
        deferredImport: deferredImport);
  }

  /// Write access of a static or top-level field or setter [element].
  factory StaticUse.staticSet(MemberEntity element,
      [ImportEntity deferredImport]) {
    assert(
        element.isStatic || element.isTopLevel,
        failedAt(
            element,
            "Static set element $element "
            "must be a top-level or static method."));
    assert(
        (element.isField && element.isAssignable) || element.isSetter,
        failedAt(element,
            "Static set element $element must be a field or a setter."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_SET,
        deferredImport: deferredImport);
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
    return new StaticUse.internal(element, StaticUseKind.FIELD_INIT);
  }

  /// Invocation of a super method [element] with the given [callStructure].
  factory StaticUse.superInvoke(
      FunctionEntity element, CallStructure callStructure,
      [List<DartType> typeArguments]) {
    assert(
        element.isInstanceMember,
        failedAt(element,
            "Super invoke element $element must be an instance method."));
    assert(
        callStructure != null,
        failedAt(element,
            "Not CallStructure for super invocation of element $element."));
    StaticUse staticUse = new StaticUse.internal(
        element, StaticUseKind.SUPER_INVOKE,
        callStructure: callStructure, typeArguments: typeArguments);
    assert(staticUse._checkGenericInvariants());
    return staticUse;
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
    return new StaticUse.internal(element, StaticUseKind.SUPER_GET);
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
    return new StaticUse.internal(element, StaticUseKind.SUPER_SETTER_SET);
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
    assert(
        element.isGenerativeConstructor,
        failedAt(
            element,
            "Constructor invoke element $element must be a "
            "generative constructor."));
    assert(
        callStructure != null,
        failedAt(
            element,
            "Not CallStructure for super constructor invocation of element "
            "$element."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_INVOKE,
        callStructure: callStructure);
  }

  /// Invocation of a constructor (body) [element] through a this or super
  /// constructor call with the given [callStructure].
  factory StaticUse.constructorBodyInvoke(
      ConstructorBodyEntity element, CallStructure callStructure) {
    assert(
        callStructure != null,
        failedAt(
            element,
            "Not CallStructure for constructor body invocation of element "
            "$element."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_INVOKE,
        callStructure: callStructure);
  }

  /// Direct invocation of a generator (body) [element], as a static call or
  /// through a this or super constructor call.
  factory StaticUse.generatorBodyInvoke(FunctionEntity element) {
    return new StaticUse.internal(element, StaticUseKind.STATIC_INVOKE,
        callStructure: CallStructure.NO_ARGS);
  }

  /// Direct invocation of a method [element] with the given [callStructure].
  factory StaticUse.directInvoke(FunctionEntity element,
      CallStructure callStructure, List<DartType> typeArguments) {
    assert(
        element.isInstanceMember,
        failedAt(element,
            "Direct invoke element $element must be an instance member."));
    assert(element.isFunction,
        failedAt(element, "Direct invoke element $element must be a method."));
    StaticUse staticUse = new StaticUse.internal(
        element, StaticUseKind.DIRECT_INVOKE,
        callStructure: callStructure, typeArguments: typeArguments);
    assert(staticUse._checkGenericInvariants());
    return staticUse;
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
    return new StaticUse.internal(element, StaticUseKind.STATIC_GET);
  }

  /// Direct write access of a field [element].
  factory StaticUse.directSet(FieldEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(element,
            "Direct set element $element must be an instance member."));
    assert(element.isField,
        failedAt(element, "Direct set element $element must be a field."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_SET);
  }

  /// Constructor invocation of [element] with the given [callStructure].
  factory StaticUse.constructorInvoke(
      ConstructorEntity element, CallStructure callStructure) {
    assert(
        element.isConstructor,
        failedAt(element,
            "Constructor invocation element $element must be a constructor."));
    assert(
        callStructure != null,
        failedAt(
            element,
            "Not CallStructure for constructor invocation of element "
            "$element."));
    return new StaticUse.internal(element, StaticUseKind.STATIC_INVOKE,
        callStructure: callStructure);
  }

  /// Constructor invocation of [element] with the given [callStructure] on
  /// [type].
  factory StaticUse.typedConstructorInvoke(
      ConstructorEntity element,
      CallStructure callStructure,
      InterfaceType type,
      ImportEntity deferredImport) {
    assert(type != null,
        failedAt(element, "No type provided for constructor invocation."));
    assert(
        element.isConstructor,
        failedAt(
            element,
            "Typed constructor invocation element $element "
            "must be a constructor."));
    return new StaticUse.internal(element, StaticUseKind.CONSTRUCTOR_INVOKE,
        type: type,
        callStructure: callStructure,
        deferredImport: deferredImport);
  }

  /// Constant constructor invocation of [element] with the given
  /// [callStructure] on [type].
  factory StaticUse.constConstructorInvoke(
      ConstructorEntity element,
      CallStructure callStructure,
      InterfaceType type,
      ImportEntity deferredImport) {
    assert(type != null,
        failedAt(element, "No type provided for constructor invocation."));
    assert(
        element.isConstructor,
        failedAt(
            element,
            "Const constructor invocation element $element "
            "must be a constructor."));
    return new StaticUse.internal(
        element, StaticUseKind.CONST_CONSTRUCTOR_INVOKE,
        type: type,
        callStructure: callStructure,
        deferredImport: deferredImport);
  }

  /// Initialization of an instance field [element].
  factory StaticUse.fieldInit(FieldEntity element) {
    assert(
        element.isInstanceMember,
        failedAt(
            element, "Field init element $element must be an instance field."));
    return new StaticUse.internal(element, StaticUseKind.FIELD_INIT);
  }

  /// Constant initialization of an instance field [element].
  factory StaticUse.fieldConstantInit(
      FieldEntity element, ConstantValue constant) {
    assert(
        element.isInstanceMember,
        failedAt(
            element, "Field init element $element must be an instance field."));
    return new StaticUse.internal(element, StaticUseKind.FIELD_CONSTANT_INIT,
        constant: constant);
  }

  /// Read access of an instance field or boxed field [element].
  factory StaticUse.fieldGet(FieldEntity element) {
    assert(
        element.isInstanceMember || element is JRecordField,
        failedAt(element,
            "Field init element $element must be an instance or boxed field."));
    return new StaticUse.internal(element, StaticUseKind.INSTANCE_FIELD_GET);
  }

  /// Write access of an instance field or boxed field [element].
  factory StaticUse.fieldSet(FieldEntity element) {
    assert(
        element.isInstanceMember || element is JRecordField,
        failedAt(element,
            "Field init element $element must be an instance or boxed field."));
    return new StaticUse.internal(element, StaticUseKind.INSTANCE_FIELD_SET);
  }

  /// Read of a local function [element].
  factory StaticUse.closure(Local element) {
    return new StaticUse.internal(element, StaticUseKind.CLOSURE);
  }

  /// An invocation of a local function [element] with the provided
  /// [callStructure] and [typeArguments].
  factory StaticUse.closureCall(Local element, CallStructure callStructure,
      List<DartType> typeArguments) {
    StaticUse staticUse = new StaticUse.internal(
        element, StaticUseKind.CLOSURE_CALL,
        callStructure: callStructure, typeArguments: typeArguments);
    assert(staticUse._checkGenericInvariants());
    return staticUse;
  }

  /// Read of a call [method] on a closureClass.
  factory StaticUse.callMethod(FunctionEntity method) {
    return new StaticUse.internal(method, StaticUseKind.CALL_METHOD);
  }

  /// Implicit method/constructor invocation of [element] created by the
  /// backend.
  factory StaticUse.implicitInvoke(FunctionEntity element) {
    return new StaticUse.internal(element, StaticUseKind.STATIC_INVOKE,
        callStructure: element.parameterStructure.callStructure);
  }

  /// Inlining of [element].
  factory StaticUse.constructorInlining(
      ConstructorEntity element, InterfaceType instanceType) {
    return new StaticUse.internal(element, StaticUseKind.INLINING,
        type: instanceType);
  }

  /// Inlining of [element].
  factory StaticUse.methodInlining(
      FunctionEntity element, List<DartType> typeArguments) {
    return new StaticUse.internal(element, StaticUseKind.INLINING,
        typeArguments: typeArguments);
  }

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    return other is StaticUse &&
        element == other.element &&
        kind == other.kind &&
        type == other.type &&
        callStructure == other.callStructure &&
        equalElements(typeArguments, other.typeArguments) &&
        deferredImport == other.deferredImport &&
        constant == other.constant;
  }

  @override
  String toString() =>
      'StaticUse($element,$kind,$type,$typeArguments,$callStructure)';
}

enum TypeUseKind {
  IS_CHECK,
  AS_CAST,
  CATCH_TYPE,
  TYPE_LITERAL,
  INSTANTIATION,
  NATIVE_INSTANTIATION,
  CONST_INSTANTIATION,
  CONSTRUCTOR_REFERENCE,
  IMPLICIT_CAST,
  PARAMETER_CHECK,
  RTI_VALUE,
  TYPE_ARGUMENT,
  NAMED_TYPE_VARIABLE_NEW_RTI,
  TYPE_VARIABLE_BOUND_CHECK,
}

/// Use of a [DartType].
class TypeUse {
  static const String tag = 'type-use';

  final DartType type;
  final TypeUseKind kind;
  @override
  final int hashCode;
  final ImportEntity deferredImport;

  TypeUse.internal(DartType type, TypeUseKind kind, [this.deferredImport])
      : this.type = type,
        this.kind = kind,
        this.hashCode = Hashing.objectsHash(type, kind, deferredImport);

  factory TypeUse.readFromDataSource(DataSource source) {
    source.begin(tag);
    DartType type = source.readDartType();
    TypeUseKind kind = source.readEnum(TypeUseKind.values);
    ImportEntity deferredImport = source.readImportOrNull();
    source.end(tag);
    return new TypeUse.internal(type, kind, deferredImport);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeDartType(type);
    sink.writeEnum(kind);
    sink.writeImportOrNull(deferredImport);
    sink.end(tag);
  }

  /// Short textual representation use for testing.
  String get shortText {
    StringBuffer sb = new StringBuffer();
    switch (kind) {
      case TypeUseKind.IS_CHECK:
        sb.write('is:');
        break;
      case TypeUseKind.AS_CAST:
        sb.write('as:');
        break;
      case TypeUseKind.CATCH_TYPE:
        sb.write('catch:');
        break;
      case TypeUseKind.TYPE_LITERAL:
        sb.write('lit:');
        break;
      case TypeUseKind.INSTANTIATION:
        sb.write('inst:');
        break;
      case TypeUseKind.CONST_INSTANTIATION:
        sb.write('const:');
        break;
      case TypeUseKind.CONSTRUCTOR_REFERENCE:
        sb.write('constructor:');
        break;
      case TypeUseKind.NATIVE_INSTANTIATION:
        sb.write('native:');
        break;
      case TypeUseKind.IMPLICIT_CAST:
        sb.write('impl:');
        break;
      case TypeUseKind.PARAMETER_CHECK:
        sb.write('param:');
        break;
      case TypeUseKind.RTI_VALUE:
        sb.write('rti:');
        break;
      case TypeUseKind.TYPE_ARGUMENT:
        sb.write('typeArg:');
        break;
      case TypeUseKind.NAMED_TYPE_VARIABLE_NEW_RTI:
        sb.write('named:');
        break;
      case TypeUseKind.TYPE_VARIABLE_BOUND_CHECK:
        sb.write('bound:');
        break;
    }
    sb.write(type);
    if (deferredImport != null) {
      sb.write('{');
      sb.write(deferredImport.name);
      sb.write('}');
    }
    return sb.toString();
  }

  /// [type] used in an is check, like `e is T` or `e is! T`.
  factory TypeUse.isCheck(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.IS_CHECK);
  }

  /// [type] used in an as cast, like `e as T`.
  factory TypeUse.asCast(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.AS_CAST);
  }

  /// [type] used as a parameter type or field type in Dart 2, like `T` in:
  ///
  ///    method(T t) {}
  ///    T field;
  ///
  factory TypeUse.parameterCheck(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.PARAMETER_CHECK);
  }

  /// [type] used in an implicit cast in Dart 2, like `T` in
  ///
  ///    dynamic foo = new Object();
  ///    T bar = foo; // Implicitly `T bar = foo as T`.
  ///
  factory TypeUse.implicitCast(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.IMPLICIT_CAST);
  }

  /// [type] used in a on type catch clause, like `try {} on T catch (e) {}`.
  factory TypeUse.catchType(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.CATCH_TYPE);
  }

  /// [type] used as a type literal, like `foo() => T;`.
  factory TypeUse.typeLiteral(DartType type, ImportEntity deferredImport) {
    return new TypeUse.internal(type, TypeUseKind.TYPE_LITERAL, deferredImport);
  }

  /// [type] used in an instantiation, like `new T();`.
  factory TypeUse.instantiation(InterfaceType type) {
    return new TypeUse.internal(type, TypeUseKind.INSTANTIATION);
  }

  /// [type] used in a constant instantiation, like `const T();`.
  factory TypeUse.constInstantiation(
      InterfaceType type, ImportEntity deferredImport) {
    return new TypeUse.internal(
        type, TypeUseKind.CONST_INSTANTIATION, deferredImport);
  }

  /// [type] used in a native instantiation.
  factory TypeUse.nativeInstantiation(InterfaceType type) {
    return new TypeUse.internal(type, TypeUseKind.NATIVE_INSTANTIATION);
  }

  /// [type] used as a direct RTI value.
  factory TypeUse.constTypeLiteral(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.RTI_VALUE);
  }

  /// [type] constructor used, for example in a `instanceof` check.
  factory TypeUse.constructorReference(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.CONSTRUCTOR_REFERENCE);
  }

  /// [type] used directly as a type argument.
  ///
  /// The happens during optimization where a type variable can be replaced by
  /// an invariable type argument derived from a constant receiver.
  factory TypeUse.typeArgument(DartType type) {
    return new TypeUse.internal(type, TypeUseKind.TYPE_ARGUMENT);
  }

  /// [type] used as a named type variable in a recipe.
  factory TypeUse.namedTypeVariableNewRti(TypeVariableType type) =>
      TypeUse.internal(type, TypeUseKind.NAMED_TYPE_VARIABLE_NEW_RTI);

  /// [type] used as a bound on a type variable.
  factory TypeUse.typeVariableBoundCheck(DartType type) =>
      TypeUse.internal(type, TypeUseKind.TYPE_VARIABLE_BOUND_CHECK);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! TypeUse) return false;
    return type == other.type && kind == other.kind;
  }

  @override
  String toString() => 'TypeUse($type,$kind)';
}

/// Use of a [ConstantValue].
class ConstantUse {
  static const String tag = 'constant-use';

  final ConstantValue value;

  ConstantUse._(this.value);

  factory ConstantUse.readFromDataSource(DataSource source) {
    source.begin(tag);
    ConstantValue value = source.readConstant();
    source.end(tag);
    return new ConstantUse._(value);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeConstant(value);
    sink.end(tag);
  }

  /// Short textual representation use for testing.
  String get shortText {
    return value.toDartText(null);
  }

  /// Constant used as the initial value of a field.
  ConstantUse.init(ConstantValue value) : this._(value);

  /// Type constant used for registration of custom elements.
  ConstantUse.customElements(TypeConstantValue value) : this._(value);

  /// Constant literal used in code.
  ConstantUse.literal(ConstantValue value) : this._(value);

  /// Deferred constant used in code.
  ConstantUse.deferred(DeferredGlobalConstantValue value) : this._(value);

  @override
  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! ConstantUse) return false;
    return value == other.value;
  }

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'ConstantUse(${value.toStructuredText(null)})';
}
