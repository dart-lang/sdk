import "dart:io";

import "../test/simple_stats.dart";

void usage([String extraMessage]) {
  print("Usage:");
  print("On Linux via bash you can do something like");
  print("dart pkg/front_end/tool/stat_on_dash_v.dart \ "
      "   now_run_{1..10}.data then_run_{1..10}.data");
  if (extraMessage != null) {
    print("");
    print("Notice:");
    print(extraMessage);
  }
  exit(1);
}

main(List<String> args) {
  if (args.length < 4) {
    usage("Requires more input.");
  }
  // Maps from "part" (or "category" or whatever) =>
  // (map from file group => list of runtimes)
  Map<String, Map<String, List<int>>> data = {};
  Set<String> allGroups = {};
  for (String file in args) {
    File f = new File(file);
    if (!f.existsSync()) usage("$file doesn't exist.");
    String groupId = replaceNumbers(file);
    allGroups.add(groupId);
    String fileContent = f.readAsStringSync();
    List<String> fileLines = fileContent.split("\n");
    Set<String> partsSeen = {};
    for (String line in fileLines) {
      if (!isTimePrependedLine(line)) continue;
      String trimmedLine = line.substring(16).trim();
      String part = replaceNumbers(trimmedLine);
      if (!partsSeen.add(part)) {
        int seen = 2;
        while (true) {
          String newPartName = "$part ($seen)";
          if (partsSeen.add(newPartName)) {
            part = newPartName;
            break;
          }
          seen++;
        }
      }
      int microSeconds = findMs(trimmedLine, inMs: true);
      Map<String, List<int>> groupToTime = data[part] ??= {};
      List<int> times = groupToTime[groupId] ??= [];
      times.add(microSeconds);
    }
  }

  if (allGroups.length < 2) {
    assert(allGroups.length == 1);
    usage("Found only 1 group. At least two are required.");
  }

  Map<String, double> combinedChange = {};

  bool printedAnything = false;
  for (String part in data.keys) {
    Map<String, List<int>> partData = data[part];
    List<int> prevRuntimes;
    String prevGroup;
    bool printed = false;
    for (String group in allGroups) {
      List<int> runtimes = partData[group];
      if (runtimes == null) {
        // Fake it to be a small list of 0s.
        runtimes = new List<int>.filled(5, 0);
        if (!printed) {
          printed = true;
          print("$part:");
        }
        print("Notice: faking data for $group");
      }
      if (prevRuntimes != null) {
        TTestResult result = SimpleTTestStat.ttest(runtimes, prevRuntimes);
        if (result.significant) {
          if (!printed) {
            printed = true;
            print("$part:");
          }
          print("$prevGroup => $group: $result");
          print("$group: $runtimes");
          print("$prevGroup: $prevRuntimes");
          combinedChange["$prevGroup => $group"] ??= 0;
          double leastConfidentChange;
          if (result.diff < 0) {
            leastConfidentChange = result.diff + result.confidence;
          } else {
            leastConfidentChange = result.diff - result.confidence;
          }

          combinedChange["$prevGroup => $group"] += leastConfidentChange;
        }
      }
      prevRuntimes = runtimes;
      prevGroup = group;
    }
    if (printed) {
      print("---");
      printedAnything = true;
    }
  }
  if (printedAnything) {
    for (String part in combinedChange.keys) {
      print("Combined least change for $part: "
          "${combinedChange[part].toStringAsFixed(2)} ms.");
    }
  } else {
    print("Nothing significant found.");
  }
}

/// Returns ms or µs or throws if ms not found.
int findMs(String s, {bool inMs: true}) {
  // Find " in " followed by numbers possibly followed by (a dot and more
  // numbers) followed by "ms"; e.g. " in 42.3ms"

  // This is O(n^2) but it doesn't matter.
  for (int i = 0; i < s.length; i++) {
    int j = 0;
    if (s.codeUnitAt(i + j++) != $SPACE) continue;
    if (s.codeUnitAt(i + j++) != $i) continue;
    if (s.codeUnitAt(i + j++) != $n) continue;
    if (s.codeUnitAt(i + j++) != $SPACE) continue;
    int numberStartsAt = i + j;
    if (!isNumber(s.codeUnitAt(i + j++))) continue;
    while (isNumber(s.codeUnitAt(i + j))) {
      j++;
    }
    // We've seen " is 0+" => we should now either have "ms" or a dot,
    // more numbers followed by "ms".
    if (s.codeUnitAt(i + j) == $m) {
      j++;
      if (s.codeUnitAt(i + j++) != $s) continue;
      // Seen " is 0+ms" => We're done.
      int ms = int.parse(s.substring(numberStartsAt, i + j - 2));
      if (inMs) return ms;
      return ms * 1000;
    } else if (s.codeUnitAt(i + j) == $PERIOD) {
      int dotAt = i + j;
      j++;
      if (!isNumber(s.codeUnitAt(i + j++))) continue;
      while (isNumber(s.codeUnitAt(i + j))) {
        j++;
      }
      if (s.codeUnitAt(i + j++) != $m) continue;
      if (s.codeUnitAt(i + j++) != $s) continue;
      // Seen " is 0+.0+ms" => We're done.
      // int.parse(s.substring(numberStartsAt, i + j - 2));
      int ms = int.parse(s.substring(numberStartsAt, dotAt));
      if (inMs) return ms;
      int fraction = int.parse(s.substring(dotAt + 1, i + j - 2));
      while (fraction < 100) {
        fraction *= 10;
      }
      while (fraction >= 1000) {
        fraction ~/= 10;
      }
      return ms * 1000 + fraction;
    } else {
      continue;
    }
  }
  usage("Didn't find any ms data in line '$s'.");
  throw "usage should exit";
}

const int $SPACE = 32;
const int $PERIOD = 46;
const int $0 = 48;
const int $9 = 57;
const int $COLON = 58;
const int $_ = 95;
const int $i = 105;
const int $m = 109;
const int $n = 110;
const int $s = 115;

/// Check that format is like '0:00:00.000000: '.
bool isTimePrependedLine(String s) {
  if (s.length < 15) return false;
  int index = 0;
  if (!isNumber(s.codeUnitAt(index++))) return false;
  if (s.codeUnitAt(index++) != $COLON) return false;
  if (!isNumber(s.codeUnitAt(index++))) return false;
  if (!isNumber(s.codeUnitAt(index++))) return false;
  if (s.codeUnitAt(index++) != $COLON) return false;
  if (!isNumber(s.codeUnitAt(index++))) return false;
  if (!isNumber(s.codeUnitAt(index++))) return false;
  if (s.codeUnitAt(index++) != $PERIOD) return false;
  for (int i = 0; i < 6; i++) {
    if (!isNumber(s.codeUnitAt(index++))) return false;
  }
  if (s.codeUnitAt(index++) != $COLON) return false;
  return true;
}

bool isNumber(int codeUnit) {
  return codeUnit >= $0 && codeUnit <= $9;
}

String replaceNumbers(String s) {
  StringBuffer sb = new StringBuffer();
  bool lastWasNumber = false;
  for (int i = 0; i < s.length; i++) {
    int codeUnit = s.codeUnitAt(i);
    if (isNumber(codeUnit)) {
      if (!lastWasNumber) {
        // Ignore number; replace with '_'.
        sb.writeCharCode($_);
        lastWasNumber = true;
      }
    } else {
      sb.writeCharCode(codeUnit);
      lastWasNumber = false;
    }
  }
  return sb.toString();
}
