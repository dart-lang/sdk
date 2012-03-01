
class _TextImpl extends _CharacterDataImpl implements Text {
  _TextImpl._wrap(ptr) : super._wrap(ptr);

  String get wholeText() => _wrap(_ptr.wholeText);

  Text replaceWholeText(String content) {
    return _wrap(_ptr.replaceWholeText(_unwrap(content)));
  }

  Text splitText(int offset) {
    return _wrap(_ptr.splitText(_unwrap(offset)));
  }
}
