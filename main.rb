require 'date'
require 'csv'
require 'holiday_japan' #gem install holiday_japan
require 'active_support/all' # 数字の3桁区切り(.to_s(:delimited))に必要

class TicketPrice
  attr_accessor :price
  def initialize
    @price = 0
  end
  def customer_type(type)
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
    return customer_type[type]
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
  def movie_day?(date)
    date.day == 1
  end
  def rate_time?(datetime)
    datetime >= 20
  end
  def holiday?(date, datetime)
    HolidayJapan.check(date) || ( datetime.wday == 0 || datetime.wday == 6 )
  end
  def wday_tuning
    @price += 300
  end
end

# class Sales
#   attr_accessor :all_summary, :title_summary, :guest_summary
#   def initialize
#     @all_summary = 0
#     @title_summary = {}
#     @guest_summary = {}
#   end
#   def all_sales(sales)
#     @all_summary = sales
#   end
# end

@all_sales = 0
@title_summary = {}
@guest_summary = {}
CSV.foreach("data.csv") do |row|
  tp = TicketPrice.new
  datetime = DateTime.parse(row[0])
  date = Date.parse(row[0])
  customer_type = tp.customer_type(row[2])
  # step1 ベース料金の設定
  tp.set_base_price
  # step2 料金プランの調整
  tp.customer_tuning(customer_type)
  # step3 映画の日、時間帯、曜日による調整
  case customer_type
  when 7
    if tp.movie_day?(datetime)
      tp.price += 100
    else
      tp.price += tp.rate_time?(datetime.hour) ? 300 : 800
    end
  when 8
    if tp.movie_day?(datetime)
      tp.price += 100
    else
      tp.price += tp.rate_time?(datetime.hour) ? 300 : 500
    end
  when 9
    if tp.holiday?(date, datetime)
      if tp.movie_day?(datetime)
        tp.price += 100
      else
        tp.price += 300 unless tp.rate_time?(datetime.hour)
      end
    end
  else
  end

  # 集計(全作品)
  @all_sales += tp.price

  # 集計(作品別売上)
  title = {row[1] => tp.price}
  if @title_summary.key?(row[1])
    @title_summary = @title_summary.merge(title) {|key, oldval, newval| newval + oldval}
  else
    @title_summary[row[1]] = tp.price
  end
  title = {}

  # 集計(料金タイプ別売上)
  guest = {row[2] => tp.price}
  if @guest_summary.key?(row[2])
    @guest_summary = @guest_summary.merge(guest) {|key, oldval, newval| newval + oldval}
  else
    @guest_summary[row[2]] = tp.price
  end
  guest = {}

end
p "▼サマリー"
p "#{@all_sales.to_s(:delimited)}円"
p "***"

p "▼作品別売上"
@title_summary.each do |key, value|
  puts key.to_s + ": " + "#{value.to_s(:delimited)}円"
end
p "***"

p "▼料金タイプ別売上"
@guest_summary.each do |key, value|
  puts key.to_s + ": " + "#{value.to_s(:delimited)}円"
end
