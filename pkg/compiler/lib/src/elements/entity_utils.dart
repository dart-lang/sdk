// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library entity_utils;

import 'package:front_end/src/api_unstable/dart2js.dart'
    show isUserDefinableOperator, isMinusOperator;

import 'entities.dart';

// Somewhat stable ordering for libraries using [Uri]s
int compareLibrariesUris(Uri a, Uri b) {
  if (a == b) return 0;

  int byCanonicalUriPath() {
    return a.path.compareTo(b.path);
  }

  // Order: platform < package < other.
  if (a.scheme == 'dart') {
    if (b.scheme == 'dart') return byCanonicalUriPath();
    return -1;
  }
  if (b.scheme == 'dart') return 1;

  if (a.scheme == 'package') {
    if (b.scheme == 'package') return byCanonicalUriPath();
    return -1;
  }
  if (b.scheme == 'package') return 1;

  return _compareCanonicalUri(a, b);
}

int _compareCanonicalUri(Uri a, Uri b) {
  int r = a.scheme.compareTo(b.scheme);
  if (r != 0) return r;

  // We would like the order of 'file:' Uris to be stable across different
  // users or different builds from temporary directories.  We sort by
  // pathSegments elements from the last to the first since that tends to find
  // a stable distinction regardless of directory root.
  List<String> aSegments = a.pathSegments;
  List<String> bSegments = b.pathSegments;
  int aI = aSegments.length;
  int bI = bSegments.length;
  while (aI > 0 && bI > 0) {
    String aSegment = aSegments[--aI];
    String bSegment = bSegments[--bI];
    r = aSegment.compareTo(bSegment);
    if (r != 0) return r;
  }
  return aI.compareTo(bI); // Shortest first.
}

/// Compare URIs of compilation units.
int compareSourceUris(Uri uri1, Uri uri2) {
  if (uri1 == uri2) return 0;
  // Compilation units are compared only within the same library so we expect
  // the Uris to usually be clustered together with a common scheme and path
  // prefix.
  return '${uri1}'.compareTo('${uri2}');
}

/// Compare entities within the same compilation unit.
int compareEntities(Entity element1, int line1, int column1, Entity element2,
    int line2, int column2) {
  line1 ??= -1;
  line2 ??= -1;
  int r = line1.compareTo(line2);
  if (r != 0) return r;

  column1 ??= -1;
  column2 ??= -1;
  r = column1.compareTo(column2);
  if (r != 0) return r;

  r = element1.name.compareTo(element2.name);
  if (r != 0) return r;

  // Same file, position and name.  If this happens, we should find out why
  // and make the order total and independent of hashCode.
  return element1.hashCode.compareTo(element2.hashCode);
}

String reconstructConstructorName(FunctionEntity element) {
  String className = element.enclosingClass.name;
  if (element.name == '') {
    return className;
  } else {
    return '$className\$${element.name}';
  }
}

String reconstructConstructorNameSourceString(FunctionEntity element) {
  if (element.name == '') {
    return element.enclosingClass.name;
  } else {
    return reconstructConstructorName(element);
  }
}

/// Map an operator-name to a valid JavaScript identifier.
///
/// For non-operator names, this method just returns its input.
///
/// The results returned from this method are guaranteed to be valid
/// JavaScript identifiers, except it may include reserved words for
/// non-operator names.
String operatorNameToIdentifier(String name) {
  if (name == null) {
    return name;
  } else if (name == '==') {
    return r'operator$eq';
  } else if (name == '~') {
    return r'operator$not';
  } else if (name == '[]') {
    return r'operator$index';
  } else if (name == '[]=') {
    return r'operator$indexSet';
  } else if (name == '*') {
    return r'operator$mul';
  } else if (name == '/') {
    return r'operator$div';
  } else if (name == '%') {
    return r'operator$mod';
  } else if (name == '~/') {
    return r'operator$tdiv';
  } else if (name == '+') {
    return r'operator$add';
  } else if (name == '<<') {
    return r'operator$shl';
  } else if (name == '>>') {
    return r'operator$shr';
  } else if (name == '>>>') {
    return r'operator$shru';
  } else if (name == '>=') {
    return r'operator$ge';
  } else if (name == '>') {
    return r'operator$gt';
  } else if (name == '<=') {
    return r'operator$le';
  } else if (name == '<') {
    return r'operator$lt';
  } else if (name == '&') {
    return r'operator$and';
  } else if (name == '^') {
    return r'operator$xor';
  } else if (name == '|') {
    return r'operator$or';
  } else if (name == '-') {
    return r'operator$sub';
  } else if (name == 'unary-') {
    return r'operator$negate';
  } else {
    return name;
  }
}

String constructOperatorNameOrNull(String op, bool isUnary) {
  if (isMinusOperator(op)) {
    return isUnary ? 'unary-' : op;
  } else if (isUserDefinableOperator(op) || op == '??') {
    return op;
  } else {
    return null;
  }
}

String constructOperatorName(String op, bool isUnary) {
  String operatorName = constructOperatorNameOrNull(op, isUnary);
  if (operatorName == null)
    throw 'Unhandled operator: $op';
  else
    return operatorName;
}
