// Copyright (c) 2015, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/**
 * Support for client code that extends command-line tools that use the analysis
 * engine by adding new command-line arguments.
 */
library analyzer.plugin.command_line;

import 'package:analyzer/src/plugin/command_line_plugin.dart';
import 'package:args/args.dart';
import 'package:plugin/plugin.dart';

/**
 * The identifier of the extension point that allows plugins to add new flags
 * and options to the command-line parser before the parser is used to parse
 * the command-line. The object used as an extension must be an
 * [ArgParserContributor].
 */
final String PARSER_CONTRIBUTOR_EXTENSION_POINT_ID = Plugin.join(
    CommandLinePlugin.UNIQUE_IDENTIFIER,
    CommandLinePlugin.PARSER_CONTRIBUTOR_EXTENSION_POINT);

/**
 * The identifier of the extension point that allows plugins to access the
 * result of parsing the command-line. The object used as an extension must be
 * an [ArgResultsProcessor].
 */
final String RESULT_PROCESSOR_EXTENSION_POINT_ID = Plugin.join(
    CommandLinePlugin.UNIQUE_IDENTIFIER,
    CommandLinePlugin.RESULT_PROCESSOR_EXTENSION_POINT);

/**
 * A function that will contribute flags and options to the command-line parser.
 */
typedef void ArgParserContributor(ArgParser parser);

/**
 * A function that will process the results of parsing the command-line.
 */
typedef void ArgResultsProcessor(ArgResults results);
