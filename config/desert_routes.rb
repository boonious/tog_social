# Add your custom routes here.  If in config/routes.rb you would
# add <tt>map.resources</tt>, here you would add just <tt>resources</tt>

resources :profiles
resources :shared_objects

resources :streams, :only => [:index, :show], :member => {:network => :get}

with_options(:controller => 'groups') do |group|
  group.tag_groups       '/groups/tag/:tag',                         :action => 'tag'
end

resources :groups, :collection => { :search => :get }, :member => { :join => :get, :leave => :get, :accept_invitation => :get, :reject_invitation => :get }

namespace(:member) do |member|
  member.resources :profiles
  member.resources :groups
  member.resources :shared_objects
  member.with_options(:controller => 'groups') do |group|
    group.group_pending_members '/:id/members/pending',         :action => 'pending_members'
    group.group_accept_member   '/:id/members/:user_id/accept', :action => 'accept_member'
    group.group_reject_member   '/:id/members/:user_id/reject', :action => 'reject_member'
    group.group_invite          '/group/invite',                :action => 'invite'
  end
  member.with_options(:controller => 'friendships') do |friendship|
    friendship.add_friend     '/friend/:friend_id/add',     :action => 'add_friend'
    friendship.confirm_friend '/friend/:friend_id/confirm', :action => 'confirm_friend'
    friendship.follow_user    '/follow/:friend_id',         :action => 'follow'
    friendship.unfollow_user  '/unfollow/:friend_id',       :action => 'unfollow'
  end
  member.with_options(:controller => 'sharings') do |sharing|
    sharing.share '/sharings/share/:group_id/:shareable_type/:shareable_id', :action => 'create', :conditions => { :method => :post }    
    sharing.new_sharing '/sharings/:shareable_type/:shareable_id/new', :action => 'new'
    sharing.sharings '/sharings', :action => 'index'
    sharing.destroy_sharing '/sharings/:group_id/:id', :action => 'destroy', :conditions => { :method => :delete }      
#    sharing.destroy_sharing '/group/:id/remove/:shareable_type/:shareable_id', :action => 'destroy', :method => :delete  
  end
  member.with_options(:controller => 'shared_objects') do |shared_object|
     shared_object.new_shared_object '/:group_id/shared_objects/new', :action =>'new'
     shared_object.create_shared_object '/shared_objects/:group_id', :action =>'create', :conditions => { :method => :post}
     shared_object.update_shared_object '/shared_objects/:id', :action => 'update', :conditions => { :method => :put }
     shared_object.delete_shared_object '/:group_id/shared_objects/:id/delete/:mode', :action => 'delete', :conditions => {:method => :post}
     shared_object.destroy_shared_object '/:group_id/shared_objects/:id/destroy/:mode', :action => 'destroy', :conditions => {:method => :delete}
     shared_object.publish_shared_object '/shared_objects/:id/publish', :action => 'publish'
     shared_object.approve_sharing '/sharings/:id/approve', :action => 'approve'
     shared_object.share_existing_shared_object '/shared_objects/:id/share', :action =>'share'
  end
end

namespace(:admin) do |admin|
  admin.resources :groups, :member => { :activate => :post}
end

# => oauth support
resources :oauth_clients
authorize     '/oauth/authorize',     :controller=>'oauth', :action=>'authorize'
request_token '/oauth/request_token', :controller=>'oauth', :action=>'request_token'
access_token  '/oauth/access_token',  :controller=>'oauth', :action=>'access_token'
test_request  '/oauth/test_request',  :controller=>'oauth', :action=>'test_request'

x1 '/oauth_test',     :controller=>'oauth_test', :action=>'test'
x2 '/oauth_callback', :controller=>'oauth_test', :action=>'callback'
# => oauth support