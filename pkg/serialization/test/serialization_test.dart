// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library serialization_test;

import 'dart:json' as json;
import 'package:unittest/unittest.dart';
import 'package:serialization/serialization.dart';
import 'package:serialization/src/serialization_helpers.dart';
import 'package:serialization/src/mirrors_helpers.dart';

part 'test_models.dart';

main() {
  var p1 = new Person();
  var a1 = new Address();
  a1.street = 'N 34th';
  a1.city = 'Seattle';

  test('Basic extraction of a simple object', () {
    // TODO(alanknight): Switch these to use literal types. Issue
    var s = new Serialization()
        ..addRuleFor(a1).configureForMaps();
    Map extracted = states(a1, s).first;
    expect(extracted.length, 4);
    expect(extracted['street'], 'N 34th');
    expect(extracted['city'], 'Seattle');
    expect(extracted['state'], null);
    expect(extracted['zip'], null);
    Reader reader = setUpReader(s, extracted);
    Address a2 = readBackSimple(s, a1, reader);
    expect(a2.street, 'N 34th');
    expect(a2.city, 'Seattle');
    expect(a2.state,null);
    expect(a2.zip, null);
  });

  test('Slightly further with a simple object', () {
    // TODO(alanknight): Tests that rely on what index rules are going to be
    // at are very fragile. At least abstract it to something calculated.
    var p1 = new Person()..name = 'Alice'..address = a1;
    var s = new Serialization()
        ..addRuleFor(p1).configureForMaps()
        ..addRuleFor(a1).configureForMaps();
    // TODO(alanknight): Need a better API for getting to flat state without
    // actually writing.
    var w = new Writer(s);
    w.write(p1);
    var personRule = s.rules.firstMatching(
        (x) => x is BasicRule && x.type == reflect(p1).type);
    var flatPerson = w.states[personRule.number].first;
    var primStates = w.states.first;
    expect(primStates.isEmpty, true);
    expect(flatPerson["name"], "Alice");
    var ref = flatPerson["address"];
    expect(ref is Reference, true);
    var addressRule = s.rules.firstMatching(
        (x) => x is BasicRule && x.type == reflect(a1).type);
    expect(ref.ruleNumber, addressRule.number);
    expect(ref.objectNumber, 0);
    expect(w.states[addressRule.number].first['street'], 'N 34th');
  });

  test('exclude fields', () {
    var s = new Serialization()
        ..addRuleFor(a1,
            excludeFields: ['state', 'zip']).configureForMaps();
    var extracted = states(a1, s).first;
    expect(extracted.length, 2);
    expect(extracted['street'], 'N 34th');
    expect(extracted['city'], 'Seattle');
    Reader reader = setUpReader(s, extracted);
    Address a2 = readBackSimple(s, a1, reader);
    expect(a2.state, null);
    expect(a2.city, 'Seattle');
  });

  test('list', () {
    var list = [5, 4, 3, 2, 1];
    var s = new Serialization();
    var extracted = states(list, s).first;
    expect(extracted.length, 5);
    for (var i = 0; i < 5; i++) {
      expect(extracted[i], (5 - i));
    }
    Reader reader = setUpReader(s, extracted);
    var list2 = readBackSimple(s, list, reader);
    expect(list, list2);
  });

  test('different kinds of fields', () {
    var x = new Various.Foo("d", "e");
    x.a = "a";
    x.b = "b";
    x._c = "c";
    var s = new Serialization()
      ..addRuleFor(x,
          constructor: "Foo",
          constructorFields: ["d", "e"]);
    var state = states(x, s).first;
    expect(state.length, 4);
    var expected = "abde";
    for (var i in [0,1,2,3]) {
      expect(state[i], expected[i]);
    }
    Reader reader = setUpReader(s, state);
    Various y = readBackSimple(s, x, reader);
    expect(x.a, y.a);
    expect(x.b, y.b);
    expect(x.d, y.d);
    expect(x.e, y.e);
    expect(y._c, 'default value');
  });

  test('Stream', () {
    // This is an interesting case. The Stream doesn't expose its internal
    // collection at all, and sets it in the constructor. So to get it we
    // read a private field and then set that via the constructor. That works
    // but should we have some kind of large red flag that you're using private
    // state.
    var stream = new Stream([3,4,5]);
    expect((stream..next()).next(), 4);
    expect(stream.position, 2);
    var s = new Serialization()
      ..addRuleFor(stream,
          constructorFields: ['_collection']);
    var state = states(stream, s).first;
    // Define names for the variable offsets to make this more readable.
    var _collection = 0, position = 1;
    expect(state[_collection],[3,4,5]);
    expect(state[position], 2);
  });

  test('date', () {
    var date = new DateTime.now();
    var s = new Serialization()
        ..addRuleFor(date,
            constructorFields : ["year", "month", "day", "hour", "minute",
                                 "second", "millisecond", "isUtc"])
            .configureForMaps();
    var state = states(date, s).first;
    expect(state["year"],date.year);
    expect(state["isUtc"],date.isUtc);
    expect(state["millisecond"], date.millisecond);
  });

  test('Iteration helpers', () {
    var map = {"a" : 1, "b" : 2, "c" : 3};
    var list = [1, 2, 3];
    var set = new Set.from(list);
    var m = keysAndValues(map);
    var l = keysAndValues(list);
    var s = keysAndValues(set);

    m.forEach((key, value) {expect(key.charCodes[0], value + 96);});
    l.forEach((key, value) {expect(key + 1, value);});
    var index = 0;
    var seen = new Set();
    s.forEach((key, value) {
      expect(key, index++);
      expect(seen.contains(value), isFalse);
      seen.add(value);
    });
    expect(seen.length, 3);

    var i = 0;
    m = values(map);
    l = values(list);
    s = values(set);
    m.forEach((each) {expect(each, ++i);});
    i = 0;
    l.forEach((each) {expect(each, ++i);});
    i = 0;
    s.forEach((each) {expect(each, ++i);});
    i = 0;

    seen = new Set();
    for (var each in m) {
      expect(seen.contains(each), isFalse);
      seen.add(each);
    }
    expect(seen.length, 3);
    i = 0;
    for (var each in l) {
      expect(each, ++i);
    }
  });

  Node n1 = new Node("1"), n2 = new Node("2"), n3 = new Node("3");
  n1.children = [n2, n3];
  n2.parent = n1;
  n3.parent = n1;

  test('Trace a cyclical structure', () {
    var s = new Serialization();
    var trace = new Trace(new Writer(s));
    trace.writer.trace = trace;
    trace.trace(n1);
    var all = trace.writer.references.keys.toSet();
    expect(all.length, 4);
    expect(all.contains(n1), isTrue);
    expect(all.contains(n2), isTrue);
    expect(all.contains(n3), isTrue);
    expect(all.contains(n1.children), isTrue);
  });

  test('Flatten references in a cyclical structure', () {
    var s = new Serialization();
    var w = new Writer(s);
    w.trace = new Trace(w);
    w.write(n1);
    expect(w.states.length, 5); // prims, lists, essential lists, basic
    var children = 0, name = 1, parent = 2;
    var nodeRule = s.rules.firstMatching((x) => x is BasicRule);
    List rootNode = w.states[nodeRule.number].where(
        (x) => x[name] == "1").toList();
    rootNode = rootNode.first;
    expect(rootNode[parent], isNull);
    var list = w.states[1].first;
    expect(w.stateForReference(rootNode[children]), list);
    var parentNode = w.stateForReference(list[0])[parent];
    expect(w.stateForReference(parentNode), rootNode);
  });

  test('round-trip', () {
    runRoundTripTest(nodeSerializerReflective);
  });

  test('round-trip ClosureRule', () {
    runRoundTripTest(nodeSerializerNonReflective);
  });

  test('round-trip with essential parent', () {
    runRoundTripTest(nodeSerializerWithEssentialParent);
  });

  test('round-trip, flat format', () {
    runRoundTripTestFlat(nodeSerializerReflective);
  });

  test('round-trip using Maps', () {
    runRoundTripTest(nodeSerializerUsingMaps);
  });

  test('round-trip, flat format, using maps', () {
    runRoundTripTestFlat(nodeSerializerUsingMaps);
  });

  test('round-trip with Node CustomRule', () {
    runRoundTripTestFlat(nodeSerializerCustom);
  });

  test('round-trip with Node CustomRule, to maps', () {
    runRoundTripTest(nodeSerializerCustom);
  });

  test('eating your own tail', () {
    // Create a meta-serializer, that serializes serializations, then
    // use it to serialize a basic serialization, then run a test on the
    // the result.
    var s = new Serialization()
      ..addRuleFor(new Node(''), constructorFields: ['name'])
      ..selfDescribing = false;
    var meta = metaSerialization();
    var serialized = meta.write(s);
    var s2 = new Reader(meta)
        .read(serialized, {"Node" : reflect(new Node('')).type});
    runRoundTripTest((x) => s2);
  });

  test("Verify we're not serializing lists twice if they're essential", () {
    Node n1 = new Node("1"), n2 = new Node("2"), n3 = new Node("3");
    n1.children = [n2, n3];
    n2.parent = n1;
    n3.parent = n1;
    var s = new Serialization()
      ..addRuleFor(n1, constructorFields: ["name"]).
          setFieldWith("children", (parent, child) =>
              parent.reflectee.children = child);
    var w = new Writer(s);
    w.write(n1);
    expect(w.rules[2] is ListRuleEssential, isTrue);
    expect(w.rules[1] is ListRule, isTrue);
    expect(w.states[1].length, 0);
    expect(w.states[2].length, 1);
    s = new Serialization()
      ..addRuleFor(n1, constructorFields: ["name"]);
    w = new Writer(s);
    w.write(n1);
    expect(w.states[1].length, 1);
    expect(w.states[2].length, 0);
  });

  test('Identity of equal objects preserved', () {
    Node n1 = new NodeEqualByName("foo"),
         n2 = new NodeEqualByName("foo"),
         n3 = new NodeEqualByName("3");
    n1.children = [n2, n3];
    n2.parent = n1;
    n3.parent = n1;
    var s = new Serialization()
      ..selfDescribing = false
      ..addRuleFor(n1, constructorFields: ["name"]);
    var w = new Writer(s);
    var r = new Reader(s);
    var m1 = r.read(w.write(n1));
    var m2 = m1.children.first;
    var m3 = m1.children.last;
    expect(m1, m2);
    expect(identical(m1, m2), isFalse);
    expect(m1 == m3, isFalse);
    expect(identical(m2.parent, m3.parent), isTrue);
  });

  test("Constant values as fields", () {
    var s = new Serialization()
      ..selfDescribing = false
      ..addRuleFor(a1,
          constructor: 'withData',
          constructorFields: ["street", "Kirkland", "WA", "98103"],
          fields: []);
    String out = s.write(a1);
    var newAddress = s.read(out);
    expect(newAddress.street, a1.street);
    expect(newAddress.city, "Kirkland");
    expect(newAddress.state, "WA");
    expect(newAddress.zip, "98103");
  });

  test("Straight JSON format", () {
    var s = new Serialization();
    var writer = s.newWriter(new SimpleJsonFormat());
    var out = writer.write(a1);
    var reconstituted = json.parse(out);
    expect(reconstituted.length, 4);
    expect(reconstituted[0], "Seattle");
  });

  test("Straight JSON format, nested objects", () {
    var p1 = new Person()..name = 'Alice'..address = a1;
    var s = new Serialization();
    var addressRule = s.addRuleFor(a1)..configureForMaps();
    var personRule = s.addRuleFor(p1)..configureForMaps();
    var writer = s.newWriter(new SimpleJsonFormat(storeRoundTripInfo: true));
    var out = writer.write(p1);
    var reconstituted = json.parse(out);
    var expected = {
      "name" : "Alice",
      "rank" : null,
      "serialNumber" : null,
      "__rule" : personRule.number,
      "address" : {
        "street" : "N 34th",
        "city" : "Seattle",
        "state" : null,
        "zip" : null,
        "__rule" : addressRule.number
      }
    };
    expect(expected, reconstituted);
  });

  test("Straight JSON format, round-trip", () {
    // Note that we can't use the usual round-trip test because it has cycles.
    var p1 = new Person()..name = 'Alice'..address = a1;
    // Use maps for one rule, lists for the other.
    var s = new Serialization()
      ..addRuleFor(a1)
      ..addRuleFor(p1).configureForMaps();
    var writer = s.newWriter(new SimpleJsonFormat(storeRoundTripInfo: true));
    var out = writer.write(p1);
    var reader = s.newReader(new SimpleJsonFormat(storeRoundTripInfo: true));
    var p2 = reader.read(out);
    expect(p2.name, "Alice");
    var a2 = p2.address;
    expect(a2.street, "N 34th");
    expect(a2.city, "Seattle");
  });

  test("Straight JSON format, root is a Map", () {
    // Note that we can't use the usual round-trip test because it has cycles.
    var p1 = new Person()..name = 'Alice'..address = a1;
    // Use maps for one rule, lists for the other.
    var s = new Serialization()
      ..addRuleFor(a1)
      ..addRuleFor(p1).configureForMaps();
    var format = new SimpleJsonFormat(storeRoundTripInfo: true);
    var writer = s.newWriter(format);
    var out = writer.write({"stuff" : p1});
    var reader = s.newReader(format);
    var p2 = reader.read(out)["stuff"];
    expect(p2.name, "Alice");
    var a2 = p2.address;
    expect(a2.street, "N 34th");
    expect(a2.city, "Seattle");
  });


  test("Straight JSON format, round-trip with named objects", () {
    // Note that we can't use the usual round-trip test because it has cycles.
    var p1 = new Person()..name = 'Alice'..address = a1;
    // Use maps for one rule, lists for the other.
    var s = new Serialization()
      ..addRule(new NamedObjectRule())
      ..addRuleFor(a1)
      ..addRuleFor(p1).configureForMaps()
      ..namedObjects["foo"] = a1;
    var writer = s.newWriter(new SimpleJsonFormat(storeRoundTripInfo: true));
    var out = writer.write(p1);
    var reader = s.newReader(new SimpleJsonFormat(storeRoundTripInfo: true));
    var p2 = reader.read(out, {"foo" : 12});
    expect(p2.name, "Alice");
    var a2 = p2.address;
    expect(a2, 12);
  });

  test("Maps", () {
    var s = new Serialization()..selfDescribing = false;
    var p1 = new Person()..name = 'Alice'..address = a1;
    var data = new Map();
    data["simple data"] = 1;
    data[p1] = a1;
    data[a1] = p1;
    var formats = [new SimpleFlatFormat(), new SimpleMapFormat(),
        new SimpleJsonFormat(storeRoundTripInfo: true)];
    for (var eachFormat in formats) {
      var output = s.write(data, eachFormat);
      var reader = s.newReader(eachFormat);
      var input = reader.read(output);
      expect(input["simple data"], data["simple data"]);
      var p2 = input.keys.firstMatching((x) => x is Person);
      var a2 = input.keys.firstMatching((x) => x is Address);
      if (eachFormat is SimpleJsonFormat) {
        // JSON doesn't handle cycles, so these won't be identical.
        expect(input[p2] is Address, isTrue);
        expect(input[a2] is Person, isTrue);
        var a3 = input[p2];
        expect(a3.city, a2.city);
        expect(a3.state, a2.state);
        expect(a3.state, a2.state);
        var p3 = input[a2];
        expect(p3.name, p2.name);
        expect(p3.rank, p2.rank);
        expect(p3.address.city, a2.city);
      } else {
        expect(input[p2], same(a2));
        expect(input[a2], same(p2));
      }
    }
  });

  test("Map with string keys stays that way", () {
    var s = new Serialization()..addRuleFor(new Person());
    var data = {"abc" : 1, "def" : "ghi"};
    data["person"] = new Person()..name = "Foo";
    var output = s.write(data, new SimpleMapFormat());
    var mapRule = s.rules.firstMatching((x) => x is MapRule);
    var map = json.parse(output)["data"][mapRule.number][0];
    expect(map is Map, isTrue);
    expect(map["abc"], 1);
    expect(map["def"], "ghi");
    expect(new Reader(s).asReference(map["person"]) is Reference, isTrue);
  });
}

/******************************************************************************
 * The end of the tests and the beginning of various helper functions to make
 * it easier to write the repetitive sections.
 ******************************************************************************/

/** Create a Serialization for serializing Serializations. */
Serialization metaSerialization() {
  // Make some bogus rule instances so we have something to feed rule creation
  // and get their types. If only we had class literals implemented...
  var basicRule = new BasicRule(reflect(null).type, '', [], [], []);

  var meta = new Serialization()
    ..selfDescribing = false
    ..addRuleFor(new ListRule())
    ..addRuleFor(new PrimitiveRule())
    // TODO(alanknight): Handle CustomRule as well.
    // Note that we're passing in a constant for one of the fields.
    ..addRuleFor(basicRule,
        constructorFields: ['type',
          'constructorName',
          'constructorFields', 'regularFields', []],
        fields: [])
     ..addRuleFor(new Serialization(), constructor: "blank")
         .setFieldWith('rules',
           (InstanceMirror s, List rules) {
             rules.forEach((x) => s.reflectee.addRule(x));
           })
    ..addRule(new NamedObjectRule())
    ..addRule(new MirrorRule());
  return meta;
}

/**
 * Read back a simple object, assumed to be the only one of its class in the
 * reader.
 */
readBackSimple(Serialization s, object, Reader reader) {
  var rule = s.rulesFor(object, null).first;
  reader.inflateForRule(rule);
  var list2 = reader.allObjectsForRule(rule).first;
  return list2;
}

/**
 * Set up a basic reader with some fake data. Hard-codes the assumption
 * of how many rules there are.
 */
Reader setUpReader(aSerialization, sampleData) {
  var reader = new Reader(aSerialization);
  // We're not sure which rule needs the sample data, so put it everywhere
  // and trust that the extra will just be ignored.
  reader.data = new List.filled(10, [sampleData]);
  return reader;
}

/** Return a serialization for Node objects, using a reflective rule. */
Serialization nodeSerializerReflective(Node n) {
  return new Serialization()
    ..addRuleFor(n, constructorFields: ["name"])
    ..namedObjects['Node'] = reflect(new Node('')).type;
}

/**
 * Return a serialization for Node objects but using Maps for the internal
 * representation rather than lists.
 */
Serialization nodeSerializerUsingMaps(Node n) {
  return new Serialization()
    ..addRuleFor(n, constructorFields: ["name"]).configureForMaps()
    ..namedObjects['Node'] = reflect(new Node('')).type;
}

/**
 * Return a serialization for Node objects but using Maps for the internal
 * representation rather than lists.
 */
Serialization nodeSerializerCustom(Node n) {
  return new Serialization()
    ..addRule(new NodeRule());
}

/**
 * Return a serialization for Node objects where the "parent" instance
 * variable is considered essential state.
 */
Serialization nodeSerializerWithEssentialParent(Node n) {
  // Force the node rule to be first, in order to make a cycle which would
  // not cause a problem if we handled the list first, because the list
  // considers all of its state non-essential, thus breaking the cycle.
  var s = new Serialization.blank()
    ..addRuleFor(
        n,
        constructor: "parentEssential",
        constructorFields: ["parent"])
    ..addDefaultRules()
    ..namedObjects['Node'] = reflect(new Node('')).type
    ..selfDescribing = false;
  return s;
}

/** Return a serialization for Node objects using a ClosureToMapRule. */
Serialization nodeSerializerNonReflective(Node n) {
  var rule = new ClosureRule(
      n.runtimeType,
      (o) => {"name" : o.name, "children" : o.children, "parent" : o.parent},
      (map) => new Node(map["name"]),
      (object, map) {
        object
          ..children = map["children"]
          ..parent = map["parent"];
      });
  return new Serialization()
    ..selfDescribing = false
    ..addRule(rule);
}

/**
 * Run a round-trip test on a simple tree of nodes, using a serialization
 * that's returned by the [serializerSetup] function.
 */
runRoundTripTest(Function serializerSetUp) {
  Node n1 = new Node("1"), n2 = new Node("2"), n3 = new Node("3");
  n1.children = [n2, n3];
  n2.parent = n1;
  n3.parent = n1;
  var s = serializerSetUp(n1);
  var output = s.write(n2);
  var s2 = serializerSetUp(n1);
  var reader = new Reader(s2);
  var m2 = reader.read(output);
  var m1 = m2.parent;
  expect(m1 is Node, isTrue);
  var children = m1.children;
  expect(m1.name,"1");
  var m3 = m1.children.last;
  expect(m2.name, "2");
  expect(m3.name, "3");
  expect(m2.parent, m1);
  expect(m3.parent, m1);
  expect(m1.parent, isNull);
}

/**
 * Run a round-trip test on a simple of nodes, but using the flat format
 * rather than the maps.
 */
runRoundTripTestFlat(serializerSetUp) {
  Node n1 = new Node("1"), n2 = new Node("2"), n3 = new Node("3");
  n1.children = [n2, n3];
  n2.parent = n1;
  n3.parent = n1;
  var s = serializerSetUp(n1);
  var output = s.write(n2, new SimpleFlatFormat());
  expect(output is List, isTrue);
  var s2 = serializerSetUp(n1);
  var reader = new Reader(s2, new SimpleFlatFormat());
  var m2 = reader.read(output);
  var m1 = m2.parent;
  expect(m1 is Node, isTrue);
  var children = m1.children;
  expect(m1.name,"1");
  var m3 = m1.children.last;
  expect(m2.name, "2");
  expect(m3.name, "3");
  expect(m2.parent, m1);
  expect(m3.parent, m1);
  expect(m1.parent, isNull);
}

/** Extract the state from [object] using the rules in [s] and return it. */
states(object, Serialization s) {
  var rules = s.rulesFor(object, null);
  return rules.mappedBy((x) => x.extractState(object, doNothing)).toList();
}

/** A hard-coded rule for serializing Node instances. */
class NodeRule extends CustomRule {
  bool appliesTo(instance, _) => instance.runtimeType == Node;
  getState(instance) => [instance.parent, instance.name, instance.children];
  create(state) => new Node(state[1]);
  setState(Node node, state) {
    node.parent = state[0];
    node.children = state[2];
  }
}