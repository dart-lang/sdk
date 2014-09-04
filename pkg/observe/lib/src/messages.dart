// Copyright (c) 2014, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// Contains all warning messages produced by the observe transformer.
library observe.src.messages;

import 'package:code_transformers/messages/messages.dart';

const NO_OBSERVABLE_ON_LIBRARY = const MessageTemplate(
    const MessageId('observe', 1),
    '@observable on a library no longer has any effect. '
    'Instead, annotate individual fields as @observable.',
    '`@observable` not supported on libraries',
    _COMMON_MESSAGE_WHERE_TO_USE_OBSERVABLE);

const NO_OBSERVABLE_ON_TOP_LEVEL = const MessageTemplate(
    const MessageId('observe', 2),
    'Top-level fields can no longer be observable. '
    'Observable fields must be in observable objects.',
    '`@observable` not supported on top-level fields',
    _COMMON_MESSAGE_WHERE_TO_USE_OBSERVABLE);

const NO_OBSERVABLE_ON_CLASS = const MessageTemplate(
    const MessageId('observe', 3),
    '@observable on a class no longer has any effect. '
    'Instead, annotate individual fields as @observable.',
    '`@observable` not supported on classes',
    _COMMON_MESSAGE_WHERE_TO_USE_OBSERVABLE);

const NO_OBSERVABLE_ON_STATIC_FIELD = const MessageTemplate(
    const MessageId('observe', 4),
    'Static fields can no longer be observable. '
    'Observable fields must be in observable objects.',
    '`@observable` not supported on static fields',
    _COMMON_MESSAGE_WHERE_TO_USE_OBSERVABLE);

const REQUIRE_OBSERVABLE_INTERFACE = const MessageTemplate(
    const MessageId('observe', 5),
    'Observable fields must be in observable objects. '
    'Change this class to extend, mix in, or implement Observable.',
    '`@observable` field not in an `Observable` class',
    _COMMON_MESSAGE_WHERE_TO_USE_OBSERVABLE);

const String _COMMON_MESSAGE_WHERE_TO_USE_OBSERVABLE = '''
Only instance fields on `Observable` classes can be observable,
and you must explicitly annotate each observable field as `@observable`.

Support for using the `@observable` annotation in libraries, classes, and
elsewhere is deprecated.
''';
