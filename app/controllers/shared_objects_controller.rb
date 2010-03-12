class SharedObjectsController < ApplicationController

  def index   
  end

  def show
    @shared_object = SharedObject.find(params[:id])  
    store_location
    respond_to do |format|
      format.html
    end
  end
end
