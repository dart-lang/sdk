// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_unstable/dart2js.dart' show Link, LinkBuilder;

import 'package:js_runtime/shared/embedded_names.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_algebra.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../closure.dart' show BoxLocal, ThisLocal;
import '../common.dart';
import '../common/names.dart';
import '../common_elements.dart';
import '../compile_time_constants.dart';
import '../constants/constant_system.dart';
import '../constants/constructors.dart';
import '../constants/evaluation.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/indexed.dart';
import '../elements/names.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../ir/cached_static_type.dart';
import '../ir/closure.dart';
import '../ir/debug.dart';
import '../ir/element_map.dart';
import '../ir/types.dart';
import '../ir/visitors.dart';
import '../ir/static_type_base.dart';
import '../ir/static_type_provider.dart';
import '../ir/util.dart';
import '../js/js.dart' as js;
import '../js_backend/constant_system_javascript.dart';
import '../js_backend/namer.dart';
import '../js_backend/native_data.dart';
import '../js_emitter/code_emitter_task.dart';
import '../kernel/element_map_impl.dart';
import '../kernel/env.dart';
import '../kernel/kelements.dart';
import '../native/behavior.dart';
import '../options.dart';
import '../ordered_typeset.dart';
import '../serialization/serialization.dart';
import '../ssa/type_builder.dart';
import '../universe/call_structure.dart';
import '../universe/selector.dart';

import 'closure.dart';
import 'elements.dart';
import 'element_map.dart';
import 'env.dart';
import 'locals.dart';

/// Interface for kernel queries needed to implement the [CodegenWorldBuilder].
abstract class JsToWorldBuilder implements JsToElementMap {
  /// Returns `true` if [field] has a constant initializer.
  bool hasConstantFieldInitializer(FieldEntity field);

  /// Returns the constant initializer for [field].
  ConstantValue getConstantFieldInitializer(FieldEntity field);

  /// Calls [f] for each parameter of [function] providing the type and name of
  /// the parameter and the [defaultValue] if the parameter is optional.
  void forEachParameter(FunctionEntity function,
      void f(DartType type, String name, ConstantValue defaultValue),
      {bool isNative: false});
}

class JsKernelToElementMap
    implements JsToWorldBuilder, JsToElementMap, IrToElementMap {
  /// Tag used for identifying serialized [JsKernelToElementMap] objects in a
  /// debugging data stream.
  static const String tag = 'js-kernel-to-element-map';

  /// Tags used for identifying serialized subsections of a
  /// [JsKernelToElementMap] object in a debugging data stream.
  static const String libraryTag = 'libraries';
  static const String classTag = 'classes';
  static const String typedefTag = 'typedefs';
  static const String memberTag = 'members';
  static const String typeVariableTag = 'type-variables';
  static const String libraryDataTag = 'library-data';
  static const String classDataTag = 'class-data';
  static const String typedefDataTag = 'typedef-data';
  static const String memberDataTag = 'member-data';
  static const String typeVariableDataTag = 'type-variable-data';
  static const String nestedClosuresTag = 'nested-closures';

  final CompilerOptions options;
  final DiagnosticReporter reporter;
  CommonElementsImpl _commonElements;
  JsElementEnvironment _elementEnvironment;
  DartTypeConverter _typeConverter;
  JsConstantEnvironment _constantEnvironment;
  KernelDartTypes _types;
  ir.TypeEnvironment _typeEnvironment;
  ir.ClassHierarchy _classHierarchy;

  /// Library environment. Used for fast lookup.
  JProgramEnv programEnv;

  final EntityDataEnvMap<IndexedLibrary, JLibraryData, JLibraryEnv> libraries =
      new EntityDataEnvMap<IndexedLibrary, JLibraryData, JLibraryEnv>();
  final EntityDataEnvMap<IndexedClass, JClassData, JClassEnv> classes =
      new EntityDataEnvMap<IndexedClass, JClassData, JClassEnv>();
  final EntityDataMap<IndexedMember, JMemberData> members =
      new EntityDataMap<IndexedMember, JMemberData>();
  final EntityDataMap<IndexedTypeVariable, JTypeVariableData> typeVariables =
      new EntityDataMap<IndexedTypeVariable, JTypeVariableData>();
  final EntityDataMap<IndexedTypedef, JTypedefData> typedefs =
      new EntityDataMap<IndexedTypedef, JTypedefData>();

  final Map<ir.Library, IndexedLibrary> libraryMap = {};
  final Map<ir.Class, IndexedClass> classMap = {};
  final Map<ir.Typedef, IndexedTypedef> typedefMap = {};

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
  Map<IndexedMember, List<IndexedFunction>> _nestedClosureMap = {};

  /// NativeBasicData is need for computation of the default super class.
  NativeBasicData nativeBasicData;

  Map<IndexedFunction, JGeneratorBody> _generatorBodies = {};

  Map<IndexedClass, List<IndexedMember>> _injectedClassMembers = {};

  JsKernelToElementMap(this.reporter, Environment environment,
      KernelToElementMapImpl _elementMap, Iterable<MemberEntity> liveMembers)
      : this.options = _elementMap.options {
    _elementEnvironment = new JsElementEnvironment(this);
    _commonElements = new CommonElementsImpl(_elementEnvironment);
    _constantEnvironment = new JsConstantEnvironment(this, environment);
    _typeConverter = new DartTypeConverter(this);
    _types = new KernelDartTypes(this);

    programEnv = _elementMap.env.convert();
    for (int libraryIndex = 0;
        libraryIndex < _elementMap.libraries.length;
        libraryIndex++) {
      IndexedLibrary oldLibrary = _elementMap.libraries.getEntity(libraryIndex);
      KLibraryEnv oldEnv = _elementMap.libraries.getEnv(oldLibrary);
      KLibraryData data = _elementMap.libraries.getData(oldLibrary);
      IndexedLibrary newLibrary = convertLibrary(oldLibrary);
      JLibraryEnv newEnv = oldEnv.convert(_elementMap, liveMembers);
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
      IndexedClass oldClass = _elementMap.classes.getEntity(classIndex);
      KClassEnv env = _elementMap.classes.getEnv(oldClass);
      KClassData data = _elementMap.classes.getData(oldClass);
      IndexedLibrary oldLibrary = oldClass.library;
      LibraryEntity newLibrary = libraries.getEntity(oldLibrary.libraryIndex);
      IndexedClass newClass = convertClass(newLibrary, oldClass);
      JClassEnv newEnv = env.convert(_elementMap, liveMembers);
      classMap[env.cls] = classes.register(newClass, data.convert(), newEnv);
      assert(newClass.classIndex == oldClass.classIndex);
      libraries.getEnv(newClass.library).registerClass(newClass.name, newEnv);
    }
    for (int typedefIndex = 0;
        typedefIndex < _elementMap.typedefs.length;
        typedefIndex++) {
      IndexedTypedef oldTypedef = _elementMap.typedefs.getEntity(typedefIndex);
      KTypedefData data = _elementMap.typedefs.getData(oldTypedef);
      IndexedLibrary oldLibrary = oldTypedef.library;
      LibraryEntity newLibrary = libraries.getEntity(oldLibrary.libraryIndex);
      IndexedTypedef newTypedef = convertTypedef(newLibrary, oldTypedef);
      typedefMap[data.node] = typedefs.register(
          newTypedef,
          new JTypedefData(
              data.node,
              new TypedefType(
                  newTypedef,
                  new List<DartType>.filled(
                      data.node.typeParameters.length, const DynamicType()),
                  getDartType(data.node.type))));
      assert(newTypedef.typedefIndex == oldTypedef.typedefIndex);
    }
    for (int memberIndex = 0;
        memberIndex < _elementMap.members.length;
        memberIndex++) {
      IndexedMember oldMember = _elementMap.members.getEntity(memberIndex);
      if (!liveMembers.contains(oldMember)) {
        members.skipIndex(oldMember.memberIndex);
        continue;
      }
      KMemberData data = _elementMap.members.getData(oldMember);
      IndexedLibrary oldLibrary = oldMember.library;
      IndexedClass oldClass = oldMember.enclosingClass;
      LibraryEntity newLibrary = libraries.getEntity(oldLibrary.libraryIndex);
      ClassEntity newClass =
          oldClass != null ? classes.getEntity(oldClass.classIndex) : null;
      IndexedMember newMember = convertMember(newLibrary, newClass, oldMember);
      members.register(newMember, data.convert());
      assert(newMember.memberIndex == oldMember.memberIndex);
      if (newMember.isField) {
        fieldMap[data.node] = newMember;
      } else if (newMember.isConstructor) {
        constructorMap[data.node] = newMember;
      } else {
        methodMap[data.node] = newMember;
      }
    }
    for (int typeVariableIndex = 0;
        typeVariableIndex < _elementMap.typeVariables.length;
        typeVariableIndex++) {
      IndexedTypeVariable oldTypeVariable =
          _elementMap.typeVariables.getEntity(typeVariableIndex);
      KTypeVariableData oldTypeVariableData =
          _elementMap.typeVariables.getData(oldTypeVariable);
      Entity newTypeDeclaration;
      if (oldTypeVariable.typeDeclaration is ClassEntity) {
        IndexedClass cls = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = classes.getEntity(cls.classIndex);
        // TODO(johnniwinther): Skip type variables of unused classes.
      } else if (oldTypeVariable.typeDeclaration is MemberEntity) {
        IndexedMember member = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = members.getEntity(member.memberIndex);
        if (newTypeDeclaration == null) {
          typeVariables.skipIndex(typeVariableIndex);
          continue;
        }
      } else {
        assert(oldTypeVariable.typeDeclaration is Local);
      }
      IndexedTypeVariable newTypeVariable = createTypeVariable(
          newTypeDeclaration, oldTypeVariable.name, oldTypeVariable.index);
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
      Environment environment, ir.Component component, DataSource source) {
    _elementEnvironment = new JsElementEnvironment(this);
    _commonElements = new CommonElementsImpl(_elementEnvironment);
    _constantEnvironment = new JsConstantEnvironment(this, environment);
    _typeConverter = new DartTypeConverter(this);
    _types = new KernelDartTypes(this);

    source.registerComponentLookup(new ComponentLookup(component));
    _EntityLookup entityLookup = new _EntityLookup();
    source.registerEntityLookup(entityLookup);

    source.begin(tag);
    source.begin(libraryTag);
    int libraryCount = source.readInt();
    for (int i = 0; i < libraryCount; i++) {
      int index = source.readInt();
      JLibrary library = new JLibrary.readFromDataSource(source);
      entityLookup.registerLibrary(index, library);
    }
    source.end(libraryTag);

    source.begin(classTag);
    int classCount = source.readInt();
    for (int i = 0; i < classCount; i++) {
      int index = source.readInt();
      JClass cls = new JClass.readFromDataSource(source);
      entityLookup.registerClass(index, cls);
    }
    source.end(classTag);

    source.begin(typedefTag);
    int typedefCount = source.readInt();
    for (int i = 0; i < typedefCount; i++) {
      int index = source.readInt();
      JTypedef typedef = new JTypedef.readFromDataSource(source);
      entityLookup.registerTypedef(index, typedef);
    }
    source.end(typedefTag);

    source.begin(memberTag);
    int memberCount = source.readInt();
    for (int i = 0; i < memberCount; i++) {
      int index = source.readInt();
      JMember member = new JMember.readFromDataSource(source);
      entityLookup.registerMember(index, member);
    }
    source.end(memberTag);

    source.begin(typeVariableTag);
    int typeVariableCount = source.readInt();
    for (int i = 0; i < typeVariableCount; i++) {
      int index = source.readInt();
      JTypeVariable typeVariable = new JTypeVariable.readFromDataSource(source);
      entityLookup.registerTypeVariable(index, typeVariable);
    }
    source.end(typeVariableTag);

    programEnv = new JProgramEnv([component]);
    source.begin(libraryDataTag);
    entityLookup.forEachLibrary((int index, JLibrary library) {
      JLibraryEnv env = new JLibraryEnv.readFromDataSource(source);
      JLibraryData data = new JLibraryData.readFromDataSource(source);
      libraryMap[env.library] =
          libraries.registerByIndex(index, library, data, env);
      programEnv.registerLibrary(env);
      assert(index == library.libraryIndex);
    });
    source.end(libraryDataTag);

    source.begin(classDataTag);
    entityLookup.forEachClass((int index, JClass cls) {
      JClassEnv env = new JClassEnv.readFromDataSource(source);
      JClassData data = new JClassData.readFromDataSource(source);
      classMap[env.cls] = classes.registerByIndex(index, cls, data, env);
      if (cls is! JRecord && cls is! JClosureClass) {
        // Synthesized classes are not part of the library environment.
        libraries.getEnv(cls.library).registerClass(cls.name, env);
      }
      assert(index == cls.classIndex);
    });
    source.end(classDataTag);

    source.begin(typedefDataTag);
    entityLookup.forEachTypedef((int index, JTypedef typedef) {
      JTypedefData data = new JTypedefData.readFromDataSource(source);
      typedefMap[data.node] = typedefs.registerByIndex(index, typedef, data);
      assert(index == typedef.typedefIndex);
    });
    source.end(typedefDataTag);

    source.begin(memberDataTag);
    entityLookup.forEachMember((int index, IndexedMember member) {
      JMemberData data = new JMemberData.readFromDataSource(source);
      members.registerByIndex(index, member, data);
      switch (data.definition.kind) {
        case MemberKind.regular:
        case MemberKind.constructor:
          ir.Member node = data.definition.node;
          if (member.isField) {
            fieldMap[node] = member;
          } else if (member.isConstructor) {
            constructorMap[node] = member;
          } else {
            methodMap[node] = member;
          }
          break;
        default:
      }
      assert(index == member.memberIndex);
    });
    source.end(memberDataTag);

    source.begin(typeVariableDataTag);
    entityLookup.forEachTypeVariable((int index, JTypeVariable typeVariable) {
      JTypeVariableData data = new JTypeVariableData.readFromDataSource(source);
      typeVariableMap[data.node] =
          typeVariables.registerByIndex(index, typeVariable, data);
      assert(index == typeVariable.typeVariableIndex);
    });
    source.end(typeVariableDataTag);

    source.begin(nestedClosuresTag);
    _nestedClosureMap.addAll(
        source.readMemberMap(() => source.readMembers<IndexedFunction>()));
    source.end(nestedClosuresTag);

    source.end(tag);
  }

  /// Serializes this [JsToElementMap] to [sink].
  void writeToDataSink(DataSink sink) {
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

    sink.begin(typedefTag);
    sink.writeInt(typedefs.size);
    typedefs.forEach((JTypedef typedef, _) {
      sink.writeInt(typedef.typedefIndex);
      typedef.writeToDataSink(sink);
    });
    sink.end(typedefTag);

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

    sink.begin(typedefDataTag);
    typedefs.forEach((_, JTypedefData data) {
      data.writeToDataSink(sink);
    });
    sink.end(typedefDataTag);

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
    sink.writeMemberMap(_nestedClosureMap, sink.writeMembers);
    sink.end(nestedClosuresTag);

    sink.end(tag);
  }

  DartTypes get types => _types;

  JsElementEnvironment get elementEnvironment => _elementEnvironment;

  @override
  CommonElementsImpl get commonElements => _commonElements;

  FunctionEntity get _mainFunction {
    return programEnv.mainMethod != null
        ? getMethodInternal(programEnv.mainMethod)
        : null;
  }

  LibraryEntity get _mainLibrary {
    return programEnv.mainMethod != null
        ? getLibraryInternal(programEnv.mainMethod.enclosingLibrary)
        : null;
  }

  SourceSpan getSourceSpan(Spannable spannable, Entity currentElement) {
    SourceSpan fromSpannable(Spannable spannable) {
      if (spannable is IndexedLibrary &&
          spannable.libraryIndex < libraries.length) {
        JLibraryEnv env = libraries.getEnv(spannable);
        return computeSourceSpanFromTreeNode(env.library);
      } else if (spannable is IndexedClass &&
          spannable.classIndex < classes.length) {
        JClassData data = classes.getData(spannable);
        assert(data != null, "No data for $spannable in $this");
        return data.definition.location;
      } else if (spannable is IndexedMember &&
          spannable.memberIndex < members.length) {
        JMemberData data = members.getData(spannable);
        assert(data != null, "No data for $spannable in $this");
        return data.definition.location;
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
    JLibraryEnv libraryEnv = programEnv.lookupLibrary(uri);
    if (libraryEnv == null) return null;
    return getLibraryInternal(libraryEnv.library, libraryEnv);
  }

  String _getLibraryName(IndexedLibrary library) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    return libraryEnv.library.name ?? '';
  }

  MemberEntity lookupLibraryMember(IndexedLibrary library, String name,
      {bool setter: false}) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    ir.Member member = libraryEnv.lookupMember(name, setter: setter);
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

  ClassEntity lookupClass(IndexedLibrary library, String name) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    JClassEnv classEnv = libraryEnv.lookupClass(name);
    if (classEnv != null) {
      return getClassInternal(classEnv.cls, classEnv);
    }
    return null;
  }

  void _forEachClass(IndexedLibrary library, void f(ClassEntity cls)) {
    assert(checkFamily(library));
    JLibraryEnv libraryEnv = libraries.getEnv(library);
    libraryEnv.forEachClass((JClassEnv classEnv) {
      if (!classEnv.isUnnamedMixinApplication) {
        f(getClassInternal(classEnv.cls, classEnv));
      }
    });
  }

  MemberEntity lookupClassMember(IndexedClass cls, String name,
      {bool setter: false}) {
    assert(checkFamily(cls));
    JClassEnv classEnv = classes.getEnv(cls);
    return classEnv.lookupMember(this, name, setter: setter);
  }

  ConstructorEntity lookupConstructor(IndexedClass cls, String name) {
    assert(checkFamily(cls));
    JClassEnv classEnv = classes.getEnv(cls);
    return classEnv.lookupConstructor(this, name);
  }

  @override
  InterfaceType createInterfaceType(
      ir.Class cls, List<ir.DartType> typeArguments) {
    return new InterfaceType(getClass(cls), getDartTypes(typeArguments));
  }

  LibraryEntity getLibrary(ir.Library node) => getLibraryInternal(node);

  @override
  ClassEntity getClass(ir.Class node) => getClassInternal(node);

  InterfaceType getSuperType(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.supertype;
  }

  void _ensureThisAndRawType(ClassEntity cls, JClassData data) {
    assert(checkFamily(cls));
    if (data is JClassDataImpl && data.thisType == null) {
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
                  getTypeVariableInternal(node.typeParameters[index]));
            }));
        data.rawType = new InterfaceType(
            cls,
            new List<DartType>.filled(
                node.typeParameters.length, const DynamicType()));
      }
    }
  }

  TypeVariableEntity getTypeVariable(ir.TypeParameter node) =>
      getTypeVariableInternal(node);

  void _ensureSupertypes(ClassEntity cls, JClassData data) {
    assert(checkFamily(cls));
    if (data is JClassDataImpl && data.orderedTypeSet == null) {
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
          JClassData superdata = classes.getData(superclass);
          _ensureSupertypes(superclass, superdata);
          return supertype;
        }

        InterfaceType supertype;
        LinkBuilder<InterfaceType> linkBuilder =
            new LinkBuilder<InterfaceType>();
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
          for (ir.Supertype constraint in node.superclassConstraints()) {
            linkBuilder.addLast(processSupertype(constraint));
          }
          // Set superclass to `Object`.
          supertype = _commonElements.objectType;
        } else {
          supertype = processSupertype(node.supertype);
        }
        if (supertype == _commonElements.objectType) {
          ClassEntity defaultSuperclass =
              _commonElements.getDefaultSuperclass(cls, nativeBasicData);
          data.supertype = _elementEnvironment.getRawType(defaultSuperclass);
        } else {
          data.supertype = supertype;
        }
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
    IndexedTypedef typedef = getTypedefInternal(node);
    return typedefs.getData(typedef).rawType;
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
    throw new UnsupportedError("Unexpected member: $node");
  }

  MemberEntity getSuperMember(MemberEntity context, ir.Name name,
      {bool setter: false}) {
    // We can no longer trust the interface target of the super access since it
    // might be a member that we have cloned.
    ClassEntity cls = getMemberThisType(context).element;
    assert(
        cls != null,
        failedAt(context,
            "No enclosing class for super member access in $context."));
    IndexedClass superclass = getSuperType(cls)?.element;
    while (superclass != null) {
      JClassEnv env = classes.getEnv(superclass);
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
  ConstructorEntity getConstructor(ir.Member node) =>
      getConstructorInternal(node);

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
    JClassEnv env = classes.getEnv(superClass);
    ConstructorEntity constructor = env.lookupConstructor(this, target.name);
    if (constructor != null) {
      return constructor;
    }
    throw failedAt(source, "Super constructor for $source not found.");
  }

  @override
  FunctionEntity getMethod(ir.Procedure node) => getMethodInternal(node);

  @override
  FieldEntity getField(ir.Field node) => getFieldInternal(node);

  @override
  DartType getDartType(ir.DartType type) => _typeConverter.convert(type);

  TypeVariableType getTypeVariableType(ir.TypeParameterType type) =>
      getDartType(type);

  List<DartType> getDartTypes(List<ir.DartType> types) {
    List<DartType> list = <DartType>[];
    types.forEach((ir.DartType type) {
      list.add(getDartType(type));
    });
    return list;
  }

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
    JClassData data = classes.getData(cls);
    if (data.callType != null) {
      return substByContext(data.callType, type);
    }
    return null;
  }

  InterfaceType getThisType(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.thisType;
  }

  InterfaceType _getRawType(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureThisAndRawType(cls, data);
    return data.rawType;
  }

  FunctionType _getFunctionType(IndexedFunction function) {
    assert(checkFamily(function));
    FunctionData data = members.getData(function);
    return data.getFunctionType(this);
  }

  List<TypeVariableType> _getFunctionTypeVariables(IndexedFunction function) {
    assert(checkFamily(function));
    FunctionData data = members.getData(function);
    return data.getFunctionTypeVariables(this);
  }

  DartType _getFieldType(IndexedField field) {
    assert(checkFamily(field));
    JFieldData data = members.getData(field);
    return data.getFieldType(this);
  }

  DartType getTypeVariableBound(IndexedTypeVariable typeVariable) {
    assert(checkFamily(typeVariable));
    JTypeVariableData data = typeVariables.getData(typeVariable);
    return data.getBound(this);
  }

  DartType _getTypeVariableDefaultType(IndexedTypeVariable typeVariable) {
    assert(checkFamily(typeVariable));
    JTypeVariableData data = typeVariables.getData(typeVariable);
    return data.getDefaultType(this);
  }

  ClassEntity getAppliedMixin(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.mixedInType?.element;
  }

  bool _isMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.isMixinApplication;
  }

  bool _isUnnamedMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassEnv env = classes.getEnv(cls);
    return env.isUnnamedMixinApplication;
  }

  bool _isSuperMixinApplication(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassEnv env = classes.getEnv(cls);
    return env.isSuperMixinApplication;
  }

  void _forEachSupertype(IndexedClass cls, void f(InterfaceType supertype)) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    data.orderedTypeSet.supertypes.forEach(f);
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
      _forEachClassMember(data.supertype.element, f);
    }
  }

  ConstantConstructor _getConstructorConstant(IndexedConstructor constructor) {
    assert(checkFamily(constructor));
    JConstructorData data = members.getData(constructor);
    return data.getConstructorConstant(this, constructor);
  }

  ConstantExpression _getFieldConstantExpression(IndexedField field) {
    assert(checkFamily(field));
    JFieldData data = members.getData(field);
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
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet;
  }

  int getHierarchyDepth(IndexedClass cls) {
    assert(checkFamily(cls));
    JClassData data = classes.getData(cls);
    _ensureSupertypes(cls, data);
    return data.orderedTypeSet.maxDepth;
  }

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

  ImportEntity getImport(ir.LibraryDependency node) {
    ir.Library library = node.parent;
    JLibraryData data = libraries.getData(getLibraryInternal(library));
    return data.imports[node];
  }

  ir.TypeEnvironment get typeEnvironment {
    if (_typeEnvironment == null) {
      _typeEnvironment ??= new ir.TypeEnvironment(
          new ir.CoreTypes(programEnv.mainComponent), classHierarchy);
    }
    return _typeEnvironment;
  }

  ir.ClassHierarchy get classHierarchy {
    if (_classHierarchy == null) {
      _classHierarchy ??= new ir.ClassHierarchy(programEnv.mainComponent);
    }
    return _classHierarchy;
  }

  StaticTypeProvider getStaticTypeProvider(MemberEntity member) {
    MemberDefinition memberDefinition = members.getData(member).definition;
    Map<ir.Expression, ir.DartType> cachedStaticTypes;
    ir.InterfaceType thisType;
    switch (memberDefinition.kind) {
      case MemberKind.regular:
      case MemberKind.constructor:
      case MemberKind.constructorBody:
        ir.Member node = memberDefinition.node;
        thisType = node.enclosingClass?.thisType;
        cachedStaticTypes = members.getData(member).staticTypes;
        break;
      case MemberKind.closureCall:
        ir.TreeNode node = memberDefinition.node;
        while (node != null) {
          if (node is ir.Member) {
            ir.Member member = node;
            thisType = member.enclosingClass?.thisType;
            cachedStaticTypes = members.getData(getMember(member)).staticTypes;
            break;
          }
          node = node.parent;
        }
        break;
      case MemberKind.closureField:
      case MemberKind.signature:
      case MemberKind.generatorBody:
        cachedStaticTypes = const {};
        break;
    }

    assert(cachedStaticTypes != null, "No static types cached for $member.");
    return new CachedStaticType(typeEnvironment, cachedStaticTypes,
        new ThisInterfaceType.from(thisType));
  }

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

  ParameterStructure getParameterStructure(ir.FunctionNode node,
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

  Selector getSelector(ir.Expression node) {
    // TODO(efortuna): This is screaming for a common interface between
    // PropertyGet and SuperPropertyGet (and same for *Get). Talk to kernel
    // folks.
    if (node is ir.PropertyGet) {
      return getGetterSelector(node.name);
    }
    if (node is ir.DirectPropertyGet) {
      return getGetterSelector(node.target.name);
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
  TypeLookup typeLookup({bool resolveAsRaw: true}) {
    return resolveAsRaw
        ? (_cachedTypeLookupRaw ??= _typeLookup(resolveAsRaw: true))
        : (_cachedTypeLookupFull ??= _typeLookup(resolveAsRaw: false));
  }

  TypeLookup _cachedTypeLookupRaw;
  TypeLookup _cachedTypeLookupFull;

  TypeLookup _typeLookup({bool resolveAsRaw: true}) {
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
  NativeBehavior getNativeBehaviorForJsCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length < 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS);
      return new NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_FIRST);
      return new NativeBehavior();
    }

    String codeString = _getStringArgument(node, 1);
    if (codeString == null) {
      reporter.reportErrorMessage(
          CURRENT_ELEMENT_SPANNABLE, MessageKind.WRONG_ARGUMENT_FOR_JS_SECOND);
      return new NativeBehavior();
    }

    return NativeBehavior.ofJsCall(
        specString,
        codeString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  /// Computes the [NativeBehavior] for a call to the [JS_BUILTIN]
  /// function.
  // TODO(johnniwinther): Cache this for later use.
  NativeBehavior getNativeBehaviorForJsBuiltinCall(ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin expression has no type.");
      return new NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS builtin is missing name.");
      return new NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return new NativeBehavior();
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
  // TODO(johnniwinther): Cache this for later use.
  NativeBehavior getNativeBehaviorForJsEmbeddedGlobalCall(
      ir.StaticInvocation node) {
    if (node.arguments.positional.length < 1) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global expression has no type.");
      return new NativeBehavior();
    }
    if (node.arguments.positional.length < 2) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "JS embedded global is missing name.");
      return new NativeBehavior();
    }
    if (node.arguments.positional.length > 2 ||
        node.arguments.named.isNotEmpty) {
      reporter.internalError(CURRENT_ELEMENT_SPANNABLE,
          "JS embedded global has more than 2 arguments.");
      return new NativeBehavior();
    }
    String specString = _getStringArgument(node, 0);
    if (specString == null) {
      reporter.internalError(
          CURRENT_ELEMENT_SPANNABLE, "Unexpected first argument.");
      return new NativeBehavior();
    }
    return NativeBehavior.ofJsEmbeddedGlobalCall(
        specString,
        typeLookup(resolveAsRaw: true),
        CURRENT_ELEMENT_SPANNABLE,
        reporter,
        commonElements);
  }

  js.Name getNameForJsGetName(ConstantValue constant, Namer namer) {
    int index = extractEnumIndexFromConstantValue(
        constant, commonElements.jsGetNameEnum);
    if (index == null) return null;
    return namer.getNameForJsGetName(
        CURRENT_ELEMENT_SPANNABLE, JsGetName.values[index]);
  }

  int extractEnumIndexFromConstantValue(
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

  IndexedLibrary createLibrary(String name, Uri canonicalUri) {
    return new JLibrary(name, canonicalUri);
  }

  IndexedClass createClass(LibraryEntity library, String name,
      {bool isAbstract}) {
    return new JClass(library, name, isAbstract: isAbstract);
  }

  IndexedTypedef createTypedef(LibraryEntity library, String name) {
    return new JTypedef(library, name);
  }

  TypeVariableEntity createTypeVariable(
      Entity typeDeclaration, String name, int index) {
    return new JTypeVariable(typeDeclaration, name, index);
  }

  IndexedConstructor createGenerativeConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst}) {
    return new JGenerativeConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal, isConst: isConst);
  }

  IndexedConstructor createFactoryConstructor(ClassEntity enclosingClass,
      Name name, ParameterStructure parameterStructure,
      {bool isExternal, bool isConst, bool isFromEnvironmentConstructor}) {
    return new JFactoryConstructor(enclosingClass, name, parameterStructure,
        isExternal: isExternal,
        isConst: isConst,
        isFromEnvironmentConstructor: isFromEnvironmentConstructor);
  }

  JConstructorBody createConstructorBody(ConstructorEntity constructor) {
    return new JConstructorBody(constructor);
  }

  JGeneratorBody createGeneratorBody(
      FunctionEntity function, DartType elementType) {
    return new JGeneratorBody(function, elementType);
  }

  IndexedFunction createGetter(LibraryEntity library,
      ClassEntity enclosingClass, Name name, AsyncMarker asyncMarker,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new JGetter(library, enclosingClass, name, asyncMarker,
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
    return new JMethod(
        library, enclosingClass, name, parameterStructure, asyncMarker,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedFunction createSetter(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isExternal, bool isAbstract}) {
    return new JSetter(library, enclosingClass, name,
        isStatic: isStatic, isExternal: isExternal, isAbstract: isAbstract);
  }

  IndexedField createField(
      LibraryEntity library, ClassEntity enclosingClass, Name name,
      {bool isStatic, bool isAssignable, bool isConst}) {
    return new JField(library, enclosingClass, name,
        isStatic: isStatic, isAssignable: isAssignable, isConst: isConst);
  }

  LibraryEntity convertLibrary(IndexedLibrary library) {
    return createLibrary(library.name, library.canonicalUri);
  }

  ClassEntity convertClass(LibraryEntity library, IndexedClass cls) {
    return createClass(library, cls.name, isAbstract: cls.isAbstract);
  }

  TypedefEntity convertTypedef(LibraryEntity library, IndexedTypedef typedef) {
    return createTypedef(library, typedef.name);
  }

  MemberEntity convertMember(
      LibraryEntity library, ClassEntity cls, IndexedMember member) {
    Name memberName = new Name(member.memberName.text, library,
        isSetter: member.memberName.isSetter);
    if (member.isField) {
      IndexedField field = member;
      return createField(library, cls, memberName,
          isStatic: field.isStatic,
          isAssignable: field.isAssignable,
          isConst: field.isConst);
    } else if (member.isConstructor) {
      IndexedConstructor constructor = member;
      if (constructor.isFactoryConstructor) {
        // TODO(redemption): This should be a JFunction.
        return createFactoryConstructor(
            cls, memberName, constructor.parameterStructure,
            isExternal: constructor.isExternal,
            isConst: constructor.isConst,
            isFromEnvironmentConstructor:
                constructor.isFromEnvironmentConstructor);
      } else {
        return createGenerativeConstructor(
            cls, memberName, constructor.parameterStructure,
            isExternal: constructor.isExternal, isConst: constructor.isConst);
      }
    } else if (member.isGetter) {
      IndexedFunction getter = member;
      return createGetter(library, cls, memberName, getter.asyncMarker,
          isStatic: getter.isStatic,
          isExternal: getter.isExternal,
          isAbstract: getter.isAbstract);
    } else if (member.isSetter) {
      IndexedFunction setter = member;
      return createSetter(library, cls, memberName,
          isStatic: setter.isStatic,
          isExternal: setter.isExternal,
          isAbstract: setter.isAbstract);
    } else {
      IndexedFunction function = member;
      return createMethod(library, cls, memberName, function.parameterStructure,
          function.asyncMarker,
          isStatic: function.isStatic,
          isExternal: function.isExternal,
          isAbstract: function.isAbstract);
    }
  }

  void forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    assert(checkFamily(member));
    _nestedClosureMap[member]?.forEach(f);
  }

  @override
  InterfaceType getMemberThisType(MemberEntity member) {
    return members.getData(member).getMemberThisType(this);
  }

  @override
  ClassTypeVariableAccess getClassTypeVariableAccessForMember(
      MemberEntity member) {
    return members.getData(member).classTypeVariableAccess;
  }

  bool checkFamily(Entity entity) {
    assert(
        '$entity'.startsWith(jsElementPrefix),
        failedAt(entity,
            "Unexpected entity $entity, expected family $jsElementPrefix."));
    return true;
  }

  @override
  Spannable getSpannable(MemberEntity member, ir.Node node) {
    SourceSpan sourceSpan;
    if (node is ir.TreeNode) {
      sourceSpan = computeSourceSpanFromTreeNode(node);
    }
    sourceSpan ??= getSourceSpan(member, null);
    return sourceSpan;
  }

  Iterable<LibraryEntity> get libraryListInternal {
    return libraryMap.values;
  }

  LibraryEntity getLibraryInternal(ir.Library node, [JLibraryEnv env]) {
    LibraryEntity library = libraryMap[node];
    assert(library != null, "No library entity for $node");
    return library;
  }

  ClassEntity getClassInternal(ir.Class node, [JClassEnv env]) {
    ClassEntity cls = classMap[node];
    assert(cls != null, "No class entity for $node");
    return cls;
  }

  FieldEntity getFieldInternal(ir.Field node) {
    FieldEntity field = fieldMap[node];
    assert(field != null, "No field entity for $node");
    return field;
  }

  FunctionEntity getMethodInternal(ir.Procedure node) {
    FunctionEntity function = methodMap[node];
    assert(function != null, "No function entity for $node");
    return function;
  }

  ConstructorEntity getConstructorInternal(ir.Member node) {
    ConstructorEntity constructor = constructorMap[node];
    assert(constructor != null, "No constructor entity for $node");
    return constructor;
  }

  TypeVariableEntity getTypeVariableInternal(ir.TypeParameter node) {
    TypeVariableEntity typeVariable = typeVariableMap[node];
    if (typeVariable == null) {
      if (node.parent is ir.FunctionNode) {
        ir.FunctionNode func = node.parent;
        int index = func.typeParameters.indexOf(node);
        if (func.parent is ir.Constructor) {
          ir.Constructor constructor = func.parent;
          ir.Class cls = constructor.enclosingClass;
          typeVariableMap[node] =
              typeVariable = getTypeVariableInternal(cls.typeParameters[index]);
        } else if (func.parent is ir.Procedure) {
          ir.Procedure procedure = func.parent;
          if (procedure.kind == ir.ProcedureKind.Factory) {
            ir.Class cls = procedure.enclosingClass;
            typeVariableMap[node] = typeVariable =
                getTypeVariableInternal(cls.typeParameters[index]);
          }
        }
      }
    }
    assert(
        typeVariable != null,
        "No type variable entity for $node on "
        "${node.parent is ir.FunctionNode ? node.parent.parent : node.parent}");
    return typeVariable;
  }

  TypedefEntity getTypedefInternal(ir.Typedef node) {
    TypedefEntity typedef = typedefMap[node];
    assert(typedef != null, "No typedef entity for $node");
    return typedef;
  }

  @override
  FunctionEntity getConstructorBody(ir.Constructor node) {
    ConstructorEntity constructor = getConstructor(node);
    return _getConstructorBody(node, constructor);
  }

  FunctionEntity _getConstructorBody(
      ir.Constructor node, covariant IndexedConstructor constructor) {
    JConstructorDataImpl data = members.getData(constructor);
    if (data.constructorBody == null) {
      JConstructorBody constructorBody = createConstructorBody(constructor);
      members.register<IndexedFunction, FunctionData>(
          constructorBody,
          new ConstructorBodyDataImpl(
              node,
              node.function,
              new SpecialMemberDefinition(node, MemberKind.constructorBody),
              data.staticTypes));
      IndexedClass cls = constructor.enclosingClass;
      JClassEnvImpl classEnv = classes.getEnv(cls);
      // TODO(johnniwinther): Avoid this by only including live members in the
      // js-model.
      classEnv.addConstructorBody(constructorBody);
      data.constructorBody = constructorBody;
    }
    return data.constructorBody;
  }

  @override
  MemberDefinition getMemberDefinition(MemberEntity member) {
    return getMemberDefinitionInternal(member);
  }

  @override
  ClassDefinition getClassDefinition(ClassEntity cls) {
    return getClassDefinitionInternal(cls);
  }

  @override
  ConstantValue getFieldConstantValue(covariant IndexedField field) {
    assert(checkFamily(field));
    JFieldData data = members.getData(field);
    return data.getFieldConstantValue(this);
  }

  @override
  bool hasConstantFieldInitializer(covariant IndexedField field) {
    JFieldData data = members.getData(field);
    return data.hasConstantFieldInitializer(this);
  }

  @override
  ConstantValue getConstantFieldInitializer(covariant IndexedField field) {
    JFieldData data = members.getData(field);
    return data.getConstantFieldInitializer(this);
  }

  @override
  void forEachParameter(covariant IndexedFunction function,
      void f(DartType type, String name, ConstantValue defaultValue),
      {bool isNative: false}) {
    FunctionData data = members.getData(function);
    data.forEachParameter(this, f, isNative: isNative);
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

  JRecordField _constructRecordFieldEntry(
      InterfaceType memberThisType,
      ir.VariableDeclaration variable,
      BoxLocal boxLocal,
      Map<String, MemberEntity> memberMap,
      KernelToLocalsMap localsMap) {
    Local local = localsMap.getLocalVariable(variable);
    JRecordField boxedField =
        new JRecordField(local.name, boxLocal, isConst: variable.isConst);
    members.register(
        boxedField,
        new ClosureFieldData(
            new ClosureMemberDefinition(computeSourceSpanFromTreeNode(variable),
                MemberKind.closureField, variable),
            memberThisType));
    memberMap[boxedField.name] = boxedField;

    return boxedField;
  }

  /// Make a container controlling access to records, that is, variables that
  /// are accessed in different scopes. This function creates the container
  /// and returns a map of locals to the corresponding records created.
  @override
  Map<Local, JRecordField> makeRecordContainer(
      KernelScopeInfo info, MemberEntity member, KernelToLocalsMap localsMap) {
    Map<Local, JRecordField> boxedFields = {};
    if (info.boxedVariables.isNotEmpty) {
      NodeBox box = info.capturedVariablesAccessor;

      Map<String, IndexedMember> memberMap = <String, IndexedMember>{};
      JRecord container = new JRecord(member.library, box.name);
      BoxLocal boxLocal = new BoxLocal(container);
      InterfaceType thisType = new InterfaceType(container, const <DartType>[]);
      InterfaceType supertype = commonElements.objectType;
      JClassData containerData = new RecordClassData(
          new RecordContainerDefinition(getMemberDefinition(member).location),
          thisType,
          supertype,
          getOrderedTypeSet(supertype.element).extendClass(thisType));
      classes.register(container, containerData, new RecordEnv(memberMap));

      InterfaceType memberThisType = member.enclosingClass != null
          ? elementEnvironment.getThisType(member.enclosingClass)
          : null;
      for (ir.VariableDeclaration variable in info.boxedVariables) {
        boxedFields[localsMap.getLocalVariable(variable)] =
            _constructRecordFieldEntry(
                memberThisType, variable, boxLocal, memberMap, localsMap);
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
        ? elementEnvironment.getThisType(member.enclosingClass)
        : null;
    ClassTypeVariableAccess typeVariableAccess =
        members.getData(member).classTypeVariableAccess;
    if (typeVariableAccess == ClassTypeVariableAccess.instanceField) {
      // A closure in a field initializer will only be executed in the
      // constructor and type variables are therefore accessed through
      // parameters.
      typeVariableAccess = ClassTypeVariableAccess.parameter;
    }
    String name = _computeClosureName(node);
    SourceSpan location = computeSourceSpanFromTreeNode(node);
    Map<String, IndexedMember> memberMap = <String, IndexedMember>{};

    JClass classEntity = new JClosureClass(enclosingLibrary, name);
    // Create a classData and set up the interfaces and subclass
    // relationships that _ensureSupertypes and _ensureThisAndRawType are doing
    InterfaceType thisType = new InterfaceType(classEntity, const <DartType>[]);
    ClosureClassData closureData = new ClosureClassData(
        new ClosureClassDefinition(location),
        thisType,
        supertype,
        getOrderedTypeSet(supertype.element).extendClass(thisType));
    classes.register(classEntity, closureData, new ClosureClassEnv(memberMap));

    Local closureEntity;
    if (node.parent is ir.FunctionDeclaration) {
      ir.FunctionDeclaration parent = node.parent;
      closureEntity = localsMap.getLocalVariable(parent.variable);
    } else if (node.parent is ir.FunctionExpression) {
      closureEntity = new AnonymousClosureLocal(classEntity);
    }

    IndexedFunction callMethod = new JClosureCallMethod(
        classEntity, getParameterStructure(node), getAsyncMarker(node));
    _nestedClosureMap
        .putIfAbsent(member, () => <IndexedFunction>[])
        .add(callMethod);
    // We need create the type variable here - before we try to make local
    // variables from them (in `JsScopeInfo.from` called through
    // `KernelClosureClassInfo.fromScopeInfo` below).
    int index = 0;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      typeVariableMap[typeParameter] = typeVariables.register(
          createTypeVariable(callMethod, typeParameter.name, index),
          new JTypeVariableData(typeParameter));
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
            info.hasThisLocal
                ? new ThisLocal(localsMap.currentMember.enclosingClass)
                : null,
            this);
    _buildClosureClassFields(closureClassInfo, member, memberThisType, info,
        localsMap, recordFieldsVisibleInScope, memberMap);

    if (createSignatureMethod) {
      _constructSignatureMethod(closureClassInfo, memberMap, node,
          memberThisType, location, typeVariableAccess);
    }

    closureData.callType = getFunctionType(node);

    members.register<IndexedFunction, FunctionData>(
        callMethod,
        new ClosureFunctionData(
            new ClosureMemberDefinition(
                location, MemberKind.closureCall, node.parent),
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
        '_box_$fieldNumber', closureClassInfo, recordField.box.name,
        isConst: true, isAssignable: false);

    members.register<IndexedField, JFieldData>(
        closureField,
        new ClosureFieldData(
            new ClosureMemberDefinition(
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
    FunctionEntity signatureMethod =
        new JSignatureMethod(closureClassInfo.closureClassEntity);
    members.register<IndexedFunction, FunctionData>(
        signatureMethod,
        new SignatureFunctionData(
            new SpecialMemberDefinition(
                closureSourceNode.parent, MemberKind.signature),
            memberThisType,
            closureSourceNode.typeParameters,
            typeVariableAccess));
    memberMap[signatureMethod.name] =
        closureClassInfo.signatureMethod = signatureMethod;
  }

  void _constructClosureField(
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
        capturedLocal.name,
        isConst: isConst,
        isAssignable: isAssignable);

    members.register<IndexedField, JFieldData>(
        closureField,
        new ClosureFieldData(
            new ClosureMemberDefinition(
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

  @override
  JGeneratorBody getGeneratorBody(covariant IndexedFunction function) {
    JGeneratorBody generatorBody = _generatorBodies[function];
    if (generatorBody == null) {
      FunctionData functionData = members.getData(function);
      ir.TreeNode node = functionData.definition.node;
      DartType elementType =
          elementEnvironment.getFunctionAsyncOrSyncStarElementType(function);
      generatorBody = createGeneratorBody(function, elementType);
      members.register<IndexedFunction, FunctionData>(
          generatorBody,
          new GeneratorBodyFunctionData(functionData,
              new SpecialMemberDefinition(node, MemberKind.generatorBody)));

      if (function.enclosingClass != null) {
        // TODO(sra): Integrate this with ClassEnvImpl.addConstructorBody ?
        (_injectedClassMembers[function.enclosingClass] ??= <IndexedMember>[])
            .add(generatorBody);
      }
    }
    return generatorBody;
  }

  @override
  js.Template getJsBuiltinTemplate(
      ConstantValue constant, CodeEmitterTask emitter) {
    int index = extractEnumIndexFromConstantValue(
        constant, commonElements.jsBuiltinEnum);
    if (index == null) return null;
    return emitter.builtinTemplateFor(JsBuiltin.values[index]);
  }
}

class JsElementEnvironment extends ElementEnvironment
    implements JElementEnvironment {
  final JsKernelToElementMap elementMap;

  JsElementEnvironment(this.elementMap);

  @override
  DartType get dynamicType => const DynamicType();

  @override
  LibraryEntity get mainLibrary => elementMap._mainLibrary;

  @override
  FunctionEntity get mainFunction => elementMap._mainFunction;

  @override
  Iterable<LibraryEntity> get libraries => elementMap.libraryListInternal;

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
  void forEachLocalClassMember(ClassEntity cls, void f(MemberEntity member)) {
    elementMap._forEachLocalClassMember(cls, f);
  }

  @override
  void forEachInjectedClassMember(
      ClassEntity cls, void f(MemberEntity member)) {
    elementMap.forEachInjectedClassMember(cls, f);
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
    elementMap.forEachConstructorBody(cls, f);
  }

  @override
  void forEachNestedClosure(
      MemberEntity member, void f(FunctionEntity closure)) {
    elementMap.forEachNestedClosure(member, f);
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
  bool isEnumClass(ClassEntity cls) {
    assert(elementMap.checkFamily(cls));
    JClassData classData = elementMap.classes.getData(cls);
    return classData.isEnumClass;
  }
}

/// [BehaviorBuilder] for kernel based elements.
class JsBehaviorBuilder extends BehaviorBuilder {
  final ElementEnvironment elementEnvironment;
  final CommonElements commonElements;
  final DiagnosticReporter reporter;
  final NativeBasicData nativeBasicData;
  final CompilerOptions _options;

  JsBehaviorBuilder(this.elementEnvironment, this.commonElements,
      this.nativeBasicData, this.reporter, this._options);

  @override
  bool get trustJSInteropTypeAnnotations =>
      _options.trustJSInteropTypeAnnotations;
}

/// Constant environment mapping [ConstantExpression]s to [ConstantValue]s using
/// [_EvaluationEnvironment] for the evaluation.
class JsConstantEnvironment implements ConstantEnvironment {
  final JsKernelToElementMap _elementMap;
  final Environment _environment;

  Map<ConstantExpression, ConstantValue> _valueMap =
      <ConstantExpression, ConstantValue>{};

  JsConstantEnvironment(this._elementMap, this._environment);

  @override
  ConstantSystem get constantSystem => JavaScriptConstantSystem.only;

  ConstantValue _getConstantValue(
      Spannable spannable, ConstantExpression expression,
      {bool constantRequired}) {
    return _valueMap.putIfAbsent(expression, () {
      return expression.evaluate(
          new JsEvaluationEnvironment(_elementMap, _environment, spannable,
              constantRequired: constantRequired),
          constantSystem);
    });
  }
}

/// Evaluation environment used for computing [ConstantValue]s for
/// kernel based [ConstantExpression]s.
class JsEvaluationEnvironment extends EvaluationEnvironmentBase {
  final JsKernelToElementMap _elementMap;
  final Environment _environment;

  JsEvaluationEnvironment(
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

class JsToFrontendMapImpl extends JsToFrontendMapBase
    implements JsToFrontendMap {
  final JsKernelToElementMap _backend;

  JsToFrontendMapImpl(this._backend);

  LibraryEntity toBackendLibrary(covariant IndexedLibrary library) {
    return _backend.libraries.getEntity(library.libraryIndex);
  }

  ClassEntity toBackendClass(covariant IndexedClass cls) {
    return _backend.classes.getEntity(cls.classIndex);
  }

  MemberEntity toBackendMember(covariant IndexedMember member) {
    return _backend.members.getEntity(member.memberIndex);
  }

  TypedefEntity toBackendTypedef(covariant IndexedTypedef typedef) {
    return _backend.typedefs.getEntity(typedef.typedefIndex);
  }

  TypeVariableEntity toBackendTypeVariable(TypeVariableEntity typeVariable) {
    if (typeVariable is KLocalTypeVariable) {
      failedAt(
          typeVariable, "Local function type variables are not supported.");
    }
    IndexedTypeVariable indexedTypeVariable = typeVariable;
    return _backend.typeVariables
        .getEntity(indexedTypeVariable.typeVariableIndex);
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
  final Map<int, JTypedef> _typedefs = {};
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

  void registerTypedef(int index, JTypedef typedef) {
    assert(!_typedefs.containsKey(index),
        "Typedef for index $index has already been defined.");
    _typedefs[index] = typedef;
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

  void forEachTypedef(void f(int index, JTypedef typedef)) {
    _typedefs.forEach(f);
  }

  void forEachMember(void f(int index, JMember member)) {
    _members.forEach(f);
  }

  void forEachTypeVariable(void f(int index, JTypeVariable typeVariable)) {
    _typeVariables.forEach(f);
  }

  @override
  IndexedLibrary getLibraryByIndex(int index) {
    IndexedLibrary library = _libraries[index];
    assert(library != null, "No library found for index $index");
    return library;
  }

  @override
  IndexedClass getClassByIndex(int index) {
    IndexedClass cls = _classes[index];
    assert(cls != null, "No class found for index $index");
    return cls;
  }

  @override
  IndexedTypedef getTypedefByIndex(int index) {
    IndexedTypedef typedef = _typedefs[index];
    assert(typedef != null, "No typedef found for index $index");
    return typedef;
  }

  @override
  IndexedMember getMemberByIndex(int index) {
    IndexedMember member = _members[index];
    assert(member != null, "No member found for index $index");
    return member;
  }

  @override
  IndexedTypeVariable getTypeVariableByIndex(int index) {
    IndexedTypeVariable typeVariable = _typeVariables[index];
    assert(typeVariable != null, "No type variable found for index $index");
    return typeVariable;
  }
}
