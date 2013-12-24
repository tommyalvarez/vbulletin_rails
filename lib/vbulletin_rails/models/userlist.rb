module VBulletinRails

  # Model containing VBulletin User information
  class Userlist < ActiveRecord::Base

    # VBulletin tables prefix in database. It must set same as <tt>$config['Database']['tableprefix']</tt> in your VBulletin forum
    PREFIX = get_vbulletin_prefix
    establish_vbulletin_connection

    if Rails.version >= '3.2'
      self.table_name = PREFIX + 'userlist'
    else
      set_table_name(PREFIX + 'userlist')
    end

    attr_accessible :userid, :relationid, :type, :friend
    validates_presence_of :userid, :relationid, :type, :friend
    validates_uniqueness_of :userid, scope: :relationid

    belongs_to :user, foreign_key: :userid
    belongs_to :relation_user, foreign_key: :relationid, class_name: "User"
  end
end
