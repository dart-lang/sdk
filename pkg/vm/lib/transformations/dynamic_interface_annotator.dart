// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:yaml/yaml.dart';

import 'pragma.dart'
    show
        kDynModuleExtendablePragmaName,
        kDynModuleCanBeOverriddenPragmaName,
        kDynModuleCallablePragmaName,
        kDynModuleImplicitlyCallablePragmaName;

void annotateComponent(String dynamicInterfaceSpecification, Uri baseUri,
    Component component, CoreTypes coreTypes) {
  final spec = loadYamlNode(dynamicInterfaceSpecification) as YamlMap;
  verifyKeys(spec, const {'extendable', 'can-be-overridden', 'callable'});
  final LibraryIndex libraryIndex = LibraryIndex.all(component);

  final extendableAnnotator = parseAndAnnotate(
      spec['extendable'],
      kDynModuleExtendablePragmaName,
      baseUri,
      component,
      coreTypes,
      libraryIndex,
      annotateClasses: true,
      annotateStaticMembers: false,
      annotateInstanceMembers: false);
  parseAndAnnotate(
      spec['can-be-overridden'],
      kDynModuleCanBeOverriddenPragmaName,
      baseUri,
      component,
      coreTypes,
      libraryIndex,
      annotateClasses: false,
      annotateStaticMembers: false,
      annotateInstanceMembers: true);
  final callableAnnotator = parseAndAnnotate(spec['callable'],
      kDynModuleCallablePragmaName, baseUri, component, coreTypes, libraryIndex,
      annotateClasses: true,
      annotateStaticMembers: true,
      annotateInstanceMembers: true);

  final implicitUsesAnnotator = _ImplicitUsesAnnotator(
      pragmaConstant(coreTypes, kDynModuleImplicitlyCallablePragmaName),
      callableAnnotator.annotatedClasses,
      callableAnnotator.annotatedMembers);

  implicitUsesAnnotator.annotateMixinUses(extendableAnnotator.annotatedClasses);
  implicitUsesAnnotator.annotateMemberUses(callableAnnotator.annotatedMembers);
  implicitUsesAnnotator.annotateDispatchTargets(component);
}

InstanceConstant pragmaConstant(CoreTypes coreTypes, String pragmaName) {
  return InstanceConstant(coreTypes.pragmaClass.reference, [], {
    coreTypes.pragmaName.fieldReference: StringConstant(pragmaName),
    coreTypes.pragmaOptions.fieldReference: NullConstant()
  });
}

_Annotator parseAndAnnotate(
  YamlList? items,
  String pragmaName,
  Uri baseUri,
  Component component,
  CoreTypes coreTypes,
  LibraryIndex libraryIndex, {
  required bool annotateClasses,
  required bool annotateStaticMembers,
  required bool annotateInstanceMembers,
}) {
  final pragma = pragmaConstant(coreTypes, pragmaName);
  final annotator = _Annotator(pragma,
      annotateClasses: annotateClasses,
      annotateStaticMembers: annotateStaticMembers,
      annotateInstanceMembers: annotateInstanceMembers);
  if (items != null) {
    for (final item in items) {
      final nodes = findNodes(item, baseUri, libraryIndex, component,
          allowStaticMembers: annotateStaticMembers,
          allowInstanceMembers: annotateInstanceMembers);
      for (final node in nodes) {
        node.accept(annotator);
      }
    }
  }
  return annotator;
}

void verifyKeys(YamlMap map, Set<String> allowedKeys) {
  for (final k in map.keys) {
    if (!allowedKeys.contains(k.toString())) {
      throw 'Unexpected key "$k" in dynamic interface specification';
    }
  }
}

List<TreeNode> findNodes(YamlNode yamlNode, Uri baseUri,
    LibraryIndex libraryIndex, Component component,
    {required bool allowStaticMembers, required bool allowInstanceMembers}) {
  final yamlMap = yamlNode as YamlMap;
  final allowMembers = allowStaticMembers || allowInstanceMembers;
  if (allowMembers) {
    verifyKeys(yamlMap, const {'library', 'class', 'member'});
  } else {
    verifyKeys(yamlMap, const {'library', 'class'});
  }

  final librarySpec = yamlMap['library'] as String;
  if (librarySpec.endsWith('*')) {
    verifyKeys(yamlMap, const {'library'});
    final prefix = baseUri
        .resolve(librarySpec.substring(0, librarySpec.length - 1))
        .toString();
    final libs = component.libraries
        .where((lib) => lib.importUri.toString().startsWith(prefix))
        .toList();
    if (libs.isEmpty) {
      throw 'No libraries found for pattern "$librarySpec"';
    }
    return libs;
  }
  final libraryUri = baseUri.resolve(librarySpec).toString();

  if (yamlMap.containsKey('class')) {
    final yamlClassNode = yamlMap['class'];
    if (yamlClassNode is YamlList) {
      verifyKeys(yamlMap, const {'library', 'class'});
      return [
        for (final c in yamlClassNode)
          libraryIndex.getClass(libraryUri, c as String)
      ];
    }

    final classSpec = yamlClassNode as String;

    if (allowMembers && yamlMap.containsKey('member')) {
      final memberSpec = yamlMap['member'] as String;
      final member = libraryIndex.getMember(libraryUri, classSpec, memberSpec);
      _validateSpecifiedMember(member,
          allowStaticMembers: allowStaticMembers,
          allowInstanceMembers: allowInstanceMembers);
      return [member];
    }

    return [libraryIndex.getClass(libraryUri, classSpec)];
  }

  if (allowMembers && yamlMap.containsKey('member')) {
    final memberSpec = yamlMap['member'] as String;
    final member = libraryIndex.getMember(libraryUri, '::', memberSpec);
    _validateSpecifiedMember(member,
        allowStaticMembers: allowStaticMembers,
        allowInstanceMembers: allowInstanceMembers);
    return [member];
  }

  return [libraryIndex.getLibrary(libraryUri)];
}

void _validateSpecifiedMember(Member member,
    {required bool allowStaticMembers, required bool allowInstanceMembers}) {
  if (member.isInstanceMember) {
    if (!allowInstanceMembers) {
      throw 'Expected non-instance member $member';
    }
  } else {
    if (!allowStaticMembers) {
      throw 'Expected instance member $member';
    }
  }
}

class _Annotator extends RecursiveVisitor {
  final Constant pragma;

  final bool annotateClasses;
  final bool annotateStaticMembers;
  final bool annotateInstanceMembers;

  final Set<Class> annotatedClasses = Set<Class>.identity();
  final Set<Member> annotatedMembers = Set<Member>.identity();

  _Annotator(
    this.pragma, {
    required this.annotateClasses,
    required this.annotateStaticMembers,
    required this.annotateInstanceMembers,
  });

  bool get annotateMembers => annotateStaticMembers || annotateInstanceMembers;

  @override
  void visitLibrary(Library node) {
    for (final c in node.classes) {
      if (c.name[0] != '_') {
        c.accept(this);
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
    if (annotateClasses && annotatedClasses.add(node)) {
      print("Annotated $node with $pragma");
      node.addAnnotation(ConstantExpression(pragma));
    }
  }

  void annotateMember(Member node) {
    if ((node.isInstanceMember
            ? annotateInstanceMembers
            : annotateStaticMembers) &&
        annotatedMembers.add(node)) {
      print("Annotated $node with $pragma");
      node.addAnnotation(ConstantExpression(pragma));
    }
  }
}

class _ImplicitUsesAnnotator extends RecursiveVisitor {
  final Constant pragma;

  final Set<Class> annotatedClasses = Set<Class>.identity();
  final Set<Member> annotatedMembers = Set<Member>.identity();
  final Set<Class> _annotatedConstantClasses = Set<Class>.identity();
  final Set<Constant> _visitedConstants = Set<Constant>.identity();
  final Map<Class, _ClassInfo> _classInfos = Map<Class, _ClassInfo>.identity();

  _ImplicitUsesAnnotator(this.pragma, Set<Class> explicitlyUsedClasses,
      Set<Member> explicitlyUsedMembers) {
    annotatedClasses.addAll(explicitlyUsedClasses);
    annotatedMembers.addAll(explicitlyUsedMembers);
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
    }
  }

  @override
  void visitProcedureReference(Procedure node) {
    annotateMember(node);
    if (node.isRedirectingFactory) {
      final target = node.function.redirectingFactoryTarget?.target;
      target?.acceptReference(this);
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
      print("Annotated $node with $pragma");
      node.addAnnotation(ConstantExpression(pragma));
    }
  }

  void annotateMember(Member node) {
    if (annotatedMembers.add(node)) {
      print("Annotated $node with $pragma");
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
        }
      }
      final superclass = node.superclass;
      if (superclass != null) {
        annotateConstantClass(superclass);
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
    final implementedClassInfos = cls.implementedTypes
        .map((sup) => _getClassInfo(sup.classNode))
        .toList();
    return _ClassInfo(
        cls, superclassInfo, mixedInClassInfo, implementedClassInfos);
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
  late final Map<Name, Member> dispatchTargetsSetters =
      _initDispatchTargets(true);
  late final Map<Name, Member> dispatchTargetsNonSetters =
      _initDispatchTargets(false);

  _ClassInfo(this.classNode, this.superclass, this.mixedInClass,
      this.implementedClasses);

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
      targets = Map.of(setters
          ? superclass.dispatchTargetsSetters
          : superclass.dispatchTargetsNonSetters);
    } else {
      targets = {};
    }
    final mixedInClass = this.mixedInClass;
    if (mixedInClass != null) {
      targets.addAll(setters
          ? mixedInClass.dispatchTargetsSetters
          : mixedInClass.dispatchTargetsNonSetters);
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
