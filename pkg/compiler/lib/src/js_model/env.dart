// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.js_model.env;

import 'package:front_end/src/fasta/kernel/redirecting_factory_body.dart' as ir;
import 'package:kernel/ast.dart' as ir;

import '../common.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/visitors.dart';
import '../ir/util.dart';
import '../js_model/element_map.dart';
import '../ordered_typeset.dart';
import '../ssa/type_builder.dart';
import 'element_map.dart';
import 'element_map_impl.dart';

/// Environment for fast lookup of component libraries.
class JProgramEnv {
  final Set<ir.Component> _components;
  final Map<Uri, JLibraryEnv> _libraryMap = {};

  JProgramEnv(this._components);

  /// TODO(johnniwinther): Handle arbitrary load order if needed.
  ir.Member get mainMethod => _components.first?.mainMethod;

  ir.Component get mainComponent => _components.first;

  void registerLibrary(JLibraryEnv env) {
    _libraryMap[env.library.importUri] = env;
  }

  /// Return the [JLibraryEnv] for the library with the canonical [uri].
  JLibraryEnv lookupLibrary(Uri uri) {
    return _libraryMap[uri];
  }

  /// Calls [f] for each library in this environment.
  void forEachLibrary(void f(JLibraryEnv library)) {
    _libraryMap.values.forEach(f);
  }

  /// Returns the number of libraries in this environment.
  int get length {
    return _libraryMap.length;
  }
}

/// Environment for fast lookup of library classes and members.
class JLibraryEnv {
  final ir.Library library;
  final Map<String, JClassEnv> _classMap = {};
  final Map<String, ir.Member> _memberMap;
  final Map<String, ir.Member> _setterMap;

  JLibraryEnv(this.library, this._memberMap, this._setterMap);

  void registerClass(String name, JClassEnv classEnv) {
    _classMap[name] = classEnv;
  }

  /// Return the [JClassEnv] for the class [name] in [library].
  JClassEnv lookupClass(String name) {
    return _classMap[name];
  }

  /// Calls [f] for each class in this library.
  void forEachClass(void f(JClassEnv cls)) {
    _classMap.values.forEach(f);
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupMember(String name, {bool setter: false}) {
    return setter ? _setterMap[name] : _memberMap[name];
  }

  void forEachMember(void f(ir.Member member)) {
    _memberMap.values.forEach(f);
    for (ir.Member member in _setterMap.values) {
      if (member is ir.Procedure) {
        f(member);
      } else {
        // Skip fields; these are also in _memberMap.
      }
    }
  }
}

class JLibraryData {
  final ir.Library library;
  // TODO(johnniwinther): Avoid direct access to [imports]. It might be null if
  // it hasn't been computed for the corresponding [KLibraryData].
  final Map<ir.LibraryDependency, ImportEntity> imports;

  JLibraryData(this.library, this.imports);
}

/// Member data for a class.
abstract class JClassEnv {
  /// The [ir.Class] that defined the class, if any.
  ir.Class get cls;

  /// Whether the class is an unnamed mixin application.
  bool get isUnnamedMixinApplication;

  /// Whether the class is a mixin application that mixes in methods with super
  /// calls.
  bool get isSuperMixinApplication;

  /// Return the [MemberEntity] for the member [name] in the class. If [setter]
  /// is `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false});

  /// Calls [f] for each member of the class.
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member));

  /// Return the [ConstructorEntity] for the constructor [name] in the class.
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name);

  /// Calls [f] for each constructor of the class.
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor));

  /// Calls [f] for each constructor body for the live constructors in the
  /// class.
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor));
}

/// Environment for fast lookup of class members.
class JClassEnvImpl implements JClassEnv {
  final ir.Class cls;
  final Map<String, ir.Member> _constructorMap;
  final Map<String, ir.Member> _memberMap;
  final Map<String, ir.Member> _setterMap;
  final List<ir.Member> _members; // in declaration order.
  final bool _isSuperMixinApplication;

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity> _constructorBodyList;

  JClassEnvImpl(this.cls, this._constructorMap, this._memberMap,
      this._setterMap, this._members, this._isSuperMixinApplication);

  bool get isUnnamedMixinApplication => cls.isAnonymousMixin;

  bool get isSuperMixinApplication {
    assert(_isSuperMixinApplication != null);
    return _isSuperMixinApplication;
  }

  /// Return the [MemberEntity] for the member [name] in [cls]. If [setter] is
  /// `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    ir.Member member = setter ? _setterMap[name] : _memberMap[name];
    return member != null ? elementMap.getMember(member) : null;
  }

  /// Calls [f] for each member of [cls].
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _members.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
  }

  /// Return the [ConstructorEntity] for the constructor [name] in [cls].
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name) {
    ir.Member constructor = _constructorMap[name];
    return constructor != null ? elementMap.getConstructor(constructor) : null;
  }

  /// Calls [f] for each constructor of [cls].
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor)) {
    _constructorMap.values.forEach((ir.Member constructor) {
      f(elementMap.getConstructor(constructor));
    });
  }

  void addConstructorBody(ConstructorBodyEntity constructorBody) {
    _constructorBodyList ??= <ConstructorBodyEntity>[];
    _constructorBodyList.add(constructorBody);
  }

  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    _constructorBodyList?.forEach(f);
  }
}

class RecordEnv implements JClassEnv {
  final Map<String, MemberEntity> _memberMap;

  RecordEnv(this._memberMap);

  @override
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    // We do not create constructor bodies for containers.
  }

  @override
  void forEachConstructor(
      IrToElementMap elementMap, void f(ConstructorEntity constructor)) {
    // We do not create constructors for containers.
  }

  @override
  ConstructorEntity lookupConstructor(IrToElementMap elementMap, String name) {
    // We do not create constructors for containers.
    return null;
  }

  @override
  void forEachMember(IrToElementMap elementMap, void f(MemberEntity member)) {
    _memberMap.values.forEach(f);
  }

  @override
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    return _memberMap[name];
  }

  @override
  bool get isUnnamedMixinApplication => false;

  @override
  bool get isSuperMixinApplication => false;

  @override
  ir.Class get cls => null;
}

class ClosureClassEnv extends RecordEnv {
  ClosureClassEnv(Map<String, MemberEntity> memberMap) : super(memberMap);

  @override
  MemberEntity lookupMember(IrToElementMap elementMap, String name,
      {bool setter: false}) {
    if (setter) {
      // All closure fields are final.
      return null;
    }
    return super.lookupMember(elementMap, name, setter: setter);
  }
}

abstract class JClassData {
  ClassDefinition get definition;

  InterfaceType get thisType;
  InterfaceType get rawType;
  InterfaceType get supertype;
  InterfaceType get mixedInType;
  List<InterfaceType> get interfaces;
  OrderedTypeSet get orderedTypeSet;
  DartType get callType;

  bool get isEnumClass;
  bool get isMixinApplication;
}

class JClassDataImpl implements JClassData {
  final ir.Class cls;
  final ClassDefinition definition;
  bool isMixinApplication;
  bool isCallTypeComputed = false;

  InterfaceType thisType;
  InterfaceType rawType;
  InterfaceType supertype;
  InterfaceType mixedInType;
  List<InterfaceType> interfaces;
  OrderedTypeSet orderedTypeSet;

  JClassDataImpl(this.cls, this.definition);

  bool get isEnumClass => cls != null && cls.isEnum;

  DartType get callType => null;
}

abstract class JMemberData {
  MemberDefinition get definition;

  InterfaceType getMemberThisType(JsToElementMap elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;
}

abstract class JMemberDataImpl implements JMemberData {
  final ir.Member node;

  final MemberDefinition definition;

  JMemberDataImpl(this.node, this.definition);

  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    MemberEntity member = elementMap.getMember(node);
    ClassEntity cls = member.enclosingClass;
    if (cls != null) {
      return elementMap.elementEnvironment.getThisType(cls);
    }
    return null;
  }
}

abstract class FunctionData implements JMemberData {
  FunctionType getFunctionType(IrToElementMap elementMap);

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap);

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue));
}

abstract class FunctionDataMixin implements FunctionData {
  ir.FunctionNode get functionNode;
  List<TypeVariableType> _typeVariables;

  List<TypeVariableType> getFunctionTypeVariables(
      covariant JsToElementMapBase elementMap) {
    if (_typeVariables == null) {
      if (functionNode.typeParameters.isEmpty) {
        _typeVariables = const <TypeVariableType>[];
      } else {
        ir.TreeNode parent = functionNode.parent;
        if (parent is ir.Constructor ||
            (parent is ir.Procedure &&
                parent.kind == ir.ProcedureKind.Factory)) {
          _typeVariables = const <TypeVariableType>[];
        } else {
          _typeVariables = functionNode.typeParameters
              .map<TypeVariableType>((ir.TypeParameter typeParameter) {
            return elementMap
                .getDartType(new ir.TypeParameterType(typeParameter));
          }).toList();
        }
      }
    }
    return _typeVariables;
  }
}

class FunctionDataImpl extends JMemberDataImpl
    with FunctionDataMixin
    implements FunctionData {
  final ir.FunctionNode functionNode;
  FunctionType _type;

  FunctionDataImpl(
      ir.Member node, this.functionNode, MemberDefinition definition)
      : super(node, definition);

  FunctionType getFunctionType(covariant JsToElementMapBase elementMap) {
    return _type ??= elementMap.getFunctionType(functionNode);
  }

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    void handleParameter(ir.VariableDeclaration node, {bool isOptional: true}) {
      DartType type = elementMap.getDartType(node.type);
      String name = node.name;
      ConstantValue defaultValue;
      if (isOptional) {
        if (node.initializer != null) {
          defaultValue = elementMap.getConstantValue(node.initializer);
        } else {
          defaultValue = new NullConstantValue();
        }
      }
      f(type, name, defaultValue);
    }

    for (int i = 0; i < functionNode.positionalParameters.length; i++) {
      handleParameter(functionNode.positionalParameters[i],
          isOptional: i >= functionNode.requiredParameterCount);
    }
    functionNode.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach(handleParameter);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.property;
    return ClassTypeVariableAccess.none;
  }
}

class SignatureFunctionData implements FunctionData {
  final FunctionType functionType;
  final MemberDefinition definition;
  final InterfaceType memberThisType;
  final ClassTypeVariableAccess classTypeVariableAccess;
  final List<ir.TypeParameter> typeParameters;

  SignatureFunctionData(this.definition, this.memberThisType, this.functionType,
      this.typeParameters, this.classTypeVariableAccess);

  FunctionType getFunctionType(covariant JsToElementMapBase elementMap) {
    return functionType;
  }

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap) {
    return typeParameters
        .map<TypeVariableType>((ir.TypeParameter typeParameter) {
      return elementMap.getDartType(new ir.TypeParameterType(typeParameter));
    }).toList();
  }

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    throw new UnimplementedError('SignatureData.forEachParameter');
  }

  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    return memberThisType;
  }
}

abstract class DelegatedFunctionData implements FunctionData {
  final FunctionData baseData;

  DelegatedFunctionData(this.baseData);

  FunctionType getFunctionType(covariant JsToElementMapBase elementMap) {
    return baseData.getFunctionType(elementMap);
  }

  List<TypeVariableType> getFunctionTypeVariables(IrToElementMap elementMap) {
    return baseData.getFunctionTypeVariables(elementMap);
  }

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    return baseData.forEachParameter(elementMap, f);
  }

  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    return baseData.getMemberThisType(elementMap);
  }

  ClassTypeVariableAccess get classTypeVariableAccess =>
      baseData.classTypeVariableAccess;
}

class GeneratorBodyFunctionData extends DelegatedFunctionData {
  final MemberDefinition definition;
  GeneratorBodyFunctionData(FunctionData baseData, this.definition)
      : super(baseData);
}

abstract class JConstructorData extends FunctionData {
  ConstantConstructor getConstructorConstant(
      JsToElementMapBase elementMap, ConstructorEntity constructor);
}

class JConstructorDataImpl extends FunctionDataImpl
    implements JConstructorData {
  ConstantConstructor _constantConstructor;
  ConstructorBodyEntity constructorBody;

  JConstructorDataImpl(
      ir.Member node, ir.FunctionNode functionNode, MemberDefinition definition)
      : super(node, functionNode, definition);

  ConstantConstructor getConstructorConstant(
      JsToElementMapBase elementMap, ConstructorEntity constructor) {
    if (_constantConstructor == null) {
      if (node is ir.Constructor && constructor.isConst) {
        _constantConstructor =
            new Constantifier(elementMap).computeConstantConstructor(node);
      } else {
        failedAt(
            constructor,
            "Unexpected constructor $constructor in "
            "ConstructorDataImpl._getConstructorConstant");
      }
    }
    return _constantConstructor;
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

class ConstructorBodyDataImpl extends FunctionDataImpl {
  ConstructorBodyDataImpl(
      ir.Member node, ir.FunctionNode functionNode, MemberDefinition definition)
      : super(node, functionNode, definition);

  // TODO(johnniwinther,sra): Constructor bodies should access type variables
  // through `this`.
  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.parameter;
}

abstract class JFieldData extends JMemberData {
  DartType getFieldType(IrToElementMap elementMap);

  ConstantExpression getFieldConstantExpression(JsToElementMapBase elementMap);

  /// Return the [ConstantValue] the initial value of [field] or `null` if
  /// the initializer is not a constant expression.
  ConstantValue getFieldConstantValue(JsToElementMapBase elementMap);

  bool hasConstantFieldInitializer(JsToElementMapBase elementMap);

  ConstantValue getConstantFieldInitializer(JsToElementMapBase elementMap);
}

class JFieldDataImpl extends JMemberDataImpl implements JFieldData {
  DartType _type;
  bool _isConstantComputed = false;
  ConstantValue _constantValue;
  ConstantExpression _constantExpression;

  JFieldDataImpl(ir.Field node, MemberDefinition definition)
      : super(node, definition);

  ir.Field get node => super.node;

  DartType getFieldType(covariant JsToElementMapBase elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ConstantExpression getFieldConstantExpression(JsToElementMapBase elementMap) {
    if (_constantExpression == null) {
      if (node.isConst) {
        _constantExpression =
            new Constantifier(elementMap).visit(node.initializer);
      } else {
        failedAt(
            definition.member,
            "Unexpected field ${definition.member} in "
            "FieldDataImpl.getFieldConstant");
      }
    }
    return _constantExpression;
  }

  @override
  ConstantValue getFieldConstantValue(JsToElementMapBase elementMap) {
    if (!_isConstantComputed) {
      _constantValue = elementMap.getConstantValue(node.initializer,
          requireConstant: node.isConst, implicitNull: !node.isConst);
      _isConstantComputed = true;
    }
    return _constantValue;
  }

  @override
  bool hasConstantFieldInitializer(JsToElementMapBase elementMap) {
    return getFieldConstantValue(elementMap) != null;
  }

  @override
  ConstantValue getConstantFieldInitializer(JsToElementMapBase elementMap) {
    ConstantValue value = getFieldConstantValue(elementMap);
    assert(
        value != null,
        failedAt(
            definition.member,
            "Field ${definition.member} doesn't have a "
            "constant initial value."));
    return value;
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.instanceField;
    return ClassTypeVariableAccess.none;
  }
}

class JTypedefData {
  final TypedefEntity element;
  final TypedefType rawType;

  JTypedefData(this.element, this.rawType);
}

class JTypeVariableData {
  final ir.TypeParameter node;
  DartType _bound;
  DartType _defaultType;

  JTypeVariableData(this.node);

  DartType getBound(IrToElementMap elementMap) {
    return _bound ??= elementMap.getDartType(node.bound);
  }

  DartType getDefaultType(IrToElementMap elementMap) {
    return _defaultType ??= elementMap.getDartType(node.defaultType);
  }
}
