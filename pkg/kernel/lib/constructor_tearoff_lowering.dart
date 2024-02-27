// Copyright (c) 2024, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:kernel/ast.dart';

const String _tearOffNamePrefix = '_#';
const String _tearOffNameSuffix = '#tearOff';

/// Creates the synthesized name to use for the lowering of the tear off of a
/// constructor or factory by the given [name].
String constructorTearOffName(String name) {
  return '$_tearOffNamePrefix'
      '${name.isEmpty ? 'new' : name}'
      '$_tearOffNameSuffix';
}

/// Creates the synthesized name to use for the lowering of the tear off of a
/// constructor or factory by the given [constructorName] through a typedef by
/// the given [typedefName].
String typedefTearOffName(String typedefName, String constructorName) {
  return '$_tearOffNamePrefix'
      '$typedefName#'
      '${constructorName.isEmpty ? 'new' : constructorName}'
      '$_tearOffNameSuffix';
}

/// If [name] is the synthesized name of a lowering of a typedef tear off, a
/// list containing the [String] name of the typedef and the [Name] name of the
/// corresponding constructor or factory is returned. Returns `null` otherwise.
List<Object>? extractTypedefNameFromTearOff(Name name) {
  if (name.text.startsWith(_tearOffNamePrefix) &&
      name.text.endsWith(_tearOffNameSuffix) &&
      name.text.length >
          _tearOffNamePrefix.length + _tearOffNameSuffix.length) {
    String text =
        name.text.substring(0, name.text.length - _tearOffNameSuffix.length);
    text = text.substring(_tearOffNamePrefix.length);
    int hashIndex = text.indexOf('#');
    if (hashIndex == -1) {
      return null;
    }
    String typedefName = text.substring(0, hashIndex);
    String constructorName = text.substring(hashIndex + 1);
    constructorName = constructorName == 'new' ? '' : constructorName;
    return [typedefName, new Name(constructorName, name.library)];
  }
  return null;
}

/// Returns `true` if [member] is a lowered constructor, factory or typedef tear
/// off.
bool isTearOffLowering(Member member) {
  return member is Procedure &&
      (isConstructorTearOffLowering(member) ||
          isTypedefTearOffLowering(member));
}

/// Returns `true` if [procedure] is a lowered typedef tear off.
bool isTypedefTearOffLowering(Procedure procedure) {
  return extractTypedefNameFromTearOff(procedure.name) != null;
}

/// Returns `true` if [procedure] is a lowered constructor or factory tear off.
bool isConstructorTearOffLowering(Procedure procedure) {
  return extractConstructorNameFromTearOff(procedure.name) != null;
}

String? extractConstructorNameFromTearOff(Name name) {
  if (name.text.startsWith(_tearOffNamePrefix) &&
      name.text.endsWith(_tearOffNameSuffix) &&
      name.text.length >
          _tearOffNamePrefix.length + _tearOffNameSuffix.length) {
    String text =
        name.text.substring(0, name.text.length - _tearOffNameSuffix.length);
    text = text.substring(_tearOffNamePrefix.length);
    if (text.contains('#')) {
      return null;
    }
    return text == 'new' ? '' : text;
  }
  return null;
}
