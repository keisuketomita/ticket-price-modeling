require './class'
require 'csv'

@sales = Sales.new
@errors = []
array = CSV.read("data.csv")
array.each_with_index do |row, index|
  tp = TicketPrice.new
  datetime = DateTime.parse(row[0])
  date = Date.parse(row[0])
  customer_type = tp.correct_customer?(row[2], index)
  tp.correct_title?(row[1], index)
  if tp.error_message.empty?
    # step1 ベース料金の設定
    tp.set_base_price
    # step2 料金プランの調整
    tp.customer_tuning(customer_type)
    # step3 映画の日、時間帯、曜日による調整
    tp.weekday_tuning(customer_type) unless tp.holiday?(date, datetime)
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
  else
    tp.error_message.each do |message|
      @errors.push [message]
    end
  end
  if index == array.size - 1
    CSV.open("result.csv", "wb", col_sep: "\t") do |csv|
      csv << ["▼サマリー"]
      csv << ["売上： #{@sales.all_summary.to_s(:delimited)}円"]
      csv << []
      csv << ["▼作品別売上"]
      @sales.title_summary.each do |key, value|
        csv << ["・" + key.to_s + ": " + "#{value.to_s(:delimited)}円"]
      end
      csv << []
      csv << ["▼料金タイプ別売上"]
      @sales.guest_summary.each do |key, value|
        csv << ["・" + key.to_s + ": " + "#{value.to_s(:delimited)}円"]
      end
    end
    CSV.open("error.csv", "wb") do |csv|
      @errors.each do |message|
        csv << message
      end
    end
  end
end
