// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.element_map;

import 'package:front_end/src/fasta/util/link.dart' show Link, LinkBuilder;
import 'package:js_runtime/shared/embedded_names.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../closure.dart' show BoxLocal, ThisLocal;
import '../common.dart';
import '../common/names.dart';
import '../common/resolution.dart';
import '../common_elements.dart';
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/constructors.dart';
import '../constants/evaluation.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/names.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../frontend_strategy.dart';
import '../js/js.dart' as js;
import '../js_backend/allocator_analysis.dart' show KAllocatorAnalysis;
import '../js_backend/backend.dart' show JavaScriptBackend;
import '../js_backend/backend_usage.dart';
import '../js_backend/constant_system_javascript.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/namer.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../js_emitter/code_emitter_task.dart';
import '../js_model/closure.dart';
import '../js_model/elements.dart';
import '../js_model/locals.dart';
import '../native/native.dart' as native;
import '../native/resolver.dart';
import '../options.dart';
import '../ordered_typeset.dart';
import '../ssa/kernel_impact.dart';
import '../ssa/type_builder.dart';
import '../universe/call_structure.dart';
import '../universe/class_hierarchy.dart';
import '../universe/class_set.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../world.dart';

import 'kernel_debug.dart';
import 'element_map.dart';
import 'visitors.dart';
import 'env.dart';
import 'indexed.dart';
import 'kelements.dart';
import 'types.dart';

part 'native_basic_data.dart';
part 'no_such_method_resolver.dart';

/// Interface for kernel queries needed to implement the [CodegenWorldBuilder].
abstract class KernelToWorldBuilder implements KernelToElementMapForBuilding {
  /// Returns `true` if [field] has a constant initializer.
  bool hasConstantFieldInitializer(FieldEntity field);

  /// Returns the constant initializer for [field].
  ConstantValue getConstantFieldInitializer(FieldEntity field);

  /// Calls [f] for each parameter of [function] providing the type and name of
  /// the parameter and the [defaultValue] if the parameter is optional.
  void forEachParameter(FunctionEntity function,
      void f(DartType type, String name, ConstantValue defaultValue));
}

abstract class KernelToElementMapImpl {
  CommonElements get commonElements;
  DiagnosticReporter get reporter;
  InterfaceType getThisType(IndexedClass cls);
  InterfaceType getSuperType(IndexedClass cls);
  OrderedTypeSet getOrderedTypeSet(IndexedClass cls);
  Iterable<InterfaceType> getInterfaces(IndexedClass cls);
  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls);
  DartType substByContext(DartType type, InterfaceType context);
  DartType getCallType(InterfaceType type);
  int getHierarchyDepth(IndexedClass cls);
  DartType getTypeVariableBound(IndexedTypeVariable typeVariable);
}

abstract class KernelToElementMapBase
    implements KernelToElementMap, KernelToElementMapImpl {
  final CompilerOptions options;
  final DiagnosticReporter reporter;
  CommonElements _commonElements;
  ElementEnvironment _elementEnvironment;
  DartTypeConverter _typeConverter;
  KernelConstantEnvironment _constantEnvironment;
  KernelDartTypes _types;
  ir.TypeEnvironment _typeEnvironment;
  bool _isStaticTypePrepared = false;

  /// Library environment. Used for fast lookup.
  ProgramEnv _env = new ProgramEnv();

  final EntityDataEnvMap<IndexedLibrary, LibraryData, LibraryEnv> _libraries =
      new EntityDataEnvMap<IndexedLibrary, LibraryData, LibraryEnv>();
  final EntityDataEnvMap<IndexedClass, ClassData, ClassEnv> _classes =
      new EntityDataEnvMap<IndexedClass, ClassData, ClassEnv>();
  final EntityDataMap<IndexedMember, MemberData> _members =
      new EntityDataMap<IndexedMember, MemberData>();
  final EntityDataMap<IndexedTypeVariable, TypeVariableData> _typeVariables =
      new EntityDataMap<IndexedTypeVariable, TypeVariableData>();
  final EntityDataMap<IndexedTypedef, TypedefData> _typedefs =
      new EntityDataMap<IndexedTypedef, TypedefData>();

  KernelToElementMapBase(this.options, this.reporter, Environment environment) {
    _elementEnvironment = new KernelElementEnvironment(this);
    _commonElements = new CommonElements(_elementEnvironment);
    _constantEnvironment = new KernelConstantEnvironment(this, environment);
    _typeConverter = new DartTypeConverter(this);
    _types = new KernelDartTypes(this);
  }

  bool checkFamily(Entity entity);

  DartTypes get types => _types;

  ElementEnvironment get elementEnvironment => _elementEnvironment;

  @override
  CommonElements get commonElements => _commonElements;

  /// NativeBasicData is need for computation of the default super class.
  NativeBasicData get nativeBasicData;

  FunctionEntity get _mainFunction {
    return _env.mainMethod != null ? _getMethod(_env.mainMethod) : null;
  }

  LibraryEntity get _mainLibrary {
    return _env.mainMethod != null
        ? _getLibrary(_env.mainMethod.enclosingLibrary)
        : null;
  }

  Iterable<LibraryEntity> get _libraryList;

  SourceSpan getSourceSpan(Spannable spannable, Entity currentElement) {
    SourceSpan fromSpannable(Spannable spannable) {
      if (spannable is IndexedLibrary &&
          spannable.libraryIndex < _libraries.length) {
        LibraryEnv env = _libraries.getEnv(spannable);
        return computeSourceSpanFromTreeNode(env.library);
      } else if (spannable is IndexedClass &&
          spannable.classIndex < _classes.length) {
        ClassData data = _classes.getData(spannable);
        return data.definition.location;
      } else if (spannable is IndexedMember &&
          spannable.memberIndex < _members.length) {
        MemberData data = _members.getData(spannable);
        return data.definition.location;
      } else if (spannable is KLocalFunction) {
        return getSourceSpan(spannable.memberContext, currentElement);
      } else if (spannable is JLocal) {
        return getSourceSpan(spannable.memberContext, currentElement);
      }
      return null;
    }

    SourceSpan sourceSpan = fromSpannable(spannable);
    sourceSpan ??= fromSpannable(currentElement);
    return sourceSpan;
  }

  LibraryEntity lookupLibrary(Uri uri) {
    LibraryEnv libraryEnv = _env.lookupLibrary(uri);
    if (libraryEnv == null) return null;
    return _getLibrary(libraryEnv.library, libraryEnv);
  }

  String _getLibraryName(IndexedLibrary library) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraries.getEnv(library);
    return libraryEnv.library.name ?? '';
  }

  MemberEntity lookupLibraryMember(IndexedLibrary library, String name,
      {bool setter: false}) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraries.getEnv(library);
    ir.Member member = libraryEnv.lookupMember(name, setter: setter);
    return member != null ? getMember(member) : null;
  }

  void _forEachLibraryMember(
      IndexedLibrary library, void f(MemberEntity member)) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraries.getEnv(library);
    libraryEnv.forEachMember((ir.Member node) {
      f(getMember(node));
    });
  }

  ClassEntity lookupClass(IndexedLibrary library, String name) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraries.getEnv(library);
    ClassEnv classEnv = libraryEnv.lookupClass(name);
    if (classEnv != null) {
      return _getClass(classEnv.cls, classEnv);
    }
    return null;
  }

  void _forEachClass(IndexedLibrary library, void f(ClassEntity cls)) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraries.getEnv(library);
    libraryEnv.forEachClass((ClassEnv classEnv) {
      if (!classEnv.isUnnamedMixinApplication) {
        f(_getClass(classEnv.cls, classEnv));
      }
    });
  }

  void ensureClassMembers(ir.Class node) {
    _classes.getEnv(_getClass(node)).ensureMembers(this);
  }

  MemberEntity lookupClassMember(IndexedClass cls, String name,
      {bool setter: false}) {
    assert(checkFamily(cls));
    ClassEnv classEnv = _classes.getEnv(cls);
    return classEnv.lookupMember(this, name, setter: setter);
  }

  ConstructorEntity lookupConstructor(IndexedClass cls, String name) {
    assert(checkFamily(cls));
    ClassEnv classEnv = _classes.getEnv(cls);
    return classEnv.lookupConstructor(this, name);
  }

  @override
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments) {
    return new InterfaceType(getClass(cls), getDartTypes(typeArguments));
  }

  LibraryEntity getLibrary(ir.Library node) => _getLibrary(node);

  LibraryEntity _getLibrary(ir.Library node, [LibraryEnv libraryEnv]);

  @override
  ClassEntity getClass(ir.Class node) => _getClass(node);

  ClassEntity _getClass(ir.Class node, [ClassEnv classEnv]);

  InterfaceType getSuperType(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.supertype;
  }

  void _ensureThisAndRawType(ClassEntity cls, ClassData data) {
    assert(checkFamily(cls));
    if (data is ClassDataImpl && data.thisType == null) {
      ir.Class node = data.cls;
      if (node.typeParameters.isEmpty) {
        data.thisType =
            data.rawType = new InterfaceType(cls, const <DartType>[]);
      } else {
        data.thisType = new InterfaceType(
            cls,
            new List<DartType>.generate(node.typeParameters.length,
                (int index) {
              return new TypeVariableType(
                  _getTypeVariable(node.typeParameters[index]));
            }));
        data.rawType = new InterfaceType(
            cls,
            new List<DartType>.filled(
                node.typeParameters.length, const DynamicType()));
      }
    }
  }

  TypeVariableEntity getTypeVariable(ir.TypeParameter node) =>
      _getTypeVariable(node);

  TypeVariableEntity _getTypeVariable(ir.TypeParameter node);

  void _ensureSupertypes(ClassEntity cls, ClassData data) {
    assert(checkFamily(cls));
    if (data is ClassDataImpl && data.orderedTypeSet == null) {
      _ensureThisAndRawType(cls, data);

      ir.Class node = data.cls;

      if (node.supertype == null) {
        data.orderedTypeSet = new OrderedTypeSet.singleton(data.thisType);
        data.isMixinApplication = false;
        data.interfaces = const <InterfaceType>[];
      } else {
        InterfaceType processSupertype(ir.Supertype node) {
          InterfaceType supertype = _typeConverter.visitSupertype(node);
          IndexedClass superclass = supertype.element;
          ClassData superdata = _classes.getData(superclass);
          _ensureSupertypes(superclass, superdata);
          return supertype;
        }

        InterfaceType supertype = processSupertype(node.supertype);
        if (supertype == _commonElements.objectType) {
          ClassEntity defaultSuperclass =
              _commonElements.getDefaultSuperclass(cls, nativeBasicData);
          data.supertype = _elementEnvironment.getRawType(defaultSuperclass);
        } else {
          data.supertype = supertype;
        }
        LinkBuilder<InterfaceType> linkBuilder =
            new LinkBuilder<InterfaceType>();
        if (node.mixedInType != null) {
          data.isMixinApplication = true;
          linkBuilder
              .addLast(data.mixedInType = processSupertype(node.mixedInType));
        } else {
          data.isMixinApplication = false;
        }
        node.implementedTypes.forEach((ir.Supertype supertype) {
          linkBuilder.addLast(processSupertype(supertype));
        });
        Link<InterfaceType> interfaces =
            linkBuilder.toLink(const Link<InterfaceType>());
        OrderedTypeSetBuilder setBuilder =
            new KernelOrderedTypeSetBuilder(this, cls);
        data.orderedTypeSet = setBuilder.createOrderedTypeSet(
            data.supertype, interfaces.reverse(const Link<InterfaceType>()));
        data.interfaces = new List<InterfaceType>.from(interfaces.toList());
      }
    }
  }

  @override
  TypedefType getTypedefType(ir.Typedef node) {
    IndexedTypedef typedef = _getTypedef(node);
    return _typedefs.getData(typedef).rawType;
  }

  TypedefEntity _getTypedef(ir.Typedef node);

  @override
  MemberEntity getMember(ir.Member node) {
    if (node is ir.Field) {
      return _getField(node);
    } else if (node is ir.Constructor) {
      return _getConstructor(node);
    } else if (node is ir.Procedure) {
      if (node.kind == ir.ProcedureKind.Factory) {
        return _getConstructor(node);
      } else {
        return _getMethod(node);
      }
    }
    throw new UnsupportedError("Unexpected member: $node");
  }

  MemberEntity getSuperMember(
      MemberEntity context, ir.Name name, ir.Member target,
      {bool setter: false}) {
    if (target != null && !target.isAbstract && target.isInstanceMember) {
      return getMember(target);
    }
    ClassEntity cls = context.enclosingClass;
    assert(
        cls != null,
        failedAt(context,
            "No enclosing class for super member access in $context."));
    IndexedClass superclass = getSuperType(cls)?.element;
    while (superclass != null) {
      ClassEnv env = _classes.getEnv(superclass);
      MemberEntity superMember =
          env.lookupMember(this, name.name, setter: setter);
      if (superMember != null) {
        if (!superMember.isInstanceMember) return null;
        if (!superMember.isAbstract) {
          return superMember;
        }
      }
      superclass = getSuperType(superclass)?.element;
    }
    return null;
  }

  @override
  ConstructorEntity getConstructor(ir.Member node) => _getConstructor(node);

  ConstructorEntity _getConstructor(ir.Member node);

  ConstructorEntity getSuperConstructor(
      ir.Constructor sourceNode, ir.Member targetNode) {
    ConstructorEntity source = getConstructor(sourceNode);
    ClassEntity sourceClass = source.enclosingClass;
    ConstructorEntity target = getConstructor(targetNode);
    ClassEntity targetClass = target.enclosingClass;
    IndexedClass superClass = getSuperType(sourceClass)?.element;
    if (superClass == targetClass) {
      return target;
    }
    ClassEnv env = _classes.getEnv(superClass);
    ConstructorEntity constructor = env.lookupConstructor(this, target.name);
    if (constructor != null) {
      return constructor;
    }
    throw failedAt(source, "Super constructor for $source not found.");
  }

  @override
  FunctionEntity getMethod(ir.Procedure node) => _getMethod(node);

  FunctionEntity _getMethod(ir.Procedure node);

  @override
  FieldEntity getField(ir.Field node) => _getField(node);

  FieldEntity _getField(ir.Field node);

  @override
  DartType getDartType(ir.DartType type) => _typeConverter.convert(type);

  @override
  TypeVariableType getTypeVariableType(ir.TypeParameterType type) =>
      getDartType(type);

  List<DartType> getDartTypes(List<ir.DartType> types) {
    List<DartType> list = <DartType>[];
    types.forEach((ir.DartType type) {
      list.add(getDartType(type));
    });
    return list;
  }

  @override
  InterfaceType getInterfaceType(ir.InterfaceType type) =>
      _typeConverter.convert(type);

  @override
  FunctionType getFunctionType(ir.FunctionNode node) {
    DartType returnType;
    if (node.parent is ir.Constructor) {
      // The return type on generative constructors is `void`, but we need
      // `dynamic` type to match the element model.
      returnType = const DynamicType();
    } else {
      returnType = getDartType(node.returnType);
    }
    List<DartType> parameterTypes = <DartType>[];
    List<DartType> optionalParameterTypes = <DartType>[];

    DartType getParameterType(ir.VariableDeclaration variable) {
      if (variable.isCovariant || variable.isGenericCovariantImpl) {
        // A covariant parameter has type `Object` in the method signature.
        return commonElements.objectType;
      }
      return getDartType(variable.type);
    }

    for (ir.VariableDeclaration variable in node.positionalParameters) {
      if (parameterTypes.length == node.requiredParameterCount) {
        optionalParameterTypes.add(getParameterType(variable));
      } else {
        parameterTypes.add(getParameterType(variable));
      }
    }
    List<String> namedParameters = <String>[];
    List<DartType> namedParameterTypes = <DartType>[];
    List<ir.VariableDeclaration> sortedNamedParameters =
        node.namedParameters.toList()..sort((a, b) => a.name.compareTo(b.name));
    for (ir.VariableDeclaration variable in sortedNamedParameters) {
      namedParameters.add(variable.name);
      namedParameterTypes.add(getParameterType(variable));
    }
    List<FunctionTypeVariable> typeVariables;
    if (node.typeParameters.isNotEmpty) {
      List<DartType> typeParameters = <DartType>[];
      for (ir.TypeParameter typeParameter in node.typeParameters) {
        typeParameters
            .add(getDartType(new ir.TypeParameterType(typeParameter)));
      }
      typeVariables = new List<FunctionTypeVariable>.generate(
          node.typeParameters.length,
          (int index) => new FunctionTypeVariable(index));

      DartType subst(DartType type) {
        return type.subst(typeVariables, typeParameters);
      }

      returnType = subst(returnType);
      parameterTypes = parameterTypes.map(subst).toList();
      optionalParameterTypes = optionalParameterTypes.map(subst).toList();
      namedParameterTypes = namedParameterTypes.map(subst).toList();
      for (int index = 0; index < typeVariables.length; index++) {
        typeVariables[index].bound =
            subst(getDartType(node.typeParameters[index].bound));
      }
    } else {
      typeVariables = const <FunctionTypeVariable>[];
    }

    return new FunctionType(returnType, parameterTypes, optionalParameterTypes,
        namedParameters, namedParameterTypes, typeVariables);
  }

  ConstantValue computeConstantValue(
      Spannable spannable, ConstantExpression constant,
      {bool requireConstant: true}) {
    return _constantEnvironment._getConstantValue(spannable, constant,
        constantRequired: requireConstant);
  }

  DartType substByContext(DartType type, InterfaceType context) {
    return type.subst(
        context.typeArguments, getThisType(context.element).typeArguments);
  }

  /// Returns the type of the `call` method on 'type'.
  ///
  /// If [type] doesn't have a `call` member `null` is returned. If [type] has
  /// an invalid `call` member (non-method or a synthesized method with both
  /// optional and named parameters) a [DynamicType] is returned.
  DartType getCallType(InterfaceType type) {
    IndexedClass cls = type.element;
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    if (data.callType != null) {
      return substByContext(data.callType, type);
    }
    return null;
  }

  InterfaceType getThisType(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.thisType;
  }

  InterfaceType _getRawType(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.rawType;
  }

  FunctionType _getFunctionType(IndexedFunction function) {
    assert(checkFamily(function));
    FunctionData data = _members.getData(function);
    return data.getFunctionType(this);
  }

  List<TypeVariableType> _getFunctionTypeVariables(IndexedFunction function) {
    assert(checkFamily(function));
    FunctionData data = _members.getData(function);
    return data.getFunctionTypeVariables(this);
  }

  DartType _getFieldType(IndexedField field) {
    assert(checkFamily(field));
    FieldData data = _members.getData(field);
    return data.getFieldType(this);
  }

  DartType getTypeVariableBound(IndexedTypeVariable typeVariable) {
    assert(checkFamily(typeVariable));
    TypeVariableData data = _typeVariables.getData(typeVariable);
    return data.getBound(this);
  }

  DartType _getTypeVariableDefaultType(IndexedTypeVariable typeVariable) {
    assert(checkFamily(typeVariable));
    TypeVariableData data = _typeVariables.getData(typeVariable);
    return data.getDefaultType(this);
  }

  ClassEntity getAppliedMixin(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.mixedInType?.element;
  }

  bool _isMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.isMixinApplication;
  }

  bool _isUnnamedMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassEnv env = _classes.getEnv(cls);
    return env.isUnnamedMixinApplication;
  }

  bool _isSuperMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassEnv env = _classes.getEnv(cls);
    env.ensureMembers(this);
    return env.isSuperMixinApplication;
  }

  void _forEachSupertype(IndexedClass cls, void f(InterfaceType supertype)) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    data.orderedTypeSet.supertypes.forEach(f);
  }

  void _forEachMixin(IndexedClass cls, void f(ClassEntity mixin)) {
    assert(checkFamily(cls));
    while (cls != null) {
      ClassData data = _classes.getData(cls);
      _ensureSupertypes(cls, data);
      if (data.mixedInType != null) {
        f(data.mixedInType.element);
      }
      cls = data.supertype?.element;
    }
  }

  void _forEachConstructor(IndexedClass cls, void f(ConstructorEntity member)) {
    assert(checkFamily(cls));
    ClassEnv env = _classes.getEnv(cls);
    env.forEachConstructor(this, f);
  }

  void _forEachConstructorBody(
      IndexedClass cls, void f(ConstructorBodyEntity member)) {
    throw new UnsupportedError(
        'KernelToElementMapBase._forEachConstructorBody');
  }

  void _forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure));

  void _forEachLocalClassMember(IndexedClass cls, void f(MemberEntity member)) {
    assert(checkFamily(cls));
    ClassEnv env = _classes.getEnv(cls);
    env.forEachMember(this, (MemberEntity member) {
      f(member);
    });
  }

  void _forEachInjectedClassMember(
      IndexedClass cls, void f(MemberEntity member)) {
    assert(checkFamily(cls));
    throw new UnsupportedError(
        'KernelToElementMapBase._forEachInjectedClassMember');
  }

  void _forEachClassMember(
      IndexedClass cls, void f(ClassEntity cls, MemberEntity member)) {
    assert(checkFamily(cls));
    ClassEnv env = _classes.getEnv(cls);
    env.forEachMember(this, (MemberEntity member) {
      f(cls, member);
    });
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    if (data.supertype != null) {
      _forEachClassMember(data.supertype.element, f);
    }
  }

  ConstantConstructor _getConstructorConstant(IndexedConstructor constructor) {
    assert(checkFamily(constructor));
    ConstructorData data = _members.getData(constructor);
    return data.getConstructorConstant(this, constructor);
  }

  ConstantExpression _getFieldConstantExpression(IndexedField field) {
    assert(checkFamily(field));
    FieldData data = _members.getData(field);
    return data.getFieldConstantExpression(this);
  }

  InterfaceType asInstanceOf(InterfaceType type, ClassEntity cls) {
    assert(checkFamily(cls));
    OrderedTypeSet orderedTypeSet = getOrderedTypeSet(type.element);
    InterfaceType supertype =
        orderedTypeSet.asInstanceOf(cls, getHierarchyDepth(cls));
    if (supertype != null) {
      supertype = substByContext(supertype, type);
    }
    return supertype;
  }

  OrderedTypeSet getOrderedTypeSet(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet;
  }

  int getHierarchyDepth(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet.maxDepth;
  }

  Iterable<InterfaceType> getInterfaces(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.interfaces;
  }

  Spannable _getSpannable(MemberEntity member, ir.Node node) {
    SourceSpan sourceSpan;
    if (node is ir.TreeNode) {
      sourceSpan = computeSourceSpanFromTreeNode(node);
    }
    sourceSpan ??= getSourceSpan(member, null);
    return sourceSpan;
  }

  MemberDefinition _getMemberDefinition(covariant IndexedMember member) {
    assert(checkFamily(member));
    return _members.getData(member).definition;
  }

  ClassDefinition _getClassDefinition(covariant IndexedClass cls) {
    assert(checkFamily(cls));
    return _classes.getData(cls).definition;
  }

  ir.Typedef _getTypedefNode(covariant IndexedTypedef typedef) {
    return _typedefs.getData(typedef).node;
  }

  @override
  ImportEntity getImport(ir.LibraryDependency node) {
    ir.Library library = node.parent;
    LibraryData data = _libraries.getData(_getLibrary(library));
    return data.imports[node];
  }

  DartType getStaticType(ir.Expression node) {
    if (!_isStaticTypePrepared) {
      _isStaticTypePrepared = true;
      try {
        _typeEnvironment ??= new ir.TypeEnvironment(
            new ir.CoreTypes(_env.mainComponent),
            new ir.ClassHierarchy(_env.mainComponent));
      } catch (e) {}
    }
    if (_typeEnvironment == null) {
      // The class hierarchy crashes on multiple inheritance. Use `dynamic`
      // as static type.
      return commonElements.dynamicType;
    }
    ir.TreeNode enclosingClass = node;
    while (enclosingClass != null && enclosingClass is! ir.Class) {
      enclosingClass = enclosingClass.parent;
    }
    try {
      _typeEnvironment.thisType =
          enclosingClass is ir.Class ? enclosingClass.thisType : null;
      return getDartType(node.getStaticType(_typeEnvironment));
    } catch (e) {
      // The static type computation crashes on type errors. Use `dynamic`
      // as static type.
      return commonElements.dynamicType;
    }
  }

  @override
  Name getName(ir.Name name) {
    return new Name(
        name.name, name.isPrivate ? getLibrary(name.library) : null);
  }

  CallStructure getCallStructure(ir.Arguments arguments) {
    int argumentCount = arguments.positional.length + arguments.named.length;
    List<String> namedArguments = arguments.named.map((e) => e.name).toList();
    return new CallStructure(
        argumentCount, namedArguments, arguments.types.length);
  }

  @override
  Selector getSelector(ir.Expression node) {
    // TODO(efortuna): This is screaming for a common interface between
    // PropertyGet and SuperPropertyGet (and same for *Get). Talk to kernel
    // folks.
    if (node is ir.PropertyGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.SuperPropertyGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.PropertySet) {
      return getSetterSelector(node.name);
    }
    if (node is ir.SuperPropertySet) {
      return getSetterSelector(node.name);
    }
    if (node is ir.InvocationExpression) {
      return getInvocationSelector(node);
    }
    throw failedAt(
        CURRENT_ELEMENT_SPANNABLE,
        "Can only get the selector for a property get or an invocation: "
        "${node}");
  }

  Selector getInvocationSelector(ir.InvocationExpression invocation) {
    Name name = getName(invocation.name);
    SelectorKind kind;
    if (Selector.isOperatorName(name.text)) {
      if (name == Names.INDEX_NAME || name == Names.INDEX_SET_NAME) {
        kind = SelectorKind.INDEX;
      } else {
        kind = SelectorKind.OPERATOR;
      }
    } else {
      kind = SelectorKind.CALL;
    }

    CallStructure callStructure = getCallStructure(invocation.arguments);
    return new Selector(kind, name, callStructure);
  }

  Selector getGetterSelector(ir.Name irName) {
    Name name = new Name(
        irName.name, irName.isPrivate ? getLibrary(irName.library) : null);
    return new Selector.getter(name);
  }

  Selector getSetterSelector(ir.Name irName) {
    Name name = new Name(
        irName.name, irName.isPrivate ? getLibrary(irName.library) : null);
    return new Selector.setter(name);
  }

  /// Looks up [typeName] for use in the spec-string of a `JS` call.
  // TODO(johnniwinther): Use this in [native.NativeBehavior] instead of calling
  // the `ForeignResolver`.
  native.TypeLookup typeLookup({bool resolveAsRaw: true}) {
    return resolveAsRaw
        ? (_cachedTypeLookupRaw ??= _typeLookup(resolveAsRaw: true))
        : (_cachedTypeLookupFull ??= _typeLookup(resolveAsRaw: false));
  }

  native.TypeLookup _cachedTypeLookupRaw;
  native.TypeLookup _cachedTypeLookupFull;

  native.TypeLookup _typeLookup({bool resolveAsRaw: true}) {
    bool cachedMayLookupInMain;
    bool mayLookupInMain() {
      var mainUri = elementEnvironment.mainLibrary.canonicalUri;
      // Tests permit lookup outside of dart: libraries.
      return mainUri.path.contains('tests/compiler/dart2js_native') ||
          mainUri.path.contains('tests/compiler/dart2js_extra');
    }

    DartType lookup(String typeName, {bool required}) {
      DartType findInLibrary(LibraryEntity library) {
        if (library != null) {
          ClassEntity cls = elementEnvironment.lookupClass(library, typeName);
          if (cls != null) {
            // TODO(johnniwinther): Align semantics.
            return resolveAsRaw
                ? elementEnvironment.getRawType(cls)
                : elementEnvironment.getThisType(cls);
          }
        }
        return null;
      }

      DartType findIn(Uri uri) {
        return findInLibrary(elementEnvironment.lookupLibrary(uri));
      }

      // TODO(johnniwinther): Narrow the set of lookups based on the depending
      // library.
      // TODO(johnniwinther): Cache more results to avoid redundant lookups?
      DartType type;
      if (cachedMayLookupInMain ??= mayLookupInMain()) {
        type ??= findInLibrary(elementEnvironment.mainLibrary);
      }
      type ??= findIn(Uris.dart_core);
      type ??= findIn(Uris.dart__js_helper);
      type ??= findIn(Uris.dart__interceptors);
      type ??= findIn(Uris.dart__native_typed_data);
      type ??= findIn(Uris.dart_collection);
      type ??= findIn(Uris.dart_math);
      type ??= findIn(Uris.dart_html);
      type ??= findIn(Uris.dart_html_common);
      type ??= findIn(Uris.dart_svg);
      type ??= findIn(Uris.dart_web_audio);
      type ??= findIn(Uris.dart_web_gl);
      type ??= findIn(Uris.dart_web_sql);
      type ??= findIn(Uris.dart_indexed_db);
      type ??= findIn(Uris.dart_typed_data);
      type ??= findIn(Uris.dart_mirrors);
      if (type == null && required) {
        reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
            MessageKind.GENERIC, {'text': "Type '$typeName' not found."});
      }
      return type;
    }

    return lookup;
  }

  String _getStringArgument(ir.StaticInvocation node, int index) {
    return node.arguments.positional[index].accept(new Stringifier());
  }

  /// Computes the [native.NativeBehavior] for a call to the [JS] function.
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length < 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS);
      return new native.NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST);
      return new native.NativeBehavior();
    }

    String codeString = _getStringArgument(node, 1);
    if (codeString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND);
      return new native.NativeBehavior();
    }

    return native.NativeBehavior.ofJsCall(
        specString,
        codeString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Computes the [native.NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForJsBuiltinCall(
      ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin expression has no type.");
      return new native.NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin is missing name.");
      return new native.NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return new native.NativeBehavior();
    }
    return native.NativeBehavior.ofJsBuiltinCall(
        specString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Computes the [native.NativeBehavior] for a call to the
  /// [JS_EMBEDDED_GLOBAL] function.
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global expression has no type.");
      return new native.NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS embedded global is missing name.");
      return new native.NativeBehavior();
    }
    if (node.arguments.positional.length > 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global has more than 2 arguments.");
      return new native.NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return new native.NativeBehavior();
    }
    return native.NativeBehavior.ofJsEmbeddedGlobalCall(
        specString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  js.Name getNameForJsGetName(ConstantValue constant, Namer namer) {
    int index = _extractEnumIndexFromConstantValue(
        constant, commonElements.jsGetNameEnum);
    if (index == null) return null;
    return namer.getNameForJsGetName(
        CURRENT_ELEMENT_SPANNABLE, JsGetName.values[index]);
  }

  int _extractEnumIndexFromConstantValue(
      ConstantValue constant, ClassEntity classElement) {
    if (constant is ConstructedConstantValue) {
      if (constant.type.element == classElement) {
        assert(constant.fields.length == 1 || constant.fields.length == 2);
        ConstantValue indexConstant = constant.fields.values.first;
        if (indexConstant is IntConstantValue) {
          return indexConstant.intValue.toInt();
        }
      }
    }
    return null;
  }

  ConstantValue getConstantValue(ir.Expression node,
      {bool requireConstant: true, bool implicitNull: false}) {
    ConstantExpression constant;
    if (node == null) {
      if (!implicitNull) {
        throw failedAt(
            CURRENT_ELEMENT_SPANNABLE, 'No expression for constant.');
      }
      constant = new NullConstantExpression();
    } else {
      constant =
          new Constantifier(this, requireConstant: requireConstant).visit(node);
    }
    if (constant == null) {
      if (requireConstant) {
        throw new UnsupportedError(
            'No constant for ${DebugPrinter.prettyPrint(node)}');
      }
      return null;
    }
    ConstantValue value = computeConstantValue(
        computeSourceSpanFromTreeNode(node), constant,
        requireConstant: requireConstant);
    if (!value.isConstant && !requireConstant) {
      return null;
    }
    return value;
  }

  /// Converts [annotations] into a list of [ConstantValue]s.
  List<ConstantValue> getMetadata(List<ir.Expression> annotations) {
    if (annotations.isEmpty) return const <ConstantValue>[];
    List<ConstantValue> metadata = <ConstantValue>[];
    annotations.forEach((ir.Expression node) {
      metadata.add(getConstantValue(node));
    });
    return metadata;
  }

  FunctionEntity getSuperNoSuchMethod(ClassEntity cls) {
    while (cls != null) {
      cls = elementEnvironment.getSuperClass(cls);
      MemberEntity member = elementEnvironment.lookupLocalClassMember(
          cls, Identifiers.noSuchMethod_);
      if (member != null && !member.isAbstract) {
        if (member.isFunction) {
          FunctionEntity function = member;
          if (function.parameterStructure.positionalParameters >= 1) {
            return function;
          }
        }
        // If [member] is not a valid `noSuchMethod` the target is
        // `Object.superNoSuchMethod`.
        break;
      }
    }
    FunctionEntity function = elementEnvironment.lookupLocalClassMember(
        commonElements.objectClass, Identifiers.noSuchMethod_);
    assert(function != null,
        failedAt(cls, "No super noSuchMethod found for class $cls."));
    return function;
  }
}

/// Mixin that implements the abstract methods in [KernelToElementMapBase].
abstract class ElementCreatorMixin implements KernelToElementMapBase {
  /// Set to `true` before creating the J-World from the K-World to assert that
  /// no entities are created late.
  bool _envIsClosed = false;
  ProgramEnv get _env;
  EntityDataEnvMap<IndexedLibrary, LibraryData, LibraryEnv> get _libraries;
  EntityDataEnvMap<IndexedClass, ClassData, ClassEnv> get _classes;
  EntityDataMap<IndexedMember, MemberData> get _members;
  EntityDataMap<IndexedTypeVariable, TypeVariableData> get _typeVariables;
  EntityDataMap<IndexedTypedef, TypedefData> get _typedefs;

  Map<ir.Library, IndexedLibrary> _libraryMap = <ir.Library, IndexedLibrary>{};
  Map<ir.Class, IndexedClass> _classMap = <ir.Class, IndexedClass>{};
  Map<ir.Typedef, IndexedTypedef> _typedefMap = <ir.Typedef, IndexedTypedef>{};

  /// Map from [ir.TypeParameter] nodes to the corresponding
  /// [TypeVariableEntity].
  ///
  /// Normally the type variables are [IndexedTypeVariable]s, but for type
  /// parameters on local function (in the frontend) these are _not_ since
  /// their type declaration is neither a class nor a member. In the backend,
  /// these type parameters belong to the call-method and are therefore indexed.
  Map<ir.TypeParameter, TypeVariableEntity> _typeVariableMap =
      <ir.TypeParameter, TypeVariableEntity>{};
  Map<ir.Member, IndexedConstructor> _constructorMap =
      <ir.Member, IndexedConstructor>{};
  Map<ir.Procedure, IndexedFunction> _methodMap =
      <ir.Procedure, IndexedFunction>{};
  Map<ir.Field, IndexedField> _fieldMap = <ir.Field, IndexedField>{};
  Map<ir.TreeNode, Local> _localFunctionMap = <ir.TreeNode, Local>{};

  Name getName(ir.Name node);
  FunctionType getFunctionType(ir.FunctionNode node);
  MemberEntity getMember(ir.Member node);
  Entity getClosure(ir.FunctionDeclaration node);

  Iterable<LibraryEntity> get _libraryList {
    if (_env.length != _libraryMap.length) {
      // Create a [KLibrary] for each library.
      _env.forEachLibrary((LibraryEnv env) {
        _getLibrary(env.library, env);
      });
    }
    return _libraryMap.values;
  }

  LibraryEntity _getLibrary(ir.Library node, [LibraryEnv libraryEnv]) {
    return _libraryMap[node] ??= _getLibraryCreate(node, libraryEnv);
  }

  LibraryEntity _getLibraryCreate(ir.Library node, LibraryEnv libraryEnv) {
    assert(
        !_envIsClosed,
        "Environment of $this is closed. Trying to create "
        "library for $node.");
    Uri canonicalUri = node.importUri;
    String name = node.name;
    if (name == null) {
      // Use the file name as script name.
      String path = canonicalUri.path;
      name = path.substring(path.lastIndexOf('/') + 1);
    }
    IndexedLibrary library = createLibrary(name, canonicalUri);
    return _libraries.register(library, new LibraryData(node),
        libraryEnv ?? _env.lookupLibrary(canonicalUri));
  }

  ClassEntity _getClass(ir.Class node, [ClassEnv classEnv]) {
    return _classMap[node] ??= _getClassCreate(node, classEnv);
  }

  ClassEntity _getClassCreate(ir.Class node, ClassEnv classEnv) {
    assert(
        !_envIsClosed,
        "Environment of $this is closed. Trying to create "
        "class for $node.");
    KLibrary library = _getLibrary(node.enclosingLibrary);
    if (classEnv == null) {
      classEnv = _libraries.getEnv(library).lookupClass(node.name);
    }
    IndexedClass cls =
        createClass(library, node.name, isAbstract: node.isAbstract);
    return _classes.register(
        cls,
        new ClassDataImpl(node, new RegularClassDefinition(cls, node)),
        classEnv);
  }

  TypedefEntity _getTypedef(ir.Typedef node) {
    return _typedefMap[node] ??= _getTypedefCreate(node);
  }

  TypedefEntity _getTypedefCreate(ir.Typedef node) {
    assert(
        !_envIsClosed,
        "Environment of $this is closed. Trying to create "
        "typedef for $node.");
    IndexedLibrary library = _getLibrary(node.enclosingLibrary);
    IndexedTypedef typedef = createTypedef(library, node.name);
    TypedefType typedefType = new TypedefType(
        typedef,
        new List<DartType>.filled(
            node.typeParameters.length, const DynamicType()),
        getDartType(node.type));
    return _typedefs.register(
        typedef, new TypedefData(node, typedef, typedefType));
  }

  TypeVariableEntity _getTypeVariable(ir.TypeParameter node) {
    return _typeVariableMap[node] ??= _getTypeVariableCreate(node);
  }

  TypeVariableEntity _getTypeVariableCreate(ir.TypeParameter node) {
    assert(
        !_envIsClosed,
        "Environment of $this is closed. Trying to create "
        "type variable for $node.");
    if (node.parent is ir.Class) {
      ir.Class cls = node.parent;
      int index = cls.typeParameters.indexOf(node);
      return _typeVariables.register(
          createTypeVariable(_getClass(cls), node.name, index),
          new TypeVariableData(node));
    }
    if (node.parent is ir.FunctionNode) {
      ir.FunctionNode func = node.parent;
      int index = func.typeParameters.indexOf(node);
      if (func.parent is ir.Constructor) {
        ir.Constructor constructor = func.parent;
        ir.Class cls = constructor.enclosingClass;
        return _getTypeVariable(cls.typeParameters[index]);
      } else if (func.parent is ir.Procedure) {
        ir.Procedure procedure = func.parent;
        if (procedure.kind == ir.ProcedureKind.Factory) {
          ir.Class cls = procedure.enclosingClass;
          return _getTypeVariable(cls.typeParameters[index]);
        } else {
          return _typeVariables.register(
              createTypeVariable(_getMethod(procedure), node.name, index),
              new TypeVariableData(node));
        }
      } else {
        throw new UnsupportedError('Unsupported function type parameter parent '
            'node ${func.parent}.');
      }
    }
    throw new UnsupportedError('Unsupported type parameter type node $node.');
  }

  ConstructorEntity _getConstructor(ir.Member node) {
    return _constructorMap[node] ??= _getConstructorCreate(node);
  }

  ConstructorEntity _getConstructorCreate(ir.Member node) {
    assert(
        !_envIsClosed,
        "Environment of $this is closed. Trying to create "
        "constructor for $node.");
    MemberDefinition definition;
    ir.FunctionNode functionNode;
    ClassEntity enclosingClass = _getClass(node.enclosingClass);
    Name name = getName(node.name);
    bool isExternal = node.isExternal;

    IndexedConstructor constructor;
    if (node is ir.Constructor) {
      functionNode = node.function;
      constructor = createGenerativeConstructor(enclosingClass, name,
          _getParameterStructure(functionNode, includeTypeParameters: false),
          isExternal: isExternal, isConst: node.isConst);
      definition = new SpecialMemberDefinition(
          constructor, node, MemberKind.constructor);
    } else if (node is ir.Procedure) {
      functionNode = node.function;
      bool isFromEnvironment = isExternal &&
          name.text == 'fromEnvironment' &&
          const ['int', 'bool', 'String'].contains(enclosingClass.name);
      constructor = createFactoryConstructor(enclosingClass, name,
          _getParameterStructure(functionNode, includeTypeParameters: false),
          isExternal: isExternal,
          isConst: node.isConst,
          isFromEnvironmentConstructor: isFromEnvironment);
      definition = new RegularMemberDefinition(constructor, node);
    } else {
      // TODO(johnniwinther): Convert `node.location` to a [SourceSpan].
      throw failedAt(
          NO_LOCATION_SPANNABLE, "Unexpected constructor node: ${node}.");
    }
    return _members.register<IndexedConstructor, ConstructorData>(
        constructor, new ConstructorDataImpl(node, functionNode, definition));
  }

  FunctionEntity _getMethod(ir.Procedure node) {
    return _methodMap[node] ??= _getMethodCreate(node);
  }

  FunctionEntity _getMethodCreate(ir.Procedure node) {
    assert(
        !_envIsClosed,
        "Environment of $this is closed. Trying to create "
        "function for $node.");
    LibraryEntity library;
    ClassEntity enclosingClass;
    if (node.enclosingClass != null) {
      enclosingClass = _getClass(node.enclosingClass);
      library = enclosingClass.library;
    } else {
      library = _getLibrary(node.enclosingLibrary);
    }
    Name name = getName(node.name);
    bool isStatic = node.isStatic;
    bool isExternal = node.isExternal;
    // TODO(johnniwinther): Remove `&& !node.isExternal` when #31233 is fixed.
    bool isAbstract = node.isAbstract && !node.isExternal;
    AsyncMarker asyncMarker = getAsyncMarker(node.function);
    IndexedFunction function;
    switch (node.kind) {
      case ir.ProcedureKind.Factory:
        throw new UnsupportedError("Cannot create method from factory.");
      case ir.ProcedureKind.Getter:
        function = createGetter(library, enclosingClass, name, asyncMarker,
            isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
        break;
      case ir.ProcedureKind.Method:
      case ir.ProcedureKind.Operator:
        function = createMethod(library, enclosingClass, name,
            _getParameterStructure(node.function), asyncMarker,
            isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
        break;
      case ir.ProcedureKind.Setter:
        assert(asyncMarker == AsyncMarker.SYNC);
        function = createSetter(library, enclosingClass, name.setter,
            isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
        break;
    }
    return _members.register<IndexedFunction, FunctionData>(
        function,
        new FunctionDataImpl(
            node, node.function, new RegularMemberDefinition(function, node)));
  }

  FieldEntity _getField(ir.Field node) {
    return _fieldMap[node] ??= _getFieldCreate(node);
  }

  FieldEntity _getFieldCreate(ir.Field node) {
    assert(
        !_envIsClosed,
        "Environment of $this is closed. Trying to create "
        "field for $node.");
    LibraryEntity library;
    ClassEntity enclosingClass;
    if (node.enclosingClass != null) {
      enclosingClass = _getClass(node.enclosingClass);
      library = enclosingClass.library;
    } else {
      library = _getLibrary(node.enclosingLibrary);
    }
    Name name = getName(node.name);
    bool isStatic = node.isStatic;
    IndexedField field = createField(library, enclosingClass, name,
        isStatic: isStatic,
        isAssignable: node.isMutable,
        isConst: node.isConst);
    return _members.register<IndexedField, FieldData>(field,
        new FieldDataImpl(node, new RegularMemberDefinition(field, node)));
  }

  ParameterStructure _getParameterStructure(ir.FunctionNode node,
      // TODO(johnniwinther): Remove this when type arguments are passed to
      // constructors like calling a generic method.
      {bool includeTypeParameters: true}) {
    // TODO(johnniwinther): Cache the computed function type.
    int requiredParameters = node.requiredParameterCount;
    int positionalParameters = node.positionalParameters.length;
    int typeParameters = node.typeParameters.length;
    List<String> namedParameters =
        node.namedParameters.map((p) => p.name).toList()..sort();
    return new ParameterStructure(requiredParameters, positionalParameters,
        namedParameters, includeTypeParameters ? typeParameters : 0);
  }

  IndexedLibrary createLibrary(String name, Uri canonicalUri);

  IndexedClass createClass(LibraryEntity library, String name,
      {bool isAbstract});

  IndexedTypedef createTypedef(LibraryEntity library, String name);

  TypeVariableEntity createTypeVariable(
      Entity typeDeclaration, String name, int index);

  IndexedConstructor createGenerativeConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst});

  IndexedConstructor createFactoryConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, bool isFromEnvironmentConstructor});

  IndexedFunction createGetter(LibraryEntity library,
      ClassEntity enclosingClass, Name name, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, bool isAbstract});

  IndexedFunction createMethod(
      LibraryEntity library,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      AsyncMarker asyncMarker,
      {bool isStatic,
      bool isExternal,
      bool isAbstract});

  IndexedFunction createSetter(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isExternal, bool isAbstract});

  IndexedField createField(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isAssignable, bool isConst});
}

/// Implementation of [KernelToElementMapForImpact] that only supports world
/// impact computation.
class KernelToElementMapForImpactImpl extends KernelToElementMapBase
    with ElementCreatorMixin
    implements KernelToElementMapForImpact {
  native.BehaviorBuilder _nativeBehaviorBuilder;
  FrontendStrategy _frontendStrategy;

  KernelToElementMapForImpactImpl(DiagnosticReporter reporter,
      Environment environment, this._frontendStrategy, CompilerOptions options)
      : super(options, reporter, environment);

  @override
  bool checkFamily(Entity entity) {
    assert(
        '$entity'.startsWith(kElementPrefix),
        failedAt(entity,
            "Unexpected entity $entity, expected family $kElementPrefix."));
    return true;
  }

  DartType getTypeVariableBound(TypeVariableEntity typeVariable) {
    if (typeVariable is KLocalTypeVariable) return typeVariable.bound;
    return super.getTypeVariableBound(typeVariable);
  }

  DartType _getTypeVariableDefaultType(TypeVariableEntity typeVariable) {
    if (typeVariable is KLocalTypeVariable) return typeVariable.defaultType;
    return super._getTypeVariableDefaultType(typeVariable);
  }

  @override
  void _forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    throw new UnsupportedError(
        "KernelToElementMapForImpactImpl._forEachNestedClosure");
  }

  @override
  NativeBasicData get nativeBasicData => _frontendStrategy.nativeBasicData;

  /// Adds libraries in [component] to the set of libraries.
  ///
  /// The main method of the first component is used as the main method for the
  /// compilation.
  void addComponent(ir.Component component) {
    _env.addComponent(component);
  }

  native.BehaviorBuilder get nativeBehaviorBuilder =>
      _nativeBehaviorBuilder ??= new KernelBehaviorBuilder(elementEnvironment,
          commonElements, nativeBasicData, reporter, options);

  ResolutionImpact computeWorldImpact(KMember member) {
    return buildKernelImpact(
        _members.getData(member).definition.node, this, reporter, options);
  }

  ScopeModel computeScopeModel(KMember member) {
    ir.Member node = _members.getData(member).definition.node;
    return KernelClosureAnalysis.computeScopeModel(member, node);
  }

  /// Returns the kernel [ir.Procedure] node for the [method].
  ir.Procedure _lookupProcedure(KFunction method) {
    return _members.getData(method).definition.node;
  }

  @override
  ir.Library getLibraryNode(LibraryEntity library) {
    return _libraries.getData(library).library;
  }

  @override
  Entity getClosure(ir.FunctionDeclaration node) {
    return getLocalFunction(node);
  }

  @override
  Local getLocalFunction(ir.TreeNode node) {
    assert(
        node is ir.FunctionDeclaration || node is ir.FunctionExpression,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE, 'Invalid local function node: $node'));
    KLocalFunction localFunction = _localFunctionMap[node];
    if (localFunction == null) {
      MemberEntity memberContext;
      Entity executableContext;
      ir.TreeNode parent = node.parent;
      while (parent != null) {
        if (parent is ir.Member) {
          executableContext = memberContext = getMember(parent);
          break;
        }
        if (parent is ir.FunctionDeclaration ||
            parent is ir.FunctionExpression) {
          KLocalFunction localFunction = getLocalFunction(parent);
          executableContext = localFunction;
          memberContext = localFunction.memberContext;
          break;
        }
        parent = parent.parent;
      }
      String name;
      ir.FunctionNode function;
      if (node is ir.FunctionDeclaration) {
        name = node.variable.name;
        function = node.function;
      } else if (node is ir.FunctionExpression) {
        function = node.function;
      }
      localFunction = _localFunctionMap[node] =
          new KLocalFunction(name, memberContext, executableContext, node);
      int index = 0;
      List<KLocalTypeVariable> typeVariables = <KLocalTypeVariable>[];
      for (ir.TypeParameter typeParameter in function.typeParameters) {
        typeVariables.add(_typeVariableMap[typeParameter] =
            new KLocalTypeVariable(localFunction, typeParameter.name, index));
        index++;
      }
      index = 0;
      for (ir.TypeParameter typeParameter in function.typeParameters) {
        typeVariables[index].bound = getDartType(typeParameter.bound);
        typeVariables[index].defaultType =
            getDartType(typeParameter.defaultType);
        index++;
      }
      localFunction.functionType = getFunctionType(function);
    }
    return localFunction;
  }

  bool _implementsFunction(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    OrderedTypeSet orderedTypeSet = data.orderedTypeSet;
    InterfaceType supertype = orderedTypeSet.asInstanceOf(
        commonElements.functionClass,
        getHierarchyDepth(commonElements.functionClass));
    if (supertype != null) {
      return true;
    }
    return data.callType is FunctionType;
  }

  @override
  MemberDefinition getMemberDefinition(MemberEntity member) {
    return _getMemberDefinition(member);
  }

  @override
  ClassDefinition getClassDefinition(ClassEntity cls) {
    return _getClassDefinition(cls);
  }

  @override
  ir.Typedef getTypedefNode(TypedefEntity typedef) {
    return _getTypedefNode(typedef);
  }

  /// Returns the element type of a async/sync*/async* function.
  @override
  DartType getFunctionAsyncOrSyncStarElementType(ir.FunctionNode functionNode) {
    DartType returnType = getDartType(functionNode.returnType);
    switch (functionNode.asyncMarker) {
      case ir.AsyncMarker.SyncStar:
        return elementEnvironment.getAsyncOrSyncStarElementType(
            AsyncMarker.SYNC_STAR, returnType);
      case ir.AsyncMarker.Async:
        return elementEnvironment.getAsyncOrSyncStarElementType(
            AsyncMarker.ASYNC, returnType);
      case ir.AsyncMarker.AsyncStar:
        return elementEnvironment.getAsyncOrSyncStarElementType(
            AsyncMarker.ASYNC_STAR, returnType);
      default:
        failedAt(CURRENT_ELEMENT_SPANNABLE,
            "Unexpected ir.AsyncMarker: ${functionNode.asyncMarker}");
    }
    return null;
  }

  /// Returns `true` is [node] has a `@Native(...)` annotation.
  // TODO(johnniwinther): Cache this for later use.
  bool isNativeClass(ir.Class node) {
    for (ir.Expression annotation in node.annotations) {
      if (annotation is ir.ConstructorInvocation) {
        FunctionEntity target = getConstructor(annotation.target);
        if (target.enclosingClass == commonElements.nativeAnnotationClass) {
          return true;
        }
      }
    }
    return false;
  }

  /// Compute the kind of foreign helper function called by [node], if any.
  ForeignKind getForeignKind(ir.StaticInvocation node) {
    if (commonElements.isForeignHelper(getMember(node.target))) {
      switch (node.target.name.name) {
        case JavaScriptBackend.JS:
          return ForeignKind.JS;
        case JavaScriptBackend.JS_BUILTIN:
          return ForeignKind.JS_BUILTIN;
        case JavaScriptBackend.JS_EMBEDDED_GLOBAL:
          return ForeignKind.JS_EMBEDDED_GLOBAL;
        case JavaScriptBackend.JS_INTERCEPTOR_CONSTANT:
          return ForeignKind.JS_INTERCEPTOR_CONSTANT;
      }
    }
    return ForeignKind.NONE;
  }

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType getInterfaceTypeForJsInterceptorCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length != 1 ||
        node.arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
          MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    }
    ir.Node argument = node.arguments.positional.first;
    if (argument is ir.TypeLiteral && argument.type is ir.InterfaceType) {
      return getInterfaceType(argument.type);
    }
    return null;
  }

  /// Computes the native behavior for reading the native [field].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      {bool isJsInterop}) {
    DartType type = getDartType(field.type);
    List<ConstantValue> metadata = getMetadata(field.annotations);
    return nativeBehaviorBuilder.buildFieldLoadBehavior(
        type, metadata, typeLookup(resolveAsRaw: false),
        isJsInterop: isJsInterop);
  }

  /// Computes the native behavior for writing to the native [field].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForFieldStore(ir.Field field) {
    DartType type = getDartType(field.type);
    return nativeBehaviorBuilder.buildFieldStoreBehavior(type);
  }

  /// Computes the native behavior for calling [member].
  // TODO(johnniwinther): Cache this for later use.
  native.NativeBehavior getNativeBehaviorForMethod(ir.Member member,
      {bool isJsInterop}) {
    DartType type;
    if (member is ir.Procedure) {
      type = getFunctionType(member.function);
    } else if (member is ir.Constructor) {
      type = getFunctionType(member.function);
    } else {
      failedAt(CURRENT_ELEMENT_SPANNABLE, "Unexpected method node $member.");
    }
    List<ConstantValue> metadata = getMetadata(member.annotations);
    return nativeBehaviorBuilder.buildMethodBehavior(
        type, metadata, typeLookup(resolveAsRaw: false),
        isJsInterop: isJsInterop);
  }

  IndexedLibrary createLibrary(String name, Uri canonicalUri) {
    return new KLibrary(name, canonicalUri);
  }

  IndexedClass createClass(LibraryEntity library, String name,
      {bool isAbstract}) {
    return new KClass(library, name, isAbstract: isAbstract);
  }

  @override
  IndexedTypedef createTypedef(LibraryEntity library, String name) {
    return new KTypedef(library, name);
  }

  TypeVariableEntity createTypeVariable(
      Entity typeDeclaration, String name, int index) {
    return new KTypeVariable(typeDeclaration, name, index);
  }

  IndexedConstructor createGenerativeConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst}) {
    return new KGenerativeConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal, isConst: isConst);
  }

  IndexedConstructor createFactoryConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, bool isFromEnvironmentConstructor}) {
    return new KFactoryConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal,
        isConst: isConst,
        isFromEnvironmentConstructor: isFromEnvironmentConstructor);
  }

  IndexedFunction createGetter(LibraryEntity library,
      ClassEntity enclosingClass, Name name, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new KGetter(library, enclosingClass, name, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createMethod(
      LibraryEntity library,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      AsyncMarker asyncMarker,
      {bool isStatic,
      bool isExternal,
      bool isAbstract}) {
    return new KMethod(
        library, enclosingClass, name, parameterStructure, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createSetter(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new KSetter(library, enclosingClass, name,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedField createField(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isAssignable, bool isConst}) {
    return new KField(library, enclosingClass, name,
        isStatic: isStatic, isAssignable: isAssignable, isConst: isConst);
  }
}

class KernelElementEnvironment extends ElementEnvironment {
  final KernelToElementMapBase elementMap;

  KernelElementEnvironment(this.elementMap);

  @override
  DartType get dynamicType => const DynamicType();

  @override
  LibraryEntity get mainLibrary => elementMap._mainLibrary;

  @override
  FunctionEntity get mainFunction => elementMap._mainFunction;

  @override
  Iterable<LibraryEntity> get libraries => elementMap._libraryList;

  @override
  String getLibraryName(LibraryEntity library) {
    return elementMap._getLibraryName(library);
  }

  @override
  InterfaceType getThisType(ClassEntity cls) {
    return elementMap.getThisType(cls);
  }

  @override
  InterfaceType getRawType(ClassEntity cls) {
    return elementMap._getRawType(cls);
  }

  @override
  bool isGenericClass(ClassEntity cls) {
    return getThisType(cls).typeArguments.isNotEmpty;
  }

  @override
  bool isMixinApplication(ClassEntity cls) {
    return elementMap._isMixinApplication(cls);
  }

  @override
  bool isUnnamedMixinApplication(ClassEntity cls) {
    return elementMap._isUnnamedMixinApplication(cls);
  }

  @override
  bool isSuperMixinApplication(ClassEntity cls) {
    return elementMap._isSuperMixinApplication(cls);
  }

  @override
  ClassEntity getEffectiveMixinClass(ClassEntity cls) {
    if (!isMixinApplication(cls)) return null;
    do {
      cls = elementMap.getAppliedMixin(cls);
    } while (isMixinApplication(cls));
    return cls;
  }

  @override
  DartType getTypeVariableBound(TypeVariableEntity typeVariable) {
    return elementMap.getTypeVariableBound(typeVariable);
  }

  @override
  DartType getTypeVariableDefaultType(TypeVariableEntity typeVariable) {
    return elementMap._getTypeVariableDefaultType(typeVariable);
  }

  @override
  InterfaceType createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments) {
    return new InterfaceType(cls, typeArguments);
  }

  @override
  FunctionType getFunctionType(FunctionEntity function) {
    return elementMap._getFunctionType(function);
  }

  @override
  List<TypeVariableType> getFunctionTypeVariables(FunctionEntity function) {
    return elementMap._getFunctionTypeVariables(function);
  }

  @override
  DartType getFunctionAsyncOrSyncStarElementType(FunctionEntity function) {
    // TODO(sra): Should be getting the DartType from the node.
    DartType returnType = getFunctionType(function).returnType;
    return getAsyncOrSyncStarElementType(function.asyncMarker, returnType);
  }

  @override
  DartType getAsyncOrSyncStarElementType(
      AsyncMarker asyncMarker, DartType returnType) {
    switch (asyncMarker) {
      case AsyncMarker.SYNC:
        return returnType;
      case AsyncMarker.SYNC_STAR:
        if (returnType is InterfaceType) {
          if (returnType.element == elementMap.commonElements.iterableClass) {
            return returnType.typeArguments.first;
          }
        }
        return dynamicType;
      case AsyncMarker.ASYNC:
        if (returnType is FutureOrType) return returnType.typeArgument;
        if (returnType is InterfaceType) {
          if (returnType.element == elementMap.commonElements.futureClass) {
            return returnType.typeArguments.first;
          }
        }
        return dynamicType;
      case AsyncMarker.ASYNC_STAR:
        if (returnType is InterfaceType) {
          if (returnType.element == elementMap.commonElements.streamClass) {
            return returnType.typeArguments.first;
          }
        }
        return dynamicType;
    }
    assert(false, 'Unexpected marker ${asyncMarker}');
    return null;
  }

  @override
  DartType getFieldType(FieldEntity field) {
    return elementMap._getFieldType(field);
  }

  @override
  FunctionType getLocalFunctionType(covariant KLocalFunction function) {
    return function.functionType;
  }

  @override
  ConstantExpression getFieldConstant(FieldEntity field) {
    return elementMap._getFieldConstantExpression(field);
  }

  @override
  DartType getUnaliasedType(DartType type) => type;

  @override
  ConstructorEntity lookupConstructor(ClassEntity cls, String name,
      {bool required: false}) {
    ConstructorEntity constructor = elementMap.lookupConstructor(cls, name);
    if (constructor == null && required) {
      throw failedAt(
          CURRENT_ELEMENT_SPANNABLE,
          "The constructor '$name' was not found in class '${cls.name}' "
          "in library ${cls.library.canonicalUri}.");
    }
    return constructor;
  }

  @override
  MemberEntity lookupLocalClassMember(ClassEntity cls, String name,
      {bool setter: false, bool required: false}) {
    MemberEntity member =
        elementMap.lookupClassMember(cls, name, setter: setter);
    if (member == null && required) {
      throw failedAt(CURRENT_ELEMENT_SPANNABLE,
          "The member '$name' was not found in ${cls.name}.");
    }
    return member;
  }

  @override
  ClassEntity getSuperClass(ClassEntity cls,
      {bool skipUnnamedMixinApplications: false}) {
    assert(elementMap.checkFamily(cls));
    ClassEntity superclass = elementMap.getSuperType(cls)?.element;
    if (skipUnnamedMixinApplications) {
      while (superclass != null &&
          elementMap._isUnnamedMixinApplication(superclass)) {
        superclass = elementMap.getSuperType(superclass)?.element;
      }
    }
    return superclass;
  }

  @override
  void forEachSupertype(ClassEntity cls, void f(InterfaceType supertype)) {
    elementMap._forEachSupertype(cls, f);
  }

  @override
  void forEachMixin(ClassEntity cls, void f(ClassEntity mixin)) {
    elementMap._forEachMixin(cls, f);
  }

  @override
  void forEachLocalClassMember(ClassEntity cls, void f(MemberEntity member)) {
    elementMap._forEachLocalClassMember(cls, f);
  }

  @override
  void forEachInjectedClassMember(
      ClassEntity cls, void f(MemberEntity member)) {
    elementMap._forEachInjectedClassMember(cls, f);
  }

  @override
  void forEachClassMember(
      ClassEntity cls, void f(ClassEntity declarer, MemberEntity member)) {
    elementMap._forEachClassMember(cls, f);
  }

  @override
  void forEachConstructor(
      ClassEntity cls, void f(ConstructorEntity constructor),
      {bool ensureResolved: true}) {
    elementMap._forEachConstructor(cls, f);
  }

  @override
  void forEachConstructorBody(
      ClassEntity cls, void f(ConstructorBodyEntity constructor)) {
    elementMap._forEachConstructorBody(cls, f);
  }

  @override
  void forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    elementMap._forEachNestedClosure(member, f);
  }

  @override
  void forEachLibraryMember(
      LibraryEntity library, void f(MemberEntity member)) {
    elementMap._forEachLibraryMember(library, f);
  }

  @override
  MemberEntity lookupLibraryMember(LibraryEntity library, String name,
      {bool setter: false, bool required: false}) {
    MemberEntity member =
        elementMap.lookupLibraryMember(library, name, setter: setter);
    if (member == null && required) {
      failedAt(CURRENT_ELEMENT_SPANNABLE,
          "The member '${name}' was not found in library '${library.name}'.");
    }
    return member;
  }

  @override
  ClassEntity lookupClass(LibraryEntity library, String name,
      {bool required: false}) {
    ClassEntity cls = elementMap.lookupClass(library, name);
    if (cls == null && required) {
      failedAt(CURRENT_ELEMENT_SPANNABLE,
          "The class '$name'  was not found in library '${library.name}'.");
    }
    return cls;
  }

  @override
  void forEachClass(LibraryEntity library, void f(ClassEntity cls)) {
    elementMap._forEachClass(library, f);
  }

  @override
  LibraryEntity lookupLibrary(Uri uri, {bool required: false}) {
    LibraryEntity library = elementMap.lookupLibrary(uri);
    if (library == null && required) {
      failedAt(CURRENT_ELEMENT_SPANNABLE, "The library '$uri' was not found.");
    }
    return library;
  }

  @override
  bool isDeferredLoadLibraryGetter(MemberEntity member) {
    // The front-end generates the getter of loadLibrary explicitly as code
    // so there is no implicit representation based on a "loadLibrary" member.
    return false;
  }

  @override
  Iterable<ConstantValue> getLibraryMetadata(covariant IndexedLibrary library) {
    assert(elementMap.checkFamily(library));
    LibraryData libraryData = elementMap._libraries.getData(library);
    return libraryData.getMetadata(elementMap);
  }

  @override
  Iterable<ImportEntity> getImports(covariant IndexedLibrary library) {
    assert(elementMap.checkFamily(library));
    LibraryData libraryData = elementMap._libraries.getData(library);
    return libraryData.getImports(elementMap);
  }

  @override
  Iterable<ConstantValue> getClassMetadata(covariant IndexedClass cls) {
    assert(elementMap.checkFamily(cls));
    ClassData classData = elementMap._classes.getData(cls);
    return classData.getMetadata(elementMap);
  }

  @override
  Iterable<ConstantValue> getMemberMetadata(covariant IndexedMember member,
      {bool includeParameterMetadata: false}) {
    // TODO(redemption): Support includeParameterMetadata.
    assert(elementMap.checkFamily(member));
    MemberData memberData = elementMap._members.getData(member);
    return memberData.getMetadata(elementMap);
  }

  @override
  bool isEnumClass(ClassEntity cls) {
    assert(elementMap.checkFamily(cls));
    ClassData classData = elementMap._classes.getData(cls);
    return classData.isEnumClass;
  }
}

/// Visitor that converts kernel dart types into [DartType].
class DartTypeConverter extends ir.DartTypeVisitor<DartType> {
  final KernelToElementMapBase elementMap;
  final Map<ir.TypeParameter, DartType> currentFunctionTypeParameters =
      <ir.TypeParameter, DartType>{};
  bool topLevel = true;

  DartTypeConverter(this.elementMap);

  DartType convert(ir.DartType type) {
    topLevel = true;
    return type.accept(this);
  }

  /// Visit a inner type.
  DartType visitType(ir.DartType type) {
    topLevel = false;
    return type.accept(this);
  }

  InterfaceType visitSupertype(ir.Supertype node) {
    ClassEntity cls = elementMap.getClass(node.classNode);
    return new InterfaceType(cls, visitTypes(node.typeArguments));
  }

  List<DartType> visitTypes(List<ir.DartType> types) {
    topLevel = false;
    return new List.generate(
        types.length, (int index) => types[index].accept(this));
  }

  @override
  DartType visitTypeParameterType(ir.TypeParameterType node) {
    DartType typeParameter = currentFunctionTypeParameters[node.parameter];
    if (typeParameter != null) {
      return typeParameter;
    }
    if (node.parameter.parent is ir.Typedef) {
      // Typedefs are only used in type literals so we never need their type
      // variables.
      return const DynamicType();
    }
    return new TypeVariableType(elementMap.getTypeVariable(node.parameter));
  }

  @override
  DartType visitFunctionType(ir.FunctionType node) {
    int index = 0;
    List<FunctionTypeVariable> typeVariables;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      FunctionTypeVariable typeVariable = new FunctionTypeVariable(index);
      currentFunctionTypeParameters[typeParameter] = typeVariable;
      typeVariables ??= <FunctionTypeVariable>[];
      typeVariables.add(typeVariable);
      index++;
    }
    if (typeVariables != null) {
      for (int index = 0; index < typeVariables.length; index++) {
        typeVariables[index].bound =
            node.typeParameters[index].bound.accept(this);
      }
    }

    FunctionType type = new FunctionType(
        visitType(node.returnType),
        visitTypes(node.positionalParameters
            .take(node.requiredParameterCount)
            .toList()),
        visitTypes(node.positionalParameters
            .skip(node.requiredParameterCount)
            .toList()),
        node.namedParameters.map((n) => n.name).toList(),
        node.namedParameters.map((n) => visitType(n.type)).toList(),
        typeVariables ?? const <FunctionTypeVariable>[]);
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      currentFunctionTypeParameters.remove(typeParameter);
    }
    return type;
  }

  @override
  DartType visitInterfaceType(ir.InterfaceType node) {
    ClassEntity cls = elementMap.getClass(node.classNode);
    if (cls.name == 'FutureOr' &&
        cls.library == elementMap.commonElements.asyncLibrary) {
      return new FutureOrType(visitTypes(node.typeArguments).single);
    }
    return new InterfaceType(cls, visitTypes(node.typeArguments));
  }

  @override
  DartType visitVoidType(ir.VoidType node) {
    return const VoidType();
  }

  @override
  DartType visitDynamicType(ir.DynamicType node) {
    return const DynamicType();
  }

  @override
  DartType visitInvalidType(ir.InvalidType node) {
    // Root uses such a `o is Unresolved` and `o as Unresolved` must be special
    // cased in the builder, nested invalid types are treated as `dynamic`.
    return const DynamicType();
  }

  @override
  DartType visitBottomType(ir.BottomType node) {
    return elementMap.commonElements.nullType;
  }
}

/// [native.BehaviorBuilder] for kernel based elements.
class KernelBehaviorBuilder extends native.BehaviorBuilder {
  final ElementEnvironment elementEnvironment;
  final CommonElements commonElements;
  final DiagnosticReporter reporter;
  final NativeBasicData nativeBasicData;
  final CompilerOptions _options;

  KernelBehaviorBuilder(this.elementEnvironment, this.commonElements,
      this.nativeBasicData, this.reporter, this._options);

  @override
  bool get trustJSInteropTypeAnnotations =>
      _options.trustJSInteropTypeAnnotations;
}

/// Constant environment mapping [ConstantExpression]s to [ConstantValue]s using
/// [_EvaluationEnvironment] for the evaluation.
class KernelConstantEnvironment implements ConstantEnvironment {
  final KernelToElementMapBase _elementMap;
  final Environment _environment;

  Map<ConstantExpression, ConstantValue> _valueMap =
      <ConstantExpression, ConstantValue>{};

  KernelConstantEnvironment(this._elementMap, this._environment);

  @override
  ConstantSystem get constantSystem => JavaScriptConstantSystem.only;

  ConstantValue _getConstantValue(
      Spannable spannable, ConstantExpression expression,
      {bool constantRequired}) {
    return _valueMap.putIfAbsent(expression, () {
      return expression.evaluate(
          new KernelEvaluationEnvironment(_elementMap, _environment, spannable,
              constantRequired: constantRequired),
          constantSystem);
    });
  }
}

/// Evaluation environment used for computing [ConstantValue]s for
/// kernel based [ConstantExpression]s.
class KernelEvaluationEnvironment extends EvaluationEnvironmentBase {
  final KernelToElementMapBase _elementMap;
  final Environment _environment;

  KernelEvaluationEnvironment(
      this._elementMap, this._environment, Spannable spannable,
      {bool constantRequired})
      : super(spannable, constantRequired: constantRequired);

  @override
  CommonElements get commonElements => _elementMap.commonElements;

  @override
  DartTypes get types => _elementMap.types;

  @override
  DartType substByContext(DartType base, InterfaceType target) {
    return _elementMap.substByContext(base, target);
  }

  @override
  ConstantConstructor getConstructorConstant(ConstructorEntity constructor) {
    return _elementMap._getConstructorConstant(constructor);
  }

  @override
  ConstantExpression getFieldConstant(FieldEntity field) {
    return _elementMap._getFieldConstantExpression(field);
  }

  @override
  ConstantExpression getLocalConstant(Local local) {
    throw new UnimplementedError("_EvaluationEnvironment.getLocalConstant");
  }

  @override
  String readFromEnvironment(String name) {
    return _environment.valueOf(name);
  }

  @override
  DiagnosticReporter get reporter => _elementMap.reporter;

  @override
  bool get enableAssertions => _elementMap.options.enableUserAssertions;
}

class KClosedWorldImpl extends ClosedWorldRtiNeedMixin implements KClosedWorld {
  final KernelToElementMapForImpactImpl elementMap;
  final ElementEnvironment elementEnvironment;
  final DartTypes dartTypes;
  final CommonElements commonElements;
  final NativeData nativeData;
  final InterceptorData interceptorData;
  final BackendUsage backendUsage;
  final NoSuchMethodData noSuchMethodData;

  final Map<ClassEntity, Set<ClassEntity>> mixinUses;

  final Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses;

  // TODO(johnniwinther): Can this be derived from [ClassSet]s?
  final Set<ClassEntity> _implementedClasses;

  final Iterable<MemberEntity> liveInstanceMembers;

  /// Members that are written either directly or through a setter selector.
  final Iterable<MemberEntity> assignedInstanceMembers;
  final KAllocatorAnalysis allocatorAnalysis;

  final Iterable<ClassEntity> liveNativeClasses;

  final Iterable<MemberEntity> processedMembers;

  final ClassHierarchy classHierarchy;

  KClosedWorldImpl(this.elementMap,
      {CompilerOptions options,
      this.elementEnvironment,
      this.dartTypes,
      this.commonElements,
      this.nativeData,
      this.interceptorData,
      this.backendUsage,
      this.noSuchMethodData,
      ResolutionWorldBuilder resolutionWorldBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      this.allocatorAnalysis,
      Set<ClassEntity> implementedClasses,
      this.liveNativeClasses,
      this.liveInstanceMembers,
      this.assignedInstanceMembers,
      this.processedMembers,
      this.mixinUses,
      this.typesImplementedBySubclasses,
      Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes,
      Map<ClassEntity, ClassSet> classSets})
      : _implementedClasses = implementedClasses,
        classHierarchy = new ClassHierarchyImpl(
            commonElements, classHierarchyNodes, classSets) {
    computeRtiNeed(resolutionWorldBuilder, rtiNeedBuilder, options);
  }

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassEntity cls) {
    return _implementedClasses.contains(cls);
  }
}

class KernelNativeMemberResolver extends NativeMemberResolverBase {
  final KernelToElementMapForImpactImpl elementMap;
  final NativeBasicData nativeBasicData;
  final NativeDataBuilder nativeDataBuilder;

  KernelNativeMemberResolver(
      this.elementMap, this.nativeBasicData, this.nativeDataBuilder);

  @override
  ElementEnvironment get elementEnvironment => elementMap.elementEnvironment;

  @override
  CommonElements get commonElements => elementMap.commonElements;

  @override
  native.NativeBehavior computeNativeFieldStoreBehavior(
      covariant KField field) {
    ir.Field node = elementMap._members.getData(field).definition.node;
    return elementMap.getNativeBehaviorForFieldStore(node);
  }

  @override
  native.NativeBehavior computeNativeFieldLoadBehavior(covariant KField field,
      {bool isJsInterop}) {
    ir.Field node = elementMap._members.getData(field).definition.node;
    return elementMap.getNativeBehaviorForFieldLoad(node,
        isJsInterop: isJsInterop);
  }

  @override
  native.NativeBehavior computeNativeMethodBehavior(
      covariant KFunction function,
      {bool isJsInterop}) {
    ir.Member node = elementMap._members.getData(function).definition.node;
    return elementMap.getNativeBehaviorForMethod(node,
        isJsInterop: isJsInterop);
  }

  @override
  bool isNativeMethod(covariant KFunction function) {
    if (!native.maybeEnableNative(function.library.canonicalUri)) return false;
    ir.Member node = elementMap._members.getData(function).definition.node;
    return node.annotations.any((ir.Expression expression) {
      return expression is ir.ConstructorInvocation &&
          elementMap.getInterfaceType(expression.constructedType) ==
              commonElements.externalNameType;
    });
  }

  @override
  bool isJsInteropMember(MemberEntity element) {
    return nativeBasicData.isJsInteropMember(element);
  }
}

class JsToFrontendMapImpl extends JsToFrontendMapBase
    implements JsToFrontendMap {
  final KernelToElementMapBase _backend;

  JsToFrontendMapImpl(this._backend);

  LibraryEntity toBackendLibrary(covariant IndexedLibrary library) {
    return _backend._libraries.getEntity(library.libraryIndex);
  }

  ClassEntity toBackendClass(covariant IndexedClass cls) {
    return _backend._classes.getEntity(cls.classIndex);
  }

  MemberEntity toBackendMember(covariant IndexedMember member) {
    return _backend._members.getEntity(member.memberIndex);
  }

  TypedefEntity toBackendTypedef(covariant IndexedTypedef typedef) {
    return _backend._typedefs.getEntity(typedef.typedefIndex);
  }

  TypeVariableEntity toBackendTypeVariable(TypeVariableEntity typeVariable) {
    if (typeVariable is KLocalTypeVariable) {
      failedAt(
          typeVariable, "Local function type variables are not supported.");
    }
    IndexedTypeVariable indexedTypeVariable = typeVariable;
    return _backend._typeVariables
        .getEntity(indexedTypeVariable.typeVariableIndex);
  }
}

class JsKernelToElementMap extends KernelToElementMapBase
    with
        JsElementCreatorMixin,
        // TODO(johnniwinther): Avoid mixing in [ElementCreatorMixin]. The
        // codegen world should be a strict subset of the resolution world and
        // creating elements for IR nodes should therefore not be needed.
        // Currently some are created purely for testing (like
        // `element == commonElements.foo`, where 'foo' might not be live).
        // Others are created because we do a
        // `elementEnvironment.forEachLibraryMember(...)` call on each emitted
        // library.
        ElementCreatorMixin
    implements
        KernelToWorldBuilder,
        KernelToElementMapForBuilding {
  /// Map from members to the call methods created for their nested closures.
  Map<MemberEntity, List<FunctionEntity>> _nestedClosureMap =
      <MemberEntity, List<FunctionEntity>>{};

  NativeBasicData nativeBasicData;

  Map<FunctionEntity, JGeneratorBody> _generatorBodies =
      <FunctionEntity, JGeneratorBody>{};

  Map<ClassEntity, List<MemberEntity>> _injectedClassMembers =
      <ClassEntity, List<MemberEntity>>{};

  JsKernelToElementMap(
      DiagnosticReporter reporter,
      Environment environment,
      KernelToElementMapForImpactImpl _elementMap,
      Iterable<MemberEntity> liveMembers)
      : super(_elementMap.options, reporter, environment) {
    _env = _elementMap._env;
    for (int libraryIndex = 0;
        libraryIndex < _elementMap._libraries.length;
        libraryIndex++) {
      IndexedLibrary oldLibrary =
          _elementMap._libraries.getEntity(libraryIndex);
      LibraryEnv env = _elementMap._libraries.getEnv(oldLibrary);
      LibraryData data = _elementMap._libraries.getData(oldLibrary);
      IndexedLibrary newLibrary = convertLibrary(oldLibrary);
      _libraryMap[env.library] =
          _libraries.register<IndexedLibrary, LibraryData, LibraryEnv>(
              newLibrary, data.copy(), env.copyLive(_elementMap, liveMembers));
      assert(newLibrary.libraryIndex == oldLibrary.libraryIndex);
    }
    for (int classIndex = 0;
        classIndex < _elementMap._classes.length;
        classIndex++) {
      IndexedClass oldClass = _elementMap._classes.getEntity(classIndex);
      ClassEnv env = _elementMap._classes.getEnv(oldClass);
      ClassData data = _elementMap._classes.getData(oldClass);
      IndexedLibrary oldLibrary = oldClass.library;
      LibraryEntity newLibrary = _libraries.getEntity(oldLibrary.libraryIndex);
      IndexedClass newClass = convertClass(newLibrary, oldClass);
      _classMap[env.cls] = _classes.register(
          newClass, data.copy(), env.copyLive(_elementMap, liveMembers));
      assert(newClass.classIndex == oldClass.classIndex);
    }
    for (int typedefIndex = 0;
        typedefIndex < _elementMap._typedefs.length;
        typedefIndex++) {
      IndexedTypedef oldTypedef = _elementMap._typedefs.getEntity(typedefIndex);
      TypedefData data = _elementMap._typedefs.getData(oldTypedef);
      IndexedLibrary oldLibrary = oldTypedef.library;
      LibraryEntity newLibrary = _libraries.getEntity(oldLibrary.libraryIndex);
      IndexedTypedef newTypedef = convertTypedef(newLibrary, oldTypedef);
      _typedefMap[data.node] = _typedefs.register(
          newTypedef,
          new TypedefData(
              data.node,
              newTypedef,
              new TypedefType(
                  newTypedef,
                  new List<DartType>.filled(
                      data.node.typeParameters.length, const DynamicType()),
                  getDartType(data.node.type))));
      assert(newTypedef.typedefIndex == oldTypedef.typedefIndex);
    }
    for (int memberIndex = 0;
        memberIndex < _elementMap._members.length;
        memberIndex++) {
      IndexedMember oldMember = _elementMap._members.getEntity(memberIndex);
      if (!liveMembers.contains(oldMember)) {
        _members.skipIndex(oldMember.memberIndex);
        continue;
      }
      MemberDataImpl data = _elementMap._members.getData(oldMember);
      IndexedLibrary oldLibrary = oldMember.library;
      IndexedClass oldClass = oldMember.enclosingClass;
      LibraryEntity newLibrary = _libraries.getEntity(oldLibrary.libraryIndex);
      ClassEntity newClass =
          oldClass != null ? _classes.getEntity(oldClass.classIndex) : null;
      IndexedMember newMember = convertMember(newLibrary, newClass, oldMember);
      _members.register(newMember, data.copy());
      assert(newMember.memberIndex == oldMember.memberIndex);
      if (newMember.isField) {
        _fieldMap[data.node] = newMember;
      } else if (newMember.isConstructor) {
        _constructorMap[data.node] = newMember;
      } else {
        _methodMap[data.node] = newMember;
      }
    }
    for (int typeVariableIndex = 0;
        typeVariableIndex < _elementMap._typeVariables.length;
        typeVariableIndex++) {
      IndexedTypeVariable oldTypeVariable =
          _elementMap._typeVariables.getEntity(typeVariableIndex);
      TypeVariableData oldTypeVariableData =
          _elementMap._typeVariables.getData(oldTypeVariable);
      Entity newTypeDeclaration;
      if (oldTypeVariable.typeDeclaration is ClassEntity) {
        IndexedClass cls = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = _classes.getEntity(cls.classIndex);
      } else if (oldTypeVariable.typeDeclaration is MemberEntity) {
        IndexedMember member = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = _members.getEntity(member.memberIndex);
      } else {
        assert(oldTypeVariable.typeDeclaration is Local);
      }
      IndexedTypeVariable newTypeVariable = createTypeVariable(
          newTypeDeclaration, oldTypeVariable.name, oldTypeVariable.index);
      _typeVariables.register<IndexedTypeVariable, TypeVariableData>(
          newTypeVariable, oldTypeVariableData.copy());
      assert(newTypeVariable.typeVariableIndex ==
          oldTypeVariable.typeVariableIndex);
    }
    // TODO(johnniwinther): We should close the environment in the beginning of
    // this constructor but currently we need the [MemberEntity] to query if the
    // member is live, thus potentially creating the [MemberEntity] in the
    // process. Avoid this.
    _elementMap._envIsClosed = true;
  }

  @override
  Entity getClosure(ir.FunctionDeclaration node) {
    throw new UnsupportedError('JsKernelToElementMap.getClosure');
  }

  @override
  void _forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    assert(checkFamily(member));
    _nestedClosureMap[member]?.forEach(f);
  }

  InterfaceType getMemberThisType(MemberEntity member) {
    return _members.getData(member).getMemberThisType(this);
  }

  ClassTypeVariableAccess getClassTypeVariableAccessForMember(
      MemberEntity member) {
    return _members.getData(member).classTypeVariableAccess;
  }

  @override
  bool checkFamily(Entity entity) {
    assert(
        '$entity'.startsWith(jsElementPrefix),
        failedAt(entity,
            "Unexpected entity $entity, expected family $jsElementPrefix."));
    return true;
  }

  @override
  Spannable getSpannable(MemberEntity member, ir.Node node) {
    return _getSpannable(member, node);
  }

  Iterable<LibraryEntity> get _libraryList {
    return _libraryMap.values;
  }

  @override
  LibraryEntity _getLibrary(ir.Library node, [LibraryEnv env]) {
    LibraryEntity library = _libraryMap[node];
    assert(library != null, "No library entity for $node");
    return library;
  }

  @override
  ClassEntity _getClass(ir.Class node, [ClassEnv env]) {
    ClassEntity cls = _classMap[node];
    assert(cls != null, "No class entity for $node");
    return cls;
  }

  // TODO(johnniwinther): Reinsert these when [ElementCreatorMixin] is no longer
  // mixed in.
  /*@override
  FieldEntity _getField(ir.Field node) {
    FieldEntity field = _fieldMap[node];
    assert(field != null, "No field entity for $node");
    return field;
  }*/

  /*@override
  FunctionEntity _getMethod(ir.Procedure node) {
    FunctionEntity function = _methodMap[node];
    assert(function != null, "No function entity for $node");
    return function;
  }*/

  /*@override
  ConstructorEntity _getConstructor(ir.Member node) {
    ConstructorEntity constructor = _constructorMap[node];
    assert(constructor != null, "No constructor entity for $node");
    return constructor;
  }*/

  FunctionEntity getConstructorBody(ir.Constructor node) {
    ConstructorEntity constructor = getConstructor(node);
    return _getConstructorBody(node, constructor);
  }

  FunctionEntity _getConstructorBody(
      ir.Constructor node, covariant IndexedConstructor constructor) {
    ConstructorDataImpl data = _members.getData(constructor);
    if (data.constructorBody == null) {
      JConstructorBody constructorBody = createConstructorBody(constructor);
      _members.register<IndexedFunction, FunctionData>(
          constructorBody,
          new ConstructorBodyDataImpl(
              node,
              node.function,
              new SpecialMemberDefinition(
                  constructorBody, node, MemberKind.constructorBody)));
      IndexedClass cls = constructor.enclosingClass;
      ClassEnvImpl classEnv = _classes.getEnv(cls);
      // TODO(johnniwinther): Avoid this by only including live members in the
      // js-model.
      classEnv.addConstructorBody(constructorBody);
      data.constructorBody = constructorBody;
    }
    return data.constructorBody;
  }

  JConstructorBody createConstructorBody(ConstructorEntity constructor);

  @override
  MemberDefinition getMemberDefinition(MemberEntity member) {
    return _getMemberDefinition(member);
  }

  @override
  ClassDefinition getClassDefinition(ClassEntity cls) {
    return _getClassDefinition(cls);
  }

  @override
  ConstantValue getFieldConstantValue(covariant IndexedField field) {
    assert(checkFamily(field));
    FieldData data = _members.getData(field);
    return data.getFieldConstantValue(this);
  }

  bool hasConstantFieldInitializer(covariant IndexedField field) {
    FieldData data = _members.getData(field);
    return data.hasConstantFieldInitializer(this);
  }

  ConstantValue getConstantFieldInitializer(covariant IndexedField field) {
    FieldData data = _members.getData(field);
    return data.getConstantFieldInitializer(this);
  }

  void forEachParameter(covariant IndexedFunction function,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    FunctionData data = _members.getData(function);
    data.forEachParameter(this, f);
  }

  void _forEachConstructorBody(
      IndexedClass cls, void f(ConstructorBodyEntity member)) {
    ClassEnv env = _classes.getEnv(cls);
    env.forEachConstructorBody(f);
  }

  void _forEachInjectedClassMember(
      IndexedClass cls, void f(MemberEntity member)) {
    _injectedClassMembers[cls]?.forEach(f);
  }

  JRecordField _constructRecordFieldEntry(
      InterfaceType memberThisType,
      ir.VariableDeclaration variable,
      BoxLocal boxLocal,
      JClass container,
      Map<String, MemberEntity> memberMap,
      KernelToLocalsMap localsMap) {
    Local local = localsMap.getLocalVariable(variable);
    JRecordField boxedField =
        new JRecordField(local.name, boxLocal, container, variable.isConst);
    _members.register(
        boxedField,
        new ClosureFieldData(
            new ClosureMemberDefinition(
                boxedField,
                computeSourceSpanFromTreeNode(variable),
                MemberKind.closureField,
                variable),
            memberThisType));
    memberMap[boxedField.name] = boxedField;

    return boxedField;
  }

  /// Make a container controlling access to records, that is, variables that
  /// are accessed in different scopes. This function creates the container
  /// and returns a map of locals to the corresponding records created.
  Map<Local, JRecordField> makeRecordContainer(
      KernelScopeInfo info, MemberEntity member, KernelToLocalsMap localsMap) {
    Map<Local, JRecordField> boxedFields = {};
    if (info.boxedVariables.isNotEmpty) {
      NodeBox box = info.capturedVariablesAccessor;

      Map<String, MemberEntity> memberMap = <String, MemberEntity>{};
      JRecord container = new JRecord(member.library, box.name);
      InterfaceType thisType = new InterfaceType(container, const <DartType>[]);
      InterfaceType supertype = commonElements.objectType;
      ClassData containerData = new RecordClassData(
          new ClosureClassDefinition(container,
              computeSourceSpanFromTreeNode(getMemberDefinition(member).node)),
          thisType,
          supertype,
          getOrderedTypeSet(supertype.element).extendClass(thisType));
      _classes.register(container, containerData, new RecordEnv(memberMap));

      BoxLocal boxLocal = new BoxLocal(box.name);
      InterfaceType memberThisType = member.enclosingClass != null
          ? _elementEnvironment.getThisType(member.enclosingClass)
          : null;
      for (ir.VariableDeclaration variable in info.boxedVariables) {
        boxedFields[localsMap.getLocalVariable(variable)] =
            _constructRecordFieldEntry(memberThisType, variable, boxLocal,
                container, memberMap, localsMap);
      }
    }
    return boxedFields;
  }

  bool _isInRecord(
          Local local, Map<Local, JRecordField> recordFieldsVisibleInScope) =>
      recordFieldsVisibleInScope.containsKey(local);

  KernelClosureClassInfo constructClosureClass(
      MemberEntity member,
      ir.FunctionNode node,
      JLibrary enclosingLibrary,
      Map<Local, JRecordField> recordFieldsVisibleInScope,
      KernelScopeInfo info,
      KernelToLocalsMap localsMap,
      InterfaceType supertype,
      {bool createSignatureMethod}) {
    InterfaceType memberThisType = member.enclosingClass != null
        ? _elementEnvironment.getThisType(member.enclosingClass)
        : null;
    ClassTypeVariableAccess typeVariableAccess =
        _members.getData(member).classTypeVariableAccess;
    if (typeVariableAccess == ClassTypeVariableAccess.instanceField) {
      // A closure in a field initializer will only be executed in the
      // constructor and type variables are therefore accessed through
      // parameters.
      typeVariableAccess = ClassTypeVariableAccess.parameter;
    }
    String name = _computeClosureName(node);
    SourceSpan location = computeSourceSpanFromTreeNode(node);
    Map<String, MemberEntity> memberMap = <String, MemberEntity>{};

    JClass classEntity = new JClosureClass(enclosingLibrary, name);
    // Create a classData and set up the interfaces and subclass
    // relationships that _ensureSupertypes and _ensureThisAndRawType are doing
    InterfaceType thisType = new InterfaceType(classEntity, const <DartType>[]);
    ClosureClassData closureData = new ClosureClassData(
        new ClosureClassDefinition(classEntity, location),
        thisType,
        supertype,
        getOrderedTypeSet(supertype.element).extendClass(thisType));
    _classes.register(classEntity, closureData, new ClosureClassEnv(memberMap));

    Local closureEntity;
    if (node.parent is ir.FunctionDeclaration) {
      ir.FunctionDeclaration parent = node.parent;
      closureEntity = localsMap.getLocalVariable(parent.variable);
    } else if (node.parent is ir.FunctionExpression) {
      closureEntity = new JLocal('', localsMap.currentMember);
    }

    FunctionEntity callMethod = new JClosureCallMethod(
        classEntity, _getParameterStructure(node), getAsyncMarker(node));
    _nestedClosureMap
        .putIfAbsent(member, () => <FunctionEntity>[])
        .add(callMethod);
    // We need create the type variable here - before we try to make local
    // variables from them (in `JsScopeInfo.from` called through
    // `KernelClosureClassInfo.fromScopeInfo` below).
    int index = 0;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      _typeVariableMap[typeParameter] = _typeVariables.register(
          createTypeVariable(callMethod, typeParameter.name, index),
          new TypeVariableData(typeParameter));
      index++;
    }

    KernelClosureClassInfo closureClassInfo =
        new KernelClosureClassInfo.fromScopeInfo(
            classEntity,
            node,
            <Local, JRecordField>{},
            info,
            localsMap,
            closureEntity,
            info.hasThisLocal ? new ThisLocal(localsMap.currentMember) : null,
            this);
    _buildClosureClassFields(closureClassInfo, member, memberThisType, info,
        localsMap, recordFieldsVisibleInScope, memberMap);

    if (createSignatureMethod) {
      _constructSignatureMethod(closureClassInfo, memberMap, node,
          memberThisType, location, typeVariableAccess);
    }

    closureData.callType = getFunctionType(node);

    _members.register<IndexedFunction, FunctionData>(
        callMethod,
        new ClosureFunctionData(
            new ClosureMemberDefinition(
                callMethod, location, MemberKind.closureCall, node.parent),
            memberThisType,
            closureData.callType,
            node,
            typeVariableAccess));
    memberMap[callMethod.name] = closureClassInfo.callMethod = callMethod;
    return closureClassInfo;
  }

  void _buildClosureClassFields(
      KernelClosureClassInfo closureClassInfo,
      MemberEntity member,
      InterfaceType memberThisType,
      KernelScopeInfo info,
      KernelToLocalsMap localsMap,
      Map<Local, JRecordField> recordFieldsVisibleInScope,
      Map<String, MemberEntity> memberMap) {
    // TODO(efortuna): Limit field number usage to when we need to distinguish
    // between two variables with the same name from different scopes.
    int fieldNumber = 0;

    // For the captured variables that are boxed, ensure this closure has a
    // field to reference the box. This puts the boxes first in the closure like
    // the AST front-end, but otherwise there is no reason to separate this loop
    // from the one below.
    // TODO(redemption): Merge this loop and the following.

    for (ir.Node variable in info.freeVariables) {
      if (variable is ir.VariableDeclaration) {
        Local capturedLocal = localsMap.getLocalVariable(variable);
        if (_isInRecord(capturedLocal, recordFieldsVisibleInScope)) {
          bool constructedField = _constructClosureFieldForRecord(
              capturedLocal,
              closureClassInfo,
              memberThisType,
              memberMap,
              variable,
              recordFieldsVisibleInScope,
              fieldNumber);
          if (constructedField) fieldNumber++;
        }
      }
    }

    // Add a field for the captured 'this'.
    if (info.thisUsedAsFreeVariable) {
      _constructClosureField(
          closureClassInfo.thisLocal,
          closureClassInfo,
          memberThisType,
          memberMap,
          getClassDefinition(member.enclosingClass).node,
          true,
          false,
          fieldNumber);
      fieldNumber++;
    }

    for (ir.Node variable in info.freeVariables) {
      // Make a corresponding field entity in this closure class for the
      // free variables in the KernelScopeInfo.freeVariable.
      if (variable is ir.VariableDeclaration) {
        Local capturedLocal = localsMap.getLocalVariable(variable);
        if (!_isInRecord(capturedLocal, recordFieldsVisibleInScope)) {
          _constructClosureField(
              capturedLocal,
              closureClassInfo,
              memberThisType,
              memberMap,
              variable,
              variable.isConst,
              false, // Closure field is never assigned (only box fields).
              fieldNumber);
          fieldNumber++;
        }
      } else if (variable is TypeVariableTypeWithContext) {
        _constructClosureField(
            localsMap.getLocalTypeVariable(variable.type, this),
            closureClassInfo,
            memberThisType,
            memberMap,
            variable.type.parameter,
            true,
            false,
            fieldNumber);
        fieldNumber++;
      } else {
        throw new UnsupportedError("Unexpected field node type: $variable");
      }
    }
  }

  /// Records point to one or more local variables declared in another scope
  /// that are captured in a scope. Access to those variables goes entirely
  /// through the record container, so we only create a field for the *record*
  /// holding [capturedLocal] and not the individual local variables accessed
  /// through the record. Records, by definition, are not mutable (though the
  /// locals they contain may be). Returns `true` if we constructed a new field
  /// in the closure class.
  bool _constructClosureFieldForRecord(
      Local capturedLocal,
      KernelClosureClassInfo closureClassInfo,
      InterfaceType memberThisType,
      Map<String, MemberEntity> memberMap,
      ir.TreeNode sourceNode,
      Map<Local, JRecordField> recordFieldsVisibleInScope,
      int fieldNumber) {
    JRecordField recordField = recordFieldsVisibleInScope[capturedLocal];

    // Don't construct a new field if the box that holds this local already has
    // a field in the closure class.
    if (closureClassInfo.localToFieldMap.containsKey(recordField.box)) {
      closureClassInfo.boxedVariables[capturedLocal] = recordField;
      return false;
    }

    FieldEntity closureField = new JClosureField(
        '_box_$fieldNumber', closureClassInfo, true, false, recordField.box);

    _members.register<IndexedField, FieldData>(
        closureField,
        new ClosureFieldData(
            new ClosureMemberDefinition(
                closureClassInfo.localToFieldMap[capturedLocal],
                computeSourceSpanFromTreeNode(sourceNode),
                MemberKind.closureField,
                sourceNode),
            memberThisType));
    memberMap[closureField.name] = closureField;
    closureClassInfo.localToFieldMap[recordField.box] = closureField;
    closureClassInfo.boxedVariables[capturedLocal] = recordField;
    return true;
  }

  void _constructSignatureMethod(
      KernelClosureClassInfo closureClassInfo,
      Map<String, MemberEntity> memberMap,
      ir.FunctionNode closureSourceNode,
      InterfaceType memberThisType,
      SourceSpan location,
      ClassTypeVariableAccess typeVariableAccess) {
    FunctionEntity signatureMethod = new JSignatureMethod(
        closureClassInfo.closureClassEntity.library,
        closureClassInfo.closureClassEntity,
        // SignatureMethod takes no arguments.
        const ParameterStructure(0, 0, const [], 0),
        AsyncMarker.SYNC);
    _members.register<IndexedFunction, FunctionData>(
        signatureMethod,
        new SignatureFunctionData(
            new SpecialMemberDefinition(signatureMethod,
                closureSourceNode.parent, MemberKind.signature),
            memberThisType,
            null,
            closureSourceNode.typeParameters,
            typeVariableAccess));
    memberMap[signatureMethod.name] =
        closureClassInfo.signatureMethod = signatureMethod;
  }

  _constructClosureField(
      Local capturedLocal,
      KernelClosureClassInfo closureClassInfo,
      InterfaceType memberThisType,
      Map<String, MemberEntity> memberMap,
      ir.TreeNode sourceNode,
      bool isConst,
      bool isAssignable,
      int fieldNumber) {
    FieldEntity closureField = new JClosureField(
        _getClosureVariableName(capturedLocal.name, fieldNumber),
        closureClassInfo,
        isConst,
        isAssignable,
        capturedLocal);

    _members.register<IndexedField, FieldData>(
        closureField,
        new ClosureFieldData(
            new ClosureMemberDefinition(
                closureClassInfo.localToFieldMap[capturedLocal],
                computeSourceSpanFromTreeNode(sourceNode),
                MemberKind.closureField,
                sourceNode),
            memberThisType));
    memberMap[closureField.name] = closureField;
    closureClassInfo.localToFieldMap[capturedLocal] = closureField;
  }

  // Returns a non-unique name for the given closure element.
  String _computeClosureName(ir.TreeNode treeNode) {
    var parts = <String>[];
    // First anonymous is called 'closure', outer ones called '' to give a
    // compound name where increasing nesting level corresponds to extra
    // underscores.
    var anonymous = 'closure';
    ir.TreeNode current = treeNode;
    // TODO(johnniwinther): Simplify computed names.
    while (current != null) {
      var node = current;
      if (node is ir.FunctionExpression) {
        parts.add(anonymous);
        anonymous = '';
      } else if (node is ir.FunctionDeclaration) {
        String name = node.variable.name;
        if (name != null && name != "") {
          parts.add(utils.operatorNameToIdentifier(name));
        } else {
          parts.add(anonymous);
          anonymous = '';
        }
      } else if (node is ir.Class) {
        // TODO(sra): Do something with abstracted mixin type names like '^#U0'.
        parts.add(node.name);
        break;
      } else if (node is ir.Procedure) {
        if (node.kind == ir.ProcedureKind.Factory) {
          parts.add(utils.reconstructConstructorName(getMember(node)));
        } else {
          parts.add(utils.operatorNameToIdentifier(node.name.name));
        }
      } else if (node is ir.Constructor) {
        parts.add(utils.reconstructConstructorName(getMember(node)));
        break;
      }
      current = current.parent;
    }
    return parts.reversed.join('_');
  }

  /// Generate a unique name for the [id]th closure field, with proposed name
  /// [name].
  ///
  /// The result is used as the name of [ClosureFieldElement]s, and must
  /// therefore be unique to avoid breaking an invariant in the element model
  /// (classes cannot declare multiple fields with the same name).
  ///
  /// Also, the names should be distinct from real field names to prevent
  /// clashes with selectors for those fields.
  ///
  /// These names are not used in generated code, just as element name.
  String _getClosureVariableName(String name, int id) {
    return "_captured_${name}_$id";
  }

  JGeneratorBody getGeneratorBody(covariant IndexedFunction function) {
    JGeneratorBody generatorBody = _generatorBodies[function];
    if (generatorBody == null) {
      FunctionData functionData = _members.getData(function);
      ir.TreeNode node = functionData.definition.node;
      DartType elementType =
          _elementEnvironment.getFunctionAsyncOrSyncStarElementType(function);
      generatorBody = createGeneratorBody(function, elementType);
      _members.register<IndexedFunction, FunctionData>(
          generatorBody,
          new GeneratorBodyFunctionData(
              functionData,
              new SpecialMemberDefinition(
                  generatorBody, node, MemberKind.generatorBody)));

      if (function.enclosingClass != null) {
        // TODO(sra): Integrate this with ClassEnvImpl.addConstructorBody ?
        (_injectedClassMembers[function.enclosingClass] ??= <MemberEntity>[])
            .add(generatorBody);
      }
    }
    return generatorBody;
  }

  JGeneratorBody createGeneratorBody(
      FunctionEntity function, DartType elementType);

  js.Template getJsBuiltinTemplate(
      ConstantValue constant, CodeEmitterTask emitter) {
    int index = _extractEnumIndexFromConstantValue(
        constant, commonElements.jsBuiltinEnum);
    if (index == null) return null;
    return emitter.builtinTemplateFor(JsBuiltin.values[index]);
  }
}

class KernelClassQueries extends ClassQueries {
  final KernelToElementMapForImpactImpl elementMap;

  KernelClassQueries(this.elementMap);

  @override
  ClassEntity getDeclaration(ClassEntity cls) {
    return cls;
  }

  @override
  Iterable<InterfaceType> getSupertypes(ClassEntity cls) {
    return elementMap.getOrderedTypeSet(cls).supertypes;
  }

  @override
  ClassEntity getSuperClass(ClassEntity cls) {
    return elementMap.getSuperType(cls)?.element;
  }

  @override
  bool implementsFunction(ClassEntity cls) {
    return elementMap._implementsFunction(cls);
  }

  @override
  int getHierarchyDepth(ClassEntity cls) {
    return elementMap.getHierarchyDepth(cls);
  }

  @override
  ClassEntity getAppliedMixin(ClassEntity cls) {
    return elementMap.getAppliedMixin(cls);
  }
}
