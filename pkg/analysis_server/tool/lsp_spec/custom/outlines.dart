// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support the Outline notifications.
final outlineClasses = <LspEntity>[
  interface('Element', [
    field('range', type: 'Range', canBeUndefined: true),
    field('name', type: 'string'),
    field('kind', type: 'string'),
    field('parameters', type: 'string', canBeUndefined: true),
    field('typeParameters', type: 'string', canBeUndefined: true),
    field('returnType', type: 'string', canBeUndefined: true),
  ]),
  interface('PublishOutlineParams', [
    field('uri', type: 'Uri'),
    field('outline', type: 'Outline'),
  ]),
  interface('Outline', [
    field('element', type: 'Element'),
    field('range', type: 'Range'),
    field('codeRange', type: 'Range'),
    field('children', type: 'Outline', array: true, canBeUndefined: true),
  ]),
  interface('PublishFlutterOutlineParams', [
    field('uri', type: 'Uri'),
    field('outline', type: 'FlutterOutline'),
  ]),
  interface('FlutterOutline', [
    field('kind', type: 'string'),
    field('label', type: 'string', canBeUndefined: true),
    field('className', type: 'string', canBeUndefined: true),
    field('variableName', type: 'string', canBeUndefined: true),
    field(
      'attributes',
      type: 'FlutterOutlineAttribute',
      array: true,
      canBeUndefined: true,
    ),
    field('dartElement', type: 'Element', canBeUndefined: true),
    field('range', type: 'Range'),
    field('codeRange', type: 'Range'),
    field(
      'children',
      type: 'FlutterOutline',
      array: true,
      canBeUndefined: true,
    ),
  ]),
  interface('FlutterOutlineAttribute', [
    field('name', type: 'string'),
    field('label', type: 'string'),
    field('valueRange', type: 'Range', canBeUndefined: true),
  ]),
];
