// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

const String wildcardPrefix = '_#wc';
const String wildcardFormalSuffix = '#formal';
const String wildcardTypeVariableSuffix = '#type';
const String wildcardVariableSuffix = '#var';

/// Returns the named used for a wildcard formal parameter using [index].
String createWildcardFormalParameterName(int index) {
  return '$wildcardPrefix$index$wildcardFormalSuffix';
}

/// Returns the named used for a wildcard type variable using [index].
String createWildcardTypeVariableName(int index) {
  return '$wildcardPrefix$index$wildcardTypeVariableSuffix';
}

/// Returns the named used for a wildcard variable using [index].
String createWildcardVariableName(int index) {
  return '$wildcardPrefix$index$wildcardVariableSuffix';
}

/// Whether the given [name] is a wildcard formal parameter.
bool isWildcardLoweredFormalParameter(String name) {
  return name.startsWith(wildcardPrefix) && name.endsWith(wildcardFormalSuffix);
}

/// Whether the given [name] is a wildcard type variable.
bool isWildcardLoweredTypeVariable(String name) {
  return name.startsWith(wildcardPrefix) &&
      name.endsWith(wildcardTypeVariableSuffix);
}

/// Whether the given [name] is a wildcard variable.
bool isWildcardLoweredVariable(String name) {
  return name.startsWith(wildcardPrefix) &&
      name.endsWith(wildcardVariableSuffix);
}
