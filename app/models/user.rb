class User < ActiveRecord::Base

  before_create :create_profile
  
  # Each user owns a homepage (subclass of group)
  after_create :create_homepage

  has_one :profile, :dependent => :destroy
  has_one :homepage, :dependent => :destroy
  
  has_many :memberships, :dependent => :destroy
  has_many :plain_memberships, :class_name => 'Membership',
                               :conditions => ['memberships.moderator <> ?', true]
  has_many :moderator_memberships, :class_name => 'Membership',
                                   :conditions => ['memberships.moderator = ?', true]

  has_many :groups, :through => :memberships,
                    :conditions => "memberships.state='active' and groups.state='active'"

  has_many :moderated_groups, :through => :moderator_memberships,
                    :conditions => "memberships.state='active' and groups.state='active'", :source => :group

  has_many :sharings, :class_name => 'Share', :dependent => :destroy
  
  # => oauth support
  has_many :client_applications
  has_many :tokens, :class_name=>"OauthToken", :order=>"authorized_at desc", :include=>[:client_application]
  # => oauth support

  accepts_nested_attributes_for :profile
  attr_accessible :profile_attributes
  
  def network
    profile.network.collect{|profile| profile.user}
  end
  
  protected

    def create_profile
      self.profile ||= Profile.new
    end
    
    def create_homepage
      @group = Homepage.new(:name=> self.login + "'s homepage", :description => "A personal space (homepage) of " + self.login + " where objects can be shared to or from, in various contexts such as posts, links.")
      @group.author = self
      @group.private = true
      @group.save
      @group.activate!
      @group.join(self, true)
      @group.activate_membership(self)
    end

end
