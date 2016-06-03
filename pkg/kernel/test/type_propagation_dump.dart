import 'package:kernel/kernel.dart';
import 'package:kernel/type_propagation/builder.dart';
import 'package:kernel/type_propagation/constraints.dart';
import 'package:kernel/type_propagation/solver.dart';
import 'package:kernel/type_propagation/visualizer.dart';
import 'package:args/args.dart';
import 'dart:io';

ArgParser parser = new ArgParser()
  ..addFlag('graph', help: 'Generate graphviz dot files')
  ..addFlag('stats',
      help: 'Print times and constraint system size', defaultsTo: true);

String get usage => """
Usage: type_propagation_dump [options] FILE.bart

Options:
${parser.usage}
""";

const String outputDir = 'typegraph';

main(List<String> args) {
  if (args.length == 0) {
    print(usage);
    exit(1);
  }
  ArgResults options = parser.parse(args);
  if (options.rest.length != 1) {
    print('Exactly one file must be given');
    exit(1);
  }
  String path = options.rest.single;

  bool visualize = options['graph'];

  Program program = loadProgramFromBinary(path);
  Stopwatch watch = new Stopwatch()..start();
  Visualizer visualizer = visualize ? new Visualizer(program) : null;
  Builder builder = new Builder(program, visualizer: visualizer);
  int buildTime = watch.elapsedMilliseconds;
  ConstraintSystem constraints = builder.constraints;

  watch..reset();
  var solver = new Solver(builder);
  solver.solve();
  int solveTime = watch.elapsedMilliseconds;

  if (options['graph']) {
    print('Printing graphviz dot files...');
    new Directory(outputDir).createSync();
    void dumpMember(Member member) {
      String name = sanitizeFilename('$member');
      String path = '$outputDir/$name.dot';
      String dotCode = visualizer.dumpMember(member);
      new File(path).writeAsStringSync(dotCode);
    }
    for (var library in program.libraries) {
      library.members.forEach(dumpMember);
      for (var class_ in library.classes) {
        class_.members.forEach(dumpMember);
      }
    }
  }

  // for (Field field in builder.fields.keys) {
  //   int variable = builder.fields[field];
  //   print('$field: ${solver.getVariableValue(variable)}');
  // }

  if (options['stats']) {
    var constraints = solver.constraints;
    int numberOfConstraints = constraints.numberOfAssignments +
        constraints.numberOfLoads +
        constraints.numberOfStores;
    int numberOfTransfers = numberOfConstraints * solver.iterations;
    double transfersPerSecond =
        (numberOfConstraints * solver.iterations) / (solveTime / 1000);
    print("""
Build time:  $buildTime ms
Solve time:  $solveTime ms
Iterations:  ${solver.iterations}

Classes:     ${constraints.numberOfClasses}
Variables:   ${constraints.numberOfVariables}
Assignments: ${constraints.numberOfAssignments}
Loads:       ${constraints.numberOfLoads}
Stores:      ${constraints.numberOfStores}

Transfers:   $numberOfTransfers (${(transfersPerSecond / 1000000).toStringAsFixed(1)} M/s)
  """);
  }
}

String sanitizeFilename(String name) {
  return name
      .replaceAll('::', '.')
      .replaceAll('/', r'$div')
      .replaceAll('(', '')
      .replaceAll(')', '');
}
