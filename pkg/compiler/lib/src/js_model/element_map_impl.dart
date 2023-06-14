// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart' as ir;

import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/src/bounds_checks.dart' as ir;
import 'package:kernel/text/debug_printer.dart';
import 'package:kernel/type_environment.dart' as ir;

import '../closure.dart' show BoxLocal, ThisLocal;
import '../common.dart';
import '../common/elements.dart';
import '../common/names.dart';
import '../constants/values.dart';
import '../deferred_load/output_unit.dart' show LateOutputUnitDataBuilder;
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/indexed.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../ir/cached_static_type.dart';
import '../ir/closure.dart';
import '../ir/constants.dart';
import '../ir/element_map.dart';
import '../ir/types.dart';
import '../ir/visitors.dart';
import '../ir/static_type_base.dart';
import '../ir/static_type_cache.dart';
import '../ir/static_type_provider.dart';
import '../ir/util.dart';
import '../js_backend/annotations.dart';
import '../js_backend/native_data.dart';
import '../js_model/class_type_variable_access.dart';
import '../kernel/dart2js_target.dart' show allowedNativeTest;
import '../kernel/element_map.dart';
import '../kernel/env.dart';
import '../kernel/kelements.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../ordered_typeset.dart';
import '../serialization/serialization.dart';
import '../universe/call_structure.dart';
import '../universe/member_usage.dart';
import '../universe/record_shape.dart';
import '../universe/selector.dart';

import 'closure.dart';
import 'elements.dart';
import 'element_map.dart';
import 'env.dart';
import 'locals.dart';
import 'records.dart'
    show JRecordClass, RecordClassData, JRecordGetter, RecordGetterData;

class JsKernelToElementMap implements JsToElementMap, IrToElementMap {
  /// Tag used for identifying serialized [JsKernelToElementMap] objects in a
  /// debugging data stream.
  static const String tag = 'js-kernel-to-element-map';

  /// Tags used for identifying serialized subsections of a
  /// [JsKernelToElementMap] object in a debugging data stream.
  static const String libraryTag = 'libraries';
  static const String classTag = 'classes';
  static const String memberTag = 'members';
  static const String typeVariableTag = 'type-variables';
  static const String libraryDataTag = 'library-data';
  static const String classDataTag = 'class-data';
  static const String memberDataTag = 'member-data';
  static const String typeVariableDataTag = 'type-variable-data';
  static const String nestedClosuresTag = 'nested-closures';

  final CompilerOptions options;
  @override
  final DiagnosticReporter reporter;
  final Environment _environment;
  late final JCommonElements _commonElements;
  late final JsElementEnvironment _elementEnvironment;
  late final DartTypeConverter _typeConverter;
  late final KernelDartTypes _types;
  late final ConstantValuefier _constantValuefier;

  /// Library environment. Used for fast lookup.
  late final JProgramEnv programEnv;

  final EntityDataEnvMap<IndexedLibrary, JLibraryData, JLibraryEnv> libraries =
      EntityDataEnvMap<IndexedLibrary, JLibraryData, JLibraryEnv>();
  final EntityDataEnvMap<IndexedClass, JClassData, JClassEnv> classes =
      EntityDataEnvMap<IndexedClass, JClassData, JClassEnv>();
  final EntityDataMap<IndexedMember, JMemberData> members =
      EntityDataMap<IndexedMember, JMemberData>();
  final EntityDataMap<IndexedTypeVariable, JTypeVariableData> typeVariables =
      EntityDataMap<IndexedTypeVariable, JTypeVariableData>();

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

  /// Map from members to the call methods created for their nested closures.
  final Map<IndexedMember, List<IndexedFunction>> _nestedClosureMap = {};

  /// NativeData is need for computation of the default super class and
  /// parameter ordering.
  late final NativeData nativeData;

  final Map<IndexedFunction, JGeneratorBody> _generatorBodies = {};

  final Map<IndexedClass, List<IndexedMember>> _injectedClassMembers = {};

  late final LateOutputUnitDataBuilder lateOutputUnitDataBuilder;

  JsKernelToElementMap(
      this.reporter,
      this._environment,
      KernelToElementMap _elementMap,
      Map<MemberEntity, MemberUsage> liveMemberUsage,
      Iterable<MemberEntity> liveAbstractMembers,
      AnnotationsData annotations)
      : this.options = _elementMap.options {
    _elementEnvironment = JsElementEnvironment(this);
    _typeConverter = DartTypeConverter(this);
    _types = KernelDartTypes(this, options);
    _commonElements = JCommonElements(_types, _elementEnvironment);
    _constantValuefier = ConstantValuefier(this);

    programEnv = _elementMap.env.convert();
    for (int libraryIndex = 0;
        libraryIndex < _elementMap.libraries.length;
        libraryIndex++) {
      IndexedLibrary oldLibrary =
          _elementMap.libraries.getEntity(libraryIndex)!;
      KLibraryEnv oldEnv = _elementMap.libraries.getEnv(oldLibrary);
      KLibraryData data = _elementMap.libraries.getData(oldLibrary);
      IndexedLibrary newLibrary = JLibrary(oldLibrary.name!,
          oldLibrary.canonicalUri, oldLibrary.isNonNullableByDefault);
      JLibraryEnv newEnv = oldEnv.convert(_elementMap, liveMemberUsage);
      libraryMap[oldEnv.library] =
          libraries.register<IndexedLibrary, JLibraryData, JLibraryEnv>(
              newLibrary, data.convert(), newEnv);
      assert(newLibrary.libraryIndex == oldLibrary.libraryIndex);
      programEnv.registerLibrary(newEnv);
    }
    // TODO(johnniwinther): Filter unused classes.
    for (int classIndex = 0;
        classIndex < _elementMap.classes.length;
        classIndex++) {
      IndexedClass oldClass = _elementMap.classes.getEntity(classIndex)!;
      KClassEnv env = _elementMap.classes.getEnv(oldClass);
      KClassData data = _elementMap.classes.getData(oldClass);
      final oldLibrary = oldClass.library as IndexedLibrary;
      LibraryEntity newLibrary = libraries.getEntity(oldLibrary.libraryIndex)!;
      IndexedClass newClass = JClass(newLibrary as JLibrary, oldClass.name,
          isAbstract: oldClass.isAbstract);
      JClassEnv newEnv = env.convert(_elementMap, liveMemberUsage,
          liveAbstractMembers, (ir.Library library) => libraryMap[library]!);
      classMap[env.cls] = classes.register(newClass, data.convert(), newEnv);
      assert(newClass.classIndex == oldClass.classIndex);
      libraries.getEnv(newLibrary).registerClass(newClass.name, newEnv);
    }

    for (int memberIndex = 0;
        memberIndex < _elementMap.members.length;
        memberIndex++) {
      IndexedMember oldMember = _elementMap.members.getEntity(memberIndex)!;
      MemberUsage? memberUsage = liveMemberUsage[oldMember];
      if (memberUsage == null && !liveAbstractMembers.contains(oldMember)) {
        members.skipIndex(oldMember.memberIndex);
        continue;
      }
      KMemberData data = _elementMap.members.getData(oldMember);
      final oldLibrary = oldMember.library as IndexedLibrary;
      final oldClass = oldMember.enclosingClass as IndexedClass?;
      JLibrary newLibrary =
          libraries.getEntity(oldLibrary.libraryIndex) as JLibrary;
      JClass? newClass = oldClass != null
          ? classes.getEntity(oldClass.classIndex) as JClass?
          : null;
      IndexedMember newMember;
      Name memberName = oldMember.memberName;
      if (oldMember is IndexedField) {
        final field = oldMember;
        newMember = JField(newLibrary, newClass, memberName,
            isStatic: field.isStatic,
            isAssignable: field.isAssignable,
            isConst: field.isConst);
      } else if (oldMember is ConstructorEntity) {
        final constructor = oldMember as IndexedConstructor;
        ParameterStructure parameterStructure =
            annotations.hasNoElision(constructor) || memberUsage == null
                ? constructor.parameterStructure
                : memberUsage.invokedParameters!;
        if (constructor.isFactoryConstructor) {
          // TODO(redemption): This should be a JFunction.
          newMember = JFactoryConstructor(
              newClass!, memberName, parameterStructure,
              isExternal: constructor.isExternal,
              isConst: constructor.isConst,
              isFromEnvironmentConstructor:
                  constructor.isFromEnvironmentConstructor);
        } else {
          newMember = JGenerativeConstructor(
              newClass!, memberName, parameterStructure,
              isExternal: constructor.isExternal, isConst: constructor.isConst);
        }
      } else if (oldMember.isGetter) {
        final getter = oldMember as IndexedFunction;
        newMember = JGetter(
            newLibrary, newClass, memberName, getter.asyncMarker,
            isStatic: getter.isStatic,
            isExternal: getter.isExternal,
            isAbstract: getter.isAbstract);
      } else if (oldMember.isSetter) {
        final setter = oldMember as IndexedFunction;
        newMember = JSetter(newLibrary, newClass, memberName,
            isStatic: setter.isStatic,
            isExternal: setter.isExternal,
            isAbstract: setter.isAbstract);
      } else {
        final function = oldMember as IndexedFunction;
        ParameterStructure parameterStructure =
            annotations.hasNoElision(function) ||
                    memberUsage == null ||
                    function.isAbstract
                ? function.parameterStructure
                : memberUsage.invokedParameters!;
        newMember = JMethod(newLibrary, newClass, memberName,
            parameterStructure, function.asyncMarker,
            isStatic: function.isStatic,
            isExternal: function.isExternal,
            isAbstract: function.isAbstract);
      }
      members.register(newMember, data.convert());
      assert(
          newMember.memberIndex == oldMember.memberIndex,
          "Member index mismatch: "
          "Old member $oldMember has index ${oldMember.memberIndex} "
          "whereas new member $newMember has index ${newMember.memberIndex}");
      if (newMember is IndexedField) {
        fieldMap[data.node as ir.Field] = newMember;
      } else if (newMember is ConstructorEntity) {
        constructorMap[data.node] = newMember as IndexedConstructor;
      } else {
        methodMap[data.node as ir.Procedure] = newMember as IndexedFunction;
      }
    }
    for (int typeVariableIndex = 0;
        typeVariableIndex < _elementMap.typeVariables.length;
        typeVariableIndex++) {
      IndexedTypeVariable oldTypeVariable =
          _elementMap.typeVariables.getEntity(typeVariableIndex)!;
      KTypeVariableData oldTypeVariableData =
          _elementMap.typeVariables.getData(oldTypeVariable);
      Entity? newTypeDeclaration;
      if (oldTypeVariable.typeDeclaration is ClassEntity) {
        final cls = oldTypeVariable.typeDeclaration as IndexedClass;
        newTypeDeclaration = classes.getEntity(cls.classIndex);
        // TODO(johnniwinther): Skip type variables of unused classes.
      } else if (oldTypeVariable.typeDeclaration is MemberEntity) {
        final member = oldTypeVariable.typeDeclaration as IndexedMember;
        newTypeDeclaration = members.getEntity(member.memberIndex);
        if (newTypeDeclaration == null) {
          typeVariables.skipIndex(typeVariableIndex);
          continue;
        }
      } else {
        assert(oldTypeVariable.typeDeclaration is Local);
      }
      IndexedTypeVariable newTypeVariable = createTypeVariable(
              newTypeDeclaration, oldTypeVariable.name!, oldTypeVariable.index)
          as IndexedTypeVariable;
      typeVariableMap[oldTypeVariableData.node] =
          typeVariables.register<IndexedTypeVariable, JTypeVariableData>(
              newTypeVariable, oldTypeVariableData.copy());
      assert(newTypeVariable.typeVariableIndex ==
          oldTypeVariable.typeVariableIndex);
    }
    // TODO(johnniwinther): We should close the environment in the beginning of
    // this constructor but currently we need the [MemberEntity] to query if the
    // member is live, thus potentially creating the [MemberEntity] in the
    // process. Avoid this.
    _elementMap.envIsClosed = true;
  }

  JsKernelToElementMap.readFromDataSource(this.options, this.reporter,
      this._environment, ir.Component component, DataSourceReader source) {
    _elementEnvironment = JsElementEnvironment(this);
    _typeConverter = DartTypeConverter(this);
    _types = KernelDartTypes(this, options);
    _commonElements = JCommonElements(_types, _elementEnvironment);
    _constantValuefier = ConstantValuefier(this);

    source.registerComponentLookup(ComponentLookup(component));
    _EntityLookup entityLookup = _EntityLookup();
    source.registerEntityLookup(entityLookup);

    source.begin(tag);
    source.begin(libraryTag);
    int libraryCount = source.readInt();
    for (int i = 0; i < libraryCount; i++) {
      int index = source.readInt();
      JLibrary library = JLibrary.readFromDataSource(source);
      entityLookup.registerLibrary(index, library);
    }
    source.end(libraryTag);

    source.begin(classTag);
    int classCount = source.readInt();
    for (int i = 0; i < classCount; i++) {
      int index = source.readInt();
      JClass cls = JClass.readFromDataSource(source);
      entityLookup.registerClass(index, cls);
    }
    source.end(classTag);

    source.begin(memberTag);
    int memberCount = source.readInt();
    for (int i = 0; i < memberCount; i++) {
      int index = source.readInt();
      JMember member = JMember.readFromDataSource(source);
      entityLookup.registerMember(index, member);
    }
    source.end(memberTag);

    source.begin(typeVariableTag);
    int typeVariableCount = source.readInt();
    for (int i = 0; i < typeVariableCount; i++) {
      int index = source.readInt();
      JTypeVariable typeVariable = JTypeVariable.readFromDataSource(source);
      entityLookup.registerTypeVariable(index, typeVariable);
    }
    source.end(typeVariableTag);

    programEnv = JProgramEnv([component]);
    source.begin(libraryDataTag);
    entityLookup.forEachLibrary((int index, JLibrary library) {
      JLibraryEnv env = JLibraryEnv.readFromDataSource(source);
      JLibraryData data = JLibraryData.readFromDataSource(source);
      libraryMap[env.library] =
          libraries.registerByIndex(index, library, data, env);
      programEnv.registerLibrary(env);
      assert(index == library.libraryIndex);
    });
    source.end(libraryDataTag);

    source.begin(classDataTag);
    entityLookup.forEachClass((int index, JClass cls) {
      JClassEnv env = JClassEnv.readFromDataSource(source);
      classes.preRegisterByIndex(index, cls, env);
      JClassData data = JClassData.readFromDataSource(source);
      classes.postRegisterData(cls, data);
      if (env.cls != null) {
        classMap[env.cls!] = cls;
      }
      if (cls is! JContext && cls is! JClosureClass && cls is! JRecordClass) {
        // Synthesized classes are not part of the library environment.
        libraries.getEnv(cls.library).registerClass(cls.name, env);
      }
      assert(index == cls.classIndex);
    });
    source.end(classDataTag);

    source.begin(memberDataTag);
    entityLookup.forEachMember((int index, IndexedMember member) {
      JMemberData data = JMemberData.readFromDataSource(source);
      members.registerByIndex(index, member, data);
      switch (data.definition.kind) {
        case MemberKind.regular:
        case MemberKind.constructor:
          final node = data.definition.node as ir.Member;
          if (member is IndexedField) {
            fieldMap[node as ir.Field] = member;
          } else if (member is ConstructorEntity) {
            constructorMap[node] = member as IndexedConstructor;
          } else {
            methodMap[node as ir.Procedure] = member as IndexedFunction;
          }
          break;
        default:
      }
      assert(index == member.memberIndex);
    });
    source.end(memberDataTag);

    source.begin(typeVariableDataTag);
    entityLookup.forEachTypeVariable((int index, JTypeVariable typeVariable) {
      // TODO(natebiggs): Defer reading these type variables as they trigger
      //   loading of some method bodies in the Kernel AST.
      JTypeVariableData data = JTypeVariableData.readFromDataSource(source);
      typeVariableMap[data.node] =
          typeVariables.registerByIndex(index, typeVariable, data);
      assert(index == typeVariable.typeVariableIndex);
    });
    source.end(typeVariableDataTag);

    source.begin(nestedClosuresTag);
    _nestedClosureMap.addAll(source.readMemberMap(
        (MemberEntity member) => source.readMembers<IndexedFunction>()));
    source.end(nestedClosuresTag);

    source.end(tag);
  }

  /// Prepares the entity maps for codegen serialization and returns the member
  /// index limit for early members.
  ///
  /// This method creates all late members, such as constructor bodies and
  /// generator bodies, and closes the entity maps for further registration.
  int prepareForCodegenSerialization() {
    int length = members.length;
    for (int memberIndex = 0; memberIndex < length; memberIndex++) {
      MemberEntity? member = members.getEntity(memberIndex);
      if (member == null) continue;
      if (member is JGenerativeConstructor) {
        getConstructorBody(
            members.getData(member).definition.node as ir.Constructor);
      }
      if (member is IndexedFunction && member.asyncMarker != AsyncMarker.SYNC) {
        getGeneratorBody(member);
      }
    }
    libraries.close();
    classes.close();
    members.close();
    typeVariables.close();
    return length;
  }

  /// Serializes this [JsToElementMap] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);

    // Serialize the entities before serializing the data.
    sink.begin(libraryTag);
    sink.writeInt(libraries.size);
    libraries.forEach((JLibrary library, _, __) {
      sink.writeInt(library.libraryIndex);
      library.writeToDataSink(sink);
    });
    sink.end(libraryTag);

    sink.begin(classTag);
    sink.writeInt(classes.size);
    classes.forEach((JClass cls, _, __) {
      sink.writeInt(cls.classIndex);
      cls.writeToDataSink(sink);
    });
    sink.end(classTag);

    sink.begin(memberTag);
    sink.writeInt(members.size);
    members.forEach((JMember member, _) {
      sink.writeInt(member.memberIndex);
      member.writeToDataSink(sink);
    });
    sink.end(memberTag);

    sink.begin(typeVariableTag);
    sink.writeInt(typeVariables.size);
    typeVariables.forEach((JTypeVariable typeVariable, _) {
      sink.writeInt(typeVariable.typeVariableIndex);
      typeVariable.writeToDataSink(sink);
    });
    sink.end(typeVariableTag);

    // Serialize the entity data after having serialized the entities.
    sink.begin(libraryDataTag);
    libraries.forEach((_, JLibraryData data, JLibraryEnv env) {
      env.writeToDataSink(sink);
      data.writeToDataSink(sink);
    });
    sink.end(libraryDataTag);

    sink.begin(classDataTag);
    classes.forEach((_, JClassData data, JClassEnv env) {
      env.writeToDataSink(sink);
      data.writeToDataSink(sink);
    });
    sink.end(classDataTag);

    sink.begin(memberDataTag);
    members.forEach((_, JMemberData data) {
      data.writeToDataSink(sink);
    });
    sink.end(memberDataTag);

    sink.begin(typeVariableDataTag);
    typeVariables.forEach((_, JTypeVariableData data) {
      data.writeToDataSink(sink);
    });
    sink.end(typeVariableDataTag);

    sink.begin(nestedClosuresTag);
    sink.writeMemberMap(
        _nestedClosureMap,
        (MemberEntity member, List<IndexedFunction> functions) =>
            sink.writeMembers(functions));
    sink.end(nestedClosuresTag);

    sink.end(tag);
  }

  @override
  DartTypes get types => _types;

  @override
  JsElementEnvironment get elementEnvironment => _elementEnvironment;

  @override
  JCommonElements get commonElements => _commonElements;

  FunctionEntity? get _mainFunction {
    return programEnv.mainMethod != null
        ? getMethodInternal(programEnv.mainMethod as ir.Procedure)
        : null;
  }

  LibraryEntity? get _mainLibrary {
    return programEnv.mainMethod != null
        ? getLibraryInternal(programEnv.mainMethod!.enclosingLibrary)
        : null;
  }

  SourceSpan getSourceSpan(Spannable? spannable, Entity? currentElement) {
    SourceSpan fromSpannable(Spannable? spannable) {
      if (spannable is IndexedLibrary &&
          spannable.libraryIndex < libraries.length) {
        JLibraryEnv env = libraries.getEnv(spannable);
        return computeSourceSpanFromTreeNode(env.library);
      } else if (spannable is IndexedClass &&
          spannable.classIndex < classes.length) {
        JClassData data = classes.getData(spannable);
        return data.definition.location;
      } else if (spannable is IndexedMember &&
          spannable.memberIndex < members.length) {
        JMemberData data = members.getData(spannable);
        return data.definition.location;
      } else if (spannable is JLocal) {
        return getSourceSpan(spannable.memberContext, currentElement);
      }
      return SourceSpan.unknown();
    }

    SourceSpan sourceSpan = fromSpannable(spannable);
    if (sourceSpan.isKnown) return sourceSpan;
    return fromSpannable(currentElement);
  }

  LibraryEntity? lookupLibrary(Uri uri) {
    JLibraryEnv? libraryEnv = programEnv.lookupLibrary(uri);
    if (libraryEnv == null) return null;
    return getLibraryInternal(libraryEnv.library, libraryEnv);
  }

  String _getLibraryName(IndexedLibrary library) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    return libraryEnv.library.name ?? '';
  }

  MemberEntity? lookupLibraryMember(IndexedLibrary library, String name,
      {bool setter = false}) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    ir.Member? member = libraryEnv.lookupMember(name, setter: setter);
    return member != null ? getMember(member) : null;
  }

  void _forEachLibraryMember(
      IndexedLibrary library, void f(MemberEntity member)) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    libraryEnv.forEachMember((ir.Member node) {
      f(getMember(node));
    });
  }

  ClassEntity? lookupClass(IndexedLibrary library, String name) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    JClassEnv? classEnv = libraryEnv.lookupClass(name);
    if (classEnv != null) {
      return getClassInternal(classEnv.cls!, classEnv);
    }
    return null;
  }

  void _forEachClass(IndexedLibrary library, void f(ClassEntity cls)) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    libraryEnv.forEachClass((JClassEnv classEnv) {
      if (!classEnv.isUnnamedMixinApplication) {
        f(getClassInternal(classEnv.cls!, classEnv));
      }
    });
  }

  MemberEntity? lookupClassMember(IndexedClass cls, Name name) {
    assert(checkFamily(cls));
    JClassEnv classEnv = classes.getEnv(cls);
    return classEnv.lookupMember(this, name);
  }

  ConstructorEntity? lookupConstructor(IndexedClass cls, String name) {
    assert(checkFamily(cls));
    JClassEnv classEnv = classes.getEnv(cls);
    return classEnv.lookupConstructor(this, name);
  }

  @override
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments) {
    return types.interfaceType(getClass(cls), getDartTypes(typeArguments));
  }

  @override
  LibraryEntity getLibrary(ir.Library node) => getLibraryInternal(node);

  @override
  ClassEntity getClass(ir.Class node) => getClassInternal(node);

  @override
  InterfaceType? getSuperType(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.supertype;
  }

  void _ensureCallType(ClassEntity cls, JClassData data) {
    assert(checkFamily(cls));
    if (data is JClassDataImpl && !data.isCallTypeComputed) {
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

  void _ensureThisAndRawType(ClassEntity cls, JClassData data) {
    assert(checkFamily(cls));
    if (data is JClassDataImpl && data.thisType == null) {
      ir.Class node = data.cls;
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

  void _ensureJsInteropType(ClassEntity cls, JClassData data) {
    assert(checkFamily(cls));
    if (data is JClassDataImpl && data.jsInteropType == null) {
      ir.Class node = data.cls;
      if (node.typeParameters.isEmpty) {
        _ensureThisAndRawType(cls, data);
        data.jsInteropType = data.thisType;
      } else {
        data.jsInteropType = types.interfaceType(cls,
            List<DartType>.filled(node.typeParameters.length, types.anyType()));
      }
    }
  }

  void _ensureClassInstantiationToBounds(ClassEntity cls, JClassData data) {
    assert(checkFamily(cls));
    if (data is JClassDataImpl && data.instantiationToBounds == null) {
      ir.Class node = data.cls;
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

  void _ensureSupertypes(ClassEntity cls, JClassData data) {
    assert(checkFamily(cls));
    if (data is JClassDataImpl && data.orderedTypeSet == null) {
      _ensureThisAndRawType(cls, data);

      ir.Class node = data.cls;

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
        Set<InterfaceType> canonicalSupertypes = {};

        InterfaceType processSupertype(ir.Supertype supertypeNode) {
          supertypeNode = classHierarchy.getClassAsInstanceOf(
              node, supertypeNode.classNode)!;
          InterfaceType supertype =
              _typeConverter.visitSupertype(supertypeNode);
          canonicalSupertypes.add(supertype);
          final superclass = supertype.element as IndexedClass;
          JClassData superdata = classes.getData(superclass);
          _ensureSupertypes(superclass, superdata);
          for (InterfaceType supertype
              in superdata.orderedTypeSet!.supertypes!) {
            ClassDefinition definition = getClassDefinition(supertype.element);
            if (definition.kind == ClassKind.regular) {
              ir.Supertype? canonicalSupertype = classHierarchy
                  .getClassAsInstanceOf(node, definition.node as ir.Class);
              if (canonicalSupertype != null) {
                supertype = _typeConverter.visitSupertype(canonicalSupertype);
              } else {
                assert(supertype.typeArguments.isEmpty,
                    "Generic synthetic supertypes are not supported");
              }
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
              _commonElements.getDefaultSuperclass(cls, nativeData);
          InterfaceType defaultSupertype = data.supertype =
              _elementEnvironment.getRawType(defaultSuperclass);
          assert(defaultSupertype.typeArguments.isEmpty,
              "Generic default supertypes are not supported");
          canonicalSupertypes.add(defaultSupertype);
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

  @override
  ConstructorEntity getConstructor(ir.Member node) =>
      getConstructorInternal(node);

  ConstructorEntity getSuperConstructor(
      ir.Constructor sourceNode, ir.Member targetNode) {
    ConstructorEntity source = getConstructor(sourceNode);
    final sourceClass = source.enclosingClass as IndexedClass;
    ConstructorEntity target = getConstructor(targetNode);
    ClassEntity targetClass = target.enclosingClass;
    IndexedClass superClass =
        getSuperType(sourceClass)!.element as IndexedClass;
    if (superClass == targetClass) return target;
    JClassEnv env = classes.getEnv(superClass);
    return env.lookupConstructor(this, target.name!)!;
  }

  @override
  FunctionEntity getMethod(ir.Procedure node) => getMethodInternal(node);

  @override
  bool containsMethod(ir.Procedure node) => methodMap.containsKey(node);

  @override
  FieldEntity getField(ir.Field node) => getFieldInternal(node);

  @override
  DartType getDartType(ir.DartType type) => _typeConverter.visitType(type);

  @override
  TypeVariableType getTypeVariableType(ir.TypeParameterType type) =>
      getDartType(type).withoutNullability as TypeVariableType;

  @override
  List<DartType> getDartTypes(List<ir.DartType> types) {
    List<DartType> list = <DartType>[];
    types.forEach((ir.DartType type) {
      list.add(getDartType(type));
    });
    return list;
  }

  @override
  InterfaceType getInterfaceType(ir.InterfaceType type) =>
      _typeConverter.visitType(type).withoutNullability as InterfaceType;

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
    var namedParameters = <String>[];
    var requiredNamedParameters = <String>{};
    List<DartType> namedParameterTypes = [];
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
    final cls = type.element as IndexedClass;
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureCallType(cls, data);
    if (data.callType != null) {
      return substByContext(data.callType!, type) as FunctionType;
    }
    return null;
  }

  @override
  InterfaceType getThisType(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.thisType!;
  }

  InterfaceType _getJsInteropType(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureJsInteropType(cls, data);
    return data.jsInteropType!;
  }

  InterfaceType _getRawType(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.rawType!;
  }

  InterfaceType _getClassInstantiationToBounds(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureClassInstantiationToBounds(cls, data);
    return data.instantiationToBounds!;
  }

  FunctionType _getFunctionType(IndexedFunction function) {
    assert(checkFamily(function));
    final data = members.getData(function) as FunctionData;
    return data.getFunctionType(this);
  }

  List<TypeVariableType> _getFunctionTypeVariables(IndexedFunction function) {
    assert(checkFamily(function));
    final data = members.getData(function) as FunctionData;
    return data.getFunctionTypeVariables(this);
  }

  DartType _getFieldType(IndexedField field) {
    assert(checkFamily(field));
    final data = members.getData(field) as JFieldData;
    return data.getFieldType(this);
  }

  @override
  DartType getTypeVariableBound(IndexedTypeVariable typeVariable) {
    assert(checkFamily(typeVariable));
    JTypeVariableData data = typeVariables.getData(typeVariable);
    return data.getBound(this);
  }

  @override
  List<Variance> getTypeVariableVariances(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    return data.getVariances();
  }

  DartType _getTypeVariableDefaultType(IndexedTypeVariable typeVariable) {
    assert(checkFamily(typeVariable));
    JTypeVariableData data = typeVariables.getData(typeVariable);
    return data.getDefaultType(this);
  }

  ClassEntity? getAppliedMixin(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.mixedInType?.element;
  }

  bool _isMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.isMixinApplication!;
  }

  bool _isUnnamedMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassEnv env = classes.getEnv(cls);
    return env.isUnnamedMixinApplication;
  }

  bool _isMixinApplicationWithMembers(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassEnv env = classes.getEnv(cls);
    return env.isMixinApplicationWithMembers;
  }

  void _forEachSupertype(IndexedClass cls, void f(InterfaceType supertype)) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    data.orderedTypeSet!.supertypes!.forEach(f);
  }

  void _forEachConstructor(IndexedClass cls, void f(ConstructorEntity member)) {
    assert(checkFamily(cls));
    JClassEnv env = classes.getEnv(cls);
    env.forEachConstructor(this, f);
  }

  void _forEachLocalClassMember(IndexedClass cls, void f(MemberEntity member)) {
    assert(checkFamily(cls));
    JClassEnv env = classes.getEnv(cls);
    env.forEachMember(this, (MemberEntity member) {
      f(member);
    });
  }

  void _forEachClassMember(
      IndexedClass cls, void f(ClassEntity cls, MemberEntity member)) {
    assert(checkFamily(cls));
    JClassEnv env = classes.getEnv(cls);
    env.forEachMember(this, (MemberEntity member) {
      f(cls, member);
    });
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    if (data.supertype != null) {
      _forEachClassMember(data.supertype!.element as IndexedClass, f);
    }
  }

  @override
  InterfaceType? asInstanceOf(InterfaceType type, ClassEntity cls) {
    assert(checkFamily(cls));
    OrderedTypeSet orderedTypeSet =
        getOrderedTypeSet(type.element as IndexedClass);
    InterfaceType? supertype = orderedTypeSet.asInstanceOf(
        cls, getHierarchyDepth(cls as IndexedClass));
    if (supertype != null) {
      supertype = substByContext(supertype, type) as InterfaceType;
    }
    return supertype;
  }

  @override
  OrderedTypeSet getOrderedTypeSet(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet!;
  }

  @override
  int getHierarchyDepth(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet!.maxDepth;
  }

  @override
  Iterable<InterfaceType> getInterfaces(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.interfaces;
  }

  MemberDefinition getMemberDefinitionInternal(covariant IndexedMember member) {
    assert(checkFamily(member));
    return members.getData(member).definition;
  }

  ClassDefinition getClassDefinitionInternal(covariant IndexedClass cls) {
    assert(checkFamily(cls));
    return classes.getData(cls).definition;
  }

  @override
  ImportEntity getImport(ir.LibraryDependency node) {
    ir.Library library = node.enclosingLibrary;
    JLibraryData data =
        libraries.getData(getLibraryInternal(library) as IndexedLibrary);
    return data.imports[node]!;
  }

  @override
  late final ir.CoreTypes coreTypes = ir.CoreTypes(programEnv.mainComponent);

  late final ir.TypeEnvironment typeEnvironment =
      ir.TypeEnvironment(coreTypes, classHierarchy);

  late final ir.ClassHierarchy classHierarchy =
      ir.ClassHierarchy(programEnv.mainComponent, coreTypes);

  ir.StaticTypeContext getStaticTypeContext(ir.Member node) {
    // TODO(johnniwinther): Cache the static type context.
    return ir.StaticTypeContext(node, typeEnvironment);
  }

  late final Dart2jsConstantEvaluator constantEvaluator =
      Dart2jsConstantEvaluator(programEnv.mainComponent, typeEnvironment,
          (ir.LocatedMessage message, List<ir.LocatedMessage>? context) {
    reportLocatedMessage(reporter, message, context);
  },
          environment: _environment,
          evaluationMode: options.useLegacySubtyping
              ? ir.EvaluationMode.weak
              : ir.EvaluationMode.strong);

  @override
  StaticTypeProvider getStaticTypeProvider(MemberEntity member) {
    MemberDefinition memberDefinition =
        members.getData(member as IndexedMember).definition;
    late StaticTypeCache cachedStaticTypes;
    late ir.StaticTypeContext staticTypeContext;
    switch (memberDefinition.kind) {
      case MemberKind.regular:
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        final node = memberDefinition.node as ir.Member;
        staticTypeContext = getStaticTypeContext(node);
        cachedStaticTypes = members.getData(member).staticTypes;
        break;
      case MemberKind.closureCall:
        var node = memberDefinition.node as ir.TreeNode?;
        while (node != null) {
          if (node is ir.Member) {
            ir.Member member = node;
            staticTypeContext = getStaticTypeContext(member);
            cachedStaticTypes =
                members.getData(getMember(member) as IndexedMember).staticTypes;
            break;
          }
          node = node.parent;
        }
        break;
      case MemberKind.closureField:
      case MemberKind.signature:
      case MemberKind.generatorBody:
        cachedStaticTypes = const StaticTypeCache();
        var node = memberDefinition.node as ir.TreeNode?;
        while (node != null) {
          if (node is ir.Member) {
            ir.Member member = node;
            staticTypeContext = getStaticTypeContext(member);
            break;
          } else if (node is ir.Library) {
            // Closure field may use class nodes or type parameter nodes as
            // the definition node.
            staticTypeContext =
                ir.StaticTypeContext.forAnnotations(node, typeEnvironment);
          }
          node = node.parent;
        }
        break;

      case MemberKind.recordGetter:
        // TODO(51310): Avoid calling [getStaticTypeProvider] for synthetic
        // elements that have no Kernel Node context.
        return NoStaticTypeProvider();
    }
    return CachedStaticType(staticTypeContext, cachedStaticTypes,
        ThisInterfaceType.from(staticTypeContext.thisType));
  }

  @override
  Name getName(ir.Name name, {bool setter = false}) {
    return Name(name.text, name.isPrivate ? name.library!.importUri : null,
        isSetter: setter);
  }

  @override
  CallStructure getCallStructure(ir.Arguments arguments) {
    int argumentCount = arguments.positional.length + arguments.named.length;
    List<String> namedArguments = arguments.named.map((e) => e.name).toList();
    return CallStructure(argumentCount, namedArguments, arguments.types.length);
  }

  @override
  Selector getSelector(ir.Expression node) {
    // TODO(efortuna): This is screaming for a common interface between
    // PropertyGet and SuperPropertyGet (and same for *Get). Talk to kernel
    // folks.
    if (node is ir.InstanceGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.InstanceTearOff) {
      return getGetterSelector(node.name);
    }
    if (node is ir.DynamicGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.FunctionTearOff) {
      return getGetterSelector(ir.Name.callName);
    }
    if (node is ir.SuperPropertyGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.InstanceSet) {
      return getSetterSelector(node.name);
    }
    if (node is ir.DynamicSet) {
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
  // TODO(johnniwinther): Use this in [native.NativeBehavior] instead of calling
  // the `ForeignResolver`.
  TypeLookup typeLookup({bool resolveAsRaw = true}) {
    return resolveAsRaw
        ? (_cachedTypeLookupRaw ??= _typeLookup(resolveAsRaw: true))
        : (_cachedTypeLookupFull ??= _typeLookup(resolveAsRaw: false));
  }

  TypeLookup? _cachedTypeLookupRaw;
  TypeLookup? _cachedTypeLookupFull;

  TypeLookup _typeLookup({required bool resolveAsRaw}) {
    bool? cachedMayLookupInMain;

    DartType? lookup(String typeName, {bool required = false}) {
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
      if (type == null && required) {
        reporter.reportErrorMessage(CURRENT_ELEMENT_SPANNABLE,
            MessageKind.GENERIC, {'text': "Type '$typeName' not found."});
      }
      return type;
    }

    return lookup;
  }

  String? _getStringArgument(ir.StaticInvocation node, int index) {
    return node.arguments.positional[index].accept(Stringifier());
  }

  // TODO(johnniwinther): Cache this for later use.
  @override
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

  // TODO(johnniwinther): Cache this for later use.
  @override
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

  // TODO(johnniwinther): Cache this for later use.
  @override
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

  @override
  ConstantValue? getConstantValue(ir.Member? memberContext, ir.Expression? node,
      {bool requireConstant = true, bool implicitNull = false}) {
    if (node == null) {
      if (!implicitNull) {
        throw failedAt(
            CURRENT_ELEMENT_SPANNABLE, 'No expression for constant.');
      }
      return NullConstantValue();
    } else if (node is ir.ConstantExpression) {
      return _constantValuefier.visitConstant(node.constant);
    } else {
      // TODO(johnniwinther,sigmund): Effectively constant expressions should
      // be replaced in the scope visitor as part of the initializer complexity
      // computation.
      ir.StaticTypeContext staticTypeContext =
          getStaticTypeContext(memberContext!);
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
    }
    return null;
  }

  @override
  ConstantValue getRequiredSentinelConstantValue() {
    return ConstructedConstantValue(_commonElements.requiredSentinelType, {});
  }

  @override
  FunctionEntity getSuperNoSuchMethod(ClassEntity cls) {
    while (true) {
      ClassEntity? superclass = elementEnvironment.getSuperClass(cls);
      if (superclass == null) break;
      MemberEntity? member = elementEnvironment.lookupLocalClassMember(
          superclass, Names.noSuchMethod_);
      if (member != null && !member.isAbstract) {
        if (member.isFunction) {
          final function = member as FunctionEntity;
          if (function.parameterStructure.positionalParameters >= 1) {
            return function;
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

  TypeVariableEntity createTypeVariable(
      Entity? typeDeclaration, String name, int index) {
    return JTypeVariable(typeDeclaration, name, index);
  }

  JConstructorBody createConstructorBody(
      ConstructorEntity constructor, ParameterStructure parameterStructure) {
    return JConstructorBody(constructor as JConstructor, parameterStructure);
  }

  JGeneratorBody createGeneratorBody(
      FunctionEntity function, DartType elementType) {
    return JGeneratorBody(function as JFunction, elementType);
  }

  void forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    assert(checkFamily(member));
    _nestedClosureMap[member]?.forEach(f);
  }

  @override
  InterfaceType? getMemberThisType(MemberEntity member) {
    return members.getData(member as IndexedMember).getMemberThisType(this);
  }

  @override
  ClassTypeVariableAccess getClassTypeVariableAccessForMember(
      MemberEntity member) {
    return members.getData(member as IndexedMember).classTypeVariableAccess;
  }

  bool checkFamily(Entity entity) {
    assert(
        '$entity'.startsWith(jsElementPrefix),
        failedAt(entity,
            "Unexpected entity $entity, expected family $jsElementPrefix."));
    return true;
  }

  @override
  Spannable getSpannable(MemberEntity member, ir.Node node) =>
      node is ir.TreeNode
          ? computeSourceSpanFromTreeNode(node)
          : getSourceSpan(member, null);

  Iterable<LibraryEntity> get libraryListInternal {
    return libraryMap.values;
  }

  LibraryEntity getLibraryInternal(ir.Library node, [JLibraryEnv? env]) =>
      libraryMap[node]!;

  ClassEntity getClassInternal(ir.Class node, [JClassEnv? env]) =>
      classMap[node]!;

  FieldEntity getFieldInternal(ir.Field node) => fieldMap[node]!;

  FunctionEntity getMethodInternal(ir.Procedure node) => methodMap[node]!;

  ConstructorEntity getConstructorInternal(ir.Member node) =>
      constructorMap[node]!;

  TypeVariableEntity getTypeVariableInternal(ir.TypeParameter node) {
    TypeVariableEntity? typeVariable = typeVariableMap[node];
    if (typeVariable == null) {
      final parent = node.parent;
      if (parent is ir.FunctionNode) {
        final member = parent.parent;
        int index = parent.typeParameters.indexOf(node);
        if (member is ir.Constructor) {
          ir.Class cls = member.enclosingClass;
          typeVariableMap[node] =
              typeVariable = getTypeVariableInternal(cls.typeParameters[index]);
        } else if (member is ir.Procedure) {
          if (member.kind == ir.ProcedureKind.Factory) {
            ir.Class cls = member.enclosingClass!;
            typeVariableMap[node] = typeVariable =
                getTypeVariableInternal(cls.typeParameters[index]);
          }
        }
      }
    }
    if (typeVariable == null) {
      throw failedAt(
          CURRENT_ELEMENT_SPANNABLE,
          "No type variable entity for $node on "
          "${node.parent is ir.FunctionNode ? node.parent!.parent : node.parent}");
    }
    return typeVariable;
  }

  @override
  FunctionEntity getConstructorBody(ir.Constructor node) {
    ConstructorEntity constructor = getConstructor(node);
    return _getConstructorBody(constructor as IndexedConstructor);
  }

  JConstructorBody _getConstructorBody(IndexedConstructor constructor) {
    JConstructorData data = members.getData(constructor) as JConstructorData;
    JConstructorBody? constructorBody = data.constructorBody;
    if (constructorBody == null) {
      /// The constructor calls the constructor body with all parameters.
      // TODO(johnniwinther): Remove parameters that are not used in the
      //  constructor body.
      ParameterStructure parameterStructure =
          _getParameterStructureFromFunctionNode(data.node.function!);

      constructorBody = createConstructorBody(constructor, parameterStructure);
      members.register<IndexedFunction, FunctionData>(
          constructorBody,
          ConstructorBodyDataImpl(
              data.node,
              data.node.function!,
              SpecialMemberDefinition(data.node, MemberKind.constructorBody),
              data.staticTypes));
      final cls = constructor.enclosingClass as IndexedClass;
      final classEnv = classes.getEnv(cls) as JClassEnvImpl;
      // TODO(johnniwinther): Avoid this by only including live members in the
      // js-model.
      classEnv.addConstructorBody(constructorBody);
      lateOutputUnitDataBuilder.registerColocatedMembers(
          constructor, constructorBody);
      data.constructorBody = constructorBody;
    }
    return constructorBody;
  }

  @override
  MemberDefinition getMemberDefinition(MemberEntity member) {
    return getMemberDefinitionInternal(member as IndexedMember);
  }

  @override
  ir.Member? getMemberContextNode(MemberEntity member) {
    ir.Member? getParentMember(ir.TreeNode? node) {
      while (node != null) {
        if (node is ir.Member) {
          return node;
        }
        node = node.parent;
      }
      return null;
    }

    MemberDefinition definition = getMemberDefinition(member);
    switch (definition.kind) {
      case MemberKind.regular:
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        return definition.node as ir.Member;
      case MemberKind.closureCall:
      case MemberKind.closureField:
      case MemberKind.signature:
      case MemberKind.generatorBody:
        return getParentMember(definition.node as ir.TreeNode?);
      case MemberKind.recordGetter:
        return null;
    }
  }

  @override
  ClassDefinition getClassDefinition(ClassEntity cls) {
    return getClassDefinitionInternal(cls as IndexedClass);
  }

  /// Calls [f] for each parameter of [function] providing the type and name of
  /// the parameter and the [defaultValue] if the parameter is optional.
  void forEachParameter(covariant IndexedFunction function,
      void f(DartType type, String? name, ConstantValue? defaultValue),
      {bool isNative = false}) {
    final data = members.getData(function) as FunctionData;
    data.forEachParameter(this, function.parameterStructure, f,
        isNative: isNative);
  }

  void forEachConstructorBody(
      IndexedClass cls, void f(ConstructorBodyEntity member)) {
    JClassEnv env = classes.getEnv(cls);
    env.forEachConstructorBody(f);
  }

  void forEachInjectedClassMember(
      IndexedClass cls, void f(MemberEntity member)) {
    _injectedClassMembers[cls]?.forEach(f);
  }

  JContextField _constructContextFieldEntry(
      InterfaceType? memberThisType,
      ir.VariableDeclaration variable,
      BoxLocal boxLocal,
      Map<Name, MemberEntity> memberMap) {
    JContextField boxedField =
        JContextField(variable.name!, boxLocal, isConst: variable.isConst);
    members.register(
        boxedField,
        ClosureFieldData(
            ClosureMemberDefinition(computeSourceSpanFromTreeNode(variable),
                MemberKind.closureField, variable),
            memberThisType));
    memberMap[boxedField.memberName] = boxedField;

    return boxedField;
  }

  /// Make a container controlling access to contexts, that is, variables that
  /// are accessed in different scopes. This function creates the container
  /// and returns a map of locals to the corresponding records created.
  @override
  Map<ir.VariableDeclaration, JContextField> makeContextContainer(
      KernelScopeInfo info, MemberEntity member) {
    Map<ir.VariableDeclaration, JContextField> boxedFields = {};
    if (info.boxedVariables.isNotEmpty) {
      NodeBox box = info.capturedVariablesAccessor!;

      Map<Name, IndexedMember> memberMap = {};
      JContext container = JContext(member.library, box.name);
      BoxLocal boxLocal = BoxLocal(container);
      InterfaceType thisType =
          types.interfaceType(container, const <DartType>[]);
      InterfaceType supertype = commonElements.objectType;
      JClassData containerData = ContextClassData(
          ContextContainerDefinition(getMemberDefinition(member).location),
          thisType,
          supertype,
          getOrderedTypeSet(supertype.element as IndexedClass)
              .extendClass(types, thisType));
      classes.register(container, containerData, ContextEnv(memberMap));

      InterfaceType? memberThisType = member.enclosingClass != null
          ? elementEnvironment.getThisType(member.enclosingClass!)
          : null;
      for (ir.VariableDeclaration variable in info.boxedVariables) {
        boxedFields[variable] = _constructContextFieldEntry(
            memberThisType, variable, boxLocal, memberMap);
      }
    }
    return boxedFields;
  }

  ParameterStructure _getParameterStructureFromFunctionNode(
      ir.FunctionNode node) {
    int requiredPositionalParameters = node.requiredParameterCount;
    int positionalParameters = node.positionalParameters.length;
    int typeParameters = node.typeParameters.length;
    var namedParameters = <String>[];
    var requiredNamedParameters = <String>{};
    for (var p in node.namedParameters.toList()
      ..sort((a, b) => a.name!.compareTo(b.name!))) {
      namedParameters.add(p.name!);
      if (p.isRequired && !options.useLegacySubtyping) {
        requiredNamedParameters.add(p.name!);
      }
    }
    return ParameterStructure(
        requiredPositionalParameters,
        positionalParameters,
        namedParameters,
        requiredNamedParameters,
        typeParameters);
  }

  JsClosureClassInfo constructClosureClass(
      MemberEntity member,
      ir.FunctionNode node,
      JLibrary enclosingLibrary,
      Map<ir.VariableDeclaration, JContextField> contextFieldsVisibleInScope,
      KernelScopeInfo info,
      InterfaceType supertype,
      {required bool createSignatureMethod}) {
    InterfaceType? memberThisType = member.enclosingClass != null
        ? elementEnvironment.getThisType(member.enclosingClass!)
        : null;
    ClassTypeVariableAccess typeVariableAccess =
        members.getData(member as IndexedMember).classTypeVariableAccess;
    if (typeVariableAccess == ClassTypeVariableAccess.instanceField) {
      // A closure in a field initializer will only be executed in the
      // constructor and type variables are therefore accessed through
      // parameters.
      typeVariableAccess = ClassTypeVariableAccess.parameter;
    }
    String name = _computeClosureName(node);
    SourceSpan location = computeSourceSpanFromTreeNode(node);
    Map<Name, IndexedMember> memberMap = {};

    JClass classEntity = JClosureClass(enclosingLibrary, name);
    // Create a classData and set up the interfaces and subclass
    // relationships that _ensureSupertypes and _ensureThisAndRawType are doing
    InterfaceType thisType =
        types.interfaceType(classEntity, const <DartType>[]);
    ClosureClassData closureData = ClosureClassData(
        ClosureClassDefinition(location),
        thisType,
        supertype,
        getOrderedTypeSet(supertype.element as IndexedClass)
            .extendClass(types, thisType));
    classes.register(classEntity, closureData, ClosureClassEnv(memberMap));

    Local? closureEntity;
    ir.VariableDeclaration? closureEntityNode;
    if (node.parent is ir.FunctionDeclaration) {
      final parent = node.parent as ir.FunctionDeclaration;
      closureEntityNode = parent.variable;
    } else if (node.parent is ir.FunctionExpression) {
      closureEntity = AnonymousClosureLocal(classEntity as JClosureClass);
    }

    IndexedFunction callMethod = JClosureCallMethod(classEntity,
        _getParameterStructureFromFunctionNode(node), getAsyncMarker(node));
    _nestedClosureMap
        .putIfAbsent(member, () => <IndexedFunction>[])
        .add(callMethod);
    // We need create the type variable here - before we try to make local
    // variables from them (in `JsScopeInfo.from` called through
    // `KernelClosureClassInfo.fromScopeInfo` below).
    int index = 0;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      typeVariableMap[typeParameter] = typeVariables.register(
          createTypeVariable(callMethod, typeParameter.name!, index)
              as IndexedTypeVariable,
          JTypeVariableData(typeParameter));
      index++;
    }

    JsClosureClassInfo closureClassInfo = JsClosureClassInfo.fromScopeInfo(
        classEntity,
        node,
        <ir.VariableDeclaration, JContextField>{},
        info,
        member.enclosingClass,
        closureEntity,
        closureEntityNode,
        info.hasThisLocal ? ThisLocal(member.enclosingClass!) : null);
    _buildClosureClassFields(closureClassInfo, member, memberThisType, info,
        contextFieldsVisibleInScope, memberMap);

    if (createSignatureMethod) {
      _constructSignatureMethod(closureClassInfo, memberMap, node,
          memberThisType, location, typeVariableAccess);
    }

    closureData.callType = getFunctionType(node);

    members.register<IndexedFunction, FunctionData>(
        callMethod,
        ClosureFunctionData(
            ClosureMemberDefinition(
                location, MemberKind.closureCall, node.parent!),
            memberThisType,
            closureData.callType!,
            node,
            typeVariableAccess));
    memberMap[callMethod.memberName] =
        closureClassInfo.callMethod = callMethod as JFunction;
    return closureClassInfo;
  }

  void _buildClosureClassFields(
      JsClosureClassInfo closureClassInfo,
      MemberEntity member,
      InterfaceType? memberThisType,
      KernelScopeInfo info,
      Map<ir.VariableDeclaration, JContextField> contextFieldsVisibleInScope,
      Map<Name, MemberEntity> memberMap) {
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
        if (contextFieldsVisibleInScope.containsKey(variable)) {
          bool constructedField = _constructClosureFieldForRecord(
              variable,
              closureClassInfo,
              memberThisType,
              memberMap,
              variable,
              contextFieldsVisibleInScope,
              fieldNumber);
          if (constructedField) fieldNumber++;
        }
      }
    }

    // Add a field for the captured 'this'.
    if (info.thisUsedAsFreeVariable) {
      closureClassInfo.registerFieldForLocal(
          closureClassInfo.thisLocal!,
          _constructClosureField(
              closureClassInfo.thisLocal!.name!,
              closureClassInfo,
              memberThisType,
              memberMap,
              getClassDefinition(member.enclosingClass!).node as ir.TreeNode,
              true,
              false,
              fieldNumber));
      fieldNumber++;
    }

    for (ir.Node variable in info.freeVariables) {
      // Make a corresponding field entity in this closure class for the
      // free variables in the KernelScopeInfo.freeVariable.
      if (variable is ir.VariableDeclaration) {
        if (!contextFieldsVisibleInScope.containsKey(variable)) {
          closureClassInfo.registerFieldForVariable(
              variable,
              _constructClosureField(
                  variable.name!,
                  closureClassInfo,
                  memberThisType,
                  memberMap,
                  variable,
                  variable.isConst,
                  false, // Closure field is never assigned (only box fields).
                  fieldNumber));
          fieldNumber++;
        }
      } else if (variable is TypeVariableTypeWithContext) {
        TypeVariableEntity typeVariable =
            getTypeVariable(variable.type.parameter);
        // We can have distinct TypeVariableTypeWithContexts that have the same
        // local variable but with different nullabilities. We only want to
        // construct a closure field once for each local variable.
        if (closureClassInfo
            .hasFieldForTypeVariable(typeVariable as JTypeVariable)) {
          continue;
        }
        closureClassInfo.registerFieldForTypeVariable(
            typeVariable,
            _constructClosureField(
                variable.type.parameter.name!,
                closureClassInfo,
                memberThisType,
                memberMap,
                variable.type.parameter,
                true,
                false,
                fieldNumber));
        fieldNumber++;
      } else {
        throw UnsupportedError("Unexpected field node type: $variable");
      }
    }
  }

  /// Contexts point to one or more local variables declared in another scope
  /// that are captured in a scope. Access to those variables goes entirely
  /// through the context container, so we only create a field for the *context*
  /// holding [capturedLocal] and not the individual local variables accessed
  /// through the context. Contexts, by definition, are not mutable (though the
  /// locals they contain may be). Returns `true` if we constructed a new field
  /// in the closure class.
  bool _constructClosureFieldForRecord(
      ir.VariableDeclaration capturedLocal,
      JsClosureClassInfo closureClassInfo,
      InterfaceType? memberThisType,
      Map<Name, MemberEntity> memberMap,
      ir.TreeNode sourceNode,
      Map<ir.VariableDeclaration, JContextField> contextFieldsVisibleInScope,
      int fieldNumber) {
    JContextField contextField = contextFieldsVisibleInScope[capturedLocal]!;

    // Don't construct a new field if the box that holds this local already has
    // a field in the closure class.
    if (closureClassInfo.hasFieldForLocal(contextField.box)) {
      closureClassInfo.registerFieldForBoxedVariable(
          capturedLocal, contextField);
      return false;
    }

    final closureField = JClosureField(
        '_box_$fieldNumber', closureClassInfo, contextField.box.name,
        isConst: true, isAssignable: false);

    members.register<IndexedField, JFieldData>(
        closureField,
        ClosureFieldData(
            ClosureMemberDefinition(computeSourceSpanFromTreeNode(sourceNode),
                MemberKind.closureField, sourceNode),
            memberThisType));
    memberMap[closureField.memberName] = closureField;
    closureClassInfo.registerFieldForLocal(contextField.box, closureField);
    closureClassInfo.registerFieldForBoxedVariable(capturedLocal, contextField);
    return true;
  }

  void _constructSignatureMethod(
      JsClosureClassInfo closureClassInfo,
      Map<Name, MemberEntity> memberMap,
      ir.FunctionNode closureSourceNode,
      InterfaceType? memberThisType,
      SourceSpan location,
      ClassTypeVariableAccess typeVariableAccess) {
    final signatureMethod =
        JSignatureMethod(closureClassInfo.closureClassEntity);
    members.register<IndexedFunction, FunctionData>(
        signatureMethod,
        SignatureFunctionData(
            SpecialMemberDefinition(
                closureSourceNode.parent!, MemberKind.signature),
            memberThisType,
            closureSourceNode.typeParameters,
            typeVariableAccess));
    memberMap[signatureMethod.memberName] =
        closureClassInfo.signatureMethod = signatureMethod;
  }

  JField _constructClosureField(
      String name,
      JsClosureClassInfo closureClassInfo,
      InterfaceType? memberThisType,
      Map<Name, MemberEntity> memberMap,
      ir.TreeNode sourceNode,
      bool isConst,
      bool isAssignable,
      int fieldNumber) {
    JField closureField = JClosureField(
        _getClosureVariableName(name, fieldNumber), closureClassInfo, name,
        isConst: isConst, isAssignable: isAssignable);

    members.register<IndexedField, JFieldData>(
        closureField,
        ClosureFieldData(
            ClosureMemberDefinition(computeSourceSpanFromTreeNode(sourceNode),
                MemberKind.closureField, sourceNode),
            memberThisType));
    memberMap[closureField.memberName] = closureField;
    return closureField;
  }

  // Returns a non-unique name for the given closure element.
  String _computeClosureName(ir.TreeNode treeNode) {
    var parts = <String>[];
    // First anonymous is called 'closure', outer ones called '' to give a
    // compound name where increasing nesting level corresponds to extra
    // underscores.
    var anonymous = 'closure';
    ir.TreeNode? current = treeNode;
    // TODO(johnniwinther): Simplify computed names.
    while (current != null) {
      var node = current;
      if (node is ir.FunctionExpression) {
        parts.add(anonymous);
        anonymous = '';
      } else if (node is ir.FunctionDeclaration) {
        String? name = node.variable.name;
        if (name != null && name != "") {
          parts.add(utils.operatorNameToIdentifier(name)!);
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
          parts.add(utils
              .reconstructConstructorName(getMember(node) as FunctionEntity));
        } else {
          parts.add(utils.operatorNameToIdentifier(node.name.text)!);
        }
      } else if (node is ir.Constructor) {
        parts.add(utils
            .reconstructConstructorName(getMember(node) as FunctionEntity));
        break;
      } else if (node is ir.Field) {
        // Add the field name for closures in field initializers.
        parts.add(node.name.text);
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

  @override
  JGeneratorBody getGeneratorBody(covariant IndexedFunction function) {
    JGeneratorBody? generatorBody = _generatorBodies[function];
    if (generatorBody == null) {
      final functionData = members.getData(function) as FunctionData;
      DartType elementType =
          elementEnvironment.getFunctionAsyncOrSyncStarElementType(function);
      generatorBody = createGeneratorBody(function, elementType);
      members.register<IndexedFunction, FunctionData>(
          generatorBody,
          GeneratorBodyFunctionData(
              functionData,
              SpecialMemberDefinition.from(
                  functionData.definition, MemberKind.generatorBody)));

      if (function.enclosingClass != null) {
        // TODO(sra): Integrate this with ClassEnvImpl.addConstructorBody ?
        (_injectedClassMembers[function.enclosingClass as IndexedClass] ??=
                <IndexedMember>[])
            .add(generatorBody);
      }
      lateOutputUnitDataBuilder.registerColocatedMembers(
          generatorBody.function, generatorBody);
      _generatorBodies[function] = generatorBody;
    }
    return generatorBody;
  }

  String _nameForShape(RecordShape shape) {
    final sb = StringBuffer();
    sb.write('_Record_');
    sb.write(shape.fieldCount);
    for (String name in shape.fieldNames) {
      sb.write('_');
      // 'hex' escape to remove `$` and `_`.
      // `send_$_bux` --> `sendx5Fx24x5Fbux78`.
      sb.write(name
          .replaceAll(r'x', r'x78')
          .replaceAll(r'$', r'x24')
          .replaceAll(r'_', r'x5F'));
    }
    return sb.toString();
  }

  /// [getters] is an out parameter that gathers all the getters created for
  /// this shape.
  IndexedClass generateRecordShapeClass(
      RecordShape shape, InterfaceType supertype, List<MemberEntity> getters) {
    JLibrary library = supertype.element.library as JLibrary;

    String name = _nameForShape(shape);
    SourceSpan location = SourceSpan.unknown(); // TODO(50081): What to use?

    Map<Name, IndexedMember> memberMap = {};
    final classEntity = JRecordClass(library, name, isAbstract: false);

    // Create a classData and set up the interfaces and subclass relationships
    // that for regular classes would be done by _ensureSupertypes and
    // _ensureThisAndRawType.
    InterfaceType thisType = types.interfaceType(classEntity, const []);
    RecordClassData recordData = RecordClassData(
        RecordClassDefinition(location),
        thisType,
        supertype,
        getOrderedTypeSet(supertype.element as IndexedClass)
            .extendClass(types, thisType));
    classes.register(classEntity, recordData, RecordClassEnv(memberMap));

    // Add field getters, which are called only from dynamic getter invocations.

    for (int i = 0; i < shape.fieldCount; i++) {
      String name = shape.getterNameOfIndex(i);
      Name memberName = Name(name, null);
      final getter = JRecordGetter(classEntity, memberName);
      getters.add(getter);

      // The function type of a dynamic getter is a function of no arguments
      // that returns `dynamic` (any other top would be ok too).
      FunctionType functionType = commonElements.dartTypes.functionType(
          commonElements.dartTypes.dynamicType(),
          const [],
          const [],
          const [],
          const {},
          const [],
          const []);
      final data = RecordGetterData(
          RecordGetterDefinition(location, i), thisType, functionType);

      members.register<IndexedFunction, FunctionData>(getter, data);
      memberMap[memberName] = getter;
    }

    // TODO(49718): Implement `==` specialized to the shape.

    return classEntity;
  }
}

class JsElementEnvironment extends ElementEnvironment
    implements JElementEnvironment {
  final JsKernelToElementMap elementMap;

  JsElementEnvironment(this.elementMap);

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
    return elementMap._getJsInteropType(cls as IndexedClass);
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
  bool isMixinApplicationWithMembers(ClassEntity cls) {
    return elementMap._isMixinApplicationWithMembers(cls as IndexedClass);
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
  DartType getTypeVariableBound(TypeVariableEntity typeVariable) {
    return elementMap.getTypeVariableBound(typeVariable as IndexedTypeVariable);
  }

  @override
  List<Variance> getTypeVariableVariances(ClassEntity cls) {
    return elementMap.getTypeVariableVariances(cls as IndexedClass);
  }

  @override
  DartType getTypeVariableDefaultType(TypeVariableEntity typeVariable) {
    return elementMap
        ._getTypeVariableDefaultType(typeVariable as IndexedTypeVariable);
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
  DartType getFunctionAsyncOrSyncStarElementType(FunctionEntity function) {
    // TODO(sra): Should be getting the DartType from the node.
    DartType returnType = getFunctionType(function).returnType;
    return getAsyncOrSyncStarElementType(function.asyncMarker, returnType);
  }

  @override
  DartType getAsyncOrSyncStarElementType(
      AsyncMarker asyncMarker, DartType returnType) {
    var returnTypeWithoutNullability = returnType.withoutNullability;
    switch (asyncMarker) {
      case AsyncMarker.SYNC:
        return returnType;
      case AsyncMarker.SYNC_STAR:
        if (returnTypeWithoutNullability is InterfaceType) {
          if (returnTypeWithoutNullability.element ==
              elementMap.commonElements.iterableClass) {
            return returnTypeWithoutNullability.typeArguments.first;
          }
        }
        return dynamicType;
      case AsyncMarker.ASYNC:
        if (returnTypeWithoutNullability is FutureOrType) {
          return returnTypeWithoutNullability.typeArgument;
        }
        if (returnTypeWithoutNullability is InterfaceType) {
          if (returnTypeWithoutNullability.element ==
              elementMap.commonElements.futureClass) {
            return returnTypeWithoutNullability.typeArguments.first;
          }
        }
        return dynamicType;
      case AsyncMarker.ASYNC_STAR:
        if (returnTypeWithoutNullability is InterfaceType) {
          if (returnTypeWithoutNullability.element ==
              elementMap.commonElements.streamClass) {
            return returnTypeWithoutNullability.typeArguments.first;
          }
        }
        return dynamicType;
    }
    throw failedAt(
        CURRENT_ELEMENT_SPANNABLE, 'Unexpected marker ${asyncMarker}');
  }

  @override
  DartType getFieldType(FieldEntity field) {
    return elementMap._getFieldType(field as IndexedField);
  }

  @override
  FunctionType getLocalFunctionType(covariant KLocalFunction function) {
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
    assert(elementMap.checkFamily(cls));
    IndexedClass? superclass =
        elementMap.getSuperType(cls as IndexedClass)?.element as IndexedClass?;
    if (skipUnnamedMixinApplications) {
      while (superclass != null &&
          elementMap._isUnnamedMixinApplication(superclass)) {
        superclass =
            elementMap.getSuperType(superclass)?.element as IndexedClass?;
      }
    }
    return superclass;
  }

  @override
  void forEachSupertype(ClassEntity cls, void f(InterfaceType supertype)) {
    elementMap._forEachSupertype(cls as IndexedClass, f);
  }

  @override
  void forEachLocalClassMember(ClassEntity cls, void f(MemberEntity member)) {
    elementMap._forEachLocalClassMember(cls as IndexedClass, f);
  }

  @override
  void forEachInjectedClassMember(
      ClassEntity cls, void f(MemberEntity member)) {
    elementMap.forEachInjectedClassMember(cls as IndexedClass, f);
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
  void forEachConstructorBody(
      ClassEntity cls, void f(ConstructorBodyEntity constructor)) {
    elementMap.forEachConstructorBody(cls as IndexedClass, f);
  }

  @override
  void forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    elementMap.forEachNestedClosure(member, f);
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
  bool isEnumClass(ClassEntity cls) {
    assert(elementMap.checkFamily(cls));
    JClassData classData = elementMap.classes.getData(cls as IndexedClass);
    return classData.isEnumClass;
  }

  @override
  void forEachParameter(FunctionEntity function,
      void f(DartType type, String? name, ConstantValue? defaultValue)) {
    elementMap.forEachParameter(function as IndexedFunction, f,
        isNative: elementMap.nativeData.isNativeMember(function));
  }

  @override
  void forEachParameterAsLocal(GlobalLocalsMap globalLocalsMap,
      FunctionEntity function, void f(Local parameter)) {
    forEachOrderedParameterAsLocal(globalLocalsMap, elementMap, function,
        (Local parameter, {required bool isElided}) {
      if (!isElided) {
        f(parameter);
      }
    });
  }

  @override
  void forEachInstanceField(
      ClassEntity cls, void f(ClassEntity declarer, FieldEntity field)) {
    forEachClassMember(cls, (ClassEntity declarer, MemberEntity member) {
      if (member is FieldEntity && member.isInstanceMember) {
        f(declarer, member);
      }
    });
  }

  @override
  void forEachDirectInstanceField(ClassEntity cls, void f(FieldEntity field)) {
    // TODO(sra): Add ElementEnvironment.forEachDirectInstanceField or
    // parameterize [forEachInstanceField] to filter members to avoid a
    // potentially O(n^2) scan of the superclasses.
    forEachClassMember(cls, (ClassEntity declarer, MemberEntity member) {
      if (declarer != cls) return;
      if (member is! FieldEntity) return;
      if (!member.isInstanceMember) return;
      f(member);
    });
  }
}

/// [EntityLookup] implementation used to deserialize [JsKernelToElementMap].
///
/// Since data objects and environments are registered together with their
/// entity we need to have a separate lookup-by-index mechanism to allow for
/// index-based reference within data objects and environments.
class _EntityLookup implements EntityLookup {
  final Map<int, JLibrary> _libraries = {};
  final Map<int, JClass> _classes = {};
  final Map<int, JMember> _members = {};
  final Map<int, JTypeVariable> _typeVariables = {};

  void registerLibrary(int index, JLibrary library) {
    assert(!_libraries.containsKey(index),
        "Library for index $index has already been defined.");
    _libraries[index] = library;
  }

  void registerClass(int index, JClass cls) {
    assert(!_classes.containsKey(index),
        "Class for index $index has already been defined.");
    _classes[index] = cls;
  }

  void registerMember(int index, JMember member) {
    assert(!_members.containsKey(index),
        "Member for index $index has already been defined.");
    _members[index] = member;
  }

  void registerTypeVariable(int index, JTypeVariable typeVariable) {
    assert(!_typeVariables.containsKey(index),
        "Type variable for index $index has already been defined.");
    _typeVariables[index] = typeVariable;
  }

  void forEachLibrary(void f(int index, JLibrary library)) {
    _libraries.forEach(f);
  }

  void forEachClass(void f(int index, JClass cls)) {
    _classes.forEach(f);
  }

  void forEachMember(void f(int index, JMember member)) {
    _members.forEach(f);
  }

  void forEachTypeVariable(void f(int index, JTypeVariable typeVariable)) {
    _typeVariables.forEach(f);
  }

  @override
  IndexedLibrary getLibraryByIndex(int index) => _libraries[index]!;

  @override
  IndexedClass getClassByIndex(int index) => _classes[index]!;

  @override
  IndexedMember getMemberByIndex(int index) => _members[index]!;

  @override
  IndexedTypeVariable getTypeVariableByIndex(int index) =>
      _typeVariables[index]!;
}

/// [EntityLookup] implementation for an fully built [JsKernelToElementMap].
class ClosedEntityLookup implements EntityLookup {
  final JsKernelToElementMap _elementMap;

  ClosedEntityLookup(this._elementMap);

  @override
  IndexedTypeVariable getTypeVariableByIndex(int index) {
    return _elementMap.typeVariables.getEntity(index)!;
  }

  @override
  IndexedMember getMemberByIndex(int index) {
    return _elementMap.members.getEntity(index)!;
  }

  @override
  IndexedClass getClassByIndex(int index) {
    return _elementMap.classes.getEntity(index)!;
  }

  @override
  IndexedLibrary getLibraryByIndex(int index) {
    return _elementMap.libraries.getEntity(index)!;
  }
}

/// Enum used for serialization of 'late members', that is, members normally
/// created on demand, like constructor bodies and generator bodies.
enum LateMemberKind {
  constructorBody,
  generatorBody,
}

/// Entity reader that supports member entities normally created on-demand, like
/// constructor bodies and generator bodies.
///
/// The support encoding corresponds to the encoding generated by the
/// [ClosedEntityWriter].
class ClosedEntityReader extends EntityReader {
  final JsKernelToElementMap _elementMap;

  ClosedEntityReader(this._elementMap);

  @override
  IndexedMember readMemberFromDataSource(
      DataSourceReader source, EntityLookup entityLookup) {
    int index = source.readInt();
    if (index == 0) {
      return _readLateMemberFromDataSource(source, entityLookup);
    } else {
      return entityLookup.getMemberByIndex(index - 1);
    }
  }

  IndexedMember _readLateMemberFromDataSource(
      DataSourceReader source, EntityLookup entityLookup) {
    LateMemberKind kind = source.readEnum(LateMemberKind.values);
    switch (kind) {
      case LateMemberKind.constructorBody:
        IndexedConstructor constructor =
            source.readMember() as IndexedConstructor;
        return _elementMap._getConstructorBody(constructor);
      case LateMemberKind.generatorBody:
        final function = source.readMember() as IndexedFunction;
        return _elementMap.getGeneratorBody(function);
    }
  }
}

/// Entity writer that supports member entities normally created on-demand, like
/// constructor bodies and generator bodies.
///
/// The generated encoding corresponds to the encoding read by the
/// [ClosedEntityReader].
class ClosedEntityWriter extends EntityWriter {
  final int _earlyMemberIndexLimit;

  ClosedEntityWriter(this._earlyMemberIndexLimit);

  @override
  void writeMemberToDataSink(DataSinkWriter sink, IndexedMember value) {
    if (value.memberIndex >= _earlyMemberIndexLimit) {
      sink.writeInt(0);
      _writeLateMemberToDataSink(sink, value);
    } else {
      sink.writeInt(value.memberIndex + 1);
    }
  }

  void _writeLateMemberToDataSink(DataSinkWriter sink, IndexedMember value) {
    if (value is JConstructorBody) {
      sink.writeEnum(LateMemberKind.constructorBody);
      sink.writeMember(value.constructor);
    } else if (value is JGeneratorBody) {
      sink.writeEnum(LateMemberKind.generatorBody);
      sink.writeMember(value.function);
    } else {
      throw UnsupportedError("Unexpected late member $value.");
    }
  }
}
