// Copyright (c) 2017, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This file gathers constant strings from the Kythe Schema:
/// kythe.io/docs/schema/
library;

const anchorEndFact = '/kythe/loc/end';

/// Kythe node kinds
const anchorKind = 'anchor';
const anchorStartFact = '/kythe/loc/start';

/// Kythe edge kinds
const annotatedByEdge = '${edgePrefix}annotatedby';

const childOfEdge = '${edgePrefix}childof';

/// Kythe node subkinds
const classSubkind = 'class';

const completeFact = '/kythe/complete';
const constantKind = 'constant';

const constructorSubkind = 'constructor';

/// Dart specific facts, labels, and kinds
const dartLang = 'dart';

/// DEFAULT_TEXT_ENCODING is the assumed value of the TEXT_ENCODING_FACT if it
/// is empty or missing from a node with a TEXT_FACT.
const defaultTextEncoding = 'UTF-8';
const definesBindingEdge = '${edgePrefix}defines/binding';

/// Kythe edge kinds associated with anchors
const definesEdge = '${edgePrefix}defines';

const definition = 'definition';

const docKind = 'doc';

const documentsEdge = '${edgePrefix}documents';
const dynamicKind = 'dynamic#builtin';

/// EdgePrefix is the standard Kythe prefix for all edge kinds.
const edgePrefix = '/kythe/edge/';
const enumClassSubkind = 'enumClass';
const enumKind = 'enum';
const extendsEdge = '${edgePrefix}extends';
const fieldSubkind = 'field';
const fileKind = 'file';
const fnBuiltin = 'fn#builtin';
const functionKind = 'function';

const implicitSubkind = 'implicit';

/// Kythe complete states
const incomplete = 'incomplete';
const instantiatesEdge = '${edgePrefix}instantiates';
const localParameterSubkind = 'local/parameter';
const localSubkind = 'local';

/// Kythe node fact labels
const nodeKindFact = '/kythe/node/kind';

/// Kythe ordinal
const ordinal = '/kythe/ordinal';

const overridesEdge = '${edgePrefix}overrides';
const packageKind = 'package';

const paramEdge = '${edgePrefix}param';

const recordKind = 'record';

const refCallEdge = '${edgePrefix}ref/call';
const refEdge = '${edgePrefix}ref';
const refImportsEdge = '${edgePrefix}ref/imports';
const snippetEndFact = '/kythe/snippet/end';
const snippetStartFact = '/kythe/snippet/start';
const subkindFact = '/kythe/subkind';
const tappKind = 'tapp';

const textEncodingFact = '/kythe/text/encoding';
const textFact = '/kythe/text';
const textFormat = '/kythe/format';
const typedEdge = '${edgePrefix}typed';
const variableKind = 'variable';
const voidBuiltin = 'void#builtin';
