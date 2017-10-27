#! ruby
# ruby 2.4.2

# *SPECS*
#  We are looking for a program that manages disjointed intervals of integers.
#  E.g.: [[1, 3], [4, 6]] is a valid object gives two intervals.
#  [[1, 3], [3, 6]] is not a valid object because it is not disjoint.
#  [[1, 6]] is the intended result.
#  Empty array [] means no interval, it is the default/start state.
#  We want you to implement two functions:
#    - add(from, to)
#    - remove(from, to)

require 'set'                  # Adding Set and Sorted Set from Ruby Core
require 'test/unit/assertions' # To perform some tests
include Test::Unit::Assertions # To include testing functions

# *To add 2 functions to the Ruby Time class*
class Time

  # *To represent a Time (hours & minutes) as an Integer*
  def time_to_int
    hour * 60 + min
  end

  # *To have the Time represented by the number of minutes from midnight*
  def self.int_to_time(int)
    now = Time.now
    Time.new(now.year, now.month, now.day, int.to_i / 60, int.to_i % 60)
  end

end

# *Extending the class Range with the following functions*
#  - spaceship
#  - overlaps?
#  - intersection
#  - fully_includes?
#  - merge
#  - minus
#  - create_int_array
#  - create_time_range
class Range

  # *To compare the range with another range*
  # (spaceship must be defined to order ranges, within a Sorted Set)
  def <=>(other)
    first <=> other.begin
  end

  # *To check if the range overlaps the other*
  def overlaps?(other)
    cover?(other.begin) || other.cover?(first)
  end

  # *To get the intersection with another range*
  def intersection(other)
    [first, other.begin].max..[last, other.end].min
  end

  # *To check if the range includes fully the other (strictly)*
  def fully_includes?(other)
    overlaps?(other) && other == intersection(other)
  end

  # *To merge with another range*
  def merge(other)
    Range.new([first, other.begin].min, [last, other.end].max)
  end

  # *To subtracts the range with another range*
  def -(other)

    # the ranges don't overlap, nothing to subtract
    return self unless overlaps?(other)

    # the other range is bigger, resulting in no more range.
    return [] if other.fully_includes?(self)

    # the range is fully included into the other, the results is to discontinuous ranges.
    return [Range.new(first, other.begin), other.end..last] if fully_includes?(other)

    # Comparing the range to the other
    case self <=> other
      when -1, 0 # survival range is its left sub-range
        [Range.new(first, other.begin)]
      when 1     # survival range is its right sub-range
        [other.end..last]
    end

  end

  # *To represent a range as an array of dimension 2, holding its boundaries*
  def create_int_array
    [first.time_to_int, last.time_to_int]
  end

  # *To create a range of time from 2 integers (cf. below the practical application)*
  def self.create_time_range(from, to)
    from, to = to, from if to < from # Re-order if needed
    Range.new(Time.int_to_time(from), Time.int_to_time(to))
  end

end

# *Representing a Day as a Sorted Set of (Time) Ranges*
class Day < SortedSet

  # *To merge a (time) range with the Sorted Set of (time) ranges*
  def merge_range(time_range)

    # Add to the Sorted Set (ensuring the uniqueness by the definition of a Set)
    self << time_range

    # Considering 2 consecutive (time) ranges (already sorted by the definition of a Sorted Set)
    each_cons(2) do |time_range_before, time_range_after|

      # We need to consider if 2 consecutive (time) ranges are overlapping
      if time_range_before.overlaps?(time_range_after)

        # Removing the 2 overlapped (time) ranges from the Sorted Set
        subtract [time_range_before, time_range_after]

        # Merging the 2 (time) ranges (recursive call)
        merge_range time_range_before.merge(time_range_after)

      end

    end

    self
  end

end

# *Schedule your Mechanic!*
class Mechanic

  attr_reader :day, :with_time # Attributes accessible as read-only

  # *To initialize the mechanic*
  #   - with_time: if true, the (time) ranges will be Time ranges.
  def initialize(with_time=true)
    @with_time
    @day = Day.new # the time schedule for the mechanic
  end

  # *To add a (time) range*
  def add(from, to)
    @day.merge_range(@with_time ? Range.create_time_range(from, to) : from..to)
    day
  end

  # *to remove a (time) range*
  def remove(from, to)
    time_range_to_remove = @with_time ? Range.create_time_range(from, to) : from..to

    # Check and Delete if there is an exact match of the (time) range and an existing (time) range within the day.
    unless @day.delete?(time_range_to_remove)

      # looking at each (time) range of the day
      @day.each do |time_range|

        # Check if the (time) range to remove overlaps the current (time) range
        if time_range_to_remove.overlaps?(time_range)

          # Delete the (time) range
          @day.delete time_range

          # Merge the difference between the (time) range and the (time) range to remove.
          @day.merge(time_range - time_range_to_remove)

        end

      end

    end

    day
  end

  # day accessor
  def day
    if @with_time
      @day.map(&:create_int_array)
    else
      @day.map{|range| [range.begin, range.end]}
    end
  end
end

# An example sequence:
mechanic = Mechanic.new(false)
assert_equal [],                       mechanic.day
assert_equal [[1, 5]],                 mechanic.add(1, 5)
assert_equal [[1, 2], [3, 5]],         mechanic.remove(2, 3)
assert_equal [[1, 2], [3, 5], [6, 8]], mechanic.add(6, 8)
assert_equal [[1, 2], [3, 4], [7, 8]], mechanic.remove(4, 7)
assert_equal [[1, 8]],                 mechanic.add(2, 7)
p 'vroom!'

# A practical application for such a solution:
#   To define mechanic's availability for a day.
#   A key responsibility is ensuring timely matching of mechanic availability to customer demand for a service
#   and the mechanic's calendar is an integral part of that process.
#
# As an example, these intervals could be thought of as representing ranges of time within a day, in terms of the number of minutes from midnight.
# E.g: the interval array: [[0, 62], [150, 180]] would represent the ranges of 12:00 AM to 1:02 AM and 2:30 AM to 3:00 AM.
# The add/remove functions can be thought of as adding or removing available time from the day's schedule.
# E.g: remove(420, 480) implies that the entire period from 7:00 AM to 8:00 AM is now unavailable on the schedule.

mechanic = Mechanic.new
assert_equal [],                                   mechanic.day
assert_equal [[100, 500]],                         mechanic.add(100, 500)
assert_equal [[100, 200], [300, 500]],             mechanic.remove(200, 300)
assert_equal [[100, 200], [300, 500], [600, 800]], mechanic.add(600, 800)
assert_equal [[100, 200], [300, 400], [700, 800]], mechanic.remove(400, 700)
assert_equal [[100, 800]],                         mechanic.add(200, 700)
p 'vroom vroom!'