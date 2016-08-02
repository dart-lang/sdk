import 'package:kernel/kernel.dart';
import 'package:kernel/text/ast_to_text.dart';
import 'package:kernel/type_propagation/builder.dart';
import 'package:kernel/type_propagation/solver.dart';
import 'package:kernel/type_propagation/visualizer.dart';
import 'package:kernel/type_propagation/constraints.dart';
import 'package:args/args.dart';
import 'dart:io';

ArgParser parser = new ArgParser()
  ..addFlag('graph', help: 'Generate graphviz dot files')
  ..addOption('graph-filter',
      valueHelp: 'name',
      help: 'Only print graph for members whose name contains the given string')
  ..addFlag('text', help: 'Generate annotated kernel text files')
  ..addFlag('escape', help: 'Dump information from escape analysis')
  ..addFlag('stats',
      help: 'Print times and constraint system size', defaultsTo: true)
  ..addFlag('solve', help: 'Solve the constraint system', defaultsTo: true);

String get usage => """
Usage: dump [options] FILE.dill

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
  bool printEscape = options['escape'];
  bool useVisualizer = printGraphviz || printText || printEscape;

  Program program = loadProgramFromBinary(path);
  Stopwatch watch = new Stopwatch()..start();
  Visualizer visualizer = useVisualizer ? new Visualizer(program) : null;
  Builder builder = new Builder(program, visualizer: visualizer, verbose: true);
  int buildTime = watch.elapsedMilliseconds;

  watch.reset();
  var solver = new Solver(builder);
  if (options['solve']) {
    solver.solve();
  }
  int solveTime = watch.elapsedMilliseconds;
  visualizer?.solver = solver;
  ConstraintSystem constraints = builder.constraints;

  if (printEscape) {
    for (int value = 0; value <= constraints.numberOfValues; ++value) {
      TreeNode node;
      if (value < builder.hierarchy.classes.length) {
        node = builder.hierarchy.classes[value];
      } else {
        FunctionNode function = visualizer.getFunctionFromValue(value);
        if (function == null || function.parent is! Member) continue;
        node = function.parent;
      }
      int escape = solver.getEscapeContext(value);
      String escapeString = (escape == constraints.latticePointOfValue[value])
          ? 'no escape'
          : visualizer.getUnionName(escape);
      print('$node -> $escapeString');
    }
  }

  if (printText) {
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
    String filter = options['graph-filter'];
    new Directory(outputDir).createSync();
    void dumpMember(Member member) {
      if (filter != null && !'$member'.contains(filter)) return;
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
    Iterable<int> outputVariables = [
      builder.global.fields.values,
      builder.global.returns.values,
      builder.global.parameters.values
    ].expand((x) => x);
    int outputCount = outputVariables.length;
    int inferredUnknowns = 0;
    int inferredBottoms = 0;
    int inferredOther = 0;
    for (int variable in outputVariables) {
      int values = solver.getVariableValue(variable);
      if (values == Solver.bottom) {
        ++inferredBottoms;
      } else if (values == Solver.rootClass) {
        ++inferredUnknowns;
      } else {
        ++inferredOther;
      }
    }
    print("""
Build time:  $buildTime ms
Solve time:  $solveTime ms
Iterations:  ${solver.iterations}

Classes:     ${builder.hierarchy.classes.length}
Values:      ${constraints.numberOfValues}
Unions:      ${constraints.numberOfLatticePoints}
Variables:   ${constraints.numberOfVariables}
Fields:      ${builder.fieldNames.length}
Assignments: ${constraints.numberOfAssignments}
Loads:       ${constraints.numberOfLoads}
Stores:      ${constraints.numberOfStores}

Transfers:   $numberOfTransfers (${(transfersPerSecond / 1000000).toStringAsFixed(1)} M/s)

Outputs:     $outputCount
Tops:        $inferredUnknowns (${percent(inferredUnknowns, outputCount)})
Bottoms:     $inferredBottoms (${percent(inferredBottoms, outputCount)})
Other:       $inferredOther (${percent(inferredOther, outputCount)})
  """);
  }
}

String percent(int amount, int total) {
  if (total == 0) return '0%';
  return (amount / total * 100).toStringAsFixed(1) + '%';
}

String sanitizeFilename(String name) {
  return name
      .replaceAll('::', '.')
      .replaceAll('/', r'$div')
      .replaceAll('(', '')
      .replaceAll(')', '');
}
