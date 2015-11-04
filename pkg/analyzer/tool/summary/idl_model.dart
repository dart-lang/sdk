// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * This file contains a set of concrete classes representing an in-memory
 * semantic model of the IDL used to code generate summary serialization and
 * deserialization code.
 */
library analyzer.tool.summary.idl_model;

/**
 * Information about a single class defined in the IDL.
 */
class ClassDeclaration {
  /**
   * Fields defined in the class.
   */
  final Map<String, FieldType> fields = <String, FieldType>{};
}

/**
 * Information about a single enum defined in the IDL.
 */
class EnumDeclaration {
  /**
   * List of enumerated values.
   */
  final List<String> values = <String>[];
}

/**
 * Information about the type of a class field defined in the IDL.
 */
class FieldType {
  /**
   * Type of the field (e.g. 'int').
   */
  final String typeName;

  /**
   * Indicates whether this field contains a list of the type specified in
   * [typeName].
   */
  final bool isList;

  FieldType(this.typeName, this.isList);
}

/**
 * Top level representation of the summary IDL.
 */
class Idl {
  /**
   * Classes defined in the IDL.
   */
  final Map<String, ClassDeclaration> classes = <String, ClassDeclaration>{};

  /**
   * Enums defined in the IDL.
   */
  final Map<String, EnumDeclaration> enums = <String, EnumDeclaration>{};
}
