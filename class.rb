require 'date'
require 'csv'
require 'holiday_japan' #gem install holiday_japan
require 'active_support/all' # 数字の3桁区切り(.to_s(:delimited))に必要

class TicketPrice
  attr_reader :price, :error_message
  def initialize
    @price = 0
    @skip_key = 0
    @error_message = []
  end
  def correct_customer?(type, index)
    customer_type = {
      "シネマシティズン（60才以上）" => 1,
      "中・高校生" => 2,
      "幼児（3才以上）・小学生" => 3,
      "障がい者（学生以上）" => 4,
      "障がい者（高校以下）" => 5,
      "シニア（70才以上）" => 6,
      "一般" => 7,
      "学生（大・専）" => 8,
      "シネマシティズン" => 9,
    }
    if customer_type.key?(type)
      return customer_type[type]
    else
      @error_message << "(line:#{index+1})「#{type}」は存在しない料金タイプです)"
    end
  end
  def correct_title?(title, index)
    screenings = [
      "ジュマンジ",
      "ルパン三世",
      "スター・ウォーズ",
      "ジョーカー",
      "アナと雪の女王",
    ]
    @error_message << "(line:#{index+1})「#{title}」は上映されていない作品です" unless screenings.include?(title)
  end
  def set_base_price
    @price = 1000
  end
  def customer_tuning(type)
    case type
    when 5
      @price -= 100
    when 6
      @price += 100
    else
    end
  end
  def holiday?(date, datetime)
    HolidayJapan.check(date) || ( datetime.wday == 0 || datetime.wday == 6 )
  end
  def weekday_tuning(type)
    case type
    when 9
      @skip_key = 1
    end
  end
  def movie_day?(datetime)
    datetime.day == 1
  end
  def movie_day_tuning(type)
    return if @skip_key == 1
    case type
    when 7, 8, 9
      @price += 100
    end
  end
  def time_zone?(start_hour)
    if start_hour < 20
      return 0
    else
      return 1
    end
  end
  def time_zone_tuning(start_hour, type)
    return if @skip_key == 1
    case type
    when 7
      case self.time_zone?(start_hour)
      when 0
        @price += 800
      when 1
        @price += 300
      end
    when 8
      case self.time_zone?(start_hour)
      when 0
        @price += 500
      when 1
        @price += 300
      end
    when 9
      case self.time_zone?(start_hour)
      when 0
        @price += 300
      when 1
      end
    end
  end
end

class Sales
  attr_accessor :all_summary, :title_summary, :guest_summary
  def initialize
    @all_summary = 0
    @title_summary = {}
    @guest_summary = {}
  end
  def all_sales(sales)
    @all_summary += sales
  end
  def title_sales(title_hash, title)
    if @title_summary.key?(title)
      @title_summary = @title_summary.merge(title_hash) {|key, oldval, newval| newval + oldval}
    else
      @title_summary[title] = title_hash[title]
    end
  end
  def guest_sales(guest_hash, guest)
    if @guest_summary.key?(guest)
      @guest_summary = @guest_summary.merge(guest_hash) {|key, oldval, newval| newval + oldval}
    else
      @guest_summary[guest] = guest_hash[guest]
    end
  end
end
