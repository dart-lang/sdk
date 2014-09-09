library pub.barback.cycle_exception;
import '../exceptions.dart';
class CycleException implements ApplicationException {
  final String _step;
  final CycleException _next;
  List<String> get steps {
    if (_step == null) return [];
    var exception = this;
    var steps = [];
    while (exception != null) {
      steps.add(exception._step);
      exception = exception._next;
    }
    return steps;
  }
  String get message {
    var steps = this.steps;
    if (steps.isEmpty) return "Transformer cycle detected.";
    return "Transformer cycle detected:\n" +
        steps.map((step) => "  $step").join("\n");
  }
  CycleException([this._step]) : _next = null;
  CycleException._(this._step, this._next);
  CycleException prependStep(String step) {
    if (_step == null) return new CycleException(step);
    return new CycleException._(step, this);
  }
  String toString() => message;
}
