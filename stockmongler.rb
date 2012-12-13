# This is a simple program that slurps in a data file in the following format,
# as provided by Yahoo Finance:
# Date,Open,High,Low,Close,Volume,Adjusted Close
# It slurps in the text file, and walks down the open and close
# prices.  If the close is higher than the open, it buys the stock,
# if the inverse it sells it.  It records the number of trades
# and the amount of money it makes and loses,
# and prints them out at the end.
# Get the data from http://finance.yahoo.com/q/hp?s=GOOG


class Trader
   def init
      @file = ""
      @trades = 0
      @money = 0
      @trading = true
      @maximum = 0.0
      @data = []
   end

   def parse(file)
      @file = file
      IO.foreach(file) {|line|
         wholeData = line.split(",")
         deltaPrice = wholeData[4].to_f - wholeData[1].to_f
         @data.push(deltaPrice)
      }
   end

   def calcMax
      @data.each {|delta|
         if delta > 0 then
            @maximum += delta
         end
      }
   end


   def getDelta(date)
      if date < 0 then
         return 0
      elsif date > (@data.length - 1) then
         return 0
      else
         return @data[date]
      end
   end

   def movingAverage(date,length)
      delta = 0
      for i in (date-length)...date
         delta += getDelta(i)
      end
      return (delta/length) 
   end

   def pessimisticMovingAverage(date,length)
      delta = 0
      if getDelta(date) < 0 then
         return -1
      end
      for i in (date-length)...date
         delta += getDelta(i)
      end
      return (delta/length) 
   end

   def sizeWeightedAverage(date,length)
      total = 0
      delta = 0
      for i in (date-length)...date
         total += getDelta(i)
      end
      if total == 0 then return 0 end
      for i in (date-length)...date
         delta += getDelta(i) * (getDelta(i) / total)
      end 
      return (delta/length) 
   end

   def timeWeightedAverage(date,length)
      total = 0
      delta = 0
      for i in (date-length)...date
         total += getDelta(i)
      end
      for i in (date-length)...date
         delta += getDelta(i) / (2**(length-i))
      end 
      return (delta/length) 
   end

   def highPass(date,size)
      delta = getDelta(date)
      if delta > size then
         return 1
      elsif delta < (-size) then
         return -1
      else
         return 0
      end
   end

   def lowPass(date,size)
      delta = getDelta(date)
      if (delta > 0) and (delta < size) then
         return 1
      elsif delta > (-size) then
         return -1
      else
         return 0
      end
   end


   def analyze
      for i in 0...@data.length()
         basis = movingAverage(i,5) # timeWeightedAverage(i,7)
         todayDelta = @data[i]
         if basis > -3 then
            if @trading then
               @money += todayDelta
            else
               @trading = true
               @trades += 1
            end
         else
            if @trading then
               @money += todayDelta
               @trading = false
               @trades += 1
            end
         end
      end
   end

   def output
      # File, days, trades, money, efficiency
      print("%s,%d,%d,%f,%f\n" % [@file, @data.length, @trades, @money,
         @money/@maximum])
   end

   def money 
      return @money 
   end
   def trades 
      return @trades 
   end
   def efficiency
      return @money / @maximum
   end
end

print("File,Days,Trades,Money\n")
averageMoney = 0.0
averageTrades = 0.0
averageEfficiency = 0.0
ARGV.each {|stock|
   a = Trader.new;
   a.init;
   a.parse(stock);
   a.calcMax;
   a.analyze();
   a.output;
   averageMoney += a.money;
   averageTrades += a.trades;
   averageEfficiency += a.efficiency;
}
print("Stocks: %d, Avg. money: %f, avg. trades: %f, avg. efficiency: %f\n" % 
      [ARGV.length, averageMoney / ARGV.length, averageTrades / ARGV.length,
       averageEfficiency / ARGV.length]
     )
