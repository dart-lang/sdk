// Copyright (c) 2026, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import '../meta_model.dart';
import '../utils.dart';

/// Classes that support the Flutter Widget Preview.
final flutterWidgetPreviewClasses = <LspEntity>[
  interface(
    'FlutterWidgetPreviews',
    [
      field(
        'scriptUris',
        array: true,
        type: 'Uri',
        comment: 'The URIs for the updated scripts.',
      ),
      Field(
        name: 'namespaces',
        type: MapType(TypeReference.string, TypeReference.string),
        allowsNull: false,
        allowsUndefined: false,
        comment:
            'A set of library URIs and the prefixes used for types in '
            '"previewAnnotation" sources.',
      ),
      field(
        'previews',
        type: 'FlutterWidgetPreviewDetails',
        array: true,
        comment: 'The current set of previews in the script.',
      ),
    ],
    comment:
        'The set of widget previews defined in a script of an analyzed '
        'Flutter project.',
  ),
  interface(
    'FlutterWidgetPreviewDetails',
    [
      field(
        'scriptUri',
        type: 'Uri',
        comment:
            'The file:// URI pointing to the script in which the '
            'preview is defined.',
      ),
      field(
        'libraryUri',
        type: 'Uri',
        comment:
            'The unresolved URI pointing to the library in which the '
            'preview is defined. This is either a package: or dart: URI.',
      ),
      field(
        'position',
        type: 'Position',
        comment:
            'The source location at which the Preview annotation was applied.',
      ),
      field(
        'packageName',
        type: 'string',
        canBeNull: true,
        comment:
            'The name of the package in which this annotated preview '
            'function was defined.'
            '\n\n For example, if this preview is defined in '
            '"package:foo/src/bar.dart", this will have the value "foo".\n\n'
            'This should only be null if the preview is defined in a file '
            "that's not part of a Flutter package (e.g., is defined in a "
            'test).',
      ),
      field(
        'functionName',
        type: 'string',
        comment: 'The name of the function returning the preview.',
      ),
      field(
        'isBuilder',
        type: 'bool',
        comment:
            'Set to true if the preview function is returning a '
            '`WidgetBuilder` instead of a `Widget`.',
      ),
      field(
        'previewAnnotation',
        type: 'string',
        comment:
            'An equivalent Dart expression to the applied preview '
            'annotation, with namespaces applied to individual types and '
            'constant values evaluated.\n\nThis can be any object which '
            'extends `Preview` or `MultiPreview`.',
      ),
      field(
        'isMultiPreview',
        type: 'bool',
        comment:
            'Set to true if `previewAnnotation` represents a `MultiPreview`.',
      ),
      field(
        'hasError',
        type: 'bool',
        comment:
            'Set to true if there is an error that will prevent this preview '
            'from being rendered.',
      ),
      field(
        'dependencyHasErrors',
        type: 'bool',
        comment:
            'Set to true if there is an error in a dependency that will '
            'prevent this preview from being rendered.',
      ),
    ],
    comment:
        'A representation of a widget preview declaration containing all '
        'information needed to import the preview into the widget previewer.',
  ),
];
