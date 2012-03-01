
class _ConsoleImpl extends _DOMTypeBase implements Console {
  _ConsoleImpl._wrap(ptr) : super._wrap(ptr);

  MemoryInfo get memory() => _wrap(_ptr.memory);

  List get profiles() => _wrap(_ptr.profiles);

  void assertCondition(bool condition, Object arg) {
    _ptr.assertCondition(_unwrap(condition), _unwrap(arg));
    return;
  }

  void count() {
    _ptr.count();
    return;
  }

  void debug(Object arg) {
    _ptr.debug(_unwrap(arg));
    return;
  }

  void dir() {
    _ptr.dir();
    return;
  }

  void dirxml() {
    _ptr.dirxml();
    return;
  }

  void error(Object arg) {
    _ptr.error(_unwrap(arg));
    return;
  }

  void group(Object arg) {
    _ptr.group(_unwrap(arg));
    return;
  }

  void groupCollapsed(Object arg) {
    _ptr.groupCollapsed(_unwrap(arg));
    return;
  }

  void groupEnd() {
    _ptr.groupEnd();
    return;
  }

  void info(Object arg) {
    _ptr.info(_unwrap(arg));
    return;
  }

  void log(Object arg) {
    _ptr.log(_unwrap(arg));
    return;
  }

  void markTimeline() {
    _ptr.markTimeline();
    return;
  }

  void profile(String title) {
    _ptr.profile(_unwrap(title));
    return;
  }

  void profileEnd(String title) {
    _ptr.profileEnd(_unwrap(title));
    return;
  }

  void time(String title) {
    _ptr.time(_unwrap(title));
    return;
  }

  void timeEnd(String title, Object arg) {
    _ptr.timeEnd(_unwrap(title), _unwrap(arg));
    return;
  }

  void timeStamp(Object arg) {
    _ptr.timeStamp(_unwrap(arg));
    return;
  }

  void trace(Object arg) {
    _ptr.trace(_unwrap(arg));
    return;
  }

  void warn(Object arg) {
    _ptr.warn(_unwrap(arg));
    return;
  }
}
