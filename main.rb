require 'csv'
require 'date'
require 'time'
require 'holiday_japan'
require 'active_support/all'

@all_summary = 0
@title_summary = {}
@guest_summary = {}

CSV.foreach("data.csv") do |row|
  title = {}
  guest = {}

  row << 1000
  case row[2]
  when "障がい者（高校以下）"
    row[4] -= 100
  when "シニア（70才以上）"
    row[4] += 100
  when "学生（大・専）"
    row[4] += 500
  when "一般"
    row[4] += 800
  else
  end

  date = DateTime.parse(row[0])
  # step2 時間帯条件分岐
  if date.hour >= 20
    case row[2]
    when "一般"
      row[4] -= 500
    when "学生（大・専）"
      row[4] -= 200
    end
  end

  # step3 祝日条件分岐
  holiday = Date.parse(row[0])
  if date.hour < 20
    row[4] += 300 if HolidayJapan.check(holiday) && row[2] == "シネマシティズン"
    row[4] += 300 if ( date.wday == 0 || date.wday == 6 ) && row[2] == "シネマシティズン"
  end

  # step4 1日条件分岐
  if date.day == 1
    case row[2]
    when "シネマシティズン", "一般", "シニア", "学生（大・専）"
      row[4] = 1100
    end
  end

  # 結果表示
  p row if row[3] != "#{row[4]}"

  # 集計(全作品)
  @all_summary += row[4]

  # 集計(作品別売上)
  title = {row[1] => row[4]}
  if @title_summary.key?(row[1])
    @title_summary = @title_summary.merge(title) {|key, oldval, newval| newval + oldval}
  else
    @title_summary[row[1]] = row[4]
  end
  title = {}

  # 集計(料金タイプ別売上)
  guest = {row[2] => row[4]}
  if @guest_summary.key?(row[2])
    @guest_summary = @guest_summary.merge(guest) {|key, oldval, newval| newval + oldval}
  else
    @guest_summary[row[2]] = row[4]
  end
  guest = {}
end

p "▼サマリー"
p "#{@all_summary.to_s(:delimited)}円"
p "▼作品別売上"
@title_summary.each do |key, value|
  puts key.to_s + ": " + "#{value.to_s(:delimited)}円"
end
p "▼料金タイプ別売上"
@guest_summary.each do |key, value|
  puts key.to_s + ": " + "#{value.to_s(:delimited)}円"
end
