require 'rubygems'
require 'pry'
require 'sinatra'

set :sessions, true

helpers do
  def calculate_total(cards)
    arr = cards.map{|element| element[1]}

    total = 0
    arr.each do |a|
      if a == "A"
        total += 11
      else
        total += a.to_i == 0 ? 10 : a.to_i
      end
    end

    arr.select{|element| element == "A"}.count.times do
      break if total <= 21
      total -= 10
    end

    total
  end

  def card_image(card)
    suit = case card[0]
      when 'H' then 'hearts'
      when 'D' then 'diamonds'
      when 'C' then 'clubs'
      when 'S' then 'spades'
    end

    value = card[1]
    if ['J', 'Q', 'K', 'A'].include?(value)
      value = case card[1]
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
        when 'A' then 'ace'
      end
    end

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end


  def winner!(msg)
    session[:bankroll] = session[:bankroll] + session[:bet].to_i
    @show_hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    session[:bankroll] = session[:bankroll] - session[:bet].to_i
    @show_hit_or_stay_buttons = false
    @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @show_hit_or_stay_buttons = false
    @success = "<strong>It is a tie!</strong> #{msg}"
  end
end

before do
  @show_hit_or_stay_buttons = true
end

get '/' do
  if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end

get '/new_player' do
  erb :new_player
end

post '/new_player' do
  if params[:player_name].empty?
    @error = "Name is required"
    halt erb(:new_player)
  end

  session[:bankroll] = 500
  session[:player_name] = params[:player_name] 
  redirect '/bet'
end

get '/bet' do
  if session[:bankroll] < 1
    redirect '/game_over'
  end

  erb :bet
end

post '/bet' do
  if (params[:bet].empty?) || (params[:bet].to_i < 1) || (params[:bet].to_i > session[:bankroll].to_i)
    @error = "Number Amount over 1 is required. Also, bet within your bankroll."
    halt erb(:bet)
  end

  session[:bet] = params[:bet]

  redirect '/game'
end

get '/game' do
  session[:turn] = session[:player_name]

  suits = ['H', 'D', 'C', 'S']
  values = ['2', '3', '4', '5', '6', '7', '8', '9', '10', 'J', 'Q', 'K', 'A']
  session[:deck] = suits.product(values).shuffle!

  session[:dealer_cards] = []
  session[:player_cards] = []
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop
  session[:dealer_cards] << session[:deck].pop
  session[:player_cards] << session[:deck].pop

  erb :game
end

post '/game/player/hit' do
  session[:player_cards] << session[:deck].pop
  player_total = calculate_total(session[:player_cards])
  if player_total == 21
    winner!("Winner!")
    @play_again = true
  elsif player_total > 21
    loser!("Loser!")
    @play_again = true
  end

  erb :game
end

post '/game/player/stay' do
  @success = "#{session[:player_name]} has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end

get '/game/dealer' do
  session[:turn] = "dealer"

  @show_hit_or_stay_buttons = false

  dealer_total = calculate_total(session[:dealer_cards])

  if dealer_total > 21
    winner!("Congrats, dealer busted.")
    @play_again = true
  elsif dealer_total >= 17
    redirect '/game/compare'
  else
    redirect '/game/dealer/hit'
  end

    erb :game
end

get '/game/dealer/hit' do
  session[:dealer_cards] << session[:deck].pop
  redirect '/game/dealer'
end

get '/game/compare' do
  @show_hit_or_stay_buttons = false

  player_total = calculate_total(session[:player_cards])
  dealer_total = calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total} and the Dealer stayed at #{dealer_total}")
    @play_again = true
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total} and the Dealer stated at #{dealer_total}")
    @play_again = true
  else
    tie!("Both #{session[:player_name]} and Dealer stayed at #{player_total}")
    @play_again = true
  end

  erb :game
end

get '/game_over' do
  "Game over!"
end