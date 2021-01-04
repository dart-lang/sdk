// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/producer.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analyzer/file_system/file_system.dart';

/// A completion generator that can produce completion suggestions for fix data
/// files.
class FixDataGenerator extends YamlCompletionGenerator {
  /// The producer representing the known valid structure of a fix data file.
  static const MapProducer fixDataProducer = MapProducer({
    'version': EmptyProducer(),
    'transforms': ListProducer(MapProducer({
      'title': EmptyProducer(),
      'date': EmptyProducer(),
      'bulkApply': BooleanProducer(),
      'element': MapProducer({
        // TODO(brianwilkerson) Support suggesting uris.
        'uris': EmptyProducer(),
        'class': EmptyProducer(),
        'constant': EmptyProducer(),
        'constructor': EmptyProducer(),
        'enum': EmptyProducer(),
        'extension': EmptyProducer(),
        'field': EmptyProducer(),
        'function': EmptyProducer(),
        'getter': EmptyProducer(),
        'method': EmptyProducer(),
        'mixin': EmptyProducer(),
        'setter': EmptyProducer(),
        'typedef': EmptyProducer(),
        'variable': EmptyProducer(),
        'inClass': EmptyProducer(),
        'inEnum': EmptyProducer(),
        'inExtension': EmptyProducer(),
        'inMixin': EmptyProducer(),
      }),
      'changes': _changesProducer,
      'oneOf': ListProducer(MapProducer({
        'if': EmptyProducer(),
        'changes': _changesProducer,
      })),
      'variables': EmptyProducer(),
    })),
  });

  /// The producer representing the known valid structure of a list of changes.
  static const ListProducer _changesProducer = ListProducer(MapProducer({
    // TODO(brianwilkerson) Create a way to tailor the list of additional
    //  keys based on the kind when a kind has already been provided.
    'kind': EnumProducer([
      'addParameter',
      'addTypeParameter',
      'removeParameter',
      'rename',
      'renameParameter',
    ]),
    'index': EmptyProducer(),
    'name': EmptyProducer(),
    'style': EmptyProducer(),
    'argumentValue': MapProducer({
      'expression': EmptyProducer(),
      'requiredIf': EmptyProducer(),
      // TODO(brianwilkerson) Figure out how to support 'variables'.
      'variables': EmptyProducer(),
    }),
    'extends': EmptyProducer(),
    'oldName': EmptyProducer(),
    'newName': EmptyProducer(),
  }));

  /// Initialize a newly created suggestion generator for fix data files.
  FixDataGenerator(ResourceProvider resourceProvider) : super(resourceProvider);

  @override
  Producer get topLevelProducer => fixDataProducer;
}
