// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart' as ir;

import '../closure.dart';
import '../common/tasks.dart';
import '../elements/entities.dart';
import '../world.dart';
import 'element_map.dart';
import 'kernel_backend_strategy.dart';

class KernelClosureDataBuilder extends ir.Visitor {
  final KernelToLocalsMap _localsMap;
  final KernelClosureRepresentationInfo info;

  bool _inTry = false;

  KernelClosureDataBuilder(this._localsMap, ThisLocal thisLocal)
      : info = new KernelClosureRepresentationInfo(thisLocal);

  @override
  defaultNode(ir.Node node) {
    node.visitChildren(this);
  }

  @override
  visitTryCatch(ir.TryCatch node) {
    bool oldInTry = _inTry;
    _inTry = true;
    node.visitChildren(this);
    _inTry = oldInTry;
  }

  @override
  visitTryFinally(ir.TryFinally node) {
    bool oldInTry = _inTry;
    _inTry = true;
    node.visitChildren(this);
    _inTry = oldInTry;
  }

  @override
  visitVariableGet(ir.VariableGet node) {
    if (_inTry) {
      info.registerUsedInTryOrSync(_localsMap.getLocal(node.variable));
    }
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
class KernelClosureConversionTask extends ClosureConversionTask<ir.Node> {
  final KernelToElementMap _elementMap;
  final GlobalLocalsMap _globalLocalsMap;
  Map<Entity, ClosureRepresentationInfo> _infoMap =
      <Entity, ClosureRepresentationInfo>{};

  KernelClosureConversionTask(
      Measurer measurer, this._elementMap, this._globalLocalsMap)
      : super(measurer);

  /// The combined steps of generating our intermediate representation of
  /// closures that need to be rewritten and generating the element model.
  /// Ultimately these two steps will be split apart with the second step
  /// happening later in compilation just before codegen. These steps are
  /// combined here currently to provide a consistent interface to the rest of
  /// the compiler until we are ready to separate these phases.
  @override
  void convertClosures(Iterable<MemberEntity> processedEntities,
      ClosedWorldRefiner closedWorldRefiner) {
    // TODO(efortuna): implement.
  }

  /// TODO(johnniwinther,efortuna): Implement this.
  @override
  ClosureAnalysisInfo getClosureAnalysisInfo(ir.Node node) {
    return const ClosureAnalysisInfo();
  }

  /// TODO(johnniwinther,efortuna): Implement this.
  @override
  LoopClosureRepresentationInfo getClosureRepresentationInfoForLoop(
      ir.Node loopNode) {
    return const LoopClosureRepresentationInfo();
  }

  @override
  ClosureRepresentationInfo getClosureRepresentationInfo(Entity entity) {
    return _infoMap.putIfAbsent(entity, () {
      if (entity is MemberEntity) {
        ir.Member node = _elementMap.getMemberNode(entity);
        ThisLocal thisLocal;
        if (entity.isInstanceMember) {
          thisLocal = new ThisLocal(entity);
        }
        KernelClosureDataBuilder builder = new KernelClosureDataBuilder(
            _globalLocalsMap.getLocalsMap(entity), thisLocal);
        node.accept(builder);
        return builder.info;
      }

      /// TODO(johnniwinther,efortuna): Implement this.
      return const ClosureRepresentationInfo();
    });
  }
}

// TODO(johnniwinther): Add unittest for the computed
// [ClosureRepresentationInfo].
class KernelClosureRepresentationInfo extends ClosureRepresentationInfo {
  final ThisLocal thisLocal;
  final Set<Local> _localsUsedInTryOrSync = new Set<Local>();

  KernelClosureRepresentationInfo(this.thisLocal);

  void registerUsedInTryOrSync(Local local) {
    _localsUsedInTryOrSync.add(local);
  }

  bool variableIsUsedInTryOrSync(Local variable) =>
      _localsUsedInTryOrSync.contains(variable);
}
