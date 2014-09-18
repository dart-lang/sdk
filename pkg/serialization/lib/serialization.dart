// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * A general-purpose serialization facility for Dart objects.
 *
 * A [Serialization] is defined in terms of [SerializationRule]s and supports
 * reading and writing to different formats.
 *
 * For information on installing and importing this library, see the
 * [serialization package on pub.dartlang.org]
 * (http://pub.dartlang.org/packages/serialization).
 *
 * ## Setup
 *
 * A simple example of usage is
 *
 *      var address = new Address();
 *      address.street = 'N 34th';
 *      address.city = 'Seattle';
 *      var serialization = new Serialization()
 *          ..addRuleFor(Address);
 *      Map output = serialization.write(address);
 *
 * This creates a new serialization and adds a rule for address objects.
 * Then we ask the [Serialization] to write the address
 * and we get back a Map which is a [json]able representation of the state of
 * the address and related objects. Note that while the output in this case
 * is a [Map], the type will vary depending on which output format we've told
 * the [Serialization] to use.
 *
 * The version above used reflection to automatically identify the public
 * fields of the address object. We can also specify those fields explicitly.
 *
 *      var serialization = new Serialization()
 *        ..addRuleFor(Address,
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
 *        ..addRuleFor(Address,
 *            constructor: "",
 *            excludeFields: ["other", "stuff"]);
 *
 * ## Writing rules
 *
 * We can also use a completely non-reflective rule to serialize and
 * de-serialize objects. This can be more work, but it does work in
 * dart2js, where mirrors are not yet implemented. We can specify this in two
 * ways. First, we can write our own SerializationRule class that has methods
 * for our Address class.
 *
 *      class AddressRule extends CustomRule {
 *        bool appliesTo(instance, Writer w) => instance.runtimeType == Address;
 *        getState(instance) => [instance.street, instance.city];
 *        create(state) => new Address();
 *        setState(Address a, List state) {
 *          a.street = state[0];
 *          a.city = state[1];
 *        }
 *      }
 *
 * The class needs four different methods. The [CustomRule.appliesTo]
 * method tells us if
 * the rule should be used to write an object. In this example we use a test
 * based on runtimeType. We could also use an "is Address" test, but if Address
 * has subclasses that would find those as well, and we want a separate rule
 * for each. The [CustomRule.getState] method should
 * return all the state of the object that we want to recreate,
 * and should be either a Map or a List. If you want to write to human-readable
 * formats where it's useful to be able to look at the data as a map from
 * field names to values, then it's better to return it as a map. Otherwise it's
 * more efficient to return it as a list. You just need to be sure that the
 * [CustomRule.create] and [CustomRule.setState] methods interpret the data the
 * same way as [CustomRule.getState] does.
 *
 * The [CustomRule.create] method will create the new object and return it. While it's
 * possible to create the object and set all its state in this one method, that
 * increases the likelihood of problems with cycles. So it's better to use the
 * minimum necessary information in [CustomRule.create] and do more of the work
 * in [CustomRule.setState].
 *
 * The other way to do this is not creating a subclass, but by using a
 * [ClosureRule] and giving it functions for how to create
 * the address.
 *
 *      addressToMap(a) => {"number" : a.number, "street" : a.street,
 *          "city" : a.city};
 *      createAddress(Map m) => new Address.create(m["number"], m["street"]);
 *      fillInAddress(Address a, Map m) => a.city = m["city"];
 *      var serialization = new Serialization()
 *        ..addRule(
 *            new ClosureRule(anAddress.runtimeType,
 *                addressToMap, createAddress, fillInAddress);
 *
 * In this case we have created standalone functions rather than
 * methods in a subclass and we pass them to the constructor of
 * [ClosureRule]. In this case we've also had them use maps rather than
 * lists for the state, but either would work as long as the rule is
 * consistent with the representation it uses. We pass it the runtimeType
 * of the object, and functions equivalent to the methods on [CustomRule]
 *
 * ## Constant values
 *
 * There are cases where the constructor needs values that we can't easily get
 * from the serialized object. For example, we may just want to pass null, or a
 * constant value. To support this, we can specify as constructor fields
 * values that aren't field names. If any value isn't a String, or is a string
 * that doesn't correspond to a field name, it will be
 * treated as a constant and passed unaltered to the constructor.
 *
 * In some cases a non-constructor field should not be set using field
 * access or a setter, but should be done by calling a method. For example, it
 * may not be possible to set a List field "foo", and you need to call an
 * addFoo() method for each entry in the list. In these cases, if you are using
 * a BasicRule for the object you can call the setFieldWith() method.
 *
 *       s..addRuleFor(FooHolder).setFieldWith("foo",
 *           (parent, value) => for (var each in value) parent.addFoo(value));
 *
 * ## Writing
 *
 * To write objects, we use the write() method.
 *
 *       var output = serialization.write(someObject);
 *
 * By default this uses a representation in which objects are represented as
 * maps keyed by field name, but in which references between objects have been
 * converted into Reference objects. This is then typically encoded as
 * a [json] string, but can also be used in other ways, e.g. sent to another
 * isolate.
 *
 * We can write objects in different formats by passing a [Format] object to
 * the [Serialization.write] method or by getting a [Writer] object.
 * The available formats
 * include the default, a simple "flat" format that doesn't include field names,
 * and a simple JSON format that produces output more suitable for talking to
 * services that expect JSON in a predefined format. Examples of these are
 *
 *      Map output = serialization.write(address, new SimpleMapFormat());
 *      List output = serialization.write(address, new SimpleFlatFormat());
 *      var output = serialization.write(address, new SimpleJsonFormat());
 * Or, using a [Writer] explicitly
 *      var writer = serialization.newWriter(new SimpleFlatFormat());
 *      List output = writer.write(address);
 *
 * These representations are not yet considered stable.
 *
 * ## Reading
 *
 * To read objects, the corresponding [Serialization.read] method can be used.
 *
 *       Address input = serialization.read(input);
 *
 * When reading, the serialization instance doing the reading must be configured
 * with compatible rules to the one doing the writing. It's possible for the
 * rules to be different, but they need to be able to read the same
 * representation. For most practical purposes right now they should be the
 * same. The simplest way to achieve this is by having the serialization
 * variable [Serialization.selfDescribing] be true. In that case the rules
 * themselves are also
 * stored along with the serialized data, and can be read back on the receiving
 * end. Note that this may not work for all rules or all formats. The
 * [Serialization.selfDescribing] variable is true by default, but the
 * [SimpleJsonFormat] does not support it, since the point is to provide a
 * representation in a form
 * other services might expect. Using CustomRule or ClosureRule also does not
 * yet work with the [Serialization.selfDescribing] variable.
 *
 * ## Named objects
 *
 * When reading, some object references should not be serialized, but should be
 * connected up to other instances on the receiving side. A notable example of
 * this is when serialization rules have been stored. Instances of BasicRule
 * take a [ClassMirror] in their constructor, and we cannot serialize those. So
 * when we read the rules, we must provide a Map<String, Object> which maps from
 * the simple name of classes we are interested in to a [ClassMirror]. This can
 * be provided either in the [Serialization.namedObjects],
 * or as an additional parameter to the reading and writing methods on the
 * [Reader] or [Writer] respectively.
 *
 *     new Serialization()
 *       ..addRuleFor(Person, constructorFields: ["name"])
 *       ..namedObjects['Person'] = reflect(new Person()).type;
 */
library serialization;

import 'src/mirrors_helpers.dart';
import 'src/serialization_helpers.dart';
import 'dart:collection';

part 'src/reader_writer.dart';
part 'src/serialization_rule.dart';
part 'src/basic_rule.dart';
part 'src/format.dart';

/**
 * This class defines a particular serialization scheme, in terms of
 * [SerializationRule] instances, and supports reading and writing them.
 * See library comment for examples of usage.
 */
class Serialization {
  final List<SerializationRule> _rules;

  /**
   * The serialization is controlled by the list of Serialization rules. These
   * are most commonly added via [addRuleFor].
   */
  final UnmodifiableListView<SerializationRule> rules;

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
    // TODO(alanknight): Should this be moved to the format?
    // TODO(alanknight): Allow self-describing in the presence of CustomRule.
    // TODO(alanknight): Don't do duplicate work creating a writer and
    // serialization here and then re-creating when we actually serialize.
    if (_selfDescribing != null) return _selfDescribing;
    var meta = ruleSerialization();
    var w = meta.newWriter();
    _selfDescribing = !rules.any((rule) =>
        meta.rulesFor(rule, w, create: false).isEmpty);
    return _selfDescribing;
  }

  /**
   * When we write out data using this serialization, should we also write
   * out a description of the rules. This is on by default unless using
   * CustomRule subclasses, in which case it requires additional setup and
   * is off by default.
   */
  void set selfDescribing(bool value) {
    _selfDescribing = value;
  }

  /**
   * Creates a new serialization with a default set of rules for primitives
   * and lists.
   */
  factory Serialization() =>
    new Serialization.blank()
      ..addDefaultRules();

  /**
   * Creates a new serialization with no default rules at all. The most common
   * use for this is if we are reading self-describing serialized data and
   * will populate the rules from that data.
   */
  factory Serialization.blank()
    => new Serialization._(new List<SerializationRule>());

  Serialization._(List<SerializationRule> rules) :
    this._rules = rules,
    this.rules = new UnmodifiableListView(rules);

  /**
   * Create a [BasicRule] rule for [instanceOrType]. Normally this will be
   * a type, but for backward compatibilty we also allow you to pass an
   * instance (except an instance of Type), and the rule will be created
   * for its runtimeType. Optionally
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
  BasicRule addRuleFor(
      instanceOrType,
      {String constructor,
        List constructorFields,
        List<String> fields,
        List<String> excludeFields}) {

    var rule = new BasicRule(
        turnInstanceIntoSomethingWeCanUse(
            instanceOrType),
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
    addRule(new MapRule());
    addRule(new SymbolRule());
    addRule(new DateTimeRule());
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
   * This writes out an object graph rooted at [object] and returns the result.
   * The [format] parameter determines the form of the result. The default
   * format is [SimpleMapFormat] and returns a Map.
   */
  write(Object object, {Format format}) {
    return newWriter(format).write(object);
  }

  /**
   * Return a new [Writer] object for this serialization. This is useful if you
   * want to do something more complex with the writer than just returning
   * the final result.
   */
  Writer newWriter([Format format]) => new Writer(this, format);

  /**
   * Read the serialized data from [input] and return the root object
   * from the result. The [input] can be of any type that the [Format]
   * reads/writes, but normally will be a [List], [Map], or a simple type.
   * The [format] parameter determines the form of the result. The default
   * format is [SimpleMapFormat] and expects a Map as input.
   * If there are objects that need to be resolved
   * in the current context, they should be provided in [externals] as a
   * Map from names to values. In particular, in the current implementation
   * any class mirrors needed should be provided in [externals] using the
   * class name as a key. In addition to the [externals] map provided here,
   * values will be looked up in the [namedObjects] map.
   */
  read(input, {Format format, Map externals: const {}}) {
    return newReader(format).read(input, externals);
  }

  /**
   * Return a new [Reader] object for this serialization. This is useful if
   * you want to do something more complex with the reader than just returning
   * the final result.
   */
  Reader newReader([Format format]) => new Reader(this, format);

  /**
   * Return the list of SerializationRule that apply to [object]. For
   * internal use, but public because it's used in testing.
   */
  Iterable<SerializationRule> rulesFor(object, Writer w, {create : true}) {
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
      candidateRules = object.possibleRules(rules);
    } else {
      target = object;
      candidateRules = rules;
    }
    Iterable applicable = candidateRules.where(
        (each) => each.appliesTo(target, w));

    if (applicable.isEmpty) {
      return create ? [addRuleFor(target)] : applicable;
    }

    if (applicable.length == 1) return applicable;
    var first = applicable.first;
    var finalRules = applicable.where(
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
  Serialization ruleSerialization() {
    // TODO(alanknight): There's an extensibility issue here with new rules.
    // TODO(alanknight): How to handle rules with closures? They have to
    // exist on the other side, but we might be able to hook them up by name,
    // or we might just be able to validate that they're correctly set up
    // on the other side.

    var meta = new Serialization()
      ..selfDescribing = false
      ..addRuleFor(ListRule)
      ..addRuleFor(MapRule)
      ..addRuleFor(PrimitiveRule)
      ..addRuleFor(ListRuleEssential)
      ..addRuleFor(BasicRule,
          constructorFields: ['type',
            'constructorName',
            'constructorFields', 'regularFields', []],
          fields: [])
      ..addRule(new NamedObjectRule())
      ..addRule(new MirrorRule())
      ..addRuleFor(MirrorRule)
      ..addRuleFor(SymbolRule)
      ..addRuleFor(DateTimeRule);
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
  const SerializationException(this.message);
  String toString() => "SerializationException($message)";
}
