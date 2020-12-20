require 'date'
require 'csv'
require 'holiday_japan' #gem install holiday_japan
require 'active_support/all' # 数字の3桁区切り(.to_s(:delimited))に必要

class TicketPrice
  attr_reader :price
  def initialize
    @price = 0
    @skip_key = 0
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
  def holiday?(date, datetime, type)
    unless HolidayJapan.check(date) || ( datetime.wday == 0 || datetime.wday == 6 )
      case type
      when 9
        @skip_key = 1
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


@sales = Sales.new
array = CSV.read("data.csv")
array.each_with_index do |row, index|
  tp = TicketPrice.new
  datetime = DateTime.parse(row[0])
  date = Date.parse(row[0])
  customer_type = tp.customer_type(row[2])
  # step1 ベース料金の設定
  tp.set_base_price
  # step2 料金プランの調整
  tp.customer_tuning(customer_type)
  # step3 映画の日、時間帯、曜日による調整
  tp.holiday?(date, datetime, customer_type)
  tp.movie_day?(datetime) ? tp.movie_day_tuning(customer_type) : tp.time_zone_tuning(datetime.hour, customer_type)

  # 集計(全作品)
  @sales.all_sales(tp.price)

  # 集計(作品別売上)
  title_hash = {row[1] => tp.price}
  @sales.title_sales(title_hash, row[1])
  title = {}

  # 集計(料金タイプ別売上)
  guest_hash = {row[2] => tp.price}
  @sales.guest_sales(guest_hash, row[2])
  guest = {}

  if index == array.size - 1
    puts "▼サマリー"
    puts "#{@sales.all_summary.to_s(:delimited)}円"
    puts ""

    puts "▼作品別売上"
    @sales.title_summary.each do |key, value|
      puts "・" + key.to_s + ": " + "#{value.to_s(:delimited)}円"
    end
    puts ""

    puts "▼料金タイプ別売上"
    @sales.guest_summary.each do |key, value|
      puts "・" + key.to_s + ": " + "#{value.to_s(:delimited)}円"
    end
  end
end
