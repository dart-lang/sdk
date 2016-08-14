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
class ClassDeclaration extends Declaration {
  /**
   * All fields defined in the class, including deprecated ones.
   */
  final List<FieldDeclaration> allFields = <FieldDeclaration>[];

  /**
   * Indicates whether the class has the `topLevel` annotation.
   */
  final bool isTopLevel;

  /**
   * If [isTopLevel] is `true` and a file identifier was specified for this
   * class, the file identifier string.  Otherwise `null`.
   */
  final String fileIdentifier;

  ClassDeclaration(
      String documentation, String name, this.isTopLevel, this.fileIdentifier)
      : super(documentation, name);

  /**
   * Get the non-deprecated fields defined in the class.
   */
  Iterable<FieldDeclaration> get fields =>
      allFields.where((FieldDeclaration field) => !field.isDeprecated);
}

/**
 * Information about a declaration in the IDL.
 */
class Declaration {
  /**
   * The optional documentation, may be `null`.
   */
  final String documentation;

  /**
   * The name of the declaration.
   */
  final String name;

  Declaration(this.documentation, this.name);
}

/**
 * Information about a single enum defined in the IDL.
 */
class EnumDeclaration extends Declaration {
  /**
   * List of enumerated values.
   */
  final List<EnumValueDeclaration> values = <EnumValueDeclaration>[];

  EnumDeclaration(String documentation, String name)
      : super(documentation, name);
}

/**
 * Information about a single enum value defined in the IDL.
 */
class EnumValueDeclaration extends Declaration {
  EnumValueDeclaration(String documentation, String name)
      : super(documentation, name);
}

/**
 * Information about a single class field defined in the IDL.
 */
class FieldDeclaration extends Declaration {
  /**
   * The file of the field.
   */
  final FieldType type;

  /**
   * The id of the field.
   */
  final int id;

  /**
   * Indicates whether the field is deprecated.
   */
  final bool isDeprecated;

  /**
   * Indicates whether the field is informative.
   */
  final bool isInformative;

  FieldDeclaration(String documentation, String name, this.type, this.id,
      this.isDeprecated, this.isInformative)
      : super(documentation, name);
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

  @override
  String toString() => isList ? 'List<$typeName>' : typeName;
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
