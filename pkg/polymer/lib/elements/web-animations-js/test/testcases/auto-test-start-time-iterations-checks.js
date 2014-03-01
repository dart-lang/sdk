timing_test(function() {
  at(0, function() {
    assert_styles("#normal_a",{'left':'0px'});
    assert_styles("#normal_b",{'left':'0px'});
    assert_styles("#reverse_a",{'left':'0px'});
    assert_styles("#reverse_b",{'left':'0px'});
    assert_styles("#alternate_a",{'left':'0px'});
    assert_styles("#alternate_b",{'left':'0px'});
    assert_styles("#alternate-reverse_a",{'left':'0px'});
    assert_styles("#alternate-reverse_b",{'left':'0px'});
  });
  at(1, function() {
    assert_styles("#normal_a",{'left':'200px'});
    assert_styles("#normal_b",{'left':'500px'});
    assert_styles("#reverse_a",{'left':'400px'});
    assert_styles("#reverse_b",{'left':'500px'});
    assert_styles("#alternate_a",{'left':'200px'});
    assert_styles("#alternate_b",{'left':'500px'});
    assert_styles("#alternate-reverse_a",{'left':'400px'});
    assert_styles("#alternate-reverse_b",{'left':'500px'});
  });
  at(2, function() {
    assert_styles("#normal_a",{'left':'200px'});
    assert_styles("#normal_b",{'left':'500px'});
    assert_styles("#reverse_a",{'left':'400px'});
    assert_styles("#reverse_b",{'left':'500px'});
    assert_styles("#alternate_a",{'left':'400px'});
    assert_styles("#alternate_b",{'left':'500px'});
    assert_styles("#alternate-reverse_a",{'left':'200px'});
    assert_styles("#alternate-reverse_b",{'left':'500px'});
  });
  at(3, function() {
    assert_styles("#normal_a",{'left':'500px'});
    assert_styles("#normal_b",{'left':'500px'});
    assert_styles("#reverse_a",{'left':'100px'});
    assert_styles("#reverse_b",{'left':'500px'});
    assert_styles("#alternate_a",{'left':'100px'});
    assert_styles("#alternate_b",{'left':'500px'});
    assert_styles("#alternate-reverse_a",{'left':'500px'});
    assert_styles("#alternate-reverse_b",{'left':'500px'});
  });
  at(4, function() {
    assert_styles("#normal_a",{'left':'500px'});
    assert_styles("#normal_b",{'left':'100px'});
    assert_styles("#reverse_a",{'left':'100px'});
    assert_styles("#reverse_b",{'left':'500px'});
    assert_styles("#alternate_a",{'left':'100px'});
    assert_styles("#alternate_b",{'left':'500px'});
    assert_styles("#alternate-reverse_a",{'left':'500px'});
    assert_styles("#alternate-reverse_b",{'left':'100px'});
  });
  at(5, function() {
    assert_styles("#normal_a",{'left':'500px'});
    assert_styles("#normal_b",{'left':'500px'});
    assert_styles("#reverse_a",{'left':'100px'});
    assert_styles("#reverse_b",{'left':'500px'});
    assert_styles("#alternate_a",{'left':'100px'});
    assert_styles("#alternate_b",{'left':'500px'});
    assert_styles("#alternate-reverse_a",{'left':'500px'});
    assert_styles("#alternate-reverse_b",{'left':'500px'});
  });
  at(6, function() {
    assert_styles("#normal_a",{'left':'500px'});
    assert_styles("#normal_b",{'left':'500px'});
    assert_styles("#reverse_a",{'left':'100px'});
    assert_styles("#reverse_b",{'left':'500px'});
    assert_styles("#alternate_a",{'left':'100px'});
    assert_styles("#alternate_b",{'left':'500px'});
    assert_styles("#alternate-reverse_a",{'left':'500px'});
    assert_styles("#alternate-reverse_b",{'left':'500px'});
  });
  at(7, function() {
    assert_styles("#normal_a",{'left':'500px'});
    assert_styles("#normal_b",{'left':'500px'});
    assert_styles("#reverse_a",{'left':'100px'});
    assert_styles("#reverse_b",{'left':'500px'});
    assert_styles("#alternate_a",{'left':'100px'});
    assert_styles("#alternate_b",{'left':'500px'});
    assert_styles("#alternate-reverse_a",{'left':'500px'});
    assert_styles("#alternate-reverse_b",{'left':'500px'});
  });
  at(8, function() {
    assert_styles("#normal_a",{'left':'500px'});
    assert_styles("#normal_b",{'left':'500px'});
    assert_styles("#reverse_a",{'left':'100px'});
    assert_styles("#reverse_b",{'left':'100px'});
    assert_styles("#alternate_a",{'left':'100px'});
    assert_styles("#alternate_b",{'left':'100px'});
    assert_styles("#alternate-reverse_a",{'left':'500px'});
    assert_styles("#alternate-reverse_b",{'left':'500px'});
  });
}, "Auto generated tests");
