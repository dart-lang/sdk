// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// @dart = 2.7

/// General equivalence test functions.

library dart2js.equivalence.helpers;

import 'package:compiler/src/elements/types.dart';
import 'package:expect/expect.dart';

Check currentCheck;

class Check {
  final Check parent;
  final Object object1;
  final Object object2;
  final String property;
  final Object value1;
  final Object value2;
  final Function toStringFunc;

  Check(this.parent, this.object1, this.object2, this.property, this.value1,
      this.value2,
      [this.toStringFunc]);

  String printOn(StringBuffer sb, String indent) {
    if (parent != null) {
      indent = parent.printOn(sb, indent);
      sb.write('\n$indent|\n');
    }
    sb.write("${indent}property='$property'\n ");
    sb.write("${indent}object1=$object1 (${object1.runtimeType})\n ");
    sb.write("${indent}value=");
    if (value1 == null) {
      sb.write("null");
    } else if (toStringFunc != null) {
      sb.write(toStringFunc(value1));
    } else {
      sb.write("'$value1'");
    }
    sb.write(" (${value1.runtimeType}) vs\n ");
    sb.write("${indent}object2=$object2 (${object2.runtimeType})\n ");
    sb.write("${indent}value=");
    if (value2 == null) {
      sb.write("null");
    } else if (toStringFunc != null) {
      sb.write(toStringFunc(value2));
    } else {
      sb.write("'$value2'");
    }
    sb.write(" (${value2.runtimeType})");
    return ' $indent';
  }

  @override
  String toString() {
    StringBuffer sb = new StringBuffer();
    printOn(sb, '');
    return sb.toString();
  }
}

/// Equality based equivalence function.
bool equality(a, b) => a == b;

/// Check that the values [property] of [object1] and [object2], [value1] and
/// [value2] respectively, are equal and throw otherwise.
bool check<T>(var object1, var object2, String property, T value1, T value2,
    [bool equivalence(T a, T b) = equality, String toString(T a)]) {
  currentCheck = new Check(
      currentCheck, object1, object2, property, value1, value2, toString);
  if (!equivalence(value1, value2)) {
    throw currentCheck;
  }
  currentCheck = currentCheck.parent;
  return true;
}

/// Check equivalence of the two lists, [list1] and [list2], using
/// [checkEquivalence] to check the pair-wise equivalence.
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkListEquivalence<T>(
    Object object1,
    Object object2,
    String property,
    Iterable<T> list1,
    Iterable<T> list2,
    void checkEquivalence(Object o1, Object o2, String property, T a, T b)) {
  currentCheck =
      new Check(currentCheck, object1, object2, property, list1, list2);
  for (int i = 0; i < list1.length && i < list2.length; i++) {
    checkEquivalence(
        object1, object2, property, list1.elementAt(i), list2.elementAt(i));
  }
  for (int i = list1.length; i < list2.length; i++) {
    throw 'Missing equivalent for element '
        '#$i ${list2.elementAt(i)} in `${property}` on $object2.\n'
        '`${property}` on $object1:\n ${list1.join('\n ')}\n'
        '`${property}` on $object2:\n ${list2.join('\n ')}';
  }
  for (int i = list2.length; i < list1.length; i++) {
    throw 'Missing equivalent for element '
        '#$i ${list1.elementAt(i)} in `${property}` on $object1.\n'
        '`${property}` on $object1:\n ${list1.join('\n ')}\n'
        '`${property}` on $object2:\n ${list2.join('\n ')}';
  }
  currentCheck = currentCheck.parent;
  return true;
}

/// Computes the set difference between [set1] and [set2] using
/// [elementEquivalence] to determine element equivalence.
///
/// Elements both in [set1] and [set2] are added to [common], elements in [set1]
/// but not in [set2] are added to [unfound], and the set of elements in [set2]
/// but not in [set1] are returned.
Set<E> computeSetDifference<E>(
    Iterable<E> set1, Iterable<E> set2, List<List<E>> common, List<E> unfound,
    {bool sameElement(E a, E b): equality, void checkElements(E a, E b)}) {
  // TODO(johnniwinther): Avoid the quadratic cost here. Some ideas:
  // - convert each set to a list and sort it first, then compare by walking
  // both lists in parallel
  // - map each element to a canonical object, create a map containing those
  // mappings, use the mapped sets to compare (then operations like
  // set.difference would work)
  Set remaining = set2.toSet();
  for (var element1 in set1) {
    bool found = false;
    var correspondingElement;
    for (var element2 in remaining) {
      if (sameElement(element1, element2)) {
        if (checkElements != null) {
          checkElements(element1, element2);
        }
        found = true;
        correspondingElement = element2;
        remaining.remove(element2);
        break;
      }
    }
    if (found) {
      common.add([element1, correspondingElement]);
    } else {
      unfound.add(element1);
    }
  }
  return remaining;
}

/// Check equivalence of the two iterables, [set1] and [set1], as sets using
/// [elementEquivalence] to compute the pair-wise equivalence.
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkSetEquivalence<E>(var object1, var object2, String property,
    Iterable<E> set1, Iterable<E> set2, bool sameElement(E a, E b),
    {void onSameElement(E a, E b)}) {
  var common = <List<E>>[];
  var unfound = <E>[];
  Set<E> remaining = computeSetDifference(set1, set2, common, unfound,
      sameElement: sameElement, checkElements: onSameElement);
  if (unfound.isNotEmpty || remaining.isNotEmpty) {
    String message = "Set mismatch for `$property` on\n"
        "$object1\n vs\n$object2:\n"
        "Common:\n ${common.join('\n ')}\n"
        "Unfound:\n ${unfound.join('\n ')}\n"
        "Extra: \n ${remaining.join('\n ')}";
    throw message;
  }
  return true;
}

/// Check equivalence of the two iterables, [set1] and [set1], as sets using
/// [elementEquivalence] to compute the pair-wise equivalence.
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkMapEquivalence<K, V>(
    var object1,
    var object2,
    String property,
    Map<K, V> map1,
    Map<K, V> map2,
    bool sameKey(K a, K b),
    bool sameValue(V a, V b),
    {bool allowExtra: false}) {
  var common = <List<K>>[];
  var unfound = <K>[];
  var extra = computeSetDifference(map1.keys, map2.keys, common, unfound,
      sameElement: sameKey);
  if (unfound.isNotEmpty || (!allowExtra && extra.isNotEmpty)) {
    String message =
        "Map key mismatch for `$property` on $object1 vs $object2: \n"
        "Common:\n ${common.join('\n ')}\n"
        "Unfound:\n ${unfound.join('\n ')}\n"
        "Extra: \n ${extra.join('\n ')}";
    throw message;
  }
  for (List pair in common) {
    check(pair[0], pair[1], 'Map value for `$property`', map1[pair[0]],
        map2[pair[1]], sameValue);
  }
  return true;
}

void checkLists<T>(List<T> list1, List<T> list2, String messagePrefix,
    bool sameElement(T a, T b),
    {bool verbose: false,
    void onSameElement(T a, T b),
    void onDifferentElements(T a, T b),
    void onUnfoundElement(T a),
    void onExtraElement(T b),
    String elementToString(key): defaultToString}) {
  List<List> common = <List>[];
  List mismatch = [];
  List unfound = [];
  List extra = [];
  int index = 0;
  while (index < list1.length && index < list2.length) {
    var element1 = list1[index];
    var element2 = list2[index];
    if (sameElement(element1, element2)) {
      if (onSameElement != null) {
        onSameElement(element1, element2);
      }
      common.add([element1, element2]);
    } else {
      if (onDifferentElements != null) {
        onDifferentElements(element1, element2);
      }
      mismatch = [element1, element2];
      break;
    }
    index++;
  }
  for (int tail = index; tail < list1.length; tail++) {
    var element1 = list1[tail];
    if (onUnfoundElement != null) {
      onUnfoundElement(element1);
    }
    unfound.add(element1);
  }
  for (int tail = index; tail < list2.length; tail++) {
    var element2 = list2[tail];
    if (onExtraElement != null) {
      onExtraElement(element2);
    }
    extra.add(element2);
  }
  StringBuffer sb = new StringBuffer();
  sb.write("$messagePrefix:");
  if (verbose) {
    sb.write("\n Common: \n");
    for (List pair in common) {
      var element1 = pair[0];
      var element2 = pair[1];
      sb.write("  [${elementToString(element1)},"
          "${elementToString(element2)}]\n");
    }
  }
  if (mismatch.isNotEmpty) {
    sb.write("\n Mismatch @ $index:\n  "
        "${mismatch.map(elementToString).join('\n  ')}");
  }

  if (unfound.isNotEmpty || verbose) {
    sb.write("\n Unfound:\n  ${unfound.map(elementToString).join('\n  ')}");
  }
  if (extra.isNotEmpty || verbose) {
    sb.write("\n Extra: \n  ${extra.map(elementToString).join('\n  ')}");
  }
  String message = sb.toString();
  if (mismatch.isNotEmpty || unfound.isNotEmpty || extra.isNotEmpty) {
    Expect.fail(message);
  } else if (verbose) {
    print(message);
  }
}

void checkSets<E>(Iterable<E> set1, Iterable<E> set2, String messagePrefix,
    bool sameElement(E a, E b),
    {bool failOnUnfound: true,
    bool failOnExtra: true,
    bool verbose: false,
    void onSameElement(E a, E b),
    void onUnfoundElement(E a),
    void onExtraElement(E b),
    bool elementFilter(E element),
    elementConverter(E element),
    String elementToString(E key): defaultToString}) {
  if (elementFilter != null) {
    set1 = set1.where(elementFilter);
    set2 = set2.where(elementFilter);
  }
  if (elementConverter != null) {
    set1 = set1.map(elementConverter);
    set2 = set2.map(elementConverter);
  }
  var common = <List<E>>[];
  var unfound = <E>[];
  var remaining = computeSetDifference(set1, set2, common, unfound,
      sameElement: sameElement, checkElements: onSameElement);
  if (onUnfoundElement != null) {
    unfound.forEach(onUnfoundElement);
  }
  if (onExtraElement != null) {
    remaining.forEach(onExtraElement);
  }
  StringBuffer sb = new StringBuffer();
  sb.write("$messagePrefix:");
  if (verbose) {
    sb.write("\n Common: \n");
    for (List pair in common) {
      var element1 = pair[0];
      var element2 = pair[1];
      sb.write("  [${elementToString(element1)},"
          "${elementToString(element2)}]\n");
    }
  }
  if (unfound.isNotEmpty || verbose) {
    sb.write("\n Unfound:\n  ${unfound.map(elementToString).join('\n  ')}");
  }
  if (remaining.isNotEmpty || verbose) {
    sb.write("\n Extra: \n  ${remaining.map(elementToString).join('\n  ')}");
  }
  String message = sb.toString();
  if (unfound.isNotEmpty || remaining.isNotEmpty) {
    if ((failOnUnfound && unfound.isNotEmpty) ||
        (failOnExtra && remaining.isNotEmpty)) {
      Expect.fail(message);
    } else {
      print(message);
    }
  } else if (verbose) {
    print(message);
  }
}

String defaultToString(obj) => '$obj';

void checkMaps<K, V>(Map<K, V> map1, Map<K, V> map2, String messagePrefix,
    bool sameKey(K a, K b), bool sameValue(V a, V b),
    {bool failOnUnfound: true,
    bool failOnMismatch: true,
    bool keyFilter(K key),
    bool verbose: false,
    String keyToString(K key): defaultToString,
    String valueToString(V key): defaultToString}) {
  var common = <List<K>>[];
  var unfound = <K>[];
  var mismatch = <List<K>>[];

  Iterable<K> keys1 = map1.keys;
  Iterable<K> keys2 = map2.keys;
  if (keyFilter != null) {
    keys1 = keys1.where(keyFilter);
    keys2 = keys2.where(keyFilter);
  }
  var remaining = computeSetDifference(keys1, keys2, common, unfound,
      sameElement: sameKey, checkElements: (k1, k2) {
    var v1 = map1[k1];
    var v2 = map2[k2];
    if (!sameValue(v1, v2)) {
      mismatch.add([k1, k2]);
    }
  });
  StringBuffer sb = new StringBuffer();
  sb.write("$messagePrefix:");
  if (verbose) {
    sb.write("\n Common: \n");
    for (List pair in common) {
      var k1 = pair[0];
      var k2 = pair[1];
      var v1 = map1[k1];
      var v2 = map2[k2];
      sb.write(" key1   =${keyToString(k1)}\n");
      sb.write(" key2   =${keyToString(k2)}\n");
      sb.write("  value1=${valueToString(v1)}\n");
      sb.write("  value2=${valueToString(v2)}\n");
    }
  }
  if (unfound.isNotEmpty || verbose) {
    sb.write("\n Unfound: \n");
    for (var k1 in unfound) {
      var v1 = map1[k1];
      sb.write(" key1   =${keyToString(k1)}\n");
      sb.write("  value1=${valueToString(v1)}\n");
    }
  }
  if (remaining.isNotEmpty || verbose) {
    sb.write("\n Extra: \n");
    for (var k2 in remaining) {
      var v2 = map2[k2];
      sb.write(" key2   =${keyToString(k2)}\n");
      sb.write("  value2=${valueToString(v2)}\n");
    }
  }
  if (mismatch.isNotEmpty || verbose) {
    sb.write("\n Mismatch: \n");
    for (List pair in mismatch) {
      var k1 = pair[0];
      var k2 = pair[1];
      var v1 = map1[k1];
      var v2 = map2[k2];
      sb.write(" key1   =${keyToString(k1)}\n");
      sb.write(" key2   =${keyToString(k2)}\n");
      sb.write("  value1=${valueToString(v1)}\n");
      sb.write("  value2=${valueToString(v2)}\n");
    }
  }
  String message = sb.toString();
  if (unfound.isNotEmpty || mismatch.isNotEmpty || remaining.isNotEmpty) {
    if ((unfound.isNotEmpty && failOnUnfound) ||
        (mismatch.isNotEmpty && failOnMismatch) ||
        remaining.isNotEmpty) {
      Expect.fail(message);
    } else {
      print(message);
    }
  } else if (verbose) {
    print(message);
  }
}

class DartTypePrinter implements DartTypeVisitor {
  StringBuffer sb = new StringBuffer();

  @override
  void visit(DartType type, [_]) {
    type.accept(this, null);
  }

  String visitTypes(List<DartType> types) {
    String comma = '';
    for (DartType type in types) {
      sb.write(comma);
      visit(type);
      comma = ',';
    }
    return comma;
  }

  @override
  void visitLegacyType(LegacyType type, _) {
    visit(type.baseType);
    sb.write('*');
  }

  @override
  void visitNullableType(NullableType type, _) {
    visit(type.baseType);
    sb.write('?');
  }

  @override
  void visitNeverType(NeverType type, _) {
    sb.write('Never');
  }

  @override
  void visitVoidType(VoidType type, _) {
    sb.write('void');
  }

  @override
  void visitDynamicType(DynamicType type, _) {
    sb.write('dynamic');
  }

  @override
  void visitErasedType(ErasedType type, _) {
    sb.write('erased');
  }

  @override
  void visitAnyType(AnyType type, _) {
    sb.write('any');
  }

  @override
  void visitInterfaceType(InterfaceType type, _) {
    sb.write(type.element.name);
    if (type.typeArguments.any((type) => type is! DynamicType)) {
      sb.write('<');
      visitTypes(type.typeArguments);
      sb.write('>');
    }
  }

  @override
  void visitFunctionType(FunctionType type, _) {
    visit(type.returnType);
    sb.write(' Function');
    if (type.typeVariables.isNotEmpty) {
      sb.write('<');
      visitTypes(type.typeVariables);
      sb.write('>');
    }
    sb.write('(');
    String comma = visitTypes(type.parameterTypes);
    if (type.optionalParameterTypes.isNotEmpty) {
      sb.write(comma);
      sb.write('[');
      visitTypes(type.optionalParameterTypes);
      sb.write(']');
    }
    if (type.namedParameters.isNotEmpty) {
      sb.write(comma);
      sb.write('{');
      for (int index = 0; index < type.namedParameters.length; index++) {
        sb.write(comma);
        sb.write(type.namedParameters[index]);
        sb.write(':');
        visit(type.namedParameterTypes[index]);
        comma = ',';
      }
      sb.write('}');
    }
    sb.write(')');
  }

  @override
  void visitFunctionTypeVariable(FunctionTypeVariable type, _) {
    sb.write(type);
  }

  @override
  void visitTypeVariableType(TypeVariableType type, _) {
    sb.write(type);
  }

  @override
  void visitFutureOrType(FutureOrType type, _) {
    sb.write('FutureOr<');
    visit(type.typeArgument);
    sb.write('>');
  }

  String getText() => sb.toString();
}

/// Normalized toString on types.
String typeToString(DartType type) {
  DartTypePrinter printer = new DartTypePrinter();
  printer.visit(type);
  return printer.getText();
}
