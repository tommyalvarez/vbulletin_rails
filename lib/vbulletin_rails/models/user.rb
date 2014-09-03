module VBulletinRails

  # Model containing VBulletin User information
  class User < ActiveRecord::Base

    # VBulletin tables prefix in database. It must set same as <tt>$config['Database']['tableprefix']</tt> in your VBulletin forum
    PREFIX = get_vbulletin_prefix
    establish_vbulletin_connection

    if Rails.version >= '3.2'
      self.primary_key = :userid
      self.table_name = PREFIX + 'user'
    else
      set_primary_key(:userid)
      set_table_name(PREFIX + 'user')
    end

    attr_accessible :email, :password, :username,  :lastactivity, :lastvisit, :avatarid, :avatarrevision
    attr_accessible :usertitle, :joindate, :userfield_attributes, :usertextfield_attributes, :fbaccesstoken
    attr_accessible :fbjoindate, :fbuserid, :fbname

    validates_presence_of :email, :password
    validates_uniqueness_of :email
    validates_format_of :email, :with => /^([^@\s]+)@((?:[-a-z0-9]+\.)+[a-z]{2,})$/i

    belongs_to :avatar, foreign_key: :avatarid
    has_one :userfield, :foreign_key => :userid, :dependent => :delete
    has_one :usertextfield, :foreign_key => :userid, :dependent => :delete
    has_many :session, :foreign_key => :userid
    has_many :relations, class_name: "Userlist", foreign_key: :userid, conditions: {type: "buddy", friend: "yes"}
    has_many :relation_users, through: :relations, class_name: "User", foreign_key: :relationid

    after_initialize :defaults

    # scopes
    scope :by_email, lambda{|email| email.blank?? where("1=0") : where(email: email)}

    # nested_attributes
    accepts_nested_attributes_for :userfield
    accepts_nested_attributes_for :usertextfield

    # Sets all unnecessary parameters as default for newly registered VBulletin user.
    def defaults
      nowstamp = Time.now.to_i
      self.usergroupid ||= 2
      self.username ||= (self.username.blank? ? self.email : self.username)
      self.usertitle ||= 'Junior Member'
      self.joindate ||= nowstamp
      self.daysprune ||= -1
      self.lastvisit ||= nowstamp
      self.lastactivity ||= nowstamp
      self.reputationlevelid ||= 5
      self.timezoneoffset ||= '0'
      self.options ||= 45108311
      self.birthday_search ||= '1800-01-01'
      self.startofweek ||= -1
      self.languageid ||= 1
      self.userfield ||= Userfield.new
      self.usertextfield ||= Usertextfield.new
      self.adminoptions ||= 0
      self.fbaccesstoken ||= ""
      self.fbname ||= ""
      self.infractiongroupid ||= 0
      self.infractiongroupids ||= 0
      self.infractions ||= 0
      self.ipoints ||= 0
    end

    # Authenticate VBulletin user with provided password. Returns VBulletinRails::User object if success
    def authenticate(passwd)
      User.password_hash(passwd.to_s, salt) == password ? self : false
    end

    # Authenticate VBulletin user with provided session hash. Returns VBulletinRails::User object if success
    def authenticate_bb_password(bb_password_hash)
      bb_password_hash == bb_password ? self : false
    end

    # Returns correct VBulletin session hash for user
    def bb_password
      Digest::MD5.hexdigest(password + Rails.configuration.vbulletin.cookie_salt)
    end

    # Sets new VBulletinRails::User password
    def password= passwd
      return unless passwd
      new_salt = User.fresh_salt
      self.passworddate = Date.today.to_s
      self.salt = new_salt
      self.send(:write_attribute, :password, User.password_hash(passwd.to_s, new_salt))
    end

    # Registers VBulletin user with given username/email and password
    #
    #   VBulletinRails::User.register :username => 'username',      :password => 'user password'
    #   VBulletinRails::User.register :email => 'user@example.com', :password => 'user password'
    def self.register options
      vb_user = self.new(options)
      if vb_user.save
        connection.execute("UPDATE `#{PREFIX}user` SET `birthday_search` = '0000-00-00' WHERE `#{PREFIX}user`.`userid` = '#{vb_user.userid}'")
        return self.find(vb_user.userid)
      else
        return vb_user
      end
    end

    def get_avatar
      my_avatar = nil
      
      if avatarid == 0 && avatarrevision != 0
        my_avatar =  "http://www.nightclubber.com.ar/foro/customavatars/thumbs/avatar#{self.userid}_#{self.avatarrevision}.gif" 
      else
        if avatarrevision == 0
          my_avatar = "http://www.nightclubber.com.ar/foro/images/ncstyle/misc/unknown.gif"
        else
          my_avatar = "http://www.nightclubber.com.ar/foro/#{self.avatar.avatarpath}"
        end
      end

    end

    private
    #:nodoc:
    def self.password_hash password, salt
      Digest::MD5.hexdigest(Digest::MD5.hexdigest(password) + salt)
    end

    #:nodoc:
    def self.fresh_salt length = 30
      (1..length).map {(rand(33) + 93).chr}.join
    end

  end
end
