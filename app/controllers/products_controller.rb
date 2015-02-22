class ProductsController  < InheritedResources::Base
  respond_to :html, :json

  actions :show, :index

  skip_authorization_check
  skip_before_action :authenticate_user!

end
