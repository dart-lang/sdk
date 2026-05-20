// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support for the new (Go-specified) interactive-refactors.
final interactiveFormClasses = <LspEntity>[
  // TODO(dantup): Try to generate this from the form.ts file once it has a
  //  stable location.
  //  https://github.com/golang/vscode-go/blob/fecc31339bc33de4b1db2a2242ba46ea552d0f39/extension/src/language/form.ts
  interface('InteractiveParams', [
    field(
      'formFields',
      array: true,
      type: 'FormField',
      canBeUndefined: true,
      comment:
          'Defines the questions and validation errors. This is a '
          'server-to-client field.',
    ),
    field(
      'formAnswers',
      array: true,
      type: 'LSPAny',
      comment:
          'The values for the form questions.\n\n'
          'When sent by the language server, this acts as preserved/previous '
          'input.\n\n'
          'When sent by the client (in a resolve request), this is required '
          'when formFields are defined.',
    ),
    field(
      'data',
      type: 'LSPAny',
      canBeUndefined: true,
      comment: 'Context preserved for the server.',
    ),
  ]),

  interface('FormField', [
    field(
      'description',
      type: 'String',
      comment:
          'The text content of the question (the prompt) presented to the '
          'user.',
    ),
    field(
      'type',
      type: 'FormFieldType',
      comment: 'The data type and validation constraints for the answer.',
    ),
    field(
      'default',
      type: 'LSPAny',
      canBeUndefined: true,
      comment:
          'An optional initial value for the answer. If [type] is '
          "'enum', this value must be present in the enum's "
          'values array.',
    ),
    field(
      'error',
      type: 'String',
      canBeUndefined: true,
      comment:
          'A validation message from the language server. If empty or '
          'null, the current answer is considered valid.',
    ),
  ], comment: 'A single question in a form and its validation state.'),

  // Field kinds
  interface('FormFieldType', abstract: true, [
    field('kind', type: 'String'),
  ]), // Base
  interface('FormFieldTypeString', baseType: 'FormFieldType', [
    field('kind', type: 'string', literal: true),
  ], comment: 'A text input.'),
  interface(
    'FormFieldTypeDocumentURI',
    baseType: 'FormFieldType',
    [field('kind', type: 'documentURI', literal: true)],
    comment:
        'FormFieldTypeDocumentURI defines an input for a file or directory '
        'URI.\n\n'
        'The client determines the best mechanism to collect this information '
        'from the user (e.g., a graphical file picker, a text input with '
        'autocomplete, etc).\n\n'
        'The value returned by the client must be a valid "DocumentUri" as '
        'defined in the LSP specification: '
        'https://microsoft.github.io/language-server-protocol/specifications/lsp/3.17/specification/#documentUri',
  ),
  interface('FormFieldTypeBool', baseType: 'FormFieldType', [
    field('kind', type: 'bool', literal: true),
  ], comment: 'A boolean input.'),
  interface('FormFieldTypeNumber', baseType: 'FormFieldType', [
    field('kind', type: 'number', literal: true),
  ], comment: 'A numeric input.'),
  interface('FormFieldTypeEnum', baseType: 'FormFieldType', [
    field('kind', type: 'enum', literal: true),
    field(
      'name',
      type: 'string',
      canBeUndefined: true,
      comment: 'An optional identifier for the enum type.',
    ),
    field(
      'entries',
      array: true,
      type: 'FormEnumEntry',
      comment: 'The list of allowable options.',
    ),
  ], comment: 'A numeric input.'),
  interface('FormEnumEntry', [
    field(
      'value',
      type: 'string',
      comment:
          'The unique string identifier for this option.\n\n'
          'This is the value that will be sent back to the server in '
          '`FormAnswers` if the user selects this option.',
    ),
    field(
      'description',
      type: 'string',
      comment: 'The human-readable label presented to the user.',
    ),
  ], comment: 'A numeric input.'),
];
