// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:js_ast/src/precedence.dart' as js show PRIMARY;

import '../common_elements.dart' show JCommonElements;
import '../elements/entities.dart';
import '../js/js.dart' as js;
import '../serialization/serialization.dart';
import '../util/util.dart';
import '../js_emitter/model.dart' show Fragment;

import 'namer.dart';

// TODO(joshualitt): Figure out how to subsume more of the modular naming
// framework into this approach. For example, we are still creating ModularNames
// for the entity referenced in the DeferredHolderExpression.
enum DeferredHolderExpressionKind {
  globalObjectForStaticState,
  globalObjectForConstant,
  globalObjectForLibrary,
  globalObjectForClass,
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
  final Object data;
  js.Expression _value;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  DeferredHolderExpression(this.kind, this.data) : sourceInformation = null;
  DeferredHolderExpression._(
      this.kind, this.data, this._value, this.sourceInformation);

  factory DeferredHolderExpression.forStaticState() {
    return DeferredHolderExpression(
        DeferredHolderExpressionKind.globalObjectForStaticState, null);
  }

  factory DeferredHolderExpression.readFromDataSource(DataSource source) {
    source.begin(tag);
    var kind = source.readEnum(DeferredHolderExpressionKind.values);
    Object data;
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        data = source.readLibrary();
        break;
      case DeferredHolderExpressionKind.globalObjectForClass:
        data = source.readClass();
        break;
      case DeferredHolderExpressionKind.globalObjectForMember:
        data = source.readMember();
        break;
      case DeferredHolderExpressionKind.globalObjectForConstant:
        data = source.readConstant();
        break;
      case DeferredHolderExpressionKind.globalObjectForStaticState:
        // no entity.
        break;
    }
    source.end(tag);
    return DeferredHolderExpression(kind, data);
  }

  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeEnum(kind);
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        sink.writeLibrary(data);
        break;
      case DeferredHolderExpressionKind.globalObjectForClass:
        sink.writeClass(data);
        break;
      case DeferredHolderExpressionKind.globalObjectForMember:
        sink.writeMember(data);
        break;
      case DeferredHolderExpressionKind.globalObjectForConstant:
        sink.writeConstant(data);
        break;
      case DeferredHolderExpressionKind.globalObjectForStaticState:
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
    return DeferredHolderExpression._(kind, data, _value, newSourceInformation);
  }

  @override
  int get precedenceLevel => _value?.precedenceLevel ?? js.PRIMARY;

  @override
  int get hashCode {
    return Hashing.objectsHash(kind, data);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DeferredHolderExpression &&
        kind == other.kind &&
        data == other.data;
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('DeferredHolderExpression(kind=$kind,data=$data,');
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
    StringBuffer sb = StringBuffer();
    sb.write('DeferredHolderParameter(name=$_name)');
    return sb.toString();
  }
}

enum DeferredHolderResourceKind {
  mainFragment,
  deferredFragment,
}

/// A [DeferredHolderResource] is a deferred JavaScript statement determined by
/// the finalization of holders. Each fragment contains one
/// [DeferredHolderResource]. The actual [Statement] contained with the
/// [DeferredHolderResource] will be determined by the
/// [DeferredHolderResourceKind]. These [Statement]s differ considerably
/// depending on where they are used in the AST. This class is created by the
/// fragment emitter so does not need to support serialization.
class DeferredHolderResource extends js.DeferredStatement
    implements js.AstContainer {
  DeferredHolderResourceKind kind;
  // Each resource has a distinct name.
  String name;
  List<Fragment> fragments;
  Map<Entity, List<js.Property>> holderCode;
  js.Statement _statement;

  @override
  final js.JavaScriptNodeSourceInformation sourceInformation;

  DeferredHolderResource(this.kind, this.name, this.fragments, this.holderCode)
      : sourceInformation = null;

  DeferredHolderResource._(this.kind, this.name, this.fragments,
      this.holderCode, this._statement, this.sourceInformation);

  bool get isMainFragment => kind == DeferredHolderResourceKind.mainFragment;

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
    return DeferredHolderResource._(kind, this.name, this.fragments, holderCode,
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

const String mainResourceName = 'MAIN';

abstract class DeferredHolderExpressionFinalizer {
  /// Collects DeferredHolderExpressions from the JavaScript
  /// AST [code] and associates it with [resourceName].
  void addCode(String resourceName, js.Node code);

  /// Performs analysis on all collected DeferredHolderExpression nodes
  /// finalizes the values to expressions to access the holders.
  void finalize();
}

/// An abstraction representing a [Holder] object, which will contain some
/// portion of the programs code.
class Holder {
  final String name;
  final Map<String, int> refCountPerResource = {};
  final Map<String, List<js.Property>> propertiesPerResource = {};
  int _index;
  int _hashCode;

  Holder(this.name);

  int refCount(String resource) => refCountPerResource[resource];

  void registerUse(String resource) {
    refCountPerResource.update(resource, (count) => count + 1,
        ifAbsent: () => 0);
  }

  void registerUpdate(String resource, List<js.Property> properties) {
    (propertiesPerResource[resource] ??= []).addAll(properties);
    registerUse(resource);
  }

  int get index {
    assert(_index != null);
    return _index;
  }

  set index(int newIndex) {
    assert(_index == null);
    _index = newIndex;
  }

  @override
  bool operator ==(that) {
    return that is Holder && name == that.name;
  }

  @override
  int get hashCode {
    return _hashCode ??= Hashing.objectsHash(name);
  }
}

/// [DeferredHolderExpressionFinalizerImpl] finalizes
/// [DeferredHolderExpression]s, [DeferredHolderParameter]s,
/// [DeferredHolderResource]s, [DeferredHolderResourceExpression]s.
class DeferredHolderExpressionFinalizerImpl
    implements DeferredHolderExpressionFinalizer {
  _DeferredHolderExpressionCollectorVisitor _visitor;
  final Map<String, List<DeferredHolderExpression>> holderReferences = {};
  final List<DeferredHolderParameter> holderParameters = [];
  final List<DeferredHolderResource> holderResources = [];
  final Map<String, Set<Holder>> holdersPerResource = {};
  final Map<String, Holder> holderMap = {};
  final JCommonElements _commonElements;
  DeferredHolderResource mainHolderResource;

  DeferredHolderExpressionFinalizerImpl(this._commonElements) {
    _visitor = _DeferredHolderExpressionCollectorVisitor(this);
  }

  @override
  void addCode(String resourceName, js.Node code) {
    _visitor.setResourceNameAndVisit(resourceName, code);
  }

  final List<String> userGlobalObjects =
      List.from(Namer.reservedGlobalObjectNames)
        ..remove('C')
        ..remove('H')
        ..remove('J')
        ..remove('P')
        ..remove('W');

  /// Returns the [reservedGlobalObjectNames] for [library].
  String globalObjectNameForLibrary(LibraryEntity library) {
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

  String globalObjectNameForMember(MemberEntity entity) {
    if (_isPropertyOfStaticStateHolder(entity)) {
      return globalObjectNameForStaticState();
    } else {
      return globalObjectNameForLibrary(entity.library);
    }
  }

  String globalObjectNameForClass(ClassEntity entity) {
    return globalObjectNameForLibrary(entity.library);
  }

  final Holder globalObjectForStaticState =
      Holder(globalObjectNameForStaticState());

  static String globalObjectNameForStaticState() => r'$';

  String globalObjectNameForConstants() => 'C';

  String globalObjectNameForEntity(Entity entity) {
    if (entity is MemberEntity) {
      return globalObjectNameForMember(entity);
    } else if (entity is ClassEntity) {
      return globalObjectNameForLibrary(entity.library);
    } else {
      assert(entity is LibraryEntity);
      return globalObjectNameForLibrary(entity);
    }
  }

  Holder holderNameToHolder(String holderKey) {
    if (holderKey == globalObjectNameForStaticState()) {
      return globalObjectForStaticState;
    } else {
      return holderMap[holderKey];
    }
  }

  Holder globalObjectForEntity(Entity entity) {
    return holderNameToHolder(globalObjectNameForEntity(entity));
  }

  /// Registers a [holder] use within a given [resource], if [properties] are
  /// provided then it is assumed this is an update to a holder.
  void registerHolderUseOrUpdate(String resourceName, String holderName,
      {List<js.Property> properties}) {
    // For simplicity, we don't currently track the static state holder per
    // resource.
    if (holderName == globalObjectNameForStaticState()) return;
    Holder holder = holderMap[holderName] ??= Holder(holderName);
    if (properties == null) {
      holder.registerUse(resourceName);
    } else {
      holder.registerUpdate(resourceName, properties);
    }
    (holdersPerResource[resourceName] ??= {}).add(holder);
  }

  /// Returns a key to a global object for a given [Object] based on the
  /// [DeferredHolderExpressionKind].
  String kindToHolderName(DeferredHolderExpressionKind kind, Object data) {
    switch (kind) {
      case DeferredHolderExpressionKind.globalObjectForLibrary:
        return globalObjectNameForLibrary(data);
      case DeferredHolderExpressionKind.globalObjectForClass:
        return globalObjectNameForClass(data);
      case DeferredHolderExpressionKind.globalObjectForMember:
        return globalObjectNameForMember(data);
      case DeferredHolderExpressionKind.globalObjectForConstant:
        return globalObjectNameForConstants();
      case DeferredHolderExpressionKind.globalObjectForStaticState:
        return globalObjectNameForStaticState();
    }
    throw UnsupportedError("Unreachable");
  }

  /// Returns a global object for a given [Object] based on the
  /// [DeferredHolderExpressionKind].
  Holder kindToHolder(DeferredHolderExpressionKind kind, Object data) {
    return holderNameToHolder(kindToHolderName(kind, data));
  }

  /// Finalizes [DeferredHolderParameter]s.
  void finalizeParameters() {
    for (var parameter in holderParameters) {
      if (parameter.isFinalized) continue;
      parameter.name = globalObjectNameForStaticState();
    }
  }

  /// Finalizes all of the [DeferredHolderExpression]s associated with a
  /// [DeferredHolderResource].
  void finalizeReferences(DeferredHolderResource resource) {
    if (!holderReferences.containsKey(resource.name)) return;
    for (var reference in holderReferences[resource.name]) {
      if (reference.isFinalized) continue;
      String holder = kindToHolder(reference.kind, reference.data).name;
      js.Expression value = js.VariableUse(holder);
      reference.value =
          value.withSourceInformation(reference.sourceInformation);
    }
  }

  /// Registers all of the holders used in the entire program.
  void registerHolders() {
    // Register all holders used in all [DeferredHolderResource]s.
    for (var resource in holderResources) {
      resource.holderCode.forEach((entity, properties) {
        String holderName = globalObjectNameForEntity(entity);
        registerHolderUseOrUpdate(resource.name, holderName,
            properties: properties);
      });
    }

    // Register all holders used in [DeferredHolderReference]s.
    holderReferences.forEach((resource, references) {
      for (var reference in references) {
        String holderName = kindToHolderName(reference.kind, reference.data);
        registerHolderUseOrUpdate(resource, holderName);
      }
    });
  }

  /// Returns an [Iterable<Holder>] containing all of the holders used within a
  /// given [DeferredHolderResource]except the static state holder (if any).
  Iterable<Holder> nonStaticStateHolders(DeferredHolderResource resource) {
    return holdersPerResource[resource.name] ?? [];
  }

  /// Returns an [Iterable<Holder>] containing all of the holders used within a
  /// given [DeferredHolderResource] except the static state holder.
  Iterable<Holder> get allNonStaticStateHolders {
    return holderMap.values;
  }

  /// Generates code to declare holders for a given [resourceName].
  HolderInitCode declareHolders(String resourceName, Iterable<Holder> holders,
      {bool initializeEmptyHolders = false}) {
    // Create holder initialization code. If there are no properties
    // associated with a given holder in this specific [DeferredHolderResource]
    // then it will be omitted. However, in some cases, i.e. the main output
    // unit, we still want to declare the holder with an empty object literal
    // which will be filled in later by another [DeferredHolderResource], i.e.
    // in a specific deferred fragment. The generated code looks like this:
    //
    //    {
    //      var H = {...}, ..., G = {...};
    //    }

    List<Holder> activeHolders = [];
    List<js.VariableInitialization> holderInitializations = [];
    for (var holder in holders) {
      var holderName = holder.name;
      List<js.Property> properties =
          holder.propertiesPerResource[resourceName] ?? [];
      if (properties.isEmpty) {
        holderInitializations.add(js.VariableInitialization(
            js.VariableDeclaration(holderName, allowRename: false),
            initializeEmptyHolders ? js.ObjectInitializer(properties) : null));
      } else {
        activeHolders.add(holder);
        holderInitializations.add(js.VariableInitialization(
            js.VariableDeclaration(holderName, allowRename: false),
            js.ObjectInitializer(properties)));
      }
    }

    // Create statement to initialize holders.
    var initStatement = js.ExpressionStatement(
        js.VariableDeclarationList(holderInitializations, indentSplits: false));
    return HolderInitCode(holders, activeHolders, initStatement);
  }

  /// Finalizes [resource] to code that updates holders. [resource] must be in
  /// the AST of a deferred fragment.
  void updateHolders(DeferredHolderResource resource) {
    final holderCode =
        declareHolders(resource.name, nonStaticStateHolders(resource));

    // Set names if necessary on deferred holders list.
    js.Expression deferredHoldersList = js.ArrayInitializer(holderCode
        .activeHolders
        .map((holder) => js.js("#", holder.name))
        .toList(growable: false));
    js.Statement setNames = js.js.statement(
        'hunkHelpers.setFunctionNamesIfNecessary(#deferredHoldersList)',
        {'deferredHoldersList': deferredHoldersList});

    // Update holder assignments.
    List<js.Statement> updateHolderAssignments = [
      holderCode.statement,
      setNames
    ];
    for (var holder in holderCode.allHolders) {
      var holderName = holder.name;
      var holderIndex = js.number(holder.index);
      if (holderCode.activeHolders.contains(holder)) {
        updateHolderAssignments.add(js.js.statement(
            '#holder = hunkHelpers.updateHolder(holdersList[#index], #holder)',
            {'index': holderIndex, 'holder': js.VariableUse(holderName)}));
      } else {
        // TODO(sra): Change declaration followed by assignments to declarations
        // with initialization.
        updateHolderAssignments.add(js.js.statement(
            '#holder = holdersList[#index]',
            {'index': holderIndex, 'holder': js.VariableUse(holderName)}));
      }
    }

    // Create a single block of all statements.
    resource.statement = js.Block(updateHolderAssignments);
  }

  /// Declares all holders in the [DeferredHolderResource] representing the main
  /// fragment.
  void declareHoldersInMainResource() {
    // Declare holders in main output unit.
    var holders = allNonStaticStateHolders;
    var holderCode = declareHolders(mainHolderResource.name, holders,
        initializeEmptyHolders: true);

    // Create holder uses and init holder indices.
    List<js.VariableUse> holderUses = [];
    int i = 0;
    for (var holder in holders) {
      holder.index = i++;
      holderUses.add(js.VariableUse(holder.name));
    }

    // Create holders array statement.
    //    {
    //      var holders = [ H, ..., G ];
    //    }
    var holderArray =
        js.js.statement('var holders = #', js.ArrayInitializer(holderUses));

    mainHolderResource.statement =
        js.Block([holderCode.statement, holderArray]);
  }

  /// Allocates all [DeferredHolderResource]s and finalizes the associated
  /// [DeferredHolderExpression]s.
  void allocateResourcesAndFinalizeReferences() {
    // First finalize all holders in the main output unit.
    declareHoldersInMainResource();

    // Next finalize all [DeferredHolderResource]s.
    for (var resource in holderResources) {
      switch (resource.kind) {
        case DeferredHolderResourceKind.mainFragment:
          // There should only be one main resource and at this point it
          // should have already been finalized.
          assert(mainHolderResource == resource && resource.isFinalized);
          break;
        case DeferredHolderResourceKind.deferredFragment:
          updateHolders(resource);
          break;
      }
      finalizeReferences(resource);
    }
  }

  @override
  void finalize() {
    registerHolders();
    finalizeParameters();
    allocateResourcesAndFinalizeReferences();
  }

  void _registerDeferredHolderExpression(
      String resourceName, DeferredHolderExpression node) {
    (holderReferences[resourceName] ??= []).add(node);
  }

  void _registerDeferredHolderResource(DeferredHolderResource node) {
    if (node.isMainFragment) {
      assert(mainHolderResource == null);
      mainHolderResource = node;
    }
    holderResources.add(node);
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
  String resourceName;
  final DeferredHolderExpressionFinalizerImpl _finalizer;

  _DeferredHolderExpressionCollectorVisitor(this._finalizer);

  void setResourceNameAndVisit(String resourceName, js.Node code) {
    this.resourceName = resourceName;
    code.accept(this);
    this.resourceName = null;
  }

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
      assert(resourceName != null);
      _finalizer._registerDeferredHolderExpression(resourceName, node);
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

class HolderInitCode {
  final Iterable<Holder> allHolders;
  final List<Holder> activeHolders;
  final js.Statement statement;
  HolderInitCode(this.allHolders, this.activeHolders, this.statement);
}
