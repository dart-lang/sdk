// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.element_map;

import 'package:kernel/ast.dart' as ir;

import '../closure.dart' show BoxLocal, ThisLocal;
import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common/resolution.dart';
import '../common_elements.dart';
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/constructors.dart';
import '../constants/evaluation.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/elements.dart';
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/names.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../frontend_strategy.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/constant_system_javascript.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../js_model/closure.dart';
import '../js_model/elements.dart';
import '../js_model/locals.dart';
import '../native/enqueue.dart';
import '../native/native.dart' as native;
import '../native/resolver.dart';
import '../options.dart';
import '../ordered_typeset.dart';
import '../ssa/kernel_impact.dart';
import '../ssa/type_builder.dart';
import '../universe/class_hierarchy_builder.dart';
import '../universe/class_set.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../util/util.dart' show Link, LinkBuilder;
import '../world.dart';
import 'element_map.dart';
import 'element_map_mixins.dart';
import 'env.dart';
import 'indexed.dart';
import 'kelements.dart';

part 'native_basic_data.dart';
part 'no_such_method_resolver.dart';
part 'types.dart';

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

abstract class KernelToElementMapBase extends KernelToElementMapBaseMixin {
  final CompilerOptions options;
  final DiagnosticReporter reporter;
  CommonElements _commonElements;
  ElementEnvironment _elementEnvironment;
  DartTypeConverter _typeConverter;
  KernelConstantEnvironment _constantEnvironment;
  _KernelDartTypes _types;

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
    _types = new _KernelDartTypes(this);
  }

  bool checkFamily(Entity entity);

  DartTypes get types => _types;

  @override
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

  InterfaceType _getSuperType(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.supertype;
  }

  void _ensureThisAndRawType(ClassEntity cls, ClassData data) {
    assert(checkFamily(cls));
    if (data.thisType == null) {
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
    if (data.orderedTypeSet == null) {
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
        Link<InterfaceType> interfaces = linkBuilder.toLink();
        OrderedTypeSetBuilder setBuilder =
            new _KernelOrderedTypeSetBuilder(this, cls);
        data.orderedTypeSet = setBuilder.createOrderedTypeSet(
            data.supertype, interfaces.reverse());
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
    if (target != null) {
      return getMember(target);
    }
    ClassEntity cls = context.enclosingClass;
    IndexedClass superclass = _getSuperType(cls)?.element;
    while (superclass != null) {
      ClassEnv env = _classes.getEnv(superclass);
      MemberEntity superMember =
          env.lookupMember(this, name.name, setter: setter);
      if (superMember != null && !superMember.isAbstract) {
        return superMember;
      }
      superclass = _getSuperType(superclass)?.element;
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
    IndexedClass superClass = _getSuperType(sourceClass)?.element;
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
    for (ir.VariableDeclaration variable in node.positionalParameters) {
      if (parameterTypes.length == node.requiredParameterCount) {
        optionalParameterTypes.add(getDartType(variable.type));
      } else {
        parameterTypes.add(getDartType(variable.type));
      }
    }
    List<String> namedParameters = <String>[];
    List<DartType> namedParameterTypes = <DartType>[];
    List<ir.VariableDeclaration> sortedNamedParameters =
        node.namedParameters.toList()..sort((a, b) => a.name.compareTo(b.name));
    for (ir.VariableDeclaration variable in sortedNamedParameters) {
      namedParameters.add(variable.name);
      namedParameterTypes.add(getDartType(variable.type));
    }
    List<FunctionTypeVariable> typeVariables;
    if (node.typeParameters.isNotEmpty && options.strongMode) {
      List<DartType> typeParameters = <DartType>[];
      for (ir.TypeParameter typeParameter in node.typeParameters) {
        typeParameters
            .add(getDartType(new ir.TypeParameterType(typeParameter)));
      }
      typeVariables = new List<FunctionTypeVariable>.generate(
          node.typeParameters.length,
          (int index) => new FunctionTypeVariable(
              index, getDartType(node.typeParameters[index].bound)));

      DartType subst(DartType type) {
        return type.subst(typeVariables, typeParameters);
      }

      parameterTypes = parameterTypes.map(subst).toList();
      optionalParameterTypes = optionalParameterTypes.map(subst).toList();
      namedParameterTypes = namedParameterTypes.map(subst).toList();
    } else {
      typeVariables = const <FunctionTypeVariable>[];
    }

    return new FunctionType(returnType, parameterTypes, optionalParameterTypes,
        namedParameters, namedParameterTypes, typeVariables, null);
  }

  @override
  ConstantValue computeConstantValue(
      Spannable spannable, ConstantExpression constant,
      {bool requireConstant: true}) {
    return _constantEnvironment._getConstantValue(spannable, constant,
        constantRequired: requireConstant);
  }

  DartType _substByContext(DartType type, InterfaceType context) {
    return type.subst(
        context.typeArguments, _getThisType(context.element).typeArguments);
  }

  // TODO(johnniwinther): Remove this when call-type is provided by fasta.
  void _ensureCallType(IndexedClass cls, ClassData data) {
    if (!data.isCallTypeComputed) {
      data.isCallTypeComputed = true;
      MemberEntity callMethod = lookupClassMember(cls, Identifiers.call);
      if (callMethod != null) {
        if (callMethod.isFunction) {
          data.callType = _getFunctionType(callMethod);
        } else {
          data.callType = const DynamicType();
        }
        return;
      }

      Set<FunctionType> inheritedCallTypes = new Set<FunctionType>();
      bool inheritsInvalidCallMember = false;

      void addCallType(InterfaceType supertype) {
        if (supertype == null) return;
        DartType type = _getCallType(supertype);
        if (type == null) return;
        if (type.isFunctionType) {
          inheritedCallTypes.add(type);
        } else {
          inheritsInvalidCallMember = true;
        }
      }

      addCallType(_getSuperType(cls));
      _getInterfaces(cls).forEach(addCallType);

      // Following §11.1.1 in the spec.
      if (inheritsInvalidCallMember) {
        // From §11.1.1 in the spec (continued):
        //
        // If some but not all of the m_i, 1 ≤ i ≤ k are getters none of the m_i
        // are inherited, and a static warning is issued.
        data.callType = const DynamicType();
      } else if (inheritedCallTypes.isEmpty) {
        return;
      } else if (inheritedCallTypes.length == 1) {
        data.callType = inheritedCallTypes.single;
      } else {
        // From §11.1.1 in the spec (continued):
        //
        // Otherwise, if the static types T_1, ... , T_k of the members
        // m_1, ..., m_k are not identical, then there must be a member m_x such
        // that T_x <: T_i, 1 ≤ x ≤ k for all i ∈ 1..k, or a static type warning
        // occurs.
        List<FunctionType> subtypesOfAllInherited = <FunctionType>[];
        outer:
        for (FunctionType a in inheritedCallTypes) {
          for (FunctionType b in inheritedCallTypes) {
            if (identical(a, b)) continue;
            if (!types.isSubtype(a, b)) continue outer;
          }
          subtypesOfAllInherited.add(a);
        }
        if (subtypesOfAllInherited.length == 1) {
          // From §11.1.1 in the spec (continued):
          //
          // The member that is inherited is m_x, if it exists.
          data.callType = subtypesOfAllInherited.single;
          return;
        }

        // From §11.1.1 in the spec (continued):
        //
        // Otherwise: let numberOfPositionals(f) denote the number of
        // positional parameters of a function f, and let
        // numberOfRequiredParams(f) denote the number of required parameters of
        // a function f. Furthermore, let s denote the set of all named
        // parameters of the m_1, . . . , m_k. Then let
        //
        //     h = max(numberOfPositionals(mi)),
        //     r = min(numberOfRequiredParams(mi)), i ∈ 1..k.

        // Then I has a method named n, with r required parameters of type
        // dynamic, h positional parameters of type dynamic, named parameters s
        // of type dynamic and return type dynamic.

        // Multiple signatures with different types => create the synthesized
        // version.
        int minRequiredParameters;
        int maxPositionalParameters;
        Set<String> names = new Set<String>();
        for (FunctionType type in inheritedCallTypes) {
          type.namedParameters.forEach((String name) => names.add(name));
          int requiredParameters = type.parameterTypes.length;
          int optionalParameters = type.optionalParameterTypes.length;
          int positionalParameters = requiredParameters + optionalParameters;
          if (minRequiredParameters == null ||
              minRequiredParameters > requiredParameters) {
            minRequiredParameters = requiredParameters;
          }
          if (maxPositionalParameters == null ||
              maxPositionalParameters < positionalParameters) {
            maxPositionalParameters = positionalParameters;
          }
        }
        int optionalParameters =
            maxPositionalParameters - minRequiredParameters;
        // TODO(johnniwinther): Support function types with both optional
        // and named parameters?
        if (optionalParameters == 0 || names.isEmpty) {
          DartType dynamic = const DynamicType();
          List<DartType> requiredParameterTypes =
              new List.filled(minRequiredParameters, dynamic);
          List<DartType> optionalParameterTypes =
              new List.filled(optionalParameters, dynamic);
          List<String> namedParameters = names.toList()
            ..sort((a, b) => a.compareTo(b));
          List<DartType> namedParameterTypes =
              new List.filled(namedParameters.length, dynamic);
          data.callType = new FunctionType(
              dynamic,
              requiredParameterTypes,
              optionalParameterTypes,
              namedParameters,
              namedParameterTypes,
              // TODO(johnniwinther): Generate existential types here.
              const <FunctionTypeVariable>[],
              null);
        } else {
          // The function type is not valid.
          data.callType = const DynamicType();
        }
      }
    }
  }

  /// Returns the type of the `call` method on 'type'.
  ///
  /// If [type] doesn't have a `call` member `null` is returned. If [type] has
  /// an invalid `call` member (non-method or a synthesized method with both
  /// optional and named parameters) a [DynamicType] is returned.
  DartType _getCallType(InterfaceType type) {
    IndexedClass cls = type.element;
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureCallType(cls, data);
    if (data.callType != null) {
      return _substByContext(data.callType, type);
    }
    return null;
  }

  InterfaceType _getThisType(IndexedClass cls) {
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

  DartType _getTypeVariableBound(IndexedTypeVariable typeVariable) {
    assert(checkFamily(typeVariable));
    TypeVariableData data = _typeVariables.getData(typeVariable);
    return data.getBound(this);
  }

  ClassEntity _getAppliedMixin(IndexedClass cls) {
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

  InterfaceType _asInstanceOf(InterfaceType type, ClassEntity cls) {
    assert(checkFamily(cls));
    OrderedTypeSet orderedTypeSet = _getOrderedTypeSet(type.element);
    InterfaceType supertype =
        orderedTypeSet.asInstanceOf(cls, _getHierarchyDepth(cls));
    if (supertype != null) {
      supertype = _substByContext(supertype, type);
    }
    return supertype;
  }

  OrderedTypeSet _getOrderedTypeSet(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet;
  }

  int _getHierarchyDepth(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet.maxDepth;
  }

  Iterable<InterfaceType> _getInterfaces(IndexedClass cls) {
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

  @override
  ImportEntity getImport(ir.LibraryDependency node) {
    ir.Library library = node.parent;
    LibraryData data = _libraries.getData(_getLibrary(library));
    return data.imports[node];
  }
}

/// Mixin that implements the abstract methods in [KernelToElementMapBase].
abstract class ElementCreatorMixin implements KernelToElementMapBase {
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
    return _libraryMap.putIfAbsent(node, () {
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
    });
  }

  ClassEntity _getClass(ir.Class node, [ClassEnv classEnv]) {
    return _classMap.putIfAbsent(node, () {
      KLibrary library = _getLibrary(node.enclosingLibrary);
      if (classEnv == null) {
        classEnv = _libraries.getEnv(library).lookupClass(node.name);
      }
      IndexedClass cls =
          createClass(library, node.name, isAbstract: node.isAbstract);
      return _classes.register(cls,
          new ClassData(node, new RegularClassDefinition(cls, node)), classEnv);
    });
  }

  TypedefEntity _getTypedef(ir.Typedef node) {
    return _typedefMap.putIfAbsent(node, () {
      IndexedLibrary library = _getLibrary(node.enclosingLibrary);
      IndexedTypedef typedef = createTypedef(library, node.name);
      TypedefType typedefType = new TypedefType(
          typedef,
          new List<DartType>.filled(
              node.typeParameters.length, const DynamicType()));
      return _typedefs.register(
          typedef, new TypedefData(node, typedef, typedefType));
    });
  }

  TypeVariableEntity _getTypeVariable(ir.TypeParameter node) {
    return _typeVariableMap.putIfAbsent(node, () {
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
        }
      }
      throw new UnsupportedError('Unsupported type parameter type node $node.');
    });
  }

  ConstructorEntity _getConstructor(ir.Member node) {
    return _constructorMap.putIfAbsent(node, () {
      MemberDefinition definition;
      ir.FunctionNode functionNode;
      ClassEntity enclosingClass = _getClass(node.enclosingClass);
      Name name = getName(node.name);
      bool isExternal = node.isExternal;

      IndexedConstructor constructor;
      if (node is ir.Constructor) {
        functionNode = node.function;
        constructor = createGenerativeConstructor(
            enclosingClass, name, _getParameterStructure(functionNode),
            isExternal: isExternal, isConst: node.isConst);
        definition = new SpecialMemberDefinition(
            constructor, node, MemberKind.constructor);
      } else if (node is ir.Procedure) {
        functionNode = node.function;
        bool isFromEnvironment = isExternal &&
            name.text == 'fromEnvironment' &&
            const ['int', 'bool', 'String'].contains(enclosingClass.name);
        constructor = createFactoryConstructor(
            enclosingClass, name, _getParameterStructure(functionNode),
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
    });
  }

  FunctionEntity _getMethod(ir.Procedure node) {
    return _methodMap.putIfAbsent(node, () {
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
              isStatic: isStatic,
              isExternal: isExternal,
              isAbstract: isAbstract);
          break;
        case ir.ProcedureKind.Method:
        case ir.ProcedureKind.Operator:
          function = createMethod(library, enclosingClass, name,
              _getParameterStructure(node.function), asyncMarker,
              isStatic: isStatic,
              isExternal: isExternal,
              isAbstract: isAbstract);
          break;
        case ir.ProcedureKind.Setter:
          assert(asyncMarker == AsyncMarker.SYNC);
          function = createSetter(library, enclosingClass, name.setter,
              isStatic: isStatic,
              isExternal: isExternal,
              isAbstract: isAbstract);
          break;
      }
      return _members.register<IndexedFunction, FunctionData>(
          function,
          new FunctionDataImpl(node, node.function,
              new RegularMemberDefinition(function, node)));
    });
  }

  FieldEntity _getField(ir.Field node) {
    return _fieldMap.putIfAbsent(node, () {
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
    });
  }

  ParameterStructure _getParameterStructure(ir.FunctionNode node) {
    // TODO(johnniwinther): Cache the computed function type.
    int requiredParameters = node.requiredParameterCount;
    int positionalParameters = node.positionalParameters.length;
    int typeParameters = node.typeParameters.length;
    List<String> namedParameters =
        node.namedParameters.map((p) => p.name).toList()..sort();
    return new ParameterStructure(requiredParameters, positionalParameters,
        namedParameters, options.strongMode ? typeParameters : 0);
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

/// Completes the [ElementCreatorMixin] by creating K-model elements.
abstract class KElementCreatorMixin implements ElementCreatorMixin {
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

/// Implementation of [KernelToElementMapForImpact] that only supports world
/// impact computation.
class KernelToElementMapForImpactImpl extends KernelToElementMapBase
    with
        KernelToElementMapForImpactMixin,
        ElementCreatorMixin,
        KElementCreatorMixin {
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

  DartType _getTypeVariableBound(TypeVariableEntity typeVariable) {
    if (typeVariable is KLocalTypeVariable) return typeVariable.bound;
    return super._getTypeVariableBound(typeVariable);
  }

  @override
  void _forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    throw new UnsupportedError(
        "KernelToElementMapForImpactImpl._forEachNestedClosure");
  }

  @override
  NativeBasicData get nativeBasicData => _frontendStrategy.nativeBasicData;

  /// Adds libraries in [program] to the set of libraries.
  ///
  /// The main method of the first program is used as the main method for the
  /// compilation.
  void addProgram(ir.Program program) {
    _env.addProgram(program);
  }

  @override
  native.BehaviorBuilder get nativeBehaviorBuilder =>
      _nativeBehaviorBuilder ??= new KernelBehaviorBuilder(elementEnvironment,
          commonElements, nativeBasicData, reporter, options);

  ResolutionImpact computeWorldImpact(KMember member) {
    return buildKernelImpact(
        _members.getData(member).definition.node, this, reporter, options);
  }

  ScopeModel computeScopeModel(KMember member) {
    ir.Member node = _members.getData(member).definition.node;
    return KernelClosureAnalysis.computeScopeModel(member, node, options);
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
      for (ir.TypeParameter typeParameter in function.typeParameters) {
        KLocalTypeVariable typeVariable = _typeVariableMap[typeParameter] =
            new KLocalTypeVariable(localFunction, typeParameter.name, index);
        typeVariable.bound = getDartType(typeParameter.bound);
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
        _getHierarchyDepth(commonElements.functionClass));
    if (supertype != null) {
      return true;
    }
    _ensureCallType(cls, data);
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
    return elementMap._getThisType(cls);
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
  ClassEntity getEffectiveMixinClass(ClassEntity cls) {
    if (!isMixinApplication(cls)) return null;
    do {
      cls = elementMap._getAppliedMixin(cls);
    } while (isMixinApplication(cls));
    return cls;
  }

  @override
  DartType getTypeVariableBound(TypeVariableEntity typeVariable) {
    return elementMap._getTypeVariableBound(typeVariable);
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
    ClassEntity superclass = elementMap._getSuperType(cls)?.element;
    if (skipUnnamedMixinApplications) {
      while (superclass != null &&
          elementMap._isUnnamedMixinApplication(superclass)) {
        superclass = elementMap._getSuperType(superclass)?.element;
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
  Iterable<ConstantValue> getTypedefMetadata(TypedefEntity typedef) {
    // TODO(redemption): Support this.
    throw new UnsupportedError('ElementEnvironment.getTypedefMetadata');
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
  FunctionType getFunctionTypeOfTypedef(TypedefEntity typedef) {
    // TODO(redemption): Support this.
    throw new UnsupportedError('ElementEnvironment.getFunctionTypeOfTypedef');
  }

  @override
  TypedefType getTypedefTypeOfTypedef(TypedefEntity typedef) {
    return elementMap._typedefs.getData(typedef).rawType;
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
    if (node.parameter.parent is ir.FunctionNode &&
        node.parameter.parent.parent is ir.Procedure) {
      // Special case for Dart 1 compatibility in checked mode.
      ir.Procedure typeParameterParent = node.parameter.parent.parent;
      if (typeParameterParent.kind != ir.ProcedureKind.Factory &&
          !elementMap.options.strongMode) {
        return new Dart1MethodTypeVariableType(
            elementMap.getTypeVariable(node.parameter));
      }
    }
    return new TypeVariableType(elementMap.getTypeVariable(node.parameter));
  }

  @override
  DartType visitFunctionType(ir.FunctionType node) {
    int index = 0;
    List<FunctionTypeVariable> typeVariables;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      if (elementMap.options.strongMode) {
        // TODO(johnniwinther): Support recursive type variable bounds, like
        // `void Function<T extends Foo<T>>(T t)` when #31531 is fixed.
        DartType bound = typeParameter.bound.accept(this);
        FunctionTypeVariable typeVariable =
            new FunctionTypeVariable(index, bound);
        currentFunctionTypeParameters[typeParameter] = typeVariable;
        typeVariables ??= <FunctionTypeVariable>[];
        typeVariables.add(typeVariable);
      } else {
        currentFunctionTypeParameters[typeParameter] = const DynamicType();
      }
      index++;
    }

    DartType typedefType =
        node.typedef == null ? null : elementMap.getTypedefType(node.typedef);

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
        typeVariables ?? const <FunctionTypeVariable>[],
        typedefType);
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      currentFunctionTypeParameters.remove(typeParameter);
    }
    return type;
  }

  @override
  DartType visitInterfaceType(ir.InterfaceType node) {
    ClassEntity cls = elementMap.getClass(node.classNode);
    // TODO(johnniwinther): We currently encode 'FutureOr' as a dynamic type.
    // Update the subtyping implementations to handle 'FutureOr' correctly.
    if (cls.name == 'FutureOr' &&
        cls.library == elementMap.commonElements.asyncLibrary) {
      return const DynamicType();
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
  ConstantSystem get constantSystem => const JavaScriptConstantSystem();

  @override
  ConstantValue getConstantValueForVariable(VariableElement element) {
    throw new UnimplementedError(
        "KernelConstantEnvironment.getConstantValueForVariable");
  }

  @override
  ConstantValue getConstantValue(ConstantExpression expression) {
    return _getConstantValue(CURRENT_ELEMENT_SPANNABLE, expression,
        constantRequired: true);
  }

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

  @override
  bool hasConstantValue(ConstantExpression expression) {
    throw new UnimplementedError("KernelConstantEnvironment.hasConstantValue");
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
  InterfaceType substByContext(InterfaceType base, InterfaceType target) {
    return _elementMap._substByContext(base, target);
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
}

class KernelResolutionWorldBuilder extends KernelResolutionWorldBuilderBase {
  final KernelToElementMapForImpactImpl elementMap;

  KernelResolutionWorldBuilder(
      CompilerOptions options,
      this.elementMap,
      NativeBasicData nativeBasicData,
      NativeDataBuilder nativeDataBuilder,
      InterceptorDataBuilder interceptorDataBuilder,
      BackendUsageBuilder backendUsageBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      NativeResolutionEnqueuer nativeResolutionEnqueuer,
      NoSuchMethodRegistry noSuchMethodRegistry,
      SelectorConstraintsStrategy selectorConstraintsStrategy,
      ClassHierarchyBuilder classHierarchyBuilder,
      ClassQueries classQueries)
      : super(
            options,
            elementMap.elementEnvironment,
            elementMap.types,
            elementMap.commonElements,
            elementMap._constantEnvironment.constantSystem,
            nativeBasicData,
            nativeDataBuilder,
            interceptorDataBuilder,
            backendUsageBuilder,
            rtiNeedBuilder,
            nativeResolutionEnqueuer,
            noSuchMethodRegistry,
            selectorConstraintsStrategy,
            classHierarchyBuilder,
            classQueries);

  @override
  void forEachLocalFunction(void f(MemberEntity member, Local localFunction)) {
    for (KLocalFunction local in localFunctions) {
      f(local.memberContext, local);
    }
  }
}

abstract class KernelClosedWorldMixin implements ClosedWorldBase {
  KernelToElementMapBase get elementMap;

  @override
  bool hasElementIn(ClassEntity cls, Selector selector, Entity element) {
    while (cls != null) {
      MemberEntity member = elementEnvironment.lookupLocalClassMember(
          cls, selector.name,
          setter: selector.isSetter);
      if (member != null &&
          !member.isAbstract &&
          (!selector.memberName.isPrivate ||
              member.library == selector.library)) {
        return member == element;
      }
      cls = elementEnvironment.getSuperClass(cls);
    }
    return false;
  }

  @override
  bool hasConcreteMatch(ClassEntity cls, Selector selector,
      {ClassEntity stopAtSuperclass}) {
    assert(
        isInstantiated(cls), failedAt(cls, '$cls has not been instantiated.'));
    MemberEntity element = elementEnvironment
        .lookupClassMember(cls, selector.name, setter: selector.isSetter);
    if (element == null) return false;

    if (element.isAbstract) {
      ClassEntity enclosingClass = element.enclosingClass;
      return hasConcreteMatch(
          elementEnvironment.getSuperClass(enclosingClass), selector);
    }
    return selector.appliesUntyped(element);
  }

  @override
  bool isNamedMixinApplication(ClassEntity cls) {
    return elementMap._isMixinApplication(cls) &&
        !elementMap._isUnnamedMixinApplication(cls);
  }

  @override
  ClassEntity getAppliedMixin(ClassEntity cls) {
    return elementMap._getAppliedMixin(cls);
  }

  @override
  Iterable<ClassEntity> getInterfaces(ClassEntity cls) {
    return elementMap._getInterfaces(cls).map((t) => t.element);
  }

  @override
  ClassEntity getSuperClass(ClassEntity cls) {
    return elementMap._getSuperType(cls)?.element;
  }

  @override
  int getHierarchyDepth(ClassEntity cls) {
    return elementMap._getHierarchyDepth(cls);
  }

  @override
  OrderedTypeSet getOrderedTypeSet(ClassEntity cls) {
    return elementMap._getOrderedTypeSet(cls);
  }

  @override
  bool checkInvariants(ClassEntity cls, {bool mustBeInstantiated: true}) =>
      true;

  @override
  bool checkClass(ClassEntity cls) => true;

  @override
  bool checkEntity(Entity element) => true;
}

class KernelClosedWorld extends ClosedWorldBase
    with KernelClosedWorldMixin, ClosedWorldRtiNeedMixin {
  final KernelToElementMapForImpactImpl elementMap;

  KernelClosedWorld(this.elementMap,
      {CompilerOptions options,
      ElementEnvironment elementEnvironment,
      DartTypes dartTypes,
      CommonElements commonElements,
      ConstantSystem constantSystem,
      NativeData nativeData,
      InterceptorData interceptorData,
      BackendUsage backendUsage,
      NoSuchMethodData noSuchMethodData,
      ResolutionWorldBuilder resolutionWorldBuilder,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      Set<ClassEntity> implementedClasses,
      Iterable<ClassEntity> liveNativeClasses,
      Iterable<MemberEntity> liveInstanceMembers,
      Iterable<MemberEntity> assignedInstanceMembers,
      Iterable<MemberEntity> processedMembers,
      Set<TypedefEntity> allTypedefs,
      Map<ClassEntity, Set<ClassEntity>> mixinUses,
      Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses,
      Map<ClassEntity, ClassHierarchyNode> classHierarchyNodes,
      Map<ClassEntity, ClassSet> classSets})
      : super(
            elementEnvironment,
            dartTypes,
            commonElements,
            constantSystem,
            nativeData,
            interceptorData,
            backendUsage,
            noSuchMethodData,
            implementedClasses,
            liveNativeClasses,
            liveInstanceMembers,
            assignedInstanceMembers,
            processedMembers,
            allTypedefs,
            mixinUses,
            typesImplementedBySubclasses,
            classHierarchyNodes,
            classSets) {
    computeRtiNeed(resolutionWorldBuilder, rtiNeedBuilder,
        enableTypeAssertions: options.enableTypeAssertions);
  }

  @override
  void registerClosureClass(ClassEntity cls) {
    throw new UnsupportedError('KernelClosedWorld.registerClosureClass');
  }
}

// Interface for testing equivalence of Kernel-based entities.
class WorldDeconstructionForTesting {
  final KernelToElementMapBase elementMap;

  WorldDeconstructionForTesting(this.elementMap);

  IndexedClass getSuperclassForClass(IndexedClass cls) {
    ClassEnv env = elementMap._classes.getEnv(cls);
    ir.Supertype supertype = env.cls.supertype;
    if (supertype == null) return null;
    return elementMap.getClass(supertype.classNode);
  }

  bool isUnnamedMixinApplication(IndexedClass cls) {
    return elementMap._isUnnamedMixinApplication(cls);
  }

  InterfaceType getMixinTypeForClass(IndexedClass cls) {
    ClassEnv env = elementMap._classes.getEnv(cls);
    ir.Supertype mixedInType = env.cls.mixedInType;
    if (mixedInType == null) return null;
    return elementMap.createInterfaceType(
        mixedInType.classNode, mixedInType.typeArguments);
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
        KernelToElementMapForBuildingMixin,
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
        KernelToWorldBuilder {
  /// Map from members to the call methods created for their nested closures.
  Map<MemberEntity, List<FunctionEntity>> _nestedClosureMap =
      <MemberEntity, List<FunctionEntity>>{};

  NativeBasicData nativeBasicData;

  JsKernelToElementMap(DiagnosticReporter reporter, Environment environment,
      KernelToElementMapForImpactImpl _elementMap)
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
              newLibrary, data.copy(), env);
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
      _classMap[env.cls] = _classes.register(newClass, data.copy(), env);
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
                      data.node.typeParameters.length, const DynamicType()))));
      assert(newTypedef.typedefIndex == oldTypedef.typedefIndex);
    }
    for (int memberIndex = 0;
        memberIndex < _elementMap._members.length;
        memberIndex++) {
      IndexedMember oldMember = _elementMap._members.getEntity(memberIndex);
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
      var containerData = new ClassData(
          null,
          new ClosureClassDefinition(container,
              computeSourceSpanFromTreeNode(getMemberDefinition(member).node)));
      containerData
        ..isMixinApplication = false
        ..thisType = new InterfaceType(container, const <DartType>[])
        ..supertype = commonElements.objectType
        ..interfaces = const <InterfaceType>[];
      _classes.register(container, containerData, new RecordEnv(memberMap));

      var setBuilder = new _KernelOrderedTypeSetBuilder(this, container);
      containerData.orderedTypeSet = setBuilder.createOrderedTypeSet(
          containerData.supertype, const Link<InterfaceType>());

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
      InterfaceType supertype) {
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
    var closureData =
        new ClassData(null, new ClosureClassDefinition(classEntity, location));
    closureData
      ..isMixinApplication = false
      ..thisType = closureData.rawType =
          new InterfaceType(classEntity, const <DartType>[])
      ..supertype = supertype
      ..interfaces = const <InterfaceType>[];
    _classes.register(classEntity, closureData, new ClosureClassEnv(memberMap));
    var setBuilder = new _KernelOrderedTypeSetBuilder(this, classEntity);
    closureData.orderedTypeSet = setBuilder.createOrderedTypeSet(
        closureData.supertype, const Link<InterfaceType>());

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

    if (options.addMethodSignatures) {
      _constructSignatureMethod(closureClassInfo, memberMap, node,
          memberThisType, location, typeVariableAccess);
    }

    _members.register<IndexedFunction, FunctionData>(
        callMethod,
        new ClosureFunctionData(
            new ClosureMemberDefinition(
                callMethod, location, MemberKind.closureCall, node.parent),
            memberThisType,
            getFunctionType(node),
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
        getAsyncMarker(closureSourceNode));
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
          parts.add(Elements.operatorNameToIdentifier(name));
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
          parts.add(Elements.operatorNameToIdentifier(node.name.name));
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
    return elementMap._getOrderedTypeSet(cls).supertypes;
  }

  @override
  ClassEntity getSuperClass(ClassEntity cls) {
    return elementMap._getSuperType(cls)?.element;
  }

  @override
  bool implementsFunction(ClassEntity cls) {
    return elementMap._implementsFunction(cls);
  }

  @override
  int getHierarchyDepth(ClassEntity cls) {
    return elementMap._getHierarchyDepth(cls);
  }

  @override
  ClassEntity getAppliedMixin(ClassEntity cls) {
    return elementMap._getAppliedMixin(cls);
  }

  @override
  bool validateClass(ClassEntity cls) => true;

  @override
  bool checkClass(ClassEntity cls) => true;
}
