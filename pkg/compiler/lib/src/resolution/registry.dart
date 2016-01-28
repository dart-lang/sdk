// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.resolution.registry;

import '../common.dart';
import '../common/backend_api.dart' show
    Backend,
    ForeignResolver;
import '../common/resolution.dart' show
    Feature,
    ListLiteralUse,
    MapLiteralUse,
    ResolutionImpact;
import '../common/registry.dart' show
    Registry;
import '../compiler.dart' show
    Compiler;
import '../constants/expressions.dart';
import '../dart_types.dart';
import '../diagnostics/source_span.dart';
import '../enqueue.dart' show
    ResolutionEnqueuer;
import '../elements/elements.dart';
import '../tree/tree.dart';
import '../util/util.dart' show
    Setlet;
import '../universe/call_structure.dart' show
    CallStructure;
import '../universe/selector.dart' show
    Selector;
import '../universe/use.dart' show
    DynamicUse,
    StaticUse,
    TypeUse;
import '../universe/world_impact.dart' show
    WorldImpactBuilder;
import '../util/enumset.dart' show
    EnumSet;
import '../world.dart' show
    World;

import 'send_structure.dart';

import 'members.dart' show
    ResolverVisitor;
import 'tree_elements.dart' show
    TreeElementMapping;

class _ResolutionWorldImpact extends ResolutionImpact with WorldImpactBuilder {
  final String name;
  EnumSet<Feature> _features;
  Setlet<MapLiteralUse> _mapLiterals;
  Setlet<ListLiteralUse> _listLiterals;
  Setlet<String> _constSymbolNames;
  Setlet<ConstantExpression> _constantLiterals;

  _ResolutionWorldImpact(this.name);

  void registerMapLiteral(MapLiteralUse mapLiteralUse) {
    assert(mapLiteralUse != null);
    if (_mapLiterals == null) {
      _mapLiterals = new Setlet<MapLiteralUse>();
    }
    _mapLiterals.add(mapLiteralUse);
  }

  @override
  Iterable<MapLiteralUse> get mapLiterals {
    return _mapLiterals != null
        ? _mapLiterals : const <MapLiteralUse>[];
  }

  void registerListLiteral(ListLiteralUse listLiteralUse) {
    assert(listLiteralUse != null);
    if (_listLiterals == null) {
      _listLiterals = new Setlet<ListLiteralUse>();
    }
    _listLiterals.add(listLiteralUse);
  }

  @override
  Iterable<ListLiteralUse> get listLiterals {
    return _listLiterals != null
        ? _listLiterals : const <ListLiteralUse>[];
  }

  void registerConstSymbolName(String name) {
    if (_constSymbolNames == null) {
      _constSymbolNames = new Setlet<String>();
    }
    _constSymbolNames.add(name);
  }

  @override
  Iterable<String> get constSymbolNames {
    return _constSymbolNames != null
        ? _constSymbolNames : const <String>[];
  }

  void registerFeature(Feature feature) {
    if (_features == null) {
      _features = new EnumSet<Feature>();
    }
    _features.add(feature);
  }

  @override
  Iterable<Feature> get features {
    return _features != null
        ? _features.iterable(Feature.values) : const <Feature>[];
  }

  void registerConstantLiteral(ConstantExpression constant) {
    if (_constantLiterals == null) {
      _constantLiterals = new Setlet<ConstantExpression>();
    }
    _constantLiterals.add(constant);
  }

  Iterable<ConstantExpression> get constantLiterals {
    return _constantLiterals != null
        ? _constantLiterals : const <ConstantExpression>[];
  }

  String toString() => '_ResolutionWorldImpact($name)';
}

/// [ResolutionRegistry] collects all resolution information. It stores node
/// related information in a [TreeElements] mapping and registers calls with
/// [Backend], [World] and [Enqueuer].
// TODO(johnniwinther): Split this into an interface and implementation class.
class ResolutionRegistry extends Registry {
  final Compiler compiler;
  final TreeElementMapping mapping;
  final _ResolutionWorldImpact worldImpact;

  ResolutionRegistry(Compiler compiler, TreeElementMapping mapping)
      : this.compiler = compiler,
        this.mapping = mapping,
        this.worldImpact = new _ResolutionWorldImpact(
            mapping.analyzedElement.toString());

  bool get isForResolution => true;

  ResolutionEnqueuer get world => compiler.enqueuer.resolution;

  World get universe => compiler.world;

  Backend get backend => compiler.backend;

  String toString() => 'ResolutionRegistry for ${mapping.analyzedElement}';

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Element mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  /// Register [node] as the declaration of [element].
  void defineFunction(FunctionExpression node, FunctionElement element) {
    // TODO(sigurdm): Remove when not needed by the dart2dart backend.
    if (node.name != null) {
      mapping[node.name] = element;
    }
    mapping[node] = element;
  }

  /// Register [node] as a reference to [element].
  Element useElement(Node node, Element element) {
    if (element == null) return null;
    return mapping[node] = element;
  }

  /// Register [node] as the declaration of [element].
  void defineElement(Node node, Element element) {
    mapping[node] = element;
  }

  /// Returns the [Element] defined by [node].
  Element getDefinition(Node node) {
    return mapping[node];
  }

  /// Sets the loop variable of the for-in [node] to be [element].
  void setForInVariable(ForIn node, Element element) {
    mapping[node] = element;
  }

  /// Sets the target constructor [node] to be [element].
  void setRedirectingTargetConstructor(RedirectingFactoryBody node,
                                       ConstructorElement element) {
    useElement(node, element);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Selector mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  void setSelector(Node node, Selector selector) {
    mapping.setSelector(node, selector);
  }

  void setGetterSelectorInComplexSendSet(SendSet node, Selector selector) {
    mapping.setGetterSelectorInComplexSendSet(node, selector);
  }

  void setOperatorSelectorInComplexSendSet(SendSet node, Selector selector) {
    mapping.setOperatorSelectorInComplexSendSet(node, selector);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Type mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  DartType useType(Node annotation, DartType type) {
    if (type != null) {
      mapping.setType(annotation, type);
    }
    return type;
  }

  void setType(Node node, DartType type) => mapping.setType(node, type);

  DartType getType(Node node) => mapping.getType(node);

  //////////////////////////////////////////////////////////////////////////////
  //  Node-to-Constant mapping functionality.
  //////////////////////////////////////////////////////////////////////////////

  ConstantExpression getConstant(Node node) => mapping.getConstant(node);

  void setConstant(Node node, ConstantExpression constant) {
    mapping.setConstant(node, constant);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Target/Label functionality.
  //////////////////////////////////////////////////////////////////////////////

  /// Register [node] to be the declaration of [label].
  void defineLabel(Label node, LabelDefinition label) {
    mapping.defineLabel(node, label);
  }

  /// Undefine the label of [node].
  /// This is used to cleanup and detect unused labels.
  void undefineLabel(Label node) {
    mapping.undefineLabel(node);
  }

  /// Register the target of [node] as reference to [label].
  void useLabel(GotoStatement node, LabelDefinition label) {
    mapping.registerTargetLabel(node, label);
  }

  /// Register [node] to be the declaration of [target].
  void defineTarget(Node node, JumpTarget target) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    mapping.defineTarget(node, target);
  }

  /// Returns the [JumpTarget] defined by [node].
  JumpTarget getTargetDefinition(Node node) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    return mapping.getTargetDefinition(node);
  }

  /// Undefine the target of [node]. This is used to cleanup unused targets.
  void undefineTarget(Node node) {
    assert(invariant(node, node is Statement || node is SwitchCase,
        message: "Only statements and switch cases can define targets."));
    mapping.undefineTarget(node);
  }

  /// Register the target of [node] to be [target].
  void registerTargetOf(GotoStatement node, JumpTarget target) {
    mapping.registerTargetOf(node, target);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Potential access registration.
  //////////////////////////////////////////////////////////////////////////////

  void setAccessedByClosureIn(Node contextNode, VariableElement element,
                              Node accessNode) {
    mapping.setAccessedByClosureIn(contextNode, element, accessNode);
  }

  void registerPotentialMutation(VariableElement element, Node mutationNode) {
    mapping.registerPotentialMutation(element, mutationNode);
  }

  void registerPotentialMutationInClosure(VariableElement element,
                                           Node mutationNode) {
    mapping.registerPotentialMutationInClosure(element, mutationNode);
  }

  void registerPotentialMutationIn(Node contextNode, VariableElement element,
                                    Node mutationNode) {
    mapping.registerPotentialMutationIn(contextNode, element, mutationNode);
  }

  //////////////////////////////////////////////////////////////////////////////
  //  Various Backend/Enqueuer/World registration.
  //////////////////////////////////////////////////////////////////////////////

  void registerStaticUse(StaticUse staticUse) {
    worldImpact.registerStaticUse(staticUse);
  }

  void registerMetadataConstant(MetadataAnnotation metadata) {
    backend.registerMetadataConstant(metadata, metadata.annotatedElement, this);
  }

  /// Register the use of a type.
  void registerTypeUse(TypeUse typeUse) {
    worldImpact.registerTypeUse(typeUse);
  }

  void registerSuperUse(SourceSpan span) {
    mapping.addSuperUse(span);
  }

  void registerTypeLiteral(Send node, DartType type) {
    mapping.setType(node, type);
    worldImpact.registerTypeUse(new TypeUse.typeLiteral(type));
  }

  void registerLiteralList(Node node,
                           InterfaceType type,
                           {bool isConstant,
                            bool isEmpty}) {
    setType(node, type);
    worldImpact.registerListLiteral(
        new ListLiteralUse(type, isConstant: isConstant, isEmpty: isEmpty));
  }

  void registerMapLiteral(Node node,
                          InterfaceType type,
                          {bool isConstant,
                           bool isEmpty}) {
    setType(node, type);
    worldImpact.registerMapLiteral(
        new MapLiteralUse(type, isConstant: isConstant, isEmpty: isEmpty));
  }

  void registerForeignCall(Node node,
                           Element element,
                           CallStructure callStructure,
                           ResolverVisitor visitor) {
    backend.registerForeignCall(
        node, element, callStructure,
        new ForeignResolutionResolver(visitor, this));
  }

  void registerDynamicUse(DynamicUse dynamicUse) {
    worldImpact.registerDynamicUse(dynamicUse);
  }

  void registerFeature(Feature feature) {
    worldImpact.registerFeature(feature);
  }

  void registerConstSymbol(String name) {
    worldImpact.registerConstSymbolName(name);
  }

  void registerConstantLiteral(ConstantExpression constant) {
    worldImpact.registerConstantLiteral(constant);
  }

  ClassElement defaultSuperclass(ClassElement element) {
    return backend.defaultSuperclass(element);
  }

  void registerMixinUse(MixinApplicationElement mixinApplication,
                        ClassElement mixin) {
    universe.registerMixinUse(mixinApplication, mixin);
  }

  void registerInstantiation(InterfaceType type) {
    worldImpact.registerTypeUse(new TypeUse.instantiation(type));
  }

  void registerSendStructure(Send node, SendStructure sendStructure) {
    mapping.setSendStructure(node, sendStructure);
  }

  void registerNewStructure(NewExpression node, NewStructure newStructure) {
    mapping.setNewStructure(node, newStructure);
  }

  // TODO(johnniwinther): Remove this when [SendStructure]s are part of the
  // [ResolutionResult].
  SendStructure getSendStructure(Send node) {
    return mapping.getSendStructure(node);
  }

  void registerTryStatement() {
    mapping.containsTryStatement = true;
  }
}

class ForeignResolutionResolver implements ForeignResolver {
  final ResolverVisitor visitor;
  final ResolutionRegistry registry;

  ForeignResolutionResolver(this.visitor, this.registry);

  @override
  ConstantExpression getConstant(Node node) {
    return registry.getConstant(node);
  }

  @override
  void registerInstantiatedType(InterfaceType type) {
    registry.registerInstantiation(type);
  }

  @override
  DartType resolveTypeFromString(Node node, String typeName) {
    return visitor.resolveTypeFromString(node, typeName);
  }
}
