module VBulletinRails
  # Model containing VBulletin private messages join-table information
  class Pm < ActiveRecord::Base

    # VBulletin tables prefix in database. It must set same as <tt>$config['Database']['tableprefix']</tt> in your VBulletin forum
    PREFIX = get_vbulletin_prefix
    establish_vbulletin_connection

    if Rails.version >= '3.2'
      self.primary_key = :pmid
      self.table_name = PREFIX + 'pm'
    else
      set_primary_key(:pmid)
      set_table_name(PREFIX + 'pm')
    end


    belongs_to :user, :foreign_key => :userid
    belongs_to :pmtext, :foreign_key => :pmtextid


  end
end