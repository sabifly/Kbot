require 'discordrb'
require 'csv'

class Kbot
	# 初期化
	def initialize
		# botの定義
		@bot = Discordrb::Bot.new token: 'MzEyODg3MzI0NjkyMTg1MDg5.C_hmog._CIsuE9jNLuor7CUeT8Vp7EbdXg', client_id: 312887324692185089
		# CSVファイル読み込み
		@csv_data = CSV.read('./words.csv', headers: true)
		# 最終行番号
		@last_line_no = @csv_data.size
		# スリープの状態
		@is_sleep = false
		# イベント格納用ハッシュ
		@event_hash = Hash.new("default")
		# TODO: startで起動させないメソッド 暫定的に配列で管理する 別のやり方を模索中...
		@primely_methods = [:start, :run, :add_event]
	end

	# Bot起動処理
	def start
		# インスタンスメソッドを順次実行
		self.class.instance_methods(false).each do |exec_method|
			# 特定のメソッドを除く
			if (!@primely_methods.include?(exec_method))
				send exec_method
			end
		end
		run
	end

	# bot起動
	def run
		@bot.run
	end

	# イベント追加
	def add_event(id, req, res)
		@bot.message(contains: req) do |event|
			event.respond res
			@event_hash[id] = @bot.message
		end
	end

	# 単語リスト中の全イベント追加
	def add_all_event
		return if @is_sleep
		@csv_data.each do |data|
			add_event(data[0], data[1], data[2])
		end
	end

	# 学習コマンド
	def learn
		@bot.message(start_with: '!oikora') do |event|
			return if @is_sleep
			msg = event.message.content
			if msg.match(".*\s.*\s.*")
				req = msg.split(" ")[1]
				res = msg.split(" ")[2]
				CSV.open('./words.csv','a') do |file|
					@last_line_no += 1
					file << [@last_line_no,req,res]
				end
				add_event(@last_line_no, req, res)
				event.respond '覚えたわ！XOXO'
			end
		end
	end

	# 単語リスト表示コマンド
	def showWordList
		@bot.message(start_with: '!douke') do |event|
			csv_data = @csv_data.sort_by { |_, b| b }
			msg = ''
			@csv_data.each{|row|
				msg << %(#{row[0]},#{row[1]},#{row[2]})
				msg << "\n"
			}
			event.respond msg
		end
	end

	# スリープコマンド
	def sleep
		@bot.message(start_with: '!dontmove') do |event|
			event.respond '寝るわ！！ぐぐっ！！'
			@is_sleep = true
		end
	end

	# スリープ解除コマンド
	def wake
		@bot.message(start_with: '!move') do |event|
			event.respond 'おは・ｗ・'
			@is_sleep = false
		end
	end

	# スリープ状態確認コマンド
	def is_sleep
		@bot.message(start_with: '!tooya') do |event|
			if @is_sleep
				event.respond 'Zzz...'
			else
				event.respond 'え！？なにけ！？'
			end
		end
	end

	# 終了コマンド
	def exit
		@bot.message(start_with: '!gg') do |event|
			@bot.stop
		end
	end
end
