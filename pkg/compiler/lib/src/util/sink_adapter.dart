import '../../compiler_new.dart' as api;

class BinaryOutputSinkAdapter implements Sink<List<int>> {
  api.BinaryOutputSink output;

  BinaryOutputSinkAdapter(this.output);

  @override
  void add(List<int> data) {
    output.write(data);
  }

  @override
  void close() {
    output.close();
  }
}
