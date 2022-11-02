// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common.dart';
import '../elements/entities.dart';
import '../elements/types.dart';
import '../ir/closure.dart';
import '../js_backend/annotations.dart';
import '../js_model/element_map.dart';
import '../serialization/deferrable.dart';
import '../serialization/serialization.dart';
import '../universe/selector.dart';
import 'elements.dart';
import 'closure_migrated.dart' as migrated;
import 'js_world_builder.dart' show JsClosedWorldBuilder;

export 'closure_migrated.dart'
    show AnonymousClosureLocal, JClosureField, JContextField;

class ClosureDataImpl implements ClosureData {
  /// Tag used for identifying serialized [ClosureData] objects in a
  /// debugging data stream.
  static const String tag = 'closure-data';

  final JsToElementMap _elementMap;

  /// Map of the scoping information that corresponds to a particular entity.
  final Deferrable<Map<MemberEntity, ScopeInfo>> _scopeMap;
  final Deferrable<Map<ir.TreeNode, CapturedScope>> _capturedScopesMap;
  // Indicates the type variables (if any) that are captured in a given
  // Signature function.
  final Deferrable<Map<MemberEntity, CapturedScope>>
      _capturedScopeForSignatureMap;

  final Deferrable<Map<ir.LocalFunction, ClosureRepresentationInfo>>
      _localClosureRepresentationMap;

  final Map<MemberEntity, MemberEntity> _enclosingMembers;

  ClosureDataImpl(
      this._elementMap,
      Map<MemberEntity, ScopeInfo> scopeMap,
      Map<ir.TreeNode, CapturedScope> capturedScopesMap,
      Map<MemberEntity, CapturedScope> capturedScopeForSignatureMap,
      Map<ir.LocalFunction, ClosureRepresentationInfo>
          localClosureRepresentationMap,
      this._enclosingMembers)
      : _scopeMap = Deferrable.eager(scopeMap),
        _capturedScopesMap = Deferrable.eager(capturedScopesMap),
        _capturedScopeForSignatureMap =
            Deferrable.eager(capturedScopeForSignatureMap),
        _localClosureRepresentationMap =
            Deferrable.eager(localClosureRepresentationMap);

  ClosureDataImpl._deserialized(
      this._elementMap,
      this._scopeMap,
      this._capturedScopesMap,
      this._capturedScopeForSignatureMap,
      this._localClosureRepresentationMap,
      this._enclosingMembers);

  /// Deserializes a [ClosureData] object from [source].
  factory ClosureDataImpl.readFromDataSource(
      JsToElementMap elementMap, DataSourceReader source) {
    source.begin(tag);
    // TODO(johnniwinther): Support shared [ScopeInfo].
    final scopeMap = source.readDeferrable(() => source.readMemberMap(
        (MemberEntity member) => ScopeInfo.readFromDataSource(source)));
    final capturedScopesMap = source.readDeferrable(() =>
        source.readTreeNodeMap(() => CapturedScope.readFromDataSource(source)));
    final capturedScopeForSignatureMap = source.readDeferrable(() =>
        source.readMemberMap(
            (MemberEntity member) => CapturedScope.readFromDataSource(source)));
    final localClosureRepresentationMap = source.readDeferrable(() =>
        source.readTreeNodeMap<ir.LocalFunction, ClosureRepresentationInfo>(
            () => ClosureRepresentationInfo.readFromDataSource(source)));
    Map<MemberEntity, MemberEntity> enclosingMembers =
        source.readMemberMap((member) => source.readMember());
    source.end(tag);
    return ClosureDataImpl._deserialized(
        elementMap,
        scopeMap,
        capturedScopesMap,
        capturedScopeForSignatureMap,
        localClosureRepresentationMap,
        enclosingMembers);
  }

  /// Serializes this [ClosureData] to [sink].
  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.begin(tag);
    sink.writeDeferrable(() => sink.writeMemberMap(_scopeMap.loaded(),
        (MemberEntity member, ScopeInfo info) => info.writeToDataSink(sink)));
    sink.writeDeferrable(() => sink.writeTreeNodeMap(
            _capturedScopesMap.loaded(), (CapturedScope scope) {
          scope.writeToDataSink(sink);
        }));
    sink.writeDeferrable(() => sink.writeMemberMap(
        _capturedScopeForSignatureMap.loaded(),
        (MemberEntity member, CapturedScope scope) =>
            scope.writeToDataSink(sink)));
    sink.writeDeferrable(() => sink
            .writeTreeNodeMap(_localClosureRepresentationMap.loaded(),
                (ClosureRepresentationInfo info) {
          info.writeToDataSink(sink);
        }));
    sink.writeMemberMap(_enclosingMembers,
        (MemberEntity member, MemberEntity value) {
      sink.writeMember(value);
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

    return _scopeMap.loaded()[entity]!;
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
        return _capturedScopesMap.loaded()[definition.node] ??
            const CapturedScope();
      case MemberKind.signature:
        return _capturedScopeForSignatureMap.loaded()[entity] ??
            const CapturedScope();
      default:
        throw failedAt(entity, "Unexpected member definition $definition");
    }
  }

  @override
  // TODO(efortuna): Eventually capturedScopesMap[node] should always
  // be non-null, and we should just test that with an assert.
  CapturedLoopScope getCapturedLoopScope(ir.Node loopNode) =>
      _capturedScopesMap.loaded()[loopNode] as CapturedLoopScope? ??
      const CapturedLoopScope();

  @override
  ClosureRepresentationInfo getClosureInfo(ir.LocalFunction node) =>
      _localClosureRepresentationMap.loaded()[node]!;

  @override
  MemberEntity getEnclosingMember(MemberEntity member) {
    return _enclosingMembers[member] ?? member;
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
  final DiagnosticReporter _reporter;
  final JsToElementMap _elementMap;
  final AnnotationsData _annotationsData;

  /// Map of the scoping information that corresponds to a particular entity.
  final Map<MemberEntity, ScopeInfo> _scopeMap = {};
  final Map<ir.TreeNode, CapturedScope> _capturedScopesMap = {};
  // Indicates the type variables (if any) that are captured in a given
  // Signature function.
  final Map<MemberEntity, CapturedScope> _capturedScopeForSignatureMap = {};

  final Map<ir.LocalFunction, ClosureRepresentationInfo>
      _localClosureRepresentationMap = {};

  final Map<MemberEntity, MemberEntity> _enclosingMembers = {};

  ClosureDataBuilder(this._reporter, this._elementMap, this._annotationsData);

  void _updateScopeBasedOnRtiNeed(KernelScopeInfo scope, ClosureRtiNeed rtiNeed,
      MemberEntity outermostEntity) {
    bool includeForRti(Set<VariableUse> useSet) {
      for (VariableUse usage in useSet) {
        switch (usage.kind) {
          case VariableUseKind.explicit:
            return true;
          case VariableUseKind.implicitCast:
            if (_annotationsData
                .getImplicitDowncastCheckPolicy(outermostEntity)
                .isEmitted) {
              return true;
            }
            break;
          case VariableUseKind.localType:
            break;
          case VariableUseKind.constructorTypeArgument:
            ConstructorEntity constructor =
                _elementMap.getConstructor(usage.member!);
            if (rtiNeed.classNeedsTypeArguments(constructor.enclosingClass)) {
              return true;
            }
            break;
          case VariableUseKind.staticTypeArgument:
            FunctionEntity method =
                _elementMap.getMethod(usage.member as ir.Procedure);
            if (rtiNeed.methodNeedsTypeArguments(method)) {
              return true;
            }
            break;
          case VariableUseKind.instanceTypeArgument:
            Selector selector = _elementMap.getSelector(usage.invocation!);
            if (rtiNeed.selectorNeedsTypeArguments(selector)) {
              return true;
            }
            break;
          case VariableUseKind.localTypeArgument:
            // TODO(johnniwinther): We should be able to track direct local
            // function invocations and not have to use the selector here.
            Selector selector = _elementMap.getSelector(usage.invocation!);
            if (rtiNeed.localFunctionNeedsTypeArguments(usage.localFunction!) ||
                rtiNeed.selectorNeedsTypeArguments(selector)) {
              return true;
            }
            break;
          case VariableUseKind.memberParameter:
            if (_annotationsData
                .getParameterCheckPolicy(outermostEntity)
                .isEmitted) {
              return true;
            } else {
              FunctionEntity method =
                  _elementMap.getMethod(usage.member as ir.Procedure);
              if (rtiNeed.methodNeedsSignature(method)) {
                return true;
              }
            }
            break;
          case VariableUseKind.localParameter:
            if (_annotationsData
                .getParameterCheckPolicy(outermostEntity)
                .isEmitted) {
              return true;
            } else if (rtiNeed
                .localFunctionNeedsSignature(usage.localFunction!)) {
              return true;
            }
            break;
          case VariableUseKind.memberReturnType:
            FunctionEntity method =
                _elementMap.getMethod(usage.member as ir.Procedure);
            if (rtiNeed.methodNeedsSignature(method)) {
              return true;
            }
            break;
          case VariableUseKind.localReturnType:
            if (usage.localFunction!.function.asyncMarker !=
                ir.AsyncMarker.Sync) {
              // The Future/Iterator/Stream implementation requires the type.
              return true;
            }
            if (rtiNeed.localFunctionNeedsSignature(usage.localFunction!)) {
              return true;
            }
            break;
          case VariableUseKind.fieldType:
            if (_annotationsData
                .getParameterCheckPolicy(outermostEntity)
                .isEmitted) {
              return true;
            }
            break;
          case VariableUseKind.listLiteral:
            if (rtiNeed.classNeedsTypeArguments(
                _elementMap.commonElements.jsArrayClass)) {
              return true;
            }
            break;
          case VariableUseKind.setLiteral:
            if (rtiNeed.classNeedsTypeArguments(
                _elementMap.commonElements.setLiteralClass)) {
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
                null, usage.instantiation!.typeArguments.length)) {
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
      Map<MemberEntity, ClosureScopeModel> closureModels,
      ClosureRtiNeed rtiNeed,
      List<FunctionEntity> callMethods) {
    void processModel(MemberEntity member, ClosureScopeModel model) {
      Map<ir.VariableDeclaration, migrated.JContextField> allBoxedVariables =
          _elementMap.makeContextContainer(model.scopeInfo!, member);
      _scopeMap[member] = JsScopeInfo.from(
          allBoxedVariables, model.scopeInfo!, member.enclosingClass);

      model.capturedScopesMap
          .forEach((ir.Node node, KernelCapturedScope scope) {
        Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables =
            _elementMap.makeContextContainer(scope, member);
        _updateScopeBasedOnRtiNeed(scope, rtiNeed, member);

        if (scope is KernelCapturedLoopScope) {
          _capturedScopesMap[node as ir.TreeNode] = JsCapturedLoopScope.from(
              boxedVariables, scope, member.enclosingClass);
        } else {
          _capturedScopesMap[node as ir.TreeNode] = JsCapturedScope.from(
              boxedVariables, scope, member.enclosingClass);
        }
        allBoxedVariables.addAll(boxedVariables);
      });

      Map<ir.LocalFunction, KernelScopeInfo> closuresToGenerate =
          model.closuresToGenerate;
      for (ir.LocalFunction node in closuresToGenerate.keys) {
        ir.FunctionNode functionNode = node.function;
        JsClosureClassInfo closureClassInfo = _produceSyntheticElements(
            closedWorldBuilder,
            member,
            functionNode,
            closuresToGenerate[node]!,
            allBoxedVariables,
            rtiNeed,
            createSignatureMethod: rtiNeed.localFunctionNeedsSignature(
                functionNode.parent as ir.LocalFunction));
        // Add also for the call method.
        _scopeMap[closureClassInfo.callMethod!] = closureClassInfo;
        if (closureClassInfo.signatureMethod != null) {
          _scopeMap[closureClassInfo.signatureMethod!] = closureClassInfo;

          // Set up capturedScope for signature method. This is distinct from
          // _capturedScopesMap because there is no corresponding ir.Node for
          // the signature.
          if (rtiNeed.localFunctionNeedsSignature(
                  functionNode.parent as ir.LocalFunction) &&
              model.capturedScopesMap[functionNode] != null) {
            KernelCapturedScope capturedScope =
                model.capturedScopesMap[functionNode]!;
            assert(capturedScope is! KernelCapturedLoopScope);
            KernelCapturedScope signatureCapturedScope =
                KernelCapturedScope.forSignature(capturedScope);
            _updateScopeBasedOnRtiNeed(signatureCapturedScope, rtiNeed, member);
            _capturedScopeForSignatureMap[closureClassInfo.signatureMethod!] =
                JsCapturedScope.from(
                    {}, signatureCapturedScope, member.enclosingClass);
          }
        }
        callMethods.add(closureClassInfo.callMethod!);
      }
    }

    closureModels.forEach((MemberEntity member, ClosureScopeModel model) {
      _reporter.withCurrentElement(member, () {
        processModel(member, model);
      });
    });
    return ClosureDataImpl(
        _elementMap,
        _scopeMap,
        _capturedScopesMap,
        _capturedScopeForSignatureMap,
        _localClosureRepresentationMap,
        _enclosingMembers);
  }

  /// Given what variables are captured at each point, construct closure classes
  /// with fields containing the captured variables to replicate the Dart
  /// closure semantics in JS. If this closure captures any variables (meaning
  /// the closure accesses a variable that gets accessed at some point), then
  /// boxForCapturedVariables stores the local context for those variables.
  /// If no variables are captured, this parameter is null.
  JsClosureClassInfo _produceSyntheticElements(
      JsClosedWorldBuilder closedWorldBuilder,
      MemberEntity member,
      ir.FunctionNode node,
      KernelScopeInfo info,
      Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables,
      ClosureRtiNeed rtiNeed,
      {required bool createSignatureMethod}) {
    _updateScopeBasedOnRtiNeed(info, rtiNeed, member);
    JsClosureClassInfo closureClassInfo = closedWorldBuilder.buildClosureClass(
        member, node, member.library as JLibrary, boxedVariables, info,
        createSignatureMethod: createSignatureMethod);

    // We want the original declaration where that function is used to point
    // to the correct closure class.
    _enclosingMembers[closureClassInfo.callMethod!] = member;
    if (closureClassInfo.signatureMethod != null) {
      _enclosingMembers[closureClassInfo.signatureMethod!] = member;
    }
    if (node.parent is ir.Member) {
      assert(_elementMap.getMember(node.parent as ir.Member) == member);
    } else {
      assert(node.parent is ir.LocalFunction);
      _localClosureRepresentationMap[node.parent as ir.LocalFunction] =
          closureClassInfo;
    }
    return closureClassInfo;
  }
}

class JsScopeInfo extends ScopeInfo {
  /// Tag used for identifying serialized [JsScopeInfo] objects in a
  /// debugging data stream.
  static const String tag = 'scope-info';

  final Iterable<ir.VariableDeclaration> _localsUsedInTryOrSync;

  Set<Local>? _localsUsedInTryOrSyncCache;

  @override
  final Local? thisLocal;

  final Map<ir.VariableDeclaration, migrated.JContextField> _boxedVariables;

  Map<Local, migrated.JContextField>? _boxedVariablesCache;

  JsScopeInfo.internal(
      this._localsUsedInTryOrSync, this.thisLocal, this._boxedVariables);

  JsScopeInfo.from(
      this._boxedVariables, KernelScopeInfo info, ClassEntity? enclosingClass)
      : this.thisLocal = info.hasThisLocal ? ThisLocal(enclosingClass!) : null,
        this._localsUsedInTryOrSync = info.localsUsedInTryOrSync;

  void _ensureBoxedVariableCache(KernelToLocalsMap localsMap) {
    if (_boxedVariablesCache == null) {
      if (_boxedVariables.isEmpty) {
        _boxedVariablesCache = const {};
      } else {
        final cache = <Local, migrated.JContextField>{};
        _boxedVariables.forEach(
            (ir.VariableDeclaration node, migrated.JContextField field) {
          cache[localsMap.getLocalVariable(node)] = field;
        });
        _boxedVariablesCache = cache;
      }
    }
  }

  @override
  void forEachBoxedVariable(
      KernelToLocalsMap localsMap, f(Local local, FieldEntity field)) {
    _ensureBoxedVariableCache(localsMap);
    _boxedVariablesCache!.forEach(f);
  }

  @override
  bool localIsUsedInTryOrSync(KernelToLocalsMap localsMap, Local variable) {
    if (_localsUsedInTryOrSyncCache == null) {
      if (_localsUsedInTryOrSync.isEmpty) {
        _localsUsedInTryOrSyncCache = const {};
      } else {
        _localsUsedInTryOrSyncCache = {};
        for (ir.VariableDeclaration node in _localsUsedInTryOrSync) {
          _localsUsedInTryOrSyncCache!.add(localsMap.getLocalVariable(node));
        }
      }
    }
    return _localsUsedInTryOrSyncCache!.contains(variable);
  }

  @override
  String toString() {
    StringBuffer sb = StringBuffer();
    sb.write('this=$thisLocal,');
    sb.write('localsUsedInTryOrSync={${_localsUsedInTryOrSync.join(', ')}}');
    return sb.toString();
  }

  @override
  bool isBoxedVariable(KernelToLocalsMap localsMap, Local variable) {
    _ensureBoxedVariableCache(localsMap);
    return _boxedVariablesCache!.containsKey(variable);
  }

  factory JsScopeInfo.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Iterable<ir.VariableDeclaration> localsUsedInTryOrSync =
        source.readTreeNodes<ir.VariableDeclaration>();
    Local? thisLocal = source.readLocalOrNull();
    Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables =
        source.readTreeNodeMap<ir.VariableDeclaration, migrated.JContextField>(
            () => source.readMember() as migrated.JContextField);
    source.end(tag);
    if (boxedVariables.isEmpty) boxedVariables = const {};
    return JsScopeInfo.internal(
        localsUsedInTryOrSync, thisLocal, boxedVariables);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(ScopeInfoKind.scopeInfo);
    sink.begin(tag);
    sink.writeTreeNodes(_localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeTreeNodeMap(_boxedVariables, sink.writeMember);
    sink.end(tag);
  }
}

class JsCapturedScope extends JsScopeInfo implements CapturedScope {
  /// Tag used for identifying serialized [JsCapturedScope] objects in a
  /// debugging data stream.
  static const String tag = 'captured-scope';

  @override
  final Local? contextBox;

  JsCapturedScope.internal(super.localsUsedInTryOrSync, super.thisLocal,
      super.boxedVariables, this.contextBox)
      : super.internal();

  JsCapturedScope.from(
      super.boxedVariables, super.capturedScope, super.enclosingClass)
      : this.contextBox =
            boxedVariables.isNotEmpty ? boxedVariables.values.first.box : null,
        super.from();

  @override
  bool get requiresContextBox => _boxedVariables.isNotEmpty;

  factory JsCapturedScope.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Iterable<ir.VariableDeclaration> localsUsedInTryOrSync =
        source.readTreeNodes<ir.VariableDeclaration>();
    Local? thisLocal = source.readLocalOrNull();
    Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables =
        source.readTreeNodeMap<ir.VariableDeclaration, migrated.JContextField>(
            () => source.readMember() as migrated.JContextField);
    Local? context = source.readLocalOrNull();
    source.end(tag);
    return JsCapturedScope.internal(
        localsUsedInTryOrSync, thisLocal, boxedVariables, context);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(ScopeInfoKind.capturedScope);
    sink.begin(tag);
    sink.writeTreeNodes(_localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeTreeNodeMap(_boxedVariables, sink.writeMember);
    sink.writeLocalOrNull(contextBox);
    sink.end(tag);
  }
}

class JsCapturedLoopScope extends JsCapturedScope implements CapturedLoopScope {
  /// Tag used for identifying serialized [JsCapturedLoopScope] objects in a
  /// debugging data stream.
  static const String tag = 'captured-loop-scope';

  final List<ir.VariableDeclaration> _boxedLoopVariables;

  JsCapturedLoopScope.internal(super.localsUsedInTryOrSync, super.thisLocal,
      super.boxedVariables, super.context, this._boxedLoopVariables)
      : super.internal();

  JsCapturedLoopScope.from(super.boxedVariables,
      KernelCapturedLoopScope super.capturedScope, super.enclosingClass)
      : this._boxedLoopVariables = capturedScope.boxedLoopVariables,
        super.from();

  @override
  bool get hasBoxedLoopVariables => _boxedLoopVariables.isNotEmpty;

  factory JsCapturedLoopScope.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Iterable<ir.VariableDeclaration> localsUsedInTryOrSync =
        source.readTreeNodes<ir.VariableDeclaration>();
    Local? thisLocal = source.readLocalOrNull();
    Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables =
        source.readTreeNodeMap<ir.VariableDeclaration, migrated.JContextField>(
            () => source.readMember() as migrated.JContextField);
    Local? context = source.readLocalOrNull();
    List<ir.VariableDeclaration> boxedLoopVariables =
        source.readTreeNodes<ir.VariableDeclaration>();
    source.end(tag);
    return JsCapturedLoopScope.internal(localsUsedInTryOrSync, thisLocal,
        boxedVariables, context, boxedLoopVariables);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(ScopeInfoKind.capturedLoopScope);
    sink.begin(tag);
    sink.writeTreeNodes(_localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeTreeNodeMap(_boxedVariables, sink.writeMember);
    sink.writeLocalOrNull(contextBox);
    sink.writeTreeNodes(_boxedLoopVariables);
    sink.end(tag);
  }

  @override
  List<Local> getBoxedLoopVariables(KernelToLocalsMap localsMap) {
    List<Local> locals = [];
    for (ir.VariableDeclaration boxedLoopVariable in _boxedLoopVariables) {
      locals.add(localsMap.getLocalVariable(boxedLoopVariable));
    }
    return locals;
  }
}

// TODO(johnniwinther): Add unittest for the computed [ClosureClass].
class JsClosureClassInfo extends JsScopeInfo
    implements ClosureRepresentationInfo, migrated.JsClosureClassInfo {
  /// Tag used for identifying serialized [JsClosureClassInfo] objects in a
  /// debugging data stream.
  static const String tag = 'closure-representation-info';

  @override
  JFunction? callMethod;

  @override
  JSignatureMethod? signatureMethod;

  /// The local used for this closure, if it is an anonymous closure, i.e.
  /// an `ir.FunctionExpression`.
  final Local? _closureEntity;

  /// The local variable that defines this closure, if it is a local function
  /// declaration.
  final ir.VariableDeclaration? _closureEntityVariable;

  @override
  final Local? thisLocal;

  @override
  final JClass closureClassEntity;

  final Map<ir.VariableDeclaration, JField> _variableToFieldMap;
  final Map<JTypeVariable, JField> _typeVariableToFieldMap;
  final Map<Local, JField> _localToFieldMap;
  Map<JField, Local>? _fieldToLocalsMap;

  JsClosureClassInfo.internal(
      Iterable<ir.VariableDeclaration> localsUsedInTryOrSync,
      this.thisLocal,
      Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables,
      this.callMethod,
      this.signatureMethod,
      this._closureEntity,
      this._closureEntityVariable,
      this.closureClassEntity,
      this._variableToFieldMap,
      this._typeVariableToFieldMap,
      this._localToFieldMap)
      : super.internal(localsUsedInTryOrSync, thisLocal, boxedVariables);

  JsClosureClassInfo.fromScopeInfo(
      this.closureClassEntity,
      ir.FunctionNode closureSourceNode,
      Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables,
      KernelScopeInfo info,
      ClassEntity? enclosingClass,
      this._closureEntity,
      this._closureEntityVariable,
      this.thisLocal)
      : _variableToFieldMap = {},
        _typeVariableToFieldMap = {},
        _localToFieldMap = {},
        super.from(boxedVariables, info, enclosingClass);

  factory JsClosureClassInfo.readFromDataSource(DataSourceReader source) {
    source.begin(tag);
    Iterable<ir.VariableDeclaration> localsUsedInTryOrSync =
        source.readTreeNodes<ir.VariableDeclaration>();
    Local? thisLocal = source.readLocalOrNull();
    Map<ir.VariableDeclaration, migrated.JContextField> boxedVariables =
        source.readTreeNodeMap<ir.VariableDeclaration, migrated.JContextField>(
            () => source.readMember() as migrated.JContextField);
    JFunction callMethod = source.readMember() as JFunction;
    JSignatureMethod? signatureMethod =
        source.readMemberOrNull() as JSignatureMethod?;
    Local? closureEntity = source.readLocalOrNull();
    ir.VariableDeclaration? closureEntityVariable =
        source.readTreeNodeOrNull() as ir.VariableDeclaration?;
    JClass closureClassEntity = source.readClass() as JClass;
    Map<ir.VariableDeclaration, JField> localToFieldMap =
        source.readTreeNodeMap<ir.VariableDeclaration, JField>(
            () => source.readMember() as JField);
    Map<JTypeVariable, JField> typeVariableToFieldMap =
        source.readTypeVariableMap<JTypeVariable, JField>(
            () => source.readMember() as JField);
    Map<Local, JField> thisLocalToFieldMap =
        source.readLocalMap(() => source.readMember() as JField);
    source.end(tag);
    if (boxedVariables.isEmpty) boxedVariables = const {};
    if (localToFieldMap.isEmpty) localToFieldMap = const {};
    return JsClosureClassInfo.internal(
        localsUsedInTryOrSync,
        thisLocal,
        boxedVariables,
        callMethod,
        signatureMethod,
        closureEntity,
        closureEntityVariable,
        closureClassEntity,
        localToFieldMap,
        typeVariableToFieldMap,
        thisLocalToFieldMap);
  }

  @override
  void writeToDataSink(DataSinkWriter sink) {
    sink.writeEnum(ScopeInfoKind.closureRepresentationInfo);
    sink.begin(tag);
    sink.writeTreeNodes(_localsUsedInTryOrSync);
    sink.writeLocalOrNull(thisLocal);
    sink.writeTreeNodeMap(_boxedVariables, sink.writeMember);
    sink.writeMember(callMethod!);
    sink.writeMemberOrNull(signatureMethod);
    sink.writeLocalOrNull(_closureEntity);
    sink.writeTreeNodeOrNull(_closureEntityVariable);
    sink.writeClass(closureClassEntity);
    sink.writeTreeNodeMap(_variableToFieldMap, sink.writeMember);
    sink.writeTypeVariableMap(_typeVariableToFieldMap, sink.writeMember);
    sink.writeLocalMap(_localToFieldMap, sink.writeMember);
    sink.end(tag);
  }

  @override
  bool hasFieldForLocal(Local local) => _localToFieldMap.containsKey(local);

  @override
  void registerFieldForLocal(Local local, JField field) {
    assert(_fieldToLocalsMap == null);
    _localToFieldMap[local] = field;
  }

  @override
  void registerFieldForVariable(ir.VariableDeclaration node, JField field) {
    assert(_fieldToLocalsMap == null);
    _variableToFieldMap[node] = field;
  }

  @override
  bool hasFieldForTypeVariable(JTypeVariable typeVariable) =>
      _typeVariableToFieldMap.containsKey(typeVariable);

  @override
  void registerFieldForTypeVariable(JTypeVariable typeVariable, JField field) {
    assert(_fieldToLocalsMap == null);
    _typeVariableToFieldMap[typeVariable] = field;
  }

  @override
  void registerFieldForBoxedVariable(
      ir.VariableDeclaration node, JField field) {
    assert(_boxedVariablesCache == null);
    _boxedVariables[node] = field as migrated.JContextField;
  }

  void _ensureFieldToLocalsMap(KernelToLocalsMap localsMap) {
    if (_fieldToLocalsMap == null) {
      _fieldToLocalsMap = {};
      _variableToFieldMap.forEach((ir.VariableDeclaration node, JField field) {
        _fieldToLocalsMap![field] = localsMap.getLocalVariable(node);
      });
      _typeVariableToFieldMap
          .forEach((TypeVariableEntity typeVariable, JField field) {
        _fieldToLocalsMap![field] =
            localsMap.getLocalTypeVariableEntity(typeVariable);
      });
      _localToFieldMap.forEach((Local local, JField field) {
        _fieldToLocalsMap![field] = local;
      });
      if (_fieldToLocalsMap!.isEmpty) {
        _fieldToLocalsMap = const {};
      }
    }
  }

  @override
  List<Local> getCreatedFieldEntities(KernelToLocalsMap localsMap) {
    _ensureFieldToLocalsMap(localsMap);
    return _fieldToLocalsMap!.values.toList();
  }

  @override
  Local getLocalForField(KernelToLocalsMap localsMap, FieldEntity field) {
    _ensureFieldToLocalsMap(localsMap);
    return _fieldToLocalsMap![field]!;
  }

  @override
  FieldEntity? get thisFieldEntity => _localToFieldMap[thisLocal];

  @override
  void forEachFreeVariable(
      KernelToLocalsMap localsMap, f(Local variable, JField field)) {
    _ensureFieldToLocalsMap(localsMap);
    _ensureBoxedVariableCache(localsMap);
    _fieldToLocalsMap!.forEach((JField field, Local local) {
      f(local, field);
    });
    _boxedVariablesCache!.forEach(f);
  }

  @override
  bool get isClosure => true;

  @override
  Local? getClosureEntity(KernelToLocalsMap localsMap) {
    return _closureEntityVariable != null
        ? localsMap.getLocalVariable(_closureEntityVariable!)
        : _closureEntity;
  }
}

abstract class ClosureRtiNeed {
  bool classNeedsTypeArguments(ClassEntity cls);

  bool methodNeedsTypeArguments(FunctionEntity method);

  bool methodNeedsSignature(MemberEntity method);

  bool localFunctionNeedsTypeArguments(ir.LocalFunction node);

  bool localFunctionNeedsSignature(ir.LocalFunction node);

  bool selectorNeedsTypeArguments(Selector selector);

  bool instantiationNeedsTypeArguments(
      FunctionType? functionType, int typeArgumentCount);
}
