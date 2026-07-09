// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support the original (Dart-specific) interactive-refactors.
final interactiveRefactorsClasses = <LspEntity>[
  interface(
    'CommandParameter',
    [
      field(
        'parameterLabel',
        type: 'String',
        comment:
            'A human-readable label to be displayed in the UI affordance '
            'used to prompt the user for the value of the parameter.',
      ),
      AbstractGetter(
        name: 'kind',
        type: TypeReference.string,
        comment:
            'The kind of this parameter. The client may use different '
            'UIs based on this value.',
      ),
      AbstractGetter(
        name: 'defaultValue',
        type: TypeReference.lspAny,
        comment:
            'An optional default value for the parameter. The type of '
            'this value may vary between parameter kinds but must always be '
            'something that can be converted directly to/from JSON.',
      ),
    ],
    abstract: true,
    comment:
        'Information about one of the arguments needed by the command.'
        '\n\n'
        'A list of parameters is sent in the `data` field of the '
        '`CodeActionLiteral` returned by the server. The values of the '
        'parameters should appear in the `args` field of the `Command` sent '
        'to the server in the same order as the corresponding parameters.',
  ),
  interface(
    'SaveUriCommandParameter',
    [
      field('kind', type: 'saveUri', literal: true),
      field(
        'defaultValue',
        type: 'String',
        canBeNull: true,
        canBeUndefined: true,
        comment: 'An optional default URI for the parameter.',
      ),
      field(
        'parameterTitle',
        type: 'String',
        comment: 'A title that may be displayed on a file dialog.',
      ),
      field(
        'actionLabel',
        type: 'String',
        comment: 'A label for the file dialogs action button.',
      ),
      Field(
        name: 'filters',
        type: MapType(TypeReference.string, ArrayType(TypeReference.string)),
        allowsNull: true,
        allowsUndefined: true,
        comment:
            'A set of file filters for a file dialog. '
            'Keys of the map are textual names ("Dart") and the value '
            'is a list of file extensions (["dart"]).',
      ),
    ],
    baseType: 'CommandParameter',
    comment: 'Information about a Save URI argument needed by the command.',
  ),
];
