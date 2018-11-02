// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../constants/constant_system.dart';
import '../deferred_load.dart';
import '../diagnostics/diagnostic_listener.dart';
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../environment.dart';
import '../js_emitter/sorter.dart';
import '../js_backend/annotations.dart';
import '../js_backend/allocator_analysis.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/constant_system_javascript.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types.dart';
import '../ordered_typeset.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../types/abstract_value_domain.dart';
import '../universe/class_hierarchy.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'locals.dart';

class JsClosedWorld extends ClosedWorldBase {
  static const String tag = 'closed-world';

  final JsKernelToElementMap elementMap;
  final RuntimeTypesNeed rtiNeed;
  AbstractValueDomain _abstractValueDomain;
  final JAllocatorAnalysis allocatorAnalysis;
  final AnnotationsData annotationsData;
  final GlobalLocalsMap globalLocalsMap;
  final ClosureData closureDataLookup;
  final OutputUnitData outputUnitData;
  Sorter _sorter;

  JsClosedWorld(this.elementMap,
      {ConstantSystem constantSystem,
      NativeData nativeData,
      InterceptorData interceptorData,
      BackendUsage backendUsage,
      this.rtiNeed,
      this.allocatorAnalysis,
      NoSuchMethodData noSuchMethodData,
      Set<ClassEntity> implementedClasses,
      Set<ClassEntity> liveNativeClasses,
      Set<MemberEntity> liveInstanceMembers,
      Set<MemberEntity> assignedInstanceMembers,
      Set<MemberEntity> processedMembers,
      Map<ClassEntity, Set<ClassEntity>> mixinUses,
      Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses,
      ClassHierarchy classHierarchy,
      AbstractValueStrategy abstractValueStrategy,
      this.annotationsData,
      this.globalLocalsMap,
      this.closureDataLookup,
      this.outputUnitData})
      : super(
            elementMap.elementEnvironment,
            elementMap.types,
            elementMap.commonElements,
            JavaScriptConstantSystem.only,
            nativeData,
            interceptorData,
            backendUsage,
            noSuchMethodData,
            implementedClasses,
            liveNativeClasses,
            liveInstanceMembers,
            assignedInstanceMembers,
            processedMembers,
            mixinUses,
            typesImplementedBySubclasses,
            classHierarchy) {
    _abstractValueDomain = abstractValueStrategy.createDomain(this);
  }

  /// Deserializes a [JsClosedWorld] object from [source].
  factory JsClosedWorld.readFromDataSource(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      DataSource source) {
    source.begin(tag);

    JsKernelToElementMap elementMap =
        new JsKernelToElementMap.readFromDataSource(
            options, reporter, environment, component, source);
    GlobalLocalsMap globalLocalsMap =
        new GlobalLocalsMap.readFromDataSource(source);
    source.registerLocalLookup(new LocalLookupImpl(globalLocalsMap));
    ClassHierarchy classHierarchy = new ClassHierarchy.readFromDataSource(
        source, elementMap.commonElements);
    NativeData nativeData = new NativeData.readFromDataSource(
        source, elementMap.elementEnvironment);
    elementMap.nativeBasicData = nativeData;
    InterceptorData interceptorData = new InterceptorData.readFromDataSource(
        source, nativeData, elementMap.commonElements);
    BackendUsage backendUsage = new BackendUsage.readFromDataSource(source);
    RuntimeTypesNeed rtiNeed = new RuntimeTypesNeed.readFromDataSource(
        source, elementMap.elementEnvironment);
    JAllocatorAnalysis allocatorAnalysis =
        new JAllocatorAnalysis.readFromDataSource(source, options);
    NoSuchMethodData noSuchMethodData =
        new NoSuchMethodData.readFromDataSource(source);

    Set<ClassEntity> implementedClasses = source.readClasses().toSet();
    Set<ClassEntity> liveNativeClasses = source.readClasses().toSet();
    Set<MemberEntity> liveInstanceMembers = source.readMembers().toSet();
    Set<MemberEntity> assignedInstanceMembers = source.readMembers().toSet();
    Set<MemberEntity> processedMembers = source.readMembers().toSet();
    Map<ClassEntity, Set<ClassEntity>> mixinUses =
        source.readClassMap(() => source.readClasses().toSet());
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        source.readClassMap(() => source.readClasses().toSet());

    AnnotationsData annotationsData =
        new AnnotationsData.readFromDataSource(source);

    ClosureData closureData =
        new ClosureData.readFromDataSource(elementMap, source);

    OutputUnitData outputUnitData =
        new OutputUnitData.readFromDataSource(source);

    source.end(tag);

    return new JsClosedWorld(elementMap,
        nativeData: nativeData,
        interceptorData: interceptorData,
        backendUsage: backendUsage,
        rtiNeed: rtiNeed,
        allocatorAnalysis: allocatorAnalysis,
        noSuchMethodData: noSuchMethodData,
        implementedClasses: implementedClasses,
        liveNativeClasses: liveNativeClasses,
        liveInstanceMembers: liveInstanceMembers,
        assignedInstanceMembers: assignedInstanceMembers,
        processedMembers: processedMembers,
        mixinUses: mixinUses,
        typesImplementedBySubclasses: typesImplementedBySubclasses,
        classHierarchy: classHierarchy,
        abstractValueStrategy: abstractValueStrategy,
        annotationsData: annotationsData,
        globalLocalsMap: globalLocalsMap,
        closureDataLookup: closureData,
        outputUnitData: outputUnitData);
  }

  /// Serializes this [JsClosedWorld] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    elementMap.writeToDataSink(sink);
    globalLocalsMap.writeToDataSink(sink);

    classHierarchy.writeToDataSink(sink);
    nativeData.writeToDataSink(sink);
    interceptorData.writeToDataSink(sink);
    backendUsage.writeToDataSink(sink);
    rtiNeed.writeToDataSink(sink);
    allocatorAnalysis.writeToDataSink(sink);
    noSuchMethodData.writeToDataSink(sink);
    sink.writeClasses(implementedClasses);
    sink.writeClasses(liveNativeClasses);
    sink.writeMembers(liveInstanceMembers);
    sink.writeMembers(assignedInstanceMembers);
    sink.writeMembers(processedMembers);
    sink.writeClassMap(
        mixinUses, (Set<ClassEntity> set) => sink.writeClasses(set));
    sink.writeClassMap(typesImplementedBySubclasses,
        (Set<ClassEntity> set) => sink.writeClasses(set));
    annotationsData.writeToDataSink(sink);
    closureDataLookup.writeToDataSink(sink);
    outputUnitData.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  Sorter get sorter {
    return _sorter ??= new KernelSorter(elementMap);
  }

  @override
  AbstractValueDomain get abstractValueDomain {
    return _abstractValueDomain;
  }

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
    assert(classHierarchy.isInstantiated(cls),
        failedAt(cls, '$cls has not been instantiated.'));
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
    return elementMap.elementEnvironment.isMixinApplication(cls) &&
        !elementMap.elementEnvironment.isUnnamedMixinApplication(cls);
  }

  @override
  ClassEntity getAppliedMixin(ClassEntity cls) {
    return elementMap.getAppliedMixin(cls);
  }

  @override
  Iterable<ClassEntity> getInterfaces(ClassEntity cls) {
    return elementMap.getInterfaces(cls).map((t) => t.element);
  }

  @override
  ClassEntity getSuperClass(ClassEntity cls) {
    return elementMap.getSuperType(cls)?.element;
  }

  @override
  int getHierarchyDepth(ClassEntity cls) {
    return elementMap.getHierarchyDepth(cls);
  }

  @override
  OrderedTypeSet getOrderedTypeSet(ClassEntity cls) {
    return elementMap.getOrderedTypeSet(cls);
  }
}

class KernelSorter implements Sorter {
  final JsToElementMap elementMap;

  KernelSorter(this.elementMap);

  int _compareLibraries(LibraryEntity a, LibraryEntity b) {
    return utils.compareLibrariesUris(a.canonicalUri, b.canonicalUri);
  }

  int _compareSourceSpans(Entity entity1, SourceSpan sourceSpan1,
      Entity entity2, SourceSpan sourceSpan2) {
    int r = utils.compareSourceUris(sourceSpan1.uri, sourceSpan2.uri);
    if (r != 0) return r;
    return utils.compareEntities(
        entity1, sourceSpan1.begin, null, entity2, sourceSpan2.begin, null);
  }

  @override
  Iterable<LibraryEntity> sortLibraries(Iterable<LibraryEntity> libraries) {
    return libraries.toList()..sort(_compareLibraries);
  }

  @override
  Iterable<T> sortMembers<T extends MemberEntity>(Iterable<T> members) {
    return members.toList()..sort(compareMembersByLocation);
  }

  @override
  Iterable<ClassEntity> sortClasses(Iterable<ClassEntity> classes) {
    List<ClassEntity> regularClasses = <ClassEntity>[];
    List<ClassEntity> unnamedMixins = <ClassEntity>[];
    for (ClassEntity cls in classes) {
      if (elementMap.elementEnvironment.isUnnamedMixinApplication(cls)) {
        unnamedMixins.add(cls);
      } else {
        regularClasses.add(cls);
      }
    }
    List<ClassEntity> sorted = <ClassEntity>[];
    regularClasses.sort(compareClassesByLocation);
    sorted.addAll(regularClasses);
    unnamedMixins.sort((a, b) {
      int result = _compareLibraries(a.library, b.library);
      if (result != 0) return result;
      result = a.name.compareTo(b.name);
      assert(result != 0,
          failedAt(a, "Multiple mixins named ${a.name}: $a vs $b."));
      return result;
    });
    sorted.addAll(unnamedMixins);
    return sorted;
  }

  @override
  Iterable<TypedefEntity> sortTypedefs(Iterable<TypedefEntity> typedefs) {
    // TODO(redemption): Support this.
    assert(typedefs.isEmpty);
    return typedefs;
  }

  @override
  int compareLibrariesByLocation(LibraryEntity a, LibraryEntity b) {
    return _compareLibraries(a, b);
  }

  @override
  int compareClassesByLocation(ClassEntity a, ClassEntity b) {
    int r = _compareLibraries(a.library, b.library);
    if (r != 0) return r;
    ClassDefinition definition1 = elementMap.getClassDefinition(a);
    ClassDefinition definition2 = elementMap.getClassDefinition(b);
    return _compareSourceSpans(
        a, definition1.location, b, definition2.location);
  }

  @override
  int compareTypedefsByLocation(TypedefEntity a, TypedefEntity b) {
    // TODO(redemption): Support this.
    failedAt(a, 'KernelSorter.compareTypedefsByLocation unimplemented');
    return 0;
  }

  @override
  int compareMembersByLocation(MemberEntity a, MemberEntity b) {
    int r = _compareLibraries(a.library, b.library);
    if (r != 0) return r;
    MemberDefinition definition1 = elementMap.getMemberDefinition(a);
    MemberDefinition definition2 = elementMap.getMemberDefinition(b);
    return _compareSourceSpans(
        a, definition1.location, b, definition2.location);
  }
}

/// [LocalLookup] implementation used to deserialize [JsClosedWorld].
class LocalLookupImpl implements LocalLookup {
  final GlobalLocalsMap _globalLocalsMap;

  LocalLookupImpl(this._globalLocalsMap);

  @override
  Local getLocalByIndex(MemberEntity memberContext, int index) {
    KernelToLocalsMapImpl map = _globalLocalsMap.getLocalsMap(memberContext);
    return map.getLocalByIndex(index);
  }
}
