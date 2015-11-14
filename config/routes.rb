Rails.application.routes.draw do

  root 'favicons#index'
  get  'favicons'          => 'favicons#show'

  get  'traveler'          => 'traveler#index'
  get  'traveler/favicons' => 'traveler#favicons'

end
