Rails.application.routes.draw do

  root 'favicons#index'

  get  'favicons' => 'favicons#show'
  get  'traveler' => 'traveler#index'

end
