Rails.application.routes.draw do

  root 'favicons#index'

  get  'favicons' => 'favicons#show'

end
