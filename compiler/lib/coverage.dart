// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

//#library("coverage");

// Dart coverage test
class Coverage{
  static Map<String, Set<String>> coveredFunctions;
  static Map<String, Set<int>> coveredStatements;
  static Map<String, Map<int, Set<int>>> coveredBranches;
  static Set<String> loopBranchTracker;
  static Map<String, int> totalFunctions, totalStatements, totalBranches;

  static void init() {
    coveredFunctions = new HashMap<String, Set<String>>();
    coveredStatements = new HashMap<String, Set<int>>();
    coveredBranches = new HashMap<String, Map<int, Set<int>>>();
    loopBranchTracker = new Set<String>();
    totalFunctions = new HashMap<String, int>();
    totalStatements = new HashMap<String, int>();
    totalBranches = new HashMap<String, int>();
  }

}

// Call for each Dart Unit
void setCoverageTotals(String unit, int numFunctions, int numStatements, 
  int numBranches) {
  if(Coverage.totalFunctions == null){
    Coverage.init();
  }
  Coverage.totalFunctions[unit] = numFunctions;
  Coverage.totalStatements[unit] = numStatements;
  Coverage.totalBranches[unit] = numBranches;
}

void coverFunction(String unitName, String funcName) {
  if(Coverage.coveredFunctions == null) {
    Coverage.init();
  }
  if(Coverage.coveredFunctions[unitName] == null) {
    Coverage.coveredFunctions[unitName] = new Set<String>();
  }
  Coverage.coveredFunctions[unitName].add(funcName);
}

void coverStatement(String unitName, int lineNum) {
  if(Coverage.coveredStatements == null) {
    Coverage.init();
  }
  if(Coverage.coveredStatements[unitName] == null) {
    Coverage.coveredStatements[unitName] = new Set<int>();
  }
  Coverage.coveredStatements[unitName].add(lineNum);
}

void coverBranch(String unitName, int lineNum, int startPos) {
  if(Coverage.coveredBranches == null) {
    Coverage.init();
  }
  if(Coverage.coveredBranches[unitName] == null) {
    Coverage.coveredBranches[unitName] = new HashMap<int, Set<int>>();
  }
  if(Coverage.coveredBranches[unitName][lineNum] == null) {
    Coverage.coveredBranches[unitName][lineNum] = new Set<int>();
  }
  Coverage.coveredBranches[unitName][lineNum].add(startPos);
}

void loopBranchBefore(String unitName, int lineNum, int startPos) {
  Coverage.loopBranchTracker.remove('$unitName,$lineNum,$startPos');
}

void loopBranchInside(String unitName, int lineNum, int startPos) {
  Coverage.loopBranchTracker.add('$unitName,$lineNum,$startPos');
}

void coverLoopBranch(String unitName, int lineNum, int startPos, int endPos) {
  if(Coverage.coveredBranches == null) {
    Coverage.init();
  }
  if(Coverage.coveredBranches[unitName] == null) {
    Coverage.coveredBranches[unitName] = new HashMap<int, Set<int>>();
  }
  if(Coverage.coveredBranches[unitName][lineNum] == null) {
    Coverage.coveredBranches[unitName][lineNum] = new Set<int>();
  }
  
  if(Coverage.loopBranchTracker.contains('$unitName,$lineNum,$startPos')) {
    // Branch that enters loop.
    Coverage.coveredBranches[unitName][lineNum].add(startPos);
  } else {
    // Branch that doesn't enter loop.
    Coverage.coveredBranches[unitName][lineNum].add(endPos);
  }
  
}

void printCoverageSummary() {
  print(getCoverageSummary());
}

String getCoverageSummary() {
  int covFunc = 0, totFunc = 0, covStmt = 0, totStmt = 0, covBr = 0, totBr = 0;
  if(Coverage.totalFunctions != null) {
    for(String unit in Coverage.totalFunctions.getKeys()) {
      if(Coverage.coveredFunctions.containsKey(unit)) {
        covFunc += Coverage.coveredFunctions[unit].length;
      }
      if(Coverage.totalFunctions.containsKey(unit)) {
        totFunc += Coverage.totalFunctions[unit];
      }
    }
  }

  if(Coverage.totalStatements != null) {
    for(String unit in Coverage.totalStatements.getKeys()) {
      if(Coverage.coveredStatements.containsKey(unit)) {
        covStmt += Coverage.coveredStatements[unit].length;
      }
      if(Coverage.totalStatements.containsKey(unit)) {
        totStmt += Coverage.totalStatements[unit];
      }
    }
  }

  if(Coverage.totalBranches != null) {
    for(String unit in Coverage.totalBranches.getKeys()) {
      if(Coverage.coveredBranches.containsKey(unit)) {
        Map<int, Set<int>> brn = Coverage.coveredBranches[unit];
        for(int line in brn.getKeys()) {
          for(int st in brn[line]) {
            covBr++;
          }
        }
      }
      if(Coverage.totalBranches.containsKey(unit)) {
        totBr += Coverage.totalBranches[unit];
      }
    }
  }

  StringBuffer output = new StringBuffer('COVERAGE SUMMARY:\n');
  output.add('Function Coverage = ');
  output.add('$covFunc/$totFunc (${calculatePercent(covFunc,totFunc)}%)\n');
  output.add('Statement Coverage = ');
  output.add('$covStmt/$totStmt (${calculatePercent(covStmt,totStmt)}%)\n');
  output.add('Branch Coverage = ');
  output.add('$covBr/$totBr (${calculatePercent(covBr,totBr)}%)');
  return output.toString();
}

String getCoverageDetails(){
  Set<String> allUnits = new HashSet<String>();
  if(Coverage.totalFunctions != null) {
    allUnits.addAll(Coverage.totalFunctions.getKeys());
  }
  if(Coverage.totalStatements != null) {
    allUnits.addAll(Coverage.totalStatements.getKeys());
  }
  if(Coverage.totalBranches != null) {
    allUnits.addAll(Coverage.totalBranches.getKeys());
  }
  
  StringBuffer coverageDetails = new StringBuffer();
  for(String unit in allUnits) {
    int covFunc = 0, totFunc = 0, covStmt = 0, totStmt = 0, covBr = 0, totBr = 0;
    if(Coverage.totalFunctions != null && 
      Coverage.totalFunctions.containsKey(unit)) {
      if(Coverage.coveredFunctions.containsKey(unit)){
        covFunc = Coverage.coveredFunctions[unit].length;
      }
      totFunc = Coverage.totalFunctions[unit];
    }
    if(Coverage.totalStatements != null && 
      Coverage.totalStatements.containsKey(unit)) {
      if(Coverage.coveredStatements.containsKey(unit)){
        covStmt = Coverage.coveredStatements[unit].length;
      }
      totStmt = Coverage.totalStatements[unit];
    }
    if(Coverage.totalBranches != null && 
      Coverage.totalBranches.containsKey(unit)) {
      if(Coverage.coveredBranches.containsKey(unit)){
        Map<int, Set<int>> brn = Coverage.coveredBranches[unit];
        for(int line in brn.getKeys()) {
          for(int st in brn[line]) {
            covBr++;
          }
        }
      }
      totBr = Coverage.totalBranches[unit];
    }
    coverageDetails.add('<tr> <td>$unit <td> $covFunc/$totFunc ');
    coverageDetails.add('<td> $covStmt/$totStmt <td> $covBr/$totBr\n');
  }
  return coverageDetails.toString();
}

String calculatePercent(int val, int total){
  return (val/total*100).toStringAsPrecision(3);
}

String getString(Map m){
  StringBuffer o = new StringBuffer();
  if(m != null) {
    for(String key in m.getKeys()){
      o.add('$key:${m[key]}\n');
    }
  }
  return o.toString();
}
