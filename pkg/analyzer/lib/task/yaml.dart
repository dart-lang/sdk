// Copyright (c) 2016, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.task.yaml;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/model.dart';
import 'package:yaml/yaml.dart';

/**
 * The result of parsing a YAML file.
 */
final ResultDescriptor<YamlDocument> YAML_DOCUMENT =
    new ResultDescriptor<YamlDocument>('YAML_DOCUMENT', null);

/**
 * The analysis errors associated with a [Source] representing a YAML file.
 */
final ListResultDescriptor<AnalysisError> YAML_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'YAML_ERRORS', AnalysisError.NO_ERRORS);
