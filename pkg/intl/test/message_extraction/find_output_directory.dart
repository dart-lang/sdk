/**
 * A shared library for finding the valu eof the --output-dir parameter
 * which all of these programs use.
 */
library find_output_directory;

const directiveName = '--output-dir=';

_asString(list) => new String.fromCharCodes(list);

findOutputDirectory(List<String> args) {
  var directive = args.firstWhere(
      (x) => x.contains(directiveName),
      orElse: () => null);
  if (directive == null) return '.';
  var file = directive.codeUnits.skip(directiveName.length);
  return _asString(file);
}

