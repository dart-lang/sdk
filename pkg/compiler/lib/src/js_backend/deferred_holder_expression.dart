// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_ast/src/precedence.dart' as js show PRIMARY;

import '../common_elements.dart' show JCommonElements;
import '../elements/entities.dart';
import '../js/js.dart' as js;
import '../serialization/serialization.dart';
import '../util/util.dart';

import 'namer.dart';

// TODO(joshualitt): Figure out how to subsume more of the modular naming
// framework into this approach. For example, we are still creating ModularNames
// for the entity referenced in the DeferredHolderExpression.
enum DeferredHolderExpressionKind {
  globalObjectForStaticState,
  globalObjectForConstants,
  globalObjectForLibrary,
  globalObjectForClass,
  globalObjectForType,
  globalObjectForMember,
}

/// A [DeferredHolderExpression] is a deferred JavaScript expression determined
/// by the finalization of holders. It is the injection point for data or
/// code to related to holders. The actual [Expression] contained within the
/// [DeferredHolderExpression] is determined by the
/// [DeferredHolderExpressionKind], eventually, most will be a [PropertyAccess]
/// but currently all are [VariableUse]s.
class DeferredHolderExpression extends js.DeferredExpression
    implements js.AstContainer {
  static const String tag = 'deferred-holder-expression';

  final DeferredHolderExpressionKind kind;
  final Entity entity;
  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  DeferredHolderExpression(this.kind, this.entity) : sourceInformation = null;
  DeferredHolderExpression._(
      this.kind, this.entity, this._value, this.sourceInformation);
  factory DeferredHolderExpression.forConstants() {
    return DeferredHolderExpression(
        DeferredHolderExpressionKind.globalObjectForConstants, null);
  }

  factory DeferredHolderExpression.forStaticState() {
    return DeferredHolderExpression(
        DeferredHolderExpressionKind.globalObjectForStaticState, null);
  }

  factory DeferredHolderExpression.readFromDataSource(DataSource source) {
    source.begin(tag);
    var kind = source.readEnum(DeferredHolderExpressionKind.values);
    Entity entity;
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        entity = source.readLibrary();
        break;
      case DeferredHolderExpressionKind.globalObjectForClass:
        entity = source.readClass();
        break;
      case DeferredHolderExpressionKind.globalObjectForType:
        entity = source.readClass();
        break;
      case DeferredHolderExpressionKind.globalObjectForMember:
        entity = source.readMember();
        break;
      case DeferredHolderExpressionKind.globalObjectForStaticState:
      case DeferredHolderExpressionKind.globalObjectForConstants:
        // no entity.
        break;
    }
    source.end(tag);
    return DeferredHolderExpression(kind, entity);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        sink.writeLibrary(entity);
        break;
      case DeferredHolderExpressionKind.globalObjectForClass:
        sink.writeClass(entity);
        break;
      case DeferredHolderExpressionKind.globalObjectForType:
        sink.writeClass(entity);
        break;
      case DeferredHolderExpressionKind.globalObjectForMember:
        sink.writeMember(entity);
        break;
      case DeferredHolderExpressionKind.globalObjectForStaticState:
      case DeferredHolderExpressionKind.globalObjectForConstants:
        // no entity.
        break;
    }
    sink.end(tag);
  }

  set value(js.Expression value) {
    assert(!isFinalized && value != null);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(isFinalized, '$this is unassigned');
    return _value;
  }

  @override
  bool get isFinalized => _value != null;

  @override
  DeferredHolderExpression withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return DeferredHolderExpression._(
        kind, entity, _value, newSourceInformation);
  }

  @override
  int get precedenceLevel => _value?.precedenceLevel ?? js.PRIMARY;

  @override
  int get hashCode {
    return Hashing.objectsHash(kind, entity);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeferredHolderExpression &&
        kind == other.kind &&
        entity == other.entity;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('DeferredHolderExpression(kind=$kind,entity=$entity,');
    sb.write('value=$_value)');
    return sb.toString();
  }

  @override
  Iterable<js.Node> get containedNodes => isFinalized ? [_value] : const [];
}

/// A [DeferredHolderParameter] is a deferred JavaScript expression determined
/// by the finalization of holders. It is the injection point for data or
/// code to related to holders. This class does not support serialization.
/// TODO(joshualitt): Today this exists just for the static state holder.
/// Ideally we'd be able to treat the static state holder like other holders.
class DeferredHolderParameter extends js.Expression implements js.Parameter {
  String _name;

  @override
  final bool allowRename = false;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  DeferredHolderParameter() : sourceInformation = null;
  DeferredHolderParameter._(this._name, this.sourceInformation);

  set name(String name) {
    assert(!isFinalized && name != null);
    _name = name;
  }

  @override
  String get name {
    assert(isFinalized, '$this is unassigned');
    return _name;
  }

  @override
  bool get isFinalized => _name != null;

  @override
  DeferredHolderParameter withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return DeferredHolderParameter._(_name, newSourceInformation);
  }

  @override
  int get precedenceLevel => js.PRIMARY;

  @override
  T accept<T>(js.NodeVisitor<T> visitor) => visitor.visitParameter(this);

  @override
  R accept1<R, A>(js.NodeVisitor1<R, A> visitor, A arg) =>
      visitor.visitParameter(this, arg);

  @override
  void visitChildren<T>(js.NodeVisitor<T> visitor) {}

  @override
  void visitChildren1<R, A>(js.NodeVisitor1<R, A> visitor, A arg) {}

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('DeferredHolderParameter(name=$_name)');
    return sb.toString();
  }
}

enum DeferredHolderResourceKind {
  declaration,
  update,
}

/// A [DeferredHolderResource] is a deferred JavaScript statement determined by
/// the finalization of holders. It is the injection point for data or
/// code to holders. The actual [Statement] contained with the
/// [DeferredHolderResource] will be determined by the
/// [DeferredHolderResourceKind]. These [Statement]s differ considerably
/// depending on where they are used in the AST. This class does not support
/// serialization.
class DeferredHolderResource extends js.DeferredStatement
    implements js.AstContainer {
  DeferredHolderResourceKind kind;
  Map<Entity, List<js.Property>> holderCode;
  bool initializeEmptyHolders;
  js.Statement _statement;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  DeferredHolderResource(this.kind,
      {this.holderCode: const {}, this.initializeEmptyHolders: false})
      : sourceInformation = null;

  DeferredHolderResource._(this.kind, this.holderCode,
      this.initializeEmptyHolders, this._statement, this.sourceInformation);

  set statement(js.Statement statement) {
    assert(!isFinalized && statement != null);
    _statement = statement;
  }

  @override
  js.Statement get statement {
    assert(isFinalized, 'DeferredHolderResource is unassigned');
    return _statement;
  }

  @override
  bool get isFinalized => _statement != null;

  @override
  DeferredHolderResource withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return DeferredHolderResource._(kind, holderCode, initializeEmptyHolders,
        _statement, newSourceInformation);
  }

  @override
  Iterable<js.Node> get containedNodes => isFinalized ? [_statement] : const [];

  @override
  void visitChildren<T>(js.NodeVisitor<T> visitor) {
    _statement?.accept<T>(visitor);
  }

  @override
  void visitChildren1<R, A>(js.NodeVisitor1<R, A> visitor, A arg) {
    _statement?.accept1<R, A>(visitor, arg);
  }
}

enum DeferredHolderResourceExpressionKind {
  constantHolderReference,
}

/// Similar to [DeferredHolderExpression], [DeferredHolderResourceExpression]
/// is used by resources which want to insert a DeferredExpression into the
/// ast. This class does not support serialization.
class DeferredHolderResourceExpression extends js.DeferredExpression
    implements js.AstContainer {
  final DeferredHolderResourceExpressionKind kind;
  final Entity entity;
  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  DeferredHolderResourceExpression(this.kind, this.entity)
      : sourceInformation = null;
  DeferredHolderResourceExpression._(
      this.kind, this.entity, this._value, this.sourceInformation);

  factory DeferredHolderResourceExpression.constantHolderReference() {
    return DeferredHolderResourceExpression(
        DeferredHolderResourceExpressionKind.constantHolderReference, null);
  }

  set value(js.Expression value) {
    assert(!isFinalized && value != null);
    _value = value;
  }

  @override
  js.Expression get value {
    assert(isFinalized, '$this is unassigned');
    return _value;
  }

  @override
  bool get isFinalized => _value != null;

  @override
  DeferredHolderResourceExpression withSourceInformation(
      js.JavaScriptNodeSourceInformation newSourceInformation) {
    if (newSourceInformation == sourceInformation) return this;
    if (newSourceInformation == null) return this;
    return DeferredHolderResourceExpression._(
        kind, entity, _value, newSourceInformation);
  }

  @override
  int get precedenceLevel => _value?.precedenceLevel ?? js.PRIMARY;

  @override
  int get hashCode {
    return Hashing.objectsHash(kind, entity);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeferredHolderExpression &&
        kind == other.kind &&
        entity == other.entity;
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('DeferredHolderResourceExpression(kind=$kind,entity=$entity,');
    sb.write('value=$_value)');
    return sb.toString();
  }

  @override
  Iterable<js.Node> get containedNodes => isFinalized ? [_value] : const [];
}

abstract class DeferredHolderExpressionFinalizer {
  /// Collects DeferredHolderExpressions from the JavaScript
  /// AST [code];
  void addCode(js.Node code);

  /// Performs analysis on all collected DeferredHolderExpression nodes
  /// finalizes the values to expressions to access the holders.
  void finalize();
}

/// [DeferredHolderExpressionFinalizerImpl] finalizes
/// [DeferredHolderExpression]s, [DeferredHolderParameter]s,
/// [DeferredHolderResource]s, [DeferredHolderResourceExpression]s.
class DeferredHolderExpressionFinalizerImpl
    implements DeferredHolderExpressionFinalizer {
  _DeferredHolderExpressionCollectorVisitor _visitor;
  final List<DeferredHolderExpression> holderReferences = [];
  final List<DeferredHolderParameter> holderParameters = [];
  final List<DeferredHolderResource> holderResources = [];
  final List<DeferredHolderResourceExpression> holderResourceExpressions = [];
  final Set<String> _uniqueHolders = {};
  final List<String> _holders = [];
  final Map<Entity, String> _entityMap = {};
  final JCommonElements _commonElements;

  DeferredHolderExpressionFinalizerImpl(this._commonElements) {
    _visitor = _DeferredHolderExpressionCollectorVisitor(this);
  }

  @override
  void addCode(js.Node code) {
    code.accept(_visitor);
  }

  final List<String> userGlobalObjects =
      new List.from(Namer.reservedGlobalObjectNames)
        ..remove('C')
        ..remove('H')
        ..remove('J')
        ..remove('P')
        ..remove('W');

  /// Returns the [reservedGlobalObjectNames] for [library].
  String globalObjectForLibrary(LibraryEntity library) {
    if (library == _commonElements.interceptorsLibrary) return 'J';
    Uri uri = library.canonicalUri;
    if (uri.scheme == 'dart') {
      if (uri.path == 'html') return 'W';
      if (uri.path.startsWith('_')) return 'H';
      return 'P';
    }
    return userGlobalObjects[library.name.hashCode % userGlobalObjects.length];
  }

  /// Returns true if [element] is stored in the static state holder
  /// ([staticStateHolder]).  We intend to store only mutable static state
  /// there, whereas constants are stored in 'C'. Functions, accessors,
  /// classes, etc. are stored in one of the other objects in
  /// [reservedGlobalObjectNames].
  bool _isPropertyOfStaticStateHolder(MemberEntity element) {
    // TODO(ahe): Make sure this method's documentation is always true and
    // remove the word "intend".
    return element.isField;
  }

  String globalObjectForMember(MemberEntity entity) {
    if (_isPropertyOfStaticStateHolder(entity)) {
      return globalObjectForStaticState();
    } else {
      return globalObjectForLibrary(entity.library);
    }
  }

  String globalObjectForClass(ClassEntity entity) {
    return globalObjectForLibrary(entity.library);
  }

  String globalObjectForType(Entity entity) {
    return globalObjectForClass(entity);
  }

  String globalObjectForStaticState() => r'$';

  String globalObjectForConstants() => 'C';

  String globalObjectForEntity(Entity entity) {
    if (entity is MemberEntity) {
      return globalObjectForMember(entity);
    } else if (entity is ClassEntity) {
      return globalObjectForLibrary(entity.library);
    } else {
      assert(entity is LibraryEntity);
      return globalObjectForLibrary(entity);
    }
  }

  /// Registers an [Entity] with a specific [holder].
  void registerHolderUse(String holder, Entity entity) {
    if (_uniqueHolders.add(holder)) _holders.add(holder);
    if (entity != null) {
      assert(!_entityMap.containsKey(entity) || _entityMap[entity] == holder);
      _entityMap[entity] = holder;
    }
  }

  /// Returns a global object for a given [Entity] based on the
  /// [DeferredHolderExpressionKind].
  String kindToHolder(DeferredHolderExpressionKind kind, Entity entity) {
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        return globalObjectForLibrary(entity);
      case DeferredHolderExpressionKind.globalObjectForClass:
        return globalObjectForClass(entity);
      case DeferredHolderExpressionKind.globalObjectForType:
        return globalObjectForType(entity);
      case DeferredHolderExpressionKind.globalObjectForMember:
        return globalObjectForMember(entity);
      case DeferredHolderExpressionKind.globalObjectForConstants:
        return globalObjectForConstants();
      case DeferredHolderExpressionKind.globalObjectForStaticState:
        return globalObjectForStaticState();
    }
    throw UnsupportedError("Unreachable");
  }

  /// Finalizes [DeferredHolderExpression]s [DeferredHolderParameter]s.
  void finalizeReferences() {
    // Finalize [DeferredHolderExpression]s and registers holder usage.
    for (var reference in holderReferences) {
      if (reference.isFinalized) continue;
      Entity entity = reference.entity;
      String holder = kindToHolder(reference.kind, entity);
      js.Expression value = js.VariableUse(holder);
      registerHolderUse(holder, entity);
      reference.value =
          value.withSourceInformation(reference.sourceInformation);
    }

    // Finalize [DeferredHolderParameter]s.
    for (var parameter in holderParameters) {
      if (parameter.isFinalized) continue;
      parameter.name = globalObjectForStaticState();
    }
  }

  /// Registers all of the holders used by a given [DeferredHolderResource].
  void registerHolders(DeferredHolderResource resource) {
    for (var entity in resource.holderCode.keys) {
      var holder = globalObjectForEntity(entity);
      registerHolderUse(holder, entity);
    }
  }

  /// Returns a [List<String>] containing all of the holders except the static
  /// state holder.
  List<String> get nonStaticStateHolders {
    return _holders
        .where((holder) => holder != globalObjectForStaticState())
        .toList(growable: false);
  }

  /// Generates code to declare holders.
  HolderCode declareHolders(DeferredHolderResource resource) {
    // Collect all holders except the static state holder. Then, create a map of
    // holder to list of properties which are associated with that holder, but
    // only with respect to a given [DeferredHolderResource]. Each fragment will
    // have its own [DeferredHolderResource] and associated code.
    Map<String, List<js.Property>> codePerHolder = {};
    final holders = nonStaticStateHolders;
    for (var holder in holders) {
      codePerHolder[holder] = [];
    }

    final holderCode = resource.holderCode;
    holderCode.forEach((entity, properties) {
      assert(_entityMap.containsKey(entity));
      var holder = _entityMap[entity];
      assert(codePerHolder.containsKey(holder));
      codePerHolder[holder].addAll(properties);
    });

    // Create holder initialization code based on the [codePerHolder]. If there
    // are no properties associated with a given holder in this specific
    // [DeferredHolderResource] then it will be omitted. However, in some cases,
    // i.e. the main output unit, we still want to declare the holder with an
    // empty object literal which will be filled in later by another
    // [DeferredHolderResource], i.e. in a specific deferred fragment.
    // The generated code looks like this:
    //
    //    {
    //      var H = {...}, ..., G = {...};
    //      var holders = [ H, ..., G ]; // Main unit only.
    //    }

    List<String> activeHolders = [];
    List<js.VariableInitialization> holderInitializations = [];
    for (var holder in holders) {
      List<js.Property> properties = codePerHolder[holder];
      if (properties.isEmpty) {
        holderInitializations.add(js.VariableInitialization(
            js.VariableDeclaration(holder, allowRename: false),
            resource.initializeEmptyHolders
                ? js.ObjectInitializer(properties)
                : null));
      } else {
        activeHolders.add(holder);
        holderInitializations.add(js.VariableInitialization(
            js.VariableDeclaration(holder, allowRename: false),
            js.ObjectInitializer(properties)));
      }
    }

    List<js.Statement> statements = [];
    statements.add(js.ExpressionStatement(js.VariableDeclarationList(
        holderInitializations,
        indentSplits: false)));
    if (resource.initializeEmptyHolders) {
      statements.add(js.js.statement(
          'var holders = #',
          js.ArrayInitializer(holders
              .map((holder) => js.VariableUse(holder))
              .toList(growable: false))));
    }
    return HolderCode(activeHolders, statements);
  }

  /// Finalizes [resource] to code that updates holders. [resource] must be in
  /// the AST of a deferred fragment.
  void updateHolders(DeferredHolderResource resource) {
    // Declare holders.
    final holderCode = declareHolders(resource);

    // Set names if necessary on deferred holders list.
    js.Expression deferredHoldersList = js.ArrayInitializer(holderCode
        .activeHolders
        .map((holder) => js.js("#", holder))
        .toList(growable: false));
    js.Statement setNames = js.js.statement(
        'hunkHelpers.setFunctionNamesIfNecessary(#deferredHoldersList)',
        {'deferredHoldersList': deferredHoldersList});

    // Update holder assignments.
    final holders = nonStaticStateHolders;
    List<js.Statement> updateHolderAssignments = [setNames];
    for (int i = 0; i < holders.length; i++) {
      var holder = holders[i];
      if (holderCode.activeHolders.contains(holder)) {
        updateHolderAssignments.add(js.js.statement(
            '#holder = hunkHelpers.updateHolder(holdersList[#index], #holder)',
            {'index': js.number(i), 'holder': js.VariableUse(holder)}));
      } else {
        // TODO(sra): Change declaration followed by assignments to declarations
        // with initialization.
        updateHolderAssignments.add(js.js.statement(
            '#holder = holdersList[#index]',
            {'index': js.number(i), 'holder': js.VariableUse(holder)}));
      }
    }

    // Create a single block of all statements.
    List<js.Statement> statements = holderCode.statements
        .followedBy(updateHolderAssignments)
        .toList(growable: false);
    resource.statement = js.Block(statements);
  }

  /// Creates a reference to the constant holder.
  void allocateConstantHolderReference(
      DeferredHolderResourceExpression resource) {
    String constantHolder = _holders.firstWhere(
        (holder) => holder == globalObjectForConstants(),
        orElse: () => null);
    resource.value = constantHolder == null
        ? js.LiteralNull()
        : js.VariableUse(constantHolder);
  }

  /// Allocates all [DeferredHolderResource]s and
  /// [DeferredHolderResourceExpression]s.
  void allocateResources() {
    // First ensure all holders used in all [DeferredHolderResource]s have been
    // allocated.
    for (var resource in holderResources) {
      registerHolders(resource);
    }
    _holders.sort();

    // Next finalize all [DeferredHolderResource]s.
    for (var resource in holderResources) {
      switch (resource.kind) {
        case DeferredHolderResourceKind.declaration:
          var holderCode = declareHolders(resource);
          resource.statement = js.Block(holderCode.statements);
          break;
        case DeferredHolderResourceKind.update:
          updateHolders(resource);
          break;
      }
    }

    // Finally, finalize any [DeferredHolderResourceExpression]s.
    for (var resource in holderResourceExpressions) {
      switch (resource.kind) {
        case DeferredHolderResourceExpressionKind.constantHolderReference:
          allocateConstantHolderReference(resource);
          break;
      }
    }
  }

  @override
  void finalize() {
    finalizeReferences();
    allocateResources();
  }

  void _registerDeferredHolderExpression(DeferredHolderExpression node) {
    holderReferences.add(node);
  }

  void _registerDeferredHolderResource(DeferredHolderResource node) {
    holderResources.add(node);
  }

  void _registerDeferredHolderResourceExpression(
      DeferredHolderResourceExpression node) {
    holderResourceExpressions.add(node);
  }

  void _registerDeferredHolderParameter(DeferredHolderParameter node) {
    holderParameters.add(node);
  }
}

/// Scans a JavaScript AST to collect all the [DeferredHolderExpression],
/// [DeferredHolderParameter], [DeferredHolderResource], and
/// [DeferredHolderResourceExpression] nodes.
///
/// The state is kept in the finalizer so that this scan could be extended to
/// look for other deferred expressions in one pass.
class _DeferredHolderExpressionCollectorVisitor extends js.BaseVisitor<void> {
  final DeferredHolderExpressionFinalizerImpl _finalizer;

  _DeferredHolderExpressionCollectorVisitor(this._finalizer);

  @override
  void visitNode(js.Node node) {
    assert(node is! DeferredHolderExpression);
    if (node is js.AstContainer) {
      for (js.Node element in node.containedNodes) {
        element.accept(this);
      }
    } else {
      super.visitNode(node);
    }
  }

  @override
  void visitDeferredExpression(js.DeferredExpression node) {
    if (node is DeferredHolderExpression) {
      _finalizer._registerDeferredHolderExpression(node);
    } else if (node is DeferredHolderResourceExpression) {
      _finalizer._registerDeferredHolderResourceExpression(node);
    } else {
      visitNode(node);
    }
  }

  @override
  void visitDeferredStatement(js.DeferredStatement node) {
    if (node is DeferredHolderResource) {
      _finalizer._registerDeferredHolderResource(node);
    } else {
      visitNode(node);
    }
  }

  @override
  void visitParameter(js.Parameter node) {
    if (node is DeferredHolderParameter) {
      _finalizer._registerDeferredHolderParameter(node);
    } else {
      visitNode(node);
    }
  }
}

class HolderCode {
  final List<String> activeHolders;
  final List<js.Statement> statements;
  HolderCode(this.activeHolders, this.statements);
}
