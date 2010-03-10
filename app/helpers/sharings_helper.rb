module SharingsHelper
  
  def share_with_groups_link(shareable, only_moderated_groups=false)
    return if !shareable
    groups = only_moderated_groups ? current_user.moderated_groups : current_user.groups
    render :partial => 'shared/share_with_groups', :locals => {:groups => groups, :shareable => shareable}
  end
    
    
  def share_link(link_text, share_with, shareable)
    if share_with.shared?(shareable)
      "#{link_text}<br/><small>#{I18n.t('tog_social.sharings.member.already_shared')}</small>"
    else
      link_to link_text,
          member_share_path(share_with, shareable.class.to_s, shareable.id),
          :method => :post,
          :html => {:title => I18n.t("tog_social.sharings.member.share_with", :name => share_with.name)}
    end
  end    
    
  def shareable_title(shareable)
    title_for_object(shareable)
  end

  def related_shared_to(sharing, current_shared_to)
    related_sharings = Share.find(:all, :conditions => [ 'shareable_id = ? AND shared_to_id != ?', sharing.shareable_id, current_shared_to.id])
    related_shared_to = related_sharings.collect{|x| x.shared_to }
		related_shared_to.delete(sharing.shareable.user.homepage)
    related_shared_to
  end  
  
  def title_for_object(obj)
    if (obj.respond_to?(:name))
      string = obj.name
    elsif (obj.respond_to?(:title))
      string = obj.title
    else
      string = "#{obj.class.name} / #{obj.id}"
    end
    string      
  end
  
  def title_link_for_group_object(obj)
    if obj.instance_of? Group
      group_owner = User.find(obj.user_id)
      if obj == group_owner.groups.first
        link_to = link_to(group_owner.profile.full_name, obj) + ' (profile)'
      else
        link_to = link_to(title_for_object(obj), obj)
      end
    else
      link_to = link_to(title_for_object(obj), obj)
    end
  end

end

