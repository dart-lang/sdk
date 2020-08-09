import 'dart:collection';
import 'dart:core';

main() {
  // Set
  print(globalSet);
  print(identitySet);
  print(linkedSet);
  print(linkedIdentitySet);
  print(linkedCustomSet);
  // Map
  print(globalMap);
  print(globalMapLiteral);
  print(identityMap);
  print(unmodifiableMap);
  print(linkedMap);
  print(linkedIdentityMap);
  print(linkedCustomMap);
}

Set globalSet = Set();
Set identitySet = Set.identity();
Set<String> linkedSet = new LinkedHashSet<String>();
Set<String> linkedIdentitySet =
    new LinkedHashSet<String>(equals: identical, hashCode: identityHashCode);
Set<String> linkedCustomSet = new LinkedHashSet<String>(
    equals: (a, b) => a == b,
    hashCode: (o) => o.hashCode,
    isValidKey: (o) => true);

Map globalMap = Map();
Map identityMap = Map.identity();
Map unmodifiableMap = Map.unmodifiable(identityMap);
Map globalMapLiteral = {};
Map<String, String> linkedMap = new LinkedHashMap<String, String>();
Map<String, String> linkedIdentityMap =
    new LinkedHashMap(equals: identical, hashCode: identityHashCode);
Map<String, String> linkedCustomMap = new LinkedHashMap(
    equals: (a, b) => a == b,
    hashCode: (o) => o.hashCode,
    isValidKey: (o) => true);
