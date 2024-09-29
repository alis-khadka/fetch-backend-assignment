Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Defines the root path route ("/")
  root "points#home"

  # Endpoints for the points_controller
  post "add", to: "points#add", as: :points_add
  post "spend", to: "points#spend", as: :points_spend
  get "balance", to: "points#balance", as: :points_balance

  # Endpoints for the points_controller with wallet_id parameter
  post ":wallet_id/add", to: "points#add", as: :points_add_with_id
  post ":walled_id/spend", to: "points#spend", as: :points_spend_with_id
  get ":walled_id/balance", to: "points#balance", as: :points_balance_with_id
end
