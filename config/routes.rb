Rails.application.routes.draw do
  get 'welcome/index'
  post '/send_data' => 'welcome#send_data'
  
  
  root 'welcome#index'
end
