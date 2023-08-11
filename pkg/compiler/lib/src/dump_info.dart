// Copyright (c) 2013, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dump_info;

import 'dart:convert' show JsonEncoder, StringConversionSink;

import 'package:compiler/src/js_model/elements.dart';
import 'package:dart2js_info/info.dart';
import 'package:dart2js_info/json_info_codec.dart';
import 'package:dart2js_info/binary_serialization.dart' as dump_info;
import 'package:kernel/ast.dart' as ir;
import 'package:kernel/core_types.dart' as ir;

import '../compiler_api.dart' as api;
import 'common.dart';
import 'common/elements.dart' show JElementEnvironment;
import 'common/names.dart';
import 'common/tasks.dart' show CompilerTask;
import 'common/ram_usage.dart';
import 'compiler.dart' show Compiler;
import 'constants/values.dart' show ConstantValue;
import 'deferred_load/output_unit.dart' show OutputUnit, deferredPartFileName;
import 'elements/entities.dart';
import 'elements/entity_utils.dart' as entity_utils;
import 'elements/names.dart';
import 'inferrer/abstract_value_domain.dart';
import 'inferrer/types.dart'
    show GlobalTypeInferenceMemberResult, GlobalTypeInferenceResults;
import 'js/js.dart' as jsAst;
import 'js_model/js_strategy.dart';
import 'js_model/js_world.dart' show JClosedWorld;
import 'js_backend/field_analysis.dart';
import 'universe/world_impact.dart' show WorldImpact;
import 'util/sink_adapter.dart';

class ElementInfoCollector {
  final Compiler compiler;
  final JClosedWorld closedWorld;
  final GlobalTypeInferenceResults _globalInferenceResults;
  final DumpInfoTask dumpInfoTask;

  JElementEnvironment get environment => closedWorld.elementEnvironment;

  final state = DumpInfoStateData();

  ElementInfoCollector(this.compiler, this.dumpInfoTask, this.closedWorld,
      this._globalInferenceResults);

  void run() {
    dumpInfoTask._constantToNode.forEach((constant, node) {
      // TODO(sigmund): add dependencies on other constants
      var span = dumpInfoTask._nodeData[node]!;
      var info = ConstantInfo(
          size: span.end! - span.start!,
          code: [span],
          outputUnit: _unitInfoForConstant(constant));
      state.constantToInfo[constant] = info;
      state.info.constants.add(info);
    });
    environment.libraries.forEach(visitLibrary);
  }

  /// Whether to emit information about [entity].
  ///
  /// By default we emit information for any entity that contributes to the
  /// output size. Either because it is a function being emitted or inlined,
  /// or because it is an entity that holds dependencies to other entities.
  bool shouldKeep(Entity entity) {
    return dumpInfoTask.impacts.containsKey(entity) ||
        dumpInfoTask.inlineCount.containsKey(entity);
  }

  LibraryInfo? visitLibrary(LibraryEntity lib) {
    String libname = environment.getLibraryName(lib);
    if (libname.isEmpty) {
      libname = '<unnamed>';
    }
    int size = dumpInfoTask.sizeOf(lib);
    LibraryInfo info = LibraryInfo(libname, lib.canonicalUri, null, size);
    state.entityToInfo[lib] = info;

    environment.forEachLibraryMember(lib, (MemberEntity member) {
      if (member.isFunction || member.isGetter || member.isSetter) {
        final functionInfo = visitFunction(member as FunctionEntity);
        if (functionInfo != null) {
          info.topLevelFunctions.add(functionInfo);
          functionInfo.parent = info;
        }
      } else if (member is FieldEntity) {
        final fieldInfo = visitField(member);
        if (fieldInfo != null) {
          info.topLevelVariables.add(fieldInfo);
          fieldInfo.parent = info;
        }
      }
    });

    environment.forEachClass(lib, (ClassEntity clazz) {
      final classTypeInfo = visitClassType(clazz);
      if (classTypeInfo != null) {
        info.classTypes.add(classTypeInfo);
        classTypeInfo.parent = info;
      }

      final classInfo = visitClass(clazz);
      if (classInfo != null) {
        info.classes.add(classInfo);
        classInfo.parent = info;
      }
    });

    if (info.isEmpty && !shouldKeep(lib)) return null;
    state.info.libraries.add(info);
    return info;
  }

  GlobalTypeInferenceMemberResult _resultOfMember(MemberEntity e) =>
      _globalInferenceResults.resultOfMember(e);

  AbstractValue _resultOfParameter(Local e) =>
      _globalInferenceResults.resultOfParameter(e);

  FieldInfo? visitField(FieldEntity field) {
    AbstractValue inferredType = _resultOfMember(field).type;
    // If a field has an empty inferred type it is never used.
    if (closedWorld.abstractValueDomain
        .isEmpty(inferredType)
        .isDefinitelyTrue) {
      return null;
    }

    int size = dumpInfoTask.sizeOf(field);
    List<CodeSpan> code = dumpInfoTask.codeOf(field);

    // TODO(het): Why doesn't `size` account for the code size already?
    size += code.length;

    FieldInfo info = FieldInfo(
        name: field.name!,
        type: '${environment.getFieldType(field)}',
        inferredType: '$inferredType',
        code: code,
        outputUnit: _unitInfoForMember(field),
        isConst: field.isConst);
    state.entityToInfo[field] = info;
    final fieldData = closedWorld.fieldAnalysis.getFieldData(field as JField);
    if (fieldData.initialValue != null) {
      info.initializer =
          state.constantToInfo[fieldData.initialValue] as ConstantInfo?;
    }

    if (compiler.options.experimentCallInstrumentation) {
      // We use field.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${field.hashCode}';
    }

    int closureSize = _addClosureInfo(info, field);
    info.size = size + closureSize;

    state.info.fields.add(info);
    return info;
  }

  ClassTypeInfo? visitClassType(ClassEntity clazz) {
    // Omit class type if it is not needed.
    ClassTypeInfo classTypeInfo = ClassTypeInfo(
        name: clazz.name, outputUnit: _unitInfoForClassType(clazz));

    // TODO(joshualitt): Get accurate size information for class types.
    classTypeInfo.size = 0;

    bool isNeeded =
        compiler.backendStrategy.emitterTask.neededClassTypes.contains(clazz);
    if (!isNeeded) {
      return null;
    }

    state.info.classTypes.add(classTypeInfo);
    return classTypeInfo;
  }

  /// Returns all immediately extended, implemented, or mixed-in types of
  /// [clazz].
  List<ClassEntity> getImmediateSupers(ClassEntity clazz) {
    final superclass =
        environment.getSuperClass(clazz, skipUnnamedMixinApplications: true);
    // Ignore 'Object' to reduce overhead.
    return [
      if (superclass != null &&
          superclass != closedWorld.commonElements.objectClass)
        superclass,
      ...closedWorld.dartTypes.getInterfaces(clazz).map((i) => i.element),
    ];
  }

  ClassInfo? visitClass(ClassEntity clazz) {
    // True if [info] can be safely removed from the output.
    bool filterClassInfo(ClassInfo info) =>
        !compiler.backendStrategy.emitterTask.neededClasses.contains(clazz) &&
        info.fields.isEmpty &&
        info.functions.isEmpty;

    ClassInfo? classInfo = state.entityToInfo[clazz] as ClassInfo?;
    if (classInfo != null) {
      return filterClassInfo(classInfo) ? null : classInfo;
    }
    final supers = <ClassInfo>[];
    getImmediateSupers(clazz).forEach((superInterface) {
      final superclass =
          environment.lookupClass(superInterface.library, superInterface.name);
      if (superclass == null) return;
      final classInfo = visitClass(superclass);
      if (classInfo == null) return;
      supers.add(classInfo);
    });
    classInfo = ClassInfo(
        name: clazz.name,
        isAbstract: clazz.isAbstract,
        supers: supers,
        outputUnit: _unitInfoForClass(clazz));
    state.entityToInfo[clazz] = classInfo;

    int size = dumpInfoTask.sizeOf(clazz);
    environment.forEachLocalClassMember(clazz, (member) {
      if (member.isFunction || member.isGetter || member.isSetter) {
        final functionInfo = visitFunction(member as FunctionEntity);
        if (functionInfo != null) {
          classInfo!.functions.add(functionInfo);
          functionInfo.parent = classInfo;
          for (var closureInfo in functionInfo.closures) {
            size += closureInfo.size;
          }
        }
      } else if (member is FieldEntity) {
        final fieldInfo = visitField(member);
        if (fieldInfo != null) {
          classInfo!.fields.add(fieldInfo);
          fieldInfo.parent = classInfo;
          for (var closureInfo in fieldInfo.closures) {
            size += closureInfo.size;
          }
        }
      } else {
        throw StateError('Class member not a function or field');
      }
    });
    environment.forEachConstructor(clazz, (constructor) {
      final functionInfo = visitFunction(constructor);
      if (functionInfo != null) {
        classInfo!.functions.add(functionInfo);
        functionInfo.parent = classInfo;
        for (var closureInfo in functionInfo.closures) {
          size += closureInfo.size;
        }
      }
    });

    classInfo.size = size;

    if (filterClassInfo(classInfo)) {
      return null;
    }

    state.info.classes.add(classInfo);
    return classInfo;
  }

  ClosureInfo? visitClosureClass(ClassEntity element) {
    ClosureInfo closureInfo = ClosureInfo(
        name: element.name,
        outputUnit: _unitInfoForClass(element),
        size: dumpInfoTask.sizeOf(element));
    state.entityToInfo[element] = closureInfo;

    final callMethod =
        closedWorld.elementEnvironment.lookupClassMember(element, Names.call);

    final functionInfo = visitFunction(callMethod as FunctionEntity);
    if (functionInfo == null) return null;
    closureInfo.function = functionInfo;
    functionInfo.parent = closureInfo;

    state.info.closures.add(closureInfo);
    return closureInfo;
  }

  FunctionInfo? visitFunction(FunctionEntity function) {
    int size = dumpInfoTask.sizeOf(function);
    // TODO(sigmund): consider adding a small info to represent unreachable
    // code here.
    if (size == 0 && !shouldKeep(function)) return null;

    // TODO(het): use 'toString' instead of 'text'? It will add '=' for setters
    String name = function.memberName.text;
    int? kind;
    if (function.isStatic || function.isTopLevel) {
      kind = FunctionInfo.TOP_LEVEL_FUNCTION_KIND;
    } else if (function.enclosingClass != null) {
      kind = FunctionInfo.METHOD_FUNCTION_KIND;
    }

    if (function is ConstructorEntity) {
      name = name == ""
          ? "${function.enclosingClass.name}"
          : "${function.enclosingClass.name}.${function.name}";
      kind = FunctionInfo.CONSTRUCTOR_FUNCTION_KIND;
    }

    FunctionModifiers modifiers = FunctionModifiers(
      isStatic: function.isStatic,
      isConst: function.isConst,
      isFactory:
          function is ConstructorEntity ? function.isFactoryConstructor : false,
      isExternal: function.isExternal,
    );
    List<CodeSpan> code = dumpInfoTask.codeOf(function);

    List<ParameterInfo> parameters = <ParameterInfo>[];
    List<String> inferredParameterTypes = <String>[];

    closedWorld.elementEnvironment.forEachParameterAsLocal(
        _globalInferenceResults.globalLocalsMap, function, (parameter) {
      inferredParameterTypes.add('${_resultOfParameter(parameter)}');
    });
    int parameterIndex = 0;
    closedWorld.elementEnvironment.forEachParameter(function, (type, name, _) {
      // Synthesized parameters have no name. This can happen on parameters of
      // setters derived from lowering late fields.
      parameters.add(ParameterInfo(name ?? '#t${parameterIndex}',
          inferredParameterTypes[parameterIndex++], '$type'));
    });

    final functionType = environment.getFunctionType(function);
    String returnType = '${functionType.returnType}';

    String inferredReturnType = '${_resultOfMember(function).returnType}';
    String sideEffects =
        '${_globalInferenceResults.inferredData.getSideEffectsOfElement(function)}';

    int inlinedCount = dumpInfoTask.inlineCount[function] ?? 0;

    FunctionInfo info = FunctionInfo(
        name: name,
        functionKind: kind!,
        modifiers: modifiers,
        returnType: returnType,
        inferredReturnType: inferredReturnType,
        parameters: parameters,
        sideEffects: sideEffects,
        inlinedCount: inlinedCount,
        code: code,
        type: functionType.toString(),
        outputUnit: _unitInfoForMember(function));
    state.entityToInfo[function] = info;

    int closureSize = _addClosureInfo(info, function);
    size += closureSize;

    if (compiler.options.experimentCallInstrumentation) {
      // We use function.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${function.hashCode}';
    }

    info.size = size;

    state.info.functions.add(info);
    return info;
  }

  /// Adds closure information to [info], using all nested closures in [member].
  ///
  /// Returns the total size of the nested closures, to add to the info size.
  int _addClosureInfo(Info info, MemberEntity member) {
    assert(info is FunctionInfo || info is FieldInfo);
    int size = 0;
    List<ClosureInfo> nestedClosures = <ClosureInfo>[];
    environment.forEachNestedClosure(member, (closure) {
      final closureInfo = visitClosureClass(closure.enclosingClass!);
      if (closureInfo != null) {
        closureInfo.parent = info;
        nestedClosures.add(closureInfo);
        size += closureInfo.size;
      }
    });
    if (info is FunctionInfo) info.closures = nestedClosures;
    if (info is FieldInfo) info.closures = nestedClosures;

    return size;
  }

  OutputUnitInfo _infoFromOutputUnit(OutputUnit outputUnit) {
    return state.outputToInfo.putIfAbsent(outputUnit, () {
      // Dump-info currently only works with the full emitter. If another
      // emitter is used it will fail here.
      JsBackendStrategy backendStrategy = compiler.backendStrategy;
      final filename = outputUnit.isMainOutput
          ? (compiler.options.outputUri?.pathSegments.last ?? 'out')
          : deferredPartFileName(compiler.options, outputUnit.name);
      OutputUnitInfo info = OutputUnitInfo(filename, outputUnit.name,
          backendStrategy.emitterTask.emitter.generatedSize(outputUnit));
      info.imports
          .addAll(closedWorld.outputUnitData.getImportNames(outputUnit));
      state.info.outputUnits.add(info);
      return info;
    });
  }

  OutputUnitInfo _unitInfoForMember(MemberEntity entity) {
    return _infoFromOutputUnit(
        closedWorld.outputUnitData.outputUnitForMember(entity));
  }

  OutputUnitInfo _unitInfoForClass(ClassEntity entity) {
    return _infoFromOutputUnit(
        closedWorld.outputUnitData.outputUnitForClass(entity, allowNull: true));
  }

  OutputUnitInfo _unitInfoForClassType(ClassEntity entity) {
    return _infoFromOutputUnit(closedWorld.outputUnitData
        .outputUnitForClassType(entity, allowNull: true));
  }

  OutputUnitInfo _unitInfoForConstant(ConstantValue constant) {
    final outputUnit =
        closedWorld.outputUnitData.outputUnitForConstant(constant);
    return _infoFromOutputUnit(outputUnit);
  }
}

class KernelInfoCollector {
  final ir.Component component;
  final Compiler compiler;
  final JClosedWorld closedWorld;
  final DumpInfoTask dumpInfoTask;
  final state = DumpInfoStateData();
  final ir.CoreTypes coreTypes;

  JElementEnvironment get environment => closedWorld.elementEnvironment;

  KernelInfoCollector(
      this.component, this.compiler, this.dumpInfoTask, this.closedWorld)
      : this.coreTypes = ir.CoreTypes(component);

  void run() {
    // TODO(markzipan): Add CFE constants to `state.info.constants`.
    component.libraries.forEach(visitLibrary);
  }

  LibraryInfo? visitLibrary(ir.Library lib) {
    final libEntity = environment.lookupLibrary(lib.importUri);
    if (libEntity == null) return null;

    String? libname = lib.name;
    if (libname == null || libname.isEmpty) {
      libname = '${lib.importUri}';
    }
    LibraryInfo info = LibraryInfo(libname, lib.importUri, null, 0);

    lib.members.forEach((ir.Member member) {
      final memberEntity =
          environment.lookupLibraryMember(libEntity, member.name.text);
      if (memberEntity == null) return;
      final function = member.function;
      if (function != null) {
        final functionInfo = visitFunction(function,
            functionEntity: memberEntity as FunctionEntity);
        if (functionInfo != null) {
          info.topLevelFunctions.add(functionInfo);
          functionInfo.parent = info;
        }
      } else {
        final fieldInfo = visitField(member as ir.Field,
            fieldEntity: memberEntity as FieldEntity);
        if (fieldInfo != null) {
          info.topLevelVariables.add(fieldInfo);
          fieldInfo.parent = info;
        }
      }
    });

    lib.classes.forEach((ir.Class clazz) {
      final classEntity = environment.lookupClass(libEntity, clazz.name);
      if (classEntity == null) return;

      final classTypeInfo = visitClassType(clazz);
      if (classTypeInfo != null) {
        info.classTypes.add(classTypeInfo);
        classTypeInfo.parent = info;
      }

      final classInfo = visitClass(clazz, classEntity: classEntity);
      if (classInfo != null) {
        info.classes.add(classInfo);
        classInfo.parent = info;
      }
    });

    state.info.libraries.add(info);
    return info;
  }

  FieldInfo? visitField(ir.Field field, {required FieldEntity fieldEntity}) {
    FieldInfo info = FieldInfo.fromKernel(
      name: field.name.text,
      type: field.type.toStringInternal(),
      isConst: field.isConst,
    );

    if (compiler.options.experimentCallInstrumentation) {
      // We use field.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${field.hashCode}';
    }

    _addClosureInfo(info, field,
        libraryEntity: fieldEntity.library, memberEntity: fieldEntity);

    state.info.fields.add(info);
    return info;
  }

  ClassTypeInfo? visitClassType(ir.Class clazz) {
    ClassTypeInfo classTypeInfo = ClassTypeInfo(name: clazz.name);
    state.info.classTypes.add(classTypeInfo);
    return classTypeInfo;
  }

  ClassInfo? visitClass(ir.Class clazz, {required ClassEntity classEntity}) {
    if (state.entityToInfo[classEntity] != null)
      return state.entityToInfo[classEntity] as ClassInfo?;

    final supers = <ClassInfo>[];
    clazz.supers.forEach((supertype) {
      final superclass = supertype.classNode;
      // Ignore 'Object' to reduce overhead.
      if (superclass == coreTypes.objectClass) {
        return;
      }
      final superclassLibrary =
          environment.lookupLibrary(superclass.enclosingLibrary.importUri)!;
      final superclassEntity =
          environment.lookupClass(superclassLibrary, superclass.name);
      if (superclassEntity == null) return;
      final classInfo = visitClass(superclass, classEntity: superclassEntity);
      if (classInfo != null) supers.add(classInfo);
    });

    ClassInfo classInfo = ClassInfo.fromKernel(
        name: clazz.name, isAbstract: clazz.isAbstract, supers: supers);
    state.entityToInfo[classEntity] = classInfo;

    clazz.members.forEach((ir.Member member) {
      final isSetter = member is ir.Procedure && member.isSetter;
      // clazz.members includes constructors
      final name = Name(member.name.text,
          member.name.isPrivate ? member.name.library!.importUri : null,
          isSetter: isSetter);
      final memberEntity =
          environment.lookupLocalClassMember(classEntity, name) ??
              environment.lookupConstructor(classEntity, member.name.text);
      if (memberEntity == null) return;

      final function = member.function;
      if (function != null) {
        // Multiple kernel members can map to single JWorld member
        // (e.g., when one of a getter/field pair are tree-shaken),
        // so avoid duplicating the downstream info object.
        if (memberEntity is FunctionEntity) {
          final functionInfo =
              visitFunction(function, functionEntity: memberEntity);
          if (functionInfo != null) {
            classInfo.functions.add(functionInfo);
            functionInfo.parent = classInfo;
          }
        }
      } else {
        final fieldInfo = visitField(member as ir.Field,
            fieldEntity: memberEntity as FieldEntity);
        if (fieldInfo != null) {
          classInfo.fields.add(fieldInfo);
          fieldInfo.parent = classInfo;
        }
      }
    });

    state.info.classes.add(classInfo);
    return classInfo;
  }

  FunctionInfo? visitFunction(ir.FunctionNode function,
      {required FunctionEntity functionEntity,
      LocalFunctionInfo? localFunctionInfo}) {
    final parent = function.parent;
    bool isClosureCallMethod = parent is ir.LocalFunction;
    String name = isClosureCallMethod ? 'call' : parent!.toStringInternal();
    bool isConstructor = parent is ir.Constructor;
    bool isFactory = parent is ir.Procedure && parent.isFactory;
    // Kernel `isStatic` refers to static members, constructors, and top-level
    // members.
    bool isTopLevel = (parent is ir.Field && parent.isStatic) ||
        (parent is ir.Procedure && parent.isStatic) ||
        (parent is ir.Member && parent.enclosingClass == null);
    bool isStaticMember = ((parent is ir.Field && parent.isStatic) ||
            (parent is ir.Procedure && parent.isStatic)) &&
        (parent is ir.Member && parent.enclosingClass != null) &&
        !isConstructor &&
        !isFactory;
    bool isConst = parent is ir.Member && parent.isConst;
    bool isExternal = parent is ir.Member && parent.isExternal;
    bool isMethod = isClosureCallMethod ||
        (parent is ir.Member && parent.enclosingClass != null);
    bool isGetter = parent is ir.Procedure && parent.isGetter;
    bool isSetter = parent is ir.Procedure && parent.isSetter;
    late int kind;
    if (isStaticMember || isTopLevel) {
      kind = FunctionInfo.TOP_LEVEL_FUNCTION_KIND;
    } else if (isMethod) {
      kind = FunctionInfo.METHOD_FUNCTION_KIND;
    }
    if (isConstructor || isFactory) {
      kind = FunctionInfo.CONSTRUCTOR_FUNCTION_KIND;
      String functionName = function.toStringInternal();
      name = functionName.isEmpty ? '$name' : '$name$functionName';
    } else {
      if (parent!.parent is ir.Class && name.contains('.')) {
        name = name.split('.')[1];
      }
    }
    if (name.endsWith('.')) name = name.substring(0, name.length - 1);

    FunctionModifiers modifiers = FunctionModifiers(
      isStatic: isStaticMember,
      isConst: isConst,
      isFactory: isFactory,
      isExternal: isExternal,
      isGetter: isGetter,
      isSetter: isSetter,
    );

    // TODO(markzipan): Determine if it's safe to default to nonNullable here.
    final nullability = parent is ir.Member
        ? parent.enclosingLibrary.nonNullable
        : ir.Nullability.nonNullable;
    final functionType = function.computeFunctionType(nullability);

    FunctionInfo info = FunctionInfo.fromKernel(
        name: name,
        functionKind: kind,
        modifiers: modifiers,
        returnType: function.returnType.toStringInternal(),
        type: functionType.toStringInternal());

    final functionParent = function.parent;
    if (functionParent is ir.Member)
      _addClosureInfo(info, functionParent,
          libraryEntity: functionEntity.library, memberEntity: functionEntity);
    else {
      // This branch is only reached when function is a 'call' method.
      // TODO(markzipan): Ensure call methods never have children.
      info.closures = [];
    }

    if (compiler.options.experimentCallInstrumentation) {
      // We use function.hashCode because it is globally unique and it is
      // available while we are doing codegen.
      info.coverageId = '${function.hashCode}';
    }

    state.info.functions.add(info);
    return info;
  }

  /// Adds closure information to [info], using all nested closures in [member].
  void _addClosureInfo(Info info, ir.Member member,
      {required LibraryEntity libraryEntity,
      required MemberEntity memberEntity}) {
    final localFunctionInfoCollector = LocalFunctionInfoCollector();
    member.accept(localFunctionInfoCollector);
    List<ClosureInfo> nestedClosures = <ClosureInfo>[];
    localFunctionInfoCollector.localFunctions.forEach((key, value) {
      late FunctionEntity closureEntity;
      int closureOrder = value.order;
      environment.forEachNestedClosure(memberEntity, (closure) {
        if (closure.enclosingClass!.name == value.name &&
            (closureOrder-- == 0)) {
          closureEntity = closure;
        }
      });
      final closureClassEntity = closureEntity.enclosingClass!;
      final closureInfo = ClosureInfo.fromKernel(name: value.disambiguatedName);

      final callMethod = closedWorld.elementEnvironment
          .lookupClassMember(closureClassEntity, Names.call);
      final functionInfo = visitFunction(key.function,
          functionEntity: callMethod as FunctionEntity,
          localFunctionInfo: value);

      closureInfo.function = functionInfo!;
      functionInfo.parent = closureInfo;
      state.info.closures.add(closureInfo);

      closureInfo.parent = info;
      nestedClosures.add(closureInfo);
    });
    if (info is FunctionInfo) info.closures = nestedClosures;
    if (info is FieldInfo) info.closures = nestedClosures;
  }
}

/// Maps JWorld Entity objects to disambiguated names in order to map them
/// to/from Kernel.
///
/// This is primarily used for naming closure objects, which rely on Entity
/// object identity to determine uniqueness.
///
/// Note: this relies on the Kernel traversal order to determine order, which
/// may change in the future.
class EntityDisambiguator {
  final nameFrequencies = <String, int>{};
  final entityNames = <Entity, String>{};

  String name(Entity entity) {
    final disambiguatedName = entityNames[entity];
    if (disambiguatedName != null) {
      return disambiguatedName;
    }
    final entityName = entity.name!;
    nameFrequencies[entityName] = (nameFrequencies[entityName] ?? -1) + 1;
    final order = nameFrequencies[entityName]!;
    entityNames[entity] =
        order == 0 ? entityName : '${entityName}%${order - 1}';

    return entityNames[entity]!;
  }
}

/// Annotates [KernelInfoCollector] with info extracted from closed-world
/// analysis.
class DumpInfoAnnotator {
  final KernelInfoCollector kernelInfo;
  final Compiler compiler;
  final JClosedWorld closedWorld;
  final GlobalTypeInferenceResults _globalInferenceResults;
  final DumpInfoTask dumpInfoTask;
  final entityDisambiguator = EntityDisambiguator();

  JElementEnvironment get environment => closedWorld.elementEnvironment;

  DumpInfoAnnotator(this.kernelInfo, this.compiler, this.dumpInfoTask,
      this.closedWorld, this._globalInferenceResults);

  void run() {
    dumpInfoTask._constantToNode.forEach((constant, node) {
      // TODO(sigmund): add dependencies on other constants
      var span = dumpInfoTask._nodeData[node]!;
      var info = ConstantInfo(
          size: span.end! - span.start!,
          code: [span],
          outputUnit: _unitInfoForConstant(constant));
      kernelInfo.state.constantToInfo[constant] = info;
      info.treeShakenStatus = TreeShakenStatus.Live;
      kernelInfo.state.info.constants.add(info);
    });
    environment.libraries.forEach(visitLibrary);
  }

  /// Whether to emit information about [entity].
  ///
  /// By default we emit information for any entity that contributes to the
  /// output size. Either because it is a function being emitted or inlined,
  /// or because it is an entity that holds dependencies to other entities.
  bool shouldKeep(Entity entity) {
    return dumpInfoTask.impacts.containsKey(entity) ||
        dumpInfoTask.inlineCount.containsKey(entity);
  }

  LibraryInfo? visitLibrary(LibraryEntity lib) {
    var kLibraryInfos = kernelInfo.state.info.libraries
        .where((i) => '${i.uri}' == '${lib.canonicalUri}');
    assert(
        kLibraryInfos.length == 1,
        'Ambiguous library resolution. '
        'Expected singleton, found $kLibraryInfos');
    var kLibraryInfo = kLibraryInfos.first;
    kernelInfo.state.entityToInfo[lib] = kLibraryInfo;

    String libname = environment.getLibraryName(lib);
    if (libname.isEmpty) {
      libname = '${lib.canonicalUri}';
    }
    assert(kLibraryInfo.name == libname);
    kLibraryInfo.size = dumpInfoTask.sizeOf(lib);

    environment.forEachLibraryMember(lib, (MemberEntity member) {
      if (member.isFunction || member.isGetter || member.isSetter) {
        visitFunction(member as FunctionEntity, libname);
      } else if (member is FieldEntity) {
        visitField(member, libname);
      } else {
        throw StateError('Class member not a function or field');
      }
    });

    environment.forEachClass(lib, (ClassEntity clazz) {
      visitClassType(clazz, libname);
      visitClass(clazz, libname);
    });

    bool hasLiveFields = [
      ...kLibraryInfo.topLevelFunctions,
      ...kLibraryInfo.topLevelVariables,
      ...kLibraryInfo.classes,
      ...kLibraryInfo.classTypes
    ].any((i) => i.treeShakenStatus == TreeShakenStatus.Live);
    if (!hasLiveFields && !shouldKeep(lib)) return null;
    kLibraryInfo.treeShakenStatus = TreeShakenStatus.Live;
    return kLibraryInfo;
  }

  GlobalTypeInferenceMemberResult _resultOfMember(MemberEntity e) =>
      _globalInferenceResults.resultOfMember(e);

  AbstractValue _resultOfParameter(Local e) =>
      _globalInferenceResults.resultOfParameter(e);

  // TODO(markzipan): [parentName] is used for disambiguation, but this might
  // not always be valid. Check and validate later.
  FieldInfo? visitField(FieldEntity field, String parentName) {
    final inferredType = _resultOfMember(field).type;
    // If a field has an empty inferred type it is never used.
    if (closedWorld.abstractValueDomain
        .isEmpty(inferredType)
        .isDefinitelyTrue) {
      return null;
    }

    final kFieldInfos = kernelInfo.state.info.fields
        .where((f) =>
            f.name == field.name &&
            fullyResolvedNameForInfo(f.parent) == parentName)
        .toList();
    assert(
        kFieldInfos.length == 1,
        'Ambiguous field resolution. '
        'Expected singleton, found $kFieldInfos');
    final kFieldInfo = kFieldInfos.first;
    kernelInfo.state.entityToInfo[field] = kFieldInfo;

    int size = dumpInfoTask.sizeOf(field);
    List<CodeSpan> code = dumpInfoTask.codeOf(field);

    // TODO(het): Why doesn't `size` account for the code size already?
    size += code.length;

    kFieldInfo.outputUnit = _unitInfoForMember(field);
    kFieldInfo.inferredType = '$inferredType';
    kFieldInfo.code = code;
    kFieldInfo.treeShakenStatus = TreeShakenStatus.Live;

    FieldAnalysisData fieldData =
        closedWorld.fieldAnalysis.getFieldData(field as JField);
    if (fieldData.initialValue != null) {
      kFieldInfo.initializer = kernelInfo
          .state.constantToInfo[fieldData.initialValue] as ConstantInfo?;
    }

    int closureSize = _addClosureInfo(kFieldInfo, field);
    kFieldInfo.size = size + closureSize;
    return kFieldInfo;
  }

  // TODO(markzipan): [parentName] is used for disambiguation, but this might
  // not always be valid. Check and validate later.
  ClassTypeInfo? visitClassType(ClassEntity clazz, String parentName) {
    var kClassTypeInfos = kernelInfo.state.info.classTypes
        .where((i) => i.name == clazz.name && i.parent!.name == parentName);
    assert(
        kClassTypeInfos.length == 1,
        'Ambiguous class type resolution. '
        'Expected singleton, found $kClassTypeInfos');
    var kClassTypeInfo = kClassTypeInfos.first;

    // TODO(joshualitt): Get accurate size information for class types.
    kClassTypeInfo.size = 0;

    // Omit class type if it is not needed.
    bool isNeeded =
        compiler.backendStrategy.emitterTask.neededClassTypes.contains(clazz);
    if (!isNeeded) return null;

    assert(kClassTypeInfo.name == clazz.name);
    kClassTypeInfo.outputUnit = _unitInfoForClassType(clazz);
    kClassTypeInfo.treeShakenStatus = TreeShakenStatus.Live;
    return kClassTypeInfo;
  }

  // TODO(markzipan): [parentName] is used for disambiguation, but this might
  // not always be valid. Check and validate later.
  ClassInfo? visitClass(ClassEntity clazz, String parentName) {
    final kClassInfos = kernelInfo.state.info.classes
        .where((i) =>
            i.name == clazz.name &&
            fullyResolvedNameForInfo(i.parent) == parentName)
        .toList();
    assert(
        kClassInfos.length == 1,
        'Ambiguous class resolution. '
        'Expected singleton, found $kClassInfos');
    final kClassInfo = kClassInfos.first;
    kernelInfo.state.entityToInfo[clazz] = kClassInfo;

    /// Add synthetically injected superclasses like `Interceptor` and
    /// `LegacyJavaScriptObject`.
    final syntheticSuperclass = closedWorld.commonElements
        .getDefaultSuperclass(clazz, closedWorld.nativeData);
    if (syntheticSuperclass != closedWorld.commonElements.objectClass) {
      final classInfo = kernelInfo.state.entityToInfo[syntheticSuperclass];
      if (classInfo != null) {
        kClassInfo.supers.add(classInfo as ClassInfo);
      }
    }

    int size = dumpInfoTask.sizeOf(clazz);
    final disambiguatedMemberName = '$parentName/${clazz.name}';
    environment.forEachLocalClassMember(clazz, (member) {
      // Skip certain incongruent locals that during method alias installation.
      if (member is JMethod && member.enclosingClass!.name != clazz.name) {
        return;
      }
      if (member.isFunction || member.isGetter || member.isSetter) {
        final functionInfo =
            visitFunction(member as FunctionEntity, disambiguatedMemberName);
        if (functionInfo != null) {
          for (var closureInfo in functionInfo.closures) {
            size += closureInfo.size;
          }
        }
      } else if (member is FieldEntity) {
        final fieldInfo = visitField(member, disambiguatedMemberName);
        if (fieldInfo != null) {
          for (var closureInfo in fieldInfo.closures) {
            size += closureInfo.size;
          }
        }
      } else {
        throw StateError('Class member not a function or field');
      }
    });
    environment.forEachConstructor(clazz, (constructor) {
      final functionInfo = visitFunction(constructor, disambiguatedMemberName);
      if (functionInfo != null) {
        for (var closureInfo in functionInfo.closures) {
          size += closureInfo.size;
        }
      }
    });
    kClassInfo.size = size;

    bool hasLiveFields = [...kClassInfo.fields, ...kClassInfo.functions]
        .any((i) => i.treeShakenStatus == TreeShakenStatus.Live);
    if (!compiler.backendStrategy.emitterTask.neededClasses.contains(clazz) &&
        !hasLiveFields) {
      return null;
    }

    kClassInfo.outputUnit = _unitInfoForClass(clazz);
    kClassInfo.treeShakenStatus = TreeShakenStatus.Live;
    return kClassInfo;
  }

  ClosureInfo? visitClosureClass(ClassEntity element) {
    final disambiguatedElementName = entityDisambiguator.name(element);
    final kClosureInfos = kernelInfo.state.info.closures
        .where((info) => info.name == disambiguatedElementName)
        .toList();
    assert(
        kClosureInfos.length == 1,
        'Ambiguous closure resolution. '
        'Expected singleton, found $kClosureInfos');
    final kClosureInfo = kClosureInfos.first;
    kernelInfo.state.entityToInfo[element] = kClosureInfo;

    kClosureInfo.outputUnit = _unitInfoForClass(element);
    kClosureInfo.size = dumpInfoTask.sizeOf(element);

    final callMethod =
        closedWorld.elementEnvironment.lookupClassMember(element, Names.call);

    final functionInfo = visitFunction(
        callMethod as FunctionEntity, disambiguatedElementName,
        isClosure: true);
    if (functionInfo == null) return null;

    kClosureInfo.treeShakenStatus = TreeShakenStatus.Live;
    return kClosureInfo;
  }

  // TODO(markzipan): [parentName] is used for disambiguation, but this might
  // not always be valid. Check and validate later.
  FunctionInfo? visitFunction(FunctionEntity function, String parentName,
      {bool isClosure = false}) {
    int size = dumpInfoTask.sizeOf(function);
    if (size == 0 && !shouldKeep(function)) return null;

    var compareName = function.name;
    if (function is ConstructorEntity) {
      compareName = compareName == ""
          ? "${function.enclosingClass.name}"
          : "${function.enclosingClass.name}.${function.name}";
    }

    // Multiple kernel members can sometimes map to a single JElement.
    // [isSetter] and [isGetter] are required for disambiguating these cases.
    final kFunctionInfos = kernelInfo.state.info.functions
        .where((i) =>
            i.name == compareName &&
            (isClosure ? i.parent!.name : fullyResolvedNameForInfo(i.parent)) ==
                parentName &&
            !(function.isGetter ^ i.modifiers.isGetter) &&
            !(function.isSetter ^ i.modifiers.isSetter))
        .toList();
    assert(
        kFunctionInfos.length <= 1,
        'Ambiguous function resolution. '
        'Expected single or none, found $kFunctionInfos');
    if (kFunctionInfos.length == 0) return null;
    final kFunctionInfo = kFunctionInfos.first;
    kernelInfo.state.entityToInfo[function] = kFunctionInfo;

    List<CodeSpan> code = dumpInfoTask.codeOf(function);
    List<ParameterInfo> parameters = <ParameterInfo>[];
    List<String> inferredParameterTypes = <String>[];

    closedWorld.elementEnvironment.forEachParameterAsLocal(
        _globalInferenceResults.globalLocalsMap, function, (parameter) {
      inferredParameterTypes.add('${_resultOfParameter(parameter)}');
    });
    int parameterIndex = 0;
    closedWorld.elementEnvironment.forEachParameter(function, (type, name, _) {
      // Synthesized parameters have no name. This can happen on parameters of
      // setters derived from lowering late fields.
      parameters.add(ParameterInfo(name ?? '#t${parameterIndex}',
          inferredParameterTypes[parameterIndex++], '$type'));
    });

    String inferredReturnType = '${_resultOfMember(function).returnType}';
    String sideEffects =
        '${_globalInferenceResults.inferredData.getSideEffectsOfElement(function)}';
    int inlinedCount = dumpInfoTask.inlineCount[function] ?? 0;

    kFunctionInfo.inferredReturnType = inferredReturnType;
    kFunctionInfo.sideEffects = sideEffects;
    kFunctionInfo.inlinedCount = inlinedCount;
    kFunctionInfo.code = code;
    kFunctionInfo.parameters = parameters;
    kFunctionInfo.outputUnit = _unitInfoForMember(function);

    int closureSize = _addClosureInfo(kFunctionInfo, function);
    kFunctionInfo.size = size + closureSize;

    kFunctionInfo.treeShakenStatus = TreeShakenStatus.Live;
    return kFunctionInfo;
  }

  /// Adds closure information to [info], using all nested closures in [member].
  ///
  /// Returns the total size of the nested closures, to add to the info size.
  int _addClosureInfo(BasicInfo info, MemberEntity member) {
    assert(info is FunctionInfo || info is FieldInfo);
    int size = 0;
    environment.forEachNestedClosure(member, (closure) {
      final closureInfo = visitClosureClass(closure.enclosingClass!);
      if (closureInfo != null) {
        closureInfo.treeShakenStatus = TreeShakenStatus.Live;
        size += closureInfo.size;
      }
    });
    return size;
  }

  OutputUnitInfo _infoFromOutputUnit(OutputUnit outputUnit) {
    return kernelInfo.state.outputToInfo.putIfAbsent(outputUnit, () {
      // Dump-info currently only works with the full emitter. If another
      // emitter is used it will fail here.
      JsBackendStrategy backendStrategy = compiler.backendStrategy;
      final filename = outputUnit.isMainOutput
          ? (compiler.options.outputUri?.pathSegments.last ?? 'out')
          : deferredPartFileName(compiler.options, outputUnit.name);
      OutputUnitInfo info = OutputUnitInfo(filename, outputUnit.name,
          backendStrategy.emitterTask.emitter.generatedSize(outputUnit));
      info.treeShakenStatus = TreeShakenStatus.Live;
      info.imports
          .addAll(closedWorld.outputUnitData.getImportNames(outputUnit));
      kernelInfo.state.info.outputUnits.add(info);
      return info;
    });
  }

  OutputUnitInfo _unitInfoForMember(MemberEntity entity) {
    return _infoFromOutputUnit(
        closedWorld.outputUnitData.outputUnitForMember(entity));
  }

  OutputUnitInfo _unitInfoForClass(ClassEntity entity) {
    return _infoFromOutputUnit(
        closedWorld.outputUnitData.outputUnitForClass(entity, allowNull: true));
  }

  OutputUnitInfo _unitInfoForClassType(ClassEntity entity) {
    return _infoFromOutputUnit(closedWorld.outputUnitData
        .outputUnitForClassType(entity, allowNull: true));
  }

  OutputUnitInfo _unitInfoForConstant(ConstantValue constant) {
    OutputUnit outputUnit =
        closedWorld.outputUnitData.outputUnitForConstant(constant);
    return _infoFromOutputUnit(outputUnit);
  }
}

class Selection {
  final Entity selectedEntity;
  final Object? receiverConstraint;
  Selection(this.selectedEntity, this.receiverConstraint);
}

/// Interface used to record information from different parts of the compiler so
/// we can emit them in the dump-info task.
// TODO(sigmund,het): move more features here. Ideally the dump-info task
// shouldn't reach into internals of other parts of the compiler. For example,
// we currently reach into the full emitter and as a result we don't support
// dump-info when using the startup-emitter (issue #24190).
abstract class InfoReporter {
  void reportInlined(FunctionEntity element, MemberEntity inlinedFrom);
}

class DumpInfoTask extends CompilerTask implements InfoReporter {
  final Compiler compiler;
  final bool useBinaryFormat;

  DumpInfoTask(this.compiler)
      : useBinaryFormat = compiler.options.useDumpInfoBinaryFormat,
        super(compiler.measurer);

  @override
  String get name => "Dump Info";

  /// The size of the generated output.
  late int _programSize;

  /// Data associated with javascript AST nodes. The map only contains keys for
  /// nodes that we care about.  Keys are automatically added when
  /// [registerEntityAst] is called.
  final Map<jsAst.Node, CodeSpan> _nodeData = <jsAst.Node, CodeSpan>{};

  // A mapping from Dart Entities to JavaScript AST Nodes.
  final Map<Entity, List<jsAst.Node>> _entityToNodes =
      <Entity, List<jsAst.Node>>{};
  final Map<ConstantValue, jsAst.Node> _constantToNode =
      <ConstantValue, jsAst.Node>{};

  final Map<Entity, int> inlineCount = <Entity, int>{};

  // A mapping from an entity to a list of entities that are
  // inlined inside of it.
  final Map<Entity, List<Entity>> inlineMap = <Entity, List<Entity>>{};

  final Map<MemberEntity, WorldImpact> impacts = <MemberEntity, WorldImpact>{};

  /// Register the size of the generated output.
  void reportSize(int programSize) {
    _programSize = programSize;
  }

  @override
  void reportInlined(FunctionEntity element, MemberEntity inlinedFrom) {
    inlineCount.update(element, (i) => i + 1, ifAbsent: () => 1);
    inlineMap.putIfAbsent(inlinedFrom, () => <Entity>[]);
    inlineMap[inlinedFrom]!.add(element);
  }

  void registerImpact(MemberEntity member, WorldImpact impact) {
    if (compiler.options.dumpInfo) {
      impacts[member] = impact;
    }
  }

  void unregisterImpact(var impactSource) {
    impacts.remove(impactSource);
  }

  /// Returns an iterable of [Selection]s that are used by [entity]. Each
  /// [Selection] contains an entity that is used and the selector that
  /// selected the entity.
  Iterable<Selection> getRetaining(Entity entity, JClosedWorld closedWorld) {
    final impact = impacts[entity];
    if (impact == null) return const <Selection>[];

    var selections = <Selection>[];
    impact.forEachDynamicUse((_, dynamicUse) {
      final mask = dynamicUse.receiverConstraint as AbstractValue?;
      selections.addAll(closedWorld
          // TODO(het): Handle `call` on `Closure` through
          // `world.includesClosureCall`.
          .locateMembers(dynamicUse.selector, mask)
          .map((MemberEntity e) => Selection(e, mask)));
    });
    impact.forEachStaticUse((_, staticUse) {
      selections.add(Selection(staticUse.element, null));
    });
    unregisterImpact(entity);
    return selections;
  }

  /// Registers that a javascript AST node [code] was produced by the dart
  /// Entity [entity].
  void registerEntityAst(Entity? entity, jsAst.Node code) {
    if (compiler.options.dumpInfo) {
      if (entity != null) {
        _entityToNodes.putIfAbsent(entity, () => <jsAst.Node>[]).add(code);
      }
      _nodeData[code] ??= useBinaryFormat ? CodeSpan() : _CodeData();
    }
  }

  void registerConstantAst(ConstantValue constant, jsAst.Node code) {
    if (compiler.options.dumpInfo) {
      assert(_constantToNode[constant] == null ||
          _constantToNode[constant] == code);
      _constantToNode[constant] = code;
      _nodeData[code] ??= useBinaryFormat ? CodeSpan() : _CodeData();
    }
  }

  bool get shouldEmitText => !useBinaryFormat;
  // TODO(sigmund): delete the stack once we stop emitting the source text.
  final List<_CodeData> _stack = [];
  void enterNode(jsAst.Node node, int start) {
    var data = _nodeData[node];
    data?.start = start;

    if (shouldEmitText && data != null) {
      _stack.add(data as _CodeData);
    }
  }

  void emit(String string) {
    if (shouldEmitText) {
      // Note: historically we emitted the full body of classes and methods, so
      // instance methods ended up emitted twice.  Once we use a different
      // encoding of dump info, we also plan to remove this duplication.
      _stack.forEach((f) => f._text.write(string));
    }
  }

  void exitNode(jsAst.Node node, int start, int end, int? closing) {
    var data = _nodeData[node];
    data?.end = end;
    if (shouldEmitText && data != null) {
      var last = _stack.removeLast();
      assert(data == last);
      assert(data.start == start);
    }
  }

  /// Returns the size of the source code that was generated for an entity.
  /// If no source code was produced, return 0.
  int sizeOf(Entity entity) {
    if (_entityToNodes.containsKey(entity)) {
      return _entityToNodes[entity]!.map(sizeOfNode).fold(0, (a, b) => a + b);
    } else {
      return 0;
    }
  }

  int sizeOfNode(jsAst.Node node) {
    final span = _nodeData[node];
    if (span == null) return 0;
    return span.end! - span.start!;
  }

  List<CodeSpan> codeOf(MemberEntity entity) {
    final code = _entityToNodes[entity];
    if (code == null) return const [];
    return code.map((ast) => _nodeData[ast]!).toList();
  }

  Future<DumpInfoStateData> dumpInfo(JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) async {
    late DumpInfoStateData dumpInfoState;
    await measure(() async {
      ElementInfoCollector elementInfoCollector = ElementInfoCollector(
          compiler, this, closedWorld, globalInferenceResults)
        ..run();

      dumpInfoState =
          await buildDumpInfoData(closedWorld, elementInfoCollector);
      if (useBinaryFormat) {
        dumpInfoBinary(dumpInfoState.info);
      } else {
        dumpInfoJson(dumpInfoState.info);
      }
      return;
    });
    return dumpInfoState;
  }

  Future<DumpInfoStateData> dumpInfoNew(
      ir.Component component,
      JClosedWorld closedWorld,
      GlobalTypeInferenceResults globalInferenceResults) async {
    late DumpInfoStateData dumpInfoState;
    await measure(() async {
      KernelInfoCollector kernelInfoCollector =
          KernelInfoCollector(component, compiler, this, closedWorld)..run();

      DumpInfoAnnotator(kernelInfoCollector, compiler, this, closedWorld,
          globalInferenceResults)
        ..run();

      dumpInfoState =
          await buildDumpInfoDataNew(closedWorld, kernelInfoCollector);
      TreeShakingInfoVisitor().filter(dumpInfoState.info);

      if (useBinaryFormat) {
        dumpInfoBinary(dumpInfoState.info);
      } else {
        dumpInfoJson(dumpInfoState.info);
      }
    });
    return dumpInfoState;
  }

  void dumpInfoJson(AllInfo data) {
    StringBuffer jsonBuffer = StringBuffer();
    JsonEncoder encoder = const JsonEncoder.withIndent('  ');
    final sink = encoder.startChunkedConversion(
        StringConversionSink.fromStringSink(jsonBuffer));
    sink.add(AllInfoJsonCodec(isBackwardCompatible: true).encode(data));
    final name = (compiler.options.outputUri?.pathSegments.last ?? 'out');
    compiler.outputProvider
        .createOutputSink(name, 'info.json', api.OutputType.dumpInfo)
      ..add(jsonBuffer.toString())
      ..close();
    compiler.reporter
        .reportInfoMessage(NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {
      'text': "View the dumped .info.json file at "
          "https://dart-lang.github.io/dump-info-visualizer"
    });
  }

  void dumpInfoBinary(AllInfo data) {
    final name =
        (compiler.options.outputUri?.pathSegments.last ?? 'out') + ".info.data";
    Sink<List<int>> sink = BinaryOutputSinkAdapter(compiler.outputProvider
        .createBinarySink(compiler.options.outputUri!.resolve(name)));
    dump_info.encode(data, sink);
    compiler.reporter
        .reportInfoMessage(NO_LOCATION_SPANNABLE, MessageKind.GENERIC, {
      'text': "Use `package:dart2js_info` to parse and process the dumped "
          ".info.data file."
    });
  }

  Future<DumpInfoStateData> buildDumpInfoData(
      JClosedWorld closedWorld, ElementInfoCollector infoCollector) async {
    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    DumpInfoStateData result = infoCollector.state;

    // Recursively build links to function uses
    final functionEntities =
        infoCollector.state.entityToInfo.keys.where((k) => k is FunctionEntity);
    for (final entity in functionEntities) {
      final info = infoCollector.state.entityToInfo[entity] as FunctionInfo;
      Iterable<Selection> uses = getRetaining(entity, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        // Don't register dart2js builtin functions that are not recorded.
        final useInfo =
            infoCollector.state.entityToInfo[selection.selectedEntity];
        if (useInfo == null) continue;
        info.uses.add(
            DependencyInfo(useInfo, selection.receiverConstraint?.toString()));
      }
    }

    // Recursively build links to field uses
    Iterable<Entity> fieldEntity =
        infoCollector.state.entityToInfo.keys.where((k) => k is FieldEntity);
    for (final entity in fieldEntity) {
      final info = infoCollector.state.entityToInfo[entity] as FieldInfo;
      Iterable<Selection> uses = getRetaining(entity, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        final useInfo =
            infoCollector.state.entityToInfo[selection.selectedEntity];
        if (useInfo == null) continue;
        info.uses.add(
            DependencyInfo(useInfo, selection.receiverConstraint?.toString()));
      }
    }

    // Track dependencies that come from inlining.
    for (Entity entity in inlineMap.keys) {
      final outerInfo = infoCollector.state.entityToInfo[entity] as CodeInfo?;
      if (outerInfo == null) continue;
      for (final inlined in inlineMap[entity]!) {
        final inlinedInfo = infoCollector.state.entityToInfo[inlined];
        if (inlinedInfo == null) continue;
        outerInfo.uses.add(DependencyInfo(inlinedInfo, 'inlined'));
      }
    }

    var fragmentsToLoad =
        compiler.backendStrategy.emitterTask.emitter.finalizedFragmentsToLoad;
    var fragmentMerger =
        compiler.backendStrategy.emitterTask.emitter.fragmentMerger;
    result.info.deferredFiles =
        fragmentMerger.computeDeferredMap(fragmentsToLoad);
    stopwatch.stop();

    result.info.program = ProgramInfo(
        entrypoint: infoCollector
                .state.entityToInfo[closedWorld.elementEnvironment.mainFunction]
            as FunctionInfo,
        size: _programSize,
        ramUsage: await currentHeapCapacityInMb(),
        dart2jsVersion:
            compiler.options.hasBuildId ? compiler.options.buildId : null,
        compilationMoment: DateTime.now(),
        compilationDuration: compiler.measurer.elapsedWallClock,
        toJsonDuration: Duration(milliseconds: stopwatch.elapsedMilliseconds),
        dumpInfoDuration: Duration(milliseconds: this.timing),
        noSuchMethodEnabled: closedWorld.backendUsage.isNoSuchMethodUsed,
        isRuntimeTypeUsed: closedWorld.backendUsage.isRuntimeTypeUsed,
        isIsolateInUse: false,
        isFunctionApplyUsed: closedWorld.backendUsage.isFunctionApplyUsed,
        minified: compiler.options.enableMinification);

    return result;
  }

  Future<DumpInfoStateData> buildDumpInfoDataNew(
      JClosedWorld closedWorld, KernelInfoCollector infoCollector) async {
    Stopwatch stopwatch = Stopwatch();
    stopwatch.start();

    DumpInfoStateData result = infoCollector.state;

    // Recursively build links to function uses
    Iterable<Entity> functionEntities =
        infoCollector.state.entityToInfo.keys.where((k) => k is FunctionEntity);
    for (final entity in functionEntities) {
      final info = infoCollector.state.entityToInfo[entity] as FunctionInfo;
      Iterable<Selection> uses = getRetaining(entity, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        // Don't register dart2js builtin functions that are not recorded.
        final useInfo =
            infoCollector.state.entityToInfo[selection.selectedEntity];
        if (useInfo == null) continue;
        if (useInfo.treeShakenStatus != TreeShakenStatus.Live) continue;
        info.uses.add(
            DependencyInfo(useInfo, selection.receiverConstraint?.toString()));
      }
    }

    // Recursively build links to field uses
    Iterable<Entity> fieldEntity =
        infoCollector.state.entityToInfo.keys.where((k) => k is FieldEntity);
    for (final entity in fieldEntity) {
      final info = infoCollector.state.entityToInfo[entity] as FieldInfo;
      Iterable<Selection> uses = getRetaining(entity, closedWorld);
      // Don't bother recording an empty list of dependencies.
      for (Selection selection in uses) {
        final useInfo =
            infoCollector.state.entityToInfo[selection.selectedEntity];
        if (useInfo == null) continue;
        if (useInfo.treeShakenStatus != TreeShakenStatus.Live) continue;
        info.uses.add(
            DependencyInfo(useInfo, selection.receiverConstraint?.toString()));
      }
    }

    // Track dependencies that come from inlining.
    for (Entity entity in inlineMap.keys) {
      final outerInfo = infoCollector.state.entityToInfo[entity] as CodeInfo?;
      if (outerInfo == null) continue;
      for (final inlined in inlineMap[entity]!) {
        final inlinedInfo = infoCollector.state.entityToInfo[inlined];
        if (inlinedInfo == null) continue;
        if (inlinedInfo.treeShakenStatus != TreeShakenStatus.Live) continue;
        outerInfo.uses.add(DependencyInfo(inlinedInfo, 'inlined'));
      }
    }

    var fragmentsToLoad =
        compiler.backendStrategy.emitterTask.emitter.finalizedFragmentsToLoad;
    var fragmentMerger =
        compiler.backendStrategy.emitterTask.emitter.fragmentMerger;
    result.info.deferredFiles =
        fragmentMerger.computeDeferredMap(fragmentsToLoad);
    stopwatch.stop();

    result.info.program = ProgramInfo(
        entrypoint: infoCollector
                .state.entityToInfo[closedWorld.elementEnvironment.mainFunction]
            as FunctionInfo,
        size: _programSize,
        ramUsage: await currentHeapCapacityInMb(),
        dart2jsVersion:
            compiler.options.hasBuildId ? compiler.options.buildId : null,
        compilationMoment: DateTime.now(),
        compilationDuration: compiler.measurer.elapsedWallClock,
        toJsonDuration: Duration(milliseconds: stopwatch.elapsedMilliseconds),
        dumpInfoDuration: Duration(milliseconds: this.timing),
        noSuchMethodEnabled: closedWorld.backendUsage.isNoSuchMethodUsed,
        isRuntimeTypeUsed: closedWorld.backendUsage.isRuntimeTypeUsed,
        isIsolateInUse: false,
        isFunctionApplyUsed: closedWorld.backendUsage.isFunctionApplyUsed,
        minified: compiler.options.enableMinification);

    return result;
  }
}

/// Helper class to store what dump-info will show for a piece of code.
// TODO(sigmund): delete once we no longer emit text by default.
class _CodeData extends CodeSpan {
  final StringBuffer _text = StringBuffer();

  @override
  String get text => '$_text';
  int get length => end! - start!;
}

/// Holds dump-info's mutable state.
class DumpInfoStateData {
  final AllInfo info = AllInfo();
  final Map<Entity, Info> entityToInfo = <Entity, Info>{};
  final Map<ConstantValue, Info> constantToInfo = <ConstantValue, Info>{};
  final Map<OutputUnit, OutputUnitInfo> outputToInfo = {};

  DumpInfoStateData();
}

class LocalFunctionInfo {
  final ir.LocalFunction localFunction;
  final String name;
  final int order;
  bool isInvoked = false;

  LocalFunctionInfo(this.localFunction, this.name, this.order);

  get disambiguatedName => order == 0 ? name : '$name%${order - 1}';
}

class LocalFunctionInfoCollector extends ir.RecursiveVisitor<void> {
  final localFunctions = <ir.LocalFunction, LocalFunctionInfo>{};
  final localFunctionNameCount = <String, int>{};

  LocalFunctionInfo generateLocalFunctionInfo(ir.LocalFunction localFunction) {
    final name = _computeClosureName(localFunction);
    localFunctionNameCount[name] = (localFunctionNameCount[name] ?? -1) + 1;
    return LocalFunctionInfo(
        localFunction, name, localFunctionNameCount[name]!);
  }

  @override
  void visitFunctionExpression(ir.FunctionExpression node) {
    assert(localFunctions[node] == null);
    localFunctions[node] = generateLocalFunctionInfo(node);
    defaultExpression(node);
  }

  @override
  void visitFunctionDeclaration(ir.FunctionDeclaration node) {
    assert(localFunctions[node] == null);
    localFunctions[node] = generateLocalFunctionInfo(node);
    defaultStatement(node);
  }

  @override
  void visitLocalFunctionInvocation(ir.LocalFunctionInvocation node) {
    if (localFunctions[node.localFunction] == null)
      visitFunctionDeclaration(node.localFunction);
    localFunctions[node.localFunction]!.isInvoked = true;
  }
}

// Returns a non-unique name for the given closure element.
//
// Must be kept logically identical to js_model/element_map_impl.dart.
String _computeClosureName(ir.TreeNode treeNode) {
  String reconstructConstructorName(ir.Member node) {
    String className = node.enclosingClass!.name;
    return node.name.text == '' ? className : '$className\$${node.name.text}';
  }

  var parts = <String>[];
  // First anonymous is called 'closure', outer ones called '' to give a
  // compound name where increasing nesting level corresponds to extra
  // underscores.
  var anonymous = 'closure';
  ir.TreeNode? current = treeNode;
  while (current != null) {
    var node = current;
    if (node is ir.FunctionExpression) {
      parts.add(anonymous);
      anonymous = '';
    } else if (node is ir.FunctionDeclaration) {
      final name = node.variable.name;
      if (name != null && name != "") {
        parts.add(entity_utils.operatorNameToIdentifier(name)!);
      } else {
        parts.add(anonymous);
        anonymous = '';
      }
    } else if (node is ir.Class) {
      parts.add(node.name);
      break;
    } else if (node is ir.Procedure) {
      if (node.kind == ir.ProcedureKind.Factory) {
        parts.add(reconstructConstructorName(node));
      } else {
        parts.add(entity_utils.operatorNameToIdentifier(node.name.text)!);
      }
    } else if (node is ir.Constructor) {
      parts.add(reconstructConstructorName(node));
      break;
    } else if (node is ir.Field) {
      // Add the field name for closures in field initializers.
      String name = node.name.text;
      parts.add(name);
    }
    current = current.parent;
  }
  return parts.reversed.join('_');
}

/// Filters dead code from Dart2JS [Info] trees.
class TreeShakingInfoVisitor extends InfoVisitor<void> {
  List<T> filterDeadInfo<T extends Info>(List<T> infos) {
    return infos
        .where((info) => info.treeShakenStatus == TreeShakenStatus.Live)
        .toList();
  }

  void filter(AllInfo info) {
    info.program = info.program;
    info.libraries = filterDeadInfo<LibraryInfo>(info.libraries);
    info.functions = filterDeadInfo<FunctionInfo>(info.functions);
    info.typedefs = filterDeadInfo<TypedefInfo>(info.typedefs);
    info.typedefs = filterDeadInfo<TypedefInfo>(info.typedefs);
    info.classes = filterDeadInfo<ClassInfo>(info.classes);
    info.classTypes = filterDeadInfo<ClassTypeInfo>(info.classTypes);
    info.fields = filterDeadInfo<FieldInfo>(info.fields);
    info.constants = filterDeadInfo<ConstantInfo>(info.constants);
    info.closures = filterDeadInfo<ClosureInfo>(info.closures);
    info.outputUnits = filterDeadInfo<OutputUnitInfo>(info.outputUnits);
    info.deferredFiles = info.deferredFiles;
    // TODO(markzipan): 'dependencies' is always empty. Revisit this if/when
    // this holds meaningful information.
    info.dependencies = info.dependencies;
    info.accept(this);
  }

  @override
  visitAll(AllInfo info) {
    info.libraries = filterDeadInfo<LibraryInfo>(info.libraries);
    info.constants = filterDeadInfo<ConstantInfo>(info.constants);

    info.libraries.forEach(visitLibrary);
    info.constants.forEach(visitConstant);
  }

  @override
  visitProgram(ProgramInfo info) {}

  @override
  visitLibrary(LibraryInfo info) {
    info.topLevelFunctions =
        filterDeadInfo<FunctionInfo>(info.topLevelFunctions);
    info.topLevelVariables = filterDeadInfo<FieldInfo>(info.topLevelVariables);
    info.classes = filterDeadInfo<ClassInfo>(info.classes);
    info.classTypes = filterDeadInfo<ClassTypeInfo>(info.classTypes);
    info.typedefs = filterDeadInfo<TypedefInfo>(info.typedefs);

    info.topLevelFunctions.forEach(visitFunction);
    info.topLevelVariables.forEach(visitField);
    info.classes.forEach(visitClass);
    info.classTypes.forEach(visitClassType);
    info.typedefs.forEach(visitTypedef);
  }

  @override
  visitClass(ClassInfo info) {
    info.functions = filterDeadInfo<FunctionInfo>(info.functions);
    info.fields = filterDeadInfo<FieldInfo>(info.fields);
    info.supers = filterDeadInfo<ClassInfo>(info.supers);

    info.functions.forEach(visitFunction);
    info.fields.forEach(visitField);
    info.supers.forEach(visitClass);
  }

  @override
  visitClassType(ClassTypeInfo info) {}

  @override
  visitField(FieldInfo info) {
    info.closures = filterDeadInfo<ClosureInfo>(info.closures);

    info.closures.forEach(visitClosure);
  }

  @override
  visitConstant(ConstantInfo info) {}

  @override
  visitFunction(FunctionInfo info) {
    info.closures = filterDeadInfo<ClosureInfo>(info.closures);

    info.closures.forEach(visitClosure);
  }

  @override
  visitTypedef(TypedefInfo info) {}
  @override
  visitOutput(OutputUnitInfo info) {}
  @override
  visitClosure(ClosureInfo info) {
    visitFunction(info.function);
  }
}

/// Returns a fully resolved name for [info] for disambiguation.
String fullyResolvedNameForInfo(Info? info) {
  if (info == null) return '';
  var name = info.name;
  var currentInfo = info;
  while (currentInfo.parent != null) {
    currentInfo = currentInfo.parent!;
    name = '${currentInfo.name}/$name';
  }
  return name;
}
