// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.env;

import 'package:front_end/src/fasta/kernel/redirecting_factory_body.dart' as ir;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/clone.dart';
import 'package:kernel/type_algebra.dart';

import '../common.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ordered_typeset.dart';
import '../ssa/type_builder.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'element_map_mixins.dart';

/// Environment for fast lookup of program libraries.
class ProgramEnv {
  final Set<ir.Program> _programs = new Set<ir.Program>();

  Map<Uri, LibraryEnv> _libraryMap;

  /// TODO(johnniwinther): Handle arbitrary load order if needed.
  ir.Member get mainMethod => _programs.first?.mainMethod;

  void addProgram(ir.Program program) {
    if (_programs.add(program)) {
      if (_libraryMap != null) {
        _addLibraries(program);
      }
    }
  }

  void _addLibraries(ir.Program program) {
    for (ir.Library library in program.libraries) {
      _libraryMap[library.importUri] = new LibraryEnv(library);
    }
  }

  void _ensureLibraryMap() {
    if (_libraryMap == null) {
      _libraryMap = <Uri, LibraryEnv>{};
      for (ir.Program program in _programs) {
        _addLibraries(program);
      }
    }
  }

  /// Return the [LibraryEnv] for the library with the canonical [uri].
  LibraryEnv lookupLibrary(Uri uri) {
    _ensureLibraryMap();
    return _libraryMap[uri];
  }

  /// Calls [f] for each library in this environment.
  void forEachLibrary(void f(LibraryEnv library)) {
    _ensureLibraryMap();
    _libraryMap.values.forEach(f);
  }

  /// Returns the number of libraries in this environment.
  int get length {
    _ensureLibraryMap();
    return _libraryMap.length;
  }
}

/// Environment for fast lookup of library classes and members.
class LibraryEnv {
  final ir.Library library;

  Map<String, ClassEnv> _classMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;

  LibraryEnv(this.library);

  void _ensureClassMap() {
    if (_classMap == null) {
      _classMap = <String, ClassEnv>{};
      for (ir.Class cls in library.classes) {
        _classMap[cls.name] = new ClassEnvImpl(cls);
      }
    }
  }

  /// Return the [ClassEnv] for the class [name] in [library].
  ClassEnv lookupClass(String name) {
    _ensureClassMap();
    return _classMap[name];
  }

  /// Calls [f] for each class in this library.
  void forEachClass(void f(ClassEnv cls)) {
    _ensureClassMap();
    _classMap.values.forEach(f);
  }

  void _ensureMemberMaps() {
    if (_memberMap == null) {
      _memberMap = <String, ir.Member>{};
      _setterMap = <String, ir.Member>{};
      for (ir.Member member in library.members) {
        if (member.name.name.contains('#')) {
          // Skip synthetic .dill members.
          continue;
        }
        if (member is ir.Procedure) {
          if (member.kind == ir.ProcedureKind.Setter) {
            _setterMap[member.name.name] = member;
          } else {
            _memberMap[member.name.name] = member;
          }
        } else if (member is ir.Field) {
          _memberMap[member.name.name] = member;
          if (member.isMutable) {
            _setterMap[member.name.name] = member;
          }
        } else {
          failedAt(
              NO_LOCATION_SPANNABLE, "Unexpected library member node: $member");
        }
      }
    }
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupMember(String name, {bool setter: false}) {
    _ensureMemberMaps();
    return setter ? _setterMap[name] : _memberMap[name];
  }

  void forEachMember(void f(ir.Member member)) {
    _ensureMemberMaps();
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

class LibraryData {
  final ir.Library library;
  Iterable<ConstantValue> _metadata;

  LibraryData(this.library);

  Iterable<ConstantValue> getMetadata(KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(library.annotations);
  }

  LibraryData copy() {
    return new LibraryData(library);
  }
}

/// Member data for a class.
abstract class ClassEnv {
  /// The [ir.Class] that defined the class, if any.
  ir.Class get cls;

  /// Whether the class is an unnamed mixin application.
  bool get isUnnamedMixinApplication;

  /// Return the [MemberEntity] for the member [name] in the class. If [setter]
  /// is `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false});

  /// Calls [f] for each member of the class.
  void forEachMember(
      KernelToElementMap elementMap, void f(MemberEntity member));

  /// Return the [ConstructorEntity] for the constructor [name] in the class.
  ConstructorEntity lookupConstructor(
      KernelToElementMap elementMap, String name);

  /// Calls [f] for each constructor of the class.
  void forEachConstructor(
      KernelToElementMap elementMap, void f(ConstructorEntity constructor));

  /// Calls [f] for each constructor body for the live constructors in the
  /// class.
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor));
}

/// Environment for fast lookup of class members.
class ClassEnvImpl implements ClassEnv {
  final ir.Class cls;
  final bool isUnnamedMixinApplication;

  Map<String, ir.Member> _constructorMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;

  /// Constructor bodies created for this class.
  List<ConstructorBodyEntity> _constructorBodyList;

  ClassEnvImpl(this.cls)
      // TODO(johnniwinther): Change this to use a property on [cls] when such
      // is added to kernel.
      : isUnnamedMixinApplication =
            cls.name.contains('+') || cls.name.contains('&');

  /// Copied from 'package:kernel/transformations/mixin_full_resolution.dart'.
  ir.Constructor _buildForwardingConstructor(
      CloneVisitor cloner, ir.Constructor superclassConstructor) {
    var superFunction = superclassConstructor.function;

    // We keep types and default values for the parameters but always mark the
    // parameters as final (since we just forward them to the super
    // constructor).
    ir.VariableDeclaration cloneVariable(ir.VariableDeclaration variable) {
      ir.VariableDeclaration clone = cloner.clone(variable);
      clone.isFinal = true;
      return clone;
    }

    // Build a [FunctionNode] which has the same parameters as the one in the
    // superclass constructor.
    var positionalParameters =
        superFunction.positionalParameters.map(cloneVariable).toList();
    var namedParameters =
        superFunction.namedParameters.map(cloneVariable).toList();
    var function = new ir.FunctionNode(new ir.EmptyStatement(),
        positionalParameters: positionalParameters,
        namedParameters: namedParameters,
        requiredParameterCount: superFunction.requiredParameterCount,
        returnType: const ir.VoidType());

    // Build a [SuperInitializer] which takes all positional/named parameters
    // and forward them to the super class constructor.
    var positionalArguments = <ir.Expression>[];
    for (var variable in positionalParameters) {
      positionalArguments.add(new ir.VariableGet(variable));
    }
    var namedArguments = <ir.NamedExpression>[];
    for (var variable in namedParameters) {
      namedArguments.add(
          new ir.NamedExpression(variable.name, new ir.VariableGet(variable)));
    }
    var superInitializer = new ir.SuperInitializer(superclassConstructor,
        new ir.Arguments(positionalArguments, named: namedArguments));

    // Assemble the constructor.
    return new ir.Constructor(function,
        name: superclassConstructor.name,
        initializers: <ir.Initializer>[superInitializer]);
  }

  void _ensureMaps(KernelToElementMapBase elementMap) {
    if (_memberMap == null) {
      _memberMap = <String, ir.Member>{};
      _setterMap = <String, ir.Member>{};
      _constructorMap = <String, ir.Member>{};

      void addMembers(ir.Class c, {bool includeStatic}) {
        for (ir.Member member in c.members) {
          if (member.name.name.contains('#')) {
            // Skip synthetic .dill members.
            continue;
          }
          if (member is ir.Constructor) {
            if (!includeStatic) continue;
            _constructorMap[member.name.name] = member;
          } else if (member is ir.Procedure &&
              member.kind == ir.ProcedureKind.Factory) {
            if (member.function.body is ir.RedirectingFactoryBody) {
              // Don't include redirecting factories.
              continue;
            }
            if (!includeStatic) continue;
            _constructorMap[member.name.name] = member;
          } else if (member is ir.Procedure) {
            if (!includeStatic && member.isStatic) continue;
            if (member.kind == ir.ProcedureKind.Setter) {
              _setterMap[member.name.name] = member;
            } else {
              _memberMap[member.name.name] = member;
            }
          } else if (member is ir.Field) {
            if (!includeStatic && member.isStatic) continue;
            _memberMap[member.name.name] = member;
            if (member.isMutable) {
              _setterMap[member.name.name] = member;
            }
            _memberMap[member.name.name] = member;
          } else {
            failedAt(
                NO_LOCATION_SPANNABLE, "Unexpected class member node: $member");
          }
        }
      }

      if (cls.mixedInClass != null) {
        addMembers(cls.mixedInClass, includeStatic: false);
      }
      addMembers(cls, includeStatic: true);

      if (isUnnamedMixinApplication && _constructorMap.isEmpty) {
        // Ensure that constructors are created for the superclass in case it
        // is also an unnamed mixin application.
        ClassEntity superclass = elementMap.getClass(cls.superclass);
        elementMap.elementEnvironment.lookupConstructor(superclass, '');

        // Unnamed mixin applications have no constructors when read from .dill.
        // For each generative constructor in the superclass we make a
        // corresponding forwarding constructor in the subclass.
        //
        // This code is copied from
        // 'package:kernel/transformations/mixin_full_resolution.dart'
        var superclassSubstitution = getSubstitutionMap(cls.supertype);
        var superclassCloner =
            new CloneVisitor(typeSubstitution: superclassSubstitution);

        for (var superclassConstructor in cls.superclass.constructors) {
          var forwardingConstructor = _buildForwardingConstructor(
              superclassCloner, superclassConstructor);
          cls.addMember(forwardingConstructor);
          _constructorMap[forwardingConstructor.name.name] =
              forwardingConstructor;
        }
      }
    }
  }

  /// Return the [MemberEntity] for the member [name] in [cls]. If [setter] is
  /// `true`, the setter or assignable field corresponding to [name] is
  /// returned.
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false}) {
    _ensureMaps(elementMap);
    ir.Member member = setter ? _setterMap[name] : _memberMap[name];
    return member != null ? elementMap.getMember(member) : null;
  }

  /// Calls [f] for each member of [cls].
  void forEachMember(
      KernelToElementMap elementMap, void f(MemberEntity member)) {
    _ensureMaps(elementMap);
    _memberMap.values.forEach((ir.Member member) {
      f(elementMap.getMember(member));
    });
    for (ir.Member member in _setterMap.values) {
      if (member is ir.Procedure) {
        f(elementMap.getMember(member));
      } else {
        // Skip fields; these are also in _memberMap.
      }
    }
  }

  /// Return the [ConstructorEntity] for the constructor [name] in [cls].
  ConstructorEntity lookupConstructor(
      KernelToElementMap elementMap, String name) {
    _ensureMaps(elementMap);
    ir.Member constructor = _constructorMap[name];
    return constructor != null ? elementMap.getConstructor(constructor) : null;
  }

  /// Calls [f] for each constructor of [cls].
  void forEachConstructor(
      KernelToElementMap elementMap, void f(ConstructorEntity constructor)) {
    _ensureMaps(elementMap);
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

class ClosureClassEnv extends RecordEnv {
  ClosureClassEnv(Map<String, MemberEntity> memberMap) : super(memberMap);

  @override
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false}) {
    if (setter) {
      // All closure fields are final.
      return null;
    }
    return super.lookupMember(elementMap, name, setter: setter);
  }
}

class RecordEnv implements ClassEnv {
  final Map<String, MemberEntity> _memberMap;

  RecordEnv(this._memberMap);

  @override
  void forEachConstructorBody(void f(ConstructorBodyEntity constructor)) {
    // We do not create constructor bodies for containers.
  }

  @override
  void forEachConstructor(
      KernelToElementMap elementMap, void f(ConstructorEntity constructor)) {
    // We do not create constructors for containers.
  }

  @override
  ConstructorEntity lookupConstructor(
      KernelToElementMap elementMap, String name) {
    // We do not create constructors for containers.
    return null;
  }

  @override
  void forEachMember(
      KernelToElementMap elementMap, void f(MemberEntity member)) {
    _memberMap.values.forEach(f);
  }

  @override
  MemberEntity lookupMember(KernelToElementMap elementMap, String name,
      {bool setter: false}) {
    return _memberMap[name];
  }

  @override
  bool get isUnnamedMixinApplication => false;

  @override
  ir.Class get cls => null;
}

class ClassData {
  /// TODO(johnniwinther): Remove this from the [ClassData] interface. Use
  /// `definition.node` instead.
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
  DartType callType;

  Iterable<ConstantValue> _metadata;

  ClassData(this.cls, this.definition);

  Iterable<ConstantValue> getMetadata(KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(cls.annotations);
  }

  ClassData copy() {
    return new ClassData(cls, definition);
  }
}

abstract class MemberData {
  MemberDefinition get definition;

  Iterable<ConstantValue> getMetadata(KernelToElementMap elementMap);

  InterfaceType getMemberThisType(KernelToElementMapForBuilding elementMap);

  ClassTypeVariableAccess get classTypeVariableAccess;
}

abstract class MemberDataImpl implements MemberData {
  /// TODO(johnniwinther): Remove this from the [MemberData] interface. Use
  /// `definition.node` instead.
  final ir.Member node;

  final MemberDefinition definition;

  Iterable<ConstantValue> _metadata;

  MemberDataImpl(this.node, this.definition);

  Iterable<ConstantValue> getMetadata(
      covariant KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(node.annotations);
  }

  InterfaceType getMemberThisType(KernelToElementMapForBuilding elementMap) {
    MemberEntity member = elementMap.getMember(node);
    ClassEntity cls = member.enclosingClass;
    if (cls != null) {
      return elementMap.elementEnvironment.getThisType(cls);
    }
    return null;
  }

  MemberData copy();
}

abstract class FunctionData implements MemberData {
  FunctionType getFunctionType(KernelToElementMap elementMap);

  void forEachParameter(KernelToElementMapForBuilding elementMap,
      void f(DartType type, String name, ConstantValue defaultValue));
}

class FunctionDataImpl extends MemberDataImpl implements FunctionData {
  final ir.FunctionNode functionNode;
  FunctionType _type;

  FunctionDataImpl(
      ir.Member node, this.functionNode, MemberDefinition definition)
      : super(node, definition);

  FunctionType getFunctionType(covariant KernelToElementMapBase elementMap) {
    return _type ??= elementMap.getFunctionType(functionNode);
  }

  void forEachParameter(KernelToElementMapForBuilding elementMap,
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
  FunctionData copy() {
    return new FunctionDataImpl(node, functionNode, definition);
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess {
    if (node.isInstanceMember) return ClassTypeVariableAccess.property;
    return ClassTypeVariableAccess.none;
  }
}

abstract class ConstructorData extends FunctionData {
  ConstantConstructor getConstructorConstant(
      KernelToElementMapBase elementMap, ConstructorEntity constructor);
}

class ConstructorDataImpl extends FunctionDataImpl implements ConstructorData {
  ConstantConstructor _constantConstructor;
  ConstructorBodyEntity constructorBody;

  ConstructorDataImpl(
      ir.Member node, ir.FunctionNode functionNode, MemberDefinition definition)
      : super(node, functionNode, definition);

  ConstantConstructor getConstructorConstant(
      KernelToElementMapBase elementMap, ConstructorEntity constructor) {
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
  ConstructorData copy() {
    return new ConstructorDataImpl(node, functionNode, definition);
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

abstract class FieldData extends MemberData {
  DartType getFieldType(KernelToElementMap elementMap);

  ConstantExpression getFieldConstantExpression(
      KernelToElementMapBase elementMap);

  /// Return the [ConstantValue] the initial value of [field] or `null` if
  /// the initializer is not a constant expression.
  ConstantValue getFieldConstantValue(KernelToElementMapBase elementMap);

  bool hasConstantFieldInitializer(KernelToElementMapBase elementMap);

  ConstantValue getConstantFieldInitializer(KernelToElementMapBase elementMap);
}

class FieldDataImpl extends MemberDataImpl implements FieldData {
  DartType _type;
  bool _isConstantComputed = false;
  ConstantValue _constantValue;
  ConstantExpression _constantExpression;

  FieldDataImpl(ir.Field node, MemberDefinition definition)
      : super(node, definition);

  ir.Field get node => super.node;

  DartType getFieldType(covariant KernelToElementMapBase elementMap) {
    return _type ??= elementMap.getDartType(node.type);
  }

  ConstantExpression getFieldConstantExpression(
      KernelToElementMapBase elementMap) {
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
  ConstantValue getFieldConstantValue(KernelToElementMapBase elementMap) {
    if (!_isConstantComputed) {
      _constantValue = elementMap.getConstantValue(node.initializer,
          requireConstant: node.isConst, implicitNull: !node.isConst);
      _isConstantComputed = true;
    }
    return _constantValue;
  }

  @override
  bool hasConstantFieldInitializer(KernelToElementMapBase elementMap) {
    return getFieldConstantValue(elementMap) != null;
  }

  @override
  ConstantValue getConstantFieldInitializer(KernelToElementMapBase elementMap) {
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

  @override
  FieldData copy() {
    return new FieldDataImpl(node, definition);
  }
}

class TypedefData {
  final ir.Typedef node;
  final TypedefEntity element;
  final TypedefType rawType;

  TypedefData(this.node, this.element, this.rawType);
}
