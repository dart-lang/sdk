// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

/// This tool builds a program with a deferred graph isomorphic to the provided
/// graph, or generates permutations of bits and the associated files to
/// generate complex deferred graphs.

/// For example, if 5 bits are permuted, we end up with files like:
///   lib1.dart
///   lib2.dart
///   lib3.dart
///   lib4.dart
///   lib5.dart
///   libB.dart
///   lib_000_01.dart
///   lib_000_10.dart
///   lib_001_00.dart
///   lib_010_00.dart
///   lib_100_00.dart
///   main.dart
///
/// Where
///   main.dart contains main().
///   libX.dart contains the actual deferred import of the file with the bit at
///     the X position starting from the left, ie lib1 imports lib_100_00, lib2
///     imports lib_010_00, etc.
///   libImport.dart is the 'top of the diamond' which contains all of the code.
///   lib_XXX_XX.dart invokes all of the functions in libImport which have a
///     1 bit at that position, ie lib_100_00 invokes all code in libImport with
///     a first bit of 1, f100_00, f110_00, etc.
///
/// Note: There are restrictions to what we can generate. Specifically, certain
/// OutputUnits can never be empty, namely we will always generate one file for
/// each entryLib, and because of our dependency on expect, we will always have
/// a file representing the intersection of all import entities. So, for example
/// with three bits, each of 100, 010, 001 and 111 must be present in the graph
/// file, but 110, 101, and 011 are optional.

// TODO(joshualitt): This is a good start for a fuzzer. There is still work to
// do:
// * Emit some classes as const and some not
// * Randomize what we emit as we walk the graph so it is more sparse.

import 'dart:io';
import 'dart:math';
import 'package:dart_style/dart_style.dart' show DartFormatter;

typedef NameFunc = String Function(List<int>, int);

/// A simple constant pass through function for bit strings that don't need
/// special printing, ie stops.
String passThroughNameFunc(List<int> l, int i) => l[i].toString();

/// Generates all permutations of bits recursively.
void generatePermutedNames(
    Map<int, List<List<int>>> names, int maxBit, List<int> bits, int bit) {
  if (bit == maxBit) {
    for (int i = 0; i < bits.length; i++) {
      if (bits[i] == 1) {
        names.putIfAbsent(i, () => []);
        names[i]!.add(List.from(bits));
      }
    }
    return;
  }
  generatePermutedNames(names, maxBit, bits, bit + 1);
  bits[bit] = 1;
  generatePermutedNames(names, maxBit, bits, bit + 1);
  bits[bit] = 0;
}

/// A helper function to generate names from lists of strings of bits.
int namesFromGraphFileLines(
    List<String> lines, Map<int, List<List<int>>> names) {
  int maxBit = 0;
  for (var line in lines) {
    List<int> name = [];
    // Each line should have the same length.
    assert(maxBit == 0 || maxBit == line.length);
    maxBit = max(maxBit, line.length);
    for (int i = 0; i < line.length; i++) {
      var bit = line[i];
      if (bit == '1') {
        name.add(1);
        (names[i] ??= []).add(name);
      } else {
        name.add(0);
      }
    }
  }
  return maxBit;
}

/// Parses names from a graph file dumped from dart2js and returns the max bit.
int namesFromGraphFile(String graphFile, Map<int, List<List<int>>> names) {
  var lines = File(graphFile).readAsLinesSync();
  return namesFromGraphFileLines(lines, names);
}

class ImportData {
  String import;
  String entryPoint;

  ImportData(this.import, this.entryPoint);
}

class GraphIsomorphizer {
  /// The output directory, only relevant if files are written out.
  final String outDirectory;

  /// Various buffers for the files the GraphIsomorphizer generates.
  StringBuffer rootImportBuffer = StringBuffer();
  StringBuffer mainBuffer = StringBuffer();
  Map<String, StringBuffer> mixerLibBuffers = {};
  Map<String, StringBuffer> entryLibBuffers = {};

  /// A map of bit positions to lists of bit lists.
  final Map<int, List<List<int>>> names;

  /// A map of bit positions to lists of class names.
  final Map<int, List<String>> classNames = {};
  final Map<int, List<String>> mixerClassNames = {};

  /// A map of bit positions to lists of mixin names.
  final Map<int, List<String>> mixinNames = {};

  /// A map of bit positions to lists of class names used only as types.
  final Map<int, List<String>> typeNames = {};
  final Map<int, List<String>> mixerTypeNames = {};
  final Map<int, List<String>> closureNames = {};

  /// We will permute bits up until the maximum bit.
  int maxBit = 0;

  /// The 'top of the diamond' import file containing all code.
  final String rootImportFilename = 'libImport.dart';

  /// The main filename.
  final String mainFilename = 'main.dart';

  /// A bool to omit the comment block.
  final bool skipCopyright;

  // A bool to generate simple code within test files.
  final bool simple;

  GraphIsomorphizer(this.names, this.maxBit,
      {this.outDirectory = '.',
      this.skipCopyright = false,
      this.simple = false});

  void noInlineDecorator(StringBuffer out) {
    out.write("@pragma('dart2js:noInline')\n");
  }

  void importExpect(StringBuffer out) {
    out.write('import "package:expect/expect.dart";\n\n');
  }

  void newline(StringBuffer out) {
    out.write('\n');
  }

  /// Generates the header for a file.
  void generateHeader(StringBuffer out) {
    if (!skipCopyright) {
      out.write("""
// Copyright (c) 2021, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

// This file was autogenerated by the pkg/compiler/tool/graph_isomorphizer.dart.
""");
    }
  }

  /// Generates the root import, where classes, types, mixins, and closures
  /// live.
  void generateRootImport(StringBuffer out) {
    generateHeader(out);
    importExpect(out);

    // We verify that each function in libImport is invoked only once from each
    // mixerLib and that only the correct functions are called, ie for lib_001,
    // only functions with XX1 are invoked.
    out.write('void v(Set<String> u, String name, int bit) {\n' +
        '  Expect.isTrue(u.add(name));\n' +
        "  Expect.equals(name[bit], '1');\n" +
        '}\n\n');

    // Sort the names to ensure they are in a canonical order.
    var nameKeys = names.keys.toList();
    nameKeys.sort();

    Set<String> uniques = {};
    if (!simple) {
      // Generate the 'base' classes, mixins, and types which will be combined to
      // generate hierarchies. Also generate a const instance per class and a closure
      // to invoke.
      for (var bitPosition in nameKeys) {
        var bitsList = names[bitPosition]!;
        for (var bits in bitsList) {
          var name = generateBitString(bits);
          if (!uniques.add(name)) continue;
          String className = 'C$name';
          String mixinName = 'M$name';
          String typeName = 'T$name';
          (classNames[bitPosition] ??= []).add(className);
          (mixinNames[bitPosition] ??= []).add(mixinName);
          (typeNames[bitPosition] ??= []).add(typeName);
          (mixerClassNames[bitPosition] ??= []).add(className);
          (mixerTypeNames[bitPosition] ??= []).add(typeName);
          out.write('class $className { const $className(); }\n');
          out.write('mixin $mixinName {}\n');
          out.write('class $typeName {}\n');
          out.write('const $className i$className = const $className();\n');
          out.write('closure$className(foo) => ($className unused) ');
          out.write('=> i$className.toString() == foo.toString();\n');
        }
      }

      // Generate combined classes and types, as well as const instances and
      // closures.
      newline(out);
      uniques = {};
      for (var bitPosition in nameKeys) {
        var bitsList = names[bitPosition]!;
        for (var bits in bitsList) {
          var name = generateBitString(bits);
          var bitCount = bits.reduce((a, b) => a + b);
          var baseName = 'C$name';
          if (!uniques.add(baseName)) continue;
          if (bitCount > 1) {
            List<String> classes = [];
            List<String> mixins = [];
            List<String> types = [];
            for (int i = 0; i < bits.length; i++) {
              if (bits[i] == 1) {
                classes.addAll(classNames[i]!);
                mixins.addAll(mixinNames[i]!);
                types.addAll(typeNames[i]!);
              }
            }
            String mixinString = mixins.join(', ');
            int count = 1;
            assert(classes.length == types.length);
            for (int i = 0; i < classes.length; i++) {
              var cls = classes[i];
              var type = types[i];
              List<String> classImpls = [];
              List<String> typeImpls = [];
              if (i > 0) {
                classImpls.addAll(classes.sublist(0, i));
                typeImpls.addAll(types.sublist(0, i));
              }
              if (i < classes.length - 1) {
                classImpls.addAll(classes.sublist(i + 1));
                typeImpls.addAll(types.sublist(i + 1));
              }
              var classImplementsString = classImpls.join(', ');
              String className = '${baseName}_class_${count}';
              out.write('class $className extends $cls with $mixinString ');
              out.write(
                  'implements $classImplementsString { const $className(); }\n');
              out.write('const $className i$className = const $className();\n');
              out.write('closure$className(foo) => ($className unused) ');
              out.write('=> i$className.toString() == foo.toString();\n');

              var typeImplementsString = typeImpls.join(', ');
              String typeName = 'T${name}_type__${count}';
              out.write('class $typeName extends $type with $mixinString ');
              out.write('implements $typeImplementsString {}\n');
              for (int i = 0; i < bits.length; i++) {
                if (bits[i] == 1) {
                  mixerClassNames[i]!.add(className);
                  mixerTypeNames[i]!.add(typeName);
                }
              }
              count++;
            }
          }
        }
      }
    }

    // Generate functions.
    newline(out);
    uniques = {};
    for (var name in nameKeys) {
      var bitsList = names[name]!;
      for (var bits in bitsList) {
        var name = generateBitString(bits);
        if (uniques.add(name)) {
          noInlineDecorator(out);
          var stringBits = generateBitString(bits, withStops: false);
          out.write(
              "f$name(Set<String> u, int b) => v(u, '$stringBits', b);\n");
        }
      }
    }
  }

  /// Generates a mixerLib which will be loaded as a deferred library from an entryLib.
  void generateMixerLib(
      String name, StringBuffer out, String import, List<int> bits, int bit) {
    generateHeader(out);
    importExpect(out);
    out.write("import '$import';\n\n");

    if (!simple) {
      // create type test.
      noInlineDecorator(out);
      out.write('typeTest(dynamic t) {\n');
      for (var type in mixerTypeNames[bit]!) {
        out.write('  if (t is $type) { return true; }\n');
      }
      out.write('  return false;\n');
      out.write('}\n\n');
    }

    noInlineDecorator(out);
    out.write('g$name() {\n');

    if (!simple) {
      out.write('  // C${generateCommentName(bits, bit)};\n');

      // Construct new instances of each class and pass them to the typeTest
      for (var cls in mixerClassNames[bit]!) {
        out.write('  Expect.isFalse(typeTest($cls()));\n');
      }
      newline(out);

      // Invoke the test closure for each class.
      for (var cls in mixerClassNames[bit]!) {
        out.write('  Expect.isTrue(closure$cls($cls())($cls()));\n');
      }
      newline(out);

      // Verify the runtimeTypes of the closures haven't been mangled.
      for (var cls in mixerClassNames[bit]!) {
        out.write(
            '  Expect.equals(closure$cls($cls()).runtimeType.toString(), ');
        out.write("'($cls) => bool');\n");
      }
    }
    newline(out);

    // Collect the names so we can sort them and put them in a canonical order.
    int count = 0;
    List<String> namesBits = [];
    names[bit]!.forEach((nameBits) {
      var nameString = generateBitString(nameBits);
      namesBits.add(nameString);
      count++;
    });

    out.write('  Set<String> uniques = {};\n\n'
        '  // f${generateCommentName(bits, bit)};\n');

    namesBits.sort();
    for (var name in namesBits) {
      out.write('  f$name(uniques, $bit);\n');
    }

    // We expect 'count' unique strings added to be added to 'uniques'.
    out.write("  Expect.equals($count, uniques.length);\n"
        '}\n');
  }

  /// Generates a string of bits, with optional parameters to control how the
  /// bits print.
  String generateBitString(List<int> bits,
      {NameFunc f = passThroughNameFunc, bool withStops = true}) {
    int stop = 0;
    StringBuffer sb = StringBuffer();
    for (int i = 0; i < bits.length; i++) {
      if (stop++ % 3 == 0 && withStops) {
        sb.write('_');
      }
      sb.write(f(bits, i));
    }
    return sb.toString();
  }

  /// Generates a pretty bit string for use in comments.
  String generateCommentName(List<int> bits, int fixBit) {
    return generateBitString(bits,
        f: (List<int> bits, int bit) => bit == fixBit ? '1' : '*');
  }

  /// Generates an entryLib file.
  void generateEntryLib(StringBuffer out, String mainName, String funcName,
      String import, int bit) {
    generateHeader(out);
    var name = 'b$bit';
    out.write("import '$import' deferred as $name;\n\n"
        '$mainName async {\n'
        '  await $name.loadLibrary();\n'
        '  $name.g$funcName();\n'
        '}\n');
  }

  /// Generates entry and mixer libs for the supplied names.
  List<ImportData> generateEntryAndMixerLibs() {
    // Generates each lib_XXX.dart and the associated entryLib file.
    List<ImportData> importData = [];
    for (int i = 1; i <= maxBit; i++) {
      // Generate the bit list representing this library. ie a list of all
      // 0s with a single 1 bit flipped.
      int oneBit = i - 1;
      List<int> bits = [];
      for (int j = 0; j < maxBit; j++) bits.add(j == oneBit ? 1 : 0);

      // Generate the mixerLib for this entryLib.
      var name = generateBitString(bits);
      var mixerLibBuffer = StringBuffer();
      var mixerLibName = "lib$name.dart";
      generateMixerLib(name, mixerLibBuffer, rootImportFilename, bits, oneBit);
      mixerLibBuffers[mixerLibName] = mixerLibBuffer;

      // Generate the entryLib for this mixerLib.
      var entryLibName = 'lib$i.dart';
      var entryFuncName = 'entryLib$i()';
      var entryLibBuffer = StringBuffer();
      generateEntryLib(entryLibBuffer, entryFuncName, name, mixerLibName, i);
      entryLibBuffers[entryLibName] = entryLibBuffer;

      // Stash the entry point in entryLib for later reference in the main file.
      importData.add(ImportData(entryLibName, entryFuncName));
    }
    return importData;
  }

  /// Generates the main file.
  void generateMain(StringBuffer out, List<ImportData> importData) {
    generateHeader(mainBuffer);
    for (var data in importData) {
      out.write("import '${data.import}';\n");
    }
    out.write('\n'
        'main() {\n');
    for (var data in importData) {
      out.write('  ${data.entryPoint};\n');
    }
    out.write('}\n');
  }

  /// Generates all files into buffers.
  void generateFiles() {
    generateRootImport(rootImportBuffer);
    var importData = generateEntryAndMixerLibs();
    generateMain(mainBuffer, importData);
  }

  /// Helper to dump contents to file.
  void writeToFile(String filename, StringBuffer contents) {
    var file = File(this.outDirectory + '/' + filename);
    file.createSync(recursive: true);
    var sink = file.openWrite();
    sink.write(DartFormatter().format(contents.toString()));
    sink.close();
  }

  /// Writes all buffers to files.
  void writeFiles() {
    mixerLibBuffers.forEach(writeToFile);
    entryLibBuffers.forEach(writeToFile);
    writeToFile(rootImportFilename, rootImportBuffer);
    writeToFile(mainFilename, mainBuffer);
  }

  /// Generate and write files.
  void run() {
    generateFiles();
    writeFiles();
  }
}

/// Creates a GraphIsomorphizer based on the provided args.
GraphIsomorphizer createGraphIsomorphizer(List<String> args) {
  bool simple = true;
  int maxBit = 0;
  String graphFile = '';
  String outDirectory = '.';

  for (var arg in args) {
    if (arg.startsWith('--max-bit')) {
      maxBit = int.parse(arg.substring('--max-bit='.length));
    }
    if (arg.startsWith('--graph-file')) {
      graphFile = arg.substring('--graph-file='.length);
    }
    if (arg.startsWith('--out-dir')) {
      outDirectory = arg.substring('--out-dir='.length);
    }
    if (arg == '--simple') {
      simple = true;
    }
  }

  // If we don't have a graphFile, then we generate all permutations of bits up
  // to maxBit.
  Map<int, List<List<int>>> names = {};
  if (graphFile.isEmpty) {
    List<int> bits = List.filled(maxBit, 0);
    generatePermutedNames(names, maxBit, bits, 0);
  } else {
    maxBit = namesFromGraphFile(graphFile, names);
  }
  return GraphIsomorphizer(names, maxBit,
      outDirectory: outDirectory, simple: simple);
}

void main(List<String> args) {
  var graphIsomorphizer = createGraphIsomorphizer(args);
  graphIsomorphizer.run();
}
