// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart' as ir;
import 'package:js_shared/synced/embedded_names.dart' show JsGetName;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/src/bounds_checks.dart' as ir;
import 'package:kernel/text/debug_printer.dart';
import 'package:kernel/type_environment.dart' as ir;

import '../common.dart';
import '../common/elements.dart';
import '../common/names.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/indexed.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../ir/annotations.dart';
import '../ir/constants.dart';
import '../ir/element_map.dart';
import '../ir/impact.dart';
import '../ir/impact_data.dart';
import '../ir/static_type.dart';
import '../ir/static_type_cache.dart';
import '../ir/types.dart';
import '../ir/visitors.dart';
import '../ir/util.dart';
import '../js/js.dart' as js;
import '../js_backend/annotations.dart';
import '../js_backend/backend_impact.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/custom_elements_analysis.dart';
import '../js_backend/namer.dart';
import '../js_backend/native_data.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../js_model/elements.dart';
import '../js_model/locals.dart';
import '../kernel/dart2js_target.dart';
import '../kernel/transformations/modular/late_lowering.dart' as late_lowering
    show
        isBackingFieldForLateInstanceField,
        isBackingFieldForLateFinalInstanceField;
import '../native/behavior.dart';
import '../native/enqueue.dart';
import '../options.dart';
import '../ordered_typeset.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';
import '../universe/world_impact.dart';
import 'element_map.dart';
import 'env.dart';
import 'kernel_impact.dart';

/// Implementation of [IrToElementMap] that only supports world
/// impact computation.
class KernelToElementMap implements IrToElementMap {
  final CompilerOptions options;
  @override
  final DiagnosticReporter reporter;
  final Environment _environment;
  final NativeBasicDataBuilder nativeBasicDataBuilder =
      NativeBasicDataBuilder();
  NativeBasicData? _nativeBasicData;
  late final KCommonElements _commonElements;
  late final KernelElementEnvironment _elementEnvironment;
  late final DartTypeConverter _typeConverter;
  late final KernelDartTypes _types;
  ir.CoreTypes? _coreTypes;
  ir.TypeEnvironment? _typeEnvironment;
  ir.ClassHierarchy? _classHierarchy;
  Dart2jsConstantEvaluator? _constantEvaluator;
  late final ConstantValuefier _constantValuefier;

  /// Library environment. Used for fast lookup.
  KProgramEnv env = KProgramEnv();

  final EntityDataEnvMap<IndexedLibrary, KLibraryData, KLibraryEnv> libraries =
      EntityDataEnvMap<IndexedLibrary, KLibraryData, KLibraryEnv>();
  final EntityDataEnvMap<IndexedClass, KClassData, KClassEnv> classes =
      EntityDataEnvMap<IndexedClass, KClassData, KClassEnv>();
  final EntityDataMap<IndexedMember, KMemberData> members =
      EntityDataMap<IndexedMember, KMemberData>();
  final EntityDataMap<IndexedTypeVariable, KTypeVariableData> typeVariables =
      EntityDataMap<IndexedTypeVariable, KTypeVariableData>();

  /// Set to `true` before creating the J-World from the K-World to assert that
  /// no entities are created late.
  bool envIsClosed = false;

  final Map<ir.Library, IndexedLibrary> libraryMap = {};
  final Map<ir.Class, IndexedClass> classMap = {};

  /// Map from [ir.TypeParameter] nodes to the corresponding
  /// [TypeVariableEntity].
  ///
  /// Normally the type variables are [IndexedTypeVariable]s, but for type
  /// parameters on local function (in the frontend) these are _not_ since
  /// their type declaration is neither a class nor a member. In the backend,
  /// these type parameters belong to the call-method and are therefore indexed.
  final Map<ir.TypeParameter, TypeVariableEntity> typeVariableMap = {};
  final Map<ir.Member, IndexedConstructor> constructorMap = {};
  final Map<ir.Procedure, IndexedFunction> methodMap = {};
  final Map<ir.Field, IndexedField> fieldMap = {};
  final Map<ir.TreeNode, Local> localFunctionMap = {};

  BehaviorBuilder? _nativeBehaviorBuilder;

  Map<IndexedMember, Map<ir.Expression, TypeMap>>? typeMapsForTesting;
  Map<ir.Member, ImpactData>? impactDataForTesting;

  KernelToElementMap(this.reporter, this._environment, this.options) {
    _elementEnvironment = KernelElementEnvironment(this);
    _typeConverter = DartTypeConverter(this);
    _types = KernelDartTypes(this, options);
    _commonElements = KCommonElements(_types, _elementEnvironment);
    _constantValuefier = ConstantValuefier(this);
  }

  /// Access to the [DartTypes] object.
  DartTypes get types => _types;

  KernelElementEnvironment get elementEnvironment => _elementEnvironment;

  /// Access to the commonly used elements and types.
  @override
  KCommonElements get commonElements => _commonElements;

  FunctionEntity? get _mainFunction {
    return env.mainMethod != null
        ? getMethodInternal(env.mainMethod as ir.Procedure)
        : null;
  }

  LibraryEntity? get _mainLibrary {
    return env.mainMethod != null
        ? getLibraryInternal(env.mainMethod!.enclosingLibrary)
        : null;
  }

  SourceSpan getSourceSpan(Spannable spannable, Entity? currentElement) {
    SourceSpan fromSpannable(Spannable spannable) {
      if (spannable is IndexedLibrary &&
          spannable.libraryIndex < libraries.length) {
        KLibraryEnv env = libraries.getEnv(spannable);
        return computeSourceSpanFromTreeNode(env.library);
      } else if (spannable is IndexedClass &&
          spannable.classIndex < classes.length) {
        KClassData data = classes.getData(spannable);
        return computeSourceSpanFromTreeNode(data.node);
      } else if (spannable is IndexedMember &&
          spannable.memberIndex < members.length) {
        KMemberData data = members.getData(spannable);
        return computeSourceSpanFromTreeNode(data.node);
      } else if (spannable is JLocalFunction) {
        return getSourceSpan(spannable.memberContext, currentElement);
      } else if (spannable is JLocal) {
        return getSourceSpan(spannable.memberContext, currentElement);
      }
      return SourceSpan.unknown();
    }

    SourceSpan sourceSpan = fromSpannable(spannable);
    if (sourceSpan.isKnown) return sourceSpan;
    return fromSpannable(currentElement!);
  }

  LibraryEntity? lookupLibrary(Uri uri) {
    KLibraryEnv? libraryEnv = env.lookupLibrary(uri);
    if (libraryEnv == null) return null;
    return getLibraryInternal(libraryEnv.library, libraryEnv);
  }

  String _getLibraryName(IndexedLibrary library) {
    KLibraryEnv libraryEnv = libraries.getEnv(library);
    return libraryEnv.library.name ?? '';
  }

  MemberEntity? lookupLibraryMember(IndexedLibrary library, String name,
      {bool setter = false}) {
    KLibraryEnv libraryEnv = libraries.getEnv(library);
    ir.Member? member = libraryEnv.lookupMember(name, setter: setter);
    return member != null ? getMember(member) : null;
  }

  void _forEachLibraryMember(
      IndexedLibrary library, void f(MemberEntity member)) {
    KLibraryEnv libraryEnv = libraries.getEnv(library);
    libraryEnv.forEachMember((ir.Member node) {
      f(getMember(node));
    });
  }

  ClassEntity? lookupClass(IndexedLibrary library, String name) {
    KLibraryEnv libraryEnv = libraries.getEnv(library);
    KClassEnv? classEnv = libraryEnv.lookupClass(name);
    if (classEnv != null) {
      return getClassInternal(classEnv.cls, classEnv);
    }
    return null;
  }

  void _forEachClass(IndexedLibrary library, void f(ClassEntity cls)) {
    KLibraryEnv libraryEnv = libraries.getEnv(library);
    libraryEnv.forEachClass((KClassEnv classEnv) {
      if (!classEnv.isUnnamedMixinApplication) {
        f(getClassInternal(classEnv.cls, classEnv));
      }
    });
  }

  /// Returns the [ClassEntity] for [node] while ensuring that the member
  /// environment for [node] is computed.
  ///
  /// This is needed to ensure that live members are always included in the
  /// environment of a class. Static members and mixed in members a member
  /// can be become live through static access and mixin application,
  /// respectively, which does not require lookup into the class members.
  ///
  /// Since the J-model class environment is computed from the K-model
  /// environment, not ensuring the computation of the class members, can result
  /// in a live member being present in the J-model but unavailable when queried
  /// as a member of its enclosing class.
  IndexedClass getClassForMemberInternal(ir.Class node) {
    final cls = getClassInternal(node);
    classes.getEnv(cls).ensureMembers(this);
    return cls;
  }

  MemberEntity? lookupClassMember(IndexedClass cls, Name name,
      {bool setter = false}) {
    KClassEnv classEnv = classes.getEnv(cls);
    return classEnv.lookupMember(this, name);
  }

  ConstructorEntity? lookupConstructor(IndexedClass cls, String name) {
    KClassEnv classEnv = classes.getEnv(cls);
    return classEnv.lookupConstructor(this, name);
  }

  /// Return the [InterfaceType] corresponding to the [cls] with the given
  /// [typeArguments] and [nullability].
  @override
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments) {
    return types.interfaceType(getClass(cls), getDartTypes(typeArguments));
  }

  LibraryEntity getLibrary(ir.Library node) => getLibraryInternal(node);

  /// Returns the [ClassEntity] corresponding to the class [node].
  @override
  ClassEntity getClass(ir.Class node) => getClassInternal(node);

  @override
  InterfaceType? getSuperType(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.supertype;
  }

  /// Returns the superclass of [cls] if any.

  ClassEntity? getSuperClass(ClassEntity cls) {
    return getSuperType(cls as IndexedClass)?.element;
  }

  void _ensureCallType(ClassEntity cls, KClassData data) {
    if (!data.isCallTypeComputed) {
      MemberEntity? callMember =
          _elementEnvironment.lookupClassMember(cls, Names.call);
      if (callMember is FunctionEntity &&
          callMember.isFunction &&
          !callMember.isAbstract) {
        data.callType = _elementEnvironment.getFunctionType(callMember);
      }
      data.isCallTypeComputed = true;
    }
  }

  void _ensureThisAndRawType(ClassEntity cls, KClassData data) {
    if (data.thisType == null) {
      ir.Class node = data.node;
      if (node.typeParameters.isEmpty) {
        data.thisType =
            data.rawType = types.interfaceType(cls, const <DartType>[]);
      } else {
        data.thisType = types.interfaceType(
            cls,
            List<DartType>.generate(node.typeParameters.length, (int index) {
              return types.typeVariableType(
                  getTypeVariableInternal(node.typeParameters[index]));
            }));
        data.rawType = types.interfaceType(
            cls,
            List<DartType>.filled(
                node.typeParameters.length, types.dynamicType()));
      }
    }
  }

  void _ensureJsInteropType(ClassEntity cls, KClassData data) {
    if (data.jsInteropType == null) {
      ir.Class node = data.node;
      if (node.typeParameters.isEmpty) {
        _ensureThisAndRawType(cls, data);
        data.jsInteropType = data.thisType;
      } else {
        data.jsInteropType = types.interfaceType(cls,
            List<DartType>.filled(node.typeParameters.length, types.anyType()));
      }
    }
  }

  void _ensureClassInstantiationToBounds(ClassEntity cls, KClassData data) {
    if (data.instantiationToBounds == null) {
      ir.Class node = data.node;
      if (node.typeParameters.isEmpty) {
        _ensureThisAndRawType(cls, data);
        data.instantiationToBounds = data.thisType;
      } else {
        data.instantiationToBounds = getInterfaceType(ir.instantiateToBounds(
            coreTypes.legacyRawType(node), coreTypes.objectClass,
            isNonNullableByDefault: node
                .enclosingLibrary.isNonNullableByDefault) as ir.InterfaceType);
      }
    }
  }

  @override
  TypeVariableEntity getTypeVariable(ir.TypeParameter node) =>
      getTypeVariableInternal(node);

  void _ensureSupertypes(ClassEntity cls, KClassData data) {
    if (data.orderedTypeSet == null) {
      _ensureThisAndRawType(cls, data);

      ir.Class node = data.node;

      if (node.supertype == null) {
        data.orderedTypeSet = OrderedTypeSet.singleton(data.thisType!);
        data.isMixinApplication = false;
        data.interfaces = const <InterfaceType>[];
      } else {
        // Set of canonical supertypes.
        //
        // This is necessary to support when a class implements the same
        // supertype in multiple non-conflicting ways, like implementing A<int*>
        // and A<int?> or B<Object?> and B<dynamic>.
        Set<InterfaceType> canonicalSupertypes = <InterfaceType>{};

        InterfaceType processSupertype(ir.Supertype supertypeNode) {
          supertypeNode = classHierarchy.getClassAsInstanceOf(
              node, supertypeNode.classNode)!;
          InterfaceType supertype =
              _typeConverter.visitSupertype(supertypeNode);
          canonicalSupertypes.add(supertype);
          IndexedClass superclass = supertype.element as IndexedClass;
          KClassData superdata = classes.getData(superclass);
          _ensureSupertypes(superclass, superdata);
          for (InterfaceType supertype
              in superdata.orderedTypeSet!.supertypes!) {
            ir.Supertype? canonicalSupertype =
                classHierarchy.getClassAsInstanceOf(
                    node, getClassNode(supertype.element as IndexedClass));
            if (canonicalSupertype != null) {
              supertype = _typeConverter.visitSupertype(canonicalSupertype);
            } else {
              assert(supertype.typeArguments.isEmpty,
                  "Generic synthetic supertypes are not supported");
            }
            canonicalSupertypes.add(supertype);
          }
          return supertype;
        }

        InterfaceType supertype;
        List<InterfaceType> interfaces = <InterfaceType>[];
        if (node.isMixinDeclaration) {
          // A mixin declaration
          //
          //   mixin M on A, B, C {}
          //
          // is encoded by CFE as
          //
          //   abstract class M extends A implements B, C {}
          //   abstract class M extends A&B&C {}
          //
          // but we encode it as
          //
          //   abstract class M extends Object implements A, B, C {}
          //
          // so we need get the superclasses from the on-clause, A, B, and C,
          // through [superclassConstraints].
          for (ir.Supertype constraint in node.onClause) {
            interfaces.add(processSupertype(constraint));
          }
          // Set superclass to `Object`.
          supertype = _commonElements.objectType;
        } else {
          supertype = processSupertype(node.supertype!);
        }
        if (supertype == _commonElements.objectType) {
          ClassEntity defaultSuperclass =
              _commonElements.getDefaultSuperclass(cls, nativeBasicData);
          data.supertype = _elementEnvironment.getRawType(defaultSuperclass);
          assert(data.supertype!.typeArguments.isEmpty,
              "Generic default supertypes are not supported");
          canonicalSupertypes.add(data.supertype!);
        } else {
          data.supertype = supertype;
        }
        if (node.mixedInType != null) {
          data.isMixinApplication = true;
          interfaces
              .add(data.mixedInType = processSupertype(node.mixedInType!));
        } else {
          data.isMixinApplication = false;
        }
        node.implementedTypes.forEach((ir.Supertype supertype) {
          interfaces.add(processSupertype(supertype));
        });
        OrderedTypeSetBuilder setBuilder =
            KernelOrderedTypeSetBuilder(this, cls);
        data.orderedTypeSet =
            setBuilder.createOrderedTypeSet(canonicalSupertypes);
        data.interfaces = interfaces;
      }
    }
  }

  /// Returns the [MemberEntity] corresponding to the member [node].
  @override
  MemberEntity getMember(ir.Member node) {
    if (node is ir.Field) {
      return getFieldInternal(node);
    } else if (node is ir.Constructor) {
      return getConstructorInternal(node);
    } else if (node is ir.Procedure) {
      if (node.kind == ir.ProcedureKind.Factory) {
        return getConstructorInternal(node);
      } else {
        return getMethodInternal(node);
      }
    }
    throw UnsupportedError("Unexpected member: $node");
  }

  /// Returns the [ConstructorEntity] corresponding to the generative or factory
  /// constructor [node].
  @override
  ConstructorEntity getConstructor(ir.Member node) =>
      getConstructorInternal(node);

  /// Returns the [ConstructorEntity] corresponding to a super initializer in
  /// [constructor].
  ///
  /// The IR resolves super initializers to a [target] up in the type hierarchy.
  /// Most of the time, the result of this function will be the entity
  /// corresponding to that target. In the presence of unnamed mixins, this
  /// function returns an entity for an intermediate synthetic constructor that
  /// kernel doesn't explicitly represent.
  ///
  /// For example:
  ///     class M {}
  ///     class C extends Object with M {}
  ///
  /// Kernel will say that C()'s super initializer resolves to Object(), but
  /// this function will return an entity representing the unnamed mixin
  /// application "Object+M"'s constructor.
  ConstructorEntity getSuperConstructor(
      ir.Constructor sourceNode, ir.Member targetNode) {
    ConstructorEntity source = getConstructor(sourceNode);
    ClassEntity sourceClass = source.enclosingClass;
    ConstructorEntity target = getConstructor(targetNode);
    ClassEntity targetClass = target.enclosingClass;
    IndexedClass? superClass =
        getSuperType(sourceClass as IndexedClass)?.element as IndexedClass?;
    if (superClass == targetClass) {
      return target;
    }

    /// This path is needed for synthetically injected superclasses like
    /// `Interceptor` and `LegacyJavaScriptObject`.
    KClassEnv env = classes.getEnv(superClass!);
    ConstructorEntity? constructor = env.lookupConstructor(this, target.name);
    if (constructor != null) {
      return constructor;
    }
    throw failedAt(source, "Super constructor for $source not found.");
  }

  /// Returns the [FunctionEntity] corresponding to the procedure [node].
  @override
  FunctionEntity getMethod(ir.Procedure node) => getMethodInternal(node);

  /// Returns the [FieldEntity] corresponding to the field [node].
  @override
  FieldEntity getField(ir.Field node) => getFieldInternal(node);

  /// Returns the [DartType] corresponding to [type].
  @override
  DartType getDartType(ir.DartType type) => _typeConverter.visitType(type);

  /// Returns the [TypeVariableType] corresponding to [type].
  TypeVariableType getTypeVariableType(ir.TypeParameterType type) =>
      getDartType(type).withoutNullability as TypeVariableType;

  List<DartType> getDartTypes(List<ir.DartType> types) {
    List<DartType> list = <DartType>[];
    types.forEach((ir.DartType type) {
      list.add(getDartType(type));
    });
    return list;
  }

  /// Returns the [InterfaceType] corresponding to [type].
  InterfaceType getInterfaceType(ir.InterfaceType type) =>
      _typeConverter.visitType(type).withoutNullability as InterfaceType;

  /// Returns the [FunctionType] of the [node].
  @override
  FunctionType getFunctionType(ir.FunctionNode node) {
    DartType returnType;
    if (node.parent is ir.Constructor) {
      // The return type on generative constructors is `void`, but we need
      // `dynamic` type to match the element model.
      returnType = types.dynamicType();
    } else {
      returnType = getDartType(node.returnType);
    }
    List<DartType> parameterTypes = <DartType>[];
    List<DartType> optionalParameterTypes = <DartType>[];

    DartType getParameterType(ir.VariableDeclaration variable) {
      // isCovariant implies this FunctionNode is a class Procedure.
      var isCovariant =
          variable.isCovariantByDeclaration || variable.isCovariantByClass;
      var isFromNonNullableByDefaultLibrary = isCovariant &&
          (node.parent as ir.Procedure).enclosingLibrary.isNonNullableByDefault;
      return types.getTearOffParameterType(getDartType(variable.type),
          isCovariant, isFromNonNullableByDefaultLibrary);
    }

    for (ir.VariableDeclaration variable in node.positionalParameters) {
      if (parameterTypes.length == node.requiredParameterCount) {
        optionalParameterTypes.add(getParameterType(variable));
      } else {
        parameterTypes.add(getParameterType(variable));
      }
    }
    List<String> namedParameters = <String>[];
    Set<String> requiredNamedParameters = <String>{};
    List<DartType> namedParameterTypes = <DartType>[];
    List<ir.VariableDeclaration> sortedNamedParameters = node.namedParameters
        .toList()
      ..sort((a, b) => a.name!.compareTo(b.name!));
    for (ir.VariableDeclaration variable in sortedNamedParameters) {
      namedParameters.add(variable.name!);
      namedParameterTypes.add(getParameterType(variable));
      if (variable.isRequired) {
        requiredNamedParameters.add(variable.name!);
      }
    }
    List<FunctionTypeVariable> typeVariables;
    if (node.typeParameters.isNotEmpty) {
      List<DartType> typeParameters = <DartType>[];
      for (ir.TypeParameter typeParameter in node.typeParameters) {
        typeParameters.add(getDartType(
            ir.TypeParameterType(typeParameter, ir.Nullability.nonNullable)));
      }
      typeVariables = List<FunctionTypeVariable>.generate(
          node.typeParameters.length,
          (int index) => types.functionTypeVariable(index));

      DartType subst(DartType type) {
        return types.subst(typeVariables, typeParameters, type);
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

    return types.functionType(
        returnType,
        parameterTypes,
        optionalParameterTypes,
        namedParameters,
        requiredNamedParameters,
        namedParameterTypes,
        typeVariables);
  }

  @override
  DartType substByContext(DartType type, InterfaceType context) {
    return types.subst(context.typeArguments,
        getThisType(context.element as IndexedClass).typeArguments, type);
  }

  /// Returns the type of the `call` method on 'type'.
  ///
  /// If [type] doesn't have a `call` member or has a non-method `call` member,
  /// `null` is returned.
  @override
  FunctionType? getCallType(InterfaceType type) {
    IndexedClass cls = type.element as IndexedClass;
    KClassData data = classes.getData(cls);
    _ensureCallType(cls, data);
    if (data.callType != null) {
      return substByContext(data.callType!, type) as FunctionType?;
    }
    return null;
  }

  @override
  InterfaceType getThisType(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.thisType!;
  }

  InterfaceType? _getJsInteropType(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureJsInteropType(cls, data);
    return data.jsInteropType;
  }

  InterfaceType _getRawType(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.rawType!;
  }

  InterfaceType _getClassInstantiationToBounds(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureClassInstantiationToBounds(cls, data);
    return data.instantiationToBounds!;
  }

  DartType _getFieldType(IndexedField field) {
    KFieldData data = members.getData(field) as KFieldData;
    return data.getFieldType(this);
  }

  FunctionType _getFunctionType(IndexedFunction function) {
    KFunctionData data = members.getData(function) as KFunctionData;
    return data.getFunctionType(this);
  }

  List<TypeVariableType> _getFunctionTypeVariables(IndexedFunction function) {
    KFunctionData data = members.getData(function) as KFunctionData;
    return data.getFunctionTypeVariables(this);
  }

  @override
  DartType getTypeVariableBound(IndexedTypeVariable typeVariable) {
    KTypeVariableData data = typeVariables.getData(typeVariable);
    return data.getBound(this);
  }

  @override
  List<Variance> getTypeVariableVariances(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    return data.getVariances();
  }

  /// Returns the class mixed into [cls] if any.
  // TODO(johnniwinther): Replace this by a `getAppliedMixins` function that
  // return transitively mixed in classes like in:
  //     class A {}
  //     class B = Object with A;
  //     class C = Object with B;
  ClassEntity? getAppliedMixin(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.mixedInType?.element;
  }

  bool _isMixinApplication(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.isMixinApplication;
  }

  bool _isUnnamedMixinApplication(IndexedClass cls) {
    KClassEnv env = classes.getEnv(cls);
    return env.isUnnamedMixinApplication;
  }

  void _forEachSupertype(IndexedClass cls, void f(InterfaceType supertype)) {
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    data.orderedTypeSet!.supertypes!.forEach(f);
  }

  void _forEachMixin(IndexedClass? cls, void f(ClassEntity mixin)) {
    while (cls != null) {
      KClassData data = classes.getData(cls);
      _ensureSupertypes(cls, data);
      if (data.mixedInType != null) {
        f(data.mixedInType!.element);
      }
      cls = data.supertype?.element as IndexedClass?;
    }
  }

  void _forEachConstructor(IndexedClass cls, void f(ConstructorEntity member)) {
    KClassEnv env = classes.getEnv(cls);
    env.forEachConstructor(this, f);
  }

  void _forEachLocalClassMember(IndexedClass cls, void f(MemberEntity member)) {
    KClassEnv env = classes.getEnv(cls);
    env.forEachMember(this, (MemberEntity member) {
      f(member);
    });
  }

  void forEachInjectedClassMember(
      IndexedClass cls, void f(MemberEntity member)) {
    throw UnsupportedError(
        'KernelToElementMapBase._forEachInjectedClassMember');
  }

  void _forEachClassMember(
      IndexedClass cls, void f(ClassEntity cls, MemberEntity member)) {
    KClassEnv env = classes.getEnv(cls);
    env.forEachMember(this, (MemberEntity member) {
      f(cls, member);
    });
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    if (data.supertype != null) {
      _forEachClassMember(data.supertype!.element as IndexedClass, f);
    }
  }

  @override
  InterfaceType? asInstanceOf(InterfaceType type, ClassEntity cls) {
    OrderedTypeSet orderedTypeSet =
        getOrderedTypeSet(type.element as IndexedClass);
    InterfaceType? supertype = orderedTypeSet.asInstanceOf(
        cls, getHierarchyDepth(cls as IndexedClass));
    if (supertype != null) {
      supertype = substByContext(supertype, type) as InterfaceType?;
    }
    return supertype;
  }

  @override
  OrderedTypeSet getOrderedTypeSet(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet!;
  }

  /// Returns all supertypes of [cls].
  Iterable<InterfaceType> getSuperTypes(ClassEntity cls) {
    return getOrderedTypeSet(cls as IndexedClass).supertypes!;
  }

  /// Returns the hierarchy depth of [cls].
  @override
  int getHierarchyDepth(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet!.maxDepth;
  }

  @override
  Iterable<InterfaceType> getInterfaces(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    assert(data.interfaces != null);
    return data.interfaces!;
  }

  /// Returns the defining node for [member].
  ir.Member getMemberNode(MemberEntity member) {
    return members.getData(member as IndexedMember).node;
  }

  /// Returns the defining node for [cls].
  ir.Class getClassNode(ClassEntity cls) {
    return classes.getData(cls as IndexedClass).node;
  }

  /// Return the [ImportEntity] corresponding to [node].
  ImportEntity? getImport(ir.LibraryDependency? node) {
    if (node == null) return null;
    ir.Library library = node.enclosingLibrary;
    KLibraryData data = libraries.getData(getLibraryInternal(library));
    return data.imports![node];
  }

  /// Returns the core types for the underlying kernel model.
  @override
  ir.CoreTypes get coreTypes => _coreTypes ??= ir.CoreTypes(env.mainComponent);

  /// Returns the type environment for the underlying kernel model.
  ir.TypeEnvironment get typeEnvironment =>
      _typeEnvironment ??= ir.TypeEnvironment(coreTypes, classHierarchy);

  /// Returns the class hierarchy for the underlying kernel model.
  ir.ClassHierarchy get classHierarchy =>
      _classHierarchy ??= ir.ClassHierarchy(env.mainComponent, coreTypes);

  ir.StaticTypeContext getStaticTypeContext(MemberEntity member) {
    // TODO(johnniwinther): Cache the static type context.
    return ir.StaticTypeContext(
        getMemberNode(member as IndexedMember), typeEnvironment);
  }

  Dart2jsConstantEvaluator get constantEvaluator {
    return _constantEvaluator ??=
        Dart2jsConstantEvaluator(env.mainComponent, typeEnvironment,
            (ir.LocatedMessage message, List<ir.LocatedMessage>? context) {
      reportLocatedMessage(reporter, message, context);
    },
            environment: _environment,
            evaluationMode: options.useLegacySubtyping
                ? ir.EvaluationMode.weak
                : ir.EvaluationMode.strong);
  }

  @override
  Name getName(ir.Name name, {bool setter = false}) {
    return Name(name.text, name.isPrivate ? name.library!.importUri : null,
        isSetter: setter);
  }

  /// Returns the [CallStructure] corresponding to the [arguments].

  @override
  CallStructure getCallStructure(ir.Arguments arguments) {
    int argumentCount = arguments.positional.length + arguments.named.length;
    List<String> namedArguments = arguments.named.map((e) => e.name).toList();
    return CallStructure(argumentCount, namedArguments, arguments.types.length);
  }

  ParameterStructure getParameterStructure(ir.FunctionNode node,
      // TODO(johnniwinther): Remove this when type arguments are passed to
      // constructors like calling a generic method.
      {bool includeTypeParameters = true}) {
    // TODO(johnniwinther): Cache the computed function type.
    int requiredPositionalParameters = node.requiredParameterCount;
    int positionalParameters = node.positionalParameters.length;
    int typeParameters = node.typeParameters.length;
    List<String> namedParameters = <String>[];
    Set<String> requiredNamedParameters = <String>{};
    List<ir.VariableDeclaration> sortedNamedParameters = node.namedParameters
        .toList()
      ..sort((a, b) => a.name!.compareTo(b.name!));
    for (var variable in sortedNamedParameters) {
      namedParameters.add(variable.name!);
      if (variable.isRequired && !options.useLegacySubtyping) {
        requiredNamedParameters.add(variable.name!);
      }
    }
    return ParameterStructure(
        requiredPositionalParameters,
        positionalParameters,
        namedParameters,
        requiredNamedParameters,
        includeTypeParameters ? typeParameters : 0);
  }

  /// Returns the [Selector] corresponding to the invocation of [name] with
  /// [arguments].
  Selector getInvocationSelector(ir.Name irName, int positionalArguments,
      List<String> namedArguments, int typeArguments) {
    Name name = getName(irName);
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

    CallStructure callStructure = CallStructure(
        positionalArguments + namedArguments.length,
        namedArguments,
        typeArguments);
    return Selector(kind, name, callStructure);
  }

  Selector getGetterSelector(ir.Name irName) {
    Name name =
        Name(irName.text, irName.isPrivate ? irName.library!.importUri : null);
    return Selector.getter(name);
  }

  Selector getSetterSelector(ir.Name irName) {
    Name name =
        Name(irName.text, irName.isPrivate ? irName.library!.importUri : null);
    return Selector.setter(name);
  }

  /// Looks up [typeName] for use in the spec-string of a `JS` call.
  // TODO(johnniwinther): Use this in [NativeBehavior] instead of calling
  // the `ForeignResolver`.
  TypeLookup typeLookup({required bool resolveAsRaw}) {
    return resolveAsRaw ? _cachedTypeLookupRaw : _cachedTypeLookupFull;
  }

  late final TypeLookup _cachedTypeLookupRaw = _typeLookup(resolveAsRaw: true);
  late final TypeLookup _cachedTypeLookupFull =
      _typeLookup(resolveAsRaw: false);

  TypeLookup _typeLookup({required bool resolveAsRaw}) {
    bool? cachedMayLookupInMain;

    DartType lookup(String typeName, {bool? required}) {
      DartType? findInLibrary(LibraryEntity? library) {
        if (library != null) {
          ClassEntity? cls = elementEnvironment.lookupClass(library, typeName);
          if (cls != null) {
            // TODO(johnniwinther): Align semantics.
            return resolveAsRaw
                ? elementEnvironment.getRawType(cls)
                : elementEnvironment.getThisType(cls);
          }
        }
        return null;
      }

      DartType? findIn(Uri uri) {
        return findInLibrary(elementEnvironment.lookupLibrary(uri));
      }

      // TODO(johnniwinther): Narrow the set of lookups based on the depending
      // library.
      // TODO(johnniwinther): Cache more results to avoid redundant lookups?
      cachedMayLookupInMain ??=
          // Tests permit lookup outside of dart: libraries.
          allowedNativeTest(elementEnvironment.mainLibrary!.canonicalUri);
      DartType? type;
      if (cachedMayLookupInMain!) {
        type ??= findInLibrary(elementEnvironment.mainLibrary);
      }
      type ??= findIn(Uris.dart_core);
      type ??= findIn(Uris.dart__js_helper);
      type ??= findIn(Uris.dart__late_helper);
      type ??= findIn(Uris.dart__interceptors);
      type ??= findIn(Uris.dart__native_typed_data);
      type ??= findIn(Uris.dart_collection);
      type ??= findIn(Uris.dart_math);
      type ??= findIn(Uris.dart_html);
      type ??= findIn(Uris.dart_html_common);
      type ??= findIn(Uris.dart_svg);
      type ??= findIn(Uris.dart_web_audio);
      type ??= findIn(Uris.dart_web_gl);
      type ??= findIn(Uris.dart_indexed_db);
      type ??= findIn(Uris.dart_typed_data);
      type ??= findIn(Uris.dart__rti);
      type ??= findIn(Uris.dart_mirrors);
      if (type == null && required!) {
        reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
            MessageKind.GENERIC, {'text': "Type '$typeName' not found."});
      }
      return type!;
    }

    return lookup;
  }

  String? _getStringArgument(ir.StaticInvocation node, int index) {
    return node.arguments.positional[index].accept(Stringifier());
  }

  /// Computes the [NativeBehavior] for a call to the [JS] function.
  /// TODO(johnniwinther): Cache this for later use.
  NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length < 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS);
      return NativeBehavior();
    }
    String? specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST);
      return NativeBehavior();
    }

    String? codeString = _getStringArgument(node, 1);
    if (codeString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND);
      return NativeBehavior();
    }

    return NativeBehavior.ofJsCall(
        specString,
        codeString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// TODO(johnniwinther): Cache this for later use.
  /// Computes the [NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  NativeBehavior getNativeBehaviorForJsBuiltinCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin expression has no type.");
      return NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin is missing name.");
      return NativeBehavior();
    }
    String? specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return NativeBehavior();
    }
    return NativeBehavior.ofJsBuiltinCall(
        specString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Computes the [NativeBehavior] for a call to the
  /// [JS_EMBEDDED_GLOBAL] function.
  /// TODO(johnniwinther): Cache this for later use.
  NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global expression has no type.");
      return NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS embedded global is missing name.");
      return NativeBehavior();
    }
    if (node.arguments.positional.length > 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global has more than 2 arguments.");
      return NativeBehavior();
    }
    String? specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return NativeBehavior();
    }
    return NativeBehavior.ofJsEmbeddedGlobalCall(
        specString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Returns the [js.Name] for the `JsGetName` [constant] value.
  js.Name? getNameForJsGetName(ConstantValue constant, ModularNamer namer) {
    int? index = extractEnumIndexFromConstantValue(
        constant, commonElements.jsGetNameEnum);
    if (index == null) return null;
    return namer.getNameForJsGetName(
        CURRENT_ELEMENT_SPANNABLE, JsGetName.values[index]);
  }

  int? extractEnumIndexFromConstantValue(
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

  /// Computes the [ConstantValue] for the constant [expression].
  ConstantValue? getConstantValue(
      ir.StaticTypeContext staticTypeContext, ir.Expression? node,
      {bool requireConstant = true,
      bool implicitNull = false,
      bool checkCasts = true}) {
    if (node == null) {
      if (!implicitNull) {
        throw failedAt(
            CURRENT_ELEMENT_SPANNABLE, 'No expression for constant.');
      }
      return NullConstantValue();
    }
    ir.Constant? constant = constantEvaluator.evaluateOrNull(
        staticTypeContext, node,
        requireConstant: requireConstant);
    if (constant == null) {
      if (requireConstant) {
        throw UnsupportedError(
            'No constant for ${DebugPrinter.prettyPrint(node)}');
      }
    } else {
      ConstantValue value = _constantValuefier.visitConstant(constant);
      if (!value.isConstant && !requireConstant) {
        return null;
      }
      return value;
    }

    return null;
  }

  /// Converts [annotations] into a list of [ConstantValue]s.
  List<ConstantValue> getMetadata(
      ir.StaticTypeContext staticTypeContext, List<ir.Expression> annotations) {
    if (annotations.isEmpty) return const <ConstantValue>[];
    List<ConstantValue> metadata = <ConstantValue>[];
    annotations.forEach((ir.Expression node) {
      // We skip the implicit cast checks for metadata to avoid circular
      // dependencies in the js-interop class registration.
      metadata
          .add(getConstantValue(staticTypeContext, node, checkCasts: false)!);
    });
    return metadata;
  }

  /// Returns the `noSuchMethod` [FunctionEntity] call from a
  /// `super.noSuchMethod` invocation within [cls].
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls) {
    while (true) {
      ClassEntity? superclass = elementEnvironment.getSuperClass(cls);
      if (superclass == null) break;
      MemberEntity? member = elementEnvironment.lookupLocalClassMember(
          superclass, Names.noSuchMethod_);
      if (member != null && !member.isAbstract) {
        if (member is JMethod) {
          if (member.parameterStructure.positionalParameters >= 1) {
            return member;
          }
        }
        // If [member] is not a valid `noSuchMethod` the target is
        // `Object.superNoSuchMethod`.
        break;
      }
      cls = superclass;
    }
    return elementEnvironment.lookupLocalClassMember(
        commonElements.objectClass, Names.noSuchMethod_)! as FunctionEntity;
  }

  Iterable<LibraryEntity> get libraryListInternal {
    if (env.length != libraryMap.length) {
      // Create a [JLibrary] for each library.
      env.forEachLibrary((KLibraryEnv env) {
        getLibraryInternal(env.library, env);
      });
    }
    return libraryMap.values;
  }

  IndexedLibrary getLibraryInternal(ir.Library node,
      [KLibraryEnv? libraryEnv]) {
    return libraryMap[node] ??= _getLibraryCreate(node, libraryEnv);
  }

  IndexedLibrary _getLibraryCreate(ir.Library node, KLibraryEnv? libraryEnv) {
    assert(
        !envIsClosed,
        "Environment of $this is closed. Trying to create "
        "library for $node.");
    Uri canonicalUri = node.importUri;
    String? name = node.name;
    if (name == null) {
      // Use the file name as script name.
      String path = canonicalUri.path;
      name = path.substring(path.lastIndexOf('/') + 1);
    }
    IndexedLibrary library =
        createLibrary(name, canonicalUri, node.isNonNullableByDefault);
    return libraries.register<IndexedLibrary, KLibraryData, KLibraryEnv>(
        library,
        KLibraryData(node),
        libraryEnv ?? env.lookupLibrary(canonicalUri)!);
  }

  IndexedClass getClassInternal(ir.Class node, [KClassEnv? classEnv]) {
    return classMap[node] ??= _getClassCreate(node, classEnv);
  }

  IndexedClass _getClassCreate(ir.Class node, KClassEnv? classEnv) {
    assert(
        !envIsClosed,
        "Environment of $this is closed. Trying to create "
        "class for $node.");
    JLibrary library = getLibraryInternal(node.enclosingLibrary) as JLibrary;
    if (classEnv == null) {
      classEnv = libraries.getEnv(library).lookupClass(node.name)!;
    }
    IndexedClass cls =
        createClass(library, node.name, isAbstract: node.isAbstract);
    return classes.register(cls, KClassData(node), classEnv);
  }

  TypeVariableEntity getTypeVariableInternal(ir.TypeParameter node) {
    return typeVariableMap[node] ??= _getTypeVariableCreate(node)!;
  }

  TypeVariableEntity? _getTypeVariableCreate(ir.TypeParameter node) {
    assert(
        !envIsClosed,
        "Environment of $this is closed. Trying to create "
        "type variable for $node.");
    final declaration = node.declaration;
    // TODO(fishythefish): Use exhaustive pattern switch.
    if (declaration is ir.Class) {
      int index = declaration.typeParameters.indexOf(node);
      return typeVariables.register(
          createTypeVariable(getClassInternal(declaration), node.name!, index),
          KTypeVariableData(node));
    } else if (declaration is ir.Procedure) {
      int index = declaration.typeParameters.indexOf(node);
      if (declaration.kind == ir.ProcedureKind.Factory) {
        ir.Class cls = declaration.enclosingClass!;
        return getTypeVariableInternal(cls.typeParameters[index]);
      } else {
        return typeVariables.register(
            createTypeVariable(
                getMethodInternal(declaration), node.name!, index),
            KTypeVariableData(node));
      }
    } else if (declaration is ir.LocalFunction) {
      // Ensure that local function type variables have been created.
      getLocalFunction(declaration);
      return typeVariableMap[node];
    }
    throw UnsupportedError('Unsupported type parameter type node $node.');
  }

  IndexedConstructor getConstructorInternal(ir.Member node) {
    return constructorMap[node] ??= _getConstructorCreate(node);
  }

  IndexedConstructor _getConstructorCreate(ir.Member node) {
    assert(
        !envIsClosed,
        "Environment of $this is closed. Trying to create "
        "constructor for $node.");
    ir.FunctionNode functionNode;
    final enclosingClass =
        getClassForMemberInternal(node.enclosingClass!) as JClass;
    Name name = getName(node.name);
    bool isExternal = node.isExternal;

    IndexedConstructor constructor;
    if (node is ir.Constructor) {
      functionNode = node.function;
      constructor = createGenerativeConstructor(enclosingClass, name,
          getParameterStructure(functionNode, includeTypeParameters: false),
          isExternal: isExternal, isConst: node.isConst);
    } else if (node is ir.Procedure) {
      functionNode = node.function;
      // TODO(sigmund): Check more strictly than just the class name.
      bool isEnvironmentConstructor = isExternal &&
          (name.text == 'fromEnvironment' &&
                  const ['int', 'bool', 'String']
                      .contains(enclosingClass.name) ||
              name.text == 'hasEnvironment' && enclosingClass.name == 'bool');
      constructor = createFactoryConstructor(enclosingClass, name,
          getParameterStructure(functionNode, includeTypeParameters: false),
          isExternal: isExternal,
          isConst: node.isConst,
          isFromEnvironmentConstructor: isEnvironmentConstructor);
    } else {
      // TODO(johnniwinther): Convert `node.location` to a [SourceSpan].
      throw failedAt(
          NO_LOCATION_SPANNABLE, "Unexpected constructor node: ${node}.");
    }
    return members.register<IndexedConstructor, KConstructorData>(
        constructor, KConstructorData(node, functionNode));
  }

  IndexedFunction getMethodInternal(ir.Procedure node) {
    // [_getMethodCreate] inserts the created function in [methodMap] so we
    // don't need to use ??= here.
    return methodMap[node] ?? _getMethodCreate(node);
  }

  IndexedFunction _getMethodCreate(ir.Procedure node) {
    assert(
        !envIsClosed,
        "Environment of $this is closed. Trying to create "
        "function for $node.");
    late IndexedFunction function;
    JLibrary library;
    JClass? enclosingClass;
    if (node.enclosingClass != null) {
      enclosingClass =
          getClassForMemberInternal(node.enclosingClass!) as JClass;
      library = enclosingClass.library;
    } else {
      library = getLibraryInternal(node.enclosingLibrary) as JLibrary;
    }
    Name name = getName(node.name);
    bool isStatic = node.isStatic;
    bool isExternal = node.isExternal;
    // TODO(johnniwinther): Remove `&& !node.isExternal` when #31233 is fixed.
    bool isAbstract = node.isAbstract && !node.isExternal;
    AsyncMarker asyncMarker = getAsyncMarker(node.function);
    switch (node.kind) {
      case ir.ProcedureKind.Factory:
        throw UnsupportedError("Cannot create method from factory.");
      case ir.ProcedureKind.Getter:
        function = createGetter(library, enclosingClass, name, asyncMarker,
            isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
        break;
      case ir.ProcedureKind.Method:
      case ir.ProcedureKind.Operator:
        function = createMethod(library, enclosingClass, name,
            getParameterStructure(node.function), asyncMarker,
            isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
        break;
      case ir.ProcedureKind.Setter:
        assert(asyncMarker == AsyncMarker.SYNC);
        function = createSetter(library, enclosingClass, name.setter,
            isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
        break;
    }
    members.register<IndexedFunction, KFunctionData>(
        function, KFunctionData(node, node.function));
    // We need to register the function before creating the type variables.
    methodMap[node] = function;
    for (ir.TypeParameter typeParameter in node.function.typeParameters) {
      getTypeVariable(typeParameter);
    }
    return function;
  }

  IndexedField getFieldInternal(ir.Field node) {
    return fieldMap[node] ??= _getFieldCreate(node);
  }

  IndexedField _getFieldCreate(ir.Field node) {
    assert(
        !envIsClosed,
        "Environment of $this is closed. Trying to create "
        "field for $node.");
    JLibrary library;
    JClass? enclosingClass;
    if (node.enclosingClass != null) {
      enclosingClass =
          getClassForMemberInternal(node.enclosingClass!) as JClass;
      library = enclosingClass.library;
    } else {
      library = getLibraryInternal(node.enclosingLibrary) as JLibrary;
    }
    Name name = getName(node.name);
    bool isStatic = node.isStatic;
    bool isLateBackingField = false;
    bool isLateFinalBackingField = false;
    if (enclosingClass != null && !isStatic) {
      isLateBackingField =
          late_lowering.isBackingFieldForLateInstanceField(node);
      isLateFinalBackingField =
          late_lowering.isBackingFieldForLateFinalInstanceField(node);
    }
    IndexedField field = createField(library, enclosingClass, name,
        isStatic: isStatic,
        isAssignable: node.hasSetter,
        isConst: node.isConst);
    return members.register<IndexedField, KFieldData>(
        field,
        KFieldData(node,
            isLateBackingField: isLateBackingField,
            isLateFinalBackingField: isLateFinalBackingField));
  }

  /// NativeBasicData is need for computation of the default super class.
  NativeBasicData get nativeBasicData {
    var data = _nativeBasicData;
    if (data == null) {
      data =
          _nativeBasicData = nativeBasicDataBuilder.close(elementEnvironment);
      assert(
          _nativeBasicData != null,
          failedAt(NO_LOCATION_SPANNABLE,
              "NativeBasicData has not been computed yet."));
    }
    return data;
  }

  /// Adds libraries in [component] to the set of libraries.
  ///
  /// The main method of the first component is used as the main method for the
  /// compilation.
  void addComponent(ir.Component component) {
    env.addComponent(component);
  }

  BehaviorBuilder get nativeBehaviorBuilder =>
      _nativeBehaviorBuilder ??= BehaviorBuilder(elementEnvironment,
          commonElements, nativeBasicData, reporter, options);

  WorldImpact computeWorldImpact(
      IndexedMember member,
      BackendImpacts impacts,
      NativeResolutionEnqueuer nativeResolutionEnqueuer,
      BackendUsageBuilder backendUsageBuilder,
      CustomElementsResolutionAnalysis customElementsResolutionAnalysis,
      RuntimeTypesNeedBuilder rtiNeedBuilder,
      AnnotationsData annotationsData,
      ImpactBuilderData impactBuilderData) {
    KMemberData memberData = members.getData(member);
    ir.Member node = memberData.node;

    if (impactBuilderData.typeMapsForTesting != null) {
      typeMapsForTesting ??= {};
      typeMapsForTesting![member] = impactBuilderData.typeMapsForTesting!;
    }
    ImpactData impactData = impactBuilderData.impactData;
    memberData.staticTypes = impactBuilderData.cachedStaticTypes;
    if (retainDataForTesting) {
      impactDataForTesting ??= {};
      impactDataForTesting![node] = impactData;
    }
    KernelImpactConverter converter = KernelImpactConverter(
        this,
        member,
        reporter,
        options,
        _constantValuefier,
        // TODO(johnniwinther): Pull the static type context from the cached
        // static types.
        ir.StaticTypeContext(node, typeEnvironment),
        impacts,
        nativeResolutionEnqueuer,
        backendUsageBuilder,
        customElementsResolutionAnalysis,
        rtiNeedBuilder,
        annotationsData);
    return converter.convert(impactData);
  }

  StaticTypeCache getCachedStaticTypes(JMember member) {
    return members.getData(member).staticTypes!;
  }

  Map<ir.Expression, TypeMap>? getTypeMapsForTesting(IndexedMember member) {
    return typeMapsForTesting![member];
  }

  /// Returns the kernel [ir.Procedure] node for the [method].
  ir.Procedure lookupProcedure(JFunction method) {
    return members.getData(method).node as ir.Procedure;
  }

  /// Returns the [ir.Library] corresponding to [library].
  ir.Library getLibraryNode(LibraryEntity library) {
    return libraries.getData(library as IndexedLibrary).library;
  }

  /// Returns the [Local] corresponding to the local function [node].
  JLocalFunction getLocalFunction(ir.LocalFunction? node) {
    JLocalFunction? localFunction = localFunctionMap[node!] as JLocalFunction?;
    if (localFunction == null) {
      late MemberEntity memberContext;
      late Entity executableContext;
      ir.TreeNode? parent = node.parent;
      while (parent != null) {
        if (parent is ir.Member) {
          executableContext = memberContext = getMember(parent);
          break;
        }
        if (parent is ir.LocalFunction) {
          JLocalFunction localFunction = getLocalFunction(parent);
          executableContext = localFunction;
          memberContext = localFunction.memberContext;
          break;
        }
        parent = parent.parent;
      }
      String? name;
      late ir.FunctionNode function;
      if (node is ir.FunctionDeclaration) {
        name = node.variable.name;
        function = node.function;
      } else if (node is ir.FunctionExpression) {
        function = node.function;
      }
      localFunction = localFunctionMap[node] =
          JLocalFunction(name, memberContext, executableContext, node);
      int index = 0;
      List<JLocalTypeVariable> typeVariables = <JLocalTypeVariable>[];
      for (ir.TypeParameter typeParameter in function.typeParameters) {
        typeVariables.add(typeVariableMap[typeParameter] =
            JLocalTypeVariable(localFunction, typeParameter.name!, index));
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

  /// Returns `true` if [cls] implements `Function` either explicitly or through
  /// a `call` method.
  bool implementsFunction(IndexedClass cls) {
    KClassData data = classes.getData(cls);
    OrderedTypeSet orderedTypeSet = data.orderedTypeSet!;
    InterfaceType? supertype = orderedTypeSet.asInstanceOf(
        commonElements.functionClass,
        getHierarchyDepth(commonElements.functionClass as IndexedClass));
    if (supertype != null) {
      return true;
    }
    return data.callType?.withoutNullability is FunctionType;
  }

  /// Compute the kind of foreign helper function called by [node], if any.
  ForeignKind getForeignKind(ir.StaticInvocation node) {
    if (commonElements.isForeignHelper(getMember(node.target))) {
      return getForeignKindFromName(node.target.name.text);
    }
    return ForeignKind.NONE;
  }

  /// Computes the [InterfaceType] referenced by a call to the
  /// [JS_INTERCEPTOR_CONSTANT] function, if any.
  InterfaceType? getInterfaceTypeForJsInterceptorCall(
      ir.StaticInvocation node) {
    if (node.arguments.positional.length != 1 ||
        node.arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
          MessageKind.WRONG_ARGUMENT_FOR_JS_INTERCEPTOR_CONSTANT);
    }
    ir.Node argument = node.arguments.positional.first;
    if (argument is ir.TypeLiteral && argument.type is ir.InterfaceType) {
      return getInterfaceType(argument.type as ir.InterfaceType);
    } else if (argument is ir.ConstantExpression &&
        argument.constant is ir.TypeLiteralConstant) {
      ir.TypeLiteralConstant constant =
          argument.constant as ir.TypeLiteralConstant;
      if (constant.type is ir.InterfaceType) {
        return getInterfaceType(constant.type as ir.InterfaceType);
      }
    }
    return null;
  }

  /// Computes the native behavior for reading the native [field].
  /// TODO(johnniwinther): Cache this for later use.
  NativeBehavior getNativeBehaviorForFieldLoad(ir.Field field,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {required bool isJsInterop}) {
    DartType type = getDartType(field.type);
    return nativeBehaviorBuilder.buildFieldLoadBehavior(type,
        createsAnnotations, returnsAnnotations, typeLookup(resolveAsRaw: false),
        isJsInterop: isJsInterop);
  }

  /// Computes the native behavior for writing to the native [field].
  /// TODO(johnniwinther): Cache this for later use.
  NativeBehavior getNativeBehaviorForFieldStore(ir.Field field) {
    DartType type = getDartType(field.type);
    return nativeBehaviorBuilder.buildFieldStoreBehavior(type);
  }

  /// Computes the native behavior for calling the function or constructor
  /// [member].
  /// TODO(johnniwinther): Cache this for later use.
  NativeBehavior getNativeBehaviorForMethod(ir.Member member,
      Iterable<String> createsAnnotations, Iterable<String> returnsAnnotations,
      {required bool isJsInterop}) {
    late DartType type;
    if (member is ir.Procedure) {
      type = getFunctionType(member.function);
    } else if (member is ir.Constructor) {
      type = getFunctionType(member.function);
    } else {
      failedAt(CURRENT_ELEMENT_SPANNABLE, "Unexpected method node $member.");
    }
    return nativeBehaviorBuilder.buildMethodBehavior(type as FunctionType,
        createsAnnotations, returnsAnnotations, typeLookup(resolveAsRaw: false),
        isJsInterop: isJsInterop);
  }

  IndexedLibrary createLibrary(
      String name, Uri canonicalUri, bool isNonNullableByDefault) {
    return JLibrary(name, canonicalUri, isNonNullableByDefault);
  }

  IndexedClass createClass(JLibrary library, String name,
      {required bool isAbstract}) {
    return JClass(library, name, isAbstract: isAbstract);
  }

  IndexedTypeVariable createTypeVariable(
      Entity typeDeclaration, String name, int index) {
    return JTypeVariable(typeDeclaration, name, index);
  }

  IndexedConstructor createGenerativeConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {required bool isExternal, required bool isConst}) {
    return JGenerativeConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal, isConst: isConst);
  }

  // TODO(dart2js-team): Rename isFromEnvironmentConstructor to
  // isEnvironmentConstructor: Here, and everywhere in the compiler.
  IndexedConstructor createFactoryConstructor(
      JClass enclosingClass, Name name, ParameterStructure parameterStructure,
      {required bool isExternal,
      required bool isConst,
      required bool isFromEnvironmentConstructor}) {
    return JFactoryConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal,
        isConst: isConst,
        isFromEnvironmentConstructor: isFromEnvironmentConstructor);
  }

  IndexedFunction createGetter(JLibrary library, JClass? enclosingClass,
      Name name, AsyncMarker asyncMarker,
      {required bool isStatic,
      required bool isExternal,
      required bool isAbstract}) {
    return JGetter(library, enclosingClass, name, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createMethod(JLibrary library, JClass? enclosingClass,
      Name name, ParameterStructure parameterStructure, AsyncMarker asyncMarker,
      {required bool isStatic,
      required bool isExternal,
      required bool isAbstract}) {
    return JMethod(
        library, enclosingClass, name, parameterStructure, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createSetter(
      JLibrary library, JClass? enclosingClass, Name name,
      {required bool isStatic,
      required bool isExternal,
      required bool isAbstract}) {
    return JSetter(library, enclosingClass, name,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedField createField(JLibrary library, JClass? enclosingClass, Name name,
      {required bool isStatic,
      required bool isAssignable,
      required bool isConst}) {
    return JField(library, enclosingClass, name,
        isStatic: isStatic, isAssignable: isAssignable, isConst: isConst);
  }
}

class KernelElementEnvironment extends ElementEnvironment
    implements KElementEnvironment {
  final KernelToElementMap elementMap;

  KernelElementEnvironment(this.elementMap);

  @override
  DartType get dynamicType => elementMap.types.dynamicType();

  @override
  LibraryEntity? get mainLibrary => elementMap._mainLibrary;

  @override
  FunctionEntity? get mainFunction => elementMap._mainFunction;

  @override
  Iterable<LibraryEntity> get libraries => elementMap.libraryListInternal;

  @override
  String getLibraryName(LibraryEntity library) {
    return elementMap._getLibraryName(library as IndexedLibrary);
  }

  @override
  InterfaceType getThisType(ClassEntity cls) {
    return elementMap.getThisType(cls as IndexedClass);
  }

  @override
  InterfaceType getJsInteropType(ClassEntity cls) {
    return elementMap._getJsInteropType(cls as IndexedClass)!;
  }

  @override
  InterfaceType getRawType(ClassEntity cls) {
    return elementMap._getRawType(cls as IndexedClass);
  }

  @override
  InterfaceType getClassInstantiationToBounds(ClassEntity cls) =>
      elementMap._getClassInstantiationToBounds(cls as IndexedClass);

  @override
  bool isGenericClass(ClassEntity cls) {
    return getThisType(cls).typeArguments.isNotEmpty;
  }

  @override
  bool isMixinApplication(ClassEntity cls) {
    return elementMap._isMixinApplication(cls as IndexedClass);
  }

  @override
  bool isUnnamedMixinApplication(ClassEntity cls) {
    return elementMap._isUnnamedMixinApplication(cls as IndexedClass);
  }

  @override
  DartType getTypeVariableBound(TypeVariableEntity typeVariable) {
    if (typeVariable is JLocalTypeVariable) return typeVariable.bound;
    return elementMap.getTypeVariableBound(typeVariable as IndexedTypeVariable);
  }

  @override
  List<Variance> getTypeVariableVariances(ClassEntity cls) {
    return elementMap.getTypeVariableVariances(cls as IndexedClass);
  }

  @override
  InterfaceType createInterfaceType(
      ClassEntity cls, List<DartType> typeArguments) {
    return elementMap.types.interfaceType(cls, typeArguments);
  }

  @override
  FunctionType getFunctionType(FunctionEntity function) {
    return elementMap._getFunctionType(function as IndexedFunction);
  }

  @override
  List<TypeVariableType> getFunctionTypeVariables(FunctionEntity function) {
    return elementMap._getFunctionTypeVariables(function as IndexedFunction);
  }

  @override
  DartType getFieldType(FieldEntity field) {
    return elementMap._getFieldType(field as IndexedField);
  }

  @override
  FunctionType getLocalFunctionType(covariant JLocalFunction function) {
    return function.functionType;
  }

  @override
  ConstructorEntity? lookupConstructor(ClassEntity cls, String name,
      {bool required = false}) {
    ConstructorEntity? constructor =
        elementMap.lookupConstructor(cls as IndexedClass, name);
    if (constructor == null && required) {
      throw failedAt(
          CURRENT_ELEMENT_SPANNABLE,
          "The constructor '$name' was not found in class '${cls.name}' "
          "in library ${cls.library.canonicalUri}.");
    }
    return constructor;
  }

  @override
  MemberEntity? lookupLocalClassMember(ClassEntity cls, Name name,
      {bool required = false}) {
    MemberEntity? member =
        elementMap.lookupClassMember(cls as IndexedClass, name);
    if (member == null && required) {
      throw failedAt(CURRENT_ELEMENT_SPANNABLE,
          "The member '$name' was not found in ${cls.name}.");
    }
    return member;
  }

  @override
  ClassEntity? getSuperClass(ClassEntity cls,
      {bool skipUnnamedMixinApplications = false}) {
    ClassEntity? superclass =
        elementMap.getSuperType(cls as IndexedClass)?.element;
    if (skipUnnamedMixinApplications) {
      while (superclass != null &&
          elementMap._isUnnamedMixinApplication(superclass as IndexedClass)) {
        superclass = elementMap.getSuperType(superclass)?.element;
      }
    }
    return superclass;
  }

  @override
  void forEachSupertype(ClassEntity cls, void f(InterfaceType supertype)) {
    elementMap._forEachSupertype(cls as IndexedClass, f);
  }

  @override
  void forEachMixin(ClassEntity cls, void f(ClassEntity mixin)) {
    elementMap._forEachMixin(cls as IndexedClass, f);
  }

  @override
  void forEachLocalClassMember(ClassEntity cls, void f(MemberEntity member)) {
    elementMap._forEachLocalClassMember(cls as IndexedClass, f);
  }

  @override
  void forEachClassMember(
      ClassEntity cls, void f(ClassEntity declarer, MemberEntity member)) {
    elementMap._forEachClassMember(cls as IndexedClass, f);
  }

  @override
  void forEachConstructor(
      ClassEntity cls, void f(ConstructorEntity constructor)) {
    elementMap._forEachConstructor(cls as IndexedClass, f);
  }

  @override
  void forEachLibraryMember(
      LibraryEntity library, void f(MemberEntity member)) {
    elementMap._forEachLibraryMember(library as IndexedLibrary, f);
  }

  @override
  MemberEntity? lookupLibraryMember(LibraryEntity library, String name,
      {bool setter = false, bool required = false}) {
    MemberEntity? member = elementMap
        .lookupLibraryMember(library as IndexedLibrary, name, setter: setter);
    if (member == null && required) {
      failedAt(CURRENT_ELEMENT_SPANNABLE,
          "The member '${name}' was not found in library '${library.name}'.");
    }
    return member;
  }

  @override
  ClassEntity? lookupClass(LibraryEntity library, String name,
      {bool required = false}) {
    ClassEntity? cls = elementMap.lookupClass(library as IndexedLibrary, name);
    if (cls == null && required) {
      failedAt(CURRENT_ELEMENT_SPANNABLE,
          "The class '$name'  was not found in library '${library.name}'.");
    }
    return cls;
  }

  @override
  void forEachClass(LibraryEntity library, void f(ClassEntity cls)) {
    elementMap._forEachClass(library as IndexedLibrary, f);
  }

  @override
  LibraryEntity? lookupLibrary(Uri uri, {bool required = false}) {
    LibraryEntity? library = elementMap.lookupLibrary(uri);
    if (library == null && required) {
      failedAt(CURRENT_ELEMENT_SPANNABLE, "The library '$uri' was not found.");
    }
    return library;
  }

  @override
  Iterable<ImportEntity> getImports(covariant IndexedLibrary library) {
    KLibraryData libraryData = elementMap.libraries.getData(library);
    return libraryData.getImports(elementMap);
  }

  @override
  Iterable<ConstantValue> getMemberMetadata(covariant IndexedMember member,
      {bool includeParameterMetadata = false}) {
    // TODO(redemption): Support includeParameterMetadata.
    KMemberData memberData = elementMap.members.getData(member);
    return memberData.getMetadata(elementMap);
  }

  @override
  bool isEnumClass(ClassEntity cls) {
    KClassData classData = elementMap.classes.getData(cls as IndexedClass);
    return classData.isEnumClass;
  }

  @override
  ClassEntity? getEffectiveMixinClass(ClassEntity cls) {
    if (!isMixinApplication(cls)) return null;
    do {
      cls = elementMap.getAppliedMixin(cls as IndexedClass)!;
    } while (isMixinApplication(cls));
    return cls;
  }

  @override
  bool isLateBackingField(covariant IndexedField field) {
    KFieldData fieldData = elementMap.members.getData(field) as KFieldData;
    return fieldData.isLateBackingField;
  }

  @override
  bool isLateFinalBackingField(covariant IndexedField field) {
    KFieldData fieldData = elementMap.members.getData(field) as KFieldData;
    return fieldData.isLateFinalBackingField;
  }
}

class KernelNativeMemberResolver {
  static final RegExp _identifier = RegExp(r'^[a-zA-Z_$][a-zA-Z0-9_$]*$');

  final KernelToElementMap _elementMap;
  final NativeBasicData _nativeBasicData;
  final NativeDataBuilder? _nativeDataBuilder;

  KernelNativeMemberResolver(
      this._elementMap, this._nativeBasicData, this._nativeDataBuilder);

  /// Computes whether [node] is native or JsInterop.
  void resolveNativeMember(ir.Member node, IrAnnotationData annotationData) {
    bool isJsInterop = _isJsInteropMember(node);
    if (node is ir.Procedure || node is ir.Constructor) {
      FunctionEntity method = _elementMap.getMember(node) as FunctionEntity;
      bool isNative = _processMethodAnnotations(node, annotationData);
      if (isNative || isJsInterop) {
        NativeBehavior behavior = _computeNativeMethodBehavior(
            method as JFunction, annotationData,
            isJsInterop: isJsInterop);
        _nativeDataBuilder!.setNativeMethodBehavior(method, behavior);
      }
    } else if (node is ir.Field) {
      FieldEntity field = _elementMap.getMember(node) as FieldEntity;
      bool isNative = _processFieldAnnotations(node, annotationData);
      if (isNative || isJsInterop) {
        NativeBehavior fieldLoadBehavior = _computeNativeFieldLoadBehavior(
            field as JField, annotationData,
            isJsInterop: isJsInterop);
        NativeBehavior fieldStoreBehavior =
            _computeNativeFieldStoreBehavior(field);
        _nativeDataBuilder!
            .setNativeFieldLoadBehavior(field, fieldLoadBehavior);
        _nativeDataBuilder!
            .setNativeFieldStoreBehavior(field, fieldStoreBehavior);
      }
    }
  }

  /// Process the potentially native [field]. Adds information from metadata
  /// attributes. Returns `true` of [method] is native.
  bool _processFieldAnnotations(
      ir.Field node, IrAnnotationData annotationData) {
    if (node.isInstanceMember &&
        _nativeBasicData
            .isNativeClass(_elementMap.getClass(node.enclosingClass!))) {
      // Exclude non-instance (static) fields - they are not really native and
      // are compiled as isolate globals.  Access of a property of a constructor
      // function or a non-method property in the prototype chain, must be coded
      // using a JS-call.
      _setNativeName(node, annotationData);
      return true;
    } else {
      String? name = _findJsNameFromAnnotation(node, annotationData);
      if (name != null) {
        failedAt(
            computeSourceSpanFromTreeNode(node),
            '@JSName(...) annotation is not supported for static fields: '
            '$node.');
      }
    }
    return false;
  }

  /// Process the potentially native [method]. Adds information from metadata
  /// attributes. Returns `true` of [method] is native.
  bool _processMethodAnnotations(
      ir.Member node, IrAnnotationData annotationData) {
    if (_isNativeMethod(node, annotationData)) {
      if (node.enclosingClass != null && !node.isInstanceMember) {
        if (!_nativeBasicData
            .isNativeClass(_elementMap.getClass(node.enclosingClass!))) {
          _elementMap.reporter.reportErrorMessage(
              computeSourceSpanFromTreeNode(node),
              MessageKind.NATIVE_NON_INSTANCE_IN_NON_NATIVE_CLASS);
          return false;
        }
        _setNativeNameForStaticMethod(node, annotationData);
      } else {
        _setNativeName(node, annotationData);
      }
      return true;
    }
    return false;
  }

  /// Sets the native name of [element], either from an annotation, or
  /// defaulting to the Dart name.
  void _setNativeName(ir.Member node, IrAnnotationData annotationData) {
    String? name = _findJsNameFromAnnotation(node, annotationData);
    name ??= node.name.text;
    _nativeDataBuilder!.setNativeMemberName(_elementMap.getMember(node), name);
  }

  /// Sets the native name of the static native method [element], using the
  /// following rules:
  /// 1. If [element] has a @JSName annotation that is an identifier, qualify
  ///    that identifier to the @Native name of the enclosing class
  /// 2. If [element] has a @JSName annotation that is not an identifier,
  ///    use the declared @JSName as the expression
  /// 3. If [element] does not have a @JSName annotation, qualify the name of
  ///    the method with the @Native name of the enclosing class.
  void _setNativeNameForStaticMethod(
      ir.Member node, IrAnnotationData annotationData) {
    String? name = _findJsNameFromAnnotation(node, annotationData);
    name ??= node.name.text;
    if (_isIdentifier(name)) {
      ClassEntity cls = _elementMap.getClass(node.enclosingClass!);
      List<String> nativeNames = _nativeBasicData.getNativeTagsOfClass(cls);
      if (nativeNames.length != 1) {
        failedAt(
            computeSourceSpanFromTreeNode(node),
            'Unable to determine a native name for the enclosing class, '
            'options: $nativeNames');
      }
      _nativeDataBuilder!.setNativeMemberName(
          _elementMap.getMember(node), '${nativeNames[0]}.$name');
    } else {
      _nativeDataBuilder!
          .setNativeMemberName(_elementMap.getMember(node), name);
    }
  }

  bool _isIdentifier(String s) => _identifier.hasMatch(s);

  /// Returns the JSName annotation string or `null` if no JSName annotation is
  /// present.
  String? _findJsNameFromAnnotation(
      ir.Member node, IrAnnotationData annotationData) {
    return annotationData.getNativeMemberName(node);
  }

  NativeBehavior _computeNativeFieldStoreBehavior(covariant JField field) {
    ir.Field node = _elementMap.getMemberNode(field) as ir.Field;
    return _elementMap.getNativeBehaviorForFieldStore(node);
  }

  NativeBehavior _computeNativeFieldLoadBehavior(
      JField field, IrAnnotationData annotationData,
      {required bool isJsInterop}) {
    ir.Field node = _elementMap.getMemberNode(field) as ir.Field;
    Iterable<String> createsAnnotations =
        annotationData.getCreatesAnnotations(node);
    Iterable<String> returnsAnnotations =
        annotationData.getReturnsAnnotations(node);
    return _elementMap.getNativeBehaviorForFieldLoad(
        node, createsAnnotations, returnsAnnotations,
        isJsInterop: isJsInterop);
  }

  NativeBehavior _computeNativeMethodBehavior(
      JFunction function, IrAnnotationData annotationData,
      {required bool isJsInterop}) {
    ir.Member node = _elementMap.getMemberNode(function);
    Iterable<String> createsAnnotations =
        annotationData.getCreatesAnnotations(node);
    Iterable<String> returnsAnnotations =
        annotationData.getReturnsAnnotations(node);
    return _elementMap.getNativeBehaviorForMethod(
        node, createsAnnotations, returnsAnnotations,
        isJsInterop: isJsInterop);
  }

  bool _isNativeMethod(ir.Member node, IrAnnotationData annotationData) {
    if (!maybeEnableNative(node.enclosingLibrary.importUri)) return false;
    bool hasNativeBody = annotationData.hasNativeBody(node);
    // TODO(rileyporter): Move this check on non-native external usage to
    // js_interop_checks when `native` and `external` can be disambiguated.
    if (!hasNativeBody &&
        node.isExternal &&
        !_nativeBasicData.isJsInteropMember(_elementMap.getMember(node))) {
      // TODO(johnniwinther): Should we change dart:html and friends to use
      //  `external` instead of the native body syntax?
      _elementMap.reporter.reportErrorMessage(
          computeSourceSpanFromTreeNode(node), MessageKind.NON_NATIVE_EXTERNAL);
    }
    return hasNativeBody;
  }

  bool _isJsInteropMember(ir.Member node) {
    return _nativeBasicData.isJsInteropMember(_elementMap.getMember(node));
  }
}

DiagnosticMessage _createDiagnosticMessage(
    DiagnosticReporter reporter, ir.LocatedMessage message) {
  SourceSpan sourceSpan = SourceSpan(
      message.uri!, message.charOffset, message.charOffset + message.length);
  return reporter.createMessage(
      sourceSpan, MessageKind.GENERIC, {'text': message.problemMessage});
}

void reportLocatedMessage(DiagnosticReporter reporter,
    ir.LocatedMessage message, List<ir.LocatedMessage>? context) {
  DiagnosticMessage diagnosticMessage =
      _createDiagnosticMessage(reporter, message);
  List<DiagnosticMessage> infos = [];
  for (ir.LocatedMessage message in context ?? const []) {
    infos.add(_createDiagnosticMessage(reporter, message));
  }
  reporter.reportError(diagnosticMessage, infos);
}

ForeignKind getForeignKindFromName(String name) {
  switch (name) {
    case Identifiers.JS:
      return ForeignKind.JS;
    case Identifiers.JS_BUILTIN:
      return ForeignKind.JS_BUILTIN;
    case Identifiers.JS_EMBEDDED_GLOBAL:
      return ForeignKind.JS_EMBEDDED_GLOBAL;
    case Identifiers.JS_INTERCEPTOR_CONSTANT:
      return ForeignKind.JS_INTERCEPTOR_CONSTANT;
    default:
      return ForeignKind.NONE;
  }
}
