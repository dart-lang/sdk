// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of type_graph_inferrer;

Set<String> okMapSelectorsSet = new Set.from(
    const <String>[
      // From Object.
      "==",
      "hashCode",
      "toString",
      "noSuchMethod",
      "runtimeType",
      // From Map
      "[]",
      "isEmpty",
      "isNotEmpty",
      "keys",
      "length",
      "values",
      "clear",
      "containsKey",
      "containsValue",
      "forEach",
      "remove"]);

class MapTracerVisitor extends TracerVisitor<MapTypeInformation> {
  // These lists are used to keep track of newly discovered assignments to
  // the map. Note that elements at corresponding indices are expected to
  // belong to the same assignment operation.
  List<TypeInformation> keyAssignments = <TypeInformation>[];
  List<TypeInformation> valueAssignments = <TypeInformation>[];
  // This list is used to keep track of assignments of entire maps to
  // this map.
  List<MapTypeInformation> mapAssignments = <MapTypeInformation>[];

  MapTracerVisitor(tracedType, inferrer) : super(tracedType, inferrer);

  /**
   * Returns [true] if the analysis completed successfully, [false]
   * if it bailed out. In the former case, [keyAssignments] and
   * [valueAssignments] hold a list of [TypeInformation] nodes that
   * flow into the key and value types of this map.
   */
  bool run() {
    analyze();
    MapTypeInformation map = tracedType;
    if (continueAnalyzing) {
      map.flowsInto.addAll(flowsInto);
      return true;
    }
    keyAssignments = valueAssignments = mapAssignments = null;
    return false;
  }

  visitClosureCallSiteTypeInformation(ClosureCallSiteTypeInformation info) {
    bailout('Passed to a closure');
  }

  visitStaticCallSiteTypeInformation(StaticCallSiteTypeInformation info) {
    super.visitStaticCallSiteTypeInformation(info);
    Element called = info.calledElement;
    if (called.isForeign(compiler.backend) && called.name == 'JS') {
      bailout('Used in JS ${info.call}');
    }
  }

  visitDynamicCallSiteTypeInformation(DynamicCallSiteTypeInformation info) {
    super.visitDynamicCallSiteTypeInformation(info);
    Selector selector = info.selector;
    String selectorName = selector.name;
    if (currentUser == info.receiver) {
      if (!okMapSelectorsSet.contains(selectorName)) {
        if (selector.isCall) {
          int positionalLength = info.arguments.positional.length;
          if (selectorName == 'addAll') {
            // All keys and values from the argument flow into
            // the map.
            TypeInformation map = info.arguments.positional[0];
            if (map is MapTypeInformation) {
              inferrer.analyzeMapAndEnqueue(map);
              mapAssignments.add(map);
            } else {
              // If we could select a component from a [TypeInformation],
              // like the keytype or valuetype in this case, we could
              // propagate more here.
              // TODO(herhut): implement selection on [TypeInformation].
              bailout('Adding map with unknown typeinfo to current map');
            }
          } else if (selectorName == 'putIfAbsent') {
            // The first argument is a new key, the result type of
            // the second argument becomes a new value.
            // Unfortunately, the type information does not
            // explicitly track the return type, yet, so we have
            // to go to dynamic.
            // TODO(herhut,16507): Use return type of closure in
            // Map.putIfAbsent.
            keyAssignments.add(info.arguments.positional[0]);
            valueAssignments.add(inferrer.types.dynamicType);
          } else {
            // It would be nice to handle [Map.keys] and [Map.values], too.
            // However, currently those calls do not trigger the creation
            // of a [ListTypeInformation], so I have nowhere to propagate
            // that information.
            // TODO(herhut): add support for Map.keys and Map.values.
            bailout('Map used in a not-ok selector [$selectorName]');
            return;
          }
        } else if (selector.isIndexSet) {
          keyAssignments.add(info.arguments.positional[0]);
          valueAssignments.add(info.arguments.positional[1]);
        } else if (!selector.isIndex) {
          bailout('Map used in a not-ok selector [$selectorName]');
          return;
        }
      }
    } else if (selector.isCall &&
               !info.targets.every((element) => element.isFunction)) {
      bailout('Passed to a closure');
      return;
    }
  }
}
