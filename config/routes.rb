Rails.application.routes.draw do

  root 'favicons#index'
  get  'favicons'              => 'favicons#show'

  get  'the-traveler'          => 'traveler#index'
  get  'the-traveler/updates'  => 'polling#updates'

end
