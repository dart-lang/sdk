#library("dom-traverse.dart");
#import("dart:dom");
#import('../../common/common.dart');
#import('runner.dart');


void main() {
  final int num = 40;

  // Try to force real results.
  var ret;

  String html = document.body.innerHTML;

  new Suite(window, 'dom-traverse')
    .prep(() {
      html = BenchUtil.replaceAll(html, 'id="test(\\w).*?"', (Match match) {
        final group = match.group(1);
        return 'id="test${group}${num}"';
      });
      html = BenchUtil.replaceAll(html, 'name="test.*?"', (Match match) {
        return 'name="test${num}"';
      });
      html = BenchUtil.replaceAll(html, 'class="foo.*?"', (Match match) {
        return 'class="foo test${num} bar"';
      });

      final div = document.createElement('div');
      div.innerHTML = html;
      document.body.appendChild(div);
    })
    .test('firstChild', () {
      final nodes = document.body.childNodes;
      final nl = nodes.length;

      for (int i = 0; i < num; i++) {
        for (int j = 0; j < nl; j++) {
          Node cur = nodes[j];
          while (cur !== null) {
            cur = cur.firstChild;
          }
          ret = cur;
        }
      }
    })
    .test('lastChild', () {
      final nodes = document.body.childNodes;
      final nl = nodes.length;

      for (int i = 0; i < num; i++) {
        for (int j = 0; j < nl; j++) {
          Node cur = nodes[j];
          while (cur !== null) {
            cur = cur.lastChild;
          }
          ret = cur;
        }
      }
    })
    .test('nextSibling', () {
      for (int i = 0; i < num * 2; i++) {
        Node cur = document.body.firstChild;
        while (cur !== null) {
          cur = cur.nextSibling;
        }
        ret = cur;
      }
    })
    .test('previousSibling', () {
      for (int i = 0; i < num * 2; i++) {
        Node cur = document.body.firstChild;
        while (cur !== null) {
          cur = cur.previousSibling;
        }
        ret = cur;
      }
    })
    .test('childNodes', () {
      for (int i = 0; i < num; i++) {
        final nodes = document.body.childNodes;
        for (int j = 0; j < nodes.length; j++) {
          ret = nodes[j];
        }
      }
    })
    .end();
}
