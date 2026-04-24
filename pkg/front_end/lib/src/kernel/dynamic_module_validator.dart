// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:front_end/src/codes/diagnostic.dart' as diag;
import 'package:kernel/ast.dart';
import 'package:kernel/class_hierarchy.dart' show ClassHierarchy;
import 'package:kernel/core_types.dart' show CoreTypes;
import 'package:kernel/library_index.dart' show LibraryIndex;
import 'package:kernel/names.dart' show noSuchMethodName;
import 'package:yaml/yaml.dart';
import '../source/source_loader.dart' show SourceLoader;
import '../api_prototype/lowering_predicates.dart'
    show extractQualifiedNameFromExtensionMethodName;

import '../codes/cfe_codes.dart' show noLength;

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
  SourceLoader loader, {
  bool allowDynamicCallsInDynamicModules = false,
  List<String> dynamicCallsSelectorAllowList = const [],
}) {
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
    allowDynamicCallsInDynamicModules: allowDynamicCallsInDynamicModules,
    dynamicCallsSelectorAllowList: dynamicCallsSelectorAllowList,
  );
  for (Library library in libraries) {
    library.accept(validator);
  }
}

extension on YamlMap {
  void verifyKeys(Set<String> allowedKeys) {
    for (dynamic k in keys) {
      if (!allowedKeys.contains(k.toString())) {
        // Coverage-ignore-block(suite): Not run.
        throw 'Unexpected key "$k" in dynamic interface specification';
      }
    }
  }
}

/// Loaded contents of dynamic interface specification yaml file.
class DynamicInterfaceYamlFile {
  final YamlNode _root;

  DynamicInterfaceYamlFile(String contents) : _root = loadYamlNode(contents) {
    if (!isEmpty) {
      sections.verifyKeys(const {
        'extendable',
        'can-be-overridden',
        'callable',
        'can-be-used-as-type',
        'dynamically-callable',
      });
    }
  }

  bool get isEmpty => _root is! YamlMap;

  YamlMap get sections => _root as YamlMap;

  YamlList? get extendable => sections['extendable'];
  YamlList? get canBeOverridden => sections['can-be-overridden'];
  YamlList? get callable => sections['callable'];
  YamlList? get canBeUsedAsType => sections['can-be-used-as-type'];
  YamlList? get dynamicallyCallable => sections['dynamically-callable'];

  // Coverage-ignore(suite): Not run.
  Set<String> get libraries => {
    for (YamlList section in [
      ?extendable,
      ?canBeOverridden,
      ?callable,
      ?canBeUsedAsType,
    ])
      for (YamlNode item in section) (item as YamlMap)['library'] as String,
  };

  // Coverage-ignore(suite): Not run.
  Iterable<Uri> getUserLibraryUris(Uri baseUri) => libraries
      .where((String lib) => !lib.startsWith('dart:'))
      .map((String lib) => baseUri.resolve(lib));
}

/// Parsed dynamic interface specification yaml file.
class DynamicInterfaceSpecification {
  // Specified Library, Class and Member nodes.
  final Set<TreeNode> extendable = {};
  final Set<TreeNode> canBeOverridden = {};
  final Set<TreeNode> callable = {};
  final Set<TreeNode> canBeUsedAsType = {};
  final Set<TreeNode> dynamicallyCallable = {};

  factory DynamicInterfaceSpecification(
    String dynamicInterfaceSpecification,
    Uri baseUri,
    Component component,
  ) => new DynamicInterfaceSpecification.fromYamlFile(
    new DynamicInterfaceYamlFile(dynamicInterfaceSpecification),
    baseUri,
    component,
  );

  DynamicInterfaceSpecification.fromYamlFile(
    DynamicInterfaceYamlFile yamlFile,
    Uri baseUri,
    Component component,
  ) {
    if (yamlFile.isEmpty) {
      return;
    }

    final LibraryIndex libraryIndex = new LibraryIndex.all(component);

    _parseList(
      yamlFile.extendable,
      extendable,
      baseUri,
      component,
      libraryIndex,
      allowStaticDeclarations: false,
      allowInstanceMembers: false,
    );

    _parseList(
      yamlFile.canBeOverridden,
      canBeOverridden,
      baseUri,
      component,
      libraryIndex,
      allowStaticDeclarations: false,
      allowInstanceMembers: true,
    );

    _parseList(
      yamlFile.callable,
      callable,
      baseUri,
      component,
      libraryIndex,
      allowStaticDeclarations: true,
      allowInstanceMembers: true,
    );

    _parseList(
      yamlFile.canBeUsedAsType,
      canBeUsedAsType,
      baseUri,
      component,
      libraryIndex,
      allowStaticDeclarations: false,
      allowInstanceMembers: false,
    );

    _parseList(
      yamlFile.dynamicallyCallable,
      dynamicallyCallable,
      baseUri,
      component,
      libraryIndex,
      allowStaticDeclarations: false,
      allowInstanceMembers: true,
    );
  }

  void _parseList(
    YamlList? items,
    Set<TreeNode> result,
    Uri baseUri,
    Component component,
    LibraryIndex libraryIndex, {
    required bool allowStaticDeclarations,
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
          allowStaticDeclarations: allowStaticDeclarations,
          allowInstanceMembers: allowInstanceMembers,
        );
      }
    }
  }

  void findNodes(
    YamlNode yamlNode,
    Set<TreeNode> result,
    Uri baseUri,
    LibraryIndex libraryIndex,
    Component component, {
    // Allow extension types, extensions, or static members.
    required bool allowStaticDeclarations,
    required bool allowInstanceMembers,
  }) {
    final YamlMap yamlMap = yamlNode as YamlMap;
    final bool allowMembers = allowStaticDeclarations || allowInstanceMembers;
    final Set<String> keys;
    if (allowStaticDeclarations) {
      keys = const {
        'library',
        'class',
        'extension_type',
        'extension',
        'member',
      };
    } else if (allowMembers) {
      keys = const {'library', 'class', 'member'};
    } else {
      keys = const {'library', 'class', 'extension_type'};
    }
    yamlMap.verifyKeys(keys);

    final String librarySpec = yamlMap['library'] as String;
    final String libraryUri = baseUri.resolve(librarySpec).toString();

    if (yamlMap.containsKey('extension_type')) {
      final dynamic yamlExtensionNode = yamlMap['extension_type'];
      if (yamlExtensionNode is YamlList) {
        yamlMap.verifyKeys(const {'library', 'extension_type'});
        for (dynamic c in yamlExtensionNode) {
          result.add(libraryIndex.getExtensionType(libraryUri, c as String));
        }
        return;
      }

      final String extensionSpec = yamlExtensionNode as String;

      if (allowMembers && yamlMap.containsKey('member')) {
        final String memberSpec = yamlMap['member'] as String;
        final Member member = libraryIndex.getMember(
          libraryUri,
          extensionSpec,
          memberSpec,
        );
        _validateSpecifiedMember(
          member,
          allowStaticMembers: allowStaticDeclarations,
          allowInstanceMembers: allowInstanceMembers,
        );
        result.add(member);
        return;
      }

      result.add(libraryIndex.getExtensionType(libraryUri, extensionSpec));
      return;
    }

    if (yamlMap.containsKey('extension')) {
      final dynamic yamlExtensionNode = yamlMap['extension'];
      if (yamlExtensionNode is YamlList) {
        yamlMap.verifyKeys(const {'library', 'extension'});
        for (dynamic c in yamlExtensionNode) {
          result.add(libraryIndex.getExtension(libraryUri, c as String));
        }
        return;
      }

      final String extensionSpec = yamlExtensionNode as String;

      if (allowMembers && yamlMap.containsKey('member')) {
        final String memberSpec = yamlMap['member'] as String;
        final Member member = libraryIndex.getMember(
          libraryUri,
          extensionSpec,
          memberSpec,
        );
        _validateSpecifiedMember(
          member,
          allowStaticMembers: allowStaticDeclarations,
          allowInstanceMembers: allowInstanceMembers,
        );
        result.add(member);
        return;
      }

      result.add(libraryIndex.getExtension(libraryUri, extensionSpec));
      return;
    }

    if (yamlMap.containsKey('class')) {
      final dynamic yamlClassNode = yamlMap['class'];
      if (yamlClassNode is YamlList) {
        yamlMap.verifyKeys(const {'library', 'class'});
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
          allowStaticMembers: allowStaticDeclarations,
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
        allowStaticMembers: allowStaticDeclarations,
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
  static const String canBeUsedAsTypePragmaName =
      "dyn-module:language-impl:can-be-used-as-type";

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

  bool canBeUsedAsType(TreeNode node) => switch (node) {
    Class() =>
      isPlatformLibrary(node.enclosingLibrary) &&
          isAnnotatedWith(node, canBeUsedAsTypePragmaName),
    ExtensionTypeDeclaration() =>
      isPlatformLibrary(node.enclosingLibrary) &&
          // Coverage-ignore(suite): Not run.
          isAnnotatedWith(node, canBeUsedAsTypePragmaName),
    _ => // Coverage-ignore(suite): Not run.
    throw 'Unexpected node ${node.runtimeType} $node',
  };

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
  final bool allowDynamicCallsInDynamicModules;
  final Set<Constant> _visitedConstants = new Set<Constant>.identity();
  late final _DynamicCallValidator _dynamicCallValidator;

  TreeNode? _enclosingTreeNode;

  _DynamicModuleValidator(
    this.spec,
    this.languageImplPragmas,
    this.moduleLibraries,
    this.hierarchy,
    this.loader, {
    this.allowDynamicCallsInDynamicModules = false,
    List<String> dynamicCallsSelectorAllowList = const [],
  }) {
    _expandNodes(spec.callable);
    _expandNodes(spec.extendable);
    _expandNodes(spec.canBeOverridden);
    _expandNodes(spec.canBeUsedAsType);
    _expandNodes(spec.dynamicallyCallable);
    _dynamicCallValidator = new _DynamicCallValidator(
      this,
      dynamicCallsSelectorAllowList,
    )..run();
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

    _verifyDynamicallyCallableClass(node);
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
  void visitRedirectingFactoryInvocation(RedirectingFactoryInvocation node) {
    _verifyCallable(node.redirectingFactoryTarget, node);
    // Do not visit node.expression in order to avoid checking
    // that target of a redirecting factory is callable.
    // However, still visit children of node.expression to validate arguments.
    final InvocationExpression expr = node.expression;
    assert(expr is ConstructorInvocation || expr is StaticInvocation);
    expr.visitChildren(this);
  }

  @override
  // Coverage-ignore(suite): Not run.
  void visitRedirectingFactoryTearOff(RedirectingFactoryTearOff node) {
    _verifyCallable(node.target, node);
    super.visitRedirectingFactoryTearOff(node);
  }

  @override
  void visitDynamicGet(DynamicGet node) {
    _verifyDynamicallyCallable(new _Selector(.PropertyGet, node.name), node);
    super.visitDynamicGet(node);
  }

  @override
  void visitDynamicSet(DynamicSet node) {
    _verifyDynamicallyCallable(new _Selector(.PropertySet, node.name), node);
    super.visitDynamicSet(node);
  }

  @override
  void visitDynamicInvocation(DynamicInvocation node) {
    _verifyDynamicallyCallable(new _Selector(.Method, node.name), node);
    super.visitDynamicInvocation(node);
  }

  @override
  void visitRelationalPattern(RelationalPattern node) {
    if (node.accessKind == RelationalAccessKind.Dynamic) {
      _verifyDynamicallyCallable(new _Selector(.Method, node.name!), node);
    }
    super.visitRelationalPattern(node);
  }

  @override
  void visitNamedPattern(NamedPattern node) {
    if (node.accessKind == ObjectAccessKind.Dynamic) {
      _verifyDynamicallyCallable(
        new _Selector(.PropertyGet, node.fieldName),
        node,
      );
    }
    super.visitNamedPattern(node);
  }

  @override
  void visitInterfaceType(InterfaceType node) {
    _verifyCanBeUsedAsType(node.classNode, _enclosingTreeNode!);
    super.visitInterfaceType(node);
  }

  @override
  void visitExtensionType(ExtensionType node) {
    _verifyCanBeUsedAsType(node.extensionTypeDeclaration, _enclosingTreeNode!);
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

  bool _warningEmitted = false;
  void _verifyDynamicallyCallable(_Selector selector, TreeNode node) {
    if (allowDynamicCallsInDynamicModules) {
      if (!_warningEmitted) {
        _warningEmitted = true;
        loader.addProblem(
          diag.dynamicCallsAreDiscouragedInDynamicModules,
          TreeNode.noOffset,
          noLength,
          node.location!.file,
        );
      }

      if (!_dynamicCallValidator.isAllowed(selector)) {
        loader.addProblem(
          diag.dynamicCallsAreNotAllowedInDynamicModule.withArguments(
            name: selector.diagnosticName,
          ),
          node.fileOffset,
          noLength,
          node.location!.file,
        );
      }
    } else {
      // Coverage-ignore-block(suite): Not run.
      loader.addProblem(
        diag.dynamicCallsAreDisallowedByDefault,
        node.fileOffset,
        noLength,
        node.location!.file,
      );
    }
  }

  void _verifyCanBeUsedAsType(TreeNode target, TreeNode node) {
    if (!_isFromDynamicModule(target) &&
        !_isSpecified(target, spec.canBeUsedAsType) &&
        !languageImplPragmas.canBeUsedAsType(target) &&
        !_isSpecified(target, spec.callable) &&
        !languageImplPragmas.isCallable(target)) {
      switch (target) {
        case Class():
          loader.addProblem(
            diag.classShouldBeListedAsCanBeUsedAsTypeInDynamicInterface
                .withArguments(name: target.name),
            node.fileOffset,
            noLength,
            node.location!.file,
          );
        case ExtensionTypeDeclaration():
          loader.addProblem(
            diag.extensionTypeShouldBeListedAsCanBeUsedAsTypeInDynamicInterface
                .withArguments(name: target.name),
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

  void _verifyCallable(TreeNode target, TreeNode node) {
    if (target is Member) {
      target = _unwrapMember(target);
    }
    if (!_isFromDynamicModule(target) &&
        !_isSpecified(target, spec.callable) &&
        !languageImplPragmas.isCallable(target)) {
      switch (target) {
        case Constructor():
          String name = target.enclosingClass.name;
          if (target.name.text.isNotEmpty) {
            // Coverage-ignore-block(suite): Not run.
            name += '.' + target.name.text;
          }
          loader.addProblem(
            diag.constructorShouldBeListedAsCallableInDynamicInterface
                .withArguments(name: name),
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
            diag.memberShouldBeListedAsCallableInDynamicInterface.withArguments(
              name: name,
            ),
            node.fileOffset,
            noLength,
            node.location!.file,
          );
        case Class():
          loader.addProblem(
            diag.classShouldBeListedAsCallableInDynamicInterface.withArguments(
              name: target.name,
            ),
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
        diag.classShouldBeListedAsExtendableInDynamicInterface.withArguments(
          name: baseClass.name,
        ),
        node.fileOffset,
        noLength,
        node.location!.file,
      );
    }
  }

  // Verify that any subtype of dynamically-callable classes don't define or
  // inherit a `noSuchMethod` override:
  void _verifyDynamicallyCallableClass(Class node) {
    if (!_dynamicCallValidator._hasUserNoSuchMethod(node)) return;
    Class? result = _dynamicCallValidator.getDynamicallyCallableSupertype(node);
    if (result == null) return;
    loader.addProblem(
      diag.dynamicallyCallableWithNoSuchMethodDynamicSubtype.withArguments(
        name: result.name,
        subtype: node.name,
      ),
      node.fileOffset,
      noLength,
      node.location!.file,
    );
  }

  // Unwrap synthetic stubs to get actual member.
  Member _unwrapStubs(Member member) {
    if (member is Procedure) {
      switch (member.stubKind) {
        case ProcedureStubKind.ConcreteForwardingStub:
        case ProcedureStubKind.ConcreteMixinStub:
        case ProcedureStubKind.MemberSignature:
          return _unwrapStubs(member.stubTarget!);
        default:
          break;
      }
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

  Member _unwrapMember(Member member) => _unwrapMixinCopy(_unwrapStubs(member));

  void _verifyOverrides(
    List<Member> implementationMembers,
    List<Member> interfaceMembers,
  ) {
    int i = 0, j = 0;
    while (i < implementationMembers.length && j < interfaceMembers.length) {
      Member impl = _unwrapMember(implementationMembers[i]);
      Member interfaceMember = _unwrapMember(interfaceMembers[j]);
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
    if (!_isFromDynamicModule(superMember) &&
        !_isSpecified(superMember, spec.canBeOverridden) &&
        !languageImplPragmas.canBeOverridden(superMember)) {
      loader.addProblem(
        diag.memberShouldBeListedAsCanBeOverriddenInDynamicInterface
            .withArguments(
              className: superMember.enclosingClass!.name,
              memberName: superMember.name.text,
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
        _ => // Coverage-ignore(suite): Not run.
        throw 'Unexpected node ${node.runtimeType} $node',
      };
}

/// Performs preparation work required before
/// [_DynamicModulesValidator] visits the dynamic module.
///
/// Currently this includes:
/// * Ensuring names of members exposed dynamically are registered. The
///   registered names will be used while validating dynamic call nodes later.
/// * Check for invalid exposed nodes because of classes implementing
///   `noSuchMethod`. Both classes in the dynamic interface and their subtypes
///   in the host app.
class _DynamicCallValidator {
  final _DynamicModuleValidator validator;
  final Set<_Selector> _dynamicallyCallable = {};
  final Set<Class> classesExposedDynamically = {};
  DynamicInterfaceSpecification get spec => validator.spec;

  _DynamicCallValidator(
    this.validator,
    List<String> dynamicCallsSelectorAllowList,
  ) {
    for (final String descriptor in dynamicCallsSelectorAllowList) {
      List<String> split = descriptor.split(':');
      if (split.length == 1) {
        if (descriptor.startsWith('_')) {
          // Coverage-ignore(suite): Not run.
          throw "Unexpected selector name in descriptor '$descriptor': "
              "private descriptors are not supported.";
        }
        final Name name = new Name(descriptor);
        _dynamicallyCallable.add(new _Selector(.Method, name));
        _dynamicallyCallable.add(new _Selector(.PropertyGet, name));
      } else if (split.length > 2) {
        // Coverage-ignore(suite): Not run.
        throw "Unexpected selector descriptor '$descriptor'.";
      } else {
        final String kindString = split[0];
        final String nameString = split[1];
        _SelectorKind kind = switch (kindString) {
          'get' => .PropertyGet,
          'set' => .PropertySet,
          _ => // Coverage-ignore(suite): Not run.
          throw "Unexpected selector descriptor kind in '$descriptor'.",
        };
        if (nameString.startsWith('_')) {
          // Coverage-ignore(suite): Not run.
          throw "Unexpected selector name in descriptor '$descriptor': "
              "private descriptors are not supported.";
        }
        final Name name = new Name(nameString);
        _dynamicallyCallable.add(new _Selector(kind, name));
      }
    }
  }

  /// Whether [selectorName] should be allowed in a dynamic module.
  bool isAllowed(_Selector selector) => _dynamicallyCallable.contains(selector);

  /// Registers exposed selectors based on [spec] and validates classes in
  /// [component] to ensure dynamically callable classes cannot directly or
  /// indirectly override `noSuchMethod`.
  void run() {
    if (spec.dynamicallyCallable.isEmpty) return;

    for (TreeNode node in spec.dynamicallyCallable) {
      if (node is Member) {
        checkExposedClass(node.enclosingClass!, node);
        registerSelectorName(node);
      } else if (node is Class) {
        checkExposedClass(node, node);
        registerClassMembers(node);
      } else {
        for (Class c in (node as Library).classes) {
          checkExposedClass(c, c);
          registerClassMembers(c);
        }
      }
    }
  }

  /// Registers the implicit selector name of [node] in the the allow-list of
  /// dynamically callable selectors.
  void registerSelectorName(Member node) {
    if (!node.isInstanceMember) return;
    switch (node) {
      case Field():
        _dynamicallyCallable.add(new _Selector(.PropertyGet, node.name));
        if (node.hasSetter) {
          _dynamicallyCallable.add(new _Selector(.PropertySet, node.name));
        }
      case Procedure() when node.isGetter:
        _dynamicallyCallable.add(new _Selector(.PropertyGet, node.name));
      case Procedure() when node.isSetter:
        _dynamicallyCallable.add(new _Selector(.PropertySet, node.name));
      case _:
        _dynamicallyCallable.add(new _Selector(.Method, node.name));
        _dynamicallyCallable.add(new _Selector(.PropertyGet, node.name));
    }
  }

  /// Registers the implicit selectors from all members defined in [cls].
  void registerClassMembers(Class cls) {
    for (Procedure p in cls.procedures) {
      registerSelectorName(p);
    }
    for (Field f in cls.fields) {
      registerSelectorName(f);
    }
  }

  /// Checks that [cls] doesn't contain a `noSuchMethod` override.
  ///
  // TODO(sigmund): perform this check only when compiling the host app.
  // TODO(sigmund): check subtypes of dynamically-callable classes defined in
  // the host.
  void checkExposedClass(Class cls, TreeNode node) {
    if (!classesExposedDynamically.add(cls)) return;
    bool result = _hasUserNoSuchMethod(cls);
    if (result) {
      validator.loader.addProblem(
        diag.dynamicallyCallableWithNoSuchMethod.withArguments(name: cls.name),
        // TODO(sigmund): consider reporting an offset in the
        // dynamic_interface.yaml file instead.
        node.fileOffset,
        noLength,
        node.location!.file,
      );
    }
  }

  /// Searches whether a supertype of [cls] is exposed as
  /// `dynamically-callable`. If so, return the first such supertype, otherwise
  /// return `null`.
  Class? getDynamicallyCallableSupertype(Class? cls) {
    if (cls == null) return null;
    if (classesExposedDynamically.contains(cls)) return cls;
    Class? result = getDynamicallyCallableSupertype(cls.superclass);
    if (result != null) return result;
    for (Supertype type in cls.implementedTypes) {
      Class? found = getDynamicallyCallableSupertype(type.classNode);
      if (found != null) return found;
    }
    return null;
  }

  /// Whether [cls] defines or inherits a user `noSuchMethod` definition.
  bool _hasUserNoSuchMethod(Class cls) {
    // Note: we don't use `hierarchy.getInterfaceMember(cls, noSuchMethodName)`
    // because [hierarchy] only indexes code reachable from the dynamic
    // module and excludes the rest of the host libraries.
    if (cls == validator.hierarchy.coreTypes.objectClass) return false;
    if (cls.procedures.any((p) => p.name == noSuchMethodName)) {
      return true;
    }
    return _hasUserNoSuchMethod(cls.superclass!);
  }
}

enum _SelectorKind { Method, PropertyGet, PropertySet }

class _Selector {
  final _SelectorKind kind;
  final Name name;

  _Selector(this.kind, this.name);

  String get _prefix => switch (kind) {
    .Method => '',
    .PropertyGet => 'get:',
    .PropertySet => 'set:',
  };

  String get diagnosticName => '$_prefix${name.text}';

  @override
  bool operator ==(other) =>
      other is _Selector && kind == other.kind && name == other.name;

  @override
  int get hashCode => Object.hash(kind, name);
}
