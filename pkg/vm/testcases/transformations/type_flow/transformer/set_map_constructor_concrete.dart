import 'dart:collection';
import 'dart:core';

main() {
  print(globalSet);
  print(globalMap);
  print(globalMapLiteral);
  print(identityMap);
  print(unmodifiableMap);
  print(linkedMap);
  print(linkedIdentityMap);
}

Set globalSet = Set();
Map globalMap = Map();
Map identityMap = Map.identity();
Map unmodifiableMap = Map.unmodifiable(identityMap);
Map globalMapLiteral = {};
Map<String, String> linkedMap = new LinkedHashMap<String, String>();
Map<String, String> linkedIdentityMap = new LinkedHashMap(equals: identical, hashCode: identityHashCode);
Map<String, String> linkedCustomMap = new LinkedHashMap(equals: (a, b) => a == b, hashCode: (o) => o.hashCode, isValidKey: (o) => true);