bool isPrime(var n) {
  if (n < 2) return false;
  for (var i = 2; i * i <= n; i++) {
    if (n % i == 0) return false;
  }
  return true;
}

int nThPrimeNumber(int n) {
  int counter = 0;
  for (var i = 1;; i++) {
    if (isPrime(i)) counter++;
    if (counter == n) {
      return i;
    }
  }
}

void run() {
  int e = 611953;
  int p = nThPrimeNumber(50000);
  if (p != e) {
    throw Exception("Unexpected result: $p != $e");
  }
}

main(List<String> args) {
  Stopwatch timer = new Stopwatch()..start();
  for (int i = 0; i < 100; ++i) {
    run();
  }
  timer.stop();

  print("Elapsed ${timer.elapsedMilliseconds}ms");
}
