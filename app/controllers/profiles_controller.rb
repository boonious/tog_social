class ProfilesController < ApplicationController

  def index
    @order = params[:order] || 'created_at'
    @page = params[:page] || '1'
    @asc = params[:asc] || 'desc'   
    @profiles = Profile.active.paginate :per_page => Tog::Config["plugins.tog_social.profile.list.page.size"],
                                 :page => @page,
                                 :order => "profiles.#{@order} #{@asc}"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @profiles }
    end
  end

  def show
    # Facilitates 'http://baseurl/profiles/:id' or 'http://baseurl/user_name' Twitter like shortcuts to access profiles.
    @profile = params[:user_name] ? User.active.find_by_login(params[:user_name]).profile : Profile.active.find(params[:id])  
    @order = params[:order] || 'created_at'
    @page = params[:page] || '1'
    @asc = params[:asc] || 'desc'
    pagination = {:per_page => 10, :page => @page, :order => "#{@order} #{@asc}"}

    # For a form to create shared object which can be posted to the user profile
    @sharing = Share.new

    homepage = @profile.user.homepage
    query_conditions = case current_user
    when @profile.user
      ['shared_to_id = ?', homepage.id] # fetch all sharings related to this user profile/homepage for profile owner
    else
      if current_user # other signed-on user see published and their own 'pending' sharings.
        ['shared_to_id = ? AND (state = ? OR user_id = ?)', homepage.id, "published", current_user.id]
      else # fetch only published sharing for not signed-on users
        ['shared_to_id = ? AND state = ?', homepage.id, "published"]
      end
    end

    # Fetch the appropriate sharing for display in users profile
    @sharings = Share.find(:all, :conditions => query_conditions, :order => "#{@order} #{@asc}").paginate  :per_page => 10, :page => @page
    store_location
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @profile }
    end
  end

end
