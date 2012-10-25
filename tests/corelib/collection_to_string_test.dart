// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Tests for the toString methods on collections and maps.
 */

#library('collection_to_string');
#import('dart:math', prefix: 'Math');

// TODO(jjb): seed random number generator when API allows it

const int NUM_TESTS = 300;
const int MAX_COLLECTION_SIZE = 7;

Math.Random rand;

main() {
  rand = new Math.Random();
  smokeTest();
  exactTest();
  inexactTest();
}


/**
 * Test a few simple examples.
 */
void smokeTest() {
  // Non-const lists
  Expect.equals([].toString(), '[]');
  Expect.equals([1].toString(), '[1]');
  Expect.equals(['Elvis'].toString(), '[Elvis]');
  Expect.equals([null].toString(), '[null]');
  Expect.equals([1, 2].toString(), '[1, 2]');
  Expect.equals(['I', 'II'].toString(), '[I, II]');
  Expect.equals([[1, 2], [3, 4], [5, 6]].toString(), '[[1, 2], [3, 4], [5, 6]]');

  // Const lists
  Expect.equals((const[]).toString(), '[]');
  Expect.equals((const[1]).toString(), '[1]');
  Expect.equals((const['Elvis']).toString(), '[Elvis]');
  Expect.equals((const[null]).toString(), '[null]');
  Expect.equals((const[1, 2]).toString(), '[1, 2]');
  Expect.equals((const['I', 'II']).toString(), '[I, II]');
  Expect.equals((const[const[1, 2], const[3, 4], const[5, 6]]).toString(),
      '[[1, 2], [3, 4], [5, 6]]');

  // Non-const maps - Note that all keys are strings; the spec currently demands this
  Expect.equals({}.toString(), '{}');
  Expect.equals({'Elvis': 'King'}.toString(), '{Elvis: King}');
  Expect.equals({'Elvis': null}.toString(), '{Elvis: null}');
  Expect.equals({'I': 1, 'II': 2}.toString(), '{I: 1, II: 2}');
  Expect.equals({'X':{'I':1, 'II':2}, 'Y':{'III':3, 'IV':4}, 'Z':{'V':5, 'VI':6}}.toString(),
      '{X: {I: 1, II: 2}, Y: {III: 3, IV: 4}, Z: {V: 5, VI: 6}}');

  // Const maps
  Expect.equals(const{}.toString(), '{}');
  Expect.equals(const{'Elvis': 'King'}.toString(), '{Elvis: King}');
  Expect.equals({'Elvis': null}.toString(), '{Elvis: null}');
  Expect.equals(const{'I': 1, 'II': 2}.toString(), '{I: 1, II: 2}');
  Expect.equals(const{'X': const{'I': 1, 'II': 2}, 'Y': const{'III': 3, 'IV': 4},
      'Z': const{'V': 5, 'VI': 6}}.toString(),
      '{X: {I: 1, II: 2}, Y: {III: 3, IV: 4}, Z: {V: 5, VI: 6}}');
}

// SERIOUS "BASHER" TESTS

/**
 * Generate a bunch of random collections (including Maps), and test that
 * there string form is as expected. The collections include collections
 * as elements, keys, and values, and include recursive references.
 *
 * This test restricts itself to collections with well-defined iteration
 * orders (i.e., no HashSet, HashMap).
 */
void exactTest() {
  for (int i = 0; i < NUM_TESTS; i++) {
    // Choose a size from 0 to MAX_COLLECTION_SIZE, favoring larger sizes
    int size = Math.sqrt(random(MAX_COLLECTION_SIZE * MAX_COLLECTION_SIZE)).toInt();

    StringBuffer stringRep = new StringBuffer();
    Object o = randomCollection(size, stringRep, exact:true);
    Expect.equals(o.toString(), stringRep.toString());
  }
}

/**
 * Generate a bunch of random collections (including Maps), and test that
 * there string form is as expected. The collections include collections
 * as elements, keys, and values, and include recursive references.
 *
 * This test includes collections with ill-defined iteration orders (i.e.,
 * HashSet, HashMap). As a consequence, it can't use equality tests on the
 * string form. Instead, it performs equality tests on their "alphagrams."
 * This might allow false positives, but it does give a fair amount of
 * confidence.
 */
void inexactTest() {
  for (int i = 0; i < NUM_TESTS; i++) {
    // Choose a size from 0 to MAX_COLLECTION_SIZE, favoring larger sizes
    int size = Math.sqrt(random(MAX_COLLECTION_SIZE * MAX_COLLECTION_SIZE)).toInt();

    StringBuffer stringRep = new StringBuffer();
    Object o = randomCollection(size, stringRep, exact:false);
    Expect.equals(alphagram(o.toString()), alphagram(stringRep.toString()));
  }
}

/**
 * Return a random collection (or Map) of the specified size, placing its
 * string representation into the given string buffer.
 *
 * If exact is true, the returned collections will not be, and will not contain
 * a collection with ill-defined iteration order (i.e., a HashSet or HashMap).
 */
Object randomCollection(int size, StringBuffer stringRep, {bool exact}) {
  return randomCollectionHelper(size, exact, stringRep, []);
}

/**
 * Return a random collection (or map) of the specified size, placing its
 * string representation into the given string buffer. The beingMade
 * parameter is a list of collections currently under construction, i.e.,
 * candidates for recursive references.
 *
 * If exact is true, the returned collections will not be, and will not contain
 * a collection with ill-defined iteration order (i.e., a HashSet or HashMap).
 */
Object randomCollectionHelper(int size, bool exact, StringBuffer stringRep,
    List beingMade) {
  double interfaceFrac = rand.nextDouble();

  if (exact) {
    if (interfaceFrac < 1/3) {
      return randomList(size, exact, stringRep, beingMade);
    } else if (interfaceFrac < 2/3) {
      return randomQueue(size, exact, stringRep, beingMade);
    } else {
      return randomMap(size, exact, stringRep, beingMade);
    }
  } else {
    if (interfaceFrac < 1/4) {
      return randomList(size, exact, stringRep, beingMade);
    } else if (interfaceFrac < 2/4) {
      return randomQueue(size, exact, stringRep, beingMade);
    } else if (interfaceFrac < 3/4) {
      return randomSet(size, exact, stringRep, beingMade);
    } else {
      return randomMap(size, exact, stringRep, beingMade);
    }
  }
}

/**
 * Return a random List of the specified size, placing its string
 * representation into the given string buffer. The beingMade
 * parameter is a list of collections currently under construction, i.e.,
 * candidates for recursive references.
 *
 * If exact is true, the returned collections will not be, and will not contain
 * a collection with ill-defined iteration order (i.e., a HashSet or HashMap).
 */
List randomList(int size, bool exact, StringBuffer stringRep, List beingMade) {
  return populateRandomCollection(size, exact, stringRep, beingMade, []);
}

/**
 * Like randomList, but returns a queue.
 */
Queue randomQueue(int size, bool exact, StringBuffer stringRep, List beingMade){
  return populateRandomCollection(size, exact, stringRep, beingMade, new Queue());
}

/**
 * Like randomList, but returns a Set.
 */
Set randomSet(int size, bool exact, StringBuffer stringRep, List beingMade) {
  // Until we have LinkedHashSet, method will only be called with exact==true
  return populateRandomSet(size, exact, stringRep, beingMade, new Set());
}

/**
 * Like randomList, but returns a map.
 */
Map randomMap(int size, bool exact, StringBuffer stringRep, List beingMade) {
  if (exact) {
    return populateRandomMap(size, exact, stringRep, beingMade,
        new LinkedHashMap());
  } else {
    return populateRandomMap(size, exact, stringRep, beingMade,
        randomBool() ? new Map() : new LinkedHashMap());
  }
}

/**
 * Populates the given empty collection with elements, emitting the string
 * representation of the collection to stringRep.  The beingMade parameter is
 * a list of collections currently under construction, i.e., candidates for
 * recursive references.
 *
 * If exact is true, the elements of the returned collections will not be,
 * and will not contain a collection with ill-defined iteration order
 * (i.e., a HashSet or HashMap).
 */
Collection populateRandomCollection(int size, bool exact,
    StringBuffer stringRep, List beingMade, Collection coll) {
  beingMade.add(coll);
  stringRep.add(coll is List ? '[' : '{');

  for (int i = 0; i < size; i++) {
    if (i != 0) stringRep.add(', ');
    coll.add(randomElement(random(size), exact, stringRep, beingMade));
  }

  stringRep.add(coll is List ? ']' : '}');
  beingMade.removeLast();
  return coll;
}

/** Like populateRandomCollection, but for sets (elements must be hashable) */
Set populateRandomSet(int size, bool exact, StringBuffer stringRep,
    List beingMade, Set set) {
  stringRep.add('{');

  for (int i = 0; i < size; i++) {
    if (i != 0) stringRep.add(', ');
    set.add(i);
    stringRep.add(i);
  }

  stringRep.add('}');
  return set;
}


/** Like populateRandomCollection, but for maps. */
Map populateRandomMap(int size, bool exact, StringBuffer stringRep,
    List beingMade, Map map) {
  beingMade.add(map);
  stringRep.add('{');

  for (int i = 0; i < size; i++) {
    if (i != 0) stringRep.add(', ');

    int key = i; // Ensures no duplicates
    stringRep.add(key);
    stringRep.add(': ');
    Object val = randomElement(random(size), exact, stringRep, beingMade);
    map[key] = val;
  }

  stringRep.add('}');
  beingMade.removeLast();
  return map;
}

/**
 * Generates a random element which can be an int, a collection, or a map,
 * and emits it to StringRep. The beingMade parameter is a list of collections
 * currently under construction, i.e., candidates for recursive references.
 *
 * If exact is true, the returned element will not be, and will not contain
 * a collection with ill-defined iteration order (i.e., a HashSet or HashMap).
 */
Object randomElement(int size, bool exact, StringBuffer stringRep,
    List beingMade) {
  Object result;
  double elementTypeFrac = rand.nextDouble();
  if (elementTypeFrac < 1/3) {
    result = random(1000);
    stringRep.add(result);
  } else if (elementTypeFrac < 2/3) {
    // Element Is a random (new) collection
    result = randomCollectionHelper(size, exact, stringRep, beingMade);
  } else {
    // Element Is a random recursive ref
    result = beingMade[random(beingMade.length)];
    if (result is List)
      stringRep.add('[...]');
    else
      stringRep.add('{...}');
  }
  return result;
}

/** Returns a random int on [0, max) */
int random(int max) {
  return rand.nextInt(max);
}

/** Returns a random boolean value. */
bool randomBool() {
  return rand.nextBool();
}

/** Returns the alphabetized characters in a string. */
String alphagram(String s) {
  List<int> chars = s.charCodes;
  chars.sort((int a, int b) => a - b);
  return new String.fromCharCodes(chars);
}
