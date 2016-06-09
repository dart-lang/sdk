import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_propagation/builder.dart';
import 'package:kernel/type_propagation/solver.dart';
import 'package:kernel/type_propagation/visualizer.dart';
import 'package:args/args.dart';
import 'dart:io';

ArgParser parser = new ArgParser()
  ..addFlag('graph', help: 'Generate graphviz dot files')
  ..addFlag('text', help: 'Generate annotated kernel text files')
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

  bool printGraphviz = options['graph'];
  bool printText = options['text'];
  bool useVisualizer = printGraphviz || printText;

  Program program = loadProgramFromBinary(path);
  Stopwatch watch = new Stopwatch()..start();
  Visualizer visualizer = useVisualizer ? new Visualizer(program) : null;
  Builder builder = new Builder(program, visualizer: visualizer, verbose: true);
  int buildTime = watch.elapsedMilliseconds;

  watch.reset();
  var solver = new Solver(builder);
  solver.solve();
  int solveTime = watch.elapsedMilliseconds;
  visualizer?.solver = solver;

  if (options['text']) {
    print('Printing kernel text files...');
    new Directory(outputDir).createSync();
    StringBuffer buffer = new StringBuffer();
    Printer printer =
        new Printer(buffer, annotator: visualizer.getTextAnnotator());
    printer.writeProgramFile(program);
    String path = '$outputDir/program.txt';
    new File(path).writeAsStringSync('$buffer');
  }

  if (printGraphviz) {
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
