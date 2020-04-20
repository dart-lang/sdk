// Copyright (c) 2019, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library compiler.src.inferrer.set_tracer;

import '../common/names.dart';
import '../elements/entities.dart';
import '../universe/selector.dart' show Selector;
import 'node_tracer.dart';
import 'type_graph_nodes.dart';

/// A set of selector names that [Set] implements and which we know do not
/// change the element type of the set or let the set escape to code that might
/// change the element type.
Set<String> okSetSelectorSet = new Set<String>.from(const <String>[
  // From Object.
  '==',
  'hashCode',
  'toString',
  'noSuchMethod',
  'runtimeType',

  // From Iterable.
  'iterator',
  'map',
  'where',
  'expand',
  'contains',
  'forEach',
  'reduce',
  'fold',
  'every',
  'join',
  'any',
  'toList',
  'toSet',
  'length',
  'isEmpty',
  'isNotEmpty',
  'take',
  'takeWhile',
  'skip',
  'skipWhile',
  'first',
  'last',
  'single',
  'firstWhere',
  'lastWhere',
  'singleWhere',
  'elementAt',

  // From Set.
  'clear',
  'containsAll',
  'difference',
  'intersection',
  'lookup',
  'remove',
  'removeAll',
  'removeWhere',
  'retainAll',
  'retainWhere',
  'union',
]);

class SetTracerVisitor extends TracerVisitor {
  List<TypeInformation> inputs = <TypeInformation>[];

  SetTracerVisitor(tracedType, inferrer) : super(tracedType, inferrer);

  /// Returns [true] if the analysis completed successfully, [false] if it
  /// bailed out. In the former case, [inputs] holds a list of
  /// [TypeInformation] nodes that flow into the element type of this set.
  bool run() {
    analyze();
    SetTypeInformation set = tracedType;
    if (continueAnalyzing) {
      set.addFlowsIntoTargets(flowsInto);
      return true;
    }
    inputs = null;
    return false;
  }

  @override
  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    bailout('Passed to a closure');
  }

  @override
  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    MemberEntity called = info.calledElement;
    if (inferrer.closedWorld.commonElements.isForeign(called) &&
        called.name == Identifiers.JS) {
      bailout('Used in JS ${info.debugName}');
    }
  }

  @override
  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    Selector selector = info.selector;
    String selectorName = selector.name;
    if (currentUser == info.receiver) {
      if (!okSetSelectorSet.contains(selectorName)) {
        if (selector.isCall) {
          switch (selectorName) {
            case 'add':
              inputs.add(info.arguments.positional[0]);
              break;
            case 'addAll':
              // TODO(fishythefish): Extract type argument from type
              // information.
              bailout('Adding iterable with unknown typeinfo to current set');
              break;
            default:
              bailout('Set used in a not-ok selector [$selectorName]');
          }
          return;
        }
      }
    } else if (selector.isCall &&
        (info.hasClosureCallTargets ||
            info.concreteTargets.any((element) => !element.isFunction))) {
      bailout('Passed to a closure');
      return;
    }
  }
}
