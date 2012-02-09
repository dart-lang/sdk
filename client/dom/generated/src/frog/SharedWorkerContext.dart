
class _SharedWorkerContextJs extends _WorkerContextJs implements SharedWorkerContext native "*SharedWorkerContext" {

  final String name;

  EventListener onconnect;
}
