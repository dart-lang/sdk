// Copyright (c) 2018, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:collection/collection.dart' show mergeSort;
import 'package:kernel/ast.dart' as ir;
import 'package:front_end/src/api_unstable/dart2js.dart' show Link;

import '../closure.dart';
import '../common.dart';
import '../common/elements.dart' show JCommonElements, JElementEnvironment;
import '../common/names.dart';
import '../deferred_load/output_unit.dart'
    show LateOutputUnitDataBuilder, OutputUnitData;
import '../elements/entities.dart';
import '../elements/entity_utils.dart' as utils;
import '../elements/names.dart';
import '../elements/types.dart';
import '../environment.dart';
import '../inferrer/abstract_value_domain.dart';
import '../inferrer/abstract_value_strategy.dart';
import '../js_emitter/sorter.dart';
import '../js_backend/annotations.dart';
import '../js_backend/field_analysis.dart';
import '../js_backend/backend_usage.dart';
import '../js_backend/interceptor_data.dart';
import '../js_backend/native_data.dart';
import '../js_backend/no_such_method_registry.dart';
import '../js_backend/runtime_types_resolution.dart';
import '../ordered_typeset.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../universe/class_hierarchy.dart';
import '../universe/class_set.dart';
import '../universe/function_set.dart' show FunctionSet;
import '../universe/member_usage.dart';
import '../universe/selector.dart';
import '../world.dart';
import 'element_map.dart';
import 'element_map_impl.dart';
import 'elements.dart';
import 'records.dart' show RecordData;

class JClosedWorld implements World {
  static const String tag = 'closed-world';

  final NativeData nativeData;
  final InterceptorData interceptorData;
  final BackendUsage backendUsage;
  final NoSuchMethodData noSuchMethodData;

  // [_allFunctions] is created lazily because it is not used when we switch
  // from a frontend to a backend model before inference.
  late final FunctionSet _allFunctions =
      FunctionSet(liveInstanceMembers.followedBy(recordData.allGetters));

  final Map<ClassEntity, Set<ClassEntity>> mixinUses;

  late final Map<ClassEntity, List<ClassEntity>> _liveMixinUses = () {
    final result = Map<ClassEntity, List<ClassEntity>>();
    for (ClassEntity mixin in mixinUses.keys) {
      List<ClassEntity> uses = <ClassEntity>[];

      void addLiveUse(ClassEntity mixinApplication) {
        if (classHierarchy.isInstantiated(mixinApplication)) {
          uses.add(mixinApplication);
        } else if (_isNamedMixinApplication(mixinApplication)) {
          Set<ClassEntity>? next = mixinUses[mixinApplication];
          if (next != null) {
            next.forEach(addLiveUse);
          }
        }
      }

      mixinUses[mixin]!.forEach(addLiveUse);
      if (uses.isNotEmpty) {
        result[mixin] = uses;
      }
    }
    return result;
  }();

  final Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses;

  final Map<ClassEntity, Map<ClassEntity, bool>> _subtypeCoveredByCache = {};

  // TODO(johnniwinther): Can this be derived from [ClassSet]s?
  final Set<ClassEntity> implementedClasses;

  final Set<MemberEntity> liveInstanceMembers;

  final Set<MemberEntity> liveAbstractInstanceMembers;

  /// Members that are written either directly or through a setter selector.
  final Set<MemberEntity> assignedInstanceMembers;

  final Set<ClassEntity> liveNativeClasses;

  final Set<MemberEntity> processedMembers;

  /// Returns the set of interfaces passed as type arguments to the internal
  /// `extractTypeArguments` function.
  final Set<ClassEntity> extractTypeArgumentsInterfacesNewRti;

  final ClassHierarchy classHierarchy;

  final JsKernelToElementMap elementMap;
  final RuntimeTypesNeed rtiNeed;
  late AbstractValueDomain _abstractValueDomain;
  final JFieldAnalysis fieldAnalysis;
  final AnnotationsData annotationsData;
  final ClosureData closureDataLookup;
  final RecordData recordData;
  final OutputUnitData outputUnitData;

  /// The [Sorter] used for sorting elements in the generated code.
  Sorter? _sorter;

  final Map<MemberEntity, MemberAccess> memberAccess;

  JClosedWorld(
      this.elementMap,
      this.nativeData,
      this.interceptorData,
      this.backendUsage,
      this.rtiNeed,
      this.fieldAnalysis,
      this.noSuchMethodData,
      this.implementedClasses,
      this.liveNativeClasses,
      this.liveInstanceMembers,
      this.liveAbstractInstanceMembers,
      this.assignedInstanceMembers,
      this.processedMembers,
      this.extractTypeArgumentsInterfacesNewRti,
      this.mixinUses,
      this.typesImplementedBySubclasses,
      this.classHierarchy,
      AbstractValueStrategy abstractValueStrategy,
      this.annotationsData,
      this.closureDataLookup,
      this.recordData,
      this.outputUnitData,
      this.memberAccess) {
    _abstractValueDomain = abstractValueStrategy.createDomain(this);
  }

  /// Deserializes a [JClosedWorld] object from [source].
  factory JClosedWorld.readFromDataSource(
      CompilerOptions options,
      DiagnosticReporter reporter,
      Environment environment,
      AbstractValueStrategy abstractValueStrategy,
      ir.Component component,
      DataSourceReader source) {
    source.begin(tag);

    JsKernelToElementMap elementMap = JsKernelToElementMap.readFromDataSource(
        options, reporter, environment, component, source);
    ClassHierarchy classHierarchy =
        ClassHierarchy.readFromDataSource(source, elementMap.commonElements);
    NativeData nativeData =
        NativeData.readFromDataSource(source, elementMap.elementEnvironment);
    elementMap.nativeData = nativeData;
    InterceptorData interceptorData = InterceptorData.readFromDataSource(
        source, nativeData, elementMap.commonElements);
    BackendUsage backendUsage = BackendUsage.readFromDataSource(source);
    RuntimeTypesNeed rtiNeed = RuntimeTypesNeed.readFromDataSource(
        source, elementMap.elementEnvironment);
    JFieldAnalysis allocatorAnalysis =
        JFieldAnalysis.readFromDataSource(source, options);
    NoSuchMethodData noSuchMethodData =
        NoSuchMethodData.readFromDataSource(source);

    Set<ClassEntity> implementedClasses = source.readClasses().toSet();
    Set<ClassEntity> liveNativeClasses = source.readClasses().toSet();
    Set<ClassEntity> extractTypeArgumentsInterfacesNewRti =
        source.readClasses().toSet();
    Set<MemberEntity> liveInstanceMembers = source.readMembers().toSet();
    Set<MemberEntity> liveAbstractInstanceMembers =
        source.readMembers().toSet();
    Set<MemberEntity> assignedInstanceMembers = source.readMembers().toSet();
    Set<MemberEntity> processedMembers = source.readMembers().toSet();
    Map<ClassEntity, Set<ClassEntity>> mixinUses =
        source.readClassMap(() => source.readClasses().toSet());
    Map<ClassEntity, Set<ClassEntity>> typesImplementedBySubclasses =
        source.readClassMap(() => source.readClasses().toSet());

    AnnotationsData annotationsData =
        AnnotationsData.readFromDataSource(options, reporter, source);

    ClosureData closureData =
        ClosureData.readFromDataSource(elementMap, source);
    RecordData recordData = RecordData.readFromDataSource(elementMap, source);

    OutputUnitData outputUnitData = OutputUnitData.readFromDataSource(source);
    elementMap.lateOutputUnitDataBuilder =
        LateOutputUnitDataBuilder(outputUnitData);

    Map<MemberEntity, MemberAccess> memberAccess = source.readMemberMap(
        (MemberEntity member) => MemberAccess.readFromDataSource(source));

    source.end(tag);

    return JClosedWorld(
        elementMap,
        nativeData,
        interceptorData,
        backendUsage,
        rtiNeed,
        allocatorAnalysis,
        noSuchMethodData,
        implementedClasses,
        liveNativeClasses,
        liveInstanceMembers,
        liveAbstractInstanceMembers,
        assignedInstanceMembers,
        processedMembers,
        extractTypeArgumentsInterfacesNewRti,
        mixinUses,
        typesImplementedBySubclasses,
        classHierarchy,
        abstractValueStrategy,
        annotationsData,
        closureData,
        recordData,
        outputUnitData,
        memberAccess);
  }

  /// Serializes this [JClosedWorld] to [sink].
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    elementMap.writeToDataSink(sink);
    classHierarchy.writeToDataSink(sink);
    nativeData.writeToDataSink(sink);
    interceptorData.writeToDataSink(sink);
    backendUsage.writeToDataSink(sink);
    rtiNeed.writeToDataSink(sink);
    fieldAnalysis.writeToDataSink(sink);
    noSuchMethodData.writeToDataSink(sink);
    sink.writeClasses(implementedClasses);
    sink.writeClasses(liveNativeClasses);
    sink.writeClasses(extractTypeArgumentsInterfacesNewRti);
    sink.writeMembers(liveInstanceMembers);
    sink.writeMembers(liveAbstractInstanceMembers);
    sink.writeMembers(assignedInstanceMembers);
    sink.writeMembers(processedMembers);
    sink.writeClassMap(
        mixinUses, (Set<ClassEntity> set) => sink.writeClasses(set));
    sink.writeClassMap(typesImplementedBySubclasses,
        (Set<ClassEntity> set) => sink.writeClasses(set));
    annotationsData.writeToDataSink(sink);
    closureDataLookup.writeToDataSink(sink);
    recordData.writeToDataSink(sink);
    outputUnitData.writeToDataSink(sink);
    sink.writeMemberMap(
        memberAccess,
        (MemberEntity member, MemberAccess access) =>
            access.writeToDataSink(sink));
    sink.end(tag);
  }

  JElementEnvironment get elementEnvironment => elementMap.elementEnvironment;

  JCommonElements get commonElements => elementMap.commonElements;

  DartTypes get dartTypes => elementMap.types;

  /// Returns `true` if [cls] is implemented by an instantiated class.
  bool isImplemented(ClassEntity cls) {
    return implementedClasses.contains(cls);
  }

  /// Returns the most specific subclass of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subclasses. If [cls] is not instantiated, `null` is returned.
  ClassEntity? getLubOfInstantiatedSubclasses(ClassEntity cls) {
    if (nativeData.isJsInteropClass(cls)) {
      return getLubOfInstantiatedSubclasses(
          commonElements.jsLegacyJavaScriptObjectClass);
    }
    ClassHierarchyNode hierarchy = classHierarchy.getClassHierarchyNode(cls);
    return hierarchy.getLubOfInstantiatedSubclasses();
  }

  /// Returns the most specific subtype of [cls] (including [cls]) that is
  /// directly instantiated or a superclass of all directly instantiated
  /// subtypes. If no subtypes of [cls] are instantiated, `null` is returned.
  ClassEntity? getLubOfInstantiatedSubtypes(ClassEntity cls) {
    if (nativeData.isJsInteropClass(cls)) {
      return getLubOfInstantiatedSubtypes(
          commonElements.jsLegacyJavaScriptObjectClass);
    }
    ClassSet classSet = classHierarchy.getClassSet(cls);
    return classSet.getLubOfInstantiatedSubtypes();
  }

  /// Returns `true` if [cls] is mixed into a live class.
  bool isUsedAsMixin(ClassEntity cls) {
    return !mixinUsesOf(cls).isEmpty;
  }

  /// Returns `true` if any live class that mixes in [cls] implements [type].
  bool hasAnySubclassOfMixinUseThatImplements(
      ClassEntity cls, ClassEntity type) {
    return mixinUsesOf(cls)
        .any((use) => hasAnySubclassThatImplements(use, type));
  }

  /// Returns `true` if every subtype of [x] is a subclass of [y] or a subclass
  /// of a mixin application of [y].
  bool everySubtypeIsSubclassOfOrMixinUseOf(ClassEntity x, ClassEntity y) {
    Map<ClassEntity, bool> secondMap = _subtypeCoveredByCache[x] ??= {};
    return secondMap[y] ??= classHierarchy.subtypesOf(x).every(
        (ClassEntity cls) =>
            classHierarchy.isSubclassOf(cls, y) ||
            isSubclassOfMixinUseOf(cls, y));
  }

  /// Returns `true` if any subclass of [superclass] implements [type].
  bool hasAnySubclassThatImplements(ClassEntity superclass, ClassEntity type) {
    Set<ClassEntity>? subclasses = typesImplementedBySubclasses[superclass];
    if (subclasses == null) return false;
    return subclasses.contains(type);
  }

  /// Returns `true` if a call of [selector] on [cls] and/or subclasses/subtypes
  /// need noSuchMethod handling.
  ///
  /// If the receiver is guaranteed to have a member that matches what we're
  /// looking for, there's no need to introduce a noSuchMethod handler. It will
  /// never be called.
  ///
  /// As an example, consider this class hierarchy:
  ///
  ///                   A    <-- noSuchMethod
  ///                  / \
  ///                 C   B  <-- foo
  ///
  /// If we know we're calling foo on an object of type B we don't have to worry
  /// about the noSuchMethod method in A because objects of type B implement
  /// foo. On the other hand, if we end up calling foo on something of type C we
  /// have to add a handler for it.
  ///
  /// If the holders of all user-defined noSuchMethod implementations that might
  /// be applicable to the receiver type have a matching member for the current
  /// name and selector, we avoid introducing a noSuchMethod handler.
  ///
  /// As an example, consider this class hierarchy:
  ///
  ///                        A    <-- foo
  ///                       / \
  ///    noSuchMethod -->  B   C  <-- bar
  ///                      |   |
  ///                      C   D  <-- noSuchMethod
  ///
  /// When calling foo on an object of type A, we know that the implementations
  /// of noSuchMethod are in the classes B and D that also (indirectly)
  /// implement foo, so we do not need a handler for it.
  ///
  /// If we're calling bar on an object of type D, we don't need the handler
  /// either because all objects of type D implement bar through inheritance.
  ///
  /// If we're calling bar on an object of type A we do need the handler because
  /// we may have to call B.noSuchMethod since B does not implement bar.
  bool needsNoSuchMethod(
      ClassEntity base, Selector selector, ClassQuery query) {
    /// Returns `true` if subclasses in the [rootNode] tree needs noSuchMethod
    /// handling.
    bool subclassesNeedNoSuchMethod(ClassHierarchyNode rootNode) {
      if (!rootNode.isInstantiated) {
        // No subclass needs noSuchMethod handling since they are all
        // uninstantiated.
        return false;
      }
      ClassEntity rootClass = rootNode.cls;
      if (_hasConcreteMatch(rootClass, selector)) {
        // The root subclass has a concrete implementation so no subclass needs
        // noSuchMethod handling.
        return false;
      } else if (rootNode.isExplicitlyInstantiated) {
        // The root class need noSuchMethod handling.
        return true;
      }
      IterationStep result = rootNode.forEachSubclass((ClassEntity subclass) {
        if (_hasConcreteMatch(subclass, selector,
            stopAtSuperclass: rootClass)) {
          // Found a match - skip all subclasses.
          return IterationStep.SKIP_SUBCLASSES;
        } else {
          // Stop fast - we found a need for noSuchMethod handling.
          return IterationStep.STOP;
        }
      }, ClassHierarchyNode.EXPLICITLY_INSTANTIATED, strict: true);
      // We stopped fast so we need noSuchMethod handling.
      return result == IterationStep.STOP;
    }

    ClassSet classSet = classHierarchy.getClassSet(base);
    ClassHierarchyNode node = classSet.node;
    if (query == ClassQuery.EXACT) {
      return node.isExplicitlyInstantiated &&
          !_hasConcreteMatch(base, selector);
    } else if (query == ClassQuery.SUBCLASS) {
      return subclassesNeedNoSuchMethod(node);
    } else {
      if (subclassesNeedNoSuchMethod(node)) return true;
      for (ClassHierarchyNode subtypeNode in classSet.subtypeNodes) {
        if (subclassesNeedNoSuchMethod(subtypeNode)) return true;
      }
      return false;
    }
  }

  /// Returns an iterable over the common supertypes of the [classes].
  Iterable<ClassEntity> commonSupertypesOf(Iterable<ClassEntity> classes) {
    Iterator<ClassEntity> iterator = classes.iterator;
    if (!iterator.moveNext()) return const <ClassEntity>[];

    ClassEntity cls = iterator.current;
    OrderedTypeSet typeSet = elementMap.getOrderedTypeSet(cls as JClass);
    if (!iterator.moveNext()) return typeSet.types.map((type) => type.element);

    int depth = typeSet.maxDepth;
    Link<OrderedTypeSet> otherTypeSets = const Link<OrderedTypeSet>();
    do {
      ClassEntity otherClass = iterator.current;
      OrderedTypeSet otherTypeSet =
          elementMap.getOrderedTypeSet(otherClass as JClass);
      otherTypeSets = otherTypeSets.prepend(otherTypeSet);
      if (otherTypeSet.maxDepth < depth) {
        depth = otherTypeSet.maxDepth;
      }
    } while (iterator.moveNext());

    List<ClassEntity> commonSupertypes = <ClassEntity>[];
    OUTER:
    for (Link<InterfaceType> link = typeSet[depth];
        link.head.element != commonElements.objectClass;
        link = link.tail!) {
      ClassEntity cls = link.head.element;
      for (Link<OrderedTypeSet> link = otherTypeSets;
          !link.isEmpty;
          link = link.tail!) {
        if (link.head.asInstanceOf(
                cls, elementMap.getHierarchyDepth(cls as JClass)) ==
            null) {
          continue OUTER;
        }
      }
      commonSupertypes.add(cls);
    }
    commonSupertypes.add(commonElements.objectClass);
    return commonSupertypes;
  }

  /// Returns an iterable over the live mixin applications that mixin [cls].
  Iterable<ClassEntity> mixinUsesOf(ClassEntity cls) {
    return _liveMixinUses[cls] ?? const <ClassEntity>[];
  }

  /// Returns `true` if any live class that mixes in [mixin] is also a subclass
  /// of [superclass].
  bool hasAnySubclassThatMixes(ClassEntity superclass, ClassEntity mixin) {
    return mixinUsesOf(mixin).any((ClassEntity each) {
      return classHierarchy.isSubclassOf(each, superclass);
    });
  }

  /// Returns `true` if [cls] or any superclass mixes in [mixin].
  bool isSubclassOfMixinUseOf(ClassEntity cls, ClassEntity mixin) {
    if (isUsedAsMixin(mixin)) {
      ClassEntity? current = cls;
      while (current != null) {
        ClassEntity? currentMixin =
            elementMap.getAppliedMixin(current as JClass);
        if (currentMixin == mixin) return true;
        current = elementEnvironment.getSuperClass(current);
      }
    }
    return false;
  }

  late final ClassEntity _functionLub =
      getLubOfInstantiatedSubtypes(commonElements.functionClass)!;

  /// Returns `true` if [selector] on [receiver] can hit a `call` method on a
  /// subclass of `Closure` using the [abstractValueDomain].
  ///
  /// Every implementation of `Closure` has a 'call' method with its own
  /// signature so it cannot be modelled by a [FunctionEntity]. Also,
  /// call-methods for tear-off are not part of the element model.
  bool includesClosureCallInDomain(Selector selector, AbstractValue? receiver,
      AbstractValueDomain abstractValueDomain) {
    return selector.name == Identifiers.call &&
        (receiver == null ||
            // This is logically equivalent to the former implementation using
            // `abstractValueDomain.contains` (which wrapped `containsMask`).
            // The switch to `abstractValueDomain.containsType` is because
            // `contains` was generally unsound but happened to work correctly
            // here. See https://dart-review.googlesource.com/c/sdk/+/130565
            // for further discussion.
            //
            // This checks if the receiver mask contains the entire type cone
            // originating from [_functionLub] and may therefore be unsound if
            // the receiver mask contains only part of the type cone. (Is this
            // possible?)
            //
            // TODO(fishythefish): Use `isDisjoint` or equivalent instead of
            // `containsType` once we can ensure it's fast enough.
            abstractValueDomain
                .containsType(receiver, _functionLub)
                .isPotentiallyTrue);
  }

  /// Returns `true` if [selector] on [receiver] can hit a `call` method on a
  /// subclass of `Closure`.
  ///
  /// Every implementation of `Closure` has a 'call' method with its own
  /// signature so it cannot be modelled by a [FunctionEntity]. Also,
  /// call-methods for tear-off are not part of the element model.
  bool includesClosureCall(Selector selector, AbstractValue? receiver) {
    return includesClosureCallInDomain(selector, receiver, abstractValueDomain);
  }

  Selector getSelector(ir.Expression node) => elementMap.getSelector(node);

  /// Returns all the instance members that may be invoked with the [selector]
  /// on the given [receiver] using the [abstractValueDomain]. The returned elements may include noSuchMethod
  /// handlers that are potential targets indirectly through the noSuchMethod
  /// mechanism.
  Iterable<MemberEntity> locateMembersInDomain(Selector selector,
      AbstractValue? receiver, AbstractValueDomain abstractValueDomain) {
    return _allFunctions.filter(selector, receiver, abstractValueDomain);
  }

  /// Returns all the instance members that may be invoked with the [selector]
  /// on the given [receiver]. The returned elements may include noSuchMethod
  /// handlers that are potential targets indirectly through the noSuchMethod
  /// mechanism.
  Iterable<MemberEntity> locateMembers(
      Selector selector, AbstractValue? receiver) {
    return locateMembersInDomain(selector, receiver, abstractValueDomain);
  }

  /// Returns the single [MemberEntity] that matches a call to [selector] on the
  /// [receiver]. If multiple targets exist, `null` is returned.
  MemberEntity? locateSingleMember(Selector selector, AbstractValue receiver) {
    if (includesClosureCall(selector, receiver)) return null;
    return abstractValueDomain.locateSingleMember(receiver, selector);
  }

  /// Returns `true` if the field [element] is known to be effectively final.
  bool fieldNeverChanges(MemberEntity element) {
    if (element is! FieldEntity) return false;
    if (nativeData.isNativeMember(element)) {
      // Some native fields are views of data that may be changed by operations.
      // E.g. node.firstChild depends on parentNode.removeBefore(n1, n2).
      // TODO(sra): Refine the effect classification so that native effects are
      // distinct from ordinary Dart effects.
      return false;
    }

    if (!element.isAssignable) {
      return true;
    }
    if (element.isInstanceMember) {
      return !assignedInstanceMembers.contains(element);
    }
    return false;
  }

  Sorter get sorter {
    return _sorter ??= KernelSorter(elementMap);
  }

  /// Returns the [AbstractValueDomain] used in the global type inference.
  AbstractValueDomain get abstractValueDomain {
    return _abstractValueDomain;
  }

  /// Returns whether [element] will be the one used at runtime when being
  /// invoked on an instance of [cls]. [name] is used to ensure library
  /// privacy is taken into account.
  bool hasElementIn(ClassEntity cls, Name name, Entity element) {
    ClassEntity? current = cls;
    while (current != null) {
      MemberEntity? member =
          elementEnvironment.lookupLocalClassMember(current, name);
      if (member != null && !member.isAbstract) {
        return member == element;
      }
      current = elementEnvironment.getSuperClass(current);
    }
    return false;
  }

  /// Returns whether a [selector] call on an instance of [cls]
  /// will hit a method at runtime, and not go through [noSuchMethod].
  bool _hasConcreteMatch(ClassEntity cls, Selector selector,
      {ClassEntity? stopAtSuperclass}) {
    assert(classHierarchy.isInstantiated(cls),
        failedAt(cls, '$cls has not been instantiated.'));
    MemberEntity? element =
        elementEnvironment.lookupClassMember(cls, selector.memberName);
    if (element == null) return false;

    if (element.isAbstract) {
      ClassEntity enclosingClass = element.enclosingClass!;
      return _hasConcreteMatch(
          elementEnvironment.getSuperClass(enclosingClass)!, selector);
    }
    return selector.appliesUnnamed(element);
  }

  bool _isNamedMixinApplication(ClassEntity cls) {
    return elementEnvironment.isMixinApplication(cls) &&
        !elementEnvironment.isUnnamedMixinApplication(cls);
  }

  /// Returns the set of read, write, and invocation accesses found on [member]
  /// during the closed world computation.
  MemberAccess? getMemberAccess(MemberEntity member) {
    return memberAccess[member];
  }

  /// Registers [interface] as a type argument to `extractTypeArguments`.
  void registerExtractTypeArguments(ClassEntity interface) {
    extractTypeArgumentsInterfacesNewRti.add(interface);
  }

  late final Set<ClassEntity> _defaultSuperclasses = {
    commonElements.objectClass,
    commonElements.jsLegacyJavaScriptObjectClass,
    commonElements.jsInterceptorClass
  };

  /// Returns true if [cls] acts as a default superclass to some subset of
  /// classes.
  bool isDefaultSuperclass(ClassEntity cls) =>
      _defaultSuperclasses.contains(cls);
}

class KernelSorter implements Sorter {
  final JsToElementMap elementMap;

  KernelSorter(this.elementMap);

  int _compareLibraries(LibraryEntity a, LibraryEntity b) {
    return utils.compareLibrariesUris(a.canonicalUri, b.canonicalUri);
  }

  /// Compare by URI, offset and then name. My return `0` for entities that are
  /// different entities with the same name and position, which happens for some
  /// code generated by transforms, e.g. late instance field getters and
  /// setters.
  int _compareByLocationThenName(Entity entity1, SourceSpan sourceSpan1,
      Entity entity2, SourceSpan sourceSpan2) {
    int r = utils.compareSourceUris(sourceSpan1.uri, sourceSpan2.uri);
    if (r != 0) return r;

    r = sourceSpan1.begin.compareTo(sourceSpan2.begin);
    if (r != 0) return r;

    return entity1.name!.compareTo(entity2.name!);
  }

  @override
  Iterable<LibraryEntity> sortLibraries(Iterable<LibraryEntity> libraries) {
    final list = List.of(libraries);
    mergeSort(list, compare: _compareLibraries);
    return list;
  }

  @override
  Iterable<T> sortMembers<T extends MemberEntity>(Iterable<T> members) {
    final list = List.of(members);
    mergeSort(list, compare: compareMembersByLocation);
    return list;
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
    mergeSort(regularClasses, compare: compareClassesByLocation);
    mergeSort(unnamedMixins, compare: (ClassEntity a, ClassEntity b) {
      int result = _compareLibraries(a.library, b.library);
      if (result != 0) return result;
      result = a.name.compareTo(b.name);
      assert(result != 0,
          failedAt(a, "Multiple mixins named ${a.name}: $a vs $b."));
      return result;
    });
    return [...regularClasses, ...unnamedMixins];
  }

  @override
  int compareLibrariesByLocation(LibraryEntity a, LibraryEntity b) {
    return _compareLibraries(a, b);
  }

  @override
  int compareClassesByLocation(ClassEntity a, ClassEntity b) {
    if (identical(a, b)) return 0;
    int r = _compareLibraries(a.library, b.library);
    if (r != 0) return r;
    ClassDefinition definition1 = elementMap.getClassDefinition(a);
    ClassDefinition definition2 = elementMap.getClassDefinition(b);
    return _compareByLocationThenName(
        a, definition1.location, b, definition2.location);
  }

  @override
  int compareMembersByLocation(MemberEntity a, MemberEntity b) {
    if (identical(a, b)) return 0;
    int r = _compareLibraries(a.library, b.library);
    if (r != 0) return r;
    MemberDefinition definition1 = elementMap.getMemberDefinition(a);
    MemberDefinition definition2 = elementMap.getMemberDefinition(b);
    return _compareByLocationThenName(
        a, definition1.location, b, definition2.location);
  }
}
