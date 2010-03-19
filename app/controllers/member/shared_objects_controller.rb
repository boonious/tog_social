class Member::SharedObjectsController < Member::BaseController

  def index
    @order = params[:order] || 'created_at'
    @page = params[:page] || '1'
    @asc = params[:asc] || 'desc'
    @shared_objects = SharedObject.paginate :per_page => Tog::Config["plugins.tog_social.profile.list.page.size"],
                                 :page => @page,
                                 :order => "shared_objects.#{@order} #{@asc}"

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @shared_objects }
    end
  end

  def show
    @shared_object = SharedObject.find(params[:id])
    @sharings = Share.find :all, :conditions => ["user_id = ? and shareable_id = ?", @shared_object.user.id, @shared_object.id]
    store_location
    respond_to do |format|
      format.html
    end
  end
  
  def new
    @shareable = SharedObject.new
    @shared_to = []
  end
  
  def create
    if params[:commit] == 'Cancel'
       redirect_back_or_default('/')
    else
      @shareable = SharedObject.new params[:shared_object]
      @shareable.user = current_user
      @shareable.type = 'SharedObject' # May be subclasses of shared object later such as 'link', 'comment' later
      @shareable.published_at = '' if params[:shared_object][:state]=='draft' and params[:update_published_at]
      @shareable.save

      # Preparing to link the shared object to user commons (groups)
      @sharing = Share.new
      sharing_options = {}
      sharing_options.merge!({:published_at=>@sharing.published_at}) if params[:update_published_at] # not in UI at the moment
      
      # The group to share this with
      shared_to = Group.find params[:group_id] 

      # Send to Twitter if a twitter user opt to do so
      twitter_message = ""
      if params[:twitter] && current_user.service_provider.include?('twitter')
        current_user.consumer_tokens.each do | token |
          token.client.update params[:shared_object][:content] if token.instance_of? TwitterToken
          twitter_message = " and to Twitter"
        end
      end
     
      # User can also share the object simultaneous to other subscribed commons (groups)
      if params[:other_group]
        # Additional groups to share this with as specified by the users, including the current group
        @groups = Group.find params[:other_group].collect! {|x| x.to_i } << shared_to
        @groups.each do |a_group|          
          a_group.share(current_user,  @shareable.type,  @shareable.id, sharing_options)  
        end
        user_message = @groups.collect { |x| current_user.groups.first == x ? current_user.profile.full_name : x.name }
        flash[:ok] = "Object shared with " + user_message.join(', ') + twitter_message
      else
        # Share to the current group
        shared_to.share(current_user,  @shareable.type,  @shareable.id, sharing_options) 
        user_message = current_user.groups.first == shared_to ? current_user.profile.full_name : shared_to.name + ' group'
        flash[:ok] = "Object shared with " + user_message + twitter_message
      end      
      
      #Save a copy of the shareable to user's own profile
      current_user.groups.first.share(current_user,  @shareable.type,  @shareable.id, sharing_options) unless (current_user.id == shared_to.user_id && current_user.groups.first == shared_to)
      redirect_back_or_default('/')
    end    
  end
   
   def edit
     @shareable = SharedObject.find(params[:id])
     # retrieve groups this shareble shared with
     @shared_to = Share.find(:all, :conditions => ['shareable_id = ? AND user_id = ?', @shareable.id, @shareable.user.id]).collect {|share| share.shared_to_id }      
   end
   
   def update
    if params[:commit] == 'Cancel'
      redirect_back_or_default('/')
    else
      @shareable = SharedObject.find params[:id]
      if @shareable.user == current_user
        @shareable.update_attributes(params[:shared_object]) if params[:shared_object]
        new_shared_to = params[:other_group] || []
        shares_in_other_groups = Share.find(:all, :conditions => ['shareable_id = ? AND user_id = ?', @shareable.id, @shareable.user.id]).delete_if { |share| share.shared_to_id == @shareable.user.groups.first.id }
        shared_to = shares_in_other_groups.collect {|share| share.shared_to_id }
        user_groups = @shareable.user.groups[1..-1]
        sharing_options = {}
        for group in user_groups
          if new_shared_to.include?(group.id.to_s)
            # share to this group if not already shared
            group.share(current_user,  @shareable.type.to_s,  @shareable.id, sharing_options) unless shared_to.include?(group.id)        
          else
            # remove share if already shared
            Share.find(:first, :conditions => ['shareable_id = ? AND user_id = ? AND shared_to_id = ?', @shareable.id, @shareable.user.id, group.id]).destroy if shared_to.include?(group.id)
          end
        end
      end
      #need fixing
      redirect_back_or_default('/')
    end
  end
   
   def delete
     @shareable = SharedObject.find params[:id]
     @shared_to = Group.find params[:group_id]
     sharing_query = params[:mode]=='all' ?  [ 'shareable_id = ?', @shareable.id] :  [ 'shareable_id = ? AND shared_to_id = ?', @shareable.id, @shared_to.id]
     @related_sharings = Share.find(:all, :conditions => sharing_query)
     unless @shareable.user == current_user || @shared_to.user_id == current_user.id
       flash[:error] = "You are not permitted to delete this object."
       redirect_back_or_default('/')
     end
   end
   
   def destroy
    if params[:commit] == 'Cancel'
      redirect_back_or_default('/')
    else
      shareable = SharedObject.find params[:id]
      shared_to = Group.find params[:group_id]
      case params[:mode]
      when 'all'
        if shareable.user == current_user
          sharing_ids = Share.find_all_by_shareable_id(shareable.id).collect(&:id)
          Share.destroy sharing_ids
          shareable.destroy
          flash[:ok] = "The post and all the associated sharings are now deleted."
        end
      when 'sharing'
        if shared_to.user_id == current_user.id
          sharing_id = Share.find(:all, :conditions => ['shareable_id = ? AND shared_to_id = ?', shareable.id, shared_to.id]).collect(&:id)
          Share.destroy sharing_id
          flash[:ok] = "The post has been removed from " + shared_to.name + "."
        end
      else
        flash[:notice] = I18n.t("tog_social.sharings.member.remove_share_nok")      
      end
      respond_to do |format|
        format.html { redirect_back_or_default('/') }  
      end
    end
   
   end
   
   def publish
    shareable = SharedObject.find params[:id]
    if shareable.user == current_user
      shareable.update_attribute(:state, "shared")
      flash[:ok] = "The post has been published and visible publically."
    else
      flash[:notice] = "Unable to publish the post."
    end 
    respond_to do |format|
      format.html { redirect_back_or_default('/') }
    end 
  end
  
  def approve
    sharing = Share.find params[:id]
    if current_user.id == Group.find(sharing.shared_to_id).user_id
      sharing.publish!
      flash[:ok] = "You have approved this post - it's now visible publically."
    else
      flash[:notice] = "Unable to approve post."
    end 
    respond_to do |format|
      format.html { redirect_back_or_default('/') }
    end 
  end
  
  def share
    if params[:commit] == 'Cancel'
      redirect_back_or_default('/')
    else
      @shareable = SharedObject.find(params[:id])
      # retrieve groups this shareble shared with
      @shared_to = Share.find(:all, :conditions => ['shareable_id = ? AND user_id = ?', @shareable.id, @shareable.user.id]).collect {|share| share.shared_to_id }
    #  @all_groups = Group.active.collect { |group| group.type.to_s=='Homepage' ? nil : group }
    #  @all_groups.compact!
    end    
  end
    
end
