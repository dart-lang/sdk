import 'dart:io';
import 'package:docgen/docgen.dart';
import 'package:args/args.dart';
import 'package:compiler_unsupported/implementation/mirrors/mirrors.dart';
import 'package:compiler_unsupported/implementation/mirrors/mirrors_util.dart';
import 'package:logging/logging.dart';

/**
 * Analyzes Dart files and generates a representation of included libraries, 
 * classes, and members. 
 */
void main() {  
  var results = initArgParser().parse(new Options().arguments);
  new Docgen(argResults: results).analyze(listLibraries(results.rest));
}
