#library("dom-query.dart");
#import("dart:dom");
#import('../../common/common.dart');
#import('runner.dart');

void main() {
  final int num = 40;

  // Try to force real results.
  var ret;
  window.onload = (Event evt) {
    String html = document.body.innerHTML;

    new Suite(window, 'dom-query')
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
      .test('getElementById', () {
        for (int i = 0; i < num * 30; i++) {
          ret = document.getElementById('testA' + num).nodeType;
          ret = document.getElementById('testB' + num).nodeType;
          ret = document.getElementById('testC' + num).nodeType;
          ret = document.getElementById('testD' + num).nodeType;
          ret = document.getElementById('testE' + num).nodeType;
          ret = document.getElementById('testF' + num).nodeType;
        }
      })
      .test('getElementById (not in document)', () {
        for (int i = 0; i < num * 30; i++) {
          ret = document.getElementById('testA');
          ret = document.getElementById('testB');
          ret = document.getElementById('testC');
          ret = document.getElementById('testD');
          ret = document.getElementById('testE');
          ret = document.getElementById('testF');
        }
      })
      .test('getElementsByTagName(div)', () {
        for (int i = 0; i < num; i++) {
          var elems = document.getElementsByTagName('div');
          ret = elems[elems.length-1].nodeType;
        }
      })
      .test('getElementsByTagName(p)', () {
        for (int i = 0; i < num; i++) {
          final elems = document.getElementsByTagName('p');
          ret = elems[elems.length-1].nodeType;
        }
      })
      .test('getElementsByTagName(a)', () {
        for (int i = 0; i < num; i++) {
          var elems = document.getElementsByTagName('a');
          ret = elems[elems.length-1].nodeType;
        }
      })
      .test('getElementsByTagName(*)', () {
        for (int i = 0; i < num; i++) {
          var elems = document.getElementsByTagName('*');
          ret = elems[elems.length-1].nodeType;
        }
      })
      .test('getElementsByTagName (not in document)', () {
        for (int i = 0; i < num; i++) {
          var elems = document.getElementsByTagName('strong');
          ret = elems.length == 0;
        }
      })
      .test('getElementsByName', () {
        for (int i = 0; i < num * 20; i++) {
          var elems = document.getElementsByName('test' + num);
          ret = elems[elems.length-1].nodeType;
          elems = document.getElementsByName('test' + num);
          ret = elems[elems.length-1].nodeType;
          elems = document.getElementsByName('test' + num);
          ret = elems[elems.length-1].nodeType;
          elems = document.getElementsByName('test' + num);
          ret = elems[elems.length-1].nodeType;
        }
      })
      .test('getElementsByName (not in document)', () {
        for (int i = 0; i < num * 20; i++) {
          ret = document.getElementsByName('test').length == 0;
          ret = document.getElementsByName('test').length == 0;
          ret = document.getElementsByName('test').length == 0;
          ret = document.getElementsByName('test').length == 0;
          ret = document.getElementsByName('test').length == 0;
        }
      })
      .end();
  };
}
