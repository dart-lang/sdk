// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of serialization;

// TODO(alanknight): We should have an example and tests for subclassing
// serialization rule rather than using the hard-coded ClosureToMap rule. And
// possibly an abstract superclass that's designed to be subclassed that way.
/**
 * The abstract superclass for serialization rules.
 */
abstract class SerializationRule {
  /**
   * Rules belong uniquely to a particular Serialization instance, and can
   * be identified within it by number.
   */
  int _number;

  /**
   * Rules belong uniquely to a particular Serialization instance, and can
   * be identified within it by number.
   */
  int get number => _number;

  /**
   * Rules belong uniquely to a particular Serialization instance, and can
   * be identified within it by number.
   */
  void set number(x) {
    if (_number != null) throw
        new SerializationException("Rule numbers cannot be changed, once set");
    _number = x;
  }

  /**
   * Return true if this rule applies to this object, in the context
   * where we're writing it, false otherwise.
   */
  bool appliesTo(object, Writer writer);

  /**
   * This extracts the state from the object, calling [f] for each value
   * as it is extracted, and returning an object representing the whole
   * state at the end. The state that results will still have direct
   * pointers to objects, rather than references.
   */
  extractState(object, void f(value));

  /**
   * Given the variables representing the state of an object, flatten it
   * by turning object pointers into Reference objects where needed. This
   * destructively modifies the state object.
   *
   * This has a default implementation which assumes that object is indexable,
   * so either conforms to Map or List. Subclasses may override to do something
   * different.
   */
  // This has to be a separate operation from extracting, because we extract
  // as we are traversing the objects, so we don't yet have the objects to
  // generate references for them. It might be possible to avoid that by
  // doing a depth-first rather than breadth-first traversal, but I'm not
  // sure it's worth it.
  void flatten(state, Writer writer) {
    keysAndValues(state).forEach((key, value) {
      var reference = writer._referenceFor(value);
      state[key] = (reference == null) ? value : reference;
    });
  }

  /** Return true if this rule should only be applied when we are the first
   * rule found that applies to this object. This may or may not be a hack
   * that will disappear once we have better support for multiple rules.
   * We want to have multiple different rules that apply to the same object. We
   * also want to have multiple different rules that might exclusively apply
   * to the same object. So, we want either ListRule or ListRuleEssential, and
   * only one of them can be there. But on the other hand, we may want both
   * ListRule and BasicRule. So we identify the kinds of rules that can share.
   * If mustBePrimary returns true, then this rule will only be chosen if no
   * other rule has been found yet. This means that the ordering of rules in
   * the serialization is significant, which is unpleasant, but we'll have
   * to see how bad it is.
   */
  // TODO(alanknight): Reconsider whether this should be handled differently.
  get mustBePrimary => false;

  /**
   * Create the new object corresponding to [state] using the rules
   * from [reader]. This may involve recursively inflating "essential"
   * references in the state, which are those that are required for the
   * object's constructor. It is up to the rule what state is considered
   * essential.
   */
  inflateEssential(state, Reader reader);

  /**
   * The [object] has already been created. Set any of its non-essential
   * variables from the representation in [state]. Where there are references
   * to other objects they are resolved in the context of [reader].
   */
  inflateNonEssential(state, object, Reader reader);

  /**
   * If we have [object] as part of our state, should we represent that
   * directly, or should we make a reference for it. By default we use a
   * reference for everything.
   */
  bool shouldUseReferenceFor(object, Writer w) => true;

  /**
   * This writes the data from our internal representation into a List.
   * It is used in order to write to a flat format, and is likely to be
   * folded into a more general mechanism for supporting different output
   * formats.
   */
  // TODO(alanknight): This really shouldn't exist, but is a temporary measure
  // for writing to a a flat format until that's more fleshed out. It takes
  // the internal representation of the rule's state, which is particularly
  // bad. The default implementation treats the ruleData as a List of Lists
  // of references.
  void dumpStateInto(List ruleData, List target) {
    // Needing the intermediate is also bad for performance, but tricky
    // to do otherwise without a mechanism to precalculate the size.
    var intermediate = new List();
    var totalLength = 0;
    for (var eachList in ruleData) {
      if (writeLengthInFlatFormat) {
        intermediate.add(eachList.length);
      }
      for (var eachRef in eachList) {
        if (eachRef == null) {
          intermediate..add(null)..add(null);
        } else {
          eachRef.writeToList(intermediate);
        }
      }
    }
    target.addAll(intermediate);
  }

  /**
   * Return true if this rule writes a length value before each entry in
   * the flat format. Return false if the results are fixed length.
   */
  // TODO(alanknight): This should probably go away with more general formats.
  bool get writeLengthInFlatFormat => false;

  /**
   * The inverse of dumpStateInto, this reads the rule's state from an
   * iterator in a flat format.
   */
  pullStateFrom(Iterator stream) {
    var numberOfEntries = stream.next();
    var ruleData = new List();
    for (var i = 0; i < numberOfEntries; i++) {
      var subLength = dataLengthIn(stream);
      var subList = [];
      ruleData.add(subList);
      for (var j = 0; j < subLength; j++) {
        var a = stream.next();
        var b = stream.next();
        if (!(a is int)) {
          // This wasn't a reference, just use the first object as a literal.
          // particularly used for the case of null.
          subList.add(a);
        } else {
          subList.add(new Reference(this, a, b));
        }
      }
    }
    return ruleData;
  }

  /**
   * Return the length of the list of data we expect to see on a particular
   * iterator in a flat format. This may have been encoded in the stream if we
   * are variable length, or it may be constant. Note that this is expressed in
   *
   */
  dataLengthIn(Iterator stream) =>
      writeLengthInFlatFormat ? stream.next() : dataLength;

  /**
   * If the data is fixed length, return it here. Unused in the non-flat
   * format, or if the data is variable length.
   */
  int get dataLength => 0;
}

/**
 * This rule handles things that implement List. It will recreate them as
 * whatever the default implemenation of List is on the target platform.
 */
class ListRule extends SerializationRule {

  appliesTo(object, Writer w) => object is List;

  state(List list) => new List.from(list);

  List extractState(List list, f) {
    var result = new List();
    for (var each in list) {
      result.add(each);
      f(each);
    }
    return result;
  }

  inflateEssential(List state, Reader r) => new List();

  // For a list, we consider all of its state non-essential and add it
  // after creation.
  inflateNonEssential(List state, List newList, Reader r) {
    populateContents(state, newList, r);
  }

  void populateContents(List state, List newList, Reader r) {
    for(var each in state) {
      newList.add(r.inflateReference(each));
    }
  }

  /**
   * When reading from a flat format we are given [stream] and need to pull as
   * much data from it as we need. Our format is that we have an integer N
   * indicating the number of objects and then for each object a length M,
   * and then M references, where a reference is stored in the stream as two
   * integers. Or, in the special case of null, two nulls.
   */
  pullStateFrom(Iterator stream) {
    // TODO(alanknight): This is much too close to the basicRule implementation,
    // and I'd refactor them if I didn't think this whole mechanism needed to
    // change soon.
    var length = stream.next();
    var ruleData = new List();
    for (var i = 0; i < length; i++) {
      var subLength = stream.next();
      var subList = new List();
      ruleData.add(subList);
      for (var j = 0; j < subLength; j++) {
        var a = stream.next();
        var b = stream.next();
        if (!(a is int)) {
          // This wasn't a reference, just use the first object as a literal.
          // particularly used for the case of null.
          subList.add(a);
        } else {
          subList.add(new Reference(this, a, b));
        }
      }
    }
    return ruleData;
  }

  /**
   * Return true because we need to write the length of each list in the flat
   * format. */
  bool get writeLengthInFlatFormat => true;

  /** Return the length of the next list when reading the flat format. */
  int dataLengthIn(Iterator stream) => stream.next();
}

/**
 * This is a subclass of ListRule where all of the list's contents are
 * considered essential state. This is needed if an object X contains a List L,
 * but it expects L's contents to be fixed when X's constructor is called.
 */
class ListRuleEssential extends ListRule {

  /** Create the new List and also inflate all of its contents. */
  inflateEssential(List state, Reader r) {
    var object = super.inflateEssential(state, r);
    populateContents(state, object, r);
    return object;
  }

  /** Does nothing, because all the work has been done in inflateEssential. */
  inflateNonEssential(state, newList, reader) {}

  bool get mustBePrimary => true;
}

/**
 * This rule handles primitive types, defined as those that we can normally
 * represent directly in the output format. We hard-code that to mean
 * num, String, and bool.
 */
class PrimitiveRule extends SerializationRule {
  appliesTo(object, Writer w) {
    return isPrimitive(object);
  }
  extractState(object, Function f) => object;
  void flatten(object, Writer writer) {}
  inflateEssential(state, Reader r) => state;
  inflateNonEssential(object, _, Reader r) {}

  /**
   * Indicate whether we should save pointers to this object as references
   * or store the object directly. For primitives this depends on the format,
   * so we delegate to the writer.
   */
  bool shouldUseReferenceFor(object, Writer w) =>
      w.shouldUseReferencesForPrimitives;

  /**
   * This writes the data from our internal representation into a List.
   * It is used in order to write to a flat format, and is likely to be
   * folded into a more general mechanism for supporting different output
   * formats. For primitives, the ruleData is our list of all the
   * primitives and just add it into the target.
   */
  void dumpStateInto(List ruleData, List target) {
    target.addAll(ruleData);
  }

  /**
   * When reading from a flat format we are given [stream] and need to pull as
   * much data from it as we need. Our format is that we have an integer N
   * indicating the number of objects and then N simple objects.
   */
  pullStateFrom(Iterator stream) {
    var length = stream.next();
    var ruleData = new List();
    for (var i = 0; i < length; i++) {
      ruleData.add(stream.next());
    }
    return ruleData;
  }
}

/** Helper function for PrimitiveRule to tell which objects it applies to. */
bool isPrimitive(object) {
  return object is num || object is String || object is bool;
}

/** Typedef for the object construction closure used in ClosureRule. */
typedef ConstructType(Map m);

/** Typedef for the state-getting closure used in ClosureToMapRule. */
typedef Map<String, dynamic> GetStateType(object);

/** Typedef for the state-setting closure used in ClosureToMapRule. */
typedef void NonEssentialStateType(object, Map m);

/**
 * This is a rule where the extraction and creation are hard-coded as
 * closures. The result is expected to be a map indexed by field name.
 */
class ClosureRule extends CustomRule {

  /** The runtimeType of objects that this rule applies to. Used in appliesTo.*/
  final Type type;

  /** The function for constructing new objects when reading. */
  ConstructType construct;

  /** The function for returning an object's state as a Map. */
  GetStateType getStateFunction;

  /** The function for setting an object's state from a Map. */
  NonEssentialStateType setNonEssentialState;

  /**
   * Create a ClosureToMapRule for the given [type] which gets an object's
   * state by calling [getState], creates a new object by calling [construct]
   * and sets the new object's state by calling [setNonEssentialState].
   */
  ClosureRule(this.type, this.getStateFunction, this.construct,
      this.setNonEssentialState);

  bool appliesTo(object, Writer w) => object.runtimeType == type;

  getState(object) => getStateFunction(object);

  create(state) => construct(state);

  setState(object, state) {
    if (setNonEssentialState == null) return;
    setNonEssentialState(object, state);
  }
}

/**
 * This rule handles things we can't pass directly, but only by reference.
 * If objects are listed in the namedObjects in the writer or serialization,
 * it will save the name rather than saving the state.
 */
class NamedObjectRule extends SerializationRule {
  /**
   * Return true if this rule applies to the object. Checked by looking up
   * in the namedObjects collection.
   */
  bool appliesTo(object, Writer writer) {
    return writer.hasNameFor(object);
  }

  /** Extract the state of the named objects as just the object itself. */
  extractState(object, Function f) => [object];

  /** When we flatten the state we save it as the name. */
  // TODO(alanknight): This seems questionable. In a truly flat format we may
  // want to have extracted the name as a string first and flatten it into a
  // reference to that. But that requires adding the Writer as a parameter to
  // extractState, and I'm reluctant to add yet another parameter until
  // proven necessary.
  void flatten(state, Writer writer) {
    state[0] = nameFor(state.first, writer);
  }

  /** Look up the named object and return it. */
  inflateEssential(state, Reader r) => r.objectNamed(state.first);

  /** Set any non-essential state on the object. For this rule, a no-op. */
  inflateNonEssential(state, object, Reader r) {}

  /** Return the name for this object in the Writer. */
  nameFor(object, Writer writer) => writer.nameFor(object);
}

/**
 * This rule handles the special case of Mirrors, restricted to those that
 * have a simpleName. It knows that it applies to any such mirror and
 * automatically uses its simpleName as the key into the namedObjects.
 * When reading, the user is still responsible for adding the appropriate
 * mirrors to namedObject.
 */
class MirrorRule extends NamedObjectRule {
  bool appliesTo(object, Writer writer) => object is DeclarationMirror;
  nameFor(DeclarationMirror object, Writer writer) => object.simpleName;
}

/**
 * This provides an abstract superclass for writing your own rules specific to
 * a class. It makes some assumptions about behaviour, and so can have a
 * simpler set of methods that need to be implemented in order to subclass it.
 *
 */
abstract class CustomRule extends SerializationRule {
  // TODO(alanknight): It would be nice if we could provide an implementation
  // of appliesTo() here. If we add a type parameter to these classes
  // we can "is" test against it, but we need to be able to rule out subclasses.
  // => instance.runtimeType == T
  // should work.
  /**
   * Return true if this rule applies to this object, in the context
   * where we're writing it, false otherwise.
   */
  bool appliesTo(instance, Writer w);

  /**
   * Subclasses should implement this to return a list of the important fields
   * in the object. The order of the fields doesn't matter, except that the
   * create and setState methods need to know how to use it.
   */
  List getState(instance);

  /**
   * Given a [List] of the object's [state], re-create the object. This should
   * do the minimum needed to create the object, just calling the constructor.
   * Setting the remaining state of the object should be done in the [setState]
   * method, which will be called only once all the objects are created, so
   * it won't cause problems with cycles.
   */
  create(List state);

  /**
   * Set any state in [object] which wasn't set in the constructor. Between
   * this method and [create] all of the information in [state] should be set
   * in the new object.
   */
  void setState(object, List state);

  extractState(instance, Function f) {
    var state = getState(instance);
    for (var each in values(state)) {
      f(each);
    }
    return state;
  }

  inflateEssential(state, Reader r) => create(_lazy(state, r));

  void inflateNonEssential(state, object, Reader r) =>
      setState(object, _lazy(state, r));

  // We don't want to have to make the end user tell us how long the list is
  // separately, so write it out for each object, even though they're all
  // expected to be the same length.
  get writeLengthInFlatFormat => true;
}

/** Create a lazy list/map that will inflate its items on demand in [r]. */
_lazy(l, Reader r) {
  if (l is List) return new _LazyList(l, r);
  if (l is Map) return new _LazyMap(l, r);
  throw new SerializationException("Invalid type: must be Map or List - $l");
}

/**
 * This provides an implementation of Map that wraps a list which may
 * contain references to (potentially) non-inflated objects. If these
 * are accessed it will inflate them. This allows us to pass something that
 * looks like it's just a list of objects to a [CustomRule] without needing
 * to inflate all the references in advance.
 */
class _LazyMap implements Map {
  _LazyMap(this._raw, this._reader);

  Map _raw;
  Reader _reader;

  // This is the only operation that really matters.
  operator [](x) => _reader.inflateReference(_raw[x]);

  int get length => _raw.length;
  bool get isEmpty => _raw.isEmpty;
  List get keys => _raw.keys;
  bool containsKey(x) => _raw.containsKey(x);

  // These operations will work, but may be expensive, and are probably
  // best avoided.
  get _inflated => keysAndValues(_raw).map(_reader.inflateReference);
  bool containsValue(x) => _inflated.containsValue(x);
  List get values => _inflated.values;
  void forEach(f) => _inflated.forEach(f);

  // These operations are all invalid
  _throw() => throw new UnsupportedError("Not modifiable");
  operator []=(x, y) => _throw();
  putIfAbsent(x, y) => _throw();
  remove(x) => _throw();
  clear() => _throw();
}

/**
 * This provides an implementation of List that wraps a list which may
 * contain references to (potentially) non-inflated objects. If these
 * are accessed it will inflate them. This allows us to pass something that
 * looks like it's just a list of objects to a [CustomRule] without needing
 * to inflate all the references in advance.
 */
class _LazyList implements List {
  _LazyList(this._raw, this._reader);

  List _raw;
  Reader _reader;

  // This is the only operation that really matters.
  operator [](x) => _reader.inflateReference(_raw[x]);

  int get length => _raw.length;
  bool get isEmpty => _raw.isEmpty;
  get first => _reader.inflateReference(_raw.first);
  get last => _reader.inflateReference(_raw.last);

  // These operations will work, but may be expensive, and are probably
  // best avoided.
  get _inflated => _raw.map(_reader.inflateReference);
  map(f) => _inflated.map(f);
  filter(f) => _inflated.filter(f);
  bool contains(element) => _inflated.filter(element);
  forEach(f) => _inflated.forEach(f);
  reduce(x, f) => _inflated.reduce(x, f);
  every(f) => _inflated(f);
  some(f) => _inflated(f);
  iterator() => _inflated.iterator();
  indexOf(x, [pos = 0]) => _inflated.indexOf(x);
  lastIndexOf(x, [pos]) => _inflated.lastIndexOf(x);

  // These operations are all invalid
  _throw() => throw new UnsupportedError("Not modifiable");
  operator []=(x, y) => _throw();
  add(x) => _throw();
  addLast(x) => _throw();
  addAll(x) => _throw();
  sort([f]) => _throw();
  clear() => _throw();
  removeAt(x) => _throw();
  removeLast() => _throw();
  getRange(x, y) => _throw();
  setRange(x, y, z, [a]) => _throw();
  removeRange(x, y) => _throw();
  insertRange(x, y, [z]) => _throw();
  void set length(x) => _throw();
}