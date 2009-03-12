require 'test_helper'

class MutexCounterTest < Test::Unit::TestCase
  context "with a new counter" do 
    setup do
      @counter = Pandemic::MutexCounter.new
    end

    should "start at 0" do
      assert_equal 0, @counter.value
    end

    should "increment to 1 after one call to inc" do
      assert_equal 0, @counter.value
      assert_equal 1, @counter.inc
      assert_equal 1, @counter.value
    end
    
    should "be thread safe" do
      # Not exactly a perfect test, but I'm not sure how to actually test 
      # this without putting some code in the counter for this reason.
      threads = []
      5.times { threads << Thread.new { 100.times { @counter.inc }}}
      threads.each {|t| t.join } # make sure they're all done
      assert_equal 500, @counter.value
    end
  end
    
  context "with a max of 10" do
    setup do
      @counter = Pandemic::MutexCounter.new(10)
    end
    
    should "cycle from 1 to 10" do
      expected = (1..10).to_a + [1]
      actual = (1..11).collect { @counter.inc }
      assert_equal expected, actual
    end
    
    should "have the correct 'real_total'" do
      11.times { @counter.inc }
      assert_equal 1, @counter.value
      assert_equal 11, @counter.real_total
    end
  end
end