// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.keys;

/// Keys used for serialization.
class Key {
  static const Key ALIAS = const Key('alias');
  static const Key ARGUMENTS = const Key('arguments');
  static const Key BOUND = const Key('bound');
  static const Key CALL_STRUCTURE = const Key('callStructure');
  static const Key CANONICAL_URI = const Key('canonicalUri');
  static const Key CLASS = const Key('class');
  static const Key COMPILATION_UNIT = const Key('compilation-unit');
  static const Key COMPILATION_UNITS = const Key('compilation-units');
  static const Key CONDITION = const Key('condition');
  static const Key CONSTANT = const Key('constant');
  static const Key CONSTANTS = const Key('constants');
  static const Key CONSTRUCTOR = const Key('constructor');
  static const Key DEFAULT = const Key('default');
  static const Key DEFAULTS = const Key('defaults');
  static const Key ELEMENT = const Key('element');
  static const Key ELEMENTS = const Key('elements');
  static const Key EXPORTS = const Key('exports');
  static const Key EXPORT_SCOPE = const Key('export-scope');
  static const Key EXPRESSION = const Key('expression');
  static const Key FALSE = const Key('false');
  static const Key FIELD = const Key('field');
  static const Key FIELDS = const Key('fields');
  static const Key FUNCTION = const Key('function');
  static const Key ID = const Key('id');
  static const Key IMPORT = const Key('import');
  static const Key IMPORTS = const Key('imports');
  static const Key IMPORT_SCOPE = const Key('import-scope');
  static const Key INTERFACES = const Key('interfaces');
  static const Key INDEX = const Key('index');
  static const Key IS_ABSTRACT = const Key('isAbstract');
  static const Key IS_CONST = const Key('isConst');
  static const Key IS_DEFERRED = const Key('isDeferred');
  static const Key IS_EXTERNAL = const Key('isExternal');
  static const Key IS_FINAL = const Key('isFinal');
  static const Key IS_NAMED = const Key('isNamed');
  static const Key IS_OPERATOR = const Key('isOperator');
  static const Key IS_OPTIONAL = const Key('isOptional');
  static const Key KEYS = const Key('keys');
  static const Key KIND = const Key('kind');
  static const Key LEFT = const Key('left');
  static const Key LENGTH = const Key('length');
  static const Key LIBRARY = const Key('library');
  static const Key LIBRARY_DEPENDENCY = const Key('library-dependency');
  static const Key LIBRARY_NAME = const Key('library-name');
  static const Key MEMBERS = const Key('members');
  static const Key NAME = const Key('name');
  static const Key NAMES = const Key('names');
  static const Key NAMED_PARAMETERS = const Key('named-parameters');
  static const Key NAMED_PARAMETER_TYPES = const Key('named-parameter-types');
  static const Key OFFSET = const Key('offset');
  static const Key OFFSETS = const Key('offsets');
  static const Key OPERATOR = const Key('operator');
  static const Key OPTIONAL_PARAMETER_TYPES =
      const Key('optional-parameter-types');
  static const Key PARAMETERS = const Key('parameters');
  static const Key PARAMETER_TYPES = const Key('parameter-types');
  static const Key PREFIX = const Key('prefix');
  static const Key RETURN_TYPE = const Key('return-type');
  static const Key RIGHT = const Key('right');
  static const Key SUPERTYPE = const Key('supertype');
  static const Key SUPERTYPES = const Key('supertypes');
  static const Key TAGS = const Key('tags');
  static const Key TRUE = const Key('true');
  static const Key TYPE = const Key('type');
  static const Key TYPES = const Key('types');
  static const Key TYPE_ARGUMENTS = const Key('type-arguments');
  static const Key TYPE_DECLARATION = const Key('type-declaration');
  static const Key TYPE_VARIABLES = const Key('type-variables');
  static const Key URI = const Key('uri');
  static const Key VALUE = const Key('value');
  static const Key VALUES = const Key('values');

  final String name;

  const Key(this.name);

  String toString() => name;
}
