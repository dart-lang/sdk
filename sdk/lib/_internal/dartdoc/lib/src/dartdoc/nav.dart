// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

part of dartdoc;

/*
 * Constant values used for encoding navigation info.
 *
 * The generated JSON data is a list of LibraryInfo maps, defined as follows:
 *
 *     LibraryInfo = {
 *         String NAME, // Library name.
 *         List<TypeInfo> TYPES, // Library types.
 *         List<MemberInfo> MEMBERS, // Library functions and variables.
 *     };
 *     TypeInfo = {
 *         String NAME, // Type name.
 *         String ARGS, // Type variables, e.g. "<K,V>". Optional.
 *         String KIND, // One of CLASS, INTERFACE, or TYPEDEF.
 *         List<MemberInfo> MEMBERS, // Type fields and methods.
 *     };
 *     MemberInfo = {
 *        String NAME, // Member name.
 *        String KIND, // One of FIELD, CONSTRUCTOR, METHOD, GETTER, or SETTER.
 *        String LINK_NAME, // Anchor name for the member if different from
 *                          // NAME.
 *        bool NO_PARAMS, // Is true if member takes no arguments?
 *     };
 *
 *
 * TODO(johnniwinther): Shorten the string values to reduce JSON output size.
 */

const String LIBRARY = 'library';
const String CLASS = 'class';
const String INTERFACE = 'interface';
const String TYPEDEF = 'typedef';
const String MEMBERS = 'members';
const String TYPES = 'types';
const String ARGS = 'args';
const String NAME = 'name';
const String KIND = 'kind';
const String FIELD = 'field';
const String CONSTRUCTOR = 'constructor';
const String METHOD = 'method';
const String NO_PARAMS = 'noparams';
const String GETTER = 'getter';
const String SETTER = 'setter';
const String LINK_NAME = 'link_name';

/**
 * Translation of const values to strings. Used to facilitate shortening of
 * constant value strings.
 */
String kindToString(String kind) {
  if (kind == LIBRARY) {
    return 'library';
  } else if (kind == CLASS) {
    return 'class';
  } else if (kind == INTERFACE) {
    return 'interface';
  } else if (kind == TYPEDEF) {
    return 'typedef';
  } else if (kind == FIELD) {
    return 'field';
  } else if (kind == CONSTRUCTOR) {
    return 'constructor';
  } else if (kind == METHOD) {
    return 'method';
  } else if (kind == GETTER) {
    return 'getter';
  } else if (kind == SETTER) {
    return 'setter';
  }
  return '';
}