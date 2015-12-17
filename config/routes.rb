Rails.application.routes.draw do

  root 'traveler#index'
  get  'the-traveler/updates'  => 'polling#updates'

end
