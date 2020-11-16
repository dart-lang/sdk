// Copyright (c) 2020, the Dart project authors. Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'package:analysis_server/src/services/completion/yaml/producer.dart';
import 'package:analysis_server/src/services/completion/yaml/yaml_completion_generator.dart';
import 'package:analyzer/file_system/file_system.dart';

/// A completion generator that can produce completion suggestions for pubspec
/// files.
class PubspecGenerator extends YamlCompletionGenerator {
  /// The producer representing the known valid structure of a pubspec file.
  static const MapProducer pubspecProducer = MapProducer({
    'name': EmptyProducer(),
    'version': EmptyProducer(),
    'description': EmptyProducer(),
    'homepage': EmptyProducer(),
    'repository': EmptyProducer(),
    'issue_tracker': EmptyProducer(),
    'documentation': EmptyProducer(),
    'executables': EmptyProducer(),
    'publish_to': EmptyProducer(),
    'environment': MapProducer({
      'flutter': EmptyProducer(),
      'sdk': EmptyProducer(),
    }),
    'dependencies': EmptyProducer(),
    'dev_dependencies': EmptyProducer(),
    // TODO(brianwilkerson) Suggest names already listed under 'dependencies'
    //  and 'dev_dependencies'.
    'dependency_overrides': EmptyProducer(),
  });

  /// Initialize a newly created suggestion generator for pubspec files.
  PubspecGenerator(ResourceProvider resourceProvider) : super(resourceProvider);

  @override
  Producer get topLevelProducer => pubspecProducer;
}
