timing_test(function() {
  at(0, function() {
    assert_styles(".anim",{'x':'0px'});
    assert_styles(".anim2",{'ctm':'{1, 0, 0, 1, 0, 0}'});
  });
  at(1, function() {
    assert_styles(".anim",{'x':'133.3px'});
    assert_styles(".anim2",{'ctm':'{1, 0, 0, 1, 66.67, 66.67}'});
  });
  at(2, function() {
    assert_styles(".anim",{'x':'316.7px'});
    assert_styles(".anim2",{'ctm':'{0.9239, 0.3827, -0.3827, 0.9239, 156.4, 142.9}'});
  });
  at(3, function() {
    assert_styles(".anim",{'x':'500px'});
    assert_styles(".anim2",{'ctm':'{0.7071, 0.7071, -0.7071, 0.7071, 235.4, 235.4}'});
  });
  at(4, function() {
    assert_styles(".anim",{'x':'550px'});
    assert_styles(".anim2",{'ctm':'{0.3827, 0.9239, -0.9239, 0.3827, 228.7, 269.3}'});
  });
  at(5, function() {
    assert_styles(".anim",{'x':'600px'});
    assert_styles(".anim2",{'ctm':'{0, 1, -1, 0, 200, 300}'});
  });
}, "Auto generated tests");
