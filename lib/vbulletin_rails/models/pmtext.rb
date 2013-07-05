module VBulletinRails
  # Model containing VBulletin private messages join-table information
  class Pmtext < ActiveRecord::Base

    # VBulletin tables prefix in database. It must set same as <tt>$config['Database']['tableprefix']</tt> in your VBulletin forum
    PREFIX = get_vbulletin_prefix
    establish_vbulletin_connection

    if Rails.version >= '3.2'
      self.primary_key = :pmid
      self.table_name = PREFIX + 'pmtext'
    else
      set_primary_key(:pmid)
      set_table_name(PREFIX + 'pmtext')
    end

    has_many :pms, :foreign_key => :pmtextid, :dependent => :delete_all
    has_many :users, :through => :pms, :source => :user

  end
end