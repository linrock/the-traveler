Rails.application.routes.draw do

  root 'favicons#index'
  get  'favicons'              => 'favicons#show'

  get  'the-traveler'          => 'traveler#index'
  get  'the-traveler/favicons' => 'traveler#favicons'

end
