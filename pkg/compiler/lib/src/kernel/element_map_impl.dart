// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.kernel.element_map;

import 'package:kernel/ast.dart' as ir;

import '../closure.dart' show BoxLocal, ThisLocal;
import '../common.dart';
import '../common/names.dart' show Identifiers;
import '../common/resolution.dart';
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/constructors.dart';
import '../constants/evaluation.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../common_elements.dart';
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
import '../ordered_typeset.dart';
import '../options.dart';
import '../ssa/kernel_impact.dart';
import '../universe/class_set.dart';
import '../universe/selector.dart';
import '../universe/world_builder.dart';
import '../world.dart';
import '../util/util.dart' show Link, LinkBuilder;
import 'element_map.dart';
import 'element_map_mixins.dart';
import 'elements.dart';
import 'env.dart';
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
  final DiagnosticReporter reporter;
  CommonElements _commonElements;
  ElementEnvironment _elementEnvironment;
  DartTypeConverter _typeConverter;
  KernelConstantEnvironment _constantEnvironment;
  _KernelDartTypes _types;

  /// Library environment. Used for fast lookup.
  ProgramEnv _env = new ProgramEnv();

  List<LibraryEntity> _libraryList = <LibraryEntity>[];
  List<ClassEntity> _classList = <ClassEntity>[];
  List<MemberEntity> _memberList = <MemberEntity>[];
  List<TypeVariableEntity> _typeVariableList = <TypeVariableEntity>[];
  List<TypedefEntity> _typedefList = <TypedefEntity>[];

  /// List of library environments by `IndexedLibrary.libraryIndex`. This is
  /// used for fast lookup into library classes and members.
  List<LibraryEnv> _libraryEnvs = <LibraryEnv>[];

  /// List of library data by `IndexedLibrary.libraryIndex`. This is used for
  /// fast lookup into library properties.
  List<LibraryData> _libraryData = <LibraryData>[];

  /// List of class environments by `IndexedClass.classIndex`. This is used for
  /// fast lookup into class members.
  List<ClassEnv> _classEnvs = <ClassEnv>[];

  /// List of class data by `IndexedClass.classIndex`. This is used for
  /// fast lookup into class properties.
  List<ClassData> _classData = <ClassData>[];

  /// List of member data by `IndexedMember.memberIndex`. This is used for
  /// fast lookup into member properties.
  List<MemberData> _memberData = <MemberData>[];

  /// List of typedef data by `IndexedTypedef.typedefIndex`. This is used for
  /// fast lookup into typedef properties.
  List<TypedefData> _typedefData = <TypedefData>[];

  KernelToElementMapBase(this.reporter, Environment environment) {
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

  Iterable<LibraryEntity> get _libraries;

  SourceSpan getSourceSpan(Spannable spannable, Entity currentElement) {
    SourceSpan fromSpannable(Spannable spannable) {
      if (spannable is IndexedLibrary &&
          spannable.libraryIndex < _libraryEnvs.length) {
        LibraryEnv env = _libraryEnvs[spannable.libraryIndex];
        return computeSourceSpanFromTreeNode(env.library);
      } else if (spannable is IndexedClass &&
          spannable.classIndex < _classEnvs.length) {
        ClassData data = _classData[spannable.classIndex];
        return data.definition.location;
      } else if (spannable is IndexedMember &&
          spannable.memberIndex < _memberData.length) {
        MemberData data = _memberData[spannable.memberIndex];
        return data.definition.location;
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
    LibraryEnv libraryEnv = _libraryEnvs[library.libraryIndex];
    return libraryEnv.library.name ?? '';
  }

  MemberEntity lookupLibraryMember(IndexedLibrary library, String name,
      {bool setter: false}) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraryEnvs[library.libraryIndex];
    ir.Member member = libraryEnv.lookupMember(name, setter: setter);
    return member != null ? getMember(member) : null;
  }

  void _forEachLibraryMember(
      IndexedLibrary library, void f(MemberEntity member)) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraryEnvs[library.libraryIndex];
    libraryEnv.forEachMember((ir.Member node) {
      f(getMember(node));
    });
  }

  ClassEntity lookupClass(IndexedLibrary library, String name) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraryEnvs[library.libraryIndex];
    ClassEnv classEnv = libraryEnv.lookupClass(name);
    if (classEnv != null) {
      return _getClass(classEnv.cls, classEnv);
    }
    return null;
  }

  void _forEachClass(IndexedLibrary library, void f(ClassEntity cls)) {
    assert(checkFamily(library));
    LibraryEnv libraryEnv = _libraryEnvs[library.libraryIndex];
    libraryEnv.forEachClass((ClassEnv classEnv) {
      if (!classEnv.isUnnamedMixinApplication) {
        f(_getClass(classEnv.cls, classEnv));
      }
    });
  }

  MemberEntity lookupClassMember(IndexedClass cls, String name,
      {bool setter: false}) {
    assert(checkFamily(cls));
    ClassEnv classEnv = _classEnvs[cls.classIndex];
    return classEnv.lookupMember(this, name, setter: setter);
  }

  ConstructorEntity lookupConstructor(IndexedClass cls, String name) {
    assert(checkFamily(cls));
    ClassEnv classEnv = _classEnvs[cls.classIndex];
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
    ClassData data = _classData[cls.classIndex];
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
          ClassData superdata = _classData[superclass.classIndex];
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
    return _typedefData[typedef.typedefIndex].rawType;
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

  MemberEntity getSuperMember(ir.Member context, ir.Name name, ir.Member target,
      {bool setter: false}) {
    if (target != null) {
      return getMember(target);
    }
    ClassEntity cls = getMember(context).enclosingClass;
    IndexedClass superclass = _getSuperType(cls)?.element;
    while (superclass != null) {
      ClassEnv env = _classEnvs[superclass.classIndex];
      MemberEntity superMember =
          env.lookupMember(this, name.name, setter: setter);
      if (superMember != null) {
        return superMember;
      }
      superclass = _getSuperType(superclass)?.element;
    }
    throw failedAt(cls, "No super method member found for ${name} in $cls.");
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
    ClassEnv env = _classEnvs[superClass.classIndex];
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
    return new FunctionType(returnType, parameterTypes, optionalParameterTypes,
        namedParameters, namedParameterTypes);
  }

  @override
  ConstantValue computeConstantValue(ConstantExpression constant,
      {bool requireConstant: true}) {
    return _constantEnvironment.getConstantValue(constant);
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
          data.callType = new FunctionType(dynamic, requiredParameterTypes,
              optionalParameterTypes, namedParameters, namedParameterTypes);
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
    ClassData data = _classData[cls.classIndex];
    _ensureCallType(cls, data);
    if (data.callType != null) {
      return _substByContext(data.callType, type);
    }
    return null;
  }

  InterfaceType _getThisType(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
    _ensureThisAndRawType(cls, data);
    return data.thisType;
  }

  InterfaceType _getRawType(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
    _ensureThisAndRawType(cls, data);
    return data.rawType;
  }

  FunctionType _getFunctionType(IndexedFunction function) {
    assert(checkFamily(function));
    FunctionData data = _memberData[function.memberIndex];
    return data.getFunctionType(this);
  }

  DartType _getFieldType(IndexedField field) {
    assert(checkFamily(field));
    FieldData data = _memberData[field.memberIndex];
    return data.getFieldType(this);
  }

  ClassEntity _getAppliedMixin(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
    _ensureSupertypes(cls, data);
    return data.mixedInType?.element;
  }

  bool _isMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
    _ensureSupertypes(cls, data);
    return data.isMixinApplication;
  }

  bool _isUnnamedMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassEnv env = _classEnvs[cls.classIndex];
    return env.isUnnamedMixinApplication;
  }

  void _forEachSupertype(IndexedClass cls, void f(InterfaceType supertype)) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
    _ensureSupertypes(cls, data);
    data.orderedTypeSet.supertypes.forEach(f);
  }

  void _forEachMixin(IndexedClass cls, void f(ClassEntity mixin)) {
    assert(checkFamily(cls));
    while (cls != null) {
      ClassData data = _classData[cls.classIndex];
      _ensureSupertypes(cls, data);
      if (data.mixedInType != null) {
        f(data.mixedInType.element);
      }
      cls = data.supertype?.element;
    }
  }

  void _forEachConstructor(IndexedClass cls, void f(ConstructorEntity member)) {
    assert(checkFamily(cls));
    ClassEnv env = _classEnvs[cls.classIndex];
    env.forEachConstructor(this, f);
  }

  void _forEachConstructorBody(
      IndexedClass cls, void f(ConstructorBodyEntity member)) {
    throw new UnsupportedError(
        'KernelToElementMapBase._forEachConstructorBody');
  }

  void _forEachClassMember(
      IndexedClass cls, void f(ClassEntity cls, MemberEntity member)) {
    assert(checkFamily(cls));
    ClassEnv env = _classEnvs[cls.classIndex];
    env.forEachMember(this, (MemberEntity member) {
      f(cls, member);
    });
    ClassData data = _classData[cls.classIndex];
    _ensureSupertypes(cls, data);
    if (data.supertype != null) {
      _forEachClassMember(data.supertype.element, f);
    }
  }

  ConstantConstructor _getConstructorConstant(IndexedConstructor constructor) {
    assert(checkFamily(constructor));
    ConstructorData data = _memberData[constructor.memberIndex];
    return data.getConstructorConstant(this, constructor);
  }

  ConstantExpression _getFieldConstantExpression(IndexedField field) {
    assert(checkFamily(field));
    FieldData data = _memberData[field.memberIndex];
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
    ClassData data = _classData[cls.classIndex];
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet;
  }

  int _getHierarchyDepth(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet.maxDepth;
  }

  Iterable<InterfaceType> _getInterfaces(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
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
    return _memberData[member.memberIndex].definition;
  }

  ClassDefinition _getClassDefinition(covariant IndexedClass cls) {
    assert(checkFamily(cls));
    return _classData[cls.classIndex].definition;
  }
}

/// Mixin that implements the abstract methods in [KernelToElementMapBase].
abstract class ElementCreatorMixin {
  ProgramEnv get _env;
  List<LibraryEntity> get _libraryList;
  List<LibraryEnv> get _libraryEnvs;
  List<LibraryData> get _libraryData;
  List<ClassEntity> get _classList;
  List<ClassEnv> get _classEnvs;
  List<ClassData> get _classData;
  List<MemberEntity> get _memberList;
  List<MemberData> get _memberData;
  List<TypeVariableEntity> get _typeVariableList;
  List<TypedefEntity> get _typedefList;
  List<TypedefData> get _typedefData;

  Map<ir.Library, IndexedLibrary> _libraryMap = <ir.Library, IndexedLibrary>{};
  Map<ir.Class, IndexedClass> _classMap = <ir.Class, IndexedClass>{};
  Map<ir.Typedef, IndexedTypedef> _typedefMap = <ir.Typedef, IndexedTypedef>{};
  Map<ir.TypeParameter, IndexedTypeVariable> _typeVariableMap =
      <ir.TypeParameter, IndexedTypeVariable>{};
  Map<ir.Member, IndexedConstructor> _constructorMap =
      <ir.Member, IndexedConstructor>{};
  Map<ir.Procedure, IndexedFunction> _methodMap =
      <ir.Procedure, IndexedFunction>{};
  Map<ir.Field, IndexedField> _fieldMap = <ir.Field, IndexedField>{};
  Map<ir.TreeNode, Local> _localFunctionMap = <ir.TreeNode, Local>{};

  Name getName(ir.Name node);
  FunctionType getFunctionType(ir.FunctionNode node);
  MemberEntity getMember(ir.Member node);

  Iterable<LibraryEntity> get _libraries {
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
      _libraryEnvs.add(libraryEnv ?? _env.lookupLibrary(canonicalUri));
      String name = node.name;
      if (name == null) {
        // Use the file name as script name.
        String path = canonicalUri.path;
        name = path.substring(path.lastIndexOf('/') + 1);
      }
      LibraryEntity library =
          createLibrary(_libraryMap.length, name, canonicalUri);
      _libraryList.add(library);
      _libraryData.add(new LibraryData(node));
      return library;
    });
  }

  ClassEntity _getClass(ir.Class node, [ClassEnv classEnv]) {
    return _classMap.putIfAbsent(node, () {
      KLibrary library = _getLibrary(node.enclosingLibrary);
      if (classEnv == null) {
        classEnv = _libraryEnvs[library.libraryIndex].lookupClass(node.name);
      }
      _classEnvs.add(classEnv);
      ClassEntity cls = createClass(library, _classList.length, node.name,
          isAbstract: node.isAbstract);
      _classData
          .add(new ClassData(node, new RegularClassDefinition(cls, node)));
      _classList.add(cls);
      return cls;
    });
  }

  TypedefEntity _getTypedef(ir.Typedef node) {
    return _typedefMap.putIfAbsent(node, () {
      IndexedLibrary library = _getLibrary(node.enclosingLibrary);
      TypedefEntity typedef =
          createTypedef(library, _typedefList.length, node.name);
      TypedefType typedefType = new TypedefType(
          typedef,
          new List<DartType>.filled(
              node.typeParameters.length, const DynamicType()));
      _typedefData.add(new TypedefData(node, typedef, typedefType));
      _typedefList.add(typedef);
      return typedef;
    });
  }

  TypeVariableEntity _getTypeVariable(ir.TypeParameter node) {
    return _typeVariableMap.putIfAbsent(node, () {
      if (node.parent is ir.Class) {
        int typeVariableIndex = _typeVariableList.length;
        ir.Class cls = node.parent;
        int index = cls.typeParameters.indexOf(node);
        TypeVariableEntity typeVariable = createTypeVariable(
            typeVariableIndex, _getClass(cls), node.name, index);
        _typeVariableList.add(typeVariable);
        return typeVariable;
      }
      if (node.parent is ir.FunctionNode) {
        ir.FunctionNode func = node.parent;
        int index = func.typeParameters.indexOf(node);
        if (func.parent is ir.Constructor) {
          ir.Constructor constructor = func.parent;
          ir.Class cls = constructor.enclosingClass;
          return _getTypeVariable(cls.typeParameters[index]);
        }
        if (func.parent is ir.Procedure) {
          ir.Procedure procedure = func.parent;
          if (procedure.kind == ir.ProcedureKind.Factory) {
            ir.Class cls = procedure.enclosingClass;
            return _getTypeVariable(cls.typeParameters[index]);
          } else {
            int typeVariableIndex = _typeVariableList.length;
            TypeVariableEntity typeVariable = createTypeVariable(
                typeVariableIndex, _getMethod(procedure), node.name, index);
            _typeVariableList.add(typeVariable);
            return typeVariable;
          }
        }
      }
      throw new UnsupportedError('Unsupported type parameter type node $node.');
    });
  }

  ConstructorEntity _getConstructor(ir.Member node) {
    return _constructorMap.putIfAbsent(node, () {
      int memberIndex = _memberData.length;
      ConstructorEntity constructor;
      ClassEntity enclosingClass = _getClass(node.enclosingClass);
      Name name = getName(node.name);
      bool isExternal = node.isExternal;

      ir.FunctionNode functionNode;
      MemberDefinition definition;
      if (node is ir.Constructor) {
        functionNode = node.function;
        constructor = createGenerativeConstructor(memberIndex, enclosingClass,
            name, _getParameterStructure(functionNode),
            isExternal: isExternal, isConst: node.isConst);
        definition = new SpecialMemberDefinition(
            constructor, node, MemberKind.constructor);
      } else if (node is ir.Procedure) {
        functionNode = node.function;
        bool isFromEnvironment = isExternal &&
            name.text == 'fromEnvironment' &&
            const ['int', 'bool', 'String'].contains(enclosingClass.name);
        constructor = createFactoryConstructor(memberIndex, enclosingClass,
            name, _getParameterStructure(functionNode),
            isExternal: isExternal,
            isConst: node.isConst,
            isFromEnvironmentConstructor: isFromEnvironment);
        definition = new RegularMemberDefinition(constructor, node);
      } else {
        // TODO(johnniwinther): Convert `node.location` to a [SourceSpan].
        throw failedAt(
            NO_LOCATION_SPANNABLE, "Unexpected constructor node: ${node}.");
      }
      _memberData.add(new ConstructorDataImpl(node, functionNode, definition));
      _memberList.add(constructor);
      return constructor;
    });
  }

  AsyncMarker _getAsyncMarker(ir.FunctionNode node) {
    switch (node.asyncMarker) {
      case ir.AsyncMarker.Async:
        return AsyncMarker.ASYNC;
      case ir.AsyncMarker.AsyncStar:
        return AsyncMarker.ASYNC_STAR;
      case ir.AsyncMarker.Sync:
        return AsyncMarker.SYNC;
      case ir.AsyncMarker.SyncStar:
        return AsyncMarker.SYNC_STAR;
      case ir.AsyncMarker.SyncYielding:
      default:
        throw new UnsupportedError(
            "Async marker ${node.asyncMarker} is not supported.");
    }
  }

  FunctionEntity _getMethod(ir.Procedure node) {
    return _methodMap.putIfAbsent(node, () {
      int memberIndex = _memberData.length;
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
      bool isAbstract = node.isAbstract;
      IndexedFunction function;
      AsyncMarker asyncMarker = _getAsyncMarker(node.function);
      switch (node.kind) {
        case ir.ProcedureKind.Factory:
          throw new UnsupportedError("Cannot create method from factory.");
        case ir.ProcedureKind.Getter:
          function = createGetter(
              memberIndex, library, enclosingClass, name, asyncMarker,
              isStatic: isStatic,
              isExternal: isExternal,
              isAbstract: isAbstract);
          break;
        case ir.ProcedureKind.Method:
        case ir.ProcedureKind.Operator:
          function = createMethod(memberIndex, library, enclosingClass, name,
              _getParameterStructure(node.function), asyncMarker,
              isStatic: isStatic,
              isExternal: isExternal,
              isAbstract: isAbstract);
          break;
        case ir.ProcedureKind.Setter:
          assert(asyncMarker == AsyncMarker.SYNC);
          function = createSetter(
              memberIndex, library, enclosingClass, name.setter,
              isStatic: isStatic,
              isExternal: isExternal,
              isAbstract: isAbstract);
          break;
      }
      _memberData.add(new FunctionDataImpl(
          node, node.function, new RegularMemberDefinition(function, node)));
      _memberList.add(function);
      return function;
    });
  }

  FieldEntity _getField(ir.Field node) {
    return _fieldMap.putIfAbsent(node, () {
      int memberIndex = _memberData.length;
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
      FieldEntity field = createField(
          memberIndex, library, enclosingClass, name,
          isStatic: isStatic,
          isAssignable: node.isMutable,
          isConst: node.isConst);
      _memberData.add(
          new FieldDataImpl(node, new RegularMemberDefinition(field, node)));
      _memberList.add(field);
      return field;
    });
  }

  ParameterStructure _getParameterStructure(ir.FunctionNode node) {
    // TODO(johnniwinther): Cache the computed function type.
    int requiredParameters = node.requiredParameterCount;
    int positionalParameters = node.positionalParameters.length;
    List<String> namedParameters =
        node.namedParameters.map((p) => p.name).toList()..sort();
    return new ParameterStructure(
        requiredParameters, positionalParameters, namedParameters);
  }

  IndexedLibrary createLibrary(int libraryIndex, String name, Uri canonicalUri);

  IndexedClass createClass(LibraryEntity library, int classIndex, String name,
      {bool isAbstract});

  IndexedTypedef createTypedef(
      LibraryEntity library, int typedefIndex, String name);

  TypeVariableEntity createTypeVariable(
      int typeVariableIndex, Entity typeDeclaration, String name, int index);

  IndexedConstructor createGenerativeConstructor(
      int memberIndex,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      {bool isExternal,
      bool isConst});

  IndexedConstructor createFactoryConstructor(
      int memberIndex,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      {bool isExternal,
      bool isConst,
      bool isFromEnvironmentConstructor});

  IndexedFunction createGetter(int memberIndex, LibraryEntity library,
      ClassEntity enclosingClass, Name name, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, bool isAbstract});

  IndexedFunction createMethod(
      int memberIndex,
      LibraryEntity library,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      AsyncMarker asyncMarker,
      {bool isStatic,
      bool isExternal,
      bool isAbstract});

  IndexedFunction createSetter(int memberIndex, LibraryEntity library,
      ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isExternal, bool isAbstract});

  IndexedField createField(int memberIndex, LibraryEntity library,
      ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isAssignable, bool isConst});
}

/// Completes the [ElementCreatorMixin] by creating K-model elements.
abstract class KElementCreatorMixin implements ElementCreatorMixin {
  IndexedLibrary createLibrary(
      int libraryIndex, String name, Uri canonicalUri) {
    return new KLibrary(libraryIndex, name, canonicalUri);
  }

  IndexedClass createClass(LibraryEntity library, int classIndex, String name,
      {bool isAbstract}) {
    return new KClass(library, classIndex, name, isAbstract: isAbstract);
  }

  @override
  IndexedTypedef createTypedef(
      LibraryEntity library, int typedefIndex, String name) {
    throw new UnsupportedError('KElementCreatorMixin.createTypedef');
  }

  TypeVariableEntity createTypeVariable(
      int typeVariableIndex, Entity typeDeclaration, String name, int index) {
    return new KTypeVariable(typeVariableIndex, typeDeclaration, name, index);
  }

  IndexedConstructor createGenerativeConstructor(
      int memberIndex,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      {bool isExternal,
      bool isConst}) {
    return new KGenerativeConstructor(
        memberIndex, enclosingClass, name, parameterStructure,
        isExternal: isExternal, isConst: isConst);
  }

  IndexedConstructor createFactoryConstructor(
      int memberIndex,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      {bool isExternal,
      bool isConst,
      bool isFromEnvironmentConstructor}) {
    return new KFactoryConstructor(
        memberIndex, enclosingClass, name, parameterStructure,
        isExternal: isExternal,
        isConst: isConst,
        isFromEnvironmentConstructor: isFromEnvironmentConstructor);
  }

  IndexedFunction createGetter(int memberIndex, LibraryEntity library,
      ClassEntity enclosingClass, Name name, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new KGetter(memberIndex, library, enclosingClass, name, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createMethod(
      int memberIndex,
      LibraryEntity library,
      ClassEntity enclosingClass,
      Name name,
      ParameterStructure parameterStructure,
      AsyncMarker asyncMarker,
      {bool isStatic,
      bool isExternal,
      bool isAbstract}) {
    return new KMethod(memberIndex, library, enclosingClass, name,
        parameterStructure, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createSetter(int memberIndex, LibraryEntity library,
      ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new KSetter(memberIndex, library, enclosingClass, name,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedField createField(int memberIndex, LibraryEntity library,
      ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isAssignable, bool isConst}) {
    return new KField(memberIndex, library, enclosingClass, name,
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
  CompilerOptions _options;

  KernelToElementMapForImpactImpl(DiagnosticReporter reporter,
      Environment environment, this._frontendStrategy, this._options)
      : super(reporter, environment);

  @override
  bool checkFamily(Entity entity) {
    assert(
        '$entity'.startsWith(kElementPrefix),
        failedAt(entity,
            "Unexpected entity $entity, expected family $kElementPrefix."));
    return true;
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
          commonElements, nativeBasicData, reporter, _options);

  ResolutionImpact computeWorldImpact(KMember member) {
    return buildKernelImpact(
        _memberData[member.memberIndex].definition.node, this);
  }

  ScopeModel computeScopeModel(KMember member) {
    ir.Member node = _memberData[member.memberIndex].definition.node;
    return KernelClosureAnalysis.computeScopeModel(member, node);
  }

  /// Returns the kernel [ir.Procedure] node for the [method].
  ir.Procedure _lookupProcedure(KFunction method) {
    return _memberData[method.memberIndex].definition.node;
  }

  @override
  Local getLocalFunction(ir.TreeNode node) {
    assert(
        node is ir.FunctionDeclaration || node is ir.FunctionExpression,
        failedAt(
            CURRENT_ELEMENT_SPANNABLE, 'Invalid local function node: $node'));
    return _localFunctionMap.putIfAbsent(node, () {
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
          Local localFunction = getLocalFunction(parent);
          executableContext = localFunction;
          memberContext = localFunction.memberContext;
          break;
        }
        parent = parent.parent;
      }
      String name;
      FunctionType functionType;
      if (node is ir.FunctionDeclaration) {
        name = node.variable.name;
        functionType = getFunctionType(node.function);
      } else if (node is ir.FunctionExpression) {
        functionType = getFunctionType(node.function);
      }
      return new KLocalFunction(
          name, memberContext, executableContext, functionType);
    });
  }

  bool _implementsFunction(IndexedClass cls) {
    assert(checkFamily(cls));
    ClassData data = _classData[cls.classIndex];
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
}

class KernelElementEnvironment implements ElementEnvironment {
  final KernelToElementMapBase elementMap;

  KernelElementEnvironment(this.elementMap);

  @override
  DartType get dynamicType => const DynamicType();

  @override
  LibraryEntity get mainLibrary => elementMap._mainLibrary;

  @override
  FunctionEntity get mainFunction => elementMap._mainFunction;

  @override
  Iterable<LibraryEntity> get libraries => elementMap._libraries;

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
    throw new UnimplementedError(
        'KernelElementEnvironment.getTypeVariableBound');
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
  DartType getFieldType(FieldEntity field) {
    return elementMap._getFieldType(field);
  }

  @override
  FunctionType getLocalFunctionType(covariant KLocalFunction function) {
    return function.functionType;
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
  MemberEntity lookupClassMember(ClassEntity cls, String name,
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
  void forEachClassMember(
      ClassEntity cls, void f(ClassEntity declarer, MemberEntity member)) {
    elementMap._forEachClassMember(cls, f);
  }

  @override
  void forEachConstructor(
      ClassEntity cls, void f(ConstructorEntity constructor)) {
    elementMap._forEachConstructor(cls, f);
  }

  @override
  void forEachConstructorBody(
      ClassEntity cls, void f(ConstructorBodyEntity constructor)) {
    elementMap._forEachConstructorBody(cls, f);
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
    // TODO(redemption): Support these.
    return false;
  }

  @override
  Iterable<ConstantValue> getLibraryMetadata(covariant IndexedLibrary library) {
    LibraryData libraryData = elementMap._libraryData[library.libraryIndex];
    return libraryData.getMetadata(elementMap);
  }

  @override
  Iterable<ConstantValue> getClassMetadata(covariant IndexedClass cls) {
    ClassData classData = elementMap._classData[cls.classIndex];
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
    MemberData memberData = elementMap._memberData[member.memberIndex];
    return memberData.getMetadata(elementMap);
  }

  @override
  FunctionType getFunctionTypeOfTypedef(TypedefEntity typedef) {
    // TODO(redemption): Support this.
    throw new UnsupportedError('ElementEnvironment.getTypedefAlias');
  }
}

/// Visitor that converts kernel dart types into [DartType].
class DartTypeConverter extends ir.DartTypeVisitor<DartType> {
  final KernelToElementMapBase elementMap;
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
    return new TypeVariableType(elementMap.getTypeVariable(node.parameter));
  }

  @override
  DartType visitFunctionType(ir.FunctionType node) {
    return new FunctionType(
        visitType(node.returnType),
        visitTypes(node.positionalParameters
            .take(node.requiredParameterCount)
            .toList()),
        visitTypes(node.positionalParameters
            .skip(node.requiredParameterCount)
            .toList()),
        node.namedParameters.map((n) => n.name).toList(),
        node.namedParameters.map((n) => visitType(n.type)).toList());
  }

  @override
  DartType visitInterfaceType(ir.InterfaceType node) {
    ClassEntity cls = elementMap.getClass(node.classNode);
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
    return _valueMap.putIfAbsent(expression, () {
      return expression.evaluate(
          new _EvaluationEnvironment(_elementMap, _environment),
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
class _EvaluationEnvironment implements EvaluationEnvironment {
  final KernelToElementMapBase _elementMap;
  final Environment _environment;

  _EvaluationEnvironment(this._elementMap, this._environment);

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
      SelectorConstraintsStrategy selectorConstraintsStrategy)
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
            selectorConstraintsStrategy);

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

abstract class KernelClosedWorldMixin implements ClosedWorldBase {
  KernelToElementMapBase get elementMap;

  @override
  bool hasElementIn(ClassEntity cls, Selector selector, Entity element) {
    while (cls != null) {
      MemberEntity member = elementEnvironment
          .lookupClassMember(cls, selector.name, setter: selector.isSetter);
      if (member != null &&
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
        elementMap._isUnnamedMixinApplication(cls);
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
    ClassEnv env = elementMap._classEnvs[cls.classIndex];
    ir.Supertype supertype = env.cls.supertype;
    if (supertype == null) return null;
    return elementMap.getClass(supertype.classNode);
  }

  bool isUnnamedMixinApplication(IndexedClass cls) {
    return elementMap._isUnnamedMixinApplication(cls);
  }

  InterfaceType getMixinTypeForClass(IndexedClass cls) {
    ClassEnv env = elementMap._classEnvs[cls.classIndex];
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
    ir.Field node = elementMap._memberData[field.memberIndex].definition.node;
    return elementMap.getNativeBehaviorForFieldStore(node);
  }

  @override
  native.NativeBehavior computeNativeFieldLoadBehavior(covariant KField field,
      {bool isJsInterop}) {
    ir.Field node = elementMap._memberData[field.memberIndex].definition.node;
    return elementMap.getNativeBehaviorForFieldLoad(node,
        isJsInterop: isJsInterop);
  }

  @override
  native.NativeBehavior computeNativeMethodBehavior(
      covariant KFunction function,
      {bool isJsInterop}) {
    ir.Member node =
        elementMap._memberData[function.memberIndex].definition.node;
    return elementMap.getNativeBehaviorForMethod(node,
        isJsInterop: isJsInterop);
  }

  @override
  bool isNativeMethod(covariant KFunction function) {
    if (!native.maybeEnableNative(function.library.canonicalUri)) return false;
    ir.Member node =
        elementMap._memberData[function.memberIndex].definition.node;
    return node.isExternal &&
        !elementMap.isForeignLibrary(node.enclosingLibrary);
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
    return _backend._libraryList[library.libraryIndex];
  }

  ClassEntity toBackendClass(covariant IndexedClass cls) {
    return _backend._classList[cls.classIndex];
  }

  MemberEntity toBackendMember(covariant IndexedMember member) {
    return _backend._memberList[member.memberIndex];
  }

  TypeVariableEntity toBackendTypeVariable(
      covariant IndexedTypeVariable typeVariable) {
    return _backend._typeVariableList[typeVariable.typeVariableIndex];
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
  NativeBasicData nativeBasicData;

  JsKernelToElementMap(DiagnosticReporter reporter, Environment environment,
      KernelToElementMapForImpactImpl _elementMap)
      : super(reporter, environment) {
    _env = _elementMap._env;
    for (int libraryIndex = 0;
        libraryIndex < _elementMap._libraryEnvs.length;
        libraryIndex++) {
      LibraryEnv env = _elementMap._libraryEnvs[libraryIndex];
      LibraryData data = _elementMap._libraryData[libraryIndex];
      LibraryEntity oldLibrary = _elementMap._libraryList[libraryIndex];
      LibraryEntity newLibrary = convertLibrary(oldLibrary);
      _libraryMap[env.library] = newLibrary;
      _libraryList.add(newLibrary);
      _libraryData.add(data.copy());
      _libraryEnvs.add(env);
    }
    for (int classIndex = 0;
        classIndex < _elementMap._classEnvs.length;
        classIndex++) {
      ClassEnv env = _elementMap._classEnvs[classIndex];
      ClassData data = _elementMap._classData[classIndex];
      ClassEntity oldClass = _elementMap._classList[classIndex];
      IndexedLibrary oldLibrary = oldClass.library;
      LibraryEntity newLibrary = _libraryList[oldLibrary.libraryIndex];
      ClassEntity newClass = convertClass(newLibrary, oldClass);
      _classMap[env.cls] = newClass;
      _classList.add(newClass);
      _classEnvs.add(env);
      _classData.add(data.copy());
    }
    for (int memberIndex = 0;
        memberIndex < _elementMap._memberData.length;
        memberIndex++) {
      MemberDataImpl data = _elementMap._memberData[memberIndex];
      MemberEntity oldMember = _elementMap._memberList[memberIndex];
      IndexedLibrary oldLibrary = oldMember.library;
      IndexedClass oldClass = oldMember.enclosingClass;
      LibraryEntity newLibrary = _libraryList[oldLibrary.libraryIndex];
      ClassEntity newClass =
          oldClass != null ? _classList[oldClass.classIndex] : null;
      IndexedMember newMember = convertMember(newLibrary, newClass, oldMember);
      _memberList.add(newMember);
      _memberData.add(data.copy());
      if (newMember.isField) {
        _fieldMap[data.node] = newMember;
      } else if (newMember.isConstructor) {
        _constructorMap[data.node] = newMember;
      } else {
        _methodMap[data.node] = newMember;
      }
    }
    for (int typeVariableIndex = 0;
        typeVariableIndex < _elementMap._typeVariableList.length;
        typeVariableIndex++) {
      TypeVariableEntity oldTypeVariable =
          _elementMap._typeVariableList[typeVariableIndex];
      Entity newTypeDeclaration;
      if (oldTypeVariable.typeDeclaration is ClassEntity) {
        IndexedClass cls = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = _classList[cls.classIndex];
      } else {
        IndexedMember member = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = _memberList[member.memberIndex];
      }
      TypeVariableEntity newTypeVariable = createTypeVariable(typeVariableIndex,
          newTypeDeclaration, oldTypeVariable.name, oldTypeVariable.index);
      _typeVariableList.add(newTypeVariable);
    }
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

  Iterable<LibraryEntity> get _libraries {
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

  @override
  ConstructorEntity _getConstructor(ir.Member node) {
    ConstructorEntity constructor = _constructorMap[node];
    assert(constructor != null, "No constructor entity for $node");
    return constructor;
  }

  FunctionEntity getConstructorBody(ir.Constructor node) {
    ConstructorEntity constructor = getConstructor(node);
    return _getConstructorBody(node, constructor);
  }

  FunctionEntity _getConstructorBody(
      ir.Constructor node, covariant IndexedConstructor constructor) {
    ConstructorDataImpl data = _memberData[constructor.memberIndex];
    if (data.constructorBody == null) {
      ConstructorBodyEntity constructorBody = data.constructorBody =
          createConstructorBody(_memberList.length, constructor);
      _memberList.add(constructorBody);
      _memberData.add(new FunctionDataImpl(
          node,
          node.function,
          new SpecialMemberDefinition(
              constructorBody, node, MemberKind.constructorBody)));
      IndexedClass cls = constructor.enclosingClass;
      ClassEnvImpl classEnv = _classEnvs[cls.classIndex];
      // TODO(johnniwinther): Avoid this by only including live members in the
      // js-model.
      classEnv.addConstructorBody(constructorBody);
    }
    return data.constructorBody;
  }

  ConstructorBodyEntity createConstructorBody(
      int memberIndex, ConstructorEntity constructor);

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
    FieldData data = _memberData[field.memberIndex];
    return data.getFieldConstantValue(this);
  }

  bool hasConstantFieldInitializer(covariant IndexedField field) {
    assert(checkFamily(field));
    FieldData data = _memberData[field.memberIndex];
    return data.hasConstantFieldInitializer(this);
  }

  ConstantValue getConstantFieldInitializer(covariant IndexedField field) {
    assert(checkFamily(field));
    FieldData data = _memberData[field.memberIndex];
    return data.getConstantFieldInitializer(this);
  }

  void forEachParameter(covariant IndexedFunction function,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    FunctionData data = _memberData[function.memberIndex];
    data.forEachParameter(this, f);
  }

  void _forEachConstructorBody(
      IndexedClass cls, void f(ConstructorBodyEntity member)) {
    ClassEnv env = _classEnvs[cls.classIndex];
    env.forEachConstructorBody(f);
  }

  KernelClosureClass constructClosureClass(
      MemberEntity member,
      ir.FunctionNode node,
      JLibrary enclosingLibrary,
      KernelScopeInfo info,
      ir.Location location,
      KernelToLocalsMap localsMap,
      InterfaceType supertype) {
    String name = _computeClosureName(node);
    JClass classEntity =
        new JClosureClass(enclosingLibrary, _classEnvs.length, name);
    _classList.add(classEntity);
    Map<String, MemberEntity> memberMap = <String, MemberEntity>{};
    _classEnvs.add(new ClosureClassEnv(memberMap));

    // Create a classData and set up the interfaces and subclass
    // relationships that _ensureSupertypes and _ensureThisAndRawType are doing
    var closureData = new ClassData(
        null,
        new ClosureClassDefinition(
            classEntity, computeSourceSpanFromTreeNode(node)));
    closureData
      ..isMixinApplication = false
      ..thisType = closureData.rawType =
          new InterfaceType(classEntity, const <DartType>[])
      ..supertype = supertype
      ..interfaces = const <InterfaceType>[];
    var setBuilder = new _KernelOrderedTypeSetBuilder(this, classEntity);
    _classData.add(closureData);
    closureData.orderedTypeSet = setBuilder.createOrderedTypeSet(
        closureData.supertype, const Link<InterfaceType>());

    Local closureEntity;
    if (node.parent is ir.FunctionDeclaration) {
      ir.FunctionDeclaration parent = node.parent;
      closureEntity = localsMap.getLocalVariable(parent.variable);
    } else if (node.parent is ir.FunctionExpression) {
      closureEntity = new JLocal('', localsMap.currentMember);
    }
    Local thisLocal =
        info.hasThisLocal ? new ThisLocal(localsMap.currentMember) : null;

    KernelClosureClass cls = new KernelClosureClass.fromScopeInfo(
        classEntity, node, info, localsMap, closureEntity, thisLocal);
    int i = 0;
    for (ir.VariableDeclaration variable in info.freeVariables) {
      // Make a corresponding field entity in this closure class for every
      // single freeVariable in the KernelScopeInfo.freeVariable.
      _constructClosureFields(member, cls, memberMap, variable, i,
          info.capturedVariablesAccessor, localsMap);
      i++;
    }

    FunctionEntity callMethod = cls.callMethod = new JClosureCallMethod(
        _memberData.length,
        cls,
        _getParameterStructure(node),
        _getAsyncMarker(node));
    _memberList.add(cls.callMethod);

    _memberData.add(new ClosureFunctionData(
        new ClosureMemberDefinition(callMethod, closureData.definition.location,
            MemberKind.closureCall, node.parent),
        getFunctionType(node),
        node));
    memberMap[cls.callMethod.name] = cls.callMethod;
    return cls;
  }

  _constructClosureFields(
      MemberEntity member,
      KernelClosureClass cls,
      Map<String, MemberEntity> memberMap,
      ir.VariableDeclaration variable,
      int fieldNumber,
      NodeBox box,
      KernelToLocalsMap localsMap) {
    // NOTE: This construction order may be slightly different than the
    // old Element version. The old version did all the boxed items and then
    // all the others.
    Local capturedLocal = localsMap.getLocalVariable(variable);
    if (cls.isBoxed(capturedLocal)) {
      FieldEntity boxedField = new JRecordField(
          _getClosureVariableName(capturedLocal.name, fieldNumber),
          _memberData.length,
          new BoxLocal(box.name,
              localsMap.getLocalVariable(box.executableContext), member),
          cls.closureClassEntity,
          variable.isConst);
      cls.localToFieldMap[capturedLocal] = boxedField;
      _memberList.add(boxedField);
      _memberData.add(new ClosureFieldData(new ClosureMemberDefinition(
          boxedField,
          computeSourceSpanFromTreeNode(variable),
          MemberKind.closureField,
          variable)));
      memberMap[boxedField.name] = boxedField;
    } else {
      FieldEntity closureField = new JClosureField(
          _getClosureVariableName(capturedLocal.name, fieldNumber),
          _memberData.length,
          cls,
          variable.isConst,
          variable.isFinal || variable.isConst);
      cls.localToFieldMap[capturedLocal] = closureField;
      _memberList.add(closureField);
      _memberData.add(new ClosureFieldData(new ClosureMemberDefinition(
          cls.localToFieldMap[capturedLocal],
          computeSourceSpanFromTreeNode(variable),
          MemberKind.closureField,
          variable)));
      memberMap[closureField.name] = closureField;
    }
  }

  // Returns a non-unique name for the given closure element.
  String _computeClosureName(ir.TreeNode treeNode) {
    var parts = <String>[];
    if (treeNode is ir.Field && treeNode.name.name != "") {
      parts.add(treeNode.name.name);
    } else {
      parts.add('closure');
    }
    ir.TreeNode node = treeNode.parent;
    while (node != null) {
      // TODO(johnniwinther): Simplify computed names.
      if (node is ir.Constructor ||
          node.parent is ir.Constructor ||
          (node is ir.Procedure && node.kind == ir.ProcedureKind.Factory)) {
        FunctionEntity entity;
        if (node.parent is ir.Constructor) {
          entity = getConstructorBody(node.parent);
        } else {
          entity = getMember(node);
        }
        parts.add(utils.reconstructConstructorName(entity));
      } else {
        if (node is ir.Class) {
          parts.add(Elements.operatorNameToIdentifier(node.name));
        } else if (node is ir.Procedure) {
          parts.add(Elements.operatorNameToIdentifier(node.name.name));
        }
      }
      // A generative constructors's parent is the class; the class name is
      // already part of the generative constructor's name.
      if (node is ir.Constructor) break;
      node = node.parent;
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

  String getDeferredUri(ir.LibraryDependency node) {
    throw new UnimplementedError('JsKernelToElementMap.getDeferredUri');
  }
}
