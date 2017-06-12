// Copyright (c) 2012, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

import 'dart:isolate';
import 'dart:async';

class Expect {
  static void equals(x, y) {
    if (x != y) throw new ArgumentError('not equal');
  }
}

class Fields {
  Fields(int i, int j)
      : fld1 = i,
        fld2 = j,
        fld5 = true {}
  int fld1;
  final int fld2;
  static int fld3;
  static const int fld4 = 10;
  bool fld5;
}

class FieldsTest {
  static Fields testMain() {
    Fields obj = new Fields(10, 20);
    Expect.equals(10, obj.fld1);
    Expect.equals(20, obj.fld2);
    Expect.equals(10, Fields.fld4);
    Expect.equals(true, obj.fld5);
    return obj;
  }
}
// Benchpress: A collection of micro-benchmarks.
// Ported from internal v8 benchmark suite.

class Error {
  static void error(String msg) {
    throw msg;
  }
}

// F i b o n a c c i
class Fibonacci {
  static int fib(int n) {
    if (n <= 1) return 1;
    return fib(n - 1) + fib(n - 2);
  }
}

class FibBenchmark extends BenchmarkBase {
  const FibBenchmark() : super("Fibonacci");

  void warmup() {
    Fibonacci.fib(10);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    var result = Fibonacci.fib(20);
    if (result != 10946)
      Error.error("Wrong result: $result. Should be: 10946.");
  }

  static void main() {
    new FibBenchmark().report();
  }
}

// L o o p
class Loop {
  static int loop(int outerIterations) {
    int sum = 0;
    for (int i = 0; i < outerIterations; i++) {
      for (int j = 0; j < 100; j++) {
        sum++;
      }
    }
    return sum;
  }
}

class LoopBenchmark extends BenchmarkBase {
  const LoopBenchmark() : super("Loop");

  void warmup() {
    Loop.loop(10);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    var result = Loop.loop(200);
    if (result != 20000) Error.error("Wrong result: $result. Should be: 20000");
  }

  static void main() {
    new LoopBenchmark().report();
  }
}

// T o w e r s
class TowersDisk {
  final int size;
  TowersDisk next;

  TowersDisk(size)
      : this.size = size,
        next = null {}
}

class Towers {
  List<TowersDisk> piles;
  int movesDone;
  Towers(int disks)
      : piles = new List<TowersDisk>(3),
        movesDone = 0 {
    build(0, disks);
  }

  void build(int pile, int disks) {
    for (var i = disks - 1; i >= 0; i--) {
      push(pile, new TowersDisk(i));
    }
  }

  void push(int pile, TowersDisk disk) {
    TowersDisk top = piles[pile];
    if ((top != null) && (disk.size >= top.size))
      Error.error("Cannot put a big disk on a smaller disk.");
    disk.next = top;
    piles[pile] = disk;
  }

  TowersDisk pop(int pile) {
    var top = piles[pile];
    if (top == null)
      Error.error("Attempting to remove a disk from an empty pile.");
    piles[pile] = top.next;
    top.next = null;
    return top;
  }

  void moveTop(int from, int to) {
    push(to, pop(from));
    movesDone++;
  }

  void move(int from, int to, int disks) {
    if (disks == 1) {
      moveTop(from, to);
    } else {
      int other = 3 - from - to;
      move(from, other, disks - 1);
      moveTop(from, to);
      move(other, to, disks - 1);
    }
  }
}

class TowersBenchmark extends BenchmarkBase {
  const TowersBenchmark() : super("Towers");

  void warmup() {
    new Towers(6).move(0, 1, 6);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    var towers = new Towers(13);
    towers.move(0, 1, 13);
    if (towers.movesDone != 8191) {
      var moves = towers.movesDone;
      Error.error("Error in result: $moves should be: 8191");
    }
  }

  static void main() {
    new TowersBenchmark().report();
  }
}

// S i e v e
class SieveBenchmark extends BenchmarkBase {
  const SieveBenchmark() : super("Sieve");

  static int sieve(int size) {
    int primeCount = 0;
    List<bool> flags = new List<bool>(size + 1);
    for (int i = 1; i < size; i++) flags[i] = true;
    for (int i = 2; i < size; i++) {
      if (flags[i]) {
        primeCount++;
        for (int k = i + 1; k <= size; k += i) flags[k - 1] = false;
      }
    }
    return primeCount;
  }

  void warmup() {
    sieve(100);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    int result = sieve(1000);
    if (result != 168) Error.error("Wrong result: $result should be: 168");
  }

  static void main() {
    new SieveBenchmark().report();
  }
}

// P e r m u t e
// The original benchmark uses one-based indexing. Even though arrays in JS and
// lists in dart are zero-based, we stay with one-based indexing
// (wasting one element).
class Permute {
  int permuteCount;
  Permute() {}

  void swap(int n, int k, List<int> list) {
    int tmp = list[n];
    list[n] = list[k];
    list[k] = tmp;
  }

  void doPermute(int n, List<int> list) {
    permuteCount++;
    if (n != 1) {
      doPermute(n - 1, list);
      for (int k = n - 1; k >= 1; k--) {
        swap(n, k, list);
        doPermute(n - 1, list);
        swap(n, k, list);
      }
    }
  }

  int permute(int size) {
    permuteCount = 0;
    List<int> list = new List<int>(size);
    for (int i = 1; i < size; i++) list[i] = i - 1;
    doPermute(size - 1, list);
    return permuteCount;
  }
}

class PermuteBenchmark extends BenchmarkBase {
  const PermuteBenchmark() : super("Permute");

  void warmup() {
    new Permute().permute(4);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    int result = new Permute().permute(8);
    if (result != 8660) Error.error("Wrong result: $result should be: 8660");
  }

  static void main() {
    new PermuteBenchmark().report();
  }
}

// Q u e e n s
// The original benchmark uses one-based indexing. Even though arrays in JS and
// lists in dart are zero-based, we stay with one-based indexing
// (wasting one element).
class Queens {
  static bool tryQueens(
      int i, List<bool> a, List<bool> b, List<bool> c, List<int> x) {
    int j = 0;
    bool q = false;
    while ((!q) && (j != 8)) {
      j++;
      q = false;
      if (b[j] && a[i + j] && c[i - j + 7]) {
        x[i] = j;
        b[j] = false;
        a[i + j] = false;
        c[i - j + 7] = false;
        if (i < 8) {
          q = tryQueens(i + 1, a, b, c, x);
          if (!q) {
            b[j] = true;
            a[i + j] = true;
            c[i - j + 7] = true;
          }
        } else {
          q = true;
        }
      }
    }
    return q;
  }

  static void queens() {
    List<bool> a = new List<bool>(9);
    List<bool> b = new List<bool>(17);
    List<bool> c = new List<bool>(15);
    List<int> x = new List<int>(9);
    b[1] = false;
    for (int i = -7; i <= 16; i++) {
      if ((i >= 1) && (i <= 8)) a[i] = true;
      if (i >= 2) b[i] = true;
      if (i <= 7) c[i + 7] = true;
    }

    if (!tryQueens(1, b, a, c, x)) Error.error("Error in queens");
  }
}

class QueensBenchmark extends BenchmarkBase {
  const QueensBenchmark() : super("Queens");

  void warmup() {
    Queens.queens();
  }

  void exercise() {
    Queens.queens();
  }

  static void main() {
    new QueensBenchmark().report();
  }
}

// R e c u r s e
class Recurse {
  static int recurse(int n) {
    if (n <= 0) return 1;
    recurse(n - 1);
    return recurse(n - 1);
  }
}

class RecurseBenchmark extends BenchmarkBase {
  const RecurseBenchmark() : super("Recurse");

  void warmup() {
    Recurse.recurse(7);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    Recurse.recurse(13);
  }

  static void main() {
    new RecurseBenchmark().report();
  }
}

// S u m
class SumBenchmark extends BenchmarkBase {
  const SumBenchmark() : super("Sum");

  static int sum(int start, int end) {
    var sum = 0;
    for (var i = start; i <= end; i++) sum += i;
    return sum;
  }

  void warmup() {
    sum(1, 1000);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    int result = sum(1, 10000);
    if (result != 50005000)
      Error.error("Wrong result: $result should be 50005000");
  }

  static void main() {
    new SumBenchmark().report();
  }
}

// H e l p e r   f u n c t i o n s   f o r   s o r t s
class Random {
  static const int INITIAL_SEED = 74755;
  int seed;
  Random() : seed = INITIAL_SEED {}

  int random() {
    seed = ((seed * 1309) + 13849) % 65536;
    return seed;
  }
}

//
class SortData {
  List<int> list;
  int min;
  int max;

  SortData(int length) {
    Random r = new Random();
    list = new List<int>(length);
    for (int i = 0; i < length; i++) list[i] = r.random();

    int min, max;
    min = max = list[0];
    for (int i = 0; i < length; i++) {
      int e = list[i];
      if (e > max) max = e;
      if (e < min) min = e;
    }

    this.min = min;
    this.max = max;
  }

  void check() {
    List<int> a = list;
    int len = a.length;
    if ((a[0] != min) || a[len - 1] != max) Error.error("List is not sorted");
    for (var i = 1; i < len; i++) {
      if (a[i - 1] > a[i]) Error.error("List is not sorted");
    }
  }
}

// B u b b l e S o r t
class BubbleSort {
  static void sort(List<int> a) {
    int len = a.length;
    for (int i = len - 2; i >= 0; i--) {
      for (int j = 0; j <= i; j++) {
        int c = a[j];
        int n = a[j + 1];
        if (c > n) {
          a[j] = n;
          a[j + 1] = c;
        }
      }
    }
  }
}

class BubbleSortBenchmark extends BenchmarkBase {
  const BubbleSortBenchmark() : super("BubbleSort");

  void warmup() {
    SortData data = new SortData(30);
    BubbleSort.sort(data.list);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    SortData data = new SortData(130);
    BubbleSort.sort(data.list);
    data.check();
  }

  static void main() {
    new BubbleSortBenchmark().report();
  }
}

// Q u i c k S o r t
class QuickSort {
  static void sort(List<int> a, int low, int high) {
    int pivot = a[(low + high) >> 1];
    int i = low;
    int j = high;
    while (i <= j) {
      while (a[i] < pivot) i++;
      while (pivot < a[j]) j--;
      if (i <= j) {
        int tmp = a[i];
        a[i] = a[j];
        a[j] = tmp;
        i++;
        j--;
      }
    }

    if (low < j) sort(a, low, j);
    if (i < high) sort(a, i, high);
  }
}

class QuickSortBenchmark extends BenchmarkBase {
  const QuickSortBenchmark() : super("QuickSort");

  void warmup() {
    SortData data = new SortData(100);
    QuickSort.sort(data.list, 0, data.list.length - 1);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    SortData data = new SortData(800);
    QuickSort.sort(data.list, 0, data.list.length - 1);
    data.check();
  }

  static void main() {
    new QuickSortBenchmark().report();
  }
}

// T r e e S o r t
class TreeNodePress {
  int value;
  TreeNodePress left;
  TreeNodePress right;

  TreeNodePress(int n) : value = n {}

  void insert(int n) {
    if (n < value) {
      if (left == null)
        left = new TreeNodePress(n);
      else
        left.insert(n);
    } else {
      if (right == null)
        right = new TreeNodePress(n);
      else
        right.insert(n);
    }
  }

  void check() {
    TreeNodePress left = this.left;
    TreeNodePress right = this.right;
    int value = this.value;

    return ((left == null) || ((left.value < value) && left.check())) &&
        ((right == null) || ((right.value >= value) && right.check()));
  }
}

class TreeSort {
  static void sort(List<int> a) {
    int len = a.length;
    TreeNodePress tree = new TreeNodePress(a[0]);
    for (var i = 1; i < len; i++) tree.insert(a[i]);
    if (!tree.check()) Error.error("Invalid result, tree not sorted");
  }
}

class TreeSortBenchmark extends BenchmarkBase {
  const TreeSortBenchmark() : super("TreeSort");

  void warmup() {
    TreeSort.sort(new SortData(100).list);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    TreeSort.sort(new SortData(1000).list);
  }
}

// T a k
class TakBenchmark extends BenchmarkBase {
  const TakBenchmark() : super("Tak");

  static void tak(int x, int y, int z) {
    if (y >= x) return z;
    return tak(tak(x - 1, y, z), tak(y - 1, z, x), tak(z - 1, x, y));
  }

  void warmup() {
    tak(9, 6, 3);
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    tak(18, 12, 6);
  }

  static void main() {
    new TakBenchmark().report();
  }
}

// T a k l
class ListElement {
  final int length;
  final ListElement next;

  const ListElement(int length, ListElement next)
      : this.length = length,
        this.next = next;

  static ListElement makeList(int length) {
    if (length == 0) return null;
    return new ListElement(length, makeList(length - 1));
  }

  static bool isShorter(ListElement x, ListElement y) {
    ListElement xTail = x;
    ListElement yTail = y;
    while (yTail != null) {
      if (xTail == null) return true;
      xTail = xTail.next;
      yTail = yTail.next;
    }
    return false;
  }
}

class Takl {
  static ListElement takl(ListElement x, ListElement y, ListElement z) {
    if (ListElement.isShorter(y, x)) {
      return takl(takl(x.next, y, z), takl(y.next, z, x), takl(z.next, x, y));
    } else {
      return z;
    }
  }
}

class TaklBenchmark extends BenchmarkBase {
  const TaklBenchmark() : super("Takl");

  void warmup() {
    Takl.takl(ListElement.makeList(8), ListElement.makeList(4),
        ListElement.makeList(3));
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    ListElement result = Takl.takl(ListElement.makeList(15),
        ListElement.makeList(10), ListElement.makeList(6));
    if (result.length != 10) {
      int len = result.length;
      Error.error("Wrong result: $len should be: 10");
    }
  }

  static void main() {
    new TaklBenchmark().report();
  }
}

// M a i n

class BenchPress {
  static void mainWithArgs(List<String> args) {
    List<BenchmarkBase> benchmarks = [
      new BubbleSortBenchmark(),
      new FibBenchmark(),
      new LoopBenchmark(),
      new PermuteBenchmark(),
      new QueensBenchmark(),
      new QuickSortBenchmark(),
      new RecurseBenchmark(),
      new SieveBenchmark(),
      new SumBenchmark(),
      new TakBenchmark(),
      new TaklBenchmark(),
      new TowersBenchmark(),
      new TreeSortBenchmark(),
    ];
    if (args.length > 0) {
      String benchName = args[0];
      bool foundBenchmark = false;
      benchmarks.forEach((bench) {
        if (bench.name == benchName) {
          foundBenchmark = true;
          bench.report();
        }
      });
      if (!foundBenchmark) {
        Error.error("Benchmark not found: $benchName");
      }
      return;
    }
    double logMean = 0.0;
    benchmarks.forEach((bench) {
      double benchScore = bench.measure();
      String name = bench.name;
      print("$name: $benchScore");
      logMean += Math.log(benchScore);
    });
    logMean = logMean / benchmarks.length;
    double score = Math.pow(Math.E, logMean);
    print("BenchPress (average): $score");
  }

  // TODO(floitsch): let main accept arguments from the command line.
  static void main() {
    mainWithArgs([]);
  }
}

class BenchmarkBase {
  final String name;

  // Empty constructor.
  const BenchmarkBase(String name) : this.name = name;

  // The benchmark code.
  // This function is not used, if both [warmup] and [exercise] are overwritten.
  void run() {}

  // Runs a short version of the benchmark. By default invokes [run] once.
  void warmup() {
    run();
  }

  // Exercices the benchmark. By default invokes [run] 10 times.
  void exercise() {
    for (int i = 0; i < 10; i++) {
      run();
    }
  }

  // Not measured setup code executed prior to the benchmark runs.
  void setup() {}

  // Not measures teardown code executed after the benchmark runs.
  void teardown() {}

  // Measures the score for this benchmark by executing it repeately until
  // time minimum has been reached.
  static double measureFor(Function f, int timeMinimum) {
    int time = 0;
    int iter = 0;
    DateTime start = new DateTime.now();
    while (time < timeMinimum) {
      f();
      time = (new DateTime.now().difference(start)).inMilliseconds;
      iter++;
    }
    // Force double result by using a double constant.
    return (1000.0 * iter) / time;
  }

  // Measures the score for the benchmark and returns it.
  double measure() {
    setup();
    // Warmup for at least 100ms. Discard result.
    measureFor(() {
      this.warmup();
    }, -100);
    // Run the benchmark for at least 2000ms.
    double result = measureFor(() {
      this.exercise();
    }, -2000);
    teardown();
    return result;
  }

  void report() {
    double score = measure();
    print("name: $score");
  }
}

class Logger {
  static print(object) {
    printobject(object);
  }

  static printobject(obj) {}
}

//
// Dromaeo ObjectString
// Adapted from Mozilla JavaScript performance test suite.
// Microtests of strings (concatenation, methods).

class ObjectString extends BenchmarkBase {
  const ObjectString() : super("Dromaeo.ObjectString");

  static void main() {
    new ObjectString().report();
  }

  static void print(String str) {
    print(str);
  }

  String getRandomString(int characters) {
    var result = "";
    for (var i = 0; i < characters; i++) {
      result +=
          Strings.createFromCodePoints([(25 * Math.random()).toInt() + 97]);
    }
    result += result;
    result += result;
    return result;
  }

  void run() {
    //JS Dromeaeo uses 16384
    final ITERATE1 = 384;
    //JS Dromeaeo uses 80000
    final ITERATE2 = 80;
    //JS Dromeaeo uses 5000
    final ITERATE3 = 50;
    //JS Dromeaeo uses 5000
    final ITERATE4 = 1;
    //JS Dromaeo uses 5000
    final ITERATE5 = 1000;

    var result;
    var text = getRandomString(ITERATE1);

    ConcatStringBenchmark.test(ITERATE2);
    ConcatStringFromCharCodeBenchmark.test(ITERATE2);
    StringSplitBenchmark.test(text);
    StringSplitOnCharBenchmark.test(text);
    text += text;
    CharAtBenchmark.test(text, ITERATE3);
    NumberBenchmark.test(text, ITERATE3);
    CodeUnitAtBenchmark.test(text, ITERATE3);
    IndexOfBenchmark.test(text, ITERATE3);
    LastIndexOfBenchmark.test(text, ITERATE3);
    SliceBenchmark.test(text, ITERATE4);
    SubstrBenchmark.test(text, ITERATE4);
    SubstringBenchmark.test(text, ITERATE4);
    ToLowerCaseBenchmark.test(text, ITERATE5);
    ToUpperCaseBenchmark.test(text, ITERATE5);
    ComparingBenchmark.test(text, ITERATE5);
  }
}

class ConcatStringBenchmark {
  ConcatStringBenchmark() {}

  static String test(var iterations) {
    var str = "";
    for (var i = 0; i < iterations; i++) {
      str += "a";
    }
    return str;
  }
}

class ConcatStringFromCharCodeBenchmark {
  ConcatStringFromCharCodeBenchmark() {}

  static String test(var iterations) {
    var str = "";
    for (var i = 0; i < (iterations / 2); i++) {
      str += Strings.createFromCodePoints([97]);
    }
    return str;
  }
}

class StringSplitBenchmark {
  StringSplitBenchmark() {}

  static List<String> test(String input) {
    return input.split("");
  }
}

class StringSplitOnCharBenchmark {
  StringSplitOnCharBenchmark() {}

  static List<String> test(String input) {
    String multiple = input;
    multiple += multiple;
    multiple += multiple;
    multiple += multiple;
    multiple += multiple;
    return multiple.split("a");
  }
}

class CharAtBenchmark {
  CharAtBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input[0];
      str = input[input.length - 1];
      str = input[150]; //set it to 15000
      str = input[120]; //set it to 12000
    }
    return str;
  }
}

class NumberBenchmark {
  NumberBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input[0];
      str = input[input.length - 1];
      str = input[150]; //set it to 15000
      str = input[100]; //set it to 10000
      str = input[50]; //set it to 5000
    }
    return str;
  }
}

class CodeUnitAtBenchmark {
  CodeUnitAtBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.codeUnitAt(0);
      str = input.codeUnitAt(input.length - 1);
      str = input.codeUnitAt(150); //set it to 15000
      str = input.codeUnitAt(100); //set it to 10000
      str = input.codeUnitAt(50); //set it to 5000
    }
    return str;
  }
}

class IndexOfBenchmark {
  IndexOfBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.indexOf("a", 0);
      str = input.indexOf("b", 0);
      str = input.indexOf("c", 0);
      str = input.indexOf("d", 0);
    }
    return str;
  }
}

class LastIndexOfBenchmark {
  LastIndexOfBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.lastIndexOf("a", input.length - 1);
      str = input.lastIndexOf("b", input.length - 1);
      str = input.lastIndexOf("c", input.length - 1);
      str = input.lastIndexOf("d", input.length - 1);
    }
    return str;
  }
}

class SliceBenchmark {
  SliceBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.substring(0, input.length - 1);
      str = input.substring(0, 5);
      str = input.substring(input.length - 1, input.length - 1);
      str = input.substring(input.length - 6, input.length - 1);
      str = input.substring(150, 155); //set to 15000 and 15005
      str = input.substring(120, input.length - 1); //set to 12000
    }
    return str;
  }
}

class SubstrBenchmark {
  SubstrBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.substring(0, input.length - 1);
      str = input.substring(0, 4);
      str = input.substring(input.length - 1, input.length - 1);
      str = input.substring(input.length - 6, input.length - 6);
      str = input.substring(150, 154); //set to 15000 and 15005
      str = input.substring(120, 124); //set to 12000
    }
    return str;
  }
}

class SubstringBenchmark {
  SubstringBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.substring(0, input.length - 1);
      str = input.substring(0, 4);
      str = input.substring(input.length - 1, input.length - 1);
      str = input.substring(input.length - 6, input.length - 2);
      str = input.substring(150, 154); //set to 15000 and 15005
      str = input.substring(120, input.length - 2); //set to 12000
    }
    return str;
  }
}

class ToLowerCaseBenchmark {
  ToLowerCaseBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < (iterations / 1000); j++) {
      str = Ascii.toLowerCase(input);
    }
    return str;
  }
}

class ToUpperCaseBenchmark {
  ToUpperCaseBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < (iterations / 1000); j++) {
      str = Ascii.toUpperCase(input);
    }
    return str;
  }
}

class ComparingBenchmark {
  ComparingBenchmark() {}

  static bool test(String input, var iterations) {
    var tmp = "a${input}a";
    var tmp2 = "a${input}a";
    var res;
    for (var j = 0; j < (iterations / 1000); j++) {
      res = (tmp.compareTo(tmp2) == 0);
      res = (tmp.compareTo(tmp2) < 0);
      res = (tmp.compareTo(tmp2) > 0);
    }
    return res;
  }
}

// Benchmarks basic message communication between two isolates.

class Benchmark1 {
  static const MESSAGES = 10000;
  static const INIT_MESSAGE = 0;
  static const TERMINATION_MESSAGE = -1;
  static const WARMUP_TIME = 1000;
  static const RUN_TIME = 1000;
  static const RUNS = 5;

  static int run() {
    return _run;
  }

  static void add_result(var opsms) {
    _run++;
    _opsms += opsms;
  }

  static void get_result() {
    return _opsms / _run;
  }

  static void init() {
    _run = 0;
    _opsms = 0.0;
  }

  static void main() {
    init();
    PingPongGame pingPongGame = new PingPongGame();
  }

  static var _run;
  static var _opsms;
}

class PingPongGame {
  PingPongGame()
      : _ping = new ReceivePort(),
        _pingPort = _ping.toSendPort(),
        _pong = null,
        _warmedup = false,
        _iterations = 0 {
    SendPort _pong = spawnFunction(pong);
    play();
  }

  void startRound() {
    _iterations++;
    _pong.send(Benchmark1.INIT_MESSAGE, _pingPort);
  }

  void evaluateRound() {
    int time = (new DateTime.now().difference(_start)).inMilliseconds;
    if (!_warmedup && time < Benchmark1.WARMUP_TIME) {
      startRound();
    } else if (!_warmedup) {
      _warmedup = true;
      _start = new DateTime.now();
      _iterations = 0;
      startRound();
    } else if (_warmedup && time < Benchmark1.RUN_TIME) {
      startRound();
    } else {
      shutdown();
      Benchmark1.add_result((1.0 * _iterations * Benchmark1.MESSAGES) / time);
      if (Benchmark1.run() < Benchmark1.RUNS) {
        new PingPongGame();
      } else {
        print("PingPong: ", Benchmark1.get_result());
      }
    }
  }

  void play() {
    _ping.receive((int message, SendPort replyTo) {
      if (message < Benchmark1.MESSAGES) {
        _pong.send(++message, null);
      } else {
        evaluateRound();
      }
    });
    _start = new DateTime.now();
    startRound();
  }

  void shutdown() {
    _pong.send(Benchmark1.TERMINATION_MESSAGE, null);
    _ping.close();
  }

  DateTime _start;
  SendPort _pong;
  SendPort _pingPort;
  ReceivePort _ping;
  bool _warmedup;
  int _iterations;
}

void pong() {
  port.receive((message, SendPort replyTo) {
    if (message == Benchmark1.INIT_MESSAGE) {
      replyTo.send(message, null);
    } else if (message == Benchmark1.TERMINATION_MESSAGE) {
      port.close();
    } else {
      replyTo.send(message, null);
    }
  });
}

class ManyGenericInstanceofTest {
  static testMain() {
    for (int i = 0; i < 5000; i++) {
      GenericInstanceof.testMain();
    }
  }
}

// ---------------------------------------------------------------------------
// THE REST OF THIS FILE COULD BE AUTOGENERATED
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// tests/isolate/spawn_test.dart
// ---------------------------------------------------------------------------

spawn_test_main() {
  test("spawn a new isolate", () {
    SendPort port = spawnFunction(entry);
    port.call(42).then(expectAsync1((message) {
      Expect.equals(42, message);
    }));
  });
}

void entry() {
  port.receive((message, SendPort replyTo) {
    Expect.equals(42, message);
    replyTo.send(42, null);
    port.close();
  });
}

// ---------------------------------------------------------------------------
// tests/isolate/isolate_negative_test.dart
// ---------------------------------------------------------------------------

void isolate_negative_entry() {
  port.receive((ignored, replyTo) {
    replyTo.send("foo", null);
  });
}

isolate_negative_test_main() {
  test("ensure isolate code is executed", () {
    SendPort port = spawnFunction(isolate_negative_entry);
    port.call("foo").then(expectAsync1((message) {
      Expect.equals(true, "Expected fail"); // <=-------- Should fail here.
    }));
  });
}

// ---------------------------------------------------------------------------
// tests/isolate/message_test.dart
// ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// Message passing test.
// ---------------------------------------------------------------------------

class MessageTest {
  static const List list1 = const ["Hello", "World", "Hello", 0xfffffffffff];
  static const List list2 = const [null, list1, list1, list1, list1];
  static const List list3 = const [list2, 2.0, true, false, 0xfffffffffff];
  static const Map map1 = const {
    "a=1": 1,
    "b=2": 2,
    "c=3": 3,
  };
  static const Map map2 = const {
    "list1": list1,
    "list2": list2,
    "list3": list3,
  };
  static const List list4 = const [map1, map2];
  static const List elms = const [
    list1,
    list2,
    list3,
    list4,
  ];

  static void VerifyMap(Map expected, Map actual) {
    Expect.equals(true, expected is Map);
    Expect.equals(true, actual is Map);
    Expect.equals(expected.length, actual.length);
    testForEachMap(key, value) {
      if (value is List) {
        VerifyList(value, actual[key]);
      } else {
        Expect.equals(value, actual[key]);
      }
    }

    expected.forEach(testForEachMap);
  }

  static void VerifyList(List expected, List actual) {
    for (int i = 0; i < expected.length; i++) {
      if (expected[i] is List) {
        VerifyList(expected[i], actual[i]);
      } else if (expected[i] is Map) {
        VerifyMap(expected[i], actual[i]);
      } else {
        Expect.equals(expected[i], actual[i]);
      }
    }
  }

  static void VerifyObject(int index, var actual) {
    var expected = elms[index];
    Expect.equals(true, expected is List);
    Expect.equals(true, actual is List);
    Expect.equals(expected.length, actual.length);
    VerifyList(expected, actual);
  }
}

pingPong() {
  int count = 0;
  port.receive((var message, SendPort replyTo) {
    if (message == -1) {
      port.close();
      replyTo.send(count, null);
    } else {
      // Check if the received object is correct.
      if (count < MessageTest.elms.length) {
        MessageTest.VerifyObject(count, message);
      }
      // Bounce the received object back so that the sender
      // can make sure that the object matches.
      replyTo.send(message, null);
      count++;
    }
  });
}

message_test_main() {
  test("send objects and receive them back", () {
    SendPort remote = spawnFunction(pingPong);
    // Send objects and receive them back.
    for (int i = 0; i < MessageTest.elms.length; i++) {
      var sentObject = MessageTest.elms[i];
      remote.call(sentObject).then(expectAsync1((var receivedObject) {
        MessageTest.VerifyObject(i, receivedObject);
      }));
    }

    // Send recursive objects and receive them back.
    List local_list1 = ["Hello", "World", "Hello", 0xffffffffff];
    List local_list2 = [null, local_list1, local_list1];
    List local_list3 = [local_list2, 2.0, true, false, 0xffffffffff];
    List sendObject = new List(5);
    sendObject[0] = local_list1;
    sendObject[1] = sendObject;
    sendObject[2] = local_list2;
    sendObject[3] = sendObject;
    sendObject[4] = local_list3;
    remote.call(sendObject).then((var replyObject) {
      Expect.equals(true, sendObject is List);
      Expect.equals(true, replyObject is List);
      Expect.equals(sendObject.length, replyObject.length);
      Expect.equals(true, identical(replyObject[1], replyObject));
      Expect.equals(true, identical(replyObject[3], replyObject));
      Expect.equals(true, identical(replyObject[0], replyObject[2][1]));
      Expect.equals(true, identical(replyObject[0], replyObject[2][2]));
      Expect.equals(true, identical(replyObject[2], replyObject[4][0]));
      Expect.equals(true, identical(replyObject[0][0], replyObject[0][2]));
      // Bigint literals are not canonicalized so do a == check.
      Expect.equals(true, replyObject[0][3] == replyObject[4][4]);
    });

    // Shutdown the MessageServer.
    remote.call(-1).then(expectAsync1((int message) {
      Expect.equals(MessageTest.elms.length + 1, message);
    }));
  });
}

// ---------------------------------------------------------------------------
// tests/isolate/request_reply_test.dart
// ---------------------------------------------------------------------------

void request_reply_entry() {
  port.receive((message, SendPort replyTo) {
    replyTo.send(message + 87);
    port.close();
  });
}

void request_reply_main() {
  test("call", () {
    SendPort port = spawnFunction(request_reply_entry);
    port.call(42).then(expectAsync1((message) {
      Expect.equals(42 + 87, message);
    }));
  });

  test("send", () {
    SendPort port = spawnFunction(request_reply_entry);
    ReceivePort reply = new ReceivePort();
    port.send(99, reply.toSendPort());
    reply.receive(expectAsync2((message, replyTo) {
      Expect.equals(99 + 87, message);
      reply.close();
    }));
  });
}

// ---------------------------------------------------------------------------
// tests/isolate/count_test.dart
// ---------------------------------------------------------------------------

void countMessages() {
  int count = 0;
  port.receive((int message, SendPort replyTo) {
    if (message == -1) {
      Expect.equals(10, count);
      replyTo.send(-1, null);
      port.close();
      return;
    }
    Expect.equals(count, message);
    count++;
    replyTo.send(message * 2, null);
  });
}

void count_main() {
  test("count 10 consecutive messages", () {
    int count = 0;
    SendPort remote = spawnFunction(countMessages);
    ReceivePort local = new ReceivePort();
    SendPort reply = local.toSendPort();

    local.receive(expectAsync2((int message, SendPort replyTo) {
      if (message == -1) {
        Expect.equals(11, count);
        local.close();
        return;
      }

      Expect.equals((count - 1) * 2, message);
      remote.send(count++, reply);
      if (count == 10) {
        remote.send(-1, reply);
      }
    }, 11));
    remote.send(count++, reply);
  });
}

// ---------------------------------------------------------------------------
// tests/isolate/mandel_isolate_test.dart
// ---------------------------------------------------------------------------

const TERMINATION_MESSAGE = -1;
const N = 100;
const ISOLATES = 20;

mandel_main() {
  test("Render Mandelbrot in parallel", () {
    final state = new MandelbrotState();
    state._validated.future.then(expectAsync1((result) {
      expect(result, isTrue);
    }));
    for (int i = 0; i < Math.min(ISOLATES, N); i++) state.startClient(i);
  });
}

class MandelbrotState {
  MandelbrotState() {
    _result = new List<List<int>>(N);
    _lineProcessedBy = new List<LineProcessorClient>(N);
    _sent = 0;
    _missing = N;
    _validated = new Completer<bool>();
  }

  void startClient(int id) {
    assert(_sent < N);
    final client = new LineProcessorClient(this, id);
    client.processLine(_sent++);
  }

  void notifyProcessedLine(LineProcessorClient client, int y, List<int> line) {
    assert(_result[y] == null);
    _result[y] = line;
    _lineProcessedBy[y] = client;

    if (_sent != N) {
      client.processLine(_sent++);
    } else {
      client.shutdown();
    }

    // If all lines have been computed, validate the result.
    if (--_missing == 0) {
      _printResult();
      _validateResult();
    }
  }

  void _validateResult() {
    // TODO(ngeoffray): Implement this.
    _validated.complete(true);
  }

  void _printResult() {
    var output = new StringBuffer();
    for (int i = 0; i < _result.length; i++) {
      List<int> line = _result[i];
      for (int j = 0; j < line.length; j++) {
        if (line[j] < 10) output.write("0");
        output.write(line[j]);
      }
      output.write("\n");
    }
    // print(output);
  }

  List<List<int>> _result;
  List<LineProcessorClient> _lineProcessedBy;
  int _sent;
  int _missing;
  Completer<bool> _validated;
}

class LineProcessorClient {
  LineProcessorClient(MandelbrotState this._state, int this._id) {
    _port = spawnFunction(processLines);
  }

  void processLine(int y) {
    _port.call(y).then((List<int> message) {
      _state.notifyProcessedLine(this, y, message);
    });
  }

  void shutdown() {
    _port.send(TERMINATION_MESSAGE, null);
  }

  MandelbrotState _state;
  int _id;
  SendPort _port;
}

List<int> processLine(int y) {
  double inverseN = 2.0 / N;
  double Civ = y * inverseN - 1.0;
  List<int> result = new List<int>(N);
  for (int x = 0; x < N; x++) {
    double Crv = x * inverseN - 1.5;

    double Zrv = Crv;
    double Ziv = Civ;

    double Trv = Crv * Crv;
    double Tiv = Civ * Civ;

    int i = 49;
    do {
      Ziv = (Zrv * Ziv) + (Zrv * Ziv) + Civ;
      Zrv = Trv - Tiv + Crv;

      Trv = Zrv * Zrv;
      Tiv = Ziv * Ziv;
    } while (((Trv + Tiv) <= 4.0) && (--i > 0));

    result[x] = i;
  }
  return result;
}

void processLines() {
  port.receive((message, SendPort replyTo) {
    if (message == TERMINATION_MESSAGE) {
      assert(replyTo == null);
      port.close();
    } else {
      replyTo.send(processLine(message), null);
    }
  });
}
