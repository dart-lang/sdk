// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization_test_helper;

import 'dart:collection';
import 'package:compiler/src/common/resolution.dart';
import 'package:compiler/src/constants/expressions.dart';
import 'package:compiler/src/constants/values.dart';
import 'package:compiler/src/dart_types.dart';
import 'package:compiler/src/compiler.dart';
import 'package:compiler/src/elements/elements.dart';
import 'package:compiler/src/serialization/equivalence.dart';
import 'package:compiler/src/tree/nodes.dart';
import 'package:expect/expect.dart';
import 'test_data.dart';

Check currentCheck;

class Check {
  final Check parent;
  final Object object1;
  final Object object2;
  final String property;
  final Object value1;
  final Object value2;

  Check(this.parent, this.object1, this.object2, this.property, this.value1, this.value2);

  String printOn(StringBuffer sb, String indent) {
    if (parent != null) {
      indent = parent.printOn(sb, indent);
      sb.write('\n$indent|\n');
    }
    sb.write("${indent}property='$property'\n ");
    sb.write("${indent}object1=$object1 (${object1.runtimeType})\n ");
    sb.write("${indent}value=${value1 == null ? "null" : "'$value1'"} ");
    sb.write("(${value1.runtimeType}) vs\n ");
    sb.write("${indent}object2=$object2 (${object2.runtimeType})\n ");
    sb.write("${indent}value=${value2 == null ? "null" : "'$value2'"} ");
    sb.write("(${value2.runtimeType})");
    return ' $indent';
  }

  String toString() {
    StringBuffer sb = new StringBuffer();
    printOn(sb, '');
    return sb.toString();
  }
}

/// Strategy for checking equivalence.
///
/// Use this strategy to fail early with contextual information in the event of
/// inequivalence.
class CheckStrategy implements TestStrategy {
  const CheckStrategy();

  @override
  bool test(var object1, var object2, String property, var value1, var value2,
            [bool equivalence(a, b) = equality]) {
    return check(object1, object2, property, value1, value2, equivalence);
  }

  @override
  bool testLists(
      Object object1, Object object2, String property,
      List list1, List list2,
      [bool elementEquivalence(a, b) = equality]) {
    return checkListEquivalence(
        object1, object2, property, list1, list2,
        (o1, o2, p, v1, v2) {
          if (!elementEquivalence(v1, v2)) {
            throw "$o1.$p = '${v1}' <> "
                  "$o2.$p = '${v2}'";
          }
          return true;
        });
  }

  @override
  bool testSets(
      var object1, var object2, String property,
      Iterable set1, Iterable set2,
      [bool elementEquivalence(a, b) = equality]) {
    return checkSetEquivalence(
        object1, object2,property, set1, set2, elementEquivalence);
  }

  @override
  bool testMaps(
      var object1, var object2, String property, Map map1, Map map2,
      [bool keyEquivalence(a, b) = equality,
      bool valueEquivalence(a, b) = equality]) {
    return checkMapEquivalence(object1, object2, property,
        map1, map2, keyEquivalence, valueEquivalence);
  }

  @override
  bool testElements(
      Object object1, Object object2, String property,
      Element element1, Element element2) {
    return checkElementIdentities(
        object1, object2, property, element1, element2);
  }

  @override
  bool testTypes(
      Object object1, Object object2, String property,
      DartType type1, DartType type2) {
    return checkTypes(object1, object2, property, type1, type2);
  }

  @override
  bool testConstants(
      Object object1, Object object2, String property,
      ConstantExpression exp1, ConstantExpression exp2) {
    return checkConstants(object1, object2, property, exp1, exp2);
  }

  @override
  bool testConstantValues(Object object1, Object object2, String property,
      ConstantValue value1, ConstantValue value2) {
    return areConstantValuesEquivalent(value1, value2);
  }

  @override
  bool testTypeLists(
      Object object1, Object object2, String property,
      List<DartType> list1, List<DartType> list2) {
    return checkTypeLists(object1, object2, property, list1, list2);
  }

  @override
  bool testConstantLists(
      Object object1, Object object2, String property,
      List<ConstantExpression> list1,
      List<ConstantExpression> list2) {
    return checkConstantLists(object1, object2, property, list1, list2);
  }

  @override
  bool testConstantValueLists(Object object1, Object object2, String property,
      List<ConstantValue> list1, List<ConstantValue> list2) {
    return checkConstantValueLists(object1, object2, property, list1, list2);
  }

  @override
  bool testNodes(Object object1, Object object2, String property,
      Node node1, Node node2) {
    return new NodeEquivalenceVisitor(this).testNodes(
        object1, object2, property, node1, node2);
  }
}

/// Check that the values [property] of [object1] and [object2], [value1] and
/// [value2] respectively, are equal and throw otherwise.
bool check(var object1, var object2, String property, var value1, var value2,
           [bool equivalence(a, b) = equality]) {
  currentCheck = new Check(
      currentCheck, object1, object2, property, value1, value2);
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
bool checkListEquivalence(
    Object object1, Object object2, String property,
    Iterable list1, Iterable list2,
    void checkEquivalence(o1, o2, property, a, b)) {
  currentCheck =
      new Check(currentCheck, object1, object2, property, list1, list2);
  for (int i = 0; i < list1.length && i < list2.length; i++) {
    checkEquivalence(
        object1, object2, property,
        list1.elementAt(i), list2.elementAt(i));
  }
  for (int i = list1.length; i < list2.length; i++) {
    throw
        'Missing equivalent for element '
        '#$i ${list2.elementAt(i)} in `${property}` on $object2.\n'
        '`${property}` on $object1:\n ${list1.join('\n ')}\n'
        '`${property}` on $object2:\n ${list2.join('\n ')}';
  }
  for (int i = list2.length; i < list1.length; i++) {
    throw
        'Missing equivalent for element '
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
Set computeSetDifference(
    Iterable set1,
    Iterable set2,
    List<List> common,
    List unfound,
    {bool sameElement(a, b): equality,
     void checkElements(a, b)}) {
  // TODO(johnniwinther): Avoid the quadratic cost here. Some ideas:
  // - convert each set to a list and sort it first, then compare by walking
  // both lists in parallel
  // - map each element to a canonical object, create a map containing those
  // mappings, use the mapped sets to compare (then operations like
  // set.difference would work)
  Set remaining = set2.toSet();
  for (var element1 in set1) {
    var correspondingElement;
    for (var element2 in remaining) {
      if (sameElement(element1, element2)) {
        if (checkElements != null) {
          checkElements(element1, element2);
        }
        correspondingElement = element2;
        remaining.remove(element2);
        break;
      }
    }
    if (correspondingElement != null) {
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
bool checkSetEquivalence(
    var object1,
    var object2,
    String property,
    Iterable set1,
    Iterable set2,
    bool sameElement(a, b),
    {void onSameElement(a, b)}) {
  List<List> common = <List>[];
  List unfound = [];
  Set remaining =
      computeSetDifference(set1, set2, common, unfound,
          sameElement: sameElement, checkElements: onSameElement);
  if (unfound.isNotEmpty || remaining.isNotEmpty) {
    String message =
        "Set mismatch for `$property` on $object1 vs $object2: \n"
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
bool checkMapEquivalence(
    var object1,
    var object2,
    String property,
    Map map1,
    Map map2,
    bool sameKey(a, b),
    bool sameValue(a, b)) {
  List<List> common = <List>[];
  List unfound = [];
  Set remaining =
      computeSetDifference(map1.keys, map2.keys, common, unfound,
          sameElement: sameKey);
  if (unfound.isNotEmpty || remaining.isNotEmpty) {
    String message =
        "Map key mismatch for `$property` on $object1 vs $object2: \n"
        "Common:\n ${common.join('\n ')}\n"
        "Unfound:\n ${unfound.join('\n ')}\n"
        "Extra: \n ${remaining.join('\n ')}";
    throw message;
  }
  for (List pair in common) {
    check(object1, object2, 'Map value for `$property`',
        map1[pair[0]], map2[pair[1]], sameValue);
  }
  return true;
}

/// Checks the equivalence of the identity (but not properties) of [element1]
/// and [element2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkElementIdentities(
    Object object1, Object object2, String property,
    Element element1, Element element2) {
  if (identical(element1, element2)) return true;
  return check(object1, object2,
      property, element1, element2, areElementsEquivalent);
}

/// Checks the pair-wise equivalence of the identity (but not properties) of the
/// elements in [list] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkElementListIdentities(
    Object object1, Object object2, String property,
    Iterable<Element> list1, Iterable<Element> list2) {
  return checkListEquivalence(
      object1, object2, property,
      list1, list2, checkElementIdentities);
}

/// Checks the equivalence of [type1] and [type2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkTypes(
    Object object1, Object object2, String property,
    DartType type1, DartType type2) {
  if (identical(type1, type2)) return true;
  if (type1 == null || type2 == null) {
    return check(object1, object2, property, type1, type2);
  } else {
    return check(object1, object2, property, type1, type2,
        (a, b) => const TypeEquivalence(const CheckStrategy()).visit(a, b));
  }
}

/// Checks the pair-wise equivalence of the types in [list1] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkTypeLists(
    Object object1, Object object2, String property,
    List<DartType> list1, List<DartType> list2) {
  return checkListEquivalence(
      object1, object2, property, list1, list2, checkTypes);
}

/// Checks the equivalence of [exp1] and [exp2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkConstants(
    Object object1, Object object2, String property,
    ConstantExpression exp1, ConstantExpression exp2) {
  if (identical(exp1, exp2)) return true;
  if (exp1 == null || exp2 == null) {
    return check(object1, object2, property, exp1, exp2);
  } else {
    return check(object1, object2, property, exp1, exp2,
        (a, b) => const ConstantEquivalence(const CheckStrategy()).visit(a, b));
  }
}

/// Checks the equivalence of [value1] and [value2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkConstantValues(
    Object object1, Object object2, String property,
    ConstantValue value1, ConstantValue value2) {
  if (identical(value1, value2)) return true;
  if (value1 == null || value2 == null) {
    return check(object1, object2, property, value1, value2);
  } else {
    return check(object1, object2, property, value1, value2,
        (a, b) => const ConstantValueEquivalence(
            const CheckStrategy()).visit(a, b));
  }
}

/// Checks the pair-wise equivalence of the constants in [list1] and [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkConstantLists(
    Object object1, Object object2, String property,
    List<ConstantExpression> list1,
    List<ConstantExpression> list2) {
  return checkListEquivalence(
      object1, object2, property,
      list1, list2, checkConstants);
}

/// Checks the pair-wise equivalence of the constants values in [list1] and
/// [list2].
///
/// Uses [object1], [object2] and [property] to provide context for failures.
bool checkConstantValueLists(
    Object object1, Object object2, String property,
    List<ConstantValue> list1,
    List<ConstantValue> list2) {
  return checkListEquivalence(
      object1, object2, property,
      list1, list2, checkConstantValues);
}

/// Check member property equivalence between all members common to [compiler1]
/// and [compiler2].
void checkLoadedLibraryMembers(
    Compiler compiler1,
    Compiler compiler2,
    bool hasProperty(Element member1),
    void checkMemberProperties(Compiler compiler1, Element member1,
                               Compiler compiler2, Element member2,
                               {bool verbose}),
    {bool verbose: false}) {

  void checkMembers(Element member1, Element member2) {
    if (member1.isClass && member2.isClass) {
      ClassElement class1 = member1;
      ClassElement class2 = member2;
      if (!class1.isResolved) return;

      if (hasProperty(member1)) {
        if (areElementsEquivalent(member1, member2)) {
          checkMemberProperties(
              compiler1, member1,
              compiler2, member2,
              verbose: verbose);
        }
      }

      class1.forEachLocalMember((m1) {
        checkMembers(m1, class2.localLookup(m1.name));
      });
      ClassElement superclass1 = class1.superclass;
      ClassElement superclass2 = class2.superclass;
      while (superclass1 != null && superclass1.isUnnamedMixinApplication) {
        for (ConstructorElement c1 in superclass1.constructors) {
          checkMembers(c1, superclass2.lookupConstructor(c1.name));
        }
        superclass1 = superclass1.superclass;
        superclass2 = superclass2.superclass;
      }
      return;
    }

    if (!hasProperty(member1)) {
      return;
    }

    if (member2 == null) {
      throw 'Missing member for ${member1}';
    }

    if (areElementsEquivalent(member1, member2)) {
      checkMemberProperties(
          compiler1, member1,
          compiler2, member2,
          verbose: verbose);
    }
  }

  for (LibraryElement library1 in compiler1.libraryLoader.libraries) {
    LibraryElement library2 =
        compiler2.libraryLoader.lookupLibrary(library1.canonicalUri);
    if (library2 != null) {
      library1.forEachLocalMember((Element member1) {
        checkMembers(member1, library2.localLookup(member1.name));
      });

    }
  }
}

/// Check equivalence of all resolution impacts.
void checkAllImpacts(
    Compiler compiler1,
    Compiler compiler2,
    {bool verbose: false}) {
  checkLoadedLibraryMembers(
      compiler1,
      compiler2,
      (Element member1) {
        return compiler1.resolution.hasResolutionImpact(member1);
      },
      checkImpacts,
      verbose: verbose);
}

/// Check equivalence of resolution impact for [member1] and [member2].
void checkImpacts(Compiler compiler1, Element member1,
                  Compiler compiler2, Element member2,
                  {bool verbose: false}) {
  ResolutionImpact impact1 = compiler1.resolution.getResolutionImpact(member1);
  ResolutionImpact impact2 = compiler2.resolution.getResolutionImpact(member2);

  if (impact1 == null && impact2 == null) return;

  if (verbose) {
    print('Checking impacts for $member1 vs $member2');
  }

  if (impact1 == null) {
    throw 'Missing impact for $member1. $member2 has $impact2';
  }
  if (impact2 == null) {
    throw 'Missing impact for $member2. $member1 has $impact1';
  }

  testResolutionImpactEquivalence(impact1, impact2, const CheckStrategy());
}

void checkSets(
    Iterable set1,
    Iterable set2,
    String messagePrefix,
    bool sameElement(a, b),
    {bool failOnUnfound: true,
    bool failOnExtra: true,
    bool verbose: false,
    void onSameElement(a, b),
    void onUnfoundElement(a),
    void onExtraElement(b),
    String elementToString(key): defaultToString}) {
  List<List> common = <List>[];
  List unfound = [];
  Set remaining = computeSetDifference(
      set1, set2, common, unfound,
      sameElement: sameElement,
      checkElements: onSameElement);
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

void checkMaps(
    Map map1,
    Map map2,
    String messagePrefix,
    bool sameKey(a, b),
    bool sameValue(a, b),
    {bool failOnUnfound: true,
    bool failOnMismatch: true,
    bool verbose: false,
    String keyToString(key): defaultToString,
    String valueToString(key): defaultToString}) {
  List<List> common = <List>[];
  List unfound = [];
  List<List> mismatch = <List>[];
  Set remaining = computeSetDifference(
      map1.keys, map2.keys, common, unfound,
      sameElement: sameKey,
      checkElements: (k1, k2) {
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

void checkAllResolvedAsts(
    Compiler compiler1,
    Compiler compiler2,
    {bool verbose: false}) {
  checkLoadedLibraryMembers(
      compiler1,
      compiler2,
      (Element member1) {
        return member1 is ExecutableElement &&
            compiler1.resolution.hasResolvedAst(member1);
      },
      checkResolvedAsts,
      verbose: verbose);
}


/// Check equivalence of [impact1] and [impact2].
void checkResolvedAsts(Compiler compiler1, Element member1,
    Compiler compiler2, Element member2,
    {bool verbose: false}) {
  if (!compiler2.serialization.isDeserialized(member2)) {
    return;
  }
  ResolvedAst resolvedAst1 = compiler1.resolution.getResolvedAst(member1);
  ResolvedAst resolvedAst2 = compiler2.serialization.getResolvedAst(member2);

  if (resolvedAst1 == null || resolvedAst2 == null) return;

  if (verbose) {
    print('Checking resolved asts for $member1 vs $member2');
  }

  testResolvedAstEquivalence(
      resolvedAst1, resolvedAst2, const CheckStrategy());
}

/// Returns the test arguments for testing the [index]th skipped test. The
/// [skip] count is used to check that [index] is a valid index.
List<String> testSkipped(int index, int skip) {
  if (index < 0 || index >= skip) {
    throw new ArgumentError('Invalid skip index $index');
  }
  return ['${index}', '${index + 1}'];
}

/// Return the test arguments for testing the [index]th segment (1-based) of
/// the [TESTS] split into [count] groups. The first [skip] tests are excluded
/// from the automatic grouping.
List<String> testSegment(int index, int count, int skip) {
  if (index < 0 || index > count) {
    throw new ArgumentError('Invalid segment index $index');
  }

  String segmentNumber(int i) {
    return '${skip + i * (TESTS.length - skip) ~/ count}';
  }

  if (index == 1 && skip != 0) {
    return ['${skip}', segmentNumber(index)];
  } else if (index  == count) {
    return [segmentNumber(index - 1)];
  } else {
    return [segmentNumber(index - 1), segmentNumber(index)];
  }
}
