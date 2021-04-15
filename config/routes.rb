Rails.application.routes.draw do
  get 'welcome/index'
  post 'welcome/send_data'
  
  
  root 'welcome#index'
end
