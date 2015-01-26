// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

library analyzer.task.general;

import 'package:analyzer/src/generated/error.dart';
import 'package:analyzer/src/generated/source.dart';
import 'package:analyzer/task/model.dart';

/**
 * The analysis errors associated with a target.
 *
 * The value combines errors represented by multiple other results.
 */
// TODO(brianwilkerson) If we want to associate errors with targets smaller than
// a file, we will need other contribution points to collect them. In which case
// we might want to rename this and/or document that it applies to files. For
// that matter, we might also want to have one that applies to Dart files and a
// different one that applies to HTML files, because the list of errors being
// combined is likely to be different.
final ContributionPoint<List<AnalysisError>> ANALYSIS_ERRORS =
    new ContributionPoint<List<AnalysisError>>('ANALYSIS_ERRORS');

/**
 * The contents of a single file.
 */
final ResultDescriptor<String> CONTENT =
    new ResultDescriptor<String>('CONTENT', null);

/**
 * The line information for a single file.
 */
final ResultDescriptor<LineInfo> LINE_INFO =
    new ResultDescriptor<LineInfo>('LINE_INFO', null);

/**
 * The modification time of a file.
 */
final ResultDescriptor<int> MODIFICATION_TIME =
    new ResultDescriptor<int>('MODIFICATION_TIME', -1);

/**
 * The kind of a [Source].
 */
final ResultDescriptor<SourceKind> SOURCE_KIND =
    new ResultDescriptor<SourceKind>('SOURCE_KIND', SourceKind.UNKNOWN);
