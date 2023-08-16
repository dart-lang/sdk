// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../ast.dart';
import 'coverage.dart';

/// Helper class used to generate ASTs that contain all different nodes.
class NodeCreator {
  final Uri _uri;

  /// File offset counter.
  ///
  /// Used to generate distinct file offsets through [_needFileOffset].
  int _fileOffset = 0;

  /// The parent [Component] for all created libraries, classes, extensions,
  /// typedefs and members.
  final Component _component = new Component();

  /// These fields contain maps of requested nodes different kinds that are
  /// still pending. The mapped values are used to track how many nodes of the
  /// specific kind have been created. When all variants of a kind have been
  /// created, the entry is removed from the map.
  final Map<ExpressionKind, int> _pendingExpressions;
  final Map<StatementKind, int> _pendingStatements;
  final Map<DartTypeKind, int> _pendingDartTypes;
  final Map<ConstantKind, int> _pendingConstants;
  final Map<PatternKind, int> _pendingPatterns;
  final Map<InitializerKind, int> _pendingInitializers;
  final Map<MemberKind, int> _pendingMembers;
  final Map<NodeKind, int> _pendingNodes;

  /// The set of all kinds of nodes created by this node creator.
  final Set<Object> _createdKinds = {};

  /// These fields contain list of nodes needed for the creation of other nodes.
  ///
  /// Needed nodes are nodes that need to exist prior to the node that required
  /// it. For instance, to create an [InterfaceType] node, a [Class] node must
  /// exist for the [InterfaceType] to reference.
  ///
  /// Needed nodes are added to the context of the created nodes. For instance,
  /// a needed [Class] is added to the [_component] and a needed
  /// [VariableDeclaration] is added to a enclosing [Block].
  List<Library> _neededLibraries = [];
  List<Class> _neededClasses = [];
  List<ExtensionTypeDeclaration> _neededExtensionTypeDeclarations = [];
  List<Typedef> _neededTypedefs = [];
  List<TypeParameter> _neededTypeParameters = [];
  List<Constructor> _neededConstructors = [];
  List<Procedure> _neededRedirectingFactories = [];
  List<Procedure> _neededProcedures = [];
  List<Field> _neededFields = [];
  List<LibraryDependency> _neededLibraryDependencies = [];
  List<VariableDeclaration> _neededVariableDeclarations = [];
  List<LabeledStatement> _neededLabeledStatements = [];
  List<FunctionDeclaration> _neededFunctionDeclarations = [];
  List<SwitchCase> _neededSwitchCases = [];

  /// Creates a [NodeCreator] requested to create nodes of the specified kinds.
  NodeCreator({
    Iterable<ExpressionKind> expressions = ExpressionKind.values,
    Iterable<StatementKind> statements = StatementKind.values,
    Iterable<DartTypeKind> dartTypes = DartTypeKind.values,
    Iterable<ConstantKind> constants = ConstantKind.values,
    Iterable<PatternKind> patterns = PatternKind.values,
    Iterable<InitializerKind> initializers = InitializerKind.values,
    Iterable<MemberKind> members = MemberKind.values,
    Iterable<NodeKind> nodes = NodeKind.values,
  })  : _pendingExpressions = new Map<ExpressionKind, int>.fromIterables(
            expressions, new List<int>.filled(expressions.length, 0)),
        _pendingStatements = new Map<StatementKind, int>.fromIterables(
            statements, new List<int>.filled(statements.length, 0)),
        _pendingDartTypes = new Map<DartTypeKind, int>.fromIterables(
            dartTypes, new List<int>.filled(dartTypes.length, 0)),
        _pendingConstants = new Map<ConstantKind, int>.fromIterables(
            constants, new List<int>.filled(constants.length, 0)),
        _pendingPatterns = new Map<PatternKind, int>.fromIterables(
            patterns, new List<int>.filled(patterns.length, 0)),
        _pendingInitializers = new Map<InitializerKind, int>.fromIterables(
            initializers, new List<int>.filled(initializers.length, 0)),
        _pendingMembers = new Map<MemberKind, int>.fromIterables(
            members, new List<int>.filled(members.length, 0)),
        _pendingNodes = new Map<NodeKind, int>.fromIterables(
            nodes, new List<int>.filled(nodes.length, 0)),
        _uri = Uri.parse('test:uri') {
    _createdKinds.addAll(_pendingExpressions.keys);
    _createdKinds.addAll(_pendingStatements.keys);
    _createdKinds.addAll(_pendingDartTypes.keys);
    _createdKinds.addAll(_pendingInitializers.keys);
    _createdKinds.addAll(_pendingMembers.keys);
    _createdKinds.addAll(_pendingNodes.keys);
  }

  /// The kinds created by this node creator.
  Iterable<Object> get createdKinds => _createdKinds;

  /// Wraps [statement] in nodes needed in the statement context.
  ///
  /// For instance, if a [LabeledStatement] was needed for the creation of
  /// [statement], [statement] is wrapped inside the labeled statement.
  Statement _ensureContext(Statement statement) {
    if (_neededSwitchCases.isNotEmpty) {
      statement = SwitchStatement(NullLiteral(), [
        ..._neededSwitchCases,
        SwitchCase([NullLiteral()], [TreeNode.noOffset], Block([statement]))
      ]);
    }
    _neededSwitchCases.clear();
    for (LabeledStatement labeledStatement in _neededLabeledStatements) {
      labeledStatement.body = statement;
      statement = labeledStatement;
    }
    _neededLabeledStatements.clear();
    statement = Block([
      ..._neededVariableDeclarations,
      ..._neededFunctionDeclarations,
      statement
    ]);
    _neededFunctionDeclarations.clear();
    _neededVariableDeclarations.clear();
    return statement;
  }

  /// Adds [statement] to [statements] including any nodes needed in the
  /// context.
  void _addStatement(List<Statement> statements, Statement statement) {
    statements.add(_ensureContext(statement));
  }

  /// Adds [expression] to [statements] including any nodes needed in the
  /// context.
  void _addExpression(List<Statement> statements, Expression expression) {
    _addStatement(statements, ExpressionStatement(expression));
  }

  /// Adds [type] to [statements] including any nodes needed in the context.
  void _addDartType(List<Statement> statements, DartType type) {
    _addExpression(statements, TypeLiteral(type));
  }

  /// Adds [constant] to [statements] including any nodes needed in the context.
  void _addConstant(List<Statement> statements, Constant constant) {
    _addExpression(statements, ConstantExpression(constant));
  }

  /// Adds [pattern] to [statements] including any nodes needed in the context.
  void _addPattern(List<Statement> statements, Pattern pattern) {
    _addExpression(statements, PatternAssignment(pattern, NullLiteral()));
  }

  /// Generates a list of [Statement] containing all pending in-body nodes.
  List<Statement> _generateBodies() {
    List<Statement> statements = [];
    while (_pendingStatements.isNotEmpty) {
      _addStatement(statements, _createStatement());
    }
    while (_pendingExpressions.isNotEmpty) {
      _addExpression(statements, _createExpression());
    }
    while (_pendingDartTypes.isNotEmpty) {
      _addDartType(statements, _createDartType());
    }
    while (_pendingConstants.isNotEmpty) {
      _addConstant(statements, _createConstant());
    }
    for (NodeKind kind in inBodyNodeKinds) {
      while (_pendingNodes.containsKey(kind)) {
        Node node = _createNodeFromKind(kind);
        switch (kind) {
          case NodeKind.Name:
            _addExpression(
                statements,
                DynamicGet(DynamicAccessKind.Dynamic, _createExpression(),
                    node as Name));
            break;
          case NodeKind.Arguments:
            _addExpression(
                statements,
                DynamicInvocation(DynamicAccessKind.Dynamic,
                    _createExpression(), _createName(), node as Arguments));
            break;
          case NodeKind.Catch:
            _addStatement(
                statements, TryCatch(_createStatement(), [node as Catch]));
            break;
          case NodeKind.FunctionNode:
            _addExpression(
                statements, FunctionExpression(node as FunctionNode));
            break;
          case NodeKind.MapLiteralEntry:
            _addExpression(statements, MapLiteral([node as MapLiteralEntry]));
            break;
          case NodeKind.MapPatternEntry:
            _addPattern(
                statements, MapPattern(null, null, [node as MapPatternEntry]));
            break;
          case NodeKind.MapPatternRestEntry:
            _addPattern(statements,
                MapPattern(null, null, [node as MapPatternRestEntry]));
            break;
          case NodeKind.NamedExpression:
            _addExpression(
                statements,
                DynamicInvocation(
                    DynamicAccessKind.Dynamic,
                    _createExpression(),
                    _createName(),
                    Arguments([], named: [node as NamedExpression])));
            break;
          case NodeKind.NamedType:
            _addDartType(
                statements,
                FunctionType([], _createDartType(), Nullability.nonNullable,
                    namedParameters: [node as NamedType]));
            break;
          case NodeKind.PatternSwitchCase:
            _addStatement(
                statements,
                PatternSwitchStatement(
                    _createExpression(), [node as PatternSwitchCase]));
            break;
          case NodeKind.SwitchCase:
            _addStatement(statements,
                SwitchStatement(_createExpression(), [node as SwitchCase]));
            break;
          case NodeKind.SwitchExpressionCase:
            _addExpression(
                statements,
                SwitchExpression(
                    _createExpression(), [node as SwitchExpressionCase]));
            break;
          case NodeKind.TypeParameter:
            _addExpression(
                statements,
                FunctionExpression(FunctionNode(Block([]),
                    typeParameters: [node as TypeParameter])));
            break;
          default:
            throw new UnimplementedError('Unhandled in body node $kind.');
        }
      }
    }
    return statements;
  }

  /// Generates [Statement]s containing occurrences of all requested nodes.
  List<Statement> generateBodies() {
    List<Statement> statements = _generateBodies();
    Set<Object> unsupportedKinds = {};
    if (_pendingInitializers.isNotEmpty) {
      unsupportedKinds.addAll(_pendingInitializers.keys);
    }
    if (_pendingMembers.isNotEmpty) {
      unsupportedKinds.addAll(_pendingMembers.keys);
    }
    if (_pendingNodes.isNotEmpty) {
      assert(
          _pendingNodes.keys.every((kind) => !inBodyNodeKinds.contains(kind)));
      unsupportedKinds.addAll(_pendingNodes.keys);
    }
    if (unsupportedKinds.isNotEmpty) {
      throw new UnsupportedError('Cannot create these node in a body context: '
          '${unsupportedKinds.join(', ')}');
    }
    return statements;
  }

  /// Generates a [Component] containing occurrences of all requested and needed
  /// nodes.
  Component generateComponent() {
    Class cls = _needClass();
    for (Statement statement in _generateBodies()) {
      cls.addProcedure(Procedure(
          _createName(), ProcedureKind.Method, FunctionNode(statement),
          fileUri: _uri));
    }
    while (_pendingInitializers.isNotEmpty) {
      Initializer initializer = _createInitializer();
      cls.addConstructor(Constructor(FunctionNode(null),
          name: _createName(), fileUri: _uri, initializers: [initializer]));
    }
    while (_pendingMembers.isNotEmpty) {
      Member member = _createMember();
      if (member is Procedure) {
        cls.addProcedure(member);
      } else if (member is Field) {
        cls.addField(member);
      } else if (member is Constructor) {
        cls.addConstructor(member);
      } else {
        throw new UnsupportedError(
            'Unexpected member $member (${member.runtimeType})');
      }
    }
    while (_pendingNodes.isNotEmpty) {
      NodeKind kind = _pendingNodes.keys.first;
      Node node = _createNodeFromKind(kind);
      switch (kind) {
        case NodeKind.Name:
        case NodeKind.Arguments:
        case NodeKind.Catch:
        case NodeKind.FunctionNode:
        case NodeKind.MapLiteralEntry:
        case NodeKind.NamedExpression:
        case NodeKind.NamedType:
        case NodeKind.SwitchCase:
        case NodeKind.TypeParameter:
        case NodeKind.MapPatternEntry:
        case NodeKind.MapPatternRestEntry:
        case NodeKind.PatternGuard:
        case NodeKind.PatternSwitchCase:
        case NodeKind.SwitchExpressionCase:
          throw new UnimplementedError('Expected in body node $kind.');
        case NodeKind.Class:
          _needLibrary().addClass(node as Class);
          break;
        case NodeKind.Combinator:
          _needLibrary().addDependency(LibraryDependency.import(_needLibrary(),
              combinators: [node as Combinator]));
          break;
        case NodeKind.Component:
          assert(identical(node, _component),
              "Cannot create multiple Component nodes.");
          break;
        case NodeKind.Extension:
          _needLibrary().addExtension(node as Extension);
          break;
        case NodeKind.Library:
          _component.libraries.add(node as Library);
          break;
        case NodeKind.LibraryDependency:
          _needLibrary().addDependency(node as LibraryDependency);
          break;
        case NodeKind.LibraryPart:
          _needLibrary().addPart(node as LibraryPart);
          break;
        case NodeKind.Supertype:
          _needLibrary().addClass(
              Class(name: 'foo', fileUri: _uri, supertype: node as Supertype));
          break;
        case NodeKind.Typedef:
          _needLibrary().addTypedef(node as Typedef);
          break;
        case NodeKind.ExtensionTypeDeclaration:
          _needLibrary()
              .addExtensionTypeDeclaration(node as ExtensionTypeDeclaration);
          break;
      }
    }
    return _component;
  }

  /// Returns a [Library] node that fits the requirements.
  ///
  /// If no such [Library] exists in [_neededLibraries], a new [Library] is
  /// created and added to [_neededLibraries].
  // TODO(johnniwinther): Add requirements when/where needed.
  Library _needLibrary() {
    for (Library library in _neededLibraries) {
      return library;
    }
    Library library = Library(_uri, fileUri: _uri);
    _neededLibraries.add(library);
    _component.libraries.add(library);
    return library;
  }

  /// Returns a [LibraryDependency] node that fits the requirements.
  ///
  /// If no such [LibraryDependency] exists in [_neededLibraryDependencies], a
  /// new [LibraryDependency] is created and added to
  /// [_neededLibraryDependencies].
  LibraryDependency _needLibraryDependency({bool deferred = false}) {
    for (LibraryDependency libraryDependency in _neededLibraryDependencies) {
      if (!deferred || libraryDependency.isDeferred) {
        return libraryDependency;
      }
    }
    LibraryDependency libraryDependency = deferred
        ? LibraryDependency.deferredImport(_needLibrary(), 'foo')
        : LibraryDependency.import(_needLibrary());
    _neededLibraryDependencies.add(libraryDependency);
    return libraryDependency;
  }

  /// Returns a [Class] node that fits the requirements.
  ///
  /// If no such [Class] exists in [_neededClasses], a new [Class] is
  /// created and added to [_neededClasses].
  // TODO(johnniwinther): Add requirements when/where needed.
  Class _needClass() {
    for (Class cls in _neededClasses) {
      return cls;
    }
    Class cls = Class(name: 'Foo', fileUri: _uri);
    _neededClasses.add(cls);
    _needLibrary().addClass(cls);
    return cls;
  }

  /// Returns an [ExtensionTypeDeclaration] node that fits the requirements.
  ///
  /// If no such [ExtensionTypeDeclaration] exists in
  /// [_neededExtensionTypeDeclarations], a new [ExtensionTypeDeclaration] is
  /// created and added to [_neededExtensionTypeDeclarations].
  // TODO(johnniwinther): Add requirements when/where needed.
  ExtensionTypeDeclaration _needExtensionTypeDeclaration() {
    for (ExtensionTypeDeclaration extensionTypeDeclaration
        in _neededExtensionTypeDeclarations) {
      return extensionTypeDeclaration;
    }
    ExtensionTypeDeclaration extensionTypeDeclaration =
        ExtensionTypeDeclaration(
            name: 'foo',
            fileUri: _uri,
            declaredRepresentationType: const DynamicType());
    _neededExtensionTypeDeclarations.add(extensionTypeDeclaration);
    _needLibrary().addExtensionTypeDeclaration(extensionTypeDeclaration);
    return extensionTypeDeclaration;
  }

  /// Returns a [Typedef] node that fits the requirements.
  ///
  /// If no such [Typedef] exists in [_neededTypedefs], a new [Typedef] is
  /// created and added to [_neededTypedefs].
  // TODO(johnniwinther): Add requirements when/where needed.
  Typedef _needTypedef() {
    for (Typedef typedef in _neededTypedefs) {
      return typedef;
    }
    Typedef typedef = Typedef('foo', DynamicType(), fileUri: _uri);
    _neededTypedefs.add(typedef);
    _needLibrary().addTypedef(typedef);
    return typedef;
  }

  /// Returns a [TypeParameter] node that fits the requirements.
  ///
  /// If no such [TypeParameter] exists in [_neededTypeParameters], a new
  /// [TypeParameter] is created and added to [_neededTypeParameters].
  // TODO(johnniwinther): Add requirements when/where needed.
  TypeParameter _needTypeParameter() {
    for (TypeParameter typeParameter in _neededTypeParameters) {
      return typeParameter;
    }
    TypeParameter typeParameter =
        TypeParameter('foo', DynamicType(), DynamicType());
    _neededTypeParameters.add(typeParameter);
    // TODO(johnniwinther): Add the type parameter to a context; class, method
    // or function type.
    return typeParameter;
  }

  /// Returns a [Procedure] node that fits the requirements.
  ///
  /// If no such [Procedure] exists in [_neededProcedures], a new [Library] is
  /// created and added to [_neededProcedures].
  ///
  /// [index] is used to create multiple distinct [Procedure] nodes even when
  /// these have the same requirements.
  Procedure _needProcedure({int? index, bool? isStatic}) {
    for (Procedure procedure in _neededProcedures) {
      if (isStatic == null || isStatic == procedure.isStatic) {
        if (index == null || index == 0) {
          return procedure;
        } else {
          index--;
        }
      }
    }
    isStatic ??= true;
    Procedure procedure = Procedure(
        Name('foo'), ProcedureKind.Method, FunctionNode(Block([])),
        fileUri: _uri, isStatic: isStatic);
    _neededProcedures.add(procedure);
    if (isStatic) {
      _needLibrary().addProcedure(procedure);
    } else {
      _needClass().addProcedure(procedure);
    }
    return procedure;
  }

  /// Returns a [Constructor] node that fits the requirements.
  ///
  /// If no such [Constructor] exists in [_neededConstructors], a new
  /// [Constructor] is created and added to [_neededConstructors].
  // TODO(johnniwinther): Add requirements when/where needed.
  Constructor _needConstructor() {
    for (Constructor constructor in _neededConstructors) {
      return constructor;
    }
    Constructor constructor =
        Constructor(FunctionNode(null), name: Name('foo'), fileUri: _uri);
    _needClass().addConstructor(constructor);
    return constructor;
  }

  /// Returns a redirecting factory [Procedure] node that fits the requirements.
  ///
  /// If no such [Library] exists in [_neededRedirectingFactories], a new
  /// [Procedure] is created and added to [_neededRedirectingFactories].
  // TODO(johnniwinther): Add requirements when/where needed.
  Procedure _needRedirectingFactory() {
    for (Procedure redirectingFactory in _neededRedirectingFactories) {
      return redirectingFactory;
    }
    Procedure redirectingFactory = Procedure(
        Name('foo'),
        ProcedureKind.Method,
        FunctionNode(null)
          ..redirectingFactoryTarget =
              new RedirectingFactoryTarget(_needConstructor(), []),
        fileUri: _uri);
    _needClass().addProcedure(redirectingFactory);
    return redirectingFactory;
  }

  /// Returns a [Field] node that fits the requirements.
  ///
  /// If no such [Field] exists in [_neededFields], a new [Field] is
  /// created and added to [_neededFields].
  ///
  /// [index] is used to create multiple distinct [Field] nodes even when
  /// these have the same requirements.
  Field _needField({int? index, bool? isStatic, bool? hasSetter}) {
    for (Field field in _neededFields) {
      if (isStatic == null ||
          isStatic == field.isStatic && hasSetter == null ||
          hasSetter == field.hasSetter) {
        if (index == null || index == 0) {
          return field;
        } else {
          index--;
        }
      }
    }
    hasSetter ??= false;
    isStatic ??= true;
    Field field = hasSetter
        ? new Field.immutable(Name('foo'), fileUri: _uri, isStatic: isStatic)
        : new Field.mutable(Name('foo'), fileUri: _uri, isStatic: isStatic);
    _neededFields.add(field);
    if (isStatic) {
      _needLibrary().addField(field);
    } else {
      _needClass().addField(field);
    }
    return field;
  }

  /// Returns a [VariableDeclaration] node that fits the requirements.
  ///
  /// If no such [VariableDeclaration] exists in [_neededVariableDeclarations],
  /// a new [VariableDeclaration] is created and added to
  /// [_neededVariableDeclarations].
  // TODO(johnniwinther): Add requirements when/where needed.
  VariableDeclaration _needVariableDeclaration() {
    for (VariableDeclaration variableDeclaration
        in _neededVariableDeclarations) {
      return variableDeclaration;
    }
    VariableDeclaration variableDeclaration = VariableDeclaration('foo');
    _neededVariableDeclarations.add(variableDeclaration);
    return variableDeclaration;
  }

  /// Returns a [LabeledStatement] node that fits the requirements.
  ///
  /// If no such [LabeledStatement] exists in [_neededLabeledStatements], a new
  /// [LabeledStatement] is created and added to [_neededLabeledStatements].
  // TODO(johnniwinther): Add requirements when/where needed.
  LabeledStatement _needLabeledStatement() {
    for (LabeledStatement labeledStatement in _neededLabeledStatements) {
      return labeledStatement;
    }
    LabeledStatement labeledStatement = LabeledStatement(null);
    _neededLabeledStatements.add(labeledStatement);
    return labeledStatement;
  }

  /// Returns a [SwitchCase] node that fits the requirements.
  ///
  /// If no such [SwitchCase] exists in [_neededSwitchCases], a new [SwitchCase]
  /// is created and added to [_neededSwitchCases].
  // TODO(johnniwinther): Add requirements when/where needed.
  SwitchCase _needSwitchCase() {
    for (SwitchCase switchCase in _neededSwitchCases) {
      return switchCase;
    }
    SwitchCase switchCase =
        SwitchCase([NullLiteral()], [TreeNode.noOffset], EmptyStatement());
    _neededSwitchCases.add(switchCase);
    return switchCase;
  }

  /// Returns a [FunctionDeclaration] node that fits the requirements.
  ///
  /// If no such [FunctionDeclaration] exists in [_neededFunctionDeclarations],
  /// a new [FunctionDeclaration] is created and added to
  /// [_neededFunctionDeclarations].
  // TODO(johnniwinther): Add requirements when/where needed.
  FunctionDeclaration _needFunctionDeclaration() {
    for (FunctionDeclaration functionDeclaration
        in _neededFunctionDeclarations) {
      return functionDeclaration;
    }
    FunctionDeclaration functionDeclaration = FunctionDeclaration(
        VariableDeclaration('foo'), FunctionNode(Block([])));
    _neededFunctionDeclarations.add(functionDeclaration);
    return functionDeclaration;
  }

  /// Returns a fresh file offset value.
  int _needFileOffset() => _fileOffset++;

  /// Creates an [Expression] node.
  ///
  /// If there are any pending expressions, one of these is created.
  Expression _createExpression() {
    if (_pendingExpressions.isEmpty) {
      return NullLiteral()..fileOffset = _needFileOffset();
    }
    ExpressionKind kind = _pendingExpressions.keys.first;
    return _createExpressionFromKind(kind);
  }

  /// Creates an [Expression] node of the specified [kind].
  ///
  /// If there are any pending expressions of this [kind], one of these is
  /// created.
  Expression _createExpressionFromKind(ExpressionKind kind) {
    int? index = _pendingExpressions.remove(kind);
    switch (kind) {
      case ExpressionKind.AsExpression:
        return AsExpression(_createExpression(), _createDartType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.AwaitExpression:
        return AwaitExpression(_createExpression())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.BlockExpression:
        return BlockExpression(
            _createStatementFromKind(StatementKind.Block) as Block,
            _createExpression())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.BoolLiteral:
        return BoolLiteral(true)..fileOffset = _needFileOffset();
      case ExpressionKind.CheckLibraryIsLoaded:
        return CheckLibraryIsLoaded(_needLibraryDependency(deferred: true))
          ..fileOffset = _needFileOffset();
      case ExpressionKind.ConditionalExpression:
        return ConditionalExpression(_createExpression(), _createExpression(),
            _createExpression(), _createDartType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.ConstantExpression:
        return ConstantExpression(_createConstant(), _createDartType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.ConstructorInvocation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => ConstructorInvocation(_needConstructor(), _createArguments(),
              isConst: false)
            ..fileOffset = _needFileOffset(),
          () => ConstructorInvocation(_needConstructor(), _createArguments(),
              isConst: true)
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.ConstructorTearOff:
        return ConstructorTearOff(_needConstructor())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.DoubleLiteral:
        return DoubleLiteral(42.5)..fileOffset = _needFileOffset();
      case ExpressionKind.DynamicGet:
        return DynamicGet(
            DynamicAccessKind.Dynamic, _createExpression(), _createName())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.DynamicInvocation:
        return DynamicInvocation(DynamicAccessKind.Dynamic, _createExpression(),
            _createName(), _createArguments())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.DynamicSet:
        return DynamicSet(DynamicAccessKind.Dynamic, _createExpression(),
            _createName(), _createExpression())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.EqualsCall:
        return EqualsCall(_createExpression(), _createExpression(),
            functionType: _createFunctionType(),
            interfaceTarget: _needProcedure())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.EqualsNull:
        return EqualsNull(_createExpression())..fileOffset = _needFileOffset();
      case ExpressionKind.FileUriExpression:
        return FileUriExpression(_createExpression(), _uri)
          ..fileOffset = _needFileOffset();
      case ExpressionKind.FunctionExpression:
        return FunctionExpression(_createFunctionNode())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.FunctionInvocation:
        return FunctionInvocation(FunctionAccessKind.FunctionType,
            _createExpression(), _createArguments(),
            functionType: _createFunctionType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.FunctionTearOff:
        return FunctionTearOff(_createExpression())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.InstanceCreation:
        return InstanceCreation(_needClass().reference, [], {}, [], [])
          ..fileOffset = _needFileOffset();
      case ExpressionKind.InstanceGet:
        return InstanceGet(
            InstanceAccessKind.Instance, _createExpression(), _createName(),
            interfaceTarget: _needField(), resultType: _createDartType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.InstanceGetterInvocation:
        return InstanceGetterInvocation(InstanceAccessKind.Instance,
            _createExpression(), _createName(), _createArguments(),
            interfaceTarget: _needField(), functionType: _createFunctionType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.InstanceInvocation:
        return InstanceInvocation(InstanceAccessKind.Instance,
            _createExpression(), _createName(), _createArguments(),
            interfaceTarget: _needProcedure(),
            functionType: _createFunctionType())
          ..fileOffset = _needFileOffset()
          ..isBoundsSafe = true;
      case ExpressionKind.InstanceSet:
        return InstanceSet(InstanceAccessKind.Instance, _createExpression(),
            _createName(), _createExpression(),
            interfaceTarget: _needField())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.InstanceTearOff:
        return InstanceTearOff(
            InstanceAccessKind.Instance, _createExpression(), _createName(),
            interfaceTarget: _needProcedure(), resultType: _createDartType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.Instantiation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => Instantiation(_createExpression(), [])
            ..fileOffset = _needFileOffset(),
          () => Instantiation(_createExpression(), [_createDartType()])
            ..fileOffset = _needFileOffset(),
          () => Instantiation(
              _createExpression(), [_createDartType(), _createDartType()])
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.IntLiteral:
        return IntLiteral(42)..fileOffset = _needFileOffset();
      case ExpressionKind.InvalidExpression:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => InvalidExpression(null)..fileOffset = _needFileOffset(),
          () => InvalidExpression('foo')..fileOffset = _needFileOffset(),
          () => InvalidExpression('foo', _createExpression())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.IsExpression:
        return IsExpression(
          _createExpression(),
          _createDartType(),
        )..fileOffset = _needFileOffset();
      case ExpressionKind.Let:
        return Let(
            _createStatementFromKind(StatementKind.VariableDeclaration)
                as VariableDeclaration,
            _createExpression())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.ListConcatenation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => ListConcatenation([], typeArgument: _createDartType())
            ..fileOffset = _needFileOffset(),
          () => ListConcatenation([_createExpression()],
              typeArgument: _createDartType())
            ..fileOffset = _needFileOffset(),
          () => ListConcatenation([_createExpression(), _createExpression()],
              typeArgument: _createDartType())
            ..fileOffset = _needFileOffset()
        ]);
      case ExpressionKind.ListLiteral:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => ListLiteral([], typeArgument: _createDartType(), isConst: false)
            ..fileOffset = _needFileOffset(),
          () => ListLiteral([_createExpression()],
              typeArgument: _createDartType(), isConst: false)
            ..fileOffset = _needFileOffset(),
          () => ListLiteral([_createExpression(), _createExpression()],
              typeArgument: _createDartType(), isConst: false)
            ..fileOffset = _needFileOffset(),
          () => ListLiteral([_createExpression(), _createExpression()],
              typeArgument: _createDartType(), isConst: true)
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.LoadLibrary:
        return LoadLibrary(_needLibraryDependency(deferred: true))
          ..fileOffset = _needFileOffset();
      case ExpressionKind.LocalFunctionInvocation:
        return LocalFunctionInvocation(
            _needFunctionDeclaration().variable, _createArguments(),
            functionType: _createFunctionType())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.LogicalExpression:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => LogicalExpression(_createExpression(),
              LogicalExpressionOperator.AND, _createExpression())
            ..fileOffset = _needFileOffset(),
          () => LogicalExpression(_createExpression(),
              LogicalExpressionOperator.OR, _createExpression())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.MapConcatenation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => MapConcatenation([],
              keyType: _createDartType(), valueType: _createDartType())
            ..fileOffset = _needFileOffset(),
          () => MapConcatenation([_createExpression()],
              keyType: _createDartType(), valueType: _createDartType())
            ..fileOffset = _needFileOffset(),
          () => MapConcatenation([_createExpression(), _createExpression()],
              keyType: _createDartType(), valueType: _createDartType())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.MapLiteral:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => MapLiteral([],
              keyType: _createDartType(),
              valueType: _createDartType(),
              isConst: false)
            ..fileOffset = _needFileOffset(),
          () => MapLiteral([_createMapLiteralEntry()],
              keyType: _createDartType(),
              valueType: _createDartType(),
              isConst: false)
            ..fileOffset = _needFileOffset(),
          () => MapLiteral([
                _createMapLiteralEntry(),
                _createMapLiteralEntry(),
              ],
                  keyType: _createDartType(),
                  valueType: _createDartType(),
                  isConst: false)
                ..fileOffset = _needFileOffset(),
          () => MapLiteral([
                _createMapLiteralEntry(),
                _createMapLiteralEntry(),
              ],
                  keyType: _createDartType(),
                  valueType: _createDartType(),
                  isConst: true)
                ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.Not:
        return Not(_createExpression())..fileOffset = _needFileOffset();
      case ExpressionKind.NullCheck:
        return NullCheck(_createExpression())..fileOffset = _needFileOffset();
      case ExpressionKind.NullLiteral:
        return NullLiteral();
      case ExpressionKind.RedirectingFactoryTearOff:
        return RedirectingFactoryTearOff(_needRedirectingFactory())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.Rethrow:
        return Rethrow()..fileOffset = _needFileOffset();
      case ExpressionKind.SetConcatenation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => SetConcatenation([], typeArgument: _createDartType())
            ..fileOffset = _needFileOffset(),
          () => SetConcatenation([_createExpression()],
              typeArgument: _createDartType())
            ..fileOffset = _needFileOffset(),
          () => SetConcatenation([_createExpression(), _createExpression()],
              typeArgument: _createDartType())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.SetLiteral:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => SetLiteral([], typeArgument: _createDartType(), isConst: false)
            ..fileOffset = _needFileOffset(),
          () => SetLiteral([_createExpression()],
              typeArgument: _createDartType(), isConst: false)
            ..fileOffset = _needFileOffset(),
          () => SetLiteral([_createExpression(), _createExpression()],
              typeArgument: _createDartType(), isConst: false)
            ..fileOffset = _needFileOffset(),
          () => SetLiteral([_createExpression(), _createExpression()],
              typeArgument: _createDartType(), isConst: true)
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.StaticGet:
        return StaticGet(_needField())..fileOffset = _needFileOffset();
      case ExpressionKind.StaticInvocation:
        return StaticInvocation(_needProcedure(), _createArguments())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.StaticSet:
        return StaticSet(_needField(), _createExpression())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.StaticTearOff:
        return StaticTearOff(_needProcedure())..fileOffset = _needFileOffset();
      case ExpressionKind.StringConcatenation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => StringConcatenation([])..fileOffset = _needFileOffset(),
          () => StringConcatenation([_createExpression()])
            ..fileOffset = _needFileOffset(),
          () => StringConcatenation([_createExpression(), _createExpression()])
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.StringLiteral:
        return StringLiteral('foo');
      case ExpressionKind.AbstractSuperMethodInvocation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => AbstractSuperMethodInvocation(
              _createName(), _createArguments(), _needProcedure())
            ..fileOffset = _needFileOffset(),
          () => AbstractSuperMethodInvocation(
              _createName(), _createArguments(), _needProcedure())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.SuperMethodInvocation:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => SuperMethodInvocation(
              _createName(), _createArguments(), _needProcedure())
            ..fileOffset = _needFileOffset(),
          () => SuperMethodInvocation(
              _createName(), _createArguments(), _needProcedure())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.AbstractSuperPropertyGet:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => AbstractSuperPropertyGet(_createName(), _needProcedure())
            ..fileOffset = _needFileOffset(),
          () => AbstractSuperPropertyGet(_createName(), _needField())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.AbstractSuperPropertySet:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => AbstractSuperPropertySet(
              _createName(), _createExpression(), _needProcedure())
            ..fileOffset = _needFileOffset(),
          () => AbstractSuperPropertySet(
              _createName(), _createExpression(), _needField())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.SuperPropertyGet:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => SuperPropertyGet(_createName(), _needProcedure())
            ..fileOffset = _needFileOffset(),
          () => SuperPropertyGet(_createName(), _needField())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.SuperPropertySet:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => SuperPropertySet(
              _createName(), _createExpression(), _needProcedure())
            ..fileOffset = _needFileOffset(),
          () =>
              SuperPropertySet(_createName(), _createExpression(), _needField())
                ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.SymbolLiteral:
        return SymbolLiteral('foo')..fileOffset = _needFileOffset();
      case ExpressionKind.ThisExpression:
        return ThisExpression()..fileOffset = _needFileOffset();
      case ExpressionKind.Throw:
        return Throw(_createExpression())..fileOffset = _needFileOffset();
      case ExpressionKind.TypeLiteral:
        return TypeLiteral(_createDartType())..fileOffset = _needFileOffset();
      case ExpressionKind.TypedefTearOff:
        // TODO(johnniwinther): Add non-trivial cases.
        return TypedefTearOff([], _createExpression(), [])
          ..fileOffset = _needFileOffset();
      case ExpressionKind.VariableGet:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => VariableGet(_needVariableDeclaration())
            ..fileOffset = _needFileOffset(),
          () => VariableGet(_needVariableDeclaration(), _createDartType())
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.VariableSet:
        return VariableSet(_needVariableDeclaration(), _createExpression())
          ..fileOffset = _needFileOffset();
      case ExpressionKind.RecordIndexGet:
        return RecordIndexGet(_createExpression(),
            new RecordType([_createDartType()], [], Nullability.nonNullable), 0)
          ..fileOffset = _needFileOffset();
      case ExpressionKind.RecordNameGet:
        String name = _createName().text;
        return RecordNameGet(
            _createExpression(),
            new RecordType([], [new NamedType(name, _createDartType())],
                Nullability.nonNullable),
            name)
          ..fileOffset = _needFileOffset();
      case ExpressionKind.RecordLiteral:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => RecordLiteral([_createExpression()], [],
              RecordType([_createDartType()], [], Nullability.nonNullable),
              isConst: false)
            ..fileOffset = _needFileOffset(),
          () => RecordLiteral(
              [],
              [NamedExpression('foo', _createExpression())],
              RecordType([], [NamedType('foo', _createDartType())],
                  Nullability.nonNullable),
              isConst: false)
            ..fileOffset = _needFileOffset(),
          () => RecordLiteral(
              [_createExpression()],
              [NamedExpression('foo', _createExpression())],
              RecordType(
                  [_createDartType()],
                  [NamedType('foo', _createDartType())],
                  Nullability.nonNullable),
              isConst: false)
            ..fileOffset = _needFileOffset(),
          () => RecordLiteral([_createExpression()], [],
              RecordType([_createDartType()], [], Nullability.nonNullable),
              isConst: true)
            ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.SwitchExpression:
        return _createOneOf(_pendingExpressions, kind, index, [
          () => new SwitchExpression(_createExpression(), [])
            ..fileOffset = _needFileOffset(),
          () => new SwitchExpression(_createExpression(), [
                _createNodeFromKind(NodeKind.SwitchExpressionCase)
                    as SwitchExpressionCase
              ])
                ..fileOffset = _needFileOffset(),
        ]);
      case ExpressionKind.PatternAssignment:
        return new PatternAssignment(_createPattern(), _createExpression())
          ..fileOffset = _needFileOffset();
    }
  }

  /// Creates an [Pattern] node.
  ///
  /// If there are any pending expressions, one of these is created.
  Pattern _createPattern() {
    if (_pendingPatterns.isEmpty) {
      return ConstantPattern(NullLiteral()..fileOffset = _needFileOffset())
        ..fileOffset = _needFileOffset();
    }
    PatternKind kind = _pendingPatterns.keys.first;
    return _createPatternFromKind(kind);
  }

  /// Creates an [Expression] node of the specified [kind].
  ///
  /// If there are any pending expressions of this [kind], one of these is
  /// created.
  Pattern _createPatternFromKind(PatternKind kind) {
    int? index = _pendingPatterns.remove(kind);
    switch (kind) {
      case PatternKind.AndPattern:
        return AndPattern(_createPattern(), _createPattern())
          ..fileOffset = _needFileOffset();
      case PatternKind.AssignedVariablePattern:
        return AssignedVariablePattern(_needVariableDeclaration())
          ..fileOffset = _needFileOffset();
      case PatternKind.CastPattern:
        return CastPattern(_createPattern(), _createDartType())
          ..fileOffset = _needFileOffset();
      case PatternKind.ConstantPattern:
        return ConstantPattern(_createExpression())
          ..fileOffset = _needFileOffset();
      case PatternKind.NullAssertPattern:
        return NullAssertPattern(_createPattern())
          ..fileOffset = _needFileOffset();
      case PatternKind.NullCheckPattern:
        return NullCheckPattern(_createPattern())
          ..fileOffset = _needFileOffset();
      case PatternKind.InvalidPattern:
        return InvalidPattern(_createExpression(), declaredVariables: [])
          ..fileOffset = _needFileOffset();
      case PatternKind.ListPattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => ListPattern(null, [])..fileOffset = _needFileOffset(),
          () => ListPattern(_createDartType(), [_createPattern()])
            ..fileOffset = _needFileOffset(),
        ]);
      case PatternKind.MapPattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => MapPattern(null, null, []),
          () => MapPattern(_createDartType(), _createDartType(), [
                _createNodeFromKind(NodeKind.MapPatternEntry) as MapPatternEntry
              ])
                ..fileOffset = _needFileOffset(),
          () => MapPattern(_createDartType(), _createDartType(), [
                _createNodeFromKind(NodeKind.MapPatternEntry)
                    as MapPatternEntry,
                _createNodeFromKind(NodeKind.MapPatternRestEntry)
                    as MapPatternEntry
              ])
                ..fileOffset = _needFileOffset(),
        ]);
      case PatternKind.NamedPattern:
        return NamedPattern('foo', _createPattern())
          ..fileOffset = _needFileOffset();
      case PatternKind.ObjectPattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => ObjectPattern(_createDartType(), [])
            ..fileOffset = _needFileOffset(),
          () => ObjectPattern(_createDartType(), [
                _createPatternFromKind(PatternKind.NamedPattern) as NamedPattern
              ])
                ..fileOffset = _needFileOffset(),
        ]);
      case PatternKind.OrPattern:
        return OrPattern(_createPattern(), _createPattern(),
            orPatternJointVariables: [])
          ..fileOffset = _needFileOffset();
      case PatternKind.RecordPattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => RecordPattern([])..fileOffset = _needFileOffset(),
          () =>
              RecordPattern([_createPattern()])..fileOffset = _needFileOffset(),
        ]);
      case PatternKind.RelationalPattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => RelationalPattern(
              RelationalPatternKind.equals, _createExpression())
            ..fileOffset = _needFileOffset(),
          () => RelationalPattern(
              RelationalPatternKind.lessThan, _createExpression())
            ..fileOffset = _needFileOffset(),
        ]);
      case PatternKind.RestPattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => RestPattern(null)..fileOffset = _needFileOffset(),
          () => RestPattern(_createPattern())..fileOffset = _needFileOffset(),
        ]);
      case PatternKind.VariablePattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => VariablePattern(null, _createVariableDeclaration())
            ..fileOffset = _needFileOffset(),
          () => VariablePattern(_createDartType(), _createVariableDeclaration())
            ..fileOffset = _needFileOffset(),
        ]);
      case PatternKind.WildcardPattern:
        return _createOneOf(_pendingPatterns, kind, index, [
          () => WildcardPattern(null)..fileOffset = _needFileOffset(),
          () => WildcardPattern(_createDartType())
            ..fileOffset = _needFileOffset(),
        ]);
    }
  }

  /// Creates a [Statement] node.
  ///
  /// If there are any pending statements, one of these is created.
  Statement _createStatement() {
    if (_pendingStatements.isEmpty) {
      return EmptyStatement()..fileOffset = _needFileOffset();
    }
    StatementKind kind = _pendingStatements.keys.first;
    return _createStatementFromKind(kind);
  }

  /// Creates a [Statement] of the specified [kind].
  ///
  /// If there are any pending statements of this [kind], one of these is
  /// created.
  Statement _createStatementFromKind(StatementKind kind) {
    int? index = _pendingStatements.remove(kind);
    switch (kind) {
      case StatementKind.AssertBlock:
        return _createOneOf(_pendingStatements, kind, index, [
          () => AssertBlock([])..fileOffset = _needFileOffset(),
          () =>
              AssertBlock([_createStatement()])..fileOffset = _needFileOffset(),
          () => AssertBlock([_createStatement(), _createStatement()])
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.AssertStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => AssertStatement(_createExpression(),
              conditionStartOffset: _needFileOffset(),
              conditionEndOffset: _needFileOffset())
            ..fileOffset = _needFileOffset(),
          () => AssertStatement(_createExpression(),
              message: _createExpression(),
              conditionStartOffset: _needFileOffset(),
              conditionEndOffset: _needFileOffset())
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.Block:
        return _createOneOf(_pendingStatements, kind, index, [
          () => Block([])..fileOffset = _needFileOffset(),
          () => Block([_createStatement()])..fileOffset = _needFileOffset(),
          () => Block([_createStatement(), _createStatement()])
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.BreakStatement:
        return BreakStatement(_needLabeledStatement())
          ..fileOffset = _needFileOffset();
      case StatementKind.ContinueSwitchStatement:
        return ContinueSwitchStatement(_needSwitchCase())
          ..fileOffset = _needFileOffset();
      case StatementKind.DoStatement:
        return DoStatement(_createStatement(), _createExpression())
          ..fileOffset = _needFileOffset();
      case StatementKind.EmptyStatement:
        return EmptyStatement()..fileOffset = _needFileOffset();
      case StatementKind.ExpressionStatement:
        return ExpressionStatement(_createExpression())
          ..fileOffset = _needFileOffset();
      case StatementKind.ForInStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => ForInStatement(_createVariableDeclaration(),
              _createExpression(), _createStatement(),
              isAsync: false)
            ..fileOffset = _needFileOffset(),
          () => ForInStatement(_createVariableDeclaration(),
              _createExpression(), _createStatement(),
              isAsync: true)
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.ForStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => ForStatement([], null, [], _createStatement())
            ..fileOffset = _needFileOffset(),
          () => ForStatement([_createVariableDeclaration()],
              _createExpression(), [_createExpression()], _createStatement())
            ..fileOffset = _needFileOffset(),
          () => ForStatement(
              [_createVariableDeclaration(), _createVariableDeclaration()],
              _createExpression(),
              [_createExpression(), _createExpression()],
              _createStatement())
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.FunctionDeclaration:
        return FunctionDeclaration(
            VariableDeclaration(null, isSynthesized: true),
            _createFunctionNode())
          ..fileOffset = _needFileOffset();
      case StatementKind.IfStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => IfStatement(_createExpression(), _createStatement(), null)
            ..fileOffset = _needFileOffset(),
          () => IfStatement(
              _createExpression(), _createStatement(), _createStatement())
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.LabeledStatement:
        return LabeledStatement(_createStatement())
          ..fileOffset = _needFileOffset();
      case StatementKind.ReturnStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => ReturnStatement()..fileOffset = _needFileOffset(),
          () => ReturnStatement(_createExpression())
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.SwitchStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => SwitchStatement(_createExpression(), [])
            ..fileOffset = _needFileOffset(),
          () => SwitchStatement(_createExpression(), [_createSwitchCase()])
            ..fileOffset = _needFileOffset(),
          () => SwitchStatement(
              _createExpression(), [_createSwitchCase(), _createSwitchCase()])
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.TryCatch:
        return _createOneOf(_pendingStatements, kind, index, [
          () =>
              TryCatch(_createStatement(), [])..fileOffset = _needFileOffset(),
          () => TryCatch(_createStatement(), [_createCatch()])
            ..fileOffset = _needFileOffset(),
          () => TryCatch(_createStatement(), [_createCatch(), _createCatch()])
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.TryFinally:
        return TryFinally(_createStatement(), _createStatement())
          ..fileOffset = _needFileOffset();
      case StatementKind.VariableDeclaration:
        return _createOneOf(_pendingStatements, kind, index, [
          () => VariableDeclaration('foo')..fileOffset = _needFileOffset(),
          () => VariableDeclaration('foo', initializer: _createExpression())
            ..fileOffset = _needFileOffset(),
          () => VariableDeclaration('foo', type: _createDartType())
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.WhileStatement:
        return WhileStatement(_createExpression(), _createStatement())
          ..fileOffset = _needFileOffset();
      case StatementKind.YieldStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => YieldStatement(_createExpression(), isYieldStar: false)
            ..fileOffset = _needFileOffset(),
          () => YieldStatement(_createExpression(), isYieldStar: true)
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.PatternSwitchStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => PatternSwitchStatement(_createExpression(), [])
            ..fileOffset = _needFileOffset(),
          () => PatternSwitchStatement(_createExpression(), [
                _createNodeFromKind(NodeKind.PatternSwitchCase)
                    as PatternSwitchCase
              ])
                ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.IfCaseStatement:
        return _createOneOf(_pendingStatements, kind, index, [
          () => IfCaseStatement(
              _createExpression(),
              _createNodeFromKind(NodeKind.PatternGuard) as PatternGuard,
              _createStatement())
            ..fileOffset = _needFileOffset(),
          () => IfCaseStatement(
              _createExpression(),
              _createNodeFromKind(NodeKind.PatternGuard) as PatternGuard,
              _createStatement(),
              _createStatement())
            ..fileOffset = _needFileOffset(),
        ]);
      case StatementKind.PatternVariableDeclaration:
        return _createOneOf(_pendingStatements, kind, index, [
          () => new PatternVariableDeclaration(
              _createPattern(), _createExpression(),
              isFinal: false)
            ..fileOffset = _needFileOffset(),
          () => new PatternVariableDeclaration(
              _createPattern(), _createExpression(),
              isFinal: true)
            ..fileOffset = _needFileOffset(),
        ]);
    }
  }

  /// Creates a [VariableDeclaration] node.
  ///
  /// If there are any pending [VariableDeclaration] nodes, one of these is
  /// created.
  VariableDeclaration _createVariableDeclaration() {
    return _createStatementFromKind(StatementKind.VariableDeclaration)
        as VariableDeclaration;
  }

  /// Creates a [DartType] node.
  ///
  /// If there are any pending types, one of these is created.
  DartType _createDartType() {
    if (_pendingDartTypes.isEmpty) {
      return VoidType();
    }
    DartTypeKind kind = _pendingDartTypes.keys.first;
    return _createDartTypeFromKind(kind);
  }

  /// Creates a [DartType] node of the specified [kind].
  ///
  /// If there are any pending types of this [kind], one of these is created.
  DartType _createDartTypeFromKind(DartTypeKind kind) {
    int? index = _pendingDartTypes.remove(kind);
    switch (kind) {
      case DartTypeKind.DynamicType:
        return DynamicType();
      case DartTypeKind.FunctionType:
        return _createOneOf(_pendingDartTypes, kind, index, [
          // TODO(johnniwinther): Create non-trivial cases.
          () => FunctionType([], _createDartType(), Nullability.nonNullable),
        ]);
      case DartTypeKind.RecordType:
        return _createOneOf(_pendingDartTypes, kind, index, [
          // TODO(cstefantsova): Create non-trivial cases.
          () => RecordType([], [], Nullability.nonNullable),
        ]);
      case DartTypeKind.FutureOrType:
        return FutureOrType(_createDartType(), Nullability.nonNullable);
      case DartTypeKind.InterfaceType:
        return _createOneOf(_pendingDartTypes, kind, index, [
          // TODO(johnniwinther): Create non-trivial cases.
          () => InterfaceType(_needClass(), Nullability.nonNullable, []),
        ]);
      case DartTypeKind.InvalidType:
        return InvalidType();
      case DartTypeKind.NeverType:
        return NeverType.nonNullable();
      case DartTypeKind.NullType:
        return NullType();
      case DartTypeKind.TypeParameterType:
        return _createOneOf(_pendingDartTypes, kind, index, [
          () =>
              TypeParameterType(_needTypeParameter(), Nullability.nonNullable),
        ]);
      case DartTypeKind.IntersectionType:
        return _createOneOf(_pendingDartTypes, kind, index, [
          () => IntersectionType(
              TypeParameterType(_needTypeParameter(), Nullability.nonNullable),
              _createDartType()),
        ]);
      case DartTypeKind.TypedefType:
        return _createOneOf(_pendingDartTypes, kind, index, [
          // TODO(johnniwinther): Create non-trivial cases.
          () => TypedefType(_needTypedef(), Nullability.nonNullable, []),
        ]);
      case DartTypeKind.ExtensionType:
        return ExtensionType(
            _needExtensionTypeDeclaration(), Nullability.nonNullable);
      case DartTypeKind.VoidType:
        return VoidType();
    }
  }

  /// Creates a [FunctionType] node.
  ///
  /// If there are any pending [FunctionType] nodes, one of these is created.
  FunctionType _createFunctionType() {
    return _createDartTypeFromKind(DartTypeKind.FunctionType) as FunctionType;
  }

  /// Creates a [Constant] node.
  ///
  /// If there are any pending constants, one of these is created.
  Constant _createConstant() {
    if (_pendingConstants.isEmpty) {
      return NullConstant();
    }
    ConstantKind kind = _pendingConstants.keys.first;
    return _createConstantFromKind(kind);
  }

  /// Creates a [Constant] node of the specified [kind].
  ///
  /// If there are any pending constants of this [kind], one of these is
  /// created.
  Constant _createConstantFromKind(ConstantKind kind) {
    int? index = _pendingConstants.remove(kind);
    switch (kind) {
      case ConstantKind.BoolConstant:
        return BoolConstant(true);
      case ConstantKind.ConstructorTearOffConstant:
        return ConstructorTearOffConstant(_needConstructor());
      case ConstantKind.DoubleConstant:
        return DoubleConstant(42.5);
      case ConstantKind.InstanceConstant:
        return _createOneOf(_pendingConstants, kind, index, [
          () => InstanceConstant(_needClass().reference, [], {}),
          () => InstanceConstant(_needClass().reference, [
                _createDartType()
              ], {
                _needField(isStatic: false, hasSetter: false).getterReference:
                    _createConstant()
              }),
          () => InstanceConstant(_needClass().reference, [
                _createDartType()
              ], {
                _needField(index: 0, isStatic: false, hasSetter: false)
                    .getterReference: _createConstant(),
                _needField(index: 1, isStatic: false, hasSetter: false)
                    .getterReference: _createConstant()
              }),
        ]);
      case ConstantKind.InstantiationConstant:
        return InstantiationConstant(_createConstant(), [_createDartType()]);
      case ConstantKind.IntConstant:
        return IntConstant(42);
      case ConstantKind.ListConstant:
        return _createOneOf(_pendingConstants, kind, index, [
          () => ListConstant(_createDartType(), []),
          () => ListConstant(_createDartType(), [_createConstant()]),
          () => ListConstant(
              _createDartType(), [_createConstant(), _createConstant()]),
        ]);
      case ConstantKind.MapConstant:
        return _createOneOf(_pendingConstants, kind, index, [
          () => MapConstant(_createDartType(), _createDartType(), []),
          () => MapConstant(_createDartType(), _createDartType(),
              [ConstantMapEntry(_createConstant(), _createConstant())]),
          () => MapConstant(_createDartType(), _createDartType(), [
                ConstantMapEntry(_createConstant(), _createConstant()),
                ConstantMapEntry(_createConstant(), _createConstant())
              ]),
        ]);
      case ConstantKind.RecordConstant:
        return _createOneOf(_pendingConstants, kind, index, [
          () => RecordConstant(
              [], {}, RecordType([], [], Nullability.nonNullable)),
          () => RecordConstant(
              [_createConstant(), _createConstant()],
              {},
              RecordType([_createDartType(), _createDartType()], [],
                  Nullability.nonNullable)),
          () => RecordConstant(
                  [],
                  {
                    'a': _createConstant(),
                    'b': _createConstant(),
                  },
                  RecordType([], [
                    NamedType('a', _createDartType()),
                    NamedType('b', _createDartType())
                  ], Nullability.nonNullable)),
          () => RecordConstant(
              [_createConstant()],
              {'a': _createConstant()},
              RecordType(
                  [_createDartType()],
                  [NamedType('a', _createDartType())],
                  Nullability.nonNullable)),
        ]);
      case ConstantKind.NullConstant:
        return NullConstant();
      case ConstantKind.RedirectingFactoryTearOffConstant:
        return RedirectingFactoryTearOffConstant(_needRedirectingFactory());
      case ConstantKind.SetConstant:
        return _createOneOf(_pendingConstants, kind, index, [
          () => SetConstant(_createDartType(), []),
          () => SetConstant(_createDartType(), [_createConstant()]),
          () => SetConstant(
              _createDartType(), [_createConstant(), _createConstant()]),
        ]);
      case ConstantKind.StaticTearOffConstant:
        return StaticTearOffConstant(_needProcedure());
      case ConstantKind.StringConstant:
        return StringConstant('foo');
      case ConstantKind.SymbolConstant:
        return _createOneOf(_pendingConstants, kind, index, [
          () => SymbolConstant('foo', null),
          () => SymbolConstant('_foo', _needLibrary().reference),
        ]);
      case ConstantKind.TypeLiteralConstant:
        return TypeLiteralConstant(_createDartType());
      case ConstantKind.TypedefTearOffConstant:
        // TODO(johnniwinther): Add non-trivial cases.
        return TypedefTearOffConstant(
            [],
            _createConstantFromKind(ConstantKind.ConstructorTearOffConstant)
                as TearOffConstant,
            []);
      case ConstantKind.UnevaluatedConstant:
        return UnevaluatedConstant(_createExpression());
    }
  }

  /// Creates an [Initializer] node.
  ///
  /// If there are any pending initializers, one of these is created.
  Initializer _createInitializer() {
    if (_pendingInitializers.isEmpty) {
      return InvalidInitializer()..fileOffset = _needFileOffset();
    }
    InitializerKind kind = _pendingInitializers.keys.first;
    return _createInitializerFromKind(kind);
  }

  /// Creates an [Initializer] node of the specified [kind].
  ///
  /// If there are any pending initializers of this [kind], one of these is
  /// created.
  Initializer _createInitializerFromKind(InitializerKind kind) {
    // ignore: unused_local_variable
    int? index = _pendingInitializers.remove(kind);
    switch (kind) {
      case InitializerKind.AssertInitializer:
        return AssertInitializer(
            _createStatementFromKind(StatementKind.AssertStatement)
                as AssertStatement)
          ..fileOffset = _needFileOffset();
      case InitializerKind.FieldInitializer:
        return FieldInitializer(
            _needField(isStatic: false), _createExpression())
          ..fileOffset = _needFileOffset();
      case InitializerKind.InvalidInitializer:
        return InvalidInitializer()..fileOffset = _needFileOffset();
      case InitializerKind.LocalInitializer:
        return LocalInitializer(_createVariableDeclaration())
          ..fileOffset = _needFileOffset();
      case InitializerKind.RedirectingInitializer:
        return RedirectingInitializer(_needConstructor(), _createArguments())
          ..fileOffset = _needFileOffset();
      case InitializerKind.SuperInitializer:
        return SuperInitializer(_needConstructor(), _createArguments())
          ..fileOffset = _needFileOffset();
    }
  }

  /// Creates a [Member] node.
  ///
  /// If there are any pending members, one of these is created.
  Member _createMember() {
    if (_pendingMembers.isEmpty) {
      return Field.immutable(_createName(), fileUri: _uri)
        ..fileOffset = _needFileOffset();
    }
    MemberKind kind = _pendingMembers.keys.first;
    return _createMemberKind(kind);
  }

  /// Creates a [Member] node of the specified [kind].
  ///
  /// If there are any pending members of this [kind], one of these is created.
  Member _createMemberKind(MemberKind kind) {
    int? index = _pendingMembers.remove(kind);
    switch (kind) {
      case MemberKind.Constructor:
        return Constructor(_createFunctionNode(),
            name: _createName(), fileUri: _uri)
          ..fileOffset = _needFileOffset();
      case MemberKind.Field:
        return _createOneOf(_pendingMembers, kind, index, [
          () => Field.mutable(_createName(), fileUri: _uri)
            ..fileOffset = _needFileOffset(),
          () => Field.immutable(_createName(), fileUri: _uri)
            ..fileOffset = _needFileOffset(),
        ]);
      case MemberKind.Procedure:
        return _createOneOf(_pendingMembers, kind, index, [
          () => Procedure(
              _createName(), ProcedureKind.Method, _createFunctionNode(),
              fileUri: _uri)
            ..fileOffset = _needFileOffset(),
          () => Procedure(
              _createName(), ProcedureKind.Operator, _createFunctionNode(),
              fileUri: _uri)
            ..fileOffset = _needFileOffset(),
          () => Procedure(
              _createName(), ProcedureKind.Getter, _createFunctionNode(),
              fileUri: _uri)
            ..fileOffset = _needFileOffset(),
          () => Procedure(
              _createName(), ProcedureKind.Setter, _createFunctionNode(),
              fileUri: _uri)
            ..fileOffset = _needFileOffset(),
        ]);
    }
  }

  /// Creates an [Arguments] node.
  ///
  /// If there are any pending [Arguments] nodes, one of these is created.
  Arguments _createArguments() {
    return _createNodeFromKind(NodeKind.Arguments) as Arguments;
  }

  /// Creates a [Name] node.
  ///
  /// If there are any pending [Name] nodes, one of these is created.
  Name _createName() {
    return _createNodeFromKind(NodeKind.Name) as Name;
  }

  /// Creates a [FunctionNode] node.
  ///
  /// If there are any pending [FunctionNode] nodes, one of these is created.
  FunctionNode _createFunctionNode() {
    return _createNodeFromKind(NodeKind.FunctionNode) as FunctionNode;
  }

  /// Creates a [MapLiteralEntry] node.
  ///
  /// If there are any pending [MapLiteralEntry] nodes, one of these is created.
  MapLiteralEntry _createMapLiteralEntry() {
    return _createNodeFromKind(NodeKind.MapLiteralEntry) as MapLiteralEntry;
  }

  /// Creates a [SwitchCase] node.
  ///
  /// If there are any pending [SwitchCase] nodes, one of these is created.
  SwitchCase _createSwitchCase() {
    return _createNodeFromKind(NodeKind.SwitchCase) as SwitchCase;
  }

  /// Creates a [Catch] node.
  ///
  /// If there are any pending [Catch] nodes, one of these is created.
  Catch _createCatch() {
    return _createNodeFromKind(NodeKind.Catch) as Catch;
  }

  /// Creates a [Node] of the specified [kind].
  ///
  /// If there are any pending nodes of this [kind], one of these is created.
  Node _createNodeFromKind(NodeKind kind) {
    int? index = _pendingNodes.remove(kind);
    switch (kind) {
      case NodeKind.Arguments:
        return _createOneOf(_pendingNodes, kind, index, [
          // TODO(johnniwinther): Add non-trivial cases.
          () => Arguments([])..fileOffset = _needFileOffset(),
        ]);
      case NodeKind.Catch:
        // TODO(johnniwinther): Add non-trivial cases.
        return Catch(null, _createStatement())..fileOffset = _needFileOffset();
      case NodeKind.Class:
        return Class(name: 'foo', fileUri: _uri)
          ..fileOffset = _needFileOffset();
      case NodeKind.Combinator:
        return _createOneOf(_pendingNodes, kind, index, [
          () => Combinator.show([])..fileOffset = _needFileOffset(),
          () => Combinator.show(['foo'])..fileOffset = _needFileOffset(),
          () => Combinator.show(['foo', 'bar'])..fileOffset = _needFileOffset(),
          () => Combinator.hide([])..fileOffset = _needFileOffset(),
          () => Combinator.hide(['foo'])..fileOffset = _needFileOffset(),
          () => Combinator.hide(['foo', 'bar'])..fileOffset = _needFileOffset(),
        ]);
      case NodeKind.Component:
        return _component;
      case NodeKind.Extension:
        // TODO(johnniwinther): Add non-trivial cases.
        return Extension(name: 'foo', fileUri: _uri)
          ..fileOffset = _needFileOffset()
          ..onType = _createDartType();
      case NodeKind.FunctionNode:
        // TODO(johnniwinther): Add non-trivial cases.
        return FunctionNode(_createStatement())..fileOffset = _needFileOffset();
      case NodeKind.Library:
        return Library(_uri, fileUri: _uri)..fileOffset = _needFileOffset();
      case NodeKind.LibraryDependency:
        return _createOneOf(_pendingNodes, kind, index, [
          // TODO(johnniwinther): Add more cases.
          () => LibraryDependency.import(_needLibrary())
            ..fileOffset = _needFileOffset(),
          () => LibraryDependency.import(_needLibrary(), name: 'foo')
            ..fileOffset = _needFileOffset(),
          () => LibraryDependency.export(_needLibrary())
            ..fileOffset = _needFileOffset(),
        ]);
      case NodeKind.LibraryPart:
        // TODO(johnniwinther): Add non-trivial cases.
        // TODO(johnniwinther): Do we need to use a valid part uri?
        return LibraryPart([], 'foo')..fileOffset = _needFileOffset();
      case NodeKind.MapLiteralEntry:
        return MapLiteralEntry(_createExpression(), _createExpression())
          ..fileOffset = _needFileOffset();
      case NodeKind.Name:
        return _createOneOf(_pendingNodes, kind, index, [
          () => Name('foo'),
          () => Name('_foo', _needLibrary()),
        ]);
      case NodeKind.NamedExpression:
        return NamedExpression('foo', _createExpression())
          ..fileOffset = _needFileOffset();
      case NodeKind.NamedType:
        return NamedType('foo', _createDartType());
      case NodeKind.Supertype:
        return _createOneOf(_pendingNodes, kind, index, [
          () => Supertype(_needClass(), []),
          () => Supertype(_needClass(), [_createDartType()]),
          () => Supertype(_needClass(), [_createDartType(), _createDartType()]),
        ]);
      case NodeKind.SwitchCase:
        // TODO(johnniwinther): Add non-trivial cases.
        return SwitchCase(
            [NullLiteral()], [TreeNode.noOffset], _createStatement())
          ..fileOffset = _needFileOffset();
      case NodeKind.TypeParameter:
        return TypeParameter('foo', _createDartType(), _createDartType())
          ..fileOffset = _needFileOffset();
      case NodeKind.Typedef:
        return Typedef('foo', _createDartType(), fileUri: _uri)
          ..fileOffset = _needFileOffset();
      case NodeKind.ExtensionTypeDeclaration:
        // TODO(johnniwinther): Add non-trivial cases.
        return ExtensionTypeDeclaration(name: 'foo', fileUri: _uri)
          ..fileOffset = _needFileOffset()
          ..declaredRepresentationType = _createDartType();
      case NodeKind.MapPatternEntry:
        return MapPatternEntry(_createExpression(), _createPattern())
          ..fileOffset = _needFileOffset();
      case NodeKind.MapPatternRestEntry:
        return MapPatternRestEntry()..fileOffset = _needFileOffset();
      case NodeKind.PatternGuard:
        return _createOneOf(_pendingNodes, kind, index, [
          () => new PatternGuard(_createPattern())
            ..fileOffset = _needFileOffset(),
          () => new PatternGuard(_createPattern(), _createExpression())
            ..fileOffset = _needFileOffset(),
        ]);
      case NodeKind.PatternSwitchCase:
        return _createOneOf(_pendingNodes, kind, index, [
          () => new PatternSwitchCase([], [], _createStatement(),
              isDefault: true,
              hasLabel: false,
              jointVariables: [],
              jointVariableFirstUseOffsets: null),
          () => new PatternSwitchCase(
              [0],
              [_createNodeFromKind(NodeKind.PatternGuard) as PatternGuard],
              _createStatement(),
              isDefault: false,
              hasLabel: true,
              jointVariables: [],
              jointVariableFirstUseOffsets: null),
        ]);
      case NodeKind.SwitchExpressionCase:
        return new SwitchExpressionCase(
            _createNodeFromKind(NodeKind.PatternGuard) as PatternGuard,
            _createExpression())
          ..fileOffset = _needFileOffset();
    }
  }

  /// Helper that creates a node of type [V] using the list of [creators].
  ///
  /// The [index] indicates how many nodes of the [kind] that have currently
  /// been created. If there are more [creators] left after having created the
  /// [index]th node, [pending] is updated with the next pending index. If all
  /// pending nodes of the given [kind] have been created, [index] is `null` and
  /// the first [creators] function is used.
  V _createOneOf<K, V>(
      Map<K, int> pending, K kind, int? index, List<V Function()> creators) {
    if (index == null) {
      // All pending nodes have been created so we just create the first.
      return creators[0]();
    }
    if (index + 1 < creators.length) {
      pending[kind] = index + 1;
    }
    return creators[index]();
  }
}

/// [NodeKind]s for nodes that can occur inside member bodies.
const Set<NodeKind> inBodyNodeKinds = {
  NodeKind.Arguments,
  NodeKind.Catch,
  NodeKind.FunctionNode,
  NodeKind.MapLiteralEntry,
  NodeKind.MapPatternEntry,
  NodeKind.MapPatternRestEntry,
  NodeKind.Name,
  NodeKind.NamedExpression,
  NodeKind.NamedType,
  NodeKind.SwitchCase,
  NodeKind.TypeParameter,
  NodeKind.PatternGuard,
  NodeKind.PatternSwitchCase,
  NodeKind.SwitchExpressionCase,
};
