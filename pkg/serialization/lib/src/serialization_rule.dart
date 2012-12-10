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

  /** Return true if this rule applies to this object, false otherwise. */
  bool appliesTo(object);

  /**
   * This extracts the state from the object, calling [f] for each value
   * as it is extracted, and returning an object representing the whole
   * state at the end. The state that results will still have direct
   * pointers to objects, rather than references.
   */
  Object extractState(object, void f(value));

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
   * If we have an object [o] as part of our state, should we represent that
   * directly, or should we make a reference for it. By default we use a
   * reference for everything.
   */
  bool shouldUseReferenceFor(Object o, Writer w) => true;

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
      // TODO(alanknight): Abstract this out better, this really won't scale.
      if (this is ListRule)
        intermediate.add(eachList.length);
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
   * The inverse of dumpStateInto, this reads the rule's state from an
   * iterator in a flat format.
   */
  pullStateFrom(Iterator stream);
}

/**
 * This rule handles things that implement List. It will recreate them as
 * whatever the default implemenation of List is on the target platform.
 */
class ListRule extends SerializationRule {

  appliesTo(object) => object is List;

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
    var dataLength = stream.next();
    var ruleData = new List();
    for (var i = 0; i < dataLength; i++) {
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
    appliesTo(object) {
    return isPrimitive(object);
  }
  extractState(object, Function f) => object;
  void flatten(object, Writer writer) {}
  inflateEssential(state, Reader r) => state;
  inflateNonEssential(object, _, Reader r) {}

  /** Indicate whether we should save pointers to this object as references
   * or store the object directly. For primitives this depends on the format,
   * so we delegate to the writer.
   */
  bool shouldUseReferenceFor(Object o, Writer w) =>
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
    var dataLength = stream.next();
    var ruleData = new List();
    for (var i = 0; i < dataLength; i++) {
      ruleData.add(stream.next());
    }
    return ruleData;
  }
}

/** Helper function for PrimitiveRule to tell which objects it applies to. */
bool isPrimitive(Object object) {
  return object is num || object is String || object is bool;
}

/** Typedef for the object construction closure used in ClosureToMapRule. */
typedef Object ConstructType(Map m);

/** Typedef for the state-getting closure used in ClosureToMapRule. */
typedef Map<String, Object> GetStateType(Object o);

/** Typedef for the state-setting closure used in ClosureToMapRule. */
typedef void NonEssentialStateType(Object o, Map m);

/**
 * This is a rule where the extraction and creation are hard-coded as
 * closures. The result is expected to be a map indexed by field name.
 */
class ClosureToMapRule extends SerializationRule {

  /** The runtimeType of objects that this rule applies to. Used in appliesTo.*/
  final Type type;

  /** The function for constructing new objects when reading. */
  ConstructType construct;

  /** The function for returning an object's state as a Map. */
  GetStateType getState;

  /** The function for setting an object's state from a Map. */
  NonEssentialStateType setNonEssentialState;

  /**
   * Create a ClosureToMapRule for the given [type] which gets an object's
   * state by calling [getState], creates a new object by calling [construct]
   * and sets the new object's state by calling [setNonEssentialState].
   */
  ClosureToMapRule(this.type, this.getState, this.construct,
      this.setNonEssentialState);

  /**
   * If we deserialize a ClosureToMapRule we can't actually use it, because
   * we don't have the closures, so generate a stub that just returns the
   * raw state object.
   */
  ClosureToMapRule.stub(this.type) {
    getState = (x) { throw new SerializationException(
        'Closures cannot be serialized'); };
    construct = (state) => state;
    setNonEssentialState = (object, state) {};
  }

  bool appliesTo(object) => object.runtimeType == type;

  extractState(object, Function f) {
    Map state = getState(object);
    values(state).forEach(f);
    return state;
  }

  // TODO(alanknight): We're inflating twice here. How to avoid doing
  // that without giving the user even more stuff to specify.
  // Worse than that, by inflating everything in advance, we are are
  // forcing all the state to be essential.
  Object inflateEssential(Map<String, Object> state, Reader r) {
    var inflated = values(state).map((x) => r.inflateReference(x));
    return construct(inflated);
  }

  void inflateNonEssential(state, object, Reader r) {
    if (setNonEssentialState == null) return;
    var inflated = values(state).map((x) => r.inflateReference(x));
    setNonEssentialState(inflated, object);
  }
}

/**
 * This rule handles things we can't pass directly, but only by reference.
 * It extracts an identifier we can use to pass them.
 */
class ClassMirrorRule extends SerializationRule {
  // TODO(alanknight): This probably generalizes to any named object.
  bool appliesTo(object) {
    return object is ClassMirror;
  }
  extractState(object, Function f) => f(object.simpleName);
  void flatten(object, Writer writer) {}
  inflateEssential(state, Reader r) => r.externalObjectNamed(state);
  inflateNonEssential(state, object, Reader r) {}
}