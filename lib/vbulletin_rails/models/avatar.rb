module VBulletinRails

  # Model containing VBulletin User information
  class Avatar < ActiveRecord::Base


    # VBulletin tables prefix in database. It must set same as <tt>$config['Database']['tableprefix']</tt> in your VBulletin forum
    PREFIX = get_vbulletin_prefix
    establish_vbulletin_connection

    if Rails.version >= '3.2'
      self.primary_key = :avatarid
      self.table_name = PREFIX + 'avatar'
    else
      set_primary_key(:avatarid)
      set_table_name(PREFIX + 'avatar')
    end

    attr_accessible :avatarid, :avatarpath
    validates_presence_of :avatarid
    validates_presence_of :avatarpath

  end
end
