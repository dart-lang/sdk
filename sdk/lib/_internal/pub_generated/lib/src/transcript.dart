library pub.transcript;
import 'dart:collection';
class Transcript<T> {
  final int max;
  int get discarded => _discarded;
  int _discarded = 0;
  final _oldest = new List<T>();
  final _newest = new Queue<T>();
  Transcript(this.max);
  void add(T entry) {
    if (discarded > 0) {
      _newest.removeFirst();
      _discarded++;
    } else if (_newest.length == max) {
      while (_newest.length > max ~/ 2) {
        _oldest.add(_newest.removeFirst());
      }
      _newest.removeFirst();
      _discarded++;
    }
    _newest.add(entry);
  }
  void forEach(void onEntry(T entry), [void onGap(int)]) {
    if (_oldest.isNotEmpty) {
      _oldest.forEach(onEntry);
      if (onGap != null) onGap(discarded);
    }
    _newest.forEach(onEntry);
  }
}
