// Copyright (c) 2017, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file gathers constant strings from the Kythe Schema:
/// kythe.io/docs/schema/

/// Dart specific facts, labels, and kinds
const DART_LANG = 'dart';
const DYNAMIC_KIND = 'dynamic#builtin';
const FN_BUILTIN = 'fn#builtin';
const VOID_BUILTIN = 'void#builtin';

/// Kythe node fact labels
const NODE_KIND_FACT = '/kythe/node/kind';
const SUBKIND_FACT = '/kythe/subkind';

const ANCHOR_START_FACT = '/kythe/loc/start';
const ANCHOR_END_FACT = '/kythe/loc/end';

const SNIPPET_START_FACT = '/kythe/snippet/start';
const SNIPPET_END_FACT = '/kythe/snippet/end';

const TEXT_FACT = '/kythe/text';
const TEXT_ENCODING_FACT = '/kythe/text/encoding';

const COMPLETE_FACT = '/kythe/complete';

const TEXT_FORMAT = '/kythe/format';

/// DEFAULT_TEXT_ENCODING is the assumed value of the TEXT_ENCODING_FACT if it
/// is empty or missing from a node with a TEXT_FACT.
const DEFAULT_TEXT_ENCODING = 'UTF-8';

/// Kythe node kinds
const ANCHOR_KIND = 'anchor';
const FILE_KIND = 'file';

const CONSTANT_KIND = 'constant';
const DOC_KIND = 'doc';
const ENUM_KIND = 'enum';
const FUNCTION_KIND = 'function';
const PACKAGE_KIND = 'package';
const RECORD_KIND = 'record';
const TAPP_KIND = 'tapp';
const VARIABLE_KIND = 'variable';

/// Kythe node subkinds
const CLASS_SUBKIND = 'class';
const CONSTRUCTOR_SUBKIND = 'constructor';
const ENUM_CLASS_SUBKIND = 'enumClass';
const IMPLICIT_SUBKIND = 'implicit';
const FIELD_SUBKIND = 'field';
const LOCAL_SUBKIND = 'local';
const LOCAL_PARAMETER_SUBKIND = 'local/parameter';

/// Kythe complete states
const INCOMPLETE = 'incomplete';
const DEFINITION = 'definition';

/// Kythe ordinal
const ORDINAL = '/kythe/ordinal';

/// EdgePrefix is the standard Kythe prefix for all edge kinds.
const EDGE_PREFIX = '/kythe/edge/';

/// Kythe edge kinds
const ANNOTATED_BY_EDGE = EDGE_PREFIX + "annotatedby";
const CHILD_OF_EDGE = EDGE_PREFIX + "childof";
const EXTENDS_EDGE = EDGE_PREFIX + "extends";
const INSTANTIATES_EDGE = EDGE_PREFIX + "instantiates";
const OVERRIDES_EDGE = EDGE_PREFIX + "overrides";
const PARAM_EDGE = EDGE_PREFIX + "param";
const TYPED_EDGE = EDGE_PREFIX + "typed";

/// Kythe edge kinds associated with anchors
const DEFINES_EDGE = EDGE_PREFIX + "defines";
const DEFINES_BINDING_EDGE = EDGE_PREFIX + "defines/binding";
const DOCUMENTS_EDGE = EDGE_PREFIX + "documents";
const REF_EDGE = EDGE_PREFIX + "ref";
const REF_CALL_EDGE = EDGE_PREFIX + "ref/call";
const REF_IMPORTS_EDGE = EDGE_PREFIX + "ref/imports";
