require "sinatra/base"

class Demo < Sinatra::Base
  get '/' do
    "The best is yet to come and won’t that be fine. – Frank Sinatra"
  end

  # $0 is the executed file
  # __FILE__ is the current file
  run! if __FILE__ == $0
end
