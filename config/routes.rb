Foo::Application.routes.draw do
  match "/things", :to => "things#index"
end
