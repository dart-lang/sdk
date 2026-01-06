// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/api_prototype/dynamic_module_validator.dart'
    show DynamicInterfaceLanguageImplPragmas, DynamicInterfaceSpecification;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;

import 'pragma.dart'
    show
        kDynModuleCanBeOverriddenPragmaName,
        kDynModuleCallablePragmaName,
        kDynModuleExtendablePragmaName,
        kDynModuleImplicitlyCallablePragmaName,
        kDynModuleImplicitlyExtendablePragmaName,
        kDynModuleCanBeOverriddenImplicitlyPragmaName;

void annotateComponent(
  String dynamicInterfaceSpecification,
  Uri baseUri,
  Component component,
  CoreTypes coreTypes, {
  Map<String, List<Map<String, String>>>? detailedDynamicInterfaceJson,
}) {
  final spec = DynamicInterfaceSpecification(
    dynamicInterfaceSpecification,
    baseUri,
    component,
  );

  discoverLanguageImplPragmasInCoreLibraries(spec, component, coreTypes);

  final _DetailedDynamicInterfaceLogger? logger =
      detailedDynamicInterfaceJson != null
          ? _DetailedDynamicInterfaceLogger(detailedDynamicInterfaceJson)
          : null;

  logger?.setActiveSection('extendable');
  final extendableAnnotator = annotateNodes(
    spec.extendable,
    kDynModuleExtendablePragmaName,
    baseUri,
    coreTypes,
    annotateClasses: true,
    annotateFinalClasses: false,
    annotateStaticMembers: false,
    annotateInstanceMembers: false,
    logger: logger,
  );

  _ImplicitExtendableAnnotator(
    pragmaConstant(coreTypes, kDynModuleImplicitlyExtendablePragmaName),
    extendableAnnotator.annotatedClasses,
  ).annotate();

  logger?.setActiveSection('can-be-overridden');
  final canBeOverriddenAnnotator = annotateNodes(
    spec.canBeOverridden,
    kDynModuleCanBeOverriddenPragmaName,
    baseUri,
    coreTypes,
    annotateClasses: false,
    annotateFinalClasses: true,
    annotateStaticMembers: false,
    annotateInstanceMembers: true,
    logger: logger,
  );

  final hierarchy = ClassHierarchy(component, coreTypes);

  copyCanBeOverriddenToMixinApplications(
    canBeOverriddenAnnotator.annotatedMembers,
    canBeOverriddenAnnotator.pragma,
    component,
    hierarchy,
  );

  _ImplicitOverridesAnnotator(
    pragmaConstant(coreTypes, kDynModuleCanBeOverriddenImplicitlyPragmaName),
    hierarchy,
    canBeOverriddenAnnotator.annotatedMembers,
  ).annotate();

  logger?.setActiveSection('callable');
  final callableAnnotator = annotateNodes(
    spec.callable,
    kDynModuleCallablePragmaName,
    baseUri,
    coreTypes,
    annotateClasses: true,
    annotateFinalClasses: true,
    annotateStaticMembers: true,
    annotateInstanceMembers: true,
    logger: logger,
  );

  final implicitUsesAnnotator = _ImplicitUsesAnnotator(
    pragmaConstant(coreTypes, kDynModuleImplicitlyCallablePragmaName),
    callableAnnotator.annotatedClasses,
    callableAnnotator.annotatedMembers,
  );

  implicitUsesAnnotator.annotateMixinUses(extendableAnnotator.annotatedClasses);
  implicitUsesAnnotator.annotateMemberUses(callableAnnotator.annotatedMembers);
  implicitUsesAnnotator.annotateDispatchTargets(component);
}

InstanceConstant pragmaConstant(CoreTypes coreTypes, String pragmaName) {
  return InstanceConstant(coreTypes.pragmaClass.reference, [], {
    coreTypes.pragmaName.fieldReference: StringConstant(pragmaName),
    coreTypes.pragmaOptions.fieldReference: NullConstant(),
  });
}

_Annotator annotateNodes(
  Set<TreeNode> nodes,
  String pragmaName,
  Uri baseUri,
  CoreTypes coreTypes, {
  required bool annotateClasses,
  required bool annotateFinalClasses,
  required bool annotateStaticMembers,
  required bool annotateInstanceMembers,
  _DetailedDynamicInterfaceLogger? logger,
}) {
  final pragma = pragmaConstant(coreTypes, pragmaName);
  final annotator = _Annotator(
    pragma,
    annotateClasses: annotateClasses,
    annotateFinalClasses: annotateFinalClasses,
    annotateStaticMembers: annotateStaticMembers,
    annotateInstanceMembers: annotateInstanceMembers,
    logger: logger,
  );
  for (final node in nodes) {
    node.accept(annotator);
  }
  return annotator;
}

class _Annotator extends RecursiveVisitor {
  final Constant pragma;

  final bool annotateClasses;
  final bool annotateFinalClasses;
  final bool annotateStaticMembers;
  final bool annotateInstanceMembers;
  final _DetailedDynamicInterfaceLogger? logger;

  final Set<Class> annotatedClasses = Set<Class>.identity();
  final Set<Member> annotatedMembers = Set<Member>.identity();

  _Annotator(
    this.pragma, {
    required this.annotateClasses,
    required this.annotateFinalClasses,
    required this.annotateStaticMembers,
    required this.annotateInstanceMembers,
    this.logger,
  });

  bool get annotateMembers => annotateStaticMembers || annotateInstanceMembers;

  @override
  void visitLibrary(Library node) {
    for (final c in node.classes) {
      if (c.name[0] != '_') {
        c.accept(this);
      }
    }
    for (final ext in node.extensions) {
      if (ext.name[0] != '_') {
        ext.accept(this);
      }
    }
    for (final extensionType in node.extensionTypeDeclarations) {
      if (extensionType.name[0] != '_') {
        extensionType.accept(this);
      }
    }
    for (final exportRef in node.additionalExports) {
      exportRef.node!.accept(this);
    }
    if (annotateMembers) {
      _visitPublicMembers(node.procedures);
      _visitPublicMembers(node.fields);
    }
  }

  @override
  void visitClass(Class node) {
    annotateClass(node);
    if (annotateMembers) {
      _visitPublicMembers(node.constructors);
      _visitPublicMembers(node.procedures);
      _visitPublicMembers(node.fields);
    }
  }

  void _visitPublicMembers(List<Member> members) {
    for (final m in members) {
      if (!m.name.isPrivate) {
        m.accept(this);
      }
    }
  }

  @override
  void defaultMember(Member node) {
    annotateMember(node);
  }

  @override
  void visitClassReference(Class node) {
    annotateClass(node);
  }

  void annotateClass(Class node) {
    if (annotateClasses &&
        (annotateFinalClasses || !node.isFinal) &&
        annotatedClasses.add(node)) {
      logger?.logNode(node);
      node.addAnnotation(ConstantExpression(pragma));
    }
  }

  void annotateMember(Member node) {
    if ((node.isInstanceMember
            ? annotateInstanceMembers
            : annotateStaticMembers) &&
        annotatedMembers.add(node)) {
      logger?.logNode(node);
      node.addAnnotation(ConstantExpression(pragma));
    }
  }

  @override
  void visitExtension(Extension node) {
    for (final md in node.memberDescriptors) {
      final member = md.memberReference?.node;
      if (member != null) {
        annotateMember(member as Member);
      }
      final tearOff = md.tearOffReference?.node;
      if (tearOff != null) {
        annotateMember(tearOff as Member);
      }
    }
  }

  @override
  void visitExtensionTypeDeclaration(ExtensionTypeDeclaration node) {
    for (final md in node.memberDescriptors) {
      final member = md.memberReference?.node;
      if (member != null) {
        annotateMember(member as Member);
      }
      final tearOff = md.tearOffReference?.node;
      if (tearOff != null) {
        annotateMember(tearOff as Member);
      }
    }
    node.declaredRepresentationType.accept(this);
  }
}

class _ImplicitExtendableAnnotator {
  final Constant pragma;
  final Set<Class> extendableClasses;
  final Set<Class> implicitlyExtendable = Set<Class>.identity();

  _ImplicitExtendableAnnotator(this.pragma, this.extendableClasses);

  void annotate() {
    for (final cls in extendableClasses) {
      annotateSupertypesOf(cls);
    }
  }

  void annotateSupertypesOf(Class cls) {
    for (final supertype in cls.supers) {
      final supertypeClass = supertype.classNode;
      if (implicitlyExtendable.add(supertypeClass) &&
          !extendableClasses.contains(supertypeClass)) {
        supertypeClass.addAnnotation(ConstantExpression(pragma));
        annotateSupertypesOf(supertypeClass);
      }
    }
  }
}

class _ImplicitOverridesAnnotator {
  final Constant pragma;
  final ClassHierarchy hierarchy;
  final Set<Member> overriddenMembers;
  final Set<Member> implicitlyOverriddenSetters = Set<Member>.identity();
  final Set<Member> implicitlyOverriddenNonSetters = Set<Member>.identity();

  _ImplicitOverridesAnnotator(
    this.pragma,
    this.hierarchy,
    this.overriddenMembers,
  );

  void annotate() {
    for (final member in overriddenMembers) {
      final cls = member.enclosingClass!;
      if (member.hasGetter) {
        annotateSupertypesOf(cls, member.name, setter: false);
      }
      if (member.hasSetter) {
        annotateSupertypesOf(cls, member.name, setter: true);
      }
    }
  }

  void annotateSupertypesOf(
    Class cls,
    Name memberName, {
    required bool setter,
  }) {
    for (final supertype in cls.supers) {
      final supertypeClass = supertype.classNode;
      final member = ClassHierarchy.findMemberByName(
        hierarchy.getDeclaredMembers(supertypeClass, setters: setter),
        memberName,
      );
      if (member != null) {
        final implicitlyOverridden =
            setter
                ? implicitlyOverriddenSetters
                : implicitlyOverriddenNonSetters;
        if (implicitlyOverridden.add(member) &&
            !overriddenMembers.contains(member)) {
          member.addAnnotation(ConstantExpression(pragma));
        } else {
          // The member is already annotated - do not go deeper.
          continue;
        }
      }
      annotateSupertypesOf(supertypeClass, memberName, setter: setter);
    }
  }
}

class _ImplicitUsesAnnotator extends RecursiveVisitor {
  final Constant pragma;

  final Set<Class> annotatedClasses = Set<Class>.identity();
  final Set<Member> annotatedMembers = Set<Member>.identity();
  final Set<Class> _annotatedConstantClasses = Set<Class>.identity();
  final Set<Class> _annotatedSuperTypes = Set<Class>.identity();
  final Set<Constant> _visitedConstants = Set<Constant>.identity();
  final Map<Class, _ClassInfo> _classInfos = Map<Class, _ClassInfo>.identity();

  _ImplicitUsesAnnotator(
    this.pragma,
    Set<Class> explicitlyUsedClasses,
    Set<Member> explicitlyUsedMembers,
  ) {
    annotatedClasses.addAll(explicitlyUsedClasses);
    annotatedMembers.addAll(explicitlyUsedMembers);
    explicitlyUsedClasses.forEach(annotateSuperTypes);
  }

  void annotateMixinUses(Set<Class> extendableClasses) {
    for (final cls in extendableClasses) {
      if (cls.isMixinClass || cls.isMixinDeclaration) {
        cls.visitChildren(this);
      }
    }
  }

  void annotateMemberUses(Set<Member> explicitlyUsedMembers) {
    for (final node in explicitlyUsedMembers) {
      node.acceptReference(this);
    }
  }

  @override
  void visitClassReference(Class node) {
    annotateClass(node);
  }

  @override
  void visitConstructorReference(Constructor node) {
    annotateMember(node);
    if (node.isConst) {
      annotateConstantClass(node.enclosingClass);
      node.visitChildren(this);
    }
    annotateSuperTypes(node.enclosingClass);
  }

  @override
  void visitProcedureReference(Procedure node) {
    annotateMember(node);
    if (node.isRedirectingFactory) {
      final target = node.function.redirectingFactoryTarget?.target;
      target?.acceptReference(this);
    }
    if (node.isFactory) {
      annotateSuperTypes(node.enclosingClass!);
    }
    if (node.isConst) {
      node.visitChildren(this);
    }
  }

  @override
  void visitFieldReference(Field node) {
    annotateMember(node);
    if (node.isConst) {
      (node.initializer as ConstantExpression).constant.acceptReference(this);
    }
  }

  @override
  void defaultConstantReference(Constant node) {
    if (_visitedConstants.add(node)) {
      node.visitChildren(this);
    }
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    super.visitInstanceConstantReference(node);
    annotateConstantClass(node.classNode);
  }

  void annotateClass(Class node) {
    if (annotatedClasses.add(node)) {
      node.addAnnotation(ConstantExpression(pragma));
    }
  }

  void annotateMember(Member node) {
    if (annotatedMembers.add(node)) {
      node.addAnnotation(ConstantExpression(pragma));
    }
  }

  // Annotate class potentially used in an InstanceConstant.
  void annotateConstantClass(Class node) {
    if (_annotatedConstantClasses.add(node)) {
      annotateClass(node);
      for (final f in node.fields) {
        if (f.isInstanceMember) {
          annotateMember(f);
          f.initializer?.accept(this);
        }
      }
      final superclass = node.superclass;
      if (superclass != null) {
        annotateConstantClass(superclass);
      }
    }
  }

  /// Annotate all types mentioned in the chain of supertypes of the given
  /// class as they can be referenced by a dynamic module when allocating
  /// an instance of the class.
  void annotateSuperTypes(Class node) {
    if (_annotatedSuperTypes.add(node)) {
      final supertype = node.supertype;
      if (supertype != null) {
        visitList(supertype.typeArguments, this);
        annotateSuperTypes(supertype.classNode);
      }
    }
  }

  void annotateDispatchTargets(Component component) {
    for (final m in annotatedMembers) {
      if (m.isInstanceMember) {
        _getClassInfo(m.enclosingClass!).addSelector(m);
      }
    }
    for (final lib in component.libraries) {
      for (final classNode in lib.classes) {
        final classInfo = _getClassInfo(classNode);
        classInfo.collectSelectors();
        for (final selector in classInfo.setterSelectors) {
          final dispatchTarget = classInfo.dispatchTargetsSetters[selector];
          if (dispatchTarget != null) {
            annotateMember(dispatchTarget);
          }
        }
        for (final selector in classInfo.nonSetterSelectors) {
          final dispatchTarget = classInfo.dispatchTargetsNonSetters[selector];
          if (dispatchTarget != null) {
            annotateMember(dispatchTarget);
          }
        }
      }
    }
  }

  _ClassInfo _getClassInfo(Class cls) =>
      _classInfos[cls] ??= _createClassInfo(cls);

  _ClassInfo _createClassInfo(Class cls) {
    final superclass = cls.superclass;
    final superclassInfo =
        superclass != null ? _getClassInfo(superclass) : null;
    final mixedInClass = cls.mixedInClass;
    final mixedInClassInfo =
        mixedInClass != null ? _getClassInfo(mixedInClass) : null;
    final implementedClassInfos =
        cls.implementedTypes
            .map((sup) => _getClassInfo(sup.classNode))
            .toList();
    return _ClassInfo(
      cls,
      superclassInfo,
      mixedInClassInfo,
      implementedClassInfos,
    );
  }
}

class _ClassInfo {
  final Class classNode;
  final _ClassInfo? superclass;
  final _ClassInfo? mixedInClass;
  final List<_ClassInfo> implementedClasses;

  // Callable selectors.
  final setterSelectors = Set<Name>();
  final nonSetterSelectors = Set<Name>();
  bool collected = false;

  // Cache of dispatch targets.
  late final Map<Name, Member> dispatchTargetsSetters = _initDispatchTargets(
    true,
  );
  late final Map<Name, Member> dispatchTargetsNonSetters = _initDispatchTargets(
    false,
  );

  _ClassInfo(
    this.classNode,
    this.superclass,
    this.mixedInClass,
    this.implementedClasses,
  );

  void addSelector(Member m) {
    if (m.isInstanceMember) {
      if (!_isSetter(m)) {
        nonSetterSelectors.add(m.name);
      }
      if (m.hasSetter) {
        setterSelectors.add(m.name);
      }
    }
  }

  void addAllSelectors(_ClassInfo other) {
    setterSelectors.addAll(other.setterSelectors);
    nonSetterSelectors.addAll(other.nonSetterSelectors);
  }

  void collectSelectors() {
    if (!collected) {
      final superclass = this.superclass;
      if (superclass != null) {
        superclass.collectSelectors();
        addAllSelectors(superclass);
      }
      final mixedInClass = this.mixedInClass;
      if (mixedInClass != null) {
        mixedInClass.collectSelectors();
        addAllSelectors(mixedInClass);
      }
      for (final c in implementedClasses) {
        c.collectSelectors();
        addAllSelectors(c);
      }
      collected = true;
    }
  }

  Map<Name, Member> _initDispatchTargets(bool setters) {
    Map<Name, Member> targets;
    final superclass = this.superclass;
    if (superclass != null) {
      targets = Map.of(
        setters
            ? superclass.dispatchTargetsSetters
            : superclass.dispatchTargetsNonSetters,
      );
    } else {
      targets = {};
    }
    final mixedInClass = this.mixedInClass;
    if (mixedInClass != null) {
      targets.addAll(
        setters
            ? mixedInClass.dispatchTargetsSetters
            : mixedInClass.dispatchTargetsNonSetters,
      );
    }
    for (Field f in classNode.fields) {
      if (!f.isStatic && !f.isAbstract) {
        if (!setters || f.hasSetter) {
          targets[f.name] = f;
        }
      }
    }
    for (Procedure p in classNode.procedures) {
      if (!p.isStatic && !p.isAbstract) {
        if (p.isSetter == setters) {
          targets[p.name] = p;
        }
      }
    }
    return targets;
  }

  static bool _isSetter(Member m) => m is Procedure && m.isSetter;
}

void discoverLanguageImplPragmasInCoreLibraries(
  DynamicInterfaceSpecification spec,
  Component component,
  CoreTypes coreTypes,
) {
  final languageImplPragmas = DynamicInterfaceLanguageImplPragmas(coreTypes);
  final visitor = _DiscoverLanguageImplPragmasVisitor(
    spec,
    languageImplPragmas,
  );
  for (final lib in component.libraries) {
    if (languageImplPragmas.isPlatformLibrary(lib)) {
      visitor.visitLibrary(lib);
    }
  }
}

class _DiscoverLanguageImplPragmasVisitor extends RecursiveVisitor {
  final DynamicInterfaceSpecification spec;
  final DynamicInterfaceLanguageImplPragmas languageImplPragmas;

  _DiscoverLanguageImplPragmasVisitor(this.spec, this.languageImplPragmas);

  @override
  void visitClass(Class node) {
    if (languageImplPragmas.isExtendable(node)) {
      spec.extendable.add(node);
    }
    if (languageImplPragmas.isCallable(node)) {
      spec.callable.add(node);
    }
    node.visitChildren(this);
  }

  @override
  void defaultMember(Member node) {
    if (languageImplPragmas.isCallable(node)) {
      spec.callable.add(node);
    }
    if (languageImplPragmas.canBeOverridden(node)) {
      if (!node.isInstanceMember) {
        throw 'Expected instance member $node';
      }
      spec.canBeOverridden.add(node);
    }
  }
}

// Mixin transformation copies all members of mixins into mixin applications.
// So we need to copy can-be-overridden pragmas from members of mixins to
// their copies in the transformed mixin applications.
void copyCanBeOverriddenToMixinApplications(
  Set<Member> overriddenMembers,
  Constant pragma,
  Component component,
  ClassHierarchy hierarchy,
) {
  void processMember(Member original, Class mixinApplication) {
    if (!original.isInstanceMember) {
      return;
    }
    if (!overriddenMembers.contains(original)) {
      return;
    }
    final member = ClassHierarchy.findMemberByName(
      hierarchy.getDeclaredMembers(
        mixinApplication,
        setters: original is Procedure && original.isSetter,
      ),
      original.name,
    );
    if (member == null) {
      return;
    }
    if (overriddenMembers.add(member)) {
      member.addAnnotation(ConstantExpression(pragma));
    }
  }

  for (final library in component.libraries) {
    for (final cls in library.classes) {
      if (cls.isEliminatedMixin) {
        final origin = cls.implementedTypes.last.classNode;
        for (final proc in origin.procedures) {
          processMember(proc, cls);
        }
        for (final field in origin.fields) {
          processMember(field, cls);
        }
      }
    }
  }
}

class _DetailedDynamicInterfaceLogger {
  final Map<String, List<Map<String, String>>> json;
  late List<Map<String, String>> section;

  _DetailedDynamicInterfaceLogger(this.json);

  void setActiveSection(String name) {
    section = (json[name] ??= <Map<String, String>>[]);
  }

  void logNode(TreeNode node) {
    switch (node) {
      case Class():
        section.add({
          'library': node.enclosingLibrary.importUri.toString(),
          'class': node.name,
        });
      case Member() when node.enclosingClass != null:
        section.add({
          'library': node.enclosingLibrary.importUri.toString(),
          'class': node.enclosingClass!.demangledName,
          'member': node.name.text,
        });
      case Member() when node.enclosingClass == null:
        section.add({
          'library': node.enclosingLibrary.importUri.toString(),
          'member': node.name.text,
        });
    }
  }
}
