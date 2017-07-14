// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.env;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/clone.dart';
import 'package:kernel/type_algebra.dart';

import '../common.dart';
import '../common/resolution.dart';
import '../constants/constructors.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ordered_typeset.dart';
import '../ssa/kernel_impact.dart';
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
        _classMap[cls.name] = new ClassEnv(cls);
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

/// Environment for fast lookup of class members.
class ClassEnv {
  final ir.Class cls;
  final bool isUnnamedMixinApplication;

  Map<String, ir.Member> _constructorMap;
  Map<String, ir.Member> _memberMap;
  Map<String, ir.Member> _setterMap;

  ClassEnv(this.cls)
      // TODO(johnniwinther): Change this to use a property on [cls] when such
      // is added to kernel.
      : isUnnamedMixinApplication =
            cls.name.contains('+') || cls.name.contains('&');

  // TODO(efortuna): This is gross because even though the closure class *has*
  // members, we're not populating this because they aren't ir.Member types. :-(
  ClassEnv.closureClass()
      : cls = null,
        isUnnamedMixinApplication = false,
        _constructorMap = const <String, ir.Member>{},
        _memberMap = const <String, ir.Member>{},
        _setterMap = const <String, ir.Member>{};

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

  void _ensureMaps() {
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
          if (member is ir.Constructor ||
              member is ir.Procedure &&
                  member.kind == ir.ProcedureKind.Factory) {
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

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupMember(String name, {bool setter: false}) {
    _ensureMaps();
    return setter ? _setterMap[name] : _memberMap[name];
  }

  /// Return the [ir.Member] for the member [name] in [library].
  ir.Member lookupConstructor(String name) {
    _ensureMaps();
    return _constructorMap[name];
  }

  void forEachMember(void f(ir.Member member)) {
    _ensureMaps();
    _memberMap.values.forEach(f);
    for (ir.Member member in _setterMap.values) {
      if (member is ir.Procedure) {
        f(member);
      } else {
        // Skip fields; these are also in _memberMap.
      }
    }
  }

  void forEachConstructor(void f(ir.Member member)) {
    _ensureMaps();
    _constructorMap.values.forEach(f);
  }
}

class ClassData {
  final ir.Class cls;
  bool isMixinApplication;

  InterfaceType thisType;
  InterfaceType rawType;
  InterfaceType supertype;
  InterfaceType mixedInType;
  List<InterfaceType> interfaces;
  OrderedTypeSet orderedTypeSet;

  Iterable<ConstantValue> _metadata;

  ClassData(this.cls);

  Iterable<ConstantValue> getMetadata(KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(cls.annotations);
  }

  ClassData copy() {
    return new ClassData(cls);
  }
}

class MemberData {
  final ir.Member node;
  Iterable<ConstantValue> _metadata;

  MemberData(this.node);

  ResolutionImpact getWorldImpact(KernelToElementMapForImpact elementMap) {
    return buildKernelImpact(node, elementMap);
  }

  Iterable<ConstantValue> getMetadata(KernelToElementMapBase elementMap) {
    return _metadata ??= elementMap.getMetadata(node.annotations);
  }

  MemberData copy() {
    return new MemberData(node);
  }
}

class FunctionData extends MemberData {
  final ir.FunctionNode functionNode;
  FunctionType _type;

  FunctionData(ir.Member node, this.functionNode) : super(node);

  FunctionType getFunctionType(KernelToElementMapBase elementMap) {
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
          isOptional: i < functionNode.requiredParameterCount);
    }
    functionNode.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach(handleParameter);
  }

  @override
  FunctionData copy() {
    return new FunctionData(node, functionNode);
  }
}

class ConstructorData extends FunctionData {
  ConstantConstructor _constantConstructor;
  ConstructorBodyEntity constructorBody;

  ConstructorData(ir.Member node, ir.FunctionNode functionNode)
      : super(node, functionNode);

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
            "KernelWorldBuilder._getConstructorConstant");
      }
    }
    return _constantConstructor;
  }

  @override
  ConstructorData copy() {
    return new ConstructorData(node, functionNode);
  }
}

class FieldData extends MemberData {
  ConstantExpression _constant;

  FieldData(ir.Field node) : super(node);

  ir.Field get node => super.node;

  ConstantExpression getFieldConstant(
      KernelToElementMapBase elementMap, FieldEntity field) {
    if (_constant == null) {
      if (node.isConst) {
        _constant = new Constantifier(elementMap).visit(node.initializer);
      } else {
        failedAt(
            field,
            "Unexpected field $field in "
            "KernelWorldBuilder._getConstructorConstant");
      }
    }
    return _constant;
  }

  @override
  FieldData copy() {
    return new FieldData(node);
  }
}
