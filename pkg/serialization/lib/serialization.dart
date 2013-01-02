// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This provides a general-purpose serialization facility for Dart objects. A
 * [Serialization] is defined in terms of [SerializationRule]s and supports
 * reading and writing to different formats.
 *
 * Setup
 * =====
 * A simple example of usage is
 *
 *      var address = new Address();
 *      address.street = 'N 34th';
 *      address.city = 'Seattle';
 *      var serialization = new Serialization()
 *          ..addRuleFor(address);
 *      String output = serialization.write(address);
 *
 * This creates a new serialization and adds a rule for address objects. Right
 * now it has to be passed an address instance because we can't write Address
 * as a literal. Then we ask the Serialization to write the address and we get
 * back a String which is a [JSON] representation of the state of it and related
 * objects.
 *
 * The version above used reflection to automatically identify the public
 * fields of the address object. We can also specify those fields explicitly.
 *
 *      var serialization = new Serialization()
 *        ..addRuleFor(address,
 *            constructor: "create",
 *            constructorFields: ["number", "street"],
 *            fields: ["city"]);
 *
 * This rule still uses reflection to access the fields, but does not try to
 * identify which fields to use, but instead uses only the "number" and "street"
 * fields that we specified. We may also want to tell it to identify the
 * fields, but to specifically omit certain fields that we don't want
 * serialized.
 *
 *      var serialization = new Serialization()
 *        ..addRuleFor(address,
 *            constructor: "",
 *            excludeFields: ["other", "stuff"]);
 *
 * We can also use a completely non-reflective rule to serialize and
 * de-serialize objects. This can be more cumbersome, but it does work in
 * dart2js, where mirrors are not yet implemented.
 *
 *      addressToMap(a) => {"number" : a.number, "street" : a.street,
 *          "city" : a.city};
 *      createAddress(Map m) => new Address.create(m["number"], m["street"]);
 *      fillInAddress(Map m, Address a) => a.city = m["city"];
 *      var serialization = new Serialization()
 *        ..addRule(
 *            new ClosureToMapRule(anAddress.runtimeType,
 *                addressToMap, createAddress, fillInAddress);
 *
 * Note that there are three different functions provided. The addressToMap
 * function takes the fields we want serialized from the Address and puts them
 * into a map. The createAddress function creates a new address using a map like
 * the one returned by the first function. And the fillInAddress function fills
 * in any  remaining state in the created object.
 *
 * At the moment, however, using this rule increases the probability of problems
 * with cycles. The problem is that before passing values to the user-supplied
 * functions it has to inflate any references to be the real objects. Since it
 * doesn't know which ones the creation function uses it has to inflate all of
 * them. For example, consider a Node class with parent, leftChild, and
 * rightChild, and the parent field was final and set in the constructor. When
 * we inflate all of the values we will end up with a cycle and can't
 * de-serialize. If we know which fields are used by the constructor we can
 * inflate only those, which is what BasicRule does. We expect to make a richer
 * API for rules not using reflection, but there's a tension between providing
 * the serialization process with enough information and making it more work
 * to specify.
 *
 * There are cases where the constructor needs values that we can't easily get
 * the serialized object. For example, we may just want to pass null, or a
 * constant value. To support this, we can specify as constructor fields
 * values that aren't field names. If any value isn't a String, it will be
 * treated as a constant and passed unaltered to the constructor.
 *
 * In some cases a non-constructor field should not be set using field
 * access or a setter, but should be done by calling a method. For example, it
 * may not be possible to set a List field "foo", and you need to call an
 * addFoo() method for each entry in the list. In these cases, if you are using
 * a BasicRule for the object you can call the setFieldWith() method.
 *
 *       s..addRuleFor(fooHolderInstance).setFieldWith("foo",
 *           (parent, value) => for (var each in value) parent.addFoo(value));
 *
 * Writing
 * =======
 * To write objects, we use the write() methods. There are two variations.
 *
 *       String output = serialization.write(someObject);
 *       List output = serialization.writeFlat(someObject);
 *
 * The first uses a representation in which objects are represented as maps
 * keyed by field name, but in which references between objects have been
 * converted into Reference objects. This is then encoded as a [JSON] string.
 *
 * The second representation holds all the objects as a List of simple types.
 * For practical use you may want to convert that to a [JSON] or other encoded
 * representation as well.
 *
 * Both representations are primarily intended as proofs of concept for
 * different types of representation, and we expect to generalize that to a
 * pluggable mechanism for different representations.
 *
 * Reading
 * =======
 * To read objects, the corresponding methods are [read] and [readFlat].
 *
 *       List input = serialization.read(aString);
 *       List input = serialization.readFlat(aList);
 *
 * There is also a convenience method for the case of reading a single object.
 *
 *       Object result = serialization.readOne(aString);
 *       Object result = serialization.readOneFlat(aString);
 *
 * When reading, the serialization instance doing the reading must be configured
 * with compatible rules to the one doing the writing. It's possible for the
 * rules to be different, but they need to be able to read the same
 * representation. For most practical purposes right now they should be the
 * same. The simplest way to achieve this is by having the serialization
 * variable [selfDescribing] be true. In that case the rules themselves are also
 * stored along with the serialized data, and can be read back on the receiving
 * end. Note that this does not yet work for [ClosureToMapRule]. The
 * [selfDescribing] variable is true by default.
 *
 * When reading, some object references should not be serialized, but should be
 * connected up to other instances on the receiving side. A notable example of
 * this is when serialization rules have been stored. Instances of BasicRule
 * take a [ClassMirror] in their constructor, and we cannot serialize those. So
 * when we read the rules, we must provide a Map<String, Object> which maps from
 * the simple name of classes we are interested in to a [ClassMirror]. This can
 * be provided either in the [externalObjects] variable of the Serialization,
 * or as an additional parameter to the reading methods.
 *
 *     new Serialization()
 *       ..addRuleFor(new Person(), constructorFields: ["name"])
 *       ..externalObjects['Person'] = reflect(new Person()).type;
 */
library serialization;

import 'src/mirrors_helpers.dart';
import 'src/serialization_helpers.dart';
import 'dart:json' show JSON;

part 'src/reader_writer.dart';
part 'src/serialization_rule.dart';
part 'src/basic_rule.dart';

/**
 * This class defines a particular serialization scheme, in terms of
 * [SerializationRule] instances, and supports reading and writing them.
 * See library comment for examples of usage.
 */
class Serialization {

  /**
   * The serialization is controlled by the list of Serialization rules. These
   * are most commonly added via [addRuleFor].
   */
  List _rules = [];

  /**
   * The serialization is controlled by the list of Serialization rules. These
   * are most commonly added via [addRuleFor].
   */
  List get rules => _rules;

  /**
   * When reading, we may need to resolve references to existing objects in
   * the system. The right action may not be to create a new instance of
   * something, but rather to find an existing instance and connect to it.
   * For example, if we have are serializing an Email message and it has a
   * link to the owning account, it may not be appropriate to try and serialize
   * the account. Instead we should just connect the de-serialized message
   * object to the account object that already exists there.
   */
  Map<String, dynamic> namedObjects = {};

  /**
   * When we write out data using this serialization, should we also write
   * out a description of the rules. This is on by default unless using
   * CustomRule subclasses, in which case it requires additional setup and
   * is off by default.
   */
  bool _selfDescribing;

  /**
   * When we write out data using this serialization, should we also write
   * out a description of the rules. This is on by default unless using
   * CustomRule subclasses, in which case it requires additional setup and
   * is off by default.
   */
  bool get selfDescribing {
    if (_selfDescribing != null) return _selfDescribing;
    return !_rules.some((x) => x is CustomRule);
  }

  /**
   * When we write out data using this serialization, should we also write
   * out a description of the rules. This is on by default unless using
   * CustomRule subclasses, in which case it requires additional setup and
   * is off by default.
   */
  set selfDescribing(x) => _selfDescribing = x;

  /**
   * Creates a new serialization with a default set of rules for primitives
   * and lists.
   */
  Serialization() {
    addDefaultRules();
  }

  /**
   * Creates a new serialization with no default rules at all. The most common
   * use for this is if we are reading self-describing serialized data and
   * will populate the rules from that data.
   */
  Serialization.blank() { }

  /**
   * Create a [BasicRule] rule for the type of
   * [instanceOfType]. Optionally
   * allows specifying a [constructor] name, the list of [constructorFields],
   * and the list of [fields] not used in the constructor. Returns the new
   * rule. Note that [BasicRule] uses reflection, and so will not work with the
   * current state of dartj2s. If you need to run there, consider using
   * [CustomRule] instead.
   *
   * If the optional parameters aren't specified, the default constructor will
   * be used, and the list of fields will be computed. Alternatively, you can
   * omit [fields] and provide [excludeFields], which will then compute the
   * list of fields specifically excluding those listed.
   *
   * The fields can be actual public fields, but can also be getter/setter
   * pairs or getters whose value is provided in the constructor. For the
   * [constructorFields] they can also be arbitrary objects. Anything that is
   * not a String will be treated as a constant value to be used in any
   * construction of these objects.
   *
   * If the list of fields is computed, fields from the superclass will be
   * included. However, each subclass needs its own rule, since the constructors
   * are not inherited, and so may need to be specified separately for each
   * subclass.
   */
  // TODO(alanknight): Take a type rather than an instance. Issue 6282 and 6433.
  BasicRule addRuleFor(
      instanceOfType,
      {String constructor,
        List constructorFields,
        List<String> fields,
        List<String> excludeFields}) {

    var rule;
    rule = new BasicRule(
        turnInstanceIntoSomethingWeCanUse(
            instanceOfType),
        constructor, constructorFields, fields, excludeFields);
    addRule(rule);
    return rule;
  }

  /** Set up the default rules, for lists and primitives. */
  void addDefaultRules() {
    addRule(new PrimitiveRule());
    addRule(new ListRule());
    // Both these rules apply to lists, so unless otherwise indicated,
    // it will always find the first one.
    addRule(new ListRuleEssential());
  }

  /**
   * Add a new SerializationRule [rule]. The addRuleFor method will probably
   * handle most simple cases, but for adding an arbitrary rule, including
   * a SerializationRule subclass which you have created, you can use this
   * method.
   */
  void addRule(SerializationRule rule) {
    rule.number = _rules.length;
    _rules.add(rule);
  }

  /**
   * This is the basic method to write out an object graph rooted at
   * [object] and return the result. Right now this is hard-coded to return
   * a String from a custom [JSON] format, but that is likely to change to be
   * more pluggable in the near future.
   */
  String write(Object object) {
    return newWriter().write(object);
  }

  /**
   * Return a new [Writer] object for this serialization. This is useful if you
   * want to do something more complex with the writer than just returning
   * the final result.
   */
  Writer newWriter() => new Writer(this);

  /**
   * Write out the tree in a custom flat format, returning a list containing
   * only "simple" types: num, String, and bool.
   */
  List writeFlat(Object object) {
    return newWriter().writeFlat(object);
  }

  /**
   * Read the serialized data from [input] and return the root object
   * from the result. If there are objects that need to be resolved
   * in the current context, they should be provided in [externals] as a
   * Map from names to values. In particular, in the current implementation
   * any class mirrors needed should be provided in [externals] using the
   * class name as a key. In addition to the [externals] map provided here,
   * values will be looked up in the [externalObjects] map.
   */
  read(String input, [Map externals = const {}]) {
    return newReader().read(input, externals);
  }

  /**
   * Return a new [Reader] object for this serialization. This is useful if
   * you want to do something more complex with the reader than just returning
   * the final result.
   */
  Reader newReader() => new Reader(this);

  /**
   * Return the list of SerializationRule that apply to [object]. For
   * internal use, but public because it's used in testing.
   */
  List<SerializationRule> rulesFor(object, Writer w) {
    // This has a couple of edge cases.
    // 1) The owning object may have indicated we should use a different
    // rule than the default.
    // 2) We may not have a rule, in which case we lazily create a BasicRule.
    // 3) Rules are allowed to say mustBePrimary, meaning that they can be used
    // iff no other rule was chosen first.
    // TODO(alanknight): Can the mustBePrimary mechanism be removed or changed.
    // It adds an order dependency to the rules, and is messy. Reconsider in the
    // light of a more general mechanism for multiple rules per object.
    // TODO(alanknight): Finding which rules apply seems likely to be a
    // bottleneck, particularly with the current reflective implementation.
    // Consider how to improve it. e.g. cache the list of rules by class. But
    // be careful of issues like rules which have arbitrary predicates. Or
    // consider having the arbitrary predicates be secondary to an initial
    // class-based lookup mechanism.
    var target, candidateRules;
    if (object is DesignatedRuleForObject) {
      target = object.target;
      candidateRules = object.possibleRules(_rules);
    } else {
      target = object;
      candidateRules = _rules;
    }
    List applicable = candidateRules.filter(
        (each) => each.appliesTo(target, w));

    if (applicable.isEmpty) {
      return [addRuleFor(target)];
    }

    if (applicable.length == 1) return applicable;
    var first = applicable[0];
    var finalRules = applicable.filter(
        (x) => !x.mustBePrimary || (x == first));

    if (finalRules.isEmpty) throw new SerializationException(
        'No valid rule found for object $object');
    return finalRules;
  }

  /**
   * Create a Serialization for serializing SerializationRules. This is used
   * to save the rules in a self-describing format along with the data.
   * If there are new rule classes created, they will need to be described
   * here.
   */
  Serialization _ruleSerialization() {
    // TODO(alanknight): There's an extensibility issue here with new rules.
    // TODO(alanknight): How to handle rules with closures? They have to
    // exist on the other side, but we might be able to hook them up by name,
    // or we might just be able to validate that they're correctly set up
    // on the other side.

    // Make some bogus rule instances so we have something to feed rule creation
    // and get their types. If only we had class literals implemented...
   var basicRule = new BasicRule(reflect(null).type, '', [], [], []);

    var meta = new Serialization()
      ..selfDescribing = false
      ..addRuleFor(new ListRule())
      ..addRuleFor(new PrimitiveRule())
      ..addRuleFor(new ListRuleEssential())
      ..addRuleFor(basicRule,
          constructorFields: ['type',
            'constructorName',
            'constructorFields', 'regularFields', []],
          fields: [])
      ..addRule(new NamedObjectRule())
      ..addRule(new MirrorRule());
    meta.namedObjects = namedObjects;
    return meta;
  }

  /** Return true if our [namedObjects] collection has an entry for [object].*/
  bool _hasNameFor(object) {
    var sentinel = const _Sentinel();
    return _nameFor(object, () => sentinel) != sentinel;
  }

  /**
   * Return the name we have for [object] in our [namedObjects] collection or
   * the result of evaluating [ifAbsent] if there is no entry.
   */
  _nameFor(object, [ifAbsent]) {
    for (var key in namedObjects.keys) {
      if (identical(namedObjects[key], object)) return key;
    }
    return ifAbsent == null ? null : ifAbsent();
  }
}

/**
 * An exception class for errors during serialization.
 */
class SerializationException implements Exception {
  final String message;
  const SerializationException([this.message]);
}