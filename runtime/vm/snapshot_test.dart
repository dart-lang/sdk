// Copyright (c) 2011, the Dart project authors.  Please see the AUTHORS file
// for details. All rights reserved. Use of this source code is governed by a
// BSD-style license that can be found in the LICENSE file.

class Fields  {
  Fields(int i, int j) : fld1 = i, fld2 = j, fld5 = true {}
  int fld1;
  final int fld2;
  static int fld3;
  static final int fld4 = 10;
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
    if (result != 20000)
      Error.error("Wrong result: $result. Should be: 20000");
  }

  static void main() {
    new LoopBenchmark().report();
  }
}

// T o w e r s
class TowersDisk {
  final int size;
  TowersDisk next;

  TowersDisk(size) : this.size = size, next = null {}
}

class Towers {
  List<TowersDisk> piles;
  int movesDone;
  Towers(int disks) : piles = new List<TowersDisk>(3), movesDone = 0 {
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
        for (int k = i + 1; k <= size; k += i)
          flags[k - 1] = false;
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
    if (result != 168)
      Error.error("Wrong result: $result should be: 168");
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
    if (result != 8660)
      Error.error("Wrong result: $result should be: 8660");
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
  static bool tryQueens(int i,
                        List<bool> a,
                        List<bool> b,
                        List<bool> c,
                        List<int> x) {
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

    if (!tryQueens(1, b, a, c, x))
      Error.error("Error in queens");
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
  static final int INITIAL_SEED = 74755;
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
    if ((a[0] != min) || a[len - 1] != max)
      Error.error("List is not sorted");
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
      if (left == null) left = new TreeNodePress(n);
      else left.insert(n);
    } else {
      if (right == null) right = new TreeNodePress(n);
      else right.insert(n);
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
      return takl(takl(x.next, y, z),
                  takl(y.next, z, x),
                  takl(z.next, x, y));
    } else {
      return z;
    }
  }
}

class TaklBenchmark extends BenchmarkBase {
  const TaklBenchmark() : super("Takl");

  void warmup() {
    Takl.takl(ListElement.makeList(8),
              ListElement.makeList(4),
              ListElement.makeList(3));
  }

  void exercise() {
    // This value has been copied from benchpress.js, so that we can compare
    // performance.
    ListElement result = Takl.takl(ListElement.makeList(15),
                                   ListElement.makeList(10),
                                   ListElement.makeList(6));
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
  void run() { }

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
  void setup() { }

  // Not measures teardown code executed after the benchark runs.
  void teardown() { }

  // Measures the score for this benchmark by executing it repeately until
  // time minimum has been reached.
  static double measureFor(Function f, int timeMinimum) {
    int time = 0;
    int iter = 0;
    Date start = new Date.now();
    while (time < timeMinimum) {
      f();
      time = (new Date.now().difference(start)).inMilliseconds;
      iter++;
    }
    // Force double result by using a double constant.
    return (1000.0 * iter) / time;
  }

  // Measures the score for the benchmark and returns it.
  double measure() {
    setup();
    // Warmup for at least 100ms. Discard result.
    measureFor(() { this.warmup(); }, -100);
    // Run the benchmark for at least 2000ms.
    double result = measureFor(() { this.exercise(); }, -2000);
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
  static printobject(obj) { }
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
      result += Strings.
          createFromCodePoints([(25 * Math.random()).toInt() + 97]);
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
    CharCodeAtBenchmark.test(text, ITERATE3);
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


class CharCodeAtBenchmark {
  CharCodeAtBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.charCodeAt(0);
      str = input.charCodeAt(input.length - 1);
      str = input.charCodeAt(150); //set it to 15000
      str = input.charCodeAt(100); //set it to 10000
      str = input.charCodeAt(50); //set it to 5000
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
      str = input.substring(120, input.length-1); //set to 12000
    }
    return str;
  }
}

class SubstrBenchmark {
  SubstrBenchmark() {}

  static String test(String input, var iterations) {
    var str;
    for (var j = 0; j < iterations; j++) {
      str = input.substring(0, input.length-1);
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

  static final MESSAGES = 10000;
  static final INIT_MESSAGE = 0;
  static final TERMINATION_MESSAGE = -1;
  static final WARMUP_TIME = 1000;
  static final RUN_TIME = 1000;
  static final RUNS = 5;


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
    PingPongGame pingPongGame = new PingPongGame.play();
  }

  static var _run;
  static var _opsms;
}

class PingPongGame {

  PingPongGame.play()
      : _ping = new ReceivePort(),
        _pingPort = _ping.toSendPort(),
        _pong = null,
        _warmedup = false,
        _iterations = 0 {
    new Pong().spawn().then((SendPort port) {
      _pong = port;
      play();
    });
  }

  void startRound() {
    _iterations++;
    _pong.send(Benchmark1.INIT_MESSAGE, _pingPort);
  }

  void evaluateRound() {
    int time = (new Date.now().difference(_start)).inMilliseconds;
    if (!_warmedup && time < Benchmark1.WARMUP_TIME) {
      startRound();
    } else if (!_warmedup) {
      _warmedup = true;
      _start = new Date.now();
      _iterations = 0;
      startRound();
    } else if (_warmedup && time < Benchmark1.RUN_TIME) {
      startRound();
    } else {
      shutdown();
      Benchmark1.add_result((1.0 * _iterations * Benchmark1.MESSAGES) / time);
      if (Benchmark1.run() < Benchmark1.RUNS) {
        new PingPongGame.play();
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
    _start = new Date.now();
    startRound();
  }

  void shutdown() {
    _pong.send(Benchmark1.TERMINATION_MESSAGE, null);
    _ping.close();
  }

  Date _start;
  SendPort _pong;
  SendPort _pingPort;
  ReceivePort _ping;
  bool _warmedup;
  int _iterations;
}

class Pong extends Isolate {

  // TODO(hpayer): can be removed as soon as we have default constructors
  Pong() : super() { }

  void main() {
    this.port.receive((message, SendPort replyTo) {
      if (message == Benchmark1.INIT_MESSAGE) {
        _reply = replyTo;
        _reply.send(message, null);
      } else if (message == Benchmark1.TERMINATION_MESSAGE) {
        this.port.close();
      } else {
        _reply.send(message, null);
      }
    });
  }

  SendPort _reply;
}


class ManyGenericInstanceofTest {
  static testMain() {
    for (int i = 0; i < 5000; i++) {
      GenericInstanceof.testMain();
    }
  }
}

// Dart test program for testing that exceptions in other isolates bring down
// the program.
// ImportOptions=IsolateTestFramework

class Isolate2NegativeTest extends Isolate {
  Isolate2NegativeTest() : super();

  static void testMain() {
    // We will never call 'done'. This test fails with a timeout.
    IsolateTestFramework.waitForDone();
    new Isolate2NegativeTest().spawn();
  }

  void main() {
    throw "foo";
  }
}


class IsolateTestFramework {
  static void waitForDone() {
    // By keeping an open receive port we keep the isolate alive. This way we
    // can wait for other isolates to finish before terminating the main
    // isolate.
    _port = new ReceivePort();
    if (waitForDoneCallback !== null) waitForDoneCallback();
  }
  static void done() {
    _port.close();
    if (doneCallback !== null) doneCallback();
  }

  static Function waitForDoneCallback;
  static Function doneCallback;
  static ReceivePort _port;
}

// Dart test program for testing that the exit-handler is executed at the end.


class IsolateExitHandlerTest extends Isolate {
  static int counter;

  IsolateExitHandlerTest() : super.heavy();

  static void testMain() {
    Isolate.setExitHandler(() {
      Expect.equals(1, counter);
    });
    new IsolateExitHandlerTest().spawn().then((SendPort p) {
      p.call("bar").receive((msg, replyTo) {
        counter++;
      });
    });
  }

  void main() {
    bool encounteredException = false;
    try {
      Isolate.setExitHandler(() {
        Expect.equals(true, false);
      });
    } catch(var e) {
      encounteredException = true;
    }
    Expect.equals(true, encounteredException);

    this.port.receive((ignored, replyTo) {
      replyTo.send("foo", null);
      this.port.close();
    });
  }
}

interface Mint factory MintImpl {

  Mint();

  Purse createPurse(int balance);

}


class MintImpl implements Mint {

  MintImpl() { }

  Purse createPurse(int balance) {
    return new PurseImpl(this, balance);
  }

}


interface Purse {

  int queryBalance();
  Purse sproutPurse();
  void deposit(int amount, Purse$Proxy source);

}


class PurseImpl implements Purse {

  PurseImpl(this._mint, this._balance) { }

  int queryBalance() {
    return _balance;
  }

  Purse sproutPurse() {
    return _mint.createPurse(0);
  }

  void deposit(int amount, Purse$Proxy purse) {
    Purse$ProxyImpl impl = purse.dynamic;
    PurseImpl source = impl.local;
    if (source._balance < amount) throw "Not enough dough.";
    _balance += amount;
    source._balance -= amount;
  }

  Mint _mint;
  int _balance;

}


class MintMakerPromiseTest {

  static void testMain() {
    Mint$Proxy mint = createMint();
    Purse$Proxy purse = mint.createPurse(100);
    expectEquals(100, purse.queryBalance());

    Purse$Proxy sprouted = purse.sproutPurse();
    expectEquals(0, sprouted.queryBalance());

    sprouted.deposit(5, purse);
    expectEquals(0 + 5, sprouted.queryBalance());
    expectEquals(100 - 5, purse.queryBalance());

    sprouted.deposit(42, purse);
    expectEquals(0 + 5 + 42, sprouted.queryBalance());
    expectEquals(100 - 5 - 42, purse.queryBalance());

    expectDone(6);
  }

  static Mint$Proxy createMint() {
    Proxy isolate = new Proxy.forIsolate(new Mint$Dispatcher$Isolate());
    return new Mint$ProxyImpl(isolate);
  }


  static List<Promise> results;

  static void expectEquals(int expected, Promise<int> promise) {
    if (results === null) {
      results = new List<Promise>();
    }
    results.add(promise.then((int actual) {
      Expect.equals(expected, actual);
    }));
  }

  static void expectDone(int n) {
    if (results === null) {
      Expect.equals(0, n);
    } else {
      Promise done = new Promise();
      done.waitFor(results, results.length);
      done.then((ignored) {
        Expect.equals(n, results.length);
      });
    }
  }

}


// ---------------------------------------------------------------------------
// THE REST OF THIS FILE COULD BE AUTOGENERATED
// ---------------------------------------------------------------------------

interface Mint$Proxy {

  Purse$Proxy createPurse(int balance);  // Promise<int> balance.

}


class Mint$ProxyImpl extends Proxy implements Mint$Proxy {

  Mint$ProxyImpl(Proxy isolate) : super.forReply(isolate.call([null])) {}

  Purse$Proxy createPurse(int balance) {
    return new Purse$ProxyImpl(this.call([balance]));
  }

}


class Mint$Dispatcher extends Dispatcher<Mint> {

  Mint$Dispatcher(Mint mint) : super(mint) { }

  void process(var message, void reply(var response)) {
    int balance = message[0];
    Purse purse = target.createPurse(balance);
    SendPort port = Dispatcher.serve(new Purse$Dispatcher(purse));
    reply(port);
  }

}


class Mint$Dispatcher$Isolate extends Isolate {

  Mint$Dispatcher$Isolate() : super() { }

  void main() {
    this.port.receive((var message, SendPort replyTo) {
      Mint mint = new Mint();
      SendPort port = Dispatcher.serve(new Mint$Dispatcher(mint));
      Proxy proxy = new Proxy.forPort(replyTo);
      proxy.send([port]);
    });
  }

}


interface Purse$Proxy {

  Promise<int> queryBalance();
  Purse$Proxy sproutPurse();
  void deposit(int amount, Purse$Proxy source);  // Promise<int> amount.

}


class Purse$ProxyImpl extends Proxy implements Purse$Proxy {

  Purse$ProxyImpl(Promise<SendPort> port) : super.forReply(port) { }

  Promise<int> queryBalance() {
    return this.call(["balance"]);
  }

  void deposit(int amount, Purse$Proxy source) {
    this.send(["deposit", amount, source]);
  }

  Purse$Proxy sproutPurse() {
    return new Purse$ProxyImpl(this.call(["sprout"]));
  }

}


class Purse$Dispatcher extends Dispatcher<Purse> {

  Purse$Dispatcher(Purse purse) : super(purse) { }

  void process(var message, void reply(var response)) {
    String command = message[0];
    if (command == "balance") {
      int balance = target.queryBalance();
      reply(balance);
    } else if (command == "deposit") {
      int amount = message[1];
      Promise<SendPort> port = new Promise<SendPort>.fromValue(message[2]);
      Purse$Proxy source = new Purse$ProxyImpl(port);
      target.deposit(amount, source);
    } else if (command == "sprout") {
      Purse purse = target.sproutPurse();
      SendPort port = Dispatcher.serve(new Purse$Dispatcher(purse));
      reply(port);
    } else {
      // TODO: Send an exception back.
      reply("Exception: Command not understood");
    }
  }

}


// ImportOptions=IsolateTestFramework

class SpawnTest {

  static void testMain() {
    spawnIsolate();
  }

  static void spawnIsolate() {
    IsolateTestFramework.waitForDone();
    SpawnedIsolate isolate = new SpawnedIsolate();
    isolate.spawn().then((SendPort port) {
      port.call(42).receive((message, replyTo) {
        Expect.equals(42, message);
        IsolateTestFramework.done();
      });
    });
  }
}

class SpawnedIsolate extends Isolate {

  SpawnedIsolate() : super() { }

  void main() {
    this.port.receive((message, SendPort replyTo) {
      Expect.equals(42, message);
      replyTo.send(42, null);
      this.port.close();
    });
  }

}

// Dart test program for testing that the exit-handler is executed.


class IsolateExitHandlerNegativeTest extends Isolate {
  IsolateExitHandlerNegativeTest() : super.heavy();

  static void testMain() {
    Isolate.setExitHandler(() {
      Expect.equals(true, false);   // <=-------- Should fail here.
    });
    new IsolateExitHandlerNegativeTest().spawn();
  }

  void main() {
    this.port.close();
  }
}

// ImportOptions=IsolateTestFramework

class ConstructorTest extends Isolate {
  final int field;
  ConstructorTest() : super(), field = 499;

  void main() {
    IsolateTestFramework.waitForDone();
    this.port.receive((ignoredMessage, reply) {
      reply.send(field, null);
      this.port.close();
      IsolateTestFramework.done();
    });
  }

  static void testMain() {
    ConstructorTest test = new ConstructorTest();
    test.spawn().then((SendPort port) {
      ReceivePort reply = port.call("ignored");
      reply.receive((message, replyPort) {
        Expect.equals(499, message);
      });
    });
  }
}

// Dart test program for testing isolate communication with
// simple messages.
// ImportOptions=IsolateTestFramework

class IsolateTest {

  static void testMain() {
    _waitingForDoneCount = 0;
    IsolateTestFramework.waitForDone();
    RequestReplyTest.test();
    CountTest.test();
    PromiseBasedTest.test();
    StaticStateTest.test();
  }

  static void waitForDone() {
    _waitingForDoneCount++;
  }

  static void done() {
    if (--_waitingForDoneCount == 0) {
      IsolateTestFramework.done();
    }
  }

  static int _waitingForDoneCount;
}


// ---------------------------------------------------------------------------
// Request-reply test.
// ---------------------------------------------------------------------------

class RequestReplyTest {

  static void test() {
    testCall();
    testSend();
    testSendSingleShot();
  }

  static void testCall() {
    IsolateTest.waitForDone();
    new RequestReplyIsolate().spawn().then((SendPort port) {
      port.call(42).receive((message, replyTo) {
        Expect.equals(42 + 87, message);
        IsolateTest.done();
      });
    });
  }

  static void testSend() {
    IsolateTest.waitForDone();
    new RequestReplyIsolate().spawn().then((SendPort port) {
      ReceivePort reply = new ReceivePort();
      port.send(99, reply.toSendPort());
      reply.receive((message, replyTo) {
        Expect.equals(99 + 87, message);
        reply.close();
        IsolateTest.done();
      });
    });
  }

  static void testSendSingleShot() {
    IsolateTest.waitForDone();
    new RequestReplyIsolate().spawn().then((SendPort port) {
      ReceivePort reply = new ReceivePort.singleShot();
      port.send(99, reply.toSendPort());
      reply.receive((message, replyTo) {
        Expect.equals(99 + 87, message);
        IsolateTest.done();
      });
    });
  }

}


class RequestReplyIsolate extends Isolate {

  RequestReplyIsolate() : super() { }

  void main() {
    this.port.receive((message, SendPort replyTo) {
      replyTo.send(message + 87, null);
      this.port.close();
    });
  }

}


// ---------------------------------------------------------------------------
// Simple counting test.
// ---------------------------------------------------------------------------

class CountTest {

  static int count;

  static void test() {
    IsolateTest.waitForDone();
    print("Hello ");
    new CountIsolate().spawn().then((SendPort remote) {
      ReceivePort local = new ReceivePort();
      SendPort reply = local.toSendPort();

      local.receive((int message, SendPort replyTo) {
        if (message == -1) {
          Expect.equals(11, count);
          // Close the only ReceivePort to terminate the isolate after the
          // callback returns.
          local.close();
          print("IsolateTest exiting.");
          IsolateTest.done();
          return;
        }
        Expect.equals((count - 1) * 2, message);
        print("IsolateTest: $message");
        remote.send(count++, reply);
        if (count == 10) {
          remote.send(-1, reply);
        }
      });

      print("!");
      count = 0;
      remote.send(count++, reply);
    });
  }
}


class CountIsolate extends Isolate {

  CountIsolate() : super() { }

  void main() {
    print("World");
    int count = 0;

    this.port.receive((int message, SendPort replyTo) {
      print("Remote: $message");
      if (message == -1) {
        Expect.equals(10, count);
        replyTo.send(-1, null);
        // Close the only ReceivePort to terminate the isolate after the
        // callback returns.
        this.port.close();
        print("RemoteRunner exiting.");
        return;
      }

      Expect.equals(count, message);
      count++;
      replyTo.send(message * 2, null);
    });
  }
}


// ---------------------------------------------------------------------------
// Promise-based test.
// ---------------------------------------------------------------------------

class PromiseBasedTest {

  static void test() {
    IsolateTest.waitForDone();
    Proxy proxy = new Proxy.forIsolate(new PromiseIsolate());
    proxy.send([42]);  // Seed the isolate.
    proxy.call([87]).then((int value) {
      Expect.equals(42 + 87, value);
      return 99;
    }).then((int value) {
      Expect.equals(99, value);
      IsolateTest.done();
    });
  }

}


class PromiseIsolate extends Isolate {

  PromiseIsolate() : super() { }

  void main() {
    int seed = 0;
    this.port.receive((var message, SendPort replyTo) {
      if (seed == 0) {
        seed = message[0];
      } else {
        Promise<int> response = new Promise<int>();
        var proxy = new Proxy.forPort(replyTo);
        proxy.send([response]);
        response.complete(seed + message[0]);
        this.port.close();
      }
    });
  }

}


// ---------------------------------------------------------------------------
// State state test.
// ---------------------------------------------------------------------------

class StaticStateTest {

  static String state;

  static void test() {
    IsolateTest.waitForDone();
    Expect.equals(null, state);
    state = "foo";
    Expect.equals("foo", state);

    new StaticStateIsolate().spawn().then((SendPort remote) {
      remote.call("bar").receive((reply, replyTo) {
        Expect.equals("foo", state);
        Expect.equals(null, reply);

        state = "baz";
        remote.call("exit").receive((reply, replyTo) {
          Expect.equals("baz", state);
          Expect.equals("bar", reply);
          IsolateTest.done();
        });
      });
    });
  }

}


class StaticStateIsolate extends Isolate {

  StaticStateIsolate() : super() { }

  void main() {
    Expect.equals(null, StaticStateTest.state);
    this.port.receive((var message, SendPort replyTo) {
      String old = StaticStateTest.state;
      StaticStateTest.state = message;
      replyTo.send(old, null);
      if (message == "exit") {
        this.port.close();
        return;
      }
    });
  }

}


// Dart test program for testing isolate communication with
// complex messages.
// ImportOptions=IsolateTestFramework


class IsolateComplexMessagesTest {

  static void testMain() {
    LogClient.test();
  }
}


// ---------------------------------------------------------------------------
// Log server test.
// ---------------------------------------------------------------------------

class LogClient {
  static void test() {
    IsolateTestFramework.waitForDone();
    new LogIsolate().spawn().then((SendPort remote) {

      remote.send(1, null);
      remote.send("Hello", null);
      remote.send("World", null);
      remote.send(const [null, 1, 2, 3, 4], null);
      remote.send(const [1, 2.0, true, false, 0xffffffffff], null);
      remote.send(const ["Hello", "World", 0xffffffffff], null);
      // Shutdown the LogRunner.
      remote.call(-1).receive((int message, SendPort replyTo) {
        Expect.equals(6, message);
      });
      IsolateTestFramework.done();
    });
  }
}


class LogIsolate extends Isolate {
  LogIsolate() : super() { }

  void main() {
    print("Starting log server.");

    int count = 0;

    this.port.receive((var message, SendPort replyTo) {
      if (message == -1) {
        this.port.close();
        print("Stopping log server.");
        replyTo.send(count, null);
      } else {
        print("Log ($count) $message");
        switch (count) {
          case 0:
            Expect.equals(1, message);
            break;
          case 1:
            Expect.equals("Hello", message);
            break;
          case 2:
            Expect.equals("World", message);
            break;
          case 3:
            Expect.equals(5, message.length);
            Expect.equals(null, message[0]);
            Expect.equals(1, message[1]);
            Expect.equals(2, message[2]);
            Expect.equals(3, message[3]);
            Expect.equals(4, message[4]);
            break;
          case 4:
            Expect.equals(5, message.length);
            Expect.equals(1, message[0]);
            Expect.equals(2.0, message[1]);
            Expect.equals(true, message[2]);
            Expect.equals(false, message[3]);
            Expect.equals(0xffffffffff, message[4]);
            break;
          case 5:
            Expect.equals(3, message.length);
            Expect.equals("Hello", message[0]);
            Expect.equals("World", message[1]);
            Expect.equals(0xffffffffff, message[2]);
            break;
        }
        count++;
      }
    });
  }
}


// Dart test program for testing serialization of messages.
// VMOptions=--enable_type_checks --enable_asserts
// ImportOptions=IsolateTestFramework

// ---------------------------------------------------------------------------
// Message passing test.
// ---------------------------------------------------------------------------

class MessageTest {
  static void testMain() {
    PingPongClient.test();
  }

  static final List list1 = const ["Hello", "World", "Hello", 0xfffffffffff];
  static final List list2 = const [null, list1, list1, list1, list1];
  static final List list3 = const [list2, 2.0, true, false, 0xfffffffffff];
  static final Map map1 = const {
    "a=1" : 1, "b=2" : 2, "c=3" : 3,
  };
  static final Map map2 = const {
    "list1" : list1, "list2" : list2, "list3" : list3,
  };
  static final List list4 = const [map1, map2];
  static final List elms = const [
      list1, list2, list3, list4,
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

class PingPongClient {
  static void test() {
    IsolateTestFramework.waitForDone();
    new PingPongServer().spawn().then((SendPort remote) {

      // Send objects and receive them back.
      for (int i = 0; i < MessageTest.elms.length; i++) {
        var sentObject = MessageTest.elms[i];
        remote.call(sentObject).receive(
            (var receivedObject, SendPort replyTo) {
              MessageTest.VerifyObject(i, receivedObject);
            });
      }

      // Send recursive objects and receive them back.
      List local_list1 = ["Hello", "World", "Hello", 0xffffffffff];
      List local_list2 = [null, local_list1, local_list1 ];
      List local_list3 = [local_list2, 2.0, true, false, 0xffffffffff];
      List sendObject = new List(5);
      sendObject[0] = local_list1;
      sendObject[1] = sendObject;
      sendObject[2] = local_list2;
      sendObject[3] = sendObject;
      sendObject[4] = local_list3;
      remote.call(sendObject).receive(
          (var replyObject, SendPort replyTo) {
            Expect.equals(true, sendObject is List);
            Expect.equals(true, replyObject is List);
            Expect.equals(sendObject.length, replyObject.length);
            Expect.equals(true, replyObject[1] === replyObject);
            Expect.equals(true, replyObject[3] === replyObject);
            Expect.equals(true, replyObject[0] === replyObject[2][1]);
            Expect.equals(true, replyObject[0] === replyObject[2][2]);
            Expect.equals(true, replyObject[2] === replyObject[4][0]);
            Expect.equals(true, replyObject[0][0] === replyObject[0][2]);
            // Bigint literals are not canonicalized so do a == check.
            Expect.equals(true, replyObject[0][3] == replyObject[4][4]);
          });

      // Shutdown the MessageServer.
      remote.call(-1).receive(
          (int message, SendPort replyTo) {
            Expect.equals(MessageTest.elms.length + 1, message);
            IsolateTestFramework.done();
          });
    });
  }
}

class PingPongServer extends Isolate {
  PingPongServer() : super() {}

  void main() {
    print("Starting server.");
    int count = 0;
    this.port.receive(
        (var message, SendPort replyTo) {
          if (message == -1) {
            this.port.close();
            print("Stopping server.");
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
}


// ImportOptions=IsolateTestFramework

class MandelIsolateTest {

  static final TERMINATION_MESSAGE = -1;
  static final N = 100;
  static final ISOLATES = 20;

  static void testMain() {
    IsolateTestFramework.waitForDone();
    final state = new MandelbrotState();
    for (int i = 0; i < Math.min(ISOLATES, N); i++) state.startClient(i);
  }

}


class MandelbrotState {

  MandelbrotState() {
    _result = new List<List<int>>(MandelIsolateTest.N);
    _lineProcessedBy = new List<LineProcessorClient>(MandelIsolateTest.N);
    _sent = 0;
    _missing = MandelIsolateTest.N;
  }

  void startClient(int id) {
    assert(_sent < MandelIsolateTest.N);
    final client = new LineProcessorClient(this, id);
    client.processLine(_sent++);
  }

  void notifyProcessedLine(LineProcessorClient client, int y, List<int> line) {
    assert(_result[y] === null);
    _result[y] = line;
    _lineProcessedBy[y] = client;

    if (_sent != MandelIsolateTest.N) {
      client.processLine(_sent++);
    } else {
      client.shutdown();
    }

    // If all lines have been computed, validate the result.
    if (--_missing == 0) _validateResult();
  }

  void _validateResult() {
    // TODO(ngeoffray): Implement this.
    IsolateTestFramework.done();
  }

  List<List<int>> _result;
  List<LineProcessorClient> _lineProcessedBy;
  int _sent;
  int _missing;

}


class LineProcessorClient {

  LineProcessorClient(MandelbrotState this._state, int this._id) {
    _out = new LineProcessor().spawn();
  }

  void processLine(int y) {
    _out.then((SendPort p) {
      p.call(y).receive((List<int> message, SendPort replyTo) {
        _state.notifyProcessedLine(this, y, message);
      });
    });
  }

  void shutdown() {
    _out.then((SendPort p) {
      p.send(MandelIsolateTest.TERMINATION_MESSAGE, null);
    });
  }

  MandelbrotState _state;
  int _id;
  Promise<SendPort> _out;

}


class LineProcessor extends Isolate {

  LineProcessor() : super() { }

  void main() {
    this.port.receive((message, SendPort replyTo) {
      if (message == MandelIsolateTest.TERMINATION_MESSAGE) {
        assert(replyTo == null);
        this.port.close();
      } else {
        replyTo.send(_processLine(message), null);
      }
    });
  }

  static List<int> _processLine(int y) {
    double inverseN = 2.0 / MandelIsolateTest.N;
    double Civ = y * inverseN - 1.0;
    List<int> result = new List<int>(MandelIsolateTest.N);
    for (int x = 0; x < MandelIsolateTest.N; x++) {
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

}

// Dart test program for testing that isolates are spawned.
// ImportOptions=IsolateTestFramework

class IsolateNegativeTest extends Isolate {
  IsolateNegativeTest() : super();

  static void testMain() {
    IsolateTestFramework.waitForDone();
    new IsolateNegativeTest().spawn().then((SendPort port) {
      port.call("foo").receive((message, replyTo) {
        Expect.equals(true, false);   // <=-------- Should fail here.
        IsolateTestFramework.done();
      });
    });
  }

  void main() {
    this.port.receive((ignored, replyTo) {
      replyTo.send("foo", null);
    });
  }
}
