// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:yaml/yaml.dart';
import '../source/source_loader.dart' show SourceLoader;
import '../api_prototype/lowering_predicates.dart'
    show extractQualifiedNameFromExtensionMethodName;

import '../codes/cfe_codes.dart'
    show
        codeDynamicCallsAreNotAllowedInDynamicModule,
        noLength,
        codeConstructorShouldBeListedAsCallableInDynamicInterface,
        codeMemberShouldBeListedAsCallableInDynamicInterface,
        codeExtensionTypeShouldBeListedAsCallableInDynamicInterface,
        codeClassShouldBeListedAsCallableInDynamicInterface,
        codeClassShouldBeListedAsExtendableInDynamicInterface,
        codeMemberShouldBeListedAsCanBeOverriddenInDynamicInterface;

/// Validate dynamic module [libraries].
///
/// Dynamic modules cannot use certain language features
/// (such as dynamic calls). All Dart APIs used in the dynamic
/// module should be explicitly specified in the dynamic interface
/// specification yaml file.
void validateDynamicModule(
  String dynamicInterfaceSpecification,
  Uri dynamicInterfaceSpecificationUri,
  Component component,
  CoreTypes coreTypes,
  ClassHierarchy hierarchy,
  List<Library> libraries,
  SourceLoader loader,
) {
  final DynamicInterfaceSpecification spec = new DynamicInterfaceSpecification(
    dynamicInterfaceSpecification,
    dynamicInterfaceSpecificationUri,
    component,
  );
  final DynamicInterfaceLanguageImplPragmas languageImplPragmas =
      new DynamicInterfaceLanguageImplPragmas(coreTypes);
  final _DynamicModuleValidator validator = new _DynamicModuleValidator(
    spec,
    languageImplPragmas,
    new Set.of(libraries),
    hierarchy,
    loader,
  );
  for (Library library in libraries) {
    library.accept(validator);
  }
}

/// Parsed dynamic interface specification yaml file.
class DynamicInterfaceSpecification {
  // Specified Library, Class and Member nodes.
  final Set<TreeNode> extendable = {};
  final Set<TreeNode> canBeOverridden = {};
  final Set<TreeNode> callable = {};

  DynamicInterfaceSpecification(
    String dynamicInterfaceSpecification,
    Uri baseUri,
    Component component,
  ) {
    final YamlNode spec = loadYamlNode(dynamicInterfaceSpecification);
    final LibraryIndex libraryIndex = new LibraryIndex.all(component);

    // If the spec is empty, the result is a scalar and not a map.
    if (spec is! YamlMap) return;
    _verifyKeys(spec, const {'extendable', 'can-be-overridden', 'callable'});

    _parseList(
      spec['extendable'],
      extendable,
      baseUri,
      component,
      libraryIndex,
      allowStaticMembers: false,
      allowInstanceMembers: false,
    );

    _parseList(
      spec['can-be-overridden'],
      canBeOverridden,
      baseUri,
      component,
      libraryIndex,
      allowStaticMembers: false,
      allowInstanceMembers: true,
    );

    _parseList(
      spec['callable'],
      callable,
      baseUri,
      component,
      libraryIndex,
      allowStaticMembers: true,
      allowInstanceMembers: true,
    );
  }

  void _parseList(
    YamlList? items,
    Set<TreeNode> result,
    Uri baseUri,
    Component component,
    LibraryIndex libraryIndex, {
    required bool allowStaticMembers,
    required bool allowInstanceMembers,
  }) {
    if (items != null) {
      for (YamlNode item in items) {
        findNodes(
          item,
          result,
          baseUri,
          libraryIndex,
          component,
          allowStaticMembers: allowStaticMembers,
          allowInstanceMembers: allowInstanceMembers,
        );
      }
    }
  }

  void _verifyKeys(YamlMap map, Set<String> allowedKeys) {
    for (dynamic k in map.keys) {
      if (!allowedKeys.contains(k.toString())) {
        // Coverage-ignore-block(suite): Not run.
        throw 'Unexpected key "$k" in dynamic interface specification';
      }
    }
  }

  void findNodes(
    YamlNode yamlNode,
    Set<TreeNode> result,
    Uri baseUri,
    LibraryIndex libraryIndex,
    Component component, {
    required bool allowStaticMembers,
    required bool allowInstanceMembers,
  }) {
    final YamlMap yamlMap = yamlNode as YamlMap;
    final bool allowMembers = allowStaticMembers || allowInstanceMembers;
    if (allowMembers) {
      _verifyKeys(yamlMap, const {'library', 'class', 'member'});
    } else {
      _verifyKeys(yamlMap, const {'library', 'class'});
    }

    final String librarySpec = yamlMap['library'] as String;
    if (librarySpec.endsWith('*')) {
      // Coverage-ignore-block(suite): Not run.
      _verifyKeys(yamlMap, const {'library'});
      final String prefix = baseUri
          .resolve(librarySpec.substring(0, librarySpec.length - 1))
          .toString();
      final List<Library> libs = component.libraries
          .where((lib) => lib.importUri.toString().startsWith(prefix))
          .toList();
      if (libs.isEmpty) {
        throw 'No libraries found for pattern "$librarySpec"';
      }
      result.addAll(libs);
      return;
    }
    final String libraryUri = baseUri.resolve(librarySpec).toString();

    if (yamlMap.containsKey('class')) {
      final dynamic yamlClassNode = yamlMap['class'];
      if (yamlClassNode is YamlList) {
        // Coverage-ignore-block(suite): Not run.
        _verifyKeys(yamlMap, const {'library', 'class'});
        for (dynamic c in yamlClassNode) {
          result.add(libraryIndex.getClass(libraryUri, c as String));
        }
        return;
      }

      final String classSpec = yamlClassNode as String;

      if (allowMembers && yamlMap.containsKey('member')) {
        final String memberSpec = yamlMap['member'] as String;
        final Member member = libraryIndex.getMember(
          libraryUri,
          classSpec,
          memberSpec,
        );
        _validateSpecifiedMember(
          member,
          allowStaticMembers: allowStaticMembers,
          allowInstanceMembers: allowInstanceMembers,
        );
        result.add(member);
        return;
      }

      result.add(libraryIndex.getClass(libraryUri, classSpec));
      return;
    }

    if (allowMembers && yamlMap.containsKey('member')) {
      final String memberSpec = yamlMap['member'] as String;
      final Member member = libraryIndex.getMember(
        libraryUri,
        '::',
        memberSpec,
      );
      _validateSpecifiedMember(
        member,
        allowStaticMembers: allowStaticMembers,
        allowInstanceMembers: allowInstanceMembers,
      );
      result.add(member);
      return;
    }

    result.add(libraryIndex.getLibrary(libraryUri));
  }

  void _validateSpecifiedMember(
    Member member, {
    required bool allowStaticMembers,
    required bool allowInstanceMembers,
  }) {
    if (member.isInstanceMember) {
      // Coverage-ignore-block(suite): Not run.
      if (!allowInstanceMembers) {
        throw 'Expected non-instance member $member';
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      if (!allowStaticMembers) {
        throw 'Expected instance member $member';
      }
    }
  }
}

/// Recognizes dyn-module:language-impl:* pragmas which can be used
/// to annotate classes and members in core libraries to include
/// them to the dynamic interface automatically.
class DynamicInterfaceLanguageImplPragmas {
  static const String extendablePragmaName =
      "dyn-module:language-impl:extendable";
  static const String canBeOverriddenPragmaName =
      "dyn-module:language-impl:can-be-overridden";
  static const String callablePragmaName = "dyn-module:language-impl:callable";

  final CoreTypes coreTypes;
  DynamicInterfaceLanguageImplPragmas(this.coreTypes);

  bool isPlatformLibrary(Library library) => library.importUri.isScheme('dart');

  bool isExtendable(Class node) =>
      isPlatformLibrary(node.enclosingLibrary) &&
      // Coverage-ignore(suite): Not run.
      isAnnotatedWith(node, extendablePragmaName);

  bool canBeOverridden(Member node) =>
      isPlatformLibrary(node.enclosingLibrary) &&
      // Coverage-ignore(suite): Not run.
      isAnnotatedWith(node, canBeOverriddenPragmaName);

  bool isCallable(TreeNode node) => switch (node) {
    Member() =>
      isPlatformLibrary(node.enclosingLibrary) &&
          // Coverage-ignore(suite): Not run.
          (isAnnotatedWith(node, callablePragmaName) ||
              (!node.name.isPrivate &&
                  node.enclosingClass != null &&
                  isAnnotatedWith(node.enclosingClass!, callablePragmaName))),
    Class() =>
      isPlatformLibrary(node.enclosingLibrary) &&
          // Coverage-ignore(suite): Not run.
          isAnnotatedWith(node, callablePragmaName),
    ExtensionTypeDeclaration() =>
      isPlatformLibrary(node.enclosingLibrary) &&
          // Coverage-ignore(suite): Not run.
          isAnnotatedWith(node, callablePragmaName),
    // Coverage-ignore(suite): Not run.
    Extension() =>
      isPlatformLibrary(node.enclosingLibrary) &&
          isAnnotatedWith(node, callablePragmaName),
    _ => // Coverage-ignore(suite): Not run.
    throw 'Unexpected node ${node.runtimeType} $node',
  };

  // Coverage-ignore(suite): Not run.
  bool isAnnotatedWith(Annotatable node, String pragmaName) {
    for (Expression annotation in node.annotations) {
      if (annotation case ConstantExpression(:var constant)) {
        if (constant case InstanceConstant(
          :var classNode,
          :var fieldValues,
        ) when classNode == coreTypes.pragmaClass) {
          if (fieldValues[coreTypes.pragmaName.fieldReference]
              case StringConstant(:var value) when value == pragmaName) {
            return true;
          }
        }
      }
    }
    return false;
  }
}

class _DynamicModuleValidator extends RecursiveVisitor {
  final DynamicInterfaceSpecification spec;
  final DynamicInterfaceLanguageImplPragmas languageImplPragmas;
  final Set<Library> moduleLibraries;
  final ClassHierarchy hierarchy;
  final SourceLoader loader;
  final Set<Constant> _visitedConstants = new Set<Constant>.identity();

  TreeNode? _enclosingTreeNode;

  _DynamicModuleValidator(
    this.spec,
    this.languageImplPragmas,
    this.moduleLibraries,
    this.hierarchy,
    this.loader,
  ) {
    _expandNodes(spec.callable);
    _expandNodes(spec.extendable);
    _expandNodes(spec.canBeOverridden);
  }

  // Add nodes which do not have direct relation to its logical "parent" node.
  void _expandNodes(Set<TreeNode> nodes) {
    Set<TreeNode> extraNodes = {};
    for (TreeNode node in nodes) {
      _expandNode(node, extraNodes);
    }
    nodes.addAll(extraNodes);
  }

  // Add re-exports of Library and members of ExtensionTypeDeclaration and
  // Extension. These nodes do not have direct relations to their "parents".
  void _expandNode(TreeNode node, Set<TreeNode> extraNodes) {
    switch (node) {
      case Library():
        for (Reference ref in node.additionalExports) {
          TreeNode node = ref.node!;
          extraNodes.add(node);
          _expandNode(node, extraNodes);
        }
        for (ExtensionTypeDeclaration e in node.extensionTypeDeclarations) {
          // Coverage-ignore-block(suite): Not run.
          if (e.name[0] != '_') {
            _expandNode(e, extraNodes);
          }
        }
        for (Extension e in node.extensions) {
          if (e.name[0] != '_') {
            _expandNode(e, extraNodes);
          }
        }
      case ExtensionTypeDeclaration():
        for (ExtensionTypeMemberDescriptor md in node.memberDescriptors) {
          TreeNode? member = md.memberReference?.node;
          if (member != null) {
            extraNodes.add(member);
          }
          TreeNode? tearOff = md.tearOffReference?.node;
          if (tearOff != null) {
            extraNodes.add(tearOff);
          }
        }
      case Extension():
        for (ExtensionMemberDescriptor md in node.memberDescriptors) {
          TreeNode? member = md.memberReference?.node;
          if (member != null) {
            extraNodes.add(member);
          }
          TreeNode? tearOff = md.tearOffReference?.node;
          if (tearOff != null) {
            extraNodes.add(tearOff);
          }
        }
    }
  }

  @override
  void defaultTreeNode(TreeNode node) {
    final TreeNode? savedEnclosingTreeNode = _enclosingTreeNode;
    _enclosingTreeNode = node;
    super.defaultTreeNode(node);
    _enclosingTreeNode = savedEnclosingTreeNode;
  }

  @override
  void visitClass(Class node) {
    // Verify that supers are extendable.
    final Supertype? supertype = node.supertype;
    if (supertype != null) {
      _verifyExtendable(supertype, node);
    }
    final Supertype? mixedInType = node.mixedInType;
    if (mixedInType != null) {
      _verifyExtendable(mixedInType, node);
    }
    for (Supertype implementedType in node.implementedTypes) {
      _verifyExtendable(implementedType, node);
    }
    // Verify overridden members.
    final List<Member> nonSetterImplementationMembers = hierarchy
        .getDispatchTargets(node, setters: false);
    final List<Member> setterImplementationMembers = hierarchy
        .getDispatchTargets(node, setters: true);
    for (Supertype supertype in node.supers) {
      Class superclass = supertype.classNode;
      final List<Member> nonSetterInterfaceMembers = hierarchy
          .getInterfaceMembers(superclass, setters: false);
      final List<Member> setterInterfaceMembers = hierarchy.getInterfaceMembers(
        superclass,
        setters: true,
      );
      _verifyOverrides(
        nonSetterImplementationMembers,
        nonSetterInterfaceMembers,
      );
      _verifyOverrides(setterImplementationMembers, setterInterfaceMembers);
    }
    super.visitClass(node);
  }

  @override
  void visitProcedure(Procedure node) {
    if (node.stubKind == ProcedureStubKind.ConcreteMixinStub) {
      // Do not verify synthetic mixin stubs which are added to
      // a mixin application. These stubs forward calls to mixin
      // methods.
      return;
    }
    super.visitProcedure(node);
  }

  @override
  void visitFunctionNode(FunctionNode node) {
    final RedirectingFactoryTarget? redirectingFactoryTarget =
        node.redirectingFactoryTarget;
    if (redirectingFactoryTarget != null && !redirectingFactoryTarget.isError) {
      _verifyCallable(redirectingFactoryTarget.target!, node);
    }
    super.visitFunctionNode(node);
  }

  @override
  void visitInstanceGet(InstanceGet node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitInstanceGet(node);
  }

  @override
  void visitInstanceTearOff(InstanceTearOff node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitInstanceTearOff(node);
  }

  @override
  void visitInstanceSet(InstanceSet node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitInstanceSet(node);
  }

  @override
  void visitInstanceInvocation(InstanceInvocation node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitInstanceInvocation(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitInstanceGetterInvocation(InstanceGetterInvocation node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitInstanceGetterInvocation(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitEqualsCall(EqualsCall node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitEqualsCall(node);
  }

  @override
  void visitSuperInitializer(SuperInitializer node) {
    _verifyCallable(node.target, node);
    super.visitSuperInitializer(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitSuperPropertyGet(SuperPropertyGet node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitSuperPropertyGet(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitSuperPropertySet(SuperPropertySet node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitSuperPropertySet(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitSuperMethodInvocation(SuperMethodInvocation node) {
    _verifyCallable(node.interfaceTarget, node);
    super.visitSuperMethodInvocation(node);
  }

  @override
  void visitStaticGet(StaticGet node) {
    _verifyCallable(node.target, node);
    super.visitStaticGet(node);
  }

  @override
  void visitStaticTearOff(StaticTearOff node) {
    _verifyCallable(node.target, node);
    super.visitStaticTearOff(node);
  }

  @override
  void visitStaticSet(StaticSet node) {
    _verifyCallable(node.target, node);
    super.visitStaticSet(node);
  }

  @override
  void visitStaticInvocation(StaticInvocation node) {
    _verifyCallable(node.target, node);
    super.visitStaticInvocation(node);
  }

  @override
  void visitConstructorInvocation(ConstructorInvocation node) {
    _verifyCallable(node.target, node);
    super.visitConstructorInvocation(node);
  }

  @override
  void visitConstructorTearOff(ConstructorTearOff node) {
    _verifyCallable(node.target, node);
    super.visitConstructorTearOff(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    _verifyCallable(node.target, node);
    super.visitRedirectingFactoryTearOff(node);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    _dynamicCall(node);
    super.visitDynamicGet(node);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    _dynamicCall(node);
    super.visitDynamicSet(node);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    _dynamicCall(node);
    super.visitDynamicInvocation(node);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    if (node.accessKind == RelationalAccessKind.Dynamic) {
      _dynamicCall(node);
    }
    super.visitRelationalPattern(node);
  }

  @override
  void visitNamedPattern(NamedPattern node) {
    if (node.accessKind == ObjectAccessKind.Dynamic) {
      _dynamicCall(node);
    }
    super.visitNamedPattern(node);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    _verifyCallable(node.classNode, _enclosingTreeNode!);
    super.visitInterfaceType(node);
  }

  @override
  void visitExtensionType(ExtensionType node) {
    _verifyCallable(node.extensionTypeDeclaration, _enclosingTreeNode!);
    super.visitExtensionType(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitAbstractSuperPropertyGet(AbstractSuperPropertyGet node) =>
      throw 'Unexpected node ${node.runtimeType} $node';

  @override
  // Coverage-ignore(suite): Not run.
  void visitAbstractSuperPropertySet(AbstractSuperPropertySet node) =>
      throw 'Unexpected node ${node.runtimeType} $node';

  @override
  // Coverage-ignore(suite): Not run.
  void visitAbstractSuperMethodInvocation(AbstractSuperMethodInvocation node) =>
      throw 'Unexpected node ${node.runtimeType} $node';

  @override
  // Coverage-ignore(suite): Not run.
  void visitInstanceCreation(InstanceCreation node) =>
      throw 'Unexpected node ${node.runtimeType} $node';

  @override
  void defaultConstantReference(Constant node) {
    if (_visitedConstants.add(node)) {
      node.visitChildren(this);
    }
  }

  @override
  void visitInstanceConstantReference(InstanceConstant node) {
    _verifyCallable(node.classNode, _enclosingTreeNode!);
    super.visitInstanceConstantReference(node);
  }

  @override
  void visitStaticTearOffConstantReference(StaticTearOffConstant node) {
    _verifyCallable(node.target, _enclosingTreeNode!);
    super.visitStaticTearOffConstantReference(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitConstructorTearOffConstantReference(
    ConstructorTearOffConstant node,
  ) {
    _verifyCallable(node.target, _enclosingTreeNode!);
    super.visitConstructorTearOffConstantReference(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitRedirectingFactoryTearOffConstantReference(
    RedirectingFactoryTearOffConstant node,
  ) {
    _verifyCallable(node.target, _enclosingTreeNode!);
    super.visitRedirectingFactoryTearOffConstantReference(node);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitTypedefTearOffConstantReference(TypedefTearOffConstant node) =>
      throw 'Unexpected node ${node.runtimeType} $node';

  void _dynamicCall(TreeNode node) {
    loader.addProblem(
      codeDynamicCallsAreNotAllowedInDynamicModule,
      node.fileOffset,
      noLength,
      node.location!.file,
    );
  }

  void _verifyCallable(TreeNode target, TreeNode node) {
    if (target is Procedure) {
      target = _unwrapMixinStubs(target);
    }
    if (target is Member) {
      target = _unwrapMixinCopy(target);
    }
    if (!_isFromDynamicModule(target) &&
        !_isSpecified(target, spec.callable) &&
        !languageImplPragmas.isCallable(target)) {
      switch (target) {
        case Constructor():
          String name = target.enclosingClass.name;
          if (target.name.text.isNotEmpty) {
            name += '.' + target.name.text;
          }
          loader.addProblem(
            codeConstructorShouldBeListedAsCallableInDynamicInterface
                .withArgumentsOld(name),
            node.fileOffset,
            noLength,
            node.location!.file,
          );
        case Member():
          final Class? cls = target.enclosingClass;
          String name;
          if (cls != null) {
            name = '${cls.name}.${target.name.text}';
          } else {
            name = target.name.text;
            if (target.isExtensionMember || target.isExtensionTypeMember) {
              name = extractQualifiedNameFromExtensionMethodName(name)!;
            }
          }
          loader.addProblem(
            codeMemberShouldBeListedAsCallableInDynamicInterface
                .withArgumentsOld(name),
            node.fileOffset,
            noLength,
            node.location!.file,
          );
        case Class():
          loader.addProblem(
            codeClassShouldBeListedAsCallableInDynamicInterface
                .withArgumentsOld(target.name),
            node.fileOffset,
            noLength,
            node.location!.file,
          );
        case ExtensionTypeDeclaration():
          loader.addProblem(
            codeExtensionTypeShouldBeListedAsCallableInDynamicInterface
                .withArgumentsOld(target.name),
            node.fileOffset,
            noLength,
            node.location!.file,
          );
        // Coverage-ignore(suite): Not run.
        case _:
          throw 'Unexpected node ${node.runtimeType} $node';
      }
    }
  }

  void _verifyExtendable(Supertype base, Class node) {
    final Class baseClass = base.classNode;
    if (!_isFromDynamicModule(baseClass) &&
        !_isSpecified(baseClass, spec.extendable) &&
        !languageImplPragmas.isExtendable(baseClass)) {
      loader.addProblem(
        codeClassShouldBeListedAsExtendableInDynamicInterface.withArgumentsOld(
          baseClass.name,
        ),
        node.fileOffset,
        noLength,
        node.location!.file,
      );
    }
  }

  // Unwrap synthetic mixin stubs to get actual implementation member.
  Member _unwrapMixinStubs(Member member) {
    if (member is Procedure &&
        member.stubKind == ProcedureStubKind.ConcreteMixinStub) {
      return _unwrapMixinStubs(member.stubTarget!);
    }
    return member;
  }

  // Unwrap copied method from an eliminated mixin to get actual
  // interface member.
  Member _unwrapMixinCopy(Member member) {
    if (!member.isInstanceMember) {
      return member;
    }
    Class enclosingClass = member.enclosingClass!;
    if (!enclosingClass.isEliminatedMixin) {
      return member;
    }
    // Coverage-ignore-block(suite): Not run.
    Class origin = enclosingClass.implementedTypes.last.classNode;
    return hierarchy.getInterfaceMember(
      origin,
      member.name,
      setter: member is Procedure && member.isSetter,
    )!;
  }

  void _verifyOverrides(
    List<Member> implementationMembers,
    List<Member> interfaceMembers,
  ) {
    int i = 0, j = 0;
    while (i < implementationMembers.length && j < interfaceMembers.length) {
      Member impl = _unwrapMixinStubs(implementationMembers[i]);
      Member interfaceMember = interfaceMembers[j];
      int comparison = ClassHierarchy.compareMembers(impl, interfaceMember);
      if (comparison < 0) {
        ++i;
      } else if (comparison > 0) {
        // Coverage-ignore-block(suite): Not run.
        ++j;
      } else {
        if (!identical(impl, interfaceMember)) {
          _verifyOverride(impl, interfaceMember);
        }
        // A given implementation member may override multiple interface
        // members, so only move past the interface member.
        ++j;
      }
    }
  }

  void _verifyOverride(Member ownMember, Member superMember) {
    superMember = _unwrapMixinCopy(superMember);
    if (!_isFromDynamicModule(superMember) &&
        !_isSpecified(superMember, spec.canBeOverridden) &&
        !languageImplPragmas.canBeOverridden(superMember)) {
      loader.addProblem(
        codeMemberShouldBeListedAsCanBeOverriddenInDynamicInterface
            .withArgumentsOld(
              superMember.enclosingClass!.name,
              superMember.name.text,
            ),
        ownMember.fileOffset,
        noLength,
        ownMember.location!.file,
      );
    }
  }

  bool _isFromDynamicModule(TreeNode node) =>
      moduleLibraries.contains(_enclosingLibrary(node));

  Library _enclosingLibrary(TreeNode node) => switch (node) {
    Member() => node.enclosingLibrary,
    Class() => node.enclosingLibrary,
    ExtensionTypeDeclaration() => node.enclosingLibrary,
    // Coverage-ignore(suite): Not run.
    Library() => node,
    _ => // Coverage-ignore(suite): Not run.
    throw 'Unexpected node ${node.runtimeType} $node',
  };

  bool _isSpecified(TreeNode node, Set<TreeNode> specified) =>
      specified.contains(node) ||
      switch (node) {
        Member() =>
          !node.name.isPrivate && _isSpecified(node.parent!, specified),
        Class() =>
          node.name[0] != '_' && _isSpecified(node.enclosingLibrary, specified),
        ExtensionTypeDeclaration() =>
          node.name[0] != '_' && _isSpecified(node.enclosingLibrary, specified),
        Library() => false,
        // Coverage-ignore(suite): Not run.
        _ => throw 'Unexpected node ${node.runtimeType} $node',
      };
}
