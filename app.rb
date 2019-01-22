require "sinatra"
require "sinatra/reloader" if development?
require "pry-byebug"
require "better_errors"
require "csv"
require 'yaml/store'
# require "cookbook"
# require "recipe"

class Cookbook
  def initialize(csv_file)
    @csv_file = csv_file
    @recipes = []

    CSV.foreach(csv_file) do |row|
      # row == ["cake", "flour and water"]
      tried = row[2] == "true"
      tried.class
      # Create a recipe object using the data from the CSV row
      new_recipe = Recipe.new(row[0], row[1], tried)
      # Store that recipe in the array `@recipes`
      @recipes << new_recipe
    end
  end

  def all
    @recipes
  end

  def add_recipe(new_recipe)
    @recipes << new_recipe
    write_to_csv
  end

  def find(index)
    return @recipes[index]
  end

  def update_status(recipe)
    recipe.mark_as_tried!
    write_to_csv
  end

  def remove_recipe(recipe_index)
    @recipes.delete_at(recipe_index)
    write_to_csv
  end

  private

  def write_to_csv
    # Copy the content of `@recipes` to the CSV
    CSV.open(@csv_file, "w") do |csv|
      @recipes.each do |recipe|
        csv << [recipe.name, recipe.description, recipe.tried]
      end
    end
  end
end

class Recipe
  attr_reader :name, :description, :tried

  def initialize(name, description, tried = false)
    @name = name
    @description = description
    @tried = tried
  end

  def mark_as_tried!
    @tried = true
  end
end

set :bind, '0.0.0.0'

configure :development do
  use BetterErrors::Middleware
  BetterErrors.application_root = File.expand_path('..', __FILE__)
end

cookbook = Cookbook.new('recipes.csv')

get '/' do
  @recipes = cookbook.all
  erb :recipes_list
end

get '/new' do
  @recipes = cookbook.all
  erb :new
end

post '/new_recipe' do
  # binding.pry
  new_recipe = Recipe.new(params[:recipe_name], params[:recipe_description])
  cookbook.add_recipe(new_recipe)
  @new_recipe = new_recipe
  erb :new_recipe
end

get '/delete_recipe' do
  @recipes = cookbook.all
  erb :delete_recipe
end

post '/deleted_recipe' do
  # binding.pry
  cookbook.remove_recipe(params[:recipe_name].to_i)
  @recipes = cookbook.all
  erb :deleted_recipe
  # redirect to('/')
end


