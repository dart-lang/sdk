# Analysis Server Benchmarks

## How to run the benchmarks

To see a list of all available benchmarks, run:

```
dart benchmark/benchmarks.dart list
```

To run an individual benchmark, run:

```
dart benchmark/benchmarks.dart run <benchmark-id>
```

## How they're tested

In order to make sure that our benchmarks don't regress in terms of their
ability to run, we create one unit test per benchmark, and run those tests
as part of our normal CI test suite.

To save time on the CI, we only run one iteration of each benchmark
(`--repeat=1`), and we run the benchmark on a smaller data set (`--quick`).

See `test/benchmark_test.dart`.

## To add a new benchmark

Register the new benchmark in the `main()` method of benchmark/benchmarks.dart.

## On the bots

Our benchmarks run on a continuous performance testing system. Currently, the
benchmarks need to be manually registered ahead of time.
