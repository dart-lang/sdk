import 'dart:io' show File;

import '../test/binary_md_dill_reader.dart' show DillComparer;

import '../test/utils/io_utils.dart' show computeRepoDir;

main(List<String> args) {
  if (args.length != 2) {
    throw "Expects two arguments: The two files to compare";
  }
  File fileA = new File(args[0]);
  File fileB = new File(args[1]);

  List<int> a = fileA.readAsBytesSync();
  List<int> b = fileB.readAsBytesSync();

  bool shouldCompare = false;
  if (a.length != b.length) {
    print("Input lengths are different.");
    shouldCompare = true;
  } else {
    for (int i = 0; i < a.length; ++i) {
      if (a[i] != b[i]) {
        print("Data differs at byte ${i + 1}.");
        shouldCompare = true;
        break;
      }
    }
  }

  if (shouldCompare) {
    StringBuffer message = new StringBuffer();
    final String repoDir = computeRepoDir();
    File binaryMd = new File("$repoDir/pkg/kernel/binary.md");
    String binaryMdContent = binaryMd.readAsStringSync();

    DillComparer dillComparer = new DillComparer();
    if (dillComparer.compare(a, b, binaryMdContent, message)) {
      message.writeln(
          "Somehow the two different byte-lists compared to the same.");
    }

    print(message);
  } else {
    print("Inputs byte-equal!");
  }
}
