// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library dart2js.serialization.keys;

/// Keys used for serialization.
class Key {
  static const Key ALIAS = const Key('alias');
  static const Key ARGUMENTS = const Key('arguments');
  static const Key ASYNC_MARKER = const Key('asyncMarker');
  static const Key BODY = const Key('body');
  static const Key BOUND = const Key('bound');
  static const Key CACHED_TYPE = const Key('cachedType');
  static const Key CALL_STRUCTURE = const Key('callStructure');
  static const Key CALL_TYPE = const Key('callType');
  static const Key CANONICAL_URI = const Key('canonicalUri');
  static const Key CLASS = const Key('class');
  static const Key COMPILATION_UNIT = const Key('compilation-unit');
  static const Key COMPILATION_UNITS = const Key('compilation-units');
  static const Key CONDITION = const Key('condition');
  static const Key CONSTANT = const Key('constant');
  static const Key CONSTANTS = const Key('constants');
  static const Key CONSTRUCTOR = const Key('constructor');
  static const Key CONTAINS_TRY = const Key('containsTryStatement');
  static const Key DATA = const Key('data');
  static const Key DEFAULT = const Key('default');
  static const Key DEFAULTS = const Key('defaults');
  static const Key DYNAMIC_USES = const Key('dynamic-uses');
  static const Key EFFECTIVE_TARGET = const Key('effectiveTarget');
  static const Key EFFECTIVE_TARGET_TYPE = const Key('effectiveTargetType');
  static const Key ELEMENT = const Key('element');
  static const Key ELEMENTS = const Key('elements');
  static const Key ENCLOSING = const Key('enclosing');
  static const Key EXECUTABLE_CONTEXT = const Key('executable-context');
  static const Key EXPORTS = const Key('exports');
  static const Key EXPORT_SCOPE = const Key('export-scope');
  static const Key EXPRESSION = const Key('expression');
  static const Key FALSE = const Key('false');
  static const Key FEATURES = const Key('features');
  static const Key FIELD = const Key('field');
  static const Key FIELDS = const Key('fields');
  static const Key FUNCTION = const Key('function');
  static const Key GET_OR_SET = const Key('getOrSet');
  static const Key GETTER = const Key('getter');
  static const Key ID = const Key('id');
  static const Key IMMEDIATE_REDIRECTION_TARGET =
      const Key('immediateRedirectionTarget');
  static const Key IMPACTS = const Key('impacts');
  static const Key IMPORT = const Key('import');
  static const Key IMPORTS = const Key('imports');
  static const Key IMPORT_SCOPE = const Key('import-scope');
  static const Key INTERFACES = const Key('interfaces');
  static const Key INDEX = const Key('index');
  static const Key IS_ABSTRACT = const Key('isAbstract');
  static const Key IS_BREAK_TARGET = const Key('isBreakTarget');
  static const Key IS_CONST = const Key('isConst');
  static const Key IS_CONTINUE_TARGET = const Key('isContinueTarget');
  static const Key IS_DEFERRED = const Key('isDeferred');
  static const Key IS_EMPTY = const Key('isEmpty');
  static const Key IS_EXTERNAL = const Key('isExternal');
  static const Key IS_FINAL = const Key('isFinal');
  static const Key IS_INJECTED = const Key('isInjected');
  static const Key IS_NAMED = const Key('isNamed');
  static const Key IS_OPERATOR = const Key('isOperator');
  static const Key IS_OPTIONAL = const Key('isOptional');
  static const Key IS_PROXY = const Key('isProxy');
  static const Key IS_REDIRECTING = const Key('isRedirecting');
  static const Key IS_SETTER = const Key('isSetter');
  static const Key IS_UNNAMED_MIXIN_APPLICATION =
      const Key('isUnnamedMixinApplication');
  static const Key JUMP_TARGET = const Key('jumpTarget');
  static const Key JUMP_TARGETS = const Key('jumpTargets');
  static const Key JUMP_TARGET_DEFINITION = const Key('jumpTargetDefinition');
  static const Key KEYS = const Key('keys');
  static const Key KIND = const Key('kind');
  static const Key LABEL_DEFINITION = const Key('labelDefinition');
  static const Key LABEL_DEFINITIONS = const Key('labelDefinitions');
  static const Key LABELS = const Key('labels');
  static const Key LEFT = const Key('left');
  static const Key LENGTH = const Key('length');
  static const Key LIBRARY = const Key('library');
  static const Key LIBRARY_DEPENDENCY = const Key('library-dependency');
  static const Key LIBRARY_NAME = const Key('library-name');
  static const Key LISTS = const Key('lists');
  static const Key MAPS = const Key('maps');
  static const Key MEMBERS = const Key('members');
  static const Key MESSAGE_KIND = const Key('messageKind');
  static const Key METADATA = const Key('metadata');
  static const Key MIXIN = const Key('mixin');
  static const Key MIXINS = const Key('mixins');
  static const Key NAME = const Key('name');
  static const Key NAMES = const Key('names');
  static const Key NAMED_ARGUMENTS = const Key('named-arguments');
  static const Key NAMED_PARAMETERS = const Key('named-parameters');
  static const Key NAMED_PARAMETER_TYPES = const Key('named-parameter-types');
  static const Key NATIVE = const Key('native');
  static const Key NESTING_LEVEL = const Key('nestingLevel');
  static const Key NEW_STRUCTURE = const Key('newStructure');
  static const Key NODE = const Key('node');
  static const Key OFFSET = const Key('offset');
  static const Key OPERATOR = const Key('operator');
  static const Key OPTIONAL_PARAMETER_TYPES =
      const Key('optional-parameter-types');
  static const Key PARAMETERS = const Key('parameters');
  static const Key PARAMETER_TYPES = const Key('parameter-types');
  static const Key PREFIX = const Key('prefix');
  static const Key RETURN_TYPE = const Key('return-type');
  static const Key RIGHT = const Key('right');
  static const Key SELECTOR = const Key('selector');
  static const Key SEMANTICS = const Key('semantics');
  static const Key SEND_STRUCTURE = const Key('sendStructure');
  static const Key SETTER = const Key('setter');
  static const Key STATIC_USES = const Key('static-uses');
  static const Key SUB_KIND = const Key('subKind');
  static const Key SUPERTYPE = const Key('supertype');
  static const Key SUPERTYPES = const Key('supertypes');
  static const Key SYMBOLS = const Key('symbols');
  static const Key TAGS = const Key('tags');
  static const Key TARGET_LABEL = const Key('targetLabel');
  static const Key TRUE = const Key('true');
  static const Key TYPE = const Key('type');
  static const Key TYPES = const Key('types');
  static const Key TYPE_ARGUMENTS = const Key('type-arguments');
  static const Key TYPE_DECLARATION = const Key('type-declaration');
  static const Key TYPE_USES = const Key('type-uses');
  static const Key TYPE_VARIABLES = const Key('type-variables');
  static const Key URI = const Key('uri');
  static const Key VALUE = const Key('value');
  static const Key VALUES = const Key('values');

  final String name;

  const Key(this.name);

  String toString() => name;
}
