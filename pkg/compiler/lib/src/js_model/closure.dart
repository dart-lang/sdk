// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../common/tasks.dart';
import '../constants/expressions.dart';
import '../constants/values.dart';
import '../elements/entities.dart';
import '../elements/names.dart' show Name;
import '../elements/types.dart';
import '../ir/element_map.dart';
import '../ir/util.dart';
import '../js_model/element_map.dart';
import '../js_model/env.dart';
import '../ordered_typeset.dart';
import '../options.dart';
import '../serialization/serialization.dart';
import '../ssa/type_builder.dart';
import '../universe/selector.dart';
import 'elements.dart';
import 'closure_visitors.dart';
import 'js_world_builder.dart' show JsClosedWorldBuilder;
import 'locals.dart';

class KernelClosureAnalysis {
  /// Inspect members and mark if those members capture any state that needs to
  /// be marked as free variables.
  static ScopeModel computeScopeModel(MemberEntity entity, ir.Member node) {
    if (entity.isAbstract) return null;
    if (entity.isField && !entity.isInstanceMember) {
      ir.Field field = node;
      // Skip top-level/static fields without an initializer.
      if (field.initializer == null) return null;
    }

    bool hasThisLocal = false;
    if (entity.isInstanceMember) {
      hasThisLocal = true;
    } else if (entity.isConstructor) {
      ConstructorEntity constructor = entity;
      hasThisLocal = !constructor.isFactoryConstructor;
    }
    ScopeModel model = new ScopeModel();
    CapturedScopeBuilder translator =
        new CapturedScopeBuilder(model, hasThisLocal: hasThisLocal);
    if (entity.isField) {
      if (node is ir.Field && node.initializer != null) {
        node.accept(translator);
      } else {
        assert(entity.isInstanceMember);
        model.scopeInfo = new KernelScopeInfo(true);
      }
    } else {
      assert(node is ir.Procedure || node is ir.Constructor);
      node.accept(translator);
    }
    return model;
  }
}

class KernelClosureConversionTask extends ClosureConversionTask {
  KernelClosureConversionTask(Measurer measurer) : super(measurer);
}

class ClosureDataImpl implements ClosureData {
  /// Tag used for identifying serialized [ClosureData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-data';

  final JsToElementMap _elementMap;

  /// Map of the scoping information that corresponds to a particular entity.
  final Map<MemberEntity, ScopeInfo> _scopeMap;
  final Map<ir.TreeNode, CapturedScope> _capturedScopesMap;
  // Indicates the type variables (if any) that are captured in a given
  // Signature function.
  final Map<MemberEntity, CapturedScope> _capturedScopeForSignatureMap;

  // The key is either a [ir.FunctionDeclaration] or [ir.FunctionExpression].
  final Map<ir.TreeNode, ClosureRepresentationInfo>
      _localClosureRepresentationMap;

  ClosureDataImpl(this._elementMap, this._scopeMap, this._capturedScopesMap,
      this._capturedScopeForSignatureMap, this._localClosureRepresentationMap);

  /// Deserializes a [ClosureData] object from [source].
  factory ClosureDataImpl.readFromDataSource(
      JsToElementMap elementMap, DataSource source) {
    source.begin(tag);
    // TODO(johnniwinther): Support shared [ScopeInfo].
    Map<MemberEntity, ScopeInfo> scopeMap =
        source.readMemberMap(() => new ScopeInfo.readFromDataSource(source));
    Map<ir.TreeNode, CapturedScope> capturedScopesMap = source
        .readTreeNodeMap(() => new CapturedScope.readFromDataSource(source));
    Map<MemberEntity, CapturedScope> capturedScopeForSignatureMap = source
        .readMemberMap(() => new CapturedScope.readFromDataSource(source));
    Map<ir.TreeNode, ClosureRepresentationInfo> localClosureRepresentationMap =
        source.readTreeNodeMap(
            () => new ClosureRepresentationInfo.readFromDataSource(source));
    source.end(tag);
    return new ClosureDataImpl(elementMap, scopeMap, capturedScopesMap,
        capturedScopeForSignatureMap, localClosureRepresentationMap);
  }

  /// Serializes this [ClosureData] to [sink].
  void writeToDataSink(DataSink sink) {
    sink.begin(tag);
    sink.writeMemberMap(
        _scopeMap, (ScopeInfo info) => info.writeToDataSink(sink));
    sink.writeTreeNodeMap(_capturedScopesMap, (CapturedScope scope) {
      scope.writeToDataSink(sink);
    });
    sink.writeMemberMap(_capturedScopeForSignatureMap,
        (CapturedScope scope) => scope.writeToDataSink(sink));
    sink.writeTreeNodeMap(_localClosureRepresentationMap,
        (ClosureRepresentationInfo info) {
      info.writeToDataSink(sink);
    });
    sink.end(tag);
  }

  @override
  ScopeInfo getScopeInfo(MemberEntity entity) {
    // TODO(johnniwinther): Remove this check when constructor bodies a created
    // eagerly with the J-model; a constructor body should have it's own
    // [ClosureRepresentationInfo].
    if (entity is ConstructorBodyEntity) {
      ConstructorBodyEntity constructorBody = entity;
      entity = constructorBody.constructor;
    }

    ScopeInfo scopeInfo = _scopeMap[entity];
    assert(
        scopeInfo != null, failedAt(entity, "Missing scope info for $entity."));
    return scopeInfo;
  }

  // TODO(efortuna): Eventually capturedScopesMap[node] should always
  // be non-null, and we should just test that with an assert.
  @override
  CapturedScope getCapturedScope(MemberEntity entity) {
    MemberDefinition definition = _elementMap.getMemberDefinition(entity);
    switch (definition.kind) {
      case MemberKind.regular:
      case MemberKind.constructor:
      case MemberKind.constructorBody:
      case MemberKind.closureCall:
        return _capturedScopesMap[definition.node] ?? const CapturedScope();
      case MemberKind.signature:
        return _capturedScopeForSignatureMap[entity] ?? const CapturedScope();
      default:
        throw failedAt(entity, "Unexpected member definition $definition");
    }
  }

  @override
  // TODO(efortuna): Eventually capturedScopesMap[node] should always
  // be non-null, and we should just test that with an assert.
  CapturedLoopScope getCapturedLoopScope(ir.Node loopNode) =>
      _capturedScopesMap[loopNode] ?? const CapturedLoopScope();

  @override
  ClosureRepresentationInfo getClosureInfo(ir.Node node) {
    assert(node is ir.FunctionExpression || node is ir.FunctionDeclaration);
    var closure = _localClosureRepresentationMap[node];
    assert(
        closure != null,
        "Corresponding closure class not found for $node. "
        "Closures found for ${_localClosureRepresentationMap.keys}");
    return closure;
  }
}

/// Closure conversion code using our new Entity model. Closure conversion is
/// necessary because the semantics of closures are slightly different in Dart
/// than JavaScript. Closure conversion is separated out into two phases:
/// generation of a new (temporary) representation to store where variables need
/// to be hoisted/captured up at another level to re-write the closure, and then
/// the code generation phase where we generate elements and/or instructions to
/// represent this new code path.
///
/// For a general explanation of how closure conversion works at a high level,
/// check out:
/// http://siek.blogspot.com/2012/07/essence-of-closure-conversion.html or
/// http://matt.might.net/articles/closure-conversion/.

class ClosureDataBuilder {
  final JsToElementMap _elementMap;
  final GlobalLocalsMap _globalLocalsMap;
  final CompilerOptions _options;

  /// Map of the scoping information that corresponds to a particular entity.
  Map<MemberEntity, ScopeInfo> _scopeMap = {};
  Map<ir.TreeNode, CapturedScope> _capturedScopesMap = {};
  // Indicates the type variables (if any) that are captured in a given
  // Signature function.
  Map<MemberEntity, CapturedScope> _capturedScopeForSignatureMap = {};

  // The key is either a [ir.FunctionDeclaration] or [ir.FunctionExpression].
  Map<ir.TreeNode, ClosureRepresentationInfo> _localClosureRepresentationMap =
      {};

  ClosureDataBuilder(this._elementMap, this._globalLocalsMap, this._options);

  void _updateScopeBasedOnRtiNeed(KernelScopeInfo scope, ClosureRtiNeed rtiNeed,
      MemberEntity outermostEntity) {
    bool includeForRti(Set<VariableUse> useSet) {
      for (VariableUse usage in useSet) {
        switch (usage.kind) {
          case VariableUseKind.explicit:
            return true;
            break;
          case VariableUseKind.implicitCast:
            if (_options.implicitDowncastCheckPolicy.isEmitted) {
              return true;
            }
            break;
          case VariableUseKind.localType:
            if (_options.assignmentCheckPolicy.isEmitted) {
              return true;
            }
            break;

          case VariableUseKind.constructorTypeArgument:
            ConstructorEntity constructor =
                _elementMap.getConstructor(usage.member);
            if (rtiNeed.classNeedsTypeArguments(constructor.enclosingClass)) {
              return true;
            }
            break;
          case VariableUseKind.staticTypeArgument:
            FunctionEntity method = _elementMap.getMethod(usage.member);
            if (rtiNeed.methodNeedsTypeArguments(method)) {
              return true;
            }
            break;
          case VariableUseKind.instanceTypeArgument:
            Selector selector = _elementMap.getSelector(usage.invocation);
            if (rtiNeed.selectorNeedsTypeArguments(selector)) {
              return true;
            }
            break;
          case VariableUseKind.localTypeArgument:
            // TODO(johnniwinther): We should be able to track direct local
            // function invocations and not have to use the selector here.
            Selector selector = _elementMap.getSelector(usage.invocation);
            if (rtiNeed.localFunctionNeedsTypeArguments(usage.localFunction) ||
                rtiNeed.selectorNeedsTypeArguments(selector)) {
              return true;
            }
            break;
          case VariableUseKind.memberParameter:
            if (_options.parameterCheckPolicy.isEmitted) {
              return true;
            } else {
              FunctionEntity method = _elementMap.getMethod(usage.member);
              if (rtiNeed.methodNeedsSignature(method)) {
                return true;
              }
            }
            break;
          case VariableUseKind.localParameter:
            if (_options.parameterCheckPolicy.isEmitted) {
              return true;
            } else if (rtiNeed
                .localFunctionNeedsSignature(usage.localFunction)) {
              return true;
            }
            break;
          case VariableUseKind.memberReturnType:
            if (_options.assignmentCheckPolicy.isEmitted) {
              return true;
            } else {
              FunctionEntity method = _elementMap.getMethod(usage.member);
              if (rtiNeed.methodNeedsSignature(method)) {
                return true;
              }
            }
            break;
          case VariableUseKind.localReturnType:
            if (_options.assignmentCheckPolicy.isEmitted) {
              return true;
            } else if (rtiNeed
                .localFunctionNeedsSignature(usage.localFunction)) {
              return true;
            }
            break;
          case VariableUseKind.fieldType:
            if (_options.assignmentCheckPolicy.isEmitted ||
                _options.parameterCheckPolicy.isEmitted) {
              return true;
            }
            break;
          case VariableUseKind.listLiteral:
            if (rtiNeed.classNeedsTypeArguments(
                _elementMap.commonElements.jsArrayClass)) {
              return true;
            }
            break;
          case VariableUseKind.mapLiteral:
            if (rtiNeed.classNeedsTypeArguments(
                _elementMap.commonElements.mapLiteralClass)) {
              return true;
            }
            break;
          case VariableUseKind.instantiationTypeArgument:
            // TODO(johnniwinther): Use the static type of the expression.
            if (rtiNeed.instantiationNeedsTypeArguments(
                null, usage.instantiation.typeArguments.length)) {
              return true;
            }
            break;
        }
      }
      return false;
    }

    if (includeForRti(scope.thisUsedAsFreeVariableIfNeedsRti)) {
      scope.thisUsedAsFreeVariable = true;
    }
    scope.freeVariablesForRti.forEach(
        (TypeVariableTypeWithContext typeVariable, Set<VariableUse> useSet) {
      if (includeForRti(useSet)) {
        scope.freeVariables.add(typeVariable);
      }
    });
  }

  ClosureData createClosureEntities(
      JsClosedWorldBuilder closedWorldBuilder,
      Map<MemberEntity, ScopeModel> closureModels,
      ClosureRtiNeed rtiNeed,
      List<FunctionEntity> callMethods) {
    closureModels.forEach((MemberEntity member, ScopeModel model) {
      KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(member);
      Map<Local, JRecordField> allBoxedVariables =
          _elementMap.makeRecordContainer(model.scopeInfo, member, localsMap);
      _scopeMap[member] = new JsScopeInfo.from(
          allBoxedVariables, model.scopeInfo, localsMap, _elementMap);

      model.capturedScopesMap
          .forEach((ir.Node node, KernelCapturedScope scope) {
        Map<Local, JRecordField> boxedVariables =
            _elementMap.makeRecordContainer(scope, member, localsMap);
        _updateScopeBasedOnRtiNeed(scope, rtiNeed, member);

        if (scope is KernelCapturedLoopScope) {
          _capturedScopesMap[node] = new JsCapturedLoopScope.from(
              boxedVariables, scope, localsMap, _elementMap);
        } else {
          _capturedScopesMap[node] = new JsCapturedScope.from(
              boxedVariables, scope, localsMap, _elementMap);
        }
        allBoxedVariables.addAll(boxedVariables);
      });

      Map<ir.TreeNode, KernelScopeInfo> closuresToGenerate =
          model.closuresToGenerate;
      for (ir.TreeNode node in closuresToGenerate.keys) {
        ir.FunctionNode functionNode;
        if (node is ir.FunctionDeclaration) {
          functionNode = node.function;
        } else if (node is ir.FunctionExpression) {
          functionNode = node.function;
        } else {
          failedAt(member, "Unexpected closure node ${node}");
        }
        KernelClosureClassInfo closureClassInfo = _produceSyntheticElements(
            closedWorldBuilder,
            member,
            functionNode,
            closuresToGenerate[node],
            allBoxedVariables,
            rtiNeed,
            createSignatureMethod:
                rtiNeed.localFunctionNeedsSignature(functionNode.parent));
        // Add also for the call method.
        _scopeMap[closureClassInfo.callMethod] = closureClassInfo;
        if (closureClassInfo.signatureMethod != null) {
          _scopeMap[closureClassInfo.signatureMethod] = closureClassInfo;

          // Set up capturedScope for signature method. This is distinct from
          // _capturedScopesMap because there is no corresponding ir.Node for
          // the signature.
          if (rtiNeed.localFunctionNeedsSignature(functionNode.parent) &&
              model.capturedScopesMap[functionNode] != null) {
            KernelCapturedScope capturedScope =
                model.capturedScopesMap[functionNode];
            assert(capturedScope is! KernelCapturedLoopScope);
            KernelCapturedScope signatureCapturedScope =
                new KernelCapturedScope.forSignature(capturedScope);
            _updateScopeBasedOnRtiNeed(signatureCapturedScope, rtiNeed, member);
            _capturedScopeForSignatureMap[closureClassInfo.signatureMethod] =
                new JsCapturedScope.from(
                    {}, signatureCapturedScope, localsMap, _elementMap);
          }
        }
        callMethods.add(closureClassInfo.callMethod);
      }
    });
    return new ClosureDataImpl(_elementMap, _scopeMap, _capturedScopesMap,
        _capturedScopeForSignatureMap, _localClosureRepresentationMap);
  }

  /// Given what variables are captured at each point, construct closure classes
  /// with fields containing the captured variables to replicate the Dart
  /// closure semantics in JS. If this closure captures any variables (meaning
  /// the closure accesses a variable that gets accessed at some point), then
  /// boxForCapturedVariables stores the local context for those variables.
  /// If no variables are captured, this parameter is null.
  KernelClosureClassInfo _produceSyntheticElements(
      JsClosedWorldBuilder closedWorldBuilder,
      MemberEntity member,
      ir.FunctionNode node,
      KernelScopeInfo info,
      Map<Local, JRecordField> boxedVariables,
      ClosureRtiNeed rtiNeed,
      {bool createSignatureMethod}) {
    _updateScopeBasedOnRtiNeed(info, rtiNeed, member);
    KernelToLocalsMap localsMap = _globalLocalsMap.getLocalsMap(member);
    KernelClosureClassInfo closureClassInfo =
        closedWorldBuilder.buildClosureClass(
            member, node, member.library, boxedVariables, info, localsMap,
            createSignatureMethod: createSignatureMethod);

    // We want the original declaration where that function is used to point
    // to the correct closure class.
    _globalLocalsMap.setLocalsMap(closureClassInfo.callMethod, localsMap);
    if (closureClassInfo.signatureMethod != null) {
      _globalLocalsMap.setLocalsMap(
          closureClassInfo.signatureMethod, localsMap);
    }
    if (node.parent is ir.Member) {
      assert(_elementMap.getMember(node.parent) == member);
    } else {
      assert(node.parent is ir.FunctionExpression ||
          node.parent is ir.FunctionDeclaration);
      _localClosureRepresentationMap[node.parent] = closureClassInfo;
    }
    return closureClassInfo;
  }
}

enum VariableUseKind {
  /// An explicit variable use.
  ///
  /// For type variable this is an explicit as-cast, an is-test or a type
  /// literal.
  explicit,

  /// A type variable used in the type of a local variable.
  localType,

  /// A type variable used in an implicit cast.
  implicitCast,

  /// A type variable passed as the type argument of a list literal.
  listLiteral,

  /// A type variable passed as the type argument of a map literal.
  mapLiteral,

  /// A type variable passed as a type argument to a constructor.
  constructorTypeArgument,

  /// A type variable passed as a type argument to a static method.
  staticTypeArgument,

  /// A type variable passed as a type argument to an instance method.
  instanceTypeArgument,

  /// A type variable passed as a type argument to a local function.
  localTypeArgument,

  /// A type variable in a parameter type of a member.
  memberParameter,

  /// A type variable in a parameter type of a local function.
  localParameter,

  /// A type variable used in a return type of a member.
  memberReturnType,

  /// A type variable used in a return type of a local function.
  localReturnType,

  /// A type variable in a field type.
  fieldType,

  /// A type argument of an generic instantiation.
  instantiationTypeArgument,
}

class VariableUse {
  final VariableUseKind kind;
  final ir.Member member;
  final ir.TreeNode /*ir.FunctionDeclaration|ir.FunctionExpression*/
      localFunction;
  final ir.MethodInvocation invocation;
  final ir.Instantiation instantiation;

  const VariableUse._simple(this.kind)
      : this.member = null,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.memberParameter(this.member)
      : this.kind = VariableUseKind.memberParameter,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.localParameter(this.localFunction)
      : this.kind = VariableUseKind.localParameter,
        this.member = null,
        this.invocation = null,
        this.instantiation = null {
    assert(localFunction is ir.FunctionDeclaration ||
        localFunction is ir.FunctionExpression);
  }

  VariableUse.memberReturnType(this.member)
      : this.kind = VariableUseKind.memberReturnType,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.localReturnType(this.localFunction)
      : this.kind = VariableUseKind.localReturnType,
        this.member = null,
        this.invocation = null,
        this.instantiation = null {
    assert(localFunction is ir.FunctionDeclaration ||
        localFunction is ir.FunctionExpression);
  }

  VariableUse.constructorTypeArgument(this.member)
      : this.kind = VariableUseKind.constructorTypeArgument,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.staticTypeArgument(this.member)
      : this.kind = VariableUseKind.staticTypeArgument,
        this.localFunction = null,
        this.invocation = null,
        this.instantiation = null;

  VariableUse.instanceTypeArgument(this.invocation)
      : this.kind = VariableUseKind.instanceTypeArgument,
        this.member = null,
        this.localFunction = null,
        this.instantiation = null;

  VariableUse.localTypeArgument(this.localFunction, this.invocation)
      : this.kind = VariableUseKind.localTypeArgument,
        this.member = null,
        this.instantiation = null {
    assert(localFunction is ir.FunctionDeclaration ||
        localFunction is ir.FunctionExpression);
  }

  VariableUse.instantiationTypeArgument(this.instantiation)
      : this.kind = VariableUseKind.instantiationTypeArgument,
        this.member = null,
        this.localFunction = null,
        this.invocation = null;

  static const VariableUse explicit =
      const VariableUse._simple(VariableUseKind.explicit);

  static const VariableUse localType =
      const VariableUse._simple(VariableUseKind.localType);

  static const VariableUse implicitCast =
      const VariableUse._simple(VariableUseKind.implicitCast);

  static const VariableUse listLiteral =
      const VariableUse._simple(VariableUseKind.listLiteral);

  static const VariableUse mapLiteral =
      const VariableUse._simple(VariableUseKind.mapLiteral);

  static const VariableUse fieldType =
      const VariableUse._simple(VariableUseKind.fieldType);

  int get hashCode =>
      kind.hashCode * 11 +
      member.hashCode * 13 +
      localFunction.hashCode * 17 +
      invocation.hashCode * 19 +
      instantiation.hashCode * 23;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! VariableUse) return false;
    return kind == other.kind &&
        member == other.member &&
        localFunction == other.localFunction &&
        invocation == other.invocation &&
        instantiation == other.instantiation;
  }

  String toString() => 'VariableUse(kind=$kind,member=$member,'
      'localFunction=$localFunction,invocation=$invocation,'
      'instantiation=$instantiation)';
}

class KernelScopeInfo {
  final Set<ir.VariableDeclaration> localsUsedInTryOrSync;
  final bool hasThisLocal;
  final Set<ir.VariableDeclaration> boxedVariables;
  // If boxedVariables is empty, this will be null, because no variables will
  // need to be boxed.
  final NodeBox capturedVariablesAccessor;

  /// The set of variables that were defined in another scope, but are used in
  /// this scope. The items in this set are either of type VariableDeclaration
  /// or TypeParameterTypeWithContext.
  Set<ir.Node /* VariableDeclaration | TypeParameterTypeWithContext */ >
      freeVariables = new Set<ir.Node>();

  /// A set of type parameters that are defined in another scope and are only
  /// used if runtime type information is checked. If runtime type information
  /// needs to be retained, all of these type variables will be added ot the
  /// freeVariables set. Whether these variables are actually used as
  /// freeVariables will be set by the time this structure is converted to a
  /// JsScopeInfo, so JsScopeInfo does not need to use them.
  Map<TypeVariableTypeWithContext, Set<VariableUse>> freeVariablesForRti =
      <TypeVariableTypeWithContext, Set<VariableUse>>{};

  /// If true, `this` is used as a free variable, in this scope. It is stored
  /// separately from [freeVariables] because there is no single
  /// `VariableDeclaration` node that represents `this`.
  bool thisUsedAsFreeVariable = false;

  /// If true, `this` is used as a free variable, in this scope if we are also
  /// performing runtime type checks. It is stored
  /// separately from [thisUsedAsFreeVariable] because we don't know at this
  /// stage if we will be needing type checks for this scope.
  Set<VariableUse> thisUsedAsFreeVariableIfNeedsRti = new Set<VariableUse>();

  KernelScopeInfo(this.hasThisLocal)
      : localsUsedInTryOrSync = new Set<ir.VariableDeclaration>(),
        boxedVariables = new Set<ir.VariableDeclaration>(),
        capturedVariablesAccessor = null;

  KernelScopeInfo.from(this.hasThisLocal, KernelScopeInfo info)
      : localsUsedInTryOrSync = info.localsUsedInTryOrSync,
        boxedVariables = info.boxedVariables,
        capturedVariablesAccessor = null;

  KernelScopeInfo.withBoxedVariables(
      this.boxedVariables,
      this.capturedVariablesAccessor,
      this.localsUsedInTryOrSync,
      this.freeVariables,
      this.freeVariablesForRti,
      this.thisUsedAsFreeVariable,
      this.thisUsedAsFreeVariableIfNeedsRti,
      this.hasThisLocal);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('KernelScopeInfo(this=$hasThisLocal,');
    sb.write('freeVriables=$freeVariables,');
    sb.write('localsUsedInTryOrSync={${localsUsedInTryOrSync.join(', ')}}');
    String comma = '';
    sb.write('freeVariablesForRti={');
    freeVariablesForRti.forEach((key, value) {
      sb.write('$comma$key:$value');
      comma = ',';
    });
    sb.write('})');
    return sb.toString();
  }
}

/// Helper method to get or create a Local variable out of a variable
/// declaration or type parameter.
Local _getLocal(
    ir.Node variable, KernelToLocalsMap localsMap, JsToElementMap elementMap) {
  assert(variable is ir.VariableDeclaration ||
      variable is TypeVariableTypeWithContext);
  if (variable is ir.VariableDeclaration) {
    return localsMap.getLocalVariable(variable);
  } else if (variable is TypeVariableTypeWithContext) {
    return localsMap.getLocalTypeVariable(variable.type, elementMap);
  }
  throw new ArgumentError('Only know how to get/create locals for '
      'VariableDeclarations or TypeParameterTypeWithContext. Recieved '
      '${variable.runtimeType}');
}

class JsScopeInfo extends ScopeInfo {
  /// Tag used for identifying serialized [JsScopeInfo] objects in a
  /// debugging data stream.
  static const String tag = 'scope-info';

  final Iterable<Local> localsUsedInTryOrSync;
  final Local thisLocal;
  final Map<Local, JRecordField> boxedVariables;

  /// The set of variables that were defined in another scope, but are used in
  /// this scope.
  final Set<Local> freeVariables;

  JsScopeInfo.internal(this.localsUsedInTryOrSync, this.thisLocal,
      this.boxedVariables, this.freeVariables);

  JsScopeInfo.from(this.boxedVariables, KernelScopeInfo info,
      KernelToLocalsMap localsMap, JsToElementMap elementMap)
      : this.thisLocal = info.hasThisLocal
            ? new ThisLocal(localsMap.currentMember.enclosingClass)
            : null,
        this.localsUsedInTryOrSync =
            info.localsUsedInTryOrSync.map(localsMap.getLocalVariable).toSet(),
        this.freeVariables = info.freeVariables
            .map((ir.Node node) => _getLocal(node, localsMap, elementMap))
            .toSet() {
    if (info.thisUsedAsFreeVariable) {
      this.freeVariables.add(this.thisLocal);
    }
  }

  void forEachBoxedVariable(f(Local local, FieldEntity field)) {
    boxedVariables.forEach((Local l, JRecordField box) {
      f(l, box);
    });
  }

  bool localIsUsedInTryOrSync(Local variable) =>
      localsUsedInTryOrSync.contains(variable);

  String toString() {
    StringBuffer sb = new StringBuffer();
    sb.write('this=$thisLocal,');
    sb.write('localsUsedInTryOrSync={${localsUsedInTryOrSync.join(', ')}}');
    return sb.toString();
  }

  bool isBoxed(Local variable) => boxedVariables.containsKey(variable);

  factory JsScopeInfo.readFromDataSource(DataSource source) {
    source.begin(tag);
    Iterable<Local> localsUsedInTryOrSync = source.readLocals();
    Local thisLocal = source.readLocalOrNull();
    Map<Local, JRecordField> boxedVariables =
        source.readLocalMap<Local, JRecordField>(() => source.readMember());
    Set<Local> freeVariables = source.readLocals().toSet();
    source.end(tag);
    return new JsScopeInfo.internal(
        localsUsedInTryOrSync, thisLocal, boxedVariables, freeVariables);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(ScopeInfoKind.scopeInfo);
    sink.begin(tag);
    sink.writeLocals(localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeLocalMap(boxedVariables, sink.writeMember);
    sink.writeLocals(freeVariables);
    sink.end(tag);
  }
}

class KernelCapturedScope extends KernelScopeInfo {
  KernelCapturedScope(
      Set<ir.VariableDeclaration> boxedVariables,
      NodeBox capturedVariablesAccessor,
      Set<ir.VariableDeclaration> localsUsedInTryOrSync,
      Set<ir.Node /* VariableDeclaration | TypeVariableTypeWithContext */ >
          freeVariables,
      Map<TypeVariableTypeWithContext, Set<VariableUse>> freeVariablesForRti,
      bool thisUsedAsFreeVariable,
      Set<VariableUse> thisUsedAsFreeVariableIfNeedsRti,
      bool hasThisLocal)
      : super.withBoxedVariables(
            boxedVariables,
            capturedVariablesAccessor,
            localsUsedInTryOrSync,
            freeVariables,
            freeVariablesForRti,
            thisUsedAsFreeVariable,
            thisUsedAsFreeVariableIfNeedsRti,
            hasThisLocal);

  // Loops through the free variables of an existing KernelCapturedScope and
  // creates a new KernelCapturedScope that only captures type variables.
  KernelCapturedScope.forSignature(KernelCapturedScope scope)
      : this(
            _empty,
            null,
            _empty,
            scope.freeVariables.where(
                (ir.Node variable) => variable is TypeVariableTypeWithContext),
            scope.freeVariablesForRti,
            scope.thisUsedAsFreeVariable,
            scope.thisUsedAsFreeVariableIfNeedsRti,
            scope.hasThisLocal);

  // Silly hack because we don't have const sets.
  static final Set<ir.VariableDeclaration> _empty = new Set();

  bool get requiresContextBox => boxedVariables.isNotEmpty;
}

class JsCapturedScope extends JsScopeInfo implements CapturedScope {
  /// Tag used for identifying serialized [JsCapturedScope] objects in a
  /// debugging data stream.
  static const String tag = 'captured-scope';

  final Local context;

  JsCapturedScope.internal(
      Iterable<Local> localsUsedInTryOrSync,
      Local thisLocal,
      Map<Local, JRecordField> boxedVariables,
      Set<Local> freeVariables,
      this.context)
      : super.internal(
            localsUsedInTryOrSync, thisLocal, boxedVariables, freeVariables);

  JsCapturedScope.from(
      Map<Local, JRecordField> boxedVariables,
      KernelCapturedScope capturedScope,
      KernelToLocalsMap localsMap,
      JsToElementMap elementMap)
      : this.context =
            boxedVariables.isNotEmpty ? boxedVariables.values.first.box : null,
        super.from(boxedVariables, capturedScope, localsMap, elementMap);

  bool get requiresContextBox => boxedVariables.isNotEmpty;

  factory JsCapturedScope.readFromDataSource(DataSource source) {
    source.begin(tag);
    Iterable<Local> localsUsedInTryOrSync = source.readLocals();
    Local thisLocal = source.readLocalOrNull();
    Map<Local, JRecordField> boxedVariables =
        source.readLocalMap<Local, JRecordField>(() => source.readMember());
    Set<Local> freeVariables = source.readLocals().toSet();
    Local context = source.readLocalOrNull();
    source.end(tag);
    return new JsCapturedScope.internal(localsUsedInTryOrSync, thisLocal,
        boxedVariables, freeVariables, context);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(ScopeInfoKind.capturedScope);
    sink.begin(tag);
    sink.writeLocals(localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeLocalMap(boxedVariables, sink.writeMember);
    sink.writeLocals(freeVariables);
    sink.writeLocalOrNull(context);
    sink.end(tag);
  }
}

class KernelCapturedLoopScope extends KernelCapturedScope {
  final List<ir.VariableDeclaration> boxedLoopVariables;

  KernelCapturedLoopScope(
      Set<ir.VariableDeclaration> boxedVariables,
      NodeBox capturedVariablesAccessor,
      this.boxedLoopVariables,
      Set<ir.VariableDeclaration> localsUsedInTryOrSync,
      Set<ir.Node /* VariableDeclaration | TypeVariableTypeWithContext */ >
          freeVariables,
      Map<TypeVariableTypeWithContext, Set<VariableUse>> freeVariablesForRti,
      bool thisUsedAsFreeVariable,
      Set<VariableUse> thisUsedAsFreeVariableIfNeedsRti,
      bool hasThisLocal)
      : super(
            boxedVariables,
            capturedVariablesAccessor,
            localsUsedInTryOrSync,
            freeVariables,
            freeVariablesForRti,
            thisUsedAsFreeVariable,
            thisUsedAsFreeVariableIfNeedsRti,
            hasThisLocal);

  bool get hasBoxedLoopVariables => boxedLoopVariables.isNotEmpty;
}

class JsCapturedLoopScope extends JsCapturedScope implements CapturedLoopScope {
  /// Tag used for identifying serialized [JsCapturedLoopScope] objects in a
  /// debugging data stream.
  static const String tag = 'captured-loop-scope';

  final List<Local> boxedLoopVariables;

  JsCapturedLoopScope.internal(
      Iterable<Local> localsUsedInTryOrSync,
      Local thisLocal,
      Map<Local, JRecordField> boxedVariables,
      Set<Local> freeVariables,
      Local context,
      this.boxedLoopVariables)
      : super.internal(localsUsedInTryOrSync, thisLocal, boxedVariables,
            freeVariables, context);

  JsCapturedLoopScope.from(
      Map<Local, JRecordField> boxedVariables,
      KernelCapturedLoopScope capturedScope,
      KernelToLocalsMap localsMap,
      JsToElementMap elementMap)
      : this.boxedLoopVariables = capturedScope.boxedLoopVariables
            .map(localsMap.getLocalVariable)
            .toList(),
        super.from(boxedVariables, capturedScope, localsMap, elementMap);

  bool get hasBoxedLoopVariables => boxedLoopVariables.isNotEmpty;

  factory JsCapturedLoopScope.readFromDataSource(DataSource source) {
    source.begin(tag);
    Iterable<Local> localsUsedInTryOrSync = source.readLocals();
    Local thisLocal = source.readLocalOrNull();
    Map<Local, JRecordField> boxedVariables =
        source.readLocalMap<Local, JRecordField>(() => source.readMember());
    Set<Local> freeVariables = source.readLocals().toSet();
    Local context = source.readLocalOrNull();
    List<Local> boxedLoopVariables = source.readLocals();
    source.end(tag);
    return new JsCapturedLoopScope.internal(localsUsedInTryOrSync, thisLocal,
        boxedVariables, freeVariables, context, boxedLoopVariables);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(ScopeInfoKind.capturedLoopScope);
    sink.begin(tag);
    sink.writeLocals(localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeLocalMap(boxedVariables, sink.writeMember);
    sink.writeLocals(freeVariables);
    sink.writeLocalOrNull(context);
    sink.writeLocals(boxedLoopVariables);
    sink.end(tag);
  }
}

// TODO(johnniwinther): Rename this class.
// TODO(johnniwinther): Add unittest for the computed [ClosureClass].
class KernelClosureClassInfo extends JsScopeInfo
    implements ClosureRepresentationInfo {
  /// Tag used for identifying serialized [KernelClosureClassInfo] objects in a
  /// debugging data stream.
  static const String tag = 'closure-representation-info';

  JFunction callMethod;
  JSignatureMethod signatureMethod;
  final Local closureEntity;
  final Local thisLocal;
  final JClass closureClassEntity;

  final Map<Local, JField> localToFieldMap;

  KernelClosureClassInfo.internal(
      Iterable<Local> localsUsedInTryOrSync,
      this.thisLocal,
      Map<Local, JRecordField> boxedVariables,
      Set<Local> freeVariables,
      this.callMethod,
      this.signatureMethod,
      this.closureEntity,
      this.closureClassEntity,
      this.localToFieldMap)
      : super.internal(
            localsUsedInTryOrSync, thisLocal, boxedVariables, freeVariables);

  KernelClosureClassInfo.fromScopeInfo(
      this.closureClassEntity,
      ir.FunctionNode closureSourceNode,
      Map<Local, JRecordField> boxedVariables,
      KernelScopeInfo info,
      KernelToLocalsMap localsMap,
      this.closureEntity,
      this.thisLocal,
      JsToElementMap elementMap)
      : localToFieldMap = new Map<Local, JField>(),
        super.from(boxedVariables, info, localsMap, elementMap);

  factory KernelClosureClassInfo.readFromDataSource(DataSource source) {
    source.begin(tag);
    Iterable<Local> localsUsedInTryOrSync = source.readLocals();
    Local thisLocal = source.readLocalOrNull();
    Map<Local, JRecordField> boxedVariables =
        source.readLocalMap<Local, JRecordField>(() => source.readMember());
    Set<Local> freeVariables = source.readLocals().toSet();
    JFunction callMethod = source.readMember();
    JSignatureMethod signatureMethod = source.readMemberOrNull();
    Local closureEntity = source.readLocalOrNull();
    JClass closureClassEntity = source.readClass();
    Map<Local, JField> localToFieldMap =
        source.readLocalMap(() => source.readMember());
    source.end(tag);
    return new KernelClosureClassInfo.internal(
        localsUsedInTryOrSync,
        thisLocal,
        boxedVariables,
        freeVariables,
        callMethod,
        signatureMethod,
        closureEntity,
        closureClassEntity,
        localToFieldMap);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeEnum(ScopeInfoKind.closureRepresentationInfo);
    sink.begin(tag);
    sink.writeLocals(localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeLocalMap(boxedVariables, sink.writeMember);
    sink.writeLocals(freeVariables);
    sink.writeMember(callMethod);
    sink.writeMemberOrNull(signatureMethod);
    sink.writeLocalOrNull(closureEntity);
    sink.writeClass(closureClassEntity);
    sink.writeLocalMap(localToFieldMap, sink.writeMember);
    sink.end(tag);
  }

  List<Local> get createdFieldEntities => localToFieldMap.keys.toList();

  @override
  Local getLocalForField(FieldEntity field) {
    for (Local local in localToFieldMap.keys) {
      if (localToFieldMap[local] == field) {
        return local;
      }
    }
    failedAt(field, "No local for $field. Options: $localToFieldMap");
    return null;
  }

  FieldEntity get thisFieldEntity => localToFieldMap[thisLocal];

  @override
  void forEachBoxedVariable(f(Local local, JField field)) {
    boxedVariables.forEach(f);
  }

  void forEachFreeVariable(f(Local variable, JField field)) {
    localToFieldMap.forEach(f);
    boxedVariables.forEach(f);
  }

  bool isVariableBoxed(Local variable) =>
      boxedVariables.keys.contains(variable);

  bool get isClosure => true;
}

/// A local variable to disambiguate between a variable that has been captured
/// from one scope to another. This is the ir.Node version that corresponds to
/// [BoxLocal].
class NodeBox {
  final String name;
  final ir.TreeNode executableContext;
  NodeBox(this.name, this.executableContext);
}

class JClosureClass extends JClass {
  /// Tag used for identifying serialized [JClosureClass] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class';

  JClosureClass(JLibrary library, String name)
      : super(library, name, isAbstract: false);

  factory JClosureClass.readFromDataSource(DataSource source) {
    source.begin(tag);
    JLibrary library = source.readLibrary();
    String name = source.readString();
    source.end(tag);
    return new JClosureClass(library, name);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassKind.closure);
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.end(tag);
  }

  @override
  bool get isClosure => true;

  String toString() => '${jsElementPrefix}closure_class($name)';
}

class AnonymousClosureLocal implements Local {
  final JClosureClass closureClass;

  AnonymousClosureLocal(this.closureClass);

  String get name => '';

  int get hashCode => closureClass.hashCode * 13;

  bool operator ==(other) {
    if (identical(this, other)) return true;
    if (other is! AnonymousClosureLocal) return false;
    return closureClass == other.closureClass;
  }

  String toString() =>
      '${jsElementPrefix}anonymous_closure_local(${closureClass.name})';
}

class JClosureField extends JField implements PrivatelyNamedJSEntity {
  /// Tag used for identifying serialized [JClosureClass] objects in a
  /// debugging data stream.
  static const String tag = 'closure-field';

  final String declaredName;

  JClosureField(
      String name, KernelClosureClassInfo containingClass, String declaredName,
      {bool isConst, bool isAssignable})
      : this.internal(
            containingClass.closureClassEntity.library,
            containingClass.closureClassEntity,
            new Name(name, containingClass.closureClassEntity.library),
            declaredName,
            isAssignable: isAssignable,
            isConst: isConst);

  JClosureField.internal(JLibrary library, JClosureClass enclosingClass,
      Name memberName, this.declaredName, {bool isConst, bool isAssignable})
      : super(library, enclosingClass, memberName,
            isAssignable: isAssignable, isConst: isConst, isStatic: false);

  factory JClosureField.readFromDataSource(DataSource source) {
    source.begin(tag);
    JClass cls = source.readClass();
    String name = source.readString();
    String declaredName = source.readString();
    bool isConst = source.readBool();
    bool isAssignable = source.readBool();
    source.end(tag);
    return new JClosureField.internal(
        cls.library, cls, new Name(name, cls.library), declaredName,
        isAssignable: isAssignable, isConst: isConst);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.closureField);
    sink.begin(tag);
    sink.writeClass(enclosingClass);
    sink.writeString(name);
    sink.writeString(declaredName);
    sink.writeBool(isConst);
    sink.writeBool(isAssignable);
    sink.end(tag);
  }

  @override
  Entity get rootOfScope => enclosingClass;
}

class RecordClassData implements JClassData {
  /// Tag used for identifying serialized [RecordClassData] objects in a
  /// debugging data stream.
  static const String tag = 'record-class-data';

  @override
  final ClassDefinition definition;

  @override
  final InterfaceType thisType;

  @override
  final OrderedTypeSet orderedTypeSet;

  @override
  final InterfaceType supertype;

  RecordClassData(
      this.definition, this.thisType, this.supertype, this.orderedTypeSet);

  factory RecordClassData.readFromDataSource(DataSource source) {
    source.begin(tag);
    ClassDefinition definition = new ClassDefinition.readFromDataSource(source);
    InterfaceType thisType = source.readDartType();
    InterfaceType supertype = source.readDartType();
    OrderedTypeSet orderedTypeSet =
        new OrderedTypeSet.readFromDataSource(source);
    source.end(tag);
    return new RecordClassData(definition, thisType, supertype, orderedTypeSet);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassDataKind.record);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartType(thisType);
    sink.writeDartType(supertype);
    orderedTypeSet.writeToDataSink(sink);
    sink.end(tag);
  }

  @override
  bool get isMixinApplication => false;

  @override
  bool get isEnumClass => false;

  @override
  DartType get callType => null;

  @override
  List<InterfaceType> get interfaces => const <InterfaceType>[];

  @override
  InterfaceType get mixedInType => null;

  @override
  InterfaceType get rawType => thisType;
}

/// A container for variables declared in a particular scope that are accessed
/// elsewhere.
// TODO(johnniwinther): Don't implement JClass. This isn't actually a
// class.
class JRecord extends JClass {
  /// Tag used for identifying serialized [JRecord] objects in a
  /// debugging data stream.
  static const String tag = 'record';

  JRecord(LibraryEntity library, String name)
      : super(library, name, isAbstract: false);

  factory JRecord.readFromDataSource(DataSource source) {
    source.begin(tag);
    JLibrary library = source.readLibrary();
    String name = source.readString();
    source.end(tag);
    return new JRecord(library, name);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassKind.record);
    sink.begin(tag);
    sink.writeLibrary(library);
    sink.writeString(name);
    sink.end(tag);
  }

  bool get isClosure => false;

  String toString() => '${jsElementPrefix}record_container($name)';
}

/// A variable that has been "boxed" to prevent name shadowing with the
/// original variable and ensure that this variable is updated/read with the
/// most recent value.
/// This corresponds to BoxFieldElement; we reuse BoxLocal from the original
/// algorithm to correspond to the actual name of the variable.
class JRecordField extends JField {
  /// Tag used for identifying serialized [JRecordField] objects in a
  /// debugging data stream.
  static const String tag = 'record-field';

  final BoxLocal box;

  JRecordField(String name, this.box, {bool isConst})
      : super(box.container.library, box.container,
            new Name(name, box.container.library),
            isStatic: false, isAssignable: true, isConst: isConst);

  factory JRecordField.readFromDataSource(DataSource source) {
    source.begin(tag);
    String name = source.readString();
    JClass enclosingClass = source.readClass();
    bool isConst = source.readBool();
    source.end(tag);
    return new JRecordField(name, new BoxLocal(enclosingClass),
        isConst: isConst);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberKind.recordField);
    sink.begin(tag);
    sink.writeString(name);
    sink.writeClass(enclosingClass);
    sink.writeBool(isConst);
    sink.end(tag);
  }

  @override
  bool get isInstanceMember => false;
}

class ClosureClassData extends RecordClassData {
  /// Tag used for identifying serialized [ClosureClassData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class-data';

  @override
  FunctionType callType;

  ClosureClassData(ClassDefinition definition, InterfaceType thisType,
      InterfaceType supertype, OrderedTypeSet orderedTypeSet)
      : super(definition, thisType, supertype, orderedTypeSet);

  factory ClosureClassData.readFromDataSource(DataSource source) {
    source.begin(tag);
    ClassDefinition definition = new ClassDefinition.readFromDataSource(source);
    InterfaceType thisType = source.readDartType();
    InterfaceType supertype = source.readDartType();
    OrderedTypeSet orderedTypeSet =
        new OrderedTypeSet.readFromDataSource(source);
    FunctionType callType = source.readDartType();
    source.end(tag);
    return new ClosureClassData(definition, thisType, supertype, orderedTypeSet)
      ..callType = callType;
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JClassDataKind.closure);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartType(thisType);
    sink.writeDartType(supertype);
    orderedTypeSet.writeToDataSink(sink);
    sink.writeDartType(callType);
    sink.end(tag);
  }
}

class ClosureClassDefinition implements ClassDefinition {
  /// Tag used for identifying serialized [ClosureClassDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'closure-class-definition';

  final SourceSpan location;

  ClosureClassDefinition(this.location);

  factory ClosureClassDefinition.readFromDataSource(DataSource source) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    source.end(tag);
    return new ClosureClassDefinition(location);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(ClassKind.closure);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.end(tag);
  }

  ClassKind get kind => ClassKind.closure;

  ir.Node get node =>
      throw new UnsupportedError('ClosureClassDefinition.node for $location');

  String toString() => 'ClosureClassDefinition(kind:$kind,location:$location)';
}

abstract class ClosureMemberData implements JMemberData {
  final MemberDefinition definition;
  final InterfaceType memberThisType;

  ClosureMemberData(this.definition, this.memberThisType);

  @override
  InterfaceType getMemberThisType(JsToElementMap elementMap) {
    return memberThisType;
  }
}

class ClosureFunctionData extends ClosureMemberData
    with FunctionDataMixin
    implements FunctionData {
  /// Tag used for identifying serialized [ClosureFunctionData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-function-data';

  final FunctionType functionType;
  final ir.FunctionNode functionNode;
  final ClassTypeVariableAccess classTypeVariableAccess;

  ClosureFunctionData(
      ClosureMemberDefinition definition,
      InterfaceType memberThisType,
      this.functionType,
      this.functionNode,
      this.classTypeVariableAccess)
      : super(definition, memberThisType);

  factory ClosureFunctionData.readFromDataSource(DataSource source) {
    source.begin(tag);
    ClosureMemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    InterfaceType memberThisType = source.readDartType(allowNull: true);
    FunctionType functionType = source.readDartType();
    ir.FunctionNode functionNode = source.readTreeNode();
    ClassTypeVariableAccess classTypeVariableAccess =
        source.readEnum(ClassTypeVariableAccess.values);
    source.end(tag);
    return new ClosureFunctionData(definition, memberThisType, functionType,
        functionNode, classTypeVariableAccess);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.closureFunction);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartType(memberThisType, allowNull: true);
    sink.writeDartType(functionType);
    sink.writeTreeNode(functionNode);
    sink.writeEnum(classTypeVariableAccess);
    sink.end(tag);
  }

  void forEachParameter(JsToElementMap elementMap,
      void f(DartType type, String name, ConstantValue defaultValue)) {
    void handleParameter(ir.VariableDeclaration node, {bool isOptional: true}) {
      DartType type = elementMap.getDartType(node.type);
      String name = node.name;
      ConstantValue defaultValue;
      if (isOptional) {
        if (node.initializer != null) {
          defaultValue = elementMap.getConstantValue(node.initializer);
        } else {
          defaultValue = new NullConstantValue();
        }
      }
      f(type, name, defaultValue);
    }

    for (int i = 0; i < functionNode.positionalParameters.length; i++) {
      handleParameter(functionNode.positionalParameters[i],
          isOptional: i >= functionNode.requiredParameterCount);
    }
    functionNode.namedParameters.toList()
      ..sort(namedOrdering)
      ..forEach(handleParameter);
  }

  @override
  FunctionType getFunctionType(IrToElementMap elementMap) {
    return functionType;
  }
}

class ClosureFieldData extends ClosureMemberData implements JFieldData {
  /// Tag used for identifying serialized [ClosureFieldData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-field-data';

  DartType _type;

  ClosureFieldData(MemberDefinition definition, InterfaceType memberThisType)
      : super(definition, memberThisType);

  factory ClosureFieldData.readFromDataSource(DataSource source) {
    source.begin(tag);
    MemberDefinition definition =
        new MemberDefinition.readFromDataSource(source);
    InterfaceType memberThisType = source.readDartType(allowNull: true);
    source.end(tag);
    return new ClosureFieldData(definition, memberThisType);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeEnum(JMemberDataKind.closureField);
    sink.begin(tag);
    definition.writeToDataSink(sink);
    sink.writeDartType(memberThisType, allowNull: true);
    sink.end(tag);
  }

  @override
  DartType getFieldType(IrToElementMap elementMap) {
    if (_type != null) return _type;
    ir.TreeNode sourceNode = definition.node;
    ir.DartType type;
    if (sourceNode is ir.Class) {
      type = sourceNode.thisType;
    } else if (sourceNode is ir.VariableDeclaration) {
      type = sourceNode.type;
    } else if (sourceNode is ir.Field) {
      type = sourceNode.type;
    } else if (sourceNode is ir.TypeLiteral) {
      type = sourceNode.type;
    } else if (sourceNode is ir.Typedef) {
      type = sourceNode.type;
    } else if (sourceNode is ir.TypeParameter) {
      type = sourceNode.bound;
    } else {
      failedAt(
          definition.location,
          'Unexpected node type ${sourceNode} in '
          'ClosureFieldData.getFieldType');
    }
    return _type = elementMap.getDartType(type);
  }

  @override
  ConstantExpression getFieldConstantExpression(IrToElementMap elementMap) {
    failedAt(
        definition.location,
        "Unexpected field ${definition} in "
        "ClosureFieldData.getFieldConstantExpression");
    return null;
  }

  @override
  ConstantValue getConstantFieldInitializer(IrToElementMap elementMap) {
    failedAt(
        definition.location,
        "Unexpected field ${definition} in "
        "ClosureFieldData.getConstantFieldInitializer");
    return null;
  }

  @override
  bool hasConstantFieldInitializer(IrToElementMap elementMap) {
    return false;
  }

  @override
  ConstantValue getFieldConstantValue(IrToElementMap elementMap) {
    return null;
  }

  @override
  ClassTypeVariableAccess get classTypeVariableAccess =>
      ClassTypeVariableAccess.none;
}

class ClosureMemberDefinition implements MemberDefinition {
  /// Tag used for identifying serialized [ClosureMemberDefinition] objects in a
  /// debugging data stream.
  static const String tag = 'closure-member-definition';

  final SourceSpan location;
  final MemberKind kind;
  final ir.TreeNode node;

  ClosureMemberDefinition(this.location, this.kind, this.node)
      : assert(
            kind == MemberKind.closureCall || kind == MemberKind.closureField);

  factory ClosureMemberDefinition.readFromDataSource(
      DataSource source, MemberKind kind) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    ir.TreeNode node = source.readTreeNode();
    source.end(tag);
    return new ClosureMemberDefinition(location, kind, node);
  }

  void writeToDataSink(DataSink sink) {
    sink.writeEnum(kind);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.writeTreeNode(node);
    sink.end(tag);
  }

  String toString() => 'ClosureMemberDefinition(kind:$kind,location:$location)';
}

class RecordContainerDefinition implements ClassDefinition {
  /// Tag used for identifying serialized [RecordContainerDefinition] objects in
  /// a debugging data stream.
  static const String tag = 'record-definition';

  final SourceSpan location;

  RecordContainerDefinition(this.location);

  factory RecordContainerDefinition.readFromDataSource(DataSource source) {
    source.begin(tag);
    SourceSpan location = source.readSourceSpan();
    source.end(tag);
    return new RecordContainerDefinition(location);
  }

  @override
  void writeToDataSink(DataSink sink) {
    sink.writeEnum(ClassKind.record);
    sink.begin(tag);
    sink.writeSourceSpan(location);
    sink.end(tag);
  }

  ClassKind get kind => ClassKind.record;

  ir.Node get node => throw new UnsupportedError(
      'RecordContainerDefinition.node for $location');

  String toString() =>
      'RecordContainerDefinition(kind:$kind,location:$location)';
}

/// Collection of scope data collected for a single member.
class ScopeModel {
  /// Collection [ScopeInfo] data for the member.
  KernelScopeInfo scopeInfo;

  /// Collected [CapturedScope] data for nodes.
  Map<ir.Node, KernelCapturedScope> capturedScopesMap =
      <ir.Node, KernelCapturedScope>{};

  /// Collected [ScopeInfo] data for nodes.
  Map<ir.TreeNode, KernelScopeInfo> closuresToGenerate =
      <ir.TreeNode, KernelScopeInfo>{};

  String toString() {
    return '$scopeInfo\n$capturedScopesMap\n$closuresToGenerate';
  }
}

enum TypeVariableKind { cls, method, local, function }

/// A fake ir.Node that holds the TypeParameterType as well as the context in
/// which it occurs.
class TypeVariableTypeWithContext implements ir.Node {
  final ir.Node context;
  final ir.TypeParameterType type;
  final TypeVariableKind kind;
  final ir.TreeNode typeDeclaration;

  /// [context] can be either an ir.Member or a ir.FunctionDeclaration or
  /// ir.FunctionExpression.
  factory TypeVariableTypeWithContext(
      ir.TypeParameterType type, ir.TreeNode context) {
    TypeVariableKind kind;
    ir.TreeNode typeDeclaration = type.parameter.parent;
    if (typeDeclaration == null) {
      // We have a function type variable, like `T` in `void Function<T>(int)`.
      kind = TypeVariableKind.function;
    } else if (typeDeclaration is ir.Class) {
      // We have a class type variable, like `T` in `class Class<T> { ... }`.
      kind = TypeVariableKind.cls;
    } else if (typeDeclaration.parent is ir.Member) {
      ir.Member member = typeDeclaration.parent;
      if (member is ir.Constructor ||
          (member is ir.Procedure && member.isFactory)) {
        // We have a synthesized generic method type variable for a class type
        // variable.
        // TODO(johnniwinther): Handle constructor/factory type variables as
        // method type variables.
        kind = TypeVariableKind.cls;
        typeDeclaration = member.enclosingClass;
      } else {
        // We have a generic method type variable, like `T` in
        // `m<T>() { ... }`.
        kind = TypeVariableKind.method;
        typeDeclaration = typeDeclaration.parent;
        context = typeDeclaration;
      }
    } else {
      // We have a generic local function type variable, like `T` in
      // `m() { local<T>() { ... } ... }`.
      assert(
          typeDeclaration.parent is ir.FunctionExpression ||
              typeDeclaration.parent is ir.FunctionDeclaration,
          "Unexpected type declaration: $typeDeclaration");
      kind = TypeVariableKind.local;
      typeDeclaration = typeDeclaration.parent;
      context = typeDeclaration;
    }
    return new TypeVariableTypeWithContext.internal(
        type, context, kind, typeDeclaration);
  }

  TypeVariableTypeWithContext.internal(
      this.type, this.context, this.kind, this.typeDeclaration);

  accept(ir.Visitor v) {
    throw new UnsupportedError('TypeVariableTypeWithContext.accept');
  }

  visitChildren(ir.Visitor v) {
    throw new UnsupportedError('TypeVariableTypeWithContext.visitChildren');
  }

  int get hashCode => type.hashCode;

  bool operator ==(other) {
    if (other is! TypeVariableTypeWithContext) return false;
    return type == other.type && context == other.context;
  }

  String toString() =>
      'TypeVariableTypeWithContext(type=$type,context=$context,'
      'kind=$kind,typeDeclaration=$typeDeclaration)';
}

abstract class ClosureRtiNeed {
  bool classNeedsTypeArguments(ClassEntity cls);

  bool methodNeedsTypeArguments(FunctionEntity method);

  bool methodNeedsSignature(MemberEntity method);

  bool localFunctionNeedsTypeArguments(ir.Node node);

  bool localFunctionNeedsSignature(ir.Node node);

  bool selectorNeedsTypeArguments(Selector selector);

  bool instantiationNeedsTypeArguments(
      DartType functionType, int typeArgumentCount);
}
