require 'facebook/messenger'

Facebook::Messenger.configure do |config|
  puts "trying connection"
  config.access_token = ENV['FB_ACCESS_TOKEN']
  config.verify_token = ENV['FB_VERIFY_TOKEN']
end

include Facebook::Messenger

Bot.on :message do |message|
  messenger_id = message.sender['id']
  response = RestClient.get "https://graph.facebook.com/v2.6/#{messenger_id}?fields=first_name,last_name,profile_pic&access_token=#{ENV['FB_ACCESS_TOKEN']}"
  repos = JSON.parse(response)
  user = User.where(first_name: repos["first_name"]).where(last_name: repos["last_name"]).first

  puts "Received #{message.text} from #{message.sender}"

  interestslist = user.interests
  users_movies = []
  interestslist.each do |interest|
    users_movies << interest.movie
  end

  if user.nil?
    Bot.deliver(
      recipient: message.sender,
      message: {
        text: "Please, sign in with Facebook on https://www.weclap.co"
      }
    )
  else
    case message.text
    when /hello/i
      Bot.deliver(
        recipient: message.sender,
        message: {
          text: "Hello #{user.first_name}"
        }
      )

#change the url for watch the film
    when /watchlist/i
      movie_array = []
      interestslist = user.interests
      counter = 0
      interestslist.each do |interest|
        if counter < 10
          movie_array << {
            "title":"#{interest.movie.title}",
            "image_url":"#{interest.movie.poster_url}",
            "subtitle":"Directed by...",
            "buttons":[
              {
                "type":"web_url",
                "url":"#{interest.movie.website_url}",
                "title":"Show IMDB"
              },
              {
                "type":"web_url",
                "url":"#{interest.movie.website_url}",
                "title":"Watch the film"
              },            
            ]
          }
        end
        counter = counter + 1
      end
      Bot.deliver(
          recipient: message.sender,
          # message: {
          #   text: "#{movie.title}"
          # }
            "message":{
              "attachment":{
                "type":"template",
                "payload": {
                  "template_type":"generic",
                  "elements":movie_array
                }
              }
            }
        )



    when /list/i
      interestslist = user.interests
      interestslist.each do |interest|
        Bot.deliver(
          recipient: message.sender,
          message: {
            #text: "hello #{user.first_name}"
            text: "#{interest.movie.title}"
          }
        )
      end    
    else
      movies = Movie.where('title ILIKE ? OR original_title ILIKE ?', "%#{message.text}%", "%#{message.text}%")
      if movies.empty?
        Bot.deliver(
          recipient: message.sender,
          message: {
            #text: "hello #{user.first_name}"
            text: "Sorry. No film found for #{message.text}"
          }
        )
      else
        movie_array = []
        movies.each do |movie|
          next if users_movies.include?(movie)
          movie_array << {
            "title":"#{movie.title}",
            "image_url":"#{movie.poster_url}",
            "subtitle":"Directed by...",
            "buttons":[
              {
                "type":"web_url",
                "url":"#{movie.website_url}",
                "title":"Show IMDB"
              },
              {
                "type":"postback",
                "title":"Add to watchlist",
                "payload":{"movie_id":"#{movie.id}"}.to_json
              }              
            ]
          }
        end
      end
        Bot.deliver(
          recipient: message.sender,
          # message: {
          #   text: "#{movie.title}"
          # }
            "message":{
              "attachment":{
                "type":"template",
                "payload": {
                  "template_type":"generic",
                  "elements":movie_array
                }
              }
            }
        )
    end
  end
end

Bot.on :postback do |postback|

  messenger_id = postback.messaging['sender']['id']
  recipient_id = postback.messaging['recipient']['id']
  response = RestClient.get "https://graph.facebook.com/v2.6/#{messenger_id}?fields=first_name,last_name,profile_pic&access_token=#{ENV['FB_ACCESS_TOKEN']}"
  repos = JSON.parse(response)
  user = User.where(first_name: repos["first_name"]).where(last_name: repos["last_name"]).first

  payload_hash = JSON.parse(postback.payload)

  case payload_hash.keys.first
  when "movie_id"
    interest = Interest.new
    p "this is the movie i want: #{Movie.find(payload_hash["movie_id"]).title}" 
    interest.movie = Movie.find(payload_hash["movie_id"])
    interest.user = user
    if interest.save
      text = "#{interest.movie.title} has been added to your watchlist"
    else
      text = "Sorry. Something went wrong"
    end

  else
    text = 'Oups'
  end

  Bot.deliver(
    recipient: postback.messaging['sender'],
    message: {
      text: text
    }
  )
end

Bot.on :delivery do |delivery|
  puts "Delivered message(s) #{delivery.ids}"
end