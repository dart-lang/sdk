// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_runtime/shared/embedded_names.dart';
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/class_hierarchy.dart' as ir;
import 'package:kernel/core_types.dart' as ir;
import 'package:kernel/type_environment.dart' as ir;

import '../closure.dart' show BoxLocal, ThisLocal;
import '../common.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/indexed.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../ir/util.dart';
import '../js/js.dart' as js;
import '../js_backend/native_data.dart';
import '../js_emitter/code_emitter_task.dart';
import '../js_model/closure.dart';
import '../js_model/elements.dart';
import '../js_model/element_map.dart';
import '../js_model/locals.dart';
import '../kernel/element_map.dart';
import '../kernel/element_map_impl.dart';
import '../kernel/env.dart';
import '../ssa/type_builder.dart';

import 'element_map.dart';

/// Interface for kernel queries needed to implement the [CodegenWorldBuilder].
abstract class KernelToWorldBuilder implements JsToElementMap {
  /// Returns `true` if [field] has a constant initializer.
  bool hasConstantFieldInitializer(FieldEntity field);

  /// Returns the constant initializer for [field].
  ConstantValue getConstantFieldInitializer(FieldEntity field);

  /// Calls [f] for each parameter of [function] providing the type and name of
  /// the parameter and the [defaultValue] if the parameter is optional.
  void forEachParameter(FunctionEntity function,
      void f(DartType type, String name, ConstantValue defaultValue));
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
        JsToElementMap {
  /// Map from members to the call methods created for their nested closures.
  Map<MemberEntity, List<FunctionEntity>> _nestedClosureMap =
      <MemberEntity, List<FunctionEntity>>{};

  @override
  NativeBasicData nativeBasicData;

  Map<FunctionEntity, JGeneratorBody> _generatorBodies =
      <FunctionEntity, JGeneratorBody>{};

  Map<ClassEntity, List<MemberEntity>> _injectedClassMembers =
      <ClassEntity, List<MemberEntity>>{};

  JsKernelToElementMap(DiagnosticReporter reporter, Environment environment,
      KernelToElementMapImpl _elementMap, Iterable<MemberEntity> liveMembers)
      : super(_elementMap.options, reporter, environment) {
    env = _elementMap.env;
    for (int libraryIndex = 0;
        libraryIndex < _elementMap.libraries.length;
        libraryIndex++) {
      IndexedLibrary oldLibrary = _elementMap.libraries.getEntity(libraryIndex);
      LibraryEnv env = _elementMap.libraries.getEnv(oldLibrary);
      LibraryData data = _elementMap.libraries.getData(oldLibrary);
      IndexedLibrary newLibrary = convertLibrary(oldLibrary);
      libraryMap[env.library] =
          libraries.register<IndexedLibrary, LibraryData, LibraryEnv>(
              newLibrary, data.copy(), env.copyLive(_elementMap, liveMembers));
      assert(newLibrary.libraryIndex == oldLibrary.libraryIndex);
    }
    for (int classIndex = 0;
        classIndex < _elementMap.classes.length;
        classIndex++) {
      IndexedClass oldClass = _elementMap.classes.getEntity(classIndex);
      ClassEnv env = _elementMap.classes.getEnv(oldClass);
      ClassData data = _elementMap.classes.getData(oldClass);
      IndexedLibrary oldLibrary = oldClass.library;
      LibraryEntity newLibrary = libraries.getEntity(oldLibrary.libraryIndex);
      IndexedClass newClass = convertClass(newLibrary, oldClass);
      classMap[env.cls] = classes.register(
          newClass, data.copy(), env.copyLive(_elementMap, liveMembers));
      assert(newClass.classIndex == oldClass.classIndex);
    }
    for (int typedefIndex = 0;
        typedefIndex < _elementMap.typedefs.length;
        typedefIndex++) {
      IndexedTypedef oldTypedef = _elementMap.typedefs.getEntity(typedefIndex);
      TypedefData data = _elementMap.typedefs.getData(oldTypedef);
      IndexedLibrary oldLibrary = oldTypedef.library;
      LibraryEntity newLibrary = libraries.getEntity(oldLibrary.libraryIndex);
      IndexedTypedef newTypedef = convertTypedef(newLibrary, oldTypedef);
      typedefMap[data.node] = typedefs.register(
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
        memberIndex < _elementMap.members.length;
        memberIndex++) {
      IndexedMember oldMember = _elementMap.members.getEntity(memberIndex);
      if (!liveMembers.contains(oldMember)) {
        members.skipIndex(oldMember.memberIndex);
        continue;
      }
      MemberDataImpl data = _elementMap.members.getData(oldMember);
      IndexedLibrary oldLibrary = oldMember.library;
      IndexedClass oldClass = oldMember.enclosingClass;
      LibraryEntity newLibrary = libraries.getEntity(oldLibrary.libraryIndex);
      ClassEntity newClass =
          oldClass != null ? classes.getEntity(oldClass.classIndex) : null;
      IndexedMember newMember = convertMember(newLibrary, newClass, oldMember);
      members.register(newMember, data.copy());
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
      TypeVariableData oldTypeVariableData =
          _elementMap.typeVariables.getData(oldTypeVariable);
      Entity newTypeDeclaration;
      if (oldTypeVariable.typeDeclaration is ClassEntity) {
        IndexedClass cls = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = classes.getEntity(cls.classIndex);
      } else if (oldTypeVariable.typeDeclaration is MemberEntity) {
        IndexedMember member = oldTypeVariable.typeDeclaration;
        newTypeDeclaration = members.getEntity(member.memberIndex);
      } else {
        assert(oldTypeVariable.typeDeclaration is Local);
      }
      IndexedTypeVariable newTypeVariable = createTypeVariable(
          newTypeDeclaration, oldTypeVariable.name, oldTypeVariable.index);
      typeVariables.register<IndexedTypeVariable, TypeVariableData>(
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

  @override
  Entity getClosure(ir.FunctionDeclaration node) {
    throw new UnsupportedError('JsKernelToElementMap.getClosure');
  }

  @override
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
    SourceSpan sourceSpan;
    if (node is ir.TreeNode) {
      sourceSpan = computeSourceSpanFromTreeNode(node);
    }
    sourceSpan ??= getSourceSpan(member, null);
    return sourceSpan;
  }

  @override
  Iterable<LibraryEntity> get libraryListInternal {
    return libraryMap.values;
  }

  @override
  LibraryEntity getLibraryInternal(ir.Library node, [LibraryEnv env]) {
    LibraryEntity library = libraryMap[node];
    assert(library != null, "No library entity for $node");
    return library;
  }

  @override
  ClassEntity getClassInternal(ir.Class node, [ClassEnv env]) {
    ClassEntity cls = classMap[node];
    assert(cls != null, "No class entity for $node");
    return cls;
  }

  // TODO(johnniwinther): Reinsert these when [ElementCreatorMixin] is no longer
  // mixed in.
  @override
  FieldEntity getFieldInternal(ir.Field node) {
    FieldEntity field = fieldMap[node];
    assert(field != null, "No field entity for $node");
    return field;
  }

  @override
  FunctionEntity getMethodInternal(ir.Procedure node) {
    FunctionEntity function = methodMap[node];
    assert(function != null, "No function entity for $node");
    return function;
  }

  @override
  ConstructorEntity getConstructorInternal(ir.Member node) {
    ConstructorEntity constructor = constructorMap[node];
    assert(constructor != null, "No constructor entity for $node");
    return constructor;
  }

  @override
  FunctionEntity getConstructorBody(ir.Constructor node) {
    ConstructorEntity constructor = getConstructor(node);
    return _getConstructorBody(node, constructor);
  }

  FunctionEntity _getConstructorBody(
      ir.Constructor node, covariant IndexedConstructor constructor) {
    ConstructorDataImpl data = members.getData(constructor);
    if (data.constructorBody == null) {
      JConstructorBody constructorBody = createConstructorBody(constructor);
      members.register<IndexedFunction, FunctionData>(
          constructorBody,
          new ConstructorBodyDataImpl(
              node,
              node.function,
              new SpecialMemberDefinition(
                  constructorBody, node, MemberKind.constructorBody)));
      IndexedClass cls = constructor.enclosingClass;
      ClassEnvImpl classEnv = classes.getEnv(cls);
      // TODO(johnniwinther): Avoid this by only including live members in the
      // js-model.
      classEnv.addConstructorBody(constructorBody);
      data.constructorBody = constructorBody;
    }
    return data.constructorBody;
  }

  @override
  JConstructorBody createConstructorBody(ConstructorEntity constructor);

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
    FieldData data = members.getData(field);
    return data.getFieldConstantValue(this);
  }

  @override
  bool hasConstantFieldInitializer(covariant IndexedField field) {
    FieldData data = members.getData(field);
    return data.hasConstantFieldInitializer(this);
  }

  @override
  ConstantValue getConstantFieldInitializer(covariant IndexedField field) {
    FieldData data = members.getData(field);
    return data.getConstantFieldInitializer(this);
  }

  @override
  void forEachParameter(covariant IndexedFunction function,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    FunctionData data = members.getData(function);
    data.forEachParameter(this, f);
  }

  @override
  void forEachConstructorBody(
      IndexedClass cls, void f(ConstructorBodyEntity member)) {
    ClassEnv env = classes.getEnv(cls);
    env.forEachConstructorBody(f);
  }

  @override
  void forEachInjectedClassMember(
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
    members.register(
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
  @override
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
      classes.register(container, containerData, new RecordEnv(memberMap));

      BoxLocal boxLocal = new BoxLocal(box.name);
      InterfaceType memberThisType = member.enclosingClass != null
          ? elementEnvironment.getThisType(member.enclosingClass)
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
    classes.register(classEntity, closureData, new ClosureClassEnv(memberMap));

    Local closureEntity;
    if (node.parent is ir.FunctionDeclaration) {
      ir.FunctionDeclaration parent = node.parent;
      closureEntity = localsMap.getLocalVariable(parent.variable);
    } else if (node.parent is ir.FunctionExpression) {
      closureEntity = new JLocal('', localsMap.currentMember);
    }

    FunctionEntity callMethod = new JClosureCallMethod(
        classEntity, getParameterStructure(node), getAsyncMarker(node));
    _nestedClosureMap
        .putIfAbsent(member, () => <FunctionEntity>[])
        .add(callMethod);
    // We need create the type variable here - before we try to make local
    // variables from them (in `JsScopeInfo.from` called through
    // `KernelClosureClassInfo.fromScopeInfo` below).
    int index = 0;
    for (ir.TypeParameter typeParameter in node.typeParameters) {
      typeVariableMap[typeParameter] = typeVariables.register(
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

    members.register<IndexedFunction, FunctionData>(
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

    members.register<IndexedField, FieldData>(
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
    members.register<IndexedFunction, FunctionData>(
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
        isConst,
        isAssignable,
        capturedLocal);

    members.register<IndexedField, FieldData>(
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

  @override
  JGeneratorBody createGeneratorBody(
      FunctionEntity function, DartType elementType);

  @override
  js.Template getJsBuiltinTemplate(
      ConstantValue constant, CodeEmitterTask emitter) {
    int index = extractEnumIndexFromConstantValue(
        constant, commonElements.jsBuiltinEnum);
    if (index == null) return null;
    return emitter.builtinTemplateFor(JsBuiltin.values[index]);
  }
}
