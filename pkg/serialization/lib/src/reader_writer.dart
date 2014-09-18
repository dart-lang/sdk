// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of serialization;

/**
 * This writes out the state of the objects to an external format. It holds
 * all of the intermediate state needed. The primary API for it is the
 * [write] method.
 */
// TODO(alanknight): For simple serialization formats this does a lot of work
// that isn't necessary, e.g. detecting cycles and maintaining references.
// Consider having an abstract superclass with the basic functionality and
// simple serialization subclasses where we know there aren't cycles.
class Writer implements ReaderOrWriter {
  /**
   * The [serialization] holds onto the rules that define how objects
   * are serialized.
   */
  final Serialization serialization;

  /** The [trace] object keeps track of the objects to be visited while finding
   * the full set of objects to be written.*/
  Trace trace;

  /**
   * When we write out objects, should we also write out a description
   * of the rules for the serialization. This defaults to the corresponding
   * value on the Serialization.
   */
  bool selfDescribing;

  final Format format;

  /**
   * Objects that cannot be represented in-place in the serialized form need
   * to have references to them stored. The [Reference] objects are computed
   * once and stored here for each object. This provides some space-saving,
   * but also serves to record which objects we have already seen.
   */
  final Map<dynamic, Reference> references =
      new HashMap<Object, Reference>.identity();

  /**
   * The state of objects that need to be serialized is stored here.
   * Each rule has a number, and rules keep track of the objects that they
   * serialize, in order. So the state of any object can be found by indexing
   * from the rule number and the object number within the rule.
   * The actual representation of the state is determined by the rule. Lists
   * and Maps are common, but it is arbitrary.
   */
  final List<List> states = new List<List>();

  /** Return the list of rules we use. */
  List<SerializationRule> get rules => serialization.rules;

  /**
   * Creates a new [Writer] that uses the rules from its parent
   * [Serialization]. Serializations do not keep any state
   * related to a particular read/write, so the same one can be used
   * for multiple different Readers/Writers.
   */
  Writer(this.serialization, [Format newFormat]) :
    format = (newFormat == null) ? const SimpleMapFormat() : newFormat {
    trace = new Trace(this);
    selfDescribing = serialization.selfDescribing;
  }

  /**
   * This is the main API for a [Writer]. It writes the objects and returns
   * the serialized representation, as determined by [format].
   */
  write(anObject) {
    trace.addRoot(anObject);
    trace.traceAll();
    _flatten();
    return format.generateOutput(this);
  }

  /**
   * Given that we have fully populated the list of [states], and more
   * importantly, the list of [references], go through each state and turn
   * anything that requires a [Reference] into one. Since only the rules
   * know the representation they use for state, delegate to them.
   */
  void _flatten() {
    for (var eachRule in rules) {
      _growStates(eachRule);
      var index = eachRule.number;
      var statesForThisRule = states[index];
      for (var i = 0; i < statesForThisRule.length; i++) {
        var eachState = statesForThisRule[i];
        var newState = eachRule.flatten(eachState, this);
        if (newState != null) {
          statesForThisRule[i] = newState;
        }
      }
    }
  }

  /**
   * As the [trace] processes each object, it will call this method on us.
   * We find the rules for this object, and record the state of the object
   * as determined by each rule.
   */
  void _process(object, Trace trace) {
    var real = (object is DesignatedRuleForObject) ? object.target : object;
    for (var eachRule in serialization.rulesFor(object, this)) {
      _record(real, eachRule);
    }
  }

  /**
   * Record the state of [object] as determined by [rule] and keep
   * track of it. Generate a [Reference] for this object if required.
   * When it's required is up to the particular rule, but generally everything
   * gets a reference except a primitive.
   * Note that at this point the states are just the same as the fields of the
   * object, and haven't been flattened.
   */
  void _record(object, SerializationRule rule) {
    if (rule.shouldUseReferenceFor(object, this)) {
      references.putIfAbsent(object, () =>
          new Reference(this, rule.number, _nextObjectNumberFor(rule)));
      var state = rule.extractState(object, trace.note, this);
      _addStateForRule(rule, state);
    }
  }

  /**
   * Should we store primitive objects directly or create references for them.
   * That depends on which format we're using, so a flat format will want
   * references, but the Map format can store them directly.
   */
  bool get shouldUseReferencesForPrimitives
      => format.shouldUseReferencesForPrimitives;

  /**
   * Returns a serialized version of the [SerializationRule]s used to write
   * the data, if [selfDescribing] is true, otherwise returns null.
   */
  serializedRules() {
    if (!selfDescribing) return null;
    var meta = serialization.ruleSerialization();
    var writer = new Writer(meta, format);
    writer.selfDescribing = false;
    return writer.write(serialization.rules);
  }

  /** Record a [state] entry for a particular rule. */
  void _addStateForRule(eachRule, state) {
    _growStates(eachRule);
    states[eachRule.number].add(state);
  }

  /** Find what the object number for the thing we're about to add will be.*/
  int _nextObjectNumberFor(SerializationRule rule) {
    _growStates(rule);
    return states[rule.number].length;
  }

  /**
   * We store the states in a List, indexed by rule number. But rules can be
   * dynamically added, so we may have to grow the list.
   */
  void _growStates(eachRule) {
    while (states.length <= eachRule.number) states.add(new List());
  }

  /**
   * Return true if we have an object number for this object. This is used to
   * tell if we have processed the object or not. This relies on checking if we
   * have a reference or not. That saves some space by not having to keep track
   * of simple objects, but means that if someone refers to the identical string
   * from several places, we will process it several times, and store it
   * several times. That seems an acceptable tradeoff, and in cases where it
   * isn't, it's possible to apply a rule for String, or even for Strings larger
   * than x, which gives them references.
   */
  bool _hasIndexFor(object) {
    return _objectNumberFor(object) != -1;
  }

  /**
   * Given an object, find what number it has. The number is valid only in
   * the context of a particular rule, and if the rule has more than one,
   * this will return the one for the primary rule, defined as the one that
   * is listed in its canonical reference.
   */
  int _objectNumberFor(object) {
    var reference = references[object];
    return (reference == null) ? -1 : reference.objectNumber;
  }

  /**
   * Return a list of [Reference] objects pointing to our roots. This will be
   * stored in the output under "roots" in the default format.
   */
  List _rootReferences() => trace.roots.map(_referenceFor).toList();

  /**
   * Given an object, return a reference for it if one exists. If there's
   * no reference, return the object itself. Once we have finished the tracing
   * step, all objects that should have a reference (roughly speaking,
   * non-primitives) can be relied on to have a reference.
   */
  _referenceFor(object) {
    var result = references[object];
    return (result == null) ? object : result;
  }

  /**
   * Return true if the [Serialization.namedObjects] collection has a
   * reference to [object].
   */
  // TODO(alanknight): Should the writer also have its own namedObjects
  // collection specific to the particular write, or is that just adding
  // complexity for little value?
  bool hasNameFor(object) => serialization._hasNameFor(object);

  /**
   * Return the name we have for this object in the [Serialization.namedObjects]
   * collection.
   */
  String nameFor(object) => serialization._nameFor(object);

  // For debugging/testing purposes. Find what state a reference points to.
  stateForReference(Reference r) => states[r.ruleNumber][r.objectNumber];

  /** Return the state pointed to by [reference]. */
  resolveReference(reference) => stateForReference(reference);
}

/**
 * An abstract class for Reader and Writer, which primarily exists so we can
 * type things that will refer to one or the other, depending on which
 * operation we're doing.
 */
abstract class ReaderOrWriter {
  /** Return the list of serialization rules we are using.*/
  List<SerializationRule> get rules;

  /** Return the internal collection of object state and [Reference] objects. */
  List<List> get states;

  /**
   * Return the object, or state, that ref points to, depending on which
   * we're generating.
   */
  resolveReference(Reference ref);
}

/**
 * The main class responsible for reading. It holds
 * onto the necessary state and to the objects that have been inflated.
 */
class Reader implements ReaderOrWriter {

  /**
   * The serialization that specifies how we read. Note that in contrast
   * to the Writer, this is not final. This is because we may be created
   * with an empty [Serialization] and then read the rules from the data,
   * if [selfDescribing] is true.
   */
  Serialization serialization;

  /**
   * When we read objects, should we read a description of the rules if
   * present. This defaults to the corresponding value on the Serialization.
   */
  bool selfDescribing;

  /**
   * The state of objects that have been serialized is stored here.
   * Each rule has a number, and rules keep track of the objects that they
   * serialize, in order. So the state of any object can be found by indexing
   * from the rule number and the object number within the rule.
   * The actual representation of the state is determined by the rule. Lists
   * and Maps are common, but it is arbitrary. See [Writer.states].
   */
  List<List> _data;

  /** Return the internal collection of object state and [Reference] objects. */
  get states => _data;

  /**
   * The resulting objects, indexed according to the same scheme as
   * _data, where each rule has a number, and rules keep track of the objects
   * that they serialize, in order.
   */
  List<List> objects;

  final Format format;

  /**
   * Creates a new [Reader] that uses the rules from its parent
   * [Serialization]. Serializations do not keep any state related to
   * a particular read or write operation, so the same one can be used
   * for multiple different Writers/Readers.
   */
  Reader(this.serialization, [Format newFormat]) :
    format = (newFormat == null) ? const SimpleMapFormat() : newFormat  {
    selfDescribing = serialization.selfDescribing;
  }

  /**
   * When we read, we may need to look up objects by name in order to link to
   * them. This is particularly true if we have references to classes,
   * functions, mirrors, or other non-portable entities. The map in which we
   * look things up can be provided as an argument to read, but we can also
   * provide a map here, and objects will be looked up in both places.
   */
  Map namedObjects;

  /**
   * Look up the reference to an external object. This can be held either in
   * the reader-specific list of externals or in the serializer's
   */
  objectNamed(key, [Function ifAbsent]) {
    var map = (namedObjects.containsKey(key))
        ? namedObjects : serialization.namedObjects;
    if (!map.containsKey(key)) {
      (ifAbsent == null ? keyNotFound : ifAbsent)(key);
    }
    return map[key];
  }

  void keyNotFound(key) {
    throw new SerializationException(
        'Cannot find named object to link to: $key');
  }

  /**
   * Return the list of rules to be used when writing. These come from the
   * [serialization].
   */
  List<SerializationRule> get rules => serialization.rules;

  /**
   * Internal use only, for testing purposes. Set the data for this reader
   * to a List of Lists whose size must match the number of rules.
   */
  // When we set the data, initialize the object storage to a matching size.
  void set data(List<List> newData) {
    _data = newData;
    objects = _data.map((x) => new List(x.length)).toList();
  }

  /**
   * This is the primary method for a [Reader]. It takes the input data,
   * decodes it according to [format] and returns the root object.
   */
  read(rawInput, [Map externals = const {}]) {
    namedObjects = externals;
    var input = format.read(rawInput, this);
    data = input["data"];
    rules.forEach(inflateForRule);
    return inflateReference(input["roots"].first);
  }

  /**
   * If the data we are reading from has rules written to it, read them back
   * and set them as the rules we will use.
   */
  void readRules(newRules) {
    // TODO(alanknight): Replacing the serialization is kind of confusing.
    if (newRules == null) return;
    var reader = serialization.ruleSerialization().newReader(format);
    List rulesWeRead = reader.read(newRules, namedObjects);
    if (rulesWeRead != null && !rulesWeRead.isEmpty) {
      serialization = new Serialization.blank();
      rulesWeRead.forEach(serialization.addRule);
    }
  }

  /**
   * Inflate all of the objects for [rule]. Does the essential state for all
   * objects first, then the non-essential state. This avoids cycles in
   * non-essential state, because all the objects will have already been
   * created.
   */
  void inflateForRule(rule) {
    var dataForThisRule = _data[rule.number];
    keysAndValues(dataForThisRule).forEach((position, state) {
      inflateOne(rule, position, state);
    });
    keysAndValues(dataForThisRule).forEach((position, state) {
      rule.inflateNonEssential(state, allObjectsForRule(rule)[position], this);
    });
  }

  /**
   * Create a new object, based on [rule] and [state], which will
   * be stored in [position] in the storage for [rule]. This will
   * follow references and recursively inflate them, leaving Sentinel objects
   * to detect cycles.
   */
  inflateOne(SerializationRule rule, position, state) {
    var existing = allObjectsForRule(rule)[position];
    // We may already be in progress and hitting this in a cycle.
    if (existing is _Sentinel) {
      throw new SerializationException('Cycle in essential state');
    }
    // We may have already inflated this object, at least its essential state.
    if (existing != null) return existing;

    // Put a sentinel there to mark this in case of recursion.
    allObjectsForRule(rule)[position] = const _Sentinel();
    var newObject = rule.inflateEssential(state, this);
    allObjectsForRule(rule)[position] = newObject;
    return newObject;
  }

  /**
   * The parameter [possibleReference] might be a reference. If it isn't, just
   * return it. If it is, then inflate the target of the reference and return
   * the resulting object.
   */
  inflateReference(possibleReference) {
    // If this is a primitive, return it directly.
    // TODO This seems too complicated.
    return asReference(possibleReference,
        ifReference: (reference) {
          var rule = ruleFor(reference);
          var state = _stateFor(reference);
          inflateOne(rule, reference.objectNumber, state);
          return _objectFor(reference);
        });
  }

  /** Return the object pointed to by [reference]. */
  resolveReference(reference) => inflateReference(reference);

  /**
   * Given [reference], return what we have stored as an object for it. Note
   * that, depending on the current state, this might be null or a Sentinel.
   */
  _objectFor(Reference reference) =>
      objects[reference.ruleNumber][reference.objectNumber];

  /** Given [rule], return the storage for its objects. */
  allObjectsForRule(SerializationRule rule) => objects[rule.number];

  /** Given [reference], return the the state we have stored for it. */
  _stateFor(Reference reference) =>
      _data[reference.ruleNumber][reference.objectNumber];

  /** Given a reference, return the rule it references. */
  SerializationRule ruleFor(Reference reference) =>
      serialization.rules[reference.ruleNumber];

  /**
   * Return the primitive rule we are using. This is an ugly mechanism to
   * support the extra information to reconstruct objects in the
   * [SimpleJsonFormat].
   */
  SerializationRule _primitiveRule() {
    for (var each in rules) {
      if (each.runtimeType == PrimitiveRule) {
        return each;
      }
    }
    throw new SerializationException("No PrimitiveRule found");
  }

  /**
   * Given a possible reference [anObject], call either [ifReference] or
   * [ifNotReference], depending if it's a reference or not. This is the
   * primary place that knows about the serialized representation of a
   * reference.
   */
  asReference(anObject, {Function ifReference: doNothing,
      Function ifNotReference : doNothing}) {
    if (anObject is Reference) return ifReference(anObject);
    if (anObject is Map && anObject["__Ref"] != null) {
      var ref =
          new Reference(this, anObject["rule"], anObject["object"]);
      return ifReference(ref);
    } else {
      return ifNotReference(anObject);
    }
  }
}

/**
 * This serves as a marker to indicate a object that is in the process of
 * being de-serialized. So if we look for an object slot and find one of these,
 * we know we've hit a cycle.
 */
class _Sentinel {
  const _Sentinel();
}

/**
 * This represents the transitive closure of the referenced objects to be
 * used for serialization. It works closely in conjunction with the Writer,
 * and is kept as a separate object primarily for the possibility of wanting
 * to plug in different sorts of tracing rules.
 */
class Trace {
  // TODO(alanknight): It seems likely that the mechanism for cutting off
  // tracings is by specifying rules. So is there any reason any more to have
  // this as a separate class?
  final Writer writer;

  /**
   * This class works by doing a breadth-first traversal of the objects,
   * with the traversal order maintained in [queue].
   */
  final Queue queue = new Queue();

  /** The root objects from which we will be tracing. */
  final List roots = [];

  Trace(this.writer);

  void addRoot(object) {
    roots.add(object);
  }

  /** A convenience method to add a single root and trace it in one step. */
  void trace(object) {
    addRoot(object);
    traceAll();
  }

  /**
   * Process all of the objects reachable from our roots via state that the
   * serialization rules access.
   */
  void traceAll() {
    queue.addAll(roots);
    while (!queue.isEmpty) {
      var next = queue.removeFirst();
      if (!hasProcessed(next)) writer._process(next, this);
    }
  }

  /**
   * Has this object been seen yet? We test for this by checking if the
   * writer has a reference for it. See comment for _hasIndexFor.
   */
  bool hasProcessed(object) {
   return writer._hasIndexFor(object);
  }

  /** Note that we've seen [value], and add it to the queue to be processed. */
  note(value) {
    if (value != null) {
      queue.add(value);
    }
    return value;
  }
}

/**
 * Any pointers to objects that can't be represented directly in the
 * serialization format has to be stored as a reference. A reference encodes
 * the rule number of the rule that saved it in the Serialization that was used
 * for writing, and the object number within that rule.
 */
class Reference {
  /** The [Reader] or [Writer] that owns this reference. */
  final ReaderOrWriter parent;
  /** The position of the rule that controls this reference in [parent]. */
  final int ruleNumber;
  /** The index of the referred-to object in the storage of [parent] */
  final int objectNumber;

  Reference(this.parent, this.ruleNumber, this.objectNumber) {
    if (ruleNumber == null || objectNumber == null) {
      throw new SerializationException("Invalid Reference");
    }
    if (parent.rules.length < ruleNumber) {
      throw new SerializationException("Invalid Reference");
    }
  }

  /**
   * Return the thing this reference points to. Assumes that we have a valid
   * parent and that it is a Reader, as inflating is not meaningful when
   * writing.
   */
  inflated() => parent.resolveReference(this);

  /**
   * Convert the reference to a map in JSON format. This is specific to the
   * custom JSON format we define, and must be consistent with the
   * [Reader.asReference] method.
   */
  // TODO(alanknight): This is a hack both in defining a toJson specific to a
  // particular representation, and the use of a bogus sentinel "__Ref"
  Map<String, int> toJson() => {
    "__Ref" : 0,
    "rule" : ruleNumber,
    "object" : objectNumber
  };

  /** Write our information to [list]. Useful in writing to flat formats.*/
  void writeToList(List list) {
    list.add(ruleNumber);
    list.add(objectNumber);
  }

  String toString() => "Reference($ruleNumber, $objectNumber)";
}

/**
 * This is used during tracing to indicate that an object should be processed
 * using a particular rule, rather than the one that might ordinarily be
 * found for it. This normally only makes sense if the object is uniquely
 * referenced, and is a more or less internal collection. See ListRuleEssential
 * for an example. It knows how to return its object and how to filter.
 */
class DesignatedRuleForObject {
  final Function rulePredicate;
  final target;

  DesignatedRuleForObject(this.target, this.rulePredicate);

  List possibleRules(List rules) => rules.where(rulePredicate).toList();
}
