class MoviesController < ApplicationController
  include MovieScraper

  def index
    @movies = policy_scope(Movie)
    title = params[:title]
    @movies = @movies.where('title ILIKE ? OR original_title ILIKE ?', "%#{title}%", "%#{title}%") if title
    @friends = my_friends_finder
    respond_to do |format|
      format.html
      format.json
      format.js
    end
  end

  def show
    @movie = Movie.find(params[:id])
    authorize @movie
    @directors = @movie.credits[:crew]["Director"].join(', ') unless @movie.credits[:crew].blank?
    @actors = @movie.credits[:cast].join(', ')
    @genres = @movie.genres.join(', ')

    # sum = @movie.interests.reduce(0) { |sum, i| sum + i.rating if i.rating }
    # @rating = (sum / @movie.interests.count) if sum && @movie.interests.any?
    @location = current_user.address
    @shows = find_showtimes_of_the_day(@location || '75001', @movie, 5)
    @streamings = find_streamings_for(@movie) || {}
    @original_title = @movie.original_title unless @movie.original_title.blank? || @movie.title.casecmp(@movie.original_title) == 0
    respond_to do |format|
      format.html
      format.json
      format.js
    end
  end

  def my_friends_finder
    friend_ids = []

    if !current_user.buddies.nil?
      current_user.buddies.each do |buddy|
        friend_ids << buddy.friend_id
      end
    end
    if !current_user.friends.nil?
      current_user.friends.each do |buddy|
        friend_ids << buddy.buddy_id
      end
    end
    friend_ids
  end
end
