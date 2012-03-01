
class _SharedWorkerContextImpl extends _WorkerContextImpl implements SharedWorkerContext native "*SharedWorkerContext" {

  final String name;

  EventListener onconnect;
}
