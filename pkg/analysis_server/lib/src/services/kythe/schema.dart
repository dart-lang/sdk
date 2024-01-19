// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file gathers constant strings from the Kythe Schema:
/// kythe.io/docs/schema/
library;

const ANCHOR_END_FACT = '/kythe/loc/end';

/// Kythe node kinds
const ANCHOR_KIND = 'anchor';
const ANCHOR_START_FACT = '/kythe/loc/start';

/// Kythe edge kinds
const ANNOTATED_BY_EDGE = '${EDGE_PREFIX}annotatedby';

const CHILD_OF_EDGE = '${EDGE_PREFIX}childof';

/// Kythe node subkinds
const CLASS_SUBKIND = 'class';

const COMPLETE_FACT = '/kythe/complete';
const CONSTANT_KIND = 'constant';

const CONSTRUCTOR_SUBKIND = 'constructor';

/// Dart specific facts, labels, and kinds
const DART_LANG = 'dart';

/// DEFAULT_TEXT_ENCODING is the assumed value of the TEXT_ENCODING_FACT if it
/// is empty or missing from a node with a TEXT_FACT.
const DEFAULT_TEXT_ENCODING = 'UTF-8';
const DEFINES_BINDING_EDGE = '${EDGE_PREFIX}defines/binding';

/// Kythe edge kinds associated with anchors
const DEFINES_EDGE = '${EDGE_PREFIX}defines';

const DEFINITION = 'definition';

const DOC_KIND = 'doc';

const DOCUMENTS_EDGE = '${EDGE_PREFIX}documents';
const DYNAMIC_KIND = 'dynamic#builtin';

/// EdgePrefix is the standard Kythe prefix for all edge kinds.
const EDGE_PREFIX = '/kythe/edge/';
const ENUM_CLASS_SUBKIND = 'enumClass';
const ENUM_KIND = 'enum';
const EXTENDS_EDGE = '${EDGE_PREFIX}extends';
const FIELD_SUBKIND = 'field';
const FILE_KIND = 'file';
const FN_BUILTIN = 'fn#builtin';
const FUNCTION_KIND = 'function';

const IMPLICIT_SUBKIND = 'implicit';

/// Kythe complete states
const INCOMPLETE = 'incomplete';
const INSTANTIATES_EDGE = '${EDGE_PREFIX}instantiates';
const LOCAL_PARAMETER_SUBKIND = 'local/parameter';
const LOCAL_SUBKIND = 'local';

/// Kythe node fact labels
const NODE_KIND_FACT = '/kythe/node/kind';

/// Kythe ordinal
const ORDINAL = '/kythe/ordinal';

const OVERRIDES_EDGE = '${EDGE_PREFIX}overrides';
const PACKAGE_KIND = 'package';

const PARAM_EDGE = '${EDGE_PREFIX}param';

const RECORD_KIND = 'record';

const REF_CALL_EDGE = '${EDGE_PREFIX}ref/call';
const REF_EDGE = '${EDGE_PREFIX}ref';
const REF_IMPORTS_EDGE = '${EDGE_PREFIX}ref/imports';
const SNIPPET_END_FACT = '/kythe/snippet/end';
const SNIPPET_START_FACT = '/kythe/snippet/start';
const SUBKIND_FACT = '/kythe/subkind';
const TAPP_KIND = 'tapp';

const TEXT_ENCODING_FACT = '/kythe/text/encoding';
const TEXT_FACT = '/kythe/text';
const TEXT_FORMAT = '/kythe/format';
const TYPED_EDGE = '${EDGE_PREFIX}typed';
const VARIABLE_KIND = 'variable';
const VOID_BUILTIN = 'void#builtin';
