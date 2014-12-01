require 'rubygems'
require 'sinatra'

set :sessions, true

BLACKJACK_AMOUNT = 21
DEALER_MIN_HIT = 17


helpers do

  def calculate_total(cards) # e.g.[["D","2"],["D","A"],["D","3"],["H","A"],...]
    arr=cards.map{|element| element[1]} # ["2"],["A"],["3"],["A"]
    total=0

    arr.each do |a| # ["2"],["A"],["3"],["A"].each
      if a=="A"
        total+=11
      else
        total+=a.to_i==0? 10 : a.to_i # first if a.to_i = 0?(e.g. J,Q,K), total+=10; else total+=a.to_i.(e.g. 2,3,4...)
      end

    end # end of arr.each 

    arr.select{|element| element=="A"}.count.times do # ["A"],["A"].count==2, do 2 times.
      break if total<=21
      total-=10
    end

    total
  end # of calculate

  def card_image(card)
    suit=case card[0]
      when 'H' then 'hearts'
      when 'C' then 'clubs'
      when 'D' then 'diamonds'
      when 'S' then 'Spades'
    end

    value = card[1]
    if ['A','J','Q','K'].include?(value)
      value=case 
        when 'A' then 'ace'
        when 'J' then 'jack'
        when 'Q' then 'queen'
        when 'K' then 'king'
      end
    end # of if include

    "<img src='/images/cards/#{suit}_#{value}.jpg' class='card_image'>"
  end # of card_image

  def winner!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>#{session[:player_name]} wins!</strong> #{msg}"
  end

  def loser!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @error = "<strong>#{session[:player_name]} loses.</strong> #{msg}"
  end

  def tie!(msg)
    @play_again = true
    @show_hit_or_stay_buttons = false
    @success = "<strong>It's a tie!</strong> #{msg}"
  end

end # of helper


before do
 @show_hit_or_stay_buttons = true
end


get '/' do
	if session[:player_name]
    redirect '/game'
  else
    redirect '/new_player'
  end
end # of /


get '/new_player' do
  erb :new_player
end # of /new_player


post '/new_player' do
  if params[:player_name].empty?
    @error="Name is null, Please enter your name."
    halt erb(:new_player)
  end

  session[:player_name]=params[:player_name]
  redirect '/game'
end # of /new_player


get '/game' do
  session[:turn] = session[:player_name]

  suits = ['H','D','C','S']
  values = ['2','3','4','5','6','7','8','9','10','J','Q','K','A']
  session[:deck]=suits.product(values).shuffle!
  
  session[:dealer_cards]=[]
  session[:player_cards]=[]
  session[:dealer_cards]<<session[:deck].pop
  session[:player_cards]<<session[:deck].pop
  session[:dealer_cards]<<session[:deck].pop
  session[:player_cards]<<session[:deck].pop
  
  erb :game
end # of /game

post '/game/player/hit' do
  session[:player_cards]<<session[:deck].pop

  player_total=calculate_total(session[:player_cards])
  if player_total == 21
    "Congratulations! hit BlackJack!"
    @show_hit_or_stay_buttons = false
  elsif player_total > 21
    @error = "Sorry, you busted!"
    @show_hit_or_stay_buttons = false
  end

  erb :game
end # of /game/player/hit


post '/game/player/stay' do
  @success = "You has chosen to stay."
  @show_hit_or_stay_buttons = false
  redirect '/game/dealer'
end


get '/game/dealer' do
  session[:turn] = "dealer"
  @show_hit_or_stay_buttons = false

  dealer_total=calculate_total(session[:dealer_cards])

  if dealer_total == BLACKJACK_AMOUNT
    loser!("Dealer hit blackjack.")
  elsif dealer_total > BLACKJACK_AMOUNT
    winner!("Dealer busted at #{dealer_total}.")
  elsif dealer_total >= DEALER_MIN_HIT
    redirect '/game/compare'
  else
    @show_dealer_hit_button = true
  end

  erb :game
end # of /game/dealer


post '/game/dealer/hit' do
  session[:dealer_cards]<<session[:deck].pop
  redirect '/game/dealer'
end


get '/game/compare' do
  @show_hit_or_stay_buttons = false

  player_total=calculate_total(session[:player_cards])
  dealer_total=calculate_total(session[:dealer_cards])

  if player_total < dealer_total
    loser!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  elsif player_total > dealer_total
    winner!("#{session[:player_name]} stayed at #{player_total}, and the dealer stayed at #{dealer_total}.")
  else
    tie!("Both #{session[:player_name]} and the dealer stayed at #{player_total}.")
  end

  erb :game
end # of game/compare


get '/game_over' do
  erb :game_over
end