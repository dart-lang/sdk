// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.task.html;

import 'package:analyzer/error/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/model.dart';
import 'package:html/dom.dart';

/**
 * The result of parsing an HTML file.
 */
final ResultDescriptor<Document> HTML_DOCUMENT =
    new ResultDescriptor<Document>('HTML_DOCUMENT', null);

/**
 * The analysis errors associated with a [Source] representing an HTML file.
 */
final ListResultDescriptor<AnalysisError> HTML_ERRORS =
    new ListResultDescriptor<AnalysisError>(
        'HTML_ERRORS', AnalysisError.NO_ERRORS);

/**
 * The sources of the Dart libraries referenced by an HTML file.
 */
final ListResultDescriptor<Source> REFERENCED_LIBRARIES =
    new ListResultDescriptor<Source>('REFERENCED_LIBRARIES', Source.EMPTY_LIST);
