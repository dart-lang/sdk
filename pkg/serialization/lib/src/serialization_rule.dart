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
  void set number(int value) {
    if (_number != null && _number != value) throw
        new SerializationException("Rule numbers cannot be changed, once set");
    _number = value;
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
  extractState(object, void f(value), Writer w);

  /**
   * Allows rules to tell us how they expect to store their state. If this
   * isn't specified we can also just look at the data to tell.
   */
  bool get storesStateAsLists => false;
  bool get storesStateAsMaps => false;
  bool get storesStateAsPrimitives => false;

  /**
   * Given the variables representing the state of an object, flatten it
   * by turning object pointers into Reference objects where needed. This
   * destructively modifies the state object.
   *
   * This has a default implementation which assumes that object is indexable,
   * so either conforms to Map or List. Subclasses may override to do something
   * different, including returning a new state object to be used in place
   * of the original.
   */
  // This has to be a separate operation from extracting, because we extract
  // as we are traversing the objects, so we don't yet have the objects to
  // generate references for them. It might be possible to avoid that by
  // doing a depth-first rather than breadth-first traversal, but I'm not
  // sure it's worth it.
  flatten(state, Writer writer) {
    keysAndValues(state).forEach((key, value) {
      var reference = writer._referenceFor(value);
      state[key] = reference;
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
  bool get mustBePrimary => false;

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
  void inflateNonEssential(state, object, Reader reader);

  /**
   * If we have [object] as part of our state, should we represent that
   * directly, or should we make a reference for it. By default, true.
   * This may also delegate to [writer].
   */
  bool shouldUseReferenceFor(object, Writer writer) => true;

  /**
   * Return true if the data this rule returns is variable length, so a
   * length needs to be written for it if the format requires that. Return
   * false if the results are always the same length.
   */
  bool get hasVariableLengthEntries => true;

  /**
   * If the data is fixed length, return it here. The format may or may not
   * make use of this, depending on whether it already has enough information
   * to determine the length on its own. If [hasVariableLengthEntries] is true
   * this is ignored.
   */
  int get dataLength => 0;
}

/**
 * This rule handles things that implement List. It will recreate them as
 * whatever the default implemenation of List is on the target platform.
 */
class ListRule extends SerializationRule {

  bool appliesTo(object, Writer w) => object is List;

  bool get storesStateAsLists => true;

  List extractState(List list, f, Writer w) {
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
  void inflateNonEssential(List state, List newList, Reader r) {
    populateContents(state, newList, r);
  }

  void populateContents(List state, List newList, Reader r) {
    for(var each in state) {
      newList.add(r.inflateReference(each));
    }
  }

  bool get hasVariableLengthEntries => true;
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
  void inflateNonEssential(state, newList, reader) {}

  bool get mustBePrimary => true;
}

/**
 * This rule handles things that implement Map. It will recreate them as
 * whatever the default implemenation of Map is on the target platform. If a
 * map has string keys it will attempt to retain it as a map for JSON formats,
 * otherwise it will store it as a list of references to keys and values.
 */
class MapRule extends SerializationRule {

  bool appliesTo(object, Writer w) => object is Map;

  bool get storesStateAsMaps => true;

  extractState(Map map, f, Writer w) {
    // Note that we make a copy here because flattening may be destructive.
    var newMap = new Map.from(map);
    newMap.forEach((key, value) {
      f(key);
      f(value);
    });
    return newMap;
  }

  /**
   * Change the keys and values of [state] into references in [writer].
   * If [state] is a map whose keys are all strings then we leave the keys
   * as is so that JSON formats will be more readable. If the keys are
   * arbitrary then we need to turn them into references and replace the
   * state with a new Map whose keys are the references.
   */
  flatten(Map state, Writer writer) {
    bool keysAreAllStrings = state.keys.every((x) => x is String);
    if (keysAreAllStrings && !writer.shouldUseReferencesForPrimitives) {
      keysAndValues(state).forEach(
          (key, value) => state[key] = writer._referenceFor(value));
      return state;
    } else {
      var newState = [];
      keysAndValues(state).forEach((key, value) {
        newState.add(writer._referenceFor(key));
        newState.add(writer._referenceFor(value));
      });
      return newState;
    }
  }

  inflateEssential(state, Reader r) => new Map();

  // For a map, we consider all of its state non-essential and add it
  // after creation.
  void inflateNonEssential(state, Map newMap, Reader r) {
    if (state is List) {
      inflateNonEssentialFromList(state, newMap, r);
    } else {
      inflateNonEssentialFromMap(state, newMap, r);
    }
  }

  void inflateNonEssentialFromList(List state, Map newMap, Reader r) {
    var key;
    for (var each in state) {
      if (key == null) {
        key = each;
      } else {
        newMap[r.inflateReference(key)] = r.inflateReference(each);
        key = null;
      }
    }
  }

  void inflateNonEssentialFromMap(Map state, Map newMap, Reader r) {
    state.forEach((key, value) {
      newMap[r.inflateReference(key)] = r.inflateReference(value);
    });
  }

  bool get hasVariableLengthEntries => true;
}

/**
 * This rule handles primitive types, defined as those that we can normally
 * represent directly in the output format. We hard-code that to mean
 * num, String, and bool.
 */
class PrimitiveRule extends SerializationRule {
  bool appliesTo(object, Writer w) => isPrimitive(object);
  extractState(object, Function f, Writer w) => object;
  flatten(object, Writer writer) {}
  inflateEssential(state, Reader r) => state;
  void inflateNonEssential(object, _, Reader r) {}

  bool get storesStateAsPrimitives => true;

  /**
   * Indicate whether we should save pointers to this object as references
   * or store the object directly. For primitives this depends on the format,
   * so we delegate to the writer.
   */
  bool shouldUseReferenceFor(object, Writer w) =>
      w.shouldUseReferencesForPrimitives;

  bool get hasVariableLengthEntries => false;
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
  final ConstructType construct;

  /** The function for returning an object's state as a Map. */
  final GetStateType getStateFunction;

  /** The function for setting an object's state from a Map. */
  final NonEssentialStateType setNonEssentialState;

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

  void setState(object, state) {
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
  extractState(object, Function f, Writer writer) {
    var result = [nameFor(object, writer)];
    f(result.first);
    return result;
  }

  /** When we flatten the state we save it as the name. */
  // TODO(alanknight): This seems questionable. In a truly flat format we may
  // want to have extracted the name as a string first and flatten it into a
  // reference to that. But that requires adding the Writer as a parameter to
  // extractState, and I'm reluctant to add yet another parameter until
  // proven necessary.
  flatten(state, Writer writer) {
    state[0] = writer._referenceFor(state[0]);
  }

  /** Look up the named object and return it. */
  inflateEssential(state, Reader r) =>
      r.objectNamed(r.resolveReference(state.first));

  /** Set any non-essential state on the object. For this rule, a no-op. */
  void inflateNonEssential(state, object, Reader r) {}

  /** Return the name for this object in the Writer. */
  String nameFor(object, Writer writer) => writer.nameFor(object);
}

/**
 * This rule handles the special case of Mirrors. It stores the mirror by its
 * qualifiedName and attempts to look it up in both the namedObjects
 * collection, or if it's not found there, by looking it up in the mirror
 * system. When reading, the user is responsible for supplying the appropriate
 * values in [Serialization.namedObjects] or in the [externals] paramter to
 * [Serialization.read].
 */
class MirrorRule extends NamedObjectRule {
  bool appliesTo(object, Writer writer) => object is DeclarationMirror;

  String nameFor(DeclarationMirror object, Writer writer) =>
      MirrorSystem.getName(object.qualifiedName);

  inflateEssential(state, Reader r) {
    var qualifiedName = r.resolveReference(state.first);
    var lookupFull = r.objectNamed(qualifiedName, (x) => null);
    if (lookupFull != null) return lookupFull;
    var separatorIndex = qualifiedName.lastIndexOf(".");
    var type = qualifiedName.substring(separatorIndex + 1);
    var lookup = r.objectNamed(type, (x) => null);
    if (lookup != null) return lookup;
    var name = qualifiedName.substring(0, separatorIndex);
    // This is very ugly. The library name for an unnamed library is its URI.
    // That can't be constructed as a Symbol, so we can't use findLibrary.
    // So follow one or the other path depending if it has a colon, which we
    // assume is in any URI and can't be in a Symbol.
    if (name.contains(":")) {
      var uri = Uri.parse(name);
      var libMirror = currentMirrorSystem().libraries[uri];
      var candidate = libMirror.declarations[new Symbol(type)];
      return candidate is ClassMirror ? candidate : null;
    } else {
      var symbol = new Symbol(name);
      var typeSymbol = new Symbol(type);
      for (var libMirror in currentMirrorSystem().libraries.values) {
        if (libMirror.simpleName != symbol) continue;
        var candidate = libMirror.declarations[typeSymbol];
        if (candidate != null && candidate is ClassMirror) return candidate;
      }
      return null;
    }
  }
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

  extractState(instance, Function f, Writer w) {
    var state = getState(instance);
    for (var each in values(state)) {
      f(each);
    }
    return state;
  }

  inflateEssential(state, Reader r) => create(_lazy(state, r));

  void inflateNonEssential(state, object, Reader r) {
    setState(object, _lazy(state, r));
  }

  // We don't want to have to make the end user tell us how long the list is
  // separately, so write it out for each object, even though they're all
  // expected to be the same length.
  bool get hasVariableLengthEntries => true;
}

/** A hard-coded rule for serializing Symbols. */
class SymbolRule extends CustomRule {
  bool appliesTo(instance, _) => instance is Symbol;
  getState(instance) => [MirrorSystem.getName(instance)];
  create(state) => new Symbol(state[0]);
  void setState(symbol, state) {}
  int get dataLength => 1;
  bool get hasVariableLengthEntries => false;
}

/** A hard-coded rule for DateTime. */
class DateTimeRule extends CustomRule {
  bool appliesTo(instance, _) => instance is DateTime;
  List getState(DateTime date) => [date.millisecondsSinceEpoch, date.isUtc];
  DateTime create(List state) =>
      new DateTime.fromMillisecondsSinceEpoch(state[0], isUtc: state[1]);
  void setState(date, state) {}
  // Let the system know we don't have to store a length for these.
  int get dataLength => 2;
  bool get hasVariableLengthEntries => false;
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

  final Map _raw;
  final Reader _reader;

  // This is the only operation that really matters.
  operator [](x) => _reader.inflateReference(_raw[x]);

  int get length => _raw.length;
  bool get isEmpty => _raw.isEmpty;
  bool get isNotEmpty => _raw.isNotEmpty;
  Iterable get keys => _raw.keys;
  bool containsKey(x) => _raw.containsKey(x);

  // These operations will work, but may be expensive, and are probably
  // best avoided.
  get _inflated => mapValues(_raw, _reader.inflateReference);
  bool containsValue(x) => _inflated.containsValue(x);
  Iterable get values => _inflated.values;
  void forEach(f) => _inflated.forEach(f);

  // These operations are all invalid
  _throw() {
    throw new UnsupportedError("Not modifiable");
  }
  operator []=(x, y) => _throw();
  putIfAbsent(x, y) => _throw();
  bool remove(x) => _throw();
  void clear() => _throw();
  void addAll(Map other) => _throw();
}

/**
 * This provides an implementation of List that wraps a list which may
 * contain references to (potentially) non-inflated objects. If these
 * are accessed it will inflate them. This allows us to pass something that
 * looks like it's just a list of objects to a [CustomRule] without needing
 * to inflate all the references in advance.
 */
class _LazyList extends ListBase {
  _LazyList(this._raw, this._reader);

  final List _raw;
  final Reader _reader;

  operator [](int x) => _reader.inflateReference(_raw[x]);
  int get length => _raw.length;

  void set length(int value) => _throw();

  void operator []=(int index, value) => _throw();

  void _throw() {
    throw new UnsupportedError("Not modifiable");
  }
}
